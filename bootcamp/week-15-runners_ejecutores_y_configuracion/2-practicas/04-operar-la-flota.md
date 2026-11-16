# Práctica 04 — Operar la flota

> La flota está montada; ahora se opera. Miras su estado y su versión por API, vacías un runner con una pausa antes de tocarlo, rotas el token de `dind-app` y lo pones en `config.toml` en el mismo paso, das de baja un runner sin dejar su bloque huérfano, y versionas en `infra/entornos` una plantilla del `config.toml` que reconstruye la flota sin contener un solo secreto.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 03 completada · Teoría [02](../1-teoria/02-el-config-toml.md) y [08](../1-teoria/08-operar-la-flota.md) leídas · `envsubst` en el host (paquete `gettext-base` en Debian y Ubuntu)

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | La foto de la flota: estado, versión, actividad | `flota-en-version-fijada` |
| 2 | Un runner vaciado con una pausa | — |
| 3 | El token de `dind-app` rotado y en `config.toml` | — |
| 4 | Un runner dado de baja en GitLab y en `config.toml` | — |
| 5 | `runners/config.toml.plantilla` en `infra/entornos` | `plantilla-con-cache-s3`, `plantilla-sin-secretos` |
| 6 | Caducidad para los tokens nuevos | — |

Si has cerrado la terminal: el paso 0 de la [práctica 01](01-la-cache-compartida.md#paso-0-preparar-el-terreno) y `source ~/.bc-gitlab-s15`, que ya tiene `RID_DOCKER`, `RID_DIND` y `RID_DEPLOY`.

---

## Paso 1: La foto de la flota

**Por qué**: antes de operar algo hay que poder verlo entero. Tres runners en dos sitios (el proyecto `app` y el grupo `infra`), un proceso detrás (teoría 08, apartado 2.1).

```bash
for R in $RID_DOCKER $RID_DIND $RID_DEPLOY; do
  curl -s -H "$H" "$API/runners/$R" | jq -c '{id, description, runner_type, status, job_execution_status}'
  curl -s -H "$H" "$API/runners/$R/managers" | jq -c '.[] | {system_id, version}'
done
```

**Verifica**: tres runners `online`, los tres con el mismo `system_id` y `version` `19.2.2`, la de `RUNNER_VERSION` en `.env`. Si alguno tiene otra versión, hay un segundo proceso con su token en algún sitio: averigua dónde antes de seguir.

---

## Paso 2: Vaciar antes de tocar

**Por qué**: reiniciar el proceso mata los jobs de los tres runners a la vez (teoría 08, apartado 2.3). La pausa deja terminar lo que corre y no admite nada nuevo. Se ve mejor con un pipeline en marcha.

```bash
curl -s --request PUT "$API/runners/$RID_DOCKER" -H "$H" --data "paused=true" | jq -c '{paused, status}'
PIPE=$(curl -s --request POST "$API/projects/$P/pipeline" -H "$H" --data-urlencode "ref=main" | jq -r .id)
sleep 30
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | "\(.name) \(.status)"'
```

**Verifica**: `{"paused":true,"status":"paused"}`; `build` y `test` en `pending` (solo `docker-app` los coge), y `probar-imagen` en `running` o `success`: `dind-app` no está en pausa. Ahora, de vuelta:

```bash
curl -s --request PUT "$API/runners/$RID_DOCKER" -H "$H" --data "paused=false" | jq -c '{paused}'
esperar "$P" "$PIPE"                                                # success
curl -s -H "$H" "$API/runners/$RID_DOCKER" | jq -r .job_execution_status   # idle
```

`idle` en los tres es el momento de reiniciar el proceso, si alguna vez hace falta.

---

## Paso 3: Rotar el token de `dind-app`

**Por qué**: el `config.toml` ha estado esta semana en `~/.bc-gitlab-runner.toml`. Si ese archivo hubiera salido de tu máquina, sus tokens tendrían que dejar de valer. El token viejo muere al instante, así que las dos mitades (GitLab y `config.toml`) van en el mismo bloque de comandos (teoría 08, apartado 2.4).

> [!WARNING]
> Entre la primera línea y el `cp` final, `dind-app` no coge jobs. Hazlo con `dind-app` en `idle`. La copia de seguridad del archivo va antes.

```bash
cd /ruta/a/bc-gitlab
curl -s -H "$H" "$API/runners/$RID_DIND" | jq -r .job_execution_status     # idle
docker compose cp gitlab-runner:/etc/gitlab-runner/config.toml ~/.bc-gitlab-runner.toml
cp ~/.bc-gitlab-runner.toml ~/.bc-gitlab-runner.toml.antes-rotar && chmod 600 ~/.bc-gitlab-runner.toml*
NT=$(curl -s --request POST "$API/runners/$RID_DIND/reset_authentication_token" -H "$H" | jq -r .token)
sed -i '/^  name = "dind-app"$/,/^  \[runners\.docker\]$/ s|^  token = .*|  token = "'"$NT"'"|' ~/.bc-gitlab-runner.toml
docker compose cp ~/.bc-gitlab-runner.toml gitlab-runner:/etc/gitlab-runner/config.toml
unset NT
```

El `sed` solo toca la línea `token` **dentro** del bloque de `dind-app`: desde su `name` hasta su `[runners.docker]`.

**Verifica**:

```bash
sleep 5
docker compose exec gitlab-runner gitlab-runner verify 2>&1 | grep -oE 'is (not )?valid|runner_name=[a-z-]+' | paste - -
# is valid  runner_name=docker-app
# is valid  runner_name=dind-app
# is valid  runner_name=deploy-infra
```

Si `dind-app` sale `is not valid`, el `sed` no encontró el bloque. No restaures `~/.bc-gitlab-runner.toml.antes-rotar`: su token de `dind-app` ya está muerto. Pide otro con `reset_authentication_token` y pon la línea `token` de `dind-app` a mano.

---

## Paso 4: Dar de baja un runner

**Por qué**: borrar un runner en GitLab no lo quita de `config.toml`, y el proceso sigue preguntando con un token muerto (teoría 08, apartado 2.5). Se ve con un runner de usar y tirar.

```bash
R=$(curl -s --request POST "$API/user/runners" -H "$H" --data "runner_type=project_type" \
  --data "project_id=$ID_APP" --data-urlencode "description=prueba-baja" --data "tag_list=prueba-baja" --data "run_untagged=false")
RID_X=$(jq -r .id <<<"$R"); RT=$(jq -r .token <<<"$R"); unset R
docker compose exec gitlab-runner gitlab-runner register --non-interactive \
  --url http://gitlab:8888 --token "$RT" --name prueba-baja --executor docker --docker-image alpine:3.24.2 2>&1 | grep registered
unset RT
curl -s --request DELETE "$API/runners/$RID_X" -H "$H" -o /dev/null -w '%{http_code}\n'      # 204
sleep 10
docker compose logs --since 30s gitlab-runner 2>&1 | grep -m1 -oE 'forbidden .*runner_name=prueba-baja'
```

**Verifica**: `forbidden … runner_name=prueba-baja`. El proceso sigue intentándolo. Ahora, la limpieza.

> [!WARNING]
> `verify --delete` borra todos los bloques inválidos, no solo `prueba-baja`. Si el paso 3 dejó mal el token de `dind-app`, también se llevaría su bloque, y la copia `.antes-rotar` no sirve para recuperarlo. Primero una copia nueva y un `verify` a secas: solo `prueba-baja` puede salir `is not valid`.

```bash
docker compose cp gitlab-runner:/etc/gitlab-runner/config.toml ~/.bc-gitlab-runner.toml.antes-delete
chmod 600 ~/.bc-gitlab-runner.toml.antes-delete
docker compose exec gitlab-runner gitlab-runner verify 2>&1 | grep -oE 'is not valid.*runner_name=[a-z-]+' | grep -oE 'runner_name=[a-z-]+'
# runner_name=prueba-baja      ← si sale otro, para y arregla ese token antes
docker compose exec gitlab-runner gitlab-runner verify --delete 2>&1 | grep -oE 'is (not )?valid|runner_name=[a-z-]+' | paste - -
docker compose exec gitlab-runner grep -c '^\[\[runners\]\]' /etc/gitlab-runner/config.toml
# 3
```

`prueba-baja` sale `is not valid` una vez, y el archivo vuelve a tener tres bloques.

---

## Paso 5: La plantilla versionada

**Por qué**: `config.toml` no puede ir a un repositorio, pero lo que describe (tres runners, sus límites, la caché, las listas de privilegiados) es infraestructura y se revisa como tal (teoría 08, apartado 2.6). La plantilla sustituye los dos secretos (los tokens y la clave S3) por marcadores, y `envsubst` la convierte de vuelta en el archivo real.

```bash
cd /ruta/a/tus/clones/entornos && git switch main && git pull --ff-only
mkdir -p runners
docker compose -f /ruta/a/bc-gitlab/docker-compose.yml cp gitlab-runner:/etc/gitlab-runner/config.toml ~/.bc-gitlab-runner.toml
{
  echo '# Plantilla del config.toml de la flota (Semana 15). Sin secretos: los ${…} se rellenan con'
  echo '# envsubst con los tokens que da POST /user/runners y la clave de RUNNER_CACHE_SECRET_KEY.'
  awk '
    /^\[\[runners\]\]/ { n = "" }
    /^  name = / { n = $3; gsub(/"/, "", n); gsub(/-/, "_", n); n = toupper(n) }
    /^  token = / { print "  token = \"${TOKEN_" n "}\""; next }
    /^      SecretKey = / { print "      SecretKey = \"${RUNNER_CACHE_SECRET_KEY}\""; next }
    { print }' ~/.bc-gitlab-runner.toml
} > runners/config.toml.plantilla
grep -nE 'token = |SecretKey' runners/config.toml.plantilla
grep -c 'glrt-' runners/config.toml.plantilla
```

**Verifica**: tres `token = "${TOKEN_…}"`, tres `SecretKey = "${RUNNER_CACHE_SECRET_KEY}"` y `0` tokens reales. La prueba de que la plantilla sirve es reconstruir el archivo y compararlo con el de verdad:

```bash
tok() { awk -v n="$1" '$0 ~ "name = \"" n "\"" {f=1} f && /^  token =/ {gsub(/"/, "", $3); print $3; exit}' ~/.bc-gitlab-runner.toml; }
TOKEN_DOCKER_APP=$(tok docker-app) TOKEN_DIND_APP=$(tok dind-app) TOKEN_DEPLOY_INFRA=$(tok deploy-infra) \
RUNNER_CACHE_SECRET_KEY=$(grep '^RUNNER_CACHE_SECRET_KEY=' /ruta/a/bc-gitlab/.env | cut -d= -f2) \
  envsubst '${TOKEN_DOCKER_APP} ${TOKEN_DIND_APP} ${TOKEN_DEPLOY_INFRA} ${RUNNER_CACHE_SECRET_KEY}' \
  < runners/config.toml.plantilla | tail -n +3 | diff - ~/.bc-gitlab-runner.toml && echo "idéntico"
```

`idéntico`. La lista de variables de `envsubst` no es opcional: sin ella, sustituiría cualquier `$` del archivo. Sube la plantilla:

```bash
git add runners/config.toml.plantilla
git commit -S -m "docs: plantilla del config.toml de la flota de runners, sin secretos"
git push origin main
rm ~/.bc-gitlab-runner.toml.antes-*
```

El push no crea pipeline (Semana 14), y la copia de seguridad de la práctica 01 ya no sirve: sus tokens de `dind-app` están muertos.

---

## Paso 6: Caducidad para los tokens nuevos

**Por qué**: rotar a mano depende de acordarse. La instancia puede poner caducidad a los tokens de runner, por tipo; el proceso los renueva solo antes de que venzan (teoría 08, apartado 2.4). Es configuración de instancia: hace falta el token de administrador.

```bash
for T in project group; do
  curl -s --request PUT "$API/application/settings" -H "$HA" \
    --data "${T}_runner_token_expiration_interval=7776000" | jq -r ".${T}_runner_token_expiration_interval"
done
```

**Verifica**: `7776000` dos veces (90 días). Los tokens que ya existen conservan `token_expires_at: null`:

```bash
curl -s -H "$H" "$API/runners/$RID_DIND" | jq -c '{token_expires_at}'
```

La caducidad se aplica a los tokens que se emitan a partir de ahora.

---

## ✅ Resultado

- [ ] La foto de la flota: tres runners, un `system_id`, versión `19.2.2`
- [ ] `docker-app` pausado y vuelto a activar con un pipeline en marcha
- [ ] El token de `dind-app` rotado, y los tres `is valid`
- [ ] `prueba-baja` borrado en GitLab y en `config.toml`
- [ ] `runners/config.toml.plantilla` en `main` de `infra/entornos`, que reconstruye el archivo idéntico
- [ ] Caducidad de 90 días para los tokens nuevos de proyecto y de grupo

```bash
./scripts/verificar-semana.sh 15     # quince comprobaciones en verde; la del ADR, en el proyecto
```

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| Un runner con otra versión en el paso 1 | Su token está en otro proceso: un `register` antiguo en otra máquina | Rota su token (paso 3): el otro proceso se queda fuera |
| `build` no arranca tras `paused=false` | El runner tarda un ciclo de `check_interval` en volver a preguntar | Espera unos segundos; si sigue, `GET /runners/$RID_DOCKER` y mira `paused` |
| `verify` dice `is not valid` para `dind-app` tras el paso 3 | El `sed` no casó: el bloque tiene otra sangría | Edita la línea `token` del bloque a mano con un token recién rotado |
| `verify --delete` borra un runner que querías | Ese runner se había borrado en GitLab | Créalo de nuevo y regístralo; `verify` sin `--delete` primero para mirar |
| El `diff` del paso 5 no da `idéntico` | Falta una variable, o el `tail -n +3` no quita las dos líneas de comentario | `envsubst` deja vacío lo que no conoce: compara la línea que difiere |
| `PUT application/settings` da `403` | `HA` no es un token de administrador | `GITLAB_ADMIN_TOKEN` en `~/.bc-gitlab` (Semana 01) |

---

[← Anterior: El runner protegido](03-el-runner-protegido.md) · [Volver a la Semana 15](../README.md)

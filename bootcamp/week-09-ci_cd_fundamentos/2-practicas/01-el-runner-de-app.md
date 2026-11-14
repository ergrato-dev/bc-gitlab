# Práctica 01 — El runner de `app`

> Limpias lo que Auto DevOps dejó pendiente, enseñas a los jobs a encontrar GitLab dentro de la red del laboratorio, creas un runner de proyecto por API, lo registras en el contenedor del compose y lo pruebas con un job de usar y tirar.

**Duración estimada**: 50 min
**Prerrequisitos**: Semana 08 completada · Teoría [01](../1-teoria/01-del-commit-al-pipeline.md) y [03](../1-teoria/03-el-runner.md) leídas

---

## Contexto

Esta práctica no toca `main`. Deja el runner funcionando y comprobado antes de que exista el primer `.gitlab-ci.yml` de verdad, para que la práctica 02 solo tenga que pensar en el pipeline.

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | Nada pendiente de Auto DevOps | — |
| 2 | Los jobs llegan a la API | `variable-de-instancia-api` |
| 3 | El runner existe en GitLab | — |
| 4 | El runner está registrado y en línea | `runner-de-proyecto-en-linea` |
| 5 | Un job de prueba llega a GitLab | — |

---

## Paso 0: Preparar el terreno y el token del revisor

**Por qué**: esta semana hay tres merge requests a `main` que necesitan la aprobación de `revisor`, como en la Semana 08. El token se revoca en el punto 4 del proyecto.

```bash
source ~/.bc-gitlab
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
export PID=$(curl -s -H "$H" "$API/projects/$P" | jq -r .id)
export YO=$(curl -s -H "$H" "$API/user" | jq -r .username)
export REV=revisor-<tu-dominio>

export UID_REV=$(curl -s -H "$H" "$API/users?username=$REV" | jq -r '.[0].id // empty')
[[ "$UID_REV" =~ ^[0-9]+$ ]] && [[ "$PID" =~ ^[0-9]+$ ]] || { echo "Falta $REV o el proyecto: NO sigas"; return 1 2>/dev/null || exit 1; }
T_REV=$(curl -s --request POST "$API/users/$UID_REV/personal_access_tokens" \
  -H "PRIVATE-TOKEN: ${GITLAB_ADMIN_TOKEN:-$GITLAB_TOKEN}" \
  --data-urlencode "name=flujo-s09" \
  --data-urlencode "scopes[]=api" \
  --data-urlencode "expires_at=$(date -d '+7 days' +%F)" \
  | jq -r '.token')
[ -n "$T_REV" ] && [ "$T_REV" != null ] || { echo "No se creó el token: revisa permisos de administrador y NO sigas"; return 1 2>/dev/null || exit 1; }
export HR="PRIVATE-TOKEN: $T_REV"

grep -qs UID_REV ~/.bc-gitlab-s09 || echo "export REV=$REV UID_REV=$UID_REV PID=$PID" >> ~/.bc-gitlab-s09
```

Igual que en la Semana 08: el token no se guarda en ningún archivo y, si cierras la terminal, repites este paso. `~/.bc-gitlab-s09` solo guarda identificadores.

**Verifica**:

```bash
curl -s -H "$HR" "$API/user" | jq -r .username                                # revisor-<tu-dominio>
curl -s -H "$H" "$API/projects/$P/merge_requests?state=opened" | jq length     # 0
```

---

## Paso 1: Lo que Auto DevOps dejó pendiente

**Por qué**: la teoría 01 explicó que `app` ha tenido pipelines de Auto DevOps sin runner. Los que se crearon hace menos de una hora siguen en cola. Un runner nuevo que acepta jobs sin etiquetas los recogería todos en cuanto se registre.

```bash
curl -s -H "$H" "$API/projects/$P/pipelines?per_page=100" \
  | jq -r 'group_by(.status) | map("\(.[0].status): \(length)") | .[]'
```

Verás sobre todo `failed`: son los que GitLab dio por perdidos. Cancela los que sigan vivos y deja Auto DevOps desactivado de forma explícita, para que no dependa de que GitLab lo apagara solo:

```bash
for id in $(curl -s -H "$H" "$API/projects/$P/pipelines?per_page=100" \
              | jq -r '.[] | select(.status | IN("created","pending","waiting_for_resource","running")) | .id'); do
  curl -s --request POST "$API/projects/$P/pipelines/$id/cancel" -H "$H" -o /dev/null -w "cancelado $id: %{http_code}\n"
done
curl -s --request PUT "$API/projects/$P" -H "$H" --data "auto_devops_enabled=false" | jq .auto_devops_enabled
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/pipelines?per_page=100" \
  | jq '[.[] | select(.status | IN("created","pending","waiting_for_resource","running"))] | length'   # 0
```

Si sale más de `0`, repite el bucle: solo mira los 100 más recientes.

---

## Paso 2: Que los jobs encuentren GitLab

**Por qué**: dentro de un contenedor, `localhost:8888` es el propio contenedor (teoría 03, apartado 2.6). Sin esto, el job `gobernanza` de la práctica 04 no llegaría a la API.

Necesita el token de administrador: las variables de instancia afectan a todos los proyectos.

```bash
HA="PRIVATE-TOKEN: ${GITLAB_ADMIN_TOKEN:?necesitas el token de administrador de la Semana 03}"
for kv in "CI_API_V4_URL=http://gitlab:8888/api/v4" "CI_SERVER_URL=http://gitlab:8888"; do
  curl -s --request POST "$API/admin/ci/variables" -H "$HA" \
    --data-urlencode "key=${kv%%=*}" --data-urlencode "value=${kv#*=}" \
    | jq -c '{key, value, protected, masked}'
done
unset HA
```

Ninguna es secreta: no van enmascaradas. Tampoco protegidas: tienen que llegar a cualquier pipeline.

**Verifica**:

```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_ADMIN_TOKEN" "$API/admin/ci/variables" | jq -r '.[] | select(.key | test("^CI_(API_V4|SERVER)_URL$")) | "\(.key)=\(.value)"'
# CI_API_V4_URL=http://gitlab:8888/api/v4
# CI_SERVER_URL=http://gitlab:8888
```

Si ya existían (`400 has already been taken`), comprueba que tienen esos valores y sigue.

---

## Paso 3: Crear el runner en GitLab

**Por qué**: con el flujo actual, el runner nace en GitLab con su configuración decidida, y lo que se registra después es una identidad concreta, no un permiso genérico.

```bash
RT=$(curl -s --request POST "$API/user/runners" -H "$H" \
  --data "runner_type=project_type" --data "project_id=$PID" \
  --data-urlencode "description=docker-app" \
  --data "tag_list=docker" --data "run_untagged=true" \
  | jq -r '.token // empty')
[ -n "$RT" ] && echo "token de runner recibido (${#RT} caracteres)" || echo "No se creó el runner: revisa que eres Maintainer de app"
```

`tag_list=docker` no lo usa nadie todavía: es la etiqueta que la Semana 15 usará para enrutar. `run_untagged=true` hace que recoja los jobs que no piden etiqueta, que son todos los de `app`.

El token **no** se imprime: solo su longitud. Va directo al paso siguiente, en la misma terminal.

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/runners?type=project_type" \
  | jq -r '.[] | "\(.id) \(.description) \(.status)"'
# 7 docker-app never_contacted
```

`never_contacted`: existe, pero ningún runner se ha presentado con su token.

---

## Paso 4: Registrarlo en el contenedor del compose

**Por qué**: el servicio `gitlab-runner` del perfil `base` lleva corriendo desde la Semana 01 sin hacer nada. `register` le da su primera configuración.

Desde la raíz de este repositorio, donde está `docker-compose.yml`:

```bash
cd /ruta/a/bc-gitlab
docker compose --profile base ps gitlab-runner --format '{{.Name}} {{.Status}}'   # gitlab-runner Up ...

CI_SERVER_TOKEN="$RT" docker compose exec -e CI_SERVER_TOKEN gitlab-runner \
  gitlab-runner register --non-interactive \
  --url http://gitlab:8888 --clone-url http://gitlab:8888 \
  --executor docker --docker-image alpine:3.24.2 \
  --docker-network-mode bc-gitlab-network --name docker-app
unset RT
```

```
Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!
```

**Verifica** la configuración, sin el token, y el estado en GitLab:

```bash
docker compose exec gitlab-runner grep -E '^concurrent|name|url|executor|image|network_mode|volumes' /etc/gitlab-runner/config.toml
curl -s -H "$H" "$API/projects/$P/runners?type=project_type" | jq -r '.[] | "\(.description) \(.status)"'
# docker-app online
```

Si sale `offline` o `never_contacted` tras un minuto: `docker compose logs --tail 20 gitlab-runner`.

---

## Paso 5: Un job de usar y tirar

**Por qué**: comprobar las tres cosas de la teoría 03 antes de depender de ellas: que el runner recoge el job, que el job clona, y que llega a la API por `http://gitlab:8888`.

En tu clon de `app`, en una rama que no va a llegar a ninguna parte:

```bash
git switch main && git pull --ff-only
git switch -c sonda-runner
cat > .gitlab-ci.yml <<'EOF'
workflow:
  rules:
    - if: $CI_COMMIT_BRANCH == "sonda-runner"

sonda:
  image: alpine:3.24.2
  script:
    - echo "API=$CI_API_V4_URL"
    - wget -S -O /dev/null "$CI_API_V4_URL/version" 2>&1 | head -2 || true
EOF
git add .gitlab-ci.yml
git commit -S -m "ci: sonda del runner"
git push -u origin sonda-runner
```

`|| true` porque el runner ejecuta el script con `pipefail`: `wget` devuelve error ante el `401` y el job fallaría aunque la prueba haya salido bien.

Espera unos 30 segundos (la primera vez, más: descarga `alpine` y la imagen *helper* del runner) y lee el log:

```bash
JOB=$(curl -s -H "$H" "$API/projects/$P/jobs?per_page=1" | jq -r '.[0].id')
curl -s -H "$H" "$API/projects/$P/jobs/$JOB" | jq -r '.status, .runner.description'
curl -s -H "$H" "$API/projects/$P/jobs/$JOB/trace" | sed 's/\x1b\[[0-9;]*m//g' | grep -A3 'API='
```

**Verifica**:

```
success
docker-app
API=http://gitlab:8888/api/v4
$ wget -S -O /dev/null "$CI_API_V4_URL/version" 2>&1 | head -2 || true
Connecting to gitlab:8888 (172.x.x.x:8888)
  HTTP/1.1 401 Unauthorized
```

`401` es el resultado bueno: el job llegó a la API y la API le pidió credenciales que no llevaba. Si dice `API=http://localhost:8888/api/v4`, el paso 2 no se aplicó. Si dice `bad address 'gitlab'`, el runner no conecta los jobs a la red del compose: revisa `network_mode`.

Borra la rama. El pipeline queda en la historia como prueba:

```bash
git switch main && git branch -D sonda-runner && git push origin --delete sonda-runner
```

---

## ✅ Resultado

- [ ] Ningún pipeline pendiente y `auto_devops_enabled` a `false`
- [ ] `CI_API_V4_URL` y `CI_SERVER_URL` como variables de instancia, apuntando a `http://gitlab:8888`
- [ ] Runner de proyecto `docker-app`, `online`
- [ ] El job `sonda` en `success`, ejecutado por `docker-app`, con `401` desde `gitlab:8888`
- [ ] La rama `sonda-runner` borrada

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `POST /user/runners` devuelve `403` | No eres Maintainer de `app`, o el token no tiene `api` ni `create_runner` | Usa tu token de propietario de la Semana 01 |
| `register` dice `401 Unauthorized` | El token del runner está mal copiado o ya se usó en otro `register` | Borra el runner (`DELETE /runners/<id>`) y repite los pasos 3 y 4 |
| El job se queda en `pending` | El runner no está `online`, o no acepta jobs sin etiquetas | Paso 4; `GET /runners/<id> \| jq .run_untagged` |
| `Cannot connect to the Docker daemon` en el log | El contenedor del runner no tiene el socket de Docker | Revisa el volumen `/var/run/docker.sock` del servicio en el compose |
| El job falla en `get_sources` con `Could not resolve host: localhost` o similar | Falta `--clone-url` | `docker compose exec gitlab-runner grep clone_url /etc/gitlab-runner/config.toml` |
| `toomanyrequests` al descargar la imagen | Límite de Docker Hub | Espera, o inicia sesión en Docker Hub en el host; el *dependency proxy* llega en la Semana 13 |

---

## 🔗 Navegación

[← Volver a la Semana 09](../README.md) · [Siguiente: El primer pipeline →](02-el-primer-pipeline.md)

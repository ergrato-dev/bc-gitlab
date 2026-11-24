# Práctica 04 — El ensayo de actualización

> Paras el laboratorio y levantas un segundo GitLab, desechable, en 19.1.10. Le siembras datos, haces el backup con sus secretos y lo subes a 19.2.4 cronometrando. Después compruebas lo que una actualización puede romper: los datos, una variable cifrada, las migraciones en segundo plano, una clave de `gitlab.rb` que ha cambiado de sitio, y un ajuste que ya no se deja guardar. Con lo que encuentres escribes el informe, que es el procedimiento de la actualización real. El laboratorio principal no cambia de versión.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 03 completada · Teoría [07](../1-teoria/07-actualizar-sin-perder-datos.md) leída · Unos 8 GB de disco libres

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | La versión del laboratorio anotada, y el laboratorio parado | `laboratorio-en-version-fijada` |
| 2 | La instancia de ensayo en 19.1.10 | — |
| 3 | Un token en el ensayo | — |
| 4 | Datos sembrados | — |
| 5 | El backup y los secretos | — |
| 6 | El salto a 19.2.4 | — |
| 7 | Datos y migraciones comprobados | — |
| 8 | El ajuste que no se deja guardar | — |
| 9 | El informe, en `infra/plataforma` | `informe-de-actualizacion` |
| 10 | El ensayo borrado y el laboratorio de vuelta | — |

> [!IMPORTANT]
> El ensayo y el laboratorio no caben a la vez en 16 GB. Mientras dure esta práctica, tu instancia de `localhost:8888` está parada.

---

## Paso 1: La versión de partida y parar el laboratorio

**Por qué**: el ensayo simula subir **tu** instancia. Lo primero es anotar en qué versión está, y lo último de la práctica, comprobar que sigue ahí.

```bash
source ~/.bc-gitlab; source ~/.bc-gitlab-s18
export H="PRIVATE-TOKEN: $GITLAB_TOKEN" API="$GITLAB_URL/api/v4"
curl -s -H "$H" "$API/version" | jq -r .version
# 19.2.4
cd /ruta/al/repositorio/bc-gitlab
docker compose --profile base --profile sso stop
k3d cluster stop bootcamp
mkdir -p ~/bc-s18/ensayo && chmod 700 ~/bc-s18 ~/bc-s18/ensayo
```

**Verifica**: `docker ps --format '{{.Names}}'` no lista `gitlab`, `keycloak` ni los nodos `k3d-bootcamp-*`.

---

## Paso 2: La instancia de ensayo

**Por qué**: una copia desechable, con sus propios volúmenes (`bc-gitlab-ensayo-*`), su puerto (`8889`) y su versión (`ENSAYO_VERSION`, en `.env`). El compose le pone a propósito una clave de `gitlab.rb` antigua, `nginx['client_max_body_size']`, como la que tendría una instancia que lleva años actualizándose.

```bash
grep -q '^ENSAYO_VERSION=' .env || grep '^ENSAYO_' .env.example >> .env
sed -i 's/^ENSAYO_VERSION=.*/ENSAYO_VERSION=19.1.10-ce.0/' .env
sed -i "s/^ENSAYO_ROOT_PASSWORD=.*/ENSAYO_ROOT_PASSWORD=$(openssl rand -hex 16)/" .env
docker compose --profile ensayo up -d gitlab-ensayo
until curl -sf -o /dev/null http://localhost:8889/-/readiness; do sleep 15; done; echo listo
```

El primer arranque tarda de 4 a 6 minutos. Mientras, lee la sección 2.5 de la teoría 07.

**Verifica**:

```bash
curl -s http://localhost:8889/-/readiness | jq -r .status
docker inspect gitlab-ensayo --format '{{.Config.Image}}'
```

`ok` y `gitlab/gitlab-ce:19.1.10-ce.0`.

---

## Paso 3: Un token en el ensayo

**Por qué**: para sembrar y comprobar por API. Se crea desde dentro, con `gitlab-rails runner`, porque la instancia no tiene a nadie más que `root` y no vas a configurarle 2FA a una máquina que borrarás en una hora. Caduca en dos días, y el archivo, en `chmod 600`.

```bash
docker compose --profile ensayo exec gitlab-ensayo gitlab-rails runner \
  't = User.find_by_username("root").personal_access_tokens.create!(name: "ensayo-s18",
     scopes: [:api, :admin_mode], expires_at: 2.days.from_now); puts t.token' > ~/bc-s18/ensayo/token
chmod 600 ~/bc-s18/ensayo/token
export EH="PRIVATE-TOKEN: $(cat ~/bc-s18/ensayo/token)" EAPI="http://localhost:8889/api/v4"
```

Tarda un minuto: `runner` arranca Rails entero.

**Verifica**:

```bash
curl -s -H "$EH" "$EAPI/version" | jq -r .version
```

`19.1.10`.

---

## Paso 4: Sembrar datos

**Por qué**: un ensayo con la instancia vacía no encuentra nada (teoría 07, antipatrones). Siembras lo mínimo que tiene que sobrevivir: un repositorio con commits y una etiqueta, un issue, y una variable de CI, que va cifrada con `gitlab-secrets.json`.

```bash
EG=$(curl -s --request POST "$EAPI/groups" -H "$EH" \
  --data name=ensayo --data path=ensayo --data visibility=private | jq -r .id)
curl -s --request POST "$EAPI/projects" -H "$EH" \
  --data name=app --data "namespace_id=$EG" --data initialize_with_readme=true | jq -r .path_with_namespace
EP=ensayo%2Fapp
curl -s --request POST "$EAPI/projects/$EP/repository/commits" -H "$EH" -H 'Content-Type: application/json' \
  -d '{"branch":"main","commit_message":"feat: semilla del ensayo",
       "actions":[{"action":"create","file_path":"semilla.txt","content":"sobrevive al salto\n"}]}' | jq -r .short_id
curl -s --request POST "$EAPI/projects/$EP/repository/tags" -H "$EH" --data tag_name=v0.0.1 --data ref=main | jq -r .name
curl -s --request POST "$EAPI/projects/$EP/issues" -H "$EH" --data "title=Issue de antes del salto" | jq -r .iid
curl -s --request POST "$EAPI/projects/$EP/variables" -H "$EH" \
  --data key=SEMILLA_SECRETA --data "value=$(openssl rand -hex 12)" --data masked=true | jq -r .key
curl -s -H "$EH" "$EAPI/projects/$EP/variables/SEMILLA_SECRETA" | jq -r .value > ~/bc-s18/ensayo/semilla
```

**Verifica**: un ID corto de commit, `v0.0.1`, `1`, `SEMILLA_SECRETA`, y el valor de la variable guardado en `~/bc-s18/ensayo/semilla` para compararlo después.

---

## Paso 5: El backup y los secretos

**Por qué**: la única vuelta atrás (teoría 07). Se hace en la versión de partida, justo antes del salto, y se copian fuera los dos archivos que el backup no lleva.

```bash
time docker compose --profile ensayo exec gitlab-ensayo gitlab-backup create STRATEGY=copy 2>&1 | tail -n 4
docker compose --profile ensayo exec gitlab-ensayo ls /var/opt/gitlab/backups/
```

Las últimas líneas te avisan: `Backup task is done.` y que `gitlab.rb` y `gitlab-secrets.json` contienen datos sensibles y **no** están en el backup. Cópialo todo fuera del contenedor:

```bash
B=$(docker compose --profile ensayo exec gitlab-ensayo ls /var/opt/gitlab/backups/ | tr -d '\r' | tail -n 1)
docker compose --profile ensayo cp "gitlab-ensayo:/var/opt/gitlab/backups/$B" ~/bc-s18/ensayo/
docker compose --profile ensayo cp gitlab-ensayo:/etc/gitlab/gitlab-secrets.json ~/bc-s18/ensayo/
chmod 600 ~/bc-s18/ensayo/*
ls -lh ~/bc-s18/ensayo/
```

**Verifica**: el nombre del `.tar` lleva `19.1.10`, y está junto a `gitlab-secrets.json`. Anota el tiempo que dio `time` para el informe. En el laboratorio, unos 30 segundos.

---

## Paso 6: El salto

**Por qué**: 19.2 es la siguiente parada obligatoria, así que de 19.1.10 se va directo (teoría 07). El salto es cambiar la versión exacta de la imagen y recrear el contenedor.

```bash
sed -i 's/^ENSAYO_VERSION=.*/ENSAYO_VERSION=19.2.4-ce.0/' .env
date +%T
docker compose --profile ensayo up -d gitlab-ensayo
until curl -sf -o /dev/null http://localhost:8889/-/readiness; do sleep 15; done; date +%T
```

**Verifica**:

```bash
curl -s -H "$EH" "$EAPI/version" | jq -r .version
docker compose --profile ensayo logs --no-log-prefix gitlab-ensayo | grep -A 2 '^Deprecations:'
```

`19.2.4`, y el aviso del `reconfigure`:

```
Deprecations:

nginx['client_max_body_size'] has been deprecated. Please use gitlab_rails['nginx']['client_max_body_size'] instead.
```

La diferencia entre las dos horas es la ventana de mantenimiento del ensayo: en el laboratorio, unos 3 minutos. La clave antigua aún funciona; en el informe, la clave nueva va como cambio obligatorio de la actualización real.

---

## Paso 7: Datos y migraciones

**Por qué**: que la instancia responda no significa que los datos estén bien. Cada cosa sembrada se comprueba, y la variable importa más que el resto: si se descifra, el `gitlab-secrets.json` y la base de datos siguen casando.

```bash
curl -s -H "$EH" "$EAPI/projects/$EP/repository/files/semilla.txt/raw?ref=v0.0.1"
curl -s -H "$EH" "$EAPI/projects/$EP/issues" | jq -r '.[].title'
[ "$(curl -s -H "$EH" "$EAPI/projects/$EP/variables/SEMILLA_SECRETA" | jq -r .value)" = "$(cat ~/bc-s18/ensayo/semilla)" ] \
  && echo "variable intacta"
```

Ahora las migraciones en segundo plano que trae 19.2:

```bash
curl -s -H "$EH" "$EAPI/admin/batched_background_migrations" | jq -r 'group_by(.status)[] | "\(length) \(.[0].status)"'
```

**Verifica**: `sobrevive al salto`, `Issue de antes del salto`, `variable intacta`. Las migraciones salen como `finished` y alguna `active`; repite el último comando cada minuto hasta que **todas** estén en `finished`. En el laboratorio fueron 10, y tardaron menos de 5 minutos. En producción pueden ser horas: es lo que impide el siguiente salto el mismo día.

---

## Paso 8: El ajuste que no se deja guardar

**Por qué**: el `reconfigure` revisa `gitlab.rb`, pero no lo que la versión anterior dejó guardado en la base de datos. La única forma de saberlo es usarla: un `PUT` cualquiera de ajustes.

```bash
curl -s --request PUT "$EAPI/application/settings" -H "$EH" --data signup_enabled=false | jq -c '.message // {signup_enabled}'
```

Si da `{"signup_enabled":false}`, no hay hallazgo: pasa al paso 9. En 19.2.4 el ensayo encuentra esto:

```
{"importers":["must be a valid json schema"]}
```

Ningún ajuste se puede guardar, ni por API ni desde `Admin → Settings`. La causa: 19.1 guardó la clave `import_jobs_concurrency_limit` dentro del campo `importers` de `application_settings`, el esquema JSON de 19.2 ya no la admite, y ninguna migración la quita.

```bash
docker compose --profile ensayo exec gitlab-ensayo gitlab-psql -d gitlabhq_production \
  -c "select importers from application_settings;"
```

> [!WARNING]
> El arreglo es un `UPDATE` a mano sobre la base de datos de GitLab. En el ensayo da igual; en producción se hace **solo** con el backup del paso 5 copiado fuera, y se apunta en el informe con la consulta exacta. Quita una clave y no toca nada más.

```bash
docker compose --profile ensayo exec gitlab-ensayo gitlab-psql -d gitlabhq_production \
  -c "update application_settings set importers = importers - 'import_jobs_concurrency_limit';"
# UPDATE 1
sleep 60
curl -s --request PUT "$EAPI/application/settings" -H "$EH" --data signup_enabled=false | jq -c '.message // {signup_enabled}'
```

**Verifica**: `{"signup_enabled":false}`. Si tu laboratorio principal se instaló en 19.2 desde cero, no tiene esa clave: por eso solo la encuentra el ensayo.

---

## Paso 9: El informe

**Por qué**: el ensayo solo vale si deja un procedimiento que otra persona pueda seguir en la actualización real. En el clon de `infra/plataforma`, `docs/actualizaciones/19.1-a-19.2.md`:

```markdown
# Actualización 19.1.10 → 19.2.4

Ensayo del <fecha> en una instancia desechable (perfil `ensayo`) con datos sembrados.

## Camino

19.1.10 → 19.2.4, directo: 19.2 es parada obligatoria. Comprobado en Upgrade Path.

## Antes

1. Todas las `batched_background_migrations` de la versión actual en `finished`.
2. `gitlab-backup create STRATEGY=copy` en 19.1.10: <tiempo> en el ensayo.
3. Copiar fuera del servidor el `.tar`, `gitlab-secrets.json` y `gitlab.rb`.

## Salto

- Cambiar la imagen a `gitlab/gitlab-ce:19.2.4-ce.0` y recrear: <minutos> hasta `/-/readiness` en `ok`.

## Después

- Versión: `GET /version` → 19.2.4.
- Datos: repositorio, etiqueta, issue y variable cifrada intactos.
- Migraciones: <n> `batched_background_migrations`, todas `finished` en <minutos>.

## Hallazgos

| Qué | Síntoma | Arreglo |
|---|---|---|
| Clave deprecada | `nginx['client_max_body_size'] has been deprecated` | Usar `gitlab_rails['nginx']['client_max_body_size']` |
| `importers` con una clave que 19.2 no admite | Todo `PUT application/settings` → `{"importers":["must be a valid json schema"]}` | `update application_settings set importers = importers - 'import_jobs_concurrency_limit';` con backup previo |

## Vuelta atrás

Restaurar el backup de 19.1.10 en una instancia 19.1.10 con su `gitlab-secrets.json`.
No se ha ensayado: Semana 22.
```

Rellena los `<…>` con lo que anotaste. Los hallazgos son los tuyos: si en tu ensayo no salió el de `importers`, la fila dice que se comprobó y no apareció.

```bash
cd /ruta/a/tus/clones/plataforma
git add docs/actualizaciones/19.1-a-19.2.md && git commit -S -m "docs: informe del ensayo de actualización de 19.1 a 19.2"
```

El `push` va en el paso 10: ahora mismo tu instancia está parada.

---

## Paso 10: Borrar el ensayo y volver

**Por qué**: el ensayo ocupa memoria y unos 5 GB de disco, y ya ha dado lo que tenía que dar. El backup se queda en `~/bc-s18/ensayo/` por si quieres restaurarlo en la Semana 22.

> [!WARNING]
> Se borran **por nombre** el contenedor y sus tres volúmenes. Nunca `docker compose down -v`: borraría también los volúmenes del laboratorio principal, con todo lo que llevas hecho desde la Semana 01.

```bash
cd /ruta/al/repositorio/bc-gitlab
docker compose --profile ensayo rm -sf gitlab-ensayo
docker volume rm bc-gitlab-ensayo-config bc-gitlab-ensayo-logs bc-gitlab-ensayo-data
sed -i 's/^ENSAYO_VERSION=.*/ENSAYO_VERSION=19.1.10-ce.0/' .env
unset EH EAPI
docker compose --profile base --profile sso up -d
until curl -sf -o /dev/null http://localhost:8888/-/readiness; do sleep 15; done; echo listo
k3d cluster start bootcamp
cd /ruta/a/tus/clones/plataforma && git push
```

`ENSAYO_VERSION` vuelve a 19.1.10 para que el próximo ensayo empiece donde este.

**Verifica**:

```bash
curl -s -H "$H" "$API/version" | jq -r .version
docker volume ls --format '{{.Name}}' | grep -c ensayo
```

`19.2.4` y `0`.

---

## ✅ Resultado

- [ ] El laboratorio sigue en 19.2.4 y está de vuelta, con `base` y `sso`
- [ ] Has hecho un backup con su `gitlab-secrets.json` y sabes cuánto tardó
- [ ] El ensayo subió a 19.2.4 con los datos y la variable cifrada intactos
- [ ] Has esperado a que las migraciones en segundo plano terminasen
- [ ] Has encontrado la clave deprecada y el ajuste que no se dejaba guardar
- [ ] `docs/actualizaciones/19.1-a-19.2.md` en `main` de `infra/plataforma`
- [ ] El ensayo y sus volúmenes, borrados

```bash
./scripts/verificar-semana.sh 18
```

En esta práctica pasan `informe-de-actualizacion` y `laboratorio-en-version-fijada`. Con eso, las 17 de las prácticas; la 18 es el proyecto.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| El ensayo no llega a `readiness` y el sistema va lento | El laboratorio sigue en marcha | Paso 1: `stop` de `base` y `sso` |
| `bind: address already in use` en el 8889 | Otro proceso usa el puerto | Cámbialo en el compose solo para ti, o libera el puerto |
| `gitlab-rails runner` no imprime el token | Rails aún arrancando | Espera a `readiness` y repite |
| La variable no coincide tras el salto | `gitlab-secrets.json` cambió: el volumen de configuración se recreó | No borres `bc-gitlab-ensayo-config` entre pasos; restaura con el backup y los secretos |
| Migraciones en `failed` | Una migración falló a mitad | `Admin → Monitoring → Background migrations`, *Retry*; si vuelve a fallar, es un hallazgo del informe |
| `Error response from daemon: remove bc-gitlab-ensayo-data: volume is in use` | El contenedor no se borró | `docker compose --profile ensayo rm -sf gitlab-ensayo` antes del `volume rm` |
| `git push` rechazado al final | Tu instancia aún arranca | Espera a `readiness` |

---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| [Práctica 03 — Límites y superficie](03-limites-y-superficie.md) | [Proyecto de la semana](../3-proyecto/README.md) |

# Práctica 01 — El registry y el Dockerfile

> Compruebas que el registry de tu instancia responde con el nombre que ve el host, subes y borras una imagen desde tu terminal, ves con tus ojos la trampa del realm, y `app` gana su `Dockerfile` por merge request. Antes de que exista la primera imagen de versión, proteges los tags que la nombrarán.

**Duración estimada**: 50 min
**Prerrequisitos**: Semana 12 completada · Teoría [01](../1-teoria/01-el-container-registry.md), [02](../1-teoria/02-construir-sin-privilegios.md) y [03](../1-teoria/03-etiquetas-y-proteccion.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 0 | Variables, el token de `revisor` y las funciones de siempre | — |
| 1 | El registry en `localhost:5050` | — |
| 2 | Una imagen subida y borrada desde tu terminal | — |
| 3 | `Dockerfile` y `.dockerignore` en `main` de `app` | `dockerfile-en-main` |
| 4 | La trampa del realm, vista | — |
| 5 | Los tags de versión de la imagen, protegidos | `tags-de-imagen-protegidos` |

---

## Paso 0: Preparar el terreno

**Por qué**: esta semana vuelve a haber merge requests en `app` y en `ci/componentes` que necesitan la aprobación de `revisor`, y el proyecto de la Semana 12 revocó su token. Las mismas funciones, con un token nuevo y su archivo de identificadores fuera del repositorio.

```bash
source ~/.bc-gitlab
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
export HA="PRIVATE-TOKEN: ${GITLAB_ADMIN_TOKEN:-$GITLAB_TOKEN}"
export GRUPO=${PROYECTO%%/*}
export PI=$(printf '%s' "$GRUPO/infra/entornos" | jq -sRr @uri)
export PC=$(printf '%s' "$GRUPO/ci/componentes" | jq -sRr @uri)
export REV=revisor-<tu-dominio>
export UID_REV=$(curl -s -H "$H" "$API/users?username=$REV" | jq -r '.[0].id // empty')
[[ "$UID_REV" =~ ^[0-9]+$ ]] || { echo "Falta $REV: NO sigas"; return 1 2>/dev/null || exit 1; }

T_REV=$(curl -s --request POST "$API/users/$UID_REV/personal_access_tokens" -H "$HA" \
  --data-urlencode "name=flujo-s13" --data-urlencode "scopes[]=api" \
  --data-urlencode "expires_at=$(date -d '+7 days' +%F)" | jq -r '.token')
[ -n "$T_REV" ] && [ "$T_REV" != null ] || { echo "No se creó el token: revisa GITLAB_ADMIN_TOKEN y NO sigas"; return 1 2>/dev/null || exit 1; }
export HR="PRIVATE-TOKEN: $T_REV"
grep -qs GRUPO ~/.bc-gitlab-s13 || echo "export GRUPO=$GRUPO PI=$PI PC=$PC REV=$REV UID_REV=$UID_REV" >> ~/.bc-gitlab-s13

esperar() {   # espera a que un pipeline termine y escribe su estado
  until curl -s -H "$H" "$API/projects/$1/pipelines/$2" \
          | jq -e '.status | IN("success","failed","canceled","skipped")' > /dev/null; do sleep 10; done
  curl -s -H "$H" "$API/projects/$1/pipelines/$2" | jq -r .status
}

fusionar() {   # $1 = proyecto, $2 = MR: aprueba como revisor, relanza y fusiona si gobernanza está en verde
  local PR=$1 MR=$2 PIPE SHA
  curl -s --request POST "$API/projects/$PR/merge_requests/$MR/approve" -H "$HR" > /dev/null
  PIPE=$(curl -s --request POST "$API/projects/$PR/merge_requests/$MR/pipelines" -H "$H" | jq -r .id)
  esperar "$PR" "$PIPE" > /dev/null
  curl -s -H "$H" "$API/projects/$PR/pipelines/$PIPE/jobs" \
    | jq -e '.[] | select(.name == "gobernanza") | .status == "success"' > /dev/null \
    || { echo "gobernanza no está en verde en el pipeline $PIPE: lee su log"; return 1; }
  SHA=$(curl -s -H "$H" "$API/projects/$PR/merge_requests/$MR" | jq -r .sha)
  curl -s --request PUT "$API/projects/$PR/merge_requests/$MR/merge" -H "$H" \
    --data-urlencode "sha=$SHA" --data-urlencode "squash=true" | jq '{state, squash_commit_sha}'
}
```

**Verifica**:

```bash
curl -s -H "$HR" "$API/user" | jq -r .username                                # revisor-<tu-dominio>
curl -s -H "$H" "$API/projects/$P/merge_requests?state=opened" | jq length     # 0
type esperar fusionar | grep -c function                                     # 2
```

---

## Paso 1: El registry, con el nombre del host

**Por qué**: el registry lleva encendido desde la Semana 01, pero hasta hoy nadie lo usó. La versión del `docker-compose.yml` con la que empezaste quizá lo anunciaba como `gitlab:5050`, un nombre que tu host no resuelve: ni `docker login` ni el runner podrían usarlo (teoría 01, apartado 2.3).

```bash
curl -s -H "$H" "$API/projects/$P" | jq -r .container_registry_image_prefix
curl -sI http://localhost:5050/v2/ | grep -i www-authenticate
```

**Verifica**: `localhost:5050/plataforma-<tu-dominio>/app`, y un `realm="http://localhost:8888/jwt/auth"`.

Si el prefijo empieza por `gitlab:5050`, tu `docker-compose.yml` es anterior a esta semana. Actualiza el repositorio del bootcamp y recrea solo el contenedor de GitLab:

```bash
cd /ruta/a/bc-gitlab && git pull --ff-only
grep -n "registry_external_url" docker-compose.yml       # 'http://localhost:${REGISTRY_PORT:-5050}'
docker compose --profile base up -d gitlab
until [ "$(docker inspect -f '{{.State.Health.Status}}' gitlab)" = healthy ]; do sleep 10; done
```

Tarda unos minutos: `gitlab-ctl reconfigure` corre al arrancar. Vuelve a lanzar las dos comprobaciones.

---

## Paso 2: Subir y borrar desde tu terminal

**Por qué**: antes de que lo haga un job, compruebas que la cadena entera funciona desde el host: el 401, el realm, el token y la subida. Con un token propio, de dos días, que solo sirve para el registry. Lo crea el token de administración, como el de `revisor`: `POST /user/personal_access_tokens`, el de "para mí mismo", solo admite scopes de Kubernetes y responde `scopes does not have a valid value`.

```bash
YO=$(curl -s -H "$H" "$API/user" | jq -r .id)
T_REG=$(curl -s --request POST "$API/users/$YO/personal_access_tokens" -H "$HA" \
  --data-urlencode "name=registry-s13" \
  --data-urlencode "scopes[]=read_registry" --data-urlencode "scopes[]=write_registry" \
  --data-urlencode "expires_at=$(date -d '+2 days' +%F)" | jq -r .token)
export DOCKER_CONFIG=$(mktemp -d)        # las credenciales no se quedan en ~/.docker
printf '%s' "$T_REG" | docker login localhost:5050 -u "$(curl -s -H "$H" "$API/user" | jq -r .username)" --password-stdin

IMG=localhost:5050/$PROYECTO/prueba:1
docker pull -q alpine:3.24.2 && docker tag alpine:3.24.2 "$IMG" && docker push -q "$IMG"
curl -s -H "$H" "$API/projects/$P/registry/repositories?tags=true" | jq -c '.[] | {id, location, tags: [.tags[].name]}'
```

**Verifica**: `Login Succeeded`, y un repositorio `…/app/prueba` con el tag `1`. Es una subruta del registry de `app` (teoría 01, apartado 2.1).

Ahora bórralo, con el repositorio entero, y deja la terminal limpia:

```bash
RID=$(curl -s -H "$H" "$API/projects/$P/registry/repositories" | jq -r '.[] | select(.path | endswith("/prueba")) | .id')
curl -s --request DELETE "$API/projects/$P/registry/repositories/$RID" -H "$H" -o /dev/null -w '%{http_code}\n'   # 202
docker logout localhost:5050 && rm -rf "$DOCKER_CONFIG" && unset DOCKER_CONFIG
docker rmi -f "$IMG" > /dev/null
```

`T_REG` caduca en dos días; el proyecto lo revoca con el de `revisor`. No lo guardes en ningún sitio. Un día no basta: GitLab caduca el token al empezar ese día en UTC, y si tu reloj va por detrás nace ya caducado (`"active": false`).

---

## Paso 3: El `Dockerfile` de `app`, por merge request

**Por qué**: el `Dockerfile` es código de `app`: se revisa, lo audita `gobernanza` y vive en la raíz (Semana 04). Lo pruebas en local antes de abrir la merge request.

```bash
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Dockerfile de app" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=Imagen mínima, sin dependencias de ejecución, que carga cada módulo de src. Ver Semana 13." \
  | jq -r .iid)
git switch -c "$IID-dockerfile"

cat > Dockerfile <<'EOF'
# Imagen de app. Sin RUN: app no tiene dependencias en ejecución. Ver Semana 13, teoría 02.
FROM node:22.23.3-alpine3.24
WORKDIR /app
COPY package.json ./
COPY src/ ./src/
USER node
CMD ["node", "--experimental-strip-types", "--input-type=module", "-e", "import { readdirSync } from 'node:fs'; for (const f of readdirSync('src')) console.log(f, Object.keys(await import('./src/' + f)))"]
EOF

cat > .dockerignore <<'EOF'
# Lo que no se nombra aquí no entra en la imagen.
*
!package.json
!src/
src/*.test.ts
EOF

docker build -q -t app-local . && docker run --rm app-local
```

**Verifica**: una línea por cada módulo de `src/`, con sus funciones exportadas, y **ningún** `.test.ts`. Si un archivo falla al importarse, la imagen no arranca: arréglalo antes de seguir.

La construcción local usa tu Docker; la del pipeline usará kaniko. Compruébalo con la misma herramienta, sin subir nada:

```bash
docker run --rm -v "$PWD:/w" ghcr.io/osscontainertools/kaniko:v1.29.0-debug --context /w --no-push 2>&1 | tail -1
docker rmi app-local > /dev/null
```

`Skipping push to container registry due to --no-push flag`. Ahora, la merge request:

```bash
git add Dockerfile .dockerignore
git commit -S -m "build: Dockerfile mínimo de app"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="build: Dockerfile mínimo de app" \
  -o merge_request.description="Closes #$IID"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
fusionar "$P" "$MR"
git switch main && git pull --ff-only
```

**Verifica**: `state: merged`, y `Dockerfile` y `.dockerignore` en `main`.

---

## Paso 4: La trampa, vista

**Por qué**: dentro de un job, `localhost` es el propio job. Lo compruebas reproduciendo lo que haría un job ingenuo: kaniko en la red del compose, con usuario y contraseña. No sube nada, y no hace falta pipeline.

```bash
D=$(mktemp -d)
printf '{"auths":{"gitlab:5050":{"auth":"%s"}}}' "$(printf 'x:%s' "$T_REG" | base64 -w0)" > "$D/config.json"
docker run --rm --network bc-gitlab-network -v "$PWD:/w" -v "$D:/kaniko/.docker" \
  ghcr.io/osscontainertools/kaniko:v1.29.0-debug \
  --context /w --destination "gitlab:5050/$PROYECTO:trampa" --insecure 2>&1 | grep -o 'Get "http://localhost[^"]*"[^,]*refused' | head -1
rm -rf "$D"
```

**Verifica**: `Get "http://localhost:8888/jwt/auth?…": dial tcp [::1]:8888: connect: connection refused`. El registry respondió desde `gitlab:5050`, pero mandó a kaniko a pedir el token a `localhost:8888`. La práctica 02 lo resuelve dentro del componente (teoría 02, apartado 2.4).

---

## Paso 5: Proteger los tags de versión

**Por qué**: la primera imagen `0.2.0` llega en el proyecto de esta semana. La regla tiene que existir antes, para que ni siquiera la primera la pueda subir un Developer (teoría 03, apartado 2.4).

```bash
curl -s --request POST "$API/projects/$P/registry/protection/tag/rules" -H "$H" -H "Content-Type: application/json" \
  -d '{"tag_name_pattern": "^[0-9]+\\.[0-9]+\\.[0-9]+$",
       "minimum_access_level_for_push": "maintainer",
       "minimum_access_level_for_delete": "maintainer"}' \
  | jq -c '{tag_name_pattern, minimum_access_level_for_push, minimum_access_level_for_delete}'
```

**Verifica**: la regla con `maintainer` en los dos niveles. Si responde `404`, la base de metadatos del registry no está activa (teoría 01, apartado 2.5).

---

## ✅ Checklist

- [ ] `container_registry_image_prefix` empieza por `localhost:5050`
- [ ] Subiste y borraste una imagen con un PAT de solo registry
- [ ] `Dockerfile` y `.dockerignore` en `main` de `app`, por merge request
- [ ] Viste el `connection refused` de kaniko contra `localhost:8888`
- [ ] Regla de tags protegidos para semver, Maintainer para subir y borrar

---

## 🧯 Problemas frecuentes

| Síntoma | Causa | Solución |
|---|---|---|
| `docker login` responde `connection refused` | El puerto `5050` no está publicado, o GitLab aún arranca | `docker compose ps`; espera a `healthy` |
| `docker login` cuelga y acaba en `no such host` | El registry se anuncia como `gitlab:5050` | Paso 1: compose actualizado y `up -d gitlab` |
| `http: server gave HTTP response to HTTPS client` | Usas un nombre que no es `localhost` | `localhost:5050`: el daemon solo admite HTTP en `127.0.0.0/8` |
| `denied: requested access to the resource is denied` al subir | El PAT no tiene `write_registry` | Crea otro con los dos scopes |
| `docker run app-local` falla con `ERR_MODULE_NOT_FOUND` | Un módulo importa algo que el `.dockerignore` deja fuera | Añádelo a la lista, con `!` |
| La regla responde `400` | Falta uno de los dos niveles de acceso | Los dos son obligatorios |

---

[Volver a la Semana 13](../README.md) · [Siguiente: El componente imagen →](02-el-componente-imagen.md)

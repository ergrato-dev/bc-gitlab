# Práctica 02 — El componente `imagen`

> Construir una imagen con kaniko, con la trampa del realm resuelta, son quince líneas que nadie quiere escribir dos veces. Las escribes una vez, como tercer componente de `ci/componentes`, probado en su propio pipeline contra una imagen mínima. Publicas `1.2.0`, y `app` construye y sube su imagen en cada commit de `main` con cinco líneas de `include`.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 01 completada · Teoría [02](../1-teoria/02-construir-sin-privilegios.md) y [03](../1-teoria/03-etiquetas-y-proteccion.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | La imagen mínima de prueba en `ci/componentes` | — |
| 2 | `templates/imagen.yml` | `componente-imagen` |
| 3 | `ci/componentes` construyendo, subiendo y arrancando su imagen de prueba | — |
| 4 | La merge request fusionada y `main` en verde | `componentes-sigue-en-verde` |
| 5 | `1.2.0` publicada en el catálogo | `imagen-publicada` |
| 6 | `app` consumiendo `imagen@1` | `app-usa-imagen`, `imagen-por-sha` |

Si has cerrado la terminal, repite el paso 0 de la práctica 01 y `source ~/.bc-gitlab-s13`.

---

## Paso 1: Lo que se va a construir en la prueba

**Por qué**: un componente se prueba en su propio pipeline (Semana 12, teoría 06). Para `imagen`, la prueba es una imagen que no depende de npm ni de `app`: un archivo de texto sobre Alpine. Si se construye, se sube y arranca, el componente funciona.

```bash
cd /ruta/a/tus/clones/componentes && git switch main && git pull --ff-only
IIDC=$(curl -s --request POST "$API/projects/$PC/issues" -H "$H" \
  --data-urlencode "title=Componente imagen: construir y subir con kaniko" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=Tercer componente. Kaniko sin privilegios, token del registry pedido por el job. Ver Semana 13." \
  | jq -r .iid)
git switch -c "$IIDC-componente-imagen"

mkdir -p tests/imagen
cat > tests/imagen/Dockerfile <<'EOF'
# Imagen mínima con la que ci/componentes prueba el componente imagen.
FROM alpine:3.24.2
COPY prueba.txt /prueba.txt
EOF
echo "la imagen de prueba arranca" > tests/imagen/prueba.txt
```

---

## Paso 2: `templates/imagen.yml`

**Por qué**: todo lo que cambia entre consumidores es un input; todo lo demás, incluida la trampa del realm, queda dentro (teoría 02, apartado 2.4). `registro` e `inseguro` son las dos únicas concesiones al laboratorio, y por defecto valen lo que valdrían en producción.

```bash
cat > templates/imagen.yml <<'EOF'
spec:
  inputs:
    contexto:
      description: Carpeta que se envía a kaniko, relativa a la raíz del repositorio
      default: "."
    dockerfile:
      description: Dockerfile, relativo al contexto
      default: Dockerfile
    nombre:
      description: Subruta de la imagen dentro del registry del proyecto; vacío para la raíz
      default: ""
    stage:
      description: Stage en el que se construye
      default: package
    needs:
      description: Jobs que tienen que terminar antes
      type: array
      default: []
    rutas:
      description: Rutas que, si cambian en una merge request, obligan a construir la imagen
      type: array
      default: [Dockerfile, .dockerignore, package.json, src/**/*]
    registro:
      description: Registry visto desde el job. Solo cambia si el job no llega a $CI_REGISTRY
      default: $CI_REGISTRY
    inseguro:
      description: Registry por HTTP, sin TLS. Solo laboratorio
      type: boolean
      default: false
---
imagen:
  stage: $[[ inputs.stage ]]
  needs: $[[ inputs.needs ]]
  image:
    name: ghcr.io/osscontainertools/kaniko:v1.29.0-debug
    entrypoint: [""]
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: never
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        paths: $[[ inputs.rutas ]]
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_TAG
  variables:
    NOMBRE: $[[ inputs.nombre ]]
    REGISTRO: $[[ inputs.registro ]]
  script:
    - |
      if [ "$CI_PIPELINE_SOURCE" = merge_request_event ]; then
        /kaniko/executor --context "$CI_PROJECT_DIR/$[[ inputs.contexto ]]" --dockerfile "$CI_PROJECT_DIR/$[[ inputs.contexto ]]/$[[ inputs.dockerfile ]]" --no-push
        exit 0
      fi
    - RUTA="${CI_REGISTRY_IMAGE#"$CI_REGISTRY"/}${NOMBRE:+/$NOMBRE}"
    - >-
      TOKEN=$(wget -qO- --header "Authorization: Basic $(printf 'gitlab-ci-token:%s' "$CI_JOB_TOKEN" | base64 | tr -d '\n')"
      "$CI_SERVER_URL/jwt/auth?service=container_registry&scope=repository:$RUTA:push,pull"
      | sed -E 's/.*"token":"([^"]+)".*/\1/')
    - '[ -n "$TOKEN" ] || { echo "El registry no ha dado token para $RUTA"; exit 1; }'
    - printf '{"auths":{"%s":{"registrytoken":"%s"}}}' "$REGISTRO" "$TOKEN" > /kaniko/.docker/config.json
    - DESTINOS="--destination $REGISTRO/$RUTA:$CI_COMMIT_SHORT_SHA"
    - if [ -n "$CI_COMMIT_TAG" ]; then DESTINOS="$DESTINOS --destination $REGISTRO/$RUTA:${CI_COMMIT_TAG#v}"; fi
    - >-
      /kaniko/executor
      --context "$CI_PROJECT_DIR/$[[ inputs.contexto ]]"
      --dockerfile "$CI_PROJECT_DIR/$[[ inputs.contexto ]]/$[[ inputs.dockerfile ]]"
      $DESTINOS
      --label org.opencontainers.image.revision=$CI_COMMIT_SHA
      --label org.opencontainers.image.source=$CI_PROJECT_URL
      --digest-file imagen.digest
      $([ "$[[ inputs.inseguro ]]" = true ] && echo --insecure)
    - echo "Subida $CI_REGISTRY/$RUTA@$(cat imagen.digest)"
EOF
```

Lo que conviene mirar dos veces:

| Línea | Por qué así |
|---|---|
| `--dockerfile "$CI_PROJECT_DIR/…/…"` | Kaniko resuelve un `--dockerfile` relativo desde el directorio del job, no desde el contexto. Con `tests/imagen` como contexto, cogería el `Dockerfile` de la raíz |
| La rama de `merge_request_event` | Construye para saber que funciona; no sube código sin revisar (teoría 03, apartado 2.1) |
| `TOKEN=$(…)` en un bloque `>-` | La línea lleva `: ` dentro: sin el bloque, YAML la lee como un mapa y el pipeline no se crea |
| `'[ -n "$TOKEN" ] …'` entre comillas | Lo mismo, por las llaves |
| `RUTA` desde `CI_REGISTRY_IMAGE` | Minúsculas garantizadas (teoría 02, apartado 3) |
| Sin `default`, sin `variables` globales | Un componente no toca el pipeline de quien lo usa (Semana 12, teoría 04) |

---

## Paso 3: `ci/componentes` se prueba a sí mismo

**Por qué**: el mismo `include` en el SHA del commit que usaste para `npm` y `gobernanza`. Con un contexto y una subruta que **no** son los de por defecto, para probar los inputs, y un segundo job que arranca la imagen recién subida: si el runner no puede descargarla, lo sabes aquí y no en `app`.

En `.gitlab-ci.yml` de `ci/componentes`, un tercer `include` y un job:

```yaml
  - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/imagen@$CI_COMMIT_SHA
    inputs:
      contexto: tests/imagen
      nombre: prueba
      stage: build
      rutas:
        - templates/imagen.yml
        - tests/imagen/**/*
        - .gitlab-ci.yml
      registro: gitlab:5050      # solo laboratorio: el registry visto desde la red del compose
      inseguro: true             # solo laboratorio: HTTP

imagen-arranca:
  stage: test
  needs: [imagen]
  image: $CI_REGISTRY_IMAGE/prueba:$CI_COMMIT_SHORT_SHA
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_TAG
  variables:
    GIT_STRATEGY: none
  script:
    - cat /prueba.txt
```

Y una sección en el README de `ci/componentes`, que el catálogo enseña como portada:

```bash
cat >> README.md <<'EOF'

## imagen

Construye el `Dockerfile` con kaniko, sin runner privilegiado, y lo sube al registry del proyecto que lo usa.
En una merge request solo construye. En la rama por defecto sube `:<SHA corto>`; en un tag, además, `:<tag sin v>`.

| Input | Por defecto | Para qué |
|---|---|---|
| `contexto` | `.` | Carpeta del build |
| `dockerfile` | `Dockerfile` | Relativo al contexto |
| `nombre` | vacío | Subruta de la imagen |
| `stage` / `needs` | `package` / `[]` | Dónde va en tu pipeline |
| `rutas` | `Dockerfile`, `.dockerignore`, `package.json`, `src/**/*` | Qué cambios de una MR obligan a construir |
| `registro` / `inseguro` | `$CI_REGISTRY` / `false` | Solo si tus jobs no llegan al registry por su nombre público |
EOF
```

Aquí no hay lint que valga contra `main`: el `include` pide `imagen` en el SHA de `main`, que todavía no tiene `templates/imagen.yml`, y respondería `content not found`. Lo prueba el pipeline de la merge request, con el SHA de la rama.

---

## Paso 4: La merge request

```bash
git add templates/imagen.yml tests/imagen .gitlab-ci.yml README.md
git commit -S -m "feat: componente imagen, con kaniko y sin privilegios"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="feat: componente imagen" \
  -o merge_request.description="Closes #$IIDC"
MRC=$(curl -s -H "$H" "$API/projects/$PC/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
fusionar "$PC" "$MRC"
git switch main && git pull --ff-only
PIPE=$(curl -s -H "$H" "$API/projects/$PC/pipelines?ref=main&source=push&per_page=1" | jq -r '.[0].id')
esperar "$PC" "$PIPE"
curl -s -H "$H" "$API/projects/$PC/pipelines/$PIPE/jobs" | jq -r 'sort_by(.id) | .[] | "\(.stage)\t\(.name)\t\(.status)"'
```

**Verifica**: `state: merged` y `success`, con `imagen` en `build` e `imagen-arranca` en `test`. En el log de la merge request, `imagen` dijo `Skipping push … due to --no-push flag`; en el de `main`, `Subida localhost:5050/…/ci/componentes/prueba@sha256:…`; y `imagen-arranca` escribió `la imagen de prueba arranca`.

---

## Paso 5: `1.2.0`

**Por qué**: un componente nuevo no rompe a nadie que no lo use: es una *minor* (Semana 12, teoría 06). En la Semana 12 publicaste `1.0.0` y `1.1.0`.

```bash
git tag -s 1.2.0 -m "1.2.0: componente imagen"
git push origin 1.2.0
sleep 10
PIPE=$(curl -s -H "$H" "$API/projects/$PC/pipelines?ref=1.2.0&per_page=1" | jq -r '.[0].id')
esperar "$PC" "$PIPE"
jq -n '{query: "{ ciCatalogResources(search: \"componentes\") { nodes { versions(first: 1) { nodes { name components { nodes { name } } } } } } }"}' \
  | curl -s "$GITLAB_URL/api/graphql" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -c '.data.ciCatalogResources.nodes[].versions.nodes[] | {name, c: [.components.nodes[].name]}'
```

**Verifica**: `success` y `{"name":"1.2.0","c":["gobernanza","imagen","npm"]}`, en cualquier orden. El pipeline del tag subió además `ci/componentes/prueba:1.2.0`.

---

## Paso 6: `app` construye su imagen

**Por qué**: con el componente publicado, la imagen de `app` son cinco líneas. `needs: [build, test]`: no se sube una imagen de código que no pasa los tests.

```bash
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Construir y subir la imagen de app" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=Componente imagen@1 de ci/componentes. SHA corto en main, versión en tags. Ver Semana 13." \
  | jq -r .iid)
git switch -c "$IID-imagen"
```

En `.gitlab-ci.yml`, debajo de los dos componentes que ya tienes:

```yaml
  - component: $CI_SERVER_FQDN/plataforma-<tu-dominio>/ci/componentes/imagen@1
    inputs:
      needs: [build, test]
      registro: gitlab:5050      # solo laboratorio: el registry visto desde la red del compose
      inseguro: true             # solo laboratorio: HTTP
```

```bash
git add .gitlab-ci.yml
git commit -S -m "ci: construir y subir la imagen con el componente imagen"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="ci: construir y subir la imagen" \
  -o merge_request.description="Closes #$IID"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
fusionar "$P" "$MR"
git switch main && git pull --ff-only
PIPE=$(curl -s -H "$H" "$API/projects/$P/pipelines?ref=main&source=push&per_page=1" | jq -r '.[0].id')
esperar "$P" "$PIPE"
curl -s -H "$H" "$API/projects/$P/registry/repositories?tags=true" | jq -c '.[] | {location, tags: [.tags[].name]}'
```

**Verifica**: `success`, y `localhost:5050/plataforma-<tu-dominio>/app` con un tag igual a `git rev-parse --short=8 HEAD`. Esta merge request **no** construyó la imagen: solo cambió `.gitlab-ci.yml`, que no está en las `rutas` por defecto.

La prueba de que arranca, desde tu terminal, con un token de solo lectura que caduca en dos días:

```bash
YO=$(curl -s -H "$H" "$API/user" | jq -r .id)
T_LEC=$(curl -s --request POST "$API/users/$YO/personal_access_tokens" -H "$HA" \
  --data-urlencode "name=registry-s13" --data-urlencode "scopes[]=read_registry" \
  --data-urlencode "expires_at=$(date -d '+2 days' +%F)" | jq -r .token)
export DOCKER_CONFIG=$(mktemp -d)
printf '%s' "$T_LEC" | docker login localhost:5050 -u "$(curl -s -H "$H" "$API/user" | jq -r .username)" --password-stdin
docker run --rm "localhost:5050/$PROYECTO:$(git rev-parse --short=8 HEAD)"
docker inspect --format '{{json .Config.Labels}}' "localhost:5050/$PROYECTO:$(git rev-parse --short=8 HEAD)"
docker logout localhost:5050 && rm -rf "$DOCKER_CONFIG" && unset DOCKER_CONFIG T_LEC
```

**Verifica**: los módulos de `src/` con sus funciones, como en la práctica 01, y las dos etiquetas OCI con el SHA completo de `HEAD` y la URL de `app`.

---

## ✅ Checklist

- [ ] `templates/imagen.yml` con sus ocho inputs, y `ci/componentes` probándolo con valores que no son los de por defecto
- [ ] `imagen-arranca` en verde en `main` de `ci/componentes`
- [ ] `1.2.0` en el catálogo, con tres componentes
- [ ] `app` con `imagen@1`, y su imagen etiquetada con el SHA corto en el registry
- [ ] La imagen arranca en tu máquina, descargada con un token de solo lectura

---

## 🧯 Problemas frecuentes

| Síntoma | Causa | Solución |
|---|---|---|
| `dial tcp [::1]:8888: connect: connection refused` | El job usa usuario y contraseña en vez de `registrytoken` | El `config.json` del paso 2, tal cual |
| `El registry no ha dado token para …` | `CI_SERVER_URL` no llega a GitLab desde el job | La variable de instancia de la Semana 09: `http://gitlab:8888` |
| `failed to get fileinfo for …/tests/imagen/package.json` | `--dockerfile` relativo: kaniko leyó el `Dockerfile` de la raíz | La ruta completa, con `$CI_PROJECT_DIR` |
| `http: server gave HTTP response to HTTPS client` en `imagen` | Falta `inseguro: true` | El input, solo en el laboratorio |
| El pipeline no se crea: `` `needs` input: provided value is not an array `` | `needs: build` | `needs: [build, test]` |
| `Component '…/imagen@1' - content not found` | `app` pide `imagen@1` antes de que `1.2.0` esté publicada | El paso 5 primero, y que su pipeline termine en verde |

---

[← Anterior: El registry y el Dockerfile](01-el-registry-y-el-dockerfile.md) · [Volver a la Semana 13](../README.md) · [Siguiente: Limpieza y dependency proxy →](03-limpieza-y-dependency-proxy.md)

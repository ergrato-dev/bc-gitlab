# Práctica 04 — El paquete por SHA

> Desde la Semana 11, `infra/entornos` descarga el `.tgz` de `app` del artefacto de un job, cuyo ID le llega por variable, y el artefacto caduca en una semana. Hoy `app` publica el `.tgz` en su registro de paquetes con el SHA del commit como versión, e `infra/entornos` lo descarga con el `APP_SHA` que ya recibía. Una variable menos en el disparo, y un binario que sigue ahí dentro de un año.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 03 completada · Teoría [05](../1-teoria/05-el-registro-de-paquetes.md), [07](../1-teoria/07-permisos-y-job-token.md) y [08](../1-teoria/08-que-binario-va-donde.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | Duplicados prohibidos en el grupo, salvo las versiones por SHA | `duplicados-solo-por-sha` |
| 2 | `infra/entornos` descargando del registro de paquetes | `infra-baja-del-registry` |
| 3 | `app` publicando su paquete, sin `APP_PACKAGE_JOB_ID` | `paquete-por-sha`, `app-sin-id-de-job`, `infra-en-verde` |
| 4 | La regla de duplicados, probada | — |
| 5 | El registro de `infra/entornos`, leído | — |

Si has cerrado la terminal, repite el paso 0 de la práctica 01 y `source ~/.bc-gitlab-s13`. Necesitas también la función `q` del paso 4 de la práctica 03.

---

## Paso 1: Qué versión se puede sobrescribir

**Por qué**: por defecto, subir dos veces `app/0.2.0/app.tgz` deja dos archivos en la misma versión, y la descarga devuelve el último (teoría 05, apartado 2.4). Las versiones no se sobrescriben; los SHA sí, porque un reintento del job vuelve a subir el mismo.

```bash
q "{ namespace(fullPath: \"$GRUPO\") { packageSettings { genericDuplicatesAllowed genericDuplicateExceptionRegex } } }" \
  | jq -c .data.namespace.packageSettings
q "mutation { updateNamespacePackageSettings(input: { namespacePath: \"$GRUPO\",
     genericDuplicatesAllowed: false, genericDuplicateExceptionRegex: \"^[0-9a-f]{40}$\" }) {
     errors packageSettings { genericDuplicatesAllowed genericDuplicateExceptionRegex } } }" | jq -c .data
```

**Verifica**: antes, `{"genericDuplicatesAllowed":true,"genericDuplicateExceptionRegex":""}`. Después, `"errors":[]` con `false` y la expresión. El ajuste es del grupo raíz: vale para `app`, `infra/entornos` y `ci/componentes`.

---

## Paso 2: `infra/entornos` descarga por SHA

**Por qué**: `infra/entornos` cambia primero. Un push a su `main` no crea pipeline (Semana 11), así que nada lo ejecuta hasta que `app` publique el paquete en el paso 3. Si cambiaras `app` primero, el siguiente disparo llegaría sin `APP_PACKAGE_JOB_ID` a un script que lo exige.

```bash
cd /ruta/a/tus/clones/entornos && git switch main && git pull --ff-only
cat > scripts/registrar.sh <<'EOF'
#!/bin/sh
# Registra qué versión de app ha llegado y comprueba que su paquete se puede leer.
# El paquete se busca por el SHA del commit en el registro de paquetes de app (Semana 13).
# El despliegue real llega en la Semana 14.
set -eu
: "${APP_SHA:?Este pipeline solo se lanza desde app}"
: "${APP_PROJECT_ID:?Falta APP_PROJECT_ID}"
: "${ENTORNO:?Falta ENTORNO}"

curl --fail -sS -o app.tgz --header "JOB-TOKEN: $CI_JOB_TOKEN" \
  "$CI_API_V4_URL/projects/$APP_PROJECT_ID/packages/generic/app/$APP_SHA/app.tgz"

{
  echo "app_sha=$APP_SHA"
  echo "entorno=$ENTORNO"
  echo "paquete=app/$APP_SHA/app.tgz"
  echo "sha256=$(sha256sum app.tgz | cut -d' ' -f1)"
  echo "registrado_por=$GITLAB_USER_LOGIN"
} | tee registro.txt
EOF
git diff --stat
git add scripts/registrar.sh
git commit -S -m "ci: descargar el paquete de app por SHA del registro de paquetes"
git push origin main
```

**Verifica**: `git diff --stat` con una línea, `scripts/registrar.sh`, y menos líneas que antes: sin `APP_PACKAGE_JOB_ID`, sin `unzip`, sin `ls`. No hay pipeline nuevo en `infra/entornos`:

```bash
curl -s -H "$H" "$API/projects/$PI/pipelines?per_page=1" | jq -r '.[0] | "\(.source) \(.sha[0:8])"'
git rev-parse --short=8 HEAD     # distinto: el push no creó nada
```

La lista de permitidos del job token de `app` ya incluye a `infra/entornos` desde la Semana 11: vale igual para paquetes que para artefactos (teoría 07, apartado 2.1).

---

## Paso 3: `app` publica, y deja de pasar el ID

**Por qué**: el `.tgz` sigue saliendo de `package` como artefacto, porque es como lo recibe el job siguiente. Lo nuevo es `publicar-paquete`, que lo sube con nombre fijo, y que `infra` espera a ese job y no a `package`. `PACKAGE_JOB_ID` y su `dotenv` sobran.

```bash
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Publicar el paquete en el registro de paquetes" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=Paquete genérico app, versión SHA (o la del tag sin v). infra/entornos lo descarga por APP_SHA y APP_PACKAGE_JOB_ID desaparece. Ver Semana 13." \
  | jq -r .iid)
git switch -c "$IID-paquete"
```

En `.gitlab-ci.yml`, `package` pierde dos cosas, la línea del `echo` y el `dotenv`:

```yaml
package:
  stage: package
  needs: [build, test]
  rules:
    - !reference [.fuera-de-programados, rules]
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_BRANCH =~ /^release\//
    - if: $CI_COMMIT_TAG
  script:
    - npm pack
  artifacts:
    expire_in: 1 week
    paths: ["*.tgz"]
```

Y gana un job hermano, con las mismas reglas:

```yaml
publicar-paquete:
  stage: package
  image: ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/alpine:3.24.2
  needs: [package]
  rules:
    - !reference [package, rules]
  variables:
    GIT_STRATEGY: none
  before_script:
    - apk add --no-cache curl
  script:
    - VERSION=${CI_COMMIT_TAG#v}
    - VERSION=${VERSION:-$CI_COMMIT_SHA}
    - 'curl --fail-with-body -sS -H "JOB-TOKEN: $CI_JOB_TOKEN" --upload-file *.tgz "$CI_API_V4_URL/projects/$CI_PROJECT_ID/packages/generic/app/$VERSION/app.tgz"'
```

| Línea | Por qué |
|---|---|
| `!reference [package, rules]` | Las reglas de `package`, sin copiarlas: si cambian, cambian las dos |
| `GIT_STRATEGY: none` | No necesita el código: el `.tgz` llega como artefacto de `package` |
| `${CI_COMMIT_TAG#v}`, y si no hay tag, el SHA | `0.2.0` en un tag; el SHA completo en `main` y en `release/*` |
| La línea de `curl` entre comillas | Lleva `: ` dentro (`JOB-TOKEN: …`) |

En `ci/deploy.yml`, el job `infra` cambia de `needs` y pierde una variable:

```yaml
infra:
  stage: deploy
  needs: [publicar-paquete]
  rules:
    - !reference [.fuera-de-programados, rules]
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  variables:
    APP_SHA: $CI_COMMIT_SHA
    APP_PROJECT_ID: $CI_PROJECT_ID
  trigger:
    project: plataforma-<tu-dominio>/infra/entornos
    branch: main
    strategy: mirror
    inputs:
      entorno: staging
```

```bash
grep -rn 'PACKAGE_JOB_ID' .gitlab-ci.yml ci/ || echo "ni rastro"
git add .gitlab-ci.yml ci/deploy.yml
git commit -S -m "ci: publicar el paquete por SHA y dejar de pasar el ID del job a infra"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="ci: paquete genérico por SHA" \
  -o merge_request.description="Closes #$IID"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
fusionar "$P" "$MR"
git switch main && git pull --ff-only
PIPE=$(curl -s -H "$H" "$API/projects/$P/pipelines?ref=main&source=push&per_page=1" | jq -r '.[0].id')
esperar "$P" "$PIPE"
curl -s -H "$H" "$API/projects/$P/packages?package_type=generic&package_name=app&order_by=created_at&sort=desc&per_page=1" \
  | jq -r '.[0].version'
git rev-parse HEAD
```

**Verifica**: `ni rastro`, `state: merged`, `success`, y la versión del paquete igual al SHA completo de `HEAD`. Si tu pipeline de `main` llega a `infra`, abajo:

```bash
PIPE_I=$(curl -s -H "$H" "$API/projects/$PI/pipelines?source=pipeline&per_page=1" | jq -r '.[0].id')
esperar "$PI" "$PIPE_I"
```

`success`.

---

## Paso 4: La regla de duplicados, probada

**Por qué**: el paso 1 dice lo que debería pasar; esto lo comprueba. Primero, el reintento: relanzar `publicar-paquete` vuelve a subir el mismo SHA, y tiene que funcionar.

```bash
JOB=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | select(.name == "publicar-paquete") | .id')
NUEVO=$(curl -s --request POST "$API/projects/$P/jobs/$JOB/retry" -H "$H" | jq -r .id)
until curl -s -H "$H" "$API/projects/$P/jobs/$NUEVO" | jq -e '.status | IN("success","failed")' > /dev/null; do sleep 5; done
curl -s -H "$H" "$API/projects/$P/jobs/$NUEVO" | jq -r .status
```

**Verifica**: `success`. Ahora, una versión que no es un SHA, dos veces, y luego fuera:

```bash
F=$(mktemp) && echo prueba > "$F"
for i in 1 2; do
  curl -sS -H "$H" --upload-file "$F" "$API/projects/$P/packages/generic/app/0.0.0-prueba/app.tgz"; echo
done
PKG=$(curl -s -H "$H" "$API/projects/$P/packages?package_type=generic&package_version=0.0.0-prueba" | jq -r '.[0].id')
curl -s --request DELETE "$API/projects/$P/packages/$PKG" -H "$H" -o /dev/null -w '%{http_code}\n'
rm "$F"
```

**Verifica**: `{"message":"201 Created"}`, después `{"message":"400 Bad request - Duplicate package is not allowed"}`, y `204`. Con `0.2.0`, en el proyecto, pasará lo mismo: una vez publicada, no se cambia.

---

## Paso 5: Lo que registró `infra/entornos`

**Por qué**: el registro es la prueba de que `infra/entornos` descargó de verdad, y de qué.

```bash
JOB_I=$(curl -s -H "$H" "$API/projects/$PI/pipelines/$PIPE_I/jobs" | jq -r '.[] | select(.name == "registrar") | .id')
curl -s -H "$H" "$API/projects/$PI/jobs/$JOB_I/artifacts/registro.txt"
PKG=$(curl -s -H "$H" "$API/projects/$P/packages?package_type=generic&package_version=$(git rev-parse HEAD)" | jq -r '.[0].id')
curl -s -H "$H" "$API/projects/$P/packages/$PKG/package_files" | jq -r '.[-1].file_sha256'
```

**Verifica**: `paquete=app/<SHA>/app.tgz`, `entorno=staging`, y el `sha256` del registro igual al `file_sha256` del último archivo del paquete. `infra/entornos` ya no depende de que exista ningún job de `app`: con el SHA le basta.

---

## ✅ Checklist

- [ ] Duplicados genéricos prohibidos en el grupo, con la excepción para SHA
- [ ] `scripts/registrar.sh` de `infra/entornos` sin `APP_PACKAGE_JOB_ID` y descargando de `packages/generic`
- [ ] `app` con `publicar-paquete`, sin `dotenv` ni `PACKAGE_JOB_ID`
- [ ] El paquete de `HEAD` en el registro y el pipeline de `infra/entornos` en verde
- [ ] El reintento por SHA funciona y la segunda subida de una versión se rechaza

---

## 🧯 Problemas frecuentes

| Síntoma | Causa | Solución |
|---|---|---|
| `registrar` falla con `curl: (22) … 404` | El paquete de ese SHA no existe, o `app` no deja entrar a `infra/entornos` | `GET …/packages?package_version=<SHA>`; si existe, la lista de permitidos de `app` (teoría 07, apartado 2.2) |
| `registrar` falla con `Falta APP_PACKAGE_JOB_ID` | El paso 2 no se empujó | `git log -1 origin/main -- scripts/registrar.sh` en `infra/entornos` |
| `publicar-paquete` falla con `curl: Can't open '*.tgz'!` | No le llegó el artefacto | `needs: [package]` |
| `publicar-paquete` en verde y sin paquete | `curl` sin `--fail-with-body` y una respuesta de error | La línea tal cual |
| El reintento falla con `Duplicate package is not allowed` | La excepción no está, o no cumple: el SHA corto no son 40 caracteres | `$CI_COMMIT_SHA`, no `$CI_COMMIT_SHORT_SHA` |
| El pipeline no se crea: `!reference ["package", "rules"] could not be found` | El nombre del job no coincide | `package`, tal cual se llama el job |

---

[← Anterior: Limpieza y dependency proxy](03-limpieza-y-dependency-proxy.md) · [Volver a la Semana 13](../README.md)

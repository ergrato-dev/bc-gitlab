# Práctica 03 — El disparo a `infra`

> Creas `infra/entornos`, el primer proyecto del subgrupo `infra`, con un pipeline que solo nace cuando lo dispara otro. `main` de `app` lo dispara con el ID del job que generó el paquete, y `infra/entornos` descarga ese paquete exacto con su job token. La primera vez falla, y está bien: falta que `app` lo permita.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 02 completada · Teoría [05](../1-teoria/05-pipelines-multiproyecto.md) y [06](../1-teoria/06-job-token-entre-proyectos.md) leídas

---

## Contexto

`infra/entornos` todavía no despliega nada: **registra** qué versión de `app` le llega y comprueba que puede leer su paquete. En la Semana 14 el mismo pipeline desplegará; en la 24, Terraform vivirá a su lado en `infra/terraform`.

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | `infra/entornos` creado, con variables de pipeline restringidas | `infra-entornos-existe`, `infra-variables-restringidas` |
| 2 | Su `.gitlab-ci.yml` y `scripts/registrar.sh` | — |
| 3 | `package` con `dotenv` y el job de disparo `infra`, fusionados | `disparo-a-infra` |
| 4 | El primer disparo, fallido por la razón correcta | — |
| 5 | `infra/entornos` en la lista de permitidos de `app` | `job-token-de-app-acotado`, `infra-en-la-lista-de-app` |
| 6 | El disparo en verde, arriba y abajo | `pipeline-de-infra-desde-app`, `ultimo-pipeline-de-main-en-verde` |

---

## Paso 1: `infra/entornos`

**Por qué**: el subgrupo `infra` existe desde la Semana 03, vacío y con la descripción que decía "su proyecto nace en la Semana 11". Hoy nace.

```bash
GRUPO=${PROYECTO%%/*}
INFRA_ID=$(curl -s -H "$H" "$API/groups/$GRUPO%2Finfra" | jq -r .id)
[[ "$INFRA_ID" =~ ^[0-9]+$ ]] || { echo "No existe el subgrupo $GRUPO/infra: Semana 03. NO sigas"; return 1 2>/dev/null || exit 1; }

curl -s --request POST "$API/projects" -H "$H" \
  --data "name=entornos" --data "path=entornos" --data "namespace_id=$INFRA_ID" \
  --data "visibility=private" --data "initialize_with_readme=true" --data "default_branch=main" \
  --data-urlencode "description=Qué versión de app hay en cada entorno. Lo dispara main de app (Semana 11); despliega desde la Semana 14." \
  | jq -r .path_with_namespace

export PI=$(printf '%s' "$GRUPO/infra/entornos" | jq -sRr @uri)
echo "export GRUPO=$GRUPO PI=$PI" >> ~/.bc-gitlab-s11
```

Ahora, la restricción de variables de pipeline, **explícita**. El disparo de `app` pasa variables, así que con `no_one_allowed` fallaría; con `developer`, cualquier Developer de `infra` podría lanzar su pipeline con variables arbitrarias (teoría 05, apartado 2.4):

```bash
curl -s --request PUT "$API/projects/$PI" -H "$H" \
  --data "ci_pipeline_variables_minimum_override_role=maintainer" \
  | jq '{path_with_namespace, visibility, ci_pipeline_variables_minimum_override_role}'
```

**Verifica**: `"visibility": "private"` y `"ci_pipeline_variables_minimum_override_role": "maintainer"`.

---

## Paso 2: Un pipeline que solo nace disparado

**Por qué**: `infra/entornos` no tiene nada que hacer en un push propio. Su `workflow` acepta solo el origen `pipeline`: un push a su `main` no crea nada.

```bash
cd /ruta/a/tus/clones
git clone "$(curl -s -H "$H" "$API/projects/$PI" | jq -r .ssh_url_to_repo)" entornos
cd entornos
mkdir -p scripts

cat > scripts/registrar.sh <<'EOF'
#!/bin/sh
# Registra qué versión de app ha llegado y comprueba que su paquete se puede leer.
# El despliegue real llega en la Semana 14.
set -eu
: "${APP_SHA:?Este pipeline solo se lanza desde app}"
: "${APP_PROJECT_ID:?Falta APP_PROJECT_ID}"
: "${APP_PACKAGE_JOB_ID:?Falta APP_PACKAGE_JOB_ID}"

curl --fail -sS -o app.zip --header "JOB-TOKEN: $CI_JOB_TOKEN" \
  "$CI_API_V4_URL/projects/$APP_PROJECT_ID/jobs/$APP_PACKAGE_JOB_ID/artifacts"
unzip -o -q app.zip
TGZ=$(ls -- *.tgz)

{
  echo "app_sha=$APP_SHA"
  echo "paquete=$TGZ"
  echo "sha256=$(sha256sum "$TGZ" | cut -d' ' -f1)"
  echo "registrado_por=$GITLAB_USER_LOGIN"
} | tee registro.txt
EOF
chmod +x scripts/registrar.sh

cat > .gitlab-ci.yml <<'EOF'
# Este proyecto no se construye a sí mismo: lo dispara main de app.
workflow:
  name: "app $APP_SHA"
  rules:
    - if: $CI_PIPELINE_SOURCE == "pipeline"

registrar:
  image: alpine:3.24.2
  before_script:
    - apk add --no-cache curl
  script:
    - scripts/registrar.sh
  artifacts:
    paths: [registro.txt]
    expire_in: 90 days
EOF

jq -n --rawfile c .gitlab-ci.yml '{content: $c}' \
  | curl -s --request POST "$API/projects/$PI/ci/lint" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -c '{valid, errors}'
# {"valid":true,"errors":[]}

git add .gitlab-ci.yml scripts/registrar.sh
git commit -S -m "ci: registrar la versión de app que llega desde su pipeline"
git push origin main
sleep 10
curl -s -H "$H" "$API/projects/$PI/pipelines" | jq length
```

**Verifica**: `0`. El push no creó pipeline: el `workflow` solo acepta `pipeline`. `GITLAB_USER_LOGIN` en el registro dirá quién disparó de verdad (teoría 05, apartado 2.2).

---

## Paso 3: El disparo desde `app`

**Por qué**: `infra/entornos` necesita saber **qué** paquete descargar. El ID del job de `package` solo existe mientras se ejecuta: lo sacas con un informe `dotenv` (teoría 02, apartado 2.3).

```bash
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Disparar infra/entornos con cada paquete de main" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=Job infra con trigger:project y strategy: mirror; package publica su ID de job por dotenv. Ver Semana 11." \
  | jq -r .iid)
git switch -c "$IID-disparo-a-infra"
```

En `package`, dos líneas en `script` y el informe en `artifacts`:

```yaml
package:
  # … stage, needs y rules sin cambios
  script:
    - npm pack
    - echo "PACKAGE_JOB_ID=$CI_JOB_ID" > package.env
  artifacts:
    expire_in: 1 week
    paths: ["*.tgz"]
    reports:
      dotenv: package.env
```

Y el job de disparo, al final del archivo (con la ruta de **tu** grupo):

```yaml
infra:
  stage: deploy
  needs: [package]
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  variables:
    APP_SHA: $CI_COMMIT_SHA
    APP_PROJECT_ID: $CI_PROJECT_ID
    APP_PACKAGE_JOB_ID: $PACKAGE_JOB_ID
  trigger:
    project: plataforma-<tu-dominio>/infra/entornos
    branch: main
    strategy: mirror
```

`$PACKAGE_JOB_ID` llega al job de disparo porque `needs: [package]` descarga su `dotenv`, y de ahí viaja como `APP_PACKAGE_JOB_ID`.

```bash
jq -n --rawfile c .gitlab-ci.yml '{content: $c, dry_run: true, ref: "main", include_jobs: true}' \
  | curl -s --request POST "$API/projects/$P/ci/lint" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -c '{valid, errors, jobs: [.jobs[]?.name]}'
# {"valid":true,"errors":[],"jobs":["build","test","package","deploy-staging","deploy-production","infra"]}

git add .gitlab-ci.yml
git commit -S -m "ci: disparar infra/entornos con cada paquete de main"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="ci: disparar infra/entornos con cada paquete de main"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
fusionar "$MR"
git switch main && git pull --ff-only
```

**Verifica**: `state: merged`. La merge request no tenía job `infra`: solo `main` dispara.

---

## Paso 4: El primer disparo, en rojo

**Por qué**: es el fallo que vas a ver el día que alguien cree otro proyecto que lea de `app`. Mejor reconocerlo ahora.

```bash
sleep 10
PIPE=$(curl -s -H "$H" "$API/projects/$P/pipelines?ref=main&source=push&per_page=1" | jq -r '.[0].id')
esperar "$P" "$PIPE"
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/bridges" \
  | jq -c '.[] | {name, status, abajo: .downstream_pipeline.id}'
ABAJO=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/bridges" | jq -r '.[] | select(.name == "infra") | .downstream_pipeline.id')
JOB=$(curl -s -H "$H" "$API/projects/$PI/pipelines/$ABAJO/jobs" | jq -r '.[] | select(.name == "registrar") | .id')
curl -s -H "$H" "$API/projects/$PI/jobs/$JOB/trace" | grep -E 'curl:|Falta'
```

**Verifica**:

```
failed
{"name":"infra","status":"failed","abajo":<id>}
curl: (22) The requested URL returned error: 404
```

El pipeline de abajo existe, así que el disparo funcionó: tu usuario es Owner de `infra/entornos` y la restricción de variables te deja. Lo que falló es la **lectura**: el job token de `infra/entornos` no puede entrar en `app`. Un `404`, no un `403`: GitLab no confirma que el proyecto exista a quien no puede verlo. Y `main` está en rojo por `strategy: mirror`.

---

## Paso 5: La lista de permitidos de `app`

**Por qué**: quien descarga es `infra/entornos`, pero la lista que se toca es la de `app`, el proyecto al que se accede (teoría 06, apartado 2.2).

```bash
curl -s -H "$H" "$API/projects/$P/job_token_scope" | jq .
```

Si `inbound_enabled` es `false`, actívalo antes de seguir: sin restricción, cualquier proyecto de la instancia con un usuario miembro de `app` podría leer sus artefactos.

```bash
curl -s --request PATCH "$API/projects/$P/job_token_scope" -H "$H" \
  --data "enabled=true" -o /dev/null -w '%{http_code}\n'                     # 204
```

Añade `infra/entornos`, y solo él:

```bash
PI_ID=$(curl -s -H "$H" "$API/projects/$PI" | jq -r .id)
curl -s --request POST "$API/projects/$P/job_token_scope/allowlist" -H "$H" \
  --data "target_project_id=$PI_ID" | jq -c .
curl -s -H "$H" "$API/projects/$P/job_token_scope/allowlist" | jq -r '.[].path_with_namespace'
```

**Verifica**: `{"source_project_id":<app>,"target_project_id":<entornos>}` y la lista con `app` e `infra/entornos`, nada más.

---

## Paso 6: El disparo, en verde

**Por qué**: el pipeline de abajo ya existe; basta con reintentar el job que falló. Con `mirror`, el job de disparo de `app` sigue el estado del pipeline de abajo.

```bash
NUEVO=$(curl -s --request POST "$API/projects/$PI/jobs/$JOB/retry" -H "$H" | jq -r .id)
esperar "$PI" "$ABAJO"
curl -s -H "$H" "$API/projects/$PI/jobs/$NUEVO/trace" | grep -E '^(app_sha|paquete|sha256|registrado_por)='
git rev-parse HEAD
sleep 10
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE" | jq -r .status
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/bridges" | jq -c '.[] | {name, status}'
```

**Verifica**:

```
success
app_sha=<el mismo sha que git rev-parse HEAD>
paquete=<tu-paquete>-<versión>.tgz
sha256=<64 caracteres>
registrado_por=<tu usuario>
<sha>
success
{"name":"infra","status":"success"}
```

El `sha` del registro coincide con el de `main`: `infra/entornos` leyó **este** paquete, no "el último". Y `registrado_por` eres tú, no un usuario de servicio: el pipeline de abajo se creó con tu identidad.

Los pipelines de `infra/entornos` por su origen:

```bash
curl -s -H "$H" "$API/projects/$PI/pipelines?source=pipeline" | jq -r '.[] | "\(.id) \(.status) \(.name)"'
```

---

## ✅ Resultado

- [ ] `infra/entornos`, privado, con variables de pipeline restringidas a Maintainer
- [ ] Su `workflow` solo acepta pipelines disparados: un push no crea nada
- [ ] `package` publica su ID por `dotenv`; `infra` dispara con `strategy: mirror` solo desde `main`
- [ ] Viste el `404` del job token antes de la lista de permitidos
- [ ] La lista de `app` con `infra/entornos` y nada más
- [ ] El registro con el `sha` de `main` y tu usuario; los dos pipelines en verde

```bash
./scripts/verificar-semana.sh 11
```

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `infra` falla sin pipeline de abajo | El `workflow` de `infra/entornos` no acepta `pipeline`, o la ruta de `trigger:project` está mal | Paso 2; `GET /projects/<ruta codificada>` |
| `infra` falla sin pipeline de abajo y la ruta está bien | Restricción de variables en `no_one_allowed` | Paso 1 |
| `registrar` falla con `Falta APP_PACKAGE_JOB_ID` | `package` no generó `package.env`, o `infra` no tiene `needs: [package]` | Paso 3 |
| `registrar` sigue con `404` tras el paso 5 | Añadiste `app` a la lista de `infra/entornos`, al revés | La lista que se toca es la de `app` |
| Tras el reintento, `main` sigue en rojo | El pipeline de arriba no se recalculó | Reintenta el job `infra` en `app`: `POST .../jobs/<id>/retry` crea otro pipeline de abajo |
| `unzip: not found` | Imagen distinta de `alpine` | `unzip` viene en BusyBox de `alpine:3.24.2` |

---

## 🔗 Navegación

[← Anterior: Un pipeline hijo para la documentación](02-un-pipeline-hijo-para-la-documentacion.md) · [Volver a la Semana 11](../README.md) · [Siguiente: Concurrencia y calendario →](04-concurrencia-y-calendario.md)

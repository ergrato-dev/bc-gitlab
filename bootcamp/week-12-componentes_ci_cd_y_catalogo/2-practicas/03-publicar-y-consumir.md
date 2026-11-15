# Práctica 03 — Publicar y consumir

> Proteges `ci/componentes` como el proyecto sensible que es, le añades un job que publica cada tag y lo pones en el catálogo. Publicas `1.0.0`, y `app` deja de tener su propio `.npm`, `build`, `test` y `gobernanza`: los recibe de `ci/componentes` con `@1`. La primera merge request de `app` sin el script de gobernanza la audita el componente.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 02 completada · Teoría [05](../1-teoria/05-catalogo.md), [06](../1-teoria/06-versionar-y-probar.md) y [08](../1-teoria/08-gobernar-el-ci-compartido.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | `revisor` como Developer, CODEOWNERS, `main` y los tags protegidos | `tags-de-componentes-protegidos` |
| 2 | `GOBERNANZA_TOKEN` y el job `publicar`, por merge request | — |
| 3 | `ci/componentes` en el catálogo | `componentes-en-el-catalogo` |
| 4 | La versión `1.0.0` publicada | `versiones-semver-sin-v` |
| 5 | El grupo en la lista de permitidos de `ci/componentes` | `grupo-lee-componentes` |
| 6 | `app` consumiendo `npm@1` y `gobernanza@1` | `app-usa-npm`, `app-usa-gobernanza` |

Si has cerrado la terminal, repite el paso 0 de la práctica 01 y `source ~/.bc-gitlab-s12`.

---

## Paso 1: Dueños y protecciones

**Por qué**: quien publica en `ci/componentes` ejecuta código en `app` (teoría 08, apartado 1). `revisor` revisa y aprueba, pero **no** publica: Developer, no Maintainer. En la Semana 03 lo dejaste como Guest en el grupo; aquí sube solo en este proyecto.

```bash
curl -s --request POST "$API/projects/$PC/members" -H "$H" \
  --data "user_id=$UID_REV" --data "access_level=30" | jq -c '{username, access_level}'

cd /ruta/a/tus/clones/componentes && git pull --ff-only
cat > CODEOWNERS <<EOF
# Dueños de ci/componentes. En CE GitLab no lo exige: lo lee el componente gobernanza.
* @$REV
EOF
git add CODEOWNERS && git commit -S -m "chore: dueños de ci/componentes" && git push origin main
```

Último push directo. Ahora, `main` sin push para nadie y fusión para Maintainer. GitLab ya la protegió al crear el proyecto con sus valores por defecto: la quitas y la vuelves a crear con los tuyos.

```bash
curl -s --request DELETE "$API/projects/$PC/protected_branches/main" -H "$H" -o /dev/null -w '%{http_code}\n'
curl -s --request POST "$API/projects/$PC/protected_branches" -H "$H" \
  --data "name=main" --data "push_access_level=0" --data "merge_access_level=40" --data "allow_force_push=false" \
  | jq -c '{name, push: [.push_access_levels[].access_level], merge: [.merge_access_levels[].access_level]}'
curl -s --request POST "$API/projects/$PC/protected_tags" -H "$H" \
  --data-urlencode "name=*" --data "create_access_level=40" \
  | jq -c '{name, crear: [.create_access_levels[].access_level]}'
```

**Verifica**: `204`, `{"name":"main","push":[0],"merge":[40]}`, `{"name":"*","crear":[40]}` y `revisor` con `"access_level":30`.

---

## Paso 2: El job que publica, por merge request

**Por qué**: `gobernanza` audita también las merge requests de `ci/componentes` (práctica 02, paso 4), y necesita su propio token, como `app` en la Semana 09. El token se crea y se guarda sin pasar por tu terminal.

```bash
curl -s --request POST "$API/projects/$PC/access_tokens" -H "$H" \
  --data-urlencode "name=gobernanza-ci" --data "scopes[]=read_api" --data "access_level=20" \
  --data "expires_at=$(date -d '+180 days' +%F)" \
  | jq -j '.token // empty' \
  | curl -s --request POST "$API/projects/$PC/variables" -H "$H" \
      --data "key=GOBERNANZA_TOKEN" --data-urlencode "value@-" \
      --data "masked_and_hidden=true" --data "masked=true" --data "protected=false" \
  | jq -c '{key, masked, hidden, protected, value}'
```

Y el job, al final de `.gitlab-ci.yml` de `ci/componentes`:

```bash
IIDC=$(curl -s --request POST "$API/projects/$PC/issues" -H "$H" \
  --data-urlencode "title=Publicar cada tag semver en el catálogo" \
  --data-urlencode "description=Job publicar con release:, solo en tags X.Y.Z sin v, después de las pruebas. Ver Semana 12." \
  | jq -r .iid)
git switch -c "$IIDC-publicar"

cat >> .gitlab-ci.yml <<'EOF'

# Publica la versión en el catálogo. Solo llega aquí si build y test pasan en el pipeline del tag.
publicar:
  stage: release
  image: registry.gitlab.com/gitlab-org/cli:v1.126.0
  variables:
    CI_SERVER_FQDN: gitlab:8888   # solo laboratorio: el mismo host que CI_SERVER_URL (teoría 06, apartado 2.7)
  script: echo "Publicando $CI_COMMIT_TAG"
  release:
    tag_name: $CI_COMMIT_TAG
    description: "Versión $CI_COMMIT_TAG de $CI_PROJECT_PATH. Cambios y uso: README.md."
  rules:
    - if: $CI_COMMIT_TAG =~ /^[0-9]+\.[0-9]+\.[0-9]+$/
EOF

git add .gitlab-ci.yml
git commit -S -m "ci: publicar cada tag semver en el catálogo"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="ci: publicar cada tag semver en el catálogo" \
  -o merge_request.description="Closes #$IIDC"
MRC=$(curl -s -H "$H" "$API/projects/$PC/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
fusionar "$PC" "$MRC"
git switch main && git pull --ff-only
```

**Verifica**: `{"key":"GOBERNANZA_TOKEN","masked":true,"hidden":true,"protected":false,"value":null}` y `state: merged`. Mira el log de `gobernanza` en el pipeline de la merge request:

```bash
PIPE=$(curl -s -H "$H" "$API/projects/$PC/merge_requests/$MRC/pipelines" | jq -r '.[0].id')
J=$(curl -s -H "$H" "$API/projects/$PC/pipelines/$PIPE/jobs" | jq -r '.[] | select(.name == "gobernanza") | .id')
curl -s -H "$H" "$API/projects/$PC/jobs/$J/trace" | grep -E '✅|❌|problema'
# ✅ cierra un issue
# ✅ aprobada por: revisor-<tu-dominio>
# ✅ .gitlab-ci.yml: aprobado por su dueño
# 0 problema(s) en !1
```

El componente se auditó a sí mismo con el script que vive a su lado.

---

## Paso 3: En el catálogo

**Por qué**: sin marcar el proyecto, un tag es solo un tag: `@1` no resolvería nada (teoría 05, apartado 1).

**Con la UI**: en `ci/componentes`, `Settings → General → Visibility, project features, permissions`, activa **CI/CD Catalog project** y guarda.

**Por API** (no hay REST, es GraphQL):

```bash
jq -n --arg p "$GRUPO/ci/componentes" \
  '{query: "mutation($p: ID!) { catalogResourcesCreate(input: {projectPath: $p}) { errors } }", variables: {p: $p}}' \
  | curl -s "$GITLAB_URL/api/graphql" -H "$H" -H "Content-Type: application/json" -d @-
```

**Verifica**:

```bash
jq -n --arg p "$GRUPO/ci/componentes" '{query: "query($p: ID!) { project(fullPath: $p) { isCatalogResource } }", variables: {p: $p}}' \
  | curl -s "$GITLAB_URL/api/graphql" -H "$H" -H "Content-Type: application/json" -d @- | jq -c .data
# {"project":{"isCatalogResource":true}}
```

Todavía no aparece en `Explore → CI/CD Catalog`: no tiene ninguna versión.

---

## Paso 4: `1.0.0`

**Por qué**: el tag dispara el pipeline que vuelve a probar y, si todo pasa, publica (teoría 06, apartado 2.6). Sin `v`: las versiones parciales no la encontrarían (teoría 06, apartado 2.3).

```bash
git tag -s 1.0.0 -m "1.0.0: componentes npm y gobernanza"
git push origin 1.0.0
sleep 10
PIPE=$(curl -s -H "$H" "$API/projects/$PC/pipelines?ref=1.0.0&per_page=1" | jq -r '.[0].id')
esperar "$PC" "$PIPE"
curl -s -H "$H" "$API/projects/$PC/pipelines/$PIPE/jobs" | jq -r 'sort_by(.id) | .[] | "\(.stage)\t\(.name)\t\(.status)"'
```

**Verifica**: `success`, con `build` y `test` antes que `publicar`. Y la versión en el catálogo:

```bash
curl -s -H "$H" "$API/projects/$PC/releases" | jq -r '.[].tag_name'
jq -n '{query: "{ ciCatalogResources(search: \"componentes\") { nodes { fullPath versions { nodes { name components { nodes { name includePath } } } } } } }"}' \
  | curl -s "$GITLAB_URL/api/graphql" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -c '.data.ciCatalogResources.nodes[] | {fullPath, v: [.versions.nodes[] | {name, c: [.components.nodes[].includePath]}]}'
```

`1.0.0`, y dos `includePath` que empiezan por `$CI_SERVER_FQDN`: las líneas que vas a copiar en `app`. En la UI, `Explore → CI/CD Catalog` enseña el proyecto con su README como portada y la pestaña de componentes con sus inputs.

---

## Paso 5: El grupo puede leer `ci/componentes`

**Por qué**: el job `gobernanza` de `app` descargará el script con el job token **de `app`**. `ci/componentes` es privado: sin una entrada en su lista de permitidos, la descarga devuelve 403 (teoría 08, apartado 2.3).

```bash
GID_RAIZ=$(curl -s -H "$H" "$API/groups/$GRUPO" | jq -r .id)
curl -s --request POST "$API/projects/$PC/job_token_scope/groups_allowlist" -H "$H" \
  --data "target_group_id=$GID_RAIZ" | jq -c .
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$PC/job_token_scope/groups_allowlist" | jq -r '.[].web_url'
# http://localhost:8888/groups/plataforma-<tu-dominio>
```

---

## Paso 6: `app` consume

**Por qué**: es el momento en que el YAML deja de duplicarse. `app` pierde 50 líneas y un script, y gana dos `include`.

```bash
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Construir, probar y auditar con los componentes de ci/componentes" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=npm@1 y gobernanza@1 sustituyen a .npm, build, test, gobernanza y scripts/gobernanza.sh. Ver Semana 12." \
  | jq -r .iid)
git switch -c "$IID-componentes"
```

En `.gitlab-ci.yml`, **borra enteros** los bloques `.npm:`, `build:`, `test:` y `gobernanza:`. `package` se queda: su `needs: [build, test]` ahora apunta a los jobs del componente, que se llaman igual a propósito. Y el `include`, con la ruta de **tu** grupo:

```yaml
include:
  - local: ci/deploy.yml
  - component: $CI_SERVER_FQDN/plataforma-<tu-dominio>/ci/componentes/npm@1
  - component: $CI_SERVER_FQDN/plataforma-<tu-dominio>/ci/componentes/gobernanza@1
```

Ningún input: los valores por defecto de los dos componentes son los de `app`. El script ya no hace falta aquí:

```bash
git rm scripts/gobernanza.sh
grep -nE '^(\.npm|build|test|gobernanza):' .gitlab-ci.yml || echo "bloques borrados"
git add .gitlab-ci.yml
git commit -S -m "ci: construir, probar y auditar con los componentes"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="ci: construir, probar y auditar con los componentes" \
  -o merge_request.description="Closes #$IID"
RAMA=$(git branch --show-current)
curl -s -H "$H" "$API/projects/$P/ci/lint?content_ref=$RAMA" \
  | jq -c '{valid, errors, c: [.includes[] | select(.type == "component") | .location]}'
```

**Verifica**: `valid: true` y las dos rutas con `@1`. Fusiona, y mira de dónde salió `gobernanza`:

```bash
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$RAMA&state=opened" | jq -r '.[0].iid')
fusionar "$P" "$MR"
git switch main && git pull --ff-only
PIPE=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/pipelines" | jq -r '.[0].id')
J=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | select(.name == "gobernanza") | .id')
curl -s -H "$H" "$API/projects/$P/jobs/$J/trace" | grep -E 'raw\?ref=|problema'
```

`state: merged`, la línea de `curl` con el SHA de `1.0.0` en `ref=`, y `0 problema(s)`. La merge request que borró `scripts/gobernanza.sh` de `app` la auditó el mismo script, descargado de `ci/componentes`.

El primer pipeline de `main` tarda algo más en `build`: la clave de caché era `package-lock.json` y ahora es `./package-lock.json`, la que construye el input `directorio`. Una caché fría, una vez.

```bash
PIPE=$(curl -s -H "$H" "$API/projects/$P/pipelines?ref=main&source=push&per_page=1" | jq -r '.[0].id')
esperar "$P" "$PIPE"
```

**Verifica**: `success`, con los mismos jobs que en la práctica 01.

---

## ✅ Resultado

- [ ] `revisor` Developer en `ci/componentes`, dueño de todo en su CODEOWNERS
- [ ] `main` de `ci/componentes` sin push para nadie; tags solo para Maintainer
- [ ] El job `publicar`, fusionado con `gobernanza` en verde auditando a `ci/componentes`
- [ ] `ci/componentes` en el catálogo, con `1.0.0` publicada
- [ ] El grupo raíz en la lista de permitidos del job token de `ci/componentes`
- [ ] `app` sin `.npm`, `build`, `test`, `gobernanza` ni `scripts/gobernanza.sh`, y en verde

```bash
./scripts/verificar-semana.sh 12
```

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `publicar` falla: `server gave HTTP response to HTTPS client` | Falta `CI_SERVER_FQDN: gitlab:8888` en el job | Paso 2 y teoría 06, apartado 2.7 |
| El pipeline del tag no tiene `publicar` | El tag lleva `v`, o no es `X.Y.Z` | Tag nuevo sin `v`: `1.0.1` |
| `release` creada pero `1.0.0` no aparece en el catálogo | El proyecto no estaba marcado, o el commit del tag no tiene `README.md` | Paso 3; publica `1.0.1` |
| `gobernanza` en `ci/componentes`: `falta la aprobación de @revisor-…` | `revisor` sigue siendo Guest | Paso 1 |
| `gobernanza` en `app`: `curl: (22) … 403` | El grupo no está en la lista de permitidos de `ci/componentes` | Paso 5 |
| `content not found` con `@1` | No hay ninguna versión publicada `1.x.y` | Paso 4 |
| `package job: undefined need: build` | El componente `npm` no entró: revisa la ruta del `include` | `ci/lint` y `includes` |
| `push` a `main` de `ci/componentes` rechazado | Es lo que pediste en el paso 1 | Merge request |

---

## 🔗 Navegación

[← Anterior: Los dos componentes](02-los-dos-componentes.md) · [Volver a la Semana 12](../README.md) · [Siguiente: Inputs en `infra` →](04-inputs-en-infra.md)

# Práctica 02 — El primer pipeline

> Preparas `app` para que un contenedor limpio la pueda construir y probar sin ti, escribes el `.gitlab-ci.yml` de tres stages, lo validas con la API antes de empujarlo, y lo fusionas viéndolo pasar a verde en su propia merge request.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 01 completada · Teoría [02](../1-teoria/02-anatomia-del-gitlab-ci-yml.md), [05](../1-teoria/05-artefactos.md) y [06](../1-teoria/06-cache.md) leídas

---

## Contexto

`app` se prueba con `npm test` desde la Semana 02, pero nada en el repositorio dice qué versión de nada hace falta ni qué produce el proyecto. El pipeline obliga a escribirlo: si no está en el repositorio, el contenedor no lo tiene.

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | El issue | — |
| 2 | TypeScript, `package-lock.json` y `test:ci` | `lockfile-en-main` |
| 3 | `.gitlab-ci.yml` validado | `gitlab-ci-en-main`, `ci-valido-en-main`, `stages-build-test-package`, `workflow-rules`, `imagenes-fijadas`, `cache-por-lockfile` |
| 4 | El pipeline de la merge request en verde | — |
| 5 | Fusionado, y el pipeline de `main` en verde | `ultimo-pipeline-de-main-en-verde`, `tres-jobs-en-main` |

---

## Paso 0: Preparar el terreno

```bash
source ~/.bc-gitlab && source ~/.bc-gitlab-s09
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
[ -n "${HR:-}" ] || echo "Falta \$HR: repite el paso 0 de la práctica 01"
```

---

## Paso 1: El issue

```bash
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Pipeline de build, test y package" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=Cada cambio se construye, se prueba y se empaqueta en el runner del proyecto. Ver Semana 09." \
  | jq -r .iid)
echo "export IID_CI=$IID" >> ~/.bc-gitlab-s09
echo "issue #$IID"
```

---

## Paso 2: Lo que el contenedor necesita saber

**Por qué**: el contenedor del job no tiene nada de tu máquina. Lo que use tiene que estar declarado, con su versión exacta, en el repositorio.

```bash
git switch main && git pull --ff-only
git switch -c "$IID-pipeline"

npm install --save-dev --save-exact typescript@7.0.2 @types/node@22
```

`--save-exact` escribe `7.0.2`, no `^7.0.2`. Y `npm install` crea o actualiza `package-lock.json`, que fija también las dependencias de las dependencias: es lo que `npm ci` exige y lo que la clave de caché usa.

La configuración de TypeScript, solo para **comprobar tipos**. Quien ejecuta el código sigue siendo Node, que quita los tipos sin mirarlos:

```bash
cat > tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "noEmit": true,
    "target": "esnext",
    "module": "nodenext",
    "allowImportingTsExtensions": true,
    "erasableSyntaxOnly": true,
    "verbatimModuleSyntax": true,
    "strict": true,
    "types": ["node"]
  },
  "include": ["src"]
}
EOF
npx tsc && echo "tipos correctos"
```

Si `tsc` encuentra errores, son errores de verdad que `--experimental-strip-types` nunca te habría dicho. Arréglalos en esta misma rama, en un commit `fix(types): ...` aparte.

Ahora el script de tests para el pipeline, lo que el paquete publica y lo que Git no debe ver:

```bash
npm pkg set "scripts.test:ci=node --experimental-strip-types --test --experimental-test-coverage --test-reporter=spec --test-reporter-destination=stdout --test-reporter=junit --test-reporter-destination=junit.xml 'src/*.test.ts'"
npm pkg set "files[]=src/" "files[]=!src/*.test.ts"
printf '.npm/\n*.tgz\njunit.xml\n' >> .gitignore

npm run test:ci | tail -8
npm pack --dry-run 2>&1 | grep -E 'notice [0-9.]+[kB]* |total files'
```

**Verifica**:

- La tabla de cobertura termina con una fila `all files` y `junit.xml` existe.
- `npm pack --dry-run` lista `package.json`, tu código de `src/` y, si existen, `README.md` y `LICENSE`. Ni tests, ni `assets/`, ni `.gitlab-ci.yml`.

```bash
git add package.json package-lock.json tsconfig.json .gitignore
git commit -S -m "build: comprobar tipos con TypeScript y preparar los tests para CI"
```

> [!NOTE]
> `test:ci` y `test` ejecutan los mismos tests. `test:ci` añade dos salidas a la vez, la legible y la JUnit, y la cobertura. Así cualquiera puede reproducir el job en local con el mismo comando.

---

## Paso 3: El `.gitlab-ci.yml`

**Por qué**: el archivo de la teoría 02, sin `gobernanza` todavía. Va validado **antes** del commit: un pipeline roto en la historia es una mancha que no se borra.

```bash
cat > .gitlab-ci.yml <<'EOF'
# Pipeline de app. Las decisiones, en el ADR-007 de la wiki.
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS
      when: never
    - if: $CI_COMMIT_BRANCH
    - if: $CI_COMMIT_TAG

stages: [build, test, package]

variables:
  GIT_LFS_SKIP_SMUDGE: "1"   # ningún job usa las imágenes de assets/

default:
  image: node:22.23.3-alpine3.24
  interruptible: true

.npm:
  cache:
    key:
      files: [package-lock.json]
    paths: [.npm/]
    policy: pull
  before_script:
    - npm ci --cache .npm --prefer-offline --no-audit --no-fund

build:
  stage: build
  extends: .npm
  cache:
    policy: pull-push
  script:
    - npx tsc

test:
  stage: test
  extends: .npm
  script:
    - npm run test:ci
  coverage: '/all files\s*\|\s*([\d.]+)/'
  artifacts:
    when: always
    expire_in: 1 week
    reports:
      junit: junit.xml

package:
  stage: package
  script:
    - npm pack
  artifacts:
    expire_in: 1 week
    paths: ["*.tgz"]
EOF

jq -n --rawfile c .gitlab-ci.yml '{content: $c}' \
  | curl -s --request POST "$API/projects/$P/ci/lint" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq '{valid, errors, warnings}'
```

**Verifica**: `"valid": true` y las dos listas vacías. Prueba también a romperlo a propósito, sin guardarlo:

```bash
sed 's/stage: package/stage: paquete/' .gitlab-ci.yml | jq -Rs '{content: .}' \
  | curl -s --request POST "$API/projects/$P/ci/lint" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -r '.errors[]'
# package job: chosen stage paquete does not exist; available stages are .pre, build, test, package, .post
```

```bash
git add .gitlab-ci.yml
git commit -S -m "ci: construir, probar y empaquetar cada cambio"
git push -u origin HEAD \
  -o merge_request.create \
  -o merge_request.target=main \
  -o merge_request.title="ci: construir, probar y empaquetar cada cambio"
```

Sin trailer `Changelog:`: a quien usa `app` no le cambia nada.

---

## Paso 4: El pipeline de la merge request

**Por qué**: la merge request que introduce el pipeline es la primera que lo ejecuta. Si está en rojo aquí, no llega a `main`.

```bash
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
echo "export MR_CI=$MR" >> ~/.bc-gitlab-s09
curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/pipelines" | jq -r '.[] | "\(.id) \(.source) \(.status)"'
```

Un solo pipeline, de origen `merge_request_event`. El push creó la rama y la merge request a la vez, y `workflow:rules` descartó el pipeline de rama.

Espera a que termine (la primera vez, un par de minutos: descarga la imagen de Node) y mira cada job:

```bash
PIPE=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/pipelines" | jq -r '.[0].id')
until curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE" | jq -e '.status | IN("success","failed","canceled")' > /dev/null; do sleep 10; done
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | "\(.stage)\t\(.name)\t\(.status)\t\(.duration | floor)s"'
```

**Verifica**:

```
package   package  success  6s
test      test     success  11s
build     build    success  14s
```

Si algo sale en rojo, el log dice por qué:

```bash
JOB=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | select(.status == "failed") | .id' | head -1)
curl -s -H "$H" "$API/projects/$P/jobs/$JOB/trace" | sed 's/\x1b\[[0-9;]*m//g' | grep -v '^section_' | tail -25
```

Arréglalo con un commit nuevo en la rama: el push lanza otro pipeline de la merge request.

---

## Paso 5: Revisión, fusión y el pipeline de `main`

**Por qué**: `.gitlab-ci.yml` cae bajo la regla `*` de `CODEOWNERS` (tú y `revisor`) y `package.json` también. `gobernanza.sh` se ejecuta todavía en tu terminal: la práctica 04 lo convierte en job.

```bash
curl -s --request POST "$API/projects/$P/merge_requests/$MR/approve" -H "$HR" | jq -r '.approved_by[].user.username'
bash scripts/gobernanza.sh "$MR" && {
  SHA=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .sha)
  curl -s --request PUT "$API/projects/$P/merge_requests/$MR/merge" -H "$H" \
    --data-urlencode "sha=$SHA" --data-urlencode "squash=true" | jq '{state, squash_commit_sha}'
}
git switch main && git pull --ff-only
```

La fusión crea un commit en `main`, y ese push crea **otro** pipeline, de origen `push`, sobre `main`:

```bash
sleep 20
curl -s -H "$H" "$API/projects/$P/pipelines?ref=main&per_page=1" | jq -r '.[0] | "\(.id) \(.source) \(.status)"'
```

Espera a que termine como en el paso 4.

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/pipelines/latest?ref=main" | jq '{status, coverage, source}'
curl -s -H "$H" "$API/projects/$P/issues/$IID" | jq -r .state      # closed
```

`status: success` y `coverage` con un número. La insignia de pipeline que creaste en la Semana 04 deja de decir *unknown*: abre la portada de `app` en el navegador.

---

## ✅ Resultado

- [ ] `typescript` y `@types/node` en `devDependencies` con versión exacta, y `package-lock.json` en `main`
- [ ] `tsconfig.json`, `test:ci` y `files` en `main`
- [ ] `.gitlab-ci.yml` validado por la API antes de empujarlo
- [ ] Un solo pipeline en la merge request, de origen `merge_request_event`, en verde
- [ ] El pipeline de `main` en verde, con cobertura
- [ ] El issue cerrado

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `npm ci` falla: `package-lock.json` no está sincronizado | Se tocó `package.json` sin volver a ejecutar `npm install` | `npm install` en local y commit del lockfile |
| `build` falla con errores `TS…` | Errores de tipos reales en `src/` | Arréglalos en la rama; `npx tsc` en local los muestra igual |
| `build` falla con `Cannot find type definition file for 'node'` | Falta `@types/node` | Paso 2 |
| `test` falla con `ERR_MODULE_NOT_FOUND` | Un import sin la extensión `.ts` | Igual que en la Semana 02 |
| `test` en verde pero `coverage` sale `null` | La expresión no encuentra `all files` en el log | Comprueba que `test:ci` lleva `--experimental-test-coverage` |
| Dos pipelines en la merge request | El push y la merge request se crearon por separado antes de tener `workflow:rules` | Con el archivo de esta práctica no vuelve a pasar |
| La fusión dice `el asunto no sigue Conventional Commits` | El título de la merge request | `PUT .../merge_requests/$MR` con `title=ci: ...` |

---

## 🔗 Navegación

[← Anterior: El runner de `app`](01-el-runner-de-app.md) · [Volver a la Semana 09](../README.md) · [Siguiente: Artefactos y caché, medidos →](03-artefactos-y-cache-medidos.md)

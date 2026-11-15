# Práctica 02 — Los dos componentes

> Creas `ci/componentes`, el proyecto que el subgrupo `ci` esperaba desde la Semana 03, y escribes sus dos componentes: `npm`, que construye y prueba, y `gobernanza`, que audita la merge request con un script que viaja desde el propio proyecto. El pipeline de `ci/componentes` se incluye a sí mismo para probarlos antes de que nadie los use.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 01 completada · Teoría [03](../1-teoria/03-spec-inputs.md) y [04](../1-teoria/04-componentes.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | `ci/componentes`, con el runner y un clon | `componentes-existe` |
| 2 | El componente `npm` y el proyecto mínimo que lo prueba | `componente-npm` |
| 3 | El pipeline de `ci/componentes`, probando `npm` | — |
| 4 | El componente `gobernanza` y su script | `componente-gobernanza` |
| 5 | Un input mal pasado, visto, y `main` en verde | `componentes-se-prueba` |

Si has cerrado la terminal, repite el paso 0 de la práctica 01 y `source ~/.bc-gitlab-s12`.

---

## Paso 1: `ci/componentes`

**Por qué**: el subgrupo `ci` existe desde la Semana 03 con su descripción ("Sus proyectos nacen en las Semanas 12 y 17"). La descripción del proyecto no es decorativa: sin ella, el catálogo no publica (teoría 05, apartado 2.2).

```bash
CI_ID=$(curl -s -H "$H" "$API/groups/$GRUPO%2Fci" | jq -r .id)
[[ "$CI_ID" =~ ^[0-9]+$ ]] || { echo "No existe el subgrupo $GRUPO/ci: Semana 03. NO sigas"; return 1 2>/dev/null || exit 1; }

curl -s --request POST "$API/projects" -H "$H" \
  --data "name=componentes" --data "path=componentes" --data "namespace_id=$CI_ID" \
  --data "visibility=private" --data "initialize_with_readme=true" --data "default_branch=main" \
  --data-urlencode "description=Componentes CI/CD del grupo: npm (construir y probar) y gobernanza (auditar la merge request). Se publican en el catálogo." \
  | jq -r .path_with_namespace

export PC=$(printf '%s' "$GRUPO/ci/componentes" | jq -sRr @uri)
echo "export PC=$PC" >> ~/.bc-gitlab-s12
```

`ci/componentes` necesita runner, igual que `infra/entornos` en la Semana 11: `docker-app` es de proyecto.

```bash
RID=$(curl -s -H "$H" "$API/projects/$P/runners" | jq -r '.[] | select(.description == "docker-app") | .id')
curl -s --request POST "$API/projects/$PC/runners" -H "$H" --data "runner_id=$RID" | jq -r .description

cd /ruta/a/tus/clones
git clone "$(curl -s -H "$H" "$API/projects/$PC" | jq -r .ssh_url_to_repo)" componentes
cd componentes && mkdir -p templates tests/npm scripts
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$PC" | jq '{path_with_namespace, visibility, description: (.description | length > 0)}'
curl -s -H "$H" "$API/runners/$RID" | jq -r '.projects[].path_with_namespace'
```

`"visibility": "private"`, descripción presente, y el runner con `app`, `infra/entornos` y `ci/componentes`.

---

## Paso 2: El componente `npm`

**Por qué**: es `.npm`, `build` y `test` de `app` (Semanas 09 a 11), reescritos para no depender de `app`: el job oculto con un nombre propio, la regla de fuera de programados dentro del componente, y como inputs lo que cambia entre proyectos (teoría 04, apartado 2.5).

```bash
cat > templates/npm.yml <<'EOF'
spec:
  inputs:
    directorio:
      description: Carpeta del package.json, relativa a la raíz del repositorio
      default: "."
    imagen:
      description: Imagen de Node con la que se construye y se prueba
      default: node:22.23.3-alpine3.24
    build:
      description: Comando que compila
      default: npx tsc
    rutas:
      description: Rutas que, si cambian en una merge request, obligan a construir y probar
      type: array
      default: [src/**/*, package.json, package-lock.json, tsconfig.json, .gitlab-ci.yml]
---
# build y test son el contrato: el consumidor los nombra en sus needs.
.componente-npm:
  image: $[[ inputs.imagen ]]
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: never
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        paths: $[[ inputs.rutas ]]
    - if: $CI_PIPELINE_SOURCE != "merge_request_event"
  cache:
    key:
      files:
        - $[[ inputs.directorio ]]/package-lock.json
    paths:
      - $[[ inputs.directorio ]]/.npm/
    policy: pull
  before_script:
    - cd $[[ inputs.directorio ]]
    - npm ci --cache .npm --prefer-offline --no-audit --no-fund

build:
  stage: build
  extends: .componente-npm
  cache:
    policy: pull-push
  script:
    - $[[ inputs.build ]]

test:
  stage: test
  extends: .componente-npm
  needs: []
  script:
    - npm run test:ci
  coverage: '/all files\s*\|\s*([\d.]+)/'
  artifacts:
    when: always
    expire_in: 1 week
    reports:
      junit: $[[ inputs.directorio ]]/junit.xml
EOF
```

Fíjate en `files` y `paths`: listas en bloque. Con corchetes, `$[[` rompería el YAML (teoría 03, apartado 2.5).

Y un proyecto mínimo para probarlo, sin dependencias: lo que se prueba es el componente, no npm.

```bash
cat > tests/npm/package.json <<'EOF'
{
  "name": "prueba-del-componente-npm",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "test:ci": "node --test --test-reporter=spec --test-reporter=junit --test-reporter-destination=stdout --test-reporter-destination=junit.xml"
  }
}
EOF
cat > tests/npm/package-lock.json <<'EOF'
{
  "name": "prueba-del-componente-npm",
  "version": "1.0.0",
  "lockfileVersion": 3,
  "requires": true,
  "packages": {
    "": {
      "name": "prueba-del-componente-npm",
      "version": "1.0.0"
    }
  }
}
EOF
cat > tests/npm/index.test.js <<'EOF'
const test = require('node:test');
const assert = require('node:assert');
test('el componente ejecuta los tests del proyecto', () => assert.strictEqual(1 + 1, 2));
EOF
```

**Verifica**: `ls -R templates tests` enseña `npm.yml` y los tres archivos de `tests/npm/`.

---

## Paso 3: El pipeline que lo prueba

**Por qué**: el componente se incluye a sí mismo en el commit que se está probando, con inputs que **no** son los de por defecto. Si un cambio rompe `directorio` o `build`, falla aquí y no en `app` (teoría 06, apartado 2.5).

```bash
cat > .gitlab-ci.yml <<'EOF'
# Pipeline de ci/componentes: prueba cada componente en el commit que se está probando.
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS
      when: never
    - if: $CI_COMMIT_BRANCH
    - if: $CI_COMMIT_TAG

stages: [build, test, release]

include:
  - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/npm@$CI_COMMIT_SHA
    inputs:
      directorio: tests/npm
      build: node --check index.test.js
      rutas:
        - .gitlab-ci.yml
        - templates/npm.yml
        - tests/npm/**/*
EOF

git add .
git commit -S -m "feat: componente npm y su proyecto de prueba"
git push origin main
```

Empujas directamente a `main`: el proyecto está naciendo, como `infra/entornos` en la Semana 11. A partir de la práctica 03, solo por merge request.

**Verifica**:

```bash
sleep 10
PIPE=$(curl -s -H "$H" "$API/projects/$PC/pipelines?ref=main&per_page=1" | jq -r '.[0].id')
esperar "$PC" "$PIPE"
curl -s -H "$H" "$API/projects/$PC/pipelines/$PIPE/jobs" | jq -c '.[] | {name, status}'
curl -s -H "$H" "$API/projects/$PC/pipelines/$PIPE/test_report" | jq -c '{total_count, success_count}'
```

`success`, `build` y `test` en verde, y `{"total_count":1,"success_count":1}`: el informe JUnit llegó desde `tests/npm/junit.xml`, con la ruta que construyó el input `directorio`.

---

## Paso 4: El componente `gobernanza`

**Por qué**: el job de la Semana 09 ejecuta `scripts/gobernanza.sh` de `app`. El script no viaja con un componente (teoría 04, apartado 2.1): vive en `ci/componentes` y el job lo descarga en el SHA exacto del componente.

```bash
cp /ruta/a/tu/clon/de/app/scripts/gobernanza.sh scripts/
chmod +x scripts/gobernanza.sh

cat > templates/gobernanza.yml <<'EOF'
spec:
  component: [sha]
  inputs:
    origen:
      description: Ruta de este proyecto de componentes, de donde el job descarga scripts/gobernanza.sh
      default: plataforma-<tu-dominio>/ci/componentes
    stage:
      description: Stage del job; el consumidor tiene que tenerlo en sus stages
      default: test
    imagen:
      description: Imagen con la que se ejecuta la auditoría
      default: alpine:3.24.2
---
# Necesita GOBERNANZA_TOKEN en el proyecto consumidor (Semana 09) y que el consumidor
# esté en la lista de permitidos del job token de este proyecto (práctica 03).
gobernanza:
  stage: $[[ inputs.stage ]]
  image: $[[ inputs.imagen ]]
  needs: []
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  allow_failure: true
  before_script:
    - apk add --no-cache bash curl jq
  script:
    - ORIGEN=$(jq -rn --arg p '$[[ inputs.origen | expand_vars ]]' '$p | @uri')
    - >
      curl --fail -sS -o /tmp/gobernanza.sh --header "JOB-TOKEN: $CI_JOB_TOKEN"
      "$CI_API_V4_URL/projects/$ORIGEN/repository/files/scripts%2Fgobernanza.sh/raw?ref=$[[ component.sha ]]"
    - bash /tmp/gobernanza.sh
EOF
sed -i "s|plataforma-<tu-dominio>/ci/componentes|$GRUPO/ci/componentes|" templates/gobernanza.yml
grep -n 'default: plataforma' templates/gobernanza.yml
```

Tres detalles:

- **`ref=$[[ component.sha ]]`**: el script de la versión `1.0.0` es el de `1.0.0`, aunque `main` haya cambiado (teoría 04, apartado 2.6).
- **`expand_vars`**: deja que `ci/componentes` se pase a sí mismo `origen: $CI_PROJECT_PATH`, y la variable se expande al crear el pipeline. Sin él, entre comillas simples, llegaría el texto `$CI_PROJECT_PATH`.
- **`bash /tmp/gobernanza.sh`**: fuera del directorio de trabajo, para no ensuciar el repositorio del consumidor.

Y el pipeline de `ci/componentes` lo consume también. Añade al final de `include` en `.gitlab-ci.yml`:

```yaml
  - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/gobernanza@$CI_COMMIT_SHA
    inputs:
      origen: $CI_PROJECT_PATH
```

Así, cada merge request de `ci/componentes` pasará por la auditoría que está cambiando (teoría 08, apartado 2.2). En un push a `main` no entra: su regla es solo de merge request.

```bash
git add .
git commit -S -m "feat: componente gobernanza con su script"
git push origin main
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$PC/repository/tree?path=templates&ref=main" | jq -r '.[].name'
curl -s -H "$H" "$API/projects/$PC/ci/lint?include_merged_yaml=true" \
  | jq -r '.merged_yaml' | grep 'ORIGEN='
# gobernanza.yml
# npm.yml
#   - ORIGEN=$(jq -rn --arg p 'plataforma-<tu-dominio>/ci/componentes' '$p | @uri')
```

La ruta ya expandida en `merged_yaml`: el `expand_vars` se resolvió al crear la configuración.

---

## Paso 5: Un contrato que se defiende

**Por qué**: un input mal pasado no llega al job: el pipeline ni se crea, y el mensaje dice qué input y por qué (teoría 03, apartado 2.2).

```bash
SHA=$(git rev-parse HEAD)
jq -n --arg sha "$SHA" '{content: ("stages: [build, test]\ninclude:\n  - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/npm@" + $sha + "\n    inputs:\n      rutas: src\n      color: rojo\n"), dry_run: true, ref: "main"}' \
  | curl -s --request POST "$API/projects/$PC/ci/lint" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -r '.errors[]'
```

**Verifica**: un solo error que nombra el componente con su SHA y los dos problemas: ``unknown input arguments: color, `rutas` input: provided value is not an array``. Ni el input que sobra ni el del tipo equivocado llegan a ningún job.

Y `main`, en verde:

```bash
PIPE=$(curl -s -H "$H" "$API/projects/$PC/pipelines?ref=main&per_page=1" | jq -r '.[0].id')
esperar "$PC" "$PIPE"
```

**Verifica**: `success`.

---

## ✅ Resultado

- [ ] `ci/componentes` privado, con descripción, README y el runner `docker-app`
- [ ] `templates/npm.yml` con cuatro inputs y `templates/gobernanza.yml` con tres y el contexto `sha`
- [ ] `scripts/gobernanza.sh` en `ci/componentes`, ejecutable
- [ ] El pipeline de `main` en verde, con un test en su informe
- [ ] Viste los dos errores de un input mal pasado

```bash
./scripts/verificar-semana.sh 12
```

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| El pipeline no se crea: `did not find expected ',' or ']'` | Un `$[[` dentro de una lista entre corchetes | Listas en bloque (paso 2) |
| `the component path is not supported` | La ruta no empieza por `$CI_SERVER_FQDN`, o lo sobrescribiste | `$CI_SERVER_FQDN/$CI_PROJECT_PATH/...` |
| `content not found` | El nombre del componente no coincide con el archivo de `templates/` | `npm` para `templates/npm.yml` |
| Jobs en `pending` para siempre | `docker-app` no está habilitado en `ci/componentes` | Paso 1 |
| `test` en verde pero `total_count: 0` | `junit.xml` no está donde dice el informe | `directorio` y el `--test-reporter-destination` |

---

## 🔗 Navegación

[← Anterior: `include` en `app`](01-include-en-app.md) · [Volver a la Semana 12](../README.md) · [Siguiente: Publicar y consumir →](03-publicar-y-consumir.md)

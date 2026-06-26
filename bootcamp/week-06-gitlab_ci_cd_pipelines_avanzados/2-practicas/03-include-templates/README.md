# 🔬 Práctica 03 — Include y Templates

## 🎯 Objetivo

Dividir un `.gitlab-ci.yml` monolítico en módulos reutilizables usando `include:local`. Crear una estructura de directorios clara, verificar que el pipeline resultante funciona igual y explorar la herencia con `extends`.

## ⏱️ Tiempo estimado: 40 minutos

## 📋 Requisitos previos

- Proyecto `api-gateway` con pipeline funcional de las prácticas anteriores
- Familiaridad con la estructura básica de `.gitlab-ci.yml`

---

## 📝 Paso 1: Estructura de Directorios

```bash
cd /tmp/api-gateway-vars   # o donde clonaste el proyecto
git checkout main
git pull

# ¿QUÉ HACE?: Crea la estructura de directorios para los módulos CI
# ¿POR QUÉ?: Separar los concerns — cada módulo tiene un solo propósito
# ¿PARA QUÉ?: Diferentes equipos pueden editar diferentes módulos sin conflictos

mkdir -p .gitlab/ci
```

Estructura final que vamos a crear:

```
.
├── .gitlab-ci.yml          ← Orquestador: solo includes + variables globales
└── .gitlab/
    └── ci/
        ├── stages.yml      ← Definición del orden de stages
        ├── build.yml       ← Jobs de compilación/instalación
        ├── test.yml        ← Jobs de tests
        └── deploy.yml      ← Jobs de deploy con environments
```

---

## 📝 Paso 2: Crear los Módulos

**`.gitlab/ci/stages.yml`**

```yaml
stages:
  - validate
  - build
  - test
  - deploy
```

**`.gitlab/ci/build.yml`**

```yaml
# ── Templates reutilizables ──────────────────────────────────
# El prefijo "." hace que GitLab NO ejecute este job directamente
.base-job:
  image: alpine:latest
  before_script:
    - echo "=== Iniciando job en ${CI_JOB_NAME} ==="
    - echo "Commit: ${CI_COMMIT_SHORT_SHA} en ${CI_COMMIT_REF_NAME}"

# ── Jobs reales ──────────────────────────────────────────────
validate-yaml:
  extends: .base-job
  stage: validate
  script:
    - echo "Validando .gitlab-ci.yml..."
    - ls -la .gitlab/ci/
    - echo "Módulos CI encontrados: $(ls .gitlab/ci/*.yml | wc -l)"
  rules:
    - changes:
        - ".gitlab-ci.yml"
        - ".gitlab/ci/*.yml"
      when: on_success
    - when: never

install-deps:
  extends: .base-job
  stage: build
  script:
    - echo "Simulando instalación de dependencias..."
    - echo "npm ci --prefer-offline"
    - echo "Dependencias instaladas OK"
  artifacts:
    paths:
      - dist/
    expire_in: 1 hour
    when: always

build-app:
  extends: .base-job
  stage: build
  needs: [install-deps]
  script:
    - echo "Compilando aplicación..."
    - mkdir -p dist
    - echo "version=${CI_COMMIT_SHORT_SHA}" > dist/build-info.txt
    - echo "branch=${CI_COMMIT_REF_NAME}" >> dist/build-info.txt
    - echo "timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> dist/build-info.txt
    - cat dist/build-info.txt
  artifacts:
    paths:
      - dist/
    expire_in: 1 day
```

**`.gitlab/ci/test.yml`**

```yaml
.test-base:
  stage: test
  image: alpine:latest
  before_script:
    - echo "Preparando entorno de tests..."

unit-tests:
  extends: .test-base
  script:
    - echo "Ejecutando tests unitarios..."
    - echo "✅ test_login ... PASSED"
    - echo "✅ test_logout ... PASSED"
    - echo "✅ test_register ... PASSED"
    - echo "Coverage: 87%"
  coverage: '/Coverage: (\d+)%/'
  rules:
    - when: always

lint:
  extends: .test-base
  script:
    - echo "Ejecutando linter..."
    - echo "✅ src/ — 0 errores"
    - echo "✅ tests/ — 0 errores"
  allow_failure: true
  rules:
    - when: always

integration-tests:
  extends: .test-base
  script:
    - echo "Tests de integración (simulados)..."
    - echo "✅ test_api_health ... PASSED"
    - echo "✅ test_db_connection ... PASSED"
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_COMMIT_BRANCH == "develop"
    - when: never
```

**`.gitlab/ci/deploy.yml`**

```yaml
.deploy-base:
  stage: deploy
  image: alpine:latest
  before_script:
    - echo "Preparando deploy a ${CI_ENVIRONMENT_NAME}..."

deploy-staging:
  extends: .deploy-base
  script:
    - echo "Desplegando a staging..."
    - cat dist/build-info.txt
    - echo "URL: ${CI_ENVIRONMENT_URL}"
  environment:
    name: staging
    url: https://staging.mi-app.example.com
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"
      when: on_success
    - when: never

deploy-production:
  extends: .deploy-base
  script:
    - echo "Desplegando a producción..."
    - cat dist/build-info.txt
    - echo "URL: ${CI_ENVIRONMENT_URL}"
  environment:
    name: production
    url: https://mi-app.example.com
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: manual
      allow_failure: false
    - when: never
```

**`.gitlab-ci.yml` (archivo orquestador)**

```yaml
# ============================================
# Pipeline principal — solo orquesta includes
# ============================================

include:
  - local: .gitlab/ci/stages.yml
  - local: .gitlab/ci/build.yml
  - local: .gitlab/ci/test.yml
  - local: .gitlab/ci/deploy.yml

# Variables globales compartidas por todos los módulos
variables:
  APP_NAME: "bootcamp-api"
  DOCKER_DRIVER: overlay2
```

---

## 📝 Paso 3: Commitear y Verificar

```bash
# ¿QUÉ HACE?: Agrega todos los módulos y el orquestador al commit
# ¿POR QUÉ?: GitLab necesita que todos los archivos incluidos existan en el mismo commit
# ¿PARA QUÉ?: Si falta un archivo incluido, el pipeline falla con "Local file not found"

git add .gitlab-ci.yml .gitlab/
git status
# Debe mostrar:
#   new file: .gitlab/ci/stages.yml
#   new file: .gitlab/ci/build.yml
#   new file: .gitlab/ci/test.yml
#   new file: .gitlab/ci/deploy.yml
#   modified: .gitlab-ci.yml

git commit -m "ci(week-06): practice 03 — modular pipeline with include:local"
git push origin main
```

**Verificar en la UI que el pipeline incluye todos los jobs:**

```
http://localhost/bootcamp-org/backend/api-gateway/-/pipelines

Stages esperadas:
  validate → build → test → deploy

Jobs esperados:
  validate: validate-yaml (skipped — si no cambiaron archivos CI)
  build:    install-deps, build-app
  test:     unit-tests, lint, integration-tests (solo en main/develop)
  deploy:   deploy-production (manual)
```

---

## 📝 Paso 4: Validar el Pipeline via CI Lint API

```bash
# ¿QUÉ HACE?: Valida la sintaxis del .gitlab-ci.yml EXPANDIDO (con todos los includes)
# ¿POR QUÉ?: El lint verifica no solo el archivo principal sino el resultado de fusionar todos los includes
# ¿PARA QUÉ?: Detectar conflictos de nombres de jobs o errores en los módulos

PROJECT_ID=<tu-project-id>

curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{\"content\": $(cat .gitlab-ci.yml | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')}" \
  "http://localhost/api/v4/projects/${PROJECT_ID}/ci/lint?dry_run=true&ref=main" \
  | python3 -c "
import sys, json
result = json.load(sys.stdin)
if result.get('valid'):
    stages = result.get('stages', [])
    jobs = [j['name'] for j in result.get('jobs', [])]
    print(f'✅ Pipeline válido')
    print(f'   Stages ({len(stages)}): {\" → \".join(stages)}')
    print(f'   Jobs ({len(jobs)}): {jobs}')
else:
    print('❌ Errores:')
    for e in result.get('errors', []):
        print(f'   - {e}')
"
```

---

## 📝 Paso 5: Explorar Herencia con `extends`

Modifica `unit-tests` en `.gitlab/ci/test.yml` para agregar un artifact:

```yaml
unit-tests:
  extends: .test-base
  script:
    - echo "Ejecutando tests unitarios..."
    - mkdir -p test-results
    - echo '<?xml version="1.0"?><testsuites><testsuite name="unit" tests="3" failures="0"><testcase name="test_login"/><testcase name="test_logout"/><testcase name="test_register"/></testsuite></testsuites>' > test-results/junit.xml
    - echo "Coverage: 87%"
  coverage: '/Coverage: (\d+)%/'
  artifacts:
    paths:
      - test-results/
    reports:
      junit: test-results/junit.xml
    expire_in: 1 week
  rules:
    - when: always
```

```bash
git add .gitlab/ci/test.yml
git commit -m "ci: add JUnit artifact to unit-tests"
git push origin main
```

Verificar en la UI del pipeline → job `unit-tests` → pestaña `Tests` → deben aparecer los 3 tests pasados.

---

## 📝 Paso 6: Reto — Include desde Proyecto Compartido

Si quieres explorar `include:project`, crea un segundo proyecto de templates:

```bash
# Crear proyecto de templates via API
curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "ci-templates",
    "namespace_id": 1,
    "visibility": "internal",
    "initialize_with_readme": true
  }' \
  "http://localhost/api/v4/projects/" \
  | python3 -c "import sys,json; p=json.load(sys.stdin); print(f'Proyecto: {p[\"path_with_namespace\"]} (ID: {p[\"id\"]})')"
```

```yaml
# En api-gateway/.gitlab-ci.yml, agrega:
include:
  - local: .gitlab/ci/stages.yml
  - local: .gitlab/ci/build.yml
  - local: .gitlab/ci/test.yml
  - local: .gitlab/ci/deploy.yml
  # Template de proyecto compartido:
  - project: 'root/ci-templates'    # ajustar namespace
    ref: main
    file: '/templates/security-basic.yml'
```

---

## 🔧 Troubleshooting

**`Local file not found`**
```
→ El archivo incluido no existe en el mismo commit
→ Verificar: git ls-files .gitlab/ci/
→ Los includes:local usan el estado del commit actual, no del working directory
→ Solución: git add + git commit + git push antes de disparar el pipeline
```

**`Job names must be unique`**
```
→ Dos archivos incluidos definen un job con el mismo nombre
→ Revisar todos los módulos buscando nombres duplicados
→ Solución: renombrar uno de los jobs o moverlo a un solo archivo
```

**`stages do not contain this job's stage`**
```
→ Un job referencia un stage que no está en stages.yml
→ Verificar que stages.yml incluye todos los stages usados en los módulos
```

---

## ✅ Checklist de verificación

- [ ] Estructura `.gitlab/ci/` con 4 módulos creada y commiteada
- [ ] `.gitlab-ci.yml` solo contiene `include:` y `variables:` (es un orquestador puro)
- [ ] Pipeline en `main` muestra jobs de todos los módulos correctamente
- [ ] CI Lint API confirma que el pipeline expandido es válido y lista todos los jobs
- [ ] Job `unit-tests` tiene artifact JUnit visible en la pestaña `Tests` del pipeline
- [ ] `extends: .test-base` hereda correctamente el `before_script` y la `image`

## 📦 Entregables

- [ ] Captura del pipeline con los 4 stages y todos los jobs visibles
- [ ] Captura del CI Lint API mostrando `valid: true` y la lista de jobs
- [ ] Captura del job `unit-tests` mostrando los tests en la pestaña `Tests`
- [ ] El repositorio con la estructura `.gitlab/ci/` committeada

---

⬅️ **Práctica anterior:** [02 — Rules Condicionales](../02-rules-condicionales/README.md)
➡️ **Siguiente práctica:** [04 — Environments](../04-environments/README.md)

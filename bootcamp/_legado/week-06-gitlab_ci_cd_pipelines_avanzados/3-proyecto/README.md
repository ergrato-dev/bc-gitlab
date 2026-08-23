# 🏗️ Proyecto Semana 06 — Pipeline CI/CD Avanzado

## 📋 Descripción

Evolucionar el pipeline de la Semana 05 a un pipeline CI/CD completo, modular y condicional. El proyecto integra todos los conceptos de la semana: variables protegidas, rules por rama/tag, modularización con `include`, environments staging/production, y opcionalmente un trigger multi-proyecto.

## ⏱️ Tiempo estimado: 90 minutos

## 🎯 Objetivos

Al terminar este proyecto tendrás un pipeline productivo que:
- Ejecuta jobs diferentes según el contexto (rama, MR, tag)
- Protege secretos con variables enmascaradas
- Está dividido en módulos mantenibles por equipos separados
- Rastrea deployments en environments de GitLab con historial
- Es la base de un pipeline real que podrías usar en un proyecto laboral

---

## 📋 Requisitos

### 1. Variables y Secretos

- [ ] Variable `DEPLOY_TOKEN` configurada en Settings → CI/CD → Variables (masked: true, protected: true)
- [ ] Variable `DOCKER_REGISTRY_PASS` configurada (masked: true)
- [ ] Variables predefinidas usadas: `CI_COMMIT_SHORT_SHA` en nombres de artifacts, `CI_COMMIT_REF_NAME` en logs
- [ ] El pipeline NO contiene ningún secreto hardcodeado

### 2. Pipeline Condicional con Rules

- [ ] Jobs de **feature branches**: solo `build` y `test-rapido`
- [ ] Jobs de **develop**: `build`, `test-completo`, `deploy-staging` (automático)
- [ ] Jobs de **main**: `build`, `test-completo`, `deploy-production` (manual)
- [ ] Jobs de **tags `v*`**: todos los tests + `deploy-production` (manual)
- [ ] Jobs de **MR**: `build`, `test-rapido`, optional `security-scan`

### 3. Modularización con `include`

- [ ] Estructura `.gitlab/ci/` con al menos 4 módulos: `stages.yml`, `build.yml`, `test.yml`, `deploy.yml`
- [ ] `.gitlab-ci.yml` principal solo contiene `include:` y `variables:` globales
- [ ] Templates internos (`.nombre:`) para evitar duplicación entre jobs

### 4. Environments

- [ ] Environment `staging` con URL y despliegue automático desde `develop`
- [ ] Environment `production` con URL y despliegue manual desde `main`/tags
- [ ] Historial de al menos 3 deployments a staging
- [ ] Action `on_stop` configurada para staging

### 5. (Extra) Trigger Multi-Proyecto

- [ ] Job que dispara el pipeline de un segundo proyecto al publicar un tag

---

## 📁 Estructura Esperada

```
.gitlab-ci.yml                   ← Orquestador
.gitlab/
  ci/
    stages.yml                   ← stages: validate, build, test, security, deploy
    build.yml                    ← install-deps, build-app
    test.yml                     ← unit-tests, integration-tests, lint
    security.yml                 ← dependency-scan, sast-basic (opcional)
    deploy.yml                   ← deploy-staging, deploy-production, stop-staging
```

---

## 📝 Paso 1: Preparar el Repositorio

```bash
cd /tmp
git clone http://root:$GITLAB_ADMIN_PASS@localhost/bootcamp-org/backend/api-gateway.git api-gateway-project
cd api-gateway-project

# Asegurarse de tener main y develop
git checkout main && git pull
git checkout develop 2>/dev/null || git checkout -b develop
git push origin develop
git checkout main
```

---

## 📝 Paso 2: Configurar Variables del Proyecto

```bash
PROJECT_ID=<tu-project-id>

# Función helper para crear variables
create_var() {
  local key=$1 value=$2 masked=$3 protected=$4
  curl --silent --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{\"key\": \"$key\", \"value\": \"$value\", \"masked\": $masked, \"protected\": $protected}" \
    "http://localhost/api/v4/projects/${PROJECT_ID}/variables" \
    | python3 -c "import sys,json; r=json.load(sys.stdin); print(f'  {r.get(\"key\", r)}: masked={r.get(\"masked\")}, protected={r.get(\"protected\")}')"
}

echo "Configurando variables del proyecto..."
create_var "DEPLOY_TOKEN" "token-deploy-bootcamp-2025x" "true" "true"
create_var "DOCKER_REGISTRY_PASS" "docker-pass-bootcamp-demo" "true" "false"
create_var "NOTIFY_WEBHOOK" "https://hooks.example.com/notify" "false" "false"

echo "Variables configuradas ✅"
```

---

## 📝 Paso 3: Crear los Módulos CI

**`.gitlab/ci/stages.yml`**

```yaml
stages:
  - validate
  - build
  - test
  - security
  - deploy
```

**`.gitlab/ci/build.yml`**

```yaml
.build-base:
  image: alpine:latest
  before_script:
    - echo "Build iniciado por ${GITLAB_USER_NAME:-pipeline}"
    - echo "Commit: ${CI_COMMIT_SHORT_SHA} | Branch: ${CI_COMMIT_REF_NAME}"

validate-yaml:
  extends: .build-base
  stage: validate
  script:
    - echo "✅ Validando estructura del proyecto CI..."
    - ls -la .gitlab/ci/
  rules:
    - changes: [".gitlab-ci.yml", ".gitlab/ci/*.yml"]
    - when: never

install-deps:
  extends: .build-base
  stage: build
  script:
    - echo "📦 Instalando dependencias..."
    - echo "npm ci --prefer-offline"
    - echo "✅ Instalación completada"
  artifacts:
    paths: [dist/]
    expire_in: 1 hour
    when: always
  rules:
    - when: always

build-app:
  extends: .build-base
  stage: build
  needs: [install-deps]
  script:
    - echo "🔨 Compilando aplicación..."
    - mkdir -p dist
    - echo "version=${CI_COMMIT_SHORT_SHA}" > dist/build-info.txt
    - echo "branch=${CI_COMMIT_REF_NAME}" >> dist/build-info.txt
    - echo "timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> dist/build-info.txt
    - echo "deploy_token_length=${#DEPLOY_TOKEN}" >> dist/build-info.txt
    - cat dist/build-info.txt
    - echo "✅ Build completado"
  artifacts:
    name: "${APP_NAME}-${CI_COMMIT_SHORT_SHA}"
    paths: [dist/]
    expire_in: 1 day
  rules:
    - when: always
```

**`.gitlab/ci/test.yml`**

```yaml
.test-base:
  image: alpine:latest
  before_script:
    - echo "🧪 Iniciando tests en ${CI_COMMIT_REF_NAME}..."

unit-tests:
  extends: .test-base
  stage: test
  script:
    - echo "Ejecutando tests unitarios..."
    - mkdir -p test-results
    - |
      cat > test-results/junit.xml << 'XML'
      <?xml version="1.0"?>
      <testsuites>
        <testsuite name="unit" tests="5" failures="0" time="1.2">
          <testcase name="test_auth_login" time="0.2"/>
          <testcase name="test_auth_logout" time="0.1"/>
          <testcase name="test_user_create" time="0.3"/>
          <testcase name="test_user_validate" time="0.4"/>
          <testcase name="test_health_check" time="0.2"/>
        </testsuite>
      </testsuites>
      XML
    - echo "✅ 5/5 tests pasados"
    - echo "Coverage: 85%"
  coverage: '/Coverage: (\d+)%/'
  artifacts:
    paths: [test-results/]
    reports:
      junit: test-results/junit.xml
    expire_in: 1 week
    when: always
  rules:
    - when: always

integration-tests:
  extends: .test-base
  stage: test
  script:
    - echo "Ejecutando tests de integración..."
    - echo "✅ test_api_health: PASSED"
    - echo "✅ test_db_connection: PASSED"
    - echo "✅ test_auth_flow: PASSED"
    - echo "Coverage: 78%"
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: on_success
    - if: $CI_COMMIT_BRANCH == "develop"
      when: on_success
    - when: never

lint:
  extends: .test-base
  stage: test
  script:
    - echo "Ejecutando linter..."
    - echo "✅ 0 errores de lint"
  allow_failure: true
  rules:
    - when: always
```

**`.gitlab/ci/security.yml`**

```yaml
dependency-scan:
  stage: security
  image: alpine:latest
  script:
    - echo "🔍 Escaneando dependencias vulnerables..."
    - echo "ℹ️ En producción: usar template Security/Dependency-Scanning.gitlab-ci.yml"
    - echo "✅ 0 vulnerabilidades críticas encontradas"
  allow_failure: true
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - when: never
```

**`.gitlab/ci/deploy.yml`**

```yaml
variables:
  STAGING_URL: "https://staging.bootcamp-app.example.com"
  PRODUCTION_URL: "https://bootcamp-app.example.com"

.deploy-base:
  stage: deploy
  image: alpine:latest
  before_script:
    - echo "🚀 Deploy a ${CI_ENVIRONMENT_NAME}"
    - echo "Commit: ${CI_COMMIT_SHORT_SHA}"
    - echo "Token configurado: ${#DEPLOY_TOKEN} chars"

deploy-staging:
  extends: .deploy-base
  script:
    - echo "Desplegando a staging..."
    - cat dist/build-info.txt
    - echo "✅ Deploy a ${STAGING_URL} completado"
  environment:
    name: staging
    url: $STAGING_URL
    on_stop: stop-staging
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"
      when: on_success
    - when: never

stop-staging:
  extends: .deploy-base
  script:
    - echo "Deteniendo staging..."
    - echo "✅ Staging detenido"
  environment:
    name: staging
    action: stop
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"
      when: manual
  allow_failure: true

deploy-production:
  extends: .deploy-base
  script:
    - echo "Desplegando a producción..."
    - cat dist/build-info.txt
    - echo "✅ Deploy a ${PRODUCTION_URL} completado"
  environment:
    name: production
    url: $PRODUCTION_URL
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: manual
      allow_failure: false
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
      when: manual
      allow_failure: false
    - when: never
```

**`.gitlab-ci.yml` (orquestador)**

```yaml
# ============================================================
# Semana 06 — Pipeline CI/CD Avanzado
# ============================================================

include:
  - local: .gitlab/ci/stages.yml
  - local: .gitlab/ci/build.yml
  - local: .gitlab/ci/test.yml
  - local: .gitlab/ci/security.yml
  - local: .gitlab/ci/deploy.yml

variables:
  APP_NAME: "bootcamp-api"
  DOCKER_DRIVER: overlay2
```

---

## 📝 Paso 4: Commit y Verificar Pipeline Completo

```bash
mkdir -p .gitlab/ci

# Crear todos los archivos del paso 3...
# (copiar el contenido de cada bloque al archivo correspondiente)

git add .gitlab-ci.yml .gitlab/
git commit -m "feat(week-06): complete CI/CD pipeline — variables, rules, include, environments"
git push origin main
```

**Verificar en la UI:**
```
CI/CD → Pipelines → Pipeline en main
  validate: validate-yaml (skipped si no cambiaron CIs)
  build:    install-deps ✅, build-app ✅
  test:     unit-tests ✅, integration-tests ✅, lint ✅
  security: dependency-scan ✅
  deploy:   deploy-production ⏸️ (manual)
```

---

## 📝 Paso 5: Verificar Escenarios

```bash
# Escenario 1: develop → staging automático
git checkout develop
git merge main
git push origin develop
# → debe ejecutar deploy-staging automáticamente

# Escenario 2: feature branch → solo tests rápidos
git checkout -b feature/new-endpoint
git commit --allow-empty -m "feat: add /health endpoint"
git push origin feature/new-endpoint
# → solo build + unit-tests + lint

# Escenario 3: tag → deploy-production disponible
git checkout main
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0
# → todos los jobs + deploy-production (manual)
```

---

## 📝 Paso 6: Verificación Final via API

```bash
PROJECT_ID=<tu-project-id>

echo "=== VARIABLES ==="
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/${PROJECT_ID}/variables" \
  | python3 -c "
import sys, json
for v in json.load(sys.stdin):
    print(f'  {v[\"key\"]}: masked={v[\"masked\"]}, protected={v[\"protected\"]}')
"

echo ""
echo "=== ENVIRONMENTS ==="
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/${PROJECT_ID}/environments" \
  | python3 -c "
import sys, json
for e in json.load(sys.stdin):
    print(f'  [{e.get(\"state\")}] {e[\"name\"]} → {e.get(\"external_url\", \"(sin URL)\")}')
"

echo ""
echo "=== ÚLTIMOS 5 PIPELINES ==="
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/${PROJECT_ID}/pipelines?per_page=5" \
  | python3 -c "
import sys, json
icons = {'success': '✅', 'failed': '❌', 'running': '🔄', 'pending': '⏳', 'manual': '⏸️'}
for p in json.load(sys.stdin):
    icon = icons.get(p['status'], '?')
    print(f'  {icon} #{p[\"id\"]} [{p[\"status\"]:12}] {p[\"ref\"]}')
"
```

---

## ✅ Checklist Final

- [ ] Variables `DEPLOY_TOKEN` y `DOCKER_REGISTRY_PASS` configuradas (masked/protected)
- [ ] Pipeline en `main`: todos los stages hasta deploy-production (manual)
- [ ] Pipeline en `develop`: build + test + deploy-staging (automático)
- [ ] Pipeline en `feature/*`: solo build + test-rapido + lint
- [ ] Pipeline en tag `v1.0.0`: completo con deploy-production disponible
- [ ] Environments `staging` y `production` en `Operate → Environments`
- [ ] Historial de deployments con al menos 3 entradas en staging

## 📦 Entregables

- [ ] URL del proyecto en `http://localhost/bootcamp-org/backend/api-gateway`
- [ ] `.gitlab-ci.yml` orquestador + 5 módulos en `.gitlab/ci/` en `main`
- [ ] Capturas de los 4 escenarios de pipeline (main, develop, feature, tag)
- [ ] Captura de `Operate → Environments` con staging y production
- [ ] Output del script de verificación final (variables + environments + pipelines)

---

⬅️ **Prácticas:** [04 — Environments](../2-practicas/04-environments/README.md)
➡️ **Glosario:** [5-glosario/README.md](../5-glosario/README.md)

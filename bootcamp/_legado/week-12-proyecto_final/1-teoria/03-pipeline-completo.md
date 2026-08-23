# 03 — Diseño del Pipeline Completo

El pipeline final integra todo lo visto en el bootcamp: stages múltiples, seguridad, environments, templates reutilizables, cache, artifacts y despliegue condicional. No es el pipeline más complejo posible — es el más completo dadas las capacidades de GitLab CE.

---

## Estructura de stages y decisiones de diseño

```yaml
stages:
  - build        # Compilar código, construir imagen Docker
  - test         # Tests unitarios, cobertura, linting
  - security     # SAST, Secret Detection, Container Scanning
  - package      # Etiquetar imagen, generar artifacts de release
  - deploy       # Deploy a staging (automático) o production (manual)
```

El orden importa: no tiene sentido hacer el deploy si los tests fallan, y no tiene sentido escanear una imagen que no existe aún. El stage `security` va después de `test` porque los templates de SAST necesitan el código fuente completo, y `container-scanning` necesita la imagen ya construida.

---

## Archivo principal .gitlab-ci.yml

```yaml
# ¿QUÉ HACE?: Define el pipeline completo del proyecto final
# ¿POR QUÉ?: Un pipeline bien estructurado da feedback rápido y previene deploys inseguros
# ¿PARA QUÉ?: Automatiza todo el flujo desde el push hasta el deploy con seguridad integrada

stages:
  - build
  - test
  - security
  - package
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: ""
  # La imagen principal del proyecto se construye a partir del commit actual
  APP_IMAGE: $CI_REGISTRY_IMAGE/app:$CI_COMMIT_SHORT_SHA
  LATEST_IMAGE: $CI_REGISTRY_IMAGE/app:latest

# Cache de dependencias para acelerar jobs de test
.python-cache:
  cache:
    key: "$CI_COMMIT_REF_SLUG-python"
    paths:
      - .venv/
      - .cache/pip/
    policy: pull-push

# ─── STAGE: BUILD ─────────────────────────────────────────────────────────────
include:
  - local: ci-templates/build.yml
  - local: ci-templates/test.yml
  - local: ci-templates/deploy.yml
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml

build-app:
  extends: .build-docker-template
  stage: build

# ─── STAGE: TEST ──────────────────────────────────────────────────────────────
unit-tests:
  extends: .python-cache
  stage: test
  image: python:3.11-slim
  script:
    - pip install --quiet -r requirements.txt
    - pytest tests/unit/ --junitxml=junit.xml --cov=src --cov-report=xml
  coverage: '/TOTAL.*\s+(\d+%)$/'
  artifacts:
    when: always
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
    paths:
      - junit.xml
      - coverage.xml
    expire_in: 1 week

lint:
  stage: test
  image: python:3.11-slim
  script:
    - pip install --quiet ruff
    - ruff check src/ --output-format=gitlab > gl-code-quality-report.json
  artifacts:
    reports:
      codequality: gl-code-quality-report.json
  allow_failure: true   # No bloquea el pipeline pero muestra advertencia en MR

# ─── STAGE: SECURITY ──────────────────────────────────────────────────────────
# Los templates SAST, Secret-Detection, Container-Scanning y Dependency-Scanning
# se auto-configuran. Solo necesitamos sobrescribir variables para Container Scanning:
container-scanning:
  variables:
    CS_IMAGE: $APP_IMAGE
    CS_DOCKERFILE_PATH: Dockerfile

# ─── STAGE: PACKAGE ───────────────────────────────────────────────────────────
tag-release:
  stage: package
  image: docker:24
  services:
    - docker:24-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker pull $APP_IMAGE
    - docker tag $APP_IMAGE $LATEST_IMAGE
    - docker tag $APP_IMAGE $CI_REGISTRY_IMAGE/app:$CI_COMMIT_TAG
    - docker push $LATEST_IMAGE
    - docker push $CI_REGISTRY_IMAGE/app:$CI_COMMIT_TAG
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/  # Solo en tags semver (v1.2.3)

# ─── STAGE: DEPLOY ────────────────────────────────────────────────────────────
deploy-staging:
  extends: .deploy-template
  stage: deploy
  variables:
    DEPLOY_PORT: "5001"
    DEPLOY_NAME: "app-staging"
    DEPLOY_ENV_VARS: "-e ENV=staging -e LOG_LEVEL=debug"
  environment:
    name: staging
    url: http://$CI_SERVER_HOST:5001
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: on_success

deploy-production:
  extends: .deploy-template
  stage: deploy
  variables:
    DEPLOY_PORT: "5000"
    DEPLOY_NAME: "app-production"
    DEPLOY_ENV_VARS: "-e ENV=production -e LOG_LEVEL=warn"
  environment:
    name: production
    url: http://$CI_SERVER_HOST:5000
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
      when: manual   # Requiere click manual en GitLab UI
```

---

## Templates CI reutilizables

```yaml
# ci-templates/build.yml
# ¿QUÉ HACE?: Template para construir y subir la imagen Docker al Container Registry
# ¿POR QUÉ?: El mismo proceso de build se reutiliza en otros proyectos del grupo
# ¿PARA QUÉ?: Mantener consistencia entre proyectos y reducir duplicación

.build-docker-template:
  image: docker:24
  services:
    - docker:24-dind
  variables:
    DOCKER_BUILDKIT: "1"
    DOCKERFILE_PATH: "Dockerfile"
    BUILD_CONTEXT: "."
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - |
      # Build con cache de capas previas para acelerar
      docker pull $CI_REGISTRY_IMAGE/app:latest || true
      docker build \
        --build-arg BUILDKIT_INLINE_CACHE=1 \
        --cache-from $CI_REGISTRY_IMAGE/app:latest \
        --file $DOCKERFILE_PATH \
        --tag $APP_IMAGE \
        $BUILD_CONTEXT
      docker push $APP_IMAGE
  after_script:
    - docker logout $CI_REGISTRY
  tags:
    - docker
```

```yaml
# ci-templates/deploy.yml
# ¿QUÉ HACE?: Template para desplegar la imagen en el servidor de destino
# ¿POR QUÉ?: El proceso de deploy es el mismo para staging y production, solo cambia el puerto
# ¿PARA QUÉ?: Separar la lógica de deploy de las reglas de cuándo ejecutarlo

.deploy-template:
  image: docker:24
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker pull $APP_IMAGE
    - docker stop $DEPLOY_NAME 2>/dev/null || true
    - docker rm $DEPLOY_NAME 2>/dev/null || true
    - |
      docker run -d \
        --name $DEPLOY_NAME \
        --restart unless-stopped \
        -p $DEPLOY_PORT:8080 \
        --network proyecto-final-net \
        $DEPLOY_ENV_VARS \
        $APP_IMAGE
    - |
      # Smoke test: verificar que la app respondió en 30s
      timeout=30
      while [ $timeout -gt 0 ]; do
        if curl -sf http://localhost:$DEPLOY_PORT/health > /dev/null 2>&1; then
          echo "✅ App respondiendo en puerto $DEPLOY_PORT"
          break
        fi
        sleep 2
        timeout=$((timeout - 2))
      done
      [ $timeout -gt 0 ] || (echo "❌ App no respondió en 30s" && exit 1)
  after_script:
    - docker logout $CI_REGISTRY
  tags:
    - docker
```

---

## Reglas de ejecución (rules vs only/except)

En proyectos modernos de GitLab, `rules:` reemplaza a `only:/except:`. Es más expresivo y permite condiciones complejas:

```yaml
# Patrones comunes de rules:

# Ejecutar en cualquier branch excepto main
rules:
  - if: $CI_COMMIT_BRANCH && $CI_COMMIT_BRANCH != "main"

# Ejecutar solo en MRs hacia main
rules:
  - if: $CI_MERGE_REQUEST_TARGET_BRANCH_NAME == "main"

# Ejecutar en push a main O en tags semver
rules:
  - if: $CI_COMMIT_BRANCH == "main"
  - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/

# No ejecutar en pipelines programados (scheduled)
rules:
  - if: $CI_PIPELINE_SOURCE == "schedule"
    when: never
  - when: on_success

# Ejecutar solo si cambió un archivo específico
rules:
  - changes:
      - Dockerfile
      - requirements.txt
```

---

## Variables CI/CD protegidas y enmascaradas

```bash
# ¿QUÉ HACE?: Lista las variables CI/CD configuradas en el proyecto
# ¿POR QUÉ?: Verificar que todas las variables sensibles están protegidas y enmascaradas
# ¿PARA QUÉ?: Sin estas variables, el pipeline falla al intentar autenticarse al Registry

# Via API: listar variables del proyecto
curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/variables" | \
  jq '.[] | {key, protected, masked, environment_scope}'
```

Variables requeridas para el proyecto final:

| Variable | Protegida | Enmascarada | Scope |
|----------|:---------:|:-----------:|-------|
| `CI_REGISTRY_USER` | ✅ | ❌ | All |
| `CI_REGISTRY_PASSWORD` | ✅ | ✅ | All |
| `STAGING_SSH_KEY` | ✅ | ❌ (tipo File) | staging |
| `PRODUCTION_SSH_KEY` | ✅ | ❌ (tipo File) | production |
| `DEPLOY_HOST_STAGING` | ❌ | ❌ | staging |
| `DEPLOY_HOST_PRODUCTION` | ✅ | ❌ | production |

---

## Optimización con cache de capas Docker

El build sin cache puede tardar 5-10 minutos. Con cache de capas, baja a 30-60 segundos en cambios de código (sin cambios en dependencias):

```dockerfile
# Dockerfile optimizado para CI/CD — capas ordenadas de menos a más cambiante
FROM python:3.11-slim

WORKDIR /app

# Capa de dependencias — cambia raramente
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Capa de código — cambia en cada commit
COPY src/ ./src/

# Usuario no-root para seguridad
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8080
CMD ["python", "-m", "gunicorn", "src.app:create_app()", "--bind", "0.0.0.0:8080"]
```

---

## Monitoreo del pipeline via API

```bash
# ¿QUÉ HACE?: Consulta el estado de los últimos pipelines via API
# ¿POR QUÉ?: Permite scripts de automatización que esperan que el pipeline termine
# ¿PARA QUÉ?: CI/CD encadenado o scripts de release que dependen del pipeline

PROJECT_ID=1
TOKEN=$ADMIN_TOKEN

# Último pipeline en main
curl -s --header "PRIVATE-TOKEN: $TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines?ref=main&per_page=1" | \
  jq '.[0] | {id, status, duration, web_url}'

# Jobs del pipeline con su estado y duración
PIPELINE_ID=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines?per_page=1" | jq '.[0].id')

curl -s --header "PRIVATE-TOKEN: $TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines/$PIPELINE_ID/jobs" | \
  jq '.[] | {name, stage, status, duration: (.duration // 0 | floor)}'
```

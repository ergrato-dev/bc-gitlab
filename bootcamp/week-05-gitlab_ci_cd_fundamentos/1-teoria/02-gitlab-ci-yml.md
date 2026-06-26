# 📖 02 — Estructura del Archivo .gitlab-ci.yml

## 🎯 Objetivos de aprendizaje

- ✅ Entender la estructura YAML de un archivo `.gitlab-ci.yml`
- ✅ Conocer las keywords fundamentales: `stages`, `image`, `script`, `rules`
- ✅ Usar variables de entorno en el pipeline
- ✅ Controlar cuándo se ejecuta el pipeline con `rules` y `only/except`
- ✅ Validar la sintaxis del `.gitlab-ci.yml` antes de hacer push

---

## 🤔 ¿Qué es el .gitlab-ci.yml?

El `.gitlab-ci.yml` es el contrato entre tu código y el CI/CD. Defines **qué** debe ejecutarse, **cuándo**, en **qué orden**, y con **qué imagen Docker**. GitLab lo lee automáticamente en cada push.

**Analogía:** El `.gitlab-ci.yml` es como una receta de cocina. Especificas los ingredientes (imagen Docker = la cocina), los pasos (script = la receta), el orden (stages), y cuándo cocinar (rules = solo los viernes o solo cuando hay ingredientes frescos). El cocinero (Runner) sigue la receta exactamente.

---

## 📐 Anatomía Completa de un .gitlab-ci.yml

```yaml
# ─────────────────────────────────────────────────
# SECCIÓN 1: Configuración global (aplica a todos los jobs)
# ─────────────────────────────────────────────────

# Imagen Docker por defecto para todos los jobs
image: node:20-alpine

# Variables disponibles en todos los jobs
variables:
  NODE_ENV: test
  APP_VERSION: "1.0.0"
  COVERAGE_THRESHOLD: "80"

# Comandos que se ejecutan ANTES del script en cada job
before_script:
  - npm ci --quiet

# ─────────────────────────────────────────────────
# SECCIÓN 2: Definición de etapas (orden del pipeline)
# ─────────────────────────────────────────────────

stages:
  - validate      # Primero: lint y seguridad
  - test          # Segundo: tests unitarios e integración
  - build         # Tercero: compilar/empaquetar
  - deploy        # Cuarto: desplegar

# ─────────────────────────────────────────────────
# SECCIÓN 3: Definición de los jobs
# ─────────────────────────────────────────────────

lint:
  stage: validate
  script:
    - npm run lint
    - npm run format:check
  rules:
    - if: $CI_MERGE_REQUEST_IID         # Solo en MRs

security-scan:
  stage: validate
  image: semgrep/semgrep:latest
  script:
    - semgrep --config=auto src/
  rules:
    - if: $CI_COMMIT_BRANCH == "main"   # Solo en main

unit-tests:
  stage: test
  script:
    - npm test -- --coverage
  coverage: '/Coverage: \d+\.\d+%/'    # Extrae cobertura del output
  artifacts:
    paths:
      - coverage/
    expire_in: 1 week

build-app:
  stage: build
  script:
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 day
  rules:
    - if: $CI_COMMIT_BRANCH == "main"

deploy-staging:
  stage: deploy
  script:
    - ./scripts/deploy.sh staging
  environment:
    name: staging
    url: https://staging.app.com
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

---

## 🔑 Keywords Fundamentales

### `stages` — Orden del Pipeline

```yaml
stages:
  - validate
  - test
  - build
  - deploy
```

- Los jobs de la misma stage se ejecutan **en paralelo**
- Las stages se ejecutan **en secuencia**: `validate` termina → `test` empieza
- Si un job falla, los jobs de stages siguientes NO se ejecutan (por defecto)

### `image` — La Imagen Docker

```yaml
# Global (para todos los jobs):
image: node:20-alpine

# Por job (sobreescribe el global):
security-scan:
  image: semgrep/semgrep:latest
  script:
    - semgrep --config=auto .
```

La imagen Docker define el entorno de ejecución. El Runner descarga la imagen y ejecuta los comandos dentro de un contenedor fresco por cada job.

```yaml
# Imágenes comunes por ecosistema:
# Node.js:    node:20-alpine, node:18-slim
# Python:     python:3.12-slim, python:3.11-alpine
# Java:       maven:3.9-eclipse-temurin-17, gradle:8-jdk17
# Go:         golang:1.22-alpine
# PHP:        php:8.3-cli-alpine
# Ruby:       ruby:3.3-alpine
# Docker:     docker:27
# GitLab CLI: alpine:latest (instalar glab manualmente)
```

### `script` — Los Comandos

```yaml
unit-tests:
  script:
    - echo "Iniciando tests..."     # Comando 1
    - npm install                    # Comando 2
    - npm test                       # Comando 3: si falla, el job falla
    - echo "Tests completados"       # Solo se ejecuta si el anterior pasó
```

Cada línea es un comando de shell. Si cualquier comando devuelve código de salida != 0, el job falla y los comandos siguientes NO se ejecutan.

### `before_script` y `after_script`

```yaml
# Global — aplica a todos los jobs:
before_script:
  - npm ci --quiet

# Por job — sobreescribe el global:
integration-tests:
  before_script:
    - npm ci --quiet
    - docker-compose up -d db redis
  script:
    - npm run test:integration
  after_script:
    - docker-compose down    # Se ejecuta incluso si el job falla
```

### `variables` — Variables de Entorno

```yaml
# Variables definidas en el pipeline:
variables:
  APP_ENV: production
  REGISTRY: registry.gitlab.com
  IMAGE_NAME: $CI_REGISTRY_IMAGE/app   # Usando variable predefinida de GitLab

# Acceder en scripts:
build:
  script:
    - echo "Construyendo para $APP_ENV"
    - docker build -t $IMAGE_NAME:$CI_COMMIT_SHA .
```

**Variables predefinidas de GitLab (siempre disponibles):**

```
$CI_COMMIT_SHA          → Hash completo del commit (abc1234...)
$CI_COMMIT_SHORT_SHA    → Hash corto (abc1234)
$CI_COMMIT_BRANCH       → Nombre de la rama actual (main, feature/42-jwt)
$CI_MERGE_REQUEST_IID   → ID del MR (solo disponible en contexto de MR)
$CI_PROJECT_ID          → ID numérico del proyecto
$CI_PROJECT_NAME        → Nombre del proyecto (api-gateway)
$CI_PROJECT_PATH        → Ruta completa (bootcamp-org/backend/api-gateway)
$CI_PIPELINE_ID         → ID del pipeline
$CI_JOB_NAME            → Nombre del job actual
$CI_COMMIT_TAG          → El tag del commit (si es un tag)
$GITLAB_USER_NAME       → Usuario que disparó el pipeline
$CI_REGISTRY            → URL del GitLab Container Registry
$CI_REGISTRY_IMAGE      → URL completa de la imagen del proyecto
$CI_REGISTRY_USER       → Usuario para el registry
$CI_REGISTRY_PASSWORD   → Password para el registry
```

---

## 🎛️ Controlar Cuándo se Ejecuta: `rules`

```yaml
deploy-produccion:
  stage: deploy
  script:
    - ./deploy.sh production
  rules:
    # Regla 1: Solo si es un tag semver (v1.0.0, v2.3.1)
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
      when: on_success

    # Regla 2: Si es la rama main pero NO un tag
    - if: $CI_COMMIT_BRANCH == "main" && $CI_COMMIT_TAG == null
      when: manual    # Requiere click manual para ejecutar
      allow_failure: false

    # Regla 3: Ninguna de las anteriores — no ejecutar el job
    - when: never
```

**Valores de `when`:**

```yaml
when: on_success  # Solo si todos los jobs anteriores pasaron (default)
when: on_failure  # Solo si algún job anterior falló (útil para notificaciones)
when: always      # Siempre (incluso si jobs anteriores fallaron)
when: manual      # Solo al clickear manualmente en la UI
when: delayed     # Con un delay: start_in: "5 minutes"
when: never       # Nunca (efectivamente deshabilita el job)
```

**Condiciones comunes en `rules`:**

```yaml
rules:
  # Solo en ramas (no en MRs):
  - if: $CI_COMMIT_BRANCH

  # Solo en MRs:
  - if: $CI_MERGE_REQUEST_IID

  # Solo en la rama main:
  - if: $CI_COMMIT_BRANCH == "main"

  # Solo en tags:
  - if: $CI_COMMIT_TAG

  # Solo cuando ciertos archivos cambian:
  - changes:
      - "src/**/*"
      - "package.json"

  # Combinar condiciones:
  - if: $CI_COMMIT_BRANCH == "main"
    changes:
      - "src/**/*"
```

---

## 🔒 Variables Secretas (CI/CD Variables)

Las variables con valores secretos (tokens, passwords, API keys) NO deben estar en el `.gitlab-ci.yml`. Se configuran en GitLab como variables protegidas:

```
Proyecto → Settings → CI/CD → Variables → Add variable

Key:       PRODUCTION_DB_PASSWORD
Value:     <el valor real>
Type:      Variable (o File para contenidos de archivo)
Protected: ✓ (solo disponible en ramas/tags protegidos)
Masked:    ✓ (no aparece en los logs del pipeline)
```

Usarlas en el pipeline como cualquier variable de entorno:

```yaml
deploy:
  script:
    - export DB_URL="postgresql://user:$PRODUCTION_DB_PASSWORD@db:5432/app"
    - ./migrate.sh
```

---

## ✅ Validar el .gitlab-ci.yml

Antes de hacer push y esperar que falle el pipeline, valida la sintaxis:

### CI Lint en la UI de GitLab

```
Proyecto → CI/CD → Pipelines → CI Lint (botón en la esquina)
→ Pegar el contenido del .gitlab-ci.yml
→ Click "Validate" — muestra errores de sintaxis y la resolución de stages/jobs
```

### Validación via API

```bash
# ¿QUÉ HACE?: Valida el .gitlab-ci.yml sin necesidad de hacer push
# ¿POR QUÉ?: Detecta errores de sintaxis YAML antes de disparar un pipeline fallido
# ¿PARA QUÉ?: Ahorra tiempo en el ciclo desarrollo → push → pipeline fallido → fix
curl --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{
    \"content\": $(cat .gitlab-ci.yml | python3 -c 'import sys, json; print(json.dumps(sys.stdin.read()))')
  }" \
  "http://localhost/api/v4/ci/lint" \
  | python3 -c "
import sys, json
result = json.load(sys.stdin)
if result.get('valid'):
    print('✅ .gitlab-ci.yml es válido')
    print(f'   Stages: {result.get(\"stages\", [])}')
    print(f'   Jobs: {[j[\"name\"] for j in result.get(\"jobs\", [])]}')
else:
    print('❌ Errores encontrados:')
    for error in result.get('errors', []):
        print(f'   - {error}')
"
```

---

## 🖼️ Diagrama: Anatomía del .gitlab-ci.yml

![Diagrama de la estructura del .gitlab-ci.yml](../0-assets/02-ci-yml-anatomy.svg)

> **Diagrama:** Muestra la relación entre las secciones globales (image, variables, before_script), las stages y los jobs individuales, indicando cuáles secciones se heredan globalmente y cuáles se sobreescriben a nivel de job.

---

## 🤔 Preguntas de reflexión

1. Tienes 5 jobs en la stage `test` que tardan entre 2 y 8 minutos cada uno. ¿Cuánto tarda la stage `test` en completarse? ¿Cuántos Runners necesitas para la máxima paralelización?

2. La keyword `before_script` a nivel global aplica a todos los jobs. Si tienes un job de seguridad que usa una imagen diferente (Semgrep) donde `npm ci` no aplica, ¿cómo lo manejarías?

3. Una variable `PRODUCTION_DB_PASSWORD` está configurada como "Protected". ¿Qué ocurre si un developer crea una rama `feature/test` e intenta usar esa variable en el pipeline?

4. El job `deploy-produccion` tiene `when: manual`. ¿Quién puede clickear ese botón? ¿Hay alguna forma de restringir quién puede disparar un deploy manual?

5. ¿Por qué no deberías poner credenciales (passwords, tokens) directamente en el `.gitlab-ci.yml` aunque el repositorio sea privado?

---

## 📚 Recursos adicionales

- [.gitlab-ci.yml keyword reference](https://docs.gitlab.com/ee/ci/yaml/)
- [Predefined CI/CD variables](https://docs.gitlab.com/ee/ci/variables/predefined_variables.html)
- [CI/CD variables — Secrets](https://docs.gitlab.com/ee/ci/variables/)
- [Rules — controlar cuándo se ejecutan los jobs](https://docs.gitlab.com/ee/ci/yaml/#rules)
- [CI Lint API](https://docs.gitlab.com/ee/api/lint.html)

---

⬅️ **Lección anterior:** [01 — ¿Qué es CI/CD?](./01-que-es-ci-cd.md)
➡️ **Siguiente lección:** [03 — Stages y Jobs](./03-stages-y-jobs.md)

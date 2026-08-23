# 📖 04 — Imágenes Docker en CI/CD

## 🎯 Objetivos de aprendizaje

- ✅ Entender por qué los jobs de CI se ejecutan dentro de contenedores Docker
- ✅ Elegir la imagen Docker adecuada para cada tipo de job
- ✅ Usar `services` para levantar dependencias (base de datos, cache) durante los tests
- ✅ Construir y publicar imágenes Docker desde el pipeline con el GitLab Registry
- ✅ Entender las alternativas a Docker-in-Docker (DinD) y sus trade-offs

---

## 🤔 ¿Por Qué Docker en CI?

Antes de Docker en CI, cada runner necesitaba tener instalado Node, Java, Python, Ruby... todo. Actualizar una versión rompía jobs de otros proyectos. Era el caos del "funciona en mi máquina" — pero en el servidor de CI.

**Analogía:** Las imágenes Docker en CI son como cajas de herramientas especializadas. Para arreglar la electricidad traes la caja de electricista (imagen Node). Para plomería traes la caja de plomero (imagen Python). No mezclas herramientas ni necesitas tener todo en un solo lugar permanente. Cada trabajo usa exactamente las herramientas que necesita.

---

## 🐳 La Keyword `image`

```yaml
# ¿QUÉ HACE?: Define el contenedor Docker donde se ejecuta el job
# ¿POR QUÉ?: Cada job necesita un entorno específico (Node 20, Python 3.12, etc.)
# ¿PARA QUÉ?: Aislamiento, reproducibilidad, y versiones exactas del runtime

# Global (aplica a todos los jobs que no especifiquen imagen propia):
image: node:20-alpine

# Los jobs heredan la imagen global:
test-unit:
  script:
    - node --version  # Usa Node 20-alpine
    - npm test

# Un job puede sobreescribir la imagen global:
security-scan:
  image: semgrep/semgrep:1.45.0   # Esta imagen específica, no Node
  script:
    - semgrep --config=auto src/
```

### Elegir la Imagen Correcta

```yaml
# ✅ Preferir imágenes slim/alpine cuando sea posible:
image: node:20-alpine       # 55MB — versión mínima de Alpine Linux
# vs
image: node:20              # 1.1GB — basada en Debian completo

# ✅ Pinear versiones exactas para reproducibilidad:
image: node:20.11.0-alpine3.19    # Versión exacta
# vs
image: node:latest                # ⚠️ Cambia con cada release

# ✅ Para proyectos con múltiples ecosistemas:
stages:
  - test

test-backend:
  image: openjdk:21-jdk-slim
  script: ./gradlew test

test-frontend:
  image: node:20-alpine
  script: npm test

test-python-scripts:
  image: python:3.12-slim
  script: pytest scripts/
```

---

## 🗄️ Services: Dependencias del Job

Los `services` son contenedores Docker adicionales que corren junto al job. Útiles para bases de datos, caches, o cualquier servicio externo necesario en los tests.

```yaml
integration-tests:
  image: node:20-alpine
  services:
    - postgres:16-alpine    # ← Se ejecuta como contenedor separado
    - redis:7-alpine        # ← También como contenedor separado
  variables:
    # Variables para configurar el servicio de PostgreSQL:
    POSTGRES_DB: testdb
    POSTGRES_USER: testuser
    POSTGRES_PASSWORD: testpass
    # Variables para el código de test:
    DATABASE_URL: "postgresql://testuser:testpass@postgres:5432/testdb"
    REDIS_URL: "redis://redis:6379"
  before_script:
    - npm ci --quiet
    - npx wait-on tcp:postgres:5432 -t 30000  # Esperar a que Postgres esté listo
  script:
    - npm run test:integration
```

**¿Cómo se conectan el job y los services?**

```
                [postgres:16-alpine]
                       ↑ hostname: "postgres"
[node:20-alpine] ──────┤ puerto: 5432
    (job)              ↓ hostname: "redis"
                [redis:7-alpine]
                       puerto: 6379
```

GitLab crea una red Docker interna. El hostname del service es el nombre del servicio (antes de los `:16-alpine`). Desde el job, accedes a PostgreSQL en `postgres:5432`.

```yaml
# Nombres de host de services comunes:
services:
  - postgres:16           → hostname: postgres
  - mysql:8               → hostname: mysql
  - redis:7               → hostname: redis
  - elasticsearch:8.12    → hostname: elasticsearch
  - mongo:7               → hostname: mongo
  - rabbitmq:3            → hostname: rabbitmq

# Alias personalizado (para control total del hostname):
services:
  - name: postgres:16-alpine
    alias: database        → hostname: database
```

---

## 🐋 Construir Imágenes Docker: Docker-in-Docker (DinD)

Para construir imágenes Docker dentro de un job de CI, el runner necesita acceso al daemon Docker. La solución estándar es Docker-in-Docker:

```yaml
build-docker-image:
  stage: build
  image: docker:27
  services:
    - docker:27-dind          # El daemon Docker que usará el job
  variables:
    DOCKER_TLS_CERTDIR: ""   # Deshabilitar TLS para entornos de desarrollo
  before_script:
    # Login al GitLab Container Registry:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    # ¿QUÉ HACE?: Construye la imagen y la etiqueta con el SHA del commit
    # ¿POR QUÉ?: El SHA garantiza que cada imagen es única e identificable
    # ¿PARA QUÉ?: Poder hacer rollback a una versión exacta: docker pull image:abc1234
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker build -t $CI_REGISTRY_IMAGE:latest .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE:latest
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

### Variables del GitLab Container Registry

```
$CI_REGISTRY          → registry.gitlab.com (o tu dominio si es self-hosted)
$CI_REGISTRY_IMAGE    → registry.gitlab.com/namespace/project
$CI_REGISTRY_USER     → Usuario para autenticarse (gitlab-ci-token)
$CI_REGISTRY_PASSWORD → Token temporal generado por GitLab para el pipeline
```

---

## 🔧 Alternativas a Docker-in-Docker

DinD requiere que el runner tenga el modo privilegiado activado, lo que puede ser un riesgo de seguridad en entornos compartidos. Alternativas:

### Kaniko (sin daemon Docker)

```yaml
build-con-kaniko:
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:latest
    entrypoint: [""]    # Sobreescribir entrypoint para ejecutar comandos
  script:
    - /kaniko/executor
      --context $CI_PROJECT_DIR
      --dockerfile $CI_PROJECT_DIR/Dockerfile
      --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
      --destination $CI_REGISTRY_IMAGE:latest
```

Kaniko no necesita modo privilegiado — es la opción más segura para construcción de imágenes.

### Buildah (alternativa de RedHat)

```yaml
build-con-buildah:
  stage: build
  image: quay.io/buildah/stable:latest
  script:
    - buildah bud -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - buildah push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
```

---

## 📦 Workflow Completo: Build, Push, Deploy

```yaml
stages:
  - test
  - build
  - deploy

variables:
  DOCKER_IMAGE: $CI_REGISTRY_IMAGE/app

# ─── Tests primero ───────────────────────────────────
test-unit:
  stage: test
  image: node:20-alpine
  script:
    - npm ci --quiet
    - npm test

# ─── Build de imagen Docker ───────────────────────────
build-image:
  stage: build
  image: docker:27
  services:
    - docker:27-dind
  variables:
    DOCKER_TLS_CERTDIR: ""
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build
        --build-arg VERSION=$CI_COMMIT_SHA
        --tag $DOCKER_IMAGE:$CI_COMMIT_SHA
        --tag $DOCKER_IMAGE:latest
        .
    - docker push $DOCKER_IMAGE:$CI_COMMIT_SHA
    - docker push $DOCKER_IMAGE:latest
  needs:
    - test-unit      # Solo construir si los tests pasan
  rules:
    - if: $CI_COMMIT_BRANCH == "main"

# ─── Deploy a staging ────────────────────────────────
deploy-staging:
  stage: deploy
  image: alpine:latest
  before_script:
    - apk add --no-cache openssh-client
    - eval $(ssh-agent -s)
    - echo "$STAGING_SSH_KEY" | ssh-add -
  script:
    - ssh -o StrictHostKeyChecking=no deploy@staging.app.com
        "docker pull $DOCKER_IMAGE:latest &&
         docker stop app || true &&
         docker run -d --name app -p 3000:3000 $DOCKER_IMAGE:latest"
  environment:
    name: staging
    url: http://staging.app.com
  needs:
    - build-image
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

---

## 🔐 Seguridad en Imágenes de CI

```yaml
# ✅ Buenas prácticas de seguridad:

# 1. Pinear versiones exactas (evitar cambios inesperados):
image: node:20.11.0-alpine3.19   # ✅
image: node:latest               # ⚠️ Puede cambiar sin aviso

# 2. Usar imágenes oficiales o verificadas:
image: node:20-alpine            # ✅ Imagen oficial de Node.js
image: mi-imagen-random          # ⚠️ ¿De quién es esta imagen?

# 3. Escanear imágenes en el pipeline:
scan-imagen:
  stage: validate
  image: aquasec/trivy:latest
  script:
    - trivy image --exit-code 1 --severity HIGH,CRITICAL $DOCKER_IMAGE:$CI_COMMIT_SHA

# 4. No guardar secretos en layers de la imagen Docker:
# En el Dockerfile:
# ❌ RUN echo "DB_PASS=secret" >> .env
# ✅ ENV DB_PASS=${DB_PASS}  # Pasada en runtime, no en build
```

---

## 🖼️ Diagrama: Jobs, Images y Services

![Diagrama de jobs con images y services](../0-assets/04-docker-images-services.svg)

> **Diagrama:** Muestra cómo GitLab Runner crea una red Docker para cada job, con el contenedor principal (image) y los contenedores auxiliares (services), indicando los hostnames y puertos disponibles desde el job principal.

---

## 🤔 Preguntas de reflexión

1. Un job usa `image: node:20-alpine`. El Dockerfile del proyecto usa `FROM node:18`. ¿Puede haber inconsistencias entre el entorno de CI y la imagen final? ¿Cómo las mitgarías?

2. Los `services` como `postgres:16-alpine` se descargan cada vez que se ejecuta el job. ¿Cómo afecta esto al tiempo del pipeline? ¿Qué mecanismo de GitLab CI podría reducir ese tiempo?

3. Docker-in-Docker requiere `privileged: true` en el runner. ¿Por qué esto es un riesgo de seguridad en runners compartidos? ¿Cómo funcionaría Kaniko para mitigar esto?

4. La imagen `$CI_REGISTRY_IMAGE:latest` se sobreescribe en cada push a `main`. Si una nueva versión tiene un bug crítico, ¿cómo harías rollback? ¿Qué etiquetado alternativo evitaría perder la versión anterior?

5. Los tests de integración necesitan PostgreSQL. Si el job tarda en esperar a que Postgres esté listo, los tests fallan con "connection refused". ¿Cuál es la solución que usarías? ¿Y si el runner no tiene `wait-on` instalado?

---

## 📚 Recursos adicionales

- [Docker integration](https://docs.gitlab.com/ee/ci/docker/)
- [Using Docker images](https://docs.gitlab.com/ee/ci/docker/using_docker_images.html)
- [Docker-in-Docker](https://docs.gitlab.com/ee/ci/docker/using_docker_build.html)
- [Kaniko — Build without daemon](https://docs.gitlab.com/ee/ci/docker/using_kaniko.html)
- [GitLab Container Registry](https://docs.gitlab.com/ee/user/packages/container_registry/)

---

⬅️ **Lección anterior:** [03 — Stages y Jobs](./03-stages-y-jobs.md)
➡️ **Siguiente lección:** [05 — Artifacts y Cache](./05-artifacts-y-cache.md)

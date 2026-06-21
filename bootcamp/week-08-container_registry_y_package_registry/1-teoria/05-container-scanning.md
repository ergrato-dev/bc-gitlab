# 05 — Container Scanning y Seguridad

## Niveles de escaneo en GitLab

GitLab ofrece multiples tipos de escaneo de seguridad integrados en los pipelines:

### 1. Container Scanning
Escanea imagenes Docker por vulnerabilidades conocidas (CVEs). Usa Trivy o Grype como motor.

```yaml
include:
  - template: Security/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
    CS_DOCKERFILE_PATH: ./Dockerfile
```

**Requisito:** La imagen debe existir en el registry (se escanea la imagen, no el Dockerfile).

### 2. Dependency Scanning
Analiza dependencias del proyecto (npm, Maven, pip, etc.):

```yaml
include:
  - template: Security/Dependency-Scanning.gitlab-ci.yml
```

Soporta: Bundler, Maven, Gradle, npm, pip, pipenv, Go modules, Composer, NuGet, Conan.

### 3. SAST (Static Application Security Testing)
Analiza codigo fuente buscando vulnerabilidades:

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml
```

### 4. Secret Detection
Busca secretos (API keys, tokens) en el codigo:

```yaml
include:
  - template: Security/Secret-Detection.gitlab-ci.yml
```

## Pipeline completo de seguridad

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml

stages:
  - build
  - test
  - security
  - deploy

# Jobs de plantilla se inyectan automaticamente

docker-build:
  stage: build
  image: docker:24-dind
  services:
    - docker:24-dind
  variables:
    DOCKER_TLS_CERTDIR: ""
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
```

## Visualizacion de resultados

- **Merge Request**: Vulnerabilidades mostradas en el widget de seguridad
- **Pipeline**: Security tab con tabla de vulnerabilidades
- **Security Dashboard**: Group → Security Dashboard (vista consolidada)
- **Vulnerability Report**: Project → Security & Compliance → Vulnerability Report

## Umbrales y politicas

En Settings → Security & Compliance → Configuration se pueden configurar:
- Estados de approval requeridos
- Umbrales de severidad (Critical, High, Medium, Low)
- Acciones al detectar vulnerabilidades (bloquear merge, solo alertar)

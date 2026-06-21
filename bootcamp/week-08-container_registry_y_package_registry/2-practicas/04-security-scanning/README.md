# Practica 04 — Security Scanning en Pipeline

## Objetivo

Integrar escaneo de seguridad en el pipeline: Container Scanning, Dependency Scanning y SAST.

## Instrucciones

### Paso 1: Pipeline con todos los escaneos

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

variables:
  DOCKER_TLS_CERTDIR: ""

docker-build:
  stage: build
  image: docker:24-dind
  services:
    - docker:24-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
  tags:
    - docker
    - privileged

# Las plantillas inyectan automaticamente:
# - sast
# - secret_detection
# - dependency_scanning
# - container_scanning

container_scanning:
  variables:
    CS_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
  needs:
    - docker-build

unit-test:
  stage: test
  image: node:18-alpine
  script:
    - echo "Unit tests..."
```

### Paso 2: Verificar resultados

1. Ejecuta el pipeline completo
2. Ve al pipeline → Security tab
3. Revisa las vulnerabilidades encontradas por cada scanner
4. Abre el Vulnerability Report: Security & Compliance → Vulnerability Report

### Paso 3: Umbrales de seguridad

En el `.gitlab-ci.yml` se pueden configurar severidades minimas:

```yaml
container_scanning:
  variables:
    CS_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
    CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN: "false"
    CS_SEVERITY_THRESHOLD: "high"
    # Solo fallara si encuentra HIGH o CRITICAL
```

### Paso 4: Exportar reportes

```yaml
sast:
  artifacts:
    reports:
      sast: gl-sast-report.json
    paths:
      - gl-sast-report.json

dependency_scanning:
  artifacts:
    reports:
      dependency_scanning: gl-dependency-scanning-report.json
```

## Verificacion

- [ ] Los 4 escaneos se ejecutan en el pipeline
- [ ] Reportes de vulnerabilidades visibles en Security tab
- [ ] Vulnerability Report muestra hallazgos
- [ ] Container Scanning escanea la imagen construida en `docker-build`

## Reto adicional

Configura el Security Dashboard de grupo (Group → Security → Dashboard) y un Merge Request con widget de seguridad:

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml

sast:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

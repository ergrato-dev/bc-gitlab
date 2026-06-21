# 03 — Diseño del Pipeline Completo

El pipeline final debe integrar todos los conceptos vistos en el bootcamp: stages múltiples, seguridad, environments, templates y artefactos.

## Estructura de stages

```yaml
stages:
  - build
  - test
  - security
  - package
  - deploy-staging
  - deploy-production
```

## Stage: Build

Compila la aplicación y construye la imagen Docker:
```yaml
build-image:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
  tags:
    - docker
```

## Stage: Test

Ejecuta tests unitarios y de integración, y análisis de calidad:
```yaml
unit-tests:
  stage: test
  script:
    - pip install -r requirements.txt
    - pytest --junitxml=report.xml --cov=src
  artifacts:
    reports:
      junit: report.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml

lint:
  stage: test
  script:
    - pip install ruff
    - ruff check src/
```

## Stage: Security

Incluye los templates de seguridad:
```yaml
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml

container-scanning:
  variables:
    CS_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
```

## Stage: Package

Versiona y etiqueta la imagen final:
```yaml
package:
  stage: package
  image: docker:24
  services:
    - docker:24-dind
  script:
    - docker pull $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
    - docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA $CI_REGISTRY_IMAGE:latest
    - docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA $CI_REGISTRY_IMAGE:$CI_COMMIT_TAG
    - docker push $CI_REGISTRY_IMAGE:latest
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_TAG
  only:
    - tags
```

## Stage: Deploy

Despliegue a staging (automático) y a production (manual):
```yaml
deploy-staging:
  stage: deploy-staging
  environment:
    name: staging
    url: https://staging.app.local
  script:
    - echo "Deploying to staging..."
    - docker-compose -f docker-compose.staging.yml up -d
  only:
    - main

deploy-production:
  stage: deploy-production
  environment:
    name: production
    url: https://app.local
  script:
    - echo "Deploying to production..."
    - docker-compose -f docker-compose.prod.yml up -d
  when: manual
  only:
    - tags
```

## Variables CI/CD protegidas

Definir en Settings → CI/CD → Variables:
- `CI_REGISTRY_USER` (protegida, para ramas protegidas)
- `CI_REGISTRY_PASSWORD` (protegida, enmascarada)
- `DEPLOY_SSH_KEY` (protegida, tipo File)
- `STAGING_HOST`, `PRODUCTION_HOST` (no protegidas)

# Practica 04 — Environments y Deployments

## Objetivo

Configurar entornos staging y production con historial de deployments y acciones de rollback.

## Instrucciones

### Pipeline completo con environments

```yaml
stages:
  - build
  - deploy-staging
  - deploy-production

variables:
  STAGING_URL: "https://staging.mi-app.example.com"
  PRODUCTION_URL: "https://mi-app.example.com"

build:
  stage: build
  script:
    - echo "Building app..."
    - mkdir -p dist
    - echo "v${CI_PIPELINE_ID}" > dist/version.txt
  artifacts:
    paths:
      - dist/

deploy-staging:
  stage: deploy-staging
  script:
    - echo "Deploy a ${STAGING_URL}"
    - cat dist/version.txt
  environment:
    name: staging
    url: ${STAGING_URL}
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"

deploy-production:
  stage: deploy-production
  script:
    - echo "Deploy a ${PRODUCTION_URL}"
    - cat dist/version.txt
  environment:
    name: production
    url: ${PRODUCTION_URL}
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: manual
      allow_failure: false

stop-staging:
  stage: deploy-staging
  script:
    - echo "Deteniendo staging..."
  environment:
    name: staging
    action: stop
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

## Verificacion

- [ ] Environments `staging` y `production` aparecen en Operate → Environments
- [ ] URL del entorno es clickeable desde la UI
- [ ] Historial de deployments disponible
- [ ] `deploy-production` requiere confirmacion manual
- [ ] `stop-staging` ejecuta la accion de detener el entorno

## Reto adicional

Implementa un review app para merge requests que cree un entorno efimero con `auto_stop_in` y se destruya al cerrar el MR:

```yaml
deploy-review:
  environment:
    name: review/$CI_MERGE_REQUEST_IID
    on_stop: stop-review
    auto_stop_in: 1 day
```

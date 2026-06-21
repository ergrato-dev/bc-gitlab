# 04 — Environments y Deployments

## Definicion

Un `environment` representa el destino de un despliegue (servidor, cluster, plataforma). GitLab rastrea el historial de deployments y permite acciones como rollback.

## Configuracion basica

```yaml
deploy-staging:
  stage: deploy
  script:
    - echo "Desplegando a staging..."
    - ./deploy.sh staging
  environment:
    name: staging
    url: https://staging.example.com

deploy-production:
  stage: deploy
  script:
    - ./deploy.sh production
  environment:
    name: production
    url: https://example.com
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

## Funcionalidades de environments

### Monitoreo
En Operate → Environments se visualizan todos los entornos con:
- Estado actual del despliegue
- URL del entorno
- Ultimo commit desplegado
- Boton de rollback

### Acciones de entorno
```yaml
stop_staging:
  stage: cleanup
  script:
    - ./undeploy.sh staging
  environment:
    name: staging
    action: stop
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

### Preparacion (on_stop)
```yaml
deploy-review:
  stage: deploy
  script: ./deploy-review.sh
  environment:
    name: review/$CI_COMMIT_REF_NAME
    on_stop: stop_review
    auto_stop_in: 1 week

stop_review:
  stage: deploy
  script: ./destroy-review.sh
  environment:
    name: review/$CI_COMMIT_REF_NAME
    action: stop
  rules:
    - if: $CI_MERGE_REQUEST_ID
      when: manual
  allow_failure: true
```

## Deployment freeze

En Settings → CI/CD se pueden configurar periodos de congelamiento donde no se permiten despliegues a ciertos entornos (ej: produccion durante festivos).

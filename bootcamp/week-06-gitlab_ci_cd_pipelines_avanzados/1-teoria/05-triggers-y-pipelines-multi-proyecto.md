# 05 — Triggers y Pipelines Multi-Proyecto

## Triggers de pipeline

Un trigger permite iniciar un pipeline desde otro proyecto o sistema externo mediante un token.

### Crear un trigger
Settings → CI/CD → Pipeline triggers → Add trigger

### Usar un trigger desde otro `.gitlab-ci.yml`
```yaml
# Proyecto A: disparador
trigger-downstream:
  stage: deploy
  trigger:
    project: grupo/proyecto-b
    branch: main
    strategy: depend  # Opcional: espera resultado
  variables:
    UPSTREAM_COMMIT: $CI_COMMIT_SHA
```

### Opciones de `strategy`
- No declarada (default): El job se marca exitoso inmediatamente
- `depend`: El job espera a que el pipeline downstream termine y refleja su estado

### Usar trigger via API
```bash
curl -X POST \
  --form token=$CI_JOB_TOKEN \
  --form ref=main \
  "https://gitlab.example.com/api/v4/projects/42/trigger/pipeline"
```

## Pipelines parent-child

Permite dividir un pipeline grande en sub-pipelines que se ejecutan en el mismo proyecto:

```yaml
# .gitlab-ci.yml principal
generate-config:
  stage: build
  script: ./generate-child-pipeline.sh
  artifacts:
    paths:
      - child-pipeline.yml

child-pipeline:
  stage: test
  trigger:
    include:
      - artifact: child-pipeline.yml
        job: generate-config
    strategy: depend
```

## Pipelines multi-proyecto

Caso de uso tipico:
1. Equipo A construye una libreria (Proyecto A)
2. Equipo B consume la libreria (Proyecto B)
3. Cuando Proyecto A publica una nueva version, dispara automáticamente el pipeline de Proyecto B

```yaml
# Proyecto A: libreria
publish-and-trigger:
  stage: deploy
  script:
    - npm publish
  trigger:
    project: frontend/app
    branch: main
    strategy: depend
```

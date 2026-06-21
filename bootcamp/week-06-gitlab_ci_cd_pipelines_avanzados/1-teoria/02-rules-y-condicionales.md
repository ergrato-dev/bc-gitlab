# 02 — Rules y Ejecucion Condicional

## `rules`

El keyword `rules` permite definir condiciones detalladas para ejecutar o saltar un job. Es la forma moderna y recomendada (reemplaza a `only`/`except`).

```yaml
deploy-production:
  stage: deploy
  script:
    - echo "Deploy a produccion"
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: on_success
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
      when: manual
    - when: never
```

### Clauses de `rules`
- `if`: Condicion evaluada con variables CI/CD
- `changes`: Ejecutar solo si ciertos archivos cambiaron
- `exists`: Ejecutar si un archivo existe en el repositorio
- `when`: `on_success`, `on_failure`, `always`, `manual`, `delayed`, `never`
- `allow_failure`: Permite fallo sin bloquear el pipeline

## `only` / `except` (legacy)

```yaml
# Solo en rama main
job:
  only:
    - main

# Excluye tags
job:
  except:
    - tags
```

## Ejemplos practicos

### Ejecutar solo en merge requests
```yaml
test:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

### Ejecutar si cambiaron archivos del frontend
```yaml
frontend-build:
  rules:
    - changes:
        - src/frontend/**/*
```

### Delay manual para aprobacion
```yaml
deploy-prod:
  when: manual
  allow_failure: false
```

### Ejecutar con retraso
```yaml
rollout:
  when: delayed
  start_in: 30 minutes
```

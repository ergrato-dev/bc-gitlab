# 03 — Include y Modularizacion de Pipelines

## Por que modularizar

A medida que los pipelines crecen, mantener un solo `.gitlab-ci.yml` se vuelve problematico. `include` permite dividir la configuracion en archivos reutilizables.

## Tipos de `include`

### `include:local`
Referencia archivos dentro del mismo repositorio:
```yaml
include:
  - local: /.gitlab/ci/build.yml
  - local: /.gitlab/ci/test.yml
  - local: /.gitlab/ci/deploy.yml
```

### `include:remote`
Referencia archivos via URL (debe ser accesible sin autenticacion):
```yaml
include:
  - remote: 'https://raw.githubusercontent.com/org/shared-ci/main/template.yml'
```

### `include:template`
Usa plantillas oficiales de GitLab:
```yaml
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - template: Jobs/Build.gitlab-ci.yml
```

### `include:project`
Referencia archivos de otro proyecto en la misma instancia:
```yaml
include:
  - project: 'shared/ci-templates'
    file: '/templates/docker-build.yml'
    ref: main
```

## Estructura recomendada

```
.gitlab/
  ci/
    stages.yml      # Definicion de stages
    build.yml       # Jobs de build
    test.yml        # Jobs de test
    deploy.yml      # Jobs de deploy
.gitlab-ci.yml      # Archivo principal con includes
```

### `.gitlab-ci.yml` principal:
```yaml
include:
  - local: .gitlab/ci/stages.yml
  - local: .gitlab/ci/build.yml
  - local: .gitlab/ci/test.yml
  - local: .gitlab/ci/deploy.yml
```

## `!reference` y anclas YAML
Para reutilizar fragmentos de configuracion dentro del mismo archivo:
```yaml
.base-config: &base
  image: alpine:latest
  before_script:
    - echo "Setup"

job1:
  <<: *base
  script: echo "Job 1"

job2:
  <<: *base
  script: echo "Job 2"
```

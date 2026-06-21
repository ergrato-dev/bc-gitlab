# Practica 03 — Include Templates

## Objetivo

Dividir un pipeline monolitico en modulos usando `include:local`.

## Instrucciones

### Paso 1: Crear estructura de directorios

```
.gitlab/
  ci/
    stages.yml
    build.yml
    test.yml
    deploy.yml
.gitlab-ci.yml
```

### Paso 2: Definir stages

`.gitlab/ci/stages.yml`:
```yaml
stages:
  - build
  - test
  - deploy
```

### Paso 3: Crear modulo de build

`.gitlab/ci/build.yml`:
```yaml
install-deps:
  stage: build
  image: node:18-alpine
  script:
    - npm ci
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
  artifacts:
    paths:
      - node_modules/
```

### Paso 4: Crear modulo de test

`.gitlab/ci/test.yml`:
```yaml
unit-test:
  stage: test
  image: node:18-alpine
  script:
    - npm test

lint:
  stage: test
  image: node:18-alpine
  script:
    - npm run lint
  allow_failure: true
```

### Paso 5: Crear modulo de deploy

`.gitlab/ci/deploy.yml`:
```yaml
deploy-staging:
  stage: deploy
  script: echo "Deploy a ${ENVIRONMENT}"
  environment:
    name: ${ENVIRONMENT}
```

### Paso 6: Archivo principal

`.gitlab-ci.yml`:
```yaml
include:
  - local: .gitlab/ci/stages.yml
  - local: .gitlab/ci/build.yml
  - local: .gitlab/ci/test.yml
  - local: .gitlab/ci/deploy.yml
```

## Verificacion

- [ ] Pipeline se ejecuta con todos los jobs de los modulos
- [ ] Los stages estan en el orden correcto
- [ ] La UI de GitLab muestra el pipeline como si fuera un solo `.gitlab-ci.yml`

## Reto adicional

Crea un template reutilizable (`include:remote` o `include:project`) con un job de notificacion a Slack y compartelo entre dos proyectos diferentes.

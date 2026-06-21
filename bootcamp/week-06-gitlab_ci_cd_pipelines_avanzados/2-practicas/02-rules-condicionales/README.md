# Practica 02 — Rules Condicionales

## Objetivo

Implementar reglas que controlen cuando se ejecuta cada job segun rama, tag, cambios y variables.

## Instrucciones

### Parte 1: Pipeline con multiples ramas

Crea un `.gitlab-ci.yml` que comporte diferente segun la rama:

```yaml
stages:
  - build
  - test
  - deploy

build:
  stage: build
  script: echo "Build ejecutado"
  rules:
    - when: always

test-rapido:
  stage: test
  script: npm test -- --only=unit
  rules:
    - if: $CI_COMMIT_BRANCH != "main"
    - when: never

test-completo:
  stage: test
  script: npm test
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_COMMIT_TAG

deploy-staging:
  stage: deploy
  script: echo "Deploy staging"
  environment:
    name: staging
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"

deploy-production:
  stage: deploy
  script: echo "Deploy prod"
  environment:
    name: production
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
```

### Parte 2: Rules con changes

```yaml
frontend-test:
  stage: test
  script: npm run test:frontend
  rules:
    - changes:
        - src/frontend/**/*
      when: on_success

backend-test:
  stage: test
  script: npm run test:backend
  rules:
    - changes:
        - src/backend/**/*
      when: on_success
```

## Verificacion

- [ ] `test-rapido` solo se ejecuta en ramas de feature
- [ ] `test-completo` solo se ejecuta en main o tags
- [ ] `deploy-production` solo se ejecuta en tags semanticos
- [ ] Jobs con `changes` solo se ejecutan cuando cambian los archivos especificados

## Reto adicional

Agrega un job `security-scan` que se ejecute en todas las ramas excepto `main` (donde se ejecutara manualmente con `when: manual`).

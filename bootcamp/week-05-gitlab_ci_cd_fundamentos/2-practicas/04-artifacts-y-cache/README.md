# Practica 04 — Artifacts y Cache

## Objetivo

Configurar artifacts para pasar resultados entre jobs y usar cache para acelerar la instalacion de dependencias.

## Instrucciones

### Parte 1: Artifacts entre stages

```yaml
stages:
  - build
  - test
  - package

instalar-deps:
  stage: build
  image: node:18-alpine
  script:
    - npm init -y
    - npm install express
  artifacts:
    paths:
      - node_modules/
      - package.json
    expire_in: 1 hour

ejecutar-tests:
  stage: test
  image: node:18-alpine
  script:
    - test -d node_modules && echo "Deps disponibles"
    - test -f package.json && echo "package.json OK"
    - node -e "require('express')" && echo "Express funciona"

empaquetar:
  stage: package
  image: alpine:latest
  script:
    - apk add --no-cache zip
    - zip -r app.zip node_modules/ package.json
  artifacts:
    paths:
      - app.zip
    expire_in: 30 days
```

### Parte 2: Cache para dependencias

```yaml
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - node_modules/

build-con-cache:
  stage: build
  image: node:18-alpine
  script:
    - npm install
```

## Verificacion

- [ ] Los artifacts de `instalar-deps` estan disponibles en `ejecutar-tests`
- [ ] `empaquetar` genera un artifact descargable
- [ ] La segunda ejecucion con cache es mas rapida que la primera

## Reto adicional

Usa `dependencies` para controlar que artifacts recibe cada job (restringe artifacts no necesarios).

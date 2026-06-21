# Practica 03 — Package Registry (npm / PyPI)

## Objetivo

Publicar un paquete en el Package Registry de GitLab usando CI/CD.

## Opcion A: npm

### Paso 1: Crear proyecto npm

```json
{
  "name": "@tu-org/bootcamp-lib",
  "version": "1.0.0",
  "description": "Libreria de ejemplo para el bootcamp GitLab",
  "main": "index.js",
  "publishConfig": {
    "@tu-org:registry": "URL_REGISTRY"
  },
  "scripts": {
    "test": "echo 'Tests OK' && exit 0"
  }
}
```

### Paso 2: Configurar .gitlab-ci.yml

```yaml
stages:
  - test
  - publish

test:
  stage: test
  image: node:18-alpine
  script:
    - npm install
    - npm test

publish-npm:
  stage: publish
  image: node:18-alpine
  script:
    - |
      cat > .npmrc << EOF
      @tu-org:registry=${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/npm/
      ${CI_API_V4_URL#https?}projects/${CI_PROJECT_ID}/packages/npm/:_authToken=${CI_JOB_TOKEN}
      EOF
    - npm publish
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
```

## Opcion B: PyPI

### Paso 1: Crear proyecto Python

```
bootcamp-lib/
  setup.py
  setup.cfg
  bootcamp_lib/
    __init__.py
```

`setup.cfg`:
```ini
[metadata]
name = bootcamp-lib
version = 1.0.0
description = Libreria de ejemplo para bootcamp GitLab

[options]
packages = find:
python_requires = >=3.8
```

### Paso 2: Pipeline PyPI

```yaml
publish-pypi:
  stage: publish
  image: python:3.11-slim
  script:
    - pip install --upgrade build twine
    - python -m build
    - |
      TWINE_PASSWORD=${CI_JOB_TOKEN} \
      TWINE_USERNAME=gitlab-ci-token \
      python -m twine upload \
        --repository-url ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/pypi \
        dist/*
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
```

## Verificacion

- [ ] Pipeline se ejecuta y publica el paquete
- [ ] Paquete visible en Deploy → Package Registry
- [ ] Se puede instalar desde el registry:

```bash
# npm
npm install @tu-org/bootcamp-lib --registry=https://gitlab.example.com/api/v4/projects/<ID>/packages/npm/

# pip
pip install bootcamp-lib --index-url https://__token__:<token>@gitlab.example.com/api/v4/projects/<ID>/packages/pypi/simple
```

## Reto adicional

Publica el paquete con informacion de build (commit SHA, pipeline ID) en el version field para trazabilidad.

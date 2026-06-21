# Practica 03 — Imagenes Docker Personalizadas

## Objetivo

Usar imagenes Docker especificas para diferentes jobs y ejecutar un job con servicio auxiliar.

## Instrucciones

### Parte 1: Diferentes imagenes por job

```yaml
stages:
  - build
  - test

build-node:
  stage: build
  image: node:18-alpine
  script:
    - node --version
    - npm --version
    - echo "console.log('hello')" > app.js
  artifacts:
    paths:
      - app.js

test-python:
  stage: test
  image: python:3.11-slim
  script:
    - python --version
    - python -c "print('Python funcionando')"
```

### Parte 2: Job con servicio PostgreSQL

```yaml
test-db:
  stage: test
  image: node:18
  services:
    - postgres:15-alpine
  variables:
    POSTGRES_DB: testdb
    POSTGRES_USER: tester
    POSTGRES_PASSWORD: testpass
  script:
    - apt-get update && apt-get install -y postgresql-client
    - PGPASSWORD=testpass psql -h postgres -U tester -d testdb -c "SELECT 1;"
    - echo "Conexion a PostgreSQL exitosa"
```

## Verificacion

- [ ] Cada job usa la imagen especificada en su definicion
- [ ] El servicio PostgreSQL es accesible desde el job
- [ ] Diferentes lenguajes/entornos coexisten en el mismo pipeline

## Reto adicional

Crea un Dockerfile y usalo como imagen personalizada con `image: ${CI_REGISTRY_IMAGE}/mi-imagen:latest`

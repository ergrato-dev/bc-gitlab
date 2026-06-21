# 04 — Imagenes Docker en CI

## La keyword `image`

Define la imagen Docker donde se ejecuta el job. Puede declararse globalmente (para todos los jobs) o por job especifico.

```yaml
image: node:18-alpine

build:
  script:
    - npm install
    - npm run build

test-python:
  image: python:3.11-slim
  script:
    - pip install -r requirements.txt
    - pytest
```

## Servicios (`services`)

Los `services` son contenedores adicionales que se ejecutan junto al job. Ideales para bases de datos, caches, o APIs:

```yaml
integration-tests:
  image: node:18
  services:
    - postgres:15-alpine
    - redis:7-alpine
  variables:
    POSTGRES_DB: testdb
    POSTGRES_PASSWORD: testpass
    REDIS_URL: redis://redis:6379
  script:
    - npm run test:integration
```

## Docker-in-Docker (DIND)

Para construir imagenes Docker dentro de un pipeline se necesita Docker-in-Docker:

```yaml
docker-build:
  image: docker:24-dind
  variables:
    DOCKER_TLS_CERTDIR: ""
  services:
    - docker:24-dind
  script:
    - docker build -t mi-app:$CI_COMMIT_SHA .
    - docker push mi-app:$CI_COMMIT_SHA
```

Alternativas a DIND: Kaniko, Buildah, o usar el socket del host Docker (menos seguro).

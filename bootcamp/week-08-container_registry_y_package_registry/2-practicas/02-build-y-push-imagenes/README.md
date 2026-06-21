# Practica 02 — Build y Push de Imagenes en Pipeline

## Objetivo

Crear un pipeline CI/CD que construya una imagen Docker, la etiquete correctamente y la publique en el Container Registry.

## Instrucciones

### Paso 1: Crear Dockerfile de ejemplo

```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

USER node

CMD ["node", "server.js"]
```

### Paso 2: Crear server.js minimo

```javascript
// server.js
const http = require('http');
const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({
    status: 'ok',
    version: process.env.APP_VERSION || 'dev',
    commit: process.env.COMMIT_SHA || 'unknown'
  }));
});

server.listen(PORT, () => console.log(`Server running on port ${PORT}`));
```

### Paso 3: Pipeline con DIND

```yaml
stages:
  - build
  - push

variables:
  APP_VERSION: "1.0.0"
  DOCKER_TLS_CERTDIR: ""
  DOCKER_DRIVER: overlay2

docker-build:
  stage: build
  image: docker:24-dind
  services:
    - docker:24-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY
  script:
    - docker build
      --build-arg COMMIT_SHA=$CI_COMMIT_SHORT_SHA
      --build-arg APP_VERSION=$APP_VERSION
      -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
      -t $CI_REGISTRY_IMAGE:latest
      -t $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
      .
    - docker push $CI_REGISTRY_IMAGE --all-tags
```

### Paso 4: Pipeline con Kaniko (alternativa sin privilegios)

```yaml
kaniko-build:
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:v1.19.0-debug
    entrypoint: [""]
  script:
    - |
      /kaniko/executor \
        --context $CI_PROJECT_DIR \
        --dockerfile $CI_PROJECT_DIR/Dockerfile \
        --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA \
        --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG \
        --cache=true \
        --cache-ttl=24h
```

## Verificacion

- [ ] Pipeline se ejecuta sin errores
- [ ] Imagen aparece en Container Registry con multiples tags
- [ ] `docker pull` funciona desde una maquina externa
- [ ] La imagen ejecuta correctamente `docker run -p 3000:3000 <imagen>`

## Reto adicional

Agrega multi-stage builds en el Dockerfile para reducir el tamano de la imagen:

```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci

FROM node:18-alpine AS runner
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
USER node
CMD ["node", "server.js"]
```

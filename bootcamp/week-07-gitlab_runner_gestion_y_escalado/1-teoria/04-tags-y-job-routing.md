# 04 — Tags y Job Routing

## Que son los tags

Los tags son etiquetas que se asignan a un Runner para dirigir jobs especificos a ejecutarse en ese Runner.

## Configuracion de tags en el Runner

Al registrar:
```bash
sudo gitlab-runner register --tag-list "docker,linux,staging"
```

O en `config.toml`:
```toml
[[runners]]
  name = "runner-nodejs"
  tags = ["nodejs", "docker", "frontend"]
```

## Uso de tags en jobs

```yaml
# Job que requiere un runner con Docker y Node
build-frontend:
  stage: build
  tags:
    - nodejs
    - docker
  script:
    - npm run build

# Job que requiere un runner con GPU
ml-training:
  stage: train
  tags:
    - gpu
    - python
    - cuda
  script:
    - python train.py
```

## Comportamiento

- Un job busca un Runner que tenga **todos** los tags especificados
- Si no hay tags en el job, cualquier Runner (con o sin tags) puede ejecutarlo
- Si hay tags, solo Runners que tengan todos los tags pueden ejecutar

## Estrategia de tags recomendada

### Tags funcionales
```yaml
# Runner: docker, linux, amd64
# Runner: docker, linux, arm64
# Runner: shell, macos
```

### Tags por tecnologia
```yaml
# Runner: nodejs, python, docker
# Runner: java, maven, gradle
# Runner: go, rust, docker
```

### Tags por entorno
```yaml
# Runner: production, high-cpu
# Runner: staging, low-cpu
# Runner: development, spot
```

## Ejemplo: Pipeline con routing

```yaml
stages:
  - test
  - build
  - deploy

test:
  stage: test
  tags: [docker, linux]
  script: npm test

build-binaries:
  stage: build
  tags: [docker, linux, arm64]
  script: ./cross-compile-arm.sh

deploy-prod:
  stage: deploy
  tags: [production, docker]
  environment: production
  script: ./deploy.sh
```

# Practica 03 — Tags y Enrutamiento

## Objetivo

Configurar multiples runners con diferentes tags y demostrar como GitLab enruta los jobs.

## Instrucciones

### Paso 1: Registrar 3 runners

Si tienes un solo host, usa Docker para simular multiples runners:

```bash
# Runner 1: Docker, linux, frontend
docker run -d --name runner-frontend \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /srv/runner-frontend/config:/etc/gitlab-runner \
  gitlab/gitlab-runner:alpine

docker exec -it runner-frontend gitlab-runner register \
  --url "http://IP_DE_GITLAB" \
  --token "REGISTRATION_TOKEN" \
  --executor "docker" \
  --docker-image "node:18-alpine:latest" \
  --tag-list "docker,linux,frontend" \
  --description "Runner Frontend"

# Runner 2: Docker, linux, backend
docker run -d --name runner-backend \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /srv/runner-backend/config:/etc/gitlab-runner \
  gitlab/gitlab-runner:alpine

docker exec -it runner-backend gitlab-runner register \
  --url "http://IP_DE_GITLAB" \
  --token "REGISTRATION_TOKEN" \
  --executor "docker" \
  --docker-image "python:3.11-slim" \
  --tag-list "docker,linux,backend" \
  --description "Runner Backend"

# Runner 3: Shell, linux, deploy
# (registralo normalmente con --executor shell --tag-list "shell,linux,deploy")
```

### Paso 2: Pipeline con routing

```yaml
stages:
  - test
  - build
  - deploy

frontend-test:
  stage: test
  tags: [frontend]
  script:
    - echo "Frontend test en runner frontend"
    - node --version

backend-test:
  stage: test
  tags: [backend]
  script:
    - echo "Backend test en runner backend"
    - python --version

frontend-build:
  stage: build
  tags: [frontend]
  script:
    - echo "Building frontend"
    - npm --version

backend-build:
  stage: build
  tags: [backend]
  script:
    - echo "Building backend"
    - pip --version

deploy-all:
  stage: deploy
  tags: [deploy, shell]
  environment: production
  script:
    - echo "Deploy desde runner shell"
    - hostname
```

## Verificacion

- [ ] Los pipelines se ejecutan en los runners correctos
- [ ] Revisa en la UI que runner ejecuto cada job
- [ ] Los tags dirigen jobs al entorno adecuado (frontend usa node, backend usa python)

## Reto adicional

Simula una falla: desactiva temporalmente un runner y observa como los jobs quedan "pending". Luego reactivalo y verifica que retoman.

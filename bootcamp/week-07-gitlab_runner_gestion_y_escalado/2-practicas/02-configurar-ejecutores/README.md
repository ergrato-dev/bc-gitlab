# Practica 02 — Configurar Ejecutores

## Objetivo

Comparar el comportamiento de los ejecutores Docker y Shell, entendiendo sus diferencias practicas.

## Instrucciones

### Parte 1: Docker Executor

Crea un pipeline que use el runner Docker:

```yaml
stages:
  - test

docker-job:
  stage: test
  tags:
    - docker
  image: node:18-alpine
  script:
    - echo "Ejecutando en Docker"
    - node --version
    - npm --version
    - ls -la /
    - whoami
    - echo "Hostname: $(hostname)"
    - cat /etc/os-release | head -3
```

### Parte 2: Shell Executor

Si tienes un runner shell registrado:

```yaml
shell-job:
  stage: test
  tags:
    - shell
  script:
    - echo "Ejecutando en Shell"
    - uname -a
    - whoami
    - echo "HOME: $HOME"
    - echo "Hostname: $(hostname)"
    - cat /etc/os-release | head -3
    - ls -la /home
```

### Parte 3: Comparacion

Ejecuta ambos pipelines y compara:

```yaml
stages:
  - test

test-environment:
  stage: test
  tags:
    - shell
  script:
    - echo "=== SHELL EXECUTOR ==="
    - whoami
    - hostname
    - echo "UID: $(id -u)"
    - echo "Shell: $SHELL"
    - ls /var/run/docker.sock 2>/dev/null && echo "Docker socket: SI" || echo "Docker socket: NO"

test-docker:
  stage: test
  tags:
    - docker
  image: alpine:latest
  script:
    - echo "=== DOCKER EXECUTOR ==="
    - whoami
    - hostname
    - echo "UID: $(id -u)"
    - cat /etc/os-release | head -1
```

## Verificacion

- [ ] Ambos jobs se ejecutan en el runner correcto (por tag)
- [ ] El job Docker muestra informacion del contenedor (Alpine/Node)
- [ ] El job Shell muestra informacion del host
- [ ] `whoami` da resultados diferentes

## Reto adicional

Configura un job con `services` (PostgreSQL) y comparalo con un job shell que se conecte a una base de datos en el host:

```yaml
docker-with-db:
  tags: [docker]
  services: [postgres:15-alpine]
  variables:
    POSTGRES_DB: test
    POSTGRES_PASSWORD: test
  script:
    - apt-get update && apt-get install -y postgresql-client
    - psql -h postgres -U postgres -d test -c "SELECT version();"
```

# Proyecto Semana 07 — Infraestructura de Runners

## Descripcion

Disenar e implementar una infraestructura de GitLab Runners con multiples ejecutores, tags, y enrutamiento inteligente para una organizacion ficticia con equipos de frontend, backend y operaciones.

## Requisitos del Proyecto

### 1. Runners a configurar

| Runner | Tipo | Executor | Tags | Proposito |
|--------|------|----------|------|-----------|
| `docker-general` | Shared | docker | `docker, linux, general` | Jobs generales |
| `docker-frontend` | Group | docker | `docker, linux, nodejs, frontend` | Builds Node.js |
| `docker-backend` | Group | docker | `docker, linux, python, backend` | Tests Python |
| `docker-java` | Group | docker | `docker, linux, java, maven` | Builds Java |
| `shell-deploy` | Specific | shell | `shell, linux, deploy` | Deploy scripts |

### 2. Pipeline de demostracion

Crear un pipeline de demostracion en un proyecto de grupo que use todos los runners:

```yaml
stages:
  - frontend
  - backend
  - java
  - deploy

frontend-build:
  stage: frontend
  tags: [frontend, nodejs]
  image: node:18-alpine
  script:
    - npm --version
    - echo "Frontend build OK"

backend-test:
  stage: backend
  tags: [backend, python]
  image: python:3.11-slim
  script:
    - python --version
    - echo "Backend test OK"

java-package:
  stage: java
  tags: [java, maven]
  image: maven:3.9-eclipse-temurin-17
  script:
    - mvn --version
    - echo "Java package OK"

deploy-infra:
  stage: deploy
  tags: [deploy, shell]
  environment: production
  script:
    - hostname
    - echo "Deploy desde shell runner"
    - echo "Despliegue completado"
```

### 3. config.toml documentado

Documentar el `config.toml` de cada runner explicando:
- `concurrent` y su proposito
- Configuracion del ejecutor
- Volumenes montados
- Parametros de red

### 4. Pruebas de enrutamiento

Realizar y documentar las siguientes pruebas:
- Job sin tags vs con tags
- Job con tags que ningun runner tiene (quedara pending)
- Pausar un runner y verificar que los jobs van a otro con mismos tags
- Job con dependencias de hardware (ej: `tags: [gpu]`)

## Entregables

- [ ] 5 Runners registrados con diferentes tags y ejecutores
- [ ] Pipeline de demostracion ejecutandose correctamente
- [ ] Documentacion del `config.toml` y su configuracion
- [ ] Pruebas de enrutamiento documentadas
- [ ] Runners con circulo verde en la UI de GitLab

# 02 — Docker Build en CI

## Docker-in-Docker (DIND)

Metodo tradicional para construir imagenes dentro de CI:

```yaml
docker-build:
  image: docker:24-dind
  stage: build
  services:
    - docker:24-dind
  variables:
    DOCKER_TLS_CERTDIR: ""
    DOCKER_DRIVER: overlay2
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
```

**Requisitos:**
- Runner en modo `privileged = true`
- Variable `DOCKER_TLS_CERTDIR: ""` (deshabilita TLS para simplicidad)

**Ventajas:**
- Compatible con cualquier Dockerfile existente
- Soporta multi-stage builds y build args

**Desventajas:**
- Requiere privilegios elevados (riesgo de seguridad)
- Mas lento (capa extra de virtualizacion)
- No funciona en Kubernetes executor sin configuracion adicional

## Kaniko

Alternativa sin privilegios para construir imagenes:

```yaml
kaniko-build:
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:v1.19.0-debug
    entrypoint: [""]
  script:
    - /kaniko/executor
      --context $CI_PROJECT_DIR
      --dockerfile $CI_PROJECT_DIR/Dockerfile
      --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
      --cache=true
      --cache-ttl=24h
```

**Ventajas:**
- No requiere Docker daemon ni privilegios
- Funciona en cualquier executor
- Soporta cache en el registry

**Desventajas:**
- No soporta todas las features de Docker build
- Mas lento en ciertos escenarios de cache

## Buildah

Otra alternativa rootless:

```yaml
buildah-build:
  stage: build
  image: quay.io/buildah/stable
  script:
    - buildah bud -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - buildah push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
```

## Comparacion

| Caracteristica | DIND | Kaniko | Buildah |
|---------------|------|--------|---------|
| Privilegios | Requiere | No | No |
| Compatibilidad | Completa | Alta | Media |
| Velocidad | Alta | Media | Alta |
| Cache | Local + Registry | Registry | Local + Registry |

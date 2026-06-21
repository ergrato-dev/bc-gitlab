# Proyecto Semana 08 — Pipeline Integral: Build, Scan, Publish

## Descripcion

Crear un pipeline CI/CD completo para una aplicacion web que:
1. Construye una imagen Docker optimizada (multi-stage build)
2. Escanea la imagen y dependencias en busca de vulnerabilidades
3. Publica la imagen en el Container Registry
4. Publica un paquete npm/PyPI en el Package Registry
5. Implementa politica de versionado y limpieza

## Requisitos del Proyecto

### 1. Aplicacion de ejemplo

Crear una aplicacion web simple (Node.js + Express o Python + Flask) con:
- Dockerfile con multi-stage build
- Al menos 5 dependencias en package.json/requirements.txt
- Tests unitarios basicos
- Script de inicio

### 2. Pipeline CI/CD

**Archivos del pipeline:**
```
.gitlab/
  ci/
    stages.yml
    docker-build.yml
    security.yml
    publish.yml
    cleanup.yml
.gitlab-ci.yml
```

**Stages:**
1. `build` — Construir imagen con DIND o Kaniko
2. `test` — Tests unitarios + lint
3. `security` — SAST, Dependency Scanning, Container Scanning, Secret Detection
4. `publish` — Push al container registry + publicar paquete
5. `cleanup` — Limpieza de imagenes antiguas (opcional)

### 3. Estrategia de versionado

```yaml
docker-build:
  script:
    - |
      # Tags inmutables
      docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA .
      
      # Tags movibles
      - docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
      
      # Rama principal -> latest
      - |
        if [ "$CI_COMMIT_BRANCH" = "main" ]; then
          docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA $CI_REGISTRY_IMAGE:latest
        fi
      
      # Tag semantico -> version
      - |
        if [ -n "$CI_COMMIT_TAG" ]; then
          docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA $CI_REGISTRY_IMAGE:$CI_COMMIT_TAG
        fi
      
      - docker push $CI_REGISTRY_IMAGE --all-tags
```

### 4. Container Registry y Package Registry

**Container Registry:**
- Imagen publicada con tags: commit SHA, branch, latest (main), version tag
- Politica de limpieza: mantener solo 5 tags por imagen, eliminar tags de ramas fusionadas

**Package Registry:**
- Publicar paquete npm (o PyPI) al crear tag versionado
- Version del paquete extraida del tag (v1.0.0 → 1.0.0)
- Paquete con scope del grupo

### 5. Pipeline de seguridad

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
    CS_SEVERITY_THRESHOLD: "high"
  needs:
    - docker-build
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

### 6. Limpieza

```yaml
cleanup-old-tags:
  stage: cleanup
  image: alpine:latest
  script:
    - apk add --no-cache curl jq
    - |
      # Listar tags y eliminar los que no son latest ni versionados
      TAGS=$(curl -s --header "PRIVATE-TOKEN: $CLEANUP_TOKEN" \
        "$CI_API_V4_URL/projects/$CI_PROJECT_ID/registry/repositories/1/tags" | \
        jq -r '.[].name' | grep -v -E '^(latest|v[0-9])' || true)
      for tag in $TAGS; do
        echo "Eliminando tag $tag (mantenemos latest y versionados)"
      done
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

## Entregables

- [ ] Aplicacion de ejemplo con Dockerfile multi-stage
- [ ] Pipeline con stages: build, test, security, publish, cleanup
- [ ] Imagen publicada en Container Registry con tags correctos
- [ ] Reporte de seguridad sin vulnerabilidades criticas
- [ ] Paquete npm/PyPI publicado en Package Registry
- [ ] Politica de limpieza configurada
- [ ] Pull de imagen y paquete funcionando desde fuera de GitLab

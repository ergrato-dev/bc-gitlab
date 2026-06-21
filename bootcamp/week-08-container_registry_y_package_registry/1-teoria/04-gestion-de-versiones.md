# 04 — Gestion de Versiones de Imagenes

## Estrategias de versionado

### 1. Semantic Versioning (SemVer)
```yaml
docker-build:
  script:
    - docker build -t $CI_REGISTRY_IMAGE:${CI_COMMIT_TAG} .
    - docker push $CI_REGISTRY_IMAGE:${CI_COMMIT_TAG}
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
```

Tags generados: `v1.0.0`, `v1.0.1`, `v2.0.0`

### 2. Commit SHA (inmutable)
```yaml
- docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA .
- docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
```

Tags generados: `abc1234`, `def5678`

### 3. Rama + SHA
```yaml
- export IMAGE_TAG="${CI_COMMIT_REF_SLUG}-${CI_COMMIT_SHORT_SHA}"
- docker build -t $CI_REGISTRY_IMAGE:$IMAGE_TAG .
```

Tags generados: `main-abc1234`, `feature-login-def5678`

### 4. Estrategia completa

```yaml
docker-build:
  stage: build
  image: docker:24-dind
  services:
    - docker:24-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY
  script:
    # Tag con commit SHA (inmutable)
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA .

    # Tag con rama (movible)
    - docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG

    # Tag latest solo en main
    - |
      if [ "$CI_COMMIT_BRANCH" = "main" ]; then
        docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA $CI_REGISTRY_IMAGE:latest
      fi

    # Si es tag semantico
    - |
      if [ -n "$CI_COMMIT_TAG" ]; then
        docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA $CI_REGISTRY_IMAGE:$CI_COMMIT_TAG
      fi

    - docker push --all-tags $CI_REGISTRY_IMAGE
```

## Limpieza de imagenes antiguas

### Politica de limpieza (Tag Cleanup)

Settings → Packages & Registries → Cleanup policies:
- **Keep most recent**: Cuantos tags mantener por imagen
- **Keep tags matching**: Regex para tags a conservar (ej: `.*-main-.*`)
- **Older than**: Antiguedad para eliminar (ej: 7 days)

### Limpieza via API
```bash
curl --header "PRIVATE-TOKEN: <token>" \
  "https://gitlab.example.com/api/v4/projects/<id>/registry/repositories/<repo_id>/tags"
```

### Limpieza en pipeline
```yaml
cleanup-old-images:
  stage: cleanup
  image: alpine:latest
  script:
    - apk add --no-cache curl jq
    - |
      # Obtener tags y eliminar los que no sean latest ni versionados
      curl --header "PRIVATE-TOKEN: $CLEANUP_TOKEN" \
        "$CI_API_V4_URL/projects/$CI_PROJECT_ID/registry/repositories/1/tags" | \
        jq -r '.[].name' | grep -v -E '^(latest|v[0-9])' | \
        while read tag; do
          echo "Eliminando tag: $tag"
        done
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

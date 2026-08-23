# 🔬 Práctica 02 — Build y Push de Imágenes en Pipeline

**Duración estimada:** 45 minutos
**Dificultad:** ⭐⭐⭐ (Media-Alta)

## 🎯 Objetivo

Implementar un pipeline CI/CD completo que construya una imagen Docker, la etiquete con múltiples tags (SHA, branch, SemVer), y la publique en el Container Registry de GitLab. Comparar el build con DinD vs Kaniko.

---

## 📋 Prerrequisitos

- Práctica 01 completada (Container Registry habilitado)
- Runner con `privileged = true` en `config.toml` (para DinD)
- `$GITLAB_TOKEN` y `$GITLAB_PROJECT_ID` exportados

```bash
# Verificar que el runner está online
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/runners?status=online" \
  | python3 -c "
import sys, json
runners = json.load(sys.stdin)
print(f'Runners online: {len(runners)}')
for r in runners:
    priv = '(privileged)' if r.get('run_untagged', False) else ''
    print(f'  #{r[\"id\"]}: {r[\"description\"]} {priv}')
"
```

---

## 🏗️ Paso 1: Crear la Aplicación de Ejemplo

Crear los siguientes archivos en el proyecto:

**`Dockerfile`** (multi-stage build):
```dockerfile
# Stage 1: Build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Runtime (imagen final más pequeña)
FROM node:18-alpine AS runtime
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY server.js ./
EXPOSE 3000
USER node
CMD ["node", "server.js"]
```

**`server.js`**:
```javascript
const http = require('http');
const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({
    status: 'ok',
    version: process.env.APP_VERSION || 'dev',
    commit: process.env.COMMIT_SHA || 'unknown',
    hostname: require('os').hostname(),
    timestamp: new Date().toISOString()
  }));
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Version: ${process.env.APP_VERSION || 'dev'}`);
});
```

**`package.json`**:
```json
{
  "name": "bootcamp-app",
  "version": "1.0.0",
  "description": "Aplicación de ejemplo para el bootcamp GitLab",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "test": "echo 'Tests OK' && exit 0"
  },
  "engines": {
    "node": ">=18"
  }
}
```

---

## 🐳 Paso 2: Pipeline con DinD

```yaml
# .gitlab-ci.yml — Opción A: Docker-in-Docker
stages:
  - build
  - verify

variables:
  DOCKER_TLS_CERTDIR: ""
  DOCKER_DRIVER: overlay2
  APP_VERSION: "1.0.0"

build-dind:
  stage: build
  image: docker:24-cli
  services:
    - name: docker:24-dind
      alias: docker
  variables:
    DOCKER_HOST: tcp://docker:2375
  before_script:
    # ¿QUÉ HACE?: Login al Container Registry de GitLab con el token temporal del job
    # ¿POR QUÉ?: CI_JOB_TOKEN es más seguro que un PAT — expira con el job
    # ¿PARA QUÉ?: Autenticar el push de la imagen al registry del proyecto
    - docker login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY
  script:
    # Build con argumentos de versión
    - docker build
        --build-arg COMMIT_SHA=$CI_COMMIT_SHORT_SHA
        --build-arg APP_VERSION=$APP_VERSION
        --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
        .

    # Tags adicionales según contexto
    - docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG

    - |
      if [ "$CI_COMMIT_BRANCH" = "main" ]; then
        docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA $CI_REGISTRY_IMAGE:latest
        echo "Tag 'latest' aplicado (rama main)"
      fi

    # Push todos los tags
    - docker push $CI_REGISTRY_IMAGE --all-tags

    # Mostrar resumen
    - echo "Imagen publicada:"
    - docker images $CI_REGISTRY_IMAGE --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"
  tags:
    - docker
    - privileged   # ← requiere runner con privileged = true

verify-image:
  stage: verify
  image: docker:24-cli
  services:
    - name: docker:24-dind
      alias: docker
  variables:
    DOCKER_HOST: tcp://docker:2375
  script:
    # ¿QUÉ HACE?: Descarga la imagen recién publicada y la ejecuta para verificar
    # ¿POR QUÉ?: Confirmar que la imagen no solo fue publicada sino que funciona
    # ¿PARA QUÉ?: Smoke test básico del build antes de continuar el pipeline
    - docker login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY
    - docker pull $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
    - |
      docker run --rm \
        --env APP_VERSION=$APP_VERSION \
        --env COMMIT_SHA=$CI_COMMIT_SHORT_SHA \
        $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA \
        node -e "
const http = require('http');
const server = require('./server.js');
setTimeout(() => { process.exit(0); }, 100);
" 2>/dev/null || true
    - echo "✅ Imagen verificada: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA"
  needs: [build-dind]
  tags: [docker, privileged]
```

---

## ⚡ Paso 3: Pipeline con Kaniko (alternativa sin privilegios)

```yaml
# .gitlab-ci.yml — Opción B: Kaniko (sin privileged)
stages:
  - build
  - verify

build-kaniko:
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:v1.23.0-debug
    entrypoint: [""]
  script:
    # ¿QUÉ HACE?: Configura autenticación en el formato que Kaniko espera (JSON)
    # ¿POR QUÉ?: Kaniko no usa docker CLI, necesita config.json directamente
    # ¿PARA QUÉ?: Push automático al registry al terminar el build
    - mkdir -p /kaniko/.docker
    - |
      echo "{
        \"auths\":{
          \"$CI_REGISTRY\":{
            \"username\":\"$CI_REGISTRY_USER\",
            \"password\":\"$CI_JOB_TOKEN\"
          }
        }
      }" > /kaniko/.docker/config.json

    # Build con cache y múltiples destinos
    - /kaniko/executor
        --context $CI_PROJECT_DIR
        --dockerfile $CI_PROJECT_DIR/Dockerfile
        --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
        --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
        --cache=true
        --cache-repo $CI_REGISTRY_IMAGE/cache
        --cache-ttl 168h
        --build-arg COMMIT_SHA=$CI_COMMIT_SHORT_SHA
        --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        --label org.opencontainers.image.revision=$CI_COMMIT_SHA
        --label org.opencontainers.image.created=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        --label org.opencontainers.image.source=$CI_PROJECT_URL
  tags:
    - docker    # NO necesita privileged
```

> **Diferencia clave:** Con Kaniko, no hay un job `verify-image` separado que haga `docker run` porque Kaniko no tiene docker CLI. La verificación se hace via la API del registry o en un job posterior con otro executor.

---

## 📊 Paso 4: Comparar DinD vs Kaniko

Después de ejecutar ambos pipelines, comparar los tiempos:

```bash
# ¿QUÉ HACE?: Consulta la duración de los jobs de build de los dos últimos pipelines
# ¿POR QUÉ?: Comparar tiempos de DinD vs Kaniko con y sin cache
# ¿PARA QUÉ?: Tomar una decisión informada sobre qué método usar

curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/jobs?scope=success&per_page=10" \
  | python3 -c "
import sys, json
jobs = json.load(sys.stdin)
build_jobs = [j for j in jobs if 'build' in j['name']]
print(f'{'Job':<25} {'Duración':>10} {'Runner'}')
print('-' * 60)
for j in build_jobs[:6]:
    dur = f'{j.get(\"duration\",0):.1f}s' if j.get('duration') else '-'
    runner = j.get('runner',{}).get('description','?')
    print(f'{j[\"name\"]:<25} {dur:>10} {runner}')
"
```

**Tabla de comparación a completar:**

| Métrica | DinD (sin cache) | DinD (con cache) | Kaniko (sin cache) | Kaniko (con cache) |
|---------|-----------------|-----------------|-------------------|--------------------|
| Tiempo de build | __ s | __ s | __ s | __ s |
| Privilegios | privileged=true | privileged=true | ninguno | ninguno |
| Tamaño imagen | __ MB | __ MB | __ MB | __ MB |

---

## 🔍 Paso 5: Verificar Tags en el Registry

```bash
# ¿QUÉ HACE?: Lista todos los tags publicados de la imagen
# ¿POR QUÉ?: Confirmar que todos los tags (SHA, branch, latest) se publicaron correctamente
# ¿PARA QUÉ?: Validar la estrategia de versionado antes de avanzar

# Obtener ID del repository
REPO_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/registry/repositories" \
  | python3 -c "
import sys, json
repos = json.load(sys.stdin)
# Buscar el repository de la imagen principal (no el cache de Kaniko)
for r in repos:
    if '/cache' not in r.get('name',''):
        print(r['id'])
        break
")

echo "Repository ID: $REPO_ID"

curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/registry/repositories/$REPO_ID/tags" \
  | python3 -c "
import sys, json
tags = json.load(sys.stdin)
print(f'Tags publicados: {len(tags)}')
print()
for t in sorted(tags, key=lambda x: x.get('created_at',''), reverse=True):
    size_mb = t.get('total_size', 0) / 1024 / 1024
    print(f'  {t[\"name\"]:<30} {size_mb:5.1f} MB  {t.get(\"created_at\",\"\")[:19]}')
"
```

---

## ✅ Checklist de verificación

- [ ] Dockerfile con multi-stage build commiteado al proyecto
- [ ] Pipeline DinD completa sin errores (requiere runner privileged)
- [ ] Pipeline Kaniko completa sin errores (sin runner privileged)
- [ ] Registry muestra al menos 3 tags: SHA, branch-slug, latest (si es main)
- [ ] `docker pull $CI_REGISTRY_IMAGE:latest` funciona desde el host
- [ ] `docker run` de la imagen muestra JSON con status:ok
- [ ] Tabla de comparación DinD vs Kaniko completada

---

## 🏆 Reto adicional

Agregar OCI labels estándar a la imagen para trazabilidad completa:

```dockerfile
# En el Dockerfile:
ARG COMMIT_SHA="unknown"
ARG BUILD_DATE="unknown"
ARG SOURCE_URL="unknown"

LABEL org.opencontainers.image.revision=$COMMIT_SHA \
      org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.source=$SOURCE_URL \
      org.opencontainers.image.title="bootcamp-app" \
      org.opencontainers.image.vendor="Bootcamp GitLab"
```

```bash
# Verificar los labels de la imagen publicada:
docker inspect $CI_REGISTRY_IMAGE:latest \
  --format '{{json .Config.Labels}}' | python3 -c "
import sys, json
labels = json.loads(sys.stdin.read())
for k, v in labels.items():
    if 'opencontainers' in k:
        print(f'{k.split(\".\")[-1]}: {v}')
"
```

---

⬅️ **Práctica anterior:** [01 — Container Registry Setup](../01-container-registry-setup/README.md)
➡️ **Siguiente práctica:** [03 — Package Registry](../03-package-registry/README.md)

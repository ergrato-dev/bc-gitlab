# 🏗️ Proyecto — Semana 08: Pipeline Integral Build, Scan y Publish

## 📋 Descripción

Implementar un pipeline CI/CD completo para una aplicación Node.js que: construye una imagen Docker optimizada con multi-stage build, escanea la imagen y el código en busca de vulnerabilidades, publica la imagen en el Container Registry con estrategia de versionado completa, publica un paquete npm en el Package Registry, y aplica una política de limpieza de tags.

---

## 🎯 Objetivos del Proyecto

Al completar el proyecto habrás:
1. Construido y publicado una imagen Docker con 4 tags diferentes según el contexto (SHA, branch, SemVer, latest)
2. Integrado los 4 tipos de security scanning en el pipeline
3. Publicado un paquete npm en el Package Registry consumible por otros proyectos
4. Configurado la Tag Cleanup Policy del registry
5. Demostrado todo el flujo en un único pipeline modular (`.gitlab/ci/` structure)

---

## 🏗️ Paso 1: Estructura del Proyecto

```
bootcamp-app/
├── .gitlab/
│   └── ci/
│       ├── docker-build.yml     ← build y push de imagen
│       ├── security.yml         ← SAST, secrets, deps, container scan
│       ├── publish.yml          ← npm package + additional tags
│       └── cleanup.yml          ← limpieza de tags via API
├── src/
│   ├── app.js                   ← Express app principal
│   └── utils/
│       └── index.js             ← módulo exportable
├── test/
│   └── app.test.js              ← tests básicos
├── .dockerignore
├── .gitlab-ci.yml               ← orquestador (solo include:)
├── Dockerfile                   ← multi-stage build
└── package.json
```

### `.gitlab-ci.yml` (orquestador)

```yaml
include:
  - local: .gitlab/ci/docker-build.yml
  - local: .gitlab/ci/security.yml
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml
  - local: .gitlab/ci/publish.yml
  - local: .gitlab/ci/cleanup.yml

stages:
  - build
  - test
  - security
  - publish
  - cleanup

variables:
  APP_NAME: "bootcamp-app"
  APP_VERSION: "1.0.0"
  DOCKER_TLS_CERTDIR: ""
  DOCKER_DRIVER: overlay2
  NODE_ENV: production
```

---

## 🐳 Paso 2: Docker Build Modular

**`.gitlab/ci/docker-build.yml`:**

```yaml
docker-build:
  stage: build
  image: docker:24-cli
  services:
    - name: docker:24-dind
      alias: docker
  variables:
    DOCKER_HOST: tcp://docker:2375
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY
  script:
    # ¿QUÉ HACE?: Construye la imagen con metadatos OCI estándar
    # ¿POR QUÉ?: Los labels vinculan cada imagen al commit exacto que la generó
    # ¿PARA QUÉ?: Trazabilidad completa — dado cualquier imagen puedo encontrar el commit

    - BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    - docker build
        --build-arg COMMIT_SHA=$CI_COMMIT_SHORT_SHA
        --build-arg APP_VERSION=$APP_VERSION
        --build-arg BUILD_DATE=$BUILD_DATE
        --label org.opencontainers.image.revision=$CI_COMMIT_SHA
        --label org.opencontainers.image.created=$BUILD_DATE
        --label org.opencontainers.image.source=$CI_PROJECT_URL
        --label org.opencontainers.image.version=$APP_VERSION
        --target runtime
        -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
        .

    # Push del tag inmutable (base)
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA

    # Tag de rama (movible)
    - docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG

    # Mostrar tamaños de imagen (multi-stage vs base)
    - docker images --filter "reference=$CI_REGISTRY_IMAGE" --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"
  artifacts:
    reports:
      dotenv: build.env   # pasar el SHA a jobs downstream
  after_script:
    - echo "IMAGE_TAG=$CI_COMMIT_SHORT_SHA" > build.env
  tags: [docker, privileged]
  rules:
    - if: $CI_COMMIT_BRANCH
    - if: $CI_COMMIT_TAG
```

---

## 🔒 Paso 3: Security Pipeline

**`.gitlab/ci/security.yml`:**

```yaml
container_scanning:
  variables:
    CS_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
    CS_DOCKERFILE_PATH: Dockerfile
    CS_SEVERITY_THRESHOLD: "high"
  needs:
    - docker-build
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_COMMIT_TAG

security-gate:
  stage: security
  image: alpine:latest
  needs:
    - job: container_scanning
      optional: true
    - job: dependency_scanning
      optional: true
  script:
    # ¿QUÉ HACE?: Analiza los reportes de seguridad y decide si el pipeline puede continuar
    # ¿POR QUÉ?: Los templates de GitLab no bloquean por defecto — este job lo fuerza
    # ¿PARA QUÉ?: Gate de calidad: no publicar imágenes con vulnerabilidades CRITICAL
    - |
      CRITICAL_COUNT=0

      if [ -f gl-container-scanning-report.json ]; then
        CRITICAL_COUNT=$(python3 -c "
import json
with open('gl-container-scanning-report.json') as f:
    report = json.load(f)
vulns = report.get('vulnerabilities', [])
count = sum(1 for v in vulns if v.get('severity') == 'Critical')
print(count)
")
        echo "Container Scanning: $CRITICAL_COUNT vulnerabilidades CRITICAL"
      fi

      if [ "$CRITICAL_COUNT" -gt 0 ]; then
        echo "❌ Pipeline bloqueado: $CRITICAL_COUNT vulnerabilidades CRITICAL encontradas"
        echo "   Revisar el Vulnerability Report del proyecto antes de publicar"
        exit 1
      fi

      echo "✅ Security gate superado: 0 vulnerabilidades CRITICAL"
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_COMMIT_TAG
```

---

## 📦 Paso 4: Publish — Tags Adicionales + Paquete npm

**`.gitlab/ci/publish.yml`:**

```yaml
# Tags adicionales en main y en releases semánticas
publish-tags:
  stage: publish
  image: docker:24-cli
  services:
    - name: docker:24-dind
      alias: docker
  variables:
    DOCKER_HOST: tcp://docker:2375
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY
  script:
    - docker pull $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA

    # latest → solo en main
    - |
      if [ "$CI_COMMIT_BRANCH" = "main" ]; then
        docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA $CI_REGISTRY_IMAGE:latest
        docker push $CI_REGISTRY_IMAGE:latest
        echo "✅ Tag 'latest' publicado"
      fi

    # SemVer → solo en tags v*
    - |
      if [ -n "$CI_COMMIT_TAG" ]; then
        docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA $CI_REGISTRY_IMAGE:$CI_COMMIT_TAG
        docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_TAG
        docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA $CI_REGISTRY_IMAGE:latest
        docker push $CI_REGISTRY_IMAGE:latest
        echo "✅ Tag '$CI_COMMIT_TAG' y 'latest' publicados"
      fi
  needs: [security-gate]
  tags: [docker, privileged]
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/

# Publicar paquete npm en releases semánticas
publish-npm:
  stage: publish
  image: node:18-alpine
  script:
    - |
      REGISTRY_URL="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/npm/"
      cat > .npmrc << EOF
      @${CI_PROJECT_NAMESPACE}:registry=${REGISTRY_URL}
      ${REGISTRY_URL#https:}:_authToken=${CI_JOB_TOKEN}
      EOF
    - npm publish
    - echo "✅ Paquete npm @${CI_PROJECT_NAMESPACE}/$(node -e 'process.stdout.write(require(\"./package.json\").name.split(\"/\")[1])') publicado"
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
```

---

## 🧹 Paso 5: Cleanup Policy

**`.gitlab/ci/cleanup.yml`:**

```yaml
# Job de limpieza — corre solo por pipeline schedule
cleanup-registry:
  stage: cleanup
  image: alpine:latest
  script:
    - apk add --no-cache curl python3
    - |
      python3 << 'PYEOF'
      import subprocess, json, re

      GITLAB_TOKEN = "$CLEANUP_TOKEN"   # usar token separado con acceso al registry API
      PROJECT_ID = "$CI_PROJECT_ID"
      BASE_URL = "http://localhost/api/v4"

      headers = f"PRIVATE-TOKEN: {GITLAB_TOKEN}"
      keep_pattern = re.compile(r'^(latest|main|develop|v\d+\.\d+\.\d+)$')

      # Obtener repositories
      result = subprocess.run(
          ["curl", "-s", "--header", headers,
           f"{BASE_URL}/projects/{PROJECT_ID}/registry/repositories?per_page=10"],
          capture_output=True, text=True
      )
      repos = json.loads(result.stdout)

      for repo in repos:
          if '/cache' in repo.get('name', ''):
              continue   # no limpiar el cache de Kaniko

          repo_id = repo["id"]
          result = subprocess.run(
              ["curl", "-s", "--header", headers,
               f"{BASE_URL}/projects/{PROJECT_ID}/registry/repositories/{repo_id}/tags?per_page=100"],
              capture_output=True, text=True
          )
          all_tags = json.loads(result.stdout)

          # Ordenar por fecha descendente
          all_tags.sort(key=lambda t: t.get('created_at',''), reverse=True)

          # Mantener los 10 más recientes + los que coinciden con el patrón
          to_keep = set()
          for t in all_tags[:10]:
              to_keep.add(t['name'])
          for t in all_tags:
              if keep_pattern.match(t['name']):
                  to_keep.add(t['name'])

          to_delete = [t for t in all_tags if t['name'] not in to_keep]

          print(f"Imagen: {repo['path']}")
          print(f"  Total: {len(all_tags)}, mantener: {len(to_keep)}, eliminar: {len(to_delete)}")

          for tag in to_delete:
              print(f"  Eliminando: {tag['name']}")
              subprocess.run(
                  ["curl", "-s", "--request", "DELETE", "--header", headers,
                   f"{BASE_URL}/projects/{PROJECT_ID}/registry/repositories/{repo_id}/tags/{tag['name']}"],
                  capture_output=True
              )

      print("✅ Limpieza completada")
      PYEOF
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

---

## 📐 Paso 6: Configurar Cleanup Policy via API

```bash
# ¿QUÉ HACE?: Configura la cleanup policy automática del proyecto via API
# ¿POR QUÉ?: La política automática corre mensualmente sin necesidad de un pipeline manual
# ¿PARA QUÉ?: Control de costos de almacenamiento a largo plazo

curl --silent --request PUT \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "container_expiration_policy_attributes": {
      "cadence": "1month",
      "enabled": true,
      "keep_n": 10,
      "older_than": "90d",
      "name_regex_keep": "latest|main|develop|v\\d+\\.\\d+\\.\\d+",
      "name_regex": ".*"
    }
  }' \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID" \
  | python3 -c "
import sys, json
p = json.load(sys.stdin)
policy = p.get('container_expiration_policy', {})
print('Cleanup policy configurada:')
print(f'  Cadencia: {policy.get(\"cadence\")}')
print(f'  Mantener últimos N: {policy.get(\"keep_n\")}')
print(f'  Mantener patrón: {policy.get(\"name_regex_keep\")}')
print(f'  Eliminar si más viejos de: {policy.get(\"older_than\")}')
"
```

---

## 📊 Paso 7: Verificación Final

```bash
# ¿QUÉ HACE?: Tabla completa del estado del registry al finalizar el proyecto
# ¿POR QUÉ?: Evidencia de que todos los pasos se completaron
# ¿PARA QUÉ?: Referencia para la entrega del proyecto

echo "=== ESTADO FINAL — SEMANA 08 ==="
echo ""

echo "--- Container Registry ---"
REPO_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/registry/repositories" \
  | python3 -c "
import sys, json
repos = json.load(sys.stdin)
for r in repos:
    if '/cache' not in r.get('name',''):
        print(r['id'])
        break
" 2>/dev/null)

if [ -n "$REPO_ID" ]; then
  curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/registry/repositories/$REPO_ID/tags?per_page=20" \
    | python3 -c "
import sys, json
tags = json.load(sys.stdin)
print(f'Tags publicados: {len(tags)}')
for t in tags:
    size_mb = t.get('total_size', 0) / 1024 / 1024
    print(f'  {t[\"name\"]:<30} {size_mb:5.1f} MB')
"
fi

echo ""
echo "--- Package Registry ---"
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/packages?per_page=10" \
  | python3 -c "
import sys, json
pkgs = json.load(sys.stdin)
print(f'Paquetes publicados: {len(pkgs)}')
for p in pkgs:
    print(f'  [{p[\"package_type\"]}] {p[\"name\"]}@{p[\"version\"]}')
"

echo ""
echo "--- Pipelines más recientes ---"
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/pipelines?per_page=5" \
  | python3 -c "
import sys, json
pipelines = json.load(sys.stdin)
for p in pipelines:
    print(f'  #{p[\"id\"]:5} {p[\"status\"]:<10} {p[\"ref\"]:<25} {p.get(\"created_at\",\"\")[:19]}')
"
```

---

## 📦 Entregables

- [ ] Dockerfile con multi-stage build commiteado (`builder` + `runtime`)
- [ ] Pipeline modular con 4 módulos en `.gitlab/ci/`
- [ ] Imagen publicada con 4 tags: SHA, branch, SemVer (tag `v1.0.0`), latest
- [ ] Pipeline de security: los 4 scanners ejecutados (passed o failed con hallazgos)
- [ ] Vulnerability Report: al menos 1 vulnerabilidad dismissada con razón
- [ ] Paquete npm publicado en Package Registry (crear tag `v1.0.0`)
- [ ] Tag Cleanup Policy configurada via API (verificar con GET /projects/:id)
- [ ] Captura de la UI: `Packages & Registries → Container Registry` con los 4 tags
- [ ] Captura de la UI: `Deploy → Package Registry` con el paquete npm

---

⬅️ **Prácticas:** [2-practicas/README.md](../2-practicas/README.md)
➡️ **Glosario:** [5-glosario/README.md](../5-glosario/README.md)

# Práctica 02 — Pipeline CI/CD Completo

## Objetivo

Crear la aplicación de ejemplo con sus tests, el `.gitlab-ci.yml` completo con 5 stages, los templates CI reutilizables, integración con Container Registry y despliegue a dos entornos (staging/production). Al final del lab, un push a `main` desencadena automáticamente el deploy a staging.

## Requisitos

- Infraestructura de la Práctica 01 funcional (GitLab + Runner + Registry)
- Runner con executor Docker y acceso a `/var/run/docker.sock`
- Tiempo estimado: 75-90 minutos

---

## Instrucciones

### Paso 1: Crear la aplicación de ejemplo (Flask + pytest)

```bash
cd ~/proyecto-final

# Aplicación Flask simple con vulnerabilidades intencionales para SAST
cat > app/src/app.py << 'PYTHON'
import os
import subprocess
import hashlib
from flask import Flask, request, jsonify

app = Flask(__name__)

# Vulnerabilidad intencional #1: Contraseña hardcodeada (Secret Detection la detecta)
DB_PASSWORD = "super_secret_password_123"

@app.route('/health')
def health():
    return jsonify({"status": "ok", "version": "1.0.0"})

@app.route('/users')
def get_users():
    # Vulnerabilidad intencional #2: SQL injection via formato de string (SAST detecta)
    user_id = request.args.get('id', '1')
    query = "SELECT * FROM users WHERE id = %s" % user_id
    return jsonify({"query": query, "note": "vulnerable on purpose for SAST demo"})

@app.route('/hash')
def hash_value():
    # Vulnerabilidad intencional #3: MD5 inseguro (Bandit/SAST detecta)
    data = request.args.get('data', 'test')
    result = hashlib.md5(data.encode()).hexdigest()
    return jsonify({"hash": result, "algorithm": "MD5 (insecure)"})

@app.route('/ping')
def ping():
    # Vulnerabilidad intencional #4: command injection (SAST detecta)
    host = request.args.get('host', 'localhost')
    result = subprocess.run(['ping', '-c', '1', host], capture_output=True, text=True)
    return jsonify({"output": result.stdout[:200]})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)
PYTHON

# requirements.txt
cat > app/requirements.txt << 'EOF'
flask==3.0.3
gunicorn==22.0.0
pytest==8.2.0
pytest-cov==5.0.0
requests==2.32.0
EOF

# Tests unitarios
cat > app/tests/test_app.py << 'PYTHON'
import pytest
from src.app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_health(client):
    rv = client.get('/health')
    assert rv.status_code == 200
    data = rv.get_json()
    assert data['status'] == 'ok'
    assert 'version' in data

def test_users_returns_200(client):
    rv = client.get('/users?id=1')
    assert rv.status_code == 200

def test_hash_returns_hash(client):
    rv = client.get('/hash?data=test')
    assert rv.status_code == 200
    data = rv.get_json()
    assert 'hash' in data
    assert len(data['hash']) == 32  # MD5 siempre produce 32 chars hex

def test_ping_responds(client):
    rv = client.get('/ping?host=127.0.0.1')
    assert rv.status_code == 200

class TestHealthEndpoint:
    def test_returns_json(self, client):
        rv = client.get('/health')
        assert rv.content_type == 'application/json'

    def test_version_field_present(self, client):
        rv = client.get('/health')
        data = rv.get_json()
        assert data.get('version') == '1.0.0'
PYTHON

# Dockerfile optimizado (capas ordenadas de menos a más cambiante)
cat > app/Dockerfile << 'DOCKERFILE'
FROM python:3.11-slim

WORKDIR /app

# Dependencias primero (cambian menos que el código)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Código fuente
COPY src/ ./src/

# Usuario no-root
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')" || exit 1

CMD ["gunicorn", "src.app:app", "--bind", "0.0.0.0:8080", "--workers", "2"]
DOCKERFILE

echo "✅ Aplicación de ejemplo creada"
ls -la app/
```

### Paso 2: Crear el proyecto en GitLab y subir el código

```bash
# ¿QUÉ HACE?: Inicializa git y sube el proyecto al GitLab local
# ¿POR QUÉ?: El pipeline se dispara en cada push al repositorio de GitLab
# ¿PARA QUÉ?: Tener el código en GitLab para que el Runner pueda clonarlo en cada job

cd ~/proyecto-final

git init
git add .
git commit -m "feat: aplicación Flask de ejemplo con Dockerfile y tests"

# Crear proyecto en GitLab via API
ADMIN_TOKEN="TU_TOKEN_ADMIN"
PROJECT_ID=$(curl -s --request POST \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "proyecto-final",
    "path": "proyecto-final",
    "description": "Proyecto final bootcamp GitLab CE",
    "visibility": "private",
    "initialize_with_readme": false,
    "default_branch": "main"
  }' \
  "http://localhost/api/v4/projects" | jq -r '.id')

echo "Proyecto creado con ID: $PROJECT_ID"

# Configurar el remote y hacer push
git remote add origin http://localhost/root/proyecto-final.git
git push -u origin main
```

### Paso 3: Crear los templates CI reutilizables

```bash
# ci-templates/build.yml
cat > ci-templates/build.yml << 'EOF'
.build-docker-template:
  image: docker:24
  services:
    - docker:24-dind
  variables:
    DOCKER_DRIVER: overlay2
    DOCKER_TLS_CERTDIR: ""
    DOCKER_BUILDKIT: "1"
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - cd app
    - docker pull $CI_REGISTRY_IMAGE/app:latest || true
    - docker build
        --build-arg BUILDKIT_INLINE_CACHE=1
        --cache-from $CI_REGISTRY_IMAGE/app:latest
        --tag $CI_REGISTRY_IMAGE/app:$CI_COMMIT_SHORT_SHA
        --file Dockerfile
        .
    - docker push $CI_REGISTRY_IMAGE/app:$CI_COMMIT_SHORT_SHA
  after_script:
    - docker logout $CI_REGISTRY
  tags:
    - docker
EOF

# ci-templates/deploy.yml
cat > ci-templates/deploy.yml << 'EOF'
.deploy-template:
  image: docker:24
  variables:
    DEPLOY_PORT: "5001"
    DEPLOY_NAME: "app-staging"
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker pull $CI_REGISTRY_IMAGE/app:$CI_COMMIT_SHORT_SHA
    - docker stop $DEPLOY_NAME 2>/dev/null || true
    - docker rm $DEPLOY_NAME 2>/dev/null || true
    - docker run -d
        --name $DEPLOY_NAME
        --restart unless-stopped
        -p $DEPLOY_PORT:8080
        --network proyecto-final-net
        $CI_REGISTRY_IMAGE/app:$CI_COMMIT_SHORT_SHA
    - |
      # Smoke test
      for i in $(seq 1 15); do
        if curl -sf http://localhost:$DEPLOY_PORT/health > /dev/null 2>&1; then
          echo "✅ App respondiendo en :$DEPLOY_PORT"
          exit 0
        fi
        sleep 2
      done
      echo "❌ Smoke test fallido"
      exit 1
  after_script:
    - docker logout $CI_REGISTRY
  tags:
    - docker
EOF
```

### Paso 4: Crear el .gitlab-ci.yml principal

```bash
cat > .gitlab-ci.yml << 'EOF'
stages:
  - build
  - test
  - security
  - package
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: ""
  APP_IMAGE: $CI_REGISTRY_IMAGE/app:$CI_COMMIT_SHORT_SHA

# Templates locales y de seguridad CE
include:
  - local: ci-templates/build.yml
  - local: ci-templates/deploy.yml
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml

# ─── BUILD ────────────────────────────────────────────────────────────────────
build:
  extends: .build-docker-template
  stage: build

# ─── TEST ─────────────────────────────────────────────────────────────────────
unit-tests:
  stage: test
  image: python:3.11-slim
  cache:
    key: "$CI_COMMIT_REF_SLUG-pip"
    paths:
      - app/.venv/
  before_script:
    - cd app
    - python -m venv .venv
    - source .venv/bin/activate
    - pip install --quiet -r requirements.txt
  script:
    - source .venv/bin/activate
    - pytest tests/ --junitxml=junit.xml --cov=src --cov-report=xml -v
  coverage: '/TOTAL.*\s+(\d+%)$/'
  artifacts:
    when: always
    reports:
      junit: app/junit.xml
      coverage_report:
        coverage_format: cobertura
        path: app/coverage.xml
    expire_in: 1 week

# ─── SECURITY ─────────────────────────────────────────────────────────────────
container-scanning:
  variables:
    CS_IMAGE: $APP_IMAGE
    CS_DOCKERFILE_PATH: app/Dockerfile

security-gate:
  stage: security
  image: python:3.11-slim
  needs:
    - job: bandit-sast
      optional: true
      artifacts: true
  script:
    - |
      python3 << 'PYTHON'
      import json, sys, os

      report_path = 'gl-sast-report.json'
      if not os.path.exists(report_path):
          print("Sin reporte SAST — omitiendo gate")
          sys.exit(0)

      with open(report_path) as f:
          report = json.load(f)

      critical = [v for v in report.get('vulnerabilities', [])
                  if v.get('severity') in ('Critical', 'High')]

      if critical:
          print(f"⚠️  {len(critical)} vulnerabilidades HIGH/CRITICAL encontradas (ver Security Dashboard)")
          for v in critical[:5]:
              print(f"  [{v['severity']}] {v['message']}")
          # En CE no podemos bloquear automáticamente — solo reportamos
          # Cambiar exit(1) si se quiere bloquear el pipeline
      else:
          print("✅ Sin vulnerabilidades HIGH/CRITICAL")
      PYTHON
  allow_failure: true

# ─── PACKAGE ──────────────────────────────────────────────────────────────────
tag-latest:
  stage: package
  image: docker:24
  services:
    - docker:24-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker pull $APP_IMAGE
    - docker tag $APP_IMAGE $CI_REGISTRY_IMAGE/app:latest
    - docker push $CI_REGISTRY_IMAGE/app:latest
  after_script:
    - docker logout $CI_REGISTRY
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  tags:
    - docker

# ─── DEPLOY ───────────────────────────────────────────────────────────────────
deploy-staging:
  extends: .deploy-template
  stage: deploy
  variables:
    DEPLOY_PORT: "5001"
    DEPLOY_NAME: "app-staging"
  environment:
    name: staging
    url: http://$CI_SERVER_HOST:5001
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: on_success

deploy-production:
  extends: .deploy-template
  stage: deploy
  variables:
    DEPLOY_PORT: "5000"
    DEPLOY_NAME: "app-production"
  environment:
    name: production
    url: http://$CI_SERVER_HOST:5000
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
      when: manual
EOF
```

### Paso 5: Configurar variables CI/CD en GitLab

```bash
# ¿QUÉ HACE?: Configura las variables necesarias para el pipeline
# ¿POR QUÉ?: Sin estas variables, el job de build no puede autenticarse al Registry
# ¿PARA QUÉ?: El pipeline puede construir y subir la imagen Docker automáticamente

# Crear un Project Access Token para el Container Registry
PAT_ID=$(curl -s --request POST \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "ci-registry-token",
    "scopes": ["read_registry", "write_registry"],
    "expires_at": "2025-12-31"
  }' \
  "http://localhost/api/v4/projects/$PROJECT_ID/access_tokens" | jq -r '.token')

echo "Token creado. Usar como CI_REGISTRY_PASSWORD"

# Configurar variables del proyecto
for var_data in \
  "{\"key\":\"CI_REGISTRY_USER\",\"value\":\"root\",\"protected\":true,\"masked\":false}" \
  "{\"key\":\"CI_REGISTRY_PASSWORD\",\"value\":\"$PAT_ID\",\"protected\":true,\"masked\":true}" \
  "{\"key\":\"CI_REGISTRY\",\"value\":\"localhost:5050\",\"protected\":false,\"masked\":false}"; do

  curl -s --request POST \
    --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    --header "Content-Type: application/json" \
    --data "$var_data" \
    "http://localhost/api/v4/projects/$PROJECT_ID/variables" | jq '{key, protected, masked}'
done
```

### Paso 6: Disparar el primer pipeline y monitorear

```bash
# Push para disparar el pipeline
git add .
git commit -m "ci: pipeline completo con SAST, tests y deploy automático"
git push origin main

# Monitorear el pipeline via API
sleep 10  # Dar tiempo a que GitLab cree el pipeline

PIPELINE_ID=$(curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines?ref=main&per_page=1" | \
  jq '.[0].id')

echo "Pipeline ID: $PIPELINE_ID"

# Esperar hasta que termine (polling cada 30s)
while true; do
  STATUS=$(curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    "http://localhost/api/v4/projects/$PROJECT_ID/pipelines/$PIPELINE_ID" | \
    jq -r '.status')
  echo "$(date +%T) — Estado: $STATUS"
  [ "$STATUS" = "success" ] || [ "$STATUS" = "failed" ] && break
  sleep 30
done

echo "Pipeline terminó con estado: $STATUS"

# Ver jobs del pipeline
curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines/$PIPELINE_ID/jobs" | \
  jq '.[] | "\(.stage)/\(.name): \(.status) (\(.duration // 0 | floor)s)"' -r
```

### Paso 7: Verificar el deploy en staging

```bash
# Verificar que la app de staging está corriendo
curl -s http://localhost:5001/health | python3 -m json.tool

# Ver la imagen en el Container Registry
curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/registry/repositories" | \
  jq '.[0] | {name, tags_count, location}'

# Verificar los tags disponibles en el registry
curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/registry/repositories/1/tags" | \
  jq '.[] | {name, created_at}'

# Crear un tag de versión para probar deploy a production (manual)
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
# → En GitLab UI: CI/CD → Pipelines → deploy-production aparece como "manual"
# → Click en el botón ► para ejecutar el deploy a production
```

---

## Preguntas de reflexión

1. El job `build` usa `docker:24-dind` como servicio. ¿Por qué se necesita DinD (Docker-in-Docker) para construir imágenes en un job de CI? ¿Qué alternativa existe?

2. El job `security-gate` tiene `allow_failure: true`. ¿En qué situación cambiarías esto a `false`? ¿Qué impacto tendría en el flujo de trabajo del equipo?

3. El deploy a staging es automático en push a `main` pero el de production es manual. ¿Por qué esta asimetría? ¿En qué caso harías ambos automáticos?

4. Si el job `unit-tests` falla, ¿se ejecuta `deploy-staging`? Explica la lógica de dependencias entre stages en GitLab CI.

5. Las variables `CI_REGISTRY_USER` y `CI_REGISTRY_PASSWORD` están marcadas como "protegidas". ¿Esto significa que solo son accesibles en `main`? ¿Cómo afecta a un MR desde una feature branch?

---

## Entregables

- [ ] `app/Dockerfile` construido y subido al Container Registry
- [ ] `app/tests/test_app.py` con mínimo 5 tests ejecutados
- [ ] Pipeline con los 5 stages visible en CI/CD → Pipelines
- [ ] Job `unit-tests` con reporte de cobertura visible en el MR
- [ ] Jobs SAST y Secret-Detection ejecutados (con hallazgos o sin ellos)
- [ ] Job `deploy-staging` completado exitosamente
- [ ] App accesible en http://localhost:5001/health
- [ ] Security Dashboard con hallazgos de SAST en Security → Vulnerability Report
- [ ] Variables CI/CD configuradas: `CI_REGISTRY_USER`, `CI_REGISTRY_PASSWORD`, `CI_REGISTRY`
- [ ] Environment "staging" visible en Deployments → Environments

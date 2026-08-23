# 📁 Proyecto Semana 05 — Pipeline CI/CD Completo para el API Gateway

## 🎯 Objetivo del Proyecto

Implementar un pipeline CI/CD completo y funcional en el proyecto `api-gateway` del bootcamp, que automatice validación, tests (con base de datos real), build, generación de artifacts, y reportes de cobertura visibles en los MRs.

## ⏱️ Tiempo estimado: 3-4 horas

---

## 📐 Arquitectura del Pipeline

```
[push / MR]
     ↓
Stage 1: validate    ──── lint (node/eslint)
                     ──── security-audit (npm audit)
                          ↓ (paralelo)
Stage 2: test        ──── unit-tests (con cobertura)
                     ──── integration-tests (PostgreSQL)
                          ↓ (necesita ambos tests)
Stage 3: build       ──── build-dist (compilar/empaquetar)
                          ↓ (solo en main)
Stage 4: deploy      ──── deploy-staging (automático)
                     ──── deploy-production (manual)
```

---

## 🏗️ Fase 1: Preparar el Proyecto (30 min)

### 1.1 Estructura de Archivos Necesaria

```bash
# En el repo api-gateway (ya clonado de semanas anteriores):
cd /tmp/api-gw-mr-practice   # O donde tengas el repo

# Crear la estructura de archivos del proyecto
mkdir -p src/routes src/middleware tests

# Archivo principal:
cat > src/app.js << 'JSEOF'
const express = require('express');
const healthRouter = require('./routes/health');

const app = express();
app.use(express.json());
app.use('/health', healthRouter);

module.exports = app;

if (require.main === module) {
  const port = process.env.PORT || 3000;
  app.listen(port, () => {
    console.log(`API Gateway running on port ${port}`);
  });
}
JSEOF

# Route /health:
cat > src/routes/health.js << 'JSEOF'
const express = require('express');
const router = express.Router();

router.get('/', async (req, res) => {
  try {
    res.status(200).json({
      status: 'healthy',
      version: process.env.APP_VERSION || '1.0.0',
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    res.status(503).json({ status: 'unhealthy', error: err.message });
  }
});

module.exports = router;
JSEOF

# Tests:
cat > tests/health.test.js << 'JSEOF'
const request = require('supertest');
const app = require('../src/app');

describe('GET /health', () => {
  it('should return 200 with healthy status', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('healthy');
  });

  it('should include version in response', async () => {
    const res = await request(app).get('/health');
    expect(res.body.version).toBeDefined();
  });

  it('should include timestamp in response', async () => {
    const res = await request(app).get('/health');
    expect(res.body.timestamp).toBeDefined();
    expect(new Date(res.body.timestamp)).toBeInstanceOf(Date);
  });
});
JSEOF

# package.json con jest y supertest:
cat > package.json << 'JSEOF'
{
  "name": "api-gateway",
  "version": "1.0.0",
  "scripts": {
    "start": "node src/app.js",
    "test": "jest --coverage --coverageReporters=text --coverageReporters=lcov",
    "lint": "echo 'Lint OK (eslint not installed in this practice)'"
  },
  "jest": {
    "testEnvironment": "node",
    "collectCoverageFrom": ["src/**/*.js"]
  },
  "dependencies": {
    "express": "^4.18.2"
  },
  "devDependencies": {
    "jest": "^29.7.0",
    "supertest": "^6.3.4"
  }
}
JSEOF

git add src/ tests/ package.json
git commit -m "feat: add project structure for CI/CD pipeline practice"
git push origin main
```

---

## 🔧 Fase 2: Implementar el Pipeline Completo (90 min)

### 2.1 El .gitlab-ci.yml Completo

```bash
cat > .gitlab-ci.yml << 'YAML_EOF'
# Pipeline CI/CD Completo — API Gateway
# Semana 05 — Bootcamp GitLab CE

image: node:20-alpine

stages:
  - validate
  - test
  - build
  - deploy

variables:
  NODE_ENV: test
  APP_VERSION: "1.0.0"
  CACHE_KEY: "$CI_COMMIT_REF_SLUG-node-modules"

# ─── CONFIGURACIÓN GLOBAL ─────────────────────────────────────

.node-cache: &node-cache
  cache:
    key: "$CACHE_KEY"
    paths:
      - node_modules/

# ─── STAGE: validate ──────────────────────────────────────────

install-deps:
  stage: validate
  <<: *node-cache
  cache:
    key: "$CACHE_KEY"
    paths:
      - node_modules/
    policy: pull-push
  script:
    - npm ci --quiet
    - echo "✅ $(ls node_modules | wc -l | tr -d ' ') dependencias instaladas"

lint:
  stage: validate
  <<: *node-cache
  cache:
    key: "$CACHE_KEY"
    paths:
      - node_modules/
    policy: pull
  needs:
    - install-deps
  script:
    - npm run lint
    - echo "✅ Lint completado"
  allow_failure: true

security-check:
  stage: validate
  needs:
    - install-deps
  <<: *node-cache
  cache:
    key: "$CACHE_KEY"
    paths:
      - node_modules/
    policy: pull
  script:
    - echo "=== Verificando dependencias de seguridad ==="
    - npm list --depth=0 2>/dev/null | head -10
    - echo "✅ Sin vulnerabilidades críticas detectadas (simulado)"
  allow_failure: true

# ─── STAGE: test ──────────────────────────────────────────────

unit-tests:
  stage: test
  <<: *node-cache
  cache:
    key: "$CACHE_KEY"
    paths:
      - node_modules/
    policy: pull
  needs:
    - install-deps
  script:
    - npm test
  coverage: '/All files\s*\|\s*(\d+\.?\d+)/'
  artifacts:
    when: always
    paths:
      - coverage/
    expire_in: 1 week

integration-tests:
  stage: test
  image: node:20-alpine
  services:
    - name: postgres:16-alpine
      alias: db
  variables:
    POSTGRES_DB: testdb
    POSTGRES_USER: testuser
    POSTGRES_PASSWORD: testpass
    DATABASE_URL: "postgresql://testuser:testpass@db:5432/testdb"
  needs:
    - install-deps
  <<: *node-cache
  cache:
    key: "$CACHE_KEY"
    paths:
      - node_modules/
    policy: pull
  before_script:
    - apk add --no-cache postgresql-client
    - until pg_isready -h db -p 5432 -U testuser; do sleep 2; done
    - echo "✅ PostgreSQL listo"
  script:
    - echo "=== Tests de integración con PostgreSQL ==="
    - psql "$DATABASE_URL" -c "CREATE TABLE IF NOT EXISTS health_logs (id SERIAL, checked_at TIMESTAMP DEFAULT NOW());"
    - psql "$DATABASE_URL" -c "INSERT INTO health_logs DEFAULT VALUES;"
    - COUNT=$(psql "$DATABASE_URL" -t -c "SELECT COUNT(*) FROM health_logs;" | tr -d ' ')
    - echo "Registros en health_logs: $COUNT"
    - test "$COUNT" -gt "0" && echo "✅ Test de integración DB: PASSED"

# ─── STAGE: build ─────────────────────────────────────────────

build-dist:
  stage: build
  needs:
    - unit-tests
    - integration-tests
  <<: *node-cache
  cache:
    key: "$CACHE_KEY"
    paths:
      - node_modules/
    policy: pull
  script:
    - echo "=== Generando build de producción ==="
    - mkdir -p dist/
    - cp -r src/ dist/app/
    - cp package.json dist/
    - echo "{\"version\": \"$APP_VERSION\", \"commit\": \"$CI_COMMIT_SHORT_SHA\", \"built_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > dist/build-info.json
    - echo "✅ Build generado:"
    - cat dist/build-info.json
  artifacts:
    name: "api-gateway-$CI_COMMIT_SHORT_SHA"
    paths:
      - dist/
    expire_in: 30 days
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_MERGE_REQUEST_IID

# ─── STAGE: deploy ────────────────────────────────────────────

deploy-staging:
  stage: deploy
  image: alpine:latest
  needs:
    - build-dist
  script:
    - echo "=== Desplegando a STAGING ==="
    - echo "Versión: $(cat dist/build-info.json)"
    - echo "✅ Desplegado en: http://staging.api-gateway.bootcamp.local"
  environment:
    name: staging
    url: http://staging.api-gateway.bootcamp.local
  rules:
    - if: $CI_COMMIT_BRANCH == "main"

deploy-production:
  stage: deploy
  image: alpine:latest
  needs:
    - build-dist
  script:
    - echo "=== Desplegando a PRODUCCIÓN ==="
    - echo "Versión: $(cat dist/build-info.json)"
    - echo "✅ Desplegado en: http://api-gateway.bootcamp.local"
  environment:
    name: production
    url: http://api-gateway.bootcamp.local
  when: manual
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
YAML_EOF

git add .gitlab-ci.yml
git commit -m "ci: implement complete CI/CD pipeline for api-gateway"
git push origin main
```

---

## 👀 Fase 3: Observar y Verificar (30 min)

### 3.1 Verificar el Pipeline en la UI

```
http://localhost/bootcamp-org/backend/api-gateway/-/pipelines

Verificar:
  ✅ Stage validate: install-deps, lint, security-check (paralelos)
  ✅ Stage test: unit-tests, integration-tests (paralelos, usando cache)
  ✅ Stage build: build-dist (solo en main)
  ▶️  Stage deploy: deploy-staging (auto), deploy-production (manual)
```

### 3.2 Verificar Coverage en el MR

Si tienes un MR abierto, el pipeline del MR debe mostrar:
```
CI/CD → Pipelines → Latest pipeline → Test summary
  → X tests passed
  → Coverage: YY%
```

### 3.3 Descargar el Artifact del Build

```bash
PROJECT_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects?search=api-gateway" \
  | python3 -c "
import sys,json
projects=[p for p in json.load(sys.stdin) if 'bootcamp-org' in p['path_with_namespace']]
print(projects[0]['id'])
")

# Obtener el job de build-dist del último pipeline exitoso:
PIPELINE_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines?status=success&per_page=1" \
  | python3 -c "import sys,json; ps=json.load(sys.stdin); print(ps[0]['id'] if ps else 'none')")

JOB_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines/$PIPELINE_ID/jobs" \
  | python3 -c "
import sys, json
jobs = json.load(sys.stdin)
build_job = next((j for j in jobs if j['name'] == 'build-dist'), None)
print(build_job['id'] if build_job else 'none')
")

echo "Descargando artifact del job $JOB_ID..."
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --output /tmp/api-gateway-build.zip \
  "http://localhost/api/v4/projects/$PROJECT_ID/jobs/$JOB_ID/artifacts"

echo "Artifact descargado: $(ls -lh /tmp/api-gateway-build.zip)"
```

---

## 📋 Entregables del Proyecto

- [ ] `package.json` con scripts test y lint
- [ ] `src/app.js` y `src/routes/health.js` con código funcional
- [ ] `tests/health.test.js` con al menos 3 tests
- [ ] `.gitlab-ci.yml` con 4 stages: validate, test, build, deploy
- [ ] Pipeline ejecutado exitosamente en `main`
- [ ] Artifact `dist/` descargable desde la UI
- [ ] Tests de integración con PostgreSQL pasados
- [ ] Job `deploy-production` visible como botón manual

### Evidencia visual:
- [ ] Captura del gráfico del pipeline con todos los stages
- [ ] Captura del artifact descargable en el job `build-dist`
- [ ] Captura del job de integración con los logs de PostgreSQL
- [ ] Output del script de descarga del artifact via API

---

## 🏆 Criterios de Evaluación

| Criterio | Puntos |
|----------|--------|
| Pipeline con 4 stages y jobs paralelos | 20 pts |
| Tests unitarios con cobertura reportada | 20 pts |
| Tests de integración con service PostgreSQL | 20 pts |
| Cache configurado y funcionando (segunda ejecución más rápida) | 15 pts |
| Artifact descargable con build info | 15 pts |
| Deploy manual a producción configurado | 10 pts |

**Total: 100 puntos** — Ver [rúbrica completa](../rubrica-evaluacion.md)

---

⬅️ **Prácticas:** [2-practicas/README.md](../2-practicas/README.md)

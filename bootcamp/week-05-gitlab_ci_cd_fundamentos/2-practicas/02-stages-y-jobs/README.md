# 🔬 Práctica 02 — Múltiples Stages, Jobs Paralelos y DAG

## 🎯 Objetivo

Crear un pipeline realista con 4 stages, jobs paralelos dentro de cada stage, dependencias DAG con `needs`, y control de fallos con `allow_failure`.

## ⏱️ Tiempo estimado: 40 minutos

## 📋 Requisitos previos

- Completada la Práctica 01 (Runner activo, primer pipeline en verde)
- Proyecto con el `.gitlab-ci.yml` del ejercicio anterior

---

## 📝 Paso 1: Pipeline con 4 Stages y Jobs Paralelos

```bash
cat > .gitlab-ci.yml << 'YAML_EOF'
# Pipeline con stages, paralelismo y artifacts
# Práctica 02 — Semana 05

image: alpine:latest

stages:
  - validate
  - test
  - build
  - deploy

# ─── Globales ────────────────────────────────────────
variables:
  APP_NAME: "api-gateway"
  APP_VERSION: "1.0.0"

# ─── STAGE: validate (3 jobs en paralelo) ───────────
lint-code:
  stage: validate
  script:
    - echo "[lint-code] Verificando sintaxis del código..."
    - echo "Simulando: eslint src/ --max-warnings 0"
    - echo "✅ Lint pasado — 0 errores, 0 warnings"

check-format:
  stage: validate
  script:
    - echo "[check-format] Verificando formato del código..."
    - echo "Simulando: prettier --check src/"
    - echo "✅ Formato correcto"

security-audit:
  stage: validate
  script:
    - echo "[security-audit] Escaneando dependencias..."
    - echo "Simulando: npm audit --audit-level moderate"
    - echo "✅ Sin vulnerabilidades críticas"
  allow_failure: true   # El pipeline continúa aunque esto falle

# ─── STAGE: test (2 jobs en paralelo) ────────────────
unit-tests:
  stage: test
  script:
    - echo "[unit-tests] Ejecutando tests unitarios..."
    - mkdir -p coverage
    - echo '{"coverage": 87.5}' > coverage/summary.json
    - echo "Tests: 42 passed, 0 failed"
    - echo "Coverage: 87.5%"
  artifacts:
    paths:
      - coverage/
    expire_in: 1 day

integration-tests:
  stage: test
  script:
    - echo "[integration-tests] Ejecutando tests de integración..."
    - echo "Conectando a DB: postgresql://localhost/testdb..."
    - echo "Simulando 15 tests de integración..."
    - echo "✅ 15/15 tests passed"

# ─── STAGE: build ────────────────────────────────────
build-app:
  stage: build
  needs:
    - unit-tests
    - integration-tests
  script:
    - echo "[build-app] Compilando aplicación..."
    - mkdir -p dist
    - echo "Version: $APP_VERSION" > dist/version.txt
    - echo "Build date: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> dist/version.txt
    - echo "Commit: $CI_COMMIT_SHORT_SHA" >> dist/version.txt
    - echo "✅ Build completado"
    - cat dist/version.txt
  artifacts:
    paths:
      - dist/
    expire_in: 1 day

# ─── STAGE: deploy ────────────────────────────────────
deploy-staging:
  stage: deploy
  needs:
    - build-app
  script:
    - echo "[deploy-staging] Desplegando a staging..."
    - echo "Versión a desplegar: $(cat dist/version.txt)"
    - echo "✅ Desplegado en http://staging.api-gateway.local"
  environment:
    name: staging
  rules:
    - if: $CI_COMMIT_BRANCH == "main"

deploy-production:
  stage: deploy
  needs:
    - build-app
  script:
    - echo "[deploy-production] Desplegando a PRODUCCIÓN..."
    - echo "⚠️  Este job requiere aprobación manual"
    - cat dist/version.txt
  environment:
    name: production
  when: manual           # Requiere click manual en la UI
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
YAML_EOF

git add .gitlab-ci.yml
git commit -m "ci: add multi-stage pipeline with parallel jobs and DAG"
git push origin main
```

---

## 📝 Paso 2: Observar el Pipeline en la UI

```
http://localhost/bootcamp-org/backend/api-gateway/-/pipelines

Click en el pipeline → visualizar el gráfico:

Stage validate (3 en paralelo):
  lint-code   check-format   security-audit
       ↓             ↓              ↓
Stage test (2 en paralelo):
       unit-tests      integration-tests
            ↓                  ↓
Stage build (1):
           build-app
                ↓
Stage deploy (2, pero production es manual):
   deploy-staging    [deploy-production] (manual)
```

Verificar:
- `lint-code`, `check-format`, `security-audit` corren simultáneamente
- `unit-tests` e `integration-tests` corren simultáneamente
- `build-app` espera a que ambos tests terminen
- `deploy-staging` corre automáticamente, `deploy-production` espera click

---

## 📝 Paso 3: Probar el Fallo con `allow_failure`

```bash
# Modificar security-audit para que falle:
cat > .gitlab-ci.yml << 'YAML_EOF'
image: alpine:latest

stages:
  - validate
  - test
  - build

variables:
  APP_NAME: "api-gateway"
  APP_VERSION: "1.0.0"

lint-code:
  stage: validate
  script:
    - echo "[lint-code] ✅ Lint pasado"

security-audit:
  stage: validate
  script:
    - echo "[security-audit] Buscando vulnerabilidades..."
    - echo "CRITICAL: SQL injection en auth.js línea 34"
    - exit 1    # Simulamos que el scan encontró algo crítico
  allow_failure: true   # El pipeline continúa a pesar de este fallo

unit-tests:
  stage: test
  script:
    - echo "[unit-tests] ✅ 42/42 tests passed"

build-app:
  stage: build
  script:
    - echo "[build-app] ✅ Build completado"
    - mkdir -p dist && echo "$APP_VERSION" > dist/version.txt
  artifacts:
    paths: [dist/]
YAML_EOF

git add .gitlab-ci.yml
git commit -m "ci: test allow_failure with failing security scan"
git push origin main
```

Observar en la UI:
- `security-audit` aparece con estado ⚠️ (warning) — fallo permitido
- El pipeline continúa a la stage `test` y `build`
- El pipeline final aparece como "Passed (with warnings)"

---

## 📝 Paso 4: DAG con `needs` — Arranque Anticipado

```bash
cat > .gitlab-ci.yml << 'YAML_EOF'
image: alpine:latest

stages:
  - build
  - test
  - package

build-backend:
  stage: build
  script:
    - echo "Compilando backend..."
    - sleep 3   # Simula tiempo de compilación
    - mkdir -p target
    - echo "backend-binary" > target/app.jar
  artifacts:
    paths: [target/]

build-frontend:
  stage: build
  script:
    - echo "Compilando frontend..."
    - sleep 2   # Simula tiempo de compilación
    - mkdir -p dist
    - echo "frontend-bundle" > dist/bundle.js
  artifacts:
    paths: [dist/]

# test-backend empieza TAN PRONTO como build-backend termine
# No espera a que build-frontend también termine
test-backend:
  stage: test
  needs: ["build-backend"]
  script:
    - echo "Verificando artifact del backend: $(cat target/app.jar)"
    - echo "Tests del backend: ✅ 30/30 passed"

# test-frontend empieza TAN PRONTO como build-frontend termine
test-frontend:
  stage: test
  needs: ["build-frontend"]
  script:
    - echo "Verificando artifact del frontend: $(cat dist/bundle.js)"
    - echo "Tests del frontend: ✅ 45/45 passed"

# Este job espera a que AMBOS tests terminen
package-final:
  stage: package
  needs:
    - job: test-backend
      artifacts: true
    - job: test-frontend
      artifacts: true
  script:
    - echo "Empaquetando todo junto:"
    - echo "  Backend: $(cat target/app.jar)"
    - echo "  Frontend: $(cat dist/bundle.js)"
    - echo "✅ Package completo"
YAML_EOF

git add .gitlab-ci.yml
git commit -m "ci: demonstrate DAG with needs for early job start"
git push origin main
```

Observar en la UI la diferencia visual entre el grafo de este pipeline vs el pipeline lineal del paso anterior.

---

## 📝 Paso 5: Verificar via API

```bash
PROJECT_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects?search=api-gateway" \
  | python3 -c "
import sys,json
projects=[p for p in json.load(sys.stdin) if 'bootcamp-org' in p['path_with_namespace']]
print(projects[0]['id'])
")

PIPELINE_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines?per_page=1" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

# ¿QUÉ HACE?: Lista todos los jobs del último pipeline con sus estados
# ¿POR QUÉ?: Verificar que la paralelización y el DAG funcionaron como esperado
# ¿PARA QUÉ?: Depuración y validación programática del pipeline
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines/$PIPELINE_ID/jobs?per_page=20" \
  | python3 -c "
import sys, json
jobs = json.load(sys.stdin)
print(f'Pipeline #{$PIPELINE_ID} — {len(jobs)} jobs:')
print()
by_stage = {}
for j in jobs:
    stage = j['stage']
    if stage not in by_stage:
        by_stage[stage] = []
    by_stage[stage].append(j)

for stage, stage_jobs in by_stage.items():
    print(f'Stage: {stage}')
    for j in stage_jobs:
        icon = '✅' if j['status'] == 'success' else ('❌' if j['status'] == 'failed' else ('⚠️' if j['allow_failure'] else '🔄'))
        duration = j.get('duration', 0) or 0
        print(f'  {icon} {j[\"name\"]:30} {j[\"status\"]:10} {duration:.1f}s')
    print()
"
```

---

## 🔧 Troubleshooting

**Jobs en la misma stage no corren en paralelo**
```
→ Necesitas múltiples runners para paralelismo real
→ Con un solo runner, corren en secuencia (pero la UI los muestra como paralelos)
→ Verificar número de runners: /api/v4/runners?status=online
```

**`needs` da error "needs refers to unknown job"**
```
→ El nombre del job en `needs` debe coincidir exactamente (case sensitive)
→ Verificar que el job referenciado existe en el mismo pipeline
```

---

## ✅ Checklist de verificación

- [ ] Pipeline con 4 stages y jobs paralelos en estado Passed
- [ ] `security-audit` falla pero el pipeline continúa (allow_failure)
- [ ] DAG con `needs` — `test-backend` empieza antes de que `build-frontend` termine
- [ ] API lista todos los jobs con sus stages y duraciones
- [ ] Job `deploy-production` aparece con botón "Play" manual en la UI

## 📦 Entregables

- [ ] Captura del gráfico del pipeline mostrando stages y paralelismo
- [ ] Captura del pipeline con `security-audit` en warning y el resto en passed
- [ ] Captura del pipeline DAG mostrando los jobs iniciando de forma no lineal
- [ ] Output del API con la lista de jobs, stages y duraciones

---

⬅️ **Anterior:** [01 — Primer Pipeline](../01-primer-pipeline/README.md)
➡️ **Siguiente:** [03 — Imágenes Docker Personalizadas](../03-imagenes-personalizadas/README.md)

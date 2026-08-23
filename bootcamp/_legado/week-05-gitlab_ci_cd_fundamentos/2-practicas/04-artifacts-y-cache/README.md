# 🔬 Práctica 04 — Artifacts y Cache en el Pipeline

## 🎯 Objetivo

Configurar artifacts para pasar archivos entre stages, usar `artifacts:reports` para mostrar resultados de tests en la UI del MR, y configurar cache con políticas para acelerar el pipeline sin desperdiciar tiempo actualizando el cache innecesariamente.

## ⏱️ Tiempo estimado: 45 minutos

## 📋 Requisitos previos

- Completada la Práctica 03
- Runner con executor Docker activo

---

## 📝 Paso 1: Artifacts para Pasar Archivos entre Stages

```bash
cat > .gitlab-ci.yml << 'YAML_EOF'
# Pipeline con artifacts entre stages
# Práctica 04 — Semana 05

image: alpine:latest

stages:
  - build
  - test
  - package

# Stage build: genera el artifact
compilar:
  stage: build
  script:
    - echo "=== Compilando aplicación ==="
    - mkdir -p build/
    - echo "// Código compilado de api-gateway v1.0.0" > build/app.js
    - echo "export default {version: '1.0.0', env: 'ci'}" >> build/app.js
    - mkdir -p build/assets/
    - echo "body { margin: 0; }" > build/assets/main.css
    - ls -la build/
    - echo "✅ Compilación completada"
  artifacts:
    name: "build-$CI_COMMIT_SHORT_SHA"    # Nombre descriptivo del artifact
    paths:
      - build/
    exclude:
      - build/**/*.map                    # Excluir source maps (son grandes)
    expire_in: 1 hour                     # Corto — solo necesitamos entre stages

# Stage test: usa el artifact del build
test-build:
  stage: test
  needs:
    - compilar                            # Descarga el artifact de "compilar"
  script:
    - echo "=== Verificando build ==="
    - test -d build/ || (echo "❌ Artifact 'build/' no encontrado" && exit 1)
    - test -f build/app.js || (echo "❌ app.js no existe" && exit 1)
    - test -d build/assets/ || (echo "❌ Directorio assets/ no existe" && exit 1)
    - echo "Contenido del artifact:"
    - cat build/app.js
    - echo "✅ Todos los archivos del build están presentes"
  artifacts:
    paths:
      - build/
    expire_in: 1 day
    when: on_success

# Stage package: combina y genera el artifact final
empaquetar:
  stage: package
  needs:
    - test-build
  script:
    - echo "=== Empaquetando para deploy ==="
    - mkdir -p release/
    - cp -r build/ release/app/
    - echo "DEPLOYED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)" > release/deploy.env
    - echo "VERSION=1.0.0" >> release/deploy.env
    - echo "COMMIT=$CI_COMMIT_SHORT_SHA" >> release/deploy.env
    - echo "Contenido del release:"
    - find release/ -type f
    - echo "✅ Release listo para deploy"
  artifacts:
    name: "release-$CI_COMMIT_SHORT_SHA"
    paths:
      - release/
    expire_in: 30 days    # El release se guarda 30 días
YAML_EOF

git add .gitlab-ci.yml
git commit -m "ci: add artifacts passing between stages"
git push origin main
```

Verificar en la UI:
```
Job "compilar" → tab "Job artifacts" → debe mostrar los archivos del build
Job "empaquetar" → descarga disponible desde la UI
```

---

## 📝 Paso 2: Artifacts:reports — Tests Visibles en el MR

```bash
cat > .gitlab-ci.yml << 'YAML_EOF'
image: python:3.12-slim

stages:
  - test

test-con-reporte-junit:
  stage: test
  script:
    - echo "=== Generando reporte JUnit ==="
    # Simular reporte JUnit (normalmente lo genera pytest, jest, etc.):
    - python3 << 'PYEOF'
import xml.etree.ElementTree as ET
from datetime import datetime

# Crear estructura JUnit XML
root = ET.Element("testsuites")
root.set("name", "API Gateway Tests")
root.set("tests", "5")
root.set("failures", "1")
root.set("time", "2.35")

suite = ET.SubElement(root, "testsuite")
suite.set("name", "unit.tests")
suite.set("tests", "5")
suite.set("failures", "1")
suite.set("time", "2.35")
suite.set("timestamp", datetime.utcnow().isoformat())

# Tests
tests = [
    ("test_health_endpoint_returns_200", True, 0.12),
    ("test_health_endpoint_includes_version", True, 0.08),
    ("test_auth_rejects_invalid_token", True, 0.15),
    ("test_auth_accepts_valid_token", True, 0.18),
    ("test_rate_limiter_blocks_after_100_requests", False, 1.82),
]

for name, passed, time in tests:
    tc = ET.SubElement(suite, "testcase")
    tc.set("name", name)
    tc.set("time", str(time))
    tc.set("classname", "test_suite")

    if not passed:
        failure = ET.SubElement(tc, "failure")
        failure.set("message", "AssertionError: 429 != 200")
        failure.text = (
            f"FAILED {name}:\n"
            "AssertionError: Rate limiter returned 200 after 100 requests,\n"
            "expected 429 Too Many Requests.\n"
            "Check RateLimiter.limit() in src/middleware/rate-limit.js"
        )

tree = ET.ElementTree(root)
tree.write("junit-report.xml", encoding="unicode", xml_declaration=True)
print("✅ junit-report.xml generado")
PYEOF

    - echo "=== Contenido del reporte ==="
    - cat junit-report.xml | python3 -c "
import sys, xml.etree.ElementTree as ET
tree = ET.parse(sys.stdin)
suite = tree.find('testsuite')
tests = list(suite)
passed = sum(1 for t in tests if not t.findall('failure'))
failed = sum(1 for t in tests if t.findall('failure'))
print(f'Tests: {len(tests)} total, {passed} passed, {failed} failed')
for t in tests:
    icon = '✅' if not t.findall('failure') else '❌'
    print(f'  {icon} {t.get(\"name\")} ({t.get(\"time\")}s)')
"

  artifacts:
    when: always                  # Guardar incluso si los tests fallan
    paths:
      - junit-report.xml          # El archivo para descargar
    reports:
      junit: junit-report.xml     # ← Interpreta el XML para la UI del MR
    expire_in: 1 week

  # El job falla porque hay 1 test fallido:
  allow_failure: true             # Pero el pipeline continúa para ver el reporte
YAML_EOF

git add .gitlab-ci.yml
git commit -m "ci: add JUnit report artifact for MR test summary"
git push origin main
```

Verificar en el MR (si hay un MR abierto):
```
Pestaña "Pipelines" del MR → debe mostrar "Test summary: 4 passed, 1 failed"
Click en "1 failed" → ver el nombre del test fallido y el mensaje de error
```

---

## 📝 Paso 3: Cache para Accelerar el Pipeline

```bash
cat > .gitlab-ci.yml << 'YAML_EOF'
image: python:3.12-slim

stages:
  - install
  - test
  - lint

variables:
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.pip-cache"   # Directorio de cache de pip

# Cache global (aplica a todos los jobs):
cache:
  key:
    files:
      - requirements.txt          # Cache se invalida si requirements.txt cambia
    prefix: "pip"                 # Prefijo para el nombre de la clave
  paths:
    - .pip-cache/                 # Guardar el cache de pip

# ─── Instalar dependencias (actualiza el cache) ──────
install-deps:
  stage: install
  cache:
    key:
      files:
        - requirements.txt
      prefix: "pip"
    paths:
      - .pip-cache/
    policy: pull-push             # Descarga Y actualiza el cache
  script:
    - echo "=== Instalando dependencias ==="
    - pip install --cache-dir=$PIP_CACHE_DIR flask pytest 2>/dev/null
    - pip list | head -10
    - echo "✅ Dependencias instaladas"

# ─── Tests (solo usa el cache, no lo actualiza) ──────
run-tests:
  stage: test
  cache:
    key:
      files:
        - requirements.txt
      prefix: "pip"
    paths:
      - .pip-cache/
    policy: pull                  # Solo descarga el cache (más rápido)
  script:
    - echo "=== Ejecutando tests con Flask disponible ==="
    - python3 -c "import flask; print(f'Flask {flask.__version__} disponible via cache')"
    - python3 -c "import pytest; print(f'Pytest {pytest.__version__} disponible via cache')"
    - echo "✅ Tests completados usando dependencias del cache"

# ─── Lint (también usa el cache) ─────────────────────
run-lint:
  stage: lint
  cache:
    key:
      files:
        - requirements.txt
      prefix: "pip"
    paths:
      - .pip-cache/
    policy: pull
  script:
    - echo "=== Linting con dependencias del cache ==="
    - python3 -c "import flask; print('Flask accesible para lint')"
    - echo "✅ Lint completado"
YAML_EOF

# Crear un requirements.txt para que la clave de cache sea significativa
cat > requirements.txt << 'EOF'
flask==3.0.0
pytest==7.4.4
EOF

git add .gitlab-ci.yml requirements.txt
git commit -m "ci: add pip cache to speed up pipeline"
git push origin main
```

En la segunda ejecución (mismo requirements.txt), los jobs `run-tests` y `run-lint` deberían ser significativamente más rápidos gracias al cache.

---

## 📝 Paso 4: Verificar Cache Hits via Logs

Observar en los logs del job si el cache fue usado:

```
En los logs del runner, buscar:
  "Checking cache for pip-..."     ← Buscando el cache
  "Downloading cache..."           ← Cache HIT — se descargó el cache
  ↑ vs
  "Cache not found..."             ← Cache MISS — no había cache previo
  "Uploading cache..."             ← El job actualizó el cache (policy: pull-push)
```

---

## 📝 Paso 5: Invalidar el Cache

```bash
# Cambiar requirements.txt invalida el cache (la key cambia):
cat >> requirements.txt << 'EOF'
httpx==0.26.0
EOF

git add requirements.txt
git commit -m "chore: add httpx dependency (invalidates cache)"
git push origin main
```

El primer pipeline con el nuevo `requirements.txt` descargará e instalará `httpx`. Los pipelines siguientes (con el mismo `requirements.txt`) usarán el nuevo cache que incluye `httpx`.

---

## 🔧 Troubleshooting

**"Cannot extract cache" o cache no funciona**
```
→ Verificar que el runner tiene espacio en disco
→ El cache es "best effort" — si no está disponible, el job instala desde cero
→ El job NO debe fallar por falta de cache — debe funcionar sin él también
```

**Artifact "dist/" no está disponible en el siguiente stage**
```
→ Verificar que el job anterior usa `artifacts: paths: - dist/`
→ El job siguiente debe tener `needs: - <nombre-del-job>` para descargar el artifact
→ Verificar que `expire_in` no venció entre stages
```

---

## ✅ Checklist de verificación

- [ ] Artifact `build/` del stage `compilar` disponible para descarga en la UI
- [ ] Stage `test-build` accede al artifact de `compilar` sin error
- [ ] Reporte JUnit generado y visible en el tab "Test summary" del pipeline o MR
- [ ] Segunda ejecución del pipeline con cache muestra "Downloading cache..." en logs
- [ ] Cambio en requirements.txt dispara "Cache not found" en el siguiente run

## 📦 Entregables

- [ ] Captura del pipeline mostrando el artifact descargable en el job "compilar"
- [ ] Captura del test summary (JUnit report) en la UI del pipeline
- [ ] Captura de los logs comparando primer run (cache miss) vs segundo run (cache hit)
- [ ] Output mostrando que el artifact del build es accesible en el stage de test

---

⬅️ **Anterior:** [03 — Imágenes Docker](../03-imagenes-personalizadas/README.md)
➡️ **Proyecto:** [3-proyecto/README.md](../../3-proyecto/README.md)

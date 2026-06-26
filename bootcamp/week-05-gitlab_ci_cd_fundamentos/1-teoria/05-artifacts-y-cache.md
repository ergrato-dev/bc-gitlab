# 📖 05 — Artifacts y Cache en GitLab CI

## 🎯 Objetivos de aprendizaje

- ✅ Entender la diferencia fundamental entre artifacts y cache
- ✅ Usar artifacts para pasar archivos entre jobs y stages
- ✅ Configurar cache para acelerar el pipeline reutilizando dependencias
- ✅ Usar `artifacts:reports` para integrar resultados de tests y coverage en la UI de GitLab
- ✅ Definir estrategias de cache por rama para equipos con muchos developers

---

## 🤔 La Diferencia Fundamental

Cuando un job termina, por defecto **todos sus archivos desaparecen**. El siguiente job empieza desde cero con solo lo que trae la imagen Docker. Artifacts y Cache son los dos mecanismos para persistir datos entre jobs, pero con propósitos distintos:

**Analogía:**
- **Artifact** es como el producto terminado de un operario en la línea de montaje — lo que produjo se pasa al siguiente operario de forma garantizada. Si el producto no llega, la línea para.
- **Cache** es como el taller bien ordenado — las herramientas comunes (martillos, llaves) ya están ahí cuando el operario llega. Si alguien se olvidó de organizarlo, el operario puede traer sus propias herramientas, tarda un poco más, pero el trabajo no falla.

| Característica | Artifacts | Cache |
|---------------|-----------|-------|
| **Propósito** | Pasar resultados entre jobs | Acelerar builds |
| **Almacenamiento** | Por pipeline (cada run tiene los suyos) | Compartido entre múltiples pipelines |
| **Garantía** | Garantizado — si el artifact no existe, el job falla | "Best effort" — puede no estar disponible |
| **Acceso** | Descargable desde la UI y API | Solo dentro del pipeline |
| **Cuándo usar** | Archivos generados que NECESITAN llegar al siguiente job | Dependencias que son lentas de instalar |
| **Expiración** | Configurable (expire_in) | No garantizada — GitLab puede limpiarla |

---

## 📦 Artifacts: Pasar Archivos entre Jobs

### Ejemplo básico

```yaml
build-app:
  stage: build
  script:
    - npm run build                # Genera /dist
  artifacts:
    paths:
      - dist/                      # Guardar la carpeta dist
    expire_in: 1 day               # Se elimina después de 1 día

deploy-staging:
  stage: deploy
  needs:
    - build-app                    # Descarga automáticamente los artifacts de build-app
  script:
    - ls dist/                     # dist/ está disponible aquí
    - rsync -av dist/ deploy@server:/var/www/
```

### Configuración completa de artifacts

```yaml
unit-tests:
  stage: test
  script:
    - npm test -- --coverage --testResultsProcessor=jest-junit
  artifacts:
    # ¿QUÉ HACE?: Define qué archivos guardar como artifact
    paths:
      - coverage/                  # Directorio de reporte de cobertura
      - junit-report.xml           # Reporte JUnit (para la UI de GitLab)
    # ¿QUÉ HACE?: Excluir archivos específicos dentro de los paths
    exclude:
      - coverage/**/*.js           # Los JS del coverage no son necesarios
    # ¿QUÉ HACE?: Artifacts especiales que GitLab interpreta y muestra en la UI
    reports:
      junit: junit-report.xml      # ← Test results aparecen en la UI del MR
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml  # ← Coverage aparece en el diff del MR
    # ¿POR QUÉ?: Guardar artifacts incluso si el job falla (para depurar)
    when: always                   # on_success (default), on_failure, always
    expire_in: 1 week              # 1 hour, 1 day, 1 week, 30 days, 1 year, never
```

### `artifacts:reports` — Integración con la UI de GitLab

```yaml
test-con-reportes:
  stage: test
  image: node:20-alpine
  script:
    - npm ci
    - npm test -- --coverage

  artifacts:
    reports:
      # Tests: aparece en MR como "Test summary" con passed/failed/skipped
      junit: junit.xml

      # Coverage: aparece en el diff del MR con porcentaje por archivo
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml

      # SAST: aparece en Security dashboard (CE básico disponible)
      sast: gl-sast-report.json

      # Dependency scanning:
      dependency_scanning: gl-dependency-scanning-report.json
```

Cuando configuras `reports:junit`, el MR en GitLab muestra:
```
✅ Tests passed: 42/42
   ❌ test: should reject invalid JWT → AssertionError: expected 401...
   ❌ test: should timeout on slow DB → Error: connect ETIMEDOUT
```

---

## ⚡ Cache: Acelerar el Pipeline

### Ejemplo básico

```yaml
install-deps:
  stage: .pre
  image: node:20-alpine
  cache:
    # ¿QUÉ HACE?: Define una clave única para este cache
    # ¿POR QUÉ?: Diferentes ramas o versiones de package.json necesitan caches distintos
    key:
      files:
        - package-lock.json       # Cache se invalida si package-lock.json cambia
    paths:
      - node_modules/             # Qué guardar en el cache
  script:
    - npm ci --quiet

test-unit:
  stage: test
  cache:
    key:
      files:
        - package-lock.json       # Misma clave → reutiliza el cache
    paths:
      - node_modules/
    policy: pull                  # Solo descargar, no actualizar el cache
  script:
    - npm test
```

### Políticas de Cache

```yaml
cache:
  policy: pull-push   # (default) Descarga el cache al inicio, lo actualiza al final
  policy: pull        # Solo descarga el cache (más rápido, no lo actualiza)
  policy: push        # Solo actualiza el cache (sin descargar)
```

### Cache por Rama

```yaml
variables:
  # Clave de cache que incluye el nombre de la rama:
  CACHE_KEY: "$CI_COMMIT_REF_SLUG"   # ej: "main", "feature-42-jwt-auth"

cache:
  key: "$CACHE_KEY-node-modules"
  paths:
    - node_modules/

# Resultado:
# main branch:                 cache key "main-node-modules"
# feature-42-jwt-auth branch:  cache key "feature-42-jwt-auth-node-modules"
```

---

## 📊 Workflow Completo con Artifacts y Cache

```yaml
stages:
  - install
  - validate
  - test
  - build
  - report

variables:
  CACHE_KEY: "$CI_COMMIT_REF_SLUG"

# ─── Stage .pre: solo instalar dependencias ───────────
install:
  stage: install
  image: node:20-alpine
  cache:
    key: "$CACHE_KEY-node-modules"
    paths:
      - node_modules/
    policy: pull-push    # Instalar y guardar en cache
  script:
    - npm ci --quiet
    - echo "Dependencias instaladas: $(ls node_modules | wc -l) paquetes"

# ─── Validate: lint y formato ─────────────────────────
lint:
  stage: validate
  image: node:20-alpine
  cache:
    key: "$CACHE_KEY-node-modules"
    paths:
      - node_modules/
    policy: pull         # Solo descargar el cache de "install"
  script:
    - npm run lint
    - npm run format:check

# ─── Test: con reporte JUnit y cobertura ──────────────
unit-tests:
  stage: test
  image: node:20-alpine
  cache:
    key: "$CACHE_KEY-node-modules"
    paths:
      - node_modules/
    policy: pull
  script:
    - npm test -- --coverage --reporters=jest-junit
  coverage: '/All files\s*\|\s*(\d+\.?\d+)/'   # Regex para extraer % global
  artifacts:
    when: always
    paths:
      - coverage/
      - junit-report.xml
    reports:
      junit: junit-report.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
    expire_in: 1 week

# ─── Build: empaquetar la aplicación ──────────────────
build-dist:
  stage: build
  image: node:20-alpine
  cache:
    key: "$CACHE_KEY-node-modules"
    paths:
      - node_modules/
    policy: pull
  needs:
    - unit-tests         # Solo si los tests pasan
  script:
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 day

# ─── Report: publicar reporte de coverage ─────────────
pages:                   # Job especial para GitLab Pages (nombre literal "pages")
  stage: report
  needs:
    - unit-tests
  script:
    - mv coverage/lcov-report public    # public/ es el directorio para Pages
  artifacts:
    paths:
      - public
    expire_in: 30 days
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

---

## 🔍 Verificar Artifacts via API

```bash
# ¿QUÉ HACE?: Lista los artifacts del último pipeline del proyecto
# ¿POR QUÉ?: Confirmar que los artifacts se crearon correctamente
# ¿PARA QUÉ?: Automatización — descargar artifacts desde scripts externos
PROJECT_ID=42

PIPELINE_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines?status=success&per_page=1" \
  | python3 -c "import sys,json; ps=json.load(sys.stdin); print(ps[0]['id'] if ps else 'none')")

echo "Último pipeline exitoso: #$PIPELINE_ID"

# Listar jobs y sus artifacts:
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines/$PIPELINE_ID/jobs" \
  | python3 -c "
import sys, json
jobs = json.load(sys.stdin)
for j in jobs:
    has_artifacts = bool(j.get('artifacts_file'))
    artifact_flag = '📦' if has_artifacts else '  '
    print(f'  {artifact_flag} {j[\"status\"]:10} {j[\"name\"]}')
    if has_artifacts:
        print(f'     → Artifact: {j[\"artifacts_file\"][\"filename\"]} ({j[\"artifacts_file\"][\"size\"]} bytes)')
"

# Descargar artifact de un job específico:
JOB_ID=<id_del_job>
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --output artifacts.zip \
  "http://localhost/api/v4/projects/$PROJECT_ID/jobs/$JOB_ID/artifacts"
```

---

## 🖼️ Diagrama: Artifacts y Cache en el Pipeline

![Diagrama de artifacts y cache entre jobs](../0-assets/05-artifacts-cache.svg)

> **Diagrama:** Muestra visualmente la diferencia entre artifacts (flujo garantizado entre jobs del mismo pipeline) y cache (almacén compartido entre múltiples ejecuciones del pipeline). También ilustra cómo `artifacts:reports` se integra con la UI del MR.

---

## 🤔 Preguntas de reflexión

1. El job `build-dist` necesita `node_modules/` (que viene del cache) y el código compilado `dist/` del job anterior. ¿Cuál viene de artifacts y cuál de cache? ¿Por qué la distinción importa?

2. El cache tiene `policy: pull` en los jobs de test. ¿Qué ocurre si alguien instala un paquete nuevo y hace push? ¿El cache ya tiene el nuevo paquete o no? ¿Cuándo se actualiza?

3. `artifacts:expire_in: 1 day` hace que los artifacts se eliminen después de 24h. El equipo quiere hacer rollback a la versión de la semana pasada. ¿Qué cambiarías en la configuración para permitir esto?

4. `artifacts:reports:junit` muestra los resultados de tests directamente en el MR. ¿Qué información concreta puede ver el reviewer en el MR que antes no podía ver sin revisar los logs del pipeline?

5. El cache de `node_modules/` tiene `key: "$CI_COMMIT_REF_SLUG"`. Si hay 50 ramas activas simultáneamente, cada una con su propio cache de 200MB, ¿cuánto espacio de almacenamiento está usando el cache? ¿Qué estrategia usarías para reducirlo?

---

## 📚 Recursos adicionales

- [Job artifacts](https://docs.gitlab.com/ee/ci/yaml/artifacts.html)
- [Caching — documentation](https://docs.gitlab.com/ee/ci/caching/)
- [Cache key variables](https://docs.gitlab.com/ee/ci/caching/#use-a-fallback-cache-key)
- [JUnit test reports](https://docs.gitlab.com/ee/ci/testing/unit_test_reports.html)
- [Test coverage visualization](https://docs.gitlab.com/ee/ci/testing/test_coverage_visualization.html)

---

⬅️ **Lección anterior:** [04 — Imágenes Docker en CI](./04-imagenes-docker.md)

---
*Fin del bloque de teoría — Semana 05. Continúa con las [Prácticas →](../2-practicas/README.md)*

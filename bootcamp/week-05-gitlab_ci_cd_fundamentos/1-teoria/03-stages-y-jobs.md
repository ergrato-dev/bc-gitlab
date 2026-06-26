# 📖 03 — Stages y Jobs: El Esqueleto del Pipeline

## 🎯 Objetivos de aprendizaje

- ✅ Entender la diferencia entre stages y jobs, y cómo se relacionan
- ✅ Diseñar pipelines con stages lógicos (validate, test, build, deploy)
- ✅ Usar `needs` para crear dependencias directas entre jobs (DAG)
- ✅ Controlar el comportamiento ante fallos con `allow_failure` y `when`
- ✅ Usar `extends` y anchors YAML para evitar duplicación en el pipeline

---

## 🤔 Stages vs Jobs

**Analogía:** El pipeline es como la construcción de un edificio. Las **stages** son las fases de la obra: cimientos, estructura, acabados, inspección. Los **jobs** son los trabajadores dentro de cada fase: en "acabados" pueden estar al mismo tiempo el pintor, el electricista y el plomero trabajando en paralelo. La siguiente fase no empieza hasta que todos en la actual terminaron.

```
STAGES (secuenciales):  validate  →  test  →  build  →  deploy
                            ↓           ↓         ↓          ↓
JOBS (paralelos         lint        unit     build-app    staging
dentro de la           sec-scan    integ    docker-img   production
misma stage):          sast        e2e
```

---

## 📐 Stages: El Orden del Pipeline

```yaml
stages:
  - validate     # Verificaciones rápidas primero (lint, seguridad)
  - test         # Tests (unitarios, integración, E2E)
  - build        # Compilar, empaquetar, construir imagen
  - deploy       # Desplegar a staging o producción

# Jobs sin `stage` explícito van a la stage "test" por defecto
```

### Comportamiento ante fallos

```
Stage validate: lint ✅  security-scan ❌
                              ↓
Stage test:  [BLOQUEADA — no se ejecuta]
Stage build: [BLOQUEADA — no se ejecuta]
Stage deploy:[BLOQUEADA — no se ejecuta]
```

Si un job falla → toda la stage falla → stages siguientes no se ejecutan.

Excepción: `allow_failure: true` permite que el job falle sin bloquear.

---

## 🔧 Jobs: Las Unidades de Trabajo

```yaml
# Estructura mínima de un job:
nombre-del-job:
  stage: test          # ¿En qué stage corre? (obligatorio si hay stages)
  image: node:20       # ¿Qué imagen Docker usar?
  script:              # ¿Qué ejecutar? (OBLIGATORIO)
    - npm test

# Estructura completa:
unit-tests:
  stage: test
  image: node:20-alpine
  variables:
    NODE_ENV: test
    JEST_TIMEOUT: "10000"
  before_script:
    - npm ci --quiet
  script:
    - npm test -- --coverage --passWithNoTests
  after_script:
    - echo "Tests completados. Coverage en artifacts."
  coverage: '/All files\s*\|\s*(\d+\.?\d+)/'  # Regex para extraer % de cobertura
  artifacts:
    paths:
      - coverage/
    expire_in: 1 week
    when: always  # Guardar artifact incluso si el job falla
  rules:
    - if: $CI_MERGE_REQUEST_IID
    - if: $CI_COMMIT_BRANCH == "main"
  allow_failure: false     # El pipeline falla si este job falla (default)
  timeout: 10 minutes      # Máximo tiempo para este job
  retry:
    max: 2                 # Reintentar hasta 2 veces si falla
    when:
      - runner_system_failure
      - stuck_or_timeout_failure
  tags:
    - docker               # Usar solo runners con el tag "docker"
```

---

## ⚡ Paralelismo dentro de una Stage

Los jobs de la misma stage corren en paralelo (si hay runners disponibles):

```yaml
stages:
  - test

# Estos 3 jobs corren en PARALELO (si hay 3 runners):
test-unit:
  stage: test
  script: npm test

test-lint:
  stage: test
  script: npm run lint

test-security:
  stage: test
  script: npm audit --audit-level moderate
```

**Tiempo total de la stage `test`:**
- Sin paralelización (secuencial): 5min + 2min + 3min = **10 minutos**
- Con paralelización (paralelo): `max(5min, 2min, 3min)` = **5 minutos**

---

## 🕸️ DAG con `needs`: Dependencias Directas

Por defecto, el pipeline es lineal: `stage1 → stage2 → stage3`. Con `needs`, puedes crear un **grafo de dependencias** (DAG: Directed Acyclic Graph):

```yaml
stages:
  - build
  - test
  - deploy

build-backend:
  stage: build
  script: mvn package -q
  artifacts:
    paths: [target/app.jar]

build-frontend:
  stage: build
  script: npm run build
  artifacts:
    paths: [dist/]

test-backend:
  stage: test
  needs: ["build-backend"]    # Solo espera a build-backend, no a build-frontend
  script: mvn test

test-frontend:
  stage: test
  needs: ["build-frontend"]   # Solo espera a build-frontend, no a build-backend
  script: npm test

deploy-app:
  stage: deploy
  needs:                      # Espera a que AMBOS tests terminen
    - test-backend
    - test-frontend
  script: ./deploy.sh
```

**Visualización del DAG:**

```
build-backend ──→ test-backend ──┐
                                  ├──→ deploy-app
build-frontend ─→ test-frontend ─┘
```

Sin `needs`, el tiempo total sería: `max(build) + max(test) + deploy`.
Con `needs`: `max(build-backend + test-backend, build-frontend + test-frontend) + deploy`.

---

## 🔄 Matrices de Jobs con `parallel:matrix`

Para ejecutar el mismo job con diferentes configuraciones:

```yaml
tests-multiple-node:
  stage: test
  parallel:
    matrix:
      - NODE_VERSION: ["18", "20", "22"]
        OS: ["ubuntu", "alpine"]
  image: node:${NODE_VERSION}-${OS}
  script:
    - node --version
    - npm test
```

Esto crea automáticamente 6 jobs: `tests-multiple-node [18, ubuntu]`, `tests-multiple-node [18, alpine]`, etc.

---

## 🧩 Reutilización con `extends` y Anchors YAML

Para evitar duplicar configuración entre jobs similares:

### `extends` (nativo de GitLab CI)

```yaml
# Template base (empieza con punto → job oculto, no se ejecuta)
.test-template:
  stage: test
  image: node:20-alpine
  before_script:
    - npm ci --quiet
  rules:
    - if: $CI_MERGE_REQUEST_IID
    - if: $CI_COMMIT_BRANCH == "main"

# Jobs que heredan el template:
test-unit:
  extends: .test-template
  script:
    - npm run test:unit

test-integration:
  extends: .test-template
  script:
    - npm run test:integration
  services:
    - postgres:15-alpine
```

### Anchors YAML (nativo de YAML)

```yaml
# Definir anchor:
.cache-config: &cache-config
  cache:
    key: $CI_COMMIT_REF_SLUG
    paths:
      - node_modules/

# Usar anchor:
test-unit:
  <<: *cache-config    # Incluye el bloque cache
  script: npm test

test-integration:
  <<: *cache-config    # Misma configuración de cache
  script: npm run test:integration
```

---

## 🛑 Control de Fallos

```yaml
# Job que puede fallar sin bloquear el pipeline:
security-scan:
  stage: validate
  script:
    - trivy fs --exit-code 1 .
  allow_failure: true    # El pipeline continúa aunque este job falle

# Job que se ejecuta SOLO si algo falló (ej: notificación):
notify-failure:
  stage: .post
  script:
    - ./notify-slack.sh "Pipeline failed on $CI_COMMIT_BRANCH"
  when: on_failure       # Solo cuando algo falla

# Job que se ejecuta SIEMPRE (limpieza):
cleanup:
  stage: .post
  script:
    - docker system prune -f
  when: always           # Siempre, incluso si el pipeline falla
```

---

## 🖼️ Diagrama: Pipeline con Stages y DAG

![Diagrama de pipeline con stages y necesidades DAG](../0-assets/03-stages-dag.svg)

> **Diagrama:** Compara un pipeline lineal clásico (stage1 → stage2 → stage3) con un pipeline DAG usando `needs`, mostrando cómo los jobs pueden empezar antes incluso si están en stages más avanzadas, cuando sus dependencias directas están completas.

---

## 🤔 Preguntas de reflexión

1. Tienes un job `e2e-tests` que tarda 15 minutos. El pipeline completo tarda 25 minutos porque `e2e-tests` espera a que `build` termine (5 min). ¿Cómo usarías `needs` para reducir el tiempo del pipeline?

2. El job `security-scan` usa `allow_failure: true`. ¿Cuál es el riesgo de esta configuración? ¿En qué circunstancias la cambiarías a `allow_failure: false`?

3. Tienes 10 proyectos con pipelines muy similares. Cada vez que cambias el template (`.test-template`) necesitas actualizar los 10 repositorios. ¿Qué característica de GitLab podría ayudarte a centralizar esto?

4. El job `deploy-produccion` tiene `when: manual`. ¿Cómo puedes asegurarte de que solo el Tech Lead puede ejecutarlo, no cualquier developer?

5. Cuando un job tiene `retry: max: 2` y falla por un error de red (runner_system_failure), GitLab lo reintenta 2 veces. ¿Qué tipos de errores NO deberían reintentarse automáticamente?

---

## 📚 Recursos adicionales

- [Stages keyword](https://docs.gitlab.com/ee/ci/yaml/#stages)
- [Needs keyword (DAG)](https://docs.gitlab.com/ee/ci/yaml/#needs)
- [Parallel:matrix](https://docs.gitlab.com/ee/ci/yaml/#parallelmatrix)
- [Extends keyword](https://docs.gitlab.com/ee/ci/yaml/#extends)
- [CI/CD pipelines — Directed Acyclic Graph](https://docs.gitlab.com/ee/ci/directed_acyclic_graph/)

---

⬅️ **Lección anterior:** [02 — .gitlab-ci.yml](./02-gitlab-ci-yml.md)
➡️ **Siguiente lección:** [04 — Imágenes Docker en CI](./04-imagenes-docker.md)

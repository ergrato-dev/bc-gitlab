# 📖 05 — Triggers y Pipelines Multi-Proyecto

## 🎯 Objetivos de aprendizaje

- ✅ Entender cuándo y por qué usar pipelines multi-proyecto
- ✅ Configurar triggers downstream con `trigger:project` y `trigger:include`
- ✅ Distinguir parent-child pipelines de multi-project pipelines
- ✅ Pasar variables entre pipelines upstream y downstream
- ✅ Usar `strategy: depend` para encadenar el resultado entre pipelines

---

## 🤔 ¿Por Qué Pipelines Multi-Proyecto?

Un sistema de software real raramente es un solo repositorio. Hay librerías compartidas, servicios independientes, y dependencias entre equipos:

```
Escenario real:
  Equipo Libs  → mantiene libcomp (librería compartida)
  Equipo Front → mantiene webapp (consume libcomp)
  Equipo Back  → mantiene api-server (consume libcomp)

Sin triggers:
  1. Equipo Libs publica libcomp v2.1.0
  2. Equipo Front debe notar manualmente el cambio y actualizar
  3. Semana después: webapp tiene bug porque usa libcomp antigua

Con triggers:
  1. Equipo Libs publica libcomp v2.1.0
  2. El pipeline de libcomp DISPARA automáticamente los pipelines de webapp y api-server
  3. En minutos: ambos equipos saben si la nueva versión rompe algo
```

**Analogía:** Los triggers son como las notificaciones push de una app. No tienes que revisar manualmente si hay cambios — cuando pasa algo relevante, te notifica.

---

## 📐 Tipos de Pipelines Encadenados

### Multi-Project Pipelines

Un proyecto dispara el pipeline de **otro proyecto diferente**. Ejemplo: el pipeline de la librería (Proyecto A) dispara automáticamente el pipeline de la aplicación que la consume (Proyecto B), verificando que la nueva versión no rompe nada.

### Parent-Child Pipelines

Un pipeline principal dispara sub-pipelines dentro del **mismo proyecto**. Los child pipelines se ejecutan en paralelo y el parent puede esperar sus resultados antes de continuar.

---

## 🔫 Multi-Project Pipelines

### Configurar el trigger en el upstream (Proyecto A)

```yaml
# Proyecto A: librería que dispara el pipeline de la app
# .gitlab-ci.yml del Proyecto A

stages:
  - test
  - publish
  - notify-consumers

test:
  stage: test
  script: npm test

publish:
  stage: publish
  script:
    - npm publish
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+/

# Job bridge — dispara el pipeline downstream
trigger-webapp:
  stage: notify-consumers
  trigger:
    project: frontend/webapp    # ← ruta completa del proyecto downstream
    branch: main                # ← en qué rama disparar (default: rama por defecto)
    strategy: depend            # ← esperar resultado y reflejar estado
  variables:
    LIBCOMP_VERSION: $CI_COMMIT_TAG    # ← pasar variables al downstream
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+/
```

### Opciones de `strategy`

| `strategy` | Comportamiento del job upstream |
|------------|--------------------------------|
| *(no declarada)* | El job bridge se marca **exitoso inmediatamente** sin esperar al downstream |
| `depend` | El job bridge espera al downstream. Si el downstream falla, el upstream también falla |

```yaml
# Con strategy: depend — encadenamiento de estado
trigger-integration-tests:
  stage: verify
  trigger:
    project: qa/integration-tests
    branch: main
    strategy: depend    # ← el pipeline upstream "hereda" el resultado del downstream
  variables:
    UPSTREAM_COMMIT: $CI_COMMIT_SHA
    UPSTREAM_PROJECT: $CI_PROJECT_PATH
```

---

## 👶 Parent-Child Pipelines

Dividir un pipeline grande en sub-pipelines del mismo proyecto. Útil para monorepos:

```yaml
# .gitlab-ci.yml (parent pipeline)
stages:
  - trigger-children

# Disparar child pipelines definidos en archivos locales
child-frontend:
  stage: trigger-children
  trigger:
    include:
      - local: .gitlab/pipelines/frontend.yml
    strategy: depend

child-backend:
  stage: trigger-children
  trigger:
    include:
      - local: .gitlab/pipelines/backend.yml
    strategy: depend

child-infra:
  stage: trigger-children
  trigger:
    include:
      - local: .gitlab/pipelines/infra.yml
    strategy: depend
```

```yaml
# .gitlab/pipelines/frontend.yml (child pipeline)
stages:
  - build
  - test

build-frontend:
  stage: build
  image: node:18-alpine
  script:
    - npm ci
    - npm run build

test-frontend:
  stage: test
  image: node:18-alpine
  script:
    - npm test
```

---

## 🔄 Child Pipelines Dinámicos

Los child pipelines pueden generarse dinámicamente desde scripts — útil cuando los sub-pipelines dependen de qué archivos cambiaron:

```yaml
# .gitlab-ci.yml
stages:
  - generate
  - trigger

# Paso 1: Script genera el archivo YAML del child pipeline
generate-pipeline:
  stage: generate
  script:
    # ¿QUÉ HACE?: Analiza qué services cambiaron y genera un pipeline específico
    # ¿POR QUÉ?: En un monorepo con 20 microservicios, no queremos testear todos
    # ¿PARA QUÉ?: Solo testear y deployar los services que realmente cambiaron
    - python3 scripts/generate-ci.py --changed-files="$(git diff --name-only HEAD~1)" \
      > generated-pipeline.yml
  artifacts:
    paths:
      - generated-pipeline.yml

# Paso 2: Usar el YAML generado como child pipeline
trigger-dynamic:
  stage: trigger
  trigger:
    include:
      - artifact: generated-pipeline.yml
        job: generate-pipeline   # ← tomar el artifact del job anterior
    strategy: depend
  needs: [generate-pipeline]
```

---

## 📨 Pasar Variables a Downstream

```yaml
# Upstream → Downstream: pasar variables con trigger:variables
trigger-downstream:
  stage: notify
  trigger:
    project: qa/smoke-tests
    strategy: depend
  variables:
    UPSTREAM_COMMIT_SHA: $CI_COMMIT_SHA
    UPSTREAM_PIPELINE_ID: $CI_PIPELINE_ID
    UPSTREAM_PROJECT_URL: $CI_PROJECT_URL
    DEPLOY_ENV: "staging"
    APP_VERSION: $CI_COMMIT_TAG

# El downstream puede acceder a estas como variables normales:
# $UPSTREAM_COMMIT_SHA, $DEPLOY_ENV, etc.
```

---

## 🔗 Triggers via API

Además de los `trigger:` jobs, puedes disparar un pipeline desde cualquier sistema externo via API:

```bash
# ¿QUÉ HACE?: Dispara el pipeline del proyecto 42 en la rama main
# ¿POR QUÉ?: Permite que sistemas externos (Jenkins, webhook de GitHub, etc.) disparen pipelines de GitLab
# ¿PARA QUÉ?: Integración con herramientas fuera de GitLab
curl -X POST \
  --form token="${PIPELINE_TRIGGER_TOKEN}" \
  --form ref=main \
  --form "variables[DEPLOY_ENV]=production" \
  --form "variables[APP_VERSION]=2.1.0" \
  "http://localhost/api/v4/projects/42/trigger/pipeline"
```

**Crear el trigger token:**
```
Proyecto → Settings → CI/CD → Pipeline triggers → Add new trigger
→ Guarda el token (solo visible una vez)
→ Úsalo como PIPELINE_TRIGGER_TOKEN en tus scripts externos
```

---

## 🔍 Ver Pipelines Encadenados en la UI

GitLab muestra la cadena de pipelines en la UI. En un multi-project pipeline, el job bridge del upstream muestra un enlace al pipeline downstream con su estado en tiempo real. Si se usa `strategy: depend`, el estado del bridge refleja el resultado del downstream.

En un parent-child pipeline, la UI del pipeline padre muestra los child pipelines anidados con su propio grafo de stages y jobs. Al hacer click en cada child se navega a su detalle completo.

---

## ⚖️ Multi-Project vs Parent-Child

| Criterio | Multi-Project | Parent-Child |
|----------|--------------|--------------|
| Proyectos | Diferentes repositorios | Mismo repositorio |
| Caso de uso | Notificar consumidores de una lib | Monorepo con múltiples servicios |
| Variables compartidas | Via `trigger:variables` | Heredadas automáticamente del parent |
| Artifacts compartidos | No directamente | Via `needs:` con `project:` |
| Visibilidad en UI | Pipelines separados enlazados | Pipelines anidados en el mismo proyecto |

---

## 🛡️ Seguridad en Triggers

```yaml
# CI_JOB_TOKEN — forma segura de disparar pipelines entre proyectos del mismo GitLab
# No necesita crear un trigger token manualmente
trigger-safe:
  stage: notify
  script:
    - |
      curl -X POST \
        --header "PRIVATE-TOKEN: ${CI_JOB_TOKEN}" \
        --form ref=main \
        "http://localhost/api/v4/projects/42/trigger/pipeline"

# Requiere que el proyecto destino permita acceso desde CI_JOB_TOKEN del proyecto fuente:
# Proyecto B → Settings → CI/CD → Token Access → Allow project A
```

---

---

## 🤔 Preguntas de reflexión

1. Tienes un monorepo con 15 microservicios. Si usas parent-child pipelines sin ningún filtro de `changes`, cada push ejecuta 15 pipelines hijos. ¿Cómo optimizarías esto para solo ejecutar los pipelines de los servicios que cambiaron?

2. `strategy: depend` hace que el upstream espere al downstream. ¿Qué pasa con el tiempo total del pipeline? ¿En qué escenarios usarías triggers sin `strategy: depend`?

3. Un pipeline de QA tarda 45 minutos. Si lo disparas como downstream con `strategy: depend`, el job upstream bloquea por 45 minutos. ¿Cómo afecta esto al uso de runners del proyecto upstream?

4. Los trigger tokens permiten que sistemas externos disparen pipelines. ¿Qué riesgos de seguridad existen? ¿Cómo los mitigarías? (Pista: considera dónde se almacena el token, quién tiene acceso, y si puede usarse para inyectar código malicioso via variables.)

5. En un pipeline parent-child dinámico, el script `generate-ci.py` genera el YAML del child pipeline. ¿Qué pasa si el script tiene un bug y genera YAML inválido? ¿GitLab lo detecta antes de intentar ejecutar? ¿O el child pipeline simplemente falla?

---

## 📚 Recursos adicionales

- [Multi-Project Pipelines](https://docs.gitlab.com/ee/ci/pipelines/multi_project_pipelines.html)
- [Parent-Child Pipelines](https://docs.gitlab.com/ee/ci/pipelines/parent_child_pipelines.html)
- [Downstream Pipelines](https://docs.gitlab.com/ee/ci/pipelines/downstream_pipelines.html)
- [trigger Keyword Reference](https://docs.gitlab.com/ee/ci/yaml/#trigger)
- [Pipeline Trigger API](https://docs.gitlab.com/ee/ci/triggers/)

---

⬅️ **Lección anterior:** [04 — Environments y Deployments](./04-environments-y-deployments.md)
➡️ **Prácticas:** [01 — Variables y Secretos](../2-practicas/01-variables-y-secretos/README.md)

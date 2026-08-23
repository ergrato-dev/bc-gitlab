# 🏗️ Proyecto — Semana 07: Infraestructura de Runners

## 📋 Descripción

Diseñar e implementar una infraestructura completa de GitLab Runners para una organización ficticia con tres equipos: Frontend, Backend y Operaciones. Cada equipo tiene runners especializados con diferentes ejecutores, tags y niveles de acceso.

**Organización ficticia:** `DevCorp` — empresa de software con 3 equipos y ~15 proyectos en GitLab.

---

## 🎯 Objetivos del Proyecto

Al completar el proyecto habrás:
1. Instalado y registrado 5 runners con diferentes tipos, ejecutores y tags
2. Demostrado enrutamiento correcto con un pipeline multi-job
3. Documentado la configuración completa de `config.toml` de cada runner
4. Registrado y analizado 4 escenarios de routing (incluido jobs pending)
5. Verificado todo vía API y con capturas de la UI

---

## 🏗️ Paso 1: Arquitectura de Runners

Registrar los siguientes 5 runners. Usar la API para crear los tokens:

| Runner | Tipo | Executor | Tags | Propósito |
|--------|------|----------|------|-----------|
| `devcorp-general` | Instance | Docker | `docker,linux,general` | Jobs sin requisitos especiales |
| `devcorp-frontend` | Instance | Docker | `docker,linux,nodejs,frontend` | Builds Node.js / React |
| `devcorp-backend` | Instance | Docker | `docker,linux,python,backend` | Tests Python / Django |
| `devcorp-java` | Instance | Docker | `docker,linux,java,maven` | Builds Java / Maven |
| `devcorp-deploy` | Instance | Shell | `shell,linux,deploy,production` | Deploy scripts, acceso SSH |

```bash
# Script para crear los 5 tokens via API

declare -A RUNNERS
RUNNERS["devcorp-general"]="docker,linux,general"
RUNNERS["devcorp-frontend"]="docker,linux,nodejs,frontend"
RUNNERS["devcorp-backend"]="docker,linux,python,backend"
RUNNERS["devcorp-java"]="docker,linux,java,maven"
RUNNERS["devcorp-deploy"]="shell,linux,deploy,production"

echo "Creando tokens para 5 runners..."
echo ""

for NAME in "${!RUNNERS[@]}"; do
    TAGS="${RUNNERS[$NAME]}"
    TOKEN=$(curl --silent --request POST \
      --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
      --header "Content-Type: application/json" \
      --data "{\"runner_type\":\"instance_type\",\"description\":\"$NAME\",\"tag_list\":\"$TAGS\",\"run_untagged\":false}" \
      "http://localhost/api/v4/user/runners" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('token','ERROR'))")
    echo "  $NAME → $TOKEN"
    export "TOKEN_${NAME//-/_^^}"="$TOKEN"
done
```

---

## 🐳 Paso 2: Instalar y Registrar los Runners Docker

```bash
# Script de instalación para los 4 runners Docker

for NAME in "devcorp-general" "devcorp-frontend" "devcorp-backend" "devcorp-java"; do
    echo "=== Instalando $NAME ==="

    # Crear directorio de configuración
    sudo mkdir -p "/srv/$NAME/config"

    # Iniciar contenedor
    docker run -d \
      --name "$NAME" \
      --restart always \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v "/srv/$NAME/config:/etc/gitlab-runner" \
      gitlab/gitlab-runner:alpine

    echo "  Contenedor $NAME iniciado"
    echo ""
done

echo "Verifica que todos están corriendo:"
docker ps --filter "name=devcorp" --format "table {{.Names}}\t{{.Status}}"
```

```bash
# Registrar cada runner con su token y configuración específica
# Reemplazar TOKEN_XXXX con los tokens obtenidos en el Paso 1

# Runner general
docker exec devcorp-general gitlab-runner register \
  --non-interactive --url "http://localhost" \
  --token "$TOKEN_GENERAL" \    # ← reemplazar
  --executor "docker" --docker-image "alpine:latest" \
  --docker-volumes "/cache" --docker-pull-policy "if-not-present" \
  --tag-list "docker,linux,general" --description "devcorp-general" \
  --run-untagged "true"          # ← general acepta jobs sin tags

# Runner frontend (imagen default: Node.js)
docker exec devcorp-frontend gitlab-runner register \
  --non-interactive --url "http://localhost" \
  --token "$TOKEN_FRONTEND" \
  --executor "docker" --docker-image "node:18-alpine" \
  --docker-volumes "/cache" --docker-pull-policy "if-not-present" \
  --tag-list "docker,linux,nodejs,frontend" --description "devcorp-frontend" \
  --run-untagged "false"

# Runner backend (imagen default: Python)
docker exec devcorp-backend gitlab-runner register \
  --non-interactive --url "http://localhost" \
  --token "$TOKEN_BACKEND" \
  --executor "docker" --docker-image "python:3.11-slim" \
  --docker-volumes "/cache" --docker-pull-policy "if-not-present" \
  --tag-list "docker,linux,python,backend" --description "devcorp-backend" \
  --run-untagged "false"

# Runner Java/Maven
docker exec devcorp-java gitlab-runner register \
  --non-interactive --url "http://localhost" \
  --token "$TOKEN_JAVA" \
  --executor "docker" --docker-image "maven:3.9-eclipse-temurin-17" \
  --docker-volumes "/cache" --docker-pull-policy "if-not-present" \
  --tag-list "docker,linux,java,maven" --description "devcorp-java" \
  --run-untagged "false"
```

```bash
# Runner deploy (Shell executor — contenedor separado sin socket Docker montado)
sudo mkdir -p /srv/devcorp-deploy/config

docker run -d \
  --name devcorp-deploy \
  --restart always \
  -v /srv/devcorp-deploy/config:/etc/gitlab-runner \
  gitlab/gitlab-runner:alpine

docker exec devcorp-deploy gitlab-runner register \
  --non-interactive --url "http://localhost" \
  --token "$TOKEN_DEPLOY" \
  --executor "shell" \
  --tag-list "shell,linux,deploy,production" --description "devcorp-deploy" \
  --run-untagged "false"
```

---

## 📄 Paso 3: Documentar el `config.toml` de Cada Runner

```bash
# ¿QUÉ HACE?: Muestra el config.toml completo de cada runner con anotaciones
# ¿POR QUÉ?: La documentación del config.toml es parte del entregable
# ¿PARA QUÉ?: Evidenciar comprensión de cada parámetro configurado

for NAME in devcorp-general devcorp-frontend devcorp-backend devcorp-java devcorp-deploy; do
    echo "====== config.toml: $NAME ======"
    sudo cat "/srv/$NAME/config/config.toml"
    echo ""
done
```

**Modificar el `concurrent` global en cada runner** (cada runner puede procesar 2 jobs simultáneos):

```bash
for NAME in devcorp-general devcorp-frontend devcorp-backend devcorp-java devcorp-deploy; do
    sudo sed -i 's/^concurrent = 1$/concurrent = 2/' "/srv/$NAME/config/config.toml"
    docker restart "$NAME"
    echo "Runner $NAME: concurrent actualizado a 2"
done
```

---

## 📊 Paso 4: Verificar la Flota Completa

```bash
# ¿QUÉ HACE?: Consulta todos los runners y verifica que los 5 están online
# ¿POR QUÉ?: Confirmar que el registro fue exitoso para todos antes del pipeline
# ¿PARA QUÉ?: Evidencia de la flota completa para el entregable

curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/runners?status=online&per_page=20" \
  | python3 -c "
import sys, json
runners = json.load(sys.stdin)
devcorp = [r for r in runners if 'devcorp' in r.get('description','')]
print(f'Runners DevCorp online: {len(devcorp)} de 5 esperados')
print()
print(f'{'ID':<6} {'Nombre':<25} {'run_untagged':<14} {'Tags'}')
print('-' * 80)
for r in devcorp:
    tags = ','.join(r.get('tag_list',[]))
    ut = r.get('run_untagged', False)
    print(f'{r[\"id\"]:<6} {r[\"description\"]:<25} {str(ut):<14} {tags}')
"
```

---

## 🚀 Paso 5: Pipeline de Demostración

Crear el siguiente `.gitlab-ci.yml` en el proyecto:

```yaml
# Pipeline de demostración de la infraestructura DevCorp
stages:
  - frontend
  - backend
  - java
  - integration
  - deploy

# ─── FRONTEND TEAM ──────────────────────────────────────────────────────────────
frontend-lint:
  stage: frontend
  tags: [frontend, nodejs]
  image: node:18-alpine
  script:
    - echo "=== FRONTEND LINT en $(hostname) ==="
    - node --version && npm --version
    - echo "Simulando: eslint src/"
    - echo "✅ Lint: 0 errores"

frontend-test:
  stage: frontend
  tags: [frontend, nodejs]
  image: node:20-alpine     # este job usa Node 20, diferente del default del runner
  script:
    - echo "=== FRONTEND TEST (Node 20) en $(hostname) ==="
    - node --version
    - echo "Simulando: jest --coverage"
    - echo "✅ 47 tests passed | Coverage: 89%"
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
    expire_in: 1 week

# ─── BACKEND TEAM ───────────────────────────────────────────────────────────────
backend-test:
  stage: backend
  tags: [backend, python]
  image: python:3.11-slim
  services:
    - name: postgres:15-alpine
      alias: db
  variables:
    POSTGRES_DB: testdb
    POSTGRES_USER: tester
    POSTGRES_PASSWORD: testpass
  script:
    - echo "=== BACKEND TEST (Python + PostgreSQL) en $(hostname) ==="
    - python3 --version && pip --version
    - apt-get update -qq && apt-get install -y -qq postgresql-client
    - until pg_isready -h db -U tester; do sleep 1; done
    - echo "PostgreSQL: ✅ conectado"
    - python3 -c "import psycopg2; print('psycopg2: disponible')" 2>/dev/null \
      || echo "psycopg2 no instalado (demo)"
    - echo "✅ 23 tests passed"

backend-lint:
  stage: backend
  tags: [backend, python]
  image: python:3.11-slim
  script:
    - echo "=== BACKEND LINT en $(hostname) ==="
    - python3 --version
    - echo "Simulando: flake8 . && black --check ."
    - echo "✅ Sin errores de estilo"

# ─── JAVA TEAM ──────────────────────────────────────────────────────────────────
java-compile:
  stage: java
  tags: [java, maven]
  image: maven:3.9-eclipse-temurin-17
  script:
    - echo "=== JAVA COMPILE en $(hostname) ==="
    - java --version && mvn --version
    - echo "Simulando: mvn compile"
    - echo "✅ BUILD SUCCESS"

java-test:
  stage: java
  tags: [java, maven]
  image: maven:3.9-eclipse-temurin-17
  script:
    - echo "=== JAVA TEST en $(hostname) ==="
    - echo "Simulando: mvn test"
    - echo "Tests run: 15, Failures: 0, Errors: 0"
    - echo "✅ BUILD SUCCESS"

# ─── INTEGRATION ────────────────────────────────────────────────────────────────
integration-check:
  stage: integration
  tags: [general]      # runner general — no requiere stack específico
  image: alpine:latest
  needs: [frontend-test, backend-test, java-test]
  script:
    - echo "=== INTEGRATION CHECK en $(hostname) ==="
    - echo "Frontend: ✅"
    - echo "Backend: ✅"
    - echo "Java: ✅"
    - echo "✅ Todos los equipos: BUILD PASSED"

# ─── DEPLOY TEAM ────────────────────────────────────────────────────────────────
deploy-staging:
  stage: deploy
  tags: [deploy, shell]    # shell runner — acceso a SSH keys del host
  environment:
    name: staging
    url: http://staging.devcorp.example.com
  script:
    - echo "=== DEPLOY STAGING en $(hostname) ==="
    - echo "Runner: $CI_RUNNER_DESCRIPTION"
    - echo "Ejecutor: Shell — acceso directo al host"
    - echo "Commit: $CI_COMMIT_SHORT_SHA"
    - echo "Simulando: rsync -av dist/ usuario@staging:/var/www/app/"
    - echo "Simulando: ssh staging 'systemctl restart app'"
    - echo "✅ Deploy a staging: COMPLETADO"
  rules:
    - if: $CI_COMMIT_BRANCH == "main"

deploy-production:
  stage: deploy
  tags: [deploy, shell]
  environment:
    name: production
    url: http://devcorp.example.com
  script:
    - echo "=== DEPLOY PRODUCTION en $(hostname) ==="
    - echo "Simulando: deploy a producción con credenciales del host"
    - echo "✅ Deploy a producción: COMPLETADO"
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: manual
      allow_failure: false
```

---

## 🧪 Paso 6: Pruebas de Enrutamiento

### Prueba A: Job sin tags → runner `devcorp-general`

```yaml
# En el .gitlab-ci.yml, añadir temporalmente:
no-tags-job:
  stage: frontend
  script:
    - echo "Runner: $CI_RUNNER_DESCRIPTION"
    - echo "Sin tags → debe ir al runner general (run_untagged=true)"
```

### Prueba B: Tags que ningún runner tiene → Job pending

```yaml
gpu-job:
  stage: backend
  tags:
    - gpu
    - cuda12
  script:
    - nvidia-smi
    - echo "Este job quedará pending"
  allow_failure: true
```

### Prueba C: Runner pausado → Jobs quedan pending

```bash
# Pausar devcorp-frontend
RUNNER_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/runners" | python3 -c "
import sys, json
for r in json.load(sys.stdin):
    if r.get('description') == 'devcorp-frontend':
        print(r['id'])
")

curl --silent --request PUT \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data '{"paused":true}' \
  "http://localhost/api/v4/runners/$RUNNER_ID"

# Disparar pipeline → los jobs con tags [frontend] quedarán pending
# Documentar con captura
# Luego reactivar:
curl --silent --request PUT \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data '{"paused":false}' \
  "http://localhost/api/v4/runners/$RUNNER_ID"
```

### Prueba D: Resumen de routing

```bash
# ¿QUÉ HACE?: Consulta el pipeline más reciente y muestra qué runner ejecutó cada job
# ¿POR QUÉ?: Evidencia principal del enrutamiento correcto para el entregable
# ¿PARA QUÉ?: Tabla completa de job → runner para documentar en el entregable

PIPELINE_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/pipelines?per_page=1" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

echo "Analizando pipeline $PIPELINE_ID..."
echo ""

curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/pipelines/$PIPELINE_ID/jobs?per_page=30" \
  | python3 -c "
import sys, json
jobs = json.load(sys.stdin)
print(f'{'Job':<30} {'Estado':<12} {'Runner':<30} {'Duración'}')
print('-' * 90)
for j in sorted(jobs, key=lambda x: x.get('id', 0)):
    runner = j.get('runner') or {}
    runner_name = runner.get('description', 'sin runner')
    duration = f'{j.get(\"duration\",0):.1f}s' if j.get('duration') else '-'
    print(f'{j[\"name\"]:<30} {j[\"status\"]:<12} {runner_name:<30} {duration}')
"
```

---

## 📦 Entregables

```
devcorp-runners/
├── config/
│   ├── devcorp-general.toml       ← config.toml del runner general (anotado)
│   ├── devcorp-frontend.toml      ← config.toml del runner frontend (anotado)
│   ├── devcorp-backend.toml       ← config.toml del runner backend (anotado)
│   ├── devcorp-java.toml          ← config.toml del runner Java (anotado)
│   └── devcorp-deploy.toml        ← config.toml del runner deploy (anotado)
└── evidencia/
    ├── 01-runners-online.png      ← Admin Area mostrando 5 runners ● verde
    ├── 02-pipeline-passed.png     ← Pipeline completo en "passed"
    ├── 03-routing-table.txt       ← Output del script de Prueba D
    ├── 04-pending-gpu.png         ← Job pending por tags inexistentes
    └── 05-runner-pausado.png      ← Jobs pending mientras runner está pausado
```

### Checklist de entregables

- [ ] 5 runners registrados con ● verde en Admin Area → CI/CD → Runners
- [ ] Pipeline de demostración en estado `passed` en rama `main`
- [ ] Cada job del pipeline corrió en el runner con los tags correctos (tabla Prueba D)
- [ ] `config.toml` de los 5 runners exportados y anotados
- [ ] Prueba B documentada: job con tags inexistentes en estado `pending`
- [ ] Prueba C documentada: runner pausado → jobs pending → runner activo → jobs corren
- [ ] Evidencia visual (capturas) en el directorio `evidencia/`

---

⬅️ **Prácticas:** [2-practicas/README.md](../2-practicas/README.md)
➡️ **Glosario:** [5-glosario/README.md](../5-glosario/README.md)

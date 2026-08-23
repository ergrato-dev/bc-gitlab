# 🔬 Práctica 03 — Tags y Enrutamiento de Jobs

**Duración estimada:** 45 minutos
**Dificultad:** ⭐⭐⭐ (Media-Alta)

## 🎯 Objetivo

Configurar múltiples runners con diferentes tags para simular una infraestructura multi-equipo, demostrar que GitLab enruta cada job al runner correcto, y diagnosticar qué ocurre cuando un job no puede ser asignado.

---

## 📋 Prerrequisitos

- Runner Docker general online (Práctica 01)
- `$GITLAB_TOKEN` y `$GITLAB_PROJECT_ID` exportados
- Permisos de Admin en la instancia GitLab

---

## 🏗️ Paso 1: Crear Tres Runners Especializados

Simularemos tres runners especializados usando tres contenedores separados en el mismo host.

### Runner Frontend (Node.js)

```bash
# ¿QUÉ HACE?: Crea un runner especializado para proyectos Node.js / Frontend
# ¿POR QUÉ?: En un entorno real, el runner frontend puede tener caché de módulos npm
# ¿PARA QUÉ?: Demostrar routing basado en tecnología

# Token para runner frontend
export TOKEN_FRONTEND=$(curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"runner_type":"instance_type","description":"runner-frontend","tag_list":["docker","linux","nodejs","frontend"],"run_untagged":false}' \
  "http://localhost/api/v4/user/runners" \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('token','ERROR'))")

echo "Token frontend: $TOKEN_FRONTEND"

# Instalar runner frontend
sudo mkdir -p /srv/runner-frontend/config

docker run -d \
  --name runner-frontend \
  --restart always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /srv/runner-frontend/config:/etc/gitlab-runner \
  gitlab/gitlab-runner:alpine

# Registrar
docker exec runner-frontend gitlab-runner register \
  --non-interactive \
  --url "http://localhost" \
  --token "$TOKEN_FRONTEND" \
  --executor "docker" \
  --docker-image "node:18-alpine" \
  --docker-volumes "/cache" \
  --docker-pull-policy "if-not-present" \
  --tag-list "docker,linux,nodejs,frontend" \
  --description "runner-frontend" \
  --run-untagged "false"
```

### Runner Backend (Python)

```bash
# Token para runner backend
export TOKEN_BACKEND=$(curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"runner_type":"instance_type","description":"runner-backend","tag_list":["docker","linux","python","backend"],"run_untagged":false}' \
  "http://localhost/api/v4/user/runners" \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('token','ERROR'))")

sudo mkdir -p /srv/runner-backend/config

docker run -d \
  --name runner-backend \
  --restart always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /srv/runner-backend/config:/etc/gitlab-runner \
  gitlab/gitlab-runner:alpine

docker exec runner-backend gitlab-runner register \
  --non-interactive \
  --url "http://localhost" \
  --token "$TOKEN_BACKEND" \
  --executor "docker" \
  --docker-image "python:3.11-slim" \
  --docker-volumes "/cache" \
  --docker-pull-policy "if-not-present" \
  --tag-list "docker,linux,python,backend" \
  --description "runner-backend" \
  --run-untagged "false"
```

### Runner Deploy (Shell)

```bash
# Token para runner deploy
export TOKEN_DEPLOY=$(curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"runner_type":"instance_type","description":"runner-deploy","tag_list":["shell","linux","deploy","production"],"run_untagged":false}' \
  "http://localhost/api/v4/user/runners" \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('token','ERROR'))")

sudo mkdir -p /srv/runner-deploy/config

docker run -d \
  --name runner-deploy \
  --restart always \
  -v /srv/runner-deploy/config:/etc/gitlab-runner \
  gitlab/gitlab-runner:alpine

docker exec runner-deploy gitlab-runner register \
  --non-interactive \
  --url "http://localhost" \
  --token "$TOKEN_DEPLOY" \
  --executor "shell" \
  --tag-list "shell,linux,deploy,production" \
  --description "runner-deploy" \
  --run-untagged "false"
```

---

## 🔍 Paso 2: Verificar los Tres Runners Online

```bash
# ¿QUÉ HACE?: Consulta todos los runners y muestra su estado con tags
# ¿POR QUÉ?: Confirmar que los tres nuevos runners están conectados antes de crear el pipeline
# ¿PARA QUÉ?: Evitar jobs pending por runners no registrados correctamente

curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/runners?status=online&per_page=20" \
  | python3 -c "
import sys, json
runners = json.load(sys.stdin)
print(f'Total runners online: {len(runners)}')
print()
print(f'{'ID':<5} {'Nombre':<25} {'Tags'}')
print('-' * 70)
for r in runners:
    tags = ', '.join(r.get('tag_list', []))
    print(f'{r[\"id\"]:<5} {r[\"description\"]:<25} {tags}')
"
```

---

## 🚀 Paso 3: Pipeline con Enrutamiento por Tags

Crear el siguiente `.gitlab-ci.yml` en el proyecto:

```yaml
stages:
  - test
  - build
  - deploy

# ─── FRONTEND ───────────────────────────────────────────────────────────────────
frontend-test:
  stage: test
  tags:
    - frontend      # ← solo el runner-frontend lo puede ejecutar
    - nodejs
  image: node:18-alpine
  script:
    # ¿QUÉ HACE?: Ejecuta en el runner con tags nodejs/frontend
    # ¿POR QUÉ?: En producción, este runner tendría el caché de npm preinstalado
    # ¿PARA QUÉ?: Verificar que el routing funciona — node debe estar disponible
    - echo "=== FRONTEND TEST en $(hostname) ==="
    - node --version
    - npm --version
    - echo "Test: import React..." # simulación
    - echo "✅ Frontend tests: PASSED"

frontend-build:
  stage: build
  tags:
    - frontend
    - nodejs
  image: node:18-alpine
  script:
    - echo "=== FRONTEND BUILD en $(hostname) ==="
    - echo "Simulating: npm run build..."
    - mkdir -p dist
    - echo "<html><body>Built at $(date)</body></html>" > dist/index.html
    - echo "✅ Frontend build: COMPLETED"
  artifacts:
    paths:
      - dist/
    expire_in: 1 hour

# ─── BACKEND ────────────────────────────────────────────────────────────────────
backend-test:
  stage: test
  tags:
    - backend       # ← solo el runner-backend lo puede ejecutar
    - python
  image: python:3.11-slim
  script:
    - echo "=== BACKEND TEST en $(hostname) ==="
    - python3 --version
    - pip --version
    - python3 -c "import sys; print(f'Python {sys.version}')"
    - echo "✅ Backend tests: PASSED"

backend-build:
  stage: build
  tags:
    - backend
    - python
  image: python:3.11-slim
  script:
    - echo "=== BACKEND BUILD en $(hostname) ==="
    - echo "Simulating: pip install && python setup.py bdist_wheel"
    - echo "✅ Backend build: COMPLETED"

# ─── DEPLOY ─────────────────────────────────────────────────────────────────────
deploy-all:
  stage: deploy
  tags:
    - deploy        # ← solo el runner-deploy (shell) lo puede ejecutar
    - shell
  environment:
    name: staging
  script:
    - echo "=== DEPLOY en $(hostname) - SHELL EXECUTOR ==="
    - echo "Deploys requieren acceso a secretos del host"
    - echo "Este runner tiene acceso a SSH keys del sistema"
    - hostname
    - whoami
    - echo "✅ Deploy: COMPLETED"
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

---

## 🧪 Paso 4: Verificar Routing en la UI y API

Después de que el pipeline corra, verificar en qué runner corrió cada job:

```bash
# ¿QUÉ HACE?: Muestra el pipeline más reciente con el runner de cada job
# ¿POR QUÉ?: Confirmar que el routing funcionó según los tags
# ¿PARA QUÉ?: Documentar que cada job fue al runner correcto

curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/pipelines?per_page=1" \
  | python3 -c "import sys,json; pipelines=json.load(sys.stdin); print(pipelines[0]['id'])" \
  | xargs -I{} curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/pipelines/{}/jobs" \
  | python3 -c "
import sys, json
jobs = json.load(sys.stdin)
print(f'{'Job':<25} {'Estado':<10} {'Runner'}')
print('-' * 65)
for j in jobs:
    runner = j.get('runner', {})
    runner_name = runner.get('description', 'sin runner') if runner else 'sin runner'
    print(f'{j[\"name\"]:<25} {j[\"status\"]:<10} {runner_name}')
"
```

---

## 🚫 Paso 5: Simular Job Pending (Tags Inexistentes)

```yaml
# Añadir al .gitlab-ci.yml temporalmente para demostrar el pending
test-gpu:
  stage: test
  tags:
    - gpu           # ← ningún runner tiene este tag
    - cuda12
  script:
    - nvidia-smi
    - echo "Este job NUNCA podrá correr — quedará pending"
```

```bash
# ¿QUÉ HACE?: Consulta jobs en estado pending del proyecto
# ¿POR QUÉ?: Verificar que el job con tags inexistentes quedó esperando
# ¿PARA QUÉ?: Demostrar el comportamiento de routing fallido

curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/jobs?scope=pending&per_page=10" \
  | python3 -c "
import sys, json
jobs = json.load(sys.stdin)
print(f'Jobs en estado PENDING: {len(jobs)}')
for j in jobs:
    tags = ','.join(j.get('tag_list', []))
    print(f'  #{j[\"id\"]}: {j[\"name\"]} — tags requeridos: [{tags}]')
    print(f'  Mensaje: Ningún runner online tiene todos estos tags')
"
```

> Después de verificar, quitar el job `test-gpu` del pipeline (o añadir `rules: - when: never`).

---

## ⏸️ Paso 6: Pausar un Runner y Observar el Comportamiento

```bash
# ¿QUÉ HACE?: Pausa el runner-frontend para simular que está en mantenimiento
# ¿POR QUÉ?: Demostrar que los jobs con tags del runner pausado quedan pending
# ¿PARA QUÉ?: Entender el comportamiento ante runners no disponibles

# Obtener ID del runner-frontend
RUNNER_FRONTEND_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/runners?status=online" \
  | python3 -c "
import sys, json
for r in json.load(sys.stdin):
    if 'frontend' in r.get('description',''):
        print(r['id'])
")

echo "Pausando runner ID: $RUNNER_FRONTEND_ID"

# Pausar el runner
curl --silent --request PUT \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"paused": true}' \
  "http://localhost/api/v4/runners/$RUNNER_FRONTEND_ID" \
  | python3 -c "import sys,json; r=json.load(sys.stdin); print(f'Runner #{r[\"id\"]} paused: {r[\"paused\"]}')"

# Disparar un nuevo pipeline — los jobs con tags [frontend] quedarán pending
echo "Ahora crea un commit para disparar el pipeline y observa los jobs frontend..."

# Reactivar el runner cuando termines la observación
# curl --request PUT --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
#   --data '{"paused": false}' \
#   "http://localhost/api/v4/runners/$RUNNER_FRONTEND_ID"
```

---

## 🔄 Paso 7: Reactivar y Confirmar que los Jobs Retoman

```bash
# ¿QUÉ HACE?: Reactiva el runner pausado
# ¿POR QUÉ?: Los jobs pending se asignan al runner cuando vuelve a estar activo
# ¿PARA QUÉ?: Demostrar que el sistema de cola no pierde jobs — solo los posterga

curl --silent --request PUT \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"paused": false}' \
  "http://localhost/api/v4/runners/$RUNNER_FRONTEND_ID" \
  | python3 -c "import sys,json; r=json.load(sys.stdin); print(f'Runner #{r[\"id\"]} activo: paused={r[\"paused\"]}')"

# Los jobs pending deberían comenzar a ejecutarse en segundos
echo "Observa en la UI cómo los jobs pending cambian a running..."
```

---

## ✅ Checklist de verificación

- [ ] Tres runners especializados online (frontend, backend, deploy)
- [ ] `frontend-test` corrió en `runner-frontend` (verificar en UI o API)
- [ ] `backend-test` corrió en `runner-backend`
- [ ] `deploy-all` corrió en `runner-deploy` (executor shell)
- [ ] Job `test-gpu` quedó en estado `pending` por tags no disponibles
- [ ] Runner pausado → jobs quedan pending → runner reactivado → jobs retoman

---

## 🏆 Reto adicional

Configurar `run_untagged = true` en el runner-frontend y observar cómo los jobs sin tags también llegan a él. Luego restablecer a `run_untagged = false`:

```bash
# Editar config.toml del runner-frontend
sudo nano /srv/runner-frontend/config/config.toml
# Cambiar: run_untagged = true
# (El runner recarga automáticamente — no hay que reiniciar)

# Ejecutar un pipeline con jobs sin tags y observar a qué runner van
# Luego reestablecer: run_untagged = false
```

---

⬅️ **Práctica anterior:** [02 — Configurar Ejecutores](../02-configurar-ejecutores/README.md)
➡️ **Siguiente práctica:** [04 — Runner en Kubernetes](../04-runner-kubernetes/README.md)

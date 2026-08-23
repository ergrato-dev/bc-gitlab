# 🔬 Práctica 03 — Imágenes Docker Personalizadas y Services

## 🎯 Objetivo

Usar diferentes imágenes Docker para distintos jobs, levantar services (PostgreSQL, Redis) para tests de integración, y entender cómo el runner crea la red Docker que conecta el job con sus services.

## ⏱️ Tiempo estimado: 45 minutos

## 📋 Requisitos previos

- Runner con executor Docker activo (requerido para images y services)
- Completada la Práctica 02

---

## 📝 Paso 1: Pipeline con Múltiples Imágenes

```bash
cat > .gitlab-ci.yml << 'YAML_EOF'
# Pipeline con diferentes imágenes por job
# Práctica 03 — Semana 05

# Imagen global (default para jobs sin imagen propia):
image: alpine:latest

stages:
  - validate
  - test
  - report

# Job 1: Usar imagen Node para tests de JS
test-node:
  stage: validate
  image: node:20-alpine       # Sobreescribe la imagen global
  script:
    - node --version
    - npm --version
    - echo "Ejecutando en Node.js $(node --version)"
    - node -e "console.log('✅ Node.js funciona en CI')"

# Job 2: Usar imagen Python para análisis
analisis-python:
  stage: validate
  image: python:3.12-slim    # Sobreescribe la imagen global
  script:
    - python3 --version
    - pip --version
    - python3 -c "
import sys
print(f'✅ Python {sys.version} funciona en CI')
print('Simulando análisis de código con bandit...')
print('No se encontraron vulnerabilidades críticas')
"

# Job 3: Usando la imagen global (alpine) para verificaciones básicas
check-files:
  stage: validate
  # Sin "image" → usa alpine:latest (la global)
  script:
    - echo "OS: $(cat /etc/os-release | grep PRETTY_NAME)"
    - echo "Verificando estructura del proyecto..."
    - ls -la
    - echo "✅ Estructura del proyecto verificada"

# Job 4: Usar imagen diferente para reporte final
reporte-final:
  stage: report
  image: python:3.12-slim
  needs:
    - test-node
    - analisis-python
    - check-files
  script:
    - python3 -c "
from datetime import datetime

results = {
    'test-node': '✅ PASSED',
    'analisis-python': '✅ PASSED',
    'check-files': '✅ PASSED'
}

print('=' * 50)
print('REPORTE DE PIPELINE')
print(f'Fecha: {datetime.utcnow().isoformat()}')
print('=' * 50)
for job, result in results.items():
    print(f'  {result}  {job}')
print('=' * 50)
print('Estado final: ✅ TODOS LOS JOBS PASARON')
"
YAML_EOF

git add .gitlab-ci.yml
git commit -m "ci: use different Docker images per job"
git push origin main
```

Verificar en los logs de cada job que el número de versión de Node/Python corresponde a la imagen especificada.

---

## 📝 Paso 2: Services — PostgreSQL para Tests de Integración

```bash
cat > .gitlab-ci.yml << 'YAML_EOF'
# Pipeline con PostgreSQL como service para tests de integración
# Práctica 03 — Semana 05

image: alpine:latest

stages:
  - test

test-con-postgres:
  stage: test
  image: python:3.12-slim
  services:
    - name: postgres:16-alpine
      alias: database          # Hostname para conectarse: "database"
  variables:
    # Variables para el servicio PostgreSQL:
    POSTGRES_DB: testdb
    POSTGRES_USER: testuser
    POSTGRES_PASSWORD: testpass
    POSTGRES_HOST_AUTH_METHOD: trust   # Facilita conexión sin SSL en CI
    # Variables para el código de test:
    DATABASE_URL: "postgresql://testuser:testpass@database:5432/testdb"
  before_script:
    - apt-get update -qq
    - apt-get install -y -qq postgresql-client   # Instalar cliente psql
    # Esperar a que PostgreSQL esté listo:
    - echo "Esperando a que PostgreSQL inicie..."
    - until pg_isready -h database -p 5432 -U testuser; do sleep 2; done
    - echo "✅ PostgreSQL listo"
  script:
    # Conectar y verificar:
    - echo "=== Verificando conexión a PostgreSQL ==="
    - psql "$DATABASE_URL" -c "\l"         # Listar bases de datos
    - psql "$DATABASE_URL" -c "SELECT version();"  # Versión de PostgreSQL
    # Crear una tabla de prueba:
    - psql "$DATABASE_URL" -c "CREATE TABLE users (id SERIAL PRIMARY KEY, name VARCHAR(100), email VARCHAR(200));"
    - psql "$DATABASE_URL" -c "INSERT INTO users (name, email) VALUES ('Alice', 'alice@test.com'), ('Bob', 'bob@test.com');"
    - psql "$DATABASE_URL" -c "SELECT * FROM users;"
    # Verificar count:
    - COUNT=$(psql "$DATABASE_URL" -t -c "SELECT COUNT(*) FROM users;" | tr -d ' ')
    - echo "Registros insertados: $COUNT"
    - test "$COUNT" -eq "2" && echo "✅ Test de integración con DB: PASSED"
YAML_EOF

git add .gitlab-ci.yml
git commit -m "ci: add integration tests with PostgreSQL service"
git push origin main
```

Verificar en los logs:
- El service `postgres:16-alpine` se descarga e inicia
- `pg_isready` espera hasta que PostgreSQL acepta conexiones
- Los comandos SQL se ejecutan exitosamente
- El test de count pasa

---

## 📝 Paso 3: Services Múltiples — PostgreSQL + Redis

```bash
cat > .gitlab-ci.yml << 'YAML_EOF'
image: python:3.12-slim

stages:
  - test

test-con-multiples-services:
  stage: test
  services:
    - name: postgres:16-alpine
      alias: db
    - name: redis:7-alpine
      alias: cache
  variables:
    POSTGRES_DB: apptest
    POSTGRES_USER: appuser
    POSTGRES_PASSWORD: apppass
    DB_URL: "postgresql://appuser:apppass@db:5432/apptest"
    REDIS_URL: "redis://cache:6379"
  before_script:
    - apt-get update -qq && apt-get install -y -qq postgresql-client redis-tools
    - until pg_isready -h db -p 5432 -U appuser; do sleep 2; done
    - until redis-cli -h cache ping | grep -q PONG; do sleep 1; done
    - echo "✅ Todos los services listos"
  script:
    - echo "=== Test con PostgreSQL ==="
    - psql "$DB_URL" -c "CREATE TABLE sessions (id SERIAL, token VARCHAR(255));"
    - psql "$DB_URL" -c "INSERT INTO sessions (token) VALUES ('tok_abc123');"
    - SESSION=$(psql "$DB_URL" -t -c "SELECT token FROM sessions LIMIT 1;" | tr -d ' ')
    - echo "Session token creado: $SESSION"

    - echo ""
    - echo "=== Test con Redis ==="
    - redis-cli -h cache SET "session:$SESSION" "user:42" EX 3600
    - CACHED_USER=$(redis-cli -h cache GET "session:$SESSION")
    - echo "Usuario en cache: $CACHED_USER"
    - redis-cli -h cache TTL "session:$SESSION"
    - echo "✅ Session en DB y en cache — flujo completo OK"

    - echo ""
    - echo "=== Resumen de Conectividad ==="
    - echo "PostgreSQL: $(psql $DB_URL -t -c 'SELECT version()' | head -1)"
    - echo "Redis: $(redis-cli -h cache INFO server | grep redis_version)"
YAML_EOF

git add .gitlab-ci.yml
git commit -m "ci: test with multiple services (PostgreSQL + Redis)"
git push origin main
```

---

## 📝 Paso 4: Verificar Artifacts y Jobs via API

```bash
PROJECT_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects?search=api-gateway" \
  | python3 -c "
import sys,json
projects=[p for p in json.load(sys.stdin) if 'bootcamp-org' in p['path_with_namespace']]
print(projects[0]['id'])
")

# Obtener el último pipeline
PIPELINE_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines?per_page=1" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

echo "Pipeline #$PIPELINE_ID"

# ¿QUÉ HACE?: Lista los jobs con las imágenes Docker que usaron
# ¿POR QUÉ?: Verificar que cada job usó la imagen correcta
# ¿PARA QUÉ?: Debugging cuando un job falla por versión incorrecta del runtime
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines/$PIPELINE_ID/jobs" \
  | python3 -c "
import sys, json
jobs = json.load(sys.stdin)
for j in jobs:
    status_icon = '✅' if j['status'] == 'success' else '❌'
    duration = j.get('duration', 0) or 0
    print(f'{status_icon} {j[\"name\"]:35} {j[\"status\"]:10} {duration:.1f}s')
"
```

---

## 🔧 Troubleshooting

**Service PostgreSQL da "connection refused"**
```
→ El service tarda en iniciar (~5-10 segundos)
→ Asegúrate de tener el loop de espera:
   until pg_isready -h <alias> -p 5432; do sleep 2; done
→ Verificar que el alias en `services` coincide con el hostname usado
```

**"pg_isready: command not found"**
```
→ La imagen base no tiene el cliente PostgreSQL
→ Instalar antes: apt-get install -y postgresql-client
→ O usar wait-on (npm): npx wait-on tcp:db:5432
```

**Error "cannot use Docker services" en el runner**
```
→ El runner puede estar usando el executor Shell, no Docker
→ Verificar: Admin → Runners → el runner debe ser executor: docker
→ Los services solo funcionan con el executor Docker
```

---

## ✅ Checklist de verificación

- [ ] Jobs con diferentes imágenes (Node, Python, Alpine) ejecutados correctamente
- [ ] Service PostgreSQL levantado y accesible desde el job
- [ ] Tests de integración con INSERT + SELECT verificados
- [ ] Pipeline con PostgreSQL + Redis ejecutado correctamente
- [ ] API confirma el estado de todos los jobs

## 📦 Entregables

- [ ] Captura del pipeline con `test-node` y `analisis-python` mostrando sus versiones
- [ ] Captura de los logs de `test-con-postgres` con el `SELECT * FROM users;` visible
- [ ] Captura del pipeline con múltiples services mostrando ambos tests pasados
- [ ] Output del API con la lista de jobs del último pipeline

---

⬅️ **Anterior:** [02 — Stages y Jobs](../02-stages-y-jobs/README.md)
➡️ **Siguiente:** [04 — Artifacts y Cache](../04-artifacts-y-cache/README.md)

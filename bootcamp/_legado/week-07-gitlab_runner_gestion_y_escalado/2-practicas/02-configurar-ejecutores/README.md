# 🔬 Práctica 02 — Comparar Ejecutores Docker vs Shell

**Duración estimada:** 40 minutos
**Dificultad:** ⭐⭐ (Media)

## 🎯 Objetivo

Entender las diferencias prácticas entre Docker Executor y Shell Executor ejecutando los mismos comandos en ambos entornos, observando el nivel de aislamiento, el acceso al sistema, y el comportamiento de los servicios (`services:`).

---

## 📋 Prerrequisitos

- Práctica 01 completada: runner Docker (`bootcamp-docker-runner`) online
- Runner Shell del reto adicional de la Práctica 01 online (`bootcamp-shell-runner`)
- `$GITLAB_TOKEN` y `$GITLAB_PROJECT_ID` exportados

Si no hiciste el reto, instala el runner shell antes de continuar:

```bash
# Verificar runners disponibles
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/runners?status=online" \
  | python3 -c "
import sys, json
for r in json.load(sys.stdin):
    tags = ','.join(r.get('tag_list', []))
    print(f'  #{r[\"id\"]}: {r[\"description\"]} [{tags}]')
"
```

---

## 🐳 Parte 1: Docker Executor — Entorno Aislado

Crear el siguiente pipeline en el proyecto:

```yaml
# .gitlab-ci.yml
stages:
  - analyze

docker-environment:
  stage: analyze
  tags:
    - docker
  image: node:18-alpine
  script:
    # ¿QUÉ HACE?: Inspecciona el entorno del contenedor Docker
    # ¿POR QUÉ?: Verificar aislamiento: hostname único, usuario limitado, OS efímero
    # ¿PARA QUÉ?: Entender qué "ve" el job dentro del contenedor
    - echo "=== IDENTIFICACIÓN DEL CONTENEDOR ==="
    - echo "Hostname: $(hostname)"          # ID aleatorio del contenedor
    - echo "Usuario: $(whoami)"            # gitlab-runner (no root por defecto)
    - echo "UID: $(id -u)"
    - echo "Directorio trabajo: $(pwd)"
    - echo ""
    - echo "=== SISTEMA OPERATIVO ==="
    - cat /etc/os-release | grep PRETTY_NAME
    - echo ""
    - echo "=== HERRAMIENTAS DISPONIBLES ==="
    - node --version                       # disponible porque usamos node:18-alpine
    - npm --version
    - echo ""
    - echo "=== FILESYSTEM RAÍZ ==="
    - ls -la / | head -10                 # filesystem del contenedor, no del host
    - echo ""
    - echo "=== ACCESO A DOCKER DEL HOST ==="
    - ls /var/run/docker.sock 2>/dev/null && echo "Socket Docker: ACCESIBLE" \
      || echo "Socket Docker: NO accesible"
    - echo ""
    - echo "=== VARIABLES DE CI ==="
    - echo "Pipeline: $CI_PIPELINE_ID"
    - echo "Job: $CI_JOB_ID"
    - echo "Runner: $CI_RUNNER_DESCRIPTION"
    - echo "Commit: $CI_COMMIT_SHORT_SHA"
```

Commitear y observar la ejecución en GitLab → CI/CD → Pipelines.

---

## 🖥️ Parte 2: Shell Executor — Acceso Directo al Host

```yaml
# Añadir al .gitlab-ci.yml

shell-environment:
  stage: analyze
  tags:
    - shell
  script:
    # ¿QUÉ HACE?: Inspecciona el entorno del host donde corre el Shell Executor
    # ¿POR QUÉ?: Sin contenedor — los comandos corren directo en la máquina del runner
    # ¿PARA QUÉ?: Entender qué "ve" el job: el sistema real, no un contenedor efímero
    - echo "=== IDENTIFICACIÓN DEL HOST ==="
    - echo "Hostname: $(hostname)"         # nombre real del servidor
    - echo "Usuario: $(whoami)"            # usuario gitlab-runner del SO
    - echo "UID: $(id -u)"
    - echo "Directorio trabajo: $(pwd)"
    - echo ""
    - echo "=== SISTEMA OPERATIVO ==="
    - cat /etc/os-release | grep PRETTY_NAME
    - uname -a
    - echo ""
    - echo "=== PROCESOS DEL HOST ==="
    - ps aux | head -5                    # procesos reales del host
    - echo ""
    - echo "=== FILESYSTEM REAL ==="
    - ls /home                            # directorio home real del host
    - df -h / | tail -1                   # disco real del host
    - echo ""
    - echo "=== ACCESO A DOCKER DEL HOST ==="
    - ls /var/run/docker.sock 2>/dev/null && echo "Socket Docker: ACCESIBLE (puede correr docker)" \
      || echo "Socket Docker: NO accesible"
    - echo ""
    - echo "=== HERRAMIENTAS DEL HOST ==="
    - which node 2>/dev/null && node --version || echo "Node: no instalado en el host"
    - which python3 2>/dev/null && python3 --version || echo "Python3: no instalado"
    - docker --version 2>/dev/null || echo "Docker CLI: no accesible"
```

---

## 🔍 Parte 3: Comparación Directa

Añadir ambos jobs en el mismo pipeline para comparar en paralelo:

```yaml
stages:
  - analyze
  - services-demo

# ─── Job Docker ───────────────────────────────────────────────────────────────
docker-info:
  stage: analyze
  tags: [docker]
  image: alpine:latest
  variables:
    EXECUTOR_TYPE: "DOCKER"
  script:
    - |
      echo "=== $EXECUTOR_TYPE EXECUTOR ==="
      echo "Hostname: $(hostname)"
      echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)"
      echo "Usuario: $(whoami)"
      echo "UID: $(id -u)"
      echo "Uptime host vs contenedor: $(uptime)"
      echo "Estado proceso init: $(cat /proc/1/comm)"

# ─── Job Shell ────────────────────────────────────────────────────────────────
shell-info:
  stage: analyze
  tags: [shell]
  variables:
    EXECUTOR_TYPE: "SHELL"
  script:
    - |
      echo "=== $EXECUTOR_TYPE EXECUTOR ==="
      echo "Hostname: $(hostname)"
      echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)"
      echo "Usuario: $(whoami)"
      echo "UID: $(id -u)"
      echo "Uptime host: $(uptime)"
      echo "Estado proceso init: $(cat /proc/1/comm)"

# ─── Services con Docker Executor ─────────────────────────────────────────────
docker-with-postgres:
  stage: services-demo
  tags: [docker]
  image: alpine:latest
  services:
    - name: postgres:15-alpine
      alias: db
  variables:
    POSTGRES_DB: testdb
    POSTGRES_USER: tester
    POSTGRES_PASSWORD: testpass123
  script:
    # ¿QUÉ HACE?: Se conecta a PostgreSQL vía network del contenedor
    # ¿POR QUÉ?: Docker Executor levanta servicios como contenedores adicionales en la misma red
    # ¿PARA QUÉ?: Tests de integración sin PostgreSQL instalado en el host
    - apk add --no-cache postgresql-client
    - echo "Esperando que PostgreSQL esté listo..."
    - until pg_isready -h db -U tester; do sleep 1; done
    - echo "PostgreSQL listo. Ejecutando query:"
    - psql "host=db user=tester dbname=testdb password=testpass123" \
        -c "SELECT version();" \
        -c "CREATE TABLE demo (id SERIAL, name TEXT);" \
        -c "INSERT INTO demo(name) VALUES ('test-docker-executor');" \
        -c "SELECT * FROM demo;"
    - echo "Conexión a services: EXITOSA"
  needs: [docker-info]
```

---

## 📊 Parte 4: Analizar los Resultados

Al completar los jobs, comparar en la UI de GitLab (CI/CD → Pipelines → el pipeline):

```bash
# ¿QUÉ HACE?: Descarga los logs de ambos jobs para comparar side-by-side
# ¿POR QUÉ?: Ver las diferencias de entorno directamente en los logs
# ¿PARA QUÉ?: Documentar las diferencias para la entrega

# Obtener IDs de los jobs
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/jobs?per_page=10" \
  | python3 -c "
import sys, json
jobs = json.load(sys.stdin)
for j in jobs:
    tags = ','.join(j.get('tag_list', []))
    print(f'#{j[\"id\"]:5} {j[\"name\"]:<30} {j[\"status\"]:<10} {j.get(\"runner\",{}).get(\"description\",\"?\"):<25}')
"
```

**Tabla de comparación esperada** (completar con los valores observados):

| Característica | Docker Executor | Shell Executor |
|---------------|----------------|----------------|
| `hostname` | ID aleatorio del contenedor | Nombre del servidor real |
| `whoami` | `gitlab-runner` (en contenedor) | `gitlab-runner` (en host) |
| OS | Alpine Linux (imagen del job) | Ubuntu/Debian del host |
| `proc/1/comm` | `sh` (proceso dentro del contenedor) | `systemd` (init del host) |
| Docker socket | Configurable (si se montó) | Accesible directamente |
| Services (PostgreSQL) | Funciona nativamente | Requiere instalación manual |
| Estado entre jobs | Contenedor destruido — entorno limpio | Archivos en /tmp persisten |

---

## 🧹 Verificar Aislamiento: Sin Estado entre Jobs

```yaml
# Añadir estos dos jobs para probar el aislamiento
stages:
  - write
  - read

write-file-docker:
  stage: write
  tags: [docker]
  image: alpine:latest
  script:
    - echo "Contenido creado en el job write" > /tmp/test-isolation.txt
    - cat /tmp/test-isolation.txt
    - echo "Archivo creado en /tmp"

read-file-docker:
  stage: read
  tags: [docker]
  image: alpine:latest
  script:
    # ¿QUÉ HACE?: Intenta leer el archivo creado en el job anterior
    # ¿POR QUÉ?: Demostrar que el Docker Executor destruye el contenedor entre jobs
    # ¿PARA QUÉ?: Confirmar el aislamiento — el archivo NO debería existir
    - ls /tmp/test-isolation.txt 2>/dev/null \
      && echo "ARCHIVO EXISTE (sin aislamiento)" \
      || echo "ARCHIVO NO EXISTE (aislamiento correcto)"
```

Con Docker Executor, el `read-file-docker` imprime "ARCHIVO NO EXISTE" — cada job empieza en un contenedor limpio. Con Shell Executor, el archivo sí persiste entre jobs del mismo runner.

---

## ✅ Checklist de verificación

- [ ] `docker-info` ejecutado en runner con tags `[docker]`
- [ ] `shell-info` ejecutado en runner con tags `[shell]`
- [ ] Los hostnames son diferentes (contenedor vs host real)
- [ ] `docker-with-postgres` conecta exitosamente a PostgreSQL via `services:`
- [ ] `read-file-docker` confirma aislamiento (archivo no existe)
- [ ] Completada la tabla de comparación con valores reales observados

---

## 🏆 Reto adicional

Probar DinD (Docker-in-Docker) en el runner Docker y comparar con construir en Shell:

```yaml
# Solo funciona si el runner tiene privileged = true en config.toml
build-docker-image:
  tags: [docker]
  image: docker:24-cli
  services:
    - docker:24-dind
  variables:
    DOCKER_HOST: tcp://docker:2375
    DOCKER_TLS_CERTDIR: ""
  script:
    - docker version
    - docker build -t test-image:latest - <<'DOCKERFILE'
      FROM alpine:latest
      RUN echo "imagen de prueba" > /mensaje.txt
      CMD cat /mensaje.txt
      DOCKERFILE
    - docker run --rm test-image:latest
```

---

⬅️ **Práctica anterior:** [01 — Instalar Runner](../01-instalar-runner/README.md)
➡️ **Siguiente práctica:** [03 — Tags y Routing](../03-tags-y-routing/README.md)

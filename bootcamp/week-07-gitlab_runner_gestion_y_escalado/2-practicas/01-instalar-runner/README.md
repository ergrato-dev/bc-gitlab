# 🔬 Práctica 01 — Instalar y Registrar GitLab Runner

**Duración estimada:** 35 minutos
**Dificultad:** ⭐⭐ (Media)

## 🎯 Objetivo

Instalar GitLab Runner como contenedor Docker, registrarlo en la instancia GitLab CE, verificar que está online, y ejecutar un primer job para confirmar que el runner funciona end-to-end.

---

## 📋 Prerrequisitos

- Instancia GitLab CE funcionando en `http://localhost`
- Docker instalado y corriendo en el host
- `$GITLAB_TOKEN` exportado (Personal Access Token con scope `api`)
- `$GITLAB_PROJECT_ID` del proyecto de práctica

```bash
# Verificar que Docker está operativo
docker --version
docker ps --format "table {{.Names}}\t{{.Status}}" | head -5

# Verificar token de GitLab
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/user" \
  | python3 -c "import sys, json; u=json.load(sys.stdin); print(f'Autenticado como: {u[\"username\"]}')"
```

---

## 🚀 Paso 1: Obtener Token de Autenticación del Runner

Desde GitLab 15.6+, usamos runner authentication tokens (no registration tokens legacy).

```bash
# ¿QUÉ HACE?: Crea un runner authentication token via API
# ¿POR QUÉ?: Es el método moderno y más seguro (registration tokens están deprecados)
# ¿PARA QUÉ?: Obtener el token antes de instalar el runner

curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "runner_type": "instance_type",
    "description": "bootcamp-docker-runner",
    "tag_list": ["docker","linux","bootcamp"],
    "run_untagged": true,
    "access_level": "not_protected"
  }' \
  "http://localhost/api/v4/user/runners" \
  | python3 -c "
import sys, json
r = json.load(sys.stdin)
if 'token' in r:
    print(f'Runner creado exitosamente:')
    print(f'  ID: {r[\"id\"]}')
    print(f'  Token: {r[\"token\"]}')
    print()
    print(f'Exporta: export RUNNER_TOKEN=\"{r[\"token\"]}\"')
else:
    print(f'Error: {r}')
"
```

> **Alternativa via UI:** Admin Area → CI/CD → Runners → New instance runner → copia el token (`glrt-XXXXXXXXXX`)

```bash
# Guardar el token para usarlo en el registro
export RUNNER_TOKEN="glrt-XXXXXXXXXX"   # ← reemplazar con el token real
```

---

## 🐳 Paso 2: Instalar el Runner como Contenedor Docker

```bash
# ¿QUÉ HACE?: Arranca el runner como contenedor persistente con acceso al Docker socket
# ¿POR QUÉ?: Necesita el socket para crear contenedores para cada job (Docker executor)
# ¿PARA QUÉ?: Runner que sobrevive reinicios del host gracias a --restart always

# Crear directorio para la configuración persistente
sudo mkdir -p /srv/gitlab-runner/config

# Iniciar el contenedor del runner
docker run -d \
  --name gitlab-runner \
  --restart always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /srv/gitlab-runner/config:/etc/gitlab-runner \
  gitlab/gitlab-runner:alpine

# Verificar que arrancó:
docker ps --filter name=gitlab-runner \
  --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
```

**Salida esperada:**
```
NAMES           STATUS          IMAGE
gitlab-runner   Up 3 seconds    gitlab/gitlab-runner:alpine
```

---

## 📋 Paso 3: Registrar el Runner (No Interactivo)

```bash
# ¿QUÉ HACE?: Registra el runner en GitLab usando el token creado en el Paso 1
# ¿POR QUÉ?: El modo no-interactivo funciona en scripts y pipelines de infra
# ¿PARA QUÉ?: Vincular este runner con la instancia GitLab para recibir jobs

docker exec gitlab-runner gitlab-runner register \
  --non-interactive \
  --url "http://localhost" \
  --token "$RUNNER_TOKEN" \
  --executor "docker" \
  --docker-image "alpine:latest" \
  --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
  --docker-volumes "/cache" \
  --docker-pull-policy "if-not-present" \
  --tag-list "docker,linux,bootcamp" \
  --description "bootcamp-docker-runner" \
  --run-untagged "true"
```

Verificar que el registro fue exitoso:

```bash
# ¿QUÉ HACE?: Lista los runners configurados en el archivo config.toml
docker exec gitlab-runner gitlab-runner list
```

**Salida esperada:**
```
Listing configured runners                          ConfigFile=/etc/gitlab-runner/config.toml
bootcamp-docker-runner                              Executor=docker Token=glrt-XXXX URL=http://localhost
```

---

## 📄 Paso 4: Inspeccionar el `config.toml` Generado

```bash
# ¿QUÉ HACE?: Muestra el config.toml que el registro creó automáticamente
# ¿POR QUÉ?: Entender qué fue configurado y verificar los valores
# ¿PARA QUÉ?: Base para futuras modificaciones manuales del archivo

sudo cat /srv/gitlab-runner/config/config.toml
```

Deberías ver algo como:
```toml
concurrent = 1
check_interval = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "bootcamp-docker-runner"
  url = "http://localhost"
  token = "glrt-XXXXXXXXXX"
  executor = "docker"
  [runners.docker]
    tls_verify = false
    image = "alpine:latest"
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]
    pull_policy = ["if-not-present"]
    shm_size = 0
    network_mode = "bridge"
```

---

## 🌐 Paso 5: Verificar en la UI y via API

```bash
# ¿QUÉ HACE?: Consulta los runners online de la instancia
# ¿POR QUÉ?: Confirmar que el runner está conectado y visible para GitLab
# ¿PARA QUÉ?: Diagnóstico de conectividad antes de ejecutar jobs

curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/runners?status=online&per_page=10" \
  | python3 -c "
import sys, json
runners = json.load(sys.stdin)
print(f'Runners online: {len(runners)}')
for r in runners:
    tags = ','.join(r.get('tag_list', []))
    print(f'  #{r[\"id\"]}: {r[\"description\"]} [{tags}] — {r[\"status\"]}')
"
```

**En la UI de GitLab:**
- Ir a Admin Area → CI/CD → Runners
- El runner `bootcamp-docker-runner` debe aparecer con ● verde

---

## ✈️ Paso 6: Ejecutar el Primer Job

Crear un `.gitlab-ci.yml` mínimo en el proyecto para confirmar que el runner ejecuta jobs:

```yaml
# ¿QUÉ HACE?: Pipeline mínimo de verificación del runner
# ¿POR QUÉ?: Un runner online pero que no ejecuta jobs no sirve
# ¿PARA QUÉ?: Confirmar el flujo completo: GitLab → runner → job → resultado

stages:
  - verify

verify-runner:
  stage: verify
  tags:
    - docker
    - bootcamp
  image: alpine:latest
  script:
    - echo "=== INFORMACIÓN DEL RUNNER ==="
    - echo "Hostname del contenedor: $(hostname)"
    - echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)"
    - echo "Usuario: $(whoami)"
    - echo "Directorio: $(pwd)"
    - echo "Variables de CI:"
    - echo "  Pipeline ID: $CI_PIPELINE_ID"
    - echo "  Runner: $CI_RUNNER_DESCRIPTION"
    - echo "  Executor: $CI_RUNNER_EXECUTABLE_ARCH"
    - echo "=== RUNNER FUNCIONANDO CORRECTAMENTE ==="
```

```bash
# Commitear el .gitlab-ci.yml al proyecto y disparar el pipeline
# Verificar via API que el job se ejecutó

curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/jobs?scope=success&per_page=5" \
  | python3 -c "
import sys, json
jobs = json.load(sys.stdin)
if jobs:
    j = jobs[0]
    print(f'Último job exitoso:')
    print(f'  ID: #{j[\"id\"]} — {j[\"name\"]}')
    print(f'  Runner: {j.get(\"runner\", {}).get(\"description\", \"?\")}')
    print(f'  Estado: {j[\"status\"]}')
    print(f'  Duración: {j.get(\"duration\", 0):.1f}s')
else:
    print('No se encontraron jobs exitosos aún')
"
```

---

## 🔄 Paso 7: Ver Logs del Runner

```bash
# ¿QUÉ HACE?: Muestra los logs del runner en tiempo real
# ¿POR QUÉ?: Para diagnóstico si los jobs no se ejecutan como se espera
# ¿PARA QUÉ?: Debugging de problemas de conectividad o configuración

docker logs gitlab-runner --tail 30 --follow
# Ctrl+C para salir del --follow

# Buscar errores específicos:
docker logs gitlab-runner 2>&1 | grep -E "ERROR|FATAL|error" | tail -10
```

---

## 🧹 Paso 8 (Opcional): Aumentar Concurrencia

Por defecto `concurrent = 1` (un job a la vez). Editar para permitir más:

```bash
# ¿QUÉ HACE?: Modifica concurrent en config.toml para permitir 4 jobs simultáneos
# ¿POR QUÉ?: El bootcamp necesita correr múltiples pipelines sin esperas
# ¿PARA QUÉ?: Aprovechar los recursos del host en prácticas con múltiples proyectos

sudo sed -i 's/^concurrent = 1/concurrent = 4/' /srv/gitlab-runner/config/config.toml

# Reiniciar para aplicar el cambio en concurrent (parámetro global):
docker restart gitlab-runner

# Verificar:
sudo grep "concurrent" /srv/gitlab-runner/config/config.toml
```

---

## ✅ Checklist de verificación

- [ ] `docker ps` muestra `gitlab-runner` con status `Up`
- [ ] Runner aparece en Admin Area → CI/CD → Runners con ● verde
- [ ] `docker exec gitlab-runner gitlab-runner list` muestra el runner
- [ ] API devuelve el runner en `/api/v4/runners?status=online`
- [ ] Job `verify-runner` ejecutado exitosamente en el proyecto
- [ ] Logs del runner muestran conexión exitosa sin errores

---

## 🏆 Reto adicional

Registrar un segundo runner con executor **Shell** para poder comparar en la Práctica 02:

```bash
# Crear token para el runner shell
export RUNNER_TOKEN_SHELL=$(curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"runner_type":"instance_type","description":"bootcamp-shell-runner","tag_list":["shell","linux","deploy"],"run_untagged":false}' \
  "http://localhost/api/v4/user/runners" \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('token','error'))")

echo "Shell runner token: $RUNNER_TOKEN_SHELL"

# Instalar como segundo contenedor
docker run -d \
  --name gitlab-runner-shell \
  --restart always \
  -v /srv/gitlab-runner-shell/config:/etc/gitlab-runner \
  gitlab/gitlab-runner:alpine

# Registrar con executor shell
docker exec gitlab-runner-shell gitlab-runner register \
  --non-interactive \
  --url "http://localhost" \
  --token "$RUNNER_TOKEN_SHELL" \
  --executor "shell" \
  --tag-list "shell,linux,deploy" \
  --description "bootcamp-shell-runner" \
  --run-untagged "false"
```

---

⬅️ **Prácticas:** [Índice de prácticas](../README.md)
➡️ **Siguiente práctica:** [02 — Configurar Ejecutores](../02-configurar-ejecutores/README.md)

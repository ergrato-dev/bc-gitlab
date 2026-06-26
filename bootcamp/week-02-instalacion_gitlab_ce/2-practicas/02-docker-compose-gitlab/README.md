# 🛠️ Práctica 02 — Levantar GitLab CE con Docker Compose

⏱️ **Tiempo estimado:** 60 minutos (incluye tiempo de espera del primer arranque)  
⭐ **Dificultad:** Básico-Intermedio  
📋 **Prerrequisitos:** Práctica 01 completada — Docker instalado, repo clonado, puertos libres

---

## 🎯 Objetivo

Levantar la instancia de GitLab CE del bootcamp, monitorear el arranque inicial, obtener la contraseña de root y verificar el acceso web.

---

## Paso 1: Posicionarte en la raíz del repositorio

```bash
# ¿QUÉ HACE?: Navega al directorio raíz del repositorio del bootcamp
# ¿POR QUÉ?: El docker-compose.yml está en la raíz, no en una subcarpeta
# ¿PARA QUÉ?: Asegurar que docker compose encuentre el archivo correcto
cd ~/bc-gitlab   # (o la ruta donde clonaste el repo)

# Verificar que estás en el lugar correcto
ls docker-compose.yml .env
```

✅ **Output esperado:** Los dos archivos aparecen sin error.

---

## Paso 2: Revisar la estructura del docker-compose.yml

Antes de ejecutar, familiarízate con lo que vas a levantar:

```bash
# ¿QUÉ HACE?: Muestra el archivo docker-compose.yml completo
# ¿POR QUÉ?: Entender qué servicios se van a crear y su configuración
# ¿PARA QUÉ?: No ejecutar comandos "a ciegas" — comprender antes de actuar
cat docker-compose.yml | grep -E "^  [a-z]|image:|container_name:|ports:" | head -40
```

Deberías ver los 5 servicios: `gitlab`, `gitlab-runner`, `registry-cache`, `prometheus`, `grafana`.

---

## Paso 3: Levantar los servicios base

```bash
# ¿QUÉ HACE?: Crea los volúmenes, la red y levanta los contenedores en segundo plano
# ¿POR QUÉ?: Sin -d los logs bloquean la terminal y Ctrl+C detendría GitLab
# ¿PARA QUÉ?: Iniciar GitLab CE y sus servicios asociados de forma persistente
docker compose up -d
```

✅ **Output esperado:**
```
[+] Running 7/7
 ✔ Network bc-gitlab-network         Created
 ✔ Volume "bc-gitlab-config"         Created
 ✔ Volume "bc-gitlab-logs"           Created
 ✔ Volume "bc-gitlab-data"           Created
 ✔ Container gitlab                  Started
 ✔ Container registry-cache          Started
 ✔ Container gitlab-runner           Waiting (esperando healthcheck de gitlab)
```

> El `gitlab-runner` aparece como "Waiting" porque tiene `depends_on: condition: service_healthy` — arrancará automáticamente cuando GitLab esté listo.

---

## Paso 4: Monitorear el primer inicio

```bash
# ¿QUÉ HACE?: Sigue los logs del contenedor gitlab en tiempo real
# ¿POR QUÉ?: El primer inicio ejecuta migraciones de BD que pueden tardar 5-10 minutos
# ¿PARA QUÉ?: Ver el progreso y detectar si algo sale mal
docker compose logs -f gitlab
```

### ¿Qué buscar en los logs?

| Mensaje en los logs | Qué significa |
|--------------------|---------------|
| `Configuring GitLab...` | Inicio del proceso de configuración |
| `Running migrations...` | Aplicando cambios a la base de datos (puede tardar) |
| `Starting gitlab-puma` | El servidor web Ruby está arrancando |
| `Starting gitlab-sidekiq` | El procesador de jobs está arrancando |
| `gitlab Reconfigured!` | ✅ Configuración completa — GitLab listo |

Cuando veas `gitlab Reconfigured!`, presiona `Ctrl+C` para dejar de seguir los logs. GitLab sigue corriendo en segundo plano.

⏱️ **Tiempo de espera típico:**
- Máquina con 8 GB RAM + SSD: ~5 minutos
- Máquina con 4 GB RAM + HDD: ~10-15 minutos

---

## Paso 5: Verificar el estado con el healthcheck

```bash
# ¿QUÉ HACE?: Muestra el estado de todos los contenedores definidos en el compose
# ¿POR QUÉ?: Incluye el estado del healthcheck: starting, healthy o unhealthy
# ¿PARA QUÉ?: Confirmar que GitLab pasó el healthcheck antes de intentar acceder
docker compose ps
```

✅ **Output esperado (cuando está listo):**
```
NAME              IMAGE                           COMMAND   STATUS
gitlab            gitlab/gitlab-ce:17-latest      ...       Up 8 minutes (healthy)
gitlab-runner     gitlab/gitlab-runner:alpine     ...       Up 3 minutes
registry-cache    registry:2                      ...       Up 8 minutes
```

⚠️ Si ves `(health: starting)`, GitLab aún no está listo. Espera 2-3 minutos más y vuelve a ejecutar.

⚠️ Si ves `(unhealthy)`, revisa los logs: `docker compose logs gitlab --tail 30`.

---

## Paso 6: Obtener la contraseña root inicial

```bash
# ¿QUÉ HACE?: Busca la contraseña dentro del archivo de contraseña inicial
# ¿POR QUÉ?: GitLab genera una contraseña aleatoria si no usas GITLAB_ROOT_PASSWORD
# ¿PARA QUÉ?: Necesitamos esta contraseña para el primer login
docker compose exec gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

✅ **Output esperado:**
```
Password: ABCxyz123456789
```

📋 **Guarda esta contraseña** en un lugar seguro. El archivo se elimina automáticamente a las 24 horas.

> Si configuraste `GITLAB_ROOT_PASSWORD` en tu `.env`, usa esa contraseña directamente.

---

## Paso 7: Verificar acceso web

```bash
# ¿QUÉ HACE?: Hace una petición HTTP y muestra el código de respuesta
# ¿POR QUÉ?: Un 302 significa que GitLab responde y redirige al login
# ¿PARA QUÉ?: Confirmar acceso web desde la línea de comandos
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost
```

✅ **Output esperado:** `HTTP 302` (redirección al login) o `HTTP 200`.

Ahora abre el navegador:

1. Ve a `http://localhost`
2. Verás la página de login de GitLab
3. Introduce `root` como usuario y la contraseña del paso anterior
4. ✅ Deberías ver el dashboard de GitLab CE

---

## Paso 8: Explorar la estructura del proyecto

Ahora que GitLab está corriendo, revisemos qué levantamos exactamente:

```bash
# ¿QUÉ HACE?: Lista los volúmenes que Docker creó para el bootcamp
# ¿POR QUÉ?: Confirmar que los volúmenes tienen los nombres explícitos correctos
# ¿PARA QUÉ?: Verificar que bc-gitlab-data existe (donde están los repos y la BD)
docker volume ls | grep bc-gitlab

# ¿QUÉ HACE?: Muestra información detallada de la red de Docker del bootcamp
# ¿POR QUÉ?: Confirma que los contenedores están en la misma red y pueden comunicarse
# ¿PARA QUÉ?: Entender la topología de red del entorno
docker network inspect bc-gitlab-network | grep -E "Name|IPv4"
```

---

## Paso 9: Explorar los servicios internos de GitLab

```bash
# ¿QUÉ HACE?: Muestra el estado de todos los servicios internos de GitLab
# ¿POR QUÉ?: GitLab corre ~15 servicios dentro del contenedor (Puma, Sidekiq, PostgreSQL...)
# ¿PARA QUÉ?: Confirmar que todos los servicios están activos (run:) y no en error
docker compose exec gitlab gitlab-ctl status
```

✅ **Output esperado:** Todos los servicios en estado `run:`. Algunos servicios tardan más y pueden aparecer en `down:` durante los primeros minutos — vuelve a ejecutar en 2 minutos.

---

## Paso 10 (Opcional): Levantar el perfil de monitoreo

```bash
# ¿QUÉ HACE?: Levanta Prometheus y Grafana además de los servicios base
# ¿POR QUÉ?: Estos servicios tienen el profile "monitoring" y no arrancan por defecto
# ¿PARA QUÉ?: Ver métricas de GitLab en dashboards visuales
docker compose --profile monitoring up -d

# Verificar que arrancan
docker compose ps | grep -E "prometheus|grafana"
```

Una vez activos, accede a:
- **Prometheus:** `http://localhost:9090`
- **Grafana:** `http://localhost:3000` (usuario: `admin`, contraseña: la de `.env`)

---

## 🚨 Troubleshooting

| Síntoma | Causa probable | Solución |
|---------|---------------|----------|
| `502 Bad Gateway` inmediatamente | GitLab aún iniciando | Esperar y monitorear logs |
| `Connection refused` en port 80 | Contenedor no arrancó | `docker compose logs gitlab --tail 20` |
| Healthcheck siempre en `starting` | Primer inicio muy lento | Esperar hasta 15 min; verificar RAM |
| `unhealthy` después de 10 min | OOM o error de config | Ver logs, verificar RAM con `docker stats` |
| Puerto 80 ya está en uso | Apache/Nginx en el host | `sudo systemctl stop nginx` o cambiar `GITLAB_HTTP_PORT` en `.env` |
| `initial_root_password: No such file` | Pasaron +24h del primer inicio | Usar la contraseña de `.env` o resetear por Rails console |

---

## 📝 Entregable

El entregable de esta práctica es el output de los siguientes comandos en un estado "sano":

```bash
# 1. Estado de los contenedores
docker compose ps

# 2. Estado de servicios internos
docker compose exec gitlab gitlab-ctl status

# 3. Verificación HTTP
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost
```

Además, una captura de pantalla del dashboard de GitLab CE en el navegador con sesión iniciada como `root`.

---

➡️ **Siguiente práctica:** [03 — Configuración post-instalación](../03-configuracion-post-instalacion/README.md)

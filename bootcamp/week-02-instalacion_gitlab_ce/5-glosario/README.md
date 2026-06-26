# 📖 Glosario — Semana 02: Instalación de GitLab CE

Términos técnicos clave de la semana, con definiciones, ejemplos y referencias cruzadas.

---

## Índice alfabético

| Término | Letra |
|---------|-------|
| [Backup](#backup) | B |
| [Bind Mount](#bind-mount) | B |
| [Container (contenedor)](#container) | C |
| [Docker Compose](#docker-compose) | D |
| [Docker Volume](#docker-volume) | D |
| [GITLAB_OMNIBUS_CONFIG](#gitlab_omnibus_config) | G |
| [GitLab Runner](#gitlab-runner) | G |
| [gitlab-ctl](#gitlab-ctl) | G |
| [gitlab-rake](#gitlab-rake) | G |
| [Healthcheck](#healthcheck) | H |
| [Image (imagen Docker)](#image) | I |
| [Named Volume](#named-volume) | N |
| [Omnibus](#omnibus) | O |
| [Profile (Docker Compose)](#profile) | P |
| [Restore](#restore) | R |
| [Secrets (gitlab-secrets.json)](#secrets) | S |
| [Service (Docker Compose)](#service) | S |
| [shm_size](#shm_size) | S |
| [Sidekiq](#sidekiq) | S |
| [STRATEGY=copy](#strategycopy) | S |
| [Volume (volumen)](#volume) | V |

---

## Backup

**Definición:** Copia de seguridad completa del estado de una instancia de GitLab, generada por la herramienta integrada `gitlab-backup`. Incluye la base de datos PostgreSQL, repositorios Git, uploads, artifacts de CI/CD, objetos LFS y más.

**Ejemplo:**

```bash
# ¿QUÉ HACE?: Crea un backup completo con la estrategia de copia segura
# ¿POR QUÉ?: STRATEGY=copy evita inconsistencias en instancias activas
# ¿PARA QUÉ?: Generar un .tar que permite restaurar el estado completo de GitLab
docker compose exec gitlab gitlab-backup create STRATEGY=copy
```

El archivo generado tiene este formato de nombre: `TIMESTAMP_FECHA_VERSION_gitlab_backup.tar`

**Relacionados:** [Restore](#restore), [Secrets](#secrets), [STRATEGY=copy](#strategycopy)

---

## Bind Mount

**Definición:** Tipo de montaje de almacenamiento en Docker donde se mapea directamente una ruta del sistema de archivos del host al contenedor. A diferencia de los Named Volumes, Docker no gestiona el ciclo de vida del bind mount.

**Ejemplo:**

```yaml
# Bind mount — monta /home/user/data del host en /data del contenedor
volumes:
  - /home/user/data:/data
```

**Cuándo usarlo:** Para compartir el socket de Docker (`/var/run/docker.sock`) o archivos de configuración que editas directamente en el host (como `prometheus.yml`).

**Para GitLab:** No recomendado para los datos principales (usa Named Volumes en su lugar) — los permisos son más complejos de gestionar.

**Relacionados:** [Named Volume](#named-volume), [Docker Volume](#docker-volume)

---

## Container

**Definición:** Instancia ejecutable de una imagen Docker. Es un proceso aislado que tiene su propio sistema de archivos, red y espacio de procesos, pero comparte el kernel del sistema operativo anfitrión.

**Ejemplo:**

```bash
# ¿QUÉ HACE?: Muestra todos los contenedores del compose con su estado
# ¿POR QUÉ?: Cada servicio (gitlab, runner, prometheus) es un contenedor separado
# ¿PARA QUÉ?: Verificar cuáles están corriendo y el resultado del healthcheck
docker compose ps
```

**Diferencia con VM:** Un contenedor comparte el kernel del host (más liviano). Una VM tiene su propio kernel (más aislado pero más pesado).

**Relacionados:** [Image](#image), [Service](#service)

---

## Docker Compose

**Definición:** Herramienta para definir y ejecutar aplicaciones multi-contenedor. Lee un archivo `docker-compose.yml` y gestiona el ciclo de vida de todos los servicios definidos como una unidad.

**Ejemplo:**

```bash
# Levantar todos los servicios en segundo plano
docker compose up -d

# Detener sin eliminar volúmenes
docker compose down

# Detener y eliminar volúmenes (DESTRUCTIVO)
docker compose down -v
```

**Docker Compose V2 vs V1:** El bootcamp usa V2 (plugin integrado al CLI de Docker). Se invoca con `docker compose` (sin guion). La versión V1 usaba `docker-compose` (con guion) y está deprecada.

**Relacionados:** [Service](#service), [Profile](#profile), [Named Volume](#named-volume)

---

## Docker Volume

**Definición:** Mecanismo de persistencia de datos gestionado por Docker, completamente independiente del ciclo de vida del contenedor. Los datos en un volumen sobreviven aunque el contenedor se destruya, se actualice o se recree.

**Tipos de volúmenes:**

| Tipo | Ejemplo | Gestión |
|------|---------|---------|
| Named Volume | `bc-gitlab-data:/var/opt/gitlab` | Por Docker (recomendado) |
| Bind Mount | `/host/path:/container/path` | Por el usuario |
| Anonymous Volume | `- /var/opt/gitlab` | Por Docker (nombre auto-generado) |

**Relacionados:** [Named Volume](#named-volume), [Bind Mount](#bind-mount)

---

## GITLAB_OMNIBUS_CONFIG

**Definición:** Variable de entorno especial de la imagen Docker de GitLab CE. Su contenido se inyecta en el archivo `/etc/gitlab/gitlab.rb` durante el arranque del contenedor, sin necesidad de editar archivos directamente.

**Ejemplo:**

```yaml
environment:
  GITLAB_OMNIBUS_CONFIG: |
    external_url 'http://localhost'
    gitlab_rails['gitlab_shell_ssh_port'] = 2224
    gitlab_rails['usage_ping_enabled'] = false
    puma['worker_processes'] = 2
```

**Por qué es importante:** Es la única forma de configurar GitLab CE en Docker sin entrar al contenedor a editar archivos. Todo lo que puede ir en `gitlab.rb` puede configurarse aquí.

**Relacionados:** [Omnibus](#omnibus), [Service](#service)

---

## GitLab Runner

**Definición:** Agente que ejecuta los trabajos (jobs) definidos en los pipelines de CI/CD de GitLab. Escucha instrucciones del servidor GitLab y ejecuta los scripts en distintos entornos: Docker, shell, Kubernetes, etc.

**En el bootcamp:** El runner corre en un contenedor Docker separado y se registra en la instancia GitLab local. Para registrarlo se usa el token `glrt-XXXX` (no el registration-token, eliminado en GitLab 17.0).

**Ejemplo:**

```bash
# Registrar el runner con el token nuevo (GitLab 17+)
# ¿QUÉ HACE?: Registra el runner con un token de autenticación
# ¿POR QUÉ?: --token glrt-XXXX es el nuevo formato (desde GitLab 17.0)
# ¿PARA QUÉ?: Conectar el runner a la instancia para ejecutar pipelines
docker compose exec gitlab-runner gitlab-runner register \
  --url http://gitlab \
  --token glrt-XXXXXXXXXXXXXXXXXX \
  --executor docker \
  --docker-image alpine:latest
```

**Relacionados:** [Service](#service), [Container](#container)

---

## gitlab-ctl

**Definición:** Herramienta de línea de comandos de GitLab Omnibus para gestionar los servicios internos del contenedor (Puma, Sidekiq, PostgreSQL, Redis, Gitaly, Nginx, etc.).

**Comandos principales:**

```bash
# ¿QUÉ HACE?: Muestra el estado de todos los servicios internos
docker compose exec gitlab gitlab-ctl status

# ¿QUÉ HACE?: Reinicia todos los servicios internos
docker compose exec gitlab gitlab-ctl restart

# ¿QUÉ HACE?: Reinicia un servicio específico
docker compose exec gitlab gitlab-ctl restart puma

# ¿QUÉ HACE?: Aplica los cambios de gitlab.rb (reconfigura)
docker compose exec gitlab gitlab-ctl reconfigure

# ¿QUÉ HACE?: Sigue los logs de un servicio en tiempo real
docker compose exec gitlab gitlab-ctl tail nginx
docker compose exec gitlab gitlab-ctl tail postgresql
```

**Relacionados:** [Omnibus](#omnibus), [Sidekiq](#sidekiq)

---

## gitlab-rake

**Definición:** Interfaz de tareas de administración de GitLab basada en Rake (el sistema de tareas de Ruby). Permite ejecutar operaciones de mantenimiento, diagnóstico, importación/exportación y más.

**Comandos más usados:**

```bash
# ¿QUÉ HACE?: Ejecuta el check oficial que valida ~20 aspectos del sistema
# ¿PARA QUÉ?: Detectar problemas de permisos, config y conectividad
docker compose exec gitlab gitlab-rake gitlab:check SANITIZE=true

# ¿QUÉ HACE?: Muestra la versión de GitLab instalada
docker compose exec gitlab gitlab-rake gitlab:env:info

# ¿QUÉ HACE?: Crea y reconstruye el archivo authorized_keys de SSH
docker compose exec gitlab gitlab-rake gitlab:shell:setup
```

**Relacionados:** [gitlab-ctl](#gitlab-ctl)

---

## Healthcheck

**Definición:** Mecanismo de Docker para verificar periódicamente si un contenedor está funcionando correctamente. Define un comando de prueba, intervalo, timeout y número de reintentos. El resultado puede ser `starting`, `healthy` o `unhealthy`.

**En el bootcamp:**

```yaml
healthcheck:
  test: curl -f http://localhost/-/health || exit 1
  interval: 60s      # Verificar cada 60 segundos
  timeout: 30s       # Timeout de cada verificación
  retries: 10        # Hasta 10 fallos antes de declarar "unhealthy"
  start_period: 300s # Esperar 5 minutos antes de empezar a contar fallos
```

**Por qué importa:** El `gitlab-runner` tiene `depends_on: condition: service_healthy` — no arrancará hasta que el healthcheck de `gitlab` pase. Esto evita que el runner intente conectarse a GitLab antes de que esté listo.

**Relacionados:** [Container](#container), [Service](#service)

---

## Image

**Definición:** Plantilla inmutable de solo lectura que contiene el sistema de archivos, dependencias y configuración inicial de un contenedor. Las imágenes se construyen a partir de un `Dockerfile` o se descargan de un registry (como Docker Hub).

**En el bootcamp:**

```yaml
image: gitlab/gitlab-ce:17-latest   # Imagen oficial de GitLab CE, rama 17
image: gitlab/gitlab-runner:alpine-latest  # Runner con Alpine Linux
image: prom/prometheus:latest              # Prometheus
```

**Diferencia imagen vs contenedor:** La imagen es el "molde", el contenedor es el "objeto" creado a partir de ese molde. Puedes tener múltiples contenedores del mismo molde.

**Relacionados:** [Container](#container)

---

## Named Volume

**Definición:** Volumen Docker con un nombre explícito, gestionado completamente por Docker. Los datos persisten en `/var/lib/docker/volumes/NOMBRE/` del host. Son la forma recomendada de manejar persistencia en producción.

**En el bootcamp:**

```yaml
volumes:
  gitlab-config:
    name: bc-gitlab-config    # Nombre explícito (no auto-generado)
  gitlab-data:
    name: bc-gitlab-data
```

**Ventajas sobre bind mounts:**
- Docker gestiona permisos automáticamente
- Independiente de la estructura de directorios del host
- Fácilmente respaldables con `docker volume inspect`
- Identificables por nombre en `docker volume ls`

**Relacionados:** [Docker Volume](#docker-volume), [Bind Mount](#bind-mount)

---

## Omnibus

**Definición:** Método de empaquetado de GitLab que incluye todos los componentes necesarios (Nginx, Puma, Sidekiq, PostgreSQL, Redis, Gitaly, etc.) en un único paquete autocontenido. La imagen Docker de GitLab CE usa Omnibus internamente.

**Origen del nombre:** "Omnibus" viene del latín y significa "para todos" — el paquete "para todo".

**Relación con Docker:** Cuando corres GitLab CE en Docker, estás corriendo Omnibus dentro de un contenedor. La configuración de Omnibus se hace a través de `GITLAB_OMNIBUS_CONFIG` o editando `/etc/gitlab/gitlab.rb` dentro del contenedor.

**Relacionados:** [GITLAB_OMNIBUS_CONFIG](#gitlab_omnibus_config), [gitlab-ctl](#gitlab-ctl)

---

## Profile

**Definición:** Característica de Docker Compose que permite definir servicios opcionales que solo se levantan cuando se especifica explícitamente el profile. Los servicios sin `profiles:` siempre se levantan con `docker compose up`.

**En el bootcamp:**

```yaml
prometheus:
  profiles:
    - monitoring  # Solo se levanta con --profile monitoring

grafana:
  profiles:
    - monitoring
```

```bash
# Levantar solo los servicios base (sin monitoring)
docker compose up -d

# Levantar también Prometheus y Grafana
docker compose --profile monitoring up -d
```

**Relacionados:** [Service](#service), [Docker Compose](#docker-compose)

---

## Restore

**Definición:** Proceso de recuperación de una instancia de GitLab a partir de un backup existente. Implica detener los servicios de escritura (Puma, Sidekiq), ejecutar `gitlab-backup restore`, y volver a configurar y reiniciar la instancia.

**Proceso básico:**

```bash
# 1. Detener servicios de escritura
docker compose exec gitlab gitlab-ctl stop puma
docker compose exec gitlab gitlab-ctl stop sidekiq

# 2. Restaurar
docker compose exec gitlab gitlab-backup restore BACKUP=TIMESTAMP

# 3. Reconfigurar y reiniciar
docker compose exec gitlab gitlab-ctl reconfigure
docker compose exec gitlab gitlab-ctl restart
```

**Regla de oro:** El `gitlab-secrets.json` del momento del backup debe coincidir con el que tiene la instancia donde restauras. Sin esto, el restore falla o los datos cifrados son ilegibles.

**Relacionados:** [Backup](#backup), [Secrets](#secrets)

---

## Secrets

**Definición (gitlab-secrets.json):** Archivo de GitLab que contiene las claves criptográficas usadas para cifrar datos sensibles: tokens de CI/CD, variables de entorno cifradas, seeds de autenticación de dos factores (2FA), tokens de integración, etc.

**Ubicación:** `/etc/gitlab/gitlab-secrets.json` dentro del contenedor (persistido en el volumen `bc-gitlab-config`).

**Por qué es crítico:**

```bash
# ¿QUÉ HACE?: Respalda el archivo de secrets al host
# ¿POR QUÉ?: Sin este archivo, el backup .tar es irrestauable completamente
# ¿PARA QUÉ?: Tener la "llave" para descifrar los datos cifrados en la base de datos
docker compose exec gitlab cat /etc/gitlab/gitlab-secrets.json > ~/gitlab-backups/gitlab-secrets.json
```

⚠️ **Nunca subas este archivo a un repositorio de código.** Contiene claves privadas.

**Relacionados:** [Backup](#backup), [Restore](#restore)

---

## Service

**Definición (Docker Compose):** Definición de un contenedor (o grupo de contenedores idénticos) en `docker-compose.yml`. Cada `service` especifica la imagen a usar, variables de entorno, puertos, volúmenes, healthcheck y dependencias.

**En el bootcamp hay 5 servicios:**

```yaml
services:
  gitlab:          # El servidor GitLab CE principal
  gitlab-runner:   # Ejecutor de pipelines CI/CD
  registry-cache:  # Caché local de Docker Hub
  prometheus:      # Recolector de métricas (profile: monitoring)
  grafana:         # Dashboards de monitoreo (profile: monitoring)
```

**Relacionados:** [Docker Compose](#docker-compose), [Container](#container), [Profile](#profile)

---

## shm_size

**Definición:** Configuración de Docker que define el tamaño de la memoria compartida (`/dev/shm`) disponible para el contenedor. GitLab requiere una cantidad mínima de memoria compartida para que Sidekiq y PostgreSQL funcionen correctamente.

**En el bootcamp:**

```yaml
gitlab:
  shm_size: '256m'  # 256 MB de memoria compartida
```

**¿Qué pasa si se omite?** Docker asigna solo 64 MB por defecto. Esto puede causar crashes silenciosos de Sidekiq o errores de "out of memory" en operaciones de base de datos de GitLab.

**Relacionados:** [Service](#service), [Sidekiq](#sidekiq)

---

## Sidekiq

**Definición:** Procesador de trabajos en segundo plano de GitLab. Maneja tareas asíncronas como: envío de emails, generación de estadísticas, indexación de búsqueda, procesamiento de CI/CD artifacts, limpieza de datos, webhooks y más.

**Por qué importa en el restore:**

```bash
# Se detiene ANTES del restore para evitar escrituras concurrentes en la BD
docker compose exec gitlab gitlab-ctl stop sidekiq
# Se reinicia DESPUÉS del restore y reconfigure
docker compose exec gitlab gitlab-ctl restart
```

**Síntoma de Sidekiq caído:** Las emails no se envían, las estadísticas no se actualizan, los MR no se procesan. La UI sigue funcionando pero las operaciones asíncronas están bloqueadas.

**Relacionados:** [gitlab-ctl](#gitlab-ctl), [shm_size](#shm_size)

---

## STRATEGY=copy

**Definición:** Parámetro del comando `gitlab-backup create` que indica cómo se copian los repositorios Git durante el backup. Con `STRATEGY=copy`, GitLab primero copia los repositorios a un directorio temporal y luego los comprime, garantizando consistencia incluso si hay escrituras concurrentes.

**Comparativa:**

| Estrategia | Comportamiento | Riesgo |
|------------|----------------|--------|
| `default` (hardlink) | Usa hard links para los repos | Riesgo de inconsistencia si hay pushes durante el backup |
| `copy` | Copia completa antes de comprimir | Sin riesgo de inconsistencia |

**Cuándo usar `copy`:** Siempre que tu instancia esté activa durante el backup (que es el caso en el bootcamp).

**Ejemplo:**

```bash
# ¿QUÉ HACE?: Crea backup con estrategia segura para instancias activas
docker compose exec gitlab gitlab-backup create STRATEGY=copy
```

**Relacionados:** [Backup](#backup)

---

## Volume

**Definición general (Docker):** Mecanismo de persistencia de datos en Docker. El término "volume" en inglés engloba todos los tipos de almacenamiento persistente (named volumes, bind mounts, tmpfs). En la práctica, cuando se dice "volumen" en el contexto del bootcamp, generalmente se refiere a Named Volumes.

**Los 3 volúmenes principales de GitLab en el bootcamp:**

| Alias en compose | Nombre real | Ruta en contenedor | Contenido |
|-----------------|-------------|-------------------|-----------|
| `gitlab-config` | `bc-gitlab-config` | `/etc/gitlab` | `gitlab.rb`, `gitlab-secrets.json` |
| `gitlab-logs` | `bc-gitlab-logs` | `/var/log/gitlab` | Logs de todos los servicios |
| `gitlab-data` | `bc-gitlab-data` | `/var/opt/gitlab` | Repos Git, PostgreSQL, uploads |

**Comandos útiles:**

```bash
# Listar volúmenes del bootcamp
docker volume ls | grep bc-gitlab

# Ver detalles (incluye ruta real en el host)
docker volume inspect bc-gitlab-data

# Ver uso de disco
docker compose exec gitlab df -h /var/opt/gitlab
```

**Relacionados:** [Named Volume](#named-volume), [Bind Mount](#bind-mount), [Docker Volume](#docker-volume)

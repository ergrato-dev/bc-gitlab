# 02 — Docker Compose para Producción

El `docker-compose.yml` del proyecto final debe ser más robusto que el usado en semanas anteriores. La diferencia entre un compose de desarrollo y uno de pseudo-producción está en tres áreas: persistencia de datos, observabilidad del estado de los servicios y configuración mediante variables de entorno.

---

## Estructura del docker-compose.yml completo

```yaml
# ¿QUÉ HACE?: Define toda la infraestructura de la plataforma DevOps
# ¿POR QUÉ?: Un único archivo permite levantar/bajar toda la plataforma con un comando
# ¿PARA QUÉ?: Entorno reproducible en cualquier máquina con Docker instalado

version: '3.8'

services:
  gitlab:
    image: gitlab/gitlab-ce:${GITLAB_VERSION:-16.11.0-ce.0}
    container_name: gitlab
    restart: unless-stopped
    hostname: ${GITLAB_HOSTNAME:-gitlab.local}
    ports:
      - "${HTTP_PORT:-80}:80"
      - "${HTTPS_PORT:-443}:443"
      - "${SSH_PORT:-2222}:22"
    volumes:
      - gitlab-config:/etc/gitlab
      - gitlab-logs:/var/log/gitlab
      - gitlab-data:/var/opt/gitlab
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url '${GITLAB_EXTERNAL_URL:-http://localhost}'

        # Registry de contenedores
        registry_external_url '${REGISTRY_URL:-http://localhost:5050}'
        gitlab_rails['registry_enabled'] = true

        # Email (deshabilitado en lab)
        gitlab_rails['smtp_enable'] = false

        # Monitoreo: Prometheus habilitado
        prometheus_monitoring['enable'] = true
        prometheus['listen_address'] = '0.0.0.0:9090'

        # Grafana deshabilitado (usamos Grafana externo)
        grafana['enable'] = false

        # Backup automático
        gitlab_rails['backup_keep_time'] = 604800

        # Performance
        puma['worker_processes'] = 2
        puma['min_threads'] = 1
        puma['max_threads'] = 4
    networks:
      - gitlab-net
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/-/health"]
      interval: 60s
      timeout: 10s
      retries: 5
      start_period: 120s   # GitLab tarda 2-3 min en iniciar

  gitlab-runner:
    image: gitlab/gitlab-runner:alpine
    container_name: gitlab-runner
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - runner-config:/etc/gitlab-runner
    networks:
      - gitlab-net
    depends_on:
      gitlab:
        condition: service_healthy

  prometheus:
    image: prom/prometheus:v2.51.0
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
    networks:
      - gitlab-net

  grafana:
    image: grafana/grafana:10.4.2
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=${GRAFANA_USER:-admin}
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD:-admin123}
      - GF_INSTALL_PLUGINS=grafana-piechart-panel
    volumes:
      - grafana-data:/var/lib/grafana
      - ./monitoring/grafana-datasources.yml:/etc/grafana/provisioning/datasources/prometheus.yml:ro
    networks:
      - gitlab-net
    depends_on:
      - prometheus

  minio:
    image: minio/minio:latest
    container_name: minio
    restart: unless-stopped
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - minio-data:/data
    environment:
      - MINIO_ROOT_USER=${MINIO_USER:-minioadmin}
      - MINIO_ROOT_PASSWORD=${MINIO_PASSWORD:-minioadmin123}
    command: server /data --console-address ":9001"
    networks:
      - gitlab-net

volumes:
  gitlab-config:
    name: proyecto-final-gitlab-config
  gitlab-logs:
    name: proyecto-final-gitlab-logs
  gitlab-data:
    name: proyecto-final-gitlab-data
  runner-config:
    name: proyecto-final-runner-config
  prometheus-data:
    name: proyecto-final-prometheus
  grafana-data:
    name: proyecto-final-grafana
  minio-data:
    name: proyecto-final-minio

networks:
  gitlab-net:
    name: proyecto-final-net
    driver: bridge
```

---

## Archivo .env.example

```bash
# ¿QUÉ HACE?: Documenta todas las variables requeridas con sus valores por defecto
# ¿POR QUÉ?: Sin este archivo, nadie puede levantar el proyecto sin preguntar qué valores usar
# ¿PARA QUÉ?: El .env real (con secretos) nunca se commitea; .env.example sí

# ─── GitLab ───────────────────────────────────────────────────────────────────
GITLAB_VERSION=16.11.0-ce.0
GITLAB_HOSTNAME=gitlab.local
GITLAB_EXTERNAL_URL=http://localhost
HTTP_PORT=80
HTTPS_PORT=443
SSH_PORT=2222

# Container Registry
REGISTRY_URL=http://localhost:5050

# ─── Monitoring ───────────────────────────────────────────────────────────────
GRAFANA_USER=admin
GRAFANA_PASSWORD=cambia-esta-password

# ─── Storage ──────────────────────────────────────────────────────────────────
MINIO_USER=minioadmin
MINIO_PASSWORD=cambia-esta-password

# ─── Backup ───────────────────────────────────────────────────────────────────
BACKUP_DIR=/var/opt/gitlab/backups
BACKUP_S3_BUCKET=gitlab-backups
```

---

## Configuración de Prometheus para scrapear GitLab

```yaml
# monitoring/prometheus.yml
# ¿QUÉ HACE?: Configura los jobs de scraping hacia GitLab y el host
# ¿POR QUÉ?: Sin esta configuración, Prometheus no sabe de dónde recolectar métricas
# ¿PARA QUÉ?: Métricas disponibles en Grafana para dashboards y alertas
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  # Prometheus integrado de GitLab (usa nombre del contenedor en red Docker)
  - job_name: 'gitlab'
    metrics_path: '/-/metrics'
    static_configs:
      - targets: ['gitlab:80']

  # Federación: recolectar métricas del Prometheus interno de GitLab
  - job_name: 'gitlab-internal-prometheus'
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job=~"gitlab.*"}'
        - '{__name__=~"sidekiq.*"}'
        - '{__name__=~"pg_.*"}'
        - '{__name__=~"redis_.*"}'
        - '{__name__=~"gitaly_.*"}'
    static_configs:
      - targets: ['gitlab:9090']
    honor_labels: true

  # Prometheus se auto-monitorea
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
```

```yaml
# monitoring/grafana-datasources.yml
# ¿QUÉ HACE?: Provisionamiento automático del datasource Prometheus en Grafana
# ¿POR QUÉ?: Sin esto, hay que configurar el datasource manualmente cada vez
# ¿PARA QUÉ?: Grafana arranca listo para consultar métricas sin intervención manual
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    uid: prometheus-uid
    editable: false
```

---

## Puntos clave de la configuración

### Healthchecks

Sin healthchecks, `depends_on: condition: service_healthy` no funciona y el Runner puede intentar registrarse antes de que GitLab esté listo. El `start_period: 120s` es crítico — GitLab tarda entre 2 y 5 minutos en el primer arranque.

```bash
# ¿QUÉ HACE?: Muestra el estado de health de todos los contenedores
docker inspect --format '{{.Name}} → {{.State.Health.Status}}' \
  $(docker compose ps -q) 2>/dev/null | grep -v "^$"
# Esperado: /gitlab → healthy, /gitlab-runner → healthy
```

### Volúmenes con nombres explícitos

```bash
# ¿QUÉ HACE?: Lista todos los volúmenes del proyecto con su tamaño
# ¿POR QUÉ?: Controlar qué datos persisten y cuánto espacio ocupan
docker volume ls --filter name=proyecto-final | \
  xargs -I{} docker volume inspect {} --format '{{.Name}}: {{.Mountpoint}}'

# Ver tamaño total de datos de GitLab
docker run --rm -v proyecto-final-gitlab-data:/data \
  alpine du -sh /data
```

Los volúmenes nombrados (en lugar de bind mounts `./data:/var/opt/gitlab`) son más portables: Docker los gestiona y se limpian con `docker compose down -v`. Los bind mounts son más útiles cuando necesitas acceder a los archivos directamente desde el host.

### Variables de entorno vs GITLAB_OMNIBUS_CONFIG

Existe una jerarquía de configuración en GitLab Omnibus:
1. `GITLAB_OMNIBUS_CONFIG` (env var en Docker) — se aplica antes de `/etc/gitlab/gitlab.rb`
2. `/etc/gitlab/gitlab.rb` (persistido en el volumen) — configuración permanente
3. `gitlab.rb.d/` — fragmentos adicionales

Para el proyecto final, toda la configuración en `GITLAB_OMNIBUS_CONFIG` es suficiente. No mezcles con ediciones manuales del `gitlab.rb` dentro del contenedor — se perderán al recrear el contenedor.

### Gestión de secretos en entorno de laboratorio

```bash
# Nunca hardcodear credenciales en docker-compose.yml
# Usar siempre ${VAR} con valor por defecto seguro

# Verificar que .env no está commiteado
git ls-files .env && echo "⚠️  ERROR: .env está siendo trackeado" || echo "✅ .env no trackeado"

# Ver qué variables están definidas (sin mostrar los valores)
grep -v "^#" .env | grep -v "^$" | cut -d'=' -f1 | sort
```

---

## Actualización de GitLab CE con Docker Compose

El proceso de actualización siempre sigue el mismo patrón:

```bash
# ¿QUÉ HACE?: Actualiza GitLab CE a una nueva versión siguiendo la guía de upgrade paths
# ¿POR QUÉ?: GitLab requiere actualizar versión por versión en major/minor releases
# ¿PARA QUÉ?: Evitar migraciones de base de datos rotas por saltar versiones

# 1. Hacer backup ANTES de actualizar
./backup/backup.sh

# 2. Cambiar la versión en .env
# GITLAB_VERSION=16.11.0-ce.0 → GITLAB_VERSION=17.0.0-ce.0

# 3. Descargar la nueva imagen
docker compose pull gitlab

# 4. Recrear el contenedor (datos persisten en volúmenes)
docker compose up -d gitlab

# 5. Esperar que las migraciones de BD terminen
docker compose logs -f gitlab | grep -E "(migration|complete|error)"

# 6. Verificar que la versión es correcta
curl -s http://localhost/api/v4/version | jq .version
```

---

## Troubleshooting de Docker Compose

```bash
# Problema: GitLab no inicia después de muchos minutos
docker compose logs gitlab --tail 50 | grep -E "(ERROR|FATAL|failed)"

# Problema: Runner no conecta a GitLab
docker compose exec gitlab-runner gitlab-runner list
# → Si está vacío, no está registrado todavía

# Problema: Prometheus no scrapea GitLab
curl -s http://localhost:9090/api/v1/targets | \
  jq '.data.activeTargets[] | {job: .labels.job, health, error}'

# Problema: Falta de espacio en disco
docker system df -v | head -30
docker system prune --volumes  # ⚠️ Borra datos no usados — usar con cuidado
```

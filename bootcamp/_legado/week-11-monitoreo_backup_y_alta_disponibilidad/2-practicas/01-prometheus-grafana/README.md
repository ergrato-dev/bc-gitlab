# Práctica 01 — Prometheus y Grafana: Monitoreo Completo de GitLab

## Objetivo

Desplegar un stack de monitoreo completo (Prometheus + Grafana + Alertmanager) para una instancia GitLab CE, crear dashboards operacionales personalizados e implementar reglas de alerta con notificaciones.

## Requisitos

- GitLab CE corriendo (Docker Compose o Omnibus)
- Docker y Docker Compose disponibles
- Puerto 9090 (Prometheus), 3000 (Grafana), 9093 (Alertmanager) disponibles
- Tiempo estimado: 60-90 minutos

---

## Instrucciones

### Paso 1: Habilitar Prometheus en GitLab

Si usas GitLab CE Omnibus, verificar que Prometheus está activo:

```bash
# ¿Está Prometheus corriendo?
sudo gitlab-ctl status prometheus
# → run: prometheus: (pid XXXX) NNNs

# Si no está habilitado, añadir a gitlab.rb:
sudo sed -i "s/# prometheus_monitoring\['enable'\] = true/prometheus_monitoring['enable'] = true/" \
  /etc/gitlab/gitlab.rb
sudo gitlab-ctl reconfigure

# Verificar que responde
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length'
# → Número de targets (debería ser 10-15)
```

Si usas GitLab en Docker con `docker-compose.yml`, añadir el puerto de Prometheus:

```yaml
# En tu docker-compose.yml de GitLab, agregar:
services:
  gitlab:
    # ... configuración existente ...
    ports:
      - "80:80"
      - "443:443"
      - "22:22"
      - "9090:9090"   # Prometheus
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        prometheus_monitoring['enable'] = true
        prometheus['listen_address'] = '0.0.0.0:9090'
```

### Paso 2: Crear el stack de monitoreo externo

Crear el directorio de trabajo:

```bash
mkdir monitoring-stack && cd monitoring-stack
mkdir -p grafana/provisioning/{datasources,dashboards,alerting}
mkdir -p prometheus/rules
```

**`docker-compose.monitoring.yml`**:

```yaml
version: '3.8'

services:
  grafana:
    image: grafana/grafana:10.4.2
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=gitlab-monitoring-2024
      - GF_SERVER_ROOT_URL=http://localhost:3000
      - GF_INSTALL_PLUGINS=grafana-piechart-panel
      - GF_FEATURE_TOGGLES_ENABLE=ngalert
      # SMTP para alertas por email (opcional)
      # - GF_SMTP_ENABLED=true
      # - GF_SMTP_HOST=smtp.gmail.com:587
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    restart: unless-stopped
    extra_hosts:
      - "host.docker.internal:host-gateway"
    networks:
      - monitoring

  # Prometheus externo (opcional si ya usas el integrado de GitLab)
  # Solo necesario si quieres retención > 30 días o federación
  prometheus-external:
    image: prom/prometheus:v2.51.0
    container_name: prometheus-external
    ports:
      - "9091:9090"   # Puerto 9091 para no conflicto con GitLab's Prometheus
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./prometheus/rules:/etc/prometheus/rules:ro
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=90d'
      - '--web.enable-admin-api'
    restart: unless-stopped
    extra_hosts:
      - "host.docker.internal:host-gateway"
    networks:
      - monitoring

volumes:
  grafana-data:
  prometheus-data:

networks:
  monitoring:
    driver: bridge
```

**`prometheus/prometheus.yml`**:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets: []  # Añadir Alertmanager si se configura

scrape_configs:
  # Federación con el Prometheus de GitLab (recolectar sus métricas)
  - job_name: 'gitlab-federation'
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job=~"gitlab.*"}'
        - '{job="node"}'
        - '{__name__=~"sidekiq.*"}'
        - '{__name__=~"pg_.*"}'
        - '{__name__=~"redis_.*"}'
    static_configs:
      - targets: ['host.docker.internal:9090']
    honor_labels: true

  # Scraping directo de los exporters de GitLab
  - job_name: 'gitlab-rails'
    static_configs:
      - targets: ['host.docker.internal:8080']

  - job_name: 'gitlab-sidekiq'
    static_configs:
      - targets: ['host.docker.internal:8082']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['host.docker.internal:9100']
```

**`grafana/provisioning/datasources/prometheus.yml`**:

```yaml
apiVersion: 1
datasources:
  - name: Prometheus-GitLab
    type: prometheus
    access: proxy
    url: http://host.docker.internal:9090
    isDefault: true
    jsonData:
      timeInterval: "15s"
      httpMethod: GET
    editable: true
    uid: prometheus-gitlab
```

```bash
# Lanzar el stack
docker compose -f docker-compose.monitoring.yml up -d

# Verificar que los contenedores iniciaron
docker compose -f docker-compose.monitoring.yml ps

# Acceder a Grafana
echo "Grafana: http://localhost:3000 (admin/gitlab-monitoring-2024)"
```

### Paso 3: Importar dashboards de GitLab

```bash
GRAFANA_URL="http://localhost:3000"
GRAFANA_AUTH="admin:gitlab-monitoring-2024"

# Función para importar dashboard por ID de Grafana.com
import_dashboard() {
  local ID=$1
  local NAME=$2
  
  echo "Importando: $NAME (ID: $ID)..."
  curl -s --request POST \
    --header "Content-Type: application/json" \
    --user "$GRAFANA_AUTH" \
    --data "{
      \"dashboard\": null,
      \"inputs\": [{\"name\": \"DS_PROMETHEUS\", \"type\": \"datasource\", \"pluginId\": \"prometheus\", \"value\": \"prometheus-gitlab\"}],
      \"folderId\": 0,
      \"overwrite\": true,
      \"path\": \"db/$ID\"
    }" \
    "$GRAFANA_URL/api/dashboards/import" | jq -r '.status // .message'
}

# Importar dashboards oficiales
# Nota: algunos requieren configuración del datasource manualmente en la UI
for ID in 20916 17614 9628 763 1860; do
  # Descargar dashboard JSON de grafana.com
  curl -s "https://grafana.com/api/dashboards/${ID}/revisions/latest/download" \
    -o "/tmp/dashboard-${ID}.json"
  
  # Importar via API
  curl -s --request POST \
    --header "Content-Type: application/json" \
    --user "$GRAFANA_AUTH" \
    --data "{\"dashboard\": $(cat /tmp/dashboard-${ID}.json), \"folderId\": 0, \"overwrite\": true}" \
    "$GRAFANA_URL/api/dashboards/import" | jq -r '.status // .slug // .message'
  
  echo "Dashboard $ID procesado"
done
```

### Paso 4: Crear dashboard personalizado via API

```bash
# Crear un dashboard personalizado de operaciones GitLab
cat > /tmp/gitlab-ops-dashboard.json << 'JSON'
{
  "dashboard": {
    "title": "GitLab Operations",
    "tags": ["gitlab", "operations"],
    "timezone": "browser",
    "refresh": "30s",
    "panels": [
      {
        "title": "HTTP Requests/sec",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "rate(gitlab_rails_requests_total[5m])",
            "legendFormat": "{{method}} {{status}}"
          }
        ]
      },
      {
        "title": "P95 Latency",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(gitlab_rails_request_duration_seconds_bucket[5m]))",
            "legendFormat": "P95 Latency"
          }
        ]
      },
      {
        "title": "Sidekiq Queue Size",
        "type": "stat",
        "gridPos": {"h": 4, "w": 6, "x": 0, "y": 8},
        "targets": [
          {
            "expr": "sum(sidekiq_queue_size)",
            "legendFormat": "Total Queue"
          }
        ]
      },
      {
        "title": "Error Rate (5xx)",
        "type": "stat",
        "gridPos": {"h": 4, "w": 6, "x": 6, "y": 8},
        "targets": [
          {
            "expr": "rate(gitlab_rails_requests_total{status=~\"5..\"}[5m])",
            "legendFormat": "5xx/sec"
          }
        ]
      },
      {
        "title": "PostgreSQL Connections",
        "type": "gauge",
        "gridPos": {"h": 4, "w": 6, "x": 12, "y": 8},
        "targets": [
          {
            "expr": "pg_stat_database_numbackends{datname=\"gitlabhq_production\"}",
            "legendFormat": "Active Connections"
          }
        ]
      },
      {
        "title": "Disk Usage /var/opt/gitlab",
        "type": "gauge",
        "gridPos": {"h": 4, "w": 6, "x": 18, "y": 8},
        "targets": [
          {
            "expr": "(node_filesystem_size_bytes{mountpoint=\"/var/opt/gitlab\"} - node_filesystem_avail_bytes{mountpoint=\"/var/opt/gitlab\"}) / node_filesystem_size_bytes{mountpoint=\"/var/opt/gitlab\"} * 100",
            "legendFormat": "Disk %"
          }
        ]
      }
    ],
    "schemaVersion": 38
  },
  "folderId": 0,
  "overwrite": true
}
JSON

curl -s --request POST \
  --header "Content-Type: application/json" \
  --user "$GRAFANA_AUTH" \
  --data @/tmp/gitlab-ops-dashboard.json \
  "$GRAFANA_URL/api/dashboards/db" | jq '{status, url: .url}'
```

### Paso 5: Configurar reglas de alerta en Prometheus

```yaml
# prometheus/rules/gitlab-alerts.yml
# ¿QUÉ HACE?: Define reglas de alerta para los problemas más críticos de GitLab
# ¿POR QUÉ?: Las alertas deben dispararse antes de que los usuarios reporten problemas
# ¿PARA QUÉ?: Notificación proactiva con tiempo de reacción antes del impacto

groups:
  - name: gitlab-critical
    rules:
      - alert: GitLabHighErrorRate
        expr: |
          rate(gitlab_rails_requests_total{status=~"5.."}[5m]) /
          rate(gitlab_rails_requests_total[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Tasa de errores alta: {{ $value | humanizePercentage }}"

      - alert: GitLabDiskSpaceWarning
        expr: |
          (node_filesystem_size_bytes{mountpoint="/var/opt/gitlab"} -
           node_filesystem_avail_bytes{mountpoint="/var/opt/gitlab"}) /
          node_filesystem_size_bytes{mountpoint="/var/opt/gitlab"} > 0.80
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Disco al {{ $value | humanizePercentage }}"

      - alert: SidekiqQueueBacklog
        expr: sum(sidekiq_queue_size) > 500
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Cola Sidekiq con {{ $value }} jobs pendientes"
```

```bash
# Recargar reglas sin reiniciar Prometheus
curl -s -X POST http://localhost:9091/-/reload
# → Verificar en Prometheus UI: http://localhost:9091/rules
```

### Paso 6: Explorar métricas con PromQL

Ejecutar estas consultas en Prometheus (http://localhost:9090) o en Grafana:

```promql
# 6.1 Ver todos los jobs de Sidekiq con su tamaño de cola
sidekiq_queue_size

# 6.2 Tasa de peticiones HTTP por código de estado
sum by (status) (rate(gitlab_rails_requests_total[5m]))

# 6.3 Top 5 endpoints más lentos
topk(5, histogram_quantile(0.95, 
  sum by (action, controller) (
    rate(gitlab_rails_request_duration_seconds_bucket[10m])
  )
))

# 6.4 Ratio de cache hits de PostgreSQL
sum(pg_stat_database_blks_hit) /
(sum(pg_stat_database_blks_hit) + sum(pg_stat_database_blks_read)) * 100

# 6.5 Memoria RSS de todos los procesos Rails
process_resident_memory_bytes{job=~"gitlab.*"}

# 6.6 Verificar si algún servicio de GitLab está caído
up{job=~"gitlab.*"} == 0
```

### Paso 7: Verificar alertas en Grafana

1. En Grafana → **Alerting → Alert rules** → verificar que las reglas están definidas
2. En **Alerting → Contact points** → configurar email o Slack como destino
3. Disparar una alerta de prueba:

```bash
# Generar carga artificial para ver métricas cambiar
# (ejecutar en otro terminal)
for i in {1..100}; do
  curl -s "http://localhost/users/sign_in" > /dev/null
  sleep 0.1
done
```

4. Observar en Grafana cómo sube la tasa de peticiones en tiempo real

---

## Preguntas de reflexión

1. ¿Qué métrica usarías como "señal de salud" principal del sistema? Justifica.

2. Los jobs de Sidekiq tardaron más de lo habitual en procesarse. ¿Qué métricas revisarías primero para diagnosticar el problema?

3. La latencia P95 subió de 200ms a 800ms. ¿Qué primeras 3 consultas PromQL ejecutarías para diagnosticar?

4. ¿Por qué es útil tener tanto el Prometheus interno de GitLab como uno externo? ¿Qué casos de uso cubre cada uno?

5. ¿Qué otras métricas o alertas agregarías a un dashboard ejecutivo que muestre SLA semanal?

---

## Entregables

- [ ] Prometheus de GitLab respondiendo en http://localhost:9090 con 10+ targets
- [ ] Stack de monitoreo (Grafana) levantado via Docker Compose
- [ ] Datasource de Prometheus configurado en Grafana
- [ ] Al menos 2 dashboards importados (ej: 20916 + uno de base de datos)
- [ ] Dashboard personalizado creado con mínimo 4 paneles relevantes
- [ ] Reglas de alerta definidas en prometheus/rules/gitlab-alerts.yml
- [ ] Al menos 6 consultas PromQL ejecutadas y resultados documentados
- [ ] Captura de pantalla del dashboard en funcionamiento

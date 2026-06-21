# Práctica 01 — Prometheus y Grafana: Configurar Monitoreo

## Objetivo

Desplegar Prometheus y Grafana para monitorear una instancia GitLab CE.

## Requisitos

- GitLab CE Docker con Prometheus habilitado
- Docker Compose para servicios adicionales
- Acceso a métricas en `http://localhost:9090`

## Instrucciones

### Paso 1: Habilitar Prometheus en GitLab CE

En tu `docker-compose.yml` o `gitlab.rb`, asegúrate de que Prometheus esté habilitado. Si usas la imagen oficial, suele venir habilitado. Verifica accediendo a:
```
http://localhost:9090
```

### Paso 2: Desplegar Grafana con Docker

Crea un `docker-compose.monitoring.yml`:
```yaml
version: '3.8'
services:
  grafana:
    image: grafana/grafana:10.4.0
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
      - ./grafana/datasources:/etc/grafana/provisioning/datasources

volumes:
  grafana-data:
```

### Paso 3: Configurar datasource de Prometheus en Grafana

Crea `grafana/datasources/prometheus.yml`:
```yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://host.docker.internal:9090
    isDefault: true
```

### Paso 4: Importar dashboard oficial de GitLab

En Grafana (http://localhost:3000):
1. Login con admin/admin
2. Dashboards → Import → ID: 20916 (GitLab Omnibus)
3. Selecciona el datasource Prometheus
4. Explora las métricas

### Paso 5: Crear un dashboard personalizado

Crea un panel con al menos:
- **Requests por segundo**: `rate(gitlab_rails_requests_total[1m])`
- **Latencia P95**: `histogram_quantile(0.95, rate(gitlab_rails_request_duration_seconds_bucket[5m]))`
- **Errores 5xx**: `rate(gitlab_rails_requests_total{status=~"5.."}[5m])`
- **Uso de memoria de Sidekiq**: `sidekiq_memory_usage_bytes`

### Paso 6: Configurar una alerta de prueba

En Grafana, crea una alerta para "Requests con error":
- Condición: `rate > 1`
- Evaluación: cada 1 minuto
- Notificación: email (configura SMTP en Grafana)

## Preguntas de reflexión
- ¿Qué métrica consideras más crítica para la operación diaria?
- ¿Cómo distinguirías un pico normal de uso de un incidente real?
- ¿Qué otras métricas agregarías para un dashboard ejecutivo?

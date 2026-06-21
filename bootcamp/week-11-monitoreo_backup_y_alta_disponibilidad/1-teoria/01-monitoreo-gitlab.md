# 01 — Monitoreo de GitLab: Prometheus, Exporters y Grafana

GitLab CE incluye Prometheus integrado y múltiples exporters que exponen métricas de todos los componentes de la plataforma.

## Prometheus Integrado

GitLab CE empaqueta su propio Prometheus que recolecta métricas de:
- **GitLab Rails**: peticiones HTTP, latencia, jobs Sidekiq, operaciones SQL
- **PostgreSQL**: conexiones activas, locks, cache hit ratio, replicación
- **Redis**: uso de memoria, comandos por segundo, conexiones
- **Gitaly**: operaciones de git, latencia, errores
- **Puma (web server)**: workers activos, peticiones en cola, tiempo de respuesta
- **Sidekiq**: jobs procesados, encolados, fallidos, reintentos

Para habilitarlo, configurar en `gitlab.rb`:
```ruby
prometheus_monitoring['enable'] = true
```

## Exporters

Cada componente expone sus métricas en un endpoint HTTP (usualmente `:9100` para node_exporter, `:9236` para gitaly, etc.). Prometheus los escrapea periódicamente (cada 15s por defecto) y almacena las series temporales localmente.

## Grafana

GitLab CE no incluye Grafana, pero se puede desplegar como contenedor adicional. Grafana se conecta a Prometheus como datasource y permite crear dashboards visuales. GitLab proporciona dashboards oficiales importables desde grafana.com con ID 20916 (GitLab Omnibus) y 17614 (GitLab Performance).

Métricas clave para dashboard:
- **Peticiones HTTP**: `gitlab_rails_requests_total`
- **Latencia P95**: `histogram_quantile(0.95, rate(gitlab_rails_request_duration_seconds_bucket[5m]))` 
- **Jobs Sidekiq en cola**: `sidekiq_queue_size`
- **Uso de memoria Redis**: `redis_memory_used_bytes`
- **Conexiones PostgreSQL**: `pg_stat_database_numbackends`
- **Errores 5xx**: `rate(gitlab_rails_requests_total{status=~"5.."}[5m])`

## Alertas

Prometheus permite definir reglas de alerta en `prometheus.rules`. Alertmanager (integrado en Prometheus) las procesa y puede notificar vía email, Slack, PagerDuty o Webhook. Ejemplos de alertas:
- Pipeline queue size > 100 por más de 5 minutos
- PostgreSQL connections > 80% del máximo
- Uso de disco > 85%
- Latencia P95 > 2 segundos

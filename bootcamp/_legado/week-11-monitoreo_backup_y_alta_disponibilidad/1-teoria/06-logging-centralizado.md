# 06 — Logging Centralizado: ELK vs Loki + Promtail + Grafana

Prometheus y Grafana (visto en `01-monitoreo-gitlab.md`) responden "¿qué tan rápido/cuánto?" con métricas numéricas, pero no responden "¿qué pasó exactamente y por qué?". Esa pregunta la responden los logs. GitLab Omnibus escribe logs de cada componente en archivos separados dentro de `/var/log/gitlab/` — sin logging centralizado, diagnosticar un incidente significa entrar por SSH a cada nodo y hacer `tail -f` o `grep` en decenas de archivos distintos, uno por componente y, en HA, uno por nodo.

---

## Por qué centralizar logs

En un GitLab single-node los logs ya están "juntos" en el mismo servidor, pero dispersos en archivos independientes por componente. En HA (varios nodos Rails, Sidekiq separado, Gitaly Cluster) el problema se multiplica: el mismo incidente deja rastro en archivos distintos, en servidores distintos, con timestamps que hay que correlacionar a mano.

| Logs dispersos (por archivo/nodo) | Logging centralizado |
|-----------------------------------|----------------------|
| `ssh` + `tail`/`grep` en cada servidor | Una sola consulta busca en todos los nodos a la vez |
| Correlacionar timestamps a mano entre archivos | Vista unificada ordenada por tiempo, con filtros por componente |
| Logs se pierden si el nodo/contenedor muere | Logs sobreviven al ciclo de vida del nodo que los generó |
| Sin retención uniforme — cada log rota por su cuenta | Política de retención centralizada y consistente |
| Imposible correlacionar con métricas de Prometheus | Se anota junto al dashboard de Grafana — métrica y log lado a lado |
| Búsqueda por texto plano, lenta en archivos grandes | Índice de búsqueda (o etiquetas) — consultas rápidas incluso con volumen alto |

**RN (regla de negocio operativa) implícita**: un runbook de incidente no debería empezar con "conectarse a cada servidor" — debería empezar con una consulta en un único lugar.

---

## Logs de GitLab CE relevantes para centralizar

GitLab Omnibus escribe todos los logs bajo `/var/log/gitlab/`, uno por componente:

| Componente | Ruta | Contenido |
|-----------|------|-----------|
| GitLab Rails (aplicación) | `/var/log/gitlab/gitlab-rails/production.log` | Peticiones HTTP, excepciones de la aplicación Ruby on Rails |
| GitLab Rails (API) | `/var/log/gitlab/gitlab-rails/api_json.log` | Peticiones a la API REST/GraphQL en formato JSON estructurado |
| Sidekiq | `/var/log/gitlab/sidekiq/current` | Ejecución de jobs asíncronos (emails, webhooks, CI scheduling) |
| Gitaly | `/var/log/gitlab/gitaly/current` | Operaciones RPC de Git (clone, push, pull, fetch) |
| Nginx | `/var/log/gitlab/nginx/gitlab_access.log` y `gitlab_error.log` | Peticiones HTTP crudas al frontend, antes de llegar a Workhorse |
| GitLab Workhorse | `/var/log/gitlab/gitlab-workhorse/current` | Proxy entre Nginx y Rails — uploads/downloads grandes, Git HTTP |
| PostgreSQL | `/var/log/gitlab/postgresql/current` | Queries lentas, errores de conexión, autovacuum |
| Redis | `/var/log/gitlab/redis/current` | Estado de persistencia, conexiones, warnings de memoria |

```bash
# ¿QUÉ HACE?: Lista los directorios de log activos de un nodo GitLab Omnibus
# ¿POR QUÉ?: Cada componente escribe en su propio subdirectorio bajo /var/log/gitlab
# ¿PARA QUÉ?: Confirmar qué rutas apuntar en el recolector de logs (Promtail/Filebeat)
sudo ls -1 /var/log/gitlab/
# → gitaly gitlab-rails gitlab-shell gitlab-workhorse nginx postgresql redis sidekiq ...
```

Prioridad de centralización cuando el tiempo/recursos son limitados: **Rails (production.log) y Nginx primero** — ahí aparecen la mayoría de errores 5xx y peticiones lentas —, luego **Sidekiq y Gitaly** para diagnosticar jobs fallidos y operaciones Git lentas.

---

## Opción 1 — ELK Stack (Elasticsearch, Logstash, Kibana)

ELK es el stack de logging más establecido: **Elasticsearch** indexa y almacena el texto completo de cada log (full-text search), **Logstash** (o su alternativa liviana Filebeat) recolecta y transforma los logs antes de enviarlos, y **Kibana** los visualiza y permite búsquedas.

```yaml
# docker-compose.elk.yml
# ¿QUÉ HACE?: Despliega Elasticsearch + Kibana + Filebeat apuntando a los logs de GitLab
# ¿POR QUÉ?: Elasticsearch indexa el contenido completo del log — bueno para búsqueda de texto libre
# ¿PARA QUÉ?: Buscar cualquier palabra/error dentro de los logs históricos de GitLab
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.13.4
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms1g -Xmx1g"
    volumes:
      - es-data:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"
    restart: unless-stopped

  kibana:
    image: docker.elastic.co/kibana/kibana:8.13.4
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    ports:
      - "5601:5601"
    depends_on:
      - elasticsearch
    restart: unless-stopped

  filebeat:
    image: docker.elastic.co/beats/filebeat:8.13.4
    user: root
    volumes:
      - ./filebeat.yml:/usr/share/filebeat/filebeat.yml:ro
      - /var/log/gitlab:/var/log/gitlab:ro
    depends_on:
      - elasticsearch
    restart: unless-stopped

volumes:
  es-data:
```

```yaml
# filebeat.yml
# ¿QUÉ HACE?: Indica a Filebeat qué archivos de log de GitLab leer y hacia dónde enviarlos
# ¿POR QUÉ?: Sin esto Filebeat no sabe que existen los logs de GitLab
# ¿PARA QUÉ?: Ingestar production.log, sidekiq y nginx en Elasticsearch
filebeat.inputs:
  - type: log
    paths:
      - /var/log/gitlab/gitlab-rails/production.log
      - /var/log/gitlab/sidekiq/current
      - /var/log/gitlab/nginx/gitlab_access.log
    fields:
      service: gitlab
    fields_under_root: true

output.elasticsearch:
  hosts: ["elasticsearch:9200"]
```

**Costo de ELK**: Elasticsearch indexa el texto completo, lo que da búsquedas potentes pero consume mucha más RAM y disco que las alternativas basadas en etiquetas — en la práctica, requiere varios GB de RAM solo para Elasticsearch incluso en instalaciones pequeñas.

---

## Opción 2 — Loki + Promtail + Grafana (recomendado para esta semana)

**Loki** indexa solo las **etiquetas** de cada log (componente, nivel, nodo), no el texto completo — es mucho más liviano que Elasticsearch. **Promtail** es el agente que recolecta los logs y los envía a Loki (equivalente a Filebeat). La ventaja clave: **Loki se consulta desde el mismo Grafana que ya se desplegó en `01-monitoreo-gitlab.md`** — no hace falta una UI nueva como Kibana, los logs aparecen junto a las métricas de Prometheus en los mismos dashboards.

```yaml
# docker-compose.logging.yml
# ¿QUÉ HACE?: Despliega Loki + Promtail apuntando a los logs de GitLab, reutilizando Grafana ya desplegado
# ¿POR QUÉ?: Loki es mucho más liviano que Elasticsearch e integra directo con el Grafana existente
# ¿PARA QUÉ?: Ver métricas (Prometheus) y logs (Loki) en el mismo dashboard, sin UI adicional
version: '3.8'

services:
  loki:
    image: grafana/loki:3.0.0
    container_name: loki
    ports:
      - "3100:3100"
    volumes:
      - ./loki-config.yml:/etc/loki/local-config.yaml
      - loki-data:/loki
    command: -config.file=/etc/loki/local-config.yaml
    restart: unless-stopped

  promtail:
    image: grafana/promtail:3.0.0
    container_name: promtail
    volumes:
      - /var/log/gitlab:/var/log/gitlab:ro
      - ./promtail-config.yml:/etc/promtail/config.yml
    command: -config.file=/etc/promtail/config.yml
    depends_on:
      - loki
    restart: unless-stopped

volumes:
  loki-data:
```

```yaml
# promtail-config.yml
# ¿QUÉ HACE?: Define qué logs de GitLab lee Promtail y con qué etiquetas los envía a Loki
# ¿POR QUÉ?: Loki necesita etiquetas (job, component) para poder filtrar sin indexar texto completo
# ¿PARA QUÉ?: Consultar por componente ({component="rails"}) en vez de buscar texto libre
server:
  http_listen_port: 9080

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: gitlab-rails
    static_configs:
      - targets: [localhost]
        labels:
          job: gitlab
          component: rails
          __path__: /var/log/gitlab/gitlab-rails/production.log

  - job_name: gitlab-sidekiq
    static_configs:
      - targets: [localhost]
        labels:
          job: gitlab
          component: sidekiq
          __path__: /var/log/gitlab/sidekiq/current

  - job_name: gitlab-gitaly
    static_configs:
      - targets: [localhost]
        labels:
          job: gitlab
          component: gitaly
          __path__: /var/log/gitlab/gitaly/current

  - job_name: gitlab-nginx
    static_configs:
      - targets: [localhost]
        labels:
          job: gitlab
          component: nginx
          __path__: /var/log/gitlab/nginx/gitlab_access.log

  - job_name: gitlab-workhorse
    static_configs:
      - targets: [localhost]
        labels:
          job: gitlab
          component: workhorse
          __path__: /var/log/gitlab/gitlab-workhorse/current
```

Datasource de Loki en Grafana (mismo patrón que el datasource de Prometheus visto en `01-monitoreo-gitlab.md`):

```yaml
# grafana/provisioning/datasources/loki.yml
# ¿QUÉ HACE?: Registra Loki como datasource adicional en el Grafana ya desplegado
# ¿POR QUÉ?: Sin esto hay que agregar el datasource manualmente en cada instalación
# ¿PARA QUÉ?: Un mismo panel de Grafana puede mostrar métrica (Prometheus) y logs (Loki) correlacionados
apiVersion: 1
datasources:
  - name: Loki-GitLab
    type: loki
    access: proxy
    url: http://loki:3100
    editable: true
```

---

## LogQL: consultas básicas

LogQL es el lenguaje de consultas de Loki — usa el mismo estilo de selección por etiquetas que PromQL, seguido de filtros de texto opcionales.

```logql
# Todos los logs del componente Rails
{job="gitlab", component="rails"}

# Solo líneas que contienen "ERROR"
{job="gitlab", component="rails"} |= "ERROR"

# Excluir ruido conocido (health checks)
{job="gitlab", component="nginx"} != "/-/health"

# Parsear el log JSON de la API y filtrar por status >= 500
{job="gitlab", component="rails"} | json | status >= 500

# Tasa de líneas de error por minuto (para graficar junto a métricas Prometheus)
sum(rate({job="gitlab", component="rails"} |= "ERROR" [1m]))

# Jobs de Sidekiq fallidos en los últimos 15 minutos
{job="gitlab", component="sidekiq"} |= "fail" [15m]

# Operaciones Gitaly con latencia alta (si el log incluye duración en ms)
{job="gitlab", component="gitaly"} | json | duration_ms > 1000
```

---

## ELK vs Loki: comparación

| Criterio | ELK (Elasticsearch) | Loki + Promtail |
|----------|---------------------|------------------|
| Qué indexa | Texto completo de cada log | Solo etiquetas (component, job, nivel) |
| Consumo de RAM/disco | Alto (varios GB incluso en instalaciones pequeñas) | Bajo — comparable al de Prometheus |
| Búsqueda de texto libre | Muy potente (full-text search) | Limitada — filtra sobre el stream ya seleccionado por etiquetas |
| Integración con Grafana | Requiere Kibana como UI separada | Nativa — mismo Grafana que ya visualiza Prometheus |
| Curva de aprendizaje | Mayor (Elasticsearch Query DSL) | Menor si ya se conoce PromQL (LogQL es similar) |
| Apropiado para | Volumen muy alto + necesidad de búsqueda de texto arbitraria | La mayoría de instalaciones GitLab self-managed, sobre todo si ya hay Grafana |

**Recomendación para este bootcamp**: Loki + Promtail, porque reutiliza el Grafana ya desplegado en `01-monitoreo-gitlab.md` — un solo stack de observabilidad (métricas + logs) en vez de dos UIs separadas (Grafana + Kibana).

---

## Mejores prácticas

- Centralizar logs desde el primer nodo, no esperar a tener HA multi-nodo — el hábito y la config ya están listos cuando el entorno crezca
- Etiquetar por `component` desde el recolector (Promtail/Filebeat) — filtrar después en la UI es más lento que filtrar en el origen
- Retención de logs: normalmente más corta que la de backups pero más larga que la de métricas crudas — 14-30 días es razonable para diagnóstico de incidentes recientes
- No centralizar logs con datos sensibles sin enmascarar (tokens, contraseñas) — revisar que `production.log` no filtre parámetros sensibles antes de enviarlo
- Correlacionar logs y métricas por timestamp: al ver un pico de latencia en el dashboard de Prometheus, saltar directo a los logs del mismo rango de tiempo en Loki
- Alertar también sobre logs, no solo métricas — un patrón de errores repetido en Sidekiq puede no reflejarse aún en las métricas de Prometheus

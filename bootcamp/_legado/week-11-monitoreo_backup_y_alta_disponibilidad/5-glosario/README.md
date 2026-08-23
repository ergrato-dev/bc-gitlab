# Glosario — Semana 11: Monitoreo, Backup y Alta Disponibilidad

| Término | Definición |
|---------|-----------|
| **Active-Active** | Configuración HA donde múltiples nodos sirven tráfico simultáneamente — contraste con active-passive donde el secundario espera inactivo |
| **Alertmanager** | Componente del ecosistema Prometheus que gestiona notificaciones de alertas: deduplicación, agrupación, enrutamiento y silenciado |
| **asíncrono (replicación)** | Modo donde el primario confirma la escritura al cliente sin esperar que la réplica confirme la recepción; mejor rendimiento, RPO > 0 |
| **Backup** | Copia de seguridad de datos y configuración que permite restaurar el sistema a un estado anterior en caso de pérdida o corrupción |
| **Checksum** | Hash criptográfico (ej: SHA256) calculado sobre un archivo backup para verificar que no fue corrompido durante almacenamiento o transferencia |
| **Consensus store** | Sistema distribuido (etcd, Consul, ZooKeeper) que mantiene un estado acordado entre nodos en un cluster; garantiza que solo un líder sea elegido |
| **Connection pooling** | Técnica donde un proxy (PgBouncer) mantiene conexiones persistentes a la BD y las reutiliza para múltiples clientes, reduciendo overhead de nueva conexión |
| **Dataloss** | Pérdida de datos; en el contexto de Praefect, repositorios desactualizados en nodos secundarios que divergen del primario |
| **DR** | Disaster Recovery: estrategia y procedimientos para recuperar sistemas después de un desastre mayor (fallo de datacenter, error humano catastrófico) |
| **Elasticsearch** | Motor de búsqueda e indexación distribuido usado por el stack ELK; indexa el texto completo de cada log para búsqueda de texto libre |
| **ELK** | Elasticsearch + Logstash + Kibana: stack de logging centralizado que indexa el contenido completo de los logs para búsqueda potente, a costo de mayor consumo de RAM/disco |
| **etcd** | Store de clave-valor distribuido y fuertemente consistente; consensus store más común para Patroni; requiere quorum (mayoría de nodos) para operar |
| **Exporter** | Componente que expone métricas en formato Prometheus desde un servicio; ejemplos: node_exporter (host), postgres_exporter (PostgreSQL), redis_exporter (Redis) |
| **Failover** | Proceso automático o manual de cambiar a un sistema de respaldo cuando el primario falla; en Patroni y Praefect es automático |
| **Federación** | Mecanismo de Prometheus para que una instancia scrapee las métricas de otra, permitiendo jerarquía de Prometheus entre datacenters |
| **Filebeat** | Agente ligero de Elastic que recolecta logs y los envía a Elasticsearch o Logstash; alternativa liviana a Logstash como recolector |
| **Geo** | Feature EE-only de GitLab que mantiene réplicas de solo lectura de la instancia completa en ubicaciones geográficas distintas, para DR entre datacenters y lectura de baja latencia en equipos distribuidos — a diferencia de Gitaly Cluster/Patroni, que replican dentro de un mismo cluster, no entre regiones |
| **GFS** | Grandfather-Father-Son: esquema de rotación de backups con retención diaria (7), semanal (4) y mensual (12) para optimizar espacio con cobertura temporal amplia |
| **Gitaly** | Servicio RPC de GitLab que maneja todas las operaciones de git (clone, push, pull, blame, diff); cada operación git pasa por Gitaly |
| **Gitaly Cluster** | Solución de HA para repositorios git que usa Praefect como proxy + múltiples nodos Gitaly con replicación entre ellos |
| **Grafana** | Plataforma de visualización que se conecta a Prometheus, Loki y otros datasources para crear dashboards interactivos, alertas y anotaciones |
| **HA** | High Availability: alta disponibilidad; capacidad de un sistema de permanecer operativo incluso si componentes individuales fallan |
| **HAProxy** | Load balancer y proxy TCP/HTTP de alta disponibilidad; detecta backends caídos automáticamente y redirige el tráfico a los saludables |
| **Health check** | Verificación periódica del estado de un servicio; HAProxy usa health checks para determinar si un backend puede recibir tráfico |
| **Keepalived** | Herramienta de alta disponibilidad para Linux que implementa VRRP para proporcionar IP virtual (VIP) compartida entre servidores |
| **Kibana** | Interfaz de visualización y búsqueda del stack ELK, conectada a Elasticsearch; equivalente en ELK a lo que Grafana es para Loki/Prometheus |
| **Lag (replicación)** | Diferencia en bytes o tiempo entre el estado del primario y la réplica; lag alto indica que la réplica está retrasada y no sería útil en failover |
| **LogQL** | Lenguaje de consultas de Loki, similar a PromQL: selecciona streams de log por etiquetas y aplica filtros de texto o parseo |
| **Logstash** | Componente del stack ELK que recolecta, transforma y envía logs a Elasticsearch; más pesado que Filebeat pero con transformaciones más ricas |
| **Loki** | Sistema de logging centralizado de Grafana Labs que indexa solo etiquetas (no el texto completo), mucho más liviano que Elasticsearch e integrado nativamente con Grafana |
| **MTTR** | Mean Time To Repair: tiempo promedio para resolver un incidente; métrica complementaria a RTO |
| **N+1** | Configuración donde hay un nodo extra respecto al mínimo operacional; si el sistema necesita N nodos para funcionar, N+1 permite la caída de 1 sin impacto |
| **Omnibus** | Paquete de instalación all-in-one de GitLab que incluye todos los servicios (Rails, Sidekiq, Gitaly, PostgreSQL, Redis, Nginx, Prometheus) en un solo proceso |
| **Patroni** | Herramienta de HA para PostgreSQL que maneja replicación streaming y failover automático usando un consensus store (etcd/Consul/ZooKeeper) |
| **PgBouncer** | Connection pooler para PostgreSQL; reduce la cantidad de conexiones activas y gestiona reconexión transparente durante failover del primario |
| **PITR** | Point-In-Time Recovery: capacidad de restaurar PostgreSQL a un momento específico usando backups base + WAL continuos; permite RPO muy bajo |
| **Praefect** | Proxy y coordinador de replicación de Gitaly Cluster; gestiona routing de operaciones git a nodos Gitaly y encola la replicación entre ellos |
| **PromQL** | Prometheus Query Language: lenguaje funcional para consultar métricas de series temporales almacenadas en Prometheus |
| **Prometheus** | Sistema de monitoreo y alertas que recolecta métricas en series temporales mediante pull (scraping) de exporters con HTTP |
| **Promtail** | Agente de Grafana Labs que recolecta logs (por ejemplo de `/var/log/gitlab/`) y los envía a Loki, etiquetándolos por job/componente |
| **Quorum** | Número mínimo de nodos que deben estar de acuerdo para tomar decisiones en un cluster distribuido; para etcd con 3 nodos, quorum = 2 |
| **Reconciliation** | Proceso de Praefect que detecta y corrige réplicas desactualizadas comparando el estado de cada nodo con el esperado según el replication factor |
| **Replicación síncrona** | Modo donde el primario espera que la réplica confirme la recepción del WAL antes de confirmar la transacción al cliente; RPO ≈ 0, mayor latencia |
| **Replication Factor** | Número de copias de cada repositorio mantenidas en Gitaly Cluster; factor 3 = cada repo existe en 3 nodos Gitaly y tolera la caída de 2 |
| **Repmgr** | Herramienta de replicación y failover para PostgreSQL; más simple que Patroni pero sin protección fuerte de split-brain |
| **Retention** | Período de tiempo durante el cual se conservan los backups antes de ser eliminados; equilibrio entre espacio de disco y capacidad de recuperación histórica |
| **RPO** | Recovery Point Objective: cantidad máxima de datos que se acepta perder en un incidente, expresado en tiempo (ej: RPO 1h = se toleran máximo 1h de pérdida de datos) |
| **RTO** | Recovery Time Objective: tiempo máximo aceptable para restaurar el servicio después de un fallo (ej: RTO 30min = el servicio debe estar en línea en 30 minutos) |
| **Runbook** | Documento operacional que describe paso a paso cómo responder a un incidente específico; reduce el tiempo de respuesta al eliminar la necesidad de improvizar |
| **Scraping** | Proceso de Prometheus de realizar peticiones HTTP GET periódicas a los endpoints de métricas de los exporters para recolectar datos |
| **SLA** | Service Level Agreement: acuerdo formal de disponibilidad entre proveedor y cliente; típicamente expresado como porcentaje de uptime mensual/anual |
| **Sidekiq** | Sistema de procesamiento de trabajos en segundo plano de GitLab; procesa emails, webhooks, CI/CD pipeline scheduling, imports/exports |
| **SPOF** | Single Point of Failure: componente cuya falla individual interrumpe todo el servicio; el objetivo de HA es eliminar todos los SPOFs críticos |
| **split-brain** | Condición peligrosa donde dos nodos creen ser el primario simultáneamente y aceptan escrituras divergentes; el consensus store previene esto |
| **Switchover** | Failover planificado y controlado donde el primario transfiere el rol al secundario de forma ordenada; contraste con failover de emergencia |
| **VIP** | Virtual IP: dirección IP flotante gestionada por Keepalived que migra automáticamente entre servidores cuando el MASTER falla |
| **VRRP** | Virtual Router Redundancy Protocol: protocolo que Keepalived usa para coordinar la VIP entre nodos mediante mensajes periódicos (advertisements) |
| **WAL** | Write-Ahead Log: registro de todos los cambios en PostgreSQL escrito antes de aplicarlos a los datos; usado para replicación streaming y PITR |
| **WAL shipping** | Modo de replicación donde los archivos WAL completos se transfieren a la réplica (más lento); contraste con streaming replication |

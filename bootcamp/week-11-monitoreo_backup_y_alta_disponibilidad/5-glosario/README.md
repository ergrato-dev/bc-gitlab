# Glosario — Semana 11

| Término | Definición |
|---------|-----------|
| **Prometheus** | Sistema de monitoreo y alertas que recolecta métricas en series temporales mediante scraping de exporters |
| **Grafana** | Plataforma de visualización que se conecta a Prometheus (y otros datasources) para crear dashboards y alertas |
| **Exporter** | Componente que expone métricas en formato Prometheus desde un servicio (node_exporter, postgres_exporter, redis_exporter) |
| **Dashboard** | Panel visual en Grafana que agrupa gráficos, tablas y alertas sobre métricas de un sistema |
| **RTO** | Recovery Time Objective: tiempo máximo aceptable para restaurar el servicio después de un fallo |
| **RPO** | Recovery Point Objective: cantidad máxima de datos que se acepta perder, medido en tiempo |
| **HA** | High Availability: alta disponibilidad, capacidad de un sistema de permanecer operativo incluso si componentes fallan |
| **SPOF** | Single Point of Failure: punto único de fallo, componente cuya falla interrumpe todo el servicio |
| **Failover** | Proceso automático o manual de cambiar a un sistema de respaldo cuando el primario falla |
| **Patroni** | Herramienta de HA para PostgreSQL que maneja replicación y failover automático usando etcd/Consul/ZooKeeper |
| **Repmgr** | Herramienta de replicación y failover para PostgreSQL de 2ndQuadrant, más simple que Patroni |
| **Praefect** | Proxy de Gitaly que maneja replicación de repositorios git entre múltiples nodos Gitaly |
| **Gitaly Cluster** | Solución de HA para repositorios git que usa Praefect + múltiples nodos Gitaly |
| **Replication Factor** | Cantidad de copias de un repositorio mantenidas en Gitaly Cluster para tolerancia a fallos |
| **WAL** | Write-Ahead Log: registro de cambios de PostgreSQL usado para replicación y recuperación punto en el tiempo (PITR) |
| **PITR** | Point-In-Time Recovery: capacidad de restaurar PostgreSQL a un momento específico usando backups + WAL |
| **Keepalived** | Herramienta de alta disponibilidad para Linux que proporciona IP virtual (VIP) compartida entre servidores |
| **VIP** | Virtual IP: dirección IP flotante compartida entre servidores para failover transparente |
| **PgBouncer** | Connection pooler para PostgreSQL que reduce la cantidad de conexiones y maneja reconexión en failover |
| **DR** | Disaster Recovery: estrategia y procedimientos para recuperar sistemas después de un desastre mayor |
| **Sidekiq** | Sistema de procesamiento de trabajos en segundo plano usado por GitLab para tareas asíncronas |

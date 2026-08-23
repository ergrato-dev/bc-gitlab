# 04 — PostgreSQL Alta Disponibilidad: Patroni y Repmgr

PostgreSQL es el componente más crítico de GitLab. Todo el estado de la aplicación —usuarios, proyectos, issues, MRs, variables CI/CD— vive en la base de datos. Una pérdida de la DB sin réplica significa perder toda la plataforma. La HA de PostgreSQL es la primera y más importante capa de resiliencia.

---

## Tipos de replicación en PostgreSQL

PostgreSQL soporta dos modos de replicación, y la elección impacta directamente en el RPO:

### Replicación asíncrona (por defecto)

```
Primario → WAL → envía a réplica → réplica aplica → confirma
                  (no espera confirmación de réplica antes de confirmar al cliente)
```

- Mejor rendimiento — la escritura confirma sin esperar a la réplica
- RPO ≠ 0: si el primario falla justo después de una escritura, pueden perderse los WALs no replicados
- Adecuado para: RPO de minutos, operaciones de escritura frecuentes

### Replicación síncrona

```
Primario → WAL → réplica confirma recepción → ENTONCES primario confirma al cliente
```

- RPO ≈ 0: toda transacción confirmada está en al menos una réplica
- Latencia mayor: el primario espera a que la réplica confirme antes de responder
- Adecuado para: RPO crítico cercano a 0, menor throughput de escritura aceptable

```sql
-- Configurar en postgresql.conf del primario
synchronous_commit = on
synchronous_standby_names = 'FIRST 1 (replica-1, replica-2)'
-- "FIRST 1" = esperar que al menos 1 réplica de la lista confirme
```

---

## Patroni: HA automática con consensus store

Patroni es el estándar de facto para PostgreSQL HA. Usa un consensus store distribuido (etcd, Consul o ZooKeeper) para coordinar cuál nodo es el líder y manejar failover automático sin intervención humana.

### Arquitectura Patroni

```
                    ┌──────────────────┐
                    │   etcd cluster   │ ← Consensus store (quorum)
                    │  (3 nodos mín.)  │
                    └────────┬─────────┘
                             │ Leader lock
            ┌────────────────┼────────────────┐
            │                │                │
     [PG Primary]      [PG Replica 1]   [PG Replica 2]
     Patroni agent      Patroni agent    Patroni agent
     puerto: 5432       puerto: 5432     puerto: 5432
     puerto: 8008       puerto: 8008     puerto: 8008
                             │
                        [PgBouncer]  ← Proxy de conexiones
                             │
                      [GitLab Rails]
```

### Instalación y configuración de Patroni

```bash
# En cada nodo PostgreSQL (Ubuntu/Debian)
sudo apt install patroni etcd-client python3-etcd

# Verificar que Patroni puede comunicarse con etcd
etcdctl --endpoints=http://192.168.1.41:2379 endpoint health
```

```yaml
# /etc/patroni/patroni.yml (repetir en cada nodo con sus propias IPs)
# ¿QUÉ HACE?: Configura Patroni para gestionar PostgreSQL con failover via etcd
# ¿POR QUÉ?: Sin Patroni, el failover de PostgreSQL requiere intervención manual
# ¿PARA QUÉ?: Failover automático en < 30 segundos cuando el primario falla
scope: gitlab-ha
namespace: /db/
name: pg-node-1   # Cambiar en cada nodo: pg-node-1, pg-node-2, pg-node-3

etcd:
  hosts: 192.168.1.41:2379,192.168.1.42:2379,192.168.1.43:2379

restapi:
  listen: 0.0.0.0:8008
  connect_address: 192.168.1.21:8008

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576  # 1MB de lag máximo para ser elegible como líder
    synchronous_mode: false            # Cambiar a true para replicación síncrona
  
  initdb:
    - encoding: UTF8
    - data-checksums        # Detectar corrupción silenciosa de disco
  
  postgresql:
    use_pg_rewind: true     # Permite resincronizar un nodo sin reclonar desde cero
    use_slots: true
    parameters:
      wal_level: replica
      hot_standby: "on"
      max_wal_senders: 10
      max_replication_slots: 10
      wal_log_hints: "on"   # Requerido para pg_rewind
      archive_mode: "on"
      archive_command: "cp %p /var/lib/postgresql/wal_archive/%f"

postgresql:
  listen: 0.0.0.0:5432
  connect_address: 192.168.1.21:5432
  data_dir: /var/lib/postgresql/14/main
  bin_dir: /usr/lib/postgresql/14/bin
  pgpass: /tmp/pgpass0
  authentication:
    replication:
      username: replicator
      password: replication-password
    superuser:
      username: postgres
      password: postgres-password

tags:
  nofailover: false
  noloadbalance: false
  clonefrom: false
  nosync: false
```

```bash
# Iniciar Patroni en el primer nodo (se convierte en primario)
sudo systemctl enable patroni
sudo systemctl start patroni

# Verificar estado del clúster
patronictl -c /etc/patroni/patroni.yml list

# Output esperado:
# + Cluster: gitlab-ha (7277642897881358435) +---------+----+-----------+
# | Member    | Host             | Role    | State   | TL | Lag in MB |
# +-----------+------------------+---------+---------+----+-----------+
# | pg-node-1 | 192.168.1.21:5432 | Leader | running | 1 |           |
# | pg-node-2 | 192.168.1.22:5432 | Replica | running | 1 | 0         |
# | pg-node-3 | 192.168.1.23:5432 | Replica | running | 1 | 0         |
```

### Simular failover con Patroni

```bash
# ¿QUÉ HACE?: Simula un failover controlado (switchover) del primario
# ¿POR QUÉ?: Probar que el failover funciona en mantenimiento planificado
# ¿PARA QUÉ?: Actualizar el nodo primario sin downtime (modo rolling)
patronictl -c /etc/patroni/patroni.yml switchover gitlab-ha

# Patroni elige automáticamente el mejor candidato (menor lag)
# GitLab detecta el nuevo primario via PgBouncer y reconecta automáticamente

# Ver el historial de failovers
patronictl -c /etc/patroni/patroni.yml history gitlab-ha
```

---

## PgBouncer: connection pooling para HA

PgBouncer actúa como proxy de conexiones entre GitLab y PostgreSQL. En un entorno HA es esencial porque:

1. **Reduce conexiones**: GitLab Rails puede abrir muchas conexiones — PgBouncer las consolida
2. **Transparencia en failover**: cuando el primario cambia, PgBouncer reconecta automáticamente
3. **Separación de lectura/escritura**: PgBouncer puede enrutar lecturas a réplicas

```ini
# /etc/pgbouncer/pgbouncer.ini
# ¿QUÉ HACE?: Configura PgBouncer como pool de conexiones para GitLab
# ¿POR QUÉ?: Sin pool, GitLab puede agotar las conexiones de PostgreSQL bajo carga
# ¿PARA QUÉ?: Manejar reconexión transparente durante failover de PostgreSQL
[databases]
gitlabhq_production = host=localhost port=5432 dbname=gitlabhq_production

[pgbouncer]
listen_addr = 0.0.0.0
listen_port = 6432
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction          # Transaction pooling: más eficiente para GitLab Rails
max_client_conn = 1000           # Conexiones máximas que acepta de GitLab
default_pool_size = 20           # Conexiones por pool hacia PostgreSQL
reserve_pool_size = 5
server_idle_timeout = 60
```

```ruby
# gitlab.rb — conectar GitLab a PgBouncer en lugar de directamente a PostgreSQL
# ¿QUÉ HACE?: GitLab conecta al pool de conexiones, no directamente a PostgreSQL
# ¿POR QUÉ?: PgBouncer gestiona el reconexión automática durante failover
# ¿PARA QUÉ?: GitLab no necesita saber la IP del primario actual — PgBouncer lo sabe
gitlab_rails['db_host']     = '127.0.0.1'  # PgBouncer local o en servidor separado
gitlab_rails['db_port']     = 6432          # Puerto de PgBouncer
gitlab_rails['db_database'] = 'gitlabhq_production'
```

---

## Repmgr: alternativa más simple (sin consensus store)

Repmgr no requiere etcd/Consul. Usa un daemon (`repmgrd`) que monitorea el primario y promueve una réplica si falla. Más simple de operar pero menos robusto que Patroni (no tiene protection de split-brain tan fuerte).

```bash
# ¿QUÉ HACE?: Configuración básica de Repmgr en el primario
# ¿POR QUÉ?: Alternativa cuando etcd/Consul no están disponibles o configuración es compleja
# ¿PARA QUÉ?: HA básica de PostgreSQL con failover semi-automático

# En el primario
cat > /etc/repmgr.conf << 'EOF'
node_id=1
node_name=pg-primary
conninfo='host=192.168.1.21 user=repmgr dbname=repmgr'
data_directory='/var/lib/postgresql/14/main'
failover=automatic
promote_command='/usr/bin/repmgr standby promote -f /etc/repmgr.conf'
follow_command='/usr/bin/repmgr standby follow -f /etc/repmgr.conf --upstream-node-id=%n'
EOF

# Registrar el primario
repmgr -f /etc/repmgr.conf primary register

# En cada réplica — clonar y registrar
repmgr -h 192.168.1.21 -U repmgr -d repmgr -f /etc/repmgr.conf standby clone
repmgr -f /etc/repmgr.conf standby register

# Ver el estado del cluster
repmgr -f /etc/repmgr.conf cluster show
```

---

## Monitoreo de PostgreSQL HA

```bash
# ¿QUÉ HACE?: Verifica el estado de replicación en tiempo real
# ¿POR QUÉ?: El lag de replicación creciente indica problemas antes del failover
# ¿PARA QUÉ?: Detectar réplicas rezagadas antes de que se vuelvan inutilizables como failover

# En el primario: ver estado de todas las réplicas
sudo -u postgres psql -c "
SELECT 
  application_name,
  client_addr,
  state,
  sync_state,
  pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn) AS bytes_not_sent,
  pg_wal_lsn_diff(sent_lsn, replay_lsn) AS bytes_replay_lag,
  (now() - reply_time) AS time_since_last_reply
FROM pg_stat_replication;
"

# Métricas de Prometheus para monitoreo de replicación
# pg_stat_replication_pg_wal_lsn_diff → lag en bytes
# pg_replication_slots_active → réplicas activas
# pg_stat_database_deadlocks → deadlocks (indican contención)
```

---

## Mejores prácticas

- Usar Patroni sobre Repmgr para nuevas instalaciones — mejor protección contra split-brain
- Mínimo 3 nodos etcd (o Consul) para quorum — con 2 nodos, si uno falla, se pierde quorum
- Configurar `maximum_lag_on_failover` — no promover una réplica muy retrasada
- Probar el failover mensualmente — `patronictl switchover` no es destructivo
- PgBouncer en modo `transaction` para GitLab — mejor rendimiento que `session` pooling
- Configurar `use_pg_rewind: true` — permite resincronizar un nodo antiguo sin reclonar completo
- Monitorear el lag de replicación en Grafana — alertar si supera 60 segundos

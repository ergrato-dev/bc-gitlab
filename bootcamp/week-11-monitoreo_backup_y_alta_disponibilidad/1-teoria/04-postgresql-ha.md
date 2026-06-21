# 04 — PostgreSQL Alta Disponibilidad: Patroni y Repmgr

PostgreSQL es el componente más crítico de GitLab y requiere una estrategia de HA robusta para evitar pérdida de datos.

## Arquitecturas de replicación

**Streaming Replication nativa de PostgreSQL**: El primario envía cambios (WAL) a las réplicas en tiempo real. Puede ser síncrona (el primario espera confirmación de al menos una réplica antes de confirmar la transacción) o asíncrona (sin espera).

## Patroni (Recomendado para HA)

Patroni es un template de HA para PostgreSQL que usa un distributed consensus store (etcd, Consul o ZooKeeper) para manejar failover automático. Flujo:
1. Patroni monitorea continuamente el primario
2. Si detecta fallo, inicia una elección de líder
3. El líder elegido promueve una réplica a primario
4. Actualiza el VIP o la configuración de conexión

Configuración mínima de Patroni:
```yaml
# patroni.yml
etcd:
  host: 192.168.1.10:2379
postgresql:
  listen: 0.0.0.0:5432
  connect_address: 192.168.1.11:5432
  use_pg_rewind: true
  parameters:
    wal_level: replica
    hot_standby: "on"
    max_wal_senders: 5
```

## Repmgr (Alternativa)

Repmgr es una herramienta de 2ndQuadrant para gestión de replicación y failover. Es más simple que Patroni pero requiere más intervención manual. Flujo:
1. Registrar primario con `repmgr primary register`
2. Clonar standby con `repmgr standby clone`
3. Registrar standby con `repmgr standby register`
4. Monitorear con `repmgrd` (daemon)
5. Failover manual con `repmgr standby promote` o automático con repmgrd

## PgBouncer para Connection Pooling

En escenarios HA con múltiples nodos Rails conectándose a PostgreSQL, se recomienda PgBouncer para:
- Reducir la cantidad de conexiones abiertas
- Manejar reconexión transparente durante failover
- Soportar transaction pooling y session pooling

## Consideraciones de consistencia

- Replicación síncrona garantiza 0 pérdida de datos pero añade latencia
- Replicación asíncrona es más rápida pero puede perder transacciones no replicadas en failover
- Para GitLab CE con RPO ~0, se requiere replicación síncrona + WAL archiving a S3

# 03 — Alta Disponibilidad: Visión General

La alta disponibilidad (HA) en GitLab busca eliminar puntos únicos de fallo (SPOFs) para garantizar que el servicio permanezca accesible incluso si componentes individuales fallan.

## Componentes críticos y sus SPOFs

| Componente | ¿Es SPOF? | Solución HA |
|-----------|-----------|-------------|
| GitLab Rails (Puma) | Sí | Balanceador de carga + múltiples nodos |
| PostgreSQL | Sí | Patroni/Repmgr con replicación |
| Redis | Sí | Redis Sentinel o Cluster |
| Gitaly | Sí | Gitaly Cluster con Praefect |
| Sidekiq | No (pueden ser múltiples) | Múltiples nodos Sidekiq |
| Nginx/HAProxy | Sí | Balanceador redundante con keepalived |
| Container Registry | Sí | Registry replicado con almacenamiento S3 |

## Niveles de disponibilidad

**Nivel 1 — Sin HA (single node)**:
Todo en un solo servidor. Apropiado para desarrollo o equipos pequeños. El downtime planificado por mantenimiento es aceptable.

**Nivel 2 — HA básica (3 nodos)**:
- 1 balanceador + 1 app + 1 DB/Redis
- Componentes separados pero sin redundancia individual
- RTO: ~1 hora, RPO: ~24 horas

**Nivel 3 — HA completa (7+ nodos)**:
- 2 balanceadores (keepalived VIP)
- 3 GitLab Rails + Sidekiq
- 3 PostgreSQL (1 primario + 2 réplicas con Patroni)
- 3 Redis (1 maestro + 2 réplicas con Sentinel)
- 3 Gitaly (Gitaly Cluster con Praefect)
- RTO: < 5 minutos, RPO: ~0 (con WAL archiving)

## Balanceo de carga

El tráfico entrante se distribuye entre múltiples nodos Rails usando HAProxy o Nginx en modo reverse proxy. Configuración clave:
- Health checks para detectar nodos caídos
- Sticky sessions para operaciones que requieren consistencia
- SSL termination en el balanceador

## RTO y RPO

- **RTO (Recovery Time Objective)**: tiempo máximo aceptable para restaurar el servicio después de un fallo. Determina la arquitectura HA necesaria.
- **RPO (Recovery Point Objective)**: cantidad máxima de datos que se acepta perder. Determina la estrategia de backup (diario = 24h RPO, WAL continuo = ~0 RPO).

## Consideraciones de red

- Todos los componentes deben comunicarse en red privada de baja latencia (< 1ms)
- PostgreSQL requiere latencia especialmente baja para replicación síncrona
- Gitaly es sensible a latencia de red por operaciones git
- Usar redes separadas para tráfico interno vs externo

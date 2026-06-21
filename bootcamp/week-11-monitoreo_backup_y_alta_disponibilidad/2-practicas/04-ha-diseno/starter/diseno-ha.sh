# ============================================
# Practica 04 — Diseno de Arquitectura HA
# ============================================
# Documento de referencia para disenar HA.
# NO es un script ejecutable.

echo "=== Practica 04: Diseno HA ==="
echo ""

cat << 'DESIGN'
## Escenario: CloudServ — 500 desarrolladores
Requerimientos: RTO < 10 min, RPO < 1 hora, sin cloud services externos.

## Arquitectura Propuesta (Nivel 2 — HA basica)

```
                 ┌─────────────────┐
  Developers ──→ │ HAProxy x2      │ (VIP via keepalived)
                 │ (balanceadores) │
                 └────────┬────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
  ┌───────▼──────┐ ┌──────▼───────┐ ┌─────▼──────┐
  │ Rails Node 1 │ │ Rails Node 2 │ │ Sidekiq x2 │
  └───────┬──────┘ └──────┬───────┘ └─────┬──────┘
          │               │               │
          └───────────────┼───────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
  ┌───────▼──────┐ ┌──────▼───────┐ ┌─────▼──────┐
  │ Patroni PGx3 │ │ Redis Sent.  │ │ Gitaly x3  │
  │ (etcd quorum)│ │ (quorum x3)  │ │ (Praefect)  │
  └──────────────┘ └──────────────┘ └────────────┘
          │               │               │
          └───────────────┼───────────────┘
                          │
                   ┌──────▼──────┐
                   │ NFS / MinIO │  (almacenamiento compartido)
                   └─────────────┘
```

## Componentes
| Componente | Nodos | Solucion HA | Justificacion |
|-----------|-------|-------------|---------------|
| Balanceador | 2 | HAProxy + keepalived | VIP failover, SSL termination |
| GitLab Rails | 2 | Puma workers | Sin estado, balanceo round-robin |
| PostgreSQL | 3 | Patroni + etcd | Failover automatico, WAL sync |
| Redis | 3 | Redis Sentinel | Quorum, failover sub-segundo |
| Gitaly | 3 | Praefect | Replication factor 3, tolera 2 fallos |
| Sidekiq | 2 | Redis queues | Sin estado, escalable horizontal |
| Almacenamiento | 1 | NFS/MinIO | Compartido entre nodos Rails |
DESIGN
echo ""

# ── Runbooks ──
echo "--- Runbooks minimos ---"
cat << 'RUNBOOKS'
1. Failover PostgreSQL:
   patronictl -c /etc/patroni.yml switchover

2. Failover Redis:
   redis-cli -h <sentinel> -p 26379 SENTINEL failover mymaster

3. Restore desde backup:
   Ver restore.sh de Practica 03

4. Escalar Rails (agregar nodo):
   gitlab-ctl reconfigure en nuevo nodo + agregar a HAProxy backend
RUNBOOKS
echo ""

echo "=== Practica 04 completada ==="

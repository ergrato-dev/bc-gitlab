# Práctica 04 — Diseño y Simulación de Alta Disponibilidad

## Objetivo

Diseñar la arquitectura HA completa para un GitLab de producción con carga realista, simular escenarios de fallo, calcular el RTO/RPO esperado para cada componente y documentar los runbooks de respuesta a incidentes. Esta práctica es de diseño y razonamiento — no requiere infraestructura, pero sí decisiones técnicas justificadas.

## Requisitos

- Haber completado la teoría de las semanas 11 (todas las unidades)
- Acceso a GitLab CE para consultar APIs de healthcheck
- Editor de texto para diagramas y documentación
- Tiempo estimado: 75-90 minutos

---

## Escenario: TechScale S.A.

TechScale es una empresa de software con:
- **150 desarrolladores** activos, pico de 80 concurrentes
- **800 proyectos** activos (400 con CI/CD habilitado)
- **200 pipelines/hora** en horas pico, promedio 5 minutos cada uno
- **SLA requerido**: 99.9% uptime (8.76 horas downtime/año máximo)
- **RTO objetivo**: 30 minutos (máximo tolerable de pérdida de acceso)
- **RPO objetivo**: 1 hora (máximo tolerable de pérdida de datos)
- **Presupuesto**: 3 servidores físicos de 32 cores / 64GB RAM + almacenamiento compartido

---

## Parte 1: Diseño de la Arquitectura HA

### Ejercicio 1.1 — Identificar y clasificar los SPOFs

Completar la tabla de componentes con su criticidad y estrategia de HA:

| Componente | ¿SPOF en single-node? | Estrategia de HA | Herramienta | RTO estimado si falla |
|-----------|:---------------------:|-----------------|-------------|----------------------|
| GitLab Rails (Puma) | ✅ | Múltiples instancias + LB | HAProxy | < 1 min (auto) |
| Sidekiq | ✅ | Múltiples workers | Systemd / K8s | < 2 min (auto) |
| PostgreSQL | ✅ | Replicación + Patroni | Patroni + etcd | < 30 seg (auto) |
| Gitaly | ✅ | Gitaly Cluster + Praefect | Praefect (3 nodos) | < 1 min (auto) |
| Redis | ✅ | Redis Sentinel | Sentinel (3 nodos) | < 30 seg (auto) |
| HAProxy/LB | ✅ | Keepalived VIP | Keepalived (2 LBs) | < 10 seg (auto) |
| Almacenamiento | ✅ | S3/Object Storage | MinIO HA o AWS S3 | N/A (objeto) |
| Praefect | Parcial | Múltiples instancias | HAProxy (2 Praefect) | < 1 min |
| etcd | ✅ (si < 3) | Cluster de 3+ nodos | etcd nativo | < 10 seg |

```bash
# ¿QUÉ HACE?: Script de inventario de SPOFs activos en una instancia
# ¿POR QUÉ?: En single-node todo es SPOF, pero es útil identificar los críticos primero
# ¿PARA QUÉ?: Priorizar qué componente redundar primero según impacto

GITLAB_URL="${1:-http://localhost}"
ADMIN_TOKEN="${2:-$GITLAB_TOKEN}"

echo "=== Análisis de componentes GitLab ==="
curl -s "${GITLAB_URL}/api/v4/application/statistics" \
  -H "PRIVATE-TOKEN: $ADMIN_TOKEN" | jq '{
  active_users,
  projects,
  pipelines: .ci_pipelines
}'

# Verificar si hay redundancia en los health checks
echo ""
echo "=== Health endpoints ==="
for endpoint in /readiness /liveness /-/health; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${GITLAB_URL}${endpoint}")
  echo "$endpoint → HTTP $STATUS"
done
```

### Ejercicio 1.2 — Diagrama de la arquitectura objetivo

Dibujar (en texto ASCII o Mermaid) la arquitectura HA para TechScale. La arquitectura debe incluir todos los componentes del ejercicio 1.1 con al menos N+1 redundancia en los críticos.

```
Arquitectura HA propuesta para TechScale S.A.
════════════════════════════════════════════

                    ┌─── Usuarios / CI Runners ───┐
                    │                              │
                    ▼                              ▼
          ┌──────────────────┐          ┌──────────────────┐
          │   HAProxy LB-1   │          │   HAProxy LB-2   │
          │  + Keepalived    │◄────────►│  + Keepalived    │
          │  VIP: 10.0.1.10  │  VRRP    │  (BACKUP)        │
          └────────┬─────────┘          └──────────────────┘
                   │
         ┌─────────┼─────────┐
         ▼         ▼         ▼
   ┌──────────┐ ┌──────────┐ ┌──────────┐
   │ Rails-1  │ │ Rails-2  │ │ Rails-3  │   ← GitLab Puma + Workhorse
   │ 10.0.2.1 │ │ 10.0.2.2 │ │ 10.0.2.3 │
   └────┬─────┘ └────┬─────┘ └────┬─────┘
        │            │            │
        └────────────┼────────────┘
                     │
         ┌───────────┼──────────────┐
         ▼           ▼              ▼
   ┌──────────┐  ┌────────────┐  ┌────────────┐
   │Praefect-1│  │ PgBouncer  │  │   Redis    │
   │10.0.3.1  │  │ 10.0.4.1   │  │ Sentinel   │
   │Praefect-2│  └─────┬──────┘  │ 3 nodos    │
   │10.0.3.2  │        │         └────────────┘
   └────┬─────┘        ▼
        │         ┌─────────────────────┐
        │         │  PostgreSQL Patroni  │
        │         │  Primary: 10.0.5.1  │
        │         │  Replica: 10.0.5.2  │
        │         │  Replica: 10.0.5.3  │
        │         └─────────────────────┘
        ▼                    │
   ┌─────────────────┐       ▼
   │ Gitaly Cluster  │  ┌──────────┐
   │ Gitaly-1: .6.1  │  │   etcd   │
   │ Gitaly-2: .6.2  │  │ 3 nodos  │
   │ Gitaly-3: .6.3  │  │ 10.0.7.x │
   └─────────────────┘  └──────────┘
```

### Ejercicio 1.3 — Calcular el uptime teórico

Con la arquitectura propuesta, calcular el uptime esperado:

```
Fórmula de uptime de sistema paralelo (N+1):
Uptime_total = 1 - (Probabilidad de que TODOS los nodos fallen)

Si cada nodo tiene uptime = 99.9% (3 nodos independientes):
Uptime_cluster = 1 - (1-0.999)^3 = 1 - 0.000000001 = 99.9999999% 

Nota: en práctica, el cuello de botella es el proceso de failover, no el hardware.
El RTO real (tiempo que el servicio está degradado durante un failover) es lo que
determina el uptime percibido por el usuario.
```

```bash
# Calcular uptime mensual con downtime registrado
echo "=== Cálculo de SLA ==="
TOTAL_MINUTOS_MES=43200  # 30 días × 24h × 60min
DOWNTIME_MINUTOS=15  # Ejemplo: 15 minutos de downtime este mes

UPTIME_PCT=$(echo "scale=4; (1 - $DOWNTIME_MINUTOS/$TOTAL_MINUTOS_MES) * 100" | bc)
echo "Uptime del mes: ${UPTIME_PCT}%"
echo "Downtime: ${DOWNTIME_MINUTOS} minutos"

if (( $(echo "$UPTIME_PCT >= 99.9" | bc -l) )); then
  echo "✅ SLA cumplido (objetivo: 99.9%)"
else
  echo "❌ SLA incumplido (objetivo: 99.9%)"
fi
```

---

## Parte 2: Simulación de Escenarios de Fallo

### Ejercicio 2.1 — Scenario: fallo del nodo Rails

```bash
# Simular fallo de un nodo Rails y verificar que HAProxy redirige

# 1. Ver el estado inicial de los backends en HAProxy
echo "show stat" | sudo socat stdio /var/run/haproxy/admin.sock | \
  grep "gitlab_rails_backend" | cut -d',' -f1,2,18

# 2. Marcar backend como DOWN desde HAProxy (no destructivo)
echo "disable server gitlab_rails_backend/rails-1" | \
  sudo socat stdio /var/run/haproxy/admin.sock

# 3. Verificar que el tráfico sigue fluyendo a los otros backends
for i in {1..10}; do
  curl -s -o /dev/null -w "HTTP %{http_code} from %{remote_ip}\n" http://localhost/
done

# 4. Verificar que HAProxy detectó el backend DOWN
echo "show stat" | sudo socat stdio /var/run/haproxy/admin.sock | \
  grep "gitlab_rails_backend" | cut -d',' -f1,2,18,19

# 5. Restaurar el backend
echo "enable server gitlab_rails_backend/rails-1" | \
  sudo socat stdio /var/run/haproxy/admin.sock

# Registrar: tiempo hasta que HAProxy detectó la caída
# Registrar: ¿alguna petición retornó error durante el fallo?
```

### Ejercicio 2.2 — Escenario: failover de PostgreSQL

```bash
# Simular y observar el proceso de failover automático de Patroni

# 1. Verificar estado inicial del cluster
patronictl -c /etc/patroni/patroni.yml list

# 2. Identificar el nodo primario
PRIMARY=$(patronictl -c /etc/patroni/patroni.yml list | grep "Leader" | awk '{print $2}')
echo "Primario actual: $PRIMARY"

# 3. Medir RTO iniciando un timer
echo "⏱️ Iniciando simulación de failover: $(date +%T)"
FAILOVER_START=$(date +%s)

# 4. Ejecutar switchover (no destructivo — Patroni gestiona la transición)
patronictl -c /etc/patroni/patroni.yml switchover gitlab-ha --force

# 5. Monitorear hasta que el nuevo primario esté activo
until patronictl -c /etc/patroni/patroni.yml list 2>/dev/null | grep -q "Leader"; do
  echo -n "."
  sleep 2
done

FAILOVER_TIME=$(($(date +%s) - FAILOVER_START))
echo ""
echo "✅ Failover completado en ${FAILOVER_TIME}s"
patronictl -c /etc/patroni/patroni.yml list

# 6. Verificar que GitLab Rails detectó el nuevo primario
curl -s http://localhost/-/readiness | jq '.master_check'
```

### Ejercicio 2.3 — Escenario: caída del nodo LB con VIP failover

```bash
# Simular fallo del HAProxy primario y verificar que el VIP migra

# 1. Estado inicial del VIP
ip addr show | grep "10.0.1.10" && echo "VIP activo en este nodo" || echo "VIP en otro nodo"

# 2. Verificar que keepalived está en MASTER
sudo systemctl status keepalived | grep -E "MASTER|BACKUP"

# 3. Detener keepalived en el nodo MASTER (simular caída)
echo "⚠️  Simulando caída del LB primario..."
sudo systemctl stop keepalived
sleep 5

# 4. Desde el nodo BACKUP, verificar que el VIP migró
# (ejecutar en el nodo BACKUP)
ip addr show | grep "10.0.1.10" && echo "✅ VIP migrado a BACKUP" || echo "❌ VIP no migrado"

# 5. Restaurar
sudo systemctl start keepalived
sleep 10
sudo systemctl status keepalived | grep -E "MASTER|BACKUP"
```

---

## Parte 3: Runbooks de Respuesta a Incidentes

### Runbook 3.1 — GitLab no accesible (HTTP 502/503)

```bash
#!/bin/bash
# RUNBOOK: GitLab no responde o responde con 502/503
# Tiempo esperado de diagnóstico: 5-10 minutos

echo "=== RUNBOOK: GitLab 502/503 ==="
echo "Inicio: $(date)"

# Paso 1: Verificar si es el LB o GitLab
echo ""
echo "1. Verificar HAProxy directamente (bypass LB)"
HTTP_DIRECT=$(curl -s -o /dev/null -w "%{http_code}" http://10.0.2.1/)
HTTP_LB=$(curl -s -o /dev/null -w "%{http_code}" http://10.0.1.10/)
echo "   LB: HTTP $HTTP_LB | Directo a Rails-1: HTTP $HTTP_DIRECT"

if [ "$HTTP_DIRECT" = "200" ] || [ "$HTTP_DIRECT" = "302" ]; then
  echo "   → Problema en LB/HAProxy, no en Rails"
  echo "   → Verificar keepalived: sudo systemctl status keepalived"
  echo "   → Ver errores HAProxy: sudo tail -50 /var/log/haproxy.log"
  exit 0
fi

# Paso 2: Verificar estado de servicios en todos los nodos Rails
echo ""
echo "2. Estado de servicios Rails"
for NODE in 10.0.2.1 10.0.2.2 10.0.2.3; do
  echo -n "   $NODE → "
  ssh "$NODE" "sudo gitlab-ctl status puma" 2>/dev/null | head -1 || echo "SSH timeout"
done

# Paso 3: Verificar PostgreSQL
echo ""
echo "3. Verificar PostgreSQL"
patronictl -c /etc/patroni/patroni.yml list 2>/dev/null || \
  echo "   ❌ Patroni no responde — verificar etcd"

# Paso 4: Ver últimas líneas de log de Rails
echo ""
echo "4. Últimos errores en Rails"
sudo tail -20 /var/log/gitlab/puma/puma_stderr.log 2>/dev/null | \
  grep -E "(ERROR|FATAL|Errno)" | head -5

echo ""
echo "=== FIN DIAGNÓSTICO. Escalar si no resuelto en 10min ==="
```

### Runbook 3.2 — Pipeline CI/CD detenidos (Sidekiq backlog)

```bash
# RUNBOOK: Pipelines no avanzan, cola Sidekiq creciente

echo "=== RUNBOOK: Sidekiq Backlog ==="

# 1. Ver tamaño de colas
curl -s "http://localhost/api/v4/admin/sidekiq/queues?per_page=20" \
  -H "PRIVATE-TOKEN: $GITLAB_ADMIN_TOKEN" | \
  jq '.[] | select(.backlog > 100) | {name, backlog, latency}'

# 2. Ver utilización de workers
curl -s "http://localhost/api/v4/admin/sidekiq/processes" \
  -H "PRIVATE-TOKEN: $GITLAB_ADMIN_TOKEN" | \
  jq '.[] | {hostname, busy, queues: (.queues | length)}'

# 3. Ver jobs stuck (en running > 1 hora)
curl -s "http://localhost/api/v4/admin/sidekiq/jobs?queues=default&count=10" \
  -H "PRIVATE-TOKEN: $GITLAB_ADMIN_TOKEN" | \
  jq '.[] | select(.queue_duration > 3600) | {id, class, queue_duration}'

# 4. Si el worker está muerto, reiniciar Sidekiq
# sudo gitlab-ctl restart sidekiq

# 5. Si la cola de Redis está llena:
# redis-cli -s /var/opt/gitlab/redis/redis.socket info memory | grep used_memory_human
```

---

## Parte 4: Cálculo de SLA y Métricas de HA

### Ejercicio 4.1 — Calcular el SLA real de TechScale

```bash
# Generar reporte de disponibilidad del último mes via GitLab API
GITLAB_URL="http://localhost"
ADMIN_TOKEN="$GITLAB_TOKEN"

echo "=== Métricas de salud actuales ==="
curl -s "${GITLAB_URL}/-/readiness?all=1" | \
  jq '.checks | to_entries | map({(.key): .value.status}) | add'

echo ""
echo "=== Versión y componentes ==="
curl -s "${GITLAB_URL}/api/v4/version" \
  -H "PRIVATE-TOKEN: $ADMIN_TOKEN" | jq .
```

### Ejercicio 4.2 — Tabla de RTO/RPO medidos

Completar con los valores obtenidos en los ejercicios anteriores:

| Componente | RTO Teórico | RTO Medido | RPO | Acción de Recovery |
|-----------|:-----------:|:----------:|:---:|-------------------|
| HAProxy (VIP failover) | ~3-10s | __ | 0 | Keepalived automático |
| GitLab Rails | ~0s (LB redirige) | __ | 0 | HAProxy health check |
| PostgreSQL (Patroni) | ~30s | __ | ~0s o ~60s | Patroni automático |
| Redis (Sentinel) | ~30s | __ | ~0s | Sentinel automático |
| Gitaly Cluster | ~60s | __ | 0 | Praefect automático |
| Backup restore (DR total) | ~30min | __ | ~1h | Manual + runbook |

---

## Preguntas de reflexión

1. La arquitectura propuesta tiene 11 servidores (3 Rails, 2 HAProxy, 3 Gitaly, 3 PostgreSQL). TechScale solo tiene 3 servidores físicos. ¿Cómo reorganizarías los componentes para maximizar HA con solo 3 servidores? ¿Qué riesgos introduce?

2. El failover de Patroni tardó 25 segundos en el ejercicio. Durante esos 25 segundos, los usuarios de GitLab recibían errores de base de datos. ¿Qué cambio en la configuración de PgBouncer reduciría el impacto de esos 25 segundos en los usuarios finales?

3. Tienes presupuesto para agregar solo un servidor más. ¿En qué componente lo invertirías y por qué? Justifica en términos de RTO, RPO, y SLA.

4. El equipo propone eliminar la capa de Praefect porque "añade complejidad" y los repositorios son "solo git". ¿Cómo argumentarías (o no) a favor de mantener Praefect?

5. Tu RTO objetivo es 30 minutos y el restore completo tarda 45 minutos. Sin cambiar la infraestructura HA (que ya cubre los fallos de componentes individuales), ¿qué estrategia de backup/DR usarías para cubrir el escenario de pérdida total del datacenter?

---

## Entregables

- [ ] Tabla SPOF completada con estrategias y herramientas
- [ ] Diagrama ASCII/Mermaid de la arquitectura HA completa
- [ ] Cálculo de uptime teórico documentado
- [ ] Ejercicio 2.1: Log de simulación fallo Rails + tiempo de detección por HAProxy
- [ ] Ejercicio 2.2: RTO medido del failover de PostgreSQL
- [ ] Ejercicio 2.3: Tiempo de migración del VIP documentado
- [ ] Runbook 3.1 ejecutado y output documentado
- [ ] Tabla RTO/RPO por componente con valores medidos
- [ ] Respuestas a las 5 preguntas de reflexión

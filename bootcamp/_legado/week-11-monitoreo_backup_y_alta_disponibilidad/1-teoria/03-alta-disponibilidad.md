# 03 — Alta Disponibilidad: Visión General y Arquitecturas

La alta disponibilidad (HA) en GitLab busca eliminar puntos únicos de fallo (SPOFs) para garantizar que el servicio permanezca accesible incluso si componentes individuales fallan. La HA no es un estado binario — existe en niveles, y cada nivel tiene un costo en complejidad operacional y presupuesto.

![Componentes de HA en GitLab — balanceadores, aplicación, DB, Git y almacenamiento](../0-assets/03-ha-components.svg)

---

## Conceptos fundamentales

**SPOF (Single Point of Failure)**: componente cuyo fallo causa que el servicio completo deje de funcionar. En un GitLab single-node, todo es SPOF.

**RTO (Recovery Time Objective)**: tiempo máximo aceptable para que el servicio vuelva a estar disponible tras un fallo. Define la urgencia de la respuesta y la arquitectura necesaria.

**RPO (Recovery Point Objective)**: cantidad máxima de datos que la organización acepta perder. Un RPO de 1 hora significa que se aceptan perder hasta 1 hora de trabajo si ocurre un fallo.

| RTO | RPO | Arquitectura recomendada |
|-----|-----|------------------------|
| < 1 hora | < 1 día | Single-node + backup diario |
| < 15 min | < 1 hora | Multi-node básico + backup + réplica DB |
| < 5 min | < 5 min | HA completa con failover automático |
| < 1 min | ~0 | HA completa + réplica síncrona + Gitaly Cluster |

---

## Componentes críticos y estrategias HA

| Componente | SPOF | Solución HA | Mínimo nodos |
|-----------|:----:|-------------|:------------:|
| GitLab Rails (Puma) | ✅ | Load balancer + múltiples instancias | 2 |
| Sidekiq | ❌ (pueden escalar) | Múltiples nodos independientes | 2 |
| PostgreSQL | ✅ | Patroni/Repmgr + réplicas | 3 (1P + 2R) |
| Redis | ✅ | Redis Sentinel o Cluster | 3 (1M + 2S) |
| Gitaly | ✅ | Gitaly Cluster con Praefect | 3 + Praefect |
| HAProxy/Nginx (LB) | ✅ | Keepalived con VIP | 2 |
| Container Registry | ✅ | Múltiples instancias + S3 backend | 2 |
| Shared Storage | ✅ | NFS HA o almacenamiento S3 | Según proveedor |

---

## Niveles de disponibilidad

### Nivel 1 — Single Node (sin HA)

```
[Usuario] → [GitLab (todo en uno: Rails + DB + Redis + Gitaly)]
```

- Todo en un solo servidor
- RTO: tiempo de arrange del servidor (30-60 min)
- RPO: tiempo desde el último backup (hasta 24h)
- Apropiado para: equipos < 50 personas, desarrollo, laboratorios
- Coste operacional: mínimo — un solo sistema que mantener

**Configuración en `docker-compose.yml`**:
```yaml
services:
  gitlab:
    image: gitlab/gitlab-ce:17.1.0-ce.0
    # Todo en un contenedor — máxima simplicidad
```

### Nivel 2 — Componentes separados (semi-HA)

```
[Usuario] → [Nginx LB] → [GitLab Rails]
                           ↓        ↓
                      [PostgreSQL] [Redis]
                           ↓
                        [Gitaly]
```

- Componentes en servidores separados pero sin redundancia
- RTO: minutos (failover manual) a decenas de minutos
- RPO: hasta 1 hora con réplica DB asíncrona
- Apropiado para: 50-200 personas, producción con mantenimiento programado aceptable
- Permite escalar cada componente de forma independiente

### Nivel 3 — HA completa

```
                   ┌─[HAProxy 1]─┐
[Usuario] → [VIP] ─┤             ├─→ [GitLab Rails 1]
                   └─[HAProxy 2]─┘   [GitLab Rails 2]
                                      [GitLab Rails 3]
                                           ↓
                              ┌────────────┼────────────┐
                         [PG Primary]  [Redis Master]  [Praefect]
                         [PG Replica1] [Redis Slave1]  [Gitaly 1]
                         [PG Replica2] [Redis Slave2]  [Gitaly 2]
                         [etcd 1-3]    [Sentinel 1-3]  [Gitaly 3]
```

- Todos los componentes redundantes
- RTO: < 5 minutos (failover automático)
- RPO: < 1 minuto con réplica síncrona
- Apropiado para: 200+ personas, producción crítica
- Mínimo: 12-15 VMs + almacenamiento compartido

---

## Balanceo de carga con HAProxy

```
# /etc/haproxy/haproxy.cfg
# ¿QUÉ HACE?: Distribuye el tráfico HTTP/HTTPS entre múltiples nodos Rails
# ¿POR QUÉ?: Un solo nodo Rails no puede manejar la carga de centenares de usuarios
# ¿PARA QUÉ?: Escalar horizontalmente GitLab y eliminar el SPOF de aplicación

global
    log /dev/log local0
    maxconn 50000

defaults
    mode http
    timeout connect 10s
    timeout client  60s
    timeout server  60s
    option forwardfor
    option http-server-close

frontend gitlab-http
    bind *:80
    bind *:443 ssl crt /etc/ssl/gitlab.pem
    http-request redirect scheme https unless { ssl_fc }
    default_backend gitlab-rails

backend gitlab-rails
    balance leastconn
    option httpchk GET /-/health
    
    server rails-1 192.168.1.11:80 check inter 10s fall 3 rise 2
    server rails-2 192.168.1.12:80 check inter 10s fall 3 rise 2
    server rails-3 192.168.1.13:80 check inter 10s fall 3 rise 2

# SSH passthrough para operaciones Git via SSH
frontend gitlab-ssh
    bind *:22
    mode tcp
    default_backend gitlab-ssh-backend

backend gitlab-ssh-backend
    mode tcp
    balance roundrobin
    server rails-1 192.168.1.11:22 check
    server rails-2 192.168.1.12:22 check
    server rails-3 192.168.1.13:22 check
```

---

## Alta disponibilidad del balanceador con Keepalived

```bash
# ¿QUÉ HACE?: Configura una VIP (Virtual IP) que migra entre dos HAProxy
# ¿POR QUÉ?: Sin esto, el balanceador es el nuevo SPOF
# ¿PARA QUÉ?: Si HAProxy-1 falla, la VIP migra a HAProxy-2 en < 3 segundos
# /etc/keepalived/keepalived.conf en HAProxy-1 (MASTER)

vrrp_script check_haproxy {
    script "pidof haproxy"
    interval 2
    weight -20
}

vrrp_instance VI_GITLAB {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 101    # BACKUP usa 100 — el de mayor prioridad toma la VIP
    
    authentication {
        auth_type PASS
        auth_pass gitlab-ha-secret
    }
    
    virtual_ipaddress {
        192.168.1.10/24   # Esta es la VIP que apuntan los DNS y los usuarios
    }
    
    track_script {
        check_haproxy
    }
}
```

---

## Almacenamiento compartido

Los nodos Rails necesitan acceso compartido a los mismos archivos (uploads, repositories en modo no-Gitaly Cluster, registry):

### NFS (Network File System)

```bash
# En el servidor NFS
sudo apt install nfs-kernel-server
cat >> /etc/exports << 'EOF'
/var/opt/gitlab/gitlab-rails/shared  192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
/var/opt/gitlab/gitlab-rails/uploads 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
EOF
sudo exportfs -a

# En cada nodo Rails
# /etc/fstab
# 192.168.1.50:/var/opt/gitlab/gitlab-rails/shared  /var/opt/gitlab/gitlab-rails/shared  nfs  defaults,_netdev  0  0
```

### S3 como alternativa a NFS (recomendado)

```ruby
# gitlab.rb — configurar S3 para uploads, registry, backups, LFS
# ¿QUÉ HACE?: Usa S3 como almacenamiento distribuido en lugar de NFS
# ¿POR QUÉ?: S3 es inherentemente HA y escala sin límite — NFS puede ser un SPOF
# ¿PARA QUÉ?: Múltiples nodos Rails leen/escriben el mismo almacenamiento sin NFS
gitlab_rails['uploads_object_store_enabled'] = true
gitlab_rails['uploads_object_store_connection'] = {
  'provider' => 'AWS',
  'region' => 'us-east-1',
  'aws_access_key_id' => 'AKIAIOSFODNN7EXAMPLE',
  'aws_secret_access_key' => 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
}
gitlab_rails['uploads_object_store_remote_directory'] = 'gitlab-uploads'

# Lo mismo aplica para LFS, artifacts, packages, MR diffs, etc.
```

---

## Redis HA con Sentinel

Redis Sentinel monitorea las instancias de Redis y maneja failover automático:

```ruby
# gitlab.rb en los nodos Rails — conectar a Redis via Sentinel
# ¿QUÉ HACE?: En lugar de conectar directamente a Redis, conecta vía Sentinel
# ¿POR QUÉ?: Sentinel descubre automáticamente qué instancia es el master actual
# ¿PARA QUÉ?: Cuando Redis master falla, GitLab se reconecta al nuevo master sin intervención
redis['enable'] = false                    # No usar Redis local

gitlab_rails['redis_sentinels'] = [
  { host: '192.168.1.31', port: 26379 },
  { host: '192.168.1.32', port: 26379 },
  { host: '192.168.1.33', port: 26379 }
]
gitlab_rails['redis_sentinels_password'] = 'sentinel-password'
```

---

## Sesiones y estado compartido en HA Rails

Con múltiples nodos Rails, las sesiones de usuario deben almacenarse en Redis (no en memoria local), ya que cada petición puede ir a un nodo diferente:

```ruby
# gitlab.rb
# Las sesiones ya van a Redis por defecto — verificar que está configurado
# Esto garantiza que un usuario autenticado en Rails-1 siga autenticado si la siguiente
# petición va a Rails-2
gitlab_rails['redis_host'] = nil   # Null si se usa Sentinel
```

---

## Estrategia de despliegue rolling update en HA

```bash
# ¿QUÉ HACE?: Actualiza GitLab en todos los nodos sin downtime
# ¿POR QUÉ?: En HA, se puede actualizar un nodo a la vez mientras los otros sirven tráfico
# ¿PARA QUÉ?: Zero-downtime upgrades (no posibles en single-node)

for NODE in rails-1 rails-2 rails-3; do
  echo "Actualizando $NODE..."
  
  # 1. Sacar el nodo del balanceador (marcar como drain en HAProxy)
  echo "disable server gitlab-rails/$NODE" | \
    sudo socat stdio /var/run/haproxy/admin.sock
  
  # 2. Esperar que las conexiones activas terminen
  sleep 30
  
  # 3. Actualizar GitLab en el nodo
  ssh "$NODE" "sudo apt-get update && sudo apt-get install -y gitlab-ce"
  
  # 4. Reconfigure y restart en el nodo
  ssh "$NODE" "sudo gitlab-ctl reconfigure && sudo gitlab-ctl restart"
  
  # 5. Verificar health check antes de volver al balanceador
  until curl -sf "http://$NODE/-/health"; do sleep 5; done
  
  # 6. Volver al balanceador
  echo "enable server gitlab-rails/$NODE" | \
    sudo socat stdio /var/run/haproxy/admin.sock
  
  echo "$NODE actualizado y de vuelta en el balanceador"
  sleep 60   # Tiempo de estabilización antes del siguiente nodo
done
```

---

## Checklist de HA

```
[ ] Load balancer con VIP (keepalived)
[ ] Mínimo 2 nodos Rails con health checks configurados
[ ] PostgreSQL: 1 primario + 2 réplicas + Patroni + etcd
[ ] Redis: 1 master + 2 réplicas + Sentinel (3 instancias)
[ ] Gitaly Cluster: Praefect + 3 nodos Gitaly
[ ] Almacenamiento compartido: NFS HA o S3
[ ] Monitoreo de todos los componentes con Prometheus
[ ] Runbook documentado para failover manual de cada componente
[ ] Procedimiento de rolling update probado en staging
[ ] Simulacro de DR ejecutado al menos una vez (¡en producción!)
```

---

## Mejores prácticas

- Empezar con el nivel de HA mínimo que satisface el RTO/RPO requerido — no sobrediseñar
- Simular fallos regularmente (chaos engineering) — descubrir las debilidades antes de producción
- Monitorear el monitoreo — si Prometheus cae, nadie sabe que algo falló
- Documentar cada componente de HA con un runbook de failover manual
- S3 sobre NFS siempre que sea posible — NFS puede ser el SPOF más frágil de la arquitectura
- Los datos en Redis son temporales — el SPOF real que necesita HA es PostgreSQL y Gitaly

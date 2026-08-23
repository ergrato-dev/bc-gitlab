# Práctica 02 — Sistema de Backup Automático con Verificación

## Objetivo

Implementar un sistema completo de backup automático para GitLab CE que incluya: script de backup con verificación de integridad, rotación automática, sincronización offsite a MinIO (compatible con S3), notificaciones y monitoreo del proceso de backup.

## Requisitos

- GitLab CE con acceso de administrador al servidor
- Docker disponible (para MinIO local como S3 compatible)
- `jq`, `curl`, `rclone` o `aws-cli` instalados
- Cuenta de email o webhook de Slack para notificaciones
- Tiempo estimado: 60 minutos + 10-20 minutos para ejecutar el backup

---

## Instrucciones

### Paso 1: Levantar MinIO como almacenamiento S3 local

```bash
# MinIO como destino de backup offsite (para laboratorio)
mkdir -p /opt/minio/data

docker run -d \
  --name minio \
  -p 9000:9000 \
  -p 9001:9001 \
  -v /opt/minio/data:/data \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin123 \
  minio/minio server /data --console-address ":9001"

# Verificar que MinIO responde
curl -s http://localhost:9000/minio/health/live && echo "MinIO OK"

# Acceder a la consola web: http://localhost:9001
# Credenciales: minioadmin / minioadmin123

# Crear el bucket para backups
docker exec minio mc alias set local http://localhost:9000 minioadmin minioadmin123
docker exec minio mc mb local/gitlab-backups
docker exec minio mc ls local/
```

### Paso 2: Configurar GitLab para backup a S3

```ruby
# Añadir en /etc/gitlab/gitlab.rb
# ¿QUÉ HACE?: Sube los backups directamente a MinIO/S3 durante la creación
# ¿POR QUÉ?: Backup offsite automático sin paso adicional de sincronización
# ¿PARA QUÉ?: Los backups están en almacenamiento separado aunque el servidor falle

gitlab_rails['backup_upload_connection'] = {
  'provider'              => 'AWS',
  'region'                => 'us-east-1',
  'aws_access_key_id'     => 'minioadmin',
  'aws_secret_access_key' => 'minioadmin123',
  'host'                  => 'localhost',
  'endpoint'              => 'http://localhost:9000',
  'path_style'            => true
}
gitlab_rails['backup_upload_remote_directory'] = 'gitlab-backups'
gitlab_rails['backup_keep_time'] = 604800   # Retener 7 días localmente
```

```bash
sudo gitlab-ctl reconfigure
echo "Configuración aplicada. Verificando conexión a MinIO..."
sudo gitlab-rails runner "
  require 'fog/aws'
  conn = Fog::Storage.new(
    provider: 'AWS',
    aws_access_key_id: 'minioadmin',
    aws_secret_access_key: 'minioadmin123',
    endpoint: 'http://localhost:9000',
    path_style: true
  )
  puts conn.directories.map(&:key).include?('gitlab-backups') ? '✅ Bucket accesible' : '❌ Bucket no encontrado'
"
```

### Paso 3: Crear el script de backup completo

```bash
sudo mkdir -p /opt/scripts
sudo nano /opt/scripts/gitlab-backup.sh
```

```bash
#!/bin/bash
# /opt/scripts/gitlab-backup.sh
# ¿QUÉ HACE?: Backup completo de GitLab con verificación, notificaciones y monitoreo
# ¿POR QUÉ?: Un backup sin verificación puede fallar silenciosamente
# ¿PARA QUÉ?: Proceso confiable y observable de backup diario

set -euo pipefail

# ─── Configuración ────────────────────────────────────────────────────────────
BACKUP_DIR="/var/opt/gitlab/backups"
CONFIG_BACKUP_DIR="/var/opt/gitlab/backups/config"
LOG_FILE="/var/log/gitlab-backup/backup-$(date +%Y%m%d).log"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7
SLACK_WEBHOOK="${SLACK_WEBHOOK_URL:-}"
EMAIL_TO="${BACKUP_EMAIL:-}"

# ─── Funciones ────────────────────────────────────────────────────────────────
log() {
  local level="${2:-INFO}"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $1" | tee -a "$LOG_FILE"
}

notify_slack() {
  [ -z "$SLACK_WEBHOOK" ] && return 0
  local color="$1"
  local message="$2"
  curl -s -X POST "$SLACK_WEBHOOK" \
    --header "Content-Type: application/json" \
    --data "{
      \"attachments\": [{
        \"color\": \"$color\",
        \"title\": \"GitLab Backup — $(hostname)\",
        \"text\": \"$message\",
        \"footer\": \"$(date '+%Y-%m-%d %H:%M')\",
        \"ts\": $(date +%s)
      }]
    }" 2>/dev/null || true
}

notify_email() {
  [ -z "$EMAIL_TO" ] && return 0
  echo "$2" | mail -s "$1" "$EMAIL_TO" 2>/dev/null || true
}

check_disk_space() {
  local available=$(df -BG "$BACKUP_DIR" | awk 'NR==2 {print $4}' | tr -d 'G')
  if [ "$available" -lt 20 ]; then
    log "⚠️  Espacio disponible bajo: ${available}GB (mínimo 20GB recomendado)" "WARN"
    notify_slack "warning" "Espacio bajo en ${BACKUP_DIR}: ${available}GB disponibles"
  fi
  log "Espacio disponible para backup: ${available}GB"
}

verify_backup() {
  local backup_file="$1"
  
  log "Verificando integridad del backup..."
  
  # Test 1: Verificar que el tar es legible
  if ! tar -tf "$backup_file" > /dev/null 2>&1; then
    log "❌ Tar corrupto o ilegible: $backup_file" "ERROR"
    return 1
  fi
  
  # Test 2: Verificar componentes mínimos
  local required=("db/" "repositories/")
  for component in "${required[@]}"; do
    if ! tar -tf "$backup_file" 2>/dev/null | grep -q "^backup/$component"; then
      log "❌ Componente faltante en backup: $component" "ERROR"
      return 1
    fi
  done
  
  # Test 3: Calcular y guardar checksum
  local checksum
  checksum=$(sha256sum "$backup_file" | cut -d' ' -f1)
  echo "$checksum  $(basename $backup_file)" >> "${BACKUP_DIR}/checksums.sha256"
  
  log "✅ Backup verificado. SHA256: ${checksum:0:12}..."
  return 0
}

# ─── Main ─────────────────────────────────────────────────────────────────────
mkdir -p "$(dirname $LOG_FILE)" "$CONFIG_BACKUP_DIR"

log "=============================================="
log "  GitLab Backup Automático — $TIMESTAMP"
log "  Hostname: $(hostname)"
log "  GitLab: $(sudo gitlab-rake gitlab:env:info 2>/dev/null | grep 'GitLab:' | awk '{print $2}' || echo 'unknown')"
log "=============================================="

START_TIME=$(date +%s)

# 1. Verificar espacio en disco
check_disk_space

# 2. Backup de configuración crítica (NO incluido en gitlab-backup)
log "Paso 1/4: Respaldando configuración y secretos..."
sudo cp /etc/gitlab/gitlab.rb        "${CONFIG_BACKUP_DIR}/gitlab.rb.${TIMESTAMP}"
sudo cp /etc/gitlab/gitlab-secrets.json "${CONFIG_BACKUP_DIR}/gitlab-secrets.json.${TIMESTAMP}"
# Rotar configs antiguas (mantener solo las últimas 7)
ls -t "${CONFIG_BACKUP_DIR}"/gitlab.rb.* 2>/dev/null | tail -n +8 | xargs rm -f 2>/dev/null || true
log "Configuración respaldada en ${CONFIG_BACKUP_DIR}"

# 3. Backup principal de GitLab
log "Paso 2/4: Ejecutando gitlab-backup create..."
if sudo /usr/bin/gitlab-backup create CRON=1 2>> "$LOG_FILE"; then
  BACKUP_FILE=$(ls -t "${BACKUP_DIR}"/*_gitlab_backup.tar 2>/dev/null | head -1)
  BACKUP_SIZE=$(du -sh "$BACKUP_FILE" 2>/dev/null | cut -f1 || echo "?")
  log "Backup creado: $(basename $BACKUP_FILE) (${BACKUP_SIZE})"
else
  log "❌ gitlab-backup create FALLÓ" "ERROR"
  notify_slack "danger" "🚨 CRÍTICO: GitLab Backup FALLÓ. Revisar $LOG_FILE"
  notify_email "[CRITICAL] GitLab Backup Failed" "El backup de GitLab falló en $(hostname) a las $(date)"
  exit 1
fi

# 4. Verificar integridad del backup creado
log "Paso 3/4: Verificando integridad..."
if ! verify_backup "$BACKUP_FILE"; then
  notify_slack "danger" "🚨 CRÍTICO: Backup creado pero verificación falló"
  exit 1
fi

# 5. Sincronizar a MinIO/S3
log "Paso 4/4: Sincronizando a almacenamiento externo..."
if command -v aws &>/dev/null; then
  aws s3 cp "$BACKUP_FILE" \
    "s3://gitlab-backups/$(hostname)/$(basename $BACKUP_FILE)" \
    --endpoint-url http://localhost:9000 \
    --no-verify-ssl 2>> "$LOG_FILE" && \
    log "✅ Sincronizado a S3/MinIO" || \
    log "⚠️ Sincronización a S3 falló (backup local disponible)" "WARN"
fi

# 6. Estadísticas finales
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
BACKUP_COUNT=$(ls "${BACKUP_DIR}"/*_gitlab_backup.tar 2>/dev/null | wc -l)

SUCCESS_MSG="✅ GitLab Backup OK
Archivo: $(basename $BACKUP_FILE)
Tamaño: ${BACKUP_SIZE}
Duración: ${DURATION}s
Backups locales: ${BACKUP_COUNT}
Servidor: $(hostname)"

log "=============================================="
log "$SUCCESS_MSG"
log "=============================================="

notify_slack "good" "$SUCCESS_MSG"
```

```bash
sudo chmod +x /opt/scripts/gitlab-backup.sh

# Probar manualmente
sudo /opt/scripts/gitlab-backup.sh
```

### Paso 4: Configurar cron con manejo de entorno

```bash
# ¿QUÉ HACE?: Configura cron con todas las variables necesarias
# ¿POR QUÉ?: Cron no hereda las variables de entorno del shell
# ¿PARA QUÉ?: Backup nocturno automático sin intervención manual
sudo crontab -e
```

Añadir estas líneas:
```
# Variables de entorno para el backup
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/T.../B.../XXX
BACKUP_EMAIL=ops-team@company.local

# Backup diario a las 2:00 AM (menor actividad)
0 2 * * * /opt/scripts/gitlab-backup.sh >> /var/log/gitlab-backup/cron.log 2>&1

# Verificar integridad del último backup cada mañana a las 8:00 AM
0 8 * * * sha256sum -c /var/opt/gitlab/backups/checksums.sha256 2>/dev/null | tail -1 >> /var/log/gitlab-backup/verify.log
```

### Paso 5: Verificar los backups en MinIO

```bash
# Via Docker exec a MinIO CLI
docker exec minio mc ls local/gitlab-backups/

# Via aws-cli con endpoint de MinIO
aws s3 ls s3://gitlab-backups/ \
  --endpoint-url http://localhost:9000 \
  --no-verify-ssl

# Calcular tamaño total de backups en MinIO
docker exec minio mc du local/gitlab-backups/

# Ver el último backup con metadatos
docker exec minio mc stat local/gitlab-backups/$(docker exec minio mc ls local/gitlab-backups/ | tail -1 | awk '{print $NF}')
```

### Paso 6: Monitoreo del proceso de backup con Prometheus

Exponer métricas del backup para Prometheus (textfile collector):

```bash
# Crear un job que actualice la métrica de último backup exitoso
cat > /opt/scripts/gitlab-backup-metrics.sh << 'METRICS'
#!/bin/bash
# ¿QUÉ HACE?: Genera métricas del backup en formato Prometheus textfile
# ¿POR QUÉ?: Permite alertar si el backup diario no se ejecutó
# ¿PARA QUÉ?: "gitlab_backup_last_success_timestamp > 24h" → alerta de backup fallido

METRICS_FILE="/var/lib/node_exporter/textfile_collector/gitlab_backup.prom"
mkdir -p "$(dirname $METRICS_FILE)"

LATEST_BACKUP=$(ls -t /var/opt/gitlab/backups/*_gitlab_backup.tar 2>/dev/null | head -1)

if [ -n "$LATEST_BACKUP" ]; then
  LAST_BACKUP_TIME=$(stat -c %Y "$LATEST_BACKUP")
  BACKUP_SIZE=$(stat -c %s "$LATEST_BACKUP")
  BACKUP_COUNT=$(ls /var/opt/gitlab/backups/*_gitlab_backup.tar 2>/dev/null | wc -l)
  
  cat > "$METRICS_FILE" << EOF
# HELP gitlab_backup_last_success_timestamp Unix timestamp del último backup exitoso
# TYPE gitlab_backup_last_success_timestamp gauge
gitlab_backup_last_success_timestamp $LAST_BACKUP_TIME

# HELP gitlab_backup_size_bytes Tamaño del último backup en bytes
# TYPE gitlab_backup_size_bytes gauge
gitlab_backup_size_bytes $BACKUP_SIZE

# HELP gitlab_backup_count Número de backups disponibles localmente
# TYPE gitlab_backup_count gauge
gitlab_backup_count $BACKUP_COUNT
EOF
  
  echo "Métricas actualizadas: $(date)"
else
  echo "gitlab_backup_last_success_timestamp 0" > "$METRICS_FILE"
fi
METRICS

chmod +x /opt/scripts/gitlab-backup-metrics.sh

# Ejecutar después de cada backup y via cron independiente
echo "5 2 * * * /opt/scripts/gitlab-backup-metrics.sh" | sudo crontab -l | sudo crontab -
```

Alerta de Prometheus para backup antiguo:
```yaml
# En prometheus/rules/gitlab-alerts.yml (añadir)
- alert: GitLabBackupTooOld
  expr: time() - gitlab_backup_last_success_timestamp > 86400  # 24 horas
  for: 1h
  labels:
    severity: critical
  annotations:
    summary: "Backup de GitLab tiene más de 24 horas"
    description: "El último backup exitoso fue hace {{ humanizeDuration $value }}"
```

---

## Preguntas de reflexión

1. El backup tomó 45 minutos y GitLab estuvo disponible durante todo el proceso. ¿Hay alguna ventana en la que los datos podrían ser inconsistentes entre el inicio y el fin del backup?

2. ¿Qué componente de GitLab ocupa más espacio en el backup: la base de datos, los repositorios git, o los uploads? ¿Cómo podrías verificarlo sin hacer el backup?

3. Si MinIO falla durante la sincronización, el backup local está disponible. ¿Qué estrategia implementarías para reintentar la sincronización automáticamente?

4. El equipo propone usar `SKIP=builds,artifacts` para reducir el tamaño del backup a la mitad. ¿Qué datos se perderían? ¿Es aceptable para tu caso de uso?

5. ¿Cómo verificarías que el backup en MinIO es accesible desde un servidor diferente al que lo generó?

---

## Entregables

- [ ] MinIO corriendo y bucket `gitlab-backups` creado
- [ ] GitLab configurado para upload a MinIO (gitlab.rb actualizado y reconfigure ejecutado)
- [ ] Script `/opt/scripts/gitlab-backup.sh` creado y ejecutado exitosamente
- [ ] Backup verificado (checksum en checksums.sha256 y componentes presentes)
- [ ] Backup sincronizado a MinIO (verificado con `mc ls`)
- [ ] Cron configurado para las 2:00 AM
- [ ] Métricas de backup expuestas para Prometheus
- [ ] Log de backup revisado y documentado (duración, tamaño, ruta del archivo)

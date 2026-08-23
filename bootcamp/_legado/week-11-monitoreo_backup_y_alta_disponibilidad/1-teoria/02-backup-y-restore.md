# 02 — Backup y Restore en GitLab CE

Un backup sin restore probado no es un backup — es una esperanza. El backup de GitLab debe ser parte de un proceso completo que incluye creación, verificación, rotación y restauración periódica en entorno de prueba.

![Estrategia de backup — componentes, destinos y políticas de retención](../0-assets/02-backup-strategy.svg)

---

## Componentes respaldables

GitLab tiene dos categorías: los que `gitlab-backup` cubre automáticamente y los que requieren backup manual.

| Componente | gitlab-backup | Backup manual | Criticidad |
|-----------|:-------------:|:-------------:|:----------:|
| Base de datos PostgreSQL | ✅ (pg_dump) | También WAL archiving | 🔴 Crítico |
| Repositorios Git | ✅ (bundle) | git clone --mirror | 🔴 Crítico |
| Uploads y attachments | ✅ | rsync / S3 | 🟡 Alto |
| Container Registry | ✅ | rsync / S3 | 🟡 Alto |
| Packages (Maven, npm, etc.) | ✅ | rsync / S3 | 🟡 Alto |
| Pages | ✅ | rsync / S3 | 🟠 Medio |
| `/etc/gitlab/gitlab.rb` | ❌ | **Backup manual obligatorio** | 🔴 Crítico |
| `/etc/gitlab/gitlab-secrets.json` | ❌ | **Backup manual obligatorio** | 🔴 Crítico |
| `/etc/ssl/` (certificados TLS) | ❌ | Backup manual | 🟡 Alto |

> `gitlab-secrets.json` contiene las claves de cifrado de la base de datos. Sin él, aunque el backup de la DB sea perfecto, los datos cifrados (variables CI/CD con `Masked`, tokens OAuth, 2FA secrets) son irrecuperables. Guardar en un vault o KMS externo.

---

## Comando de backup

```bash
# ¿QUÉ HACE?: Crea un backup completo de todos los componentes configurados
# ¿POR QUÉ?: Un solo comando respalda DB, repositorios, uploads, registry y packages
# ¿PARA QUÉ?: Backup diario para recuperación ante fallos o migraciones de versión
sudo gitlab-backup create

# Resultado: /var/opt/gitlab/backups/TIMESTAMP_GITLAB_VERSION_gitlab_backup.tar
# Ejemplo: 1719532800_2024_06_27_17.1.0_gitlab_backup.tar
```

### Opciones importantes

```bash
# STRATEGY=copy — más seguro en sistemas con git-bundles concurrentes
sudo gitlab-backup create STRATEGY=copy

# CRON=1 — suprime output interactivo para uso en cron/automatización
sudo gitlab-backup create CRON=1

# SKIP — omitir componentes (acelera el backup si alguno no es crítico)
sudo gitlab-backup create SKIP=registry       # Omitir Container Registry (puede ser enorme)
sudo gitlab-backup create SKIP=builds         # Omitir artifacts de CI/CD
sudo gitlab-backup create SKIP=lfs            # Omitir Git LFS objects

# Verificar contenido del backup sin extraer
tar -tf /var/opt/gitlab/backups/1719532800_2024_06_27_17.1.0_gitlab_backup.tar | head -20
```

---

## Backup de configuración y secretos

```bash
#!/bin/bash
# ¿QUÉ HACE?: Respalda los archivos de configuración que gitlab-backup no incluye
# ¿POR QUÉ?: Sin gitlab.rb y gitlab-secrets.json el restore es imposible
# ¿PARA QUÉ?: Guardar junto al backup principal para tener todo necesario

BACKUP_DIR="/var/opt/gitlab/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Crear backup comprimido de configuración
tar -czf "${BACKUP_DIR}/config-${TIMESTAMP}.tar.gz" \
  /etc/gitlab/gitlab.rb \
  /etc/gitlab/gitlab-secrets.json \
  /etc/ssl/certs/gitlab.crt \
  /etc/ssl/private/gitlab.key \
  2>/dev/null

# Calcular checksum para verificar integridad posterior
sha256sum "${BACKUP_DIR}/config-${TIMESTAMP}.tar.gz" >> "${BACKUP_DIR}/checksums.sha256"

echo "Config backup: config-${TIMESTAMP}.tar.gz"
```

---

## Configuración de retención automática

```ruby
# /etc/gitlab/gitlab.rb
# ¿QUÉ HACE?: GitLab elimina automáticamente backups más antiguos que N segundos
# ¿POR QUÉ?: Sin rotación los backups llenan el disco indefinidamente
# ¿PARA QUÉ?: Retener exactamente 7 días de backups sin intervención manual
gitlab_rails['backup_keep_time'] = 604800  # 7 días en segundos
```

```bash
sudo gitlab-ctl reconfigure

# Verificar espacio actual de backups
du -sh /var/opt/gitlab/backups/*
# Contar cuántos backups existen
ls /var/opt/gitlab/backups/*_gitlab_backup.tar | wc -l
```

---

## Script de backup diario con notificaciones

```bash
#!/bin/bash
# /opt/scripts/gitlab-backup-daily.sh
# ¿QUÉ HACE?: Backup completo con logging estructurado y notificaciones
# ¿POR QUÉ?: Un backup sin notificaciones puede fallar silenciosamente durante semanas
# ¿PARA QUÉ?: Backup nocturno confiable — si falla, el equipo se entera de inmediato

set -euo pipefail

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/gitlab-backup.log"
BACKUP_DIR="/var/opt/gitlab/backups"
SLACK_WEBHOOK="${SLACK_WEBHOOK_URL:-}"
RETENTION_DAYS=7

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

notify() {
  local message="$1"
  log "$message"
  if [ -n "$SLACK_WEBHOOK" ]; then
    curl -s -X POST "$SLACK_WEBHOOK" \
      --data "{\"text\": \"$message\"}" 2>/dev/null || true
  fi
}

# ─── Inicio ───────────────────────────────────────────────
log "=============================================="
log "  GitLab Backup — $(date '+%Y-%m-%d %H:%M')"
log "=============================================="
START_TIME=$(date +%s)

# 1. Backup de configuración crítica
log "Paso 1/3: Respaldando configuración y secretos..."
cp /etc/gitlab/gitlab.rb        "${BACKUP_DIR}/gitlab.rb.${TIMESTAMP}"
cp /etc/gitlab/gitlab-secrets.json "${BACKUP_DIR}/gitlab-secrets.json.${TIMESTAMP}"

# 2. Backup principal de GitLab
log "Paso 2/3: Ejecutando gitlab-backup create..."
if sudo /usr/bin/gitlab-backup create CRON=1 2>> "$LOG_FILE"; then
  END_TIME=$(date +%s)
  DURATION=$((END_TIME - START_TIME))
  BACKUP_FILE=$(ls -t "${BACKUP_DIR}"/*_gitlab_backup.tar 2>/dev/null | head -1)
  BACKUP_SIZE=$(du -sh "$BACKUP_FILE" 2>/dev/null | cut -f1 || echo "?")
  
  # Calcular checksum
  sha256sum "$BACKUP_FILE" >> "${BACKUP_DIR}/checksums.sha256"
  
  notify "✅ GitLab Backup OK — ${BACKUP_SIZE} en ${DURATION}s ($(hostname), $(date +%Y-%m-%d))"
else
  notify "🚨 CRÍTICO: GitLab Backup FALLÓ en $(hostname) — $(date). Log: $LOG_FILE"
  exit 1
fi

# 3. Sincronización a almacenamiento externo (offsite)
log "Paso 3/3: Sincronizando a almacenamiento externo..."
if command -v rclone &>/dev/null; then
  rclone sync \
    "$BACKUP_DIR" \
    "s3:gitlab-backups/$(hostname)" \
    --include "*_gitlab_backup.tar" \
    --include "*.sha256" \
    --include "config-${TIMESTAMP}.*" \
    --log-level INFO \
    --log-file "/var/log/rclone-backup.log" && \
    log "Sincronización a S3 completada" || \
    log "⚠️ Advertencia: sincronización a S3 falló"
fi

log "Backup finalizado. Total: ${DURATION}s"
```

```bash
# Instalar en cron de root
sudo crontab -e

# Backup a las 2:00 AM con webhook de Slack
# 0 2 * * * SLACK_WEBHOOK_URL="https://hooks.slack.com/services/T.../B.../XXX" /opt/scripts/gitlab-backup-daily.sh >> /var/log/cron-backup.log 2>&1
```

---

## Backup a S3 nativo (configurado en gitlab.rb)

```ruby
# /etc/gitlab/gitlab.rb
# ¿QUÉ HACE?: Configura GitLab para subir el backup directamente a S3 durante la creación
# ¿POR QUÉ?: Backup offsite automático sin paso adicional de sincronización
# ¿PARA QUÉ?: Recuperación desde S3 si el servidor local falla completamente
gitlab_rails['backup_upload_connection'] = {
  'provider'              => 'AWS',
  'region'                => 'us-east-1',
  'aws_access_key_id'     => 'AKIAIOSFODNN7EXAMPLE',
  'aws_secret_access_key' => 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
  # Para MinIO local (compatible con S3):
  # 'host'                => 'minio.company.local',
  # 'endpoint'            => 'http://minio.company.local:9000',
  # 'path_style'          => true,
}
gitlab_rails['backup_upload_remote_directory'] = 'gitlab-backups'
gitlab_rails['backup_multipart_chunk_size']    = 104857600  # 100MB chunks
```

---

## Verificación de integridad del backup

```bash
# ¿QUÉ HACE?: Verifica que el backup no está corrupto ANTES de necesitarlo
# ¿POR QUÉ?: Un backup corrupto descubierto durante DR es catastrófico
# ¿PARA QUÉ?: Validación periódica (semanal) sin hacer un restore completo
BACKUP_FILE="/var/opt/gitlab/backups/1719532800_2024_06_27_17.1.0_gitlab_backup.tar"

# 1. Verificar que el tar es legible (no corrupto)
tar -tf "$BACKUP_FILE" > /dev/null 2>&1 && \
  echo "✅ Tar íntegro" || echo "❌ Tar CORRUPTO"

# 2. Verificar checksum SHA256
sha256sum -c checksums.sha256 2>/dev/null | grep "$(basename $BACKUP_FILE)"

# 3. Verificar que contiene los componentes críticos
for component in "db/" "repositories/" "uploads.tar.gz"; do
  tar -tf "$BACKUP_FILE" | grep -q "^backup/$component" && \
    echo "✅ Contiene: $component" || echo "❌ FALTA: $component"
done
```

---

## Procedimiento de Restore

> El restore requiere **exactamente la misma versión de GitLab** que generó el backup.

```bash
# ¿QUÉ HACE?: Restore completo paso a paso — el orden es crítico
# ¿POR QUÉ?: Errores comunes: restaurar datos sin restaurar secretos primero
# ¿PARA QUÉ?: Recuperación completa de la instancia GitLab desde backup

BACKUP_ID="1719532800_2024_06_27_17.1.0"

# PASO 1: Restaurar configuración y secretos ANTES de los datos
sudo cp "gitlab.rb.${TIMESTAMP}"         /etc/gitlab/gitlab.rb
sudo cp "gitlab-secrets.json.${TIMESTAMP}" /etc/gitlab/gitlab-secrets.json
sudo chmod 600 /etc/gitlab/gitlab-secrets.json

# PASO 2: Reconfigure con la configuración restaurada
sudo gitlab-ctl reconfigure

# PASO 3: Detener servicios que usan la DB (pero mantener la DB arriba)
sudo gitlab-ctl stop puma
sudo gitlab-ctl stop sidekiq
sudo gitlab-ctl status  # Verificar que puma y sidekiq están down

# PASO 4: Copiar backup y ajustar permisos
sudo cp "${BACKUP_ID}_gitlab_backup.tar" /var/opt/gitlab/backups/
sudo chown git:git "/var/opt/gitlab/backups/${BACKUP_ID}_gitlab_backup.tar"

# PASO 5: Ejecutar restore (responder 'yes' a las confirmaciones)
sudo gitlab-backup restore BACKUP="${BACKUP_ID}"

# PASO 6: Reconfigure post-restore
sudo gitlab-ctl reconfigure

# PASO 7: Reiniciar todos los servicios
sudo gitlab-ctl restart

# PASO 8: Verificar integridad completa
sudo gitlab-rake gitlab:check SANITIZE=true

# PASO 9: Verificar datos críticos
sudo gitlab-rails runner "
  puts 'Proyectos: ' + Project.count.to_s
  puts 'Usuarios: ' + User.count.to_s
  puts 'Issues: ' + Issue.count.to_s
  puts 'Repositorios OK: ' + Repository.all.select{|r| r.exists?}.count.to_s
"
```

---

## Estrategia GFS (Grandfather-Father-Son)

Política de retención escalonada para optimizar almacenamiento y retención histórica:

| Nivel | Frecuencia | Retención | Almacenamiento |
|-------|-----------|-----------|----------------|
| Daily (hijo) | Diario | 7 días | Disco local + S3 |
| Weekly (padre) | Semanal (domingo) | 4 semanas | S3 |
| Monthly (abuelo) | Mensual (1 del mes) | 12 meses | S3 Glacier |

```bash
# Implementación GFS simple con fechas
DAY=$(date +%u)     # 1-7 (lunes-domingo)
DATE=$(date +%d)    # 01-31

if [ "$DATE" = "01" ]; then
  BACKUP_TAG="monthly"
elif [ "$DAY" = "7" ]; then
  BACKUP_TAG="weekly"
else
  BACKUP_TAG="daily"
fi

sudo gitlab-backup create CRON=1
rclone copy /var/opt/gitlab/backups/ "s3:gitlab-backups/${BACKUP_TAG}/"
```

---

## Mejores prácticas

- Respaldar siempre `gitlab.rb` y `gitlab-secrets.json` — sin ellos el restore no funciona
- Probar el restore mensualmente en entorno aislado — el RTO real suele ser mayor al estimado
- Guardar backups offsite — si el servidor falla, el backup local también puede perderse
- Verificar checksums post-backup semanalmente — detectar corrupción antes de necesitar el backup
- Mantener la versión de GitLab en el nombre del backup — el restore requiere la misma versión
- No confiar en `SKIP` para backups productivos — omitir componentes solo en backups de prueba

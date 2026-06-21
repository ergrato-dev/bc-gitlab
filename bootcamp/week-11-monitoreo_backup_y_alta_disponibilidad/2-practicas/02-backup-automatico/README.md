# Práctica 02 — Backup Automático

## Objetivo

Configurar un script de backup automático con rotación y notificaciones.

## Instrucciones

### Paso 1: Crear script de backup

Crea `backup-gitlab.sh`:
```bash
#!/bin/bash
set -euo pipefail

BACKUP_DIR="/var/opt/gitlab/backups"
RETENTION_DAYS=7
LOG_FILE="/var/log/gitlab-backup.log"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Iniciando backup de GitLab..."

# Backup de configuración
cp /etc/gitlab/gitlab.rb "${BACKUP_DIR}/gitlab.rb.${TIMESTAMP}"
cp /etc/gitlab/gitlab-secrets.json "${BACKUP_DIR}/gitlab-secrets.json.${TIMESTAMP}"

# Backup principal
if gitlab-backup create STRATEGY=copy CRON=1; then
  log "Backup completado exitosamente"
else
  log "ERROR: Backup falló"
  exit 1
fi

# Rotación de backups
log "Rotando backups con más de ${RETENTION_DAYS} días..."
find "$BACKUP_DIR" -name "*_gitlab_backup.tar" -mtime "+${RETENTION_DAYS}" -delete

# Sincronizar a almacenamiento externo (descomenta y configura)
# rclone sync "$BACKUP_DIR" s3:gitlab-backups/

log "Proceso de backup finalizado. Tamaño del backup:"
du -sh "$BACKUP_DIR"/*_gitlab_backup.tar 2>/dev/null | tail -1
```

### Paso 2: Probar el script

```bash
chmod +x backup-gitlab.sh
sudo ./backup-gitlab.sh
```

Verifica que se crearon los archivos en `/var/opt/gitlab/backups/`.

### Paso 3: Configurar cron

Agrega al crontab de root:
```bash
sudo crontab -e
```

```
# Backup diario de GitLab a las 2:00 AM
0 2 * * * /opt/scripts/backup-gitlab.sh
```

### Paso 4: Agregar notificación por email

Agrega al final del script:
```bash
# Notificación por email
if [ $? -eq 0 ]; then
  echo "Backup de GitLab completado exitosamente el ${TIMESTAMP}" | \
    mail -s "[OK] GitLab Backup ${TIMESTAMP}" admin@empresa.com
else
  echo "ERROR: Backup de GitLab falló el ${TIMESTAMP}. Revisar ${LOG_FILE}" | \
    mail -s "[CRITICAL] GitLab Backup Failed ${TIMESTAMP}" admin@empresa.com
fi
```

### Paso 5: Monitoreo del backup

Agrega un check en tu dashboard de monitoreo:
```promql
# Tiempo desde el último backup exitoso (en segundos)
time() - gitlab_backup_last_success_timestamp
```
Si el valor supera 86400 (24 horas), el backup diario no se ejecutó.

## Preguntas de reflexión
- ¿Qué otros componentes respaldarías además de los incluidos en gitlab-backup?
- ¿Cómo verificarías la integridad de un backup sin restaurarlo?
- ¿Cuál es tu estrategia para backups off-site?

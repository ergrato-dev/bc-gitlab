#!/usr/bin/env bash
# ============================================
# Practica 02 — Backup Automatico
# ============================================
# Ejecutar: chmod +x backup.sh && ./backup.sh

set -euo pipefail

BACKUP_DIR="${HOME}/bc-gitlab-backups"
RETENTION_DAYS=7
S3_BUCKET="${S3_BUCKET:-}"  # Opcional: s3://mi-bucket/backups

echo "=== Backup GitLab CE ==="
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# ── PASO 1: Crear backup ──
echo ">>> Creando backup..."
# docker compose exec gitlab gitlab-backup create STRATEGY=copy
echo ""

# ── PASO 2: Respaldar configuracion ──
echo ">>> Respaldando configuracion..."
# mkdir -p "${BACKUP_DIR}/config"
# docker compose exec gitlab cat /etc/gitlab/gitlab-secrets.json > "${BACKUP_DIR}/config/gitlab-secrets.json.$(date +%Y%m%d)"
# docker compose cp gitlab:/etc/gitlab/gitlab.rb "${BACKUP_DIR}/config/gitlab.rb.$(date +%Y%m%d)"
echo ""

# ── PASO 3: Copiar backup al host ──
echo ">>> Copiando backup al host..."
# mkdir -p "${BACKUP_DIR}/data"
# docker compose cp gitlab:/var/opt/gitlab/backups/ "${BACKUP_DIR}/data/"
echo ""

# ── PASO 4: Rotacion (keep last N days) ──
echo ">>> Rotando backups (> ${RETENTION_DAYS} dias)..."
# find "${BACKUP_DIR}/data" -name "*_gitlab_backup.tar" -mtime +${RETENTION_DAYS} -delete
echo ""

# ── PASO 5: Sync a S3 (opcional) ──
if [ -n "${S3_BUCKET}" ]; then
    echo ">>> Sincronizando a S3..."
    # rclone sync "${BACKUP_DIR}" "${S3_BUCKET}" --progress
else
    echo ">>> S3 no configurado (set S3_BUCKET env var)"
fi
echo ""

echo "=== Backup completado: ${BACKUP_DIR} ==="
echo "Ultimos backups:"
# docker compose exec gitlab ls -lh /var/opt/gitlab/backups/ | tail -5

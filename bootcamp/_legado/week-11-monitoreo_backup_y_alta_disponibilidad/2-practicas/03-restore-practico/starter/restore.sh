#!/usr/bin/env bash
# ============================================
# Practica 03 — Restore Practico
# ============================================
# ADVERTENCIA: Restaura en una instancia LIMPIA.
# NUNCA restaurar sobre datos existentes.

echo "=== Restore GitLab CE ==="
echo ""

TIMESTAMP="${1:-}"
if [ -z "$TIMESTAMP" ]; then
    echo "Uso: $0 <timestamp>"
    echo "Listar backups: docker compose exec gitlab ls /var/opt/gitlab/backups/"
    exit 1
fi

echo ">>> PASO 1: Detener servicios que escriben en DB..."
# docker compose exec gitlab gitlab-ctl stop puma
# docker compose exec gitlab gitlab-ctl stop sidekiq
echo ""

echo ">>> PASO 2: Restaurar backup ${TIMESTAMP}..."
# docker compose exec gitlab gitlab-backup restore BACKUP=${TIMESTAMP}
echo ""

echo ">>> PASO 3: Reconfigurar y reiniciar..."
# docker compose exec gitlab gitlab-ctl reconfigure
# docker compose exec gitlab gitlab-ctl restart
echo ""

echo ">>> PASO 4: Verificar integridad..."
# docker compose exec gitlab gitlab-ctl status
# docker compose exec gitlab gitlab-rake gitlab:check SANITIZE=true
echo ""

echo ">>> PASO 5: Checks post-restore..."
echo "Verificar:"
echo "  - Usuarios: docker compose exec gitlab gitlab-rails runner 'puts User.count'"
echo "  - Proyectos: docker compose exec gitlab gitlab-rails runner 'puts Project.count'"
echo "  - Issues: docker compose exec gitlab gitlab-rails runner 'puts Issue.count'"
echo "  - UI: http://localhost (login con credenciales conocidas)"
echo ""

echo "=== Restore completado ==="

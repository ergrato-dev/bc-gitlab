#!/bin/bash
# start.sh — Inicia todos los servicios de GitLab en el lab
set -euo pipefail

echo "=== gl-epti: Iniciando servicios GitLab ==="

gitlab-ctl start

echo ""
echo "[OK] Servicios GitLab iniciados."
echo "Verifica con: gl-epti-health"

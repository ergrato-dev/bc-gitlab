#!/bin/bash
# stop.sh — Detiene todos los servicios de GitLab en el lab
set -euo pipefail

echo "=== gl-epti: Deteniendo servicios GitLab ==="

gitlab-ctl stop

echo ""
echo "[OK] Servicios GitLab detenidos."
echo "Para reiniciar: start.sh"

#!/bin/bash
# start.sh — Levanta el laboratorio (perfil base).
#
# Perfiles adicionales (docs/perfiles-de-laboratorio.md):
#   docker compose --profile observabilidad up -d    # Semana 21
set -euo pipefail

cd "$(cd "$(dirname "$0")" && pwd)"

echo "=== Levantando el laboratorio (perfil base) ==="
docker compose --profile base up -d

echo ""
echo "[OK] Laboratorio iniciado."
echo "El primer arranque tarda ~5 min. Sigue el progreso con:"
echo "  docker compose logs -f gitlab"
echo ""
echo "Acceso: http://localhost:8888 (usuario: root)"
echo "Contrasena inicial:"
echo "  docker compose exec gitlab grep 'Password:' /etc/gitlab/initial_root_password"

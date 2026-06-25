#!/bin/bash
# start.sh — Levanta el entorno gl-epti completo
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.gl-epti.yml"

echo "=== gl-epti: Levantando entorno ==="
echo ""

docker compose -f "$COMPOSE_FILE" up -d

echo ""
echo "[OK] Entorno gl-epti iniciado."
echo "Espera ~5 min en el primer inicio. Monitorea con:"
echo "  docker compose -f $COMPOSE_FILE logs -f gl-epti"
echo ""
echo "Acceso: http://localhost:8888  (usuario: root / ChangeMe123!)"

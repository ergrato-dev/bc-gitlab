#!/bin/bash
# stop.sh — Detiene el entorno gl-epti
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.gl-epti.yml"

echo "=== gl-epti: Deteniendo entorno ==="

docker compose -f "$COMPOSE_FILE" down

echo ""
echo "[OK] Entorno gl-epti detenido. Datos preservados."
echo "Para destruir todo: docker compose -f $COMPOSE_FILE down -v"

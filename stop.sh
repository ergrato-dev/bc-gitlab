#!/bin/bash
# stop.sh — Detiene el laboratorio conservando los datos.
set -euo pipefail

cd "$(cd "$(dirname "$0")" && pwd)"

echo "=== Deteniendo el laboratorio ==="
docker compose --profile base --profile observabilidad down

echo ""
echo "[OK] Detenido. Los datos se conservan en los volumenes."
echo "Para destruirlo todo, volumenes incluidos:"
echo "  docker compose --profile base --profile observabilidad down -v"

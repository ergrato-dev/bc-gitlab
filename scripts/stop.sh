#!/usr/bin/env bash
# stop.sh — Para el laboratorio conservando todos los datos.
#
# Uso: ./scripts/stop.sh
#
# Este script NUNCA borra volumenes. Tu proyecto de 26 semanas vive en ellos.
# Si de verdad quieres destruirlo todo, escribe el comando a mano — la friccion
# es deliberada:
#   docker compose --profile base --profile observabilidad down -v
set -euo pipefail
cd "$(cd "$(dirname "$0")/.." && pwd)"

echo "== Deteniendo el laboratorio =="
docker compose --profile base --profile observabilidad --profile ha down

echo
echo "Detenido. Los datos siguen en los volumenes."
echo "Para volver: ./scripts/start.sh"

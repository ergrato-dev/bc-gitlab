#!/usr/bin/env bash
# start.sh — Levanta el laboratorio y espera a que GitLab este listo de verdad.
#
# Uso:
#   ./scripts/start.sh                  # perfil base
#   ./scripts/start.sh observabilidad   # base + Prometheus/Grafana/Loki (S21)
#
# Los perfiles y su coste en memoria: docs/perfiles-de-laboratorio.md
# Nunca toca los volumenes. Para pararlo: ./scripts/stop.sh
set -euo pipefail
cd "$(cd "$(dirname "$0")/.." && pwd)"

PERFILES=(--profile base)
for p in "$@"; do PERFILES+=(--profile "$p"); done

[ -f .env ] || { echo "Falta .env. Ejecuta: cp .env.example .env"; exit 1; }

echo "== Levantando el laboratorio: base ${*:-} =="
docker compose "${PERFILES[@]}" up -d

PUERTO=$(grep -E '^GITLAB_HTTP_PORT=' .env | cut -d= -f2 || echo 8888)
PUERTO=${PUERTO:-8888}

echo
echo "Esperando a que GitLab responda (el primer arranque tarda ~5 min)..."
for i in $(seq 1 60); do
  if curl -fs "http://localhost:${PUERTO}/-/readiness" > /dev/null 2>&1; then
    echo "GitLab listo tras $((i * 10))s."
    echo
    echo "  Acceso:      http://localhost:${PUERTO}  (usuario: root)"
    echo "  Contrasena:  docker compose exec gitlab grep 'Password:' /etc/gitlab/initial_root_password"
    echo "  Diagnostico: docker compose exec gitlab /opt/lab/lab-health"
    exit 0
  fi
  sleep 10
done

echo
echo "Sigue sin responder tras 10 min. Revisa:"
echo "  docker compose logs gitlab | tail -50"
echo "  docker stats --no-stream"
exit 1

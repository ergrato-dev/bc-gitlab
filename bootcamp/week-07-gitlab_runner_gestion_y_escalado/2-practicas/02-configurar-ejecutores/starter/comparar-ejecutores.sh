#!/usr/bin/env bash
# ============================================
# Practica 02 — Comparar Ejecutores
# ============================================
# Ejecuta jobs con Docker executor y Shell
# executor para ver las diferencias.

echo "=== Practica 02: Comparar Ejecutores ==="
echo ""
echo "Usa el .gitlab-ci.yml correspondiente en tu proyecto."
echo ""

# ── PASO 1: Verificar runners registrados ──
echo "--- Paso 1: Runners disponibles ---"
# docker compose exec gitlab-runner gitlab-runner list
echo ""

# ── PASO 2: Crear .gitlab-ci.yml ──
echo "--- Paso 2: Crear pipeline comparativo ---"
cat << 'YAML'
# Copia esto a .gitlab-ci.yml en tu proyecto:
stages:
  - test

docker-job:
  stage: test
  tags: [docker]
  image: alpine:latest
  script:
    - echo "=== DOCKER EXECUTOR ==="
    - whoami
    - hostname
    - cat /etc/os-release | head -2
    - echo "UID: $(id -u)"
    - ls /var/run/docker.sock 2>/dev/null && echo "Docker socket: SI"

shell-job:
  stage: test
  tags: [shell]
  script:
    - echo "=== SHELL EXECUTOR ==="
    - whoami
    - hostname
    - cat /etc/os-release | head -2
    - echo "UID: $(id -u)"
    - ls /var/run/docker.sock 2>/dev/null && echo "Docker socket: SI"
YAML
echo ""

# ── PASO 3: Commit y push ──
echo "--- Paso 3: Subir y ejecutar ---"
echo "git add .gitlab-ci.yml && git commit -m 'ci: comparar ejecutores' && git push"
echo ""

# ── PASO 4: Comparar resultados ──
echo "--- Paso 4: Analizar diferencias ---"
echo "CI/CD → Pipelines → Click en cada job → Ver logs"
echo "Compara:"
echo "  - whoami (root en Docker? tu usuario en shell?)"
echo "  - hostname (container ID vs hostname real)"
echo "  - OS release (Alpine vs tu SO)"
echo ""

echo "=== Practica 02 completada ==="

#!/usr/bin/env bash
# ============================================
# Practica 01 — Instalar y Registrar Runner
# ============================================
# Guia paso a paso. El runner YA esta en
# docker-compose.yml del bootcamp.
# Esta practica ensena a registrarlo.

echo "=== Practica 01: Registrar Runner ==="
echo ""

# ── PASO 1: Verificar runner existente ──
echo "--- Paso 1: Ver runner en docker-compose ---"
# Descomenta:
# docker compose ps gitlab-runner
# docker compose logs gitlab-runner --tail 20
echo ""

# ── PASO 2: Obtener token de registro ──
echo "--- Paso 2: Obtener registration token ---"
echo "Opción A (Shared): Admin Area → CI/CD → Runners → New instance runner"
echo "Opción B (Project): Project → Settings → CI/CD → Runners → New project runner"
echo "Copia el token."
echo ""

# ── PASO 3: Registrar runner (non-interactive) ──
echo "--- Paso 3: Registrar runner ---"
echo "Reemplaza TU_TOKEN con el token copiado:"
# Descomenta:
# docker compose exec gitlab-runner gitlab-runner register \
#   --non-interactive \
#   --url http://gitlab \
#   --registration-token "TU_TOKEN" \
#   --executor docker \
#   --docker-image alpine:latest \
#   --docker-volumes /var/run/docker.sock:/var/run/docker.sock \
#   --tag-list "docker,linux,bootcamp" \
#   --description "bootcamp-docker-runner"
echo ""

# ── PASO 4: Verificar registro ──
echo "--- Paso 4: Verificar ---"
# Descomenta:
# docker compose exec gitlab-runner gitlab-runner list
# docker compose exec gitlab-runner gitlab-runner verify
echo ""

# ── PASO 5: Ver en GitLab UI ──
echo "--- Paso 5: Verificar en UI ---"
echo "Admin Area → CI/CD → Runners"
echo "Debe aparecer 'bootcamp-docker-runner' con circulo VERDE"
echo ""

# ── PASO 6: Ver config.toml ──
echo "--- Paso 6: Explorar config.toml ---"
# docker compose exec gitlab-runner cat /etc/gitlab-runner/config.toml
echo ""

echo "=== Practica 01 completada ==="

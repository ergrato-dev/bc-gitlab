#!/usr/bin/env bash
# ============================================
# PRACTICA 01: Preparacion del Entorno
# ============================================
# Verifica que el sistema cumple los requisitos
# para correr GitLab CE con Docker Compose.

set -euo pipefail

echo "=== Practica 01: Preparacion del Entorno ==="
echo ""

# ── PASO 1: Verificar Docker ──
echo "--- Paso 1: Verificar Docker ---"
# Descomenta y ejecuta:
# docker --version
# docker compose version
echo ""

# ── PASO 2: Verificar Docker sin sudo ──
echo "--- Paso 2: Verificar acceso a Docker (sin sudo) ---"
# Descomenta y ejecuta:
# docker ps
# Si falla: sudo usermod -aG docker $USER && newgrp docker
echo ""

# ── PASO 3: Verificar recursos ──
echo "--- Paso 3: Verificar recursos del sistema ---"
# Descomenta y ejecuta:
# free -h          # RAM (minimo 8 GB)
# df -h /          # Disco (minimo 20 GB libres)
# lscpu | grep "Model name"  # CPU (4+ cores recomendados)
echo ""

# ── PASO 4: Verificar puertos libres ──
echo "--- Paso 4: Verificar puertos (80, 443, 2224, 5000) ---"
# Descomenta y ejecuta:
# ss -tuln | grep -E ':80 |:443 |:2224 |:5000 '
# Si estan ocupados, edita .env para cambiar puertos
echo ""

# ── PASO 5: Clonar repositorio del bootcamp ──
echo "--- Paso 5: Clonar bc-gitlab ---"
# Descomenta y ejecuta:
# cd ~
# git clone https://github.com/ergrato-dev/bc-gitlab.git
# cd bc-gitlab
# cp .env.example .env
echo ""

# ── PASO 6: Verificar .env ──
echo "--- Paso 6: Revisar variables de entorno ---"
# Descomenta y ejecuta:
# cat .env
echo ""

echo ""
echo "=== Preparacion completada ==="
echo "Entorno listo. Continua con la Practica 02 para levantar GitLab CE."

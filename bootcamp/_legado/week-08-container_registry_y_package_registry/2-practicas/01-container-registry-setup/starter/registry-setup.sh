#!/usr/bin/env bash
# ============================================
# Practica 01 — Container Registry Setup
# ============================================

echo "=== Practica 01: Container Registry ==="
echo ""

# ── PASO 1: Verificar acceso al registry ──
echo "--- Paso 1: Login manual ---"
echo "Crea Personal Access Token: Settings → Access Tokens → read_registry + write_registry"
# Descomenta con tu token:
# docker login registry.localhost  # o http://localhost:5000
# Username: root
# Password: TU_PERSONAL_ACCESS_TOKEN
echo ""

# ── PASO 2: Subir imagen de prueba ──
echo "--- Paso 2: Pull, tag, push ---"
# docker pull alpine:latest
# docker tag alpine:latest localhost:5000/root/test-image:v1.0.0
# docker push localhost:5000/root/test-image:v1.0.0
echo ""

# ── PASO 3: Verificar en UI ──
echo "--- Paso 3: Verificar en GitLab ---"
echo "Project → Packages & Registries → Container Registry"
echo "Debe aparecer 'test-image' con tag v1.0.0"
echo ""

# ── PASO 4: Pull y ejecutar ──
echo "--- Paso 4: Pull y run ---"
# docker pull localhost:5000/root/test-image:v1.0.0
# docker run --rm localhost:5000/root/test-image:v1.0.0 echo "Hello from Container Registry!"
echo ""

# ── PASO 5: Login en CI con CI_JOB_TOKEN ──
echo "--- Paso 5: Variables CI/CD para registry ---"
echo "En .gitlab-ci.yml, GitLab expone automaticamente:"
echo "  CI_REGISTRY       = localhost:5000"
echo "  CI_REGISTRY_IMAGE = localhost:5000/group/project"
echo "  CI_REGISTRY_USER  = gitlab-ci-token"
echo "  CI_JOB_TOKEN      = token temporal"
echo ""

echo "=== Practica 01 completada ==="

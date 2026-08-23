#!/usr/bin/env bash
# ============================================
# PRACTICA 02: Grupos y Subgrupos
# ============================================
# Crear estructura organizacional jerarquica.

echo "=== Practica 02: Grupos y Subgrupos ==="
echo ""

# ── PASO 1: Crear grupo raiz ──
echo "--- Paso 1: Crear grupo Bootcamp-Org (UI) ---"
echo "1. Groups → New Group"
echo "2. Group name: Bootcamp-Org"
echo "3. URL: bootcamp-org"
echo "4. Visibility: Private"
echo "5. Click Create group"
echo ""

# ── PASO 2: Crear subgrupos ──
echo "--- Paso 2: Crear subgrupos (UI) ---"
echo "Dentro de Bootcamp-Org, crea estos subgrupos:"
echo ""
echo "1. frontend → New subgroup"
echo "2. backend → New subgroup"
echo "3. devops → New subgroup"
echo ""

# ── PASO 3: Crear proyectos dentro de cada subgrupo ──
echo "--- Paso 3: Crear proyectos (UI) ---"
echo "Ve a cada subgrupo y crea proyectos con 'Initialize with README':"
echo ""
echo "bootcamp-org/frontend/:"
echo "  - web-app"
echo "  - mobile-app"
echo ""
echo "bootcamp-org/backend/:"
echo "  - api-gateway"
echo "  - auth-service"
echo ""
echo "bootcamp-org/devops/:"
echo "  - infrastructure"
echo "  - ci-cd-pipelines"
echo ""

# ── PASO 4: Verificar estructura con GitLab API ──
echo "--- Paso 4: Verificar via API ---"
# Descomenta e inserta TU_TOKEN:
# echo "=== Grupos ==="
# curl -s --header "PRIVATE-TOKEN: TU_TOKEN" \
#   "http://localhost/api/v4/groups?search=bootcamp-org" | grep -o '"name":"[^"]*"'
# echo ""
# echo "=== Subgrupos ==="
# curl -s --header "PRIVATE-TOKEN: TU_TOKEN" \
#   "http://localhost/api/v4/groups?search=bootcamp-org" | grep -o '"full_path":"[^"]*"'
echo ""

# ── PASO 5: Documentar estructura ──
echo "--- Paso 5: Documentar ---"
# Descomenta y ejecuta:
# cat > ~/Estructura-Bootcamp-Org.md << 'EOF'
# # Estructura Bootcamp-Org
# 
# ```
# Bootcamp-Org/
# ├── frontend/
# │   ├── web-app
# │   └── mobile-app
# ├── backend/
# │   ├── api-gateway
# │   └── auth-service
# └── devops/
#     ├── infrastructure
#     └── ci-cd-pipelines
# ```
# EOF
# echo "Documentacion guardada en ~/Estructura-Bootcamp-Org.md"
echo ""

echo "=== Practica 02 completada ==="
echo "Verifica en: http://localhost/groups/bootcamp-org"

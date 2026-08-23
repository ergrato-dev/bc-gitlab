#!/usr/bin/env bash
# ============================================
# Practica 01 — REST API con curl
# ============================================

echo "=== Practica 01: REST API ==="
echo ""

# ── Configuracion ──
export GITLAB_URL="${GITLAB_URL:-http://localhost}"
export GITLAB_TOKEN="${GITLAB_TOKEN:-TU_PERSONAL_ACCESS_TOKEN}"

echo "URL: ${GITLAB_URL}"
echo "Token: ${GITLAB_TOKEN:0:8}..."
echo ""

# ── PASO 1: Crear proyecto ──
echo "--- Crear proyecto ---"
# Descomenta:
# curl -s --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
#   "${GITLAB_URL}/api/v4/projects" \
#   --data "name=api-test-project&visibility=private&initialize_with_readme=true" | \
#   python3 -m json.tool | grep -E '"id"|"name"|"web_url"'
echo ""

# ── PASO 2: Listar proyectos ──
echo "--- Listar proyectos ---"
# curl -s --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
#   "${GITLAB_URL}/api/v4/projects?owned=true&per_page=5" | \
#   python3 -c "import sys,json; [print(f'  #{p[\"id\"]} {p[\"name\"]}') for p in json.load(sys.stdin)]"
echo ""

# ── PASO 3: Crear issue ──
echo "--- Crear issue ---"
# Reemplaza PROJECT_ID con el ID del proyecto
# curl -s --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
#   "${GITLAB_URL}/api/v4/projects/PROJECT_ID/issues" \
#   --data "title=Bug encontrado via API&description=Reportado desde curl&labels=bug"
echo ""

# ── PASO 4: Paginacion ──
echo "--- Paginacion ---"
# curl -sI --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
#   "${GITLAB_URL}/api/v4/projects?per_page=2&page=1" | grep -iE "x-total|x-page"
echo ""

# ── PASO 5: Rate limit ──
echo "--- Rate limit headers ---"
# curl -sI --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
#   "${GITLAB_URL}/api/v4/user" | grep -iE "ratelimit"
echo ""

echo "=== Practica 01 completada ==="

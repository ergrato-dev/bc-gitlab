#!/usr/bin/env bash
# ============================================
# Practica 04: Issue Boards (Kanban)
# ============================================

echo "=== Practica 04: Issue Boards ==="
echo ""

# ── PASO 1: Verificar labels de workflow ──
echo "--- Paso 1: Crear labels de workflow (si no existen) ---"
echo "Project → Issues → Labels → New label:"
echo "  workflow::todo         (#CCCCCC)"
echo "  workflow::in-progress  (#428BCA)"
echo "  workflow::review       (#F0AD4E)"
echo "  workflow::done         (#5CB85C)"
echo ""

# ── PASO 2: Crear issues para el board ──
echo "--- Paso 2: Crear issues via API ---"
TOKEN="TU_TOKEN"
PROJECT="bootcamp-org%2Fbackend%2Fapi-gateway"
API="http://localhost/api/v4/projects/$PROJECT/issues"

# Descomenta para crear:
# for title in \
#   "Agregar validacion de inputs en API" \
#   "Crear pagina de login" \
#   "Arreglar estilos del footer" \
#   "Escribir README del proyecto" \
#   "Configurar health checks en Docker"; do
#   curl -s --header "PRIVATE-TOKEN: $TOKEN" \
#     --data "title=$title&labels=workflow::todo" "$API" > /dev/null
# done
# echo "5 issues creados."
echo ""

# ── PASO 3: Crear Issue Board ──
echo "--- Paso 3: Configurar board Kanban (UI) ---"
echo "1. Project → Issues → Boards"
echo "2. Click 'Create board'"
echo "3. Name: Kanban - Sprint 1"
echo "4. Add lists (Create list):"
echo "   - workflow::todo"
echo "   - workflow::in-progress"
echo "   - workflow::review"
echo "   - workflow::done"
echo ""

# ── PASO 4: Mover issues en el board ──
echo "--- Paso 4: Simular flujo Kanban ---"
echo "Arrastra issues entre columnas:"
echo "  1. 'Crear pagina de login' → in-progress"
echo "  2. 'Agregar validacion de inputs' → in-progress"
echo "  3. 'Crear pagina de login' → review"
echo "  4. 'Crear pagina de login' → done (completado!)"
echo ""

# ── PASO 5: Filtrar board ──
echo "--- Paso 5: Filtrar por milestone o label ---"
echo "En el board, usa el filtro para ver solo issues de:"
echo "  - Milestone: Sprint 1"
echo "  - Label: frontend"
echo "Util para ver solo lo relevante a un equipo."
echo ""

# ── PASO 6: Board a nivel grupo ──
echo "--- Paso 6 (opcional): Board en Bootcamp-Org ---"
echo "Groups → Bootcamp-Org → Issues → Boards"
echo "Muestra issues de TODOS los proyectos del grupo."
echo "Ideal para PM/Lead supervisando multiples equipos."
echo ""

echo "=== Practica 04 completada ==="

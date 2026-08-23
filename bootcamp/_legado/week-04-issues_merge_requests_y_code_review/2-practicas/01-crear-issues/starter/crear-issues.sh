#!/usr/bin/env bash
# ============================================
# Practica 01: Crear y Gestionar Issues
# ============================================

echo "=== Practica 01: Issues ==="
echo ""

# ── PASO 1: Crear labels ──
echo "--- Paso 1: Crear labels (UI) ---"
echo "Project → Issues → Labels → New label"
echo "Crea estos labels con colores:"
echo "  bug (#FF0000) | feature (#428BCA) | documentation (#F0AD4E)"
echo "  frontend (#5CB85C) | backend (#8E44AD)"
echo "  priority::1 (#D9534F) | priority::2 (#F0AD4E) | priority::3 (#5BC0DE)"
echo "  workflow::todo | workflow::in-progress | workflow::review | workflow::done"
echo ""

# ── PASO 2: Crear milestone ──
echo "--- Paso 2: Crear milestone (UI) ---"
echo "1. Issues → Milestones → New milestone"
echo "2. Title: Sprint 1"
echo "3. Start date: today | End date: +2 weeks"
echo "4. Create milestone"
echo ""

# ── PASO 3: Crear issues via GitLab API ──
echo "--- Paso 3: Crear issues via API ---"
echo "Reemplaza TOKEN, NAMESPACE y PROJECT:"
# Descomenta y ejecuta con tu token:
# TOKEN="TU_TOKEN"
# PROJECT="bootcamp-org%2Fbackend%2Fapi-gateway"
# API="http://localhost/api/v4/projects/$PROJECT/issues"
# 
# curl -s --header "PRIVATE-TOKEN: $TOKEN" \
#   --data "title=Error 500 en endpoint /health&description=El endpoint /health devuelve 500 cuando...&labels=bug,backend,priority::1&milestone_id=1" \
#   "$API"
# 
# curl -s --header "PRIVATE-TOKEN: $TOKEN" \
#   --data "title=Implementar autenticacion JWT&description=Agregar JWT auth al API Gateway...&labels=feature,backend,priority::2&milestone_id=1" \
#   "$API"
# 
# curl -s --header "PRIVATE-TOKEN: $TOKEN" \
#   --data "title=Documentar endpoints en README&labels=documentation,priority::3&milestone_id=1" \
#   "$API"
echo ""

# ── PASO 4: Listar issues ──
echo "--- Paso 4: Listar issues via API ---"
# curl -s --header "PRIVATE-TOKEN: $TOKEN" "$API?state=opened" | python3 -m json.tool
echo ""

# ── PASO 5: Quick actions ──
echo "--- Paso 5: Usar quick actions en comentarios ---"
echo "En un issue, agrega un comentario con:"
echo "  /assign @your-username"
echo "  /weight 3"
echo "  /due $(date -d '+7 days' +%Y-%m-%d)"
echo ""

# ── PASO 6: Referenciar issue en commit ──
echo "--- Paso 6: Referenciar issue en commit ---"
# cd tu-repo
# echo "# API Docs" >> README.md
# git add README.md
# git commit -m "docs: actualizar README con docs (#1)"
# git push origin main
echo "El issue #1 mostrara la referencia al commit."
echo ""

echo "=== Practica 01 completada ==="

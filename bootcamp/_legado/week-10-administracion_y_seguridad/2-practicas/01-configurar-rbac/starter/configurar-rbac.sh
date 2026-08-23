#!/usr/bin/env bash
# ============================================
# Practica 01 — RBAC: Roles y Permisos
# ============================================

echo "=== Practica 01: RBAC ==="
echo ""
echo "--- Escenario: Equipo Alpha (6 miembros) ---"
echo ""
echo "Crea el grupo 'alpha-team' y el proyecto 'backend-api'"
echo ""

# ── PASO 1: Crear usuarios via API ──
echo "--- Paso 1: Crear usuarios de prueba (Admin Area UI) ---"
echo "Admin Area → Users → New user:"
echo "  tech-lead    / tech@alpha.local"
echo "  dev-senior-1 / senior1@alpha.local"
echo "  dev-senior-2 / senior2@alpha.local"
echo "  dev-junior-1 / junior1@alpha.local"
echo "  dev-junior-2 / junior2@alpha.local"
echo "  qa-engineer  / qa@alpha.local"
echo ""

# ── PASO 2: Matriz de roles ──
echo "--- Paso 2: Asignar roles ---"
cat << 'MATRIX'
Grupo alpha-team (Group → Members):
  tech-lead      → Owner
  dev-senior-1   → Maintainer
  dev-senior-2   → Maintainer
  dev-junior-1   → Developer
  dev-junior-2   → Developer
  qa-engineer    → Reporter

Proyecto backend-api (Project → Members):
  (hereda del grupo - no necesita asignacion extra)
MATRIX
echo ""

# ── PASO 3: Protected branches ──
echo "--- Paso 3: Protected branches ---"
echo "Settings → Repository → Protected branches:"
echo "  main:"
echo "    Allowed to merge: Maintainers"
echo "    Allowed to push:  Nobody"
echo "  develop:"
echo "    Allowed to merge: Developers + Maintainers"
echo "    Allowed to push:  Developers + Maintainers"
echo ""

# ── PASO 4: Verificar permisos (API) ──
echo "--- Paso 4: Verificar via API ---"
TOKEN="TU_ADMIN_TOKEN"
# Listar miembros del grupo
# curl -s --header "PRIVATE-TOKEN: $TOKEN" \
#   "http://localhost/api/v4/groups/alpha-team/members" | \
#   python3 -c "import sys,json;[print(f'  {m[\"username\"]:15s} access={m[\"access_level\"]}') for m in json.load(sys.stdin)]"
echo ""

echo "=== Practica 01 completada ==="

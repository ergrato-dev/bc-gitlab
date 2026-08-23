#!/usr/bin/env bash
# ============================================
# PRACTICA 03: Permisos y Roles
# ============================================
# Configurar miembros con diferentes roles y
# verificar la herencia de permisos.

echo "=== Practica 03: Permisos y Roles ==="
echo ""

# ── PASO 1: Crear usuarios de prueba ──
echo "--- Paso 1: Crear usuarios (Admin Area UI) ---"
echo "Admin Area → Users → New user"
echo "Crea 3 usuarios:"
echo "  developer1 / developer1@bootcamp.local"
echo "  maintainer1 / maintainer1@bootcamp.local"
echo "  reporter1 / reporter1@bootcamp.local"
echo ""
echo "O via API si tienes token root:"
# Descomenta y ejecuta con token root:
# for user in developer1 maintainer1 reporter1; do
#   curl --request POST \
#     --header "PRIVATE-TOKEN: TU_ROOT_TOKEN" \
#     --data "email=${user}@bootcamp.local&username=${user}&name=${user^}&password=Bootcamp2025!&skip_confirmation=true" \
#     "http://localhost/api/v4/users"
# done
echo ""

# ── PASO 2: Agregar miembros al grupo raiz ──
echo "--- Paso 2: Invitar miembros a Bootcamp-Org (UI) ---"
echo "1. Ve a http://localhost/groups/bootcamp-org/-/group_members"
echo "2. Invite members:"
echo "   - maintainer1 → Maintainer"
echo "   - developer1 → Developer"
echo "   - reporter1 → Reporter"
echo ""

# ── PASO 3: Verificar herencia ──
echo "--- Paso 3: Verificar herencia ---"
echo "Abre una ventana incognito para cada usuario y verifica:"
echo ""
echo "developer1:"
echo "  http://localhost/bootcamp-org/frontend/web-app → ¿puede ver codigo?"
echo "  http://localhost/bootcamp-org/backend/api-gateway → ¿puede crear MR?"
echo ""
echo "reporter1:"
echo "  http://localhost/bootcamp-org/devops/infrastructure → ¿puede hacer push?"
echo "  Deberia ver codigo pero no poder pushear"
echo ""

# ── PASO 4: Permiso granular en proyecto especifico ──
echo "--- Paso 4: Permiso granular (UI) ---"
echo "1. Ve a bootcamp-org/devops/infrastructure → Settings → Members"
echo "2. Agrega reporter1 con rol Developer (SOLO en este proyecto)"
echo "3. Verifica que reporter1 ahora puede pushear a infrastructure"
echo "4. Verifica que en web-app sigue siendo Reporter"
echo ""

# ── PASO 5: Documentar matriz de permisos ──
echo "--- Paso 5: Documentar ---"
cat > ~/matriz-permisos.md << 'EOF'
# Matriz de Permisos — Bootcamp-Org

| Miembro | Rol heredado | web-app | api-gateway | infrastructure |
|---------|-------------|---------|-------------|----------------|
| maintainer1 | Maintainer | Maintainer | Maintainer | Maintainer |
| developer1 | Developer | Developer | Developer | Developer |
| reporter1 | Reporter → Developer en infra | Reporter | Reporter | **Developer** |
| root | Owner | Owner | Owner | Owner |
EOF
echo "Matriz guardada en ~/matriz-permisos.md"
echo ""

echo "=== Practica 03 completada ==="

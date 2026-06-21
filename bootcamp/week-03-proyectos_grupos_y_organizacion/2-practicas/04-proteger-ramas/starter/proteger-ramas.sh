#!/usr/bin/env bash
# ============================================
# PRACTICA 04: Proteger Ramas
# ============================================
# Configurar proteccion de ramas y verificar
# que las reglas se cumplen en la practica.

echo "=== Practica 04: Proteger Ramas ==="
echo ""

# ── PASO 1: Configurar proteccion en main (UI) ──
echo "--- Paso 1: Proteger main en api-gateway ---"
echo "1. Ve a http://localhost/bootcamp-org/backend/api-gateway"
echo "2. Settings → Repository → Protected branches"
echo "3. Expand → Select branch: main"
echo "4. Allowed to merge: Maintainers"
echo "5. Allowed to push: Nobody"
echo "6. Click Protect"
echo ""

# ── PASO 2: Intentar push directo (debe fallar) ──
echo "--- Paso 2: Intentar push directo como developer1 ---"
echo "Abre terminal como developer1 y ejecuta:"
# Descomenta en sesion de developer1:
# git clone git@gitlab.local:bootcamp-org/backend/api-gateway.git
# cd api-gateway
# echo "intento directo" >> README.md
# git add README.md && git commit -m "test: intento push directo"
# git push origin main
# # Debe mostrar: "remote: You are not allowed to push code to protected branches"
echo ""

# ── PASO 3: Flujo correcto con MR ──
echo "--- Paso 3: Flujo correcto via Merge Request ---"
# git checkout -b feature/test-protection
# echo "cambio via MR" >> README.md
# git add README.md && git commit -m "feat: cambio via merge request"
# git push origin feature/test-protection
echo "GitLab mostrara banner para crear MR. Crealo."
echo ""

# ── PASO 4: Merge como Maintainer ──
echo "--- Paso 4: Merge como maintainer1 ---"
echo "Inicia sesion como maintainer1 y:"
echo "1. Ve al MR en http://localhost/bootcamp-org/backend/api-gateway/-/merge_requests"
echo "2. Revisa los cambios → Approve"
echo "3. Click Merge"
echo ""

# ── PASO 5: Proteger con wildcard ──
echo "--- Paso 5: Proteger release/* con wildcard ---"
echo "1. Settings → Repository → Protected branches"
echo "2. Select wildcard: release/*"
echo "3. Allowed to merge: Maintainers"
echo "4. Allowed to push: Nobody"
echo "5. Click Protect"
echo ""
echo "Prueba:"
# git checkout -b release/1.0.0
# echo "v1.0.0" > VERSION
# git add VERSION && git commit -m "chore: version 1.0.0"
# git push origin release/1.0.0
# # Debe ser rechazado - push directo bloqueado
echo ""

# ── PASO 6: Pipeline must succeed (preparando para CI/CD) ──
echo "--- Paso 6: Configurar pipeline must succeed ---"
echo "1. Settings → Merge requests → Merge checks"
echo "2. Marcar 'Pipelines must succeed'"
echo "3. Marcar 'All threads must be resolved'"
echo "Esto obligara a que los pipelines pasen antes del merge (Semana 05+)"
echo ""

echo "=== Practica 04 completada ==="
echo "Verifica protected branches en:"
echo "  http://localhost/bootcamp-org/backend/api-gateway/-/settings/repository"

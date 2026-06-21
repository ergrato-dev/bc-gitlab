#!/usr/bin/env bash
# ============================================
# PRACTICA 02: Flujo Git Basico
# ============================================
# Precondicion: Tener un proyecto creado en GitLab CE
# y SSH configurado (Practica 01).

set -euo pipefail

echo "=== Practica 02: Flujo Git Basico ==="
echo ""

# ── PASO 1: Clonar repositorio ──
echo "--- Paso 1: Clonar repositorio ---"
echo "Reemplaza <tu-proyecto> con el nombre de tu proyecto en GitLab"
# Descomenta y ejecuta:
# git clone git@gitlab.local:root/<tu-proyecto>.git
# cd <tu-proyecto>
echo ""

# ── PASO 2: Verificar estado inicial ──
echo "--- Paso 2: Verificar estado inicial ---"
# Descomenta y ejecuta:
# git status
# git log --oneline
echo ""

# ── PASO 3: Crear archivo nuevo ──
echo "--- Paso 3: Crear archivo nuevo ---"
# Descomenta y ejecuta:
# echo "# Mi primer proyecto DevOps" > README.md
echo ""

# ── PASO 4: Ver cambios ──
echo "--- Paso 4: Ver cambios con git diff/status ---"
# Descomenta y ejecuta:
# git status
# git diff
echo ""

# ── PASO 5: Agregar al staging ──
echo "--- Paso 5: git add (mover a staging) ---"
# Descomenta y ejecuta:
# git add README.md
# git status
echo ""

# ── PASO 6: Hacer commit ──
echo "--- Paso 6: git commit (guardar snapshot) ---"
# Descomenta y ejecuta:
# git commit -m "docs: agregar titulo al README"
# git log --oneline
echo ""

# ── PASO 7: Subir cambios ──
echo "--- Paso 7: git push (subir a GitLab) ---"
# Descomenta y ejecuta:
# git push origin main
echo ""

# ── PASO 8: Modificar archivo existente ──
echo "--- Paso 8: Modificar archivo existente ---"
# Descomenta y ejecuta:
# echo "" >> README.md
# echo "Proyecto creado durante el Bootcamp GitLab CE Zero to Hero." >> README.md
# git status
echo ""

# ── PASO 9: Commit y push de la modificacion ──
echo "--- Paso 9: Commit y push ---"
# Descomenta y ejecuta:
# git add README.md
# git commit -m "docs: agregar descripcion del proyecto"
# git push origin main
echo ""

echo ""
echo "=== Practica 02 completada ==="
echo "Verifica en GitLab CE que los commits aparezcan:"
echo "  http://localhost/root/<tu-proyecto> → Repository → Commits"

#!/usr/bin/env bash
# ============================================
# PRACTICA 03: Ramas y Merges
# ============================================
# Aprenderas a crear ramas, trabajar en ellas y
# fusionarlas a la rama principal.

set -euo pipefail

echo "=== Practica 03: Ramas y Merges ==="
echo ""

# ── PASO 1: Crear rama feature ──
echo "--- Paso 1: Crear y cambiar a rama feature/readme ---"
# Descomenta y ejecuta:
# git checkout -b feature/readme
echo ""

# ── PASO 2: Verificar rama actual ──
echo "--- Paso 2: Verificar en que rama estamos ---"
# Descomenta y ejecuta:
# git branch
# git status
echo ""

# ── PASO 3: Hacer cambios en la rama feature ──
echo "--- Paso 3: Editar archivo en feature/readme ---"
# Descomenta y ejecuta:
# cat >> README.md << 'EOF'
# 
# ## Descripcion
# 
# Este proyecto demuestra el uso de Git y GitLab CE para
# control de versiones y colaboracion.
# EOF
# git status
echo ""

# ── PASO 4: Commit en la rama feature ──
echo "--- Paso 4: Commit en feature/readme ---"
# Descomenta y ejecuta:
# git add README.md
# git commit -m "docs: agregar seccion Descripcion al README"
echo ""

# ── PASO 5: Ver historial de la rama ──
echo "--- Paso 5: Ver historial ---"
# Descomenta y ejecuta:
# git log --oneline --graph --all
echo ""

# ── PASO 6: Volver a main y fusionar ──
echo "--- Paso 6: Merge feature/readme → main ---"
# Descomenta y ejecuta:
# git checkout main
# git merge feature/readme
echo ""

# ── PASO 7: Verificar merge ──
echo "--- Paso 7: Ver historial post-merge ---"
# Descomenta y ejecuta:
# git log --oneline --graph --all
echo ""

# ── PASO 8: Eliminar rama fusionada ──
echo "--- Paso 8: Eliminar rama feature/readme ---"
# Descomenta y ejecuta:
# git branch -d feature/readme
# git branch
echo ""

# ── PASO 9: Subir main actualizado ──
echo "--- Paso 9: Push de main actualizado ---"
# Descomenta y ejecuta:
# git push origin main
echo ""

echo ""
echo "=== Practica 03 completada ==="
echo "Verifica el grafo de commits con:"
echo "  git log --oneline --graph --all"

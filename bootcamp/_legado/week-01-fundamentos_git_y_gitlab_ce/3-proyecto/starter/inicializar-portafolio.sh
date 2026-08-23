#!/usr/bin/env bash
# ============================================
# Proyecto Semana 01: Inicializar portafolio
# ============================================
# Este script genera la estructura base del proyecto.
# Descomenta los bloques y ejecutalos en orden.
# NO es un script para ejecutar de corrido — es una
# guia paso a paso.

echo "=== Proyecto Semana 01: Portafolio DevOps ==="
echo ""
echo "Sigue las instrucciones descomentando cada bloque."
echo ""

# ── PASO 1: Crear carpeta e inicializar Git ──
echo "--- Paso 1: Inicializar repositorio local ---"
# mkdir -p ~/mi-portafolio-devops
# cd ~/mi-portafolio-devops
# git init
# git remote add origin git@gitlab.local:root/mi-portafolio-devops.git
echo ""

# ── PASO 2: Crear estructura de carpetas ──
echo "--- Paso 2: Crear estructura ---"
# mkdir -p src docs
echo ""

# ── PASO 3: README.md ──
echo "--- Paso 3: Crear README.md ---"
# cat > README.md << 'EOF'
# # Mi Portafolio DevOps
# Proyecto del Bootcamp GitLab CE Zero to Hero.
# EOF
echo ""

# ── PASO 4: .gitignore ──
echo "--- Paso 4: Crear .gitignore ---"
# cat > .gitignore << 'EOF'
# *.log
# *.tmp
# .DS_Store
# EOF
echo ""

# ── PASO 5: Script de ejemplo ──
echo "--- Paso 5: Crear script de ejemplo ---"
# cat > src/hello.sh << 'EOF'
# #!/usr/bin/env bash
# echo "Hola DevOps!"
# EOF
# chmod +x src/hello.sh
echo ""

# ── PASO 6: Notas de aprendizaje ──
echo "--- Paso 6: Crear notas ---"
# cat > docs/notas.md << 'EOF'
# # Notas de Aprendizaje
# ## Semana 01
# - Git y GitLab CE fundamentos
# EOF
echo ""

# ── PASO 7: Primer commit ──
echo "--- Paso 7: Primer commit ---"
# git add -A
# git commit -m "feat: inicializar portafolio DevOps"
# git branch -M main
# git push -u origin main
echo ""

# ── PASO 8: Crear rama develop ──
echo "--- Paso 8: Crear rama develop ---"
# git checkout -b develop
# echo "## Proximos temas" >> docs/notas.md
# git add docs/notas.md
# git commit -m "docs: agregar proximos temas"
# git push -u origin develop
echo ""

# ── PASO 9: Merge a main ──
echo "--- Paso 9: Merge develop → main ---"
# git checkout main
# git merge develop
# git push origin main
echo ""

echo ""
echo "=== Proyecto completado ==="
echo "Verifica en GitLab CE: http://localhost/root/mi-portafolio-devops"

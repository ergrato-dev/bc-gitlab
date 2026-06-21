#!/usr/bin/env bash
# ============================================
# Practica 02: Crear Merge Requests
# ============================================

echo "=== Practica 02: Merge Requests ==="
echo ""

# ── PASO 1: Crear template de MR ──
echo "--- Paso 1: Crear template de MR ---"
# cd tu-proyecto
# mkdir -p .gitlab/merge_request_templates
# cat > .gitlab/merge_request_templates/Default.md << 'EOF'
# ## Descripcion
# [Describe los cambios]
# 
# ## Issue Relacionado
# Closes #
# 
# ## Tipo de Cambio
# - [ ] Bug fix  - [ ] Feature  - [ ] Refactor  - [ ] Docs
# 
# ## Checklist
# - [ ] Codigo probado  - [ ] Pipeline verde  - [ ] No codigo comentado
# 
# /assign @me
# EOF
# git add .gitlab/ && git commit -m "chore: agregar template de MR" && git push
echo ""

# ── PASO 2: Crear rama con ID del issue ──
echo "--- Paso 2: Crear rama feature ---"
# git checkout main && git pull origin main
# git checkout -b 2-jwt-authentication
echo ""

# ── PASO 3: Hacer cambios y push ──
echo "--- Paso 3: Codigo + commit + push ---"
# mkdir -p src/auth
# echo "// JWT auth module" > src/auth/jwt.js
# git add src/auth/
# git commit -m "feat: implementar modulo JWT (#2)"
# git push origin 2-jwt-authentication
echo ""

# ── PASO 4: Crear MR con template (UI) ──
echo "--- Paso 4: Crear MR en UI ---"
echo "GitLab mostrara banner 'Create merge request'. Click y:"
echo "1. Template: Default"
echo "2. Title: Draft: Implementar autenticacion JWT"
echo "3. Description: completar y vincular Closes #2"
echo "4. Assign reviewer (si hay otro usuario)"
echo "5. Create merge request"
echo ""

# ── PASO 5: Merge methods via API ──
echo "--- Paso 5: Merge usando squash ---"
echo "En la UI del MR, explora las opciones:"
echo "  - Merge commit"
echo "  - Squash and merge ← Recomendado para historial limpio"
echo ""
echo "Solo Maintainer puede mergear. Si no eres maintainer:"
echo "  - Pide approval"
echo "  - Maintainer hace merge con squash"
echo ""

# ── PASO 6: Segundo MR ──
echo "--- Paso 6: Crear segundo MR (documentacion) ---"
# git checkout main && git pull
# git checkout -b 3-api-docs
# echo "## Endpoints" >> README.md
# git add README.md && git commit -m "docs: documentar API endpoints (#3)"
# git push origin 3-api-docs
# Crear MR en UI, mergear
echo ""

echo "=== Practica 02 completada ==="

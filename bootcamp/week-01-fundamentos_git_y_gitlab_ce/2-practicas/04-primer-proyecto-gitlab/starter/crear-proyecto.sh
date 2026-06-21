#!/usr/bin/env bash
# ============================================
# PRACTICA 04: Primer Proyecto en GitLab CE
# ============================================
# Integra todo lo aprendido: crear proyecto en
# GitLab UI, conectar con SSH, trabajar con Git.

echo "=== Practica 04: Primer Proyecto en GitLab CE ==="
echo ""

# ── FASE 1: En GitLab CE (UI) ──
echo "--- Fase 1: Crear proyecto en GitLab CE ---"
echo "1. Abre http://localhost en tu navegador"
echo "2. Inicia sesion como root"
echo "3. Click en 'New Project' → 'Create blank project'"
echo "4. Nombre: practica-04-gitlab"
echo "5. Visibility: Private"
echo "6. Marca 'Initialize repository with a README'"
echo "7. Click 'Create project'"
echo ""

# ── FASE 2: Agregar SSH Key ──
echo "--- Fase 2: Agregar clave SSH a GitLab ---"
echo "1. Ve a Preferences → SSH Keys"
echo "2. Pega tu clave publica (~/.ssh/id_ed25519_bootcamp.pub)"
echo "3. Titulo: 'mi-laptop-bootcamp'"
echo "4. Click 'Add key'"
echo ""

# ── FASE 3: Clonar localmente ──
echo "--- Fase 3: Clonar proyecto ---"
# Descomenta y ejecuta:
# git clone git@gitlab.local:root/practica-04-gitlab.git
# cd practica-04-gitlab
echo ""

# ── FASE 4: Estructurar proyecto ──
echo "--- Fase 4: Agregar archivos al proyecto ---"

# Crear estructura basica
# Descomenta y ejecuta:
# mkdir -p src docs
# echo "print('Hola desde GitLab CE')" > src/main.py
# echo "# Documentacion" > docs/README.md
# echo "node_modules/" > .gitignore
# echo "__pycache__/" >> .gitignore
# echo "*.log" >> .gitignore
echo ""

# ── FASE 5: Commit y push ──
echo "--- Fase 5: Commit y push ---"
# Descomenta y ejecuta:
# git status
# git add -A
# git commit -m "feat: agregar estructura inicial del proyecto
# 
# - src/main.py: script principal
# - docs/README.md: documentacion
# - .gitignore: reglas de ignorado"
# git push origin main
echo ""

echo ""
echo "=== Practica 04 completada ==="
echo "Verifica en GitLab CE que todos los archivos aparezcan:"
echo "  http://localhost/root/practica-04-gitlab"

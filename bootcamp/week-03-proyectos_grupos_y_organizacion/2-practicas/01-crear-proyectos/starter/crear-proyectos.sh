#!/usr/bin/env bash
# ============================================
# PRACTICA 01: Crear Proyectos en GitLab CE
# ============================================
# Guia paso a paso. Descomenta y ejecuta.
# Algunas tareas son via UI (indicadas).

echo "=== Practica 01: Crear Proyectos ==="
echo ""

# ── PASO 1: Proyecto en blanco ──
echo "--- Paso 1: Crear proyecto en blanco (UI) ---"
echo "1. Dashboard → New Project → Create blank project"
echo "2. Project name: practica-proyecto-01"
echo "3. Visibility: Private"
echo "4. Marcar 'Initialize repository with a README'"
echo "5. Click Create project"
echo ""

# ── PASO 2: Proyecto desde template ──
echo "--- Paso 2: Crear proyecto desde template (UI) ---"
echo "1. New Project → Create from template"
echo "2. Seleccionar Pages/Plain HTML"
echo "3. Project name: practica-template"
echo "4. Visibility: Private"
echo "5. Click Create project"
echo ""

# ── PASO 3: Importar proyecto desde URL ──
echo "--- Paso 3: Importar proyecto (UI) ---"
echo "1. New Project → Import project → Repo by URL"
echo "2. Git repo URL: https://github.com/octocat/Hello-World.git"
echo "3. Project name: practica-import"
echo "4. Visibility: Private"
echo "5. Click Create project"
echo ""

# ── PASO 4: Crear proyecto via API ──
echo "--- Paso 4: Crear via API (terminal) ---"
echo "Primero genera un token de acceso:"
echo "  Settings → Access Tokens → Add new token"
echo "  Name: practica-api | Scopes: api | Copy the token"
echo ""
echo "Luego ejecuta:"
# Descomenta y reemplaza TU_TOKEN:
# curl --request POST \
#   --header "PRIVATE-TOKEN: TU_TOKEN" \
#   --data "name=practica-api&visibility=private&initialize_with_readme=true" \
#   "http://localhost/api/v4/projects"
echo ""

# ── PASO 5: Clonar proyecto creado ──
echo "--- Paso 5: Clonar y verificar ---"
# Descomenta y ejecuta:
# git clone git@gitlab.local:root/practica-proyecto-01.git
# cd practica-proyecto-01
# echo "Proyecto creado en Semana 03" >> README.md
# git add README.md && git commit -m "docs: agregar nota de semana 03"
# git push origin main
echo ""

echo "=== Practica 01 completada ==="
echo "Verifica en: http://localhost → Projects → Your projects"

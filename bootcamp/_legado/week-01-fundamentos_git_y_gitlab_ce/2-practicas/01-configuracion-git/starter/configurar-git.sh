#!/usr/bin/env bash
# ============================================
# PRACTICA 01: Configuracion de Git
# ============================================
# Instrucciones: Descomenta cada bloque y ejecutalo en orden.
# Verifica cada paso antes de continuar.

echo "=== Practica 01: Configuracion de Git ==="
echo ""

# ── PASO 1: Configurar identidad ──
echo "--- Paso 1: Configurar identidad ---"
# Descomenta y ejecuta:
# git config --global user.name "Tu Nombre Completo"
# git config --global user.email "tu@email.com"
echo "Ejecuta los comandos de arriba con tus datos reales"
echo ""

# ── PASO 2: Configurar editor ──
echo "--- Paso 2: Configurar editor por defecto ---"
# Descomenta y ejecuta:
# git config --global core.editor "code --wait"
echo ""

# ── PASO 3: Configurar rama por defecto ──
echo "--- Paso 3: Configurar rama por defecto ---"
# Descomenta y ejecuta:
# git config --global init.defaultBranch main
echo ""

# ── PASO 4: Activar color en output ──
echo "--- Paso 4: Activar colores ---"
# Descomenta y ejecuta:
# git config --global color.ui auto
echo ""

# ── PASO 5: Generar clave SSH ──
echo "--- Paso 5: Generar clave SSH ---"
# Descomenta y ejecuta (cambia el email):
# ssh-keygen -t ed25519 -C "tu@email.com" -f ~/.ssh/id_ed25519_bootcamp
echo ""

# ── PASO 6: Iniciar ssh-agent y agregar clave ──
echo "--- Paso 6: Agregar clave al agente SSH ---"
# Descomenta y ejecuta:
# eval "$(ssh-agent -s)"
# ssh-add ~/.ssh/id_ed25519_bootcamp
echo ""

# ── PASO 7: Configurar ~/.ssh/config ──
echo "--- Paso 7: Configurar acceso SSH simplificado ---"
# Descomenta y ejecuta:
# cat >> ~/.ssh/config << 'EOF'
# Host gitlab.local
#     HostName localhost
#     Port 2224
#     User git
#     IdentityFile ~/.ssh/id_ed25519_bootcamp
# EOF
echo ""

# ── PASO 8: Verificar configuracion ──
echo "--- Paso 8: Verificar configuracion ---"
# Descomenta y ejecuta:
# git config --list
# cat ~/.ssh/id_ed25519_bootcamp.pub
echo ""

echo ""
echo "=== Practica 01 completada ==="
echo "Ahora copia la clave publica (Paso 8) y agregala en GitLab CE:"
echo "  http://localhost → Preferences → SSH Keys"

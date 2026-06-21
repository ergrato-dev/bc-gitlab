#!/usr/bin/env bash
# ============================================
# PRACTICA 02: Levantar GitLab CE con Docker Compose
# ============================================
# Usa el docker-compose.yml de la raiz del proyecto.
# Este script es una guia paso a paso, descomenta y ejecuta.

echo "=== Practica 02: Levantar GitLab CE ==="
echo ""

# ── PASO 1: Verificar que estas en la raiz del proyecto ──
echo "--- Paso 1: Verificar ubicacion ---"
# Descomenta y ejecuta:
# ls docker-compose.yml .env.example
# Si no ves los archivos: cd ~/bc-gitlab
echo ""

# ── PASO 2: Ver .env configurado ──
echo "--- Paso 2: Ver variables de entorno ---"
# Descomenta y ejecuta:
# grep -E '^[A-Z]' .env | grep -v '^#'
echo ""

# ── PASO 3: Levantar GitLab CE (+ Runner + Registry) ──
echo "--- Paso 3: Levantar servicios ---"
# Descomenta y ejecuta:
# docker compose up -d
echo "Esto levanta: gitlab, gitlab-runner, registry-cache"
echo ""

# ── PASO 4: Monitorear inicio (primer inicio ~5 min) ──
echo "--- Paso 4: Ver logs en tiempo real ---"
# Descomenta y ejecuta:
# docker compose logs -f gitlab
# Ctrl+C para salir de los logs
echo ""

# ── PASO 5: Verificar estado ──
echo "--- Paso 5: Verificar salud de servicios ---"
# Descomenta y ejecuta:
# docker compose ps
# docker compose exec gitlab gitlab-ctl status
echo ""

# ── PASO 6: Probar HTTP ──
echo "--- Paso 6: Verificar que GitLab responde ---"
# Descomenta y ejecuta:
# curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost
# Esperar hasta que devuelva 200 o 302
echo ""

# ── PASO 7: Obtener contrasena root ──
echo "--- Paso 7: Obtener contrasena root inicial ---"
# Descomenta y ejecuta:
# docker compose exec gitlab grep 'Password:' /etc/gitlab/initial_root_password
echo "GUARDA ESTA CONTRASENA. El archivo se borra en 24h."
echo ""

# ── PASO 8: Acceder a GitLab CE ──
echo "--- Paso 8: Acceder a GitLab CE ---"
echo "Abre http://localhost en tu navegador"
echo "Usuario: root"
echo "Contrasena: la obtenida en el Paso 7"
echo ""

echo ""
echo "=== GitLab CE funcionando ==="

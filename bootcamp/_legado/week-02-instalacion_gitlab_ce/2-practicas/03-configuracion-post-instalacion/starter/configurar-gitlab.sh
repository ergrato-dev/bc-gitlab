#!/usr/bin/env bash
# ============================================
# PRACTICA 03: Configuracion Post-Instalacion
# ============================================
# Tareas que se hacen UNA SOLA VEZ despues de
# levantar GitLab CE por primera vez.

echo "=== Practica 03: Configuracion Post-Instalacion ==="
echo ""
echo "Algunas tareas se hacen desde la UI. Otras desde la terminal."
echo ""

# ── TAREAS DE UI (Navegador) ──
echo "--- Tareas en el navegador (http://localhost) ---"
echo ""
echo "1. Iniciar sesion como root"
echo "2. Avatar → Preferences → Password → Cambiar contrasena"
echo "3. Admin Area → Settings → Appearance:"
echo "   - Title: 'Bootcamp DevOps - [Tu Nombre]'"
echo "   - Description: 'Instancia de practica'"
echo "4. Admin Area → Settings → General → Sign-up: Disabled"
echo "5. Admin Area → Settings → General → Default project visibility: Private"
echo ""

# ── TAREAS DE TERMINAL ──
echo "--- Tareas en la terminal ---"
echo ""

# Verificar que todos los servicios internos corren
echo "Verificar servicios internos:"
# Descomenta y ejecuta:
# docker compose exec gitlab gitlab-ctl status
echo ""

# Ver configuracion aplicada
echo "Ver configuracion de GitLab:"
# Descomenta y ejecuta:
# docker compose exec gitlab grep -v '^#' /etc/gitlab/gitlab.rb | grep -v '^$'
echo ""

# Probar envio de email (si configuraste SMTP)
echo "Probar envio de email (solo si configuraste SMTP):"
# Descomenta y ejecuta:
# docker compose exec gitlab gitlab-rails runner "Notify.test_email('tu@email.com', 'Test', 'GitLab CE funcionando').deliver_now"
echo ""

# Crear usuario de prueba (opcional)
echo "Crear usuario estudiante de prueba:"
# Descomenta y ejecuta:
# docker compose exec gitlab gitlab-rails runner "User.create!(username: 'estudiante', email: 'estudiante@bootcamp.local', name: 'Estudiante Bootcamp', password: 'Bootcamp2025!', password_confirmation: 'Bootcamp2025!', admin: false)"
echo ""

echo ""
echo "=== Configuracion post-instalacion completada ==="
echo "Verifica en http://localhost que los cambios se aplicaron."

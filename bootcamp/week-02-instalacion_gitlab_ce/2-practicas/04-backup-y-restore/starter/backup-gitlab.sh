#!/usr/bin/env bash
# ============================================
# PRACTICA 04: Backup y Restore
# ============================================
# Crear un backup completo de GitLab CE y
# verificar el proceso de restauracion.

echo "=== Practica 04: Backup y Restore ==="
echo ""

# ── PASO 1: Crear proyecto de prueba ──
echo "--- Paso 1: Crear proyecto test-backup (hacer en UI) ---"
echo "1. http://localhost → New Project → Create blank project"
echo "2. Nombre: test-backup"
echo "3. Marcar 'Initialize with README'"
echo "4. Click Create project"
echo ""

# ── PASO 2: Backup completo ──
echo "--- Paso 2: Ejecutar gitlab-backup create ---"
# Descomenta y ejecuta:
# docker compose exec gitlab gitlab-backup create
echo ""

# ── PASO 3: Ver backups generados ──
echo "--- Paso 3: Listar backups ---"
# Descomenta y ejecuta:
# docker compose exec gitlab ls -lh /var/opt/gitlab/backups/
echo ""

# ── PASO 4: Respaldar archivos de configuracion ──
echo "--- Paso 4: Respaldar configuracion critica ---"
# Descomenta y ejecuta:
# mkdir -p ./backups/config
# docker compose exec gitlab cat /etc/gitlab/gitlab-secrets.json > ./backups/config/gitlab-secrets.json
# docker compose cp gitlab:/etc/gitlab/gitlab.rb ./backups/config/gitlab.rb.bak
echo "CRITICO: gitlab-secrets.json contiene claves de encriptacion."
echo "Sin este archivo NO podras restaurar backups."
echo ""

# ── PASO 5: Copiar backup al host ──
echo "--- Paso 5: Extraer backup al host ---"
# Descomenta y ejecuta:
# mkdir -p ./backups/data
# docker compose cp gitlab:/var/opt/gitlab/backups/ ./backups/data/
echo ""

# ── PASO 6: Script de backup automatico ──
echo "--- Paso 6: Crear script de backup programado ---"
# Descomenta y ejecuta:
# cat > ./backups/auto-backup.sh << 'SCRIPT'
# #!/bin/bash
# cd ~/bc-gitlab
# TIMESTAMP=$(date +%Y%m%d_%H%M%S)
# mkdir -p ./backups/data
# docker compose exec -T gitlab gitlab-backup create
# docker compose cp gitlab:/var/opt/gitlab/backups/ ./backups/data/
# echo "[$TIMESTAMP] Backup completado: ./backups/data/"
# SCRIPT
# chmod +x ./backups/auto-backup.sh
echo ""

# ── PASO 7: Simular restore (SOLO EN PRACTICA) ──
echo "--- Paso 7: Probar restore (OPCIONAL - SOLO PRACTICA) ---"
echo "ADVERTENCIA: Restaurar un backup SOBRESCRIBE los datos actuales."
echo "Solo hacer en entorno de practica, NUNCA en produccion."
echo ""
echo "Comandos para restore (NO ejecutar sin entender):"
echo "  docker compose exec gitlab gitlab-ctl stop puma"
echo "  docker compose exec gitlab gitlab-ctl stop sidekiq"
echo "  docker compose exec gitlab gitlab-backup restore BACKUP=TIMESTAMP"
echo "  docker compose exec gitlab gitlab-ctl reconfigure"
echo "  docker compose exec gitlab gitlab-ctl restart"
echo ""

echo ""
echo "=== Backup completado ==="
echo "Backups en: ./backups/data/"
echo "Config en : ./backups/config/"

#!/usr/bin/env bash
# ============================================
# Proyecto Semana 11 — Disaster Recovery Plan
# ============================================

echo "============================================="
echo "  Disaster Recovery Plan — Bootcamp GitLab CE"
echo "============================================="
echo ""

cat << 'PLAN'
## Plan de Disaster Recovery

### Escenarios y Procedimientos

1. FALLO DE DISCO
   Deteccion: Alertas de espacio en disco (>80%), errores E/S
   RTO: 2 horas | RPO: 1 hora
   Procedimiento:
   a. Notificar al equipo por Slack/email
   b. Crear backup de emergencia si es posible
   c. Provisionar nuevo storage (VM/nodo)
   d. Restaurar backup: ./restore.sh <timestamp>
   e. Verificar: gitlab-rake gitlab:check, UI funcional
   f. Comunicar resolucion

2. FALLO DE BASE DE DATOS
   Deteccion: Errores 500, gitlab-ctl status muestra postgresql down
   RTO: 30 min | RPO: ~0 (WAL archiving)
   Procedimiento:
   a. Si Patroni: failover automatico → verificar nuevo primario
   b. Si standalone: restaurar desde backup + WAL (PITR)
   c. gitlab-ctl reconfigure
   d. Verificar conteo de registros

3. DESASTRE DE DATACENTER
   Deteccion: Todos los servicios offline, no responde ping
   RTO: 4 horas | RPO: 24 horas
   Procedimiento:
   a. Activar plan de DR completo
   b. Provisionar infraestructura en sitio alterno (Docker Compose)
   c. Descargar backups desde S3/NFS off-site
   d. Ejecutar dr-restore.sh automatizado
   e. Cambiar DNS al nuevo sitio
   f. Verificar integridad completa

4. RANSOMWARE
   Deteccion: Archivos encriptados, nota de rescate
   RTO: 8 horas | RPO: 24 horas
   Procedimiento:
   a. AISLAR inmediatamente (desconectar red)
   b. NO pagar rescate
   c. Destruir infraestructura comprometida
   d. Restaurar desde backup limpio (off-site)
   e. Rotar todas las credenciales (tokens, passwords, SSH keys)
   f. Analisis forense: como entraron?

5. ERROR HUMANO (DROP TABLE)
   Deteccion: Usuario reporta datos perdidos
   RTO: 1 hora | RPO: ~0 (PITR)
   Procedimiento:
   a. Identificar timestamp del error
   b. Restaurar backup mas reciente
   c. Aplicar WAL hasta justo antes del error (PITR)
   d. Verificar datos

### Contactos de Emergencia
- DevOps Lead: [nombre] - [telefono] - [email]
- DBA: [nombre] - [telefono]
- Manager: [nombre] - [telefono]

### Ubicacion de Backups
- Local: /var/opt/gitlab/backups/ (rotacion 7 dias)
- Off-site: S3/MinIO bucket (diario, retencion 90 dias)
- Config: gitlab-secrets.json + gitlab.rb en 1Password/Vault
PLAN
echo ""

echo ">>> Verificar estado actual"
TOKEN="${GITLAB_TOKEN:-TU_TOKEN}"
# curl -s --header "PRIVATE-TOKEN: $TOKEN" \
#   "http://localhost/api/v4/health" | python3 -m json.tool
echo ""

echo "============================================="

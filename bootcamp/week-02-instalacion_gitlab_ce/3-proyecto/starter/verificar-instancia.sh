#!/usr/bin/env bash
# ============================================
# Proyecto Semana 02 — Script de Verificacion
# ============================================
# Ejecuta este script para verificar que tu
# instancia GitLab CE esta correctamente configurada.
# Adjunta la salida a tu entrega.

echo "============================================="
echo "  Verificacion — Semana 02"
echo "  GitLab CE en Docker — Bootcamp Zero to Hero"
echo "============================================="
echo ""

# ── Docker status ──
echo ">>> Docker Compose Status"
# docker compose ps
echo ""

# ── GitLab health ──
echo ">>> GitLab Internal Services"
# docker compose exec gitlab gitlab-ctl status
echo ""

# ── HTTP check ──
echo ">>> HTTP Response Check"
# curl -s -o /dev/null -w "Status: %{http_code} | Time: %{time_total}s\n" http://localhost
echo ""

# ── Version de GitLab ──
echo ">>> GitLab Version"
# docker compose exec gitlab gitlab-rake gitlab:env:info 2>/dev/null | grep -E "Version|Revision"
echo ""

# ── Recursos ──
echo ">>> Container Resources"
# docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
echo ""

# ── Backups ──
echo ">>> Backups Disponibles"
# docker compose exec gitlab ls -lh /var/opt/gitlab/backups/ 2>/dev/null || echo "No backups yet"
echo ""

# ── Volumenes ──
echo ">>> Docker Volumes (bc-gitlab-*)"
# docker volume ls | grep bc-gitlab
echo ""

# ── Configuracion aplicada ──
echo ">>> GitLab Config (non-default settings)"
# docker compose exec gitlab grep -v '^#' /etc/gitlab/gitlab.rb | grep -v '^$' | head -30
echo ""

# ── Numero de proyectos ──
echo ">>> Project Count"
# docker compose exec gitlab gitlab-psql -c "SELECT count(*) FROM projects" 2>/dev/null || echo "DB query skipped"
echo ""

echo "============================================="
echo "  Verificacion completada"
echo "  Guarda esta salida para tu entrega"
echo "============================================="

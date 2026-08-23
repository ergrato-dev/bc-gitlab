#!/usr/bin/env bash
# ============================================
# Proyecto Semana 07 — Infraestructura Runners
# ============================================

echo "============================================="
echo "  Verificacion — Semana 07"
echo "  Infraestructura de GitLab Runners"
echo "============================================="
echo ""

echo ">>> Runners registrados"
# docker compose exec gitlab-runner gitlab-runner list
echo ""

echo ">>> config.toml"
# docker compose exec gitlab-runner cat /etc/gitlab-runner/config.toml
echo ""

echo ">>> Estado de Runners (via API)"
TOKEN="TU_ADMIN_TOKEN"
# curl -s --header "PRIVATE-TOKEN: $TOKEN" \
#   "http://localhost/api/v4/runners?scope=active" | \
#   python3 -c "
# import sys, json
# for r in json.load(sys.stdin):
#     print(f'  {r[\"description\"]:30s} | tags: {r.get(\"tag_list\",[])} | online: {r[\"online\"]}')
# " 2>/dev/null || echo "Requiere admin token"
echo ""

echo "============================================="
echo "  Checklist:"
echo "  [ ] Runner Docker con tag [docker] registrado y verde"
echo "  [ ] Runner (opcional) con tag [shell] registrado"
echo "  [ ] Pipeline con tags enruta jobs correctamente"
echo "  [ ] config.toml documentado"
echo "  [ ] Al menos 1 job de frontend + 1 job de backend"
echo "============================================="

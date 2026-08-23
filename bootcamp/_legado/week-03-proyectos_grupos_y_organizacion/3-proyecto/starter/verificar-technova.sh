#!/usr/bin/env bash
# ============================================
# Proyecto Semana 03 — Verificacion TechNova
# ============================================
# Ejecuta para verificar la estructura
# organizacional TechNova.

echo "============================================="
echo "  Verificacion — Semana 03"
echo "  TechNova — Estructura Organizacional"
echo "============================================="
echo ""

TOKEN="TU_TOKEN_ROOT"

echo ">>> Grupos y Subgrupos"
# curl -s --header "PRIVATE-TOKEN: $TOKEN" \
#   "http://localhost/api/v4/groups?search=technova" | grep -o '"full_path":"[^"]*"'
echo ""

echo ">>> Proyectos"
# curl -s --header "PRIVATE-TOKEN: $TOKEN" \
#   "http://localhost/api/v4/groups/technova%2Forion/projects?per_page=20" | grep -o '"name":"[^"]*"'
echo ""

echo ">>> Miembros por Grupo"
# for group in orion vega nexus shared; do
#   echo "--- technova/$group ---"
#   curl -s --header "PRIVATE-TOKEN: $TOKEN" \
#     "http://localhost/api/v4/groups/technova%2F$group/members" | grep -o '"username":"[^"]*","access_level":[0-9]*'
# done
echo ""

echo ">>> Ramas Protegidas (verificar en UI)"
echo "  http://localhost/bootcamp-org/backend/api-gateway/-/settings/repository"
echo "  http://localhost/technova/nexus/infrastructure/-/settings/repository"
echo ""

echo "============================================="
echo "  Checklist manual:"
echo "  [ ] 4 grupos creados (technova, orion, vega, nexus, shared)"
echo "  [ ] 10+ proyectos en los grupos correctos"
echo "  [ ] Miembros asignados con roles segun especificacion"
echo "  [ ] main protegida en todos los proyectos"
echo "  [ ] develop protegida en orion y vega"
echo "  [ ] production protegida en nexus/infrastructure"
echo "  [ ] ORGANIZATION.md documentado"
echo "============================================="

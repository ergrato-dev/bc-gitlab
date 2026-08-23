#!/usr/bin/env bash
# ============================================
# Proyecto Semana 04 — Verificacion GitLab Flow
# ============================================

echo "============================================="
echo "  Verificacion — Semana 04"
echo "  GitLab Flow — Ciclo Completo"
echo "============================================="
echo ""

TOKEN="TU_TOKEN"
PROJECT="bootcamp-org%2Fbackend%2Fapi-gateway"
API="http://localhost/api/v4/projects/$PROJECT"

echo ">>> Issues abiertos"
# curl -s --header "PRIVATE-TOKEN: $TOKEN" "$API/issues?state=opened&per_page=5" | \
#   python3 -c "import sys,json; [print(f'  #{i[\"iid\"]} {i[\"title\"]} [{i[\"state\"]}]') for i in json.load(sys.stdin)]" 2>/dev/null
echo ""

echo ">>> Merge Requests recientes"
# curl -s --header "PRIVATE-TOKEN: $TOKEN" "$API/merge_requests?state=all&per_page=5" | \
#   python3 -c "import sys,json; [print(f'  !{m[\"iid\"]} {m[\"title\"]} [{m[\"state\"]}]') for m in json.load(sys.stdin)]" 2>/dev/null
echo ""

echo ">>> Ramas"
# git branch -a 2>/dev/null || echo "  Ejecutar desde el repo clonado"
echo ""

echo ">>> Ramas de ambiente"
# for branch in main staging production; do
#   git rev-parse --verify origin/$branch >/dev/null 2>&1 && echo "  ✓ $branch" || echo "  ✗ $branch (falta)"
# done
echo ""

echo "============================================="
echo "  Checklist manual GitLab Flow:"
echo "  [ ] Issue #6 con descripcion, labels, milestone"
echo "  [ ] Branch 6-health-check-endpoint desde main"
echo "  [ ] Codigo: src/routes/health.js + tests"
echo "  [ ] Draft MR creado con template y Closes #6"
echo "  [ ] Code review: 2+ comentarios en linea"
echo "  [ ] Review summary: Request Changes"
echo "  [ ] Correcciones hechas, pipeline verde"
echo "  [ ] MR aprobado y mergeado (squash) a main"
echo "  [ ] MR main → staging creado y mergeado"
echo "  [ ] MR staging → production creado y mergeado"
echo "  [ ] FLOW.md documentando el proceso"
echo "============================================="

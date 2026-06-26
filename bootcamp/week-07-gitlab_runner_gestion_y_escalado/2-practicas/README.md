# 🔬 Prácticas — Semana 07: GitLab Runner

Cuatro prácticas progresivas que cubren la instalación, configuración, enrutamiento y despliegue en Kubernetes de GitLab Runner.

## Secuencia recomendada

| # | Práctica | Tiempo | Concepto clave |
|---|----------|--------|----------------|
| 01 | [Instalar y Registrar Runner](./01-instalar-runner/README.md) | 35 min | Docker runner, authentication tokens, config.toml |
| 02 | [Comparar Ejecutores](./02-configurar-ejecutores/README.md) | 40 min | Docker vs Shell executor, aislamiento, services |
| 03 | [Tags y Routing](./03-tags-y-routing/README.md) | 45 min | Multi-runner, enrutamiento por tags, jobs pending |
| 04 | [Runner en Kubernetes](./04-runner-kubernetes/README.md) | 50 min | Helm chart, pods efímeros, node selectors |

## Prerrequisitos globales

- Instancia GitLab CE en `http://localhost`
- Docker instalado y operativo en el host
- `$GITLAB_TOKEN` exportado (Personal Access Token con scope `api`)
- `$GITLAB_PROJECT_ID` del proyecto de práctica (semana 05 o uno nuevo)

```bash
# Verificar prerrequisitos antes de empezar
echo "=== Docker ==="
docker --version && docker ps --format "table {{.Names}}\t{{.Status}}" | head -3

echo ""
echo "=== GitLab token ==="
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/user" \
  | python3 -c "
import sys, json
try:
    u = json.load(sys.stdin)
    print(f'✅ Autenticado como: {u[\"username\"]} (ID: {u[\"id\"]})')
except:
    print('❌ Error: verificar GITLAB_TOKEN')
"

echo ""
echo "=== Runners actuales ==="
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/runners?status=online" \
  | python3 -c "
import sys, json
runners = json.load(sys.stdin)
print(f'Runners online: {len(runners)}')
for r in runners:
    tags = ','.join(r.get('tag_list', []))
    print(f'  #{r[\"id\"]}: {r[\"description\"]} [{tags}]')
"
```

## Dependencias entre prácticas

```
Práctica 01 (instalar runner)
    ↓ requiere: runner Docker online
Práctica 02 (ejecutores)
    ↓ requiere: runner Docker + runner Shell online
Práctica 03 (tags y routing)
    ↓ requiere: runner Docker (práctica 01) + puede reusar los runners creados en 03
Práctica 04 (Kubernetes)
    → independiente de 01-03 (requiere cluster K8s, no runners Docker)
```

## Notas del instructor

- Las prácticas 01-03 usan el mismo host y pueden compartir config en `/srv/`
- La práctica 04 es **opcional** si no hay cluster K8s disponible — el entendimiento conceptual viene de la teoría
- Los tokens de runner se crean por práctica; no hay que reutilizarlos entre sesiones
- Si un runner queda "offline" entre sesiones: `docker restart <nombre-del-runner>`

---

⬅️ **Teoría:** [1-teoria/](../1-teoria/)
➡️ **Proyecto:** [3-proyecto/README.md](../3-proyecto/README.md)

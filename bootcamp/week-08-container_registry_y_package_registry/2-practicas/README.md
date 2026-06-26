# 🔬 Prácticas — Semana 08: Container Registry y Package Registry

Cuatro prácticas progresivas que cubren el Container Registry, build de imágenes en CI, publicación de paquetes y security scanning.

## Secuencia recomendada

| # | Práctica | Tiempo | Concepto clave |
|---|----------|--------|----------------|
| 01 | [Container Registry Setup](./01-container-registry-setup/README.md) | 35 min | Habilitar registry, autenticación (PAT / CI Token / Deploy Token), push manual |
| 02 | [Build y Push de Imágenes](./02-build-y-push-imagenes/README.md) | 45 min | DinD vs Kaniko, multi-stage build, multi-tag strategy |
| 03 | [Package Registry](./03-package-registry/README.md) | 40 min | npm + PyPI en Package Registry, CI Job Token |
| 04 | [Security Scanning](./04-security-scanning/README.md) | 45 min | SAST, Secret Detection, Dependency Scan, Container Scan |

## Prerrequisitos globales

- Instancia GitLab CE en `http://localhost` con Container Registry habilitado
- Docker instalado y operativo en el host
- Runner con `privileged = true` para las prácticas 02 y 04 (DinD)
- `$GITLAB_TOKEN` exportado (Personal Access Token con scopes `api`, `read_registry`, `write_registry`)
- `$GITLAB_PROJECT_ID` del proyecto de práctica

```bash
# Verificación completa de prerrequisitos
echo "=== Docker ==="
docker --version

echo ""
echo "=== GitLab token y proyecto ==="
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID" \
  | python3 -c "
import sys, json
p = json.load(sys.stdin)
print(f'✅ Proyecto: {p[\"path_with_namespace\"]}')
print(f'   Registry: {p.get(\"container_registry_image_prefix\", \"(no configurado)\")}')
"

echo ""
echo "=== Runners online ==="
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
Práctica 01 (registry setup)
    ↓ requiere: Container Registry habilitado
Práctica 02 (build + push)
    ↓ requiere: al menos una imagen en el registry
Práctica 04 (security scanning)
    → depende de: imagen en registry (práctica 02)

Práctica 03 (package registry)
    → independiente de 01 y 02 — solo necesita el proyecto y un runner Docker
```

---

⬅️ **Teoría:** [1-teoria/](../1-teoria/)
➡️ **Proyecto:** [3-proyecto/README.md](../3-proyecto/README.md)

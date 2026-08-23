# 🔬 Prácticas — Semana 06: Pipelines Avanzados

Cuatro prácticas progresivas que cubren variables CI/CD, ejecución condicional, modularización con `include` y environments de deploy.

## Secuencia recomendada

| # | Práctica | Tiempo | Concepto clave |
|---|----------|--------|----------------|
| 01 | [Variables y Secretos](./01-variables-y-secretos/README.md) | 35 min | Variables masked/protected, prioridad |
| 02 | [Rules Condicionales](./02-rules-condicionales/README.md) | 40 min | Pipeline por rama/tag/MR/changes |
| 03 | [Include Templates](./03-include-templates/README.md) | 40 min | Modularización, extends, CI Lint |
| 04 | [Environments](./04-environments/README.md) | 45 min | Deploy staging/production, rollback |

## Prerrequisitos globales

- Proyecto `bootcamp-org/backend/api-gateway` funcional (de Semana 05)
- GitLab Runner en línea: verificar en `Admin → Runners`
- `$GITLAB_TOKEN` exportado en la terminal
- Ramas `main` (protegida) y `develop` presentes

```bash
# Verificar que el runner está online antes de empezar
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/runners?type=instance_type&status=online" \
  | python3 -c "
import sys, json
runners = json.load(sys.stdin)
print(f'Runners online: {len(runners)}')
for r in runners:
    print(f'  #{r[\"id\"]}: {r[\"description\"]}')
"
```

## Uso de los starters

Cada práctica tiene un directorio `starter/` con el `.gitlab-ci.yml` de punto de partida. Copiar al proyecto antes de comenzar:

```bash
# Ejemplo para práctica 01:
cp bootcamp/week-06-gitlab_ci_cd_pipelines_avanzados/2-practicas/01-variables-y-secretos/starter/.gitlab-ci.yml \
   /tmp/api-gateway-vars/.gitlab-ci.yml
```

---

⬅️ **Teoría:** [1-teoria/](../1-teoria/)
➡️ **Proyecto:** [3-proyecto/README.md](../3-proyecto/README.md)

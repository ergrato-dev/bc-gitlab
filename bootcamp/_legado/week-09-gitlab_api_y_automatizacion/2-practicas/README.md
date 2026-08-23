# 🔬 Prácticas — Semana 09: GitLab API y Automatización

Cuatro prácticas progresivas que cubren la API REST, GraphQL, webhooks y automatización con Python.

## Secuencia recomendada

| # | Práctica | Tiempo | Concepto clave |
|---|----------|--------|----------------|
| 01 | [REST API Básico](./01-rest-api-basico/README.md) | 35 min | CRUD con curl, paginación, rate limiting, manejo de errores HTTP |
| 02 | [GraphQL en Práctica](./02-graphql-consultas/README.md) | 35 min | GraphiQL explorer, queries con variables, mutations, paginación cursor |
| 03 | [Webhooks](./03-webhooks-integracion/README.md) | 40 min | Servidor Flask, secret token, ngrok, routing por tipo de evento |
| 04 | [Automatización Python](./04-python-automatizacion/README.md) | 45 min | python-gitlab, 4 tareas operativas, retry con backoff exponencial |

## Prerrequisitos globales

- Instancia GitLab CE en `http://localhost`
- Personal Access Token con scope `api` exportado en `$GITLAB_TOKEN`
- Python 3.9+ con `pip install python-gitlab flask requests python-dotenv`
- `$GITLAB_PROJECT_ID` de un proyecto de práctica

```bash
# Verificación rápida
echo "=== Token ==="
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/user" \
  | python3 -c "import sys,json; u=json.load(sys.stdin); print(f'✅ {u[\"username\"]} (ID:{u[\"id\"]})')"

echo ""
echo "=== Python ==="
python3 -c "import gitlab, flask, requests; print('✅ Librerías OK')"
```

## Dependencias entre prácticas

```
Práctica 01 (REST API + proyecto api-practice-lab)
    ↓ crea el proyecto que usan las prácticas 02, 03 y 04
Práctica 02 (GraphQL — usa $GITLAB_PROJECT_PATH del proyecto anterior)
    → independiente de 03 y 04

Práctica 03 (Webhooks — necesita un proyecto con issues y MRs)
    → puede usar el proyecto de práctica 01

Práctica 04 (Python — usa $GITLAB_PROJECT_ID)
    → usa el proyecto de práctica 01
    → puede ejecutarse en paralelo con 03
```

---

⬅️ **Teoría:** [1-teoria/](../1-teoria/)
➡️ **Proyecto:** [3-proyecto/README.md](../3-proyecto/README.md)

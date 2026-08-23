# Práctica 02 — GraphQL en Práctica

**Duración estimada:** 35 minutos
**Dificultad:** ⭐⭐⭐ (Media-Alta)

## 🎯 Objetivo

Ejecutar queries y mutations GraphQL contra la API de GitLab: explorar el esquema con GraphiQL, obtener datos relacionados en una sola petición, y comparar el coste en peticiones HTTP vs REST.

---

## 📋 Prerrequisitos

- `$GITLAB_URL` y `$GITLAB_TOKEN` exportados (del paso de la Práctica 01)
- El proyecto `api-practice-lab` del ejercicio anterior
- Python con `requests`: `pip install requests`

```bash
# Obtener el fullPath del proyecto para las queries
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$GITLAB_PROJECT_ID" \
  | python3 -c "
import sys, json
p = json.load(sys.stdin)
print(f'fullPath: {p[\"path_with_namespace\"]}')
export_line = f'export GITLAB_PROJECT_PATH=\"{p[\"path_with_namespace\"]}\"'
print(f'Ejecutar: {export_line}')
"

export GITLAB_PROJECT_PATH="mi-grupo/api-practice-lab"
```

---

## Paso 1: GraphiQL Explorer

Abrir en el navegador: `http://localhost/-/graphql-explorer`

La interfaz tiene tres paneles:
- **Izquierda:** editor de queries (con autocompletado con Ctrl+Space)
- **Derecha:** resultado JSON
- **Inferior izquierdo:** variables de la query
- **Panel Docs (icono libro):** explorador del esquema completo

**Ejercicio:** antes de ejecutar las queries del paso 2, explorar el esquema buscando el tipo `Project` y ver qué campos tiene disponibles.

---

## Paso 2: Queries de Lectura

### Query 1: Proyectos con pipelines — 1 petición vs N REST

En GraphiQL o via curl:

```graphql
query ProyectosConPipelines {
  projects(membership: true, first: 5) {
    nodes {
      name
      fullPath
      description
      visibility
      statistics {
        commitCount
        storageSize
      }
      pipelines(first: 3) {
        nodes {
          id
          status
          ref
          createdAt
          duration
        }
      }
    }
  }
}
```

```bash
# ¿QUÉ HACE?: Ejecuta la query via curl para ver la respuesta JSON completa
# ¿POR QUÉ?: Con REST se necesitarían N proyectos × 1 petición/pipelines = N+1 peticiones
# ¿PARA QUÉ?: Demostrar que GraphQL consolida datos relacionados en 1 sola petición

curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "query": "query { projects(membership: true, first: 5) { nodes { name fullPath pipelines(first: 3) { nodes { status ref createdAt } } } } }"
  }' \
  "$GITLAB_URL/api/graphql" \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)
projects = data.get('data', {}).get('projects', {}).get('nodes', [])
print(f'Proyectos en la respuesta: {len(projects)}')
for p in projects:
    pips = p.get('pipelines', {}).get('nodes', [])
    print(f'  {p[\"fullPath\"]}')
    if pips:
        for pip in pips:
            print(f'    pipeline [{pip[\"status\"]}] {pip[\"ref\"]} — {pip.get(\"createdAt\",\"\")[:10]}')
    else:
        print(f'    (sin pipelines)')
"
```

### Query 2: Issues con labels, assignees y autor — con variables

```graphql
query IssuesDelProyecto($path: ID!, $estado: IssuableState) {
  project(fullPath: $path) {
    name
    issueStateCounts {
      opened
      closed
    }
    issues(state: $estado, first: 10) {
      nodes {
        iid
        title
        state
        createdAt
        labels { nodes { title color } }
        assignees { nodes { username name } }
        author { username }
      }
    }
  }
}
```

Variables:
```json
{
  "path": "mi-grupo/api-practice-lab",
  "estado": "opened"
}
```

```bash
# Ejecutar con variables separadas del query (forma correcta)
curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{
    \"query\": \"query(\$path: ID!, \$estado: IssuableState) { project(fullPath: \$path) { name issueStateCounts { opened closed } issues(state: \$estado, first: 10) { nodes { iid title labels { nodes { title } } } } } }\",
    \"variables\": {\"path\": \"$GITLAB_PROJECT_PATH\", \"estado\": \"opened\"}
  }" \
  "$GITLAB_URL/api/graphql" \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)
errors = data.get('errors')
if errors:
    print('Errores:', errors)
else:
    proj = data['data']['project']
    counts = proj.get('issueStateCounts', {})
    issues = proj.get('issues', {}).get('nodes', [])
    print(f'Proyecto: {proj[\"name\"]}')
    print(f'Issues abiertos: {counts.get(\"opened\")} | cerrados: {counts.get(\"closed\")}')
    for i in issues:
        labels = [l['title'] for l in i.get('labels', {}).get('nodes', [])]
        print(f'  #{i[\"iid\"]} [{\"|\".join(labels)}] {i[\"title\"]}')
"
```

### Query 3: Merge Requests de un proyecto con diffs

```graphql
query MRsConDiff($path: ID!) {
  project(fullPath: $path) {
    mergeRequests(state: opened, first: 5) {
      nodes {
        iid
        title
        sourceBranch
        targetBranch
        author { username }
        diffStats {
          path
          additions
          deletions
        }
        createdAt
      }
    }
  }
}
```

---

## Paso 3: Mutations — Modificar datos

### Crear un issue via GraphQL

```bash
# ¿QUÉ HACE?: Crea un issue usando una mutation GraphQL
# ¿POR QUÉ?: Las mutations son el equivalente de POST/PUT/DELETE de REST en GraphQL
# ¿PARA QUÉ?: Practicar la diferencia sintáctica entre query y mutation

curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{
    \"query\": \"mutation { createIssue(input: { projectPath: \\\"$GITLAB_PROJECT_PATH\\\", title: \\\"Issue creado via GraphQL mutation\\\", description: \\\"Creado en la Práctica 02 de la Semana 09\\\", labelNames: [\\\"feature\\\", \\\"practica\\\"] }) { issue { iid title webUrl } errors } }\"
  }" \
  "$GITLAB_URL/api/graphql" \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)
result = data.get('data', {}).get('createIssue', {})
errors = result.get('errors', [])
issue = result.get('issue')
if errors:
    print(f'Errores: {errors}')
elif issue:
    print(f'Issue creado: #{issue[\"iid\"]}')
    print(f'  Título: {issue[\"title\"]}')
    print(f'  URL: {issue[\"webUrl\"]}')
"
```

---

## Paso 4: Paginación con cursor en GraphQL

```python
#!/usr/bin/env python3
"""Iterar todos los issues de un proyecto con cursor-based pagination."""

import requests, os, json

GITLAB_URL = os.environ["GITLAB_URL"]
TOKEN = os.environ["GITLAB_TOKEN"]
PROJECT_PATH = os.environ.get("GITLAB_PROJECT_PATH", "mi-grupo/api-practice-lab")

QUERY = """
query($path: ID!, $cursor: String) {
  project(fullPath: $path) {
    issues(state: opened, first: 20, after: $cursor) {
      nodes {
        iid
        title
        state
        createdAt
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
}
"""

# ¿QUÉ HACE?: Itera todas las páginas de issues usando el cursor de GraphQL
# ¿POR QUÉ?: GraphQL no usa page/per_page numérico — usa cursor opaco
# ¿PARA QUÉ?: Obtener todos los issues sin importar cuántos haya

cursor = None
all_issues = []
page = 0

while True:
    page += 1
    resp = requests.post(
        f"{GITLAB_URL}/api/graphql",
        headers={"PRIVATE-TOKEN": TOKEN},
        json={"query": QUERY, "variables": {"path": PROJECT_PATH, "cursor": cursor}}
    )
    resp.raise_for_status()
    
    data = resp.json()
    if "errors" in data:
        print(f"Errores GraphQL: {data['errors']}")
        break
    
    issues_page = data["data"]["project"]["issues"]
    nodes = issues_page["nodes"]
    all_issues.extend(nodes)
    
    print(f"  Página {page}: {len(nodes)} issues")
    
    page_info = issues_page["pageInfo"]
    if not page_info["hasNextPage"]:
        break
    cursor = page_info["endCursor"]

print(f"\nTotal issues: {len(all_issues)}")
for issue in all_issues:
    print(f"  #{issue['iid']} {issue['title']}")
```

```bash
# Ejecutar el script
export GITLAB_URL="http://localhost"
export GITLAB_TOKEN="tu-token"
export GITLAB_PROJECT_PATH="mi-grupo/api-practice-lab"
python3 graphql_pagination.py
```

---

## Paso 5: Introspección — Explorar el Esquema

```bash
# ¿QUÉ HACE?: Lista los tipos disponibles en el esquema GraphQL de GitLab
# ¿POR QUÉ?: Permite descubrir qué objetos y campos existen sin leer la documentación
# ¿PARA QUÉ?: Orientarse al empezar a trabajar con el esquema

# Listar todos los tipos (filtrar solo los de GitLab, no los built-in)
curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"query":"{ __schema { types { name kind description } } }"}' \
  "$GITLAB_URL/api/graphql" \
  | python3 -c "
import sys, json
types = json.load(sys.stdin)['data']['__schema']['types']
gitlab_types = [t for t in types if not t['name'].startswith('__') and t['kind'] == 'OBJECT']
print(f'Tipos OBJECT en el esquema: {len(gitlab_types)}')
for t in sorted(gitlab_types, key=lambda x: x['name'])[:15]:
    desc = (t.get('description') or '')[:60]
    print(f'  {t[\"name\"]:<35} {desc}')
"

# Ver campos disponibles en el tipo Project
curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"query":"{ __type(name: \"Project\") { fields { name type { name kind } description } } }"}' \
  "$GITLAB_URL/api/graphql" \
  | python3 -c "
import sys, json
fields = json.load(sys.stdin)['data']['__type']['fields']
print(f'Campos del tipo Project: {len(fields)}')
for f in sorted(fields, key=lambda x: x['name'])[:20]:
    type_info = f['type']
    print(f'  {f[\"name\"]:<35} {type_info[\"name\"] or type_info[\"kind\"]}')
"
```

---

## ✅ Checklist de verificación

- [ ] GraphiQL Explorer abre en `http://localhost/-/graphql-explorer`
- [ ] Query 1 (proyectos con pipelines) ejecutada — ver diferencia con N peticiones REST
- [ ] Query 2 (issues con labels) ejecutada con variables separadas
- [ ] Mutation `createIssue` ejecutada y issue visible en la UI
- [ ] Script de paginación cursor-based ejecutado sin errores
- [ ] Instrospección: número de tipos OBJECT en el esquema registrado

---

## Preguntas de reflexión

1. ¿Cuántas peticiones REST necesitarías para obtener los mismos datos que la Query 1 (5 proyectos + sus 3 últimas pipelines cada uno)?
2. ¿Cuándo usarías REST y cuándo GraphQL en un proyecto real?
3. ¿Qué diferencia hay entre paginación con cursor (GraphQL) y paginación numérica (REST)?

---

⬅️ **Práctica anterior:** [01 — REST API Básico](../01-rest-api-basico/README.md)
➡️ **Siguiente práctica:** [03 — Webhooks](../03-webhooks-integracion/README.md)

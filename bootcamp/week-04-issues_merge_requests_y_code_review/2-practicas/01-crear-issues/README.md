# 🔬 Práctica 01 — Crear y Gestionar Issues

## 🎯 Objetivo

Crear un sistema completo de issues con labels organizados, milestones y templates, y practicar el uso de Quick Actions para gestión ágil.

## ⏱️ Tiempo estimado: 45 minutos

## 📋 Requisitos previos

- Proyecto `bootcamp-org/backend/api-gateway` de la Semana 03
- Token `$GITLAB_TOKEN` disponible
- Usuarios `developer1` y `maintainer1` creados

---

## 📝 Paso 1: Configurar Labels del Proyecto

```bash
# Obtener el ID del proyecto api-gateway
PROJECT_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects?search=api-gateway" \
  | python3 -c "
import sys,json
projects=[p for p in json.load(sys.stdin) if 'bootcamp-org' in p['path_with_namespace']]
print(projects[0]['id'])
")

echo "Project ID: $PROJECT_ID"

# ¿QUÉ HACE?: Crea todos los labels necesarios en el proyecto via API
# ¿POR QUÉ?: Más rápido que crearlos uno a uno en la UI; garantiza colores consistentes
# ¿PARA QUÉ?: Sin labels, el tracker es un caos sin estructura

declare -A LABELS
LABELS["bug"]="#FF0000"
LABELS["feature"]="#0075CB"
LABELS["maintenance"]="#F0AD4E"
LABELS["documentation"]="#5CB85C"
LABELS["security"]="#D4004B"
LABELS["priority::1"]="#D9534F"
LABELS["priority::2"]="#F0AD4E"
LABELS["priority::3"]="#5BC0DE"
LABELS["priority::4"]="#5CB85C"
LABELS["area::frontend"]="#5CB85C"
LABELS["area::backend"]="#8E44AD"
LABELS["area::devops"]="#2980B9"
LABELS["workflow::todo"]="#CCCCCC"
LABELS["workflow::in-progress"]="#428BCA"
LABELS["workflow::review"]="#F0AD4E"
LABELS["workflow::done"]="#5CB85C"

for name in "${!LABELS[@]}"; do
  color="${LABELS[$name]}"
  result=$(curl --silent --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{\"name\": \"$name\", \"color\": \"$color\"}" \
    "http://localhost/api/v4/projects/$PROJECT_ID/labels")
  echo "$result" | python3 -c "import sys,json; l=json.load(sys.stdin); print(f'  {l.get(\"name\", l.get(\"message\", \"ERROR\"))}')"
done
```

Verificar en la UI:
```
http://localhost/bootcamp-org/backend/api-gateway/-/labels
→ Debe mostrar ~16 labels con sus colores
```

---

## 📝 Paso 2: Crear un Milestone

```bash
# ¿QUÉ HACE?: Crea el milestone Sprint 1 en el proyecto
# ¿POR QUÉ?: Los milestones agrupan issues bajo un objetivo temporal
# ¿PARA QUÉ?: Ver el progreso del sprint: cuántos issues cerrados vs abiertos

MILESTONE_ID=$(curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "title": "Sprint 1",
    "description": "Primer sprint — API Gateway básico con autenticación",
    "start_date": "2025-01-06",
    "due_date": "2025-01-17"
  }' \
  "http://localhost/api/v4/projects/$PROJECT_ID/milestones" \
  | python3 -c "import sys,json; m=json.load(sys.stdin); print(m['id'])")

echo "Milestone ID: $MILESTONE_ID"
```

---

## 📝 Paso 3: Crear Issues de Práctica

### Via UI — Issue de Bug

```
http://localhost/bootcamp-org/backend/api-gateway/-/issues/new

Title:        Error 500 al consultar /health cuando DB no responde
Description:
  ## 🐛 Resumen del Bug
  El endpoint `GET /health` devuelve HTTP 500 cuando PostgreSQL
  no está disponible, en lugar de 503 Service Unavailable.

  ## Pasos para Reproducir
  1. Detener la base de datos: `docker compose stop db`
  2. Consultar: `curl http://localhost:3000/health`
  3. Observar que devuelve 500

  ## Comportamiento Esperado
  HTTP 503 con body: {"status": "degraded", "database": "unhealthy"}

  ## Comportamiento Actual
  HTTP 500 con body: "Internal Server Error"

  ## Entorno
  - Versión: v1.0.0 (en desarrollo)
  - Ambiente: Local con Docker Compose

Labels:      bug, area::backend, priority::1, workflow::todo
Milestone:   Sprint 1
Assignee:    developer1
```

### Via API — Crear los 4 issues de práctica

```bash
# ¿QUÉ HACE?: Crea 4 issues con diferente tipo y prioridad via API
# ¿POR QUÉ?: Simula el backlog real de un proyecto con trabajo variado
# ¿PARA QUÉ?: Tener issues suficientes para practicar boards, filters y quick actions

DEV1_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/users?username=developer1" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

ISSUES=(
  "Implementar autenticación JWT en API Gateway|feature,area::backend,priority::2,workflow::todo|$DEV1_ID"
  "Documentar todos los endpoints en README|documentation,priority::3,workflow::todo|$DEV1_ID"
  "Actualizar dependencias npm (vulnerabilidades)|maintenance,security,priority::2,workflow::todo|$DEV1_ID"
)

for issue_data in "${ISSUES[@]}"; do
  IFS='|' read -r title labels assignee <<< "$issue_data"
  echo "Creando: $title"
  curl --silent --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{
      \"title\": \"$title\",
      \"labels\": \"$labels\",
      \"milestone_id\": $MILESTONE_ID,
      \"assignee_ids\": [$assignee]
    }" \
    "http://localhost/api/v4/projects/$PROJECT_ID/issues" \
    | python3 -c "import sys,json; i=json.load(sys.stdin); print(f'  → #{i.get(\"iid\", \"?\")} {i.get(\"title\", \"ERROR\")}')"
done
```

---

## 📝 Paso 4: Usar Quick Actions

Abre el primer issue (el de bug) y en el campo de comentario escribe:

```
Analizando el problema. El error ocurre en la línea 34 del health controller.

/weight 3
/due 2025-01-10
/label ~workflow::in-progress
/unlabel ~workflow::todo
```

Click "Comment" y verifica:
- El campo **Weight** muestra 3
- El campo **Due date** muestra la fecha
- El label cambió de `workflow::todo` a `workflow::in-progress`

---

## 📝 Paso 5: Crear un Issue via API y verificar

```bash
# ¿QUÉ HACE?: Lista todos los issues del proyecto con sus labels y milestone
# ¿POR QUÉ?: Verifica que los issues fueron creados correctamente
# ¿PARA QUÉ?: Base para el ejercicio de Issue Boards (práctica 04)
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/issues?state=opened&per_page=20" \
  | python3 -c "
import sys, json
issues = json.load(sys.stdin)
print(f'Total issues abiertos: {len(issues)}')
for i in sorted(issues, key=lambda x: x['iid']):
    labels = [l['name'] for l in i['labels']]
    print(f'  #{i[\"iid\"]} [{i[\"state\"]}] {i[\"title\"]}')
    print(f'     Labels: {labels}')
    print(f'     Assignee: {i[\"assignee\"][\"username\"] if i[\"assignee\"] else \"None\"}')
"
```

---

## 📝 Paso 6: Referenciar Issues en Commits

```bash
# Clonar el repo y agregar una referencia a un issue en el commit
git clone "http://root:$(echo $GITLAB_TOKEN)@localhost/bootcamp-org/backend/api-gateway.git" /tmp/api-gateway-test
cd /tmp/api-gateway-test

echo "# API Gateway" > README.md
git add README.md
git commit -m "docs: agregar título al README

Referencia: #3 (documentar endpoints)

Co-authored-by: developer1 <developer1@bootcamp.local>"

git push "http://root:$GITLAB_TOKEN@localhost/bootcamp-org/backend/api-gateway.git" main
```

Verificar:
```
Issue #3 → Activity tab → debe mostrar la referencia al commit
```

---

## 🔧 Troubleshooting

**Error al crear labels: "Label already exists"**
```
→ El proyecto puede ya tener labels del mismo nombre
→ La API devuelve error 409 en ese caso
→ Verificar en UI: Issues → Labels
→ Puedes ignorar este error y continuar con los demás labels
```

**Issues creados sin milestone**
```
→ Verificar que $MILESTONE_ID tiene un valor numérico: echo $MILESTONE_ID
→ Si está vacío, obtenerlo manualmente:
   curl -H "PRIVATE-TOKEN: $TOKEN" localhost/api/v4/projects/$ID/milestones
   y exportar el id correcto
```

---

## ✅ Checklist de verificación

- [ ] ~16 labels creados con colores correctos
- [ ] Milestone "Sprint 1" creado con fechas
- [ ] Al menos 4 issues creados con labels y milestone
- [ ] Quick actions actualizaron weight, due date y workflow label
- [ ] Commit con referencia `#N` en el mensaje

## 📦 Entregables

- [ ] Captura de `Issues → Labels` mostrando todos los labels con colores
- [ ] Captura de la lista de issues con labels y milestone
- [ ] Captura de un issue individual mostrando: description, labels, assignee, weight, due date
- [ ] Captura del issue mostrando la referencia al commit (Activity tab)

---

➡️ **Siguiente práctica:** [02 — Crear Merge Requests](../02-crear-merge-requests/README.md)

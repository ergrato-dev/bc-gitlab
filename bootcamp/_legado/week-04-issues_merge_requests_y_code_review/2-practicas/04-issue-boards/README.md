# 🔬 Práctica 04 — Issue Boards (Kanban)

## 🎯 Objetivo

Configurar un Issue Board Kanban en GitLab, mover issues entre columnas, crear un board de sprint con scope de milestone, y explorar el board de grupo para visibilidad multi-proyecto.

## ⏱️ Tiempo estimado: 30 minutos

## 📋 Requisitos previos

- Issues creados en la Práctica 01 con los labels `workflow::*`
- Al menos un milestone activo (Sprint 1)
- `$GITLAB_TOKEN` disponible

---

## 📝 Paso 1: Crear el Issue Board

```
http://localhost/bootcamp-org/backend/api-gateway/-/boards

Si hay un board por defecto "Development", hacer click en él.
Si no: New board
```

```
Board → Edit board

Name:     Sprint 1 Kanban
Scope:    ← Solo aparece en EE (en CE no hay scope por milestone)
```

En GitLab CE, todos los issues del proyecto aparecen en el board.

---

## 📝 Paso 2: Configurar las Columnas del Board

El board por defecto tiene solo "Open" y "Closed". Agregar las columnas de workflow:

```
Board → Add list

List type: Label
Label:     workflow::todo
Click "Add to board"
```

Repetir para agregar estas columnas en orden:

```
1. "Open" (columna por defecto — ya existe)
2. workflow::todo     ← Añadir
3. workflow::in-progress  ← Añadir
4. workflow::review   ← Añadir
5. "Closed" (columna por defecto — ya existe)
```

El board debe verse así:
```
┌─────────┬──────────────────┬───────────────────┬────────────────┬──────────┐
│  Open   │  workflow::todo  │ workflow::in-prog  │workflow::review│  Closed  │
├─────────┼──────────────────┼───────────────────┼────────────────┼──────────┤
│  #1     │  #2 JWT auth     │                   │                │          │
│  #5     │  #3 Docs         │                   │                │          │
│         │  #4 Security upd │                   │                │          │
└─────────┴──────────────────┴───────────────────┴────────────────┴──────────┘
```

---

## 📝 Paso 3: Mover Issues por el Board

En la UI del board, **arrastrar y soltar** issues entre columnas:

```
Escenario a simular:
  1. Issue #2 (JWT auth): Open → workflow::in-progress
     → El developer empieza a trabajar
     → Arrastrar de "Open" a "workflow::in-progress"

  2. Issue #3 (Docs): Open → workflow::todo
     → Está en el backlog pero sin empezar
     → Arrastrar a "workflow::todo"

  3. Issue #4 (Security): workflow::todo → workflow::in-progress
     → El developer terminó #2 y empieza #4
```

**Verificar via API que los labels cambiaron:**

```bash
# ¿QUÉ HACE?: Lista todos los issues con sus labels actuales
# ¿POR QUÉ?: Al mover en el board, GitLab cambia los labels automáticamente
# ¿PARA QUÉ?: Confirmar que el board y los labels están sincronizados
PROJECT_ID=<TU_PROJECT_ID>

curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/issues?state=opened&per_page=10" \
  | python3 -c "
import sys, json
issues = json.load(sys.stdin)
for i in sorted(issues, key=lambda x: x['iid']):
    labels = [l['name'] for l in i['labels']]
    workflow = next((l for l in labels if l.startswith('workflow::')), 'sin workflow')
    print(f'  #{i[\"iid\"]} [{workflow}] {i[\"title\"][:50]}')
"
```

---

## 📝 Paso 4: Mover Issues via API

Además de arrastrar en la UI, los labels se pueden cambiar via API (simula lo que hace el board):

```bash
# ¿QUÉ HACE?: Actualiza los labels de un issue para moverlo de columna
# ¿POR QUÉ?: El board solo actualiza labels — no hay un "estado" de board separado
# ¿PARA QUÉ?: Automatización — mover issues por el board desde scripts de CI/CD

ISSUE_IID=2  # El issue de JWT auth

# Mover a workflow::review (simula que el developer creó el MR)
curl --silent --request PUT \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "add_labels": "workflow::review",
    "remove_labels": "workflow::in-progress,workflow::todo"
  }' \
  "http://localhost/api/v4/projects/$PROJECT_ID/issues/$ISSUE_IID" \
  | python3 -c "
import sys, json
i = json.load(sys.stdin)
labels = [l['name'] for l in i['labels']]
print(f'Issue #{i[\"iid\"]} labels: {labels}')
"
```

Verificar en el board de la UI que el issue #2 ahora está en la columna "workflow::review".

---

## 📝 Paso 5: Crear el Board a Nivel de Grupo

El board de grupo muestra issues de todos los proyectos del grupo en una sola vista:

```
http://localhost/bootcamp-org/-/boards

Aquí verás issues de:
  - bootcamp-org/backend/api-gateway
  - bootcamp-org/backend/user-service
  - bootcamp-org/frontend/web-app
  - (todos los proyectos del grupo bootcamp-org)

Configurar columnas igual que en el proyecto:
  Board → Add list → Label → workflow::todo
  Board → Add list → Label → workflow::in-progress
  Board → Add list → Label → workflow::review
```

---

## 📝 Paso 6: Filtrar el Board por Assignee

En el board de proyecto o grupo, usar los filtros:

```
Board → Filtros (barra superior)

Filtrar por assignee:
  Assignee: developer1

→ Solo se muestran los issues asignados a developer1
```

Esto es útil para:
- Ver la carga de trabajo de un developer específico
- Standup daily: ¿en qué está trabajando cada persona?
- Detectar si alguien tiene demasiados issues en progreso al mismo tiempo

---

## 📝 Paso 7: Estado del Board via API

```bash
# ¿QUÉ HACE?: Lista las columnas (lists) del board via API
# ¿POR QUÉ?: Permite ver la estructura del board sin acceder a la UI
# ¿PARA QUÉ?: Automatización y reportes de estado del sprint

# Primero obtener el ID del board
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/boards" \
  | python3 -c "
import sys, json
boards = json.load(sys.stdin)
for b in boards:
    print(f'Board {b[\"id\"]}: {b[\"name\"]}')
    for l in b.get('lists', []):
        label = l.get('label', {}).get('name', 'N/A') if l.get('label') else l.get('list_type', 'N/A')
        print(f'  [{l[\"position\"]}] {label}')
"
```

---

## 📝 Paso 8: Resumen del Sprint via API

```bash
# ¿QUÉ HACE?: Calcula el progreso del sprint contando issues por workflow label
# ¿POR QUÉ?: El milestone progress en CE es básico — esto da más detalle
# ¿PARA QUÉ?: Reporte de standup o daily: cuántos issues en cada estado

curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/issues?milestone=Sprint 1&per_page=50" \
  | python3 -c "
import sys, json
from collections import Counter

issues = json.load(sys.stdin)
totals = Counter()

for i in issues:
    labels = [l['name'] for l in i['labels']]
    workflow = next((l for l in labels if l.startswith('workflow::')), 'sin-label')
    if i['state'] == 'closed':
        workflow = 'cerrado'
    totals[workflow] += 1

print('=== Sprint Progress ===')
total = sum(totals.values())
for state, count in sorted(totals.items()):
    bar = '█' * count
    print(f'  {state:<25} {bar} ({count}/{total})')
"
```

---

## 🔧 Troubleshooting

**Los labels de workflow no aparecen en el board**
```
→ Verificar que los labels existen: Issues → Labels
→ Si no existen, crearlos primero (ver Práctica 01, Paso 1)
```

**El board de grupo no muestra los issues del proyecto**
```
→ Verificar que el proyecto está dentro del grupo bootcamp-org
→ Issues → Groups → bootcamp-org → boards
```

---

## ✅ Checklist de verificación

- [ ] Board de proyecto con 4 columnas: Open, workflow::todo, workflow::in-progress, workflow::review, Closed
- [ ] Al menos 3 issues movidos a diferentes columnas
- [ ] Labels cambiaron automáticamente al mover en el board
- [ ] Move via API funcionó (add_labels / remove_labels)
- [ ] Board de grupo configurado y mostrando issues de múltiples proyectos
- [ ] Script de resumen de sprint ejecutado con éxito

## 📦 Entregables

- [ ] Captura del board con issues distribuidos en las 4 columnas
- [ ] Captura del board de grupo mostrando issues de múltiples proyectos
- [ ] Output del script de resumen de sprint con el conteo por estado
- [ ] Output del API listando las columnas del board

---

⬅️ **Anterior:** [03 — Code Review Práctico](../03-code-review-practico/README.md)
➡️ **Proyecto de la Semana:** [3-proyecto/instrucciones.md](../../3-proyecto/instrucciones.md)

# 🔬 Práctica 02 — Grupos y Subgrupos

## 🎯 Objetivo

Crear una estructura organizacional jerárquica completa con grupos, subgrupos y proyectos, y verificar la herencia de miembros entre niveles.

## ⏱️ Tiempo estimado: 45 minutos

## 📋 Requisitos previos

- Práctica 01 completada
- Token `$GITLAB_TOKEN` disponible en la sesión
- Acceso como `root`

---

## 🏗️ Estructura a Construir

Al final de esta práctica habrás creado:

```
bootcamp-org/                        ← Grupo raíz
├── frontend/                        ← Subgrupo
│   ├── web-app/                     ← Proyecto
│   └── mobile-app/                  ← Proyecto
├── backend/                         ← Subgrupo
│   ├── api-gateway/                 ← Proyecto
│   └── auth-service/                ← Proyecto
└── devops/                          ← Subgrupo
    ├── infrastructure/              ← Proyecto
    └── ci-cd-pipelines/             ← Proyecto
```

---

## 📝 Paso 1: Crear el grupo raíz

### Via UI

```
1. Click en "+" → New group
2. Seleccionar "Create group"
3. Completar:
   Group name:    Bootcamp-Org
   Group URL:     bootcamp-org
   Visibility:    Private
   Description:   Organización de práctica del bootcamp GitLab CE
4. Click "Create group"
```

### Guardar el ID del grupo para la API

```bash
# ¿QUÉ HACE?: Obtiene el ID del grupo recién creado via API
# ¿POR QUÉ?: Necesitamos el ID para crear los subgrupos con parent_id
# ¿PARA QUÉ?: Automatizar la creación del resto de la estructura
PARENT_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/groups?search=bootcamp-org" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

echo "Grupo raíz ID: $PARENT_ID"
```

---

## 📝 Paso 2: Crear los subgrupos

### Via API (los tres subgrupos de una vez)

```bash
# ¿QUÉ HACE?: Crea el subgrupo frontend dentro de bootcamp-org
# ¿POR QUÉ?: parent_id vincula este grupo como hijo de bootcamp-org
# ¿PARA QUÉ?: Establecer la jerarquía organizacional
for subgroup in frontend backend devops; do
  echo "Creando subgrupo: $subgroup"
  curl --silent --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{
      \"name\": \"$subgroup\",
      \"path\": \"$subgroup\",
      \"parent_id\": $PARENT_ID,
      \"visibility\": \"private\"
    }" \
    "http://localhost/api/v4/groups" | python3 -c "import sys,json; g=json.load(sys.stdin); print(f'  → ID: {g[\"id\"]}, path: {g[\"full_path\"]}')"
done
```

### Verificar en la UI

```
http://localhost/bootcamp-org
→ Sidebar: verás "Subgroups and projects"
→ Deben aparecer frontend/, backend/, devops/
```

---

## 📝 Paso 3: Crear los proyectos en cada subgrupo

Necesitamos el namespace (full_path) de cada subgrupo para crear proyectos dentro de ellos:

```bash
# ¿QUÉ HACE?: Lista los subgrupos de bootcamp-org con sus IDs
# ¿POR QUÉ?: Necesitamos el namespace para el campo "namespace" al crear proyectos
# ¿PARA QUÉ?: Crear proyectos dentro del namespace correcto via API
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/groups/$PARENT_ID/subgroups" \
  | python3 -c "
import sys, json
groups = json.load(sys.stdin)
for g in groups:
    print(f'{g[\"id\"]}: {g[\"full_path\"]}')
"
```

```bash
# ¿QUÉ HACE?: Crea todos los proyectos de práctica via API en un solo script
# ¿POR QUÉ?: Más eficiente que crearlos uno a uno en la UI
# ¿PARA QUÉ?: Construir la estructura completa en 30 segundos en lugar de 10 minutos

declare -A PROJECTS
PROJECTS["bootcamp-org/frontend"]="web-app mobile-app"
PROJECTS["bootcamp-org/backend"]="api-gateway auth-service"
PROJECTS["bootcamp-org/devops"]="infrastructure ci-cd-pipelines"

for namespace in "${!PROJECTS[@]}"; do
  for project in ${PROJECTS[$namespace]}; do
    echo "Creando: $namespace/$project"
    curl --silent --request POST \
      --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
      --header "Content-Type: application/json" \
      --data "{
        \"name\": \"$project\",
        \"namespace\": \"$namespace\",
        \"visibility\": \"private\",
        \"initialize_with_readme\": true
      }" \
      "http://localhost/api/v4/projects" \
      | python3 -c "import sys,json; p=json.load(sys.stdin); print(f'  → ID: {p.get(\"id\", \"ERROR\")}, URL: {p.get(\"http_url_to_repo\", p.get(\"message\", \"?\"))}')"
  done
done
```

---

## 📝 Paso 4: Verificar la estructura completa

### Via UI

```
http://localhost/bootcamp-org

En la página del grupo:
→ Click "Subgroups and projects" (en el sidebar o pestaña)
→ Deberías ver 3 subgrupos y 0 proyectos directos en bootcamp-org

Navegar a:
→ http://localhost/bootcamp-org/frontend
   Debe mostrar 2 proyectos: web-app, mobile-app

→ http://localhost/bootcamp-org/backend
   Debe mostrar 2 proyectos: api-gateway, auth-service

→ http://localhost/bootcamp-org/devops
   Debe mostrar 2 proyectos: infrastructure, ci-cd-pipelines
```

### Via API

```bash
# ¿QUÉ HACE?: Lista todos los proyectos de bootcamp-org incluyendo subgrupos
# ¿POR QUÉ?: include_subgroups=true traversa toda la jerarquía recursivamente
# ¿PARA QUÉ?: Verificar que los 6 proyectos están en sus namespaces correctos
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/groups/$PARENT_ID/projects?include_subgroups=true" \
  | python3 -c "
import sys, json
projects = json.load(sys.stdin)
print(f'Total proyectos: {len(projects)}')
for p in sorted(projects, key=lambda x: x['path_with_namespace']):
    print(f'  {p[\"path_with_namespace\"]}')
"
```

Output esperado:
```
Total proyectos: 6
  bootcamp-org/backend/api-gateway
  bootcamp-org/backend/auth-service
  bootcamp-org/devops/ci-cd-pipelines
  bootcamp-org/devops/infrastructure
  bootcamp-org/frontend/mobile-app
  bootcamp-org/frontend/web-app
```

---

## 📝 Paso 5: Agregar miembro al grupo raíz

```bash
# Primero, obtener el ID del usuario root
ROOT_USER_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/user" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")

echo "Root user ID: $ROOT_USER_ID"

# El usuario root ya es Owner del grupo porque lo creó.
# Vamos a verificar los miembros actuales del grupo:

# ¿QUÉ HACE?: Lista los miembros directos del grupo (sin heredados)
# ¿POR QUÉ?: "members" solo lista los asignados explícitamente al grupo
# ¿PARA QUÉ?: Verificar quién tiene acceso antes de agregar nuevos miembros
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/groups/$PARENT_ID/members" \
  | python3 -c "
import sys, json
members = json.load(sys.stdin)
for m in members:
    print(f'  {m[\"username\"]} — {m[\"access_level\"]} ({m[\"name\"]})')
"
```

---

## 📝 Paso 6: Verificar herencia de miembros

```bash
# ¿QUÉ HACE?: Lista los miembros efectivos (incluyendo heredados) de un proyecto
# ¿POR QUÉ?: /members/all incluye miembros heredados del grupo padre
# ¿PARA QUÉ?: Confirmar que root tiene acceso a proyectos de subgrupos por herencia

# Obtener ID de un proyecto (api-gateway)
API_GW_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects?search=api-gateway" \
  | python3 -c "import sys,json; projects=[p for p in json.load(sys.stdin) if 'bootcamp-org' in p['path_with_namespace']]; print(projects[0]['id'])")

echo "api-gateway ID: $API_GW_ID"

# Ver miembros efectivos del proyecto api-gateway
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$API_GW_ID/members/all" \
  | python3 -c "
import sys, json
members = json.load(sys.stdin)
access_labels = {10: 'Guest', 20: 'Reporter', 30: 'Developer', 40: 'Maintainer', 50: 'Owner'}
for m in members:
    inherited = '(heredado)' if m.get('membership_state') == 'active' else ''
    level = access_labels.get(m['access_level'], str(m['access_level']))
    print(f'  {m[\"username\"]} — {level} {inherited}')
"
```

---

## 🔧 Troubleshooting

**Error al crear proyecto: `"namespace": "bootcamp-org/frontend"`**
```
Si da error 400, puede ser que el namespace se pase diferente:
Alternativa: usar el ID del subgrupo con "namespace_id":
  --data '{"name":"web-app","namespace_id":43,"initialize_with_readme":true}'
```

**El loop de bash no funciona (error de sintaxis)**
```
→ Asegurarte de estar usando bash, no sh
→ Verificar: echo $SHELL (debe ser /bin/bash o /usr/bin/bash)
→ Alternativa: crear los proyectos uno por uno en la UI
```

---

## ✅ Checklist de verificación

- [ ] Grupo `bootcamp-org` creado y visible en `http://localhost/bootcamp-org`
- [ ] 3 subgrupos creados: `frontend`, `backend`, `devops`
- [ ] 6 proyectos creados, 2 en cada subgrupo
- [ ] La API lista 6 proyectos con `include_subgroups=true`
- [ ] El usuario `root` aparece como miembro efectivo en `api-gateway` (heredado)

## 📦 Entregables

- [ ] Captura de `http://localhost/bootcamp-org` mostrando los 3 subgrupos
- [ ] Output del comando de verificación mostrando los 6 proyectos con sus paths
- [ ] URL de 2 proyectos en grupos diferentes (ej: `http://localhost/bootcamp-org/backend/api-gateway` y `http://localhost/bootcamp-org/frontend/web-app`)

---

⬅️ **Práctica anterior:** [01 — Crear Proyectos](../01-crear-proyectos/README.md)
➡️ **Siguiente práctica:** [03 — Permisos y Roles](../03-permisos-y-roles/README.md)

# 🔬 Práctica 03 — Permisos y Roles

## 🎯 Objetivo

Crear usuarios con diferentes roles en grupos y proyectos, verificar qué pueden y no pueden hacer según su rol, y comprobar que la herencia de permisos funciona correctamente.

## ⏱️ Tiempo estimado: 45 minutos

## 📋 Requisitos previos

- Práctica 02 completada (estructura `bootcamp-org` creada)
- Token `$GITLAB_TOKEN` disponible
- Acceso como `root` al Admin Area

---

## 📝 Paso 1: Crear usuarios de práctica

Como administrador, crear tres usuarios que representan roles típicos de un equipo:

### Via Admin Area (UI)

```
http://localhost/admin/users/new

Usuario 1:
  Name:     Developer One
  Username: developer1
  Email:    developer1@bootcamp.local
  Password: Bootcamp2024!
  ✓ Send welcome email: NO (desmarcar para no necesitar SMTP)
  Access level: Regular

→ Repetir para:

Usuario 2:
  Name:     Maintainer One
  Username: maintainer1
  Email:    maintainer1@bootcamp.local
  Password: Bootcamp2024!

Usuario 3:
  Name:     Reporter One
  Username: reporter1
  Email:    reporter1@bootcamp.local
  Password: Bootcamp2024!
```

### Via API (más rápido)

```bash
# ¿QUÉ HACE?: Crea los tres usuarios en una sola ejecución del bucle
# ¿POR QUÉ?: La API de admin permite crear usuarios sin confirmar email
# ¿PARA QUÉ?: Configurar el entorno de práctica en segundos

declare -A USERS
USERS["developer1"]="Developer One"
USERS["maintainer1"]="Maintainer One"
USERS["reporter1"]="Reporter One"

for username in "${!USERS[@]}"; do
  name="${USERS[$username]}"
  echo "Creando usuario: $username"
  curl --silent --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{
      \"name\": \"$name\",
      \"username\": \"$username\",
      \"email\": \"${username}@bootcamp.local\",
      \"password\": \"Bootcamp2024!\",
      \"skip_confirmation\": true
    }" \
    "http://localhost/api/v4/users" \
    | python3 -c "import sys,json; u=json.load(sys.stdin); print(f'  → ID: {u.get(\"id\", \"ERROR\")}, username: {u.get(\"username\", u.get(\"message\", \"?\"))}')"
done
```

### Guardar IDs de usuarios

```bash
# ¿QUÉ HACE?: Obtiene el ID de cada usuario para usarlo en las llamadas de miembro
# ¿POR QUÉ?: La API de grupos requiere user_id, no username
DEV1_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/users?username=developer1" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

MAINT1_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/users?username=maintainer1" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

REP1_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/users?username=reporter1" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

echo "developer1 ID: $DEV1_ID"
echo "maintainer1 ID: $MAINT1_ID"
echo "reporter1 ID: $REP1_ID"

# Guardar PARENT_ID del grupo raíz
PARENT_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/groups?search=bootcamp-org" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")
```

---

## 📝 Paso 2: Agregar miembros al grupo raíz

```bash
# ¿QUÉ HACE?: Agrega los 3 usuarios al grupo bootcamp-org con diferentes roles
# ¿POR QUÉ?: Al agregar al grupo raíz, heredarán acceso a todos los subgrupos y proyectos
# ¿PARA QUÉ?: Gestión centralizada de permisos sin asignar uno por uno en cada proyecto

# Maintainer → access_level 40
curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data "user_id=$MAINT1_ID&access_level=40" \
  "http://localhost/api/v4/groups/$PARENT_ID/members" \
  | python3 -c "import sys,json; m=json.load(sys.stdin); print(f'Maintainer agregado: {m.get(\"username\", m)}')"

# Developer → access_level 30
curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data "user_id=$DEV1_ID&access_level=30" \
  "http://localhost/api/v4/groups/$PARENT_ID/members" \
  | python3 -c "import sys,json; m=json.load(sys.stdin); print(f'Developer agregado: {m.get(\"username\", m)}')"

# Reporter → access_level 20
curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data "user_id=$REP1_ID&access_level=20" \
  "http://localhost/api/v4/groups/$PARENT_ID/members" \
  | python3 -c "import sys,json; m=json.load(sys.stdin); print(f'Reporter agregado: {m.get(\"username\", m)}')"
```

### Verificar miembros del grupo

```bash
# ¿QUÉ HACE?: Lista los 4 miembros del grupo (root + los 3 nuevos)
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/groups/$PARENT_ID/members" \
  | python3 -c "
import sys, json
members = json.load(sys.stdin)
levels = {10:'Guest', 20:'Reporter', 30:'Developer', 40:'Maintainer', 50:'Owner'}
for m in sorted(members, key=lambda x: x['access_level'], reverse=True):
    print(f'  {m[\"username\"]:15} → {levels.get(m[\"access_level\"], str(m[\"access_level\"]))}')
"
```

---

## 📝 Paso 3: Verificar herencia en proyectos

```bash
# ¿QUÉ HACE?: Verifica qué rol tiene developer1 en el proyecto api-gateway (subgrupo backend)
# ¿POR QUÉ?: developer1 no fue asignado directamente al proyecto; hereda del grupo
# ¿PARA QUÉ?: Confirmar que la herencia de permisos funciona correctamente

API_GW_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects?search=api-gateway" \
  | python3 -c "
import sys,json
projects = [p for p in json.load(sys.stdin) if 'bootcamp-org' in p['path_with_namespace']]
print(projects[0]['id'])
")

# Listar miembros efectivos (incluyendo heredados)
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$API_GW_ID/members/all" \
  | python3 -c "
import sys, json
members = json.load(sys.stdin)
levels = {10:'Guest', 20:'Reporter', 30:'Developer', 40:'Maintainer', 50:'Owner'}
print('Miembros efectivos en bootcamp-org/backend/api-gateway:')
for m in sorted(members, key=lambda x: x['access_level'], reverse=True):
    print(f'  {m[\"username\"]:15} → {levels.get(m[\"access_level\"])}')
"
```

---

## 📝 Paso 4: Permisos directos en proyecto específico (sobrescribir herencia)

`reporter1` es Reporter en el grupo (puede ver pero no hacer push). Vamos a darle permisos de Developer **solo** en el proyecto `infrastructure`:

```bash
# Obtener ID del proyecto infrastructure
INFRA_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects?search=infrastructure" \
  | python3 -c "
import sys,json
projects = [p for p in json.load(sys.stdin) if 'bootcamp-org' in p['path_with_namespace']]
print(projects[0]['id'])
")

echo "infrastructure ID: $INFRA_ID"

# ¿QUÉ HACE?: Agrega a reporter1 como Developer directamente en infrastructure
# ¿POR QUÉ?: El acceso directo al proyecto sobreescribe (eleva) el rol heredado
# ¿PARA QUÉ?: Dar permisos granulares sin cambiar el rol del usuario en toda la organización
curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data "user_id=$REP1_ID&access_level=30" \
  "http://localhost/api/v4/projects/$INFRA_ID/members" \
  | python3 -c "import sys,json; m=json.load(sys.stdin); print(f'reporter1 en infrastructure: {m.get(\"access_level\", \"ERROR\")}')"
```

### Verificar el efecto

```bash
# En infrastructure: reporter1 debe ser Developer (acceso directo elevado)
echo "=== Miembros de infrastructure ==="
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$INFRA_ID/members/all" \
  | python3 -c "
import sys, json
members = json.load(sys.stdin)
levels = {10:'Guest', 20:'Reporter', 30:'Developer', 40:'Maintainer', 50:'Owner'}
for m in sorted(members, key=lambda x: x['access_level'], reverse=True):
    print(f'  {m[\"username\"]:15} → {levels.get(m[\"access_level\"])}')
"

# En web-app: reporter1 debe seguir siendo Reporter (herencia del grupo)
WEB_APP_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects?search=web-app" \
  | python3 -c "
import sys,json
projects = [p for p in json.load(sys.stdin) if 'bootcamp-org' in p['path_with_namespace']]
print(projects[0]['id'])
")

echo "=== Miembros de web-app (reporter1 debe ser Reporter aquí) ==="
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$WEB_APP_ID/members/all" \
  | python3 -c "
import sys, json
members = json.load(sys.stdin)
levels = {10:'Guest', 20:'Reporter', 30:'Developer', 40:'Maintainer', 50:'Owner'}
for m in [m for m in members if m['username'] == 'reporter1']:
    print(f'  reporter1 → {levels.get(m[\"access_level\"])}')
"
```

---

## 📝 Paso 5: Verificar permisos en la UI (login como cada usuario)

Abrir una ventana de incógnito y probar:

**Como `developer1` / `Bootcamp2024!`:**
```
→ Ir a http://localhost/bootcamp-org/backend/api-gateway
→ Debe poder VER el código (Repository → Files)
→ Debe poder ir a Issues y crear uno
→ NO debe ver Settings del proyecto (no tiene Maintainer)
→ El sidebar no tiene "Settings" para él
```

**Como `reporter1` / `Bootcamp2024!`:**
```
→ Ir a http://localhost/bootcamp-org/frontend/web-app
→ Puede VER el código (Repository) pero no puede hacer push
→ NO puede crear Merge Requests (sin botón "New merge request")
→ SÍ puede comentar en Issues

→ Ir a http://localhost/bootcamp-org/devops/infrastructure
→ Aquí sí puede crear Merge Requests (es Developer aquí por acceso directo)
```

**Como `maintainer1` / `Bootcamp2024!`:**
```
→ Ir a http://localhost/bootcamp-org/backend/api-gateway
→ Puede VER Settings del proyecto
→ Puede ir a Settings → Members y agregar miembros
→ Puede ir a Settings → Repository → Protected branches
```

---

## 🔧 Troubleshooting

**Error "403 Forbidden" al agregar miembro**
```
→ Tu token no tiene permisos de Owner en el grupo
→ Verificar: curl -H "PRIVATE-TOKEN: $TOKEN" localhost/api/v4/groups/ID/members/all
→ Asegurarte de usar el token de root
```

**Usuario creado pero no puede hacer login**
```
→ En GitLab CE, los usuarios pueden requerir confirmación de email
→ Ir a Admin Area → Users → developer1 → Edit → Deactivate "Pending approval"
→ O usar skip_confirmation: true en la API (ya está en el comando)
```

---

## ✅ Checklist de verificación

- [ ] 3 usuarios creados: `developer1`, `maintainer1`, `reporter1`
- [ ] Los 3 usuarios son miembros de `bootcamp-org` con sus roles correctos
- [ ] `reporter1` aparece como Developer en `infrastructure` y Reporter en `web-app`
- [ ] Login como `developer1` no muestra "Settings" en el sidebar del proyecto
- [ ] Login como `maintainer1` sí muestra "Settings" con acceso completo

## 📦 Entregables

- [ ] Captura de `bootcamp-org → Members` mostrando los 4 miembros y sus roles
- [ ] Captura de `infrastructure → Members` mostrando reporter1 como Developer
- [ ] Captura de `web-app → Members` (effective) mostrando reporter1 como Reporter
- [ ] Breve explicación (3-5 líneas) de la diferencia entre permisos heredados y permisos directos

---

⬅️ **Práctica anterior:** [02 — Grupos y Subgrupos](../02-grupos-y-subgrupos/README.md)
➡️ **Siguiente práctica:** [04 — Proteger Ramas](../04-proteger-ramas/README.md)

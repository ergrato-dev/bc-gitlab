# 📋 Instrucciones del Proyecto — Semana 03

Este documento describe las fases detalladas para completar el proyecto integrador. Úsalo junto con el [README.md del proyecto](./README.md) y el script de verificación.

---

## Fase 1: Diseñar la estructura antes de crear

Antes de entrar a GitLab, diseña tu estructura en papel (o en un documento):

```
technova/
├── Visibilidad: Private
├── Owner: root
│
├── orion/             ← Squad Frontend
│   ├── storefront/    ← Frontend principal (React/Next.js)
│   └── admin-panel/   ← Panel de administración
│
├── vega/              ← Squad Backend
│   ├── api-gateway/   ← API Gateway
│   ├── product-service/
│   ├── order-service/
│   └── user-service/
│
├── nexus/             ← Squad DevOps/Infra
│   ├── infrastructure/
│   └── ci-cd-config/
│
└── shared/            ← Recursos compartidos
    ├── design-system/
    └── api-contracts/
```

Confirma que entiendes:
- Qué subgrupo corresponde a cada squad
- Qué proyectos van en cada subgrupo
- Quién tendrá qué rol en cada nivel

---

## Fase 2: Crear la estructura de grupos

### 2.1 Crear el grupo raíz `technova`

```
http://localhost → + → New group → Create group
  Name:        TechNova
  URL:         technova
  Visibility:  Private
  Description: Startup de e-commerce — plataforma SaaS
```

### 2.2 Crear los 4 subgrupos

Para cada subgrupo (orion, vega, nexus, shared):
```
Desde la página de technova → + → New subgroup
  Name:       orion    (luego vega, nexus, shared)
  URL:        orion
  Visibility: Private
```

**Alternativa via API (más rápido):**

```bash
# Obtener ID del grupo technova
TN_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/groups?search=technova" \
  | python3 -c "import sys,json; print([g for g in json.load(sys.stdin) if g['path']=='technova'][0]['id'])")

echo "TechNova group ID: $TN_ID"

for squad in orion vega nexus shared; do
  curl --silent --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --data "name=$squad&path=$squad&parent_id=$TN_ID&visibility=private" \
    "http://localhost/api/v4/groups" \
    | python3 -c "import sys,json; g=json.load(sys.stdin); print(f'  {g[\"full_path\"]} (ID: {g[\"id\"]})')"
done
```

---

## Fase 3: Crear los 10 proyectos

```bash
# Crear todos los proyectos en sus namespaces correctos
declare -A PROJECTS_MAP
PROJECTS_MAP["technova/orion"]="storefront admin-panel"
PROJECTS_MAP["technova/vega"]="api-gateway product-service order-service user-service"
PROJECTS_MAP["technova/nexus"]="infrastructure ci-cd-config"
PROJECTS_MAP["technova/shared"]="design-system api-contracts"

for namespace in "${!PROJECTS_MAP[@]}"; do
  for project_name in ${PROJECTS_MAP[$namespace]}; do
    echo "Creando: $namespace/$project_name"
    result=$(curl --silent --request POST \
      --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
      --header "Content-Type: application/json" \
      --data "{
        \"name\": \"$project_name\",
        \"namespace\": \"$namespace\",
        \"visibility\": \"private\",
        \"initialize_with_readme\": true,
        \"default_branch\": \"main\"
      }" \
      "http://localhost/api/v4/projects")
    echo "$result" | python3 -c "import sys,json; p=json.load(sys.stdin); print(f'  → {p.get(\"path_with_namespace\", p.get(\"message\", \"ERROR\"))}')"
  done
done
```

**Verificar:**
```bash
# Debe listar los 10 proyectos
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/groups/$TN_ID/projects?include_subgroups=true" \
  | python3 -c "
import sys, json
projects = json.load(sys.stdin)
print(f'Total: {len(projects)} proyectos')
for p in sorted(projects, key=lambda x: x['path_with_namespace']):
    print(f'  {p[\"path_with_namespace\"]}')
"
# Resultado esperado: Total: 10 proyectos
```

---

## Fase 4: Crear usuarios del escenario

Si no hiciste la práctica 03, créalos ahora. Si ya los creaste, pasa a la Fase 5.

```bash
# Usuarios necesarios para el proyecto
USERS_LIST="maintainer1 dev-orion-1 dev-vega-1 dev-nexus-1"

for username in $USERS_LIST; do
  curl --silent --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --data "name=${username}&username=${username}&email=${username}@technova.local&password=TechNova2024!&skip_confirmation=true" \
    "http://localhost/api/v4/users" \
    | python3 -c "import sys,json; u=json.load(sys.stdin); print(f'  {u.get(\"username\", u.get(\"message\", \"?\"))} (ID: {u.get(\"id\", \"?\")})')"
done
```

---

## Fase 5: Asignar permisos

### 5.1 Owner a nivel raíz

`root` ya es Owner de `technova` por haberlo creado.

### 5.2 Maintainer del grupo raíz (acceso a todos los squads)

```bash
MAINT1_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/users?username=maintainer1" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

# maintainer1 → Maintainer en technova (hereda Maintainer en todo)
curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data "user_id=$MAINT1_ID&access_level=40" \
  "http://localhost/api/v4/groups/$TN_ID/members"
```

### 5.3 Developers por squad

```bash
# Obtener IDs de los subgrupos
ORION_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/groups?search=orion" \
  | python3 -c "import sys,json; print([g for g in json.load(sys.stdin) if g['path']=='orion'][0]['id'])")

VEGA_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/groups?search=vega" \
  | python3 -c "import sys,json; print([g for g in json.load(sys.stdin) if g['path']=='vega'][0]['id'])")

NEXUS_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/groups?search=nexus" \
  | python3 -c "import sys,json; print([g for g in json.load(sys.stdin) if g['path']=='nexus'][0]['id'])")

# Obtener ID de dev-orion-1 y asignar al subgrupo orion
DEV_ORION_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/users?username=dev-orion-1" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data "user_id=$DEV_ORION_ID&access_level=30" \
  "http://localhost/api/v4/groups/$ORION_ID/members" \
  | python3 -c "import sys,json; m=json.load(sys.stdin); print(f'dev-orion-1 → Developer en orion/')"

# Repetir para los otros squads según los usuarios que hayas creado
```

---

## Fase 6: Proteger ramas en todos los proyectos

El requisito del proyecto es que `main` esté protegida en **todos** los proyectos:

```bash
# Obtener todos los IDs de proyectos de technova
PROJECT_IDS=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/groups/$TN_ID/projects?include_subgroups=true&per_page=20" \
  | python3 -c "import sys,json; print(' '.join(str(p['id']) for p in json.load(sys.stdin)))")

echo "Project IDs: $PROJECT_IDS"

# Proteger main en todos los proyectos
for pid in $PROJECT_IDS; do
  echo "Protegiendo main en proyecto $pid..."
  curl --silent --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --header "Content-Type: application/json" \
    --data '{"name":"main","push_access_level":0,"merge_access_level":40}' \
    "http://localhost/api/v4/projects/$pid/protected_branches" \
    | python3 -c "import sys,json; b=json.load(sys.stdin); print(f'  → {b.get(\"name\", b.get(\"message\", \"ERROR\"))}')"
done
```

### Protecciones adicionales según el requisito

```bash
# develop en orion y vega (requiere sus IDs)
ORION_STOREFRONT_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects?search=storefront" \
  | python3 -c "import sys,json; print([p for p in json.load(sys.stdin) if 'technova' in p['path_with_namespace']][0]['id'])")

for pid in $ORION_STOREFRONT_ID; do  # Agregar IDs de otros proyectos de orion/vega
  curl --silent --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --data "name=develop&push_access_level=30&merge_access_level=30" \
    "http://localhost/api/v4/projects/$pid/protected_branches"
done
```

---

## Fase 7: Verificar con el script

```bash
# ¿QUÉ HACE?: Ejecuta el script de verificación automática del proyecto
# ¿POR QUÉ?: Valida todos los requisitos (grupos, proyectos, permisos, ramas)
# ¿PARA QUÉ?: Confirmar que la entrega cumple los criterios antes de presentar
bash 3-proyecto/starter/verificar-technova.sh
```

El script verifica:
- ✓ Grupo `technova` existe
- ✓ 4 subgrupos presentes: orion, vega, nexus, shared
- ✓ 10 proyectos en sus namespaces correctos
- ✓ `main` protegida en todos los proyectos
- ✓ `maintainer1` tiene Maintainer en `technova`

---

## Fase 8: Documentar la estructura (ORGANIZATION.md)

Crea el archivo `ORGANIZATION.md` en el proyecto `technova/nexus/ci-cd-config`:

```markdown
# TechNova — Estructura Organizacional GitLab

## Grupos y Squads

| Grupo | Squad | Responsabilidad |
|-------|-------|-----------------|
| technova/orion | Squad Orion | Frontend (React, Next.js) |
| technova/vega | Squad Vega | Backend (Go, microservicios) |
| technova/nexus | Squad Nexus | DevOps/Infra (Terraform, K8s) |
| technova/shared | Compartido | Design system, contratos API |

## Matriz de Permisos

| Grupo/Proyecto | root | maintainer1 | dev-orion-* | dev-vega-* | dev-nexus-* |
|----------------|------|-------------|-------------|------------|-------------|
| technova/ | Owner | Maintainer | - | - | - |
| orion/ | Owner(h) | Maintainer(h) | Developer | - | - |
| vega/ | Owner(h) | Maintainer(h) | - | Developer | - |
| nexus/ | Owner(h) | Maintainer(h) | - | - | Developer |
| shared/ | Owner(h) | Maintainer(h) | Developer | Developer | Developer |

> (h) = rol heredado del grupo padre

## Reglas de Protección de Ramas

- `main`: Protegida en todos los proyectos — merge solo Maintainers, push Nobody
- `develop`: Protegida en orion/ y vega/ — merge y push Developers+Maintainers
- `production`: Protegida en nexus/infrastructure — merge Maintainers, push Nobody

## Flujo de Trabajo

1. Developer crea rama `feature/<nombre>` desde `main`
2. Hace commits y push a su rama
3. Abre Merge Request → `main`
4. Maintainer revisa y aprueba
5. Maintainer hace merge
```

---

## ✅ Checklist de entrega

- [ ] Grupo `technova` con 4 subgrupos (orion, vega, nexus, shared)
- [ ] 10 proyectos creados en sus subgrupos correctos
- [ ] `root` es Owner, `maintainer1` es Maintainer en `technova`
- [ ] Developers asignados a sus subgrupos correspondientes
- [ ] `main` protegida en todos los proyectos (push=Nobody, merge=Maintainers)
- [ ] `develop` protegida en orion/ y vega/
- [ ] Script `verificar-technova.sh` pasa todas las verificaciones
- [ ] `ORGANIZATION.md` creado y commiteado en `nexus/ci-cd-config`

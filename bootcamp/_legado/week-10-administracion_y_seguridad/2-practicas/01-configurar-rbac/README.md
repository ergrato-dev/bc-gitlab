# Práctica 01 — Configurar RBAC: Roles y Permisos

## Objetivo

Diseñar e implementar un esquema completo de RBAC para un equipo de desarrollo simulado, incluyendo grupos, proyectos, protected branches y documentación de la matriz de permisos.

## Escenario

Empresa "TechCorp" con un equipo "Alpha" que gestiona dos proyectos en producción:

**Miembros del equipo:**
| Usuario | Rol | Responsabilidades |
|---------|-----|-------------------|
| `alice` | Tech Lead | Revisión final, merge a main, gestión CI/CD |
| `bob` | Developer Senior | Desarrollo, revisión de código |
| `carol` | Developer Senior | Desarrollo, revisión de código |
| `dave` | Developer Junior | Desarrollo bajo supervisión |
| `eve` | Developer Junior | Desarrollo bajo supervisión |
| `frank` | QA Engineer | Testing, reporte de bugs, lectura de pipelines |

**Proyectos:**
- `backend-api` — API REST en Python
- `frontend-app` — Aplicación React

## Requisitos de seguridad

- Solo el Tech Lead puede mergear a `main` (vía MR obligatorio)
- Los Seniors pueden mergear a `develop`
- Los Juniors solo pushean a `feature/*`
- QA puede ver todo pero no modificar código
- Nadie puede hacer push directo a `main` — ni siquiera el Tech Lead
- Los Seniors pueden aprobar MRs (2 aprobaciones requeridas)

---

## Instrucciones

### Paso 1: Crear estructura de grupos y proyectos

```bash
# Via API — más rápido y reproducible que la UI
GITLAB_URL="http://localhost"
ADMIN_TOKEN="tu-admin-pat-token"

# 1. Crear grupo raíz
GROUP_RESP=$(curl -s --request POST \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "alpha-team",
    "path": "alpha-team",
    "visibility": "private",
    "description": "Equipo Alpha — TechCorp DevOps Bootcamp"
  }' \
  "$GITLAB_URL/api/v4/groups")

GROUP_ID=$(echo "$GROUP_RESP" | jq '.id')
echo "Grupo creado: $GROUP_ID"

# 2. Crear proyectos en el grupo
BACKEND_ID=$(curl -s --request POST \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{
    \"name\": \"backend-api\",
    \"namespace_id\": $GROUP_ID,
    \"visibility\": \"private\",
    \"initialize_with_readme\": true,
    \"default_branch\": \"main\"
  }" \
  "$GITLAB_URL/api/v4/projects" | jq '.id')
echo "Proyecto backend-api: $BACKEND_ID"

FRONTEND_ID=$(curl -s --request POST \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{
    \"name\": \"frontend-app\",
    \"namespace_id\": $GROUP_ID,
    \"visibility\": \"private\",
    \"initialize_with_readme\": true,
    \"default_branch\": \"main\"
  }" \
  "$GITLAB_URL/api/v4/projects" | jq '.id')
echo "Proyecto frontend-app: $FRONTEND_ID"
```

### Paso 2: Crear usuarios de prueba

```bash
# Crear usuarios (requiere admin token)
# En GitLab CE local se puede usar la API con admin PAT

create_user() {
  local username=$1
  local email=$2
  local name=$3
  
  USER_ID=$(curl -s --request POST \
    --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{
      \"name\": \"$name\",
      \"username\": \"$username\",
      \"email\": \"$email\",
      \"password\": \"SecurePass123!\",
      \"skip_confirmation\": true,
      \"reset_password\": false
    }" \
    "$GITLAB_URL/api/v4/users" | jq '.id')
  
  echo "Usuario $username creado: $USER_ID"
  echo "$USER_ID"
}

ALICE_ID=$(create_user "alice" "alice@techcorp.local" "Alice García")
BOB_ID=$(create_user "bob" "bob@techcorp.local" "Bob Martínez")
CAROL_ID=$(create_user "carol" "carol@techcorp.local" "Carol López")
DAVE_ID=$(create_user "dave" "dave@techcorp.local" "Dave Rodríguez")
EVE_ID=$(create_user "eve" "eve@techcorp.local" "Eve Sánchez")
FRANK_ID=$(create_user "frank" "frank@techcorp.local" "Frank Torres")

# Crear PATs para cada usuario (para testing posterior)
for USER_ID in $ALICE_ID $BOB_ID $CAROL_ID $DAVE_ID $EVE_ID $FRANK_ID; do
  TOKEN=$(curl -s --request POST \
    --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    --data "name=practice-token&scopes[]=api&expires_at=2026-12-31&user_id=$USER_ID" \
    "$GITLAB_URL/api/v4/users/$USER_ID/personal_access_tokens" | \
    jq -r '.token')
  echo "Token user $USER_ID: $TOKEN"
done
```

### Paso 3: Asignar roles en el grupo

Matriz de decisión de roles:

| Miembro | Nivel | Justificación |
|---------|-------|---------------|
| alice | 40 (Maintainer) | Merge a protected branches, gestionar CI/CD. NO Owner: no debe eliminar el grupo |
| bob | 30 (Developer) | Push, MRs, issues. Puede aprobar MRs |
| carol | 30 (Developer) | Igual que bob |
| dave | 30 (Developer) | Push a ramas no protegidas. Protected branches bloquean acceso a main/develop |
| eve | 30 (Developer) | Igual que dave |
| frank | 20 (Reporter) | Solo lectura + crear issues. Sin acceso a modificar código |

```bash
# Función auxiliar para obtener user ID por username
get_uid() {
  curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    "$GITLAB_URL/api/v4/users?username=$1" | jq '.[0].id'
}

# Asignar roles en el GRUPO (se heredan a todos los proyectos del grupo)
add_member() {
  local username=$1
  local level=$2
  local user_id=$(get_uid "$username")
  
  RESULT=$(curl -s --request POST \
    --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{\"user_id\": $user_id, \"access_level\": $level}" \
    "$GITLAB_URL/api/v4/groups/$GROUP_ID/members")
  
  echo "[$username] nivel=$level → $(echo $RESULT | jq -r '.access_level // .message')"
}

add_member "alice" 40   # Maintainer
add_member "bob"   30   # Developer
add_member "carol" 30   # Developer
add_member "dave"  30   # Developer
add_member "eve"   30   # Developer
add_member "frank" 20   # Reporter

# Verificar membresías
echo ""
echo "=== Membresías del grupo ==="
curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "$GITLAB_URL/api/v4/groups/$GROUP_ID/members" | \
  jq -r '.[] | "\(.username): \(.access_level)"'
```

### Paso 4: Configurar Protected Branches en ambos proyectos

```bash
configure_branches() {
  local PROJECT_ID=$1
  local PROJECT_NAME=$2
  
  echo "=== Configurando $PROJECT_NAME (ID: $PROJECT_ID) ==="
  
  # Eliminar protección por defecto si existe
  curl -s --request DELETE \
    --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    "$GITLAB_URL/api/v4/projects/$PROJECT_ID/protected_branches/main" 2>/dev/null
  
  # main: nadie hace push directo, solo Maintainers pueden mergear
  curl -s --request POST \
    --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    --header "Content-Type: application/json" \
    --data '{
      "name": "main",
      "push_access_level": 0,
      "merge_access_level": 40,
      "allow_force_push": false
    }' \
    "$GITLAB_URL/api/v4/projects/$PROJECT_ID/protected_branches" | \
    jq '{branch: .name, push: .push_access_levels[].access_level, merge: .merge_access_levels[].access_level}'
  
  # develop: Developers+ pueden pushear, solo Maintainers mergean
  curl -s --request POST \
    --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    --header "Content-Type: application/json" \
    --data '{
      "name": "develop",
      "push_access_level": 30,
      "merge_access_level": 40,
      "allow_force_push": false
    }' \
    "$GITLAB_URL/api/v4/projects/$PROJECT_ID/protected_branches" | \
    jq '{branch: .name, push: .push_access_levels[].access_level, merge: .merge_access_levels[].access_level}'
  
  # release/*: solo Maintainers crean y mergean releases
  curl -s --request POST \
    --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    --header "Content-Type: application/json" \
    --data '{
      "name": "release/*",
      "push_access_level": 40,
      "merge_access_level": 40,
      "allow_force_push": false
    }' \
    "$GITLAB_URL/api/v4/projects/$PROJECT_ID/protected_branches" | \
    jq '{branch: .name, push: .push_access_levels[].access_level, merge: .merge_access_levels[].access_level}'
  
  echo "Protected branches configuradas en $PROJECT_NAME"
}

configure_branches "$BACKEND_ID" "backend-api"
configure_branches "$FRONTEND_ID" "frontend-app"
```

### Paso 5: Configurar MR Approvals

```bash
configure_approvals() {
  local PROJECT_ID=$1
  
  # Configuración base de approvals
  curl -s --request PUT \
    --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    --header "Content-Type: application/json" \
    --data '{
      "approvals_before_merge": 2,
      "reset_approvals_on_push": true,
      "disable_overriding_approvers_per_merge_request": true
    }' \
    "$GITLAB_URL/api/v4/projects/$PROJECT_ID/approvals" | \
    jq '{approvals_before_merge, reset_approvals_on_push}'
  
  echo "MR approvals configuradas: 2 requeridas, reset en cada push"
}

configure_approvals "$BACKEND_ID"
configure_approvals "$FRONTEND_ID"
```

### Paso 6: Verificar permisos (testing)

```bash
# Asumiendo que tienes los PATs de cada usuario en variables
# ALICE_PAT, BOB_PAT, DAVE_PAT, FRANK_PAT

echo "=== TEST 1: dave (Developer) no puede pushear a main ==="
git clone http://dave:SecurePass123!@localhost/alpha-team/backend-api.git /tmp/test-dave
cd /tmp/test-dave
git checkout main
echo "unauthorized change" >> README.md
git add . && git commit -m "test: push directo no autorizado"
git push origin main
# Expected: error: remote: GitLab: You are not allowed to push code to protected branches

echo "=== TEST 2: dave SÍ puede pushear a feature/* ==="
git checkout -b feature/nueva-funcionalidad
git push origin feature/nueva-funcionalidad
# Expected: ✅ Branch 'feature/nueva-funcionalidad' set up to track remote branch

echo "=== TEST 3: frank (Reporter) no puede pushear a ninguna rama ==="
cd /tmp
git clone http://frank:SecurePass123!@localhost/alpha-team/backend-api.git /tmp/test-frank
cd /tmp/test-frank
git checkout -b test/reporter-push
echo "test" >> README.md
git add . && git commit -m "test reporter"
git push origin test/reporter-push
# Expected: error: 403 Forbidden

echo "=== TEST 4: frank SÍ puede crear issues ==="
ISSUE=$(curl -s --request POST \
  --header "PRIVATE-TOKEN: $FRANK_PAT" \
  --data "title=Bug: botón de login no responde en móvil" \
  "http://localhost/api/v4/projects/$BACKEND_ID/issues")
echo "Issue creado: $(echo $ISSUE | jq -r '.iid // .message')"
# Expected: número de issue (ej: 1)

echo "=== TEST 5: alice (Maintainer) puede ver y gestionar todas las variables CI/CD ==="
curl -s --header "PRIVATE-TOKEN: $ALICE_PAT" \
  "http://localhost/api/v4/projects/$BACKEND_ID/variables"
# Expected: [] o lista de variables

echo "=== TEST 6: bob (Developer) no puede ver variables CI/CD ==="
curl -s --header "PRIVATE-TOKEN: $BOB_PAT" \
  "http://localhost/api/v4/projects/$BACKEND_ID/variables"
# Expected: 403 Forbidden
```

### Paso 7: Crear y documentar la Matriz de Permisos

Crea `RBAC-MATRIX.md` en el repositorio `backend-api`:

```markdown
# Matriz de Permisos — Equipo Alpha (TechCorp)

## Resumen de roles

| Usuario | Rol (grupo) | Nivel |
|---------|------------|-------|
| alice | Maintainer | 40 |
| bob, carol | Developer | 30 |
| dave, eve | Developer | 30 |
| frank | Reporter | 20 |

## Matriz de permisos detallada

| Acción | alice | bob/carol | dave/eve | frank |
|--------|:-----:|:---------:|:--------:|:-----:|
| Clonar repositorio | ✅ | ✅ | ✅ | ✅ |
| Ver código | ✅ | ✅ | ✅ | ✅ |
| Ver issues | ✅ | ✅ | ✅ | ✅ |
| Crear issues | ✅ | ✅ | ✅ | ✅ |
| Ver pipelines | ✅ | ✅ | ✅ | ✅ |
| Push a feature/* | ✅ | ✅ | ✅ | ❌ |
| Push a develop | ✅ | ✅ | ✅ | ❌ |
| Push directo a main | ❌ | ❌ | ❌ | ❌ |
| Push directo a release/* | ✅ | ❌ | ❌ | ❌ |
| Crear MR | ✅ | ✅ | ✅ | ❌ |
| Aprobar MR | ✅ | ✅ | ✅ | ❌ |
| Merge MR a main | ✅ | ❌ | ❌ | ❌ |
| Merge MR a develop | ✅ | ❌ | ❌ | ❌ |
| Ejecutar pipelines manualmente | ✅ | ✅ | ✅ | ❌ |
| Gestionar variables CI/CD | ✅ | ❌ | ❌ | ❌ |
| Añadir miembros al proyecto | ✅ | ❌ | ❌ | ❌ |
| Eliminar ramas no protegidas | ✅ | ✅ | ❌ | ❌ |
| Modificar settings del proyecto | ✅ | ❌ | ❌ | ❌ |
| Eliminar proyecto | ❌ (Owner only) | ❌ | ❌ | ❌ |

## Protected Branches

| Rama | Push directo | Merge via MR |
|------|:------------:|:------------:|
| main | ❌ Nadie | ✅ Maintainers |
| develop | ✅ Developers+ | ✅ Maintainers |
| release/* | ✅ Maintainers | ✅ Maintainers |
| feature/* | Sin restricción | Sin restricción |
| hotfix/* | Sin restricción | Sin restricción |

## Política de MR Approvals

- Mínimo 2 aprobaciones para merge a cualquier rama protegida
- El autor no puede aprobar su propio MR
- Las aprobaciones se resetean si se hace push al MR
- Todos los threads de comentarios deben resolverse antes de merge
```

---

## Preguntas de reflexión

1. Los Juniors (dave, eve) tienen nivel 30 (Developer) igual que los Seniors. ¿Cómo se diferencia su acceso si el nivel es el mismo?

2. ¿Por qué alice es Maintainer (40) y no Owner (50) en el grupo? ¿Qué pasaría si fuera Owner?

3. Un pasante de 3 meses necesita hacer contribuciones bajo supervisión estricta. ¿Qué rol asignarías? ¿Qué protected branches configurarías para su caso?

4. El equipo de seguridad (Security Audit) necesita auditar código y pipelines de todos los proyectos sin modificar nada. ¿Dónde y con qué rol los añadirías?

5. ¿Qué pasaría con los permisos de dave si se añade `dave` con nivel Developer al grupo `alpha-team`, pero luego se le añade también directamente al proyecto `backend-api` con nivel Reporter? ¿Qué nivel prevalece?

---

## Entregables

- [ ] Grupo `alpha-team` creado con visibilidad privada
- [ ] Proyectos `backend-api` y `frontend-app` dentro del grupo
- [ ] 6 usuarios con roles asignados correctamente en el grupo
- [ ] Protected branches configuradas: `main` (push=0, merge=40), `develop` (push=30, merge=40), `release/*` (push=40, merge=40)
- [ ] MR approvals: 2 requeridas, reset en push, sin auto-aprobación
- [ ] Tests de verificación ejecutados con resultados documentados
- [ ] `RBAC-MATRIX.md` commiteado en `backend-api`

# 🔬 Práctica 04 — Proteger Ramas

## 🎯 Objetivo

Configurar protección de ramas en proyectos con diferentes niveles de restricción, verificar que las reglas se aplican correctamente (push rechazado, flujo via MR), y crear un CODEOWNERS funcional.

## ⏱️ Tiempo estimado: 60 minutos

## 📋 Requisitos previos

- Práctica 03 completada (usuarios y permisos configurados)
- Token `$GITLAB_TOKEN` disponible
- Usuarios `developer1` y `maintainer1` con acceso a los proyectos
- SSH key configurada o acceso HTTP con token (para los comandos de git)

---

## 📝 Paso 1: Proteger `main` en `api-gateway`

### Via UI

```
1. Ir a http://localhost/bootcamp-org/backend/api-gateway
2. Settings → Repository → Protected branches
3. En "Search for branch", escribir: main
4. Configurar:
   Allowed to merge:         Maintainers
   Allowed to push and merge: Nobody
5. Click "Protect"
```

### Via API (alternativa)

```bash
# ¿QUÉ HACE?: Protege la rama main vía API
# ¿POR QUÉ?: push_access_level=0 = Nobody; merge_access_level=40 = Maintainers
# ¿PARA QUÉ?: Configurar protecciones en masa para todos los proyectos del grupo

API_GW_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects?search=api-gateway" \
  | python3 -c "
import sys,json
projects = [p for p in json.load(sys.stdin) if 'bootcamp-org' in p['path_with_namespace']]
print(projects[0]['id'])
")

echo "api-gateway ID: $API_GW_ID"

curl --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "main",
    "push_access_level": 0,
    "merge_access_level": 40,
    "allow_force_push": false
  }' \
  "http://localhost/api/v4/projects/$API_GW_ID/protected_branches"
```

---

## 📝 Paso 2: Verificar que el push directo es rechazado

Para este paso necesitas tener SSH configurado o usar HTTP con token.

### Opción A: Clonar via HTTP con token

```bash
# ¿QUÉ HACE?: Clona el repo usando el token en la URL (sin SSH)
# ¿POR QUÉ?: La URL con token permite clonar repos privados sin configurar SSH
# ¿PARA QUÉ?: Probar rápidamente desde la terminal sin setup adicional
git clone "http://developer1:Bootcamp2024\!@localhost/bootcamp-org/backend/api-gateway.git"
cd api-gateway
```

### Intentar push directo a main (como developer1)

```bash
# Configurar identidad git para developer1 en este repo
git config user.name "Developer One"
git config user.email "developer1@bootcamp.local"

# Hacer un cambio
echo "# Cambio de prueba — $(date)" >> README.md
git add README.md
git commit -m "test: intento de push directo a main"

# ¿QUÉ HACE?: Intenta hacer push directo a la rama protegida main
# ¿POR QUÉ?: developer1 tiene rol Developer, y main permite push solo a Nobody
# ¿PARA QUÉ?: Verificar que la protección funciona — este push DEBE ser rechazado
git push "http://developer1:Bootcamp2024\!@localhost/bootcamp-org/backend/api-gateway.git" main
```

Output esperado (el push debe fallar):
```
remote: GitLab: You are not allowed to push code to protected branches on this project.
To http://localhost/bootcamp-org/backend/api-gateway.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to 'http://localhost/...'
```

---

## 📝 Paso 3: El flujo correcto — feature branch → MR → merge

Como `developer1`, crear una rama, hacer cambios y abrir un MR:

```bash
# ¿QUÉ HACE?: Crea una rama feature desde main local
# ¿POR QUÉ?: Las ramas feature no están protegidas; developer1 puede hacer push a ellas
# ¿PARA QUÉ?: El código se sube via rama feature y se integra via Merge Request
git checkout -b feature/add-health-endpoint

# Hacer cambios relevantes
cat >> README.md << 'EOF'

## Health Check

`GET /health` → `200 OK`

Used by Kubernetes liveness probes and load balancer health checks.
EOF

git add README.md
git commit -m "feat: add health check endpoint documentation"

# ¿QUÉ HACE?: Sube la rama feature (no protegida) al servidor
# ¿POR QUÉ?: Las branches no protegidas aceptan push de cualquier Developer
# ¿PARA QUÉ?: Hacer el código disponible para crear el Merge Request en la UI
git push "http://developer1:Bootcamp2024\!@localhost/bootcamp-org/backend/api-gateway.git" \
  feature/add-health-endpoint
```

### Crear el MR en la UI

```
1. Ir a http://localhost/bootcamp-org/backend/api-gateway
   → Aparece el banner: "You pushed to feature/add-health-endpoint — Create merge request"
2. Click "Create merge request"
3. Completar:
   Title:         feat: add health check endpoint documentation
   Description:   Adds documentation for the GET /health endpoint
   Assignee:      maintainer1
   Target branch: main  (debe estar ya seleccionado)
4. Click "Create merge request"
```

### Hacer merge como maintainer1

```
1. Abrir ventana de incógnito
2. Login como maintainer1 / Bootcamp2024!
3. Ir al MR creado (http://localhost/bootcamp-org/backend/api-gateway/-/merge_requests)
4. Revisar los cambios en la pestaña "Changes"
5. Click "Approve" (si los approvals están configurados)
6. Click "Merge"
7. Confirmar
```

Verificar:
```bash
# ¿QUÉ HACE?: Verifica que el commit del MR ahora está en main
git checkout main
git pull "http://localhost/bootcamp-org/backend/api-gateway.git" main
git log --oneline -3
# Debe mostrar el commit del MR mergeado
```

---

## 📝 Paso 4: Proteger `develop` y wildcard `release/*`

```bash
# Proteger develop (merge y push para Developers + Maintainers)
curl --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "develop",
    "push_access_level": 30,
    "merge_access_level": 30
  }' \
  "http://localhost/api/v4/projects/$API_GW_ID/protected_branches"

# Proteger wildcard release/* (solo Maintainers pueden mergear, nobody push)
curl --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "release/*",
    "push_access_level": 0,
    "merge_access_level": 40
  }' \
  "http://localhost/api/v4/projects/$API_GW_ID/protected_branches"
```

### Verificar en la UI

```
Settings → Repository → Protected branches

Debes ver:
  main        Merge: Maintainers  | Push: Nobody
  develop     Merge: Developers+  | Push: Developers+
  release/*   Merge: Maintainers  | Push: Nobody
```

### Probar el wildcard

```bash
# ¿QUÉ HACE?: Crea la rama release/1.0.0 y verifica que no se puede hacer push directo
# ¿POR QUÉ?: release/* protege cualquier rama que empiece con "release/"
git checkout main
git checkout -b release/1.0.0
echo "v1.0.0" > VERSION
git add VERSION
git commit -m "chore: bump version to 1.0.0"

# Este push debe ser RECHAZADO (release/* está protegida)
git push "http://developer1:Bootcamp2024\!@localhost/bootcamp-org/backend/api-gateway.git" \
  release/1.0.0
# → remote: You are not allowed to push code to protected branches on this project.
```

---

## 📝 Paso 5: Crear CODEOWNERS

```bash
# ¿QUÉ HACE?: Crea el directorio .gitlab y el archivo CODEOWNERS
# ¿POR QUÉ?: GitLab busca CODEOWNERS en .gitlab/, docs/ o la raíz del proyecto
# ¿PARA QUÉ?: Definir revisiones obligatorias por área de código
git checkout main
git pull "http://localhost/bootcamp-org/backend/api-gateway.git" main

mkdir -p .gitlab
cat > .gitlab/CODEOWNERS << 'EOF'
# Propietario por defecto — revisa TODO lo no especificado
* @maintainer1

# El README principal requiere revisión del maintainer
README.md @maintainer1

# El archivo de versión solo lo puede aprobar el maintainer
VERSION @maintainer1

# Configuración de CI/CD solo la aprueba devops
.gitlab-ci.yml @maintainer1
EOF

git add .gitlab/CODEOWNERS
git commit -m "chore: add CODEOWNERS file"

# Subir via MR (no directamente a main)
git checkout -b chore/add-codeowners
git cherry-pick HEAD  # El último commit ya está aquí
# O simplemente:
git push "http://developer1:Bootcamp2024\!@localhost/bootcamp-org/backend/api-gateway.git" \
  chore/add-codeowners
```

> ⚠️ **Nota:** Para que CODEOWNERS tenga efecto en los MRs, el archivo debe estar en la rama **main** (la protegida). El maintainer deberá hacer merge de este MR.

---

## 📝 Paso 6: Configurar checks adicionales de MR

```
Proyecto → Settings → Merge requests → Merge checks

Activar:
  ✓ All threads must be resolved
    (todos los comentarios de code review deben resolverse antes del merge)
```

### Probar el check de threads

```
1. Crear un nuevo MR (cualquier cambio pequeño)
2. En la pestaña "Changes", hacer click en una línea de código
3. Click en el ícono de comentario → escribir: "Este cambio necesita tests"
4. Intentar hacer merge del MR
   → El botón "Merge" debe estar deshabilitado con el mensaje:
   "You can only merge this if all threads are resolved"
5. Resolver el thread: "Mark as resolved"
6. Ahora el Merge debe estar disponible
```

---

## 🔧 Troubleshooting

**Git push pide credenciales interactivamente**
```bash
# Usar la URL con credenciales embebidas
git push "http://developer1:Bootcamp2024\!@localhost/..." rama
# El "!" en la contraseña debe escaparse en bash con "\"
```

**El wildcard release/* no rechaza el push**
```
→ Verificar en Settings → Repository → Protected branches que el wildcard fue guardado
→ El nombre debe ser exactamente "release/*" con el asterisco
→ Si usaste la UI, recargar la página y verificar que aparece en la lista
```

**No aparece el banner "Create merge request" después del push**
```
→ Actualizar la página del proyecto
→ La rama debe existir en el servidor (el push debe haber sido exitoso)
→ Ir directamente a: Project → Merge requests → New merge request
```

---

## ✅ Checklist de verificación

- [ ] `main` aparece como protegida con Nobody en push y Maintainers en merge
- [ ] `develop` aparece como protegida con Developers+Maintainers en ambas opciones
- [ ] `release/*` aparece como protegida con Nobody en push
- [ ] Push directo a main produce error "pre-receive hook declined"
- [ ] MR de feature/add-health-endpoint fue mergeado exitosamente por maintainer1
- [ ] Archivo `.gitlab/CODEOWNERS` existe en el repositorio
- [ ] "All threads must be resolved" está activado en Settings

## 📦 Entregables

- [ ] Captura de **Protected branches** mostrando `main`, `develop` y `release/*`
- [ ] Captura del mensaje de error al intentar push directo a `main`
- [ ] URL del Merge Request mergeado exitosamente
- [ ] Captura del MR bloqueado por "threads not resolved" (paso 6)

---

⬅️ **Práctica anterior:** [03 — Permisos y Roles](../03-permisos-y-roles/README.md)
➡️ **Proyecto de la semana:** [Proyecto Semana 03](../../3-proyecto/README.md)

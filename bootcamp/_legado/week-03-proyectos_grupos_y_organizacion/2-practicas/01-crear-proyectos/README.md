# 🔬 Práctica 01 — Crear Proyectos en GitLab CE

## 🎯 Objetivo

Crear proyectos usando los tres métodos disponibles en GitLab (en blanco, desde template, por importación) y gestionarlos via API REST.

## ⏱️ Tiempo estimado: 45 minutos

## 📋 Requisitos previos

- GitLab CE corriendo en `http://localhost` (Semana 02)
- Acceso como usuario `root` o usuario con permiso de crear proyectos
- `curl` disponible en la terminal
- Token de acceso personal (lo crearás en el paso 1)

---

## 🔑 Paso 0: Crear Personal Access Token

Antes de empezar, crea un token para usar en los comandos de API:

```
http://localhost/-/user_settings/personal_access_tokens

New personal access token:
  Token name:       practica-03-api
  Expiration date:  (30 días desde hoy)
  Select scopes:
    ✓ api

→ Click "Create personal access token"
→ Copiar y guardar el token (no se vuelve a mostrar)
```

```bash
# ¿QUÉ HACE?: Guarda el token en una variable de entorno de la sesión
# ¿POR QUÉ?: Evita escribirlo en texto plano en cada comando
# ¿PARA QUÉ?: Todos los comandos curl de esta práctica usarán $GITLAB_TOKEN
export GITLAB_TOKEN="tu-token-aqui"

# Verificar que funciona
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/user" | python3 -m json.tool | grep username
# Debe mostrar: "username": "root"
```

---

## 📝 Paso 1: Crear proyecto en blanco (via UI)

```
1. Click en ícono "+" en la barra superior → New project
2. Seleccionar "Create blank project"
3. Completar:
   Project name:    practica-proyecto-01
   Project slug:    practica-proyecto-01   (auto-generado)
   Visibility:      Private
   ✓ Initialize repository with a README
4. Click "Create project"
```

**Verificar:** La URL del proyecto debe ser `http://localhost/root/practica-proyecto-01`

Explorar la interfaz del proyecto recién creado:

```
→ Repository: verás el README.md inicial
→ Issues: vacío pero habilitado
→ Merge requests: vacío
→ CI/CD → Pipelines: vacío (configuraremos en semana 05)
→ Settings → General: opciones de configuración
```

---

## 📝 Paso 2: Crear proyecto desde template

```
1. Click en "+" → New project
2. Seleccionar "Create from template"
3. Explorar las pestañas:
   - Built-in: templates incluidos por defecto
   - Group: (vacío si no hay templates de grupo)
   - Instance: (vacío si el admin no configuró ninguno)
4. Seleccionar "Pages/Plain HTML" → Click "Use template"
5. Completar:
   Project name:    practica-template-html
   Visibility:      Private
6. Click "Create project"
```

**Explorar el resultado:**

```
→ Repository: verás archivos pre-creados (index.html, .gitlab-ci.yml)
→ El .gitlab-ci.yml viene configurado para GitLab Pages (deploy automático)
→ Settings → General → Visibility: verifica que es Private
```

---

## 📝 Paso 3: Importar proyecto desde URL

```
1. Click en "+" → New project
2. Seleccionar "Import project"
3. Seleccionar "Repository by URL"
4. Completar:
   Git repository URL:  https://github.com/octocat/Hello-World.git
   Project name:        practica-import-hello-world
   Visibility:          Private
5. Click "Create project"
```

GitLab clonará el repositorio remoto. Puede tardar 30-60 segundos.

**Verificar:**

```bash
# ¿QUÉ HACE?: Verifica via API que el proyecto fue creado correctamente
# ¿POR QUÉ?: La UI puede mostrar "success" antes de que la importación termine
# ¿PARA QUÉ?: Confirmar que el historial de commits se importó completo
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects?search=practica-import" \
  | python3 -m json.tool | grep -E '"name"|"default_branch"'
```

---

## 📝 Paso 4: Crear proyecto via API

```bash
# ¿QUÉ HACE?: Crea un proyecto completo via REST API con todas las opciones configuradas
# ¿POR QUÉ?: La API permite automatizar la creación sin pasar por la UI
# ¿PARA QUÉ?: Scripts de onboarding, creación de estructuras en nuevos ambientes
curl --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "practica-api-project",
    "description": "Proyecto creado via API en la práctica 01",
    "visibility": "private",
    "initialize_with_readme": true,
    "default_branch": "main",
    "issues_enabled": true,
    "merge_requests_enabled": true,
    "wiki_enabled": false,
    "snippets_enabled": false
  }' \
  "http://localhost/api/v4/projects"
```

Output esperado (extracto):
```json
{
  "id": 5,
  "name": "practica-api-project",
  "path_with_namespace": "root/practica-api-project",
  "http_url_to_repo": "http://localhost/root/practica-api-project.git",
  "visibility": "private",
  "default_branch": "main"
}
```

Guarda el `"id"` del proyecto — lo usarás en siguientes comandos.

---

## 📝 Paso 5: Gestionar el proyecto via API

```bash
# Obtener ID del proyecto si no lo tienes
PROJECT_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects?search=practica-api-project" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

echo "Project ID: $PROJECT_ID"

# ¿QUÉ HACE?: Actualiza la descripción del proyecto
# ¿POR QUÉ?: PUT en /projects/:id permite modificar cualquier atributo
# ¿PARA QUÉ?: Actualizar metadata de proyectos sin entrar a la UI
curl --request PUT \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "description": "Proyecto creado via API — práctica completada",
    "topics": ["bootcamp", "gitlab", "api"]
  }' \
  "http://localhost/api/v4/projects/$PROJECT_ID"

# ¿QUÉ HACE?: Lista los proyectos del usuario actual
# ¿POR QUÉ?: Verifica que los 4 proyectos creados están accesibles
# ¿PARA QUÉ?: Auditar proyectos existentes, contar proyectos, exportar listado
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects?owned=true&per_page=20" \
  | python3 -m json.tool | grep '"name"'
```

---

## 📝 Paso 6: Explorar configuración avanzada de proyecto

En el proyecto `practica-proyecto-01`, explorar Settings:

```
Settings → General → Visibility, project features, permissions:

Desactivar:
  □ Wiki              → ya no aparece en el sidebar
  □ Snippets          → ya no aparece en el sidebar

Reactivar:
  ✓ Wiki              → vuelve a aparecer

Settings → General → Advanced:
  → Rename project: cambiar a "practica-01-renombrado"
    (observar que la URL cambia y la anterior redirige automáticamente)
  → Rename de vuelta a "practica-proyecto-01"
```

---

## ✅ Verificación Final

```bash
# ¿QUÉ HACE?: Lista todos los proyectos del usuario con su URL
# ¿POR QUÉ?: Confirmación final de que los 4 proyectos existen
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects?owned=true" \
  | python3 -c "
import sys, json
projects = json.load(sys.stdin)
for p in sorted(projects, key=lambda x: x['id']):
    print(f\"  [{p['id']}] {p['name']} — {p['http_url_to_repo']}\")
"
```

Output esperado (4 proyectos):
```
  [1] practica-proyecto-01 — http://localhost/root/practica-proyecto-01.git
  [2] practica-template-html — http://localhost/root/practica-template-html.git
  [3] practica-import-hello-world — http://localhost/root/practica-import-hello-world.git
  [4] practica-api-project — http://localhost/root/practica-api-project.git
```

---

## 🔧 Troubleshooting

**Error: "401 Unauthorized"**
```
→ El token no es válido o expiró
→ Verificar: curl -H "PRIVATE-TOKEN: $TOKEN" http://localhost/api/v4/user
→ Regenerar token si es necesario
```

**La importación desde GitHub falla**
```
→ GitHub puede rechazar clonados sin token en repos grandes
→ Alternativa: usar https://gitlab.com/gitlab-org/gitlab-foss.git (repo público de GitLab)
→ O crear un repositorio propio en GitHub con algunas pruebas
```

**El proyecto no aparece en la UI después de la API**
```
→ Recargar la página (F5)
→ Verificar en http://localhost/root (dashboard del usuario)
```

---

## 📦 Entregables

- [ ] Captura de `http://localhost/root` mostrando los 4 proyectos creados
- [ ] Output del comando `curl` de verificación final mostrando los 4 proyectos
- [ ] Captura de **Settings → General** de `practica-api-project` mostrando los topics agregados

---

➡️ **Siguiente práctica:** [02 — Grupos y Subgrupos](../02-grupos-y-subgrupos/README.md)

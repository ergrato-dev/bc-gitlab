# Practica 01 — Crear Proyectos en GitLab

## Objetivo
Crear proyectos usando diferentes metodos y configuraciones en GitLab CE.

## Instrucciones

### 1. Crear proyecto en blanco

1. Desde el dashboard, click **New project → Create blank project**
2. Nombre: `practica-proyecto-01`
3. Visibility: Private
4. Marcar **Initialize with README**
5. Crear

### 2. Crear proyecto desde template

1. **New project → Create from template**
2. Selecciona un template (ej: Node.js Express, Ruby on Rails, Pages/Plain HTML)
3. Nombre: `practica-template`
4. Visibility: Private
5. Crear

### 3. Importar proyecto desde URL

```bash
# Crear proyecto importando un repo publico
# En GitLab UI: New project → Import project → Repo by URL
# URL: https://github.com/octocat/Hello-World.git
# Nombre: practica-import
# Visibility: Private
```

### 4. Crear proyecto via API

```bash
# Obtener token de acceso personal
# Settings → Access Tokens → Add new token
# Name: practica-api
# Scopes: api
# Guardar el token generado

# Crear proyecto
curl --request POST \
  --header "PRIVATE-TOKEN: TU_TOKEN" \
  --data "name=practica-api&visibility=private&initialize_with_readme=true" \
  "http://localhost/api/v4/projects"
```

### 5. Verificar proyectos creados

Navega a **Projects → Your projects** y verifica que los 4 proyectos aparezcan.

## Entregable
- Captura de la pagina **Your projects** mostrando los 4 proyectos creados
- Salida del comando API mostrando respuesta JSON exitosa

# 01 — Proyectos en GitLab

## Objetivos

- Entender los tipos de proyectos en GitLab CE
- Crear proyectos desde cero, desde template y por importacion
- Configurar opciones de proyecto (visibilidad, CI/CD, features)

## Que es un Proyecto en GitLab?

Un proyecto es la unidad fundamental de trabajo en GitLab. Contiene:
- Repositorio de codigo fuente
- Issues (tareas, bugs)
- Merge Requests
- Pipelines de CI/CD
- Wiki
- Container Registry
- Snippets

## Tipos de Proyectos

### 1. Proyecto en Blanco
Crear desde cero, opcionalmente inicializado con README.

### 2. Proyecto desde Template
GitLab ofrece templates para diferentes frameworks y lenguajes:
- Ruby on Rails, Node.js, Python, Go
- .NET Core, Spring, Maven
- Pages/Static site (Hugo, Jekyll, Middleman)

### 3. Proyecto por Importacion
Importar desde:
- GitHub, Bitbucket, Gitea
- Repositorio Git por URL
- Manifest file (XML con multiples repos)

## Crear un Proyecto

### Via Web UI
1. Click en **New Project** (icno + en top bar o desde dashboard)
2. Seleccionar opcion: **Create blank project**, **Create from template** o **Import project**
3. Completar formulario:
   - **Project name**: Nombre unico en el namespace
   - **Project URL**: Derivado del grupo/usuario
   - **Project slug**: Version URL-safe del nombre
   - **Visibility Level**: Private, Internal o Public
   - **Initialize with README**: Opcional

### Via API
```bash
curl --request POST \
  --header "PRIVATE-TOKEN: <tu-token>" \
  --data "name=mi-nuevo-proyecto&visibility=private" \
  "http://localhost/api/v4/projects"
```

### Via CLI (con glab)
```bash
glab repo create mi-nuevo-proyecto --private
```

## Configuracion del Proyecto

En **Settings → General** puedes:
- Renombrar proyecto (cambia URL)
- Transferir a otro namespace
- Cambiar visibilidad
- Archivar proyecto (read-only)
- Eliminar proyecto (requiere confirmacion)

### Features por Proyecto

En **Settings → General → Visibility, project features, permissions**:
- Issues: Habilitar/deshabilitar
- Merge Requests: Habilitar/deshabilitar
- CI/CD: Habilitar/deshabilitar
- Container Registry: Habilitar/deshabilitar
- Packages: Habilitar/deshabilitar
- Wiki: Habilitar/deshabilitar
- Snippets: Habilitar/deshabilitar

Cada feature puede configurarse como:
- **Everyone with access**: Visible para todos con acceso al proyecto
- **Only project members**: Solo miembros del proyecto

## Buenas Practicas

- Usa nombres descriptivos y slugs coherentes
- Inicializa siempre con README y .gitignore
- Configura visibilidad siguiendo el principio de minimo privilegio
- Agrega descripcion al proyecto para contexto

# 05 — Primeros Pasos en GitLab CE

## Objetivos

- Navegar la interfaz web de GitLab CE con soltura
- Configurar autenticacion SSH desde Docker
- Crear el primer proyecto y conectarlo localmente
- Entender el menu de administracion (Admin Area)

## Acceso a GitLab CE

El bootcamp usa Docker Compose. GitLab CE corre en un contenedor:

```bash
# Verificar que GitLab esta corriendo
docker compose ps gitlab
# Debe mostrar: "healthy" o "running"

# Obtener contrasena root (solo primer inicio)
docker compose exec gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

- **URL**: `http://localhost`
- **Usuario**: `root`
- **Contrasena**: La obtenida del comando anterior

> **Importante**: El archivo `initial_root_password` se elimina a las 24h. Cambia la contrasena en tu primer inicio de sesion.

## Configurar SSH con Docker

GitLab en Docker expone SSH en el puerto **2224** (mapeado al 22 interno). Esto evita conflictos con el SSH del host.

### Generar clave SSH

```bash
# Generar par de claves (usa ed25519, mas seguro y rapido que RSA)
ssh-keygen -t ed25519 -C "bootcamp@gitlab-ce" -f ~/.ssh/id_ed25519_bootcamp

# Iniciar ssh-agent y agregar la clave
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_bootcamp

# Mostrar clave publica para copiar a GitLab
cat ~/.ssh/id_ed25519_bootcamp.pub
```

### Agregar clave SSH a GitLab

1. Inicia sesion en `http://localhost` como `root`
2. Avatar (esquina superior derecha) → **Preferences**
3. Sidebar izquierdo → **SSH Keys**
4. Pega la clave publica en el campo "Key"
5. Titulo: `mi-laptop-bootcamp`
6. Expiration date: opcional (dejar vacio = no expira)
7. Click **Add key**

### Verificar conexion SSH

```bash
# Probar conexion SSH (puerto 2224)
ssh -T -p 2224 git@localhost

# Debe responder: "Welcome to GitLab, @root!"
```

### Configurar ~/.ssh/config para no escribir el puerto siempre

```bash
cat >> ~/.ssh/config << 'EOF'
Host gitlab.local
    HostName localhost
    Port 2224
    User git
    IdentityFile ~/.ssh/id_ed25519_bootcamp
EOF

# Ahora puedes usar:
ssh -T gitlab.local
git clone git@gitlab.local:root/mi-proyecto.git
```

## La Interfaz Web — Tour Guiado

### Top Bar (barra superior)

- **Busqueda** (`/` atajo de teclado): Busca proyectos, issues, MRs, usuarios
- **Plus (+)** : Nuevo proyecto, grupo, issue, MR, snippet
- **Campana**: Notificaciones
- **Avatar**: Menu de usuario → Preferences, Settings, Sign out

### Sidebar Izquierdo (navegacion principal)

- **Projects**: Tus proyectos
- **Groups**: Grupos a los que perteneces
- **Explore**: Proyectos publicos, topics
- **Admin Area** (solo admin): Gestion de la instancia

### Dashboard (pagina principal)

Al iniciar sesion ves:
- Proyectos recientes
- Tus issues asignados
- Tus MRs pendientes de revision
- Actividad reciente

### Dentro de un Proyecto

| Pestana | Que contiene |
|---------|-------------|
| **Repository** | Archivos, ramas, tags, contribuidores, grafico de commits |
| **Issues** | Lista de issues con filtros, labels, milestones, boards |
| **Merge Requests** | MRs abiertos, merged, closed |
| **CI/CD** | Pipelines, jobs, artifacts, schedules, environments |
| **Packages & Registries** | Container Registry, Package Registry |
| **Wiki** | Documentacion del proyecto |
| **Snippets** | Fragmentos de codigo compartibles |
| **Settings** | Configuracion del proyecto (miembros, webhooks, CI/CD, etc.) |

### Admin Area (icono de llave en sidebar inferior)

Solo visible para administradores. Secciones clave:

- **Overview**: Dashboard, proyectos, usuarios, grupos
- **Monitoring**: Salud del sistema, logs, jobs en background
- **Settings**: Configuracion general de la instancia
- **CI/CD**: Runners administrados por la instancia
- **Messages**: Banner de anuncios global

## Crear el Primer Proyecto

1. Desde el dashboard, click en **New Project** (o boton + en top bar)
2. Seleccionar **Create blank project**
3. Configurar:
   - **Project name**: `hola-gitlab`
   - **Project URL**: Se autocompleta (grupo `root`)
   - **Visibility Level**: Private (solo tu lo ves)
   - Marcar **Initialize repository with a README**
4. Click **Create project**

## Conectar Localmente

```bash
# Clonar con SSH (recomendado)
git clone ssh://git@localhost:2224/root/hola-gitlab.git
cd hola-gitlab

# Si configuraste ~/.ssh/config:
git clone git@gitlab.local:root/hola-gitlab.git

# Alternativa HTTP (menos seguro para practicas, util para pruebas rapidas)
git clone http://localhost/root/hola-gitlab.git
```

### Agregar contenido

```bash
cd hola-gitlab

# Editar README.md
cat >> README.md << 'EOF'

## Mi primer proyecto en GitLab CE

Este proyecto fue creado durante el Bootcamp GitLab CE Zero to Hero.

### Stack
- GitLab CE en Docker
- SSH para autenticacion
- Markdown para documentacion
EOF

# Ver cambios
git status
git diff

# Commit y push
git add README.md
git commit -m "docs: agregar descripcion del proyecto"
git push origin main
```

### Verificar en la UI

Recarga la pagina del proyecto en GitLab (`http://localhost/root/hola-gitlab`). Debes ver el README.md renderizado con tu nuevo contenido.

## Cambiar Contrasena Root

1. Avatar → **Preferences**
2. Sidebar → **Password**
3. Ingresa contrasena actual + nueva contrasena
4. **Save password**

# 📖 05 — Primeros Pasos en GitLab CE

## 🎯 Objetivos de Aprendizaje

Al finalizar esta lección serás capaz de:

- Acceder a GitLab CE y completar la configuración inicial de seguridad
- Navegar la interfaz web con soltura
- Crear un usuario personal (distinto de root) para el trabajo diario
- Generar una clave SSH ed25519 y agregarla a GitLab CE
- Clonar repositorios vía SSH (puerto 2224) y vía HTTP
- Crear un proyecto desde la interfaz web
- Generar y usar Personal Access Tokens para automatización

---

## 🚀 Acceso Inicial a GitLab CE

El bootcamp usa Docker Compose. Antes de acceder, verifica que GitLab esté saludable:

```bash
# ¿QUÉ VAMOS A HACER?: Verificar que el contenedor GitLab está corriendo y saludable
# ¿POR QUÉ LO HACEMOS?: GitLab tarda ~3-5 minutos en iniciar; no tiene sentido abrir el browser antes
# ¿PARA QUÉ SIRVE?: Evitar el frustrante error "502 Bad Gateway" por entrar demasiado pronto
docker compose ps gitlab
# Busca "healthy" en la columna STATUS

# Si aún no está healthy, ver el progreso
docker compose logs -f gitlab | grep "GitLab"
# Cuando aparezca "GitLab is up" o similar, está listo
```

**Datos de acceso**:
- URL: `http://localhost`
- Usuario: `root`
- Contraseña: Obtenerla con el siguiente comando (solo funciona las primeras 24h):

```bash
# ¿QUÉ VAMOS A HACER?: Leer la contraseña inicial del usuario root
# ¿POR QUÉ LO HACEMOS?: GitLab genera una contraseña aleatoria en el primer inicio
# ¿PARA QUÉ SIRVE?: Es la única forma de acceder antes de configurar la instancia
docker compose exec gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

> ⚠️ **Importante**: El archivo `initial_root_password` se elimina automáticamente 24 horas después del primer inicio. Cambia la contraseña de root en tu primer inicio de sesión.

---

## 🔐 Configuración Inicial de Seguridad

Al acceder por primera vez como root, realiza estas configuraciones:

### Cambiar la Contraseña de Root

1. Click en el **avatar** (esquina superior derecha)
2. Seleccionar **Edit profile**
3. Sidebar izquierdo → **Password**
4. Ingresar contraseña actual + nueva contraseña (mínimo 8 caracteres)
5. Click **Save password**

### Configurar el Email de Root

1. Click en el **avatar** → **Edit profile**
2. En **Email**: ingresar un email real (aunque no salgan emails en el bootcamp)
3. Click **Update profile settings**

---

## 👤 Crear un Usuario Personal (Recomendado)

No es buena práctica trabajar con el usuario `root` para el día a día. Crea un usuario personal:

**Opción A: Desde la UI como admin**

1. Sidebar izquierdo → **Admin Area** (icono de llave)
2. **Overview** → **Users** → **New user**
3. Completar: nombre, username, email
4. Click **Create user**
5. En la página del usuario creado → **Edit** → asignar contraseña
6. Cerrar sesión y entrar con el nuevo usuario

**Opción B: Desde la página de registro** (si está habilitada)

1. Ir a `http://localhost/users/sign_up`
2. Completar el formulario
3. Como administrador, ir a **Admin Area** → **Users** → aprobar el usuario (si requiere aprobación)

> 💡 **Para el bootcamp**: Puedes seguir usando `root` para simplificar. En un entorno real, nunca uses el usuario administrador para trabajo diario.

---

## 🗺️ Tour de la Interfaz Web

### La Barra Superior

```
[🦊] [Barra de búsqueda]                              [🔔] [+] [👤]
  │         │                                           │    │    │
  │    Buscar todo                               Alertas │    │    Perfil
  Inicio    (atajo: /)                                   │    Crear nuevo
                                                         Notificaciones
```

**Atajos de teclado útiles**:
- `/` → Activar búsqueda global
- `?` → Ver todos los atajos disponibles
- `g` + `p` → Ir a Projects
- `g` + `i` → Ir a Issues
- `g` + `m` → Ir a Merge Requests

### El Sidebar Izquierdo

| Ítem | Qué contiene |
|------|--------------|
| **Your work** | Dashboard personal: proyectos, issues asignados, MRs a revisar |
| **Explore** | Proyectos y grupos públicos en la instancia |
| **Groups** | Grupos a los que perteneces |
| **Admin Area** | Solo visible para administradores (icono de llave) |

### Dentro de un Proyecto

Al entrar a cualquier proyecto, el sidebar izquierdo muestra:

| Sección | Qué hay dentro |
|---------|----------------|
| **Repository** | Árbol de archivos, commits, ramas, tags, comparaciones de código |
| **Issues** | Lista filtrable, boards Kanban, milestones, labels |
| **Merge Requests** | MRs abiertos y cerrados, revisiones pendientes |
| **CI/CD** | Pipelines, jobs, artifacts, schedules, environments, runners |
| **Packages & Registries** | Container Registry, Package Registry |
| **Wiki** | Documentación del proyecto en Markdown |
| **Snippets** | Fragmentos de código compartibles |
| **Settings** | Configuración del proyecto (miembros, webhooks, CI/CD, etc.) |

---

## 🔑 Configurar Autenticación SSH

SSH es el método **recomendado** para autenticación con Git. Es más seguro que HTTPS con contraseña y no requiere ingresar credenciales en cada operación.

> ⚠️ **Puerto especial**: Nuestro GitLab CE en Docker expone SSH en el puerto **2224** (no el 22 estándar). Esto evita conflictos con el SSH del sistema operativo del host.

### Paso 1: Generar el Par de Claves

```bash
# ¿QUÉ VAMOS A HACER?: Generar un par de claves SSH ed25519
# ¿POR QUÉ LO HACEMOS?: Ed25519 es más seguro y más rápido que RSA (evitamos RSA en 2024+)
# ¿PARA QUÉ SIRVE?: La clave privada queda en tu máquina; la pública va a GitLab
ssh-keygen -t ed25519 -C "bootcamp-gitlab-ce" -f ~/.ssh/id_ed25519_gitlab

# El comando preguntará por una passphrase (contraseña de la clave)
# Para el bootcamp puedes dejarla vacía (Enter sin escribir nada)
# En producción: siempre usa passphrase
```

Esto crea dos archivos:
- `~/.ssh/id_ed25519_gitlab` — Clave **privada** (nunca compartir)
- `~/.ssh/id_ed25519_gitlab.pub` — Clave **pública** (esta va a GitLab)

### Paso 2: Agregar la Clave al ssh-agent

```bash
# ¿QUÉ VAMOS A HACER?: Iniciar el agente SSH y cargar la clave privada en memoria
# ¿POR QUÉ LO HACEMOS?: El agente maneja la autenticación automáticamente
# ¿PARA QUÉ SIRVE?: Git puede autenticarse sin pedirte la passphrase cada vez
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_gitlab

# Verificar que la clave está cargada
ssh-add -l
```

### Paso 3: Agregar la Clave Pública a GitLab CE

```bash
# Ver la clave pública (esto es lo que pegarás en GitLab)
cat ~/.ssh/id_ed25519_gitlab.pub
# Copia TODO el output (empieza con "ssh-ed25519 AAAA..." y termina con el comentario)
```

En GitLab CE (`http://localhost`):
1. Click en el **avatar** → **Preferences**
2. Sidebar izquierdo → **SSH Keys**
3. Pegar la clave pública en el campo **Key**
4. **Title**: `mi-laptop-bootcamp` (o un nombre descriptivo)
5. **Expiration date**: Dejar vacío (sin expiración para el bootcamp)
6. Click **Add key**

### Paso 4: Verificar la Conexión SSH

```bash
# ¿QUÉ VAMOS A HACER?: Probar la autenticación SSH contra GitLab CE
# ¿POR QUÉ LO HACEMOS?: Para confirmar que la clave fue configurada correctamente
# ¿PARA QUÉ SIRVE?: Si esto funciona, git push/pull funcionarán sin problemas
ssh -T -p 2224 git@localhost

# Respuesta esperada:
# Welcome to GitLab, @root!
```

> 🚨 **Error común**: Si ves `Permission denied (publickey)`, verifica:
> 1. ¿Pegaste la clave **pública** (`.pub`) y no la privada?
> 2. ¿Estás usando el puerto **2224**?
> 3. ¿La clave está cargada en el agente? (`ssh-add -l`)

### Paso 5: Configurar `~/.ssh/config` (Opcional pero Muy Recomendado)

Para no tener que escribir `-p 2224` en cada comando:

```bash
# ¿QUÉ VAMOS A HACER?: Crear un alias SSH para el GitLab del bootcamp
# ¿POR QUÉ LO HACEMOS?: Para simplificar los comandos git y no tener que recordar el puerto
# ¿PARA QUÉ SIRVE?: Permite usar "gitlab.local" en lugar de "localhost -p 2224"
cat >> ~/.ssh/config << 'EOF'

Host gitlab.local
    HostName localhost
    Port 2224
    User git
    IdentityFile ~/.ssh/id_ed25519_gitlab
    StrictHostKeyChecking no
EOF

chmod 600 ~/.ssh/config

# Probar con el alias
ssh -T gitlab.local
# Respuesta esperada: Welcome to GitLab, @root!
```

---

## 📂 Clonar un Repositorio

### Vía SSH (Recomendado)

```bash
# Forma con puerto explícito (siempre funciona)
git clone ssh://git@localhost:2224/root/mi-proyecto.git

# Forma con el alias de ~/.ssh/config (más cómoda)
git clone git@gitlab.local:root/mi-proyecto.git

# ¿Dónde encuentro la URL?
# En GitLab CE → Proyecto → botón "Clone" → "Clone with SSH"
# Cambiar el host de "localhost" a "localhost:2224" si muestra la URL SSH estándar
```

### Vía HTTP

```bash
# ¿QUÉ VAMOS A HACER?: Clonar un repositorio usando HTTP básico
# ¿POR QUÉ LO HACEMOS?: Alternativa cuando SSH no está disponible o para pruebas rápidas
# ¿PARA QUÉ SIRVE?: No requiere configurar claves SSH, pero pide usuario/contraseña en cada push
git clone http://localhost/root/mi-proyecto.git

# Para evitar ingresar contraseña en cada operación (guardado en caché)
git config --global credential.helper store
# ⚠️ Guarda la contraseña en texto plano en ~/.git-credentials. Solo para bootcamp.
```

---

## 📁 Crear el Primer Proyecto desde la UI

1. Click en el **`+`** (top bar) → **New project/repository**
   — O desde el sidebar: **Your work** → **Projects** → **New project**

2. Seleccionar **Create blank project**

3. Completar el formulario:
   - **Project name**: `hola-gitlab` (se auto-completa la slug/URL)
   - **Project URL**: `http://localhost/root/hola-gitlab`
   - **Visibility Level**:
     - `Private` — Solo tú y quienes invites
     - `Internal` — Todos los usuarios de la instancia
     - `Public` — Cualquiera que acceda al servidor
   - ✅ **Initialize repository with a README** (marca esta opción)

4. Click **Create project**

5. GitLab te lleva directamente al proyecto con el README inicial.

---

## 🔐 Personal Access Tokens (PAT)

Los Personal Access Tokens son credenciales para acceder a la API de GitLab o para `git clone` vía HTTPS sin usar contraseña. Son la alternativa recomendada a las contraseñas en scripts y automatización.

```bash
# Usar un PAT para clonar via HTTPS
git clone http://oauth2:<TU_TOKEN>@localhost/root/mi-proyecto.git

# Usar un PAT para llamar a la API de GitLab
curl --header "PRIVATE-TOKEN: <TU_TOKEN>" \
     "http://localhost/api/v4/projects"
```

### Crear un Personal Access Token

1. Avatar → **Preferences**
2. Sidebar izquierdo → **Access Tokens**
3. Click **Add new token**
4. Configurar:
   - **Token name**: `bootcamp-scripts`
   - **Expiration date**: 30 días desde hoy (recomendado para práctica)
   - **Scopes** (permisos):
     - `api` — Acceso completo a la API
     - `read_repository` — Leer repositorios
     - `write_repository` — Escribir (push) a repositorios
5. Click **Create personal access token**
6. **Copiar el token ahora** — no podrás verlo de nuevo

> ⚠️ **Seguridad**: Trata los PAT como contraseñas. No los pongas en el código, no los subas a Git, y ponles fecha de expiración.

---

## ✅ Lista de Verificación de Esta Lección

Antes de continuar con las prácticas, verifica que puedes:

- [ ] Acceder a `http://localhost` y ver el dashboard de GitLab
- [ ] `ssh -T -p 2224 git@localhost` responde "Welcome to GitLab"
- [ ] `git clone ssh://git@localhost:2224/root/hola-gitlab.git` funciona
- [ ] Tienes un proyecto `hola-gitlab` visible en la UI
- [ ] Sabes navegar a Repository, Issues, Settings dentro del proyecto

---

## 🤔 Preguntas de Reflexión

1. ¿Por qué usamos ed25519 en lugar de RSA para generar las claves SSH? ¿Qué ventajas tiene?
2. El puerto SSH de GitLab CE en Docker es 2224 y no 22. ¿Por qué se mapea así? ¿Qué pasaría si intentaras usar el puerto 22?
3. ¿Cuál es la diferencia de seguridad entre autenticarse vía SSH y vía HTTP con usuario/contraseña?
4. ¿Para qué sirve un Personal Access Token versus una contraseña normal? ¿En qué casos preferirías usar cada uno?
5. ¿Por qué se recomienda no usar el usuario `root` para el trabajo diario en GitLab?

---

## 📚 Recursos Adicionales

- [GitLab SSH Keys Documentation](https://docs.gitlab.com/ee/user/ssh.html) — Guía oficial
- [Personal Access Tokens](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html) — Documentación
- [GitLab Keyboard Shortcuts](https://docs.gitlab.com/ee/user/shortcuts.html) — Lista completa de atajos

---

## ➡️ Siguiente Paso

[Ir a las Prácticas →](../2-practicas/README.md)

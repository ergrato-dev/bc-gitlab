# 📋 Instrucciones Detalladas — Proyecto Semana 01

Esta guía tiene los comandos exactos para completar el proyecto paso a paso. Sigue el orden indicado.

---

## Fase 1: Crear el Proyecto en GitLab CE

En `http://localhost` (con usuario `root` o tu usuario personal):

1. Click **`+`** → **New project/repository**
2. Seleccionar **Create blank project**
3. Configurar:
   - **Project name**: `mi-portafolio-devops`
   - **Visibility Level**: Private
   - ❌ **NO marcar** "Initialize repository with a README" (lo haremos manualmente)
4. Click **Create project**

GitLab te mostrará una pantalla con instrucciones para "Push an existing folder". Guarda la URL SSH que aparece, tendrá la forma:
`ssh://git@localhost:2224/root/mi-portafolio-devops.git`

---

## Fase 2: Inicializar el Repositorio Localmente

```bash
# Crear la carpeta del proyecto
mkdir -p ~/bootcamp/mi-portafolio-devops
cd ~/bootcamp/mi-portafolio-devops

# Inicializar como repositorio Git
git init

# Configurar la rama principal como "main"
git branch -M main

# Conectar con el repositorio remoto en GitLab CE
# (reemplaza la URL con la que copiaste de GitLab)
git remote add origin ssh://git@localhost:2224/root/mi-portafolio-devops.git

# Verificar que el remoto quedó configurado
git remote -v
# Debe mostrar: origin  ssh://git@localhost:2224/root/mi-portafolio-devops.git
```

---

## Fase 3: Crear la Estructura de Archivos

```bash
# Crear los directorios necesarios
mkdir -p docs scripts

# Verificar la estructura
ls -la
```

### Crear `README.md`

```bash
cat > README.md << 'EOF'
# Mi Portafolio DevOps

[![GitLab CE](https://img.shields.io/badge/GitLab-CE%2017.x-fc6d26?logo=gitlab)](http://localhost)
[![Bootcamp](https://img.shields.io/badge/Bootcamp-GitLab%20CE%20Zero%20to%20Hero-brightgreen)]()

Repositorio personal de aprendizaje DevOps. Creado durante el **Bootcamp GitLab CE Zero to Hero**.

## Sobre Este Repositorio

Este repositorio documenta mi progreso en el bootcamp. Cada semana agrego nuevas secciones con lo aprendido sobre GitLab CE, CI/CD, contenedores y administración de sistemas DevOps.

## Stack Tecnológico

- **GitLab CE 17.x** — Plataforma DevOps self-hosted en Docker
- **Git** — Control de versiones
- **SSH** — Autenticación segura
- **Bash** — Scripting básico
- **Docker / Docker Compose** — Contenedores (a partir de Semana 02)

## Estado del Bootcamp

| Semana | Tema | Estado |
|--------|------|--------|
| 01 | Fundamentos Git y GitLab CE | ✅ En progreso |
| 02 | Instalación GitLab CE | ⏳ Pendiente |
| 03 | Proyectos, Grupos y Organización | ⏳ Pendiente |
| 04 | Issues, MRs y Code Review | ⏳ Pendiente |
| 05 | GitLab CI/CD Fundamentos | ⏳ Pendiente |

## Estructura del Repositorio

```
mi-portafolio-devops/
├── README.md          ← Este archivo
├── .gitignore         ← Archivos ignorados por Git
├── docs/
│   └── aprendizaje.md ← Reflexiones semanales
└── scripts/
    └── hola.sh        ← Script de demostración
```
EOF
```

### Crear `.gitignore`

```bash
cat > .gitignore << 'EOF'
# ===== SISTEMA OPERATIVO =====
# macOS
.DS_Store
.AppleDouble
.LSOverride

# Windows
Thumbs.db
ehthumbs.db
Desktop.ini

# Linux
*~

# ===== ARCHIVOS TEMPORALES =====
*.log
*.tmp
*.temp
*.bak
*.cache
temp/
tmp/

# ===== EDITORES =====
# VS Code
.vscode/
*.code-workspace

# Vim/Neovim
*.swp
*.swo
[._]*.s[a-v][a-z]
[._]*.sw[a-p]

# JetBrains
.idea/
*.iml

# ===== SEGURIDAD (NUNCA subir estos) =====
.env
.env.local
.env.*.local
secrets/
*.pem
*.key
*.p12
*.pfx

# ===== DEPENDENCIAS =====
node_modules/
__pycache__/
*.pyc
*.pyo
venv/
.venv/
vendor/
EOF
```

### Crear `docs/aprendizaje.md`

```bash
cat > docs/aprendizaje.md << 'EOF'
# Notas de Aprendizaje — Bootcamp GitLab CE Zero to Hero

## Semana 01 — Fundamentos de Git y GitLab CE

### Los 3 Conceptos Más Importantes

1. **Los tres estados de Git**: Entender la diferencia entre Working Directory, Staging Area y Repository fue clave para que los comandos `git add` y `git commit` tuvieran sentido. No es magia — es un sistema de dos pasos intencional.

2. **GitLab CE como plataforma todo-en-uno**: No es solo un hosting de código. CI/CD, registry, issues, wikis — todo integrado. Esto cambia completamente la forma de pensar en herramientas DevOps.

3. **SSH con puerto 2224**: El detalle de que GitLab CE en Docker usa el puerto 2224 para SSH me hizo entender que los puertos de contenedores se mapean y no siempre son los estándar.

### Error Más Común y Cómo Lo Resolví

**El error**: Ejecutar `git push` y obtener `Permission denied (publickey)`.
**La causa**: Olvidé iniciar el `ssh-agent` y cargar mi clave con `ssh-add`.
**La solución**: `eval "$(ssh-agent -s)"` seguido de `ssh-add ~/.ssh/id_ed25519_gitlab`.
**La lección**: SSH requiere que el agente esté corriendo en la sesión actual. Si abres una terminal nueva, hay que volver a ejecutar estos comandos (o configurarlo en `~/.bashrc`).

### Comando Más Útil

`git log --oneline --graph --all` — Porque visualiza exactamente el estado del historial con las ramas. Antes de esto, Git me parecía una caja negra; este comando lo hace concreto y visible.

### Pregunta Pendiente

¿Cómo funciona el rebase interactivo (`git rebase -i`) para limpiar el historial antes de hacer una MR? ¿Es una práctica recomendada o preferible evitarlo?

---

## Semana 02 — (Pendiente)

*Se completará la próxima semana.*
EOF
```

### Crear `scripts/hola.sh`

```bash
cat > scripts/hola.sh << 'EOF'
#!/usr/bin/env bash
# hola.sh — Script de demostración del portafolio DevOps
# Autor: (Tu nombre)
# Bootcamp: GitLab CE Zero to Hero — Semana 01

set -euo pipefail

# ─── Colores ───────────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Mi Portafolio DevOps — Bienvenido    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}📅 Fecha y hora:${NC}    $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${GREEN}💻 Hostname:${NC}        $(hostname)"
echo -e "${GREEN}👤 Usuario:${NC}         $(whoami)"
echo -e "${GREEN}📁 Directorio:${NC}      $(pwd)"
echo -e "${GREEN}🐚 Shell:${NC}           $SHELL"

echo ""
echo -e "${YELLOW}🔧 Versión de Git:${NC}"
git --version

echo ""
echo -e "${YELLOW}📋 Últimos 3 commits de este repo:${NC}"
git log --oneline -3 2>/dev/null || echo "  (ejecuta desde dentro del repositorio)"

echo ""
echo -e "${BLUE}¡Bootcamp GitLab CE Zero to Hero — Semana 01 completada!${NC}"
echo ""
EOF

# Hacer el script ejecutable
chmod +x scripts/hola.sh

# Probarlo
bash scripts/hola.sh
```

---

## Fase 4: Primer Commit

```bash
# Ver el estado antes del primer commit
git status
# Debe mostrar todos los archivos como "Untracked"

# Ver la estructura completa
find . -not -path './.git/*' | sort

# Agregar todos los archivos al staging
git add README.md .gitignore docs/aprendizaje.md scripts/hola.sh

# Verificar que todo está en staging
git status

# Primer commit
git commit -m "feat: inicializar portafolio DevOps

- README.md con presentación, stack y estado del bootcamp
- .gitignore con reglas para OS, editores y seguridad
- docs/aprendizaje.md con reflexiones de la semana 01
- scripts/hola.sh: script funcional con información del sistema"
```

---

## Fase 5: Push Inicial a GitLab CE

```bash
# Subir la rama main por primera vez
git push -u origin main

# Si todo está bien, verás algo como:
# Enumerating objects: X, done.
# ...
# Branch 'main' set up to track remote branch 'main' from 'origin'.

# Verificar en el navegador
echo "Visita: http://localhost/root/mi-portafolio-devops"
```

---

## Fase 6: Crear la Rama `dev` y Agregarle Contenido

```bash
# Crear rama dev desde main
git switch -c dev

# Agregar contenido de "próximas semanas" en la documentación
cat >> docs/aprendizaje.md << 'EOF'

---

## Próximos Temas a Explorar

- **Semana 02**: Instalación manual de GitLab CE con Docker Compose
- **Semana 03**: Organización de proyectos con grupos y subgrupos
- **Semana 04**: Code Review con Merge Requests
- **Semana 05**: Mi primer pipeline `.gitlab-ci.yml`
EOF

git add docs/aprendizaje.md
git commit -m "docs: agregar roadmap de próximas semanas al portafolio"

# Agregar un placeholder para CI/CD (se usará en semana 05)
cat > .gitlab-ci.yml << 'EOF'
# Pipeline CI/CD — Se implementará en Semana 05
# Por ahora este archivo es un placeholder

stages:
  - validate

placeholder:
  stage: validate
  script:
    - echo "Pipeline del portafolio DevOps"
    - echo "GitLab CE versión: $(cat /etc/gitlab/gitlab.rb 2>/dev/null | head -1 || echo 'desconocida')"
    - bash scripts/hola.sh
  rules:
    - when: manual  # No ejecutar automáticamente aún
EOF

git add .gitlab-ci.yml
git commit -m "ci: agregar placeholder de pipeline para implementar en semana 05"

# Subir la rama dev
git push -u origin dev
```

---

## Fase 7: Crear Rama Feature y Merge Request

```bash
# Crear rama feature desde dev
git switch -c feature/documentar-ssh

# Crear un archivo de documentación específico
cat > docs/configuracion-ssh.md << 'EOF'
# Configuración SSH para GitLab CE (Docker)

## El Problema

GitLab CE en Docker no puede usar el puerto SSH estándar (22) porque ese puerto
ya lo ocupa el SSH del sistema operativo host. Por eso se mapea al puerto **2224**.

## La Solución

### Generar Clave SSH

```bash
ssh-keygen -t ed25519 -C "bootcamp" -f ~/.ssh/id_ed25519_gitlab
```

### Configurar ~/.ssh/config

```
Host gitlab.local
    HostName localhost
    Port 2224
    User git
    IdentityFile ~/.ssh/id_ed25519_gitlab
```

### Clonar Repositorios

```bash
# Con puerto explícito:
git clone ssh://git@localhost:2224/usuario/proyecto.git

# Con alias del ~/.ssh/config:
git clone git@gitlab.local:usuario/proyecto.git
```

### Verificar Conexión

```bash
ssh -T -p 2224 git@localhost
# Respuesta esperada: Welcome to GitLab, @usuario!
```
EOF

git add docs/configuracion-ssh.md
git commit -m "docs: documentar configuración SSH específica del bootcamp (puerto 2224)"

# Subir la rama feature
git push -u origin feature/documentar-ssh
```

En GitLab CE:
1. Ir a `http://localhost/root/mi-portafolio-devops`
2. Click en el banner **"Create merge request"** que aparece
3. Configurar:
   - Source: `feature/documentar-ssh` → Target: `dev`
   - Title: `docs: documentar configuración SSH para GitLab CE en Docker`
4. Click **Create merge request**
5. Revisar el diff en **Changes**
6. Click **Merge**

```bash
# Sincronizar localmente después del merge
git switch dev
git pull origin dev

# Ver el historial
git log --oneline --graph --all
```

---

## Fase 8: Merge de dev a main

```bash
# Cambiar a main
git switch main

# Hacer merge de dev en main
git merge dev

# Subir main actualizado
git push origin main

# Ver el historial final
git log --oneline --graph --all
```

---

## ✅ Verificación Final del Proyecto

```bash
# Verificar que tienes al menos 5 commits
git log --oneline | wc -l

# Verificar la estructura del repositorio
find . -not -path './.git/*' -not -name '.gitkeep' | sort

# Verificar que el script funciona
bash scripts/hola.sh

# Verificar ramas
git branch -a
# Debe mostrar: main, dev (y las remotas correspondientes)
```

# 01 — Git: Fundamentos

## Objetivos

- Entender que es Git y por que es esencial en DevOps
- Configurar Git con identidad y SSH
- Dominar los comandos fundamentales
- Entender el modelo de objetos de Git (blobs, trees, commits)

## Que es Git?

Git es un sistema de control de versiones distribuido creado por Linus Torvalds en 2005. Permite rastrear cambios en archivos, colaborar en equipo y mantener un historial completo del proyecto. A diferencia de sistemas centralizados (SVN, CVS), cada copia de trabajo es un repositorio completo.

### Por que Git en DevOps

- **Trazabilidad**: Cada cambio tiene autor, fecha y mensaje
- **Colaboracion**: Multiples personas trabajan sin conflicto
- **Integracion CI/CD**: Pipelines se disparan con eventos Git
- **Infraestructura como Codigo**: Toda configuracion versionada
- **Rollback**: Volver a cualquier estado anterior

## Conceptos Clave

- **Repositorio (repo)**: Carpeta con seguimiento de cambios (`.git/`)
- **Commit**: Snapshot del estado del proyecto identificado por SHA-1
- **Rama (branch)**: Apuntador movil a un commit
- **Remoto (remote)**: Copia del repositorio en otro lugar
- **Staging area (index)**: Area de preparacion entre working dir y repo
- **HEAD**: Apuntador a la rama/commit actual

### Los 3 Estados de Git

```
Working Directory          Staging Area           Git Repository
   (modified)         git add →  (staged)   git commit →  (committed)
                              ← git restore --staged
   ← git restore / git checkout
```

## Configuracion Inicial

```bash
# Identidad (obligatorio — aparece en cada commit)
git config --global user.name "Tu Nombre Completo"
git config --global user.email "tu@email.com"

# Rama por defecto
git config --global init.defaultBranch main

# Editor para mensajes de commit
git config --global core.editor "code --wait"

# Colores en output
git config --global color.ui auto

# Alias utiles (opcional)
git config --global alias.lg "log --oneline --graph --all"
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch

# Ver toda la configuracion
git config --list
git config --list --show-origin  # muestra de que archivo viene
```

### Archivos de Configuracion (prioridad)

1. **Local**: `.git/config` del repo (solo ese repo)
2. **Global**: `~/.gitconfig` (todos los repos del usuario)
3. **Sistema**: `/etc/gitconfig` (todos los usuarios)

## Comandos Esenciales

```bash
# ── Crear repositorio ──
git init                          # Iniciar repo nuevo
git clone <url>                   # Clonar repo existente
git clone <url> <carpeta>         # Clonar en carpeta especifica

# ── Ver estado ──
git status                        # Estado del working dir + staging
git status -s                     # Formato corto
git log                           # Historial de commits
git log --oneline --graph --all   # Vista compacta con ramas
git log -3                        # Ultimos 3 commits
git diff                          # Cambios no staged
git diff --staged                 # Cambios en staging
git show <commit>                 # Ver detalle de un commit

# ── Flujo basico ──
git add <archivo>                 # Agregar al staging
git add .                         # Agregar todo (nuevos + modificados)
git add -A                        # Agregar todo (incluye eliminados)
git add -p                        # Agregar por partes (interactivo)
git commit -m "mensaje"           # Commit con mensaje inline
git commit                        # Abre editor para mensaje largo
git commit -a -m "mensaje"        # add + commit en uno (solo tracked)

# ── Sincronizar remoto ──
git push origin main              # Subir cambios
git push -u origin main           # Push + set upstream
git pull origin main              # Bajar cambios (fetch + merge)
git fetch origin                  # Solo bajar sin fusionar

# ── Deshacer cambios ──
git restore <archivo>              # Descartar cambios en working dir
git restore --staged <archivo>     # Sacar del staging (keep changes)
git reset --soft HEAD~1            # Deshacer commit (keep changes)
git reset --hard HEAD~1            # Borrar commit y cambios (peligroso)
git revert <commit>                # Crear commit inverso (seguro)
```

## El Modelo de Objetos de Git

Git almacena todo como objetos en `.git/objects/`:

| Tipo | Contenido | Ejemplo |
|------|-----------|---------|
| **blob** | Contenido de un archivo | `echo "hola" | git hash-object --stdin` |
| **tree** | Directorio (lista de blobs + trees) | `git ls-tree HEAD` |
| **commit** | Snapshot con metadata | `git cat-file -p HEAD` |
| **tag** | Referencia con nombre a un commit | `git tag -a v1.0 -m "version 1"` |

Cada objeto se identifica por su hash SHA-1 (40 caracteres hex).

```bash
# Explorar objetos
git rev-parse HEAD                 # Hash del ultimo commit
git cat-file -t HEAD               # Tipo de objeto
git cat-file -p HEAD               # Contenido del objeto
```

## Recursos

- [Git Handbook](https://guides.github.com/introduction/git-handbook/)
- [Git Cheat Sheet](https://education.github.com/git-cheat-sheet-education.pdf)
- [Pro Git Book (gratis)](https://git-scm.com/book/es/v2)
- [Learn Git Branching (interactivo)](https://learngitbranching.js.org/?locale=es_ES)

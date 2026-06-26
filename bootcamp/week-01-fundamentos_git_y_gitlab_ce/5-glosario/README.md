# 📖 Glosario — Semana 01: Git y GitLab CE

## 🔤 Índice Alfabético

[B](#b) · [C](#c) · [D](#d) · [F](#f) · [G](#g) · [H](#h) · [M](#m) · [P](#p) · [R](#r) · [S](#s) · [T](#t) · [W](#w)

---

## B

### Branch (Rama)

**Definición**: Un puntero móvil a un commit específico en el historial de Git. Crear una rama no copia archivos — solo crea un archivo de 41 bytes en `.git/refs/heads/` con el hash del commit al que apunta. Cuando haces un nuevo commit en la rama, el puntero se mueve automáticamente al nuevo commit.

**Ejemplo de código**:
```bash
# Crear una rama y cambiar a ella
git switch -c feature/login

# Listar todas las ramas (local y remota)
git branch -a

# Ver a qué commit apunta cada rama
git branch -v
```

**Relacionados**: [Commit](#commit), [HEAD](#head), [Merge](#merge), [Remote](#remote)

---

## C

### Clone

**Definición**: Operación que crea una copia completa de un repositorio remoto en tu máquina local. No solo copia los archivos actuales — descarga todo el historial de commits, todas las ramas y todos los tags. El repositorio clonado tiene una referencia automática al original llamada `origin`.

**Ejemplo de código**:
```bash
# Clonar vía SSH (recomendado para GitLab CE con Docker)
git clone ssh://git@localhost:2224/root/mi-proyecto.git

# Clonar en una carpeta con nombre diferente
git clone ssh://git@localhost:2224/root/mi-proyecto.git mi-carpeta-local

# Clonar vía HTTP
git clone http://localhost/root/mi-proyecto.git
```

**Relacionados**: [Remote](#remote), [Repository](#repository)

---

### Commit

**Definición**: Un snapshot (fotografía) permanente del estado del proyecto en un momento específico. Cada commit tiene: un hash SHA-1 único de 40 caracteres, el autor, la fecha, el mensaje descriptivo y referencias a su(s) commit(s) padre(s). Los commits forman una cadena inmutable que es el historial del proyecto.

**Ejemplo de código**:
```bash
# Crear un commit con mensaje inline
git commit -m "feat: implementar login de usuarios"

# Ver el detalle de un commit específico
git show a1b2c3d

# Ver el objeto commit internamente
git cat-file -p HEAD
```

**Relacionados**: [Staging Area](#staging-area), [HEAD](#head), [Branch](#branch)

---

### Conflict (Conflicto)

**Definición**: Situación en la que Git no puede fusionar automáticamente dos cambios porque ambos modificaron el mismo lugar en el mismo archivo. Git detiene el merge y marca el archivo con marcadores especiales (`<<<<<<<`, `=======`, `>>>>>>>`). El desarrollador debe resolver el conflicto manualmente y completar el merge.

**Ejemplo de código**:
```bash
# Cuando hay conflicto, git status muestra:
# both modified: config.txt

# El archivo con conflicto contiene:
# <<<<<<< HEAD
# Versión de la rama actual
# =======
# Versión de la rama que se está fusionando
# >>>>>>> feature/rama-b

# Después de editar y resolver:
git add config.txt
git commit   # completa el merge
```

**Relacionados**: [Merge](#merge), [Diff](#diff), [Branch](#branch)

---

### Conventional Commits

**Definición**: Especificación para escribir mensajes de commit estructurados que siguen el formato `tipo[alcance]: descripción`. Permite generar changelogs automáticos y versiones semánticas. Los tipos más comunes son: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`, `style`.

**Ejemplo de código**:
```bash
# Formato básico
git commit -m "feat: agregar autenticación OAuth"
git commit -m "fix: corregir error 500 en endpoint /login"
git commit -m "docs: actualizar README con instrucciones SSH"

# Con alcance (scope)
git commit -m "feat(auth): implementar login con GitLab OAuth"

# Con breaking change
git commit -m "feat!: cambiar formato de respuesta API

BREAKING CHANGE: El campo 'user_id' se renombra a 'userId'"
```

**Relacionados**: [Commit](#commit)

---

## D

### DevOps

**Definición**: Conjunto de prácticas, herramientas y cultura organizacional que integra el desarrollo de software (Dev) con la operación de sistemas (Ops). El objetivo es acelerar el ciclo de vida de desarrollo: planificar → codificar → construir → probar → lanzar → desplegar → operar → monitorear. GitLab CE es una plataforma que soporta todo este ciclo.

**Ejemplo de código**:
```yaml
# El ciclo DevOps en GitLab se refleja en .gitlab-ci.yml
stages:
  - build    # Construir
  - test     # Probar
  - deploy   # Desplegar
```

**Relacionados**: [Pipeline](#pipeline), [GitLab CE](#gitlab-ce)

---

### Diff

**Definición**: La diferencia entre dos versiones de un archivo o del repositorio. Git puede mostrar diffs entre el working directory y el staging, entre el staging y el último commit, entre dos commits, o entre dos ramas. El formato usa `+` para líneas agregadas (verde) y `-` para líneas eliminadas (rojo).

**Ejemplo de código**:
```bash
# Diferencias en working directory (sin staged)
git diff

# Diferencias en staging (lo que va al próximo commit)
git diff --staged

# Diferencias entre dos commits
git diff a1b2c3d e4f5g6h

# Diferencias entre dos ramas
git diff main feature/login
```

**Relacionados**: [Staging Area](#staging-area), [Commit](#commit)

---

## F

### Fetch

**Definición**: Operación que descarga todos los cambios del repositorio remoto (nuevos commits, ramas, tags) pero **sin aplicarlos** a tu rama local. Después de un fetch, puedes ver los cambios remotos con `git log origin/main` antes de decidir si hacer merge o rebase.

**Ejemplo de código**:
```bash
# Descargar cambios de todos los remotos
git fetch origin

# Ver qué hay en el remoto después del fetch
git log origin/main --oneline

# Comparar tu main con el remoto
git diff main origin/main

# Ahora sí fusionar (opcional, ya que tienes la info)
git merge origin/main
```

**Relacionados**: [Pull](#pull), [Remote](#remote)

---

### Fork

**Definición**: Copia de un repositorio en otro espacio de nombres (otro usuario o grupo) dentro de GitLab. A diferencia de un clone (que copia en tu máquina), un fork crea una copia en el servidor. Los forks se usan para contribuir a proyectos donde no tienes permisos de escritura directa.

**Ejemplo de código**:
```bash
# Después de hacer fork en GitLab (vía UI), clonas tu fork:
git clone ssh://git@localhost:2224/mi-usuario/proyecto-forkeado.git

# Agregar el repositorio original como remoto "upstream"
git remote add upstream ssh://git@localhost:2224/autor-original/proyecto.git

# Sincronizar tu fork con el original
git fetch upstream
git merge upstream/main
git push origin main
```

**Relacionados**: [Clone](#clone), [Remote](#remote), [Merge Request](#merge-request)

---

## G

### .gitignore

**Definición**: Archivo de texto en la raíz del repositorio que lista los patrones de archivos y directorios que Git debe ignorar (no rastrear). Los patrones usan globbing: `*` para cualquier carácter, `**` para cualquier directorio, `!` para excepciones. Los archivos ya rastreados por Git NO son ignorados aunque estén en `.gitignore`.

**Ejemplo de código**:
```gitignore
# Sistema operativo
.DS_Store
Thumbs.db

# Dependencias
node_modules/
__pycache__/

# Archivos de entorno (NUNCA subir a Git)
.env
.env.local

# Logs
*.log
logs/

# Excepción: sí rastrear este log específico
!important.log

# Directorio temporal
temp/
```

**Relacionados**: [Repository](#repository), [Staging Area](#staging-area)

---

### GitLab CE

**Definición**: GitLab Community Edition. La versión gratuita y de código abierto (licencia MIT) de la plataforma DevOps de GitLab. Incluye repositorios Git, CI/CD, Container Registry, Package Registry, Issues, Merge Requests, Wiki y más — todo integrado en una sola aplicación que puedes ejecutar en tu propio servidor. En este bootcamp se ejecuta en Docker.

**Ejemplo de código**:
```bash
# Verificar que GitLab CE está corriendo en Docker
docker compose ps gitlab

# Acceder a GitLab CE
# Navegador: http://localhost

# Verificar la versión instalada
docker compose exec gitlab gitlab-rake gitlab:env:info | grep "GitLab information" -A 5
```

**Relacionados**: [DevOps](#devops), [Pipeline](#pipeline), [Merge Request](#merge-request)

---

### GitLab Runner

**Definición**: Agente ligero que ejecuta los jobs de CI/CD definidos en `.gitlab-ci.yml`. Se registra con GitLab usando un token (`glrt-XXXX`, no el registration token obsoleto de versiones anteriores a GitLab 17.0). Puede ejecutar jobs en Docker, máquinas virtuales, Kubernetes, o directamente en el shell.

**Ejemplo de código**:
```bash
# Registrar un runner con el token de GitLab 17.x
gitlab-runner register \
  --url http://localhost \
  --token glrt-XXXXXXXXXX \
  --executor docker \
  --docker-image alpine:latest \
  --description "mi-runner-docker"

# Ver los runners registrados
gitlab-runner list

# Ver el estado del runner
gitlab-runner status
```

**Relacionados**: [Pipeline](#pipeline), [GitLab CE](#gitlab-ce)

---

## H

### HEAD

**Definición**: Referencia especial que apunta a la posición actual en el historial de Git. Normalmente, HEAD apunta a la rama actual (y la rama apunta al último commit). Cuando haces un `git checkout <hash-commit>` directamente, HEAD queda en "detached" (desconectado), sin apuntar a ninguna rama.

**Ejemplo de código**:
```bash
# Ver a dónde apunta HEAD
cat .git/HEAD
# Output: ref: refs/heads/main   (HEAD → main → último commit)

# Ver el hash del commit al que apunta HEAD
git rev-parse HEAD

# Referencia a commits relativos a HEAD
HEAD~1  # El commit anterior
HEAD~2  # Dos commits atrás
HEAD^   # El padre (equivalente a HEAD~1)
```

**Relacionados**: [Branch](#branch), [Commit](#commit)

---

## M

### Merge

**Definición**: Operación que combina el historial de una rama en otra. Existen dos tipos principales: **fast-forward** (cuando la rama destino no avanzó — solo mueve el puntero) y **three-way merge** (cuando ambas ramas divergieron — crea un "merge commit" con dos padres). En GitLab, el merge típicamente se hace a través de una Merge Request.

**Ejemplo de código**:
```bash
# Fast-forward merge (main no ha avanzado desde que creaste feature)
git switch main
git merge feature/login
# Git simplemente mueve el puntero de main

# Three-way merge (ambas ramas avanzaron)
git switch main
git merge feature/login
# Git crea un "merge commit" con dos padres

# Siempre crear merge commit (no fast-forward)
git merge --no-ff feature/login

# Cancelar un merge en conflicto
git merge --abort
```

**Relacionados**: [Branch](#branch), [Conflict](#conflict), [Merge Request](#merge-request), [Rebase](#rebase)

---

### Merge Request (MR)

**Definición**: Mecanismo de GitLab para proponer que los cambios de una rama se fusionen en otra. Equivalente al "Pull Request" de GitHub. Una MR incluye: el diff de los cambios, comentarios y revisiones de código, aprobaciones, y la opción de fusionar. Es el mecanismo principal de revisión de código colaborativa en GitLab.

**Ejemplo de código**:
```bash
# Flujo para crear una MR desde la terminal
# 1. Crear y subir la rama con los cambios
git switch -c feature/nueva-funcionalidad
# ... hacer cambios y commits ...
git push -u origin feature/nueva-funcionalidad

# 2. GitLab muestra un enlace para crear la MR:
# remote: To create a merge request for feature/nueva-funcionalidad, visit:
# remote:   http://localhost/root/proyecto/-/merge_requests/new?...

# 3. Después del merge, limpiar
git switch main
git pull origin main
git branch -d feature/nueva-funcionalidad
```

**Relacionados**: [Merge](#merge), [Branch](#branch), [GitLab CE](#gitlab-ce)

---

## P

### Pipeline

**Definición**: Secuencia automatizada de stages y jobs que se ejecutan cuando hay un evento en GitLab (push, merge, schedule, etc.). Se define en el archivo `.gitlab-ci.yml` en la raíz del repositorio. Un pipeline puede tener múltiples stages (build, test, deploy) con múltiples jobs por stage. GitLab Runner ejecuta los jobs.

**Ejemplo de código**:
```yaml
# .gitlab-ci.yml — Pipeline básico
stages:
  - build
  - test
  - deploy

compilar:
  stage: build
  script:
    - echo "Compilando el proyecto..."
    - make build

pruebas-unitarias:
  stage: test
  script:
    - echo "Ejecutando tests..."
    - make test

desplegar-staging:
  stage: deploy
  script:
    - echo "Desplegando a staging..."
  only:
    - main
```

**Relacionados**: [GitLab CE](#gitlab-ce), [GitLab Runner](#gitlab-runner), [DevOps](#devops)

---

### Pull

**Definición**: Operación que descarga los cambios del repositorio remoto Y los aplica a la rama local actual. Es equivalente a ejecutar `git fetch` + `git merge` en secuencia. Si hay cambios en ambos lados (local y remoto), puede generar conflictos que hay que resolver manualmente.

**Ejemplo de código**:
```bash
# Traer y aplicar cambios del remoto
git pull origin main

# Equivalente manual (más control)
git fetch origin
git merge origin/main

# Pull con rebase en lugar de merge (historial más limpio)
git pull --rebase origin main

# Configurar pull para usar rebase por defecto
git config --global pull.rebase true
```

**Relacionados**: [Fetch](#fetch), [Push](#push), [Remote](#remote), [Merge](#merge)

---

### Push

**Definición**: Operación que sube los commits locales al repositorio remoto. Solo funciona si tus commits están "adelante" del remoto (no hay commits remotos que no tengas localmente). Si el remoto tiene commits más nuevos, debes hacer `pull` primero.

**Ejemplo de código**:
```bash
# Subir la rama main al remoto
git push origin main

# Primera vez que subes una rama (establece el upstream)
git push -u origin feature/login

# Después de establecer upstream, basta con:
git push

# Subir todos los tags locales al remoto
git push --tags

# Eliminar una rama remota
git push origin --delete feature/login-eliminada
```

**Relacionados**: [Pull](#pull), [Remote](#remote), [Branch](#branch)

---

## R

### Rebase

**Definición**: Operación que "mueve" los commits de una rama para que parezca que se empezaron desde un punto diferente del historial. Técnicamente, reescribe los commits con nuevos hashes. Produce un historial lineal y limpio. **Regla de oro**: nunca rebasear commits que ya están publicados en un remoto compartido, porque reescribir su historial confunde a otros colaboradores.

**Ejemplo de código**:
```bash
# Rebasar feature sobre la punta actual de main
git switch feature/login
git rebase main

# Rebase interactivo: reorganizar, combinar o editar commits
git rebase -i HEAD~3  # Rebasar los últimos 3 commits interactivamente

# Si hay conflictos durante el rebase:
git rebase --continue   # Después de resolver el conflicto
git rebase --abort      # Cancelar y volver al estado anterior
```

**Relacionados**: [Merge](#merge), [Commit](#commit), [Branch](#branch)

---

### Remote

**Definición**: Referencia a un repositorio Git en otra ubicación (normalmente un servidor). El remoto más común se llama `origin` y apunta al repositorio del que se hizo clone. Puedes tener múltiples remotos (ej: `origin` para tu fork y `upstream` para el repositorio original).

**Ejemplo de código**:
```bash
# Ver los remotos configurados
git remote -v

# Agregar un nuevo remoto
git remote add origin ssh://git@localhost:2224/root/mi-proyecto.git

# Cambiar la URL de un remoto existente
git remote set-url origin ssh://git@localhost:2224/root/mi-proyecto.git

# Eliminar un remoto
git remote remove upstream
```

**Relacionados**: [Clone](#clone), [Push](#push), [Fetch](#fetch)

---

### Repository (Repositorio)

**Definición**: Directorio que contiene todos los archivos del proyecto más la carpeta oculta `.git/` donde Git guarda todo el historial, los objetos, las referencias y la configuración. Un repositorio puede ser **local** (en tu máquina) o **remoto** (en GitLab CE). Clonar un repositorio crea una copia local completa del repositorio remoto.

**Ejemplo de código**:
```bash
# Inicializar un repositorio en la carpeta actual
git init

# Ver el directorio .git/ (no lo toques directamente)
ls -la .git/
# refs/      — punteros a commits (ramas, tags)
# objects/   — todos los objetos Git (blobs, trees, commits)
# HEAD       — referencia a la rama/commit actual
# config     — configuración del repositorio

# Ver cuántos objetos tiene el repositorio
git count-objects -v
```

**Relacionados**: [Clone](#clone), [Commit](#commit), [Remote](#remote)

---

## S

### Staging Area

**Definición**: Área intermedia (también llamada "índice" o "index") entre el Working Directory y el repositorio. Los archivos se agregan al staging con `git add`. Solo los archivos en staging se incluyen en el próximo commit. Esto permite hacer commits precisos con un solo propósito, incluso si tienes múltiples cambios en tu working directory.

**Ejemplo de código**:
```bash
# Agregar un archivo al staging
git add archivo.txt

# Ver qué hay en staging
git diff --staged

# Sacar un archivo del staging (mantiene los cambios en el archivo)
git restore --staged archivo.txt

# Agregar solo partes de un archivo (modo interactivo)
git add -p archivo.txt
```

**Relacionados**: [Working Directory](#working-directory), [Commit](#commit), [Diff](#diff)

---

### Stash

**Definición**: Mecanismo para guardar temporalmente los cambios del working directory y staging sin hacer un commit. El stash es como una pila (LIFO): puedes guardar múltiples "estados" y recuperarlos en cualquier orden. Ideal para cambiar de contexto urgentemente sin perder trabajo a medio terminar.

**Ejemplo de código**:
```bash
# Guardar los cambios actuales en el stash
git stash

# Guardar con una descripción
git stash push -m "WIP: formulario de login sin validar"

# Ver la lista de stashes
git stash list
# stash@{0}: WIP: formulario de login sin validar
# stash@{1}: WIP on main: abc1234 feat: ...

# Recuperar el último stash (lo aplica y elimina de la lista)
git stash pop

# Recuperar un stash específico sin eliminarlo
git stash apply stash@{1}

# Eliminar todos los stashes
git stash clear
```

**Relacionados**: [Working Directory](#working-directory), [Branch](#branch)

---

## T

### Tag

**Definición**: Referencia nombrada a un commit específico, usada para marcar versiones o hitos importantes. A diferencia de las ramas, los tags no se mueven cuando haces nuevos commits. Existen tags **ligeros** (solo un puntero) y tags **anotados** (con metadata: autor, fecha, mensaje y firma GPG opcional).

**Ejemplo de código**:
```bash
# Crear un tag ligero
git tag v1.0.0

# Crear un tag anotado (recomendado para releases)
git tag -a v1.0.0 -m "Versión 1.0.0 — Primera release estable"

# Ver todos los tags
git tag

# Ver el detalle de un tag anotado
git show v1.0.0

# Subir un tag específico al remoto
git push origin v1.0.0

# Subir todos los tags al remoto
git push --tags
```

**Relacionados**: [Commit](#commit), [Repository](#repository)

---

## W

### Working Directory

**Definición**: El directorio de trabajo donde están los archivos del proyecto en su estado actual. Es la "vista" de los archivos que ves y editas normalmente. Los cambios en el working directory no son rastreados por Git hasta que los agregas al Staging Area con `git add`. Un archivo en el working directory puede estar en uno de estos estados: untracked, modified, o sin cambios (igual al último commit).

**Ejemplo de código**:
```bash
# Ver el estado de los archivos en el working directory
git status

# Ver las diferencias en el working directory respecto al staging
git diff

# Descartar cambios en un archivo (regresa al último commit)
git restore archivo.txt

# Descartar TODOS los cambios no staged (peligroso)
git restore .
```

**Relacionados**: [Staging Area](#staging-area), [Commit](#commit), [Diff](#diff)

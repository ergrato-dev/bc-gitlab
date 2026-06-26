# 📖 01 — Git: Comandos Esenciales

## 🎯 Objetivos de Aprendizaje

Al finalizar esta lección serás capaz de:

- Explicar qué es Git y por qué es fundamental en DevOps
- Describir los tres estados de un archivo en Git y las transiciones entre ellos
- Ejecutar el flujo completo: `init` → `add` → `commit` → `push` → `pull`
- Escribir mensajes de commit siguiendo la convención *Conventional Commits*
- Interpretar la salida de `git status`, `git log` y `git diff`

---

## 📖 ¿Qué es Git?

**Analogía**: Imagina que Git es un fotógrafo personal de tu proyecto. Cada vez que ejecutas `git commit` le dices "tómate una foto ahora mismo". Git guarda esa foto (llamada *snapshot*) para siempre. Si algo sale mal, puedes pedir "muéstrame la foto del martes pasado" y Git te devuelve el proyecto exactamente como estaba.

A diferencia de guardar archivos con nombres como `proyecto_v2_FINAL_ok_este_si.zip`, Git lleva un historial completo, con autor, fecha y descripción de cada cambio.

**Datos clave**:
- Creado por Linus Torvalds en 2005 para gestionar el kernel de Linux
- Sistema **distribuido**: cada copia del repo es un repo completo con toda la historia
- Estándar de facto en la industria; GitLab, GitHub y Bitbucket se construyen sobre Git
- Velocidad extrema: crear una rama tarda milisegundos (solo escribe 41 bytes en disco)

### 🤔 ¿Por qué Git en DevOps?

| Beneficio | Qué significa en práctica |
|-----------|--------------------------|
| **Trazabilidad** | Cada cambio tiene autor, fecha y motivo |
| **Colaboración** | Múltiples personas trabajan sin pisarse |
| **CI/CD** | Los pipelines se disparan con eventos Git (push, merge) |
| **IaC** | Toda la infraestructura como código está versionada |
| **Rollback** | Volver a cualquier estado anterior en segundos |

---

## 🗂️ Los Tres Estados de un Archivo

Todo archivo en un repositorio Git vive en uno de tres estados. Entender esto es la clave para no confundirse con Git:

```
┌──────────────────┐   git add    ┌──────────────────┐  git commit  ┌──────────────────┐
│  Working         │ ──────────▶  │  Staging Area    │ ───────────▶ │  Git Repository  │
│  Directory       │              │  (Index)         │              │  (historial)     │
│                  │              │                  │              │                  │
│  Tus archivos    │              │  Preparados para │              │  Commits         │
│  (modificados)   │              │  el próximo      │              │  permanentes     │
│                  │              │  commit          │              │  (SHA-1)         │
└──────────────────┘              └──────────────────┘              └──────────────────┘
         ▲                                │                                  │
         │                               │ git restore --staged              │
         │◀──────────────────────────────┘                                  │
         │                                                                   │
         │◀──────────────────── git restore / git checkout ─────────────────┘
```

| Estado | Color en `git status` | Descripción |
|--------|-----------------------|-------------|
| **Untracked** | Rojo (sin símbolo) | Git nunca ha visto este archivo |
| **Modified** | Rojo (M) | Conocido por Git pero con cambios sin preparar |
| **Staged** | Verde (A o M) | Preparado y listo para el próximo commit |
| **Committed** | (no aparece) | Guardado en el historial permanentemente |

---

## 🛠️ Comandos Esenciales

### Crear o Clonar un Repositorio

```bash
# ¿QUÉ VAMOS A HACER?: Inicializar un repositorio Git en la carpeta actual
# ¿POR QUÉ LO HACEMOS?: Para que Git empiece a rastrear todos los cambios aquí
# ¿PARA QUÉ SIRVE?: Punto de partida de cualquier proyecto nuevo versionado con Git
git init

# ¿QUÉ VAMOS A HACER?: Descargar una copia completa de un repositorio remoto
# ¿POR QUÉ LO HACEMOS?: Para obtener el historial completo y trabajar localmente
# ¿PARA QUÉ SIRVE?: Unirte a un proyecto existente o empezar desde una plantilla
git clone <url>

# Clonar en una carpeta con nombre diferente
git clone <url> nombre-carpeta

# Clonar vía SSH con puerto personalizado (GitLab CE en Docker usa el puerto 2224)
git clone ssh://git@localhost:2224/root/mi-proyecto.git
```

> 💡 **Puerto 2224**: Nuestro GitLab CE en Docker escucha SSH en el puerto 2224 (no el 22 estándar). Siempre usa esta forma de URL o configura `~/.ssh/config` para evitar escribirlo cada vez.

---

### Inspeccionar el Estado

```bash
# ¿QUÉ VAMOS A HACER?: Ver el estado actual del working directory y staging area
# ¿POR QUÉ LO HACEMOS?: Para saber exactamente qué cambios hay antes de un commit
# ¿PARA QUÉ SIRVE?: Es el comando que más usarás; ejecútalo antes de cada commit
git status

# Formato corto (una línea por archivo)
# M = modificado, A = added/staged, ?? = untracked, D = eliminado
git status -s

# ¿QUÉ VAMOS A HACER?: Ver el historial completo de commits del repositorio
# ¿POR QUÉ LO HACEMOS?: Para entender qué cambios se hicieron, cuándo y por quién
# ¿PARA QUÉ SIRVE?: Auditoría, depuración, encontrar el commit que introdujo un bug
git log

# Vista compacta y visual con el árbol de ramas (alias muy útil — agrégalo a tu config)
git log --oneline --graph --all

# Solo los últimos 5 commits
git log -5

# ¿QUÉ VAMOS A HACER?: Mostrar las diferencias entre el working directory y el staging
# ¿POR QUÉ LO HACEMOS?: Para revisar exactamente qué cambié antes de hacer git add
# ¿PARA QUÉ SIRVE?: Evitar subir cambios accidentales, contraseñas o código incompleto
git diff

# Diferencias de lo que está en staging (lo que iría en el próximo commit)
git diff --staged

# Ver todos los cambios de un commit específico
git show <hash-del-commit>
```

---

### El Flujo Básico: Add → Commit

```bash
# ¿QUÉ VAMOS A HACER?: Agregar un archivo específico al staging area
# ¿POR QUÉ LO HACEMOS?: Para decirle a Git "este archivo sí va en el próximo commit"
# ¿PARA QUÉ SIRVE?: Permite commits precisos con un solo propósito cada uno
git add README.md

# Agregar todos los archivos nuevos y modificados del directorio actual
git add .

# Agregar todo incluyendo eliminaciones explícitas
git add -A

# ¿QUÉ VAMOS A HACER?: Agregar cambios de forma interactiva, trozo por trozo
# ¿POR QUÉ LO HACEMOS?: Para hacer commits granulares cuando editamos varios temas en un archivo
# ¿PARA QUÉ SIRVE?: Historial limpio con commits coherentes (un commit = un propósito)
git add -p

# ¿QUÉ VAMOS A HACER?: Guardar el snapshot del staging area como un commit permanente
# ¿POR QUÉ LO HACEMOS?: Para preservar este estado en el historial para siempre
# ¿PARA QUÉ SIRVE?: Cada commit es un punto de restauración al que puedes volver
git commit -m "feat: agregar página de inicio"

# Commit abriendo el editor configurado (para mensajes con cuerpo explicativo)
git commit

# add + commit en un solo paso (solo para archivos ya rastreados por Git)
git commit -a -m "fix: corregir typo en README"
```

---

### Configuración Inicial

```bash
# ¿QUÉ VAMOS A HACER?: Configurar la identidad que aparece en cada commit
# ¿POR QUÉ LO HACEMOS?: Git requiere nombre y email para saber quién hizo cada cambio
# ¿PARA QUÉ SIRVE?: Trazabilidad — saber quién modificó cada línea del código
git config --global user.name "Tu Nombre Completo"
git config --global user.email "tu@email.com"

# Configurar rama por defecto al hacer git init
git config --global init.defaultBranch main

# Configurar el editor para mensajes de commit (VS Code)
git config --global core.editor "code --wait"

# Habilitar colores en la salida de Git
git config --global color.ui auto

# Alias útiles para el día a día
git config --global alias.lg "log --oneline --graph --all"
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch

# Ver toda la configuración activa
git config --list

# Ver de qué archivo viene cada configuración (local/global/sistema)
git config --list --show-origin
```

**Prioridad de configuración** (de mayor a menor):
1. **Local** → `.git/config` del repo (solo afecta ese repo)
2. **Global** → `~/.gitconfig` (todos los repos del usuario)
3. **Sistema** → `/etc/gitconfig` (todos los usuarios de la máquina)

---

### Sincronizar con el Repositorio Remoto

```bash
# ¿QUÉ VAMOS A HACER?: Subir los commits locales al repositorio remoto
# ¿POR QUÉ LO HACEMOS?: Para compartir nuestros cambios con el equipo o hacer respaldo
# ¿PARA QUÉ SIRVE?: Colaboración, CI/CD (GitLab ejecuta pipelines al hacer push)
git push origin main

# Primera vez que subes una rama nueva: establece el upstream y hace push
git push -u origin main

# ¿QUÉ VAMOS A HACER?: Descargar y aplicar cambios del remoto a la rama actual
# ¿POR QUÉ LO HACEMOS?: Para integrar el trabajo de los demás con el nuestro
# ¿PARA QUÉ SIRVE?: Mantener tu copia local actualizada antes de empezar a trabajar
git pull origin main

# ¿QUÉ VAMOS A HACER?: Solo descargar cambios del remoto SIN aplicarlos
# ¿POR QUÉ LO HACEMOS?: Para ver qué hay en el remoto antes de decidir cómo integrar
# ¿PARA QUÉ SIRVE?: Inspeccionar cambios remotos de forma segura antes de fusionarlos
git fetch origin
```

---

### Deshacer Cambios

```bash
# Descartar cambios en working directory (regresa al último commit)
git restore <archivo>

# Sacar un archivo del staging pero conservar los cambios en working dir
git restore --staged <archivo>

# Deshacer el último commit manteniendo los cambios en staging
git reset --soft HEAD~1

# ⚠️  PELIGROSO: Borrar el último commit Y los cambios (prácticamente irrecuperable)
git reset --hard HEAD~1

# ✅ SEGURO: Revertir un commit creando uno nuevo inverso (ideal para ramas compartidas)
git revert <hash-del-commit>
```

---

## 🔄 El Flujo de Trabajo Completo

```
  Tu computadora                          GitLab CE (Docker: http://localhost)
  ──────────────────────────────────      ────────────────────────────────────

  Archivos en disco
  (Working Directory)
       │
       │ git add
       ▼
  Staging Area (Index)
       │
       │ git commit
       ▼
  Repositorio Local (.git/)
       │                                       Repositorio Remoto
       │ git push ──────────────────────────▶  (origin/main)
       │                                            │
       │ git pull ◀─────────────────────────────────┘
       │   (= fetch + merge)
       ▼
  Working Directory actualizado
```

**Flujo diario típico**:

```bash
# 1. Al empezar el día: sincronizar con el remoto
git pull origin main

# 2. Hacer cambios... editar archivos, agregar features...

# 3. Ver qué cambié (ejecutar varias veces durante el trabajo)
git status
git diff

# 4. Preparar el commit (seleccionar qué va)
git add README.md src/login.js

# 5. Verificar que el staging tiene lo correcto
git diff --staged

# 6. Crear el commit
git commit -m "feat: implementar login de usuarios"

# 7. Subir al remoto (activa los pipelines en GitLab)
git push origin main
```

---

## 📋 Conventional Commits

Conventional Commits es una especificación para mensajes de commit estructurados. GitLab puede generar changelogs automáticos y calcular versiones semánticas (SemVer) a partir de ellos.

**Formato**:
```
<tipo>[alcance opcional]: <descripción breve en imperativo>

[cuerpo opcional: qué y por qué, no cómo]

[pie: BREAKING CHANGE, referencias a issues]
```

**Tipos más usados**:

| Tipo | Cuándo usarlo | Ejemplo |
|------|---------------|---------|
| `feat` | Nueva funcionalidad | `feat: agregar autenticación OAuth` |
| `fix` | Corrección de bug | `fix: resolver error 500 en login` |
| `docs` | Solo documentación | `docs: actualizar guía de instalación` |
| `chore` | Mantenimiento sin código productivo | `chore: actualizar dependencias npm` |
| `refactor` | Refactorización (no bug fix, no feature) | `refactor: extraer servicio de email` |
| `test` | Agregar o corregir tests | `test: agregar tests unitarios de auth` |
| `ci` | Cambios en pipelines CI/CD | `ci: agregar stage de linting` |
| `style` | Formato, espacios (sin cambio de lógica) | `style: aplicar prettier al proyecto` |

```bash
# Ejemplos de commits bien escritos
git commit -m "feat(auth): implementar login con GitLab OAuth"
git commit -m "fix(api): corregir timeout en endpoint /users"
git commit -m "docs: agregar sección SSH al README"
git commit -m "chore: actualizar gitlab-ci.yml a versión 17"

# Commit con cuerpo explicativo (abre el editor)
git commit
# Dentro del editor escribir:
# feat: agregar soporte multi-idioma
#
# Implementa i18n para español e inglés.
# Los textos se cargan desde archivos JSON en src/locales/.
# Esta implementación sigue el estándar i18next.
#
# Closes #42
```

> 💡 **Tip**: Escribe el mensaje en imperativo presente: "agregar" no "agregué", "corregir" no "corregí". Piensa "este commit **hace** X".

---

## 🤔 Preguntas de Reflexión

1. ¿Cuál es la diferencia entre `git fetch` y `git pull`? ¿Cuándo preferirías usar uno sobre el otro?
2. Si haces `git add .` y luego te arrepientes de incluir un archivo, ¿cómo lo sacas del staging sin perder tus cambios?
3. Un compañero hizo push a `main` mientras tú trabajabas localmente. ¿Qué comandos ejecutas para integrar sus cambios con los tuyos?
4. ¿Por qué `git reset --hard` es peligroso? ¿Cuándo sería apropiado usarlo vs `git revert`?
5. Mira el historial de commits de un proyecto real en GitLab. ¿Siguen Conventional Commits? ¿Qué mejorarías en sus mensajes?

---

## 📚 Recursos Adicionales

- [Pro Git Book en Español](https://git-scm.com/book/es/v2) — Referencia completa y gratuita (capítulos 1-3 para esta semana)
- [Conventional Commits](https://www.conventionalcommits.org/es/v1.0.0/) — Especificación oficial
- [Learn Git Branching](https://learngitbranching.js.org/?locale=es_ES) — Práctica visual e interactiva (muy recomendado)
- [Oh Shit, Git!?!](https://ohshitgit.com/es) — Soluciones a los errores más comunes

---

## ➡️ Siguiente Lección

[02 — Git: Ramas, Merge y Rebase →](./02-git-ramas-y-flujos.md)

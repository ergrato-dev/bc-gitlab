# 📖 02 — Git: Ramas, Merge y Rebase

## 🎯 Objetivos de Aprendizaje

Al finalizar esta lección serás capaz de:

- Explicar qué es una rama y cuándo crearla
- Crear, cambiar, fusionar y eliminar ramas con fluidez
- Distinguir entre merge fast-forward y merge de tres vías
- Aplicar rebase con seguridad en ramas locales
- Resolver conflictos de merge paso a paso
- Usar `git stash` para guardar trabajo temporal
- Describir el flujo GitLab Flow y por qué lo usamos en este bootcamp

---

## 📖 ¿Qué es una Rama?

**Analogía**: Imagina que estás escribiendo una novela. La trama principal va en el cuaderno azul (rama `main`). Quieres experimentar con un final alternativo sin arruinar el cuaderno azul, entonces abres un cuaderno rojo (rama `feature/final-alternativo`) y escribes allí. Si el final alternativo queda bien, copias esas páginas al cuaderno azul (merge). Si no, tiras el cuaderno rojo sin afectar nada.

**Técnicamente**: Una rama es simplemente un **puntero móvil** a un commit. Crear una rama no copia ningún archivo; solo escribe un archivo de 41 bytes en `.git/refs/heads/`. Por eso crear ramas en Git es instantáneo.

```
main:     A ─── B ─── C
                        \
feature:                 D ─── E   ← (HEAD apunta aquí si estoy en feature)
```

### ✅ Cuándo Crear una Rama

- Para cada nueva funcionalidad (`feature/login-oauth`)
- Para cada corrección de bug (`fix/error-timeout`)
- Para experimentos que pueden descartarse
- Para trabajar sin interrumpir a los demás en `main`

---

## 🛠️ Comandos de Ramas

```bash
# ¿QUÉ VAMOS A HACER?: Listar todas las ramas locales
# ¿POR QUÉ LO HACEMOS?: Para ver en qué ramas existe trabajo activo
# ¿PARA QUÉ SIRVE?: Orientarse antes de cambiar de rama o hacer merge
git branch

# Listar ramas locales Y remotas
git branch -a

# Listar con información del último commit de cada una
git branch -v

# ¿QUÉ VAMOS A HACER?: Crear una rama nueva y cambiar a ella en un solo paso
# ¿POR QUÉ LO HACEMOS?: Para empezar a trabajar en una funcionalidad de forma aislada
# ¿PARA QUÉ SIRVE?: Evitar commits en main directamente (buena práctica de equipo)
git switch -c feature/mi-funcionalidad

# Forma clásica (equivalente al anterior, más usada en tutoriales antiguos)
git checkout -b feature/mi-funcionalidad

# Cambiar a una rama existente (forma moderna)
git switch main

# Volver a la rama donde estabas antes (el guión = "anterior")
git switch -

# ¿QUÉ VAMOS A HACER?: Eliminar una rama que ya fue fusionada
# ¿POR QUÉ LO HACEMOS?: Para mantener el repositorio limpio
# ¿PARA QUÉ SIRVE?: Higiene del repo — eliminar ramas que ya cumplieron su propósito
git branch -d feature/mi-funcionalidad

# Eliminar rama aunque NO haya sido fusionada (⚠️ pierdes los commits)
git branch -D feature/experimento-fallido

# Renombrar la rama actual
git branch -m nuevo-nombre
```

---

## 🔀 Merge: Fusionar Ramas

El merge integra el trabajo de una rama en otra. Git tiene dos estrategias principales:

### Fast-Forward Merge (sin commit de merge)

Ocurre cuando la rama destino no ha avanzado desde que se creó la rama feature. Git simplemente mueve el puntero hacia adelante.

```
Antes del merge:
  main:    A ─── B
                  \
  feature:         C ─── D

Después de git merge feature (fast-forward):
  main:    A ─── B ─── C ─── D
```

```bash
# ¿QUÉ VAMOS A HACER?: Fusionar la rama feature en main (fast-forward si es posible)
# ¿POR QUÉ LO HACEMOS?: Para integrar el trabajo terminado a la rama principal
# ¿PARA QUÉ SIRVE?: Consolidar cambios aprobados en la rama de producción
git switch main
git merge feature/mi-funcionalidad
```

### Three-Way Merge (con commit de merge)

Ocurre cuando ambas ramas han avanzado desde el punto de divergencia. Git crea un commit especial con dos padres.

```
Antes del merge:
  main:    A ─── B ─── E
                  \
  feature:         C ─── D

Después de git merge feature (three-way):
  main:    A ─── B ─── E ─── M   ← M es el "merge commit" con dos padres
                  \           /
  feature:         C ─── D ──
```

```bash
# Si quieres SIEMPRE crear un merge commit (incluso cuando fast-forward sería posible)
git merge --no-ff feature/mi-funcionalidad

# Útil para preservar la historia de que hubo una rama (visible en git log --graph)
```

---

## 🔄 Rebase: Historial Limpio y Lineal

**Analogía**: Rebase es como si rebobinaras tu trabajo, le pegaras encima los commits nuevos de `main`, y luego volveras a aplicar tus commits uno por uno. El resultado parece que empezaste a trabajar desde el estado más reciente de `main`.

```
Antes del rebase:
  main:    A ─── B ─── E
                  \
  feature:         C ─── D

Después de git rebase main (estando en feature):
  main:    A ─── B ─── E
                         \
  feature:                C' ─── D'   ← commits reescritos (nuevos hashes)
```

```bash
# ¿QUÉ VAMOS A HACER?: Reaplicar los commits de feature sobre la punta de main
# ¿POR QUÉ LO HACEMOS?: Para que el historial quede lineal (sin commits de merge)
# ¿PARA QUÉ SIRVE?: Historial más limpio y fácil de leer (preferido en muchos equipos)
git switch feature/mi-funcionalidad
git rebase main

# Luego en main: fast-forward merge (no crea merge commit)
git switch main
git merge feature/mi-funcionalidad
```

### ⚠️ Regla de Oro del Rebase

> **NUNCA** hagas rebase de commits que ya están en el repositorio remoto y que otros pueden estar usando.

| Situación | Usar |
|-----------|------|
| Rama solo tuya, no pusheada | `git rebase` ✅ |
| Rama compartida o ya en remoto | `git merge` ✅ |
| Rama de MR abierta en GitLab | Consulta con el equipo |

---

## ⚡ Resolución de Conflictos

Un conflicto ocurre cuando Git no puede decidir automáticamente cómo combinar cambios en el mismo lugar de un archivo. No es un error — es información: dos personas modificaron lo mismo.

### Crear un Conflicto (para practicar)

```bash
# Rama A modifica el archivo
git switch -c rama-a
echo "Versión A del archivo" > config.txt
git add config.txt && git commit -m "config: versión A"

# Rama B modifica el mismo archivo
git switch main
git switch -c rama-b
echo "Versión B del archivo" > config.txt
git add config.txt && git commit -m "config: versión B"

# Intentar fusionar → CONFLICTO
git switch main
git merge rama-a   # OK (fast-forward)
git merge rama-b   # ¡CONFLICTO!
```

### Anatomía de un Conflicto

```
<<<<<<< HEAD
Versión A del archivo
=======
Versión B del archivo
>>>>>>> rama-b
```

- `<<<<<<< HEAD`: Lo que hay en tu rama actual (`main`)
- `=======`: Separador
- `>>>>>>> rama-b`: Lo que viene de la rama que estás fusionando

### Resolver el Conflicto Paso a Paso

```bash
# Paso 1: Ver qué archivos tienen conflictos
git status
# (aparecen en rojo con "both modified")

# Paso 2: Abrir el archivo y editar manualmente
# Eliminar los marcadores <<<<<<<, =======, >>>>>>>
# Dejar el contenido final que quieres
nano config.txt   # o abre en tu editor preferido

# Paso 3: Marcar como resuelto
git add config.txt

# Paso 4: Completar el merge
git commit
# Git propone un mensaje automático, puedes aceptarlo

# Si prefieres cancelar el merge y empezar de cero
git merge --abort
```

> 💡 **Tip VS Code**: VS Code detecta conflictos automáticamente y muestra botones "Accept Current Change", "Accept Incoming Change", "Accept Both Changes". Úsalos para resolver más rápido.

---

## 📦 git stash: Guardar Trabajo Temporal

**Analogía**: El stash es como una gaveta donde guardas trabajo a medio terminar cuando de repente necesitas cambiar de tarea urgente.

```bash
# ¿QUÉ VAMOS A HACER?: Guardar los cambios actuales sin hacer commit
# ¿POR QUÉ LO HACEMOS?: Porque necesitamos cambiar de rama pero no queremos perder el trabajo
# ¿PARA QUÉ SIRVE?: Cambiar de contexto sin commits sucios o incompletos
git stash

# Guardar con una descripción para identificarlo después
git stash push -m "WIP: formulario de login sin validar"

# Ver la lista de stashes guardados
git stash list

# Recuperar el último stash (lo aplica y lo elimina de la lista)
git stash pop

# Recuperar un stash específico (lo aplica pero lo mantiene en la lista)
git stash apply stash@{1}

# Eliminar un stash sin aplicarlo
git stash drop stash@{0}

# Eliminar todos los stashes
git stash clear
```

**Flujo típico de uso**:
```bash
# Estoy trabajando en feature/login...
git stash push -m "WIP: login a medias"

# Cambio a main para hotfix urgente
git switch main
# ... arreglo el bug urgente, commit, push ...

# Vuelvo a mi feature
git switch feature/login
git stash pop    # recupero mi trabajo
```

---

## 🌊 GitLab Flow: El Flujo de Este Bootcamp

Existen varios flujos de trabajo con Git (Git Flow, GitHub Flow, Trunk-based). Para este bootcamp usamos **GitLab Flow**, que es el más apropiado cuando trabajamos directamente con GitLab CE.

**Principios de GitLab Flow**:

```
main (siempre desplegable)
  │
  ├─ feature/nueva-funcionalidad  → Merge Request → merge a main
  ├─ fix/bug-critico              → Merge Request → merge a main
  └─ docs/actualizar-readme       → Merge Request → merge a main

Para entornos (opcional en este bootcamp):
  main → production (rama de producción protegida)
```

**Reglas del flujo**:
1. `main` siempre está en estado desplegable
2. Todo trabajo nuevo va en una rama con nombre descriptivo
3. El merge a `main` se hace vía **Merge Request** en GitLab (con revisión de código)
4. Los commits en `main` disparan el pipeline de CI/CD
5. Se usa Conventional Commits para mensajes

**Convención de nombres de ramas**:

```bash
feature/agregar-login         # Nueva funcionalidad
fix/error-validacion-email    # Corrección de bug
docs/actualizar-readme        # Solo documentación
chore/actualizar-dependencias # Mantenimiento
refactor/extraer-servicio     # Refactorización

# Con número de issue (si usas el tracker de GitLab)
feature/42-login-oauth
fix/137-timeout-api
```

---

## 🤔 Preguntas de Reflexión

1. Crea una rama `feature/experimento`, haz dos commits y luego elimínala sin fusionar. ¿Qué le pasó a esos commits? ¿Cómo los recuperarías?
2. ¿Cuál es la diferencia entre un merge fast-forward y un merge de tres vías? ¿Cuándo se usa cada uno?
3. ¿Por qué el rebase "reescribe la historia"? ¿Qué problemas causa si otros ya descargaron esos commits?
4. En tu trabajo actual (o en un proyecto personal), ¿qué flujo de ramas sería más apropiado: GitLab Flow, Git Flow o Trunk-based Development? ¿Por qué?
5. Tienes cambios a medio hacer en `feature/login` y te piden urgentemente revisar un bug en `main`. ¿Cuáles son tus opciones? ¿Cuál preferirías y por qué?

---

## 📚 Recursos Adicionales

- [Pro Git — Capítulo 3: Ramificaciones en Git](https://git-scm.com/book/es/v2/Ramificaciones-en-Git-%C2%BFQu%C3%A9-es-una-rama%3F)
- [GitLab Flow](https://about.gitlab.com/topics/version-control/what-is-gitlab-flow/) — Documentación oficial
- [Learn Git Branching](https://learngitbranching.js.org/?locale=es_ES) — Práctica interactiva de ramas y rebase
- [Git MERGE vs REBASE — Academind](https://www.youtube.com/watch?v=0chZFIZLR_0) — Video explicativo (9 min)

---

## ➡️ Siguiente Lección

[03 — GitLab CE: Overview →](./03-gitlab-ce-overview.md)

# 🛠️ Práctica 03 — Ramas y Merges

⏱️ **Tiempo estimado**: 60 minutos
⭐⭐⭐ **Dificultad**: Intermedio
📋 **Prerrequisitos**: Práctica 02 completada (repositorio `practica-flujo-git` con commits)

---

## 🎯 Objetivo

Practicar el ciclo completo de trabajo con ramas: crear una rama `feature/`, desarrollar en ella, crear una Merge Request en GitLab CE, hacer el merge vía UI y vía CLI, y resolver un conflicto intencional. Al finalizar entenderás el flujo de trabajo colaborativo real con GitLab.

---

## 📚 Teoría Relacionada

- [02 — Git: Ramas, Merge y Rebase](../../1-teoria/02-git-ramas-y-flujos.md)

---

## 📋 Instrucciones

### Paso 1: Preparar el Repositorio Base

Continúa trabajando en el repositorio de la Práctica 02 o usa el de la práctica anterior:

```bash
cd practica-flujo-git

# Asegúrate de estar en main y actualizado
git switch main
git pull origin main

# Ver el estado inicial
git log --oneline --graph --all
git branch -a
```

---

### Paso 2: Crear y Trabajar en una Rama Feature

```bash
# Crear la rama feature y cambiar a ella
git switch -c feature/agregar-guia-comandos

# Verificar que estamos en la rama correcta
git branch
# Debe mostrar: * feature/agregar-guia-comandos

# Crear un archivo nuevo en la rama
cat > docs/guia-comandos.md << 'EOF'
# Guía de Comandos Git — Semana 01

## Comandos Básicos

### git status
Ver el estado del repositorio: qué cambió, qué está en staging.

```bash
git status
git status -s  # formato corto
```

### git add
Mover archivos al staging area para incluirlos en el próximo commit.

```bash
git add <archivo>    # archivo específico
git add .            # todos los cambios
git add -p           # interactivo (trozo por trozo)
```

### git commit
Guardar el estado actual del staging como un commit permanente.

```bash
git commit -m "tipo: descripción breve"
git commit          # abre el editor para mensaje largo
```

### git log
Ver el historial de commits.

```bash
git log --oneline --graph --all   # vista visual compacta
git log -5                         # últimos 5 commits
```

## Referencia Rápida

| Situación | Comando |
|-----------|---------|
| ¿Qué cambié? | `git status` + `git diff` |
| Preparar para commit | `git add <archivos>` |
| Guardar cambios | `git commit -m "mensaje"` |
| Subir a GitLab | `git push origin <rama>` |
| Traer cambios | `git pull origin main` |
| Ver historial | `git log --oneline --graph` |
EOF

# Primer commit en la rama
git add docs/guia-comandos.md
git commit -m "docs: agregar guía de referencia de comandos git"

# Hacer un segundo cambio en la misma rama
echo "" >> docs/guia-comandos.md
echo "## Comandos de Ramas" >> docs/guia-comandos.md
echo "- \`git switch -c <nombre>\` — Crear y cambiar de rama" >> docs/guia-comandos.md
echo "- \`git switch main\` — Volver a main" >> docs/guia-comandos.md
echo "- \`git branch\` — Listar ramas" >> docs/guia-comandos.md
echo "- \`git merge <rama>\` — Fusionar rama en la actual" >> docs/guia-comandos.md

git add docs/guia-comandos.md
git commit -m "docs: agregar sección de comandos de ramas a la guía"

# Ver el historial (debe mostrar la divergencia)
git log --oneline --graph --all
```

---

### Paso 3: Subir la Rama y Crear una Merge Request en GitLab CE

```bash
# Subir la rama al remoto
git push -u origin feature/agregar-guia-comandos
```

En GitLab CE (`http://localhost/root/practica-flujo-git`):

1. Aparecerá un banner azul: **"You pushed to feature/agregar-guia-comandos"** con botón **Create merge request**. Click en ese botón.

   (Alternativa: Sidebar → **Merge requests** → **New merge request**)

2. Configurar la MR:
   - **Title**: `docs: agregar guía de comandos git`
   - **Description**: Describe qué agregaste y por qué
   - **Assignee**: Asignarte a ti mismo
   - **Labels**: Si tienes labels creadas, agrega `documentation`
   - Source: `feature/agregar-guia-comandos` → Target: `main`

3. Click **Create merge request**

4. Revisa el diff en la pestaña **Changes** — debe mostrar el nuevo archivo

5. Click **Merge** para hacer el merge vía UI

---

### Paso 4: Sincronizar main Localmente

```bash
# Volver a main
git switch main

# Traer los cambios del merge hecho en la UI
git pull origin main

# Verificar que el merge llegó
git log --oneline --graph --all
# Debe mostrar el merge commit o fast-forward

# Eliminar la rama local (ya fue fusionada)
git branch -d feature/agregar-guia-comandos

# Eliminar la rama remota también
git push origin --delete feature/agregar-guia-comandos
```

---

### Paso 5: Merge Vía CLI (Segunda Rama)

```bash
# Crear otra rama
git switch -c feature/agregar-gitignore

# Crear un .gitignore básico
cat > .gitignore << 'EOF'
# Archivos del sistema operativo
.DS_Store
Thumbs.db

# Archivos temporales y logs
*.log
*.tmp
*.swp
*~
temp/

# Dependencias (para proyectos Node.js, Python, etc.)
node_modules/
__pycache__/
*.pyc
venv/
.env

# Archivos del editor
.vscode/
.idea/
*.suo
EOF

git add .gitignore
git commit -m "chore: agregar .gitignore con reglas para OS, logs y editores"

# Volver a main y hacer merge CLI (sin MR)
git switch main
git merge feature/agregar-gitignore

# Ver el resultado
git log --oneline --graph --all

# Push del merge
git push origin main

# Limpiar la rama local y remota
git branch -d feature/agregar-gitignore
```

---

### Paso 6: Crear y Resolver un Conflicto Intencional

```bash
# Crear rama A que modifica el README
git switch -c feature/rama-a
echo "" >> README.md
echo "## Cambio desde Rama A" >> README.md
echo "Esta línea fue agregada por la rama A." >> README.md
git add README.md
git commit -m "docs: agregar sección desde rama A"

# Volver a main y crear rama B que modifica el mismo archivo en el mismo lugar
git switch main
git switch -c feature/rama-b
echo "" >> README.md
echo "## Cambio desde Rama B" >> README.md
echo "Esta línea fue agregada por la rama B (diferente contenido)." >> README.md
git add README.md
git commit -m "docs: agregar sección desde rama B"

# Fusionar rama A primero (OK, no hay conflicto aún)
git switch main
git merge feature/rama-a
# Fast-forward o merge exitoso

# Intentar fusionar rama B → ¡CONFLICTO!
git merge feature/rama-b
# Output: CONFLICT (content): Merge conflict in README.md
```

```bash
# Ver los archivos en conflicto
git status
# README.md aparece como "both modified"

# Ver el contenido del archivo con los marcadores de conflicto
cat README.md
# Verás algo como:
# <<<<<<< HEAD
# ## Cambio desde Rama A
# Esta línea fue agregada por la rama A.
# =======
# ## Cambio desde Rama B
# Esta línea fue agregada por la rama B (diferente contenido).
# >>>>>>> feature/rama-b

# Resolver el conflicto: editar el archivo para quedarte con AMBAS secciones
# Elimina los marcadores <<<<<<, =======, >>>>>>>
# Deja el contenido que quieres en el resultado final

# En este caso, queremos ambas secciones:
# Abre el editor y edita README.md para que quede así:
# (elimina los marcadores y deja el contenido combinado)
nano README.md
# O usa VS Code que detecta los conflictos visualmente

# Después de editar, marcar como resuelto
git add README.md

# Completar el merge
git commit
# Git propone un mensaje automático: acepta con :wq (en vim) o cierra VS Code

# Verificar el historial
git log --oneline --graph --all

# Push
git push origin main

# Limpiar ramas
git branch -d feature/rama-a feature/rama-b
```

---

## ✅ Verificación Final

```bash
# El historial debe mostrar múltiples ramas fusionadas
git log --oneline --graph --all

# Las ramas feature deben estar eliminadas
git branch -a
# Solo debe aparecer: * main y origin/main (y origin/HEAD)

# El repositorio debe tener estos archivos
ls -la
# README.md, .gitignore, docs/
ls docs/
# guia-comandos.md, notas.md
```

---

## 🚨 Troubleshooting

| Problema | Causa | Solución |
|----------|-------|----------|
| `error: branch not found` al hacer `-d` | La rama ya fue eliminada | Verificar con `git branch -a` |
| `The branch is not fully merged` al hacer `-d` | La rama tiene commits sin fusionar | Usar `-D` si estás seguro, o hacer el merge primero |
| Conflicto bloqueado, no sé resolverlo | Confusión con los marcadores | `git merge --abort` para cancelar y empezar de nuevo |
| MR en GitLab muestra conflictos | El target branch (main) avanzó mientras trabajabas en feature | Hacer `git switch feature/...`, `git merge main` (o `git rebase main`), resolver conflictos, push |
| `Merge conflict in README.md` al hacer pull | El remote y local modificaron el mismo archivo | Resolver conflicto igual que en el Paso 6 |

---

## 📝 Entregable

1. Output de `git log --oneline --graph --all` mostrando el historial con múltiples ramas fusionadas
2. Captura de la Merge Request cerrada/merged en GitLab CE
3. Output de `git branch -a` (solo debe quedar `main`)
4. URL del proyecto: `http://localhost/root/practica-flujo-git/-/network/main`

---

## ➡️ Siguiente Práctica

[Práctica 04 — Primer Proyecto en GitLab CE →](../04-primer-proyecto-gitlab/README.md)

# 🛠️ Práctica 02 — Flujo Git Básico

⏱️ **Tiempo estimado**: 60 minutos
⭐⭐ **Dificultad**: Básico-Intermedio
📋 **Prerrequisitos**: Práctica 01 completada (SSH configurado, acceso a GitLab CE)

---

## 🎯 Objetivo

Dominar el ciclo completo de trabajo con Git: clonar desde GitLab CE, editar archivos localmente, preparar commits con mensajes en formato Conventional Commits, sincronizar con el remoto y ver el historial visual. Al final tendrás un repositorio con al menos 3 commits en GitLab CE.

---

## 📚 Teoría Relacionada

- [01 — Git: Comandos Esenciales](../../1-teoria/01-git-fundamentos.md) (secciones: flujo básico, sincronizar con remoto)
- [05 — Primeros Pasos en GitLab CE](../../1-teoria/05-primeros-pasos-gitlab.md) (sección: Crear el Primer Proyecto)

---

## 📋 Instrucciones

### Paso 1: Crear un Proyecto en GitLab CE

En `http://localhost`:

1. Click **`+`** (top bar) → **New project/repository**
2. Seleccionar **Create blank project**
3. Completar:
   - **Project name**: `practica-flujo-git`
   - **Visibility Level**: Private
   - ✅ **Initialize repository with a README**
4. Click **Create project**

---

### Paso 2: Clonar el Proyecto Localmente

```bash
# Copiar la URL SSH del proyecto desde GitLab CE
# En el proyecto → botón "Clone" → "Clone with SSH"
# La URL será algo como: ssh://git@localhost:2224/root/practica-flujo-git.git

# Clonar el repositorio
git clone ssh://git@localhost:2224/root/practica-flujo-git.git

# Entrar al directorio
cd practica-flujo-git

# Verificar que el repositorio se clonó correctamente
git log --oneline
# Debe mostrar el commit inicial del README
```

---

### Paso 3: Primer Commit — Mejorar el README

```bash
# Ver el estado inicial
git status
# Output esperado: "nothing to commit, working tree clean"

# Editar el README.md (agrega contenido real)
cat >> README.md << 'EOF'

## Descripción

Repositorio de práctica para el **Bootcamp GitLab CE Zero to Hero**.

Semana 01: Aprendiendo el flujo básico de Git.

## Comandos Practicados

- `git clone` — Clonar desde GitLab CE
- `git status` — Ver estado del repositorio
- `git add` — Preparar cambios
- `git commit` — Guardar snapshot
- `git push` — Sincronizar con GitLab CE
- `git pull` — Traer cambios del remoto
EOF

# Ver qué cambió
git status
# Debe mostrar README.md en rojo (modified)

git diff
# Debe mostrar las líneas agregadas en verde
```

```bash
# Preparar el commit
git add README.md

# Verificar que está en staging
git status
# README.md debe aparecer en verde (staged)

# Hacer el commit con Conventional Commits
git commit -m "docs: mejorar README con descripción y comandos practicados"

# Verificar el commit
git log --oneline
```

---

### Paso 4: Segundo Commit — Crear un Archivo Nuevo

```bash
# Crear un archivo de notas de aprendizaje
mkdir -p docs
cat > docs/notas.md << 'EOF'
# Notas de Aprendizaje — Semana 01

## Conceptos Clave

- **Working Directory**: donde edito mis archivos
- **Staging Area**: zona de preparación antes del commit
- **Repository**: historial permanente de commits
- **Remote**: copia del repositorio en GitLab CE

## Comandos que Aprendí

| Comando | Para qué sirve |
|---------|----------------|
| `git status` | Ver el estado actual |
| `git add` | Pasar archivos a staging |
| `git commit` | Guardar en el historial |
| `git push` | Subir a GitLab CE |
| `git pull` | Bajar cambios del remoto |

## Errores Cometidos y Cómo Los Resolví

(Ir completando esto durante la semana)
EOF

# Ver el nuevo archivo
git status
# docs/notas.md debe aparecer como "Untracked files"

# Agregar al staging
git add docs/notas.md

# Commit
git commit -m "docs: agregar notas de aprendizaje de la semana 01"
```

---

### Paso 5: Sincronizar con GitLab CE

```bash
# Subir los commits locales al remoto
git push origin main

# Output esperado:
# Enumerating objects: X, done.
# Counting objects: 100% (X/X), done.
# Writing objects: 100% (X/X), ... bytes | ... MiB/s, done.
# To ssh://localhost:2224/root/practica-flujo-git.git
#    abc1234..def5678  main -> main
```

Verifica en `http://localhost/root/practica-flujo-git` que aparecen tus commits.

---

### Paso 6: Simular un Cambio desde Otro Dispositivo (Editar en GitLab UI)

1. En `http://localhost/root/practica-flujo-git`
2. Click en el archivo `README.md`
3. Click en el **ícono de lápiz** (Edit)
4. Agregar una línea al final: `## Editado desde la UI de GitLab CE`
5. En **Commit changes**:
   - Message: `docs: agregar nota sobre edición desde UI`
   - Branch: `main`
6. Click **Commit changes**

```bash
# Traer el cambio del remoto
git pull origin main

# Ver que el cambio llegó
git log --oneline
# Debe aparecer el commit hecho desde la UI

# Ver el contenido actualizado
cat README.md
```

---

### Paso 7: Ver el Historial Visual

```bash
# Vista compacta con el árbol de ramas
git log --oneline --graph --all

# Vista detallada con todos los metadatos
git log

# Ver el diff de un commit específico (copia el hash del log anterior)
git show <hash-del-primer-commit>

# Estadísticas de cambios por commit
git log --stat --oneline
```

---

## ✅ Verificación Final

```bash
# Tu repositorio debe tener al menos 3 commits
git log --oneline
# Ejemplo de output esperado:
# a1b2c3d (HEAD -> main, origin/main) docs: agregar nota sobre edición desde UI
# e4f5g6h docs: agregar notas de aprendizaje de la semana 01
# i7j8k9l docs: mejorar README con descripción y comandos practicados
# m0n1o2p Initial commit

# Ver la estructura del repositorio
ls -la
# Debe mostrar: README.md, docs/

ls docs/
# Debe mostrar: notas.md
```

---

## 🚨 Troubleshooting

| Problema | Causa | Solución |
|----------|-------|----------|
| `git push` rechazado: `rejected [remote rejected]` | El remoto tiene commits que no tienes localmente | Hacer `git pull origin main` primero, luego `git push` |
| `fatal: 'origin' does not appear to be a git repository` | Remote mal configurado | Verificar con `git remote -v` y reconfigurar con `git remote set-url` |
| `error: src refspec main does not match any` | La rama local no se llama `main` | Verificar con `git branch` y renombrar: `git branch -m master main` |
| `git pull` genera conflicto | Editaste el mismo archivo localmente y en la UI | Resolver el conflicto manualmente (ver teoría 02) |
| `nothing to commit, working tree clean` después de editar | Olvidaste guardar el archivo en el editor | Guardar en el editor y ejecutar `git status` de nuevo |

---

## 📝 Entregable

Captura de pantalla o texto del output de:

1. `git log --oneline --graph --all` (mostrando al menos 3 commits)
2. URL del proyecto en GitLab CE: `http://localhost/root/practica-flujo-git`
3. Vista del proyecto en GitLab mostrando los archivos README.md y docs/notas.md

---

## ➡️ Siguiente Práctica

[Práctica 03 — Ramas y Merges →](../03-ramas-y-merges/README.md)

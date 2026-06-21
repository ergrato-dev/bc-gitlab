# Practica 03 — Ramas y Merges

## Objetivo
Crear ramas, trabajar en ellas y fusionarlas a la rama principal.

## Instrucciones

1. Crear una rama `feature/readme`
2. Editar el README.md en esa rama
3. Hacer commit de los cambios
4. Cambiar a `main` y hacer merge
5. Eliminar la rama `feature/readme`

### Paso a Paso

```bash
# 1. Crear y cambiar a nueva rama
git checkout -b feature/readme

# 2. Editar README.md
echo "## Descripcion" >> README.md
echo "Este es mi primer proyecto en GitLab CE." >> README.md

# 3. Commit
git add README.md
git commit -m "docs: agregar descripcion al README"

# 4. Volver a main y fusionar
git checkout main
git merge feature/readme

# 5. Eliminar la rama
git branch -d feature/readme

# 6. Subir main actualizado
git push origin main
```

## Entregable
- Salida de `git log --oneline --graph --all` mostrando el merge
- Captura de `git branch -a`

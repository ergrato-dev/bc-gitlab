# Practica 02 — Flujo Git Basico

## Objetivo
Practicar el flujo de trabajo basico: clone → edit → add → commit → push.

## Instrucciones

1. Clonar un repositorio
2. Hacer cambios en un archivo
3. Ver el estado con `git status`
4. Agregar al staging con `git add`
5. Hacer commit con mensaje descriptivo
6. Subir cambios con `git push`

### Paso a Paso

```bash
# 1. Clonar (usa URL de tu proyecto en GitLab)
git clone git@localhost:root/mi-primer-proyecto.git
cd mi-primer-proyecto

# 2. Crear o editar un archivo
echo "# Mi Proyecto" >> README.md

# 3. Ver estado
git status

# 4. Agregar al staging
git add README.md

# 5. Hacer commit
git commit -m "docs: actualizar README con titulo"

# 6. Subir cambios
git push origin main
```

## Entregable
- URL del repositorio con el commit visible
- Salida de `git log --oneline -5`

# 04 — GitLab Flow

## Objetivos

- Entender el flujo de trabajo GitLab Flow
- Implementar el ciclo completo issue → branch → MR → review → merge
- Usar ramas de ambiente (staging, production)
- Integrar issues con el flujo de desarrollo

## GitLab Flow: El Ciclo Completo

GitLab Flow integra issues, branches y merge requests en un flujo cohesivo:

```
Issue Created → Assignee → Branch Created → Code Changes → Push →
MR Created (Draft) → Code Review → CI Pipeline → MR Approved →
Merge to Main → Deploy to Staging → Promote to Production
```

## Paso a Paso

### 1. Crear Issue

```
Proyecto → Issues → New Issue
Titulo: "Implementar pagina de perfil de usuario"
Labels: ~feature, ~frontend, ~priority::2
Milestone: Sprint 1
Assignee: developer1
```

### 2. Crear Rama desde el Issue

En la pagina del issue, usa el boton **Create merge request** o crea la rama manualmente:

```bash
git checkout -b 42-user-profile
# Convencion: <issue-number>-<descripcion>
git push origin 42-user-profile
```

### 3. Desarrollar y Commits

```bash
# Commits atomicos con mensajes descriptivos
git commit -m "feat: agregar ruta de perfil de usuario"
git commit -m "feat: implementar vista de perfil"
git commit -m "test: agregar pruebas de pagina de perfil"
git commit -m "style: ajustar estilos responsivos del perfil"
```

### 4. Crear MR (Draft)

Inicialmente como Draft para obtener feedback temprano:

```bash
# Push y crear MR
git push origin 42-user-profile
# En UI: Create MR con titulo "Draft: Implementar pagina de perfil"
```

### 5. Code Review y CI

- Se ejecuta el pipeline automaticamente
- Reviewers agregan comentarios
- Autor responde y hace fixes
- Pipeline pasa (verde)

### 6. Quitar Draft y Merge

```markdown
# Cuando el MR esta listo:
1. Quitar "Draft:" del titulo
2. Solicitar approval final
3. Reviewer aprueba
4. Merge (Squash and Merge recomendado)
5. Issue se cierra automaticamente (si se uso "Closes #42")
```

## Ramas de Ambiente

GitLab Flow extiende GitHub Flow con ramas de ambiente:

```
main → staging → production
```

### Flujo de Despliegue

```
Feature Branch → MR → main (via MR, CI ejecuta pruebas)
main → MR → staging (via MR, despliegue automatico a staging)
staging → MR → production (via MR, despliegue manual a prod)
```

### Configuracion de Ramas de Ambiente

```bash
# Crear ramas de ambiente
git checkout main
git checkout -b staging
git push origin staging

git checkout main
git checkout -b production
git push origin production
```

Proteger ambas ramas:
- `main`: Merge por Maintainers, push por Nobody
- `staging`: Merge por Maintainers, push por Nobody
- `production`: Merge solo por Maintainers, push por Nobody

## Release Branches (Versiones)

Para software versionado, agregar ramas de release:

```
main → 1-0-stable → 1-0-stable → ...
```

```bash
# Crear rama de release
git checkout -b 1-0-stable
git push origin 1-0-stable

# Hotfix en version estable
git checkout 1-0-stable
git checkout -b hotfix/bug-critico
# ... fix ...
git checkout 1-0-stable
git merge hotfix/bug-critico
git push origin 1-0-stable
# Tambien mergear a main si aplica
git checkout main
git merge 1-0-stable
```

## Vinculacion Issue ↔ MR

Al crear un MR desde la pagina del issue, GitLab vincula automaticamente:

```
Issue #42 esta vinculado a MR !15
```

En la descripcion del MR, incluir `Closes #42` para cerrar el issue al mergear.

En commits, usar:
```
feat: agregar pagina de perfil (#42)
```

Esto crea una referencia automatica en el issue.

## Buenas Practicas GitLab Flow

1. Cada MR resuelve exactamente 1 issue
2. Rama nombrada como `<issue-id>-<descripcion>`
3. MRs pequenos y frecuentes
4. Pipelines must succeed para merge
5. Squash and merge para historial limpio
6. Eliminar rama fuente despues del merge

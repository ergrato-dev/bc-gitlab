# 02 — Merge Requests en GitLab

## Objetivos

- Entender el ciclo de vida de un Merge Request
- Crear MRs con descripciones efectivas
- Configurar opciones de merge y revision
- Usar draft/WIP MRs para trabajo en progreso

## Que es un Merge Request?

Un Merge Request (MR) es una solicitud para fusionar cambios de una rama a otra. Es equivalente al Pull Request de GitHub. Incluye:

- Diffs del codigo cambiado
- Pipeline status
- Discusiones y revisiones
- Widget de merge (condiciones y opciones)

## Ciclo de Vida de un MR

```
[New] → [Draft/WIP] → [Ready for Review] → [Approved] → [Merged]
                                     ↓
                              [Changes Requested]
                                     ↓
                              [Updated] → [Ready for Review] → [Approved] → [Merged]
```

## Crear un Merge Request

### Desde la UI
1. **Project → Merge Requests → New merge request**
2. Seleccionar rama origen (`feature/nombre`) y destino (`main`)
3. Completar titulo y descripcion
4. Asignar reviewer (opcional)
5. Agregar labels, milestone (opcional)
6. Click **Create merge request**

### Desde la terminal (push + MR link)

Al hacer push de una rama nueva, GitLab muestra un link en la salida:
```
remote: To create a merge request for feature/login, visit:
remote:   http://localhost/root/proyecto/-/merge_requests/new?merge_request[source_branch]=feature/login
```

### Template de MR recomendado

```markdown
## Descripcion
[Breve descripcion de los cambios]

## Issue Relacionado
Closes #42

## Cambios Realizados
- Agregado modulo de autenticacion
- Configurado middleware de sesiones
- Agregadas pruebas unitarias

## Como Probar
1. Ejecutar `npm test`
2. Iniciar servidor `npm run dev`
3. Probar login con credenciales test

## Screenshots (si aplica)
[Imagenes de cambios visuales]

## Checklist
- [ ] Pruebas pasan
- [ ] Documentacion actualizada
- [ ] No hay codigo comentado
- [ ] Sigue guia de estilo
```

## Draft / WIP Merge Requests

Un MR marcado como **Draft:** o **WIP:** en el titulo no puede ser mergeado. Util para:
- Compartir trabajo en progreso para feedback temprano
- Ejecutar pipelines antes de que el codigo este finalizado
- Indicar que el MR no esta listo para merge

Para marcar/desmarcar:
- Titulo: `Draft: Implementar login` → El MR no se puede mergear
- Quitar `Draft:` del titulo → El MR queda disponible para merge

## Opciones de Merge

Al mergear, GitLab ofrece diferentes estrategias:

### Merge Commit
Crea un commit de merge que preserva todo el historial.
```
git merge --no-ff feature/login
```

### Merge Commit with Semi-linear History
Similar a merge commit, pero requiere que la rama este actualizada con `main` (rebase previo).

### Fast-forward Merge
Si es posible, mueve el puntero de `main` al ultimo commit de la rama. Requiere que no haya commits nuevos en `main` desde que se creo la rama.

### Squash and Merge
Combina todos los commits de la rama en un solo commit en `main`. Ideal para mantener historial limpio.

```
Antes:  feature/login: A → B → C → D
Despues: main: [Squash commit con mensaje del MR]
```

## Configuracion de Merge Requests

En **Settings → Merge requests**:

- **Merge method**: Merge commit, Fast-forward, Squash
- **Squash commits when merging**: Forzar squash siempre
- **Pipelines must succeed**: Requerir CI verde antes de merge
- **All threads must be resolved**: Requerir resolver todos los comentarios
- **Approvals required**: Numero minimo de approvals
- **Delete source branch**: Eliminar rama automaticamente despues del merge

## Referencias en Commits

Palabras clave que cierran issues automaticamente al mergear:

```
Closes #42
Fixes #42
Resolves #42
Implements #42
```

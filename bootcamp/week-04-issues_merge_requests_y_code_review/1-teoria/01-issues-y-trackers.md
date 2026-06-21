# 01 — Issues y Trackers en GitLab

## Objetivos

- Entender el sistema de issues en GitLab
- Crear issues con descripciones efectivas
- Organizar issues con labels, milestones y weight
- Usar quick actions para agilizar la gestion

## Sistema de Issues

Los issues en GitLab son la unidad de trabajo para rastrear tareas, bugs, mejoras, incidentes y discusiones. Cada issue pertenece a un proyecto unico y tiene un ID numerico secuencial.

### Anatomia de un Issue

- **Titulo**: Descripcion concisa de la tarea
- **Descripcion**: Contexto detallado, criterios de aceptacion, pasos para reproducir
- **Assignee**: Persona responsable de resolverlo
- **Labels**: Etiquetas para categorizar (`bug`, `feature`, `frontend`, `backend`)
- **Milestone**: Agrupacion temporal (sprint, release, version)
- **Due date**: Fecha limite
- **Weight**: Estimacion de complejidad (1 = trivial, 9 = muy complejo)
- **Confidential**: Issue visible solo para miembros con permisos

## Crear un Issue

### Template recomendado

```markdown
## Descripcion
[Descripcion clara del problema o tarea]

## Criterios de Aceptacion
- [ ] Criterio 1
- [ ] Criterio 2

## Pasos para Reproducir (si es bug)
1. Ir a...
2. Hacer click en...
3. Ver error...

## Comportamiento Esperado
[Que deberia pasar]

## Comportamiento Actual
[Que esta pasando]

## Informacion Adicional
- Navegador: Chrome 120
- Entorno: Staging
```

### Quick Actions

Escribe estos comandos en comentarios del issue para realizar acciones rapidamente:

```
/assign @username       # Asignar a un usuario
/label ~bug ~frontend   # Agregar labels
/milestone %v1.0        # Asignar milestone
/due 2024-12-31         # Fecha limite
/weight 3               # Peso/estimacion
/close                  # Cerrar issue
/reopen                 # Reabrir issue
/title Nuevo titulo     # Cambiar titulo
```

## Labels

Los labels clasifican issues y MRs. Pueden crearse a nivel proyecto o grupo.

### Tipos comunes de labels

**Tipo de trabajo:**
- `~bug`, `~feature`, `~maintenance`, `~documentation`, `~security`

**Prioridad (con colores):**
- `~priority::1` (rojo, urgente)
- `~priority::2` (naranja, alto)
- `~priority::3` (amarillo, medio)
- `~priority::4` (verde, bajo)

**Area/Team:**
- `~frontend`, `~backend`, `~devops`, `~design`, `~qa`

**Estado de workflow:**
- `~workflow::todo`, `~workflow::in-progress`, `~workflow::review`, `~workflow::done`

## Milestones

Un milestone agrupa issues y MRs con un objetivo y fecha comun. Tipicamente representa un sprint, release o version.

**Tipos:**
- **Project milestone**: Aplica a un proyecto especifico
- **Group milestone**: Aplica a todos los proyectos en un grupo (permite planificar multi-proyecto)

### Crear un Milestone

1. **Project/Group → Issues → Milestones → New milestone**
2. Titulo: `Sprint 1` o `v1.0.0`
3. Fecha inicio y fin
4. Descripcion (opcional)

## Issues Relacionados y Epics

- **Related issues**: Vincular issues entre si (`Related to`, `Blocks`, `Is blocked by`)
- **Epics** (disponible en GitLab EE, no CE): Agrupan issues de multiples proyectos bajo un objetivo comun

En CE, puedes simular epics usando labels `~epic::nombre-del-epic`.

## Buenas Practicas

- Escribir titulos descriptivos y accionables
- Usar templates para asegurar consistencia
- Asignar labels, milestone y assignee al crear
- Mantener la descripcion actualizada con el progreso
- Referenciar issues en commits y MRs con `#ID`
- Cerrar issues con mensajes de commit: `Closes #42` o `Fixes #42`

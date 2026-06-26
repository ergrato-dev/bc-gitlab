# 📖 05 — Templates y Automatización en GitLab CE

## 🎯 Objetivos de aprendizaje

- ✅ Crear templates de Issues y Merge Requests que estandarizan el proceso del equipo
- ✅ Usar Quick Actions dentro de templates para automatizar asignaciones
- ✅ Configurar un Issue Board (Kanban) para visualizar el flujo de trabajo
- ✅ Entender qué se puede automatizar en GitLab CE vs lo que requiere EE

---

## 🤔 ¿Por qué Templates?

Sin templates, cada developer crea issues y MRs a su manera: algunos con contexto completo, otros con solo el título. El reviewer pierde tiempo pidiendo información que debería estar desde el inicio.

**Analogía:** Los templates de issues y MRs son como los formularios de admisión de un hospital. En lugar de que cada enfermero pregunte diferente información a cada paciente, existe un formulario estándar que asegura que siempre se recolecta el nombre, síntomas, alergias e historial médico relevante. El médico (reviewer) puede ir directo a revisar en lugar de recolectar datos básicos.

---

## 📋 Templates de Issues

Los templates de issues viven en `.gitlab/issue_templates/` en el repositorio. GitLab muestra un dropdown "Choose a template" al crear un issue.

### Template para Bug

```
.gitlab/issue_templates/Bug.md
```

```markdown
## 🐛 Resumen del Bug
<!-- Describe el bug en una oración clara y concisa -->

## Pasos para Reproducir
1. Ir a '...'
2. Click en '...'
3. Observar que '...'

## Comportamiento Esperado
<!-- Qué debería ocurrir -->

## Comportamiento Actual
<!-- Qué está ocurriendo actualmente -->

## Capturas de Pantalla / Logs
<!-- Pegar screenshots, stack trace, o logs de error aquí -->
```
ERROR: ...
```

## Entorno
- **SO:** Ubuntu 22.04 / macOS 14 / Windows 11
- **Navegador:** Chrome 120 / Firefox 121
- **Versión del sistema:** v1.2.0
- **Ambiente:** Producción / Staging / Local

## Información Adicional
<!-- Cualquier contexto extra que pueda ayudar -->

/label ~bug ~priority::2
/weight 3
```

### Template para Feature Request

```
.gitlab/issue_templates/Feature.md
```

```markdown
## ✨ Descripción de la Funcionalidad
<!-- Describe qué se quiere lograr, no cómo implementarlo -->

## Problema que Resuelve
<!-- ¿Qué problema del usuario resuelve esta funcionalidad? -->

## Criterios de Aceptación
<!-- Lista verificable de cuándo esta feature está "terminada" -->
- [ ] Criterio 1 (observable y verificable)
- [ ] Criterio 2
- [ ] Criterio 3

## Diseño / Mockups
<!-- Links a Figma, screenshots de prototipo, o descripción visual -->

## Consideraciones Técnicas
<!-- APIs afectadas, cambios en base de datos, dependencias nuevas -->

## Alternativas Consideradas
<!-- ¿Qué otras soluciones se evaluaron? ¿Por qué se descartaron? -->

/label ~feature ~priority::3
```

### Template para Tarea de Mantenimiento

```
.gitlab/issue_templates/Maintenance.md
```

```markdown
## 🔧 Descripción de la Tarea
<!-- ¿Qué deuda técnica o mantenimiento se va a realizar? -->

## Motivación
<!-- ¿Por qué es necesario hacerlo ahora? (seguridad, rendimiento, deuda técnica) -->

## Impacto Estimado
- [ ] Sin impacto en funcionalidad (refactor interno)
- [ ] Actualización de dependencias
- [ ] Cambio de configuración
- [ ] Posible breaking change (describir)

## Plan de Implementación
1. Paso 1
2. Paso 2
3. Rollback plan si algo sale mal

/label ~maintenance ~priority::4
```

### Crear los templates en el proyecto

```bash
# ¿QUÉ HACE?: Crea el directorio de templates y los archivos iniciales
# ¿POR QUÉ?: GitLab busca templates en .gitlab/issue_templates/ automáticamente
# ¿PARA QUÉ?: Estandarizar cómo el equipo reporta bugs, features y tareas

git checkout -b chore/add-issue-templates

mkdir -p .gitlab/issue_templates

# Pegar el contenido de cada template en sus archivos correspondientes
# Bug.md, Feature.md, Maintenance.md

git add .gitlab/issue_templates/
git commit -m "chore: add issue templates for Bug, Feature, and Maintenance"
git push origin chore/add-issue-templates
# → Crear MR hacia main
```

---

## 📝 Templates de Merge Requests

Los templates de MR viven en `.gitlab/merge_request_templates/`. El template `Default.md` se aplica automáticamente a todos los MRs nuevos.

### Template Default (para todos los MRs)

```
.gitlab/merge_request_templates/Default.md
```

```markdown
## ¿Qué hace este MR?
<!-- Describe los cambios en 2-3 oraciones. Si es obvio por el issue, puedes ser breve. -->

## Issue relacionado
Closes #<!-- ID del issue -->

## Tipo de cambio
- [ ] 🐛 Bug fix (corrección de defecto)
- [ ] ✨ Nueva funcionalidad
- [ ] ⚡ Mejora de rendimiento
- [ ] 🔨 Refactorización (sin cambio de comportamiento)
- [ ] 📝 Documentación
- [ ] 🔧 Mantenimiento / CI-CD
- [ ] 💥 Breaking change

## Cambios realizados
- <!-- Cambio 1 -->
- <!-- Cambio 2 -->

## Cómo probar
1. <!-- Paso 1 -->
2. <!-- Paso 2 -->
3. <!-- Resultado esperado -->

## Screenshots (si aplica UI)
| Antes | Después |
|-------|---------|
| <!-- imagen --> | <!-- imagen --> |

## Checklist del autor
- [ ] Tests agregados/actualizados
- [ ] Sin `console.log` de debug
- [ ] Sin credenciales o datos sensibles
- [ ] Documentación actualizada
- [ ] Pipeline en verde

/assign @me
/label ~workflow::review
```

### Template para Hotfix

```
.gitlab/merge_request_templates/Hotfix.md
```

```markdown
## 🚨 Hotfix — Descripción del Problema Crítico
<!-- Qué está fallando en producción -->

## Issue relacionado
Closes #<!-- ID del issue -->

## Causa Raíz
<!-- Por qué falló. Diagnóstico técnico. -->

## Solución Implementada
<!-- Qué se cambió y por qué es la solución correcta -->

## Riesgo de la Solución
<!-- ¿Puede este cambio causar otros problemas? ¿Qué se probó? -->

## Rollback Plan
<!-- Cómo revertir si la solución empeora las cosas -->

## Tiempo de Impacto
<!-- Desde cuándo está fallando. Cuántos usuarios afectados. -->

/label ~bug ~priority::1
/assign @me
```

---

## 🎛️ Issue Boards (Kanban en GitLab)

Los Issue Boards convierten los labels de workflow en un tablero Kanban visual. Cada columna es un label; los issues se mueven arrastrando entre columnas.

### Configurar un Board básico

```
Proyecto → Issues → Boards → New board

Name:       Sprint 1 Board
Scope:      Milestone: Sprint 1   ← Solo issues de este sprint

Columnas (en orden):
  Open  → ~workflow::todo → ~workflow::in-progress → ~workflow::review → Closed
```

Para agregar columnas:
```
Board → Add list
  Value:  ~workflow::in-progress
```

### El flujo Kanban con boards

```
[Open]    → Developer empieza → [In Progress]
             Developer crea MR → [Review]
             Reviewer aprueba → [Closed] (o [Merged])
```

Mover un issue entre columnas automáticamente agrega/quita el label correspondiente.

### Board a nivel de grupo (multi-proyecto)

```
Grupo → Issues → Boards

Permite ver issues de TODOS los proyectos del grupo en un solo tablero.
Ideal para el Scrum Master / PM del equipo.
```

---

## ⚡ Quick Actions en Templates

Las Quick Actions en los templates se ejecutan automáticamente cuando se crea el issue o MR. Son especialmente poderosas en templates:

```markdown
<!-- En el template Bug.md -->
/label ~bug
/weight 3

<!-- En el template Feature.md -->
/label ~feature
/weight 5

<!-- En el template Hotfix.md -->
/label ~bug ~priority::1
/assign @me
/milestone %current
```

**Notas importantes:**
- `/assign @me` asigna al usuario que crea el issue (no al creador del template)
- `/milestone %current` asigna el milestone activo del proyecto
- Las quick actions se procesan al guardar el issue/MR, no al cargar el template

---

## 🔄 Cerrar Issues Automáticamente

Cuando un MR se mergea a la rama default (`main`), GitLab cierra automáticamente los issues referenciados en la descripción con estas palabras clave:

```
Closes #42        (más común)
Fixes #42
Resolves #42
Implements #42    (para features)

Múltiples:
Closes #42, #43, #44

Cross-project:
Closes namespace/project#42
```

**Configurar la rama que dispara el cierre:**
```
Proyecto → Settings → Repository → Default branch

Si tu default branch es "develop" en lugar de "main",
los issues solo se cierran cuando el MR llega a "develop".
```

---

## 📊 Difference: GitLab CE vs EE (Automatización)

Es importante saber qué está disponible en CE (gratuito self-hosted) y qué requiere EE:

| Funcionalidad | CE | EE |
|--------------|----|----|
| Templates de Issues y MRs | ✅ | ✅ |
| Issue Boards básicos | ✅ | ✅ |
| Issue Boards múltiples | ✅ | ✅ |
| Quick Actions básicas | ✅ | ✅ |
| Cierre automático de issues | ✅ | ✅ |
| Service Desk (email → issue) | ✅ | ✅ |
| Scoped Labels (priority::1) | ✅ | ✅ |
| **Epics** (agrupar issues) | ❌ | ✅ |
| **Roadmaps** | ❌ | ✅ |
| **Iteraciones** (sprints nativos) | ❌ | ✅ |
| **Weight summing** en milestone | ❌ | ✅ |
| **Board Swimlanes** | ❌ | ✅ |
| **Approval Rules avanzadas** | ❌ | ✅ |

**En CE puedes simular Epics con:** labels tipo `~epic::nombre-del-epic` y filtrar issues por ese label.

---

## 🤔 Preguntas de reflexión

1. Tu equipo tiene templates de Bug y Feature, pero el 60% de los issues se crean sin usar ningún template. ¿Qué harías para aumentar la adopción sin forzar a la gente?

2. El template Default.md de MR incluye `/assign @me`. Un junior abre un MR y se lo asigna a sí mismo pero debería asignárselo a su tech lead. ¿Qué cambiarías en el template?

3. Tienes un Issue Board por sprint. El sprint termina el viernes. El lunes empezará Sprint 2. ¿Qué pasa con los issues incompletos del Sprint 1 que quedan en el board?

4. Un issue tiene la quick action `/weight 8` en el template de Feature. El PM siempre borra ese valor y lo reemplaza con su propia estimación. ¿Tiene sentido mantener el default en el template? ¿Qué alternativa propones?

5. ¿En qué situaciones usarías un Group template (de grupo) en lugar de un Project template (de proyecto)? ¿Qué ventaja tiene el group template?

---

## 📚 Recursos adicionales

- [Description templates](https://docs.gitlab.com/ee/user/project/description_templates.html)
- [Quick Actions Reference](https://docs.gitlab.com/ee/user/project/quick_actions.html)
- [Issue Boards](https://docs.gitlab.com/ee/user/project/issue_board.html)
- [Service Desk (email → issue)](https://docs.gitlab.com/ee/user/project/service_desk/)

---

⬅️ **Lección anterior:** [04 — GitLab Flow](./04-gitlab-flow.md)

---
*Fin del bloque de teoría — Semana 04. Continúa con las [Prácticas →](../2-practicas/README.md)*

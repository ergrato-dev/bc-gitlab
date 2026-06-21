# 05 — Templates y Automatizacion

## Objetivos

- Crear y usar templates de Issues y Merge Requests
- Configurar templates por defecto para el proyecto
- Implementar quick actions para automatizar tareas
- Usar description templates para estandarizar procesos

## Templates de Issues

Los templates de issues ayudan a mantener consistencia en como se reportan bugs, features y tareas.

### Crear Template de Issue

Crea el archivo `.gitlab/issue_templates/Bug.md` en el repositorio:

```markdown
## Resumen del Bug
[Descripcion concisa del bug]

## Pasos para Reproducir
1. Ir a '...'
2. Click en '...'
3. Scroll hasta '...'
4. Ver error

## Comportamiento Esperado
[Que deberia pasar]

## Comportamiento Actual
[Que esta pasando]

## Screenshots
[Si aplica, pegar imagenes]

## Entorno
- SO: [e.g. Ubuntu 22.04]
- Navegador: [e.g. Chrome 120]
- Version: [e.g. v1.2.0]

## Informacion Adicional
[Cualquier contexto extra]

/label ~bug
/weight 3
```

### Template para Feature Request

Archivo `.gitlab/issue_templates/Feature.md`:

```markdown
## Descripcion de la Funcionalidad
[Descripcion clara de que se quiere lograr]

## Problema que Resuelve
[Que problema soluciona esta funcionalidad?]

## Criterios de Aceptacion
- [ ] Criterio 1
- [ ] Criterio 2
- [ ] Criterio 3

## Diseno (si aplica)
[Links a Figma, mockups, etc.]

## Consideraciones Tecnicas
[APIs afectadas, cambios en DB, dependencias]

/label ~feature
```

### Seleccionar Template

Al crear un nuevo issue, GitLab mostrara un dropdown **Choose a template** con las opciones definidas en `.gitlab/issue_templates/`.

## Templates de Merge Requests

Archivo `.gitlab/merge_request_templates/Default.md`:

```markdown
## Descripcion
[Resumen de los cambios realizados]

## Issue Relacionado
Closes #ISSUE_ID

## Tipo de Cambio
- [ ] Bug fix
- [ ] Nueva funcionalidad
- [ ] Mejora de rendimiento
- [ ] Refactorizacion
- [ ] Documentacion
- [ ] CI/CD

## Cambios Realizados
- Cambio 1
- Cambio 2

## Como Probar
1. Paso 1
2. Paso 2

## Screenshots (si aplica)
| Antes | Despues |
|-------|---------|
|       |         |

## Checklist
- [ ] Pruebas agregadas/actualizadas
- [ ] Documentacion actualizada
- [ ] Codigo sigue guia de estilo
- [ ] No hay console.log ni codigo comentado
- [ ] Pipeline en verde

/label ~workflow::review
/assign_reviewer @team-lead
```

## Templates Multiples

Puedes tener diferentes templates para diferentes tipos de MR:

```
.gitlab/merge_request_templates/
├── Default.md
├── Hotfix.md
├── Release.md
└── Documentation.md
```

## Default Description Templates

Configurar un template por defecto que se aplica automaticamente a todos los MRs nuevos:

**Settings → Merge requests → Default description template:**

```markdown
## Que hace este MR?
<!-- Describe los cambios -->

## Issue Relacionado
<!-- Closes # -->

## Checklist
- [ ] Pruebas
- [ ] Documentacion
- [ ] Pipeline verde
```

## Quick Actions en Templates

Puedes incluir quick actions en los templates para automatizar:

```
/asign @backend-team
/label ~feature ~backend
/milestone %Sprint-1
/weight 3
/due 2024-12-31
```

Las quick actions se ejecutan al crear el issue/MR.

## Variables en Templates

GitLab soporta variables limitadas en el campo `description`:

- `%{project_name}`: Nombre del proyecto
- `%{branch}`: Rama actual (en MRs)

## Issue Boards Config

Puedes configurar labels de workflow para usar con Issue Boards:

```markdown
Labels de workflow sugeridas:
- ~workflow::todo      (default al crear)
- ~workflow::in-progress  (asignar al empezar)
- ~workflow::review    (cuando el MR esta listo)
- ~workflow::done      (cuando se mergea)
```

## Buenas Practicas

- Mantener templates simples pero completos
- No pedir informacion que ya esta en otro lado
- Incluir quick actions utiles para reducir pasos manuales
- Versionar los templates en el repositorio
- Revisar y actualizar templates periodicamente
- Templates de grupo (hereda a todos los proyectos):
  - **Group → Settings → General → Templates**

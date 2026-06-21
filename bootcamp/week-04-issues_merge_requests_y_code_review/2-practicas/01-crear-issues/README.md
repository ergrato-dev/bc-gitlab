# Practica 01 — Crear y Gestionar Issues

## Objetivo
Crear issues con descripciones completas, labels, milestones y asignaciones en GitLab CE.

## Instrucciones

### 1. Configurar labels del proyecto

1. Ve a uno de tus proyectos (ej: `bootcamp-org/backend/api-gateway`)
2. **Issues → Labels → New label**
3. Crea los siguientes labels:

| Nombre | Color |
|--------|-------|
| bug | #FF0000 |
| feature | #428BCA |
| documentation | #F0AD4E |
| frontend | #5CB85C |
| backend | #8E44AD |
| priority::1 | #D9534F |
| priority::2 | #F0AD4E |
| priority::3 | #5BC0DE |
| priority::4 | #5CB85C |
| workflow::todo | #CCCCCC |
| workflow::in-progress | #428BCA |
| workflow::review | #F0AD4E |
| workflow::done | #5CB85C |

### 2. Crear milestone

1. **Issues → Milestones → New milestone**
2. Titulo: `Sprint 1`
3. Fecha inicio: hoy
4. Fecha fin: 2 semanas despues

### 3. Crear issues

Crea al menos 3 issues en el proyecto:

**Issue 1 — Bug:**
- Titulo: "Error 500 al consultar endpoint /health"
- Description: Usar template de bug (descripcion, pasos, comportamiento esperado)
- Labels: ~bug, ~backend, ~priority::1
- Milestone: Sprint 1
- Assignee: Tu usuario

**Issue 2 — Feature:**
- Titulo: "Implementar autenticacion JWT en API Gateway"
- Description: Usar template de feature (descripcion, criterios, consideraciones)
- Labels: ~feature, ~backend, ~priority::2
- Milestone: Sprint 1
- Assignee: Tu usuario

**Issue 3 — Documentation:**
- Titulo: "Documentar endpoints en README"
- Labels: ~documentation, ~priority::3
- Milestone: Sprint 1

### 4. Usar quick actions

En un comentario del Issue 1, escribe:
```
/weight 5
/due 2024-12-31
```

Verifica que se actualicen los campos.

### 5. Referenciar issues en commits

```bash
cd ~/gitlab-bootcamp/repos/api-gateway
echo "# API Gateway" >> README.md
git add README.md
git commit -m "docs: agregar titulo al README (#1)"
```

Verifica que el issue #1 muestre la referencia al commit.

## Entregable
- Captura de la lista de issues con labels y milestone
- Captura de un issue individual mostrando descripcion, labels, assignee, weight y due date
- Salida de `git log --oneline` mostrando referencia a issue

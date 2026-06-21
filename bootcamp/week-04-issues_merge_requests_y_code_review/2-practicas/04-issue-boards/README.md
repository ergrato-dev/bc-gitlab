# Practica 04 — Issue Boards (Kanban)

## Objetivo
Configurar y usar GitLab Issue Boards para gestionar el flujo de trabajo con metodologia Kanban.

## Instrucciones

### 1. Configurar labels de workflow

Asegurate de tener estos labels en tu proyecto/grupo:

| Label | Color | Proposito |
|-------|-------|-----------|
| workflow::todo | #CCCCCC | Issues pendientes |
| workflow::in-progress | #428BCA | En desarrollo |
| workflow::review | #F0AD4E | En code review |
| workflow::done | #5CB85C | Completados |

### 2. Crear varios issues

Crea al menos 5 issues en el proyecto (pueden ser simples, no necesitan codigo real):

1. "Agregar validacion de inputs en API" — ~feature, ~backend, ~workflow::todo
2. "Crear pagina de login" — ~feature, ~frontend, ~workflow::todo
3. "Arreglar estilos del footer" — ~bug, ~frontend, ~workflow::todo
4. "Escribir README del proyecto" — ~documentation, ~workflow::todo
5. "Configurar health checks en Docker" — ~devops, ~workflow::todo

### 3. Crear Issue Board

1. **Project → Issues → Boards**
2. Veras un board basico con listas Open y Closed
3. Click en **Create board**
4. Nombre: `Kanban - Sprint 1`
5. Configurar listas:
   - Click **Create list** → Seleccionar label `workflow::todo`
   - Click **Create list** → Seleccionar label `workflow::in-progress`
   - Click **Create list** → Seleccionar label `workflow::review`
   - Click **Create list** → Seleccionar label `workflow::done`

### 4. Usar el board para gestionar trabajo

Simula el flujo de trabajo:

1. Arrastra "Crear pagina de login" de `todo` → `in-progress` (asignate el issue)
2. Arrastra "Agregar validacion de inputs" de `todo` → `in-progress`
3. Arrastra "Crear pagina de login" de `in-progress` → `review`
4. Arrastra "Crear pagina de login" de `review` → `done`
5. Mueve "Arreglar estilos del footer" a `in-progress`

### 5. Configurar scope del board

Puedes filtrar el board para mostrar solo issues que cumplan ciertos criterios:

1. En el board, click en el icono de filtro
2. Agrega filtros:
   - Milestone: Sprint 1
   - Labels: frontend
3. Veras solo los issues de frontend en Sprint 1

### 6. Board a nivel grupo (opcional)

Crea un board en **Bootcamp-Org → Issues → Boards** que muestre issues de todos los proyectos:

1. El scope incluye todos los proyectos del grupo
2. Util para PM/Lead que supervisan multiples equipos

### 7. Usar filtros en bloque

Selecciona multiples issues (checkbox) y arrastralos para cambiar su estado en bloque.

## Entregable
- Captura del board Kanban con al menos 3 listas y issues distribuidos
- Captura del board filtrado (ej: solo issues de frontend)
- Explicacion breve: Como ayuda un board Kanban en la gestion de proyectos?

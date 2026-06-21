# Practica 03 — Permisos y Roles

## Objetivo
Configurar miembros con diferentes roles en grupos y proyectos, verificando permisos heredados.

## Instrucciones

### 1. Crear usuarios adicionales

Como admin (root):

1. **Admin Area → Users → New user**
2. Crear usuarios:
   - `developer1` / developer1@bootcamp.local / Developer One
   - `maintainer1` / maintainer1@bootcamp.local / Maintainer One
   - `reporter1` / reporter1@bootcamp.local / Reporter One

### 2. Agregar miembros al grupo raiz

1. Ve a **Bootcamp-Org → Members → Invite members**
2. Agrega:
   - `maintainer1` con rol **Maintainer**
   - `developer1` con rol **Developer**
   - `reporter1` con rol **Reporter**

### 3. Verificar herencia

Inicia sesion como cada usuario y verifica que permisos tienen en los proyectos:

| Usuario | Puede push? | Puede crear MR? | Puede ver issues? | Puede gestionar miembros? |
|---------|------------|-----------------|-------------------|--------------------------|
| developer1 | Si (no en protegidas) | Si | Si | No |
| maintainer1 | Si (todas) | Si | Si | Si |
| reporter1 | No | No | Si | No |

### 4. Permisos granulares en proyecto especifico

1. Ve a **Bootcamp-Org / devops / infrastructure**
2. **Settings → Members**
3. Agrega a `reporter1` como **Developer** en ESTE proyecto especifico
4. Verifica que `reporter1` ahora puede hacer push SOLO en `infrastructure`
5. Verifica que en otros proyectos (ej: `web-app`) sigue siendo Reporter

### 5. Compartir proyecto con grupo externo

1. Crea un grupo `equipo-movil` (fuera de Bootcamp-Org)
2. Agrega algunos miembros
3. En el proyecto `frontend/mobile-app` → **Settings → Members → Invite a group**
4. Invita `equipo-movil` con rol **Developer**
5. Verifica que los miembros de `equipo-movil` pueden acceder a `mobile-app`

## Entregable
- Captura de **Bootcamp-Org → Members** mostrando los miembros y sus roles
- Captura de `repository` files para cada usuario mostrando diferentes niveles de acceso
- Explicacion breve de la diferencia entre permisos heredados y permisos directos

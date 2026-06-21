# 03 — Visibilidad y Permisos en GitLab

## Objetivos

- Comprender los niveles de visibilidad
- Conocer los roles de miembros y sus capacidades
- Configurar permisos a nivel proyecto y grupo
- Compartir proyectos con grupos externos

## Niveles de Visibilidad

### Private (Privado)
- Solo miembros explicitos pueden ver y acceder
- No listado en busquedas publicas
- Requiere autenticacion para clonar (HTTP o SSH)

### Internal (Interno)
- Cualquier usuario autenticado en la instancia puede ver
- No visible para usuarios no autenticados
- Util en empresas donde todos los empleados tienen cuenta

### Public (Publico)
- Visible para cualquier persona, incluso sin autenticacion
- Clonacion anonima permitida
- Listado en busquedas publicas
- Solo el owner/admin puede cambiar a este nivel

## Roles de Miembros

GitLab define 5 roles jerarquicos con permisos incrementales:

| Permiso | Guest | Reporter | Developer | Maintainer | Owner |
|---------|-------|----------|-----------|------------|-------|
| Ver proyecto | Si | Si | Si | Si | Si |
| Crear issues | Si | Si | Si | Si | Si |
| Ver merge requests | No | Si | Si | Si | Si |
| Comentar MR/issues | Si | Si | Si | Si | Si |
| Ver codigo | No | Si | Si | Si | Si |
| Push a ramas no protegidas | No | No | Si | Si | Si |
| Crear MRs | No | No | Si | Si | Si |
| Push a ramas protegidas | No | No | No | Si | Si |
| Gestionar miembros | No | No | No | Si | Si |
| Cambiar visibilidad | No | No | No | Si | Si |
| Eliminar proyecto | No | No | No | Si | Si |

### Descripcion de Roles

**Guest (Invitado):**
Ideal para stakeholders, clientes. Puede ver issues y dejar comentarios, pero no acceder al codigo.

**Reporter (Reportador):**
Puede ver el codigo y el progreso. Ideal para QA, project managers. No puede hacer push.

**Developer (Desarrollador):**
Trabaja en el codigo. Puede crear ramas, hacer push (excepto a protegidas), crear MRs. Rol por defecto para desarrolladores.

**Maintainer (Mantenedor):**
Puede hacer merge, push a ramas protegidas, gestionar el proyecto. Ideal para tech leads. No puede cambiar configuracion critica como visibilidad.

**Owner (Propietario):**
Control total. Solo disponible a nivel grupo (no proyecto). Puede transferir ownership, eliminar el grupo.

## Herencia de Permisos

Los permisos fluyen hacia abajo en la jerarquia:

```
Grupo Padre (Owner)
├── Owner en Grupo Padre → Owner en todos los subgrupos y proyectos
├── Maintainer en Grupo Padre → Maintainer en todos los subgrupos
└── Developer en Grupo Padre → Developer en todos los subgrupos
```

Los subgrupos pueden agregar mas permisos, pero no reducir los heredados.

## Compartir Proyectos con Grupos

Puedes invitar a un grupo entero a un proyecto especifico:

1. **Project → Settings → Members → Invite a group**
2. Seleccionar grupo
3. Elegir rol maximo
4. Fecha de expiracion (opcional)

Esto es util cuando:
- Un equipo necesita acceso a un proyecto de otro equipo
- Proyectos cross-funcionales que involucran multiples areas

## Buenas Practicas

- **Principio de minimo privilegio**: Asignar el rol minimo necesario
- Usar grupos para gestionar permisos en lugar de asignar usuarios individualmente
- Revisar miembros periodicamente (especialmente con fechas de expiracion)
- Documentar la estructura de permisos
- No compartir cuentas de administrador
- Usar tokens de acceso personal con scopes limitados para scripts y APIs

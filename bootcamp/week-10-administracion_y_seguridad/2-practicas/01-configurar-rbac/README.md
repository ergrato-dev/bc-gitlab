# Práctica 01 — Configurar RBAC: Roles y Permisos

## Objetivo

Crear un esquema completo de RBAC para un equipo de desarrollo simulado.

## Escenario

Equipo "Alpha" con 6 miembros:
- 1 Tech Lead
- 2 Developers senior
- 2 Developers junior
- 1 QA Engineer

## Instrucciones

### Paso 1: Crear grupo y proyecto
1. Crea un grupo llamado `alpha-team`
2. Dentro del grupo, crea un proyecto `backend-api`

### Paso 2: Asignar roles
| Miembro | Rol en grupo | Rol en proyecto |
|---------|-------------|-----------------|
| Tech Lead | Owner | Maintainer |
| Dev Senior 1 | Maintainer | Maintainer |
| Dev Senior 2 | Maintainer | Maintainer |
| Dev Junior 1 | Developer | Developer |
| Dev Junior 2 | Developer | Developer |
| QA Engineer | Reporter | Reporter |

¿Por qué el QA es Reporter en lugar de Developer? Porque solo necesita ver issues y pipelines, no modificar código.

### Paso 3: Configurar Protected Branches
1. Ve a Settings → Repository → Protected branches
2. Protege `main` permitiendo push/merge solo a Maintainers
3. Protege `develop` permitiendo push a Developers y merge solo a Maintainers

### Paso 4: Verificar permisos
Para cada rol, verifica qué puede y qué no puede hacer:
- ¿Puede un Developer mergear a `main`?
- ¿Puede el QA hacer push a `develop`?
- ¿Puede el Tech Lead eliminar el proyecto?

### Paso 5: Documentar
Crea una matriz de permisos en formato tabla documentando cada rol y sus capacidades.

## Preguntas de reflexión
- ¿Cuál es la diferencia entre dar permisos a nivel de grupo vs proyecto?
- ¿En qué caso usarías una protected branch con patrón `release/*`?
- ¿Qué rol asignarías a un pasante de 3 meses?

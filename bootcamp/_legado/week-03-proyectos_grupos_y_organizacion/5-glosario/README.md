# 📖 Glosario — Semana 03: Proyectos, Grupos y Organización

Términos técnicos clave de la semana, con definiciones, ejemplos y referencias cruzadas.

---

## Índice alfabético

| Término | Letra |
|---------|-------|
| [Access Level](#access-level) | A |
| [Approval Rule](#approval-rule) | A |
| [Archivar (Archive)](#archivar) | A |
| [Branch Protection](#branch-protection) | B |
| [CODEOWNERS](#codeowners) | C |
| [Developer](#developer) | D |
| [Feature Branch](#feature-branch) | F |
| [Force Push](#force-push) | F |
| [Git Flow](#git-flow) | G |
| [GitHub Flow](#github-flow) | G |
| [GitLab Flow](#gitlab-flow) | G |
| [Group (Grupo)](#group) | G |
| [Guest](#guest) | G |
| [Herencia de Permisos](#herencia-de-permisos) | H |
| [Internal](#internal) | I |
| [Maintainer](#maintainer) | M |
| [Merge Request (MR)](#merge-request) | M |
| [Namespace](#namespace) | N |
| [Owner](#owner) | O |
| [Personal Access Token](#personal-access-token) | P |
| [Private](#private) | P |
| [Protected Branch](#protected-branch) | P |
| [Public](#public) | P |
| [Reporter](#reporter) | R |
| [Rol de Miembro](#rol-de-miembro) | R |
| [Slug](#slug) | S |
| [Subgroup (Subgrupo)](#subgroup) | S |
| [Transferir Proyecto](#transferir-proyecto) | T |
| [Trunk-Based Development](#trunk-based-development) | T |
| [Visibilidad](#visibilidad) | V |
| [Wildcard (Rama)](#wildcard) | W |

---

## A

### Access Level

Valor numérico que representa el nivel de permisos de un miembro en GitLab. La API de GitLab usa estos valores en lugar de nombres de rol.

| Rol | access_level |
|-----|-------------|
| Guest | 10 |
| Reporter | 20 |
| Developer | 30 |
| Maintainer | 40 |
| Owner | 50 |

```bash
# Agregar usuario como Developer (access_level=30) via API
curl --request POST \
  --header "PRIVATE-TOKEN: $TOKEN" \
  --data "user_id=7&access_level=30" \
  "http://localhost/api/v4/groups/42/members"
```

Ver también: [Rol de Miembro](#rol-de-miembro)

---

### Approval Rule

Regla que establece cuántas aprobaciones (y opcionalmente de quiénes) se necesitan antes de poder hacer merge de un Merge Request.

En GitLab CE: se puede configurar el número mínimo de approvals.
En GitLab EE: se pueden definir grupos específicos de aprobadores, approvals condicionales por tipo de archivo, etc.

```
Proyecto → Settings → Merge requests → Approval rules
```

Ver también: [CODEOWNERS](#codeowners), [Merge Request](#merge-request)

---

### Archivar

Poner un proyecto en **modo de solo lectura**. El código sigue siendo visible y clonable, pero no se pueden crear Issues, MRs, ni hacer push de nuevos commits.

Se usa para proyectos finalizados que aún sirven como referencia. Se diferencia de eliminar en que el código no se pierde y sigue siendo accesible.

```
Proyecto → Settings → General → Advanced → Archive project
```

Opuesto: **Unarchive** restaura el proyecto a modo normal.

---

## B

### Branch Protection

Configuración que aplica restricciones sobre quién puede hacer push, merge o force push a una rama específica. Es la herramienta principal para implementar code review obligatorio.

Las protecciones se definen por proyecto y por rama (o patrón wildcard).

```
Proyecto → Settings → Repository → Protected branches
```

```bash
# Via API: proteger main (push=Nobody, merge=Maintainers)
curl --request POST \
  --header "PRIVATE-TOKEN: $TOKEN" \
  --data "name=main&push_access_level=0&merge_access_level=40" \
  "http://localhost/api/v4/projects/42/protected_branches"
```

Ver también: [Protected Branch](#protected-branch), [Wildcard](#wildcard)

---

## C

### CODEOWNERS

Archivo en `.gitlab/CODEOWNERS`, `docs/CODEOWNERS` o `CODEOWNERS` (raíz) que define qué usuarios o grupos son "propietarios" de archivos o directorios específicos.

Cuando un MR modifica un archivo con owner definido, GitLab agrega automáticamente a ese owner como reviewer requerido. El MR no puede mergearse hasta que el owner apruebe.

```
# Sintaxis del archivo CODEOWNERS
*              @tech-lead          # Todos los archivos
*.tf           @devops-team        # Archivos Terraform
src/auth/      @security-team      # Directorio de autenticación
.gitlab-ci.yml @devops-lead        # Pipeline de CI
```

Requiere tener habilitado "Require approval from code owners" en la configuración de la rama protegida.

Ver también: [Approval Rule](#approval-rule), [Protected Branch](#protected-branch)

---

## D

### Developer

Rol de GitLab con nivel de acceso 30. Es el rol estándar para miembros del equipo de desarrollo.

**Puede:**
- Ver y clonar el código
- Crear ramas (no protegidas) y hacer push a ellas
- Crear y gestionar Merge Requests
- Crear y gestionar Issues, Milestones
- Ejecutar pipelines de CI/CD manualmente

**No puede:**
- Push a ramas protegidas (por defecto)
- Hacer merge a ramas protegidas
- Gestionar miembros del proyecto o grupo
- Acceder a Settings del proyecto

Ver también: [Rol de Miembro](#rol-de-miembro), [Access Level](#access-level)

---

## F

### Feature Branch

Rama creada específicamente para desarrollar una nueva funcionalidad, fix o mejora. Se crea desde una rama base (`main` o `develop`), se trabaja en ella, y se integra via Merge Request.

**Convención de nombres recomendada:**
```
feature/nombre-descriptivo    ← Nueva funcionalidad
fix/descripcion-del-bug       ← Corrección de bug
docs/que-se-documenta         ← Solo documentación
chore/tarea                   ← Dependencias, configuración
refactor/modulo               ← Sin cambio de comportamiento externo
```

Las feature branches no están protegidas — cualquier Developer puede hacer push a ellas.

Ver también: [Git Flow](#git-flow), [GitHub Flow](#github-flow)

---

### Force Push

Operación `git push --force` que reescribe el historial remoto. Puede destruir commits que otros miembros del equipo ya tienen localmente.

En GitLab, el force push a ramas protegidas está **deshabilitado por defecto** y se puede habilitar explícitamente en la configuración de la rama:

```
Protected branches → allow_force_push: true
```

⚠️ **Peligroso:** Solo habilitar en casos excepcionales y con coordinación del equipo.

---

## G

### Git Flow

Modelo de branching propuesto por Vincent Driessen (2010). Define ramas permanentes (`main`, `develop`) y ramas de soporte de vida limitada (`feature/*`, `release/*`, `hotfix/*`).

**Ideal para:** Software con releases versionados (apps móviles, librerías, software empaquetado).
**No recomendado para:** Servicios web con deploy continuo (demasiada complejidad).

Ver también: [GitHub Flow](#github-flow), [GitLab Flow](#gitlab-flow), [Trunk-Based Development](#trunk-based-development)

---

### GitHub Flow

Estrategia simplificada con **una sola rama permanente: `main`**. Toda feature se desarrolla en una rama corta y se integra via Merge/Pull Request. `main` siempre está en estado desplegable.

**Flujo:** `main` → feature branch → commits → MR → code review → merge → deploy

**Ideal para:** Servicios web con deploy continuo, equipos pequeños/medianos.

Ver también: [Git Flow](#git-flow), [GitLab Flow](#gitlab-flow)

---

### GitLab Flow

Extensión de GitHub Flow propuesta por GitLab Inc. Añade ramas de ambiente (`pre-production`, `production`) para deployments multi-ambiente, o ramas de release (`1-0-stable`) para soporte de versiones múltiples.

Ver también: [GitHub Flow](#github-flow)

---

### Group

Namespace en GitLab que agrupa proyectos y subgrupos relacionados. Permite gestionar permisos, variables de CI/CD, runners y webhooks de forma centralizada para todos los proyectos del grupo.

```
URL de grupo: http://localhost/mi-empresa
              http://localhost/mi-empresa/backend  (subgrupo)
```

Los grupos pueden anidarse hasta 20 niveles de profundidad.

Ver también: [Subgroup](#subgroup), [Namespace](#namespace), [Herencia de Permisos](#herencia-de-permisos)

---

### Guest

Rol de GitLab con nivel de acceso 10. El más restrictivo.

**Puede:**
- Ver el proyecto (si tiene acceso)
- Crear y comentar Issues
- Ver la Wiki

**No puede:**
- Ver el código fuente
- Clonar el repositorio
- Ver ni crear Merge Requests
- Ver pipelines de CI/CD

**Caso de uso típico:** Clientes externos que siguen el progreso del proyecto vía Issues sin acceso al código.

Ver también: [Rol de Miembro](#rol-de-miembro)

---

## H

### Herencia de Permisos

Mecanismo por el cual los roles asignados a un grupo se propagan automáticamente hacia abajo a todos los subgrupos y proyectos del grupo.

**Reglas clave:**
1. Los roles fluyen **hacia abajo** (grupo → subgrupo → proyecto)
2. Un rol heredado **no puede reducirse** en niveles inferiores (solo aumentar)
3. El rol **efectivo** de un usuario en un proyecto es el **mayor** entre heredado y directo

```
empresa/ (Ana = Maintainer)
├── frontend/ (Bob = Developer)   ← Ana hereda Maintainer aquí también
│   └── web-app/                  ← Ana = Maintainer (heredado), Bob = Developer (heredado)
└── backend/                      ← Ana = Maintainer (heredado), Bob NO tiene acceso aquí
```

Ver también: [Group](#group), [Rol de Miembro](#rol-de-miembro)

---

## I

### Internal

Nivel de visibilidad en GitLab. Un proyecto o grupo `Internal` es visible para **cualquier usuario autenticado** en la instancia, sin necesitar ser miembro explícito.

Diferente de `Public` (visible sin autenticación) y `Private` (solo miembros explícitos).

⚠️ En instancias con registro público habilitado, `Internal` puede exponer contenido a usuarios externos que se registren.

Ver también: [Visibilidad](#visibilidad), [Private](#private), [Public](#public)

---

## M

### Maintainer

Rol de GitLab con nivel de acceso 40. El rol de tech lead o responsable del proyecto.

**Puede (además de Developer):**
- Push a ramas protegidas
- Hacer merge de MRs a cualquier rama
- Gestionar miembros del proyecto
- Configurar Protected Branches y Tags
- Acceder a Settings del proyecto
- Gestionar webhooks e integraciones

**No puede (solo Owner):**
- Cambiar la visibilidad del proyecto
- Eliminar el proyecto

Ver también: [Owner](#owner), [Rol de Miembro](#rol-de-miembro)

---

### Merge Request

Solicitud formal para integrar los cambios de una rama (source) a otra (target). Es el punto central del code review en GitLab.

Un MR puede tener:
- Descripción y template
- Revisores asignados (reviewers)
- Assignee (responsable de completar el MR)
- Aprobaciones requeridas (approval rules)
- Pipeline de CI/CD asociado
- CODEOWNERS como revisores automáticos
- Threads de discusión en líneas de código específicas

```
Proyecto → Merge requests → New merge request
  Source branch: feature/mi-feature
  Target branch: main
```

Ver también: [Approval Rule](#approval-rule), [CODEOWNERS](#codeowners), [Protected Branch](#protected-branch)

---

## N

### Namespace

El "espacio de nombres" que define la URL y la jerarquía donde vive un proyecto o grupo en GitLab.

```
http://localhost / namespace / proyecto
                    ───────────────────
                    Puede ser:
                    • Usuario:   /root/proyecto
                    • Grupo:     /empresa/proyecto
                    • Subgrupo:  /empresa/backend/proyecto
```

Un proyecto solo puede estar en un namespace a la vez. Transferir un proyecto cambia su namespace (y su URL).

Ver también: [Group](#group), [Subgroup](#subgroup), [Transferir Proyecto](#transferir-proyecto)

---

## O

### Owner

Rol de GitLab con nivel de acceso 50. El nivel más alto de permisos. **Solo disponible a nivel de grupo**, no de proyecto directamente.

**Puede (además de Maintainer):**
- Cambiar la visibilidad del grupo
- Eliminar el grupo (y todos sus proyectos y subgrupos)
- Transferir el grupo a otro grupo padre
- Cambiar el namespace (URL) del grupo

El creador de un grupo es automáticamente Owner del mismo.

Ver también: [Maintainer](#maintainer), [Rol de Miembro](#rol-de-miembro)

---

## P

### Personal Access Token

Token de autenticación personal que permite acceder a la API de GitLab y a repositorios sin usar contraseña. Reemplaza las credenciales usuario/contraseña en scripts y herramientas de automatización.

```
Configuración → Access Tokens → Add new token

Scopes disponibles:
  api           → Acceso completo a la API (CRUD de proyectos, grupos, etc.)
  read_api      → Solo lectura de la API
  read_user     → Solo leer información del usuario actual
  read_repository / write_repository → Clonar y push
  read_registry / write_registry → Container Registry
```

⚠️ Siempre poner fecha de expiración. Nunca commitear tokens al repositorio.

---

### Private

Nivel de visibilidad más restrictivo. Un proyecto o grupo `Private` solo es accesible para los miembros que han sido **explícitamente invitados**.

Es el nivel de visibilidad por defecto recomendado para proyectos de empresa.

Ver también: [Visibilidad](#visibilidad), [Internal](#internal), [Public](#public)

---

### Protected Branch

Rama en GitLab con restricciones de acceso configuradas. Controla quién puede hacer push directo, quién puede hacer merge, y si se permite force push.

Configuración típica para `main` en producción:
```
Allowed to merge:     Maintainers      (solo tech leads pueden integrar)
Allowed to push:      Nobody           (nadie puede saltar el proceso de MR)
Allow force push:     No               (el historial es inmutable)
```

Ver también: [Branch Protection](#branch-protection), [Wildcard](#wildcard), [CODEOWNERS](#codeowners)

---

### Public

Nivel de visibilidad más permisivo. Un proyecto o grupo `Public` es visible para **cualquier persona en internet**, incluso sin cuenta de GitLab.

El clonado es posible sin autenticación (`git clone` anónimo).

Solo Owner o Admin puede cambiar un proyecto a `Public` en GitLab CE.

Ver también: [Visibilidad](#visibilidad)

---

## R

### Reporter

Rol de GitLab con nivel de acceso 20. Puede ver y clonar el código, pero no puede modificarlo.

**Puede (además de Guest):**
- Clonar el repositorio (read-only)
- Ver y comentar Merge Requests
- Ver pipelines y descargar artefactos de CI/CD
- Ver el Container Registry

**No puede:**
- Hacer push de ningún tipo
- Crear Merge Requests

**Caso de uso típico:** QA engineers, Project Managers, auditores que necesitan visibilidad del código sin poder modificarlo.

Ver también: [Rol de Miembro](#rol-de-miembro)

---

### Rol de Miembro

Nivel de acceso asignado a un usuario en un proyecto o grupo de GitLab. Determina qué acciones puede realizar. Existen 5 roles en orden ascendente de permisos:

```
Guest (10) < Reporter (20) < Developer (30) < Maintainer (40) < Owner (50)
```

El rol se puede asignar a nivel de grupo (heredado hacia abajo) o directamente a un proyecto (específico).

Ver también: [Guest](#guest), [Reporter](#reporter), [Developer](#developer), [Maintainer](#maintainer), [Owner](#owner), [Herencia de Permisos](#herencia-de-permisos)

---

## S

### Slug

Versión de un nombre compatible con URLs: en minúsculas, sin espacios (reemplazados por guiones), sin caracteres especiales.

```
"Mi Empresa Backend"  →  mi-empresa-backend   (slug)
"API Gateway v2"      →  api-gateway-v2        (slug)
```

GitLab auto-genera el slug al escribir el nombre de proyecto o grupo. El slug define la URL y no debe cambiarse después de crear el proyecto (rompe URLs existentes).

---

### Subgroup

Grupo anidado dentro de otro grupo (o subgrupo). Hereda los miembros, permisos y parte de la configuración del grupo padre.

```
empresa/               ← Grupo raíz
└── backend/           ← Subgrupo (nivel 1)
    └── microservicios/ ← Sub-subgrupo (nivel 2)
        └── auth/       ← Proyecto
```

La visibilidad de un subgrupo nunca puede ser más permisiva que la del grupo padre.

GitLab CE soporta hasta 20 niveles de anidamiento.

Ver también: [Group](#group), [Herencia de Permisos](#herencia-de-permisos)

---

## T

### Transferir Proyecto

Mover un proyecto de un namespace a otro (de usuario a grupo, o entre grupos). La URL anterior redirige automáticamente, pero las referencias hardcodeadas en scripts y webhooks se rompen.

```
Proyecto → Settings → General → Advanced → Transfer project
→ Seleccionar nuevo namespace (usuario o grupo)
→ Escribir el nombre del proyecto para confirmar
```

⚠️ Requiere ser Maintainer en el proyecto origen y al menos Developer en el namespace destino.

Ver también: [Namespace](#namespace)

---

### Trunk-Based Development

Estrategia de branching donde todos los desarrolladores trabajan sobre una única rama principal (`main` o `trunk`). Las ramas de feature tienen vida muy corta (menos de 24 horas) o no existen — los desarrolladores hacen commits directamente a `main`.

Requiere:
- Suite de tests automatizados robusta
- Feature flags para código incompleto
- Cultura de commits frecuentes y pequeños
- Deploy continuo automatizado

**Ideal para:** Equipos de alto rendimiento con madurez de CI/CD. No recomendado para equipos en formación.

Ver también: [Git Flow](#git-flow), [GitHub Flow](#github-flow)

---

## V

### Visibilidad

Configuración que determina quién puede ver un proyecto o grupo en GitLab. Existen tres niveles:

| Nivel | Quién puede ver |
|-------|----------------|
| Private | Solo miembros explícitos |
| Internal | Cualquier usuario autenticado en la instancia |
| Public | Cualquier persona (incluso sin cuenta) |

La visibilidad de un subgrupo o proyecto **no puede ser más permisiva** que la del grupo padre.

```
Settings → General → Visibility, project features, permissions
→ Visibility Level: ● Private / ○ Internal / ○ Public
```

Ver también: [Private](#private), [Internal](#internal), [Public](#public)

---

## W

### Wildcard

Patrón con comodín (`*`) usado en la configuración de Protected Branches para proteger múltiples ramas a la vez.

```
Patrón        Aplica a
────────────  ─────────────────────────────────
release/*     release/1.0, release/2.0-rc1
hotfix/*      hotfix/login-bug, hotfix/payment
v*            v1.0.0, v2.3.1, v3.0.0-beta
*-stable      1-0-stable, 2-0-stable
```

El wildcard `*` coincide con cualquier cadena de caracteres (excepto `/`).

Ver también: [Protected Branch](#protected-branch), [Branch Protection](#branch-protection)

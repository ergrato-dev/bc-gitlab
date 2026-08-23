# 📖 02 — Grupos y Subgrupos en GitLab CE

## 🎯 Objetivos de aprendizaje

- ✅ Entender la jerarquía de namespaces en GitLab (usuario → grupo → subgrupo → proyecto)
- ✅ Crear grupos y subgrupos con configuraciones apropiadas
- ✅ Comprender la herencia de miembros, permisos y configuraciones
- ✅ Configurar ajustes compartidos a nivel de grupo (CI/CD variables, runners, webhooks)
- ✅ Gestionar grupos via API REST

---

## 🤔 ¿Qué es un Grupo en GitLab?

Un grupo es un **namespace organizacional** que agrupa proyectos relacionados y permite gestionar permisos de forma centralizada. Mientras que un proyecto es la unidad de trabajo, el grupo es la unidad organizacional.

**Analogía:** Un grupo en GitLab es como un departamento en una empresa. El departamento de Ingeniería agrupa todos los proyectos de ingeniería, tiene empleados (miembros con roles), normas compartidas (políticas de CI/CD, variables de entorno) y puede tener subdepartamentos (subgrupos: Frontend, Backend, DevOps). Agregar a alguien al departamento le da acceso automático a todos los proyectos del departamento, sin necesidad de invitarlos uno por uno.

---

## 🏗️ Jerarquía de Namespaces

GitLab organiza todo en una jerarquía de namespaces:

```
Nivel 0:  gitlab.com (o tu instancia: localhost)
           │
Nivel 1:  mi-empresa/                    ← Grupo raíz
           ├── frontend/                  ← Subgrupo (nivel 2)
           │   ├── web-app/              ← Proyecto
           │   └── landing-page/         ← Proyecto
           ├── backend/                   ← Subgrupo (nivel 2)
           │   ├── api-gateway/           ← Proyecto
           │   └── auth-service/          ← Proyecto
           │       └── internal/          ← Subgrupo (nivel 3)
           │           └── crypto-utils/  ← Proyecto (nivel 4)
           └── devops/                    ← Subgrupo (nivel 2)
               ├── infrastructure/        ← Proyecto (Terraform)
               └── ci-cd-templates/       ← Proyecto (shared pipelines)
```

GitLab CE soporta hasta **20 niveles** de subgrupos anidados, aunque en la práctica raramente se necesitan más de 4.

---

## ➕ Crear un Grupo

### Via Web UI

1. Click en el ícono `+` de la barra superior → **New group**
2. Seleccionar **Create group**
3. Completar:

```
Group name:    mi-empresa
Group URL:     mi-empresa           ← Será /mi-empresa en la URL
Description:   Organización principal de la empresa
Visibility:    Private
```

4. Click **Create group**

### Via API

```bash
# ¿QUÉ HACE?: Crea un grupo raíz
# ¿POR QUÉ?: Permite automatizar la creación de la estructura organizacional
# ¿PARA QUÉ?: Reproducir la misma estructura en staging y producción sin clicks
curl --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "mi-empresa",
    "path": "mi-empresa",
    "description": "Organización principal",
    "visibility": "private"
  }' \
  "http://localhost/api/v4/groups"
```

Response importante:
```json
{
  "id": 42,        ← Necesitas este ID para crear subgrupos
  "name": "mi-empresa",
  "path": "mi-empresa",
  "full_path": "mi-empresa"
}
```

---

## ➕ Crear un Subgrupo

Un subgrupo es simplemente un grupo con un `parent_id`.

### Via Web UI

1. Navegar al grupo padre (ej: `mi-empresa`)
2. Click en `+` → **New subgroup**
3. Completar nombre, URL y visibilidad
4. Click **Create subgroup**

> ⚠️ La visibilidad de un subgrupo **no puede ser más permisiva** que la del grupo padre. Si el grupo padre es Private, los subgrupos solo pueden ser Private.

### Via API

```bash
# ¿QUÉ HACE?: Crea un subgrupo dentro del grupo con id=42
# ¿POR QUÉ?: El parent_id establece la relación jerárquica
# ¿PARA QUÉ?: Construir la estructura completa programáticamente
curl --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "frontend",
    "path": "frontend",
    "parent_id": 42,
    "visibility": "private"
  }' \
  "http://localhost/api/v4/groups"
```

---

## 👥 Gestión de Miembros en Grupos

### Agregar miembros

```
Grupo → Members → Invite members

Campos:
  GitLab member or Email address: usuario@ejemplo.com
  Choose a role: Developer
  Access expiration date: 2025-12-31   ← Opcional, recomendado para consultores
```

Los miembros del grupo automáticamente **heredan** acceso a todos los proyectos y subgrupos del grupo.

### Via API

```bash
# ¿QUÉ HACE?: Agrega al usuario con user_id=7 al grupo como Developer
# ¿POR QUÉ?: access_level=30 corresponde a Developer (ver tabla de access levels)
# ¿PARA QUÉ?: Onboarding automatizado de nuevos miembros del equipo
curl --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data "user_id=7&access_level=30" \
  "http://localhost/api/v4/groups/42/members"
```

**Tabla de access_level:**

| Rol | access_level |
|-----|-------------|
| Guest | 10 |
| Reporter | 20 |
| Developer | 30 |
| Maintainer | 40 |
| Owner | 50 |

---

## 🔄 Herencia en la Jerarquía

La herencia es uno de los conceptos más importantes de la gestión de grupos en GitLab:

### Qué se hereda

```
mi-empresa/ (grupo raíz)
│
│  → Ana es Owner aquí
│     ↓ Ana hereda Owner en TODOS los subgrupos y proyectos
│
├── frontend/
│   │  → Bob es Maintainer aquí
│   │     ↓ Bob hereda Maintainer en todos los proyectos de frontend/
│   │
│   ├── web-app/        ← Ana=Owner, Bob=Maintainer
│   └── landing-page/   ← Ana=Owner, Bob=Maintainer
│
└── backend/
    │  → Carlos es Developer aquí (específico a backend/)
    │
    ├── api-gateway/    ← Ana=Owner, Carlos=Developer
    └── auth-service/   ← Ana=Owner, Carlos=Developer
```

### Reglas de herencia

1. **Los roles fluyen hacia abajo**, nunca hacia arriba
2. **No se puede reducir** el rol heredado en subgrupos (solo aumentar)
3. Un Developer en el grupo padre **puede ser promovido** a Maintainer en un proyecto específico
4. Un Maintainer en el grupo padre **no puede ser degradado** a Developer en un subgrupo

### Ejemplo práctico

```bash
# ¿QUÉ HACE?: Lista los miembros efectivos de un proyecto, incluyendo heredados
# ¿POR QUÉ?: "all" incluye los heredados del grupo, no solo los directos
# ¿PARA QUÉ?: Auditar quién realmente tiene acceso a un proyecto específico
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/123/members/all"
```

---

## ⚙️ Configuración Compartida a Nivel de Grupo

Una de las ventajas más poderosas de los grupos es que la configuración se comparte hacia abajo:

### CI/CD Variables de grupo

Variables disponibles en todos los proyectos del grupo:

```
Grupo → Settings → CI/CD → Variables → Add variable

Key:       DOCKER_REGISTRY
Value:     registry.mi-empresa.com
Type:      Variable
Protected: ✓    ← Solo disponible en ramas/tags protegidos
Masked:    ✓    ← No aparece en los logs del pipeline
```

Esto evita definir la misma variable en 20 proyectos distintos.

### Runners de grupo

Los runners registrados a nivel de grupo están disponibles para todos los proyectos del grupo:

```
Grupo → Settings → CI/CD → Runners

Aquí puedes:
  - Ver runners disponibles para el grupo
  - Habilitar/deshabilitar runners específicos
  - Ver runners heredados de instancia
```

### Webhooks de grupo

Webhooks que se disparan para eventos de cualquier proyecto del grupo:

```
Grupo → Settings → Webhooks → Add new webhook

URL:    https://api.mi-empresa.com/gitlab-events
Trigger:
  ✓ Push events
  ✓ Merge request events
  ✓ Pipeline events
```

---

## 🖼️ Diagrama: Jerarquía de Grupos

![Diagrama de jerarquía de grupos en GitLab](../0-assets/01-jerarquia-grupos.svg)

> **Diagrama:** Ilustra la jerarquía grupo → subgrupo → proyecto y cómo fluyen hacia abajo los permisos, variables CI/CD y runners. También muestra que la visibilidad solo puede ser igual o más restrictiva en subgrupos respecto al padre.

---

## 🔍 Explorar y Buscar Grupos

```bash
# ¿QUÉ HACE?: Lista todos los grupos accesibles para el token actual
# ¿POR QUÉ?: search= filtra por nombre, útil en organizaciones con muchos grupos
# ¿PARA QUÉ?: Encontrar el ID de un grupo para usarlo en otras llamadas API
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/groups?search=frontend&per_page=20"

# ¿QUÉ HACE?: Lista los subgrupos directos de un grupo
# ¿POR QUÉ?: Permite mapear la jerarquía desde código
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/groups/42/subgroups"

# ¿QUÉ HACE?: Lista todos los proyectos de un grupo (incluyendo subgrupos)
# ¿POR QUÉ?: include_subgroups=true traversa toda la jerarquía
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/groups/42/projects?include_subgroups=true"
```

---

## 📐 Buenas Prácticas de Estructura de Grupos

### Patrón 1: Por producto/dominio (recomendado para empresas)

```
empresa/
├── producto-web/
│   ├── frontend/
│   └── backend/
├── producto-mobile/
│   ├── android/
│   └── ios/
└── plataforma/
    ├── infrastructure/
    └── shared-services/
```

### Patrón 2: Por equipo

```
empresa/
├── equipo-frontend/
├── equipo-backend/
└── equipo-devops/
```

### Patrón 3: Híbrido (para organizaciones medianas)

```
empresa/
├── <nombre-producto>/
│   ├── <nombre-equipo>/
│   │   └── <proyecto>/
│   └── shared/
└── infra/
```

### Reglas generales

- **Máximo 3-4 niveles** de profundidad (más que eso es difícil de navegar)
- **Nombres kebab-case**: `mi-empresa`, `equipo-backend`, no `MiEmpresa` ni `equipo_backend`
- **Visibilidad Private** por defecto en grupos de empresa
- **No crear grupos por usuario** — los usuarios ya tienen su namespace personal
- **Grupo `shared/`** para código compartido entre equipos: design systems, contracts, utilities

---

## 🤔 Preguntas de reflexión

1. Tienes una empresa con 5 productos distintos, cada uno con equipos de frontend y backend. ¿Usarías estructura por producto o por equipo? ¿Qué ventajas tiene cada opción en términos de gestión de permisos?

2. ¿Por qué GitLab no permite que un subgrupo tenga visibilidad `public` si su grupo padre es `private`? ¿Qué problema de seguridad evita esta restricción?

3. Un miembro es `Maintainer` en el grupo `empresa/backend`. Un proyecto `empresa/frontend/storefront` necesita urgentemente su ayuda. ¿Qué opciones tienes para darle acceso sin romper el principio de mínimo privilegio?

4. Tienes una variable `DATABASE_URL` definida tanto en el grupo como en un proyecto específico del grupo. ¿Cuál tiene precedencia en el pipeline de CI/CD? ¿Es ese el comportamiento que esperarías?

5. ¿Cuál es la diferencia entre agregar a un usuario directamente a un proyecto vs. invitar a su grupo a un proyecto? ¿En qué situación usarías cada enfoque?

---

## 📚 Recursos adicionales

- [GitLab Groups Documentation](https://docs.gitlab.com/ee/user/group/)
- [GitLab API — Groups](https://docs.gitlab.com/ee/api/groups.html)
- [Group-level CI/CD variables](https://docs.gitlab.com/ee/ci/variables/#add-a-cicd-variable-to-a-group)
- [Group runners](https://docs.gitlab.com/ee/ci/runners/runners_scope.html#group-runners)
- [GitLab Permissions Reference](https://docs.gitlab.com/ee/user/permissions.html)

---

⬅️ **Lección anterior:** [01 — Proyectos en GitLab](./01-proyectos.md)
➡️ **Siguiente lección:** [03 — Visibilidad y Permisos](./03-visibilidad-y-permisos.md)

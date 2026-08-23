# Grupos y subgrupos

> Un grupo es un contenedor con miembros, ajustes y descendientes. Todo lo que decides en él lo heredan sus hijos, y por eso decidirlo mal se paga en cadena.

## 🎯 Objetivos

- Crear un subgrupo por API y por interfaz, y saber qué hereda del padre
- Enumerar los ajustes de grupo que existen en CE y qué controlan
- Restringir quién puede crear proyectos y subgrupos, y por qué es lo primero que se toca
- Entender el borrado programado de grupos y cómo deshacerlo

---

## 1. Qué problema resuelve

Una organización con quince repositorios y ocho personas no tiene un problema de repositorios: tiene un problema de **repetición**. Si los permisos se dan proyecto a proyecto, cada persona que entra o sale obliga a quince operaciones, y la que se olvida es justo la que importa.

El grupo resuelve eso invirtiendo el sentido: los permisos se dan **una vez, arriba**, y bajan solos. Con subgrupos, además, se puede matizar: acceso amplio en el tronco, acceso estrecho en la rama que lo necesita.

La contrapartida, que conviene tener presente desde hoy: **la herencia solo suma**. Un subgrupo puede dar más acceso que su padre, nunca menos. Si alguien es Developer del grupo raíz, lo es de todo lo que cuelgue, y no hay ajuste en el hijo que se lo quite. Diseñar el árbol es, sobre todo, decidir qué se pone en la raíz.

---

## 2. Cómo funciona

### 2.1 La jerarquía

```
plataforma-biblioteca/          ← grupo raíz (top-level group)
├── app                         ← proyecto
├── infra/                      ← subgrupo
└── ci/                         ← subgrupo
    ├── componentes             ← proyecto
    └── automatizacion          ← proyecto
```

Vocabulario que la documentación usa sin avisar:

| Término | Qué significa |
|---|---|
| **Grupo raíz** (*top-level group*) | El que no tiene padre. Algunos ajustes solo existen aquí |
| **Subgrupo** (*subgroup*) | Cualquier grupo con padre |
| **Antepasados** (*ancestors*) | La cadena hacia arriba: padre, abuelo… |
| **Descendientes** (*descendants*) | Todo lo que cuelga hacia abajo, a cualquier profundidad |
| **`root_ancestor`** | El grupo raíz del árbol. Aparece en la API y en los mensajes de error |

El límite de anidamiento en la versión fijada es de **20 antepasados** (`Namespace::NUMBER_OF_ANCESTORS_ALLOWED = 20`). Nadie llega ahí por diseño: se llega por accidente, replicando el organigrama de la empresa dentro de GitLab.

### 2.2 Qué hereda un subgrupo del padre

| Se hereda | Detalle |
|---|---|
| **Miembros y roles** | Con el rol que tengan arriba, o más si se los eleva abajo |
| **Visibilidad máxima** | Un hijo no puede ser más visible que su padre (teoría [06](06-visibilidad-quien-ve-que.md)) |
| **Grupos invitados** | Lo que se comparte con el padre alcanza a los hijos (teoría [05](05-compartir-grupos-y-proyectos.md)) |
| **Variables de CI/CD** | Las del grupo llegan a los pipelines de sus proyectos (S10) |
| **Runners de grupo** | Los registra el padre, los usan los hijos (S15) |
| **Etiquetas y hitos de grupo** | Se ven desde los proyectos descendientes (S05) |
| **Dependency proxy y registry** | Se configuran arriba y se usan abajo (S13) |

No se hereda hacia arriba: un miembro del subgrupo `ci` **no** ve el proyecto `app` que cuelga de la raíz. La herencia baja, nunca sube. Es la propiedad que hace que un subgrupo sirva para dar acceso a un contratista sin abrirle la organización entera.

### 2.3 Crear un subgrupo

**Con la interfaz**: `Grupo → New subgroup`, o desde el botón `+` de la barra superior. El formulario pide nombre y ruta, y hereda la visibilidad del padre como valor por defecto.

**Con la API**: es el mismo endpoint que para un grupo raíz, más `parent_id`.

```bash
source ~/.bc-gitlab
GRUPO=$(printf '%s' "${PROYECTO%/*}" | jq -sRr @uri)
GID=$(curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/groups/$GRUPO" | jq -r '.id')

curl -s --request POST "$GITLAB_URL/api/v4/groups" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data-urlencode "name=Infra" \
  --data-urlencode "path=infra" \
  --data-urlencode "parent_id=$GID" \
  --data-urlencode "description=Terraform, manifiestos y estado remoto. Su proyecto nace en la Semana 11" \
  | jq '{id, full_path, visibility, parent_id}'
```

```json
{
  "id": 6,
  "full_path": "plataforma-biblioteca/infra",
  "visibility": "private",
  "parent_id": 5
}
```

Sin `parent_id` habrías creado un grupo raíz con el mismo nombre, que es el error más común del día y no da ningún error: da un grupo en el sitio equivocado.

### 2.4 Los ajustes de grupo que importan en CE

Todos se leen en `GET /groups/:id` y se escriben con `PUT /groups/:id`.

| Ajuste | Valores | Para qué |
|---|---|---|
| `project_creation_level` | `noone`, `owner`, `maintainer`, `developer`, `administrator` | Quién puede crear proyectos dentro del grupo |
| `subgroup_creation_level` | `owner`, `maintainer` | Quién puede crear subgrupos |
| `visibility` | `private`, `internal`, `public` | Quién ve el grupo sin ser miembro |
| `request_access_enabled` | booleano | Si un usuario puede pedir acceso desde la interfaz |
| `share_with_group_lock` | booleano | Impide compartir los proyectos del grupo con otros grupos |
| `require_two_factor_authentication` | booleano | Exige 2FA a los miembros del grupo |
| `two_factor_grace_period` | horas | Margen antes de exigirla de verdad |
| `default_branch` | cadena | Rama por defecto de los proyectos nuevos del grupo |
| `default_branch_protection_defaults` | objeto | Protección por defecto de esa rama (S07) |
| `lfs_enabled` | booleano | Habilita LFS en los proyectos del grupo (S04) |
| `emails_enabled` | booleano | Notificaciones por correo del grupo |
| `mentions_disabled` | booleano | Impide mencionar al grupo entero con `@grupo` |
| `enabled_git_access_protocol` | `ssh`, `http`, `all` | Restringe cómo se clona |
| `shared_runners_setting` | cadena | Si los runners de instancia sirven a este grupo (S15) |

De la lista, dos se tocan hoy y las demás llegan con su semana:

```bash
curl -s --request PUT "$GITLAB_URL/api/v4/groups/$GID" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data-urlencode "project_creation_level=maintainer" \
  --data-urlencode "subgroup_creation_level=owner" \
  | jq '{project_creation_level, subgroup_creation_level}'
```

**Por qué esos dos valores.** El valor por defecto de la instancia permite que un Developer cree proyectos. Suena inofensivo y no lo es: un proyecto creado por alguien que no administra el grupo nace fuera del inventario, sin las protecciones que la Semana 07 va a exigir, y con el creador como Owner. La regla que este bootcamp sigue —y que la práctica 01 aplica— es que **la estructura la crea quien la administra**.

> [!NOTE]
> `project_creation_level` acepta `developer` y `administrator`, pero la interfaz de CE solo ofrece tres de las cinco opciones. Si pones un valor por API que la interfaz no muestra, el ajuste funciona y el desplegable aparece en blanco. Es coherente con la API; es confuso para quien lo mire después.

### 2.5 Ajustes que **no** están en CE

| Ajuste | Tier | Qué hace | Sustituto en este bootcamp |
|---|:--:|---|---|
| `ip_restriction_ranges` | Premium | Limita el acceso al grupo por rango de IP | Nada equivalente; se compensa con red del laboratorio |
| `allowed_email_domain` | Premium | Solo admite miembros con correo de un dominio | Revisión periódica de miembros (práctica 04) |
| `prevent_forking_outside_group` | Premium | Impide forks fuera del grupo | Auditoría de forks por API |
| Sincronización con LDAP/SAML | Premium | Membresía gestionada desde el directorio | Alta manual por API (práctica 02) |
| `unique_project_download_limit` | Ultimate | Corta descargas masivas de repositorios | Registro de auditoría revisado a mano |
| Roles personalizados | Ultimate | Roles con permisos a la carta | Los cinco roles estándar, bien repartidos |

_Tiers comprobados en agosto de 2026 contra la [comparativa oficial](https://about.gitlab.com/pricing/feature-comparison/)._

---

## 3. Cómo se borra un grupo

Desde hace varias versiones, y en la 19.2 también en CE, **`DELETE /groups/:id` no borra: programa el borrado**. El grupo queda marcado, deja de aparecer en los listados normales y se elimina de verdad más tarde.

```bash
# Programa el borrado
curl -s --request DELETE "$GITLAB_URL/api/v4/groups/$GID" -H "PRIVATE-TOKEN: $GITLAB_TOKEN"
# 202 Accepted

# Arrepentirse
curl -s --request POST "$GITLAB_URL/api/v4/groups/$GID/restore" -H "PRIVATE-TOKEN: $GITLAB_TOKEN" | jq -r '.full_path'
```

Para borrar un **subgrupo** inmediatamente hay que pedirlo dos veces y con la ruta completa escrita a mano, que es la forma que tiene GitLab de preguntar "¿seguro?":

```bash
curl -s --request DELETE \
  "$GITLAB_URL/api/v4/groups/$SUBID?permanently_remove=true&full_path=plataforma-biblioteca%2Fpruebas" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN"
```

> [!WARNING]
> Borrar un grupo se lleva por delante **todos sus proyectos, subgrupos, issues, merge requests, paquetes y registros**. El borrado programado da un margen de rescate; el `permanently_remove` no da ninguno. Antes de borrar nada que tenga contenido: `GET /groups/:id/projects?include_subgroups=true` y mira qué hay dentro.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Replicar el organigrama de la empresa en subgrupos | Cinco niveles de profundidad para llegar a un repositorio, y permisos imposibles de leer | Dos niveles, tres como mucho. El árbol modela el **acceso**, no la jerarquía de personas |
| Crear el subgrupo sin `parent_id` | Aparece un grupo raíz gemelo y las rutas dejan de coincidir con la documentación | Comprobar `full_path` en la respuesta, siempre |
| Dejar `project_creation_level` en el valor por defecto | Proyectos fuera del inventario, sin protecciones y con Owner accidental | `maintainer` (o `owner` en un grupo pequeño) |
| Usar un subgrupo como carpeta de un solo proyecto | Un nivel más de ruta que no aporta ni un permiso distinto | El subgrupo se justifica por permisos o por volumen, no por estética |
| Poner los ajustes en cada subgrupo | Se desincronizan en semanas y nadie sabe cuál manda | Configurar arriba y dejar que se herede |
| Borrar un grupo "para limpiar" sin mirar dentro | Se lleva registros, paquetes y historial que no estaban en ningún backup | `GET /groups/:id/projects?include_subgroups=true` antes de tocar nada |

---

## 5. Trucos

- **El árbol de una vez**: `GET /groups/:id/descendant_groups | jq -r '.[].full_path'`. `subgroups` solo devuelve los hijos directos.
- **Todo lo que hay dentro, proyectos incluidos**: `GET /groups/:id/projects?include_subgroups=true&with_shared=false`. Sin `with_shared=false` te cuenta también lo que solo está compartido, y el inventario sale inflado.
- **Ajustes de varios grupos de golpe**: `GET /groups?top_level_only=true | jq -r '.[] | "\(.full_path)\t\(.project_creation_level)"'`.
- **Ver qué cambió un `PUT`**: la respuesta trae el grupo entero. `jq '{project_creation_level, subgroup_creation_level}'` y compruebas sin abrir la interfaz.
- **La página de miembros de un grupo, directa**: `http://localhost:8888/groups/<ruta>/-/group_members`.

---

## 📚 Recursos Adicionales

- [Subgrupos](https://docs.gitlab.com/ee/user/group/subgroups/) — herencia, límites y casos de uso
- [API de grupos](https://docs.gitlab.com/ee/api/groups.html) — todos los parámetros de creación y actualización
- [Borrado de grupos](https://docs.gitlab.com/ee/user/group/manage.html#remove-a-group) — el borrado programado y su restauración

---

## ✅ Checklist de Verificación

- [ ] Sabes qué hereda un subgrupo y qué no puede quitar de lo heredado
- [ ] Has creado un subgrupo con `parent_id` y comprobado su `full_path` en la respuesta
- [ ] Tu grupo raíz tiene `project_creation_level=maintainer` y `subgroup_creation_level=owner`
- [ ] Sabes que `DELETE /groups/:id` programa el borrado, y cómo restaurarlo

---

[← Anterior: Namespaces y rutas](01-namespaces-y-rutas.md) · [Volver a la Semana 03](../README.md) · [Siguiente: Los roles →](03-los-roles-y-que-puede-cada-uno.md)

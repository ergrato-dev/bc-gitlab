# 📖 Glosario — Semana 03

Términos que aparecen esta semana. El nombre real de la feature va en inglés entre paréntesis, y el **tier** cuando aplica.

El glosario acumulado de toda la plataforma está en [glosario-global](../../../docs/glosario-global.md).

---

## A

**Acceso efectivo** (*effective access*) — El rol que de verdad tiene alguien sobre un recurso: el **máximo** entre su membresía directa, la heredada de cualquier antepasado y la que le llega por un grupo invitado. Lo devuelve `members/all` ya calculado.

**`access_level`** — El campo numérico con el que la API expresa un rol: `10` Guest, `15` Planner, `20` Reporter, `30` Developer, `40` Maintainer, `50` Owner. Free.

**Antepasado** (*ancestor*) — Cualquier grupo por encima de otro en la jerarquía. Sus miembros bajan; los de abajo no suben.

**Auditoría de accesos** — Responder con datos a tres preguntas: quién tiene acceso, qué excepciones hay y quién entra desde fuera. En esta semana es `scripts/auditar-accesos.sh`.

## B

**Bot de recurso** (*resource bot*) — El usuario que GitLab crea al generar un token de grupo o de proyecto. Aparece en la lista de miembros como `group_<id>_bot_…` o `project_<id>_bot_…`, con el rol que se le dio. Free.

## C

**Caducidad de membresía** (*membership expiration*, `expires_at`) — Fecha en la que GitLab **elimina** la membresía. No la degrada: la quita. Free.

**Compartir** (*share* / *invite a group*) — Dar acceso a un proyecto o grupo a **otro grupo entero**, con un techo de acceso. Free.

## D

**Descendiente** (*descendant*) — Todo lo que cuelga de un grupo a cualquier profundidad. `GET /groups/:id/descendant_groups` los devuelve todos; `subgroups`, solo los hijos directos.

**Developer** — Rol `30`. Empuja código a ramas no protegidas, abre merge requests, ejecuta y cancela pipelines, publica imágenes en el registry. No administra el proyecto. Free.

## E

**Elevación directa** — Dar a alguien un rol en un proyecto concreto, superior al que tiene en el grupo. Es la única forma de subir en un sitio sin subir en todo el árbol.

**Externo, usuario** (*external user*) — Usuario marcado con `external: true`. No ve los proyectos `internal`; solo lo público y aquello donde tenga rol. Free.

## G

**Grupo** (*group*) — Namespace con miembros, roles y ajustes propios. Lo que se decide en él lo heredan sus descendientes.

**Grupo invitado** (*invited group*) — Grupo al que se ha compartido un proyecto o grupo. Sus miembros acceden con el **mínimo** entre su rol allí y el techo de la compartición. Free.

**Grupo raíz** (*top-level group*) — Grupo sin padre. Algunos ajustes solo existen en este nivel.

**Guest** — Rol `10`. Ve el proyecto, los issues, los hitos y la wiki. **No ve el código de un proyecto privado**. Free.

## H

**Herencia** (*inheritance*) — Mecanismo por el que la membresía de un grupo alcanza a sus subgrupos y proyectos. Baja, nunca sube, y solo suma.

## I

**`internal`** — Visibilidad intermedia: lo ve cualquier usuario **autenticado** de la instancia, excepto los externos. Free.

## L

**LDAP/SAML group sync** — Membresía gestionada automáticamente desde un directorio corporativo. **Premium**. En CE se sustituye con altas por API y revisión periódica.

## M

**Maintainer** — Rol `40`. Administra el proyecto: ajustes, variables de CI/CD, protecciones de rama, miembros del proyecto. No administra el grupo. Free.

**`members` / `members/all`** — Los dos endpoints de membresía: el primero devuelve solo los directos; el segundo, también los heredados y los de grupos invitados, con el acceso efectivo. Free.

**Menor privilegio** (*least privilege*) — Cada identidad con el mínimo acceso que le permite trabajar. En GitLab se aplica sobre todo decidiendo qué **no** se pone en el grupo raíz.

**Minimal Access** — Rol `5`. Miembro del grupo raíz sin acceso a nada de dentro. **Premium**.

## N

**Namespace** — Contenedor de nombres: un grupo o un espacio personal. Decide la unicidad de rutas, la herencia de permisos y el techo de visibilidad.

**`name` frente a `path`** — `name` es la etiqueta visible y admite espacios y acentos; `path` es el segmento de URL y es kebab-case ASCII. La API trabaja con `path`.

## O

**Owner** — Rol `50`. Administra el grupo: reparte roles, lo transfiere y lo borra. Free.

## P

**Planner** — Rol `15`, disponible desde la 17.7. Gestiona issues, hitos y wiki, y **ve el código**, pero no lo escribe. Free.

**`project_creation_level`** — Ajuste de grupo que decide quién puede crear proyectos dentro: `noone`, `owner`, `maintainer`, `developer`, `administrator`. Free.

## R

**Reporter** — Rol `20`. Lee y clona el código, ve pipelines y registry, administra issues y hitos. No empuja. Free.

**Rutas reservadas** (*reserved names*) — Palabras que GitLab usa en sus propias URLs y no acepta como ruta: `admin`, `api`, `groups`, `-`, y otras.

## S

**Scope de token** — Qué **tipo** de operaciones admite un token (`api`, `read_api`, `read_repository`…). Es un límite independiente del rol: los dos se aplican, y el más estricto manda.

**Solicitud de acceso** (*access request*) — Petición de entrada a un grupo o proyecto, pendiente de aprobación. Aprobarla sin indicar rol concede **Developer (30)** por defecto. Free.

**Subgrupo** (*subgroup*) — Grupo con padre. Hereda miembros, visibilidad máxima, variables, runners y grupos invitados. Free, con hasta 20 antepasados.

**`share_with_group_lock`** — Ajuste de grupo que impide compartir sus proyectos con otros grupos. Free.

## T

**Techo de compartición** (*max role*, `group_access`) — Rol máximo que puede alcanzar cualquier miembro del grupo invitado. Se escribe como `group_access` y se lee como `group_access_level`.

**Token de grupo** (*group access token*) — Credencial con rol propio y caducidad, asociada a un usuario bot, válida para el grupo y sus descendientes. Free en instancias autohospedadas.

**Transferir** (*transfer*) — Mover un proyecto o un grupo a otro namespace. `PUT /projects/:id/transfer` y `POST /groups/:id/transfer`. Conserva el contenido; cambia la ruta.

## V

**Visibilidad** (*visibility*) — Quién ve un recurso **sin ser miembro**: `private`, `internal` o `public`. Un hijo nunca puede ser más visible que su padre.

## Otros términos de pago que se mencionan

| Término | Tier | Sustituto en este bootcamp |
|---|:--:|---|
| Roles personalizados (*custom roles*) | Ultimate | Reparto cuidadoso de los cinco roles estándar, con elevaciones documentadas |
| `ip_restriction_ranges` | Premium | Red del laboratorio y revisión periódica |
| `allowed_email_domain` | Premium | Auditoría de miembros de la práctica 04 |
| `prevent_forking_outside_group` | Premium | Revisión de forks por API |
| Minimal Access | Premium | No usar ese nivel: quien no necesita nada, no es miembro |

---

[← Volver a la Semana 03](../README.md)

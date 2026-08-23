# 🔗 Enlaces — Semana 03

## Los que vas a tener abiertos toda la semana

| Enlace | Para qué |
|---|---|
| [Permisos y roles](https://docs.gitlab.com/ee/user/permissions.html) | La tabla oficial de qué puede cada rol, con el tier de cada fila. Larga: úsala con `Ctrl+F` |
| [API de miembros](https://docs.gitlab.com/ee/api/members.html) | `members`, `members/all`, `expires_at` y los códigos de error de cada operación |
| [API de grupos](https://docs.gitlab.com/ee/api/groups.html) | Creación con `parent_id`, ajustes, `share`, `transfer` y borrado programado |
| [Subgrupos](https://docs.gitlab.com/ee/user/group/subgroups/) | Qué se hereda, qué no, y los límites de la jerarquía |

## Namespaces y rutas

| Enlace | Para qué |
|---|---|
| [Namespaces](https://docs.gitlab.com/ee/user/namespace/) | La diferencia entre espacio personal y grupo, explicada corta |
| [API de namespaces](https://docs.gitlab.com/ee/api/namespaces.html) | El endpoint `exists`, que evita el 400 al crear |
| [Nombres reservados](https://docs.gitlab.com/ee/user/reserved_names.html) | Por qué `admin` o `api` no te dejan usarlos como ruta |

## Permisos y accesos

| Enlace | Para qué |
|---|---|
| [Miembros de un grupo](https://docs.gitlab.com/ee/user/group/manage.html#members) | El filtro *Direct / Inherited* de la interfaz, que responde en dos clics lo que la API responde en dos peticiones |
| [Compartir un proyecto con un grupo](https://docs.gitlab.com/ee/user/project/members/sharing_projects_groups.html) | El mecanismo del techo, con sus límites |
| [API de solicitudes de acceso](https://docs.gitlab.com/ee/api/access_requests.html) | Aprobar, denegar, y el rol por defecto que conviene no dejar al azar |
| [Roles personalizados](https://docs.gitlab.com/ee/user/custom_roles.html) | Qué problema resuelven y por qué son Ultimate. Léelo para saber qué estás sustituyendo |

## Identidades que no son personas

| Enlace | Para qué |
|---|---|
| [Tokens de grupo](https://docs.gitlab.com/ee/user/group/settings/group_access_tokens.html) | Alcance, scopes, usuario bot y caducidad |
| [Tokens de proyecto](https://docs.gitlab.com/ee/user/project/settings/project_access_tokens.html) | La variante de un solo proyecto, que es la que más se usa |
| [Scopes de los tokens](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#personal-access-token-scopes) | Qué permite exactamente `api` frente a `read_api`. Scope y rol son dos límites distintos |

## Visibilidad y movimientos

| Enlace | Para qué |
|---|---|
| [Visibilidad de proyectos y grupos](https://docs.gitlab.com/ee/user/public_access.html) | Los tres niveles y qué ve cada uno |
| [Transferir un proyecto](https://docs.gitlab.com/ee/user/project/settings/migrate_projects.html) | Requisitos, consecuencias y lo que se pierde |
| [Reducir el riesgo al mover](https://docs.gitlab.com/ee/user/group/manage.html#transfer-a-group) | El caso del árbol entero |

## Para leer una vez y volver

| Enlace | Para qué |
|---|---|
| [The GitLab Handbook — Access management](https://handbook.gitlab.com/handbook/security/access-management-policy/) | Cómo gestiona los accesos una empresa que fabrica la herramienta. Es un ejemplo real de política escrita |
| [OWASP — Authorization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html) | Menor privilegio y denegación por defecto, en dos páginas y sin producto de por medio |

> Enlaces comprobados en agosto de 2026.

---

[← Volver a la Semana 03](../../README.md)

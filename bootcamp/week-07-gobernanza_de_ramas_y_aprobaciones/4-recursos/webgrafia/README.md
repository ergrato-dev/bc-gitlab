# 🔗 Enlaces — Semana 07

## Los que vas a tener abiertos toda la semana

| Enlace | Para qué |
|---|---|
| [API de ramas protegidas](https://docs.gitlab.com/api/protected_branches/) | Crear, leer y quitar reglas; qué acepta `PATCH` y qué no |
| [API de tags protegidos](https://docs.gitlab.com/api/protected_tags/) | `create_access_level` y los comodines |
| [Git server hooks](https://docs.gitlab.com/administration/server_hooks/) | `gitaly hooks set`, hooks globales, variables `GL_*` y mensajes `GL-HOOK-ERR` |
| [Plantillas del commit](https://docs.gitlab.com/user/project/merge_requests/commit_templates/) | `%{approved_by}` y el resto de variables de las plantillas de fusión y squash |

## Protecciones

| Enlace | Para qué |
|---|---|
| [Ramas protegidas](https://docs.gitlab.com/user/project/repository/branches/protected/) | Niveles de acceso, comodines y la regla de la más permisiva |
| [Protección de la rama por defecto](https://docs.gitlab.com/user/project/repository/branches/default/#protect-initial-default-branches) | Las cuatro opciones para proyectos nuevos y cómo las sobrescribe un grupo |
| [Tags protegidos](https://docs.gitlab.com/user/project/protected_tags/) | Qué se puede y qué no con un tag protegido |
| [API de ramas](https://docs.gitlab.com/api/branches/) | `protected`, `can_push`, `developers_can_push` de una rama concreta |

## Dueños y aprobaciones

| Enlace | Para qué |
|---|---|
| [Code Owners](https://docs.gitlab.com/user/project/codeowners/) | Lo que hace Premium con `CODEOWNERS`: para saber qué estás sustituyendo |
| [Sintaxis de Code Owners](https://docs.gitlab.com/user/project/codeowners/reference/) | Patrones, secciones, prioridad de la última regla |
| [API de aprobaciones](https://docs.gitlab.com/api/merge_request_approvals/) | `approvals`, `approve` y `unapprove`, lo que hay en CE |
| [Feature comparison](https://about.gitlab.com/pricing/feature-comparison/) | Approval rules, push rules, *Allowed to unprotect*: el tier de cada una |

## Git

| Enlace | Para qué |
|---|---|
| [githooks(5)](https://git-scm.com/docs/githooks) | `pre-receive`, `update`, `post-receive`, y el entorno de cuarentena |
| [git-rev-list](https://git-scm.com/docs/git-rev-list) | `--not --all` y `--parents`, las dos piezas del hook |
| [git-interpret-trailers](https://git-scm.com/docs/git-interpret-trailers) | Cómo lee Git `Approved-by:` y `%(trailers:key=...)` |

> Enlaces comprobados en noviembre de 2026.

---

[← Volver a la Semana 07](../../README.md)

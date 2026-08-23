# 🔗 Enlaces — Semana 02

## Referencia de Git (los que vas a tener abiertos toda la semana)

| Enlace | Para qué |
|---|---|
| [Documentación de Git](https://git-scm.com/docs) | El índice de todos los comandos. La sección `EXAMPLES` de cada página suele ser lo más útil |
| [`gitrevisions(7)`](https://git-scm.com/docs/gitrevisions) | Qué significan `~`, `^`, `@{}`, `..` y `...`. Media hora aquí ahorra confusiones para siempre |
| [`git rebase`](https://git-scm.com/docs/git-rebase) | `--onto`, `--exec` y `--autosquash`, con los diagramas de qué commit acaba dónde |
| [`git reflog`](https://git-scm.com/docs/git-reflog) | El rescate, y su política de caducidad |
| [`git config`](https://git-scm.com/docs/git-config) | Toda opción que aparece en el material. Busca con `Ctrl+F`: es una sola página enorme |

## Firma de commits

| Enlace | Para qué |
|---|---|
| [Commits firmados en GitLab](https://docs.gitlab.com/ee/user/project/repository/signed_commits/) | El índice de los tres formatos soportados |
| [Firma SSH en GitLab](https://docs.gitlab.com/ee/user/project/repository/signed_commits/ssh.html) | El procedimiento oficial, incluido registrar la clave con uso de firma |
| [`git config` — `gpg.ssh.allowedSignersFile`](https://git-scm.com/docs/git-config#Documentation/git-config.txt-gpgsshallowedSignersFile) | El formato exacto del archivo, que no es obvio |
| [`ssh-keygen -Y`](https://man.openbsd.org/ssh-keygen#Y) | La primitiva de firma que Git usa por debajo, útil para firmar cualquier archivo |
| [API de commits — firma](https://docs.gitlab.com/ee/api/commits.html#get-signature-of-a-commit) | El endpoint que usa el autograding, con la respuesta por tipo de firma |
| [API de claves de usuario](https://docs.gitlab.com/ee/api/user_keys.html) | `usage_type` y el resto de parámetros de `POST /user/keys` |

## Convenciones de mensajes

| Enlace | Para qué |
|---|---|
| [Conventional Commits](https://www.conventionalcommits.org/es/v1.0.0/) | La especificación, en español |
| [`git interpret-trailers`](https://git-scm.com/docs/git-interpret-trailers) | Cómo parsea Git el bloque final del mensaje |
| [Palabras clave de cierre de issues](https://docs.gitlab.com/ee/user/project/issues/managing_issues.html#closing-issues-automatically) | `Closes`, `Fixes`, `Related to` y la sintaxis entre proyectos |
| [Semantic Versioning](https://semver.org/lang/es/) | Adónde lleva la convención en la Semana 08 |

## Cuando algo se rompa

| Enlace | Para qué |
|---|---|
| [Oh Shit, Git!?!](https://ohshitgit.com/) | Los diez desastres más comunes y su salida, sin rodeos |
| [`git bisect`](https://git-scm.com/docs/git-bisect) | `run`, `skip`, `log`, `replay` y el significado del código 125 |
| [`git filter-repo`](https://github.com/newren/git-filter-repo) | La herramienta para sacar algo de la historia, y su guía de migración desde `filter-branch` |
| [Reducir el tamaño del repositorio](https://docs.gitlab.com/ee/user/project/repository/reducing_the_repo_size_using_git.html) | El procedimiento de GitLab, con la parte del mantenimiento que purga los objetos huérfanos |
| [`git worktree`](https://git-scm.com/docs/git-worktree) | Árboles de trabajo múltiples sobre un solo clon |

## Gobernanza (adónde va esto)

| Enlace | Para qué |
|---|---|
| [Push rules](https://docs.gitlab.com/ee/user/project/repository/push_rules.html) | Qué incluye la feature **Premium**, para saber qué estás sustituyendo |
| [Server hooks](https://docs.gitlab.com/ee/administration/server_hooks.html) | El sustituto libre, que se monta en la Semana 07 |
| [Ramas protegidas](https://docs.gitlab.com/ee/user/project/repository/branches/protected.html) | Free, y la otra mitad de la respuesta |

_Enlaces comprobados en agosto de 2026._

---

[← Volver a la Semana 02](../../README.md)

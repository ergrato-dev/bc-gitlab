# 🔗 Enlaces — Semana 08

## Los que vas a tener abiertos toda la semana

| Enlace | Para qué |
|---|---|
| [Changelogs](https://docs.gitlab.com/user/project/changelogs/) | El trailer `Changelog:`, `changelog_config.yml`, categorías y la sintaxis de la plantilla |
| [API de repositorios: changelog](https://docs.gitlab.com/api/repositories/#generate-changelog-data) | `GET` y `POST`, `from`, `to`, `branch`, `message` y `config_file_ref` |
| [API de releases](https://docs.gitlab.com/api/releases/) | Crear, leer, actualizar y borrar releases; `milestones`, `assets` y `released_at` |
| [Plantillas del commit](https://docs.gitlab.com/user/project/merge_requests/commit_templates/) | `%{first_multiline_commit_description}` y el resto de marcadores de la plantilla de squash |

## Ramas y versiones

| Enlace | Para qué |
|---|---|
| [What is GitLab Flow?](https://about.gitlab.com/topics/version-control/what-is-gitlab-flow/) | Las ramas de entorno y de release, y la regla *upstream first* |
| [Versionado Semántico 2.0.0](https://semver.org/lang/es/) | La especificación completa, con la gramática de pre-release y metadatos |
| [Ramas protegidas](https://docs.gitlab.com/user/project/repository/branches/protected/) | Comodines como `release/*` y quién puede crear una rama protegida |
| [Cherry-pick changes](https://docs.gitlab.com/user/project/merge_requests/cherry_pick_changes/) | El botón *Cherry-pick* de commits y merge requests |
| [API de commits: cherry-pick](https://docs.gitlab.com/api/commits/#cherry-pick-a-commit) | `branch`, `dry_run` y el mensaje que genera GitLab |
| [API de tags](https://docs.gitlab.com/api/tags/) | `target`, `commit` y `message` de un tag; crear tags anotados por API |

## Releases

| Enlace | Para qué |
|---|---|
| [Releases](https://docs.gitlab.com/user/project/releases/) | Tipos de release, evidencia, permisos y la relación con los tags protegidos |
| [Release links API](https://docs.gitlab.com/api/releases/links/) | Añadir assets después de publicar y `direct_asset_path` |
| [Release evidence](https://docs.gitlab.com/user/project/releases/release_evidence/) | Qué guarda la evidencia y cuándo se recoge |

## Métricas

| Enlace | Para qué |
|---|---|
| [DORA metrics en GitLab](https://docs.gitlab.com/user/analytics/dora_metrics/) | Lo que calcula Ultimate y de qué datos sale: útil para comparar con tu DORA-lite |
| [Value Stream Analytics](https://docs.gitlab.com/user/group/value_stream_analytics/) | Etapas por defecto, y qué es de proyecto (CE) y qué de grupo (Premium) |
| [API de merge requests](https://docs.gitlab.com/api/merge_requests/) | `created_at`, `merged_at`, `updated_after` y `target_branch` |
| [API de issues](https://docs.gitlab.com/api/issues/) | `labels`, `state` y `closed_at` |
| [jq Manual](https://jqlang.org/manual/) | `fromdateiso8601`, `capture`, `IN` y `def` para funciones propias |

## Git

| Enlace | Para qué |
|---|---|
| [`git tag`](https://git-scm.com/docs/git-tag) | `-s`, `-v` y la diferencia entre tags ligeros y anotados |
| [`git cherry-pick`](https://git-scm.com/docs/git-cherry-pick) | `-x`, `-m` y cómo continuar tras un conflicto |
| [`git interpret-trailers`](https://git-scm.com/docs/git-interpret-trailers) | Qué cuenta como trailer y por qué tiene que ir en el último párrafo |
| [`git log` — formatos de trailers](https://git-scm.com/docs/git-log#Documentation/git-log.txt-trailersoptions) | `%(trailers:key=…,valueonly,separator=)` |

> Enlaces comprobados en noviembre de 2026.

---

[← Volver a la Semana 08](../../README.md)

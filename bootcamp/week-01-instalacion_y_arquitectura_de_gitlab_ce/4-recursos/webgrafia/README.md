# 🔗 Enlaces — Semana 01

## Referencia (los que vas a tener abiertos toda la semana)

| Enlace | Para qué |
|---|---|
| [Documentación de GitLab](https://docs.gitlab.com/) | Todo. Usa el selector de versión de arriba a la derecha: la de `latest` no es la tuya |
| [Recursos de la API v4](https://docs.gitlab.com/ee/api/api_resources.html) | El índice de endpoints. Lo vas a usar 26 semanas |
| [Configuración de Omnibus](https://docs.gitlab.com/omnibus/settings/) | Qué prefijo lleva cada opción de `gitlab.rb` |
| [Plantilla de `gitlab.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-config-template/gitlab.rb.template) | Miles de líneas comentadas. La referencia definitiva de qué opciones existen |
| [Comparativa de tiers](https://about.gitlab.com/pricing/feature-comparison/) | Antes de dar por hecho que una feature la tienes |

## Arquitectura

| Enlace | Para qué |
|---|---|
| [Arquitectura de GitLab](https://docs.gitlab.com/ee/development/architecture.html) | El diagrama oficial completo, con los diagramas de secuencia por tipo de petición |
| [Gitaly](https://docs.gitlab.com/ee/administration/gitaly/) | Por qué existe. Volverás en la Semana 23 |
| [GitLab Workhorse](https://docs.gitlab.com/ee/development/workhorse/) | Qué peticiones intercepta y por qué |
| [Almacenamiento de repositorios](https://docs.gitlab.com/ee/administration/repository_storage_paths.html) | La explicación oficial de `@hashed` |

## Cuando algo falle

| Enlace | Para qué |
|---|---|
| [Comprobaciones de estado](https://docs.gitlab.com/ee/administration/monitoring/health_check.html) | Los tres endpoints y qué comprueba cada uno |
| [Logs de GitLab](https://docs.gitlab.com/ee/administration/logs/) | Qué error está en qué archivo |
| [Solución de problemas](https://docs.gitlab.com/ee/administration/troubleshooting/) | Casos concretos con sus síntomas |
| [Tareas de `gitlab-rake`](https://docs.gitlab.com/ee/administration/raketasks/) | `gitlab:check`, `gitlab:gitaly:check` y el resto |

## Herramientas

| Enlace | Para qué |
|---|---|
| [CLI `glab`](https://gitlab.com/gitlab-org/cli) | Subcomandos y ejemplos |
| [Manual de `jq`](https://jqlang.github.io/jq/manual/) | `select`, interpolación y filtros. Media hora aquí ahorra semanas |
| [Perfiles de Compose](https://docs.docker.com/compose/how-tos/profiles/) | Por qué un servicio con perfil no arranca por defecto |

_Enlaces comprobados en agosto de 2026._

---

[← Volver a la Semana 01](../../README.md)

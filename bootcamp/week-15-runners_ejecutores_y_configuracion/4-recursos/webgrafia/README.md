# 🔗 Enlaces — Semana 15

Comprobados en noviembre de 2026 contra la documentación de GitLab Runner y de GitLab.

## Los que vas a tener abiertos toda la semana

| Enlace | Para qué |
|---|---|
| [Advanced configuration](https://docs.gitlab.com/runner/configuration/advanced-configuration/) | Cada clave de `config.toml`: global, `[[runners]]`, `[runners.docker]`, `[runners.cache]` |
| [Docker executor](https://docs.gitlab.com/runner/executors/docker/) | Contenedores por job, servicios, `privileged` y las listas `allowed_*` |
| [Use Docker to build Docker images](https://docs.gitlab.com/ci/docker/using_docker_build/) | `dind` con TLS, las cuatro variables y el volumen `/certs/client` |
| [Runners API](https://docs.gitlab.com/api/runners/) | Crear, cambiar, pausar, asignar, rotar y listar gestores y jobs |
| [Caching in GitLab CI/CD](https://docs.gitlab.com/ci/caching/) | Claves, `fallback_keys`, `unprotect` y la separación por protección |

## Para cuando lo necesites

| Enlace | Para qué |
|---|---|
| [Executors](https://docs.gitlab.com/runner/executors/) | La tabla que compara todos los ejecutores |
| [Registering runners](https://docs.gitlab.com/runner/register/) | `register` no interactivo y lo que no admite con un token `glrt-` |
| [New runner creation workflow](https://docs.gitlab.com/ci/runners/new_creation_workflow/) | Por qué las etiquetas y la protección viven en GitLab |
| [Runner scopes](https://docs.gitlab.com/ci/runners/runners_scope/) | Instancia, grupo y proyecto; gestores y su `system_id` |
| [Configure runners](https://docs.gitlab.com/ci/runners/configure_runners/) | `ref_protected`, tiempo máximo y rotación automática de tokens |
| [Long polling](https://docs.gitlab.com/runner/configuration/advanced-configuration/#long-polling-issues) | El aviso que da el runner con `request_concurrency = 1` |
| [Docker Autoscaler executor](https://docs.gitlab.com/runner/executors/docker_autoscaler/) | El sustituto de Docker Machine, para cuando la flota viva en la nube |
| [SeaweedFS: Amazon S3 API](https://github.com/seaweedfs/seaweedfs/wiki/Amazon-S3-API) | Qué parte de S3 implementa el almacén de `cache-s3` |
| [Imagen oficial `docker`](https://hub.docker.com/_/docker) | Las variantes `cli`, `dind` y `dind-rootless`, y sus tags |

## Lo que es de pago, para saber qué te pierdes

| Enlace | Tier |
|---|---|
| [Protected environments](https://docs.gitlab.com/ci/environments/protected_environments/) | Premium |
| [GitLab-hosted runners](https://docs.gitlab.com/ci/runners/hosted_runners/) | Solo GitLab.com y Dedicated: en una instancia propia, la flota es tuya |
| [Runner fleet dashboard](https://docs.gitlab.com/ci/runners/runner_fleet_dashboard/) | Ultimate. Sustituto: la API de este archivo y, en la Semana 21, Grafana |

---

[← Volver a la Semana 15](../../README.md)

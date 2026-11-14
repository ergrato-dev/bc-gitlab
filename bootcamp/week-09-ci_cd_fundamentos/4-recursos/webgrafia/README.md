# 🔗 Enlaces — Semana 09

## Los que vas a tener abiertos toda la semana

| Enlace | Para qué |
|---|---|
| [CI/CD YAML syntax reference](https://docs.gitlab.com/ci/yaml/) | Todas las palabras clave de `.gitlab-ci.yml`, con ejemplos |
| [Predefined CI/CD variables](https://docs.gitlab.com/ci/variables/predefined_variables/) | Qué variables `CI_*` recibe cada job y en qué pipelines |
| [Jobs API](https://docs.gitlab.com/api/jobs/) | Listar jobs, leer el log, reintentar y cancelar |
| [Pipelines API](https://docs.gitlab.com/api/pipelines/) | Crear pipelines, `latest`, informes de tests y cancelar |
| [CI Lint API](https://docs.gitlab.com/api/lint/) | Validar contenido o la configuración de una rama, con `include_merged_yaml` |

## El runner

| Enlace | Para qué |
|---|---|
| [GitLab Runner](https://docs.gitlab.com/runner/) | Instalación, ejecutores y la relación con el servidor |
| [Run GitLab Runner in a container](https://docs.gitlab.com/runner/install/docker/) | El montaje del socket y del volumen de configuración que usa el compose |
| [Register a runner](https://docs.gitlab.com/runner/register/) | `register --non-interactive` y sus opciones |
| [New runner creation workflow](https://docs.gitlab.com/ci/runners/new_creation_workflow/) | Por qué cambió el registro y qué se retira |
| [Advanced configuration](https://docs.gitlab.com/runner/configuration/advanced-configuration/) | Todas las claves de `config.toml`, incluidas `clone_url` y `network_mode` |

## Artefactos, caché e informes

| Enlace | Para qué |
|---|---|
| [Job artifacts](https://docs.gitlab.com/ci/jobs/job_artifacts/) | Declarar, pasar entre jobs, caducidad y `keep_latest_artifact` |
| [Caching in GitLab CI/CD](https://docs.gitlab.com/ci/caching/) | Claves, políticas, cachés protegidas y la tabla artefacto frente a caché |
| [Unit test reports](https://docs.gitlab.com/ci/testing/unit_test_reports/) | El informe JUnit en la merge request |
| [Code coverage](https://docs.gitlab.com/ci/testing/code_coverage/) | La expresión `coverage` y la insignia |
| [Node.js test runner](https://nodejs.org/docs/latest-v22.x/api/test.html) | Los reporteros `spec` y `junit`, y `--experimental-test-coverage` |

## Tokens y variables

| Enlace | Para qué |
|---|---|
| [CI/CD job token](https://docs.gitlab.com/ci/jobs/ci_job_token/) | Qué puede hacer `CI_JOB_TOKEN` y cómo se limita |
| [Project access tokens](https://docs.gitlab.com/user/project/settings/project_access_tokens/) | Rol, scopes, caducidad y el usuario bot |
| [CI/CD variables](https://docs.gitlab.com/ci/variables/) | `masked`, `hidden`, `protected` y la prioridad entre variables |

---

[← Volver a la Semana 09](../../README.md)

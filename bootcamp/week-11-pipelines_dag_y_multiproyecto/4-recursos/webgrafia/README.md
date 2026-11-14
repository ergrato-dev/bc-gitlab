# 🔗 Enlaces — Semana 11

Comprobados en noviembre de 2026 contra la documentación de GitLab.

## Los que vas a tener abiertos toda la semana

| Enlace | Para qué |
|---|---|
| [`needs`](https://docs.gitlab.com/ci/yaml/#needs) | La referencia, con `artifacts`, `optional` y el límite de 50 |
| [Downstream pipelines](https://docs.gitlab.com/ci/pipelines/downstream_pipelines/) | Padre-hijo, multiproyecto, `dotenv` hacia abajo y las merge requests |
| [`trigger`](https://docs.gitlab.com/ci/yaml/#trigger) | `include`, `project`, `branch`, `strategy` y `forward` |
| [Jobs API — bridges](https://docs.gitlab.com/api/jobs/#list-pipeline-trigger-jobs) | Del job de disparo al pipeline que creó |
| [Pipelines API](https://docs.gitlab.com/api/pipelines/) | `source=parent_pipeline`, `source=pipeline`, `source=schedule` |

## Job token

| Enlace | Para qué |
|---|---|
| [GitLab CI/CD job token](https://docs.gitlab.com/ci/jobs/ci_job_token/) | Qué puede hacer, con qué identidad y la lista de permitidos |
| [Project job token scope API](https://docs.gitlab.com/api/project_job_token_scopes/) | Activar la restricción y gestionar la lista |
| [Job artifacts API](https://docs.gitlab.com/api/job_artifacts/) | Descargar por ID de job con `JOB-TOKEN` |

## Concurrencia y programados

| Enlace | Para qué |
|---|---|
| [Resource group](https://docs.gitlab.com/ci/resource_groups/) | Los cuatro modos de proceso |
| [Resource groups API](https://docs.gitlab.com/api/resource_groups/) | Cambiar el modo y ver `upcoming_jobs` |
| [Deployment safety](https://docs.gitlab.com/ci/environments/deployment_safety/) | *Prevent outdated deployment jobs* y los reintentos de *rollback* |
| [Scheduled pipelines](https://docs.gitlab.com/ci/pipelines/schedules/) | Propietario, *take ownership* y límites |
| [Pipeline schedules API](https://docs.gitlab.com/api/pipeline_schedules/) | Crear, variables, `play` y sus pipelines |

## Lo que es de pago

| Enlace | Para qué |
|---|---|
| [`needs:project`](https://docs.gitlab.com/ci/yaml/#needsproject) | Premium: lo que sustituyen el job token y la API de artefactos |

---

[← Volver a la Semana 11](../../README.md)

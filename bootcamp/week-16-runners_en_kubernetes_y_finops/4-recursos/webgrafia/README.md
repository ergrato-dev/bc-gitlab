# 🔗 Enlaces — Semana 16

Comprobados en noviembre de 2026 contra la documentación de GitLab Runner, de k3d y de Kubernetes.

## Los que vas a tener abiertos toda la semana

| Enlace | Para qué |
|---|---|
| [The Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/) | Cada clave de `[runners.kubernetes]`: recursos, `*_overwrite_max_allowed`, `poll_timeout`, permisos |
| [GitLab Runner Helm chart](https://docs.gitlab.com/runner/install/kubernetes/) | Instalar, actualizar y desinstalar con Helm |
| [Configure the GitLab Runner Helm chart](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration/) | `runners.config`, `runners.secret`, la caché y `rbac` |
| [`k3d cluster create`](https://k3d.io/stable/usage/commands/k3d_cluster_create/) | Todos los flags de la práctica 01 |
| [Pipelines API](https://docs.gitlab.com/api/pipelines/) y [Jobs API](https://docs.gitlab.com/api/jobs/) | `duration` y `queued_duration` para la línea base y `docs/finops.md` |

## Para cuando lo necesites

| Enlace | Para qué |
|---|---|
| [k3d — Registries](https://k3d.io/stable/usage/registries/) y [k3s — Private registry configuration](https://docs.k3s.io/installation/private-registry) | El espejo de Docker Hub en `registries.yaml` |
| [Runners API](https://docs.gitlab.com/api/runners/) | Pausar, gestores y jobs de cada runner |
| [Docker Autoscaler executor](https://docs.gitlab.com/runner/executors/docker_autoscaler/) e [Instance executor](https://docs.gitlab.com/runner/executors/instance/) | Las alternativas sin Kubernetes de la teoría 05 |
| [Compute minutes](https://docs.gitlab.com/ci/pipelines/compute_minutes/) | La cuota de pago y cómo cuenta GitLab los minutos |
| [CI/CD analytics](https://docs.gitlab.com/user/analytics/ci_cd_analytics/) | Las gráficas de duración y éxito que trae CE |

---

[← Volver a la Semana 16](../../README.md)

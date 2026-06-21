# ADR: Decision de Estructura de Semanas

## Fecha
Junio 2026

## Contexto
Creacion inicial del bootcamp GitLab CE. Se necesita definir la estructura de nombres para las carpetas semanales.

## Decision
Usar el formato `week-XX-tema_principal` donde:

- `XX` es el numero de semana con padding (01, 02, ..., 12)
- `tema_principal` se extrae del titulo principal del README.md de la semana

### Ejemplos
- `week-01-fundamentos_git_y_gitlab_ce`
- `week-05-gitlab_ci_cd_fundamentos`
- `week-12-proyecto_final`

## Semanas Definidas

| Semana | Carpeta | Tema |
|--------|---------|------|
| 01 | `week-01-fundamentos_git_y_gitlab_ce` | Fundamentos de Git y GitLab CE |
| 02 | `week-02-instalacion_gitlab_ce` | Instalacion de GitLab CE |
| 03 | `week-03-proyectos_grupos_y_organizacion` | Proyectos, grupos y organizacion |
| 04 | `week-04-issues_merge_requests_y_code_review` | Issues, Merge Requests y Code Review |
| 05 | `week-05-gitlab_ci_cd_fundamentos` | GitLab CI/CD — Fundamentos |
| 06 | `week-06-gitlab_ci_cd_pipelines_avanzados` | GitLab CI/CD — Pipelines Avanzados |
| 07 | `week-07-gitlab_runner_gestion_y_escalado` | GitLab Runner — Gestion y Escalado |
| 08 | `week-08-container_registry_y_package_registry` | Container Registry y Package Registry |
| 09 | `week-09-gitlab_api_y_automatizacion` | GitLab API y Automatizacion |
| 10 | `week-10-administracion_y_seguridad` | Administracion y Seguridad |
| 11 | `week-11-monitoreo_backup_y_alta_disponibilidad` | Monitoreo, Backup y Alta Disponibilidad |
| 12 | `week-12-proyecto_final` | Proyecto Final — Plataforma DevOps Completa |

# Bootcamp GitLab CE — Zero to Hero

## Indice de Semanas

| Semana | Tema | Horas | Etapa |
|--------|------|-------|-------|
| [01](./week-01-fundamentos_git_y_gitlab_ce/README.md) | Fundamentos de Git y GitLab CE | 6h | Fundamentos |
| [02](./week-02-instalacion_gitlab_ce/README.md) | Instalacion de GitLab CE con Docker | 6h | Fundamentos |
| [03](./week-03-proyectos_grupos_y_organizacion/README.md) | Proyectos, Grupos y Organizacion | 6h | Fundamentos |
| [04](./week-04-issues_merge_requests_y_code_review/README.md) | Issues, Merge Requests y Code Review | 6h | Intermedio |
| [05](./week-05-gitlab_ci_cd_fundamentos/README.md) | GitLab CI/CD — Fundamentos | 6h | Intermedio |
| [06](./week-06-gitlab_ci_cd_pipelines_avanzados/README.md) | GitLab CI/CD — Pipelines Avanzados | 6h | Intermedio |
| [07](./week-07-gitlab_runner_gestion_y_escalado/README.md) | GitLab Runner — Gestion y Escalado | 6h | Intermedio |
| [08](./week-08-container_registry_y_package_registry/README.md) | Container Registry y Package Registry | 6h | Avanzado |
| [09](./week-09-gitlab_api_y_automatizacion/README.md) | GitLab API y Automatizacion | 6h | Avanzado |
| [10](./week-10-administracion_y_seguridad/README.md) | Administracion y Seguridad | 6h | Avanzado |
| [11](./week-11-monitoreo_backup_y_alta_disponibilidad/README.md) | Monitoreo, Backup y HA | 6h | Avanzado |
| [12](./week-12-proyecto_final/README.md) | Proyecto Final — Plataforma DevOps | 6h | Produccion |

**Total**: 12 semanas | 72 horas

## Estructura de cada Semana

```
week-XX-tema_principal/
├── README.md                 # Objetivos, contenidos, entregables
├── rubrica-evaluacion.md     # Criterios de evaluacion
├── 0-assets/                 # Diagramas SVG
├── 1-teoria/                 # 5 archivos de contenido teorico
├── 2-practicas/              # 4 ejercicios guiados
├── 3-proyecto/               # Proyecto integrador semanal
├── 4-recursos/               # Ebooks, videos, enlaces
│   ├── ebooks-free/
│   ├── videografia/
│   └── webgrafia/
└── 5-glosario/               # Terminos clave A-Z
```

## Entorno de Desarrollo

Todo el bootcamp usa **Docker Compose** como plataforma de ejecución. No se necesita instalar nada en el sistema host:

```bash
# Levantar GitLab CE + Runner + Registry cache
docker compose up -d

# Agregar monitoreo (Prometheus + Grafana)
docker compose --profile monitoring up -d
```

Para semanas de administración avanzada (10-11) existe además el entorno **gl-epti** con scripts de auditoría y backup pre-instalados. Ver [docs/README.md](../docs/README.md#entornos-disponibles).

[Volver al README principal](../README.md)

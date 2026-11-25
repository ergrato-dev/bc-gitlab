# Bootcamp GitLab CE — Zero to Platform Engineer

26 semanas · 8 h/semana · 208 horas. Una sola instancia GitLab CE autohospedada, un solo proyecto que crece capa a capa.

La columna **Estado** dice la verdad sobre el repositorio: ✅ la semana está escrita, ⬜ todavía no. El contenido se publica en orden, una semana por entrega.

---

## Índice de Semanas

### Fase 1 — Fundamentos (S01-04, 32 h)

| Semana | Tema | Estado |
|:--:|---|:--:|
| [01](week-01-instalacion_y_arquitectura_de_gitlab_ce/README.md) | [Instalación de GitLab CE en Docker y arquitectura interna](week-01-instalacion_y_arquitectura_de_gitlab_ce/README.md) | ✅ |
| [02](week-02-git_avanzado_y_firma_de_commits/README.md) | [Git quirúrgico y commits firmados](week-02-git_avanzado_y_firma_de_commits/README.md) | ✅ |
| [03](week-03-grupos_proyectos_y_permisos/README.md) | [Grupos, subgrupos, roles y namespaces](week-03-grupos_proyectos_y_permisos/README.md) | ✅ |
| [04](week-04-repositorio_como_producto/README.md) | [El repositorio como producto: docs, wiki, snippets, insignias y LFS](week-04-repositorio_como_producto/README.md) | ✅ |

### Fase 2 — Colaboración (S05-08, 32 h)

| Semana | Tema | Estado |
|:--:|---|:--:|
| [05](week-05-issues_etiquetas_y_tableros/README.md) | [Issues, taxonomía de etiquetas y tableros](week-05-issues_etiquetas_y_tableros/README.md) | ✅ |
| [06](week-06-merge_requests_y_code_review/README.md) | [Merge requests y code review](week-06-merge_requests_y_code_review/README.md) | ✅ |
| [07](week-07-gobernanza_de_ramas_y_aprobaciones/README.md) | [Gobernanza de ramas y aprobaciones](week-07-gobernanza_de_ramas_y_aprobaciones/README.md) | ✅ |
| [08](week-08-gitlab_flow_releases_y_metricas/README.md) | [GitLab Flow, releases y métricas de flujo](week-08-gitlab_flow_releases_y_metricas/README.md) | ✅ |

### Fase 3 — CI/CD (S09-13, 40 h)

| Semana | Tema | Estado |
|:--:|---|:--:|
| [09](week-09-ci_cd_fundamentos/README.md) | [CI/CD: fundamentos, runner, artifacts y cache](week-09-ci_cd_fundamentos/README.md) | ✅ |
| [10](week-10-reglas_variables_y_secretos/README.md) | [Reglas, variables y secretos](week-10-reglas_variables_y_secretos/README.md) | ✅ |
| [11](week-11-pipelines_dag_y_multiproyecto/README.md) | [Pipelines DAG y multiproyecto](week-11-pipelines_dag_y_multiproyecto/README.md) | ✅ |
| [12](week-12-componentes_ci_cd_y_catalogo/README.md) | [Componentes CI/CD y catálogo](week-12-componentes_ci_cd_y_catalogo/README.md) | ✅ |
| [13](week-13-registry_de_contenedores_y_paquetes/README.md) | [Registry de contenedores y paquetes](week-13-registry_de_contenedores_y_paquetes/README.md) | ✅ |

### Fase 4 — Entrega, escala y automatización (S14-17, 32 h)

| Semana | Tema | Estado |
|:--:|---|:--:|
| [14](week-14-entornos_review_apps_y_feature_flags/README.md) | [Entornos, review apps y feature flags](week-14-entornos_review_apps_y_feature_flags/README.md) | ✅ |
| [15](week-15-runners_ejecutores_y_configuracion/README.md) | [Runners: ejecutores y configuración](week-15-runners_ejecutores_y_configuracion/README.md) | ✅ |
| [16](week-16-runners_en_kubernetes_y_finops/README.md) | [Runners en Kubernetes y FinOps](week-16-runners_en_kubernetes_y_finops/README.md) | ✅ |
| [17](week-17-api_webhooks_y_chatops/README.md) | [API, webhooks y ChatOps](week-17-api_webhooks_y_chatops/README.md) | ✅ |

### Fase 5 — Seguridad y cadena de suministro (S18-20, 24 h)

| Semana | Tema | Estado |
|:--:|---|:--:|
| [18](week-18-administracion_hardening_y_actualizaciones/README.md) | [Administración, hardening y actualizaciones](week-18-administracion_hardening_y_actualizaciones/README.md) | ✅ |
| [19](week-19-seguridad_del_pipeline_con_herramientas_oss/README.md) | [Seguridad del pipeline con herramientas OSS](week-19-seguridad_del_pipeline_con_herramientas_oss/README.md) | ✅ |
| 20 | Cadena de suministro y políticas como código | ⬜ |

### Fase 6 — Operación, observabilidad y HA (S21-23, 24 h)

| Semana | Tema | Estado |
|:--:|---|:--:|
| 21 | Observabilidad, SLO y troubleshooting | ⬜ |
| 22 | Backup, recuperación y respuesta a incidentes | ⬜ |
| 23 | Alta disponibilidad con Praefect y PostgreSQL | ⬜ |

### Fase 7 — IaC y GitOps (S24-25, 16 h)

| Semana | Tema | Estado |
|:--:|---|:--:|
| 24 | Terraform y estado remoto en GitLab | ⬜ |
| 25 | GitOps con GitLab Agent y entrega progresiva | ⬜ |

### Fase 8 — Capstone (S26, 8 h)

| Semana | Tema | Estado |
|:--:|---|:--:|
| 26 | Capstone: plataforma GitLab completa | ⬜ |

---

## Estructura de cada semana

```
week-XX-tema_principal/
├── README.md                 # Objetivos, contenidos, tiempos, trucos, entregables
├── rubrica-evaluacion.md     # Conocimiento 30% / Desempeño 40% / Producto 30%
├── checks.json               # Autograding declarativo contra la API v4
├── 0-assets/                 # Diagramas SVG
├── 1-teoria/                 # 7-8 archivos, un concepto por archivo
├── 2-practicas/              # 4 prácticas guiadas, cada paso verificable
├── 3-proyecto/               # La capa que esta semana añade al proyecto
├── 4-recursos/               # ebooks-free, videografia, webgrafia
└── 5-glosario/               # Términos clave A-Z con su tier
```

Las semanas con código de apoyo añaden `starter/`.

---

## Antes de empezar

1. [Preparar el entorno](../docs/setup-entorno.md) — Docker, `glab`, `jq`, k3d, firma de commits y token.
2. [Recibir tu dominio y entender el proyecto](../docs/proyecto-hilo-conductor.md) — el mismo durante 26 semanas.
3. [Entender el autograding](../docs/autograding.md) — quién corrige y qué no puede corregir.

## Verificar una semana

```bash
./scripts/verificar-semana.sh --doctor   # una vez, antes de la Semana 01
./scripts/verificar-semana.sh 09         # al terminar cada semana
```

## Perfiles del laboratorio

No todas las semanas levantan lo mismo, y algunos perfiles no caben juntos en memoria. Consulta [perfiles-de-laboratorio.md](../docs/perfiles-de-laboratorio.md) antes de las semanas 16, 18, 21, 23 y 25.

```bash
docker compose --profile base up -d
```

---

[← Volver al README principal](../README.md)

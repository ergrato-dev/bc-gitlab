# ADR-001 — Estructura y nombres de las semanas

**Estado**: aceptada · **Fecha**: agosto de 2026 · **Sustituye a**: la malla de 13 semanas

---

## Contexto

El bootcamp nació con 13 semanas de 6 h (78 h) y salida "Administrador DevOps Junior". En paralelo se diseñó una propuesta de track senior de otras 13 semanas que nunca se escribió.

Mantener dos tracks separados obligaba a duplicar fundamentos, a sostener dos mallas y a que el alumno eligiera nivel antes de saber dónde estaba. Además, el track senior dependía de licencias EE en trial para media docena de semanas, con una ventana de 30 días imposible de coordinar en autoestudio.

## Decisión

**Un solo track de 26 semanas × 8 h = 208 horas**, progresivo, de cero a Platform Engineer. La propuesta senior se absorbe como las fases 5 a 8.

### Nombres de carpeta

Formato: `week-XX-tema_principal`

- `XX` — número de semana con dos dígitos y cero a la izquierda (`01`, no `1`).
- `tema_principal` — en `snake_case`, sin tildes ni eñes, derivado del H1 del `README.md` de la semana.
- Sin prefijos de track: al haber uno solo, `week-sNN` deja de tener sentido.

El script `scripts/verificar-enlaces.sh` valida el formato con `^week-[0-9]{2}-[a-z0-9_]+$` y falla si alguna carpeta se sale.

### La malla

| Semana | Slug | Fase |
|:--:|---|---|
| 01 | `week-01-instalacion_y_arquitectura_de_gitlab_ce` | Fundamentos |
| 02 | `week-02-git_avanzado_y_firma_de_commits` | Fundamentos |
| 03 | `week-03-grupos_proyectos_y_permisos` | Fundamentos |
| 04 | `week-04-repositorio_como_producto` | Fundamentos |
| 05 | `week-05-issues_etiquetas_y_tableros` | Colaboración |
| 06 | `week-06-merge_requests_y_code_review` | Colaboración |
| 07 | `week-07-gobernanza_de_ramas_y_aprobaciones` | Colaboración |
| 08 | `week-08-gitlab_flow_releases_y_metricas` | Colaboración |
| 09 | `week-09-ci_cd_fundamentos` | CI/CD |
| 10 | `week-10-reglas_variables_y_secretos` | CI/CD |
| 11 | `week-11-pipelines_dag_y_multiproyecto` | CI/CD |
| 12 | `week-12-componentes_ci_cd_y_catalogo` | CI/CD |
| 13 | `week-13-registry_de_contenedores_y_paquetes` | CI/CD |
| 14 | `week-14-entornos_review_apps_y_feature_flags` | Entrega y escala |
| 15 | `week-15-runners_ejecutores_y_configuracion` | Entrega y escala |
| 16 | `week-16-runners_en_kubernetes_y_finops` | Entrega y escala |
| 17 | `week-17-api_webhooks_y_chatops` | Entrega y escala |
| 18 | `week-18-administracion_hardening_y_actualizaciones` | Seguridad |
| 19 | `week-19-seguridad_del_pipeline_con_herramientas_oss` | Seguridad |
| 20 | `week-20-cadena_de_suministro_y_politicas_como_codigo` | Seguridad |
| 21 | `week-21-observabilidad_slo_y_troubleshooting` | Operación y HA |
| 22 | `week-22-backup_recuperacion_y_respuesta_a_incidentes` | Operación y HA |
| 23 | `week-23-alta_disponibilidad_con_praefect_y_postgresql` | Operación y HA |
| 24 | `week-24-terraform_y_estado_remoto_en_gitlab` | IaC y GitOps |
| 25 | `week-25-gitops_con_gitlab_agent_y_entrega_progresiva` | IaC y GitOps |
| 26 | `week-26-capstone_plataforma_gitlab_completa` | Capstone |

Esta tabla existe en tres sitios y los tres tienen que coincidir: aquí, en el `README.md` raíz y en `.github/copilot-instructions.md`. El agente `curriculo-coherencia-reviewer` lo comprueba.

### Edición y sustituciones

**GitLab CE puro**: sin gitlab.com, sin EE, sin trials. Cada feature de pago se explica como concepto y la práctica implementa un equivalente libre. La tabla completa de sustituciones está en el `README.md` raíz.

Esto elimina el riesgo que hundía la propuesta senior —la licencia de 30 días— y mejora el material: el alumno aprende a resolver el problema, no a pulsar el botón que lo resuelve.

---

## Consecuencias

**A favor**

- Un solo hilo conductor: una instancia, un grupo, 26 capas que se apilan.
- No se repiten fundamentos ni se pide al alumno que se autoclasifique de entrada.
- Sin dependencia de licencias temporales.
- 8 h/semana permite 7-8 archivos de teoría y 4 prácticas con profundidad real, frente a los 5 archivos que cabían en 6 h.

**En contra**

- 26 semanas son seis meses de compromiso. El abandono a mitad es un riesgo real; se mitiga con fases que cierran en un estado presentable (al terminar la fase 3 ya hay una plataforma CI/CD defendible).
- Sube el requisito de máquina de 8 a 16 GB.
- El contenido de las 13 semanas antiguas no se migra: se reescribe.

### Contenido anterior

Las 13 semanas originales viven en `bootcamp/_legado/` mientras se absorben. Cada semana nueva toma de ahí lo que le sirve y borra lo que consume. Cuando `_legado/` quede vacío se elimina, junto con su exclusión en `scripts/verificar-enlaces.sh`.

Correspondencia aproximada:

| Semana antigua | Se reparte en |
|---|---|
| 01 Fundamentos de Git y GitLab CE | 01, 02 |
| 02 Instalación de GitLab CE | 01 |
| 03 Proyectos, grupos y organización | 03, 04 |
| 04 Issues, MR y code review | 05, 06 |
| 05 CI/CD fundamentos | 09, 10 |
| 06 CI/CD pipelines avanzados | 11, 12 |
| 07 GitLab Runner | 15, 16 |
| 08 Container y Package Registry | 13 |
| 09 API y automatización | 17 |
| 10 Administración y seguridad | 18 |
| 11 Monitoreo, backup y HA | 21, 22, 23 |
| 12 Proyecto final | 26 |
| 13 IaC y GitOps | 24, 25 |

---

[← Volver a docs](README.md)

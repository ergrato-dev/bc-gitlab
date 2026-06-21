# Semana 05 — GitLab CI/CD: Fundamentos

## Objetivos

- Entender los conceptos basicos de CI/CD
- Escribir un archivo `.gitlab-ci.yml` funcional
- Definir stages, jobs y scripts
- Usar imagenes Docker en pipelines
- Ejecutar el primer pipeline exitosamente

## Requisitos Previos

- GitLab CE funcional (Semana 02)
- GitLab Runner registrado (se registrara en esta semana)
- Proyectos en GitLab (Semana 03)

## Estructura de la Semana

| Componente | Tiempo | Descripcion |
|-----------|--------|-------------|
| Teoria | 2h | Conceptos CI/CD, .gitlab-ci.yml, stages |
| Practicas | 3h | Pipeline basico, imagenes, artifacts |
| Proyecto | 1h | Pipeline CI funcional para proyecto real |

## Contenidos

### Teoria
1. [01-que-es-ci-cd.md](./1-teoria/01-que-es-ci-cd.md) — Continuous Integration / Delivery / Deployment
2. [02-gitlab-ci-yml.md](./1-teoria/02-gitlab-ci-yml.md) — Estructura del archivo de pipeline
3. [03-stages-y-jobs.md](./1-teoria/03-stages-y-jobs.md) — Stages, jobs, script
4. [04-imagenes-docker.md](./1-teoria/04-imagenes-docker.md) — Usar Docker images en CI
5. [05-artifacts-y-cache.md](./1-teoria/05-artifacts-y-cache.md) — Persistencia entre jobs

### Practicas
1. [01-primer-pipeline/](./2-practicas/01-primer-pipeline/) — Pipeline minimo funcional
2. [02-stages-y-jobs/](./2-practicas/02-stages-y-jobs/) — Multiples stages
3. [03-imagenes-personalizadas/](./2-practicas/03-imagenes-personalizadas/) — Docker images custom
4. [04-artifacts-y-cache/](./2-practicas/04-artifacts-y-cache/) — Compartir archivos entre jobs

### Proyecto
- [3-proyecto/](./3-proyecto/) — Pipeline CI completo para proyecto Node.js o Python

## Entregables

- [ ] `.gitlab-ci.yml` funcional
- [ ] Pipeline con al menos 3 stages ejecutandose
- [ ] Artifacts generados correctamente
- [ ] Runner registrado y activo

---

[← Semana 04](../week-04-issues_merge_requests_y_code_review/README.md) | [Semana 06 →](../week-06-gitlab_ci_cd_pipelines_avanzados/README.md)

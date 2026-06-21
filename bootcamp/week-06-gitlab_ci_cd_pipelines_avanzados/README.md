# Semana 06 — GitLab CI/CD: Pipelines Avanzados

## Objetivos

- Dominar variables CI/CD y entornos
- Implementar pipelines condicionales (rules, only/except)
- Usar `include` para modularizar pipelines
- Configurar environments y deployments
- Crear pipelines multi-proyecto con triggers

## Requisitos Previos

- Pipeline basico funcional (Semana 05)
- Proyecto con codigo en GitLab

## Estructura de la Semana

| Componente | Tiempo | Descripcion |
|-----------|--------|-------------|
| Teoria | 2h | Variables, rules, include, environments |
| Practicas | 3h | Pipelines condicionales, modularizacion |
| Proyecto | 1h | Pipeline CI/CD avanzado |

## Contenidos

### Teoria
1. [01-variables-ci-cd.md](./1-teoria/01-variables-ci-cd.md) — Variables, alcance, mascaras
2. [02-rules-y-condicionales.md](./1-teoria/02-rules-y-condicionales.md) — rules, only, except, when
3. [03-include-y-modularizacion.md](./1-teoria/03-include-y-modularizacion.md) — include: local, remote, template
4. [04-environments-y-deployments.md](./1-teoria/04-environments-y-deployments.md) — Dev, staging, production
5. [05-triggers-y-pipelines-multi-proyecto.md](./1-teoria/05-triggers-y-pipelines-multi-proyecto.md) — Downstream pipelines

### Practicas
1. [01-variables-y-secretos/](./2-practicas/01-variables-y-secretos/) — Variables protegidas y enmascaradas
2. [02-rules-condicionales/](./2-practicas/02-rules-condicionales/) — Rules por rama, tag, variable
3. [03-include-templates/](./2-practicas/03-include-templates/) — Modularizar pipeline
4. [04-environments/](./2-practicas/04-environments/) — Deploy a staging/production

### Proyecto
- [3-proyecto/](./3-proyecto/) — Pipeline CI/CD completo con stages y environments

## Entregables

- [ ] Pipeline con rules condicionales
- [ ] Variables CI/CD configuradas
- [ ] Pipeline modularizado con include
- [ ] Environment staging configurado

---

[← Semana 05](../week-05-gitlab_ci_cd_fundamentos/README.md) | [Semana 07 →](../week-07-gitlab_runner_gestion_y_escalado/README.md)

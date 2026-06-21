# Semana 07 — GitLab Runner: Gestion y Escalado

## Objetivos

- Instalar y registrar GitLab Runner en multiples plataformas
- Configurar diferentes tipos de ejecutores (Docker, Shell, Kubernetes)
- Administrar Runners compartidos, de grupo y especificos
- Implementar autoscaling con Docker Machine
- Configurar tags para dirigir jobs a runners especificos

## Requisitos Previos

- Pipeline CI/CD funcional (Semanas 05-06)
- Docker instalado

## Estructura de la Semana

| Componente | Tiempo | Descripcion |
|-----------|--------|-------------|
| Teoria | 2h | Tipos de Runner, ejecutores, autoscaling |
| Practicas | 3h | Instalar, registrar, configurar runners |
| Proyecto | 1h | Infraestructura de Runners completa |

## Contenidos

### Teoria
1. [01-tipos-de-runners.md](./1-teoria/01-tipos-de-runners.md) — Shared, group, specific, instance
2. [02-ejecutores.md](./1-teoria/02-ejecutores.md) — Docker, Shell, Kubernetes, VirtualBox
3. [03-registro-y-configuracion.md](./1-teoria/03-registro-y-configuracion.md) — register, config.toml
4. [04-tags-y-job-routing.md](./1-teoria/04-tags-y-job-routing.md) — Tags para enrutar jobs
5. [05-autoscaling.md](./1-teoria/05-autoscaling.md) — Docker Machine, Kubernetes executor

### Practicas
1. [01-instalar-runner/](./2-practicas/01-instalar-runner/) — Instalar y registrar Runner
2. [02-configurar-ejecutores/](./2-practicas/02-configurar-ejecutores/) — Docker vs Shell executor
3. [03-tags-y-routing/](./2-practicas/03-tags-y-routing/) — Tags para jobs especificos
4. [04-runner-kubernetes/](./2-practicas/04-runner-kubernetes/) — Runner en Kubernetes

### Proyecto
- [3-proyecto/](./3-proyecto/) — Infraestructura de Runners con tags y ejecutores

## Entregables

- [ ] Runner Docker registrado y funcionando
- [ ] Al menos 2 runners con diferentes tags
- [ ] Jobs ejecutandose en el runner correcto
- [ ] config.toml documentado

---

[← Semana 06](../week-06-gitlab_ci_cd_pipelines_avanzados/README.md) | [Semana 08 →](../week-08-container_registry_y_package_registry/README.md)

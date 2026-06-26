# Semana 11 — Monitoreo, Backup y Alta Disponibilidad

## Objetivos

- Configurar monitoreo con Prometheus y Grafana
- Implementar políticas de backup y restore automatizado
- Diseñar arquitectura de alta disponibilidad (conceptual)
- Entender PostgreSQL HA y Redis Sentinel a nivel arquitectural
- Conocer Gitaly Cluster como concepto (implementación fuera del alcance de CE self-managed básico)

> **Alcance realista para 6 horas:** PostgreSQL HA (Patroni/Repmgr) y Gitaly Cluster requieren clústeres multi-nodo que exceden el entorno Docker Compose del bootcamp. Esta semana cubre monitoreo y backup en práctica, y HA en diseño/teoría.

## Requisitos Previos

- Administración de GitLab CE (Semana 10)
- Docker y Docker Compose

## Estructura de la Semana

| Componente | Tiempo | Descripción |
|-----------|--------|-------------|
| Teoría | 2h | Monitoreo, backup, HA, Gitaly Cluster |
| Prácticas | 3h | Configurar Prometheus, backup/restore |
| Proyecto | 1h | Plan de HA con DR |

## Contenidos

### Teoría
1. [01-monitoreo-gitlab.md](./1-teoria/01-monitoreo-gitlab.md) — Prometheus integrado, exporters, Grafana
2. [02-backup-y-restore.md](./1-teoria/02-backup-y-restore.md) — gitlab-backup, estrategias, S3
3. [03-alta-disponibilidad.md](./1-teoria/03-alta-disponibilidad.md) — HA overview, componentes críticos
4. [04-postgresql-ha.md](./1-teoria/04-postgresql-ha.md) — Repmgr, Patroni, failover (arquitectura y conceptos)
5. [05-gitaly-cluster.md](./1-teoria/05-gitaly-cluster.md) — Gitaly Cluster y Praefect (diseño; requiere entorno multi-nodo)

### Prácticas
1. [01-prometheus-grafana/](./2-practicas/01-prometheus-grafana/) — Configurar monitoreo
2. [02-backup-automatico/](./2-practicas/02-backup-automatico/) — Script de backup + cron
3. [03-restore-practico/](./2-practicas/03-restore-practico/) — Restaurar desde backup
4. [04-ha-diseno/](./2-practicas/04-ha-diseno/) — Diseño de arquitectura HA (diagrama + decisiones técnicas)

### Proyecto
- [3-proyecto/](./3-proyecto/) — Plan de Disaster Recovery completo

## Entregables

- [ ] Dashboard Grafana funcional
- [ ] Backup automático configurado
- [ ] Restore probado exitosamente
- [ ] Diagrama de arquitectura HA

---

[← Semana 10](../week-10-administracion_y_seguridad/README.md) | [Semana 12 →](../week-12-proyecto_final/README.md)

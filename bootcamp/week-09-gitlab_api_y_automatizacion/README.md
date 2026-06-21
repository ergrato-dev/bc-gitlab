# Semana 09 — GitLab API y Automatización

## Objetivos

- Usar GitLab REST API para automatizar tareas
- Explorar GitLab GraphQL API para consultas complejas
- Crear scripts de automatización con Python
- Gestionar proyectos, issues y MRs vía API
- Configurar webhooks para integraciones externas

## Requisitos Previos

- GitLab CE funcional
- Python 3.12+ básico
- Proyectos y CI/CD (Semanas anteriores)

## Estructura de la Semana

| Componente | Tiempo | Descripción |
|-----------|--------|-------------|
| Teoría | 2h | REST API, GraphQL, webhooks, tokens |
| Prácticas | 3h | Scripts de automatización con Python |
| Proyecto | 1h | Bot de automatización DevOps |

## Contenidos

### Teoría
1. [01-intro-gitlab-api.md](./1-teoria/01-intro-gitlab-api.md) — REST API: autenticación, endpoints
2. [02-graphql-api.md](./1-teoria/02-graphql-api.md) — GraphQL queries y mutations
3. [03-personal-access-tokens.md](./1-teoria/03-personal-access-tokens.md) — PAT, project tokens, group tokens
4. [04-webhooks.md](./1-teoria/04-webhooks.md) — Configurar y probar webhooks
5. [05-automatizacion-python.md](./1-teoria/05-automatizacion-python.md) — python-gitlab library

### Prácticas
1. [01-rest-api-basico/](./2-practicas/01-rest-api-basico/) — CRUD vía REST API
2. [02-graphql-consultas/](./2-practicas/02-graphql-consultas/) — GraphQL en práctica
3. [03-webhooks-integracion/](./2-practicas/03-webhooks-integracion/) — Webhook a Slack/Discord
4. [04-python-automatizacion/](./2-practicas/04-python-automatizacion/) — Script con python-gitlab

### Proyecto
- [3-proyecto/](./3-proyecto/) — Bot que automatiza tareas repetitivas vía API

## Entregables

- [ ] Script Python funcional usando API
- [ ] Consulta GraphQL funcional
- [ ] Webhook configurado y probado
- [ ] Documentación de endpoints usados

---

[← Semana 08](../week-08-container_registry_y_package_registry/README.md) | [Semana 10 →](../week-10-administracion_y_seguridad/README.md)

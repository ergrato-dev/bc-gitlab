# Proyecto Semana 03 — Estructura Organizacional Completa

## Objetivo
Disenar e implementar una estructura organizacional completa en GitLab CE para un equipo ficticio de desarrollo de software.

## Escenario

Eres el DevOps Lead de **TechNova**, una startup que desarrolla una plataforma SaaS de e-commerce. El equipo tiene 3 squads:

- **Squad Orion**: Frontend (React, Next.js) — 3 developers, 1 maintainer
- **Squad Vega**: Backend (Go, microservicios) — 4 developers, 1 maintainer
- **Squad Nexus**: DevOps/Infra (Terraform, Kubernetes) — 2 developers, 1 maintainer

## Requisitos

### 1. Estructura de Grupos

```
technova/
├── orion/          (Squad Orion)
├── vega/           (Squad Vega)
├── nexus/          (Squad Nexus)
└── shared/         (Librerias y configs compartidas)
```

### 2. Proyectos Minimamente Requeridos

| Grupo | Proyecto | Descripcion |
|-------|---------|-------------|
| orion | storefront | Frontend principal de la tienda |
| orion | admin-panel | Panel de administracion |
| vega | api-gateway | API Gateway (Kong/Traefik) |
| vega | product-service | Microservicio de productos |
| vega | order-service | Microservicio de ordenes |
| vega | user-service | Microservicio de usuarios |
| nexus | infrastructure | Infraestructura como codigo |
| nexus | ci-cd-config | Configuracion compartida de pipelines |
| shared | design-system | Sistema de diseno compartido |
| shared | api-contracts | Contratos OpenAPI/gRPC |

### 3. Permisos

| Grupo | Miembros | Rol |
|-------|---------|-----|
| technova | root | Owner |
| technova | squad-leads (maintainer1) | Maintainer |
| orion | dev-orion-1, -2, -3 | Developer |
| vega | dev-vega-1, -2, -3, -4 | Developer |
| nexus | dev-nexus-1, -2 | Developer |
| shared (en cada squad) | todos los devs | Developer |

### 4. Proteccion de Ramas

- `main`: Protegida en TODOS los proyectos (merge: Maintainers, push: Nobody)
- `develop`: Protegida en orion y vega (merge/push: Developers + Maintainers)
- `production`: Protegida en nexus/infrastructure (merge: Maintainers, push: Nobody)

## Entregables

1. **Diagrama de estructura** (ASCII o herramienta visual) mostrando grupos, subgrupos y proyectos
2. **Capturas de Members** de cada grupo mostrando miembros y roles
3. **Captura de Protected branches** en 2 proyectos representativos
4. **Prueba de acceso**: Push exitoso via MR de un developer y merge por maintainer
5. **Documento ORGANIZATION.md** describiendo:
   - Estructura y justificacion
   - Matriz de permisos
   - Reglas de proteccion de ramas
   - Flujo de trabajo esperado

## Criterios de Evaluacion

- [ ] Estructura de grupos coherente y bien nombrada
- [ ] Proyectos creados en los grupos correctos
- [ ] Permisos asignados correctamente (herencia + granularidad)
- [ ] Ramas protegidas configuradas en todos los niveles requeridos
- [ ] Documentacion clara de la organizacion
- [ ] Prueba funcional de push denial y MR merge

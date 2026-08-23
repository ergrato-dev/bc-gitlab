# Semana 13 — Infraestructura como Código y GitOps

## Objetivos

- Aplicar Infrastructure as Code (IaC) a la gestión de una instancia GitLab con Terraform
- Usar el Terraform GitLab Provider para declarar proyectos, grupos, variables y branch protection
- Gestionar el state de forma remota con GitLab Managed Terraform State
- Comprender los fundamentos de GitOps y contrastarlos con el modelo push-based ya conocido
- Instalar y registrar el GitLab Kubernetes Agent en un clúster Minikube
- Construir un pipeline CI/CD que valide, planee y aplique Terraform de forma segura, con detección de drift y policy-as-code

## Requisitos Previos

- Proyectos, grupos y protección de ramas creados manualmente (Semana 03)
- GitLab Runner en Kubernetes / clúster Minikube funcional (Semana 07)
- GitLab API, tokens y automatización con scripts (Semana 09)

## Estructura de la Semana

| Componente | Tiempo | Descripción |
|-----------|--------|-------------|
| Teoría | 2h | IaC, Terraform GitLab Provider, GitOps, Kubernetes Agent, CI/CD con Terraform |
| Prácticas | 3h | Provisionar con Terraform, módulo reutilizable, Agent en Minikube, pipeline GitOps |
| Proyecto | 1h | Reproducir infraestructura existente con Terraform + deploy GitOps a Minikube |

**Total: 6 horas**

## Contenidos

### Teoría
1. [01-introduccion-iac.md](./1-teoria/01-introduccion-iac.md) — IaC aplicada a GitLab: Terraform vs scripts, state, plan/apply
2. [02-terraform-gitlab-provider.md](./1-teoria/02-terraform-gitlab-provider.md) — Recursos del provider, módulos, remote state, `terraform import`
3. [03-fundamentos-gitops.md](./1-teoria/03-fundamentos-gitops.md) — Declarativo vs imperativo, reconciliation loop, GitOps vs CI/CD push-based
4. [04-gitlab-kubernetes-agent.md](./1-teoria/04-gitlab-kubernetes-agent.md) — Instalación de agentk, autorización, impersonation, despliegue de manifiestos
5. [05-cicd-con-terraform.md](./1-teoria/05-cicd-con-terraform.md) — Pipeline validate/plan/apply, state locking, drift detection, policy-as-code

### Prácticas
1. [01-provisionar-con-terraform/](./2-practicas/01-provisionar-con-terraform/) — Provisionar proyecto/grupo GitLab con Terraform
2. [02-modulo-reutilizable/](./2-practicas/02-modulo-reutilizable/) — Módulo Terraform: branch protection + variables + webhooks
3. [03-agent-en-minikube/](./2-practicas/03-agent-en-minikube/) — Instalar y registrar el Kubernetes Agent en Minikube
4. [04-pipeline-gitops/](./2-practicas/04-pipeline-gitops/) — Pipeline GitOps que sincroniza manifiestos vía el Agent

### Proyecto
- [3-proyecto/](./3-proyecto/) — Reproducir infraestructura de semanas 03-04 con Terraform + deploy GitOps de una app demo

## Entregables

- [ ] Infraestructura de semanas 03-04 gestionada por Terraform (importada, no recreada)
- [ ] State remoto en GitLab Managed Terraform State
- [ ] Módulo Terraform reutilizable instanciado al menos dos veces
- [ ] Pipeline Terraform con validate/plan/apply funcionando
- [ ] Kubernetes Agent conectado y visible en Operate → Kubernetes clusters
- [ ] App de ejemplo desplegada por GitOps, con drift corregido automáticamente demostrado

---

[← Semana 12](../week-12-proyecto_final/README.md)

# Proyecto Semana 13 — Infraestructura Reproducida con Terraform + GitOps a Minikube

## Objetivo

Tomar la infraestructura de GitLab creada manualmente en semanas previas (proyectos, grupos y protección de ramas de las semanas 03-04) y reproducirla al 100% mediante Terraform, gestionando el state en GitLab Managed Terraform State. Además, desplegar una aplicación de ejemplo al clúster Minikube usando GitOps a través del GitLab Kubernetes Agent, cerrando el ciclo completo: infraestructura como código + despliegue declarativo.

## Descripción del proyecto

Este proyecto integra las cuatro piezas cubiertas en la semana:

1. **Terraform** describe la estructura de GitLab (grupos, proyectos, branch protection, variables CI/CD)
2. **`terraform import`** adopta lo que ya existía manualmente, sin recrearlo
3. **El Kubernetes Agent** conecta un clúster Minikube con un repositorio de manifiestos
4. **Un pipeline GitOps** actualiza esos manifiestos en cada deploy, sin acceso directo del runner al clúster

## Entregables detallados

### 1. Código Terraform de la infraestructura reproducida

- `terraform/` con `providers.tf`, `variables.tf`, `main.tf`, `backend.tf`, `outputs.tf`
- Al menos un grupo y dos proyectos de las semanas 03-04, **importados** con `terraform import` (o bloques `import {}` declarativos) — no recreados desde cero
- Branch protection de `main` declarada en Terraform, coincidiendo exactamente con la configuración manual existente (verificable con `terraform plan` mostrando "No changes" tras el import)
- Al menos un módulo reutilizable (basado en la práctica 02) usado para al menos uno de los proyectos
- State remoto en GitLab Managed Terraform State — visible en Operate → Terraform states

### 2. Pipeline CI/CD para Terraform

- `.gitlab-ci.yml` con stages `validate`, `plan`, `apply`
- `plan` publicado como reporte del MR (`artifacts.reports.terraform`)
- `apply` con `when: manual`, restringido a `main`
- Un job `drift_check` (puede ejecutarse manualmente para la entrega, no requiere un Pipeline Schedule real activo)

### 3. GitLab Kubernetes Agent conectado a Minikube

- Agent registrado y visible como "Connected" en Operate → Kubernetes clusters
- `config.yaml` en `.gitlab/agents/<nombre>/` apuntando al repositorio de manifiestos
- RBAC de mínimo privilegio aplicado (ni el agent ni su Service Account deben tener `cluster-admin`)

### 4. Aplicación de ejemplo desplegada por GitOps

- Manifiestos (`deployment.yaml`, `service.yaml`) de una app de ejemplo en `manifests/produccion/`
- Un pipeline que actualiza el tag de imagen en el manifiesto en cada push a `main` (sin `kubectl apply` directo desde el runner)
- Evidencia de que el agent sincronizó el cambio: captura de `kubectl get deployment -o jsonpath='{.spec.template.spec.containers[0].image}'` mostrando el SHA del commit
- Evidencia de drift corregido automáticamente (captura de antes/después de un `kubectl scale` manual)

### 5. Documentación

- `README.md` del proyecto explicando cómo levantar el entorno desde cero (terraform init/apply, registro del agent, primer deploy)
- Diagrama simple (puede ser un `.svg` o una descripción en texto) del flujo commit → pipeline → Git → agent → clúster

## Estructura de archivos esperada

```
proyecto-iac-gitops/
├── terraform/
│   ├── providers.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── backend.tf
│   ├── outputs.tf
│   └── modules/
│       └── gitlab-microservicio/
├── .gitlab/
│   └── agents/
│       └── <nombre-agent>/
│           └── config.yaml
├── manifests/
│   └── produccion/
│       └── demo-app/
│           ├── deployment.yaml
│           └── service.yaml
├── .gitlab-ci.yml
└── README.md
```

## Criterios de evaluación

- [ ] Infraestructura de semanas 03-04 importada (no recreada) y gestionada por Terraform
- [ ] `terraform plan` sobre la infraestructura importada muestra "No changes" (import fiel al estado real)
- [ ] State remoto en GitLab Managed Terraform State, sin locks huérfanos
- [ ] Al menos un módulo Terraform reutilizable, instanciado correctamente
- [ ] Pipeline Terraform con validate/plan/apply funcionando, plan visible en el MR
- [ ] Kubernetes Agent conectado a Minikube con estado "Connected" en la UI
- [ ] RBAC de mínimo privilegio verificado con `kubectl auth can-i`
- [ ] App de ejemplo desplegada exitosamente vía el pipeline GitOps (no `kubectl apply` manual)
- [ ] Drift demostrado y corregido automáticamente por el agent
- [ ] Documentación suficiente para que otra persona reproduzca el entorno sin asistencia

## Recursos starter

En el directorio `starter/` encontrarás:
- Un esqueleto de `terraform/` con `providers.tf` y `backend.tf` de referencia
- Un `Makefile` con atajos (`tf-init`, `tf-plan`, `tf-apply`, `agent-status`, `gitops-verify`)

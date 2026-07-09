# Práctica 02 — Módulo Terraform Reutilizable: Branch Protection + Variables + Webhooks

## Objetivo

Diseñar un módulo Terraform que encapsule la configuración estándar de un microservicio (protección de rama, variables CI/CD y webhook de notificación) e instanciarlo dos veces para demostrar reutilización sin duplicar código HCL.

## Requisitos

- Práctica 01 completada (Terraform + backend remoto funcionando)
- Un endpoint HTTP para probar el webhook (ej. [webhook.site](https://webhook.site) o un `nc -l` local)
- Tiempo estimado: 60-75 minutos

---

## Instrucciones

### Paso 1: Explorar la estructura del módulo

```bash
cp -r /ruta/al/starter/* .
tree modules/
# modules/
# └── gitlab-microservicio/
#     ├── main.tf
#     ├── variables.tf
#     └── outputs.tf
```

Revisa `modules/gitlab-microservicio/main.tf`: declara `gitlab_project`, `gitlab_branch_protection`, `gitlab_project_variable` (con `for_each`) y `gitlab_project_hook`.

### Paso 2: Completar el recurso de webhook en el módulo

El starter deja `gitlab_project_hook` incompleto. Complétalo para que dispare en eventos de push y de pipeline:

```hcl
# modules/gitlab-microservicio/main.tf
# ¿QUÉ HACE?: Registra un webhook que notifica a un endpoint externo en push y en cambios de pipeline
# ¿POR QUÉ?: Reproduce as-code la práctica de webhooks vista en semana 09, pero versionada en Terraform
# ¿PARA QUÉ?: Que todo microservicio nuevo tenga el mismo webhook sin configurarlo manualmente
resource "gitlab_project_hook" "notificaciones" {
  project = gitlab_project.this.id
  url     = var.webhook_url

  push_events          = true
  pipeline_events      = true
  merge_requests_events = true
  enable_ssl_verification = false
}
```

### Paso 3: Instanciar el módulo dos veces

En `main.tf` (raíz), completa las dos instancias del módulo con nombres y variables CI/CD distintas:

```hcl
module "api_pagos" {
  source       = "./modules/gitlab-microservicio"
  nombre       = "api-pagos"
  group_id     = gitlab_group.plataforma.id
  webhook_url  = var.webhook_url

  ci_variables = {
    ENVIRONMENT = { value = "staging", protected = false, masked = false }
  }
}

module "api_notificaciones" {
  source       = "./modules/gitlab-microservicio"
  nombre       = "api-notificaciones"
  group_id     = gitlab_group.plataforma.id
  webhook_url  = var.webhook_url

  ci_variables = {
    ENVIRONMENT = { value = "staging", protected = false, masked = false }
  }
}
```

### Paso 4: Aplicar y verificar

```bash
terraform init
terraform plan -out=tfplan
# → Plan: 8 to add (2 proyectos x [project, branch_protection, variable, hook])
terraform apply tfplan
```

```bash
# Verificar branch protection vía API
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$(terraform output -raw api_pagos_project_id)/protected_branches" | jq

# Verificar que el webhook está registrado
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$(terraform output -raw api_pagos_project_id)/hooks" | jq
```

### Paso 5: Cambiar el módulo una vez, propagar a ambas instancias

```bash
# Edita modules/gitlab-microservicio/main.tf: cambia push_access_level a "maintainer"
terraform plan -out=tfplan
# → Plan: 0 to add, 2 to change, 0 to destroy  (ambos proyectos afectados por UN solo cambio en el módulo)
terraform apply tfplan
```

Esto demuestra el valor central de los módulos: un cambio de política aplica a todos los microservicios que usan el módulo, sin tocarlos uno por uno.

---

## Preguntas de reflexión

1. ¿Qué ventaja tiene declarar `ci_variables` como `map(object({...}))` con `for_each` en vez de un bloque `resource` por variable?
2. Si mañana se agrega un tercer microservicio, ¿cuántas líneas de código HCL nuevo hacen falta?
3. ¿Qué pasaría si dos módulos distintos intentan crear un webhook con la misma URL en el mismo proyecto?

---

## Entregables

- [ ] Módulo `gitlab-microservicio` completo con `gitlab_project_hook` funcional
- [ ] Dos instancias del módulo aplicadas (`api_pagos`, `api_notificaciones`)
- [ ] Verificación por API de branch protection y webhook en ambos proyectos
- [ ] Plan que muestre `2 to change, 0 to add` tras modificar el módulo una sola vez

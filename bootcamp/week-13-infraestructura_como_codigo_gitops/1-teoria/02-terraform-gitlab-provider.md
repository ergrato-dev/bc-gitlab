# 02 — Terraform GitLab Provider: recursos, módulos y remote state

El [Terraform GitLab Provider](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs), mantenido por GitLab, expone como recursos Terraform prácticamente todo lo que la API REST permite gestionar: proyectos, grupos, variables, protecciones de rama, webhooks, miembros, deploy tokens y más. Esta teoría cubre los recursos más usados, cómo empaquetarlos en módulos reutilizables y cómo guardar el state de forma remota usando el backend HTTP nativo de GitLab.

![Recursos del provider de Terraform para GitLab organizados en un módulo](../0-assets/02-terraform-provider-recursos.svg)

---

## Configuración del provider

```hcl
# providers.tf
# ¿QUÉ HACE?: Declara qué provider usa este proyecto Terraform y con qué versión
# ¿POR QUÉ?: Sin esta declaración, `terraform init` no sabe qué plugin descargar
# ¿PARA QUÉ?: Fijar un rango de versión predecible (~> 17.0 acepta parches, no minors nuevos)
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 17.0"
    }
  }
}

# ¿QUÉ HACE?: Configura la conexión del provider contra la instancia GitLab CE del bootcamp
# ¿POR QUÉ?: El token nunca se hardcodea — se lee de una variable de entorno TF_VAR_gitlab_token
# ¿PARA QUÉ?: Autenticar todas las llamadas que el provider hace a la API REST/GraphQL de GitLab
provider "gitlab" {
  base_url = "http://localhost/api/v4/"
  token    = var.gitlab_token
}

variable "gitlab_token" {
  description = "Personal/project access token con scope api"
  type        = string
  sensitive   = true
}
```

```bash
# ¿QUÉ HACE?: Exporta el token como variable de entorno que Terraform lee automáticamente
# ¿POR QUÉ?: TF_VAR_<nombre> es la convención de Terraform para inyectar variables sin escribirlas en archivos
# ¿PARA QUÉ?: Evitar que el token quede en el historial de Git o en el state en texto plano innecesariamente
export TF_VAR_gitlab_token="glpat-XXXXXXXXXXXXXXXXXXXX"
```

---

## `gitlab_project`: el recurso base

```hcl
# ¿QUÉ HACE?: Declara un proyecto GitLab con configuración completa de CI/CD y visibilidad
# ¿POR QUÉ?: Cada atributo aquí reemplaza un clic manual en Settings del proyecto
# ¿PARA QUÉ?: Que un proyecto nuevo nazca ya configurado según el estándar del equipo
resource "gitlab_project" "api_pagos" {
  name        = "api-pagos"
  description = "Servicio de procesamiento de pagos"
  namespace_id = gitlab_group.plataforma.id

  visibility_level = "private"
  default_branch   = "main"

  # CI/CD
  auto_devops_enabled              = false
  builds_access_level              = "enabled"
  container_registry_access_level  = "enabled"

  # Configuración de merge requests
  merge_method                        = "merge"
  only_allow_merge_if_pipeline_succeeds = true
  only_allow_merge_if_all_discussions_are_resolved = true
  remove_source_branch_after_merge    = true

  # Seguridad
  squash_option = "default_on"
}
```

| Atributo | Equivalente manual (semana 03/04) |
|---|---|
| `visibility_level` | Settings → General → Visibility |
| `only_allow_merge_if_pipeline_succeeds` | Settings → Merge requests → Pipelines must succeed |
| `container_registry_access_level` | Settings → General → Container Registry |
| `default_branch` | Repository → Branches → Default |

---

## `gitlab_group`: organización jerárquica

```hcl
# ¿QUÉ HACE?: Declara la jerarquía de grupos y subgrupos de la organización
# ¿POR QUÉ?: La jerarquía completa de semana 03 (grupos, subgrupos, permisos heredados) es reproducible en código
# ¿PARA QUÉ?: Onboarding de un nuevo equipo = agregar un bloque de código, no una checklist manual
resource "gitlab_group" "plataforma" {
  name        = "plataforma"
  path        = "plataforma"
  description = "Equipos de plataforma e infraestructura"

  visibility_level         = "internal"
  lfs_enabled               = true
  request_access_enabled    = false
  default_branch_protection = 0  # 0 = totalmente desprotegida por defecto a nivel grupo; se protege por proyecto
}

resource "gitlab_group" "plataforma_backend" {
  name      = "backend"
  path      = "backend"
  parent_id = gitlab_group.plataforma.id  # subgrupo — hereda permisos del padre
}
```

---

## `gitlab_project_variable`: CI/CD como código

```hcl
# ¿QUÉ HACE?: Declara variables CI/CD del proyecto, incluyendo protegidas y enmascaradas
# ¿POR QUÉ?: Configurar variables a mano en Settings → CI/CD es el paso que más se olvida al clonar un proyecto
# ¿PARA QUÉ?: Garantizar que todo proyecto de este tipo nace con las mismas variables, sin excepción
resource "gitlab_project_variable" "registry_password" {
  project           = gitlab_project.api_pagos.id
  key               = "REGISTRY_PASSWORD"
  value             = var.registry_password
  protected         = true
  masked            = true
  environment_scope = "production"
}

resource "gitlab_project_variable" "deploy_environment" {
  project = gitlab_project.api_pagos.id
  key     = "DEPLOY_ENV"
  value   = "staging"
  protected = false
  masked    = false
}
```

> `masked = true` exige que el valor cumpla las reglas de enmascarado de GitLab (sin saltos de línea, longitud mínima) — si el valor no califica, `terraform apply` falla con un error de la API, no de Terraform.

---

## `gitlab_branch_protection`: reglas de rama como código

```hcl
# ¿QUÉ HACE?: Declara la protección de la rama main del proyecto
# ¿POR QUÉ?: Reproduce exactamente la práctica "04-proteger-ramas" de la semana 03, pero versionada
# ¿PARA QUÉ?: Auditar en Git quién cambió el nivel de protección y cuándo, en vez de buscarlo en logs de auditoría de GitLab
resource "gitlab_branch_protection" "main" {
  project            = gitlab_project.api_pagos.id
  branch             = "main"
  push_access_level          = "no one"
  merge_access_level         = "developer"
  unprotect_access_level     = "maintainer"
  allow_force_push           = false

  allowed_to_push {
    access_level = "maintainer"
  }
}
```

---

## Diseño de módulos reutilizables

Un **módulo** es un directorio con `.tf` que encapsula un conjunto de recursos relacionados y expone `variables` de entrada y `outputs` de salida. En vez de copiar y pegar los mismos 20 bloques `resource` para cada microservicio, se define un módulo `gitlab-microservicio` y se instancia una vez por servicio.

```
modules/
└── gitlab-microservicio/
    ├── main.tf         # gitlab_project, gitlab_branch_protection, gitlab_project_variable
    ├── variables.tf    # inputs: nombre, grupo, visibilidad, variables CI/CD
    └── outputs.tf      # outputs: project_id, http_url_to_repo, ssh_url_to_repo
```

```hcl
# modules/gitlab-microservicio/variables.tf
# ¿QUÉ HACE?: Define los parámetros que el módulo acepta al ser instanciado
# ¿POR QUÉ?: Sin variables tipadas, cada instancia del módulo repetiría lógica en vez de solo pasar datos
# ¿PARA QUÉ?: Que crear un microservicio nuevo sea llamar al módulo con 3-4 valores
variable "nombre" {
  type        = string
  description = "Nombre del proyecto/microservicio"
}

variable "group_id" {
  type        = number
  description = "ID del grupo GitLab donde vive el proyecto"
}

variable "ci_variables" {
  type = map(object({
    value     = string
    protected = bool
    masked    = bool
  }))
  default     = {}
  description = "Variables CI/CD a crear en el proyecto"
}
```

```hcl
# modules/gitlab-microservicio/main.tf
# ¿QUÉ HACE?: Crea el proyecto, protege main y crea las variables CI/CD recibidas
# ¿POR QUÉ?: for_each sobre var.ci_variables evita repetir un bloque resource por cada variable
# ¿PARA QUÉ?: El módulo es la unidad reutilizable — un cambio aquí afecta a todos los microservicios que lo usan
resource "gitlab_project" "this" {
  name         = var.nombre
  namespace_id = var.group_id
  visibility_level = "private"
  default_branch   = "main"
}

resource "gitlab_branch_protection" "main" {
  project             = gitlab_project.this.id
  branch              = "main"
  push_access_level   = "no one"
  merge_access_level  = "developer"
}

resource "gitlab_project_variable" "vars" {
  for_each = var.ci_variables

  project   = gitlab_project.this.id
  key       = each.key
  value     = each.value.value
  protected = each.value.protected
  masked    = each.value.masked
}
```

```hcl
# modules/gitlab-microservicio/outputs.tf
output "project_id" {
  value = gitlab_project.this.id
}

output "http_url_to_repo" {
  value = gitlab_project.this.http_url_to_repo
}
```

```hcl
# main.tf (raíz) — instanciando el módulo dos veces
# ¿QUÉ HACE?: Crea dos microservicios reutilizando la misma definición
# ¿POR QUÉ?: Cambiar la protección de rama para TODOS los microservicios = un cambio en el módulo, no en 10 archivos
# ¿PARA QUÉ?: Escalar la plataforma sin escalar la cantidad de código HCL a mantener
module "api_pagos" {
  source   = "./modules/gitlab-microservicio"
  nombre   = "api-pagos"
  group_id = gitlab_group.plataforma_backend.id

  ci_variables = {
    REGISTRY_PASSWORD = { value = var.registry_password, protected = true, masked = true }
  }
}

module "api_notificaciones" {
  source   = "./modules/gitlab-microservicio"
  nombre   = "api-notificaciones"
  group_id = gitlab_group.plataforma_backend.id

  ci_variables = {
    REGISTRY_PASSWORD = { value = var.registry_password, protected = true, masked = true }
  }
}
```

---

## Remote state con GitLab Managed Terraform State

GitLab CE incluye un **backend HTTP** nativo para state de Terraform desde la versión 13.0 — no requiere S3, Azure Blob ni ninguna infraestructura adicional. El state se guarda dentro del propio proyecto GitLab, versionado con locking automático.

```hcl
# backend.tf
# ¿QUÉ HACE?: Configura el backend remoto para que el state viva en GitLab, no en el disco local
# ¿POR QUÉ?: Resuelve los tres problemas del state local (teoría 01): colaboración, locking, exposición de secretos
# ¿PARA QUÉ?: Cualquier miembro del equipo (o el pipeline de CI) puede hacer plan/apply con el mismo state actualizado
terraform {
  backend "http" {
    address        = "http://localhost/api/v4/projects/142/terraform/state/produccion"
    lock_address   = "http://localhost/api/v4/projects/142/terraform/state/produccion/lock"
    unlock_address = "http://localhost/api/v4/projects/142/terraform/state/produccion/lock"
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = 5
  }
}
```

```bash
# ¿QUÉ HACE?: Inicializa Terraform pasando el usuario/token para autenticar contra el backend HTTP
# ¿POR QUÉ?: El backend "http" de GitLab requiere Basic Auth (usuario + PAT) en cada request
# ¿PARA QUÉ?: Reconectar al mismo state remoto sin exponer el token en backend.tf (queda fuera del repo)
terraform init \
  -backend-config="username=terraform-bot" \
  -backend-config="password=$TF_VAR_gitlab_token"
```

```bash
# ¿QUÉ HACE?: Lista los states remotos gestionados por Terraform dentro de un proyecto GitLab
# ¿POR QUÉ?: Un mismo proyecto GitLab puede alojar varios states (uno por entorno: dev, staging, produccion)
# ¿PARA QUÉ?: Ver en la UI de GitLab (Operate → Terraform states) qué states existen y quién los bloqueó
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/142/terraform/state" | jq
```

El panel **Operate → Terraform states** en la UI de GitLab muestra, por cada state remoto: quién tiene el lock actualmente (si alguno), la última vez que se aplicó, y permite descargar o eliminar un state — todo sin salir de GitLab.

### Un state por entorno

```hcl
# backend.tf para el entorno de staging (mismo proyecto Terraform, distinto nombre de state)
terraform {
  backend "http" {
    address = "http://localhost/api/v4/projects/142/terraform/state/staging"
    # ... resto igual, solo cambia el nombre al final de la URL
  }
}
```

Usar un nombre de state distinto por entorno (`produccion`, `staging`) dentro del mismo proyecto GitLab evita que un `terraform apply` accidental en el entorno equivocado destruya producción — cada entorno tiene su propio lock y su propio historial.

---

## `terraform import`: adoptar infraestructura creada manualmente

Los proyectos, grupos y protecciones de rama de las semanas 03-04 fueron creados a mano, en la UI de GitLab — no nacieron desde Terraform. Para que Terraform los gestione sin destruirlos y recrearlos (lo que perdería su historial, su ID y sus referencias), se usa `terraform import`: vincula un recurso ya existente con un bloque `resource` declarado en el código.

```hcl
# Paso 1: declarar el bloque resource "vacío" que representará el recurso existente
# ¿QUÉ HACE?: Crea el destino del import — Terraform necesita un bloque resource para asociar el ID real
# ¿POR QUÉ?: import no genera el código HCL automáticamente (en Terraform < 1.5) — solo asocia state con recurso
# ¿PARA QUÉ?: Que el import tenga dónde "aterrizar" antes de ejecutar el comando
resource "gitlab_project" "api_pagos" {
  name         = "api-pagos"   # se completa con los valores reales tras el import
  namespace_id = 42
}
```

```bash
# ¿QUÉ HACE?: Vincula el proyecto GitLab con ID 142 (creado manualmente en semana 03) con este bloque resource
# ¿POR QUÉ?: Sin import, un `apply` intentaría CREAR un proyecto nuevo con el mismo nombre y fallaría (ya existe)
# ¿PARA QUÉ?: Que Terraform "adopte" el recurso existente en su state, sin recrearlo
terraform import gitlab_project.api_pagos 142

# gitlab_project.api_pagos: Importing from ID "142"...
# gitlab_project.api_pagos: Import prepared!
#   Prepared gitlab_project for import
# gitlab_project.api_pagos: Refreshing state... [id=142]
#
# Import successful!
```

```bash
# ¿QUÉ HACE?: Muestra los valores reales del recurso importado, tal como quedaron en el state
# ¿POR QUÉ?: El bloque resource del código HCL debe actualizarse para que coincida —
#             de lo contrario, el próximo `plan` mostrará un diff "fantasma" (drift day 1)
# ¿PARA QUÉ?: Copiar los atributos reales al archivo .tf hasta que `terraform plan` no muestre cambios
terraform state show gitlab_project.api_pagos
```

```bash
# ¿QUÉ HACE?: Confirma que, tras ajustar el HCL a los valores reales, el plan queda "limpio"
# ¿POR QUÉ?: El objetivo del import es que Terraform gestione el recurso SIN proponer cambios el día 1
# ¿PARA QUÉ?: Validar que el código HCL describe fielmente lo que ya existía manualmente
terraform plan
# No changes. Your infrastructure matches the configuration.
```

Terraform 1.5+ además soporta bloques `import {}` declarativos, que permiten planificar el import junto con el resto de cambios en un solo `plan`/`apply`, sin ejecutar el comando `terraform import` de forma imperativa:

```hcl
# ¿QUÉ HACE?: Declara el import como parte del código, en vez de un comando manual separado
# ¿POR QUÉ?: El import queda versionado y revisable en un MR, igual que cualquier otro cambio
# ¿PARA QUÉ?: Migrar infraestructura manual a Terraform de forma auditable, un recurso a la vez
import {
  to = gitlab_project.api_pagos
  id = "142"
}

resource "gitlab_project" "api_pagos" {
  name         = "api-pagos"
  namespace_id = 42
}
```

```bash
# ¿QUÉ HACE?: Genera automáticamente el HCL a partir del recurso real, usando el bloque import de arriba
# ¿POR QUÉ?: Evita transcribir manualmente cada atributo desde `terraform state show`
# ¿PARA QUÉ?: Acelerar la migración de infraestructura manual (semanas 03-04) al proyecto Terraform del proyecto final
terraform plan -generate-config-out=generated_api_pagos.tf
```

Este flujo de `import` es exactamente el que usarás en la práctica 01 y en el proyecto de la semana: tomar lo creado a mano y traerlo bajo control de Terraform sin recrear nada desde cero.

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 17.0"
    }
  }
}

provider "gitlab" {
  base_url = "http://localhost/api/v4/"
  token    = var.gitlab_token
}

variable "gitlab_token" {
  type      = string
  sensitive = true
}

variable "webhook_url" {
  type        = string
  description = "URL del endpoint que recibe los eventos del webhook (ej. webhook.site)"
}

resource "gitlab_group" "plataforma" {
  name = "plataforma-modular"
  path = "plataforma-modular"
}

# TODO (Paso 3 del README): instanciar el módulo "gitlab-microservicio" dos veces
# module "api_pagos" {
#   source      = "./modules/gitlab-microservicio"
#   nombre      = "api-pagos"
#   group_id    = gitlab_group.plataforma.id
#   webhook_url = var.webhook_url
#   ci_variables = {
#     ENVIRONMENT = { value = "staging", protected = false, masked = false }
#   }
# }

output "api_pagos_project_id" {
  value = module.api_pagos.project_id
}

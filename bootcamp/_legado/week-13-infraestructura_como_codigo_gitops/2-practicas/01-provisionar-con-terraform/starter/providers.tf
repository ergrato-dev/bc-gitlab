# ¿QUÉ HACE?: Declara el provider de GitLab y la versión mínima de Terraform requerida
# ¿POR QUÉ?: Sin esta declaración, `terraform init` no sabe qué plugin descargar
# ¿PARA QUÉ?: Fijar un rango de versión predecible para todo el equipo
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

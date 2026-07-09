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

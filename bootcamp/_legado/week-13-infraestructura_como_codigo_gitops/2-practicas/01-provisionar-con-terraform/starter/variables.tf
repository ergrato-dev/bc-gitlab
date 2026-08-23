variable "gitlab_token" {
  description = "Personal/project access token con scope api"
  type        = string
  sensitive   = true
}

variable "grupo_nombre" {
  description = "Nombre del grupo a crear"
  type        = string
  default     = "practica-terraform"
}

variable "proyecto_nombre" {
  description = "Nombre del proyecto a crear dentro del grupo"
  type        = string
  default     = "practica-terraform-demo"
}

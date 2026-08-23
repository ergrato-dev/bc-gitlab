variable "nombre" {
  type        = string
  description = "Nombre del proyecto/microservicio"
}

variable "group_id" {
  type        = number
  description = "ID del grupo GitLab donde vive el proyecto"
}

variable "webhook_url" {
  type        = string
  description = "URL del endpoint que recibe las notificaciones del webhook"
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

# ¿QUÉ HACE?: State remoto en GitLab Managed Terraform State
# ¿POR QUÉ?: Ver teoría 01/02 — el state nunca debe vivir en local para trabajo en equipo
# ¿PARA QUÉ?: Reemplazar <ID> por el proyecto que aloja el state antes de `terraform init`
terraform {
  backend "http" {
    address        = "http://localhost/api/v4/projects/<ID>/terraform/state/proyecto-semana-13"
    lock_address   = "http://localhost/api/v4/projects/<ID>/terraform/state/proyecto-semana-13/lock"
    unlock_address = "http://localhost/api/v4/projects/<ID>/terraform/state/proyecto-semana-13/lock"
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = 5
  }
}

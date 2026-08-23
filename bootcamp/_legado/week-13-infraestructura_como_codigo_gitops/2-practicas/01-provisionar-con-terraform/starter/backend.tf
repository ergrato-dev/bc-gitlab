# ¿QUÉ HACE?: Configura el state remoto usando el backend HTTP nativo de GitLab
# ¿POR QUÉ?: El state nunca debe quedar en local para trabajo colaborativo (ver teoría 01/02)
# ¿PARA QUÉ?: Reemplazar <ID> por el ID del proyecto que aloja el state y ejecutar
#             `terraform init -backend-config=...` con las credenciales (ver README, Paso 4)
terraform {
  backend "http" {
    address        = "http://localhost/api/v4/projects/<ID>/terraform/state/practica-01"
    lock_address   = "http://localhost/api/v4/projects/<ID>/terraform/state/practica-01/lock"
    unlock_address = "http://localhost/api/v4/projects/<ID>/terraform/state/practica-01/lock"
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = 5
  }
}

# ¿QUÉ HACE?: Crea un grupo y un proyecto dentro de él
# ¿POR QUÉ?: Ejemplo mínimo para practicar el ciclo init/plan/apply del provider de GitLab
# ¿PARA QUÉ?: Punto de partida — modifica descripción/visibilidad y vuelve a aplicar para ver el diff
resource "gitlab_group" "practica" {
  name        = var.grupo_nombre
  path        = var.grupo_nombre
  description = "Grupo creado por Terraform — práctica 01"
  visibility_level = "private"
}

resource "gitlab_project" "practica" {
  name         = var.proyecto_nombre
  namespace_id = gitlab_group.practica.id
  description  = "Proyecto creado por Terraform — práctica 01"

  visibility_level = "private"
  default_branch   = "main"

  initialize_with_readme = true
}

output "project_id" {
  value = gitlab_project.practica.id
}

output "http_url_to_repo" {
  value = gitlab_project.practica.http_url_to_repo
}

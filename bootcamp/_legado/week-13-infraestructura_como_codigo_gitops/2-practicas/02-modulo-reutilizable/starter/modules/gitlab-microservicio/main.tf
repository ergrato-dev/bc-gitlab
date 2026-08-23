# ¿QUÉ HACE?: Crea el proyecto, protege main, crea las variables CI/CD recibidas
# ¿POR QUÉ?: for_each sobre var.ci_variables evita repetir un bloque resource por cada variable
# ¿PARA QUÉ?: El módulo es la unidad reutilizable — instánciarlo N veces sin duplicar HCL
resource "gitlab_project" "this" {
  name              = var.nombre
  namespace_id      = var.group_id
  visibility_level  = "private"
  default_branch    = "main"
  initialize_with_readme = true
}

resource "gitlab_branch_protection" "main" {
  project            = gitlab_project.this.id
  branch             = "main"
  push_access_level  = "no one"
  merge_access_level = "developer"
}

resource "gitlab_project_variable" "vars" {
  for_each = var.ci_variables

  project   = gitlab_project.this.id
  key       = each.key
  value     = each.value.value
  protected = each.value.protected
  masked    = each.value.masked
}

# TODO (Paso 2 del README): completar este recurso con los eventos correctos
resource "gitlab_project_hook" "notificaciones" {
  project = gitlab_project.this.id
  url     = var.webhook_url

  # push_events          = ...
  # pipeline_events      = ...
  # merge_requests_events = ...
  # enable_ssl_verification = ...
}

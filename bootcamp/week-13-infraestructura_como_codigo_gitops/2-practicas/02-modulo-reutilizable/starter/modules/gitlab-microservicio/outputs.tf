output "project_id" {
  value = gitlab_project.this.id
}

output "http_url_to_repo" {
  value = gitlab_project.this.http_url_to_repo
}

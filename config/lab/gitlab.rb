# ============================================
# gl-epti — GitLab CE Lab: Configuracion Omnibus
# ============================================
# Uso: copiar a /etc/gitlab/gitlab.rb y ejecutar:
#   gitlab-ctl reconfigure
# ============================================

# ── Acceso ──
external_url 'http://localhost'
gitlab_rails['gitlab_shell_ssh_port'] = 2224

# ── Funcionalidad completa ──
gitlab_rails['lfs_enabled'] = true
gitlab_rails['gitlab_default_can_create_group'] = true
gitlab_rails['usage_ping_enabled'] = false
gitlab_rails['sentry_enabled'] = false
gitlab_rails['snowplow_enabled'] = false
gitlab_rails['google_analytics_id'] = nil
gitlab_rails['third_party_offers_enabled'] = false
gitlab_rails['gitlab_environment'] = 'development'
gitlab_rails['backup_keep_time'] = 604800
gitlab_rails['impersonation_enabled'] = true

# ── Web server (HTTP plano, lab local) ──
nginx['listen_port'] = 80
nginx['listen_https'] = false
nginx['client_max_body_size'] = '256m'

# ── DB optimizada para lab (recursos contenidos) ──
postgresql['shared_buffers'] = '256MB'
postgresql['max_worker_processes'] = 2
postgresql['work_mem'] = '8MB'

# ── Redis ──
redis['maxmemory'] = '128mb'
redis['maxmemory_policy'] = 'allkeys-lru'

# ── Sidekiq (reducir concurrencia para lab) ──
sidekiq['max_concurrency'] = 10

# ── Prometheus local (sin envio externo) ──
prometheus_monitoring['enable'] = true
node_exporter['enable'] = true
gitlab_exporter['enable'] = true
redis_exporter['enable'] = true
postgres_exporter['enable'] = true

# ── Puma (web server interno) ──
puma['worker_processes'] = 2
puma['min_threads'] = 1
puma['max_threads'] = 4

# ── Container Registry (integrado) ──
registry_external_url 'http://localhost:5050'
registry['enable'] = true

# ── Pages (hosting estatico) ──
gitlab_pages['enable'] = true
pages_external_url 'http://localhost:8090'

# ── Mail (deshabilitado en lab) ──
gitlab_rails['gitlab_email_enabled'] = false

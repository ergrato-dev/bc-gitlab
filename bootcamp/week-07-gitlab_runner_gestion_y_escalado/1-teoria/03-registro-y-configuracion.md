# 03 — Registro y Configuracion

## Instalacion

### Linux (repositorio oficial)
```bash
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
sudo apt-get install gitlab-runner
```

### Docker
```bash
docker run -d --name gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /srv/gitlab-runner/config:/etc/gitlab-runner \
  gitlab/gitlab-runner:latest
```

## Registro

```bash
sudo gitlab-runner register
```

El proceso interactivo pregunta:
1. URL de la instancia GitLab: `https://gitlab.example.com`
2. Registration token (de Settings → CI/CD → Runners)
3. Descripcion del runner: `docker-runner-prod`
4. Tags: `docker, linux, production`
5. Executor: `docker`
6. Imagen por defecto: `alpine:latest`

## Archivo config.toml

Ubicacion por defecto: `/etc/gitlab-runner/config.toml`

```toml
concurrent = 4
check_interval = 0
log_level = "info"

[session_server]
  session_timeout = 1800

[[runners]]
  name = "docker-runner-prod"
  url = "https://gitlab.example.com"
  token = "glrt-xxxxxxxxxxxxxxxxxxxx"
  executor = "docker"
  [runners.docker]
    tls_verify = false
    image = "alpine:latest"
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/cache"]
    shm_size = 0
    network_mode = "bridge"
```

### Parametros globales importantes
- `concurrent`: Maximo de jobs simultaneos en este runner
- `check_interval`: Segundos entre chequeos de nuevos jobs
- `log_level`: debug, info, warn, error

### Comandos utiles
```bash
gitlab-runner list          # Listar runners configurados
gitlab-runner verify        # Verificar estado
gitlab-runner restart       # Reiniciar runner
gitlab-runner unregister    # Dar de baja un runner
gitlab-runner status        # Ver si el servicio esta corriendo
```

# Stack Tecnologico — Versiones Oficiales

## Versiones del Stack

| Tecnologia | Version | Notas |
|-----------|---------|-------|
| GitLab CE | **17.x (latest)** | Omnibus package o Docker image |
| Docker | **27.5+** | Container runtime |
| Docker Compose | **2.32+** | Orquestacion local |
| GitLab Runner | **17.x (latest)** | Misma version que GitLab CE |
| Git | **2.46+** | Control de versiones |
| Ubuntu Server | **24.04 LTS** | SO produccion |
| PostgreSQL | **16.3+** | Backend DB (incluido en Omnibus) |
| Redis | **7.2+** | Cache y colas (incluido en Omnibus) |
| Nginx | **1.26+** | Reverse proxy (incluido en Omnibus) |
| Python | **3.12+** | Scripts de automatizacion |
| Minikube | **latest** | Kubernetes local |
| kubectl | **1.32+** | CLI de Kubernetes |
| Helm | **3.16+** | Gestor de paquetes K8s |
| Prometheus | **2.54+** | Monitoreo (integrado en GitLab) |
| Grafana | **10.4+** | Dashboards |
| yamllint | **1.35+** | Linting de YAML |
| hadolint | **2.12+** | Linting de Dockerfiles |
| jq | **1.7+** | Procesamiento JSON |

## Politica de Versiones

- Usar **version exacta** o **latest stable** para herramientas principales
- GitLab CE: siempre la ultima version estable del major 17
- GitLab Runner: misma version que GitLab CE
- Docker: latest stable

## Docker Images Base

```yaml
# Imagenes usadas en el bootcamp
services:
  gitlab:
    image: gitlab/gitlab-ce:17-latest
  gitlab-runner:
    image: gitlab/gitlab-runner:alpine-latest
  postgres:
    image: postgres:16-alpine
  redis:
    image: redis:7-alpine
```

## Plantilla docker-compose.yml Base

```yaml
version: '3.8'

services:
  gitlab:
    image: gitlab/gitlab-ce:17-latest
    container_name: gitlab
    restart: always
    hostname: gitlab.local
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://gitlab.local'
        gitlab_rails['gitlab_shell_ssh_port'] = 2224
    ports:
      - "80:80"
      - "443:443"
      - "2224:22"
    volumes:
      - gitlab-config:/etc/gitlab
      - gitlab-logs:/var/log/gitlab
      - gitlab-data:/var/opt/gitlab
    shm_size: '256m'

  gitlab-runner:
    image: gitlab/gitlab-runner:alpine-latest
    container_name: gitlab-runner
    restart: always
    depends_on:
      - gitlab
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - runner-config:/etc/gitlab-runner

volumes:
  gitlab-config:
  gitlab-logs:
  gitlab-data:
  runner-config:
```

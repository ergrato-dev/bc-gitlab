# 02 — Docker Compose para Producción

El `docker-compose.yml` del proyecto final debe ser más robusto que el usado en semanas anteriores. Aquí cubrimos optimizaciones para un entorno pseudo-producción.

## Estructura recomendada

```yaml
version: '3.8'

services:
  gitlab:
    image: gitlab/gitlab-ce:${GITLAB_VERSION:-16.11.0-ce.0}
    container_name: gitlab
    restart: unless-stopped
    hostname: ${GITLAB_HOSTNAME:-gitlab.local}
    ports:
      - "${HTTP_PORT:-80}:80"
      - "${HTTPS_PORT:-443}:443"
      - "${SSH_PORT:-2222}:22"
    volumes:
      - gitlab-config:/etc/gitlab
      - gitlab-logs:/var/log/gitlab
      - gitlab-data:/var/opt/gitlab
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url '${GITLAB_EXTERNAL_URL:-https://gitlab.local}'
        nginx['listen_port'] = 80
        nginx['listen_https'] = false
        registry_external_url '${REGISTRY_URL:-https://registry.local}'
        gitlab_rails['registry_enabled'] = true
        gitlab_rails['smtp_enable'] = false
        prometheus_monitoring['enable'] = true
        grafana['enable'] = false
    networks:
      - gitlab-net
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/-/health"]
      interval: 30s
      timeout: 10s
      retries: 5

  gitlab-runner:
    image: gitlab/gitlab-runner:alpine
    container_name: gitlab-runner
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - runner-config:/etc/gitlab-runner
    networks:
      - gitlab-net
    depends_on:
      gitlab:
        condition: service_healthy

volumes:
  gitlab-config:
  gitlab-logs:
  gitlab-data:
  runner-config:

networks:
  gitlab-net:
    driver: bridge
```

## Puntos clave

**Variables de entorno**: Usar `${VAR:-default}` para valores por defecto. Crear `.env.example` con todas las variables documentadas. Nunca commitear `.env` con valores reales.

**Healthchecks**: Esenciales para que Docker Compose sepa cuándo un servicio está realmente listo. Sin healthchecks, `depends_on` solo espera que el contenedor arranque, no que el servicio responda.

**Volúmenes nombrados**: Usar volúmenes de Docker en lugar de bind mounts (`./data:/var/opt/gitlab`). Son más portables y Docker los gestiona mejor. Para backups, mapear a un directorio host.

**Redes**: Crear una red bridge dedicada para comunicación interna. Si necesitas Prometheus + Grafana, agrégalos a la misma red para que puedan escrapear métricas de GitLab.

**Persistencia**: Identificar qué directorios contienen datos que deben sobrevivir a recreaciones de contenedores: `/etc/gitlab` (configuración), `/var/log/gitlab` (logs), `/var/opt/gitlab` (datos: repos, DB, uploads).

**Límites de recursos**: En producción real se debe limitar CPU y memoria:
```yaml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 8G
    reservations:
      cpus: '2'
      memory: 4G
```

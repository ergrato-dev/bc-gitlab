# Setup con Docker Compose

> **Todo el bootcamp corre sobre Docker.** No necesitas instalar GitLab, Ruby, PostgreSQL, Redis ni Nginx en tu sistema. Solo Docker y Docker Compose.

## Paso 1: Instalar Docker

Sigue [docker-setup.md](../docker-setup.md) para instalar Docker en tu sistema.

Verifica la instalacion:

```bash
docker --version        # 27+
docker compose version  # 2.32+
```

## Paso 2: Clonar y configurar

```bash
git clone https://github.com/ergrato-dev/bc-gitlab.git
cd bc-gitlab
cp .env.example .env
```

Revisa `.env` y ajusta si es necesario (puertos, contrasenas).

## Paso 3: Levantar GitLab CE

```bash
# Iniciar GitLab CE + Runner + Registry cache
docker compose up -d
```

El primer inicio tarda **~5 minutos**. Monitorea el progreso:

```bash
docker compose logs -f gitlab
# Esperar hasta ver: "GitLab is ready" o estado "healthy"
```

## Paso 4: Obtener contrasena root

```bash
docker compose exec gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

## Paso 5: Acceder a GitLab

1. Abrir `http://localhost` en el navegador
2. Iniciar sesion con usuario `root` y la contrasena obtenida
3. **Cambiar la contrasena inmediatamente** (Avatar → Preferences → Password)

## Paso 6: Registrar un Runner

```bash
# 1. Obtener token desde la UI:
#    Admin Area → CI/CD → Runners → New instance runner
# 2. Copiar el token de registro
# 3. Registrar el runner:

docker compose exec gitlab-runner gitlab-runner register \
  --non-interactive \
  --url http://gitlab \
  --registration-token "TU_TOKEN" \
  --executor docker \
  --docker-image alpine:latest \
  --docker-volumes /var/run/docker.sock:/var/run/docker.sock \
  --description "docker-runner"
```

## Paso 7 (opcional): Levantar monitoreo

```bash
docker compose --profile monitoring up -d
# Prometheus: http://localhost:9090
# Grafana:     http://localhost:3000 (admin/admin)
```

## Comandos Utiles

```bash
# Estado de todos los servicios
docker compose ps
docker compose --profile monitoring ps

# Estado de GitLab (dentro del contenedor)
docker compose exec gitlab gitlab-ctl status

# Reiniciar GitLab
docker compose exec gitlab gitlab-ctl restart

# Backup de GitLab
docker compose exec gitlab gitlab-backup create

# Shell en el contenedor
docker compose exec gitlab bash

# Logs de un servicio
docker compose logs -f gitlab-runner

# Destruir todo (PERDIDA TOTAL DE DATOS)
docker compose down -v

# Consola Rails (avanzado)
docker compose exec gitlab gitlab-rails console
```

## Servicios y URLs

| Servicio | URL | Puerto | Profile |
|----------|-----|--------|---------|
| GitLab CE | `http://localhost` | 80 | default |
| GitLab SSH | `ssh://git@localhost` | 2224 | default |
| Registry Cache | `http://localhost:5000` | 5000 | default |
| Prometheus | `http://localhost:9090` | 9090 | monitoring |
| Grafana | `http://localhost:3000` | 3000 | monitoring |


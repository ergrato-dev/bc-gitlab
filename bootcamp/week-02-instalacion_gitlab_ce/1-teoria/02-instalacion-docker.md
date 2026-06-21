# 02 — Instalacion de GitLab CE con Docker Compose

## Objetivos

- Crear un archivo `docker-compose.yml` funcional para GitLab CE
- Configurar variables de entorno esenciales
- Configurar persistencia de datos con volumenes
- Levantar y verificar la instancia

## Archivo docker-compose.yml

Crea un archivo `docker-compose.yml` en un directorio dedicado:

```yaml
version: '3.8'

services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab-ce
    hostname: gitlab.local
    restart: always
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://gitlab.local'
        gitlab_rails['gitlab_shell_ssh_port'] = 2224
        gitlab_rails['initial_root_password'] = 'ChangeMe123!'
    ports:
      - "80:80"
      - "443:443"
      - "2224:22"
    volumes:
      - gitlab-config:/etc/gitlab
      - gitlab-logs:/var/log/gitlab
      - gitlab-data:/var/opt/gitlab
    shm_size: '256m'

volumes:
  gitlab-config:
  gitlab-logs:
  gitlab-data:
```

## Explicacion de la Configuracion

### Puertos
- **80**: HTTP (interfaz web)
- **443**: HTTPS (cuando se configure SSL)
- **2224**: SSH (mapeado a un puerto no estandar para no conflictuar con SSH del host)

### Variables de Entorno
- `GITLAB_OMNIBUS_CONFIG`: Permite inyectar configuracion directamente en `/etc/gitlab/gitlab.rb`
- `external_url`: La URL donde GitLab sera accesible
- `gitlab_rails['gitlab_shell_ssh_port']`: Puerto SSH que se mostrara en la UI para clonar

### Volumenes
- `gitlab-config`: Configuracion de GitLab (`/etc/gitlab`)
- `gitlab-logs`: Logs (`/var/log/gitlab`)
- `gitlab-data`: Datos de la aplicacion, repositorios, base de datos (`/var/opt/gitlab`)

### shm_size
Necesario para Sidekiq y servicios internos. 256 MB es el minimo recomendado.

## Levantar la Instancia

```bash
# Iniciar GitLab CE
docker compose up -d

# Ver logs en tiempo real
docker compose logs -f gitlab

# Verificar estado de salud
docker compose ps
```

El primer inicio puede tomar **5-10 minutos** mientras GitLab ejecuta la configuracion inicial, migra la base de datos y compila assets.

## Verificar que esta Funcionando

```bash
# Verificar que responde HTTP
curl -I http://localhost

# Acceder via navegador
open http://localhost
```

## Obtener la Contrasena Root Inicial

```bash
docker compose exec gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

Este archivo se elimina automaticamente despues de 24 horas por seguridad. Cambia la contrasena inmediatamente despues del primer inicio de sesion.

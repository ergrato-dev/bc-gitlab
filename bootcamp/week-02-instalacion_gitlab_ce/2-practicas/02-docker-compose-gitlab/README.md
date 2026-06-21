# Practica 02 — Levantar GitLab CE con Docker Compose

## Objetivo
Crear el archivo docker-compose.yml, levantar GitLab CE y verificar su funcionamiento.

## Instrucciones

### 1. Crear docker-compose.yml

```bash
cd ~/gitlab-bootcamp/gitlab-instance

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab-ce
    hostname: gitlab.local
    restart: always
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://localhost'
        gitlab_rails['gitlab_shell_ssh_port'] = 2224
    ports:
      - "80:80"
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
EOF
```

### 2. Levantar GitLab CE

```bash
docker compose up -d
```

### 3. Monitorear el inicio

```bash
# Ver logs en tiempo real
docker compose logs -f gitlab
```

Espera hasta ver mensajes como "GitLab is ready" o el servicio responda (5-10 minutos).

### 4. Verificar que responde

```bash
# Verificar HTTP
curl -s -o /dev/null -w "%{http_code}" http://localhost

# Acceder via navegador
# Abrir http://localhost
```

### 5. Obtener contrasena root

```bash
docker compose exec gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

Guarda esta contrasena en un lugar seguro.

## Entregable
- Captura de `docker compose ps` mostrando gitlab-ce en estado "healthy" o "running"
- Captura de la pagina de login de GitLab en el navegador

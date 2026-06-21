# Configuracion de Docker para el Bootcamp

> **Docker es la plataforma central del bootcamp.** GitLab CE, Runner, Registry y monitoreo corren en contenedores. No se instala nada en el sistema host.

## Verificar instalacion existente

```bash
docker --version      # Debe ser 27+
docker compose version # Debe ser 2.32+
```

## Instalacion de Docker

### Fedora 43+

```bash
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker
```

### Ubuntu 24.04

```bash
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
newgrp docker
```

## Recursos Minimos para GitLab CE

```bash
# Ajustar memoria swap si es necesario (minimo 4 GB RAM total)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## Comandos Esenciales

```bash
# Construir y levantar GitLab (primer inicio ~5 min)
docker compose up -d

# Ver logs de GitLab en tiempo real
docker compose logs -f gitlab

# Verificar estado de todos los servicios
docker compose ps

# Verificar que GitLab ya esta listo
docker compose exec gitlab gitlab-ctl status

# Obtener password inicial de root
docker compose exec gitlab grep 'Password:' /etc/gitlab/initial_root_password

# Shell dentro del contenedor
docker compose exec gitlab bash

# Detener servicios (mantiene datos)
docker compose down

# Destruir todo (volumenes incluidos — borra TODOS los datos)
docker compose down -v

# Levantar con monitoreo (Prometheus + Grafana)
docker compose --profile monitoring up -d

# Ver solo los servicios de monitoreo
docker compose --profile monitoring ps
```

## Verificacion

```bash
# GitLab debe responder en http://localhost
curl -I http://localhost

# Acceder a la UI
# Abrir http://localhost en navegador
# Usuario: root
# Contrasena: (del comando grep anterior)
```

## Servicios Disponibles

| Servicio | URL | Puerto |
|----------|-----|--------|
| GitLab CE | `http://localhost` | 80 |
| GitLab SSH | `ssh://git@localhost` | 2224 |
| Registry Cache | `localhost:5000` | 5000 |
| Prometheus | `http://localhost:9090` | 9090 (profile: monitoring) |
| Grafana | `http://localhost:3000` | 3000 (profile: monitoring) |

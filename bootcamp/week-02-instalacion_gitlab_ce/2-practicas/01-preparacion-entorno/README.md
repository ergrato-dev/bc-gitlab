# Practica 01 — Preparacion del Entorno

## Objetivo
Verificar que el sistema cumple los requisitos y preparar el entorno para la instalacion de GitLab CE con Docker.

## Instrucciones

### 1. Verificar Docker y Docker Compose

```bash
docker --version
docker compose version
```

Si no estan instalados:
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install docker.io docker-compose-v2
sudo usermod -aG docker $USER
# Cerrar y reabrir sesion
```

### 2. Verificar recursos disponibles

```bash
# RAM
free -h

# Espacio en disco
df -h

# CPU
lscpu | grep "Model name"
```

### 3. Crear directorio de trabajo

```bash
mkdir -p ~/gitlab-bootcamp/gitlab-instance
cd ~/gitlab-bootcamp/gitlab-instance
```

### 4. Configurar Git SSH (si no se hizo en Semana 01)

```bash
ssh-keygen -t ed25519 -C "bootcamp@gitlab.local"
cat ~/.ssh/id_ed25519.pub
```

## Entregable
- Salida de `docker --version && docker compose version`
- Salida de `free -h` mostrando al menos 8 GB
- Salida de `df -h /` mostrando al menos 20 GB libres

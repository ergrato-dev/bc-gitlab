# 🛠️ Práctica 01 — Preparación del Entorno

⏱️ **Tiempo estimado:** 30 minutos  
⭐ **Dificultad:** Básico  
📋 **Prerrequisitos:** Computadora con acceso a terminal, conexión a internet

---

## 🎯 Objetivo

Verificar que tu sistema cumple todos los requisitos para ejecutar GitLab CE con Docker Compose, y clonar el repositorio del bootcamp listo para usar.

---

## Paso 1: Verificar Docker Engine

```bash
# ¿QUÉ HACE?: Muestra la versión de Docker instalada
# ¿POR QUÉ?: Necesitamos Docker 27+ para las características de Compose V2
# ¿PARA QUÉ?: Confirmar que Docker está instalado y es la versión correcta
docker --version
```

✅ **Output esperado:**
```
Docker version 27.x.x, build xxxxxxx
```

Si la versión es menor a 20.0 o el comando no existe, instala Docker Engine siguiendo [docs.docker.com/engine/install](https://docs.docker.com/engine/install/).

---

## Paso 2: Verificar Docker Compose V2

```bash
# ¿QUÉ HACE?: Muestra la versión del plugin Docker Compose
# ¿POR QUÉ?: El bootcamp usa Docker Compose V2 (sin guion: `docker compose`)
# ¿PARA QUÉ?: Confirmar que el plugin está disponible y es la versión recomendada
docker compose version
```

✅ **Output esperado:**
```
Docker Compose version v2.32.x
```

⚠️ Si ves `docker-compose version` (con guion) es la versión V1 (deprecada). El bootcamp usa `docker compose` (sin guion, plugin V2). En Ubuntu 22.04+:

```bash
# ¿QUÉ HACE?: Instala el plugin oficial de Compose V2
# ¿POR QUÉ?: docker-compose-v2 es el paquete del plugin integrado a Docker CLI
# ¿PARA QUÉ?: Poder usar 'docker compose' (sin guion) con las características modernas
sudo apt update && sudo apt install docker-compose-plugin
```

---

## Paso 3: Verificar que tu usuario puede ejecutar Docker sin sudo

```bash
# ¿QUÉ HACE?: Lista los contenedores activos sin privilegios de root
# ¿POR QUÉ?: Ejecutar Docker con sudo constantemente es inseguro y molesto
# ¿PARA QUÉ?: Confirmar que tu usuario pertenece al grupo 'docker'
docker ps
```

✅ **Output esperado:** Una tabla vacía o contenedores existentes (sin error de permisos).

Si ves `permission denied while trying to connect to the Docker daemon socket`:

```bash
# ¿QUÉ HACE?: Agrega tu usuario al grupo 'docker' del sistema
# ¿POR QUÉ?: El socket de Docker solo es accesible por el grupo 'docker' por defecto
# ¿PARA QUÉ?: Poder ejecutar docker sin sudo en cada comando
sudo usermod -aG docker $USER

# Aplica el cambio de grupo en la sesión actual (o cierra y vuelve a abrir sesión)
newgrp docker
```

---

## Paso 4: Verificar recursos del sistema

### RAM disponible

```bash
# ¿QUÉ HACE?: Muestra la memoria RAM total y disponible del sistema
# ¿POR QUÉ?: GitLab CE requiere mínimo 4 GB libres, recomendado 8 GB
# ¿PARA QUÉ?: Detectar antes si el sistema no tiene suficiente RAM
free -h
```

✅ **Output esperado (mínimo viable):**
```
               total        used        free
Mem:            15Gi        4.2Gi       9.8Gi
Swap:          2.0Gi        0Mi         2.0Gi
```

Necesitas al menos **4 GB libres**. Con 8 GB libres tendrás una experiencia fluida.

### Espacio en disco

```bash
# ¿QUÉ HACE?: Muestra el uso del disco en todas las particiones
# ¿POR QUÉ?: GitLab necesita mínimo 10 GB, recomendado 20 GB
# ¿PARA QUÉ?: Evitar que GitLab falle a mitad de una operación por disco lleno
df -h
```

✅ **Output esperado en la partición principal:**
```
Filesystem      Size   Used  Avail Use%
/dev/sda1       100G    40G    60G  40%    ← Avail debe ser ≥ 20 GB
```

### CPU disponible

```bash
# ¿QUÉ HACE?: Muestra el número de núcleos y el modelo del procesador
# ¿POR QUÉ?: GitLab rinde mejor con 4+ cores; con 2 cores funciona pero lento
# ¿PARA QUÉ?: Confirmar que el hardware es suficiente para el bootcamp
nproc && lscpu | grep "Model name"
```

✅ **Output esperado:** `4` o más (número de cores) + el nombre del procesador.

---

## Paso 5: Verificar que los puertos necesarios están libres

```bash
# ¿QUÉ HACE?: Lista los puertos TCP que están siendo usados activamente
# ¿POR QUÉ?: Si los puertos 80, 443 o 2224 están ocupados, GitLab no puede arrancar
# ¿PARA QUÉ?: Detectar conflictos antes de intentar levantar los contenedores
ss -tuln | grep -E ':80 |:443 |:2224 '
```

✅ **Output esperado:** Sin ninguna línea de salida (los puertos están libres).

Si algún puerto aparece en uso:

| Puerto ocupado | Causa probable | Solución |
|---------------|----------------|----------|
| `:80` | Apache/Nginx corriendo en el host | `sudo systemctl stop apache2` o `sudo systemctl stop nginx` |
| `:443` | Apache/Nginx con SSL | Igual que arriba |
| `:2224` | Otro servicio SSH customizado | Cambiar `GITLAB_SSH_PORT=2225` en `.env` |

---

## Paso 6: Clonar el repositorio del bootcamp

```bash
# ¿QUÉ HACE?: Descarga el repositorio completo del bootcamp a tu máquina
# ¿POR QUÉ?: El repo incluye el docker-compose.yml, scripts y material de prácticas
# ¿PARA QUÉ?: Tener todo el entorno listo con un solo clone
git clone https://github.com/ergrato-dev/bc-gitlab.git
cd bc-gitlab
```

---

## Paso 7: Configurar el archivo .env

```bash
# ¿QUÉ HACE?: Crea tu archivo de configuración local copiando el ejemplo
# ¿POR QUÉ?: .env no está en git (tiene contraseñas), pero .env.example sí
# ¿PARA QUÉ?: Personalizar puertos, contraseñas y versiones de imágenes
cp .env.example .env
```

Revisa y edita las variables principales:

```bash
# Abre .env con tu editor preferido
nano .env  # o vim, code, gedit, etc.
```

Variables que **debes** revisar:

```bash
GITLAB_ROOT_PASSWORD=ChangeMe123!    # ← Cámbiala por algo seguro
GITLAB_EXTERNAL_URL=http://localhost  # ← Mantener así para desarrollo local
GITLAB_SSH_PORT=2224                  # ← Cambiar si 2224 está ocupado
GITLAB_HTTP_PORT=80                   # ← Cambiar si 80 está ocupado
```

---

## ✅ Verificación final: todo listo para el siguiente paso

Ejecuta este resumen de verificación:

```bash
# ¿QUÉ HACE?: Ejecuta todas las verificaciones en secuencia y muestra el resultado
# ¿POR QUÉ?: Ahorra tiempo verificando todo de una sola vez
# ¿PARA QUÉ?: Tener un registro claro del estado del sistema antes de empezar
echo "=== VERIFICACIÓN DE ENTORNO BOOTCAMP GITLAB ==="
echo ""
echo "Docker Engine:"
docker --version
echo ""
echo "Docker Compose:"
docker compose version
echo ""
echo "RAM disponible:"
free -h | grep Mem
echo ""
echo "Disco disponible:"
df -h / | tail -1
echo ""
echo "CPU cores:"
nproc
echo ""
echo "Puertos libres:"
ss -tuln | grep -E ':80 |:443 |:2224 ' && echo "⚠️ PUERTOS OCUPADOS" || echo "✅ Puertos 80, 443, 2224 libres"
echo ""
echo "Repositorio clonado:"
ls docker-compose.yml .env.example 2>/dev/null && echo "✅ Archivos presentes" || echo "❌ Faltan archivos"
```

---

## 🚨 Troubleshooting

| Error | Causa probable | Solución |
|-------|---------------|----------|
| `docker: command not found` | Docker no instalado | Instalar desde docs.docker.com/engine/install |
| `docker compose: 'compose' is not a docker command` | Plugin V2 no instalado | `sudo apt install docker-compose-plugin` |
| `permission denied /var/run/docker.sock` | Usuario no en grupo docker | `sudo usermod -aG docker $USER && newgrp docker` |
| `free -h` muestra < 4 GB disponibles | RAM insuficiente | Cerrar otras aplicaciones o agregar swap |
| Puerto 80 ocupado | Servicio web en el host | Detener Apache/Nginx del host |
| `git clone` falla | Sin conexión / firewall | Verificar conexión; intentar HTTPS en lugar de SSH |
| `.env.example` no existe | Repo incompleto o rama incorrecta | `git checkout main && git pull` |

---

## 📝 Entregable

Copia y pega el output de los siguientes comandos en tu documento de entregable:

```bash
docker --version && docker compose version
free -h
df -h / | tail -1
nproc
ss -tuln | grep -E ':80 |:443 |:2224 ' || echo "Puertos libres"
```

---

➡️ **Siguiente práctica:** [02 — Levantar GitLab CE con Docker Compose](../02-docker-compose-gitlab/README.md)

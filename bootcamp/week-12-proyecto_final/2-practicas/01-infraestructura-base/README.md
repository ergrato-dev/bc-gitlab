# Práctica 01 — Infraestructura Base

## Objetivo

Levantar la infraestructura base de la plataforma DevOps con Docker Compose.

## Instrucciones

### Paso 1: Crear estructura del proyecto

```bash
mkdir -p proyecto-final/{ci-templates,monitoring,backup,docs}
cd proyecto-final
touch .env.example .gitlab-ci.yml README.md
```

### Paso 2: Escribir docker-compose.yml

Crea el archivo con al menos 3 servicios: GitLab CE, GitLab Runner y una definición de red interna. Usa la plantilla de teoría 02 como guía pero personalízala para tu entorno (puertos, hostname, versión).

### Paso 3: Crear .env.example

```bash
GITLAB_VERSION=16.11.0-ce.0
GITLAB_HOSTNAME=gitlab.local
GITLAB_EXTERNAL_URL=http://gitlab.local
HTTP_PORT=80
SSH_PORT=2222
REGISTRY_URL=http://registry.local
```

### Paso 4: Levantar la infraestructura

```bash
docker-compose --env-file .env up -d
docker-compose ps     # Verificar que todos los servicios estén UP
docker-compose logs gitlab  # Revisar logs por si hay errores
```

### Paso 5: Verificar acceso

1. Accede a GitLab en `http://localhost` (o el puerto configurado)
2. Obtén la contraseña inicial de root:
   ```bash
   docker-compose exec gitlab cat /etc/gitlab/initial_root_password
   ```
3. Inicia sesión y cambia la contraseña de root
4. Deshabilita el registro público (Sign-up) desde Admin Area

### Paso 6: Registrar el Runner

```bash
docker-compose exec gitlab-runner gitlab-runner register \
  --non-interactive \
  --url "http://gitlab" \
  --registration-token "TOKEN_DEL_RUNNER" \
  --executor "docker" \
  --docker-image "docker:24" \
  --docker-network-mode "gitlab-net" \
  --description "docker-runner"
```

Obtén el token de registro en Admin Area → Overview → Runners.

### Verificación

- [ ] `docker-compose ps` muestra todos los servicios healthy
- [ ] Inicio de sesión en GitLab funciona
- [ ] Runner aparece como "online" en Admin Area → Runners
- [ ] Container Registry accesible en el puerto configurado

## Preguntas de reflexión
- ¿Por qué usaste redes internas de Docker en lugar de exponer todos los puertos?
- ¿Qué ventajas tiene usar `.env.example` en lugar de hardcodear valores?
- ¿Qué sucede si el contenedor de GitLab se reinicia? ¿Se pierden los datos?

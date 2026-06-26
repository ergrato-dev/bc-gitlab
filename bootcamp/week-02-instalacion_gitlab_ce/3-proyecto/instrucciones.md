# 📋 Instrucciones del Proyecto — Semana 02

Este documento describe los 6 pasos detallados para completar el proyecto integrador de la semana. Úsalo junto con el [README.md del proyecto](./README.md) y las prácticas individuales.

---

## Fase 1: Preparar el entorno

### 1.1 Verificar requisitos mínimos

```bash
# Ejecutar el chequeo completo de requisitos
docker --version         # Debe ser 20+ (recomendado 27+)
docker compose version   # Debe ser V2 (v2.x.x)
free -h                  # Necesitas ≥ 4 GB libres (recomendado 8 GB)
df -h /                  # Necesitas ≥ 20 GB libres
nproc                    # Necesitas ≥ 2 cores (recomendado 4)
ss -tuln | grep -E ':80 |:443 |:2224 ' || echo "Puertos libres"
```

Si algún requisito no se cumple, revisa [Práctica 01](../2-practicas/01-preparacion-entorno/README.md) para las instrucciones de instalación.

### 1.2 Clonar el repositorio

```bash
git clone https://github.com/ergrato-dev/bc-gitlab.git
cd bc-gitlab
```

### 1.3 Configurar .env

```bash
cp .env.example .env
# Editar .env y cambiar GITLAB_ROOT_PASSWORD por algo seguro
nano .env
```

**Variables obligatorias:**
- `GITLAB_ROOT_PASSWORD` — Contraseña del administrador root
- `GITLAB_EXTERNAL_URL` — Mantener como `http://localhost`
- `GITLAB_SSH_PORT` — Mantener como `2224` (o cambiar si está ocupado)

---

## Fase 2: Levantar GitLab CE

### 2.1 Iniciar los servicios

```bash
# Desde la raíz del repositorio
docker compose up -d
```

### 2.2 Monitorear el primer inicio

```bash
docker compose logs -f gitlab
```

Espera hasta ver `gitlab Reconfigured!` en los logs. Esto indica que GitLab terminó de configurarse. Presiona `Ctrl+C` para dejar de seguir los logs.

### 2.3 Esperar el healthcheck

```bash
# Ejecutar periódicamente hasta ver "(healthy)"
docker compose ps
```

El healthcheck verifica `http://localhost/-/health` cada 60 segundos, con hasta 10 reintentos y un período de gracia de 5 minutos. El tiempo total máximo de espera es ~15 minutos.

**Estados posibles:**
- `(health: starting)` — GitLab aún iniciando. Esperar.
- `(healthy)` — ✅ GitLab listo para usar.
- `(unhealthy)` — Hay un problema. Ver logs.

### 2.4 Verificar acceso

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost
```

Output esperado: `HTTP 302` o `HTTP 200`.

---

## Fase 3: Configuración inicial

### 3.1 Obtener contraseña root

```bash
docker compose exec gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

Guarda esta contraseña. Tienes 24 horas antes de que el archivo se elimine automáticamente.

### 3.2 Cambiar contraseña de root en la UI

1. Ve a `http://localhost`
2. Inicia sesión con `root` y la contraseña obtenida
3. Avatar (esquina superior derecha) → **Edit profile** → **Password**
4. Cambia la contraseña por una nueva y segura
5. Confirma el cambio e inicia sesión de nuevo

### 3.3 Configurar la apariencia

1. Menú lateral → ícono de escudo → **Admin Area**
2. **Settings** → **Appearance**
3. Configura **Title**, **Description** y **Sign-in page description**
4. **Save changes**

### 3.4 Deshabilitar registro público

1. **Admin Area** → **Settings** → **General**
2. Expandir **Sign-up restrictions**
3. Desmarcar **Sign-up enabled**
4. **Save changes**

### 3.5 Crear usuario de trabajo

1. **Admin Area** → **Overview** → **Users** → **New user**
2. Completa nombre, username y email
3. Haz clic en **Create user**
4. Edita el usuario y establece una contraseña en la sección **Password**

### 3.6 Verificar que el usuario puede iniciar sesión

Abre una ventana de incógnito, ve a `http://localhost` e inicia sesión con el nuevo usuario. Confirma que el acceso funciona.

---

## Fase 4: Verificar el funcionamiento

### 4.1 Sanity check oficial

```bash
docker compose exec gitlab gitlab-rake gitlab:check SANITIZE=true
```

Todos los checks deben pasar en verde. Si hay algún error en rojo (no warning), revisa [Solución de problemas](../1-teoria/05-solucion-problemas.md).

### 4.2 Estado de servicios internos

```bash
docker compose exec gitlab gitlab-ctl status
```

Todos los servicios deben mostrar `run:`. Algunos que pueden tardar más: `gitlab-monitor`, `grafana` (si no usas el profile monitoring).

### 4.3 Crear proyecto de prueba

Como tu usuario de trabajo (no root):

1. Dashboard → **New project** → **Create blank project**
2. Nombre: `hello-gitlab`
3. Visibility: Private
4. Inicializar repositorio: ✅
5. **Create project**

Agrega al menos 2 archivos con commits:
- `README.md` con descripción del proyecto
- `pre-backup-marker.txt` con fecha y hora para verificar el restore

---

## Fase 5: Primer backup

### 5.1 Crear el backup

```bash
docker compose exec gitlab gitlab-backup create STRATEGY=copy
```

Copia el nombre del archivo generado (el timestamp al inicio).

### 5.2 Respaldar archivos críticos

```bash
# Secrets — el más importante
mkdir -p ~/gitlab-backups
docker compose exec gitlab cat /etc/gitlab/gitlab-secrets.json \
  > ~/gitlab-backups/gitlab-secrets-$(date +%Y%m%d).json

# Configuración
docker compose cp gitlab:/etc/gitlab/gitlab.rb \
  ~/gitlab-backups/gitlab.rb.backup-$(date +%Y%m%d)
```

### 5.3 Copiar backup al host

```bash
docker compose cp gitlab:/var/opt/gitlab/backups/. ~/gitlab-backups/
ls -lh ~/gitlab-backups/
```

### 5.4 Verificar el restore (flujo completo)

```bash
# a) Detener servicios de escritura
docker compose exec gitlab gitlab-ctl stop puma
docker compose exec gitlab gitlab-ctl stop sidekiq

# b) Restaurar (reemplaza TIMESTAMP con el valor real)
docker compose exec gitlab gitlab-backup restore BACKUP=TIMESTAMP_2025_XX_XX_17.X.X

# c) Reconfigurar y reiniciar
docker compose exec gitlab gitlab-ctl reconfigure
docker compose exec gitlab gitlab-ctl restart

# d) Verificar
docker compose exec gitlab gitlab-rake gitlab:check SANITIZE=true
```

### 5.5 Confirmar que el restore funcionó

Ve a `http://localhost`, inicia sesión como tu usuario de trabajo y verifica que el archivo `pre-backup-marker.txt` sigue en el proyecto `hello-gitlab`.

---

## Fase 6: Documentar en INSTALL.md

Crea el archivo `INSTALL.md` en el proyecto `hello-gitlab` desde la UI de GitLab. El archivo debe seguir esta estructura:

```markdown
# Instalación de GitLab CE — Bootcamp Week 02

## Información del sistema

| Campo | Valor |
|-------|-------|
| **Fecha de instalación** | YYYY-MM-DD |
| **Versión de GitLab CE** | 17.x.x |
| **Docker Engine** | 27.x.x |
| **Docker Compose** | 2.x.x |
| **Sistema operativo del host** | Ubuntu 24.04 / macOS X / WSL2 |
| **RAM del host** | X GB |
| **CPU del host** | X cores |
| **Disco disponible** | X GB |

## Puertos configurados

| Puerto en host | Puerto en contenedor | Protocolo |
|---------------|---------------------|-----------|
| 80 | 80 | HTTP |
| 443 | 443 | HTTPS |
| 2224 | 22 | SSH |

## Configuración aplicada

- Contraseña root: Cambiada (no la inicial)
- Registro público: Deshabilitado
- Nombre de la instancia: Bootcamp DevOps Lab
- Zona horaria: America/Mexico_City (o la tuya)
- Usuario de trabajo creado: [tu-username]
- Telemetría: Deshabilitada

## Pasos realizados

1. Verificación de requisitos del sistema
2. Clonado del repositorio bc-gitlab
3. Configuración de .env con contraseña segura
4. Ejecución de `docker compose up -d`
5. Espera del healthcheck (~X minutos en este sistema)
6. Cambio de contraseña de root
7. Configuración de apariencia y restricciones
8. Creación de usuario de trabajo: [username]
9. Ejecución de `gitlab-rake gitlab:check` — sin errores
10. Creación de proyecto hello-gitlab con 2+ commits
11. Backup inicial ejecutado: [nombre del backup]
12. Restore verificado exitosamente

## Problemas encontrados y soluciones

[Documenta aquí cualquier problema que tuviste y cómo lo resolviste.
Si todo fue sin problemas, escribe "Sin problemas durante la instalación."]

## Comandos útiles de administración

```bash
# Ver estado de contenedores
docker compose ps

# Seguir logs en tiempo real
docker compose logs -f gitlab

# Ver estado de servicios internos
docker compose exec gitlab gitlab-ctl status

# Ejecutar sanity check
docker compose exec gitlab gitlab-rake gitlab:check SANITIZE=true

# Crear backup
docker compose exec gitlab gitlab-backup create STRATEGY=copy

# Obtener shell dentro del contenedor
docker compose exec gitlab bash

# Reiniciar solo el servidor web
docker compose exec gitlab gitlab-ctl restart puma
```

## Próximos pasos

Esta instancia se usará como base para el resto del bootcamp.
Semana 03: Configurar grupos, proyectos y permisos de usuarios.
```

Commitea con: `docs: complete INSTALL.md with installation documentation`

---

## ✅ Lista de verificación final

Antes de declarar el proyecto completo, ejecuta:

```bash
echo "=== VERIFICACIÓN FINAL PROYECTO SEMANA 02 ==="
echo ""
echo "--- 1. Estado de contenedores ---"
docker compose ps
echo ""
echo "--- 2. Servicios internos de GitLab ---"
docker compose exec gitlab gitlab-ctl status 2>/dev/null | head -20
echo ""
echo "--- 3. Respuesta HTTP ---"
curl -s -o /dev/null -w "HTTP %{http_code}" http://localhost
echo ""
echo "--- 4. Volúmenes de datos ---"
docker volume ls | grep bc-gitlab
echo ""
echo "--- 5. Lista de backups ---"
docker compose exec gitlab gitlab-backup list 2>/dev/null
echo ""
echo "--- 6. Secrets respaldado ---"
ls -la ~/gitlab-backups/gitlab-secrets-*.json 2>/dev/null || echo "⚠️ Secrets no encontrado en ~/gitlab-backups/"
echo ""
echo "=== Fin de la verificación ==="
```

Si todos los ítems muestran valores válidos: **el proyecto está completo**.

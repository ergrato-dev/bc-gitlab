# Práctica 03 — Restore Práctico

## Objetivo

Realizar un restore completo de GitLab desde un backup en un entorno de prueba, verificando la integridad de los datos.

## Requisitos

- Backup de GitLab CE generado en la práctica anterior
- Una segunda instancia de GitLab CE limpia (misma versión) para restaurar
- Docker Compose para levantar la instancia de prueba

## Instrucciones

### Paso 1: Levantar instancia de prueba

```bash
# Crear directorio para instancia de restore
mkdir restore-test && cd restore-test

# Copiar configuración del backup
cp /backups/gitlab.rb.20240620_020000 gitlab.rb
cp /backups/gitlab-secrets.json.20240620_020000 gitlab-secrets.json
```

Crea un `docker-compose.yml` básico para la instancia de prueba (misma versión de GitLab, puertos diferentes):
```yaml
version: '3.8'
services:
  gitlab-restore:
    image: gitlab/gitlab-ce:16.3.2-ce.0
    ports:
      - "8081:80"
      - "8444:443"
      - "2223:22"
    volumes:
      - ./config:/etc/gitlab
      - ./logs:/var/log/gitlab
      - ./data:/var/opt/gitlab
      - /backups:/backups:ro
```

### Paso 2: Copiar el backup a la nueva instancia

```bash
docker cp /backups/1718856000_2024_06_20_16.3.2_gitlab_backup.tar \
  restore-test_gitlab-restore_1:/var/opt/gitlab/backups/
```

### Paso 3: Ejecutar restore

```bash
docker exec -it restore-test_gitlab-restore_1 bash
chown git:git /var/opt/gitlab/backups/*.tar
gitlab-backup restore BACKUP=1718856000_2024_06_20_16.3.2
# Responder 'yes' a las confirmaciones
gitlab-ctl reconfigure
gitlab-ctl restart
```

### Paso 4: Verificar integridad

```bash
# Verificar servicios
gitlab-ctl status

# Verificar integridad general
gitlab-rake gitlab:check SANITIZE=true

# Verificar que los proyectos son accesibles
gitlab-rails runner "puts Project.count"
gitlab-rails runner "puts User.count"
```

### Paso 5: Checklist de verificación post-restore

| Verificación | Comando/Acción | Resultado esperado |
|-------------|---------------|-------------------|
| GitLab accesible | curl http://localhost:8081 | HTTP 302 (redirect a login) |
| Proyectos visibles | API: /api/v4/projects | Lista de proyectos |
| Repositorios clonables | git clone http://localhost:8081/grupo/proyecto.git | Clone exitoso |
| Issues presentes | Web UI → Issues | Issues del proyecto visibles |
| CI/CD pipelines visibles | Web UI → CI/CD → Pipelines | Historial de pipelines |
| Container Registry | docker login localhost:8443 | Login exitoso |

## Preguntas de reflexión
- ¿Cuánto tiempo tomó el restore completo? ¿Es aceptable para tu RTO?
- ¿Qué validaciones adicionales harías antes de poner la instancia en producción?
- ¿Qué harías si el restore falla a mitad del proceso?

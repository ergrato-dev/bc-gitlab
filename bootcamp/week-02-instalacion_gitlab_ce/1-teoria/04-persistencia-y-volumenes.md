# 04 — Persistencia de Datos y Volumenes Docker

## Objetivos

- Entender como Docker maneja la persistencia de datos
- Configurar volumenes para GitLab CE
- Realizar copias de seguridad de los volumenes
- Migrar datos entre instancias

## Por que la Persistencia es Critica

GitLab CE almacena varios tipos de datos:

- **Repositorios Git**: El activo mas valioso
- **Base de datos PostgreSQL**: Issues, MRs, usuarios, configuracion
- **Archivos subidos**: Imagenes, attachments, artifacts
- **Configuracion**: `/etc/gitlab/gitlab.rb`

Si los datos no persisten fuera del contenedor, `docker compose down` **destruye todo**.

## Volumenes en docker-compose.yml

El archivo `docker-compose.yml` raiz define 3 volumenes para GitLab:

```yaml
volumes:
  gitlab-config:   # /etc/gitlab — archivos de configuracion
  gitlab-logs:     # /var/log/gitlab — logs del sistema
  gitlab-data:     # /var/opt/gitlab — datos, repos, DB, uploads
```

Docker almacena estos volumenes en `/var/lib/docker/volumes/` del host.

### Inspeccionar volumenes

```bash
docker volume ls | grep bc-gitlab
docker volume inspect bc-gitlab-data
```

## Backup de Volumenes

### Backup completo con gitlab-backup

```bash
# Backup de base de datos + repositorios
docker compose exec gitlab gitlab-backup create STRATEGY=copy
```

El backup se guarda en `/var/opt/gitlab/backups/` dentro del contenedor.

### Backup de archivos de configuracion

```bash
docker compose exec gitlab gitlab-ctl backup-etc
```

### Copiar backup al host

```bash
docker compose cp gitlab:/var/opt/gitlab/backups ./backups/
```

### Backup programado con cron en Docker

```yaml
# Agregar a docker-compose.yml
gitlab:
  environment:
    GITLAB_OMNIBUS_CONFIG: |
      gitlab_rails['backup_keep_time'] = 604800  # 7 dias en segundos
```

## Restaurar desde Backup

```bash
# 1. Copiar backup al contenedor
docker compose cp 1719000000_2025_06_21_17.0.0_gitlab_backup.tar gitlab:/var/opt/gitlab/backups/

# 2. Restaurar (detiene servicios durante el proceso)
docker compose exec gitlab gitlab-backup restore BACKUP=1719000000_2025_06_21_17.0.0

# 3. Reiniciar GitLab
docker compose restart gitlab
```

## Migrar Datos entre Instancias

```bash
# Origen: Crear backup y copiar al host
docker compose exec gitlab gitlab-backup create
docker compose cp gitlab:/var/opt/gitlab/backups ./migracion/

# Destino: Copiar y restaurar
docker compose cp ./migracion/ gitlab:/var/opt/gitlab/backups/
docker compose exec gitlab gitlab-backup restore BACKUP=timestamp
```

## Buenas Practicas

1. **Backup diario programado** con retencion configurada
2. **Probar restore regularmente** (un backup que no se prueba no es backup)
3. **Backup externo**: Copiar backups a almacenamiento externo (S3, NFS)
4. **No usar bind mounts para produccion** (mejor volumenes nombrados)
5. **Documentar el proceso de restore** en el plan de DR

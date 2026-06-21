# 02 — Backup y Restore en GitLab CE

El backup de GitLab es fundamental para garantizar la continuidad del negocio. GitLab CE incluye la herramienta `gitlab-backup` que respalda todos los datos críticos.

## Componentes respaldables

| Componente | Incluido en gitlab-backup | Método alternativo |
|-----------|--------------------------|-------------------|
| Base de datos PostgreSQL | Sí (pg_dump) | pg_dump manual, WAL archiving |
| Repositorios Git | Sí (bundle) | git clone --mirror |
| Uploads y attachments | Sí | rsync |
| Container Registry | Sí | rsync |
| Packages (Maven, npm, etc.) | Sí | rsync |
| Configuración (`gitlab.rb`) | No | Backup manual del archivo |
| Secretos (`gitlab-secrets.json`) | No | Backup manual crítico |

## Comando de backup

```bash
sudo gitlab-backup create
```

Opciones útiles:
- `STRATEGY=copy` — más rápido en discos locales, no usa snapshots de FS
- `CRON=1` — suprime output no necesario para ejecución en cron
- `SKIP=db,uploads` — omitir componentes específicos
- `BACKUP=timestamp` — especificar timestamp personalizado

## Estrategias de backup

**Backup diario completo**: Ejecutar `gitlab-backup create` diariamente vía cron, con rotación de 7 días. Adecuado para instancias pequeñas.

**Backup incremental con WAL**: PostgreSQL puede configurarse con WAL archiving (Write-Ahead Log) para backup continuo y Point-in-Time Recovery (PITR). Requiere configurar `archive_mode = on` y `archive_command` en PostgreSQL.

**Respaldo externo a S3**: Los backups se pueden sincronizar a S3 (o MinIO, compatible con S3) con `aws s3 sync` o `rclone`. Ejemplo:
```bash
rclone sync /var/opt/gitlab/backups s3:gitlab-backups/
```

## Retención de backups

Configurar en `gitlab.rb`:
```ruby
gitlab_rails['backup_keep_time'] = 604800  # 7 días en segundos
```

Para eliminación manual más granular, usar `find` para rotar backups:
```bash
find /var/opt/gitlab/backups -name "*.tar" -mtime +7 -delete
```

## Restore

El restore se realiza con:
```bash
# 1. Restaurar configuración y secretos manualmente
# 2. Restaurar backup
sudo gitlab-backup restore BACKUP=1718856000_2024_06_20_16.3.2
# 3. Reconfigurar GitLab
sudo gitlab-ctl reconfigure
# 4. Reiniciar servicios
sudo gitlab-ctl restart
# 5. Verificar integridad
sudo gitlab-rake gitlab:check SANITIZE=true
```

**Precaución crítica**: Siempre probar el restore en un ambiente separado. Un backup sin restore probado no es un backup, es una esperanza.

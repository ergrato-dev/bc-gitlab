# Practica 04 — Backup y Restore Basico

## Objetivo
Realizar un backup completo de GitLab CE y verificar que se puede restaurar.

## Instrucciones

### 1. Crear un proyecto de prueba (para verificar restore)

1. Crea un proyecto llamado `test-backup` desde la UI de GitLab
2. Agrega un README.md con contenido

### 2. Realizar backup completo

```bash
# Ejecutar backup (sin respaldar config ni secrets por ahora)
docker compose exec gitlab gitlab-backup create

# Ver el archivo de backup creado
docker compose exec gitlab ls -la /var/opt/gitlab/backups/
```

El backup incluye: base de datos, repositorios, uploads, builds, artifacts, LFS objects, container registry, pages.

### 3. Respaldar archivos de configuracion

```bash
# Backup de gitlab-secrets.json (CRITICO: contiene claves de encriptacion)
docker compose exec gitlab cat /etc/gitlab/gitlab-secrets.json > gitlab-secrets-backup.json

# Backup de gitlab.rb
docker compose cp gitlab:/etc/gitlab/gitlab.rb ./gitlab.rb.backup
```

### 4. Simular restauracion

```bash
# Listar backups disponibles
docker compose exec gitlab gitlab-backup list

# Para restaurar (SOLO en entorno de practica - NO en produccion sin saber lo que haces):
# Primero detener servicios que escriben en DB
docker compose exec gitlab gitlab-ctl stop puma
docker compose exec gitlab gitlab-ctl stop sidekiq

# Restaurar (reemplaza TIMESTAMP con el valor real)
docker compose exec gitlab gitlab-backup restore BACKUP=TIMESTAMP

# Reconfigurar y reiniciar
docker compose exec gitlab gitlab-ctl reconfigure
docker compose exec gitlab gitlab-ctl restart
```

### 5. Automatizar backups (opcional)

Crear un script `backup.sh`:

```bash
#!/bin/bash
BACKUP_DIR="$HOME/gitlab-bootcamp/backups"
mkdir -p "$BACKUP_DIR"

cd ~/gitlab-bootcamp/gitlab-instance
docker compose exec -T gitlab gitlab-backup create

# Copiar backup a directorio local
LATEST=$(docker compose exec -T gitlab ls -t /var/opt/gitlab/backups/ | head -1)
docker compose cp "gitlab:/var/opt/gitlab/backups/$LATEST" "$BACKUP_DIR/"

echo "Backup completado: $BACKUP_DIR/$LATEST"
```

## Entregable
- Salida de `docker compose exec gitlab gitlab-backup list` mostrando al menos 1 backup
- Archivo `gitlab-secrets-backup.json` guardado localmente
- Captura del proyecto `test-backup` antes y despues del restore

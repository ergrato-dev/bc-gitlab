# 🛠️ Práctica 04 — Backup y Restore

⏱️ **Tiempo estimado:** 45 minutos  
⭐ **Dificultad:** Básico-Intermedio  
📋 **Prerrequisitos:** Práctica 03 completada — GitLab configurado con usuario de trabajo y proyecto de prueba

---

## 🎯 Objetivo

Realizar un backup completo de la instancia, respaldar los archivos críticos (`gitlab-secrets.json`), verificar el backup y ejecutar un restore de prueba para confirmar que el proceso funciona de extremo a extremo.

---

## Paso 1: Preparar contenido de prueba (antes del backup)

Para verificar que el restore funciona, necesitamos datos reconocibles en GitLab antes de hacer el backup.

Como tu usuario de trabajo (no root), ve a `http://localhost` y:

1. Abre el proyecto `hello-gitlab` creado en la práctica anterior
2. Crea un nuevo archivo → **+ (botón)** → **New file**
3. Nombre: `pre-backup-marker.txt`
4. Contenido:
   ```
   Este archivo existía ANTES del backup.
   Fecha de creación: [fecha y hora actual]
   Si lo ves después del restore, el backup funcionó correctamente.
   ```
5. Commit message: `test: add pre-backup marker file`
6. Haz clic en **Commit changes**

✅ **Verificación:** El proyecto tiene 2+ commits y el archivo `pre-backup-marker.txt` es visible.

---

## Paso 2: Crear el backup completo

```bash
# ¿QUÉ HACE?: Crea un backup completo de GitLab con la estrategia de copia
# ¿POR QUÉ?: STRATEGY=copy es más seguro para instancias activas (evita inconsistencias)
# ¿PARA QUÉ?: Generar un archivo .tar con todos los datos de la instancia
docker compose exec gitlab gitlab-backup create STRATEGY=copy
```

Este comando puede tardar **2-5 minutos**. Mientras corre, verás el progreso:

```
2025-06-25 12:00:01 -- Dumping database ...
Dumping PostgreSQL database gitlabhq_production ... [DONE]
2025-06-25 12:00:45 -- Dumping repositories ...
...
2025-06-25 12:01:30 -- Creating backup archive: 1750850001_2025_06_25_17.0.0_gitlab_backup.tar
2025-06-25 12:01:32 -- Backup done.
```

📋 **Copia el nombre del archivo** (el timestamp al inicio). Lo necesitas en el paso de restore.

---

## Paso 3: Verificar que el backup existe

```bash
# ¿QUÉ HACE?: Lista todos los backups con su fecha de creación y tamaño
# ¿POR QUÉ?: Confirma que el backup se guardó correctamente antes de depender de él
# ¿PARA QUÉ?: Identificar el nombre exacto del backup para usarlo en restore
docker compose exec gitlab gitlab-backup list

# Ver tamaño del backup (debe ser > 0 KB)
docker compose exec gitlab ls -lh /var/opt/gitlab/backups/
```

✅ **Output esperado:** Al menos un archivo con nombre `TIMESTAMP_2025_XX_XX_17.X.X_gitlab_backup.tar`.

---

## Paso 4: Respaldar los archivos de secrets (CRÍTICO)

```bash
# ¿QUÉ HACE?: Extrae gitlab-secrets.json del contenedor y lo guarda en el host
# ¿POR QUÉ?: Sin este archivo, el backup es IRRESTAUABLE (datos cifrados ilegibles)
# ¿PARA QUÉ?: Tener una copia de las claves de cifrado fuera del contenedor
docker compose exec gitlab cat /etc/gitlab/gitlab-secrets.json > ./gitlab-secrets.json

# Verificar que el archivo no está vacío
wc -c ./gitlab-secrets.json
```

✅ **Output esperado:** Un número de bytes mayor a `1000` (el archivo tiene contenido).

```bash
# ¿QUÉ HACE?: Hace una copia del archivo de configuración principal
# ¿POR QUÉ?: gitlab.rb contiene toda la configuración customizada de la instancia
# ¿PARA QUÉ?: Poder recrear la instancia con la misma configuración en caso de disaster
docker compose cp gitlab:/etc/gitlab/gitlab.rb ./gitlab.rb.backup
```

⚠️ **Guarda estos archivos en un lugar seguro** fuera del repositorio. Contienen información sensible.

---

## Paso 5: Copiar el backup al host

```bash
# ¿QUÉ HACE?: Crea el directorio de backups en el host
mkdir -p ./backups

# ¿QUÉ HACE?: Copia todos los backups del contenedor al directorio local del host
# ¿POR QUÉ?: Los backups en el volumen Docker desaparecen si eliminas los volúmenes
# ¿PARA QUÉ?: Tener una copia física fuera del contenedor
docker compose cp gitlab:/var/opt/gitlab/backups/. ./backups/

# Verificar la copia
ls -lh ./backups/
```

✅ **Output esperado:** El archivo `.tar` del backup aparece en el directorio `./backups/`.

---

## Paso 6: Simular el restore (flujo completo)

> ⚠️ **Este paso va a resetear GitLab al estado del backup.** Los cambios hechos DESPUÉS del backup se perderán. En producción solo harías esto en caso de emergencia. Aquí lo hacemos con fines educativos.

### 6a. Detener los servicios que escriben en la base de datos

```bash
# ¿QUÉ HACE?: Detiene el servidor web (Puma) y el procesador de trabajos (Sidekiq)
# ¿POR QUÉ?: Si siguen escribiendo mientras se restaura, corrompen la base de datos
# ¿PARA QUÉ?: Garantizar que nadie escribe en la BD durante el proceso de restore
docker compose exec gitlab gitlab-ctl stop puma
docker compose exec gitlab gitlab-ctl stop sidekiq

# Verificar que están detenidos
docker compose exec gitlab gitlab-ctl status | grep -E "puma|sidekiq"
# Output esperado: "down: puma: ..." y "down: sidekiq: ..."
```

### 6b. Asegurarse de que el backup está en el lugar correcto

Si el backup ya está en el volumen (lo acabamos de crear ahí), ya está disponible. Si estuvieras restaurando desde una copia del host:

```bash
# (Solo si el backup no está ya en el contenedor — en esta práctica sí está)
# docker compose cp ./backups/NOMBRE_DEL_BACKUP.tar gitlab:/var/opt/gitlab/backups/
# docker compose exec gitlab chown git:git /var/opt/gitlab/backups/NOMBRE_DEL_BACKUP.tar
```

### 6c. Ejecutar el restore

```bash
# ¿QUÉ HACE?: Extrae el backup y restaura la base de datos, repos, uploads y artifacts
# ¿POR QUÉ?: BACKUP= especifica el timestamp (sin "_gitlab_backup.tar" al final)
# ¿PARA QUÉ?: Recuperar el estado de GitLab al momento en que se creó el backup
#
# REEMPLAZA "TIMESTAMP_2025_XX_XX_17.X.X" con el nombre real de tu backup (sin .tar)
docker compose exec gitlab gitlab-backup restore BACKUP=TIMESTAMP_2025_XX_XX_17.X.X
```

El comando preguntará confirmación:
```
This task will now rebuild the authorized_keys file.
You will lose any key manually added to authorized_keys file.
Do you want to continue (yes/no)?
```
Escribe `yes` y presiona Enter.

Luego preguntará de nuevo:
```
Before restoring the database, we will remove all existing tables to avoid future problems.
If you have your own tables in the GitLab database you will lose them here.
Do you want to continue (yes/no)?
```
Escribe `yes` y presiona Enter.

⏱️ El restore puede tardar **2-10 minutos** dependiendo del tamaño.

### 6d. Reconfigurar y reiniciar

```bash
# ¿QUÉ HACE?: Aplica toda la configuración de gitlab.rb después del restore
# ¿POR QUÉ?: El restore puede dejar permisos y configuraciones en estado inconsistente
# ¿PARA QUÉ?: Restaurar GitLab a un estado completamente funcional
docker compose exec gitlab gitlab-ctl reconfigure

# ¿QUÉ HACE?: Reinicia todos los servicios internos de GitLab
# ¿POR QUÉ?: Puma y Sidekiq estaban parados; todos los servicios necesitan reinicio limpio
# ¿PARA QUÉ?: GitLab vuelve a estar completamente operativo
docker compose exec gitlab gitlab-ctl restart
```

---

## Paso 7: Verificar el restore

```bash
# ¿QUÉ HACE?: Ejecuta el check oficial de GitLab post-restore
# ¿POR QUÉ?: Verifica que permisos, conectividad y configuración quedaron correctos
# ¿PARA QUÉ?: Confirmar que el restore fue exitoso antes de declararlo "listo"
docker compose exec gitlab gitlab-rake gitlab:check SANITIZE=true
```

Ahora verifica en el navegador:

1. Ve a `http://localhost`
2. Inicia sesión con tu usuario de trabajo
3. Abre el proyecto `hello-gitlab`
4. Verifica que el archivo `pre-backup-marker.txt` existe

✅ **El restore fue exitoso** si el archivo que creaste en el Paso 1 sigue ahí.

---

## Paso 8: Automatizar el backup con un script diario

```bash
# ¿QUÉ HACE?: Crea un script de backup que puedes programar con cron
# ¿POR QUÉ?: Los backups manuales se olvidan; los automáticos protegen sin intervención
# ¿PARA QUÉ?: Tener backups diarios sin esfuerzo
cat > ./scripts/backup-diario.sh << 'EOF'
#!/bin/bash
set -euo pipefail

# Configuración
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$HOME/gitlab-backups"
DATE=$(date +%Y%m%d_%H%M%S)
LOG="$BACKUP_DIR/backup-$DATE.log"

mkdir -p "$BACKUP_DIR"

echo "=== Backup GitLab CE — $DATE ===" | tee "$LOG"
cd "$REPO_DIR"

# 1. Crear backup en el contenedor
echo "Creando backup..." | tee -a "$LOG"
docker compose exec -T gitlab gitlab-backup create STRATEGY=copy 2>&1 | tee -a "$LOG"

# 2. Copiar backup al host
LATEST=$(docker compose exec -T gitlab ls -t /var/opt/gitlab/backups/ | head -1 | tr -d '\r\n')
echo "Copiando $LATEST al host..." | tee -a "$LOG"
docker compose cp "gitlab:/var/opt/gitlab/backups/$LATEST" "$BACKUP_DIR/"

# 3. Backup de secrets
echo "Respaldando gitlab-secrets.json..." | tee -a "$LOG"
docker compose exec -T gitlab cat /etc/gitlab/gitlab-secrets.json \
  > "$BACKUP_DIR/gitlab-secrets-$DATE.json"

# 4. Limpiar backups locales de más de 7 días
find "$BACKUP_DIR" -name "*_gitlab_backup.tar" -mtime +7 -delete
find "$BACKUP_DIR" -name "gitlab-secrets-*.json" -mtime +7 -delete

echo "✅ Backup completado: $BACKUP_DIR/$LATEST" | tee -a "$LOG"
EOF

chmod +x ./scripts/backup-diario.sh
```

Para automatizarlo con cron (en el host):
```bash
# ¿QUÉ HACE?: Abre el editor de cron para el usuario actual
# ¿POR QUÉ?: cron ejecuta tareas automáticamente según el horario definido
# ¿PARA QUÉ?: Ejecutar el script de backup todos los días a las 2 AM sin intervención
crontab -e

# Agrega esta línea:
# 0 2 * * * /ruta/al/repo/bc-gitlab/scripts/backup-diario.sh >> /var/log/gitlab-backup.log 2>&1
```

---

## 🚨 Troubleshooting

| Error | Causa | Solución |
|-------|-------|----------|
| `gitlab-secrets.json mismatch` | Secrets no coinciden con el backup | Restaurar el `gitlab-secrets.json` del mismo momento del backup |
| `Permission denied` al restaurar | Permisos del archivo .tar | `docker compose exec gitlab chown git:git /var/opt/gitlab/backups/NOMBRE.tar` |
| `No space left on device` | Disco lleno durante el restore | Liberar espacio: `docker system prune` (cuidado en producción) |
| Restore cuelga sin progreso | Sidekiq aún corriendo | Verificar: `docker compose exec gitlab gitlab-ctl status sidekiq` → stop si sigue en `run:` |
| `backup list` muestra tabla vacía | Backup en path incorrecto | `docker compose exec gitlab ls -la /var/opt/gitlab/backups/` |
| El archivo `pre-backup-marker.txt` no aparece | El restore no completó | Revisar logs del restore; volver a ejecutar reconfigure + restart |

---

## 📝 Entregable

1. Output de `docker compose exec gitlab gitlab-backup list` mostrando al menos 1 backup
2. Verificación de que `gitlab-secrets.json` fue guardado localmente: `wc -c ./gitlab-secrets.json`
3. El archivo `pre-backup-marker.txt` visible en el proyecto `hello-gitlab` después del restore
4. Output de `docker compose exec gitlab gitlab-rake gitlab:check SANITIZE=true` (todo OK)

---

➡️ **Siguiente paso:** [3-proyecto — Proyecto integrador de la semana](../../3-proyecto/README.md)

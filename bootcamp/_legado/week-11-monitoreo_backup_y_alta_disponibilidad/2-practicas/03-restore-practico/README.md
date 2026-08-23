# Práctica 03 — Restore Práctico: Disaster Recovery Simulado

## Objetivo

Realizar un restore completo de GitLab CE desde un backup en un entorno de prueba aislado, medir el tiempo real de recuperación (RTO medido), verificar la integridad de todos los componentes y documentar el procedimiento de DR.

## Requisitos

- Backup generado en la práctica anterior (o cualquier backup reciente de GitLab CE)
- Docker y Docker Compose disponibles
- Suficiente espacio en disco (al menos el doble del tamaño del backup)
- La **misma versión de GitLab CE** que generó el backup
- Tiempo estimado: 60-90 minutos (dependiendo del tamaño del backup)

> Regla de oro del restore: **siempre restaurar en un entorno separado antes de tocar producción**.

---

## Instrucciones

### Paso 1: Preparar el entorno de restore

```bash
# Crear directorio de trabajo aislado
mkdir -p /opt/gitlab-dr-test/{config,logs,data,backups}
cd /opt/gitlab-dr-test

# Verificar que tenemos los archivos necesarios
BACKUP_FILE=$(ls -t /var/opt/gitlab/backups/*_gitlab_backup.tar 2>/dev/null | head -1)
CONFIG_DIR="/var/opt/gitlab/backups/config"

if [ -z "$BACKUP_FILE" ]; then
  echo "❌ No se encontró ningún backup. Ejecuta la práctica 02 primero."
  exit 1
fi

echo "Usando backup: $(basename $BACKUP_FILE)"
echo "Tamaño: $(du -sh $BACKUP_FILE | cut -f1)"

# Extraer el ID del backup (timestamp_version)
BACKUP_ID=$(basename "$BACKUP_FILE" _gitlab_backup.tar)
GITLAB_VERSION=$(echo "$BACKUP_ID" | grep -oP '\d+\.\d+\.\d+' | head -1)
echo "Versión GitLab del backup: $GITLAB_VERSION"

# Copiar backup y configuración
cp "$BACKUP_FILE" ./backups/
LATEST_CONFIG=$(ls -t "${CONFIG_DIR}"/gitlab.rb.* 2>/dev/null | head -1)
LATEST_SECRETS=$(ls -t "${CONFIG_DIR}"/gitlab-secrets.json.* 2>/dev/null | head -1)

if [ -n "$LATEST_CONFIG" ]; then
  cp "$LATEST_CONFIG" ./config/gitlab.rb
  cp "$LATEST_SECRETS" ./config/gitlab-secrets.json
  echo "✅ Configuración copiada"
else
  echo "⚠️  No se encontró backup de configuración. Usando configuración básica."
  cp /etc/gitlab/gitlab.rb ./config/
  cp /etc/gitlab/gitlab-secrets.json ./config/
fi
```

### Paso 2: Crear el entorno de restore con Docker Compose

```yaml
# /opt/gitlab-dr-test/docker-compose.yml
# ¿QUÉ HACE?: Levanta una instancia GitLab limpia para restore
# ¿POR QUÉ?: El restore debe hacerse en una instancia con la MISMA versión que el backup
# ¿PARA QUÉ?: Entorno aislado sin riesgo de afectar la instancia de producción
version: '3.8'

services:
  gitlab-restore:
    image: gitlab/gitlab-ce:${GITLAB_VERSION}-ce.0
    container_name: gitlab-restore
    hostname: gitlab-restore.test.local
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://localhost:8081'
        gitlab_rails['time_zone'] = 'UTC'
        # Deshabilitar emails durante restore para no enviar notificaciones falsas
        gitlab_rails['smtp_enable'] = false
    ports:
      - "8081:80"
      - "8444:443"
      - "2223:22"
    volumes:
      - ./config:/etc/gitlab
      - ./logs:/var/log/gitlab
      - ./data:/var/opt/gitlab
      - ./backups:/backups:ro   # Los backups son de solo lectura
    shm_size: '256m'
    restart: "no"   # No reiniciar automáticamente en este entorno de prueba
```

```bash
# Crear el .env con la versión correcta
echo "GITLAB_VERSION=${GITLAB_VERSION}" > .env

# Levantar la instancia (tarda 2-4 minutos para iniciar)
DR_START=$(date +%s)
echo "⏱️  DR simulacro iniciado: $(date)"

docker compose up -d

echo "Esperando que GitLab inicie (esto tarda 2-4 minutos)..."
until docker exec gitlab-restore gitlab-ctl status 2>/dev/null | grep -q "run: puma"; do
  echo -n "."
  sleep 10
done
echo ""
echo "GitLab iniciado. Tiempo: $(($(date +%s) - DR_START))s"
```

### Paso 3: Preparar el backup para restore

```bash
# Copiar el backup al directorio dentro del contenedor
BACKUP_FILENAME=$(basename "$BACKUP_FILE")
docker exec gitlab-restore bash -c "
  cp /backups/${BACKUP_FILENAME} /var/opt/gitlab/backups/
  chown git:git /var/opt/gitlab/backups/${BACKUP_FILENAME}
  ls -lah /var/opt/gitlab/backups/
"

echo "Backup disponible dentro del contenedor"
```

### Paso 4: Ejecutar el restore

```bash
echo "⏱️  Iniciando restore: $(date)"
RESTORE_START=$(date +%s)

# Detener los servicios que usan la base de datos
docker exec gitlab-restore gitlab-ctl stop puma
docker exec gitlab-restore gitlab-ctl stop sidekiq
docker exec gitlab-restore gitlab-ctl status | grep -E "puma|sidekiq"
# Ambos deben mostrar: down: ...

# Ejecutar el restore (necesita confirmación interactiva — usamos expect o pipe)
docker exec -i gitlab-restore bash << RESTORE_SCRIPT
# El restore pide confirmación dos veces — enviamos "yes" automáticamente
echo "yes" | gitlab-backup restore BACKUP=${BACKUP_ID} 2>&1
RESTORE_SCRIPT

RESTORE_TIME=$(($(date +%s) - RESTORE_START))
echo "⏱️  Restore completado en ${RESTORE_TIME} segundos"

# Reconfigure post-restore (aplica la configuración al estado restaurado)
echo "Ejecutando reconfigure post-restore..."
docker exec gitlab-restore gitlab-ctl reconfigure

# Reiniciar todos los servicios
echo "Reiniciando todos los servicios..."
docker exec gitlab-restore gitlab-ctl restart

# Esperar que todos los servicios vuelvan a estar arriba
echo "Esperando que los servicios estabilicen..."
sleep 30
docker exec gitlab-restore gitlab-ctl status
```

### Paso 5: Verificación de integridad post-restore

```bash
echo ""
echo "=============================================="
echo "  VERIFICACIÓN DE INTEGRIDAD POST-RESTORE"
echo "=============================================="

# 5.1 Verificación de servicios
echo ""
echo "5.1 Estado de servicios:"
docker exec gitlab-restore gitlab-ctl status | grep -E "(run|down)" | \
  awk '{print $1, $2}' | sort

# 5.2 Verificación general de GitLab
echo ""
echo "5.2 Ejecutando gitlab:check..."
docker exec gitlab-restore gitlab-rake gitlab:check SANITIZE=true 2>&1 | \
  grep -E "(PASSED|FAILED|ERROR|WARNING)" | head -20

# 5.3 Conteo de datos restaurados
echo ""
echo "5.3 Datos restaurados:"
docker exec gitlab-restore gitlab-rails runner "
  puts 'Usuarios: ' + User.count.to_s
  puts 'Proyectos: ' + Project.count.to_s
  puts 'Grupos: ' + Group.count.to_s
  puts 'Issues: ' + Issue.count.to_s
  puts 'Merge Requests: ' + MergeRequest.count.to_s
  puts 'Pipelines: ' + Ci::Pipeline.count.to_s
  puts 'Runners: ' + Ci::Runner.count.to_s
" 2>/dev/null

# 5.4 Verificar HTTP
echo ""
echo "5.4 Verificando HTTP:"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081)
echo "HTTP Status: $HTTP_STATUS (esperado: 302)"
[ "$HTTP_STATUS" = "302" ] && echo "✅ Redirección a login" || echo "❌ HTTP no responde correctamente"

# 5.5 Verificar API
echo ""
echo "5.5 Verificando API:"
API_RESPONSE=$(curl -s http://localhost:8081/api/v4/version)
echo "API version: $API_RESPONSE"

# 5.6 Verificar que al menos un repositorio es clonable
echo ""
echo "5.6 Verificando repositorios:"
FIRST_PROJECT=$(curl -s http://localhost:8081/api/v4/projects?per_page=1 | \
  jq -r '.[0].http_url_to_repo // "no hay proyectos"')
echo "Primer proyecto: $FIRST_PROJECT"

if [ "$FIRST_PROJECT" != "no hay proyectos" ]; then
  CLONE_URL="http://localhost:8081$(echo $FIRST_PROJECT | sed 's|http://[^/]*||')"
  cd /tmp
  git clone --mirror "$CLONE_URL" /tmp/test-clone-$(date +%s) 2>&1 | tail -3 && \
    echo "✅ Clone exitoso" || echo "⚠️  Clone requiere autenticación (esperado para repo privado)"
fi
```

### Paso 6: Checklist formal de verificación

```bash
# Generar reporte de verificación
REPORT_FILE="/opt/gitlab-dr-test/dr-verification-$(date +%Y%m%d).md"

cat > "$REPORT_FILE" << REPORT
# Reporte de Disaster Recovery Test

**Fecha**: $(date '+%Y-%m-%d %H:%M:%S')
**Backup ID**: ${BACKUP_ID}
**Servidor origen**: $(hostname)
**GitLab versión**: ${GITLAB_VERSION}
**Tiempo de restore**: ${RESTORE_TIME}s
**RTO medido**: $(($(date +%s) - DR_START))s total (incluye levantamiento de entorno)

## Checklist de Verificación

| Verificación | Resultado |
|-------------|-----------|
| GitLab HTTP accesible (localhost:8081) | $([ "$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081)" = "302" ] && echo "✅ PASS" || echo "❌ FAIL") |
| API respondiendo (/api/v4/version) | $(curl -s http://localhost:8081/api/v4/version | jq -r 'if .version then "✅ PASS: "+.version else "❌ FAIL" end') |
| Servicios corriendo | $(docker exec gitlab-restore gitlab-ctl status 2>/dev/null | grep -c "^run") / $(docker exec gitlab-restore gitlab-ctl status 2>/dev/null | wc -l) servicios |
| Usuarios en BD | $(docker exec gitlab-restore gitlab-rails runner "print User.count" 2>/dev/null) |
| Proyectos en BD | $(docker exec gitlab-restore gitlab-rails runner "print Project.count" 2>/dev/null) |
| Issues en BD | $(docker exec gitlab-restore gitlab-rails runner "print Issue.count" 2>/dev/null) |

## Métricas de DR

- **RTO total** (desde inicio hasta verificación): $(($(date +%s) - DR_START))s
- **Tiempo de restore** (solo gitlab-backup restore): ${RESTORE_TIME}s
- **Tamaño del backup**: $(du -sh $BACKUP_FILE | cut -f1)

## Observaciones

<!-- Añadir notas sobre issues encontrados, diferencias con producción, etc. -->

REPORT

echo "Reporte guardado en: $REPORT_FILE"
cat "$REPORT_FILE"
```

### Paso 7: Documentar el tiempo de DR

```bash
DR_TOTAL=$(($(date +%s) - DR_START))

echo ""
echo "=============================================="
echo "  RESUMEN DEL SIMULACRO DE DR"
echo "=============================================="
echo "Tiempo total de recovery: ${DR_TOTAL}s ($(( DR_TOTAL / 60 ))m $(( DR_TOTAL % 60 ))s)"
echo "RTO medido: ${DR_TOTAL}s"
echo ""

if [ "$DR_TOTAL" -lt 1800 ]; then
  echo "✅ Dentro del objetivo de RTO < 30 minutos"
elif [ "$DR_TOTAL" -lt 3600 ]; then
  echo "⚠️  RTO > 30 min pero < 60 min. Revisar si es aceptable."
else
  echo "❌ RTO > 60 min. Revisar arquitectura de backup."
fi

# Limpiar entorno de prueba
echo ""
echo "Limpiando entorno de prueba..."
docker compose down
echo "Contenedor eliminado. Los datos de prueba están en /opt/gitlab-dr-test/"
```

---

## Casos de error comunes y soluciones

### Error: "Backup requires GitLab version X.X.X but you have Y.Y.Y"

```bash
# El restore REQUIERE la misma versión exacta
# Solución: cambiar la imagen Docker a la versión correcta
DOCKER_IMAGE="gitlab/gitlab-ce:${GITLAB_VERSION}-ce.0"
docker pull "$DOCKER_IMAGE"
# Luego actualizar docker-compose.yml con esa versión
```

### Error: "tar: Error is not recoverable: exiting now"

```bash
# El backup está corrupto
# Verificar integridad:
tar -tf "$BACKUP_FILE" > /dev/null 2>&1 || echo "Backup corrupto — usar backup anterior"
# Ver checksums guardados para comparar
cat /var/opt/gitlab/backups/checksums.sha256
```

### Error: permisos en el directorio de backups

```bash
# Ajustar permisos correctos
docker exec gitlab-restore bash -c "
  chown -R git:git /var/opt/gitlab/backups/
  chmod 700 /var/opt/gitlab/backups/
  ls -la /var/opt/gitlab/backups/*.tar
"
```

### Servicios no inician después del restore

```bash
# Revisar logs de cada servicio
docker exec gitlab-restore gitlab-ctl tail postgresql
docker exec gitlab-restore gitlab-ctl tail puma
docker exec gitlab-restore gitlab-ctl tail sidekiq

# Intentar reconfigure adicional
docker exec gitlab-restore gitlab-ctl reconfigure
docker exec gitlab-restore gitlab-ctl restart
```

---

## Preguntas de reflexión

1. El RTO medido fue diferente al estimado en el plan de DR. ¿Qué factores explican la diferencia? ¿Qué partes del proceso se pueden acelerar?

2. Al verificar los datos restaurados, el conteo de usuarios coincide pero faltan algunos issues. ¿Qué podría explicar esta discrepancia?

3. El restore tardó 45 minutos. Tu RTO objetivo es 30 minutos. ¿Qué cambios en la estrategia de backup o infraestructura permitirían alcanzar ese objetivo?

4. Durante el restore, los usuarios de producción seguían trabajando en la instancia original. ¿Qué harías para hacer el cutover del tráfico de la instancia original a la restaurada de forma transparente?

5. Después de un DR real (no un simulacro), ¿qué acciones tomarías para evitar que el mismo problema vuelva a ocurrir?

---

## Entregables

- [ ] Entorno de restore Docker Compose creado con la versión correcta de GitLab
- [ ] Restore ejecutado exitosamente (sin errores fatales)
- [ ] Verificación de servicios: todos en estado "run"
- [ ] gitlab:check SANITIZE=true ejecutado y output documentado
- [ ] Conteo de datos: usuarios, proyectos, issues verificados vs backup
- [ ] HTTP y API verificados como funcionales
- [ ] Reporte de DR generado con RTO medido
- [ ] Entorno de prueba limpiado post-verificación

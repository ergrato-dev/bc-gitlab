# Práctica 04 — Documentación y Preparación de Defensa

## Objetivo

Generar toda la documentación operacional del proyecto, crear los scripts de backup y restore, escribir el README.md final y preparar la presentación de defensa con el demo script ensayado. Al final de esta práctica, el proyecto está listo para ser entregado y presentado.

## Requisitos

- Prácticas 01, 02 y 03 completadas
- Pipeline ejecutándose exitosamente en producción
- Grafana con dashboards y datos reales
- Tiempo estimado: 60-75 minutos

---

## Instrucciones

### Paso 1: Script de backup completo

```bash
# backup/backup.sh
cat > backup/backup.sh << 'SCRIPT'
#!/bin/bash
# ¿QUÉ HACE?: Backup completo de GitLab con verificación y upload a MinIO
# ¿POR QUÉ?: Backup sin verificación puede fallar silenciosamente
# ¿PARA QUÉ?: Proceso automatizable y trazable de backup diario

set -euo pipefail

BACKUP_DIR="/var/opt/gitlab/backups"
LOG_FILE="/tmp/gitlab-backup-$(date +%Y%m%d_%H%M%S).log"
MINIO_ALIAS="local"
MINIO_BUCKET="gitlab-backups"
START_TIME=$(date +%s)

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

log "=== Backup GitLab — $(date '+%Y-%m-%d') ==="

# 1. Backup de secretos (NO incluido en gitlab-backup create)
log "Copiando secrets y configuración..."
mkdir -p /tmp/gitlab-config-backup
docker cp gitlab:/etc/gitlab/gitlab-secrets.json \
  /tmp/gitlab-config-backup/gitlab-secrets.json.$(date +%Y%m%d) 2>&1 | tee -a "$LOG_FILE"
docker cp gitlab:/etc/gitlab/gitlab.rb \
  /tmp/gitlab-config-backup/gitlab.rb.$(date +%Y%m%d) 2>&1 | tee -a "$LOG_FILE"
log "✅ Secretos respaldados"

# 2. Backup principal de datos
log "Ejecutando gitlab-backup create..."
docker exec gitlab gitlab-backup create CRON=1 2>&1 | tee -a "$LOG_FILE"

BACKUP_FILE=$(docker exec gitlab ls -t ${BACKUP_DIR}/*_gitlab_backup.tar 2>/dev/null | head -1)
BACKUP_FILENAME=$(basename "$BACKUP_FILE")
BACKUP_SIZE=$(docker exec gitlab du -sh "$BACKUP_FILE" | cut -f1)
log "Backup creado: $BACKUP_FILENAME ($BACKUP_SIZE)"

# 3. Verificar integridad del backup
log "Verificando integridad..."
docker exec gitlab tar -tf "$BACKUP_FILE" > /dev/null 2>&1 && \
  log "✅ Backup verificado" || \
  (log "❌ ERROR: backup corrupto" && exit 1)

# 4. Calcular checksum
CHECKSUM=$(docker exec gitlab sha256sum "$BACKUP_FILE" | cut -d' ' -f1)
echo "$CHECKSUM  $BACKUP_FILENAME" >> /tmp/checksums.sha256
log "SHA256: ${CHECKSUM:0:16}..."

# 5. Subir a MinIO
log "Subiendo a MinIO..."
docker exec minio mc cp "/gitlab-backups/$BACKUP_FILENAME" \
  "${MINIO_ALIAS}/${MINIO_BUCKET}/${BACKUP_FILENAME}" 2>&1 | tee -a "$LOG_FILE" || \
  log "⚠️  Upload a MinIO falló (backup local disponible)"

# 6. Resumen
DURATION=$(($(date +%s) - START_TIME))
log "============================================"
log "Backup completado en ${DURATION}s"
log "Archivo: $BACKUP_FILENAME"
log "Tamaño: $BACKUP_SIZE"
log "Log: $LOG_FILE"
log "============================================"
SCRIPT

chmod +x backup/backup.sh
```

```bash
# backup/restore.sh
cat > backup/restore.sh << 'SCRIPT'
#!/bin/bash
# ¿QUÉ HACE?: Restaura GitLab desde un backup específico
# ¿POR QUÉ?: El restore requiere pasos precisos en orden correcto
# ¿PARA QUÉ?: Recuperación ante desastres documentada y reproducible

set -euo pipefail

BACKUP_ID="${1:-}"

if [ -z "$BACKUP_ID" ]; then
  echo "Uso: $0 <BACKUP_ID>"
  echo "Ejemplo: $0 1717200000_2024_05_31_16.11.0"
  echo ""
  echo "Backups disponibles:"
  docker exec gitlab ls -la /var/opt/gitlab/backups/*.tar 2>/dev/null | \
    awk '{print $NF}' | xargs -I{} basename {} _gitlab_backup.tar
  exit 1
fi

echo "⚠️  RESTORE de GitLab — esto sobreescribirá todos los datos actuales"
echo "Backup ID: $BACKUP_ID"
read -p "¿Confirmar? (escribir 'RESTORE' para continuar): " CONFIRM
[ "$CONFIRM" = "RESTORE" ] || (echo "Cancelado" && exit 1)

echo "1/4 Deteniendo servicios..."
docker exec gitlab gitlab-ctl stop puma
docker exec gitlab gitlab-ctl stop sidekiq
docker exec gitlab gitlab-ctl status | grep -E "(puma|sidekiq)"

echo "2/4 Ejecutando restore..."
docker exec -i gitlab bash -c "echo 'yes' | gitlab-backup restore BACKUP=${BACKUP_ID}"

echo "3/4 Reconfigurando y reiniciando..."
docker exec gitlab gitlab-ctl reconfigure
docker exec gitlab gitlab-ctl restart

echo "4/4 Verificando..."
sleep 30
curl -sf http://localhost/-/health > /dev/null && \
  echo "✅ GitLab restaurado y accesible" || \
  echo "❌ GitLab no responde — revisar logs: docker compose logs gitlab"
SCRIPT

chmod +x backup/restore.sh
```

### Paso 2: Ejecutar un backup y verificar

```bash
# Ejecutar el script de backup
./backup/backup.sh

# Verificar que el backup apareció en MinIO
docker exec minio mc ls local/gitlab-backups/ | sort -k3 | tail -5

# Simular restore en un entorno diferente (verificación conceptual)
# En la práctica real, esto se haría en una VM separada
echo "Para restore completo, ver docs/disaster-recovery.md"
```

### Paso 3: Documentar la arquitectura

```bash
cat > docs/arquitectura.md << 'EOF'
# Arquitectura de la Plataforma DevOps

## Diagrama

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Host Docker (servidor único)                      │
│                                                                      │
│  ┌────────────┐    ┌──────────────┐    ┌──────────────────────────┐ │
│  │ GitLab CE  │    │ GitLab Runner│    │  Prometheus + Grafana    │ │
│  │  :80/:443  │    │   (Docker)   │    │   :9090 / :3000          │ │
│  │  :5050     │    │              │    │                          │ │
│  │ (Registry) │    │  Ejecuta     │    │  Monitoreo y alertas     │ │
│  └────────────┘    │  jobs CI/CD  │    └──────────────────────────┘ │
│                    └──────────────┘                                  │
│  ┌────────────────┐                    ┌──────────────────────────┐ │
│  │  MinIO         │                    │  App de ejemplo          │ │
│  │  :9000/:9001   │                    │  staging: :5001          │ │
│  │  Backup storage│                    │  production: :5000       │ │
│  └────────────────┘                    └──────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## Componentes

| Componente | Imagen Docker | Propósito | Puerto(s) |
|-----------|--------------|----------|-----------|
| GitLab CE | gitlab/gitlab-ce:16.11.0-ce.0 | Repositorios, CI/CD, Registry | 80, 443, 2222, 5050 |
| GitLab Runner | gitlab/gitlab-runner:alpine | Ejecutar jobs de CI/CD | (interno) |
| Prometheus | prom/prometheus:v2.51.0 | Recolección de métricas | 9090 |
| Grafana | grafana/grafana:10.4.2 | Visualización y alertas | 3000 |
| MinIO | minio/minio:latest | Almacenamiento S3 para backups | 9000, 9001 |

## Flujo CI/CD

```
Developer → git push → GitLab CE → Pipeline trigger
  └── Stage build: docker build + push to Registry
  └── Stage test: pytest (5 tests, ~100% cobertura)
  └── Stage security: SAST (Bandit) + Secret Detection
  └── Stage deploy-staging: docker run (automático en main)
  └── Stage deploy-production: docker run (manual con tag v*.*.*)
```

## Decisiones de diseño

**Docker Compose single-node**: Para el alcance del bootcamp, un solo servidor con Docker Compose es suficiente para demostrar todos los conceptos. Para producción con 150+ usuarios, se necesitaría escalar horizontalmente (múltiples Rails, Gitaly Cluster, PostgreSQL HA).

**GitLab CE auto-administrado**: Permite practicar la administración real: RBAC, MFA, backup, configuración de runners. SaaS no da acceso a estas operaciones de plataforma.

**MinIO como S3**: Simula el comportamiento de AWS S3 sin necesitar acceso a cloud. En producción real, se reemplaza cambiando el endpoint y las credenciales — misma API.

**Pipeline con SAST**: Usa los templates de seguridad de GitLab CE para detectar vulnerabilidades intencionales en la app de demo. Los hallazgos son reales y aparecen en el Security Dashboard.
EOF
```

### Paso 4: Manual de operaciones

```bash
cat > docs/manual-operaciones.md << 'EOF'
# Manual de Operaciones — Plataforma DevOps

## Requisitos del sistema

- Docker Engine 24+ y Docker Compose v2
- RAM: mínimo 8GB (GitLab usa 4-6GB)
- Disco: mínimo 20GB libre
- Puertos disponibles: 80, 443, 2222, 3000, 9000, 9001

## Instalación desde cero

```bash
# 1. Clonar el repositorio
git clone http://gitlab.local/root/proyecto-final.git
cd proyecto-final

# 2. Configurar variables de entorno
cp .env.example .env
# Editar .env con valores apropiados para tu entorno

# 3. Levantar la plataforma
docker compose up -d

# 4. Esperar que GitLab inicie (3-5 minutos)
until curl -sf http://localhost/-/health; do sleep 15; echo "Esperando..."; done

# 5. Obtener contraseña inicial de root
docker exec gitlab cat /etc/gitlab/initial_root_password | grep "Password:"
```

## Operaciones cotidianas

### Verificar estado de la plataforma

```bash
docker compose ps
curl -sf http://localhost/-/health && echo "GitLab OK"
curl -sf http://localhost:3000/api/health | jq '.database'
```

### Ejecutar backup manual

```bash
./backup/backup.sh
# El backup se sube automáticamente a MinIO
```

### Actualizar GitLab CE

```bash
# 1. Hacer backup antes de actualizar (SIEMPRE)
./backup/backup.sh

# 2. Cambiar la versión en .env
# GITLAB_VERSION=16.11.0-ce.0 → GITLAB_VERSION=17.0.0-ce.0

# 3. Actualizar
docker compose pull gitlab
docker compose up -d gitlab

# 4. Verificar
docker compose logs gitlab --tail 50 | grep -E "(migration|error|complete)"
curl -sf http://localhost/api/v4/version | jq .version
```

### Registrar un nuevo Runner

```bash
RUNNER_TOKEN="TOKEN_DE_ADMIN_AREA"
docker exec gitlab-runner gitlab-runner register \
  --non-interactive \
  --url "http://gitlab" \
  --registration-token "$RUNNER_TOKEN" \
  --executor "docker" \
  --docker-image "python:3.11-slim" \
  --docker-network-mode "proyecto-final-net" \
  --description "mi-runner"
```

## Solución de problemas frecuentes

| Problema | Síntoma | Solución |
|---------|---------|---------|
| GitLab no inicia | `docker compose ps` muestra "unhealthy" | `docker compose logs gitlab --tail 100` para ver el error |
| Runner no toma jobs | Jobs en "pending" permanentemente | `docker exec gitlab-runner gitlab-runner verify` |
| Pipeline falla en build | Error de autenticación al Registry | Verificar variable `CI_REGISTRY_PASSWORD` en Settings → CI/CD |
| Grafana sin datos | Gráficos vacíos | Verificar que Prometheus scrape es exitoso: `http://localhost:9090/targets` |
| Disco lleno | GitLab lento / errores | `docker system prune` (sin -v) para limpiar imágenes no usadas |
EOF
```

### Paso 5: Plan de Disaster Recovery

```bash
cat > docs/disaster-recovery.md << 'EOF'
# Plan de Disaster Recovery

## Objetivos

- **RTO (Recovery Time Objective)**: 30 minutos
- **RPO (Recovery Point Objective)**: 24 horas (frecuencia de backup)

## Escenarios y procedimientos

### Escenario 1: Contenedor GitLab caído (RTO: 5 min)

**Síntoma**: `curl http://localhost/-/health` retorna error o timeout

```bash
# Diagnóstico
docker compose ps | grep gitlab
docker compose logs gitlab --tail 20

# Acción
docker compose restart gitlab
until curl -sf http://localhost/-/health; do sleep 15; done
echo "GitLab restaurado"
```

### Escenario 2: Datos corruptos en PostgreSQL (RTO: 30 min)

**Síntoma**: Errores 500 en GitLab UI, logs de PostgreSQL con errores de consistencia

```bash
# 1. Identificar el backup más reciente
docker exec gitlab ls -lt /var/opt/gitlab/backups/*.tar | head -3
BACKUP_ID="1717200000_2024_05_31_16.11.0"  # Cambiar por el backup real

# 2. Ejecutar restore
./backup/restore.sh $BACKUP_ID

# 3. Verificar
curl -sf http://localhost/-/health
```

### Escenario 3: Pérdida total del servidor (RTO: 2h)

**Síntoma**: El servidor no responde, datos locales perdidos

```bash
# Pre-requisito: backup disponible en MinIO en otro servidor
# 1. Instalar Docker en el nuevo servidor
# 2. Clonar el repositorio de infraestructura
# 3. Descargar el backup de MinIO
# 4. Restaurar siguiendo el Escenario 2

# Descargar backup desde MinIO remoto
mc alias set backup-store http://MINIO_SERVER:9000 ACCESS_KEY SECRET_KEY
mc cp backup-store/gitlab-backups/BACKUP_ID_gitlab_backup.tar /tmp/
```

## Checklist post-recuperación

Después de cualquier restore, verificar:

- [ ] GitLab accesible en HTTP/HTTPS
- [ ] Login con credenciales de admin funciona
- [ ] Al menos 1 proyecto visible
- [ ] CI/CD Runner en estado "online"
- [ ] `gitlab-rake gitlab:check SANITIZE=true` sin errores FAILED
- [ ] Contar proyectos: `gitlab-rails runner "puts Project.count"`
- [ ] Prometheus scraping activo
- [ ] Monitorear durante 30 min para detectar errores tardíos
EOF
```

### Paso 6: README.md del proyecto

```bash
cat > README.md << 'EOF'
# Proyecto Final — Plataforma DevOps con GitLab CE

Plataforma DevOps completa auto-administrada basada en GitLab CE 16.11, con CI/CD automatizado, escáners de seguridad integrados, monitoreo con Prometheus/Grafana y backup automatizado.

## Quick Start (3 pasos)

```bash
git clone http://gitlab.local/root/proyecto-final.git && cd proyecto-final
cp .env.example .env
docker compose up -d
```

GitLab disponible en http://localhost en 3-5 minutos.

## Stack tecnológico

| Componente | Tecnología | Versión |
|-----------|-----------|---------|
| GitLab CE | Docker | 16.11.0 |
| CI Runner | Docker executor | alpine |
| App demo | Python Flask + pytest | 3.11 |
| Seguridad | SAST (Bandit) + Secret Detection | CE templates |
| Monitoreo | Prometheus + Grafana | v2.51 + v10.4 |
| Backup | Script + MinIO | - |

## Arquitectura

Ver [docs/arquitectura.md](docs/arquitectura.md) para el diagrama completo.

## Pipeline CI/CD

El pipeline tiene 5 stages:

```
build → test → security → package → deploy
```

- **build**: Construye imagen Docker y la sube al Registry
- **test**: Ejecuta tests unitarios con reporte de cobertura
- **security**: SAST, Secret Detection, Container Scanning
- **package**: Etiqueta la imagen como `:latest` (solo en `main`)
- **deploy**: Staging (automático en `main`) o Production (manual en tag)

## Servicios

| URL | Servicio | Credenciales |
|-----|---------|-------------|
| http://localhost | GitLab CE | root / (ver `initial_root_password`) |
| http://localhost:3000 | Grafana | admin / admin123 |
| http://localhost:9090 | Prometheus | - |
| http://localhost:9001 | MinIO Console | minioadmin / minioadmin123 |
| http://localhost:5001 | App staging | - |
| http://localhost:5000 | App production | - |

## Operaciones

```bash
# Backup manual
./backup/backup.sh

# Restore desde backup
./backup/restore.sh <BACKUP_ID>

# Estado de todos los servicios
docker compose ps

# Logs de GitLab
docker compose logs gitlab --tail 50
```

## Documentación

- [Arquitectura](docs/arquitectura.md)
- [Manual de Operaciones](docs/manual-operaciones.md)
- [Disaster Recovery](docs/disaster-recovery.md)
- [Matriz RBAC](docs/rbac.md)

---

*Proyecto Final — Bootcamp GitLab CE Administración DevOps*
EOF
```

### Paso 7: Verificación final y pre-defensa

```bash
#!/bin/bash
echo "=== Verificación Final del Proyecto ==="

pass=0
fail=0

chk() {
  local name="$1"
  local cmd="$2"
  if eval "$cmd" > /dev/null 2>&1; then
    echo "✅ $name"
    ((pass++))
  else
    echo "❌ $name"
    ((fail++))
  fi
}

# Infraestructura
chk "GitLab accesible" "curl -sf http://localhost/-/health"
chk "Runner online" "docker exec gitlab-runner gitlab-runner verify 2>&1 | grep -q 'alive'"
chk "Prometheus OK" "curl -sf http://localhost:9090/-/healthy"
chk "Grafana OK" "curl -sf http://localhost:3000/api/health"
chk "MinIO OK" "curl -sf http://localhost:9000/minio/health/live"

# Pipeline
chk "Pipeline exitoso" "
  curl -s --header 'PRIVATE-TOKEN: $ADMIN_TOKEN' \
  'http://localhost/api/v4/projects/1/pipelines?status=success&per_page=1' | \
  jq '.[0].id' | grep -v null"

# Seguridad
chk "SAST hallazgos" "
  [ \$(curl -s --header 'PRIVATE-TOKEN: $ADMIN_TOKEN' \
  'http://localhost/api/v4/projects/1/vulnerability_findings' | jq 'length') -gt 0 ]"
chk "MFA activo" "
  curl -s --header 'PRIVATE-TOKEN: $ADMIN_TOKEN' \
  'http://localhost/api/v4/application/settings' | \
  jq -e '.require_two_factor_authentication == true'"

# Documentación
chk "README.md existe" "[ -f README.md ]"
chk "docs/arquitectura.md" "[ -f docs/arquitectura.md ]"
chk "docs/manual-operaciones.md" "[ -f docs/manual-operaciones.md ]"
chk "docs/disaster-recovery.md" "[ -f docs/disaster-recovery.md ]"
chk "backup/backup.sh ejecutable" "[ -x backup/backup.sh ]"
chk ".env no trackeado" "! git ls-files .env | grep -q ."

echo ""
echo "Resultado: $pass ✅ / $fail ❌"
[ $fail -eq 0 ] && echo "✅ PROYECTO LISTO PARA DEFENSA" || echo "⚠️  Corregir $fail puntos"
```

### Paso 8: Commit final del proyecto

```bash
# Añadir todos los archivos al repo
git add .
git status

# Commit final
git commit -m "feat: proyecto final completo — plataforma DevOps con GitLab CE"

# Push al repositorio de GitLab
git push origin main

# Verificar que el pipeline corre correctamente en el commit final
echo "Pipeline final iniciado. Ver en: http://localhost/root/proyecto-final/-/pipelines"
```

---

## Preguntas de reflexión

1. El README.md tiene instrucciones de instalación en 3 pasos. Pídele a alguien que no vio el proyecto que lo levante siguiendo solo el README. ¿En qué paso tienen dudas? ¿Qué faltó documentar?

2. El plan de DR define RTO de 2 horas para pérdida total del servidor. ¿Qué parte del proceso toma más tiempo: la restauración del software o la restauración de los datos?

3. Los scripts de backup y restore usan `docker exec` para ejecutar comandos dentro del contenedor. ¿Qué alternativa existiría si el contenedor de GitLab no responde?

4. La documentación de arquitectura muestra todos los componentes en el mismo servidor. ¿Cómo cambiaría el diagrama si migrases GitLab a un servidor y Prometheus/Grafana a otro?

5. Mirando el proyecto completo: ¿Qué fue lo más difícil de implementar? ¿Qué cambiarías si tuvieras una semana más?

---

## Entregables

- [ ] `backup/backup.sh` ejecutado exitosamente con upload a MinIO
- [ ] `backup/restore.sh` creado y documentado
- [ ] `docs/arquitectura.md` con diagrama y tabla de componentes
- [ ] `docs/manual-operaciones.md` con quick start funcional
- [ ] `docs/disaster-recovery.md` con 3 escenarios y RTO/RPO
- [ ] `docs/rbac.md` con la matriz completa de roles
- [ ] `README.md` con instalación en 3 pasos verificada
- [ ] Script de pre-validación ejecutado: todos los checks en ✅
- [ ] Commit final subido al repo de GitLab
- [ ] Demo script ensayado (cronometrado, < 7 minutos para el bloque de demo)

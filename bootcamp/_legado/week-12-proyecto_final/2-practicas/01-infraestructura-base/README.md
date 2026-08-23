# Práctica 01 — Infraestructura Base: Docker Compose Completo

## Objetivo

Levantar toda la infraestructura del proyecto final con Docker Compose: GitLab CE, Runner, Prometheus, Grafana y MinIO. Al final de esta práctica tendrás un entorno completamente funcional donde corren todos los servicios de la plataforma DevOps.

## Requisitos

- Docker Engine 24+ y Docker Compose v2
- Mínimo 8GB RAM disponible (GitLab solo necesita 4-6GB)
- 20GB de espacio en disco libre
- Puertos 80, 443, 2222, 3000, 9000, 9001 disponibles
- Tiempo estimado: 60-90 minutos (incluyendo el tiempo de inicio de GitLab)

---

## Instrucciones

### Paso 1: Crear la estructura del proyecto

```bash
mkdir -p ~/proyecto-final/{ci-templates,monitoring,backup,docs,app/src,app/tests,certs}
cd ~/proyecto-final

# Archivos base
touch .gitignore .env.example .gitlab-ci.yml README.md
touch ci-templates/build.yml ci-templates/test.yml ci-templates/deploy.yml
touch monitoring/prometheus.yml monitoring/grafana-datasources.yml
touch backup/backup.sh backup/restore.sh
touch docs/arquitectura.md docs/manual-operaciones.md docs/disaster-recovery.md

echo ".env" >> .gitignore
echo "certs/" >> .gitignore
echo "*.tar" >> .gitignore
echo "__pycache__/" >> .gitignore

ls -la
```

### Paso 2: Crear el .env y .env.example

```bash
# .env.example (commitear este)
cat > .env.example << 'EOF'
# GitLab CE
GITLAB_VERSION=16.11.0-ce.0
GITLAB_HOSTNAME=gitlab.local
GITLAB_EXTERNAL_URL=http://localhost
HTTP_PORT=80
HTTPS_PORT=443
SSH_PORT=2222
REGISTRY_URL=http://localhost:5050

# Monitoring
GRAFANA_USER=admin
GRAFANA_PASSWORD=cambia-esta-password

# Storage
MINIO_USER=minioadmin
MINIO_PASSWORD=cambia-esta-password
EOF

# .env (NO commitear — valores reales)
cp .env.example .env
# Editar .env con valores reales si es necesario
# Para el lab, los defaults son suficientes

# Verificar que .env está en .gitignore
grep ".env" .gitignore && echo "✅ .env ignorado por git"
```

### Paso 3: Crear docker-compose.yml

```bash
cat > docker-compose.yml << 'COMPOSE'
version: '3.8'

services:
  gitlab:
    image: gitlab/gitlab-ce:${GITLAB_VERSION:-16.11.0-ce.0}
    container_name: gitlab
    restart: unless-stopped
    hostname: ${GITLAB_HOSTNAME:-gitlab.local}
    ports:
      - "${HTTP_PORT:-80}:80"
      - "${HTTPS_PORT:-443}:443"
      - "${SSH_PORT:-2222}:22"
      - "5050:5050"   # Container Registry
    volumes:
      - gitlab-config:/etc/gitlab
      - gitlab-logs:/var/log/gitlab
      - gitlab-data:/var/opt/gitlab
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url '${GITLAB_EXTERNAL_URL:-http://localhost}'
        registry_external_url '${REGISTRY_URL:-http://localhost:5050}'
        gitlab_rails['registry_enabled'] = true
        gitlab_rails['smtp_enable'] = false
        prometheus_monitoring['enable'] = true
        prometheus['listen_address'] = '0.0.0.0:9090'
        grafana['enable'] = false
        puma['worker_processes'] = 2
    networks:
      - gitlab-net
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/-/health"]
      interval: 60s
      timeout: 10s
      retries: 5
      start_period: 120s

  gitlab-runner:
    image: gitlab/gitlab-runner:alpine
    container_name: gitlab-runner
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - runner-config:/etc/gitlab-runner
    networks:
      - gitlab-net
    depends_on:
      gitlab:
        condition: service_healthy

  prometheus:
    image: prom/prometheus:v2.51.0
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
    networks:
      - gitlab-net

  grafana:
    image: grafana/grafana:10.4.2
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=${GRAFANA_USER:-admin}
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD:-admin123}
      - GF_INSTALL_PLUGINS=grafana-piechart-panel
    volumes:
      - grafana-data:/var/lib/grafana
      - ./monitoring/grafana-datasources.yml:/etc/grafana/provisioning/datasources/prometheus.yml:ro
    networks:
      - gitlab-net
    depends_on:
      - prometheus

  minio:
    image: minio/minio:latest
    container_name: minio
    restart: unless-stopped
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - minio-data:/data
    environment:
      - MINIO_ROOT_USER=${MINIO_USER:-minioadmin}
      - MINIO_ROOT_PASSWORD=${MINIO_PASSWORD:-minioadmin123}
    command: server /data --console-address ":9001"
    networks:
      - gitlab-net

volumes:
  gitlab-config:
  gitlab-logs:
  gitlab-data:
  runner-config:
  prometheus-data:
  grafana-data:
  minio-data:

networks:
  gitlab-net:
    name: proyecto-final-net
    driver: bridge
COMPOSE
```

### Paso 4: Crear archivos de monitoreo

```bash
# monitoring/prometheus.yml
cat > monitoring/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'gitlab'
    metrics_path: '/-/metrics'
    static_configs:
      - targets: ['gitlab:80']

  - job_name: 'gitlab-internal'
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job=~"gitlab.*"}'
        - '{__name__=~"sidekiq.*"}'
        - '{__name__=~"pg_.*"}'
    static_configs:
      - targets: ['gitlab:9090']
    honor_labels: true
EOF

# monitoring/grafana-datasources.yml
cat > monitoring/grafana-datasources.yml << 'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
EOF
```

### Paso 5: Levantar la infraestructura

```bash
# Lanzar todos los servicios
docker compose --env-file .env up -d

# Verificar estado inicial
docker compose ps

echo "Esperando que GitLab inicie (puede tardar 3-5 minutos)..."
until curl -sf http://localhost/-/health > /dev/null 2>&1; do
  echo -n "."
  sleep 15
done
echo ""
echo "✅ GitLab disponible"
```

### Paso 6: Primer acceso y configuración inicial

```bash
# Obtener contraseña inicial de root
ROOT_PASSWORD=$(docker exec gitlab cat /etc/gitlab/initial_root_password 2>/dev/null | \
  grep "Password:" | awk '{print $2}')
echo "Contraseña root inicial: $ROOT_PASSWORD"

# Cambiar contraseña via API
NEW_PASSWORD="SuperSecure2024!"
ADMIN_TOKEN="root-token-placeholder"  # Obtener de GitLab UI primero

# 1. Abrir http://localhost en el navegador
# 2. Login: root / (contraseña del paso anterior)
# 3. Admin Area → Overview → Sign-in restrictions → Deshabilitar "Sign-up enabled"
# 4. Admin Area → Settings → General → Account and limit → Default branch: main
```

### Paso 7: Registrar el Runner

```bash
# ¿QUÉ HACE?: Registra el Runner de Docker para que pueda ejecutar jobs de CI/CD
# ¿POR QUÉ?: Sin registro, el Runner no sabe a qué GitLab conectarse ni con qué token
# ¿PARA QUÉ?: Pipeline CI/CD funcional

# 1. Obtener el token de registro en Admin Area → CI/CD → Runners → Register an instance runner
RUNNER_REGISTRATION_TOKEN="TU_TOKEN_AQUI"

docker exec gitlab-runner gitlab-runner register \
  --non-interactive \
  --url "http://gitlab" \
  --registration-token "$RUNNER_REGISTRATION_TOKEN" \
  --executor "docker" \
  --docker-image "python:3.11-slim" \
  --docker-network-mode "proyecto-final-net" \
  --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
  --description "docker-runner-proyecto-final" \
  --tag-list "docker,python,linux"

# Verificar que el runner está online
docker exec gitlab-runner gitlab-runner list
# → Debe mostrar el runner registrado con Alive=true

# En GitLab UI: Admin Area → Runners → verificar que aparece "online"
```

### Paso 8: Crear el bucket de backups en MinIO

```bash
# ¿QUÉ HACE?: Crea el bucket para almacenar backups de GitLab
# ¿POR QUÉ?: Sin el bucket, el script de backup no tiene dónde subir los archivos
# ¿PARA QUÉ?: Almacenamiento offsite de backups (en el lab, MinIO simula S3)

# Esperar que MinIO esté disponible
until curl -sf http://localhost:9000/minio/health/live > /dev/null; do sleep 5; done

# Crear bucket via CLI de MinIO
docker exec minio mc alias set local http://localhost:9000 minioadmin minioadmin123
docker exec minio mc mb local/gitlab-backups
docker exec minio mc ls local/
echo "✅ Bucket gitlab-backups creado en MinIO"

# Acceder a la consola web de MinIO: http://localhost:9001
# Credenciales: minioadmin / minioadmin123
```

### Paso 9: Verificación completa de la infraestructura

```bash
echo "=== Verificación de Infraestructura ==="

# Services
echo ""
echo "1. Estado de servicios:"
docker compose ps --format "table {{.Name}}\t{{.Status}}"

# GitLab
echo ""
echo "2. GitLab health:"
curl -s http://localhost/-/health | python3 -c "import json,sys; d=json.load(sys.stdin); [print(f'  {k}: {v}') for k,v in d.items() if isinstance(v, str)]" 2>/dev/null || \
  curl -s -o /dev/null -w "  HTTP %{http_code}" http://localhost/-/health

# Prometheus
echo ""
echo "3. Prometheus targets:"
curl -s http://localhost:9090/api/v1/targets | \
  python3 -c "
import json,sys
d=json.load(sys.stdin)
for t in d['data']['activeTargets']:
    print(f'  {t[\"labels\"][\"job\"]}: {t[\"health\"]}')
" 2>/dev/null

# Grafana
echo ""
echo "4. Grafana health:"
curl -s http://localhost:3000/api/health | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'  database: {d.get(\"database\", \"ok\")}')" 2>/dev/null

# MinIO
echo ""
echo "5. MinIO buckets:"
docker exec minio mc ls local/ 2>/dev/null

echo ""
echo "=== URLs de acceso ==="
echo "GitLab:   http://localhost"
echo "Grafana:  http://localhost:3000 (admin/admin123)"
echo "Prometheus: http://localhost:9090"
echo "MinIO:    http://localhost:9001 (minioadmin/minioadmin123)"
```

---

## Preguntas de reflexión

1. `docker compose down` borra los contenedores pero no los volúmenes. ¿Cuándo usarías `docker compose down -v`? ¿Qué riesgo implica?

2. El `healthcheck` de GitLab tiene `start_period: 120s`. ¿Qué sucedería si el start_period fuera de 10 segundos en una máquina lenta?

3. Prometheus no puede acceder a GitLab si usan redes Docker diferentes. ¿Cómo verificarías la conectividad entre contenedores desde dentro de la red Docker?

4. MinIO en este lab simula S3. ¿Qué cambiaría en la configuración si usaras AWS S3 real en lugar de MinIO?

5. El Runner usa `/var/run/docker.sock` montado en el contenedor. ¿Qué riesgo de seguridad implica esto? ¿Cuál es la alternativa?

---

## Entregables

- [ ] `docker-compose.yml` creado con los 5 servicios (GitLab, Runner, Prometheus, Grafana, MinIO)
- [ ] `.env.example` con todas las variables documentadas
- [ ] `.env` no aparece en `git ls-files` (verificado con `git status`)
- [ ] `docker compose ps` muestra todos los servicios UP y healthy
- [ ] GitLab accesible en http://localhost — login exitoso como root
- [ ] Runner registrado y visible como "online" en Admin Area → Runners
- [ ] Prometheus accesible en http://localhost:9090 con al menos 1 target "up"
- [ ] Grafana accesible en http://localhost:3000 con datasource Prometheus configurado
- [ ] Bucket `gitlab-backups` creado en MinIO
- [ ] Sign-up público deshabilitado en GitLab

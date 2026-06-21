# Práctica 03 — Seguridad y Monitoreo

## Objetivo

Completar la seguridad del pipeline y configurar el monitoreo con Prometheus + Grafana.

## Instrucciones

### Seguridad

#### Paso 1: Verificar escaneos de seguridad

Asegúrate de que los siguientes templates estén incluidos en tu `.gitlab-ci.yml`:
```yaml
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml
```

Ejecuta un pipeline y verifica en Security → Vulnerability Report que aparezcan hallazgos.

#### Paso 2: Configurar Container Scanning

Agrega las variables para que Container Scanning escanee la imagen que construiste:
```yaml
container-scanning:
  variables:
    CS_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
    CS_DOCKERFILE_PATH: Dockerfile
```

#### Paso 3: Configurar RBAC

Crea los siguientes usuarios y roles:
- `devops-admin`: Owner del grupo raíz
- `developer-1`: Developer en el proyecto de la app
- `viewer`: Reporter en el proyecto (solo lectura)

Documenta la matriz de permisos en `docs/rbac.md`.

#### Paso 4: Habilitar MFA

- Habilita MFA en tu cuenta de administrador
- Desde Admin Area, fuerza MFA para todos los usuarios
- Verifica que `viewer` sea redirigido a configurar MFA al iniciar sesión

### Monitoreo

#### Paso 5: Agregar Prometheus y Grafana al docker-compose.yml

```yaml
prometheus:
  image: prom/prometheus:v2.51.0
  container_name: prometheus
  volumes:
    - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
    - prometheus-data:/prometheus
  command:
    - '--config.file=/etc/prometheus/prometheus.yml'
    - '--storage.tsdb.path=/prometheus'
  ports:
    - "9090:9090"
  networks:
    - gitlab-net

grafana:
  image: grafana/grafana:10.4.0
  container_name: grafana
  environment:
    - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD:-admin}
  volumes:
    - grafana-data:/var/lib/grafana
    - ./monitoring/grafana-datasources.yml:/etc/grafana/provisioning/datasources/prometheus.yml
  ports:
    - "3000:3000"
  networks:
    - gitlab-net
```

#### Paso 6: Configurar Prometheus

`monitoring/prometheus.yml`:
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'gitlab'
    metrics_path: '/-/metrics'
    static_configs:
      - targets: ['gitlab:80']
```

#### Paso 7: Crear dashboard en Grafana

1. Accede a http://localhost:3000 (admin/admin)
2. Agrega Prometheus como datasource (URL: `http://prometheus:9090`)
3. Importa dashboard ID 20916 (GitLab Omnibus)
4. Crea un panel personalizado con métricas de tu app

## Verificación

- [ ] SAST reporta vulnerabilidades en el Security Dashboard
- [ ] Secret Detection se ejecuta sin errores
- [ ] Container Scanning analiza tu imagen Docker
- [ ] RBAC documentado con 3 roles distintos
- [ ] MFA funciona al iniciar sesión
- [ ] `curl http://localhost:9090` responde OK
- [ ] `curl http://localhost:3000` responde OK
- [ ] Dashboard Grafana muestra métricas de GitLab

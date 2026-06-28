# Práctica 03 — Seguridad y Monitoreo Integrado

## Objetivo

Completar el stack de seguridad del proyecto: revisar y gestionar los hallazgos del Security Dashboard, implementar RBAC con tres roles, habilitar y verificar MFA, integrar Grafana con dashboards de GitLab y configurar alertas operacionales. Al final, la plataforma tiene seguridad en profundidad y observabilidad completa.

## Requisitos

- Prácticas 01 y 02 completadas (infraestructura + pipeline funcionando)
- Pipeline con SAST y Secret Detection ya ejecutado (necesario para tener hallazgos)
- Tiempo estimado: 60-75 minutos

---

## Instrucciones

### Paso 1: Revisar el Security Dashboard

```bash
# ¿QUÉ HACE?: Consulta los hallazgos de seguridad del proyecto via API
# ¿POR QUÉ?: El Security Dashboard en GitLab CE solo muestra el último pipeline
# ¿PARA QUÉ?: Auditar vulnerabilidades detectadas por SAST antes de ir a producción

ADMIN_TOKEN="TU_TOKEN"
PROJECT_ID=1

# Ver vulnerabilidades detectadas por SAST
curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/vulnerability_findings?per_page=20" | \
  jq '.[] | {
    severity,
    name,
    scanner: .scanner.name,
    location: "\(.location.file // "?"):\(.location.start_line // "?")"
  }'
```

En GitLab UI: navegar a **Security → Vulnerability Report**. Deben aparecer al menos 3-4 hallazgos de la app Flask (MD5, SQL format string, subprocess, hardcoded password).

Para cada hallazgo, elegir una acción de triaje:
- **Confirm**: vulnerabilidad real que hay que corregir
- **Dismiss**: falso positivo con justificación documentada
- **Resolve**: ya fue corregida

```bash
# Descartar un hallazgo como falso positivo via API
VULNERABILITY_ID=1  # ID del hallazgo (ver en la URL de GitLab UI)

curl -s --request POST \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "state": "dismissed",
    "comment": "Código de demo intencional para mostrar SAST — no es código de producción"
  }' \
  "http://localhost/api/v4/projects/$PROJECT_ID/vulnerabilities/$VULNERABILITY_ID/dismiss"
```

### Paso 2: Implementar Container Scanning y Dependency Scanning

```bash
# Verificar que los scans corren en el pipeline
curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines?per_page=1" | jq '.[0].id'

PIPELINE_ID=1  # ID del último pipeline

curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines/$PIPELINE_ID/jobs" | \
  jq '.[] | select(.name | test("scan|sast|detect|secret")) | {name, status, duration}'

# Descargar el reporte SAST como artefacto
JOB_ID=$(curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines/$PIPELINE_ID/jobs" | \
  jq '.[] | select(.name == "bandit-sast") | .id')

curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/jobs/$JOB_ID/artifacts/gl-sast-report.json" | \
  jq '{total: (.vulnerabilities | length), by_severity: [.vulnerabilities[] | .severity] | group_by(.) | map({(.[0]): length}) | add}'
```

### Paso 3: Configurar RBAC con tres roles

```bash
# ¿QUÉ HACE?: Crea grupo, usuarios y asigna roles apropiados
# ¿POR QUÉ?: RBAC garantiza que cada persona tiene exactamente los permisos necesarios
# ¿PARA QUÉ?: Principio de mínimo privilegio en la plataforma DevOps

# Crear grupo de la organización
GROUP_ID=$(curl -s --request POST \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "DevOps Team",
    "path": "devops-team",
    "visibility": "private",
    "description": "Grupo principal de DevOps"
  }' \
  "http://localhost/api/v4/groups" | jq '.id')

echo "Grupo creado: ID $GROUP_ID"

# Crear tres usuarios con roles distintos
declare -A USERS=(
  ["devops-admin"]="50"   # Owner — gestiona plataforma
  ["developer1"]="30"     # Developer — desarrolla y hace deploy
  ["viewer"]="20"         # Reporter — solo lectura
)

for USERNAME in "${!USERS[@]}"; do
  ACCESS_LEVEL="${USERS[$USERNAME]}"
  
  # Crear usuario
  USER_RESP=$(curl -s --request POST \
    --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{
      \"username\": \"$USERNAME\",
      \"name\": \"User $USERNAME\",
      \"email\": \"$USERNAME@lab.local\",
      \"password\": \"BootcampLab2024!\",
      \"skip_confirmation\": true
    }" \
    "http://localhost/api/v4/users")
  
  USER_ID=$(echo "$USER_RESP" | jq '.id')
  echo "Usuario $USERNAME creado (ID: $USER_ID)"
  
  # Asignar al grupo con el rol correspondiente
  curl -s --request POST \
    --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{\"user_id\": $USER_ID, \"access_level\": $ACCESS_LEVEL}" \
    "http://localhost/api/v4/groups/$GROUP_ID/members" | \
    jq '{username: .username, access_level, access_level_name: (
      if .access_level == 50 then "Owner"
      elif .access_level == 40 then "Maintainer"
      elif .access_level == 30 then "Developer"
      elif .access_level == 20 then "Reporter"
      else "Guest"
      end
    )}'
done

# Verificar la matriz de roles
echo ""
echo "=== Matriz RBAC ==="
curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/groups/$GROUP_ID/members" | \
  jq '.[] | {username, access_level}'
```

### Paso 4: Documentar la matriz RBAC

```bash
cat > docs/rbac.md << 'EOF'
# Matriz RBAC — Proyecto Final DevOps

## Estructura de Roles

| Usuario | Rol | Nivel | Puede hacer |
|---------|-----|:-----:|-------------|
| `devops-admin` | Owner | 50 | Todo: gestionar miembros, configurar CI/CD, cambiar visibilidad |
| `developer1` | Developer | 30 | Push a branches no protegidos, crear MRs, ejecutar pipelines |
| `viewer` | Reporter | 20 | Ver código, issues y pipelines; clonar (sin push) |

## Ramas Protegidas

| Rama | Push mínimo | Merge mínimo |
|------|:-----------:|:------------:|
| `main` | Maintainer | Maintainer |
| `release/*` | Developer | Maintainer |

## Tokens y Acceso de Servicio

| Token | Scope | Expira | Propósito |
|-------|-------|:------:|----------|
| `ci-registry-token` | write_registry | 90 días | Pipeline: subir imágenes al Registry |

## Revisión de Acceso

Esta matriz debe revisarse cada 90 días. Usuarios sin actividad en 60+ días son candidatos para remoción.
EOF

echo "✅ Matriz RBAC documentada en docs/rbac.md"
```

### Paso 5: Habilitar y verificar MFA

```bash
# ¿QUÉ HACE?: Fuerza MFA para todos los usuarios con período de gracia
# ¿POR QUÉ?: MFA es la defensa más efectiva contra contraseñas comprometidas
# ¿PARA QUÉ?: Cumplimiento de seguridad básico — ninguna cuenta sin segundo factor

# Habilitar MFA requerido (24 horas de gracia)
curl -s --request PUT \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "require_two_factor_authentication": true,
    "two_factor_grace_period": 24
  }' \
  "http://localhost/api/v4/application/settings" | \
  jq '{require_two_factor_authentication, two_factor_grace_period}'

# Verificar usuarios sin MFA configurado
echo ""
echo "=== Usuarios sin MFA ==="
curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/users?two_factor=disabled&per_page=100" | \
  jq '.[] | {username, two_factor_enabled}'

# Para verificar que el comportamiento es correcto:
# 1. Abrir sesión como developer1 en modo incógnito
# 2. Debe mostrar aviso de "MFA requerido en 24 horas"
# 3. Intentar configurar un TOTP app (Google Authenticator, Authy)
# 4. Después de las 24h, al login sin MFA se bloqueará el acceso
```

### Paso 6: Integrar Grafana con dashboards de GitLab

```bash
GRAFANA_URL="http://localhost:3000"
GRAFANA_AUTH="admin:admin123"

# Verificar que el datasource de Prometheus está configurado
curl -s --user "$GRAFANA_AUTH" \
  "$GRAFANA_URL/api/datasources" | \
  jq '.[0] | {name, type, url, isDefault}'

# Importar dashboard de GitLab Omnibus desde Grafana.com
echo "Descargando dashboard GitLab..."
curl -s "https://grafana.com/api/dashboards/20916/revisions/latest/download" \
  -o /tmp/gitlab-dashboard.json 2>/dev/null && \
  echo "✅ Dashboard descargado" || \
  echo "⚠️  Sin acceso a internet — usar dashboard manual abajo"

# Importar el dashboard
if [ -f /tmp/gitlab-dashboard.json ]; then
  curl -s --request POST \
    --header "Content-Type: application/json" \
    --user "$GRAFANA_AUTH" \
    --data "{\"dashboard\": $(cat /tmp/gitlab-dashboard.json), \"folderId\": 0, \"overwrite\": true}" \
    "$GRAFANA_URL/api/dashboards/db" | jq '{status, slug}'
fi
```

### Paso 7: Crear panel personalizado de operaciones

```bash
# ¿QUÉ HACE?: Crea un dashboard personalizado con las métricas clave de operaciones
# ¿POR QUÉ?: Los dashboards genéricos tienen demasiada información; este es específico
# ¿PARA QUÉ?: Vista ejecutiva que muestra el SLA de la plataforma en tiempo real

cat > /tmp/ops-dashboard.json << 'JSON'
{
  "dashboard": {
    "title": "GitLab Operations — Proyecto Final",
    "tags": ["gitlab", "operations", "bootcamp"],
    "timezone": "browser",
    "refresh": "30s",
    "panels": [
      {
        "title": "HTTP Requests/sec",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
        "targets": [{"expr": "rate(gitlab_rails_requests_total[5m])", "legendFormat": "req/s"}]
      },
      {
        "title": "Sidekiq Queue Size",
        "type": "stat",
        "gridPos": {"h": 4, "w": 6, "x": 12, "y": 0},
        "targets": [{"expr": "sum(sidekiq_queue_size)", "legendFormat": "Jobs en cola"}]
      },
      {
        "title": "GitLab UP",
        "type": "stat",
        "gridPos": {"h": 4, "w": 6, "x": 18, "y": 0},
        "targets": [{"expr": "up{job=\"gitlab\"}", "legendFormat": "Status"}]
      }
    ],
    "schemaVersion": 38
  },
  "folderId": 0,
  "overwrite": true
}
JSON

curl -s --request POST \
  --header "Content-Type: application/json" \
  --user "$GRAFANA_AUTH" \
  --data @/tmp/ops-dashboard.json \
  "$GRAFANA_URL/api/dashboards/db" | jq '{status, url}'
```

### Paso 8: Configurar alerta de backup en Prometheus

```bash
# Crear regla de alerta para backup antiguo
mkdir -p monitoring/rules

cat > monitoring/rules/gitlab-alerts.yml << 'EOF'
groups:
  - name: gitlab-operations
    rules:
      - alert: GitLabDown
        expr: up{job="gitlab"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "GitLab no responde"

      - alert: SidekiqBacklog
        expr: sum(sidekiq_queue_size) > 200
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Cola Sidekiq con {{ $value }} jobs"

      - alert: DiskSpaceHigh
        expr: |
          (node_filesystem_size_bytes{mountpoint="/"} -
           node_filesystem_avail_bytes{mountpoint="/"}) /
          node_filesystem_size_bytes{mountpoint="/"} > 0.85
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Disco al {{ $value | humanizePercentage }}"
EOF

# Recargar configuración de Prometheus
curl -s -X POST http://localhost:9090/-/reload && echo "✅ Alertas cargadas"

# Verificar en Prometheus UI: http://localhost:9090/rules
echo "Ver reglas en: http://localhost:9090/rules"
```

### Paso 9: Verificación completa de seguridad y monitoreo

```bash
echo "=== Verificación Final de Seguridad y Monitoreo ==="

# 1. SAST tiene hallazgos
VULN_COUNT=$(curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/vulnerability_findings" | jq 'length')
echo "1. Vulnerabilidades SAST: $VULN_COUNT hallazgos"
[ "$VULN_COUNT" -gt 0 ] && echo "   ✅ SAST funcionando" || echo "   ⚠️  Sin hallazgos (verificar pipeline)"

# 2. MFA requerido
MFA_REQUIRED=$(curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/application/settings" | jq '.require_two_factor_authentication')
echo "2. MFA requerido: $MFA_REQUIRED"
[ "$MFA_REQUIRED" = "true" ] && echo "   ✅ MFA activo" || echo "   ❌ MFA no activo"

# 3. Miembros del grupo con roles correctos
echo "3. Miembros del grupo DevOps:"
curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/groups/$GROUP_ID/members" | \
  jq '.[] | "   \(.username): nivel \(.access_level)"' -r

# 4. Prometheus scraping GitLab
UP=$(curl -s "http://localhost:9090/api/v1/query?query=up{job=\"gitlab\"}" | \
  jq -r '.data.result[0].value[1] // "0"')
echo "4. GitLab en Prometheus: up=$UP"
[ "$UP" = "1" ] && echo "   ✅ Scraping activo" || echo "   ⚠️  GitLab no en Prometheus"

# 5. Dashboard Grafana
DASH_COUNT=$(curl -s --user "$GRAFANA_AUTH" \
  "$GRAFANA_URL/api/search?type=dash-db" | jq 'length')
echo "5. Dashboards en Grafana: $DASH_COUNT"
[ "$DASH_COUNT" -gt 0 ] && echo "   ✅ Dashboards importados" || echo "   ❌ Sin dashboards"

# 6. Alertas definidas en Prometheus
ALERT_COUNT=$(curl -s "http://localhost:9090/api/v1/rules" | jq '.data.groups | length')
echo "6. Grupos de alertas en Prometheus: $ALERT_COUNT"
```

---

## Preguntas de reflexión

1. La app Flask tiene 4 vulnerabilidades intencionales. ¿Cuáles de ellas son "críticas" según CVSS? ¿Cuáles son más fáciles de explotar en un entorno de producción real?

2. El `two_factor_grace_period` está en 24 horas. ¿Qué sucede si un atacante crea una cuenta justo antes de que se active MFA? ¿Existe una ventana de vulnerabilidad?

3. El usuario `viewer` (Reporter) puede clonar el repositorio pero no hacer push. Sin embargo, si el pipeline corre código del repo, ¿podría `viewer` modificar el pipeline para exfiltrar secrets?

4. Prometheus está accesible en http://localhost:9090 sin autenticación. ¿Qué información de seguridad podría obtener un atacante con acceso a Prometheus? ¿Cómo protegerías este endpoint?

5. Las alertas de Prometheus solo envían notificaciones si tienes Alertmanager configurado. En este proyecto no lo configuramos. ¿Cómo sabrías si una alerta se disparó?

---

## Entregables

- [ ] Security Dashboard con al menos 3 hallazgos de SAST visibles
- [ ] Al menos 1 hallazgo con estado "dismissed" o "confirmed" con justificación
- [ ] Grupo "DevOps Team" con 3 usuarios en roles diferentes (Owner/Developer/Reporter)
- [ ] `docs/rbac.md` con la matriz completa
- [ ] MFA requerido activado (verificable en Settings → General)
- [ ] Prometheus scrapeando GitLab (`up{job="gitlab"}=1` en Prometheus)
- [ ] Grafana con al menos 1 dashboard con datos reales de GitLab
- [ ] Dashboard de operaciones personalizado creado (mínimo 3 paneles)
- [ ] Reglas de alerta definidas en `monitoring/rules/gitlab-alerts.yml`

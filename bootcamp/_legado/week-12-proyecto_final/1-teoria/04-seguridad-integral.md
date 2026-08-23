# 04 — Stack de Seguridad Integral

La seguridad en el proyecto final cubre cuatro dimensiones: pipeline (código y artefactos), plataforma (GitLab en sí), acceso (quién puede hacer qué) y datos (backups y secretos). Un proyecto que funciona pero no tiene seguridad es un proyecto incompleto.

---

## Seguridad en Pipeline

### Templates de seguridad CE

```yaml
# ¿QUÉ HACE?: Incluye los 4 templates de seguridad disponibles en GitLab CE
# ¿POR QUÉ?: Los templates configuran automáticamente el analyzer correcto para el lenguaje
# ¿PARA QUÉ?: Detectar vulnerabilidades en código, secretos, imágenes y dependencias antes del deploy
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
```

SAST elige el analyzer automáticamente según los archivos del repo:

| Lenguaje | Analyzer | Detecta |
|----------|----------|---------|
| Python | Bandit | Inyección SQL, eval(), subprocess, MD5/SHA1 inseguros |
| JavaScript/TS | ESLint-SAST | XSS, prototype pollution, insecure regexps |
| Ruby | Brakeman | Rails CSRF, SQL injection, mass assignment |
| Go | Gosec | SQL injection, rand inseguro, path traversal |
| Java | SpotBugs | SQL injection, XXE, SSRF |

### Umbrales de seguridad en MRs

En GitLab CE no hay bloqueo automático de MRs por vulnerabilidades (eso es EE). La alternativa en CE es un job explícito que falla si hay críticos:

```yaml
# ¿QUÉ HACE?: Job que falla si el reporte SAST contiene vulnerabilidades críticas
# ¿POR QUÉ?: En CE no hay merge checks automáticos por seguridad — lo reemplazamos con un job
# ¿PARA QUÉ?: Bloquear el pipeline si hay una vulnerabilidad crítica no reconocida

security-gate:
  stage: security
  image: python:3.11-slim
  needs:
    - job: semgrep-sast
      artifacts: true
  script:
    - |
      python3 << 'PYTHON'
      import json, sys

      try:
          with open('gl-sast-report.json') as f:
              report = json.load(f)
      except FileNotFoundError:
          print("No SAST report found — skipping gate")
          sys.exit(0)

      critical = [v for v in report.get('vulnerabilities', [])
                  if v.get('severity') == 'Critical']

      if critical:
          print(f"❌ {len(critical)} vulnerabilidades CRÍTICAS encontradas:")
          for v in critical:
              print(f"  - {v['message']} en {v['location'].get('file', '?')}:{v['location'].get('start_line', '?')}")
          sys.exit(1)
      print("✅ Sin vulnerabilidades críticas")
      PYTHON
  rules:
    - if: $CI_COMMIT_BRANCH == "main" || $CI_MERGE_REQUEST_IID
```

### Verificación de secretos en el historial

```bash
# ¿QUÉ HACE?: Busca secretos que pudieran haberse commiteado antes de activar Secret Detection
# ¿POR QUÉ?: Secret Detection solo protege commits futuros, no el historial
# ¿PARA QUÉ?: Auditar el repo antes de hacerlo público o antes del proyecto final

# Scan histórico (ejecutar localmente o en un job)
HISTORIC_SAST_SCAN_MODE=historic  # Variable para Secret Detection en modo histórico

# Via truffleHog (alternativa local)
docker run --rm \
  -v "$(pwd):/app" \
  trufflesecurity/trufflehog:latest \
  git file:///app --since-commit HEAD~50 --only-verified
```

---

## Seguridad de Plataforma

### HTTPS con certificado auto-firmado

Para el laboratorio, HTTPS con certificado auto-firmado:

```bash
# ¿QUÉ HACE?: Genera certificado auto-firmado para GitLab CE en Docker
# ¿POR QUÉ?: HTTPS aunque sea con cert auto-firmado es mejor que HTTP plano
# ¿PARA QUÉ?: Practicar la configuración de TLS sin depender de un dominio real

mkdir -p certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/gitlab.key \
  -out certs/gitlab.crt \
  -subj "/CN=gitlab.local/O=Lab/C=ES" \
  -addext "subjectAltName=DNS:gitlab.local,IP:127.0.0.1"

# Copiar al volumen de configuración de GitLab
docker cp certs/gitlab.crt gitlab:/etc/gitlab/ssl/gitlab.local.crt
docker cp certs/gitlab.key gitlab:/etc/gitlab/ssl/gitlab.local.key

# Configurar en gitlab.rb (añadir a GITLAB_OMNIBUS_CONFIG):
# external_url 'https://gitlab.local'
# nginx['ssl_certificate'] = '/etc/gitlab/ssl/gitlab.local.crt'
# nginx['ssl_certificate_key'] = '/etc/gitlab/ssl/gitlab.local.key'
```

### Puertos expuestos vs red interna

En `docker-compose.yml`, solo exponer al host lo estrictamente necesario:

| Servicio | Puerto host | Puerto contenedor | ¿Por qué exponer? |
|---------|:-----------:|:-----------------:|-------------------|
| GitLab | 80, 443 | 80, 443 | Acceso de usuarios |
| GitLab SSH | 2222 | 22 | Git over SSH |
| Grafana | 3000 | 3000 | Dashboards operacionales |
| MinIO Console | 9001 | 9001 | Gestión de backups |
| **PostgreSQL** | ❌ no exponer | 5432 | Solo interno |
| **Redis** | ❌ no exponer | 6379 | Solo interno |
| **Prometheus** | ❌ no exponer | 9090 | Solo Grafana lo necesita |

---

## Seguridad de Acceso (RBAC + MFA)

### Estructura de roles para el proyecto

```bash
# ¿QUÉ HACE?: Crea la estructura de grupos y usuarios con roles apropiados
# ¿POR QUÉ?: El principio de mínimo privilegio aplica incluso en un lab
# ¿PARA QUÉ?: Demostrar en la defensa que entiendes la gestión de accesos

GITLAB_URL="http://localhost"
ADMIN_TOKEN="$GITLAB_ROOT_TOKEN"

# Crear grupo de la organización
GROUP_ID=$(curl -s --request POST \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"name": "TechCorp", "path": "techcorp", "visibility": "private"}' \
  "$GITLAB_URL/api/v4/groups" | jq '.id')

# Crear usuarios de demo
for user_data in \
  '{"username":"devops-admin","name":"DevOps Admin","email":"admin@lab.local","password":"Password123!","skip_confirmation":true}' \
  '{"username":"developer1","name":"Developer One","email":"dev1@lab.local","password":"Password123!","skip_confirmation":true}' \
  '{"username":"viewer","name":"Read Only","email":"viewer@lab.local","password":"Password123!","skip_confirmation":true}'; do

  USER_ID=$(curl -s --request POST \
    --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    --header "Content-Type: application/json" \
    --data "$user_data" \
    "$GITLAB_URL/api/v4/users" | jq '.id')

  echo "Usuario creado: ID $USER_ID"
done

# Asignar roles en el grupo (access_level: 50=Owner, 40=Maintainer, 30=Developer, 20=Reporter)
ROLES=(
  "devops-admin:50"  # Owner
  "developer1:30"    # Developer
  "viewer:20"        # Reporter
)

for role_assignment in "${ROLES[@]}"; do
  USERNAME="${role_assignment%%:*}"
  LEVEL="${role_assignment##*:}"
  
  USER_ID=$(curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    "$GITLAB_URL/api/v4/users?username=$USERNAME" | jq '.[0].id')
  
  curl -s --request POST \
    --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{\"user_id\": $USER_ID, \"access_level\": $LEVEL}" \
    "$GITLAB_URL/api/v4/groups/$GROUP_ID/members" | jq '{username: .username, access_level}'
done
```

### MFA enforcement

```bash
# ¿QUÉ HACE?: Fuerza MFA para todos los usuarios de la instancia
# ¿POR QUÉ?: Sin MFA, una contraseña comprometida es suficiente para acceder a todos los repos
# ¿PARA QUÉ?: Cumplimiento de políticas de seguridad básicas

# Habilitar MFA requerido via API (Admin Area)
curl -s --request PUT \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"require_two_factor_authentication": true, "two_factor_grace_period": 24}' \
  "$GITLAB_URL/api/v4/application/settings" | \
  jq '{require_two_factor_authentication, two_factor_grace_period}'

# Verificar usuarios sin MFA (para auditoría)
curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "$GITLAB_URL/api/v4/users?two_factor=disabled&per_page=100" | \
  jq '.[] | {id, username, two_factor_enabled}'
```

### Auditoría de tokens activos

```bash
# ¿QUÉ HACE?: Lista todos los PATs activos con su fecha de expiración
# ¿POR QUÉ?: Tokens sin expiración son un riesgo permanente si se filtran
# ¿PARA QUÉ?: Política de rotación de tokens (todos deben expirar en < 90 días)

curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "$GITLAB_URL/api/v4/personal_access_tokens?state=active&per_page=100" | \
  jq '.[] | {
    id,
    name,
    user_id,
    expires_at: (.expires_at // "SIN EXPIRACIÓN ⚠️"),
    scopes
  }' | grep -A5 "SIN EXPIRACIÓN" | head -30
```

---

## Seguridad de Datos

### Backup de gitlab-secrets.json

```bash
# ¿QUÉ HACE?: Hace backup del archivo de secretos separado del backup automático de GitLab
# ¿POR QUÉ?: gitlab-backup create NO incluye gitlab-secrets.json
# ¿PARA QUÉ?: Sin este archivo, las variables CI/CD encriptadas y los 2FA tokens son irrecuperables

# Copiar desde el volumen Docker
docker cp gitlab:/etc/gitlab/gitlab-secrets.json ./backup-secrets/gitlab-secrets.json.$(date +%Y%m%d)
docker cp gitlab:/etc/gitlab/gitlab.rb ./backup-secrets/gitlab.rb.$(date +%Y%m%d)

# Verificar que el archivo existe y tiene contenido
ls -lah ./backup-secrets/
echo "Secretos respaldados. Guardar en gestor de secretos (Vault/Bitwarden), NUNCA en git."

# En producción real: cifrar antes de almacenar
openssl enc -aes-256-cbc -pbkdf2 \
  -in ./backup-secrets/gitlab-secrets.json.$(date +%Y%m%d) \
  -out ./backup-secrets/gitlab-secrets.json.$(date +%Y%m%d).enc \
  -pass pass:${BACKUP_ENCRYPTION_KEY}
```

### Variables CI/CD: protegidas vs enmascaradas

| Característica | Protegida | Enmascarada |
|----------------|:---------:|:-----------:|
| Solo accesible en ramas protegidas | ✅ | ❌ |
| Valor oculto en logs | ❌ | ✅ |
| Visible en la UI de Settings | ✅ con permiso | ❌ nunca |
| Accesible desde forks | ❌ | ✅ si no protegida |

Las variables con credenciales (tokens, contraseñas, SSH keys) deben ser **ambas**: protegidas Y enmascaradas.

---

## Checklist de seguridad pre-entrega

```bash
# ¿QUÉ HACE?: Verifica los puntos de seguridad críticos del proyecto final
# ¿POR QUÉ?: Un error de seguridad básico en la demo genera una mala impresión
# ¿PARA QUÉ?: Asegurar que el proyecto cumple los criterios de evaluación de seguridad

echo "=== Checklist de Seguridad - Proyecto Final ==="

# 1. ¿.env está en .gitignore?
git ls-files .env > /dev/null 2>&1 && echo "❌ .env está trackeado" || echo "✅ .env no trackeado"

# 2. ¿SAST corre en el pipeline?
PIPELINE_ID=$(curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines?per_page=1" | jq '.[0].id')
curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines/$PIPELINE_ID/jobs" | \
  jq '.[] | select(.name | test("sast|bandit|semgrep")) | .name + ": " + .status' | \
  head -3

# 3. ¿MFA está habilitado?
curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/application/settings" | \
  jq '.require_two_factor_authentication' | \
  grep -q "true" && echo "✅ MFA requerido" || echo "❌ MFA no requerido"

# 4. ¿gitlab-secrets.json tiene backup?
[ -f ./backup-secrets/gitlab-secrets.json.* ] && echo "✅ Secretos respaldados" || echo "❌ Sin backup de secretos"

# 5. ¿Puertos innecesarios expuestos?
docker compose ps --format json | jq -r '.[] | .Publishers[]? | "\(.URL) → \(.TargetPort)"' | sort
echo "Verificar que PostgreSQL (5432) y Redis (6379) NO aparecen en la lista anterior"
```

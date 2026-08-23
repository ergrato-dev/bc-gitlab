# Práctica 03 — Security Scanning: SAST, Secret Detection y Dependency Scanning

## Objetivo

Implementar un pipeline completo de seguridad en GitLab CE con SAST, Secret Detection y Dependency Scanning. Introducir vulnerabilidades y secretos de prueba, analizar los resultados y configurar un security gate que bloquee merges con vulnerabilidades críticas.

## Requisitos

- GitLab CE con un runner registrado y funcional
- Un proyecto con código en Python o JavaScript (o cualquier lenguaje soportado)
- Docker disponible en el runner (los analizadores corren en contenedores)
- Tiempo estimado: 45-60 minutos (los jobs de SAST pueden tardar 2-5 minutos la primera vez)

---

## Instrucciones

### Paso 1: Preparar el repositorio de práctica

Crea un nuevo proyecto `security-scan-lab` con código Python vulnerable:

```bash
# Estructura del proyecto
mkdir security-scan-lab && cd security-scan-lab
git init
git remote add origin http://localhost/tu-grupo/security-scan-lab.git
```

Crea la estructura de archivos:

**`app.py`** — API simple con vulnerabilidades intencionales:
```python
import pickle
import subprocess
import hashlib
import sqlite3
from flask import Flask, request, jsonify

app = Flask(__name__)

# Vulnerabilidad 1: SQL Injection (CWE-89)
@app.route('/users')
def get_users():
    username = request.args.get('username', '')
    conn = sqlite3.connect('users.db')
    # VULNERABLE: concatenación directa de input del usuario
    query = "SELECT * FROM users WHERE username = '" + username + "'"
    result = conn.execute(query).fetchall()
    return jsonify(result)

# Vulnerabilidad 2: Deserialización insegura (CWE-502)
@app.route('/load', methods=['POST'])
def load_data():
    data = request.get_data()
    # VULNERABLE: pickle.loads con datos del usuario
    obj = pickle.loads(data)
    return jsonify({'loaded': str(obj)})

# Vulnerabilidad 3: Command injection (CWE-78)
@app.route('/ping')
def ping():
    host = request.args.get('host', 'localhost')
    # VULNERABLE: input del usuario directo en shell command
    result = subprocess.run(f"ping -c 1 {host}", shell=True, capture_output=True)
    return result.stdout.decode()

# Vulnerabilidad 4: Contraseña hardcodeada (CWE-798)
DB_PASSWORD = "admin123"  # B105: hardcoded password
API_KEY = "sk-prod-secret-key-do-not-share"  # Secreto en código

# Vulnerabilidad 5: Hash débil (CWE-327)
def hash_password(password):
    # VULNERABLE: MD5 es criptográficamente débil para contraseñas
    return hashlib.md5(password.encode()).hexdigest()

if __name__ == '__main__':
    app.run(debug=True)  # B201: debug=True en producción
```

**`requirements.txt`** — dependencias con versiones vulnerables:
```
flask==2.0.0
requests==2.27.0
PyYAML==5.4.1
Pillow==9.1.0
```

**`.env.example`** — secretos de ejemplo para Secret Detection:
```bash
# Variables de entorno de la aplicación
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
GITHUB_TOKEN=ghp_16C7e42F292c6912E7710c838347Ae178B4a
GITLAB_TOKEN=glpat-XXXXXXXXXXXXXXXXXXXX
STRIPE_SECRET_KEY=sk_live_TU_CLAVE_STRIPE_AQUI_NO_ES_REAL
DATABASE_URL=postgresql://admin:supersecret@db.company.com:5432/proddb
JWT_SECRET=my-super-secret-jwt-signing-key-2024
```

```bash
# Añadir archivos al repo
git add app.py requirements.txt .env.example
git commit -m "feat: initial vulnerable app for security testing"
```

### Paso 2: Crear el pipeline con todos los escaneos

**`.gitlab-ci.yml`** — pipeline completo de seguridad:

```yaml
stages:
  - test
  - security
  - security-gate

# Incluir todos los templates de seguridad disponibles en CE
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml

# Variables globales de configuración
variables:
  # SAST
  SAST_EXCLUDED_PATHS: "spec,test,tests,tmp,venv,.venv"
  
  # Secret Detection
  SECRET_DETECTION_HISTORIC_SCAN: "true"  # Primera vez: escanear historial completo
  
  # Dependency Scanning
  DS_EXCLUDED_PATHS: "spec,test"

# Test unitario básico (placeholder)
unit-test:
  stage: test
  image: python:3.11-slim
  before_script:
    - pip install pytest flask --quiet
  script:
    - echo "No hay tests unitarios en este lab. En producción, los tests van aquí."
  allow_failure: true

# Security Gate: falla si hay vulnerabilidades críticas o secretos
security-gate:
  stage: security-gate
  image: alpine:3.19
  needs:
    - job: semgrep-sast
      artifacts: true
    - job: secret_detection
      artifacts: true
  before_script:
    - apk add --no-cache jq
  script:
    - |
      echo "=== SECURITY GATE ==="
      
      CRITICAL=0
      HIGH=0
      SECRETS=0
      
      # Contar vulnerabilidades críticas en SAST
      if [ -f gl-sast-report.json ]; then
        CRITICAL=$(jq '[.vulnerabilities[] | select(.severity == "Critical")] | length' gl-sast-report.json)
        HIGH=$(jq '[.vulnerabilities[] | select(.severity == "High")] | length' gl-sast-report.json)
        echo "SAST → Critical: $CRITICAL, High: $HIGH"
      else
        echo "Advertencia: gl-sast-report.json no encontrado"
      fi
      
      # Contar secretos detectados
      if [ -f gl-secret-detection-report.json ]; then
        SECRETS=$(jq '.vulnerabilities | length' gl-secret-detection-report.json)
        echo "Secret Detection → Secretos encontrados: $SECRETS"
      fi
      
      # Evaluación del gate
      echo ""
      if [ "$CRITICAL" -gt "0" ] || [ "$SECRETS" -gt "0" ]; then
        echo "❌ SECURITY GATE FAILED"
        [ "$CRITICAL" -gt "0" ] && echo "  - $CRITICAL vulnerabilidad(es) CRÍTICA(s) en código"
        [ "$SECRETS" -gt "0" ] && echo "  - $SECRETS secreto(s) detectado(s)"
        echo "  → Corregir antes de hacer merge"
        exit 1
      else
        echo "✅ SECURITY GATE PASSED"
        [ "$HIGH" -gt "0" ] && echo "  ⚠️  Advertencia: $HIGH vulnerabilidad(es) HIGH pendientes de revisar"
        exit 0
      fi
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

```bash
# Commit y push del pipeline
git add .gitlab-ci.yml
git commit -m "ci: pipeline de seguridad completo con SAST, Secret Detection y Dependency Scanning"
git push origin main
```

### Paso 3: Observar la ejecución del pipeline

En la UI de GitLab: **CI/CD → Pipelines → [el pipeline que acaba de ejecutar]**

Puntos de observación:
1. ¿Cuántos jobs se crearon? (el template SAST crea múltiples jobs, uno por analizador)
2. ¿Cuánto tiempo tarda cada job en completar?
3. ¿Qué jobs se ejecutan en paralelo?

```bash
# Monitorear el pipeline via API
PIPELINE_ID=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines?ref=main&per_page=1" | \
  jq '.[0].id')

echo "Pipeline ID: $PIPELINE_ID"

# Listar todos los jobs del pipeline
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines/$PIPELINE_ID/jobs" | \
  jq '.[] | {name, status, duration, stage}'
```

### Paso 4: Analizar resultados de SAST

```bash
# Descargar el reporte SAST
SAST_JOB=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines/$PIPELINE_ID/jobs" | \
  jq '.[] | select(.name == "semgrep-sast") | .id')

# Descargar artifacts
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --output sast-artifacts.zip \
  "http://localhost/api/v4/projects/$PROJECT_ID/jobs/$SAST_JOB/artifacts"

unzip sast-artifacts.zip -d sast-artifacts/

# Analizar el reporte
cat sast-artifacts/gl-sast-report.json | jq '
  .vulnerabilities | 
  group_by(.severity) |
  map({
    severity: .[0].severity,
    count: length,
    findings: [.[] | {
      name: .name,
      file: .location.file,
      line: .location.start_line,
      cwe: .identifiers[0].value
    }]
  })'
```

Resultado esperado — vulnerabilidades que debería detectar en `app.py`:

| Vulnerabilidad | Severidad | Archivo | Línea |
|---------------|-----------|---------|-------|
| SQL Injection | High/Critical | app.py | ~12 |
| Deserialization | High | app.py | ~20 |
| Command Injection | High | app.py | ~27 |
| Hardcoded Password | Medium | app.py | ~31 |
| MD5 weak hash | Medium | app.py | ~38 |
| Debug mode in production | Low | app.py | ~43 |

### Paso 5: Analizar resultados de Secret Detection

```bash
# Via UI: Security → Vulnerability Report → filtrar por "Secret Detection"

# Via API: descargar reporte de secretos
SECRET_JOB=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines/$PIPELINE_ID/jobs" | \
  jq '.[] | select(.name == "secret_detection") | .id')

curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --output secret-artifacts.zip \
  "http://localhost/api/v4/projects/$PROJECT_ID/jobs/$SECRET_JOB/artifacts"

unzip secret-artifacts.zip
cat gl-secret-detection-report.json | jq '
  .vulnerabilities[] | {
    type: .name,
    severity,
    file: .location.file,
    line: .location.start_line,
    description: .description
  }'
```

Secretos esperados en `.env.example`:
- AWS Access Key ID + Secret Access Key
- GitHub Personal Access Token
- GitLab PAT
- Stripe Secret Key
- JWT Secret

### Paso 6: Analizar resultados de Dependency Scanning

```bash
# Descargar y analizar reporte de dependencias
DEP_JOB=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines/$PIPELINE_ID/jobs" | \
  jq '.[] | select(.name | contains("dependency_scanning")) | .id' | head -1)

curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --output dep-artifacts.zip \
  "http://localhost/api/v4/projects/$PROJECT_ID/jobs/$DEP_JOB/artifacts"

unzip dep-artifacts.zip

# Resumen por severidad
cat gl-dependency-scanning-report.json | jq '
  .vulnerabilities |
  group_by(.severity) |
  map({severity: .[0].severity, count: length}) |
  sort_by(.severity)'

# Detalle de vulnerabilidades con solución disponible
cat gl-dependency-scanning-report.json | jq '
  .vulnerabilities[] |
  select(.solution != null) |
  {
    cve: .identifiers[0].value,
    severity,
    package: .location.dependency.package.name,
    current_version: .location.dependency.version,
    fix: .solution
  }'
```

Dependencias vulnerables esperadas con `requirements.txt`:
- `PyYAML==5.4.1` → CVE: YAML deserialization (actualizar a 6.0+)
- `Pillow==9.1.0` → múltiples CVEs de procesamiento de imágenes
- `requests==2.27.0` → posibles CVEs según la versión exacta

### Paso 7: Remediar vulnerabilidades

```bash
# Crear una rama de fix
git checkout -b fix/security-vulnerabilities

# 7.1 Corregir SQL Injection (usar parametrización)
cat > app_fixed.py << 'PYTHON'
import hashlib
import sqlite3
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/users')
def get_users():
    username = request.args.get('username', '')
    conn = sqlite3.connect('users.db')
    # FIXED: query parametrizada — no SQL injection
    result = conn.execute("SELECT * FROM users WHERE username = ?", (username,)).fetchall()
    return jsonify(result)
PYTHON

# 7.2 Actualizar dependencias vulnerables
cat > requirements.txt << 'DEPS'
flask==2.3.3
requests==2.31.0
PyYAML==6.0.1
Pillow==10.3.0
DEPS

# 7.3 Mover secretos a variables CI/CD (nunca en código)
# En la UI: Settings → CI/CD → Variables → Add variable
# Nombre: AWS_ACCESS_KEY_ID, Valor: [real], Protected: ✅, Masked: ✅
echo "Los secretos deben estar en CI/CD Variables, no en el código"

# 7.4 Commit del fix
git add app_fixed.py requirements.txt
git commit -m "fix(security): corregir SQL injection y actualizar dependencias vulnerables"
git push origin fix/security-vulnerabilities
```

Crear MR desde `fix/security-vulnerabilities` → `main` y verificar que el pipeline de security pasa.

### Paso 8: Gestionar falsos positivos

El SAST puede generar falsos positivos. Para descartarlos documentadamente:

```bash
# Via API: marcar una vulnerabilidad como "dismissed" (falso positivo)
# 1. Obtener el ID de la vulnerabilidad
VULN_ID=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/vulnerabilities" | \
  jq '.[0].id')

# 2. Dismissar con motivo documentado
curl -s --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{
    \"state\": \"dismissed\",
    \"dismissal_reason\": \"used_in_tests\",
    \"comment\": \"Falso positivo: esta función solo se usa en el test harness, no en producción\"
  }" \
  "http://localhost/api/v4/vulnerabilities/$VULN_ID/dismiss"
```

---

## Preguntas de reflexión

1. El job de SAST tardó varios minutos en ejecutar. ¿Cómo afecta esto al flow de trabajo del developer? ¿Qué configuración usarías para reducir el tiempo sin sacrificar cobertura?

2. Secret Detection detectó secretos en `.env.example`. ¿Deberías descartar este hallazgo como falso positivo o eliminarlo del repositorio? ¿Por qué?

3. Hay una diferencia entre tener el archivo en `.gitignore` y no haberlo commiteado nunca. Si el secreto ya está en el historial de git, ¿qué pasos tomarías?

4. El security gate bloqueó el pipeline porque detectó secretos en `.env.example`. ¿Cómo configurarías una excepción para este archivo específico sin deshabilitar Secret Detection globalmente?

5. ¿Cuál es la diferencia entre SAST y Dependency Scanning en términos de qué vulnerabilidades detectan? ¿Se complementan o se solapan?

---

## Entregables

- [ ] Proyecto `security-scan-lab` creado con `app.py` vulnerable y `requirements.txt` con versiones antiguas
- [ ] Pipeline ejecutado con SAST, Secret Detection y Dependency Scanning
- [ ] Reporte SAST analizado: mínimo 4 vulnerabilidades identificadas y clasificadas
- [ ] Reporte Secret Detection: mínimo 3 secretos identificados en `.env.example`
- [ ] Reporte Dependency Scanning: mínimo 2 CVEs en dependencias identificados
- [ ] Rama `fix/security-vulnerabilities` con remediaciones y MR creado
- [ ] Security gate pasando en la rama de fix
- [ ] Al menos 1 falso positivo descartado con motivo documentado

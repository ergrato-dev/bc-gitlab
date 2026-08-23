# 🔬 Práctica 04 — Security Scanning en Pipeline

**Duración estimada:** 45 minutos
**Dificultad:** ⭐⭐⭐ (Media-Alta)

## 🎯 Objetivo

Integrar los cuatro tipos de security scanning de GitLab en un pipeline CI/CD: SAST, Secret Detection, Dependency Scanning y Container Scanning. Interpretar los reportes y configurar umbrales de severidad.

---

## 📋 Prerrequisitos

- Práctica 02 completada (imagen Docker en el Container Registry)
- Runner con `privileged = true` online (para DinD en el build de la imagen)
- `$GITLAB_TOKEN` y `$GITLAB_PROJECT_ID` exportados

```bash
# Verificar que la imagen del build existe en el registry
REPO_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/registry/repositories" \
  | python3 -c "
import sys, json
repos = json.load(sys.stdin)
if repos:
    print(repos[0]['id'])
")

if [ -z "$REPO_ID" ]; then
    echo "❌ No hay imágenes en el registry — completar Práctica 02 primero"
else
    echo "✅ Repository ID: $REPO_ID"
    curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
      "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/registry/repositories/$REPO_ID/tags?per_page=3" \
      | python3 -c "
import sys, json
tags = json.load(sys.stdin)
print(f'Tags disponibles: {len(tags)}')
for t in tags[:3]:
    print(f'  {t[\"name\"]}')
"
fi
```

---

## 🔍 Paso 1: Pipeline con Todos los Escaneos

Crear el siguiente `.gitlab-ci.yml` en el proyecto:

```yaml
# Importar templates de seguridad de GitLab
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml

stages:
  - build
  - test
  - security
  - report

variables:
  DOCKER_TLS_CERTDIR: ""
  DOCKER_DRIVER: overlay2

# ─── BUILD ───────────────────────────────────────────────────────────────────
docker-build:
  stage: build
  image: docker:24-cli
  services:
    - name: docker:24-dind
      alias: docker
  variables:
    DOCKER_HOST: tcp://docker:2375
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY
  script:
    # ¿QUÉ HACE?: Construye y publica la imagen que luego será escaneada
    # ¿POR QUÉ?: Container Scanning necesita la imagen en el registry antes de ejecutarse
    # ¿PARA QUÉ?: Tener el artefacto exacto que iría a producción para escanear

    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
    - echo "✅ Imagen publicada: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA"
  tags: [docker, privileged]

# ─── TEST ────────────────────────────────────────────────────────────────────
unit-test:
  stage: test
  image: node:18-alpine
  script:
    - npm test

# ─── SECURITY — Los templates inyectan los jobs automáticamente ───────────────
# Solo necesitamos sobreescribir variables para el Container Scanning:

container_scanning:
  # ¿QUÉ HACE?: Sobreescribe la configuración del template para escanear nuestra imagen
  # ¿POR QUÉ?: El template no sabe qué imagen construimos — hay que indicarle el tag exacto
  # ¿PARA QUÉ?: Escanear la imagen real que construimos en docker-build, no una genérica
  variables:
    CS_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
    CS_DOCKERFILE_PATH: Dockerfile
    CS_SEVERITY_THRESHOLD: "high"    # fallar solo con HIGH o CRITICAL
    CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN: "false"
  needs:
    - docker-build                   # esperar a que la imagen exista en el registry

# ─── REPORT ──────────────────────────────────────────────────────────────────
security-summary:
  stage: report
  image: alpine:latest
  needs:
    - job: container_scanning
      optional: true
  script:
    - echo "=== RESUMEN DE SEGURIDAD ==="
    - echo "Pipeline: $CI_PIPELINE_ID"
    - echo "Commit: $CI_COMMIT_SHORT_SHA"
    - echo "Imagen: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA"
    - |
      if [ -f gl-container-scanning-report.json ]; then
        python3 << 'EOF'
import json

try:
    with open('gl-container-scanning-report.json') as f:
        report = json.load(f)
    vulns = report.get('vulnerabilities', [])
    by_severity = {}
    for v in vulns:
        sev = v.get('severity', 'Unknown')
        by_severity[sev] = by_severity.get(sev, 0) + 1
    print(f"Vulnerabilidades encontradas: {len(vulns)}")
    for sev in ['Critical', 'High', 'Medium', 'Low', 'Unknown']:
        count = by_severity.get(sev, 0)
        if count > 0:
            print(f"  {sev}: {count}")
except Exception as e:
    print(f"No se pudo leer el reporte: {e}")
EOF
      else
        echo "Reporte de container scanning no disponible"
      fi
  artifacts:
    paths:
      - gl-container-scanning-report.json
    when: always
    expire_in: 1 week
  rules:
    - when: always
```

---

## 🧪 Paso 2: Introducir Código Vulnerable (SAST Demo)

Para que el SAST encuentre algo real, añadir código con vulnerabilidades deliberadas:

**`vulnerable.js`** (para el SAST):
```javascript
// SOLO PARA DEMO — Este código tiene vulnerabilidades intencionales

const { exec } = require('child_process');

// Vulnerabilidad: Command Injection
function listFiles(userInput) {
  // INSEGURO: el input del usuario va directamente al shell
  exec('ls ' + userInput, (error, stdout, stderr) => {
    console.log(stdout);
  });
}

// Vulnerabilidad: Path Traversal
function readConfig(filename) {
  const fs = require('fs');
  // INSEGURO: permite leer archivos fuera del directorio previsto
  return fs.readFileSync('/app/config/' + filename, 'utf8');
}

// Hardcoded credential (para Secret Detection)
const DB_PASSWORD = 'supersecretpassword123';  // No hacer esto nunca

module.exports = { listFiles, readConfig };
```

> **Nota:** Este archivo existe únicamente para demostrar el SAST. En un proyecto real, jamás se committean vulnerabilidades intencionales ni credenciales hardcodeadas.

```bash
# Commitear el archivo vulnerable para disparar el SAST
git add vulnerable.js
git commit -m "demo: código con vulnerabilidades para práctica SAST"
git push
```

---

## 👁️ Paso 3: Observar los Resultados en la UI

Después de que el pipeline complete:

**1. Security Tab del Pipeline:**
```
CI/CD → Pipelines → [pipeline actual] → Security

Debería mostrar:
  - SAST: 2 vulnerabilidades (command injection, path traversal)
  - Secret Detection: 1 (hardcoded password)
  - Dependency Scanning: (CVEs en dependencias si las hay)
  - Container Scanning: (CVEs en la imagen base)
```

**2. Vulnerability Report del proyecto:**
```
Proyecto → Secure → Vulnerability Report

Lista completa de todas las vulnerabilidades, con:
  - Severidad (Critical / High / Medium / Low)
  - Descripción del problema
  - Archivo y línea (para SAST)
  - CVE ID (para Dependency Scanning y Container Scanning)
  - Estado (Detected / Confirmed / Dismissed / Resolved)
```

---

## 🔧 Paso 4: Configurar Umbrales de Severidad

```yaml
# Añadir al pipeline para que falle si hay CRITICAL en cualquier scan:
sast:
  variables:
    SAST_EXCLUDED_PATHS: "spec,test,tests,tmp,node_modules"
    # Nota: SAST no tiene threshold configurable directamente — falla según hallazgos

dependency_scanning:
  variables:
    DS_MAX_ALLOWED_VULNERABILITIES: "0"   # 0 = falla si hay alguna vulnerabilidad

container_scanning:
  variables:
    CS_SEVERITY_THRESHOLD: "critical"     # solo falla si hay CRITICAL (no HIGH)
```

---

## 📊 Paso 5: Consultar Reportes via API

```bash
# ¿QUÉ HACE?: Consulta las vulnerabilidades detectadas en el pipeline via API
# ¿POR QUÉ?: Automatizar reportes sin depender de la UI
# ¿PARA QUÉ?: Integrar con sistemas de tracking de vulnerabilidades externos

# Obtener ID del pipeline más reciente
PIPELINE_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/pipelines?per_page=1" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

echo "Pipeline ID: $PIPELINE_ID"

# Obtener vulnerabilidades del pipeline (GitLab 15.0+)
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/vulnerability_findings?per_page=20" \
  | python3 -c "
import sys, json
vulns = json.load(sys.stdin)
if isinstance(vulns, list):
    print(f'Vulnerabilidades encontradas: {len(vulns)}')
    for v in vulns[:5]:
        sev = v.get('severity', '?')
        name = v.get('name', '?')[:50]
        scanner = v.get('scanner', {}).get('name', '?')
        print(f'  [{sev}] {name} — {scanner}')
    if len(vulns) > 5:
        print(f'  ... y {len(vulns)-5} más')
else:
    print(f'Respuesta: {vulns}')
" 2>/dev/null || echo "Endpoint no disponible en esta versión de GitLab CE"
```

---

## 🧹 Paso 6: Dismissar una Vulnerabilidad (False Positive)

```bash
# ¿QUÉ HACE?: Marca una vulnerabilidad como "dismissada" (falso positivo o aceptada)
# ¿POR QUÉ?: No todas las vulnerabilidades son accionables — algunas son false positives
# ¿PARA QUÉ?: Evitar que aparezcan como nuevas en cada MR una vez que ya fueron evaluadas

# Via UI:
# Secure → Vulnerability Report → [vulnerabilidad] → clic en "Dismiss"
# Seleccionar razón: "False positive" / "Used in tests" / "Not applicable" / etc.

# Via API (requiere ID de la vulnerabilidad):
VULN_ID=1   # ← obtener de la UI o de la API anterior

curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "comment": "Código solo existe en contexto de demo — no va a producción",
    "dismissal_reason": "used_in_tests"
  }' \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/vulnerabilities/$VULN_ID/dismiss" \
  | python3 -c "
import sys, json
r = json.load(sys.stdin)
print(f'Vulnerabilidad #{r.get(\"id\")} dismissada: estado = {r.get(\"state\")}')
"
```

---

## ✅ Checklist de verificación

- [ ] Pipeline completo con los 4 stages: build, test, security, report
- [ ] Jobs de security en estado `passed` o `failed` (ambos son válidos — el scan terminó)
- [ ] SAST detectó al menos 1 vulnerabilidad en `vulnerable.js`
- [ ] Secret Detection detectó la contraseña hardcodeada en `vulnerable.js`
- [ ] Container Scanning ejecutó y generó `gl-container-scanning-report.json`
- [ ] Vulnerability Report muestra las vulnerabilidades encontradas
- [ ] Al menos 1 vulnerabilidad dismissada con razón documentada

---

## 🏆 Reto adicional

Configurar el pipeline para que en Merge Requests muestre el widget de seguridad:

```yaml
sast:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == "main"

secret_detection:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == "main"
```

Crear una rama de feature, añadir otro secreto hardcodeado, abrir un MR y observar el widget de seguridad en la vista del MR.

---

⬅️ **Práctica anterior:** [03 — Package Registry](../03-package-registry/README.md)
➡️ **Proyecto:** [Proyecto Semana 08](../../3-proyecto/README.md)

# Práctica 04 — Compliance Pipeline y MR Approvals

## Objetivo

Implementar un sistema de compliance a nivel de grupo que garantice automáticamente que todos los proyectos cumplan con estándares de seguridad mínimos: SAST habilitado, MR approvals configuradas y reporte de auditoría generado en cada pipeline.

## Escenario

La empresa tiene 3 proyectos en el grupo `secure-org`:
- `project-compliant` — ya tiene SAST configurado (debe pasar compliance)
- `project-non-compliant` — NO tiene SAST (debe fallar compliance)
- `project-legacy` — proyecto antiguo sin pipeline CI/CD

El compliance pipeline debe ejecutarse en todos y detectar cuáles cumplen.

---

## Instrucciones

### Paso 1: Crear la estructura de grupo y proyectos

```bash
GITLAB_URL="http://localhost"
ADMIN_TOKEN="tu-admin-token"

# Crear el grupo
GROUP_ID=$(curl -s --request POST \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "secure-org",
    "path": "secure-org",
    "visibility": "private"
  }' \
  "$GITLAB_URL/api/v4/groups" | jq '.id')
echo "Grupo secure-org: $GROUP_ID"

# Crear proyectos
for project_name in "project-compliant" "project-non-compliant" "project-legacy"; do
  PROJ_ID=$(curl -s --request POST \
    --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{
      \"name\": \"$project_name\",
      \"namespace_id\": $GROUP_ID,
      \"visibility\": \"private\",
      \"initialize_with_readme\": true
    }" \
    "$GITLAB_URL/api/v4/projects" | jq '.id')
  echo "Proyecto $project_name: $PROJ_ID"
done
```

### Paso 2: Crear el repositorio de compliance

El compliance pipeline vive en su propio repositorio dentro del grupo:

```bash
# Crear repositorio para el compliance pipeline
COMPLIANCE_ID=$(curl -s --request POST \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{
    \"name\": \"compliance-pipeline\",
    \"namespace_id\": $GROUP_ID,
    \"visibility\": \"private\",
    \"initialize_with_readme\": true
  }" \
  "$GITLAB_URL/api/v4/projects" | jq '.id')
echo "Repositorio compliance: $COMPLIANCE_ID"
```

Clonar y crear el pipeline de compliance:

```bash
git clone http://localhost/secure-org/compliance-pipeline.git
cd compliance-pipeline
```

**`.gitlab-ci.yml`** del repositorio de compliance:

```yaml
# Este archivo se ejecuta en TODOS los proyectos del grupo
# Los desarrolladores de cada proyecto no pueden modificarlo ni omitirlo
stages:
  - compliance-check
  - compliance-report

# =============================================
# CHECK 1: Verificar que SAST esté configurado
# =============================================
check-sast-enabled:
  stage: compliance-check
  image: alpine:3.19
  before_script:
    - apk add --no-cache grep
  script:
    - echo "=== Compliance Check: SAST ==="
    - |
      if [ ! -f ".gitlab-ci.yml" ]; then
        echo "❌ FAIL: No existe .gitlab-ci.yml en este proyecto"
        echo "   Todos los proyectos deben tener CI/CD configurado"
        exit 1
      fi
    - |
      if grep -q "Security/SAST" .gitlab-ci.yml; then
        echo "✅ PASS: SAST está incluido en .gitlab-ci.yml"
      else
        echo "❌ FAIL: SAST no está configurado"
        echo "   Añade al .gitlab-ci.yml:"
        echo "   include:"
        echo "     - template: Security/SAST.gitlab-ci.yml"
        exit 1
      fi
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

# =============================================
# CHECK 2: Verificar Secret Detection
# =============================================
check-secret-detection:
  stage: compliance-check
  image: alpine:3.19
  before_script:
    - apk add --no-cache grep
  script:
    - echo "=== Compliance Check: Secret Detection ==="
    - |
      if [ -f ".gitlab-ci.yml" ] && grep -q "Secret-Detection" .gitlab-ci.yml; then
        echo "✅ PASS: Secret Detection configurado"
      else
        echo "⚠️  WARN: Secret Detection no encontrado"
        echo "   Recomendado: include: Security/Secret-Detection.gitlab-ci.yml"
        # No bloquea pero avisa — algunas excepciones pueden estar documentadas
      fi
  allow_failure: true  # Warning, no blocking
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"

# =============================================
# CHECK 3: Verificar que no hay secretos en código
# =============================================
check-no-hardcoded-secrets:
  stage: compliance-check
  image: alpine:3.19
  before_script:
    - apk add --no-cache grep
  script:
    - echo "=== Compliance Check: No hardcoded secrets ==="
    - |
      # Búsqueda básica de patrones de secretos comunes
      PATTERNS="password\s*=\s*['\"][^'\"]\|api_key\s*=\s*['\"][^'\"]\|secret\s*=\s*['\"][^'\"]\|AKIAIO"
      
      if grep -rn -i "$PATTERNS" --include="*.py" --include="*.js" --include="*.ts" \
          --include="*.rb" --include="*.go" --exclude-dir=".git" \
          --exclude-dir="node_modules" --exclude-dir="vendor" . 2>/dev/null | \
          grep -v "test\|spec\|example\|sample\|\.example"; then
        echo "⚠️  Posibles secretos hardcodeados encontrados. Revisar manualmente."
        echo "   Si son falsos positivos, documentarlos en .compliance-exceptions"
      else
        echo "✅ PASS: No se detectaron patrones de secretos evidentes"
      fi
  allow_failure: true
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"

# =============================================
# REPORTE: Generar artefacto de compliance
# =============================================
generate-compliance-report:
  stage: compliance-report
  image: alpine:3.19
  before_script:
    - apk add --no-cache jq
  script:
    - |
      echo "=== Generando reporte de compliance ==="
      
      # Determinar estado general basado en jobs anteriores
      TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
      
      cat > compliance-report.json << JSONEOF
      {
        "project": "$CI_PROJECT_PATH",
        "pipeline_id": $CI_PIPELINE_ID,
        "commit": "$CI_COMMIT_SHA",
        "branch": "$CI_COMMIT_BRANCH",
        "author": "$CI_COMMIT_AUTHOR",
        "timestamp": "$TIMESTAMP",
        "checks": {
          "sast_configured": $(grep -q "Security/SAST" .gitlab-ci.yml && echo "true" || echo "false"),
          "secret_detection_configured": $(grep -q "Secret-Detection" .gitlab-ci.yml && echo "true" || echo "false"),
          "has_ci_config": $([ -f ".gitlab-ci.yml" ] && echo "true" || echo "false")
        }
      }
      JSONEOF
      
      # Generar versión legible
      cat > compliance-report.md << MDEOF
      # Compliance Report
      
      **Proyecto**: $CI_PROJECT_PATH  
      **Pipeline**: #$CI_PIPELINE_ID  
      **Commit**: $CI_COMMIT_SHORT_SHA  
      **Autor**: $CI_COMMIT_AUTHOR  
      **Fecha**: $TIMESTAMP  
      
      ## Resultados de Compliance
      
      | Check | Estado |
      |-------|--------|
      | CI/CD configurado | $([ -f ".gitlab-ci.yml" ] && echo "✅ OK" || echo "❌ FAIL") |
      | SAST habilitado | $(grep -q "Security/SAST" .gitlab-ci.yml 2>/dev/null && echo "✅ OK" || echo "❌ FAIL") |
      | Secret Detection | $(grep -q "Secret-Detection" .gitlab-ci.yml 2>/dev/null && echo "✅ OK" || echo "⚠️ WARNING") |
      
      MDEOF
      
      echo "Reporte generado:"
      cat compliance-report.md
  artifacts:
    name: "compliance-report-$CI_PROJECT_PATH_SLUG-$CI_COMMIT_SHORT_SHA"
    paths:
      - compliance-report.json
      - compliance-report.md
    expire_in: 90 days
    reports:
      # Nota: no existe un report type nativo para compliance en CE
      # El JSON queda disponible via API de artifacts
  rules:
    - when: always  # Siempre generar el reporte, aunque otros checks fallen
```

```bash
git add .gitlab-ci.yml
git commit -m "feat: compliance pipeline para grupo secure-org"
git push origin main
```

### Paso 3: Vincular el compliance pipeline al grupo

```bash
# Obtener el ID del proyecto de compliance y configurarlo en el grupo
COMPLIANCE_PIPELINE_PATH="secure-org/compliance-pipeline/.gitlab-ci.yml@main"

curl -s --request PUT \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{
    \"compliance_frameworks\": {
      \"pipeline_configuration_full_path\": \"$COMPLIANCE_PIPELINE_PATH\"
    }
  }" \
  "$GITLAB_URL/api/v4/groups/$GROUP_ID" | \
  jq '.compliance_management_frameworks'
```

> En GitLab CE, el compliance pipeline se configura en: **Grupo → Settings → CI/CD → Compliance pipeline configuration**

### Paso 4: Preparar proyectos de prueba

**Proyecto compliant** — con SAST configurado:

```bash
git clone http://localhost/secure-org/project-compliant.git
cd project-compliant

cat > .gitlab-ci.yml << 'YAML'
stages:
  - test
  - security

include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml

unit-tests:
  stage: test
  image: python:3.11-alpine
  script:
    - echo "Ejecutando tests..."
    - python -m pytest || true
YAML

git add .gitlab-ci.yml
git commit -m "ci: pipeline completo con SAST y Secret Detection"
git push origin main
```

**Proyecto non-compliant** — sin SAST:

```bash
git clone http://localhost/secure-org/project-non-compliant.git
cd project-non-compliant

cat > .gitlab-ci.yml << 'YAML'
stages:
  - build

build:
  stage: build
  script:
    - echo "Building..."
    - echo "No tenemos escaneos de seguridad... ¡aún!"
YAML

git add .gitlab-ci.yml
git commit -m "ci: pipeline básico sin seguridad"
git push origin main
```

### Paso 5: Configurar MR Approvals a nivel de grupo

```bash
# Configurar en todos los proyectos del grupo via API
PROJECTS=$(curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "$GITLAB_URL/api/v4/groups/$GROUP_ID/projects" | jq -r '.[].id')

for PROJECT_ID in $PROJECTS; do
  PROJECT_NAME=$(curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    "$GITLAB_URL/api/v4/projects/$PROJECT_ID" | jq -r '.name')
  
  # Configurar approvals
  curl -s --request PUT \
    --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    --header "Content-Type: application/json" \
    --data '{
      "approvals_before_merge": 2,
      "reset_approvals_on_push": true,
      "disable_overriding_approvers_per_merge_request": true
    }' \
    "$GITLAB_URL/api/v4/projects/$PROJECT_ID/approvals" | \
    jq '{project: "'$PROJECT_NAME'", approvals_before_merge, reset_approvals_on_push}'
done
```

### Paso 6: Ejecutar y comparar resultados

Ejecutar pipelines en ambos proyectos (push un cambio vacío para disparar):

```bash
# Disparar pipeline en project-compliant
cd project-compliant
git commit --allow-empty -m "trigger: ejecutar compliance pipeline"
git push origin main

# Disparar pipeline en project-non-compliant
cd ../project-non-compliant
git commit --allow-empty -m "trigger: ejecutar compliance pipeline"
git push origin main
```

Verificar resultados via API:

```bash
# Función para obtener el estado del último pipeline
check_pipeline_status() {
  local PROJECT_PATH=$1
  local PROJECT_ID=$(curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    "$GITLAB_URL/api/v4/projects?search=$PROJECT_PATH" | jq '.[0].id')
  
  PIPELINE=$(curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    "$GITLAB_URL/api/v4/projects/$PROJECT_ID/pipelines?ref=main&per_page=1")
  
  echo "=== $PROJECT_PATH ==="
  echo "$PIPELINE" | jq '.[0] | {id, status, created_at}'
  
  # Listar jobs del pipeline
  PIPELINE_ID=$(echo "$PIPELINE" | jq '.[0].id')
  curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    "$GITLAB_URL/api/v4/projects/$PROJECT_ID/pipelines/$PIPELINE_ID/jobs" | \
    jq '.[] | {name, status, stage}'
}

check_pipeline_status "project-compliant"
echo ""
check_pipeline_status "project-non-compliant"
```

Resultado esperado:
- `project-compliant`: todos los jobs en verde (passed)
- `project-non-compliant`: `check-sast-enabled` falla → pipeline bloqueado

### Paso 7: Dashboard de compliance organizacional

Script para generar un dashboard de compliance de todos los proyectos:

```bash
#!/bin/bash
# ¿QUÉ HACE?: Genera reporte de compliance de todos los proyectos del grupo
# ¿POR QUÉ?: Visibilidad centralizada sin revisar cada proyecto manualmente
# ¿PARA QUÉ?: Informe semanal de compliance para dirección o auditoría

GITLAB_URL="http://localhost"
GROUP_ID="tu-group-id"

echo "# Dashboard de Compliance — $(date +%Y-%m-%d)"
echo ""
echo "| Proyecto | CI/CD | SAST | Secret Detection | Estado |"
echo "|---------|:-----:|:----:|:----------------:|:------:|"

curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "$GITLAB_URL/api/v4/groups/$GROUP_ID/projects?per_page=100" | \
  jq -r '.[].id' | \
while read PROJECT_ID; do
  PROJECT_NAME=$(curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    "$GITLAB_URL/api/v4/projects/$PROJECT_ID" | jq -r '.path')
  
  # Verificar existencia de .gitlab-ci.yml via API
  CI_EXISTS=$(curl -s -o /dev/null -w "%{http_code}" \
    --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
    "$GITLAB_URL/api/v4/projects/$PROJECT_ID/repository/files/.gitlab-ci.yml?ref=main")
  
  if [ "$CI_EXISTS" = "200" ]; then
    CI_CONTENT=$(curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
      "$GITLAB_URL/api/v4/projects/$PROJECT_ID/repository/files/.gitlab-ci.yml/raw?ref=main")
    
    HAS_CI="✅"
    HAS_SAST=$(echo "$CI_CONTENT" | grep -q "Security/SAST" && echo "✅" || echo "❌")
    HAS_SD=$(echo "$CI_CONTENT" | grep -q "Secret-Detection" && echo "✅" || echo "⚠️")
    
    if echo "$CI_CONTENT" | grep -q "Security/SAST"; then
      STATUS="✅ Compliant"
    else
      STATUS="❌ Non-compliant"
    fi
  else
    HAS_CI="❌"
    HAS_SAST="❌"
    HAS_SD="❌"
    STATUS="❌ Sin CI/CD"
  fi
  
  echo "| $PROJECT_NAME | $HAS_CI | $HAS_SAST | $HAS_SD | $STATUS |"
done
```

---

## Preguntas de reflexión

1. ¿Qué pasa si un proyecto legacy tiene un `.gitlab-ci.yml` que no puede ser modificado fácilmente? ¿Cómo manejarías una excepción temporal documentada?

2. El compliance pipeline agrega tiempo a cada ejecución de CI/CD. ¿Cómo balancearías la velocidad de entrega vs el rigor del compliance?

3. Si un proyecto pasa el compliance check de SAST (tiene el include en `.gitlab-ci.yml`) pero en realidad los jobs de SAST siempre fallan o están deshabilitados con `allow_failure: true`, ¿el check de compliance es efectivo? ¿Cómo lo mejorarías?

4. ¿Qué métricas de compliance reportarías semanalmente a la dirección? ¿En qué formato?

5. El compliance pipeline actual verifica presencia de SAST, no sus resultados. ¿Cómo modificarías el pipeline para también verificar que el pipeline de SAST pasó sin vulnerabilidades críticas?

---

## Entregables

- [ ] Grupo `secure-org` con repositorio `compliance-pipeline` creado
- [ ] Compliance pipeline con al menos 3 checks implementado y commiteado
- [ ] Compliance pipeline vinculado al grupo (verificar en Settings)
- [ ] `project-compliant` con SAST configurado — pipeline completo pasa
- [ ] `project-non-compliant` sin SAST — check-sast-enabled falla como esperado
- [ ] MR approvals configuradas: 2 requeridas con reset en push
- [ ] Dashboard de compliance ejecutado y resultado documentado (captura o texto)
- [ ] Reporte de compliance generado como artifact en al menos un pipeline

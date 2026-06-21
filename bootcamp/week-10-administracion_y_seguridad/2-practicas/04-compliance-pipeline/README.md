# Práctica 04 — Compliance Pipeline

## Objetivo

Crear un pipeline de cumplimiento a nivel de grupo que garantice que todos los proyectos ejecuten SAST y tengan merge request approvals.

## Instrucciones

### Paso 1: Crear un compliance pipeline
En un grupo, define un pipeline que se ejecute en todos los proyectos:

```yaml
# .gitlab-ci.yml del grupo (compliance pipeline)
stages:
  - compliance
  - build
  - test
  - security

compliance-check:
  stage: compliance
  script:
    - echo "=== Compliance Check ==="
    - echo "Verificando que el proyecto tenga SAST habilitado..."
    - |
      if grep -q "Security/SAST" .gitlab-ci.yml; then
        echo "SAST: OK"
      else
        echo "SAST: FAIL - SAST no está incluido en el pipeline"
        exit 1
      fi
    - echo "Verificando protected branches..."
    - echo "Compliance check completado."
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

### Paso 2: Configurar Merge Request Approvals a nivel de grupo
1. Ve al grupo → Settings → Merge requests → Merge request approvals
2. Configura:
   - Approvals required: 2
   - Prevent approval by author: Enabled
   - Prevent approvals by users who add commits: Enabled

### Paso 3: Crear un pipeline de remediation
Define un job que genere un reporte de cumplimiento:

```yaml
compliance-report:
  stage: compliance
  script:
    - echo "=== Compliance Report ===" > compliance-report.md
    - echo "Fecha: $(date)" >> compliance-report.md
    - echo "Proyecto: $CI_PROJECT_PATH" >> compliance-report.md
    - echo "Branch: $CI_COMMIT_BRANCH" >> compliance-report.md
    - echo "Pipeline ID: $CI_PIPELINE_ID" >> compliance-report.md
    - echo "" >> compliance-report.md
    - echo "## Resultados" >> compliance-report.md
  artifacts:
    paths:
      - compliance-report.md
    expire_in: 30 days
```

### Paso 4: Verificar en múltiples proyectos
1. Crea 2-3 proyectos dentro del grupo
2. Algunos deben cumplir con SAST, otros no
3. Ejecuta pipelines y verifica los resultados del compliance check

## Preguntas de reflexión
- ¿Qué otros checks agregarías al compliance pipeline?
- ¿Cómo manejarías proyectos legacy que no pueden cumplir inmediatamente?
- ¿Qué métricas de compliance reportarías a la dirección?

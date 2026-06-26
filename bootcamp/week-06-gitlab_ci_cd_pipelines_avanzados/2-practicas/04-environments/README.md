# 🔬 Práctica 04 — Environments y Deployments

## 🎯 Objetivo

Configurar entornos de staging y production con historial de deployments visible en la UI. Implementar deploy manual a producción, acción de stop para staging, y explorar el rollback nativo de GitLab.

## ⏱️ Tiempo estimado: 45 minutos

## 📋 Requisitos previos

- Pipeline modular de la Práctica 03 funcionando
- Ramas `main` y `develop` con protección configurada
- `$GITLAB_TOKEN` y `$PROJECT_ID` disponibles

---

## 📝 Paso 1: Agregar Environments al Pipeline

Actualiza `.gitlab/ci/deploy.yml` con environments completos:

```yaml
# .gitlab/ci/deploy.yml
# ============================================================
# Módulo de deploy — Semana 06 Práctica 04
# ============================================================

variables:
  STAGING_URL: "https://staging.bootcamp-app.example.com"
  PRODUCTION_URL: "https://bootcamp-app.example.com"

.deploy-base:
  stage: deploy
  image: alpine:latest
  before_script:
    - echo "=== Deploy a ${CI_ENVIRONMENT_NAME} ==="
    - echo "Commit: ${CI_COMMIT_SHORT_SHA}"
    - echo "By: ${GITLAB_USER_NAME:-pipeline}"

# ── Deploy a Staging (automático desde develop) ─────────────
deploy-staging:
  extends: .deploy-base
  script:
    - echo "Desplegando a ${STAGING_URL}..."
    - cat dist/build-info.txt 2>/dev/null || echo "(sin artifact de build)"
    - echo "✅ Deploy a staging completado"
    - echo "URL: ${CI_ENVIRONMENT_URL}"
  environment:
    name: staging
    url: $STAGING_URL
    on_stop: stop-staging        # ← job que puede destruir este environment
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"
      when: on_success
    - when: never

# ── Detener Staging (acción manual) ─────────────────────────
stop-staging:
  extends: .deploy-base
  script:
    - echo "Deteniendo environment staging..."
    - echo "✅ Staging detenido"
  environment:
    name: staging
    action: stop                  # ← marca el environment como stopped
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"
      when: manual
  allow_failure: true

# ── Deploy a Production (manual, solo desde main) ───────────
deploy-production:
  extends: .deploy-base
  script:
    - echo "Desplegando a ${PRODUCTION_URL}..."
    - cat dist/build-info.txt 2>/dev/null || echo "(sin artifact de build)"
    - echo "✅ Deploy a producción completado"
    - echo "URL: ${CI_ENVIRONMENT_URL}"
    - echo "Tag/Branch: ${CI_COMMIT_REF_NAME}"
  environment:
    name: production
    url: $PRODUCTION_URL
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: manual
      allow_failure: false
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
      when: manual
      allow_failure: false
    - when: never
```

```bash
git add .gitlab/ci/deploy.yml
git commit -m "ci(week-06): practice 04 — environments with staging/production"
git push origin main
git push origin develop  # también a develop para triggear staging
```

---

## 📝 Paso 2: Observar Environments en la UI

```
http://localhost/bootcamp-org/backend/api-gateway/-/environments

Debe aparecer:
  ● staging     https://staging.bootcamp-app.example.com
    ✅ deploy hace X minutos — commit XXXXXXXX — Ana García
    [Stop] [Rollback]

(production aparecerá cuando se haga el primer deploy manual)
```

---

## 📝 Paso 3: Múltiples Deployments a Staging

Para crear historial de deployments, haz varios pushes a `develop`:

```bash
git checkout develop

# Push 1
git commit --allow-empty -m "feat: feature A — primer deploy a staging"
git push origin develop
# Esperar que pipeline complete (~1-2 min)

# Push 2
git commit --allow-empty -m "feat: feature B — segundo deploy a staging"
git push origin develop
# Esperar que pipeline complete

# Push 3
git commit --allow-empty -m "fix: bug fix — tercer deploy a staging"
git push origin develop
```

**Observar el historial en la UI:**
```
http://localhost/bootcamp-org/backend/api-gateway/-/environments/staging/deployments

Deployment #3  ● Active   fix: bug fix    hace X min   ✅
Deployment #2  ○ Inactive feat: feature B  hace X min   ✅
Deployment #1  ○ Inactive feat: feature A  hace X min   ✅
```

---

## 📝 Paso 4: Consultar Deployments via API

```bash
PROJECT_ID=<tu-project-id>

# ¿QUÉ HACE?: Lista los environments del proyecto con su estado actual
# ¿POR QUÉ?: Verificar programáticamente qué versión está en cada environment
# ¿PARA QUÉ?: Scripting de deploy, dashboards, reportes de estado

curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/${PROJECT_ID}/environments" \
  | python3 -c "
import sys, json
envs = json.load(sys.stdin)
print(f'Environments del proyecto ({len(envs)} total):')
for e in envs:
    state = e.get('state', 'unknown')
    last_dep = e.get('last_deployment', {})
    sha = last_dep.get('sha', 'N/A')[:8] if last_dep else 'N/A'
    ref = last_dep.get('ref', 'N/A') if last_dep else 'N/A'
    print(f'  [{state:8}] {e[\"name\"]:<20} → commit {sha} ({ref})')
    if e.get('external_url'):
        print(f'  {'':10} URL: {e[\"external_url\"]}')
"
```

```bash
# Listar deployments de staging con historial
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/${PROJECT_ID}/deployments?environment=staging&per_page=5" \
  | python3 -c "
import sys, json
deps = json.load(sys.stdin)
print(f'Últimos {len(deps)} deployments a staging:')
for d in deps:
    status = '✅' if d['status'] == 'success' else '❌'
    sha = d.get('sha', 'N/A')[:8]
    ref = d.get('ref', 'N/A')
    created = d.get('created_at', 'N/A')[:10]
    deployer = d.get('user', {}).get('name', 'N/A')
    print(f'  {status} #{d[\"id\"]} [{created}] {sha} ({ref}) — {deployer}')
"
```

---

## 📝 Paso 5: Simular Rollback

El rollback en GitLab re-ejecuta el job de deploy del commit anterior:

```bash
# Obtener el ID de un deployment anterior
DEPLOYMENT_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/${PROJECT_ID}/deployments?environment=staging&per_page=3" \
  | python3 -c "
import sys, json
deps = json.load(sys.stdin)
if len(deps) > 1:
    print(deps[1]['id'])  # segundo deployment (el anterior al actual)
else:
    print('none')
")

echo "Deployment anterior: $DEPLOYMENT_ID"

# ¿QUÉ HACE?: Activa el rollback al deployment anterior via API
# ¿POR QUÉ?: Simular el proceso de rollback cuando una release falla
# ¿PARA QUÉ?: Recuperar el estado anterior de staging sin intervención manual compleja

if [ "$DEPLOYMENT_ID" != "none" ]; then
  curl --silent --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    "http://localhost/api/v4/projects/${PROJECT_ID}/deployments/${DEPLOYMENT_ID}/approval" \
    | python3 -c "import sys,json; r=json.load(sys.stdin); print(r)"
  
  echo "Rollback iniciado. Verificar en Operate → Environments → staging"
fi
```

> **Alternativa via UI:** `Operate → Environments → staging → [deployment anterior] → Rollback`

---

## 📝 Paso 6: Deploy a Producción (Manual)

```bash
git checkout main
git merge develop
git push origin main
```

En la UI, el pipeline de `main` mostrará `deploy-production` con estado "manual" (▶️). Hacer click en el botón de play:

```
http://localhost/bootcamp-org/backend/api-gateway/-/pipelines
→ Pipeline de main → job deploy-production → ▶️ (play)
→ Confirmar en el diálogo
→ Observar la ejecución del job
```

Verificar que `production` aparece en `Operate → Environments`:

```
● production   https://bootcamp-app.example.com
  ✅ XXXXXXXX  Deployed X minutes ago  [tú]
```

---

## 📝 Paso 7: Stop Staging

Detener el environment de staging:

```
Operate → Environments → staging → [Stop]
```

O via pipeline: el job `stop-staging` está disponible en pipelines de `develop` con `when: manual`.

```bash
# Verificar estado después del stop
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/${PROJECT_ID}/environments" \
  | python3 -c "
import sys, json
for e in json.load(sys.stdin):
    print(f'{e[\"name\"]}: {e.get(\"state\", \"?\")}')
"
# Esperado:
#   staging: stopped
#   production: available
```

---

## 🔧 Troubleshooting

**Environment no aparece en `Operate → Environments`**
```
→ El job debe completarse exitosamente (status: success)
→ El job debe tener la keyword "environment:" con un nombre
→ Verificar en la UI del job que muestra "Deploying to environment: staging"
```

**Stop staging no funciona**
```
→ El job "stop-staging" debe tener: environment: action: stop
→ El nombre del environment en stop-staging debe ser exactamente igual al de deploy-staging
→ Verificar que "on_stop: stop-staging" en deploy-staging coincide con el nombre del job
```

**Deploy production en estado "pending" y no se puede ejecutar**
```
→ Si el environment está protegido, puede requerir aprobaciones
→ Verificar: Settings → CI/CD → Protected environments
→ Si no hay protected environment, el job debería ser directamente manual (click ▶️)
```

---

## ✅ Checklist de verificación

- [ ] Environment `staging` visible en `Operate → Environments` con URL
- [ ] Al menos 3 deployments en el historial de staging
- [ ] API devuelve la lista de environments con estado `available`
- [ ] API devuelve el historial de deployments de staging
- [ ] Deploy a `production` exitoso via click manual
- [ ] Environment `staging` en estado `stopped` después de usar Stop

## 📦 Entregables

- [ ] Captura de `Operate → Environments` mostrando `staging` y `production`
- [ ] Captura del historial de deployments de staging (al menos 3)
- [ ] Captura del job `deploy-production` ejecutado manualmente ✅
- [ ] Output del API de environments mostrando ambos environments con sus estados

---

⬅️ **Práctica anterior:** [03 — Include Templates](../03-include-templates/README.md)
➡️ **Proyecto:** [Pipeline CI/CD Avanzado](../../3-proyecto/README.md)

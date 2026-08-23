# 🔬 Práctica 02 — Rules Condicionales

## 🎯 Objetivo

Implementar un pipeline que ejecute jobs diferentes según la rama, el tipo de pipeline (MR vs push), la existencia de un tag semántico, y los archivos que cambiaron. Verificar el comportamiento observando qué jobs aparecen en cada contexto.

## ⏱️ Tiempo estimado: 40 minutos

## 📋 Requisitos previos

- Práctica 01 completada (proyecto `api-gateway` con variables configuradas)
- Ramas `main` y `develop` existentes en el proyecto

---

## 📝 Paso 1: Crear la Rama `develop`

```bash
cd /tmp/api-gateway-vars   # o el directorio donde clonaste el proyecto
git checkout main
git pull

# Crear rama develop si no existe
git checkout -b develop
git push origin develop

# Ir a GitLab y proteger la rama develop:
# Settings → Repository → Protected branches → develop → Maintainers
```

---

## 📝 Paso 2: Pipeline Base con Rules por Rama

Copia el starter (`starter/.gitlab-ci.yml`) al proyecto, o crea:

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - deploy

# ── Siempre se ejecuta ──────────────────────────────────────
build:
  stage: build
  image: alpine:latest
  script:
    - echo "Build en rama: ${CI_COMMIT_REF_NAME}"
    - echo "Commit: ${CI_COMMIT_SHORT_SHA}"
    - echo "Pipeline source: ${CI_PIPELINE_SOURCE}"
  rules:
    - when: always

# ── Solo en ramas feature/* ─────────────────────────────────
test-rapido:
  stage: test
  image: alpine:latest
  script:
    - echo "Tests rápidos (smoke tests) para feature branches"
    - echo "Branch: ${CI_COMMIT_REF_NAME}"
  rules:
    - if: $CI_COMMIT_BRANCH =~ /^feature\//
      when: on_success
    - when: never

# ── Solo en main o tags ──────────────────────────────────────
test-completo:
  stage: test
  image: alpine:latest
  script:
    - echo "Tests completos (unit + integration)"
    - echo "Branch: ${CI_COMMIT_REF_NAME}"
    - echo "Tag: ${CI_COMMIT_TAG}"
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: on_success
    - if: $CI_COMMIT_TAG =~ /^v/
      when: on_success
    - when: never

# ── Solo en develop → deploy staging ────────────────────────
deploy-staging:
  stage: deploy
  image: alpine:latest
  script:
    - echo "Desplegando a STAGING..."
    - echo "Branch: ${CI_COMMIT_REF_NAME}"
    - echo "Environment: staging"
  environment:
    name: staging
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"
      when: on_success
    - when: never

# ── Solo tags semánticos, requiere aprobación manual ────────
deploy-production:
  stage: deploy
  image: alpine:latest
  script:
    - echo "Desplegando a PRODUCTION con tag ${CI_COMMIT_TAG}"
  environment:
    name: production
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
      when: manual
      allow_failure: false
    - when: never
```

```bash
git add .gitlab-ci.yml
git commit -m "ci(week-06): practice 02 — conditional rules"
git push origin develop  # push a develop primero
```

---

## 📝 Paso 3: Observar Diferentes Contextos

**3.1 — En `develop` (staging):**

```
Pipeline en develop debe mostrar:
  ✅ build         (always)
  ⏭️ test-rapido   (skipped — no es feature/*)
  ⏭️ test-completo (skipped — no es main/tag)
  ✅ deploy-staging (ejecutado — es develop)
  ⏭️ deploy-production (skipped — no es tag)
```

**3.2 — Crear rama feature y verificar:**

```bash
git checkout -b feature/login-page
git commit --allow-empty -m "feat: add login page"
git push origin feature/login-page
```

```
Pipeline en feature/login-page debe mostrar:
  ✅ build         (always)
  ✅ test-rapido   (ejecutado — es feature/*)
  ⏭️ test-completo (skipped)
  ⏭️ deploy-staging (skipped)
  ⏭️ deploy-production (skipped)
```

**3.3 — Push a main y verificar:**

```bash
git checkout main
git merge develop
git push origin main
```

```
Pipeline en main debe mostrar:
  ✅ build         (always)
  ⏭️ test-rapido   (skipped)
  ✅ test-completo (ejecutado)
  ⏭️ deploy-staging (skipped — no es develop)
  ⏭️ deploy-production (skipped — no es tag)
```

---

## 📝 Paso 4: Rules con `changes` (archivos específicos)

Agregar al `.gitlab-ci.yml`:

```yaml
# ── Solo si cambiaron archivos de documentación ─────────────
check-docs:
  stage: test
  image: alpine:latest
  script:
    - echo "Verificando documentación..."
    - ls docs/ 2>/dev/null || echo "Sin directorio docs/"
    - find . -name "*.md" | head -5
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - "*.md"
        - "docs/**/*"
        - "README*"
      when: on_success
    - when: never

# ── Solo si cambiaron archivos de configuración de CI ───────
validate-ci:
  stage: build
  image: alpine:latest
  script:
    - echo "Validando cambios en la configuración CI..."
    - echo "Archivo .gitlab-ci.yml modificado — revisando sintaxis"
  rules:
    - changes:
        - ".gitlab-ci.yml"
        - ".gitlab/ci/*.yml"
      when: on_success
    - when: never
```

Para probar `changes`, necesitas crear un Merge Request:

```bash
git checkout -b feature/update-docs
# Crear o modificar un archivo markdown
echo "# Actualización de docs" >> docs/README.md
git add docs/README.md
git commit -m "docs: update README"
git push origin feature/update-docs
```

Luego crear un MR via UI o API:

```bash
# ¿QUÉ HACE?: Crea un Merge Request via API para triggear el pipeline de MR
# ¿POR QUÉ?: Los pipelines de MR solo se ejecutan cuando hay un MR abierto
# ¿PARA QUÉ?: Probar las rules con if: $CI_PIPELINE_SOURCE == "merge_request_event"

PROJECT_ID=<tu-project-id>

curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "source_branch": "feature/update-docs",
    "target_branch": "main",
    "title": "Actualizar documentación",
    "description": "Test de rules con changes"
  }' \
  "http://localhost/api/v4/projects/${PROJECT_ID}/merge_requests" \
  | python3 -c "
import sys, json
mr = json.load(sys.stdin)
print(f'MR !{mr[\"iid\"]} creado: {mr[\"web_url\"]}')
"
```

```
Pipeline del MR debe mostrar:
  ✅ validate-ci   (skipped si no cambiaste .gitlab-ci.yml)
  ✅ check-docs    (ejecutado — archivos .md cambiaron + es MR)
```

---

## 📝 Paso 5: Tag Semántico — Deploy a Producción

```bash
git checkout main

# ¿QUÉ HACE?: Crea un tag semántico que dispara el pipeline de production
# ¿POR QUÉ?: La rule de deploy-production solo activa en tags /^v\d+\.\d+\.\d+$/
# ¿PARA QUÉ?: Simular un release de producción controlado

git tag -a v1.0.0 -m "Release 1.0.0 — practice 02"
git push origin v1.0.0
```

```
Pipeline del tag v1.0.0 debe mostrar:
  ✅ build
  ✅ test-completo    (tags también lo activan)
  ⏭️ deploy-staging  (skipped)
  ⏸️ deploy-production (disponible pero esperando click manual)
```

Hacer click en `deploy-production` → Confirmar → Observar ejecución.

---

## 📝 Paso 6: Inspeccionar Pipelines via API

```bash
# ¿QUÉ HACE?: Lista los últimos pipelines con su fuente y rama
# ¿POR QUÉ?: Verificar programáticamente que los pipelines se dispararon correctamente
# ¿PARA QUÉ?: Automatizar la verificación en scripts de QA

curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/${PROJECT_ID}/pipelines?per_page=10" \
  | python3 -c "
import sys, json
pipelines = json.load(sys.stdin)
icons = {'success': '✅', 'failed': '❌', 'running': '🔄', 'pending': '⏳', 'canceled': '⏹️', 'skipped': '⏭️', 'manual': '⏸️'}
print(f'{'ID':<6} {'Estado':<12} {'Fuente':<22} {'Ref':<30}')
print('-' * 72)
for p in pipelines:
    icon = icons.get(p['status'], '?')
    print(f'{p[\"id\"]:<6} {icon + \" \" + p[\"status\"]:<12} {p.get(\"source\", \"?\"):<22} {p[\"ref\"]:<30}')
"
```

Verifica que tienes pipelines con `source = push`, `source = merge_request_event` y `source = push` (para tags).

---

## 🔧 Troubleshooting

**Job aparece aunque la `rule` debería saltarlo**
```
→ Revisar el orden de reglas — "primer match gana"
→ Agregar un log de depuración: echo "Source: $CI_PIPELINE_SOURCE, Branch: $CI_COMMIT_BRANCH"
→ Usar el CI Lint: Proyecto → CI/CD → Pipelines → CI Lint
```

**`changes` no funciona como se esperaba**
```
→ `changes` solo funciona correctamente en pipelines de merge_request_event
→ En pipelines de push, compara con el commit anterior, no con el base de la MR
→ Para push: usar rules con if + changes combinados
```

**Tag creado pero pipeline no aparece con `CI_COMMIT_TAG`**
```
→ Verificar que el tag se hizo push: git push origin v1.0.0
→ La variable $CI_COMMIT_TAG solo está definida en pipelines de tag
→ En pipelines de rama, $CI_COMMIT_TAG está vacía/null
```

---

## ✅ Checklist de verificación

- [ ] En `develop`: solo `build` y `deploy-staging` se ejecutan
- [ ] En `feature/*`: solo `build` y `test-rapido` se ejecutan
- [ ] En `main`: solo `build` y `test-completo` se ejecutan
- [ ] En tag `v1.0.0`: `build`, `test-completo` y `deploy-production` (manual)
- [ ] En MR con cambios en `.md`: `check-docs` se ejecuta
- [ ] API lista los pipelines con sus `source` correctos

## 📦 Entregables

- [ ] Captura del pipeline en `develop` mostrando `deploy-staging` ✅ y los demás ⏭️
- [ ] Captura del pipeline en `feature/*` mostrando solo `test-rapido` ✅
- [ ] Captura del pipeline del tag `v1.0.0` con `deploy-production` en estado manual ⏸️
- [ ] Captura del pipeline del MR mostrando `check-docs` activado por `changes`

---

⬅️ **Práctica anterior:** [01 — Variables y Secretos](../01-variables-y-secretos/README.md)
➡️ **Siguiente práctica:** [03 — Include Templates](../03-include-templates/README.md)

# 🔬 Práctica 01 — Variables y Secretos

## 🎯 Objetivo

Configurar variables de pipeline, de proyecto y enmascaradas. Verificar la prioridad de variables y proteger secretos para que nunca aparezcan en texto plano en los logs.

## ⏱️ Tiempo estimado: 35 minutos

## 📋 Requisitos previos

- Proyecto `bootcamp-org/backend/api-gateway` de semanas anteriores
- GitLab Runner en línea
- `$GITLAB_TOKEN` disponible en la sesión de terminal

---

## 📝 Paso 1: Verificar el Proyecto Base

```bash
# ¿QUÉ HACE?: Obtiene el ID del proyecto para usar en calls posteriores
# ¿POR QUÉ?: La API de GitLab usa IDs numéricos, no rutas
# ¿PARA QUÉ?: Variable reutilizable para todos los pasos siguientes

PROJECT_PATH="bootcamp-org/backend/api-gateway"

PROJECT_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects?search=api-gateway" \
  | python3 -c "
import sys, json
projects = json.load(sys.stdin)
matches = [p for p in projects if 'bootcamp-org' in p.get('path_with_namespace', '')]
if matches:
    print(matches[0]['id'])
else:
    print('NOT_FOUND')
")

echo "Project ID: $PROJECT_ID"
```

Salida esperada: `Project ID: 7` (o algún número)

---

## 📝 Paso 2: Pipeline con Variables Globales y de Job

Clona o navega al proyecto y crea el archivo:

```bash
cd /tmp
git clone http://root:$GITLAB_ADMIN_PASS@localhost/bootcamp-org/backend/api-gateway.git api-gateway-vars
cd api-gateway-vars
git checkout main
```

Copia el starter (`starter/.gitlab-ci.yml`) o crea desde cero:

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test

variables:
  # Variables globales — visibles en todos los jobs
  APP_NAME: "bootcamp-api"
  APP_VERSION: "1.0.0"
  NODE_VERSION: "18"

# ── Variables de pipeline visibles en logs ──────────────────
mostrar-variables:
  stage: build
  image: alpine:latest
  variables:
    # Job-level sobreescribe global para este job
    NODE_VERSION: "20"        # este job usa Node 20 aunque el global diga 18
  script:
    - echo "=== Variables Globales ==="
    - echo "App: ${APP_NAME}"
    - echo "Version: ${APP_VERSION}"
    - echo "Node version (sobreescrita): ${NODE_VERSION}"
    - echo ""
    - echo "=== Variables Predefinidas de GitLab ==="
    - echo "Branch: ${CI_COMMIT_REF_NAME}"
    - echo "Commit SHA: ${CI_COMMIT_SHORT_SHA}"
    - echo "Pipeline ID: ${CI_PIPELINE_ID}"
    - echo "Job ID: ${CI_JOB_ID}"
    - echo "Project: ${CI_PROJECT_PATH}"
    - echo "Runner: ${CI_RUNNER_DESCRIPTION}"

# ── Variable enmascarada (configurada en Settings) ──────────
usar-secreto:
  stage: test
  image: alpine:latest
  script:
    # CI_JOB_TOKEN es un token temporal del job — no necesita configuración
    - echo "Job token disponible: ${CI_JOB_TOKEN:0:10}..."
    # SECRET_TOKEN debe configurarse en el paso siguiente
    - |
      if [ -n "$SECRET_TOKEN" ]; then
        echo "SECRET_TOKEN definido (${#SECRET_TOKEN} caracteres)"
        echo "Valor enmascarado: ${SECRET_TOKEN}"  # GitLab mostrará ****
      else
        echo "SECRET_TOKEN no definido aún — ver Paso 3"
      fi
  rules:
    - when: always
```

```bash
git add .gitlab-ci.yml
git commit -m "ci(week-06): practice 01 — pipeline variables"
git push origin main
```

**Observar en la UI:**
```
http://localhost/bootcamp-org/backend/api-gateway/-/pipelines

→ Abrir el job "mostrar-variables"
→ Verificar que NODE_VERSION muestra "20" (sobreescritura job-level)
→ Verificar que CI_COMMIT_SHORT_SHA muestra el SHA del commit
```

---

## 📝 Paso 3: Configurar Variable Enmascarada via API

```bash
# ¿QUÉ HACE?: Crea la variable SECRET_TOKEN en el proyecto via API
# ¿POR QUÉ?: Simula cómo se añaden secretos sin commitearlos en el repo
# ¿PARA QUÉ?: El pipeline puede acceder al secreto sin que el código lo contenga

curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "key": "SECRET_TOKEN",
    "value": "super-secreto-bootcamp-2025",
    "masked": true,
    "protected": false,
    "description": "Token de prueba para practica 01"
  }' \
  "http://localhost/api/v4/projects/${PROJECT_ID}/variables" \
  | python3 -c "
import sys, json
result = json.load(sys.stdin)
if 'key' in result:
    print(f'✅ Variable creada: {result[\"key\"]}')
    print(f'   Masked: {result[\"masked\"]}')
    print(f'   Protected: {result[\"protected\"]}')
else:
    print(f'❌ Error: {result}')
"
```

Ahora dispara un nuevo pipeline:

```bash
# ¿QUÉ HACE?: Dispara un pipeline manualmente via API
# ¿POR QUÉ?: Evita tener que hacer un commit solo para probar variables
# ¿PARA QUÉ?: Verificar que SECRET_TOKEN está disponible en el job

curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"ref": "main"}' \
  "http://localhost/api/v4/projects/${PROJECT_ID}/pipeline" \
  | python3 -c "
import sys, json
p = json.load(sys.stdin)
print(f'Pipeline #{p[\"id\"]} creado: {p[\"web_url\"]}')
"
```

**Observar en los logs del job `usar-secreto`:**
```
SECRET_TOKEN definido (26 caracteres)
Valor enmascarado: ****
```

El valor real nunca aparece — GitLab lo reemplaza automáticamente por `****`.

---

## 📝 Paso 4: Verificar la Prioridad de Variables

```bash
# ¿QUÉ HACE?: Crea una variable de proyecto con el mismo nombre que una del pipeline
# ¿POR QUÉ?: Para demostrar que el pipeline global tiene mayor prioridad que Settings
# ¿PARA QUÉ?: Entender el orden de precedencia en la práctica

curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"key": "APP_NAME", "value": "desde-settings", "masked": false}' \
  "http://localhost/api/v4/projects/${PROJECT_ID}/variables" \
  | python3 -c "
import sys, json
r = json.load(sys.stdin)
print(f'Variable APP_NAME en Settings: {r.get(\"value\", r)}')
"
```

Dispara un nuevo pipeline. ¿Qué valor muestra `APP_NAME` en los logs?

```
# Respuesta esperada: "bootcamp-api" (el del .gitlab-ci.yml gana)
# porque variables globales del pipeline tienen mayor prioridad que Settings
```

---

## 📝 Paso 5: Variable Protegida (solo en ramas protegidas)

```bash
# Crear variable protegida — solo disponible en ramas protegidas (main)
curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "key": "PROD_DEPLOY_TOKEN",
    "value": "token-produccion-secreto",
    "masked": true,
    "protected": true
  }' \
  "http://localhost/api/v4/projects/${PROJECT_ID}/variables" \
  | python3 -c "import sys,json; r=json.load(sys.stdin); print(f'Creada: {r.get(\"key\")} protected={r.get(\"protected\")}')"
```

Agrega este job al `.gitlab-ci.yml`:

```yaml
verificar-proteccion:
  stage: test
  image: alpine:latest
  script:
    - |
      if [ -n "$PROD_DEPLOY_TOKEN" ]; then
        echo "PROD_DEPLOY_TOKEN DISPONIBLE (estamos en rama protegida)"
      else
        echo "PROD_DEPLOY_TOKEN VACÍO — esta rama no es protegida"
      fi
  rules:
    - when: always
```

```bash
git add .gitlab-ci.yml
git commit -m "ci(week-06): add protected variable test"
git push origin main

# Crear rama no-protegida y hacer push
git checkout -b feature/test-variables
git commit --allow-empty -m "test: check protected var on feature branch"
git push origin feature/test-variables
```

**Resultado esperado:**
- Pipeline en `main` → `PROD_DEPLOY_TOKEN DISPONIBLE`
- Pipeline en `feature/test-variables` → `PROD_DEPLOY_TOKEN VACÍO`

---

## 📝 Paso 6: Listar Variables del Proyecto via API

```bash
# ¿QUÉ HACE?: Lista todas las variables configuradas en el proyecto
# ¿POR QUÉ?: Auditar qué variables existen sin entrar a la UI
# ¿PARA QUÉ?: Automatizar la documentación o verificación de la configuración

curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/${PROJECT_ID}/variables" \
  | python3 -c "
import sys, json
vars = json.load(sys.stdin)
print(f'Variables configuradas en el proyecto ({len(vars)} total):')
print(f'{'Nombre':<25} {'Masked':<8} {'Protected':<11} {'Tipo':<8}')
print('-' * 55)
for v in sorted(vars, key=lambda x: x['key']):
    print(f'{v[\"key\"]:<25} {str(v[\"masked\"]):<8} {str(v[\"protected\"]):<11} {v.get(\"variable_type\", \"env_var\"):<8}')
"
```

---

## 🔧 Troubleshooting

**Variable enmascarada no aparece como `****`**
```
→ El valor no cumple los requisitos de enmascaramiento:
   - Mínimo 8 caracteres
   - Sin espacios ni saltos de línea
   - Sin caracteres: " ' ` \
→ Verificar en Settings → CI/CD → Variables → Edit
```

**Variable protegida vacía en rama main**
```
→ La rama "main" debe estar marcada como protegida
→ Verificar: Settings → Repository → Protected branches
→ Si no está protegida, agregar "main" con roles Maintainer
```

**`curl: Could not resolve host`**
```
→ Usar "localhost" o la IP del servidor GitLab, no "gitlab.example.com"
→ Verificar: curl -v http://localhost/api/v4/version
```

---

## ✅ Checklist de verificación

- [ ] Job `mostrar-variables` muestra `NODE_VERSION: 20` (sobreescritura a nivel job)
- [ ] Job `mostrar-variables` muestra variables predefinidas (`CI_COMMIT_SHORT_SHA`, etc.)
- [ ] Job `usar-secreto` muestra `****` en lugar del valor real de `SECRET_TOKEN`
- [ ] Variable `APP_NAME` en Settings es sobreescrita por la del `.gitlab-ci.yml`
- [ ] `PROD_DEPLOY_TOKEN` disponible en `main` pero vacía en `feature/*`
- [ ] Listado de variables via API funciona correctamente

## 📦 Entregables

- [ ] Captura de logs del job `mostrar-variables` con las variables predefinidas visibles
- [ ] Captura mostrando `SECRET_TOKEN: ****` (enmascarada) en los logs
- [ ] Captura del job `verificar-proteccion` en `main` (disponible) y en `feature/` (vacía)
- [ ] Output del comando de listado de variables via API

---

⬅️ **Teoría:** [01 — Variables CI/CD](../../1-teoria/01-variables-ci-cd.md)
➡️ **Siguiente práctica:** [02 — Rules Condicionales](../02-rules-condicionales/README.md)

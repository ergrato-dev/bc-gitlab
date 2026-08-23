# 🔬 Práctica 01 — Primer Pipeline CI

## 🎯 Objetivo

Crear el pipeline más simple posible, entender la relación entre `.gitlab-ci.yml` y la UI de GitLab CI, y explorar las variables predefinidas disponibles en todos los jobs.

## ⏱️ Tiempo estimado: 30 minutos

## 📋 Requisitos previos

- Proyecto `bootcamp-org/backend/api-gateway` de semanas anteriores
- GitLab Runner en línea (verificar en Admin → Runners)
- `$GITLAB_TOKEN` disponible

---

## 📝 Paso 1: Verificar que el Runner está Activo

```bash
# ¿QUÉ HACE?: Lista los runners disponibles en el servidor
# ¿POR QUÉ?: Sin runners activos, los jobs se quedan en "pending" indefinidamente
# ¿PARA QUÉ?: Confirmar el setup antes de crear pipelines

curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/runners?type=instance_type&status=online" \
  | python3 -c "
import sys, json
runners = json.load(sys.stdin)
if not runners:
    print('❌ Sin runners online — verifica en Admin → Runners')
else:
    print(f'✅ {len(runners)} runner(s) online:')
    for r in runners:
        print(f'   #{r[\"id\"]}: {r.get(\"description\", \"N/A\")} ({r.get(\"executor\", \"N/A\")})')
"
```

---

## 📝 Paso 2: Crear el Primer .gitlab-ci.yml

```bash
cd /tmp/api-gw-mr-practice  # O el directorio del proyecto clonado
git checkout main
git pull

# Crear el archivo de pipeline más simple posible
cat > .gitlab-ci.yml << 'YAML_EOF'
# Pipeline mínimo — Práctica 01 de CI/CD

stages:
  - saludar

hola-mundo:
  stage: saludar
  script:
    - echo "¡Hola, GitLab CI!"
    - echo "Fecha y hora: $(date)"
    - echo "Usuario del runner: $(whoami)"
    - echo "Directorio de trabajo: $(pwd)"
    - ls -la
YAML_EOF

git add .gitlab-ci.yml
git commit -m "ci: add minimal pipeline for CI/CD practice"
git push origin main
```

---

## 📝 Paso 3: Observar el Pipeline en la UI

```
http://localhost/bootcamp-org/backend/api-gateway/-/pipelines

Debe aparecer un pipeline recién creado:
  Pipeline #N   ●running / ✅passed / ❌failed
  Triggered by: root (o el usuario que hizo el push)
  Commit: "ci: add minimal pipeline..."
  Duration: ~30 segundos
```

Click en el pipeline → Click en el job `hola-mundo` → ver los logs:

```
$ echo "¡Hola, GitLab CI!"
¡Hola, GitLab CI!
$ echo "Fecha y hora: $(date)"
Fecha y hora: Thu Jan 16 14:32:47 UTC 2025
$ echo "Usuario del runner: $(whoami)"
Usuario del runner: root
$ echo "Directorio de trabajo: $(pwd)"
Directorio de trabajo: /builds/bootcamp-org/backend/api-gateway
$ ls -la
total 16
drwxr-xr-x ...
-rw-r--r-- ... .gitlab-ci.yml
-rw-r--r-- ... README.md
...
```

---

## 📝 Paso 4: Explorar Variables Predefinidas

```bash
cat > .gitlab-ci.yml << 'YAML_EOF'
stages:
  - info

variables:
  MI_VARIABLE: "valor-personalizado"
  MI_ENTORNO: "bootcamp"

explorar-variables:
  stage: info
  script:
    - echo "=== Variables del Proyecto ==="
    - echo "Project: $CI_PROJECT_NAME"
    - echo "Path: $CI_PROJECT_PATH"
    - echo "URL: $CI_PROJECT_URL"
    - echo ""
    - echo "=== Variables del Commit ==="
    - echo "Branch: $CI_COMMIT_BRANCH"
    - echo "SHA: $CI_COMMIT_SHA"
    - echo "Short SHA: $CI_COMMIT_SHORT_SHA"
    - echo "Message: $CI_COMMIT_MESSAGE"
    - echo "Author: $CI_COMMIT_AUTHOR"
    - echo ""
    - echo "=== Variables del Pipeline ==="
    - echo "Pipeline ID: $CI_PIPELINE_ID"
    - echo "Job ID: $CI_JOB_ID"
    - echo "Job Name: $CI_JOB_NAME"
    - echo "Runner: $CI_RUNNER_DESCRIPTION"
    - echo ""
    - echo "=== Variables Personalizadas ==="
    - echo "Mi variable: $MI_VARIABLE"
    - echo "Mi entorno: $MI_ENTORNO"
YAML_EOF

git add .gitlab-ci.yml
git commit -m "ci: explore predefined CI/CD variables"
git push origin main
```

---

## 📝 Paso 5: Validar el .gitlab-ci.yml via API

```bash
# ¿QUÉ HACE?: Valida la sintaxis del archivo sin necesitar hacer push
# ¿POR QUÉ?: Detecta errores antes de disparar un pipeline fallido
# ¿PARA QUÉ?: Ahorra el ciclo de push → esperar → ver que falla → corregir

# Validar el archivo actual:
curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{\"content\": $(cat .gitlab-ci.yml | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')}" \
  "http://localhost/api/v4/ci/lint" \
  | python3 -c "
import sys, json
result = json.load(sys.stdin)
if result.get('valid'):
    print('✅ .gitlab-ci.yml válido')
    print(f'   Stages: {result.get(\"stages\", [])}')
    jobs = result.get('jobs', [])
    print(f'   Jobs ({len(jobs)}): {[j[\"name\"] for j in jobs]}')
else:
    print('❌ Errores en .gitlab-ci.yml:')
    for error in result.get('errors', []):
        print(f'   - {error}')
"
```

Probar con un YAML inválido:

```bash
# Crear YAML con error intencional:
cat > /tmp/test-invalid.yml << 'YAML_EOF'
stages:
  - test

test-job:
 script:            # ← Indentación incorrecta (1 espacio en lugar de 2)
    - echo "test"
YAML_EOF

curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{\"content\": $(cat /tmp/test-invalid.yml | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')}" \
  "http://localhost/api/v4/ci/lint" \
  | python3 -c "
import sys, json
result = json.load(sys.stdin)
print(f'Válido: {result.get(\"valid\")}')
for error in result.get('errors', []):
    print(f'Error: {error}')
"
```

---

## 📝 Paso 6: Ver el Pipeline via API

```bash
PROJECT_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects?search=api-gateway" \
  | python3 -c "
import sys,json
projects=[p for p in json.load(sys.stdin) if 'bootcamp-org' in p['path_with_namespace']]
print(projects[0]['id'])
")

# ¿QUÉ HACE?: Lista los pipelines del proyecto con su estado
# ¿POR QUÉ?: Verificar programáticamente el estado del pipeline (útil para scripting)
# ¿PARA QUÉ?: Integración con herramientas externas que necesitan saber si el pipeline pasó
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/pipelines?per_page=5" \
  | python3 -c "
import sys, json
pipelines = json.load(sys.stdin)
print(f'Últimos {len(pipelines)} pipelines:')
for p in pipelines:
    status_icon = '✅' if p['status'] == 'success' else ('❌' if p['status'] == 'failed' else '🔄')
    print(f'  {status_icon} #{p[\"id\"]} [{p[\"status\"]:10}] {p[\"ref\"]} — {p[\"sha\"][:8]}')
"
```

---

## 🔧 Troubleshooting

**Pipeline en estado "pending" indefinidamente**
```
→ No hay runners activos
→ Verificar: Admin Area → Runners (necesitas ser admin)
→ O via API: /api/v4/runners?type=instance_type&status=online
→ Solución: configurar un runner o usar el runner compartido del bootcamp
```

**Error "no stages" o "invalid YAML"**
```
→ Usar el CI Lint para validar: Proyecto → CI/CD → Pipelines → CI Lint
→ Errores comunes: tabs en lugar de espacios, indentación inconsistente
```

---

## ✅ Checklist de verificación

- [ ] Runner online confirmado via API
- [ ] Pipeline `hola-mundo` ejecutado y en estado "Passed"
- [ ] Variables predefinidas visibles en los logs del job
- [ ] CI Lint confirma que el YAML es válido
- [ ] CI Lint detecta correctamente el YAML inválido de prueba
- [ ] API lista los pipelines del proyecto

## 📦 Entregables

- [ ] Captura de `CI/CD → Pipelines` mostrando el pipeline exitoso
- [ ] Captura de los logs del job `explorar-variables` mostrando las variables predefinidas
- [ ] Output del CI Lint API para el YAML válido
- [ ] El archivo `.gitlab-ci.yml` committeado en `main`

---

➡️ **Siguiente práctica:** [02 — Múltiples Stages y Jobs](../02-stages-y-jobs/README.md)

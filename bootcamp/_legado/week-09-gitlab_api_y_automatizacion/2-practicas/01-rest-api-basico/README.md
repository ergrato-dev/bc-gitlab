# Práctica 01 — REST API Básico con curl

**Duración estimada:** 35 minutos
**Dificultad:** ⭐⭐ (Media)

## 🎯 Objetivo

Realizar operaciones CRUD completas contra la API REST de GitLab usando `curl`: crear proyecto, gestionar issues, disparar pipelines, inspeccionar paginación y rate limiting.

---

## 📋 Prerrequisitos

```bash
# Crear PAT con scope "api" via API de administración
curl --silent --request POST \
  --header "PRIVATE-TOKEN: tu-token-admin" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "practica-rest-api",
    "scopes": ["api"],
    "expires_at": "2026-12-31",
    "user_id": 1
  }' \
  "http://localhost/api/v4/users/1/personal_access_tokens" \
  | python3 -c "
import sys, json
t = json.load(sys.stdin)
print(f'export GITLAB_TOKEN=\"{t[\"token\"]}\"')
"

# O crear desde la UI: avatar → Edit profile → Access Tokens

# Exportar variables
export GITLAB_URL="http://localhost"
export GITLAB_TOKEN="glpat-xxxxxxxxxxxx"

# Verificar autenticación
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/user" \
  | python3 -c "import sys,json; u=json.load(sys.stdin); print(f'✅ Usuario: {u[\"username\"]} (ID: {u[\"id\"]})')"
```

---

## Paso 1: Explorar la API — Versión y Capacidades

```bash
# Versión de GitLab (sin autenticación)
curl --silent "$GITLAB_URL/api/v4/version" | python3 -m json.tool

# Estadísticas de la instancia (sin autenticación)
curl --silent "$GITLAB_URL/api/v4/application/statistics" \
  | python3 -c "
import sys, json
s = json.load(sys.stdin)
print(f'Proyectos: {s.get(\"projects\")}')
print(f'Usuarios: {s.get(\"users\")}')
print(f'Grupos: {s.get(\"groups\")}')
print(f'MRs: {s.get(\"merge_requests\")}')
"
```

---

## Paso 2: CRUD de Proyectos

```bash
# ¿QUÉ HACE?: Crea un proyecto de práctica para los ejercicios siguientes
# ¿POR QUÉ?: Necesitamos un proyecto propio donde crear issues, MRs y pipelines
# ¿PARA QUÉ?: Tener un sandbox limpio de API sin tocar proyectos reales

PROJECT_ID=$(curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "api-practice-lab",
    "description": "Proyecto para práctica de la API REST",
    "visibility": "private",
    "initialize_with_readme": true
  }' \
  "$GITLAB_URL/api/v4/projects" \
  | python3 -c "
import sys, json
p = json.load(sys.stdin)
print(p['id'])
import os; open('/tmp/gl_project_id.txt','w').write(str(p['id']))
")

export GITLAB_PROJECT_ID=$PROJECT_ID
echo "Proyecto creado: ID=$PROJECT_ID"
echo "$PROJECT_ID" > /tmp/gl_project_id.txt

# Verificar el proyecto creado
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$GITLAB_PROJECT_ID" \
  | python3 -c "
import sys, json
p = json.load(sys.stdin)
print(f'Nombre: {p[\"name\"]}')
print(f'URL: {p[\"web_url\"]}')
print(f'Visibilidad: {p[\"visibility\"]}')
print(f'Default branch: {p[\"default_branch\"]}')
"
```

---

## Paso 3: Gestión de Issues

```bash
# Crear 5 issues de prueba con diferentes labels
for i in 1 2 3 4 5; do
  curl --silent --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{
      \"title\": \"Issue de práctica #$i\",
      \"description\": \"Creado via API REST — iteración $i\",
      \"labels\": \"$([ $((i % 2)) -eq 0 ] && echo 'bug' || echo 'feature'),practica\",
      \"weight\": $i
    }" \
    "$GITLAB_URL/api/v4/projects/$GITLAB_PROJECT_ID/issues" \
    | python3 -c "import sys,json; i=json.load(sys.stdin); print(f'  Issue #{i[\"iid\"]} creado: {i[\"title\"]}')"
done

# Listar issues y analizar la respuesta de paginación
echo ""
echo "=== Issues del proyecto ==="
curl --silent \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --dump-header /tmp/gl_headers.txt \
  "$GITLAB_URL/api/v4/projects/$GITLAB_PROJECT_ID/issues?per_page=3&page=1" \
  | python3 -c "
import sys, json
issues = json.load(sys.stdin)
print(f'Issues en esta página: {len(issues)}')
for i in issues:
    print(f'  #{i[\"iid\"]} [{\"|\".join(i[\"labels\"])}] {i[\"title\"]}')
"

echo ""
echo "=== Headers de paginación ==="
grep -i 'X-Total\|X-Page\|X-Per-Page\|X-Next' /tmp/gl_headers.txt | grep -v '::'

# Cerrar el issue #1
ISSUE_1_IID=1
curl --silent --request PUT \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"state_event":"close","labels":"bug,practica,cerrado"}' \
  "$GITLAB_URL/api/v4/projects/$GITLAB_PROJECT_ID/issues/$ISSUE_1_IID" \
  | python3 -c "
import sys, json
i = json.load(sys.stdin)
print(f'Issue #{i[\"iid\"]} cerrado — estado: {i[\"state\"]}')
"
```

---

## Paso 4: Ramas y Merge Requests

```bash
# Crear una rama para el MR
curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"branch":"feature/api-test","ref":"main"}' \
  "$GITLAB_URL/api/v4/projects/$GITLAB_PROJECT_ID/repository/branches" \
  | python3 -c "
import sys, json
b = json.load(sys.stdin)
print(f'Rama creada: {b[\"name\"]} → commit: {b[\"commit\"][\"short_id\"]}')
"

# Crear un commit en la rama (modificar un archivo)
curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "branch": "feature/api-test",
    "commit_message": "docs: añadir notas de la práctica API",
    "actions": [
      {
        "action": "create",
        "file_path": "NOTAS.md",
        "content": "# Notas de práctica\n\nArchivo creado via API REST de GitLab.\n"
      }
    ]
  }' \
  "$GITLAB_URL/api/v4/projects/$GITLAB_PROJECT_ID/repository/commits" \
  | python3 -c "
import sys, json
c = json.load(sys.stdin)
print(f'Commit: {c[\"short_id\"]} — {c[\"title\"]}')
"

# Crear MR
MR_IID=$(curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "source_branch": "feature/api-test",
    "target_branch": "main",
    "title": "feat: práctica de REST API",
    "description": "MR creado via API REST. Closes #2 #3",
    "remove_source_branch": false
  }' \
  "$GITLAB_URL/api/v4/projects/$GITLAB_PROJECT_ID/merge_requests" \
  | python3 -c "
import sys, json
mr = json.load(sys.stdin)
print(mr['iid'])
import os; open('/tmp/gl_mr_iid.txt','w').write(str(mr['iid']))
")

echo "MR creado: !$MR_IID"

# Ver el MR creado
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$GITLAB_PROJECT_ID/merge_requests/$MR_IID" \
  | python3 -c "
import sys, json
mr = json.load(sys.stdin)
print(f'MR !{mr[\"iid\"]}: {mr[\"title\"]}')
print(f'  Estado: {mr[\"state\"]}')
print(f'  {mr[\"source_branch\"]} → {mr[\"target_branch\"]}')
print(f'  URL: {mr[\"web_url\"]}')
"
```

---

## Paso 5: Pipelines via API

```bash
# Verificar si el proyecto tiene .gitlab-ci.yml (puede no tenerlo en este lab)
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$GITLAB_PROJECT_ID/repository/files/.gitlab-ci.yml?ref=main" \
  | python3 -c "
import sys, json
r = json.load(sys.stdin)
if 'message' in r:
    print(f'⚠️ Sin .gitlab-ci.yml: {r[\"message\"]}')
else:
    print(f'✅ .gitlab-ci.yml existe ({r[\"size\"]} bytes)')
"

# Listar pipelines (puede estar vacío si no hay CI)
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$GITLAB_PROJECT_ID/pipelines?per_page=5" \
  | python3 -c "
import sys, json
pips = json.load(sys.stdin)
print(f'Pipelines: {len(pips)}')
for p in pips:
    print(f'  #{p[\"id\"]} [{p[\"status\"]}] {p[\"ref\"]}')
"
```

---

## Paso 6: Inspeccionar Rate Limiting

```bash
# ¿QUÉ HACE?: Hace 10 peticiones rápidas y monitorea el rate limit restante
# ¿POR QUÉ?: Entender el comportamiento antes de escribir scripts masivos
# ¿PARA QUÉ?: Evitar 429 en scripts de automatización real

for i in $(seq 1 10); do
  remaining=$(curl --silent --head \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    "$GITLAB_URL/api/v4/projects?page=$i" \
    | grep -i 'RateLimit-Remaining' | awk '{print $2}' | tr -d '\r')
  echo "  Petición $i — Remaining: $remaining"
done

# Verificar qué pasa con un token inválido
echo ""
echo "=== Token inválido ==="
HTTP=$(curl --silent --output /dev/null --write-out "%{http_code}" \
  --header "PRIVATE-TOKEN: token-falso-para-prueba" \
  "$GITLAB_URL/api/v4/user")
echo "HTTP con token inválido: $HTTP (esperado: 401)"
```

---

## ✅ Checklist de verificación

- [ ] PAT creado con scope `api` y exportado en `$GITLAB_TOKEN`
- [ ] `GET /api/v4/user` devuelve el perfil del usuario autenticado
- [ ] Proyecto `api-practice-lab` creado via API (ver en la UI)
- [ ] 5 issues creados; issue #1 cerrado via `state_event: close`
- [ ] Rama `feature/api-test` creada y commit añadido
- [ ] MR creado con `source_branch: feature/api-test`
- [ ] Headers de paginación `X-Total`, `X-Next-Page` observados
- [ ] HTTP 401 confirmado al usar token inválido

---

## 🏆 Reto adicional

Consultar la API de todos los proyectos del usuario e identificar cuáles no tuvieron actividad (ningún push, issue ni MR) en los últimos 30 días:

```bash
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects?owned=true&per_page=100" \
  | python3 -c "
import sys, json
from datetime import datetime, timezone, timedelta

projects = json.load(sys.stdin)
cutoff = datetime.now(timezone.utc) - timedelta(days=30)

print('Proyectos sin actividad en 30 días:')
for p in projects:
    last = p.get('last_activity_at', '')
    if last:
        last_dt = datetime.fromisoformat(last.replace('Z', '+00:00'))
        if last_dt < cutoff:
            print(f'  {p[\"path_with_namespace\"]} — última actividad: {last[:10]}')
"
```

---

⬅️ **Teoría:** [05 — Automatización Python](../../1-teoria/05-automatizacion-python.md)
➡️ **Siguiente práctica:** [02 — GraphQL](../02-graphql-consultas/README.md)

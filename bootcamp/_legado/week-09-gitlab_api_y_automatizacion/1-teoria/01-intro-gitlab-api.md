# 01 — Introducción a la API REST de GitLab

La API REST de GitLab expone prácticamente toda la funcionalidad de la plataforma como endpoints HTTP. Cualquier acción posible desde la UI — crear un issue, disparar un pipeline, añadir un miembro a un grupo — puede automatizarse via API.

![Diagrama REST API vs GraphQL — métodos de autenticación y comparación](../0-assets/01-rest-vs-graphql.svg)

---

## URL base y versión

```
http://localhost/api/v4/
```

La versión `v4` es la API actual y estable de GitLab. La `v3` fue removida en GitLab 11.0.

```bash
# Verificar que la API responde (sin autenticación)
curl --silent http://localhost/api/v4/version
# → {"version":"16.x.x","revision":"..."}
```

---

## Autenticación

La API soporta cuatro métodos de autenticación:

| Método | Header | Uso típico |
|--------|--------|-----------|
| Personal Access Token (PAT) | `PRIVATE-TOKEN: <token>` | Scripts y automatización personal |
| OAuth2 Token | `Authorization: Bearer <token>` | Aplicaciones de terceros |
| Session Cookie | Cookie de sesión web | Uso en navegador (UI) |
| GitLab CI_JOB_TOKEN | `JOB-TOKEN: $CI_JOB_TOKEN` | Dentro de pipelines |

```bash
# ¿QUÉ HACE?: Autentica la petición con el token del usuario
# ¿POR QUÉ?: El header PRIVATE-TOKEN es el método recomendado por GitLab
# ¿PARA QUÉ?: Acceder a recursos privados sin exponer el token en logs

# Método recomendado: header PRIVATE-TOKEN
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects?owned=true"

# En pipelines: CI_JOB_TOKEN (no requiere configuración)
curl --header "JOB-TOKEN: $CI_JOB_TOKEN" \
  "http://localhost/api/v4/projects/$CI_PROJECT_ID"

# Desaconsejado: query param (token visible en logs del servidor)
curl "http://localhost/api/v4/projects?private_token=$GITLAB_TOKEN"
```

---

## Paginación

GitLab usa paginación basada en `page` y `per_page`. Por defecto: 20 items/página, máximo 100.

```bash
# Obtener hasta 100 items en la primera página
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects?per_page=100&page=1"
```

Los headers de respuesta informan el estado de la paginación:

| Header | Descripción |
|--------|-------------|
| `X-Total` | Total de items en todas las páginas |
| `X-Total-Pages` | Número total de páginas |
| `X-Page` | Página actual |
| `X-Per-Page` | Items por página |
| `X-Next-Page` | Número de la siguiente página (vacío si es la última) |
| `X-Prev-Page` | Número de la página anterior |

```bash
# ¿QUÉ HACE?: Itera todas las páginas hasta agotar los resultados
# ¿POR QUÉ?: Una sola página con per_page=100 puede no ser suficiente
# ¿PARA QUÉ?: Obtener el listado completo de proyectos/issues/etc.

page=1
while true; do
  response=$(curl --silent \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --dump-header /tmp/gl_headers.txt \
    "http://localhost/api/v4/projects?per_page=100&page=$page")

  echo "$response" | python3 -c "
import sys, json
for p in json.load(sys.stdin):
    print(p['path_with_namespace'])
"

  next_page=$(grep -i 'X-Next-Page' /tmp/gl_headers.txt | awk '{print $2}' | tr -d '\r')
  [ -z "$next_page" ] && break
  page=$next_page
done
```

---

## Rate Limiting

GitLab CE auto-administrado: 300 peticiones/minuto para autenticados, 10 para anónimos.

| Header respuesta | Descripción |
|------------------|-------------|
| `RateLimit-Limit` | Límite configurado |
| `RateLimit-Remaining` | Peticiones restantes en la ventana actual |
| `RateLimit-Reset` | Timestamp Unix cuando se reinicia el límite |

Cuando se excede el límite: HTTP 429 + header `Retry-After` (segundos de espera).

```bash
# Ver headers de rate limit en una respuesta
curl --silent --head \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects" \
  | grep -i ratelimit
```

---

## Endpoints principales

### Proyectos

```bash
# Listar proyectos del usuario autenticado
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects?owned=true&per_page=20"

# Obtener un proyecto por ID
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID"

# Crear proyecto
curl --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"name":"mi-proyecto","visibility":"private"}' \
  "http://localhost/api/v4/projects"

# Eliminar proyecto
curl --request DELETE \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID"
```

### Issues

```bash
# Listar issues abiertos
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/issues?state=opened"

# Crear issue
curl --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "title": "Bug en autenticación",
    "description": "El login falla con caracteres especiales en la contraseña",
    "labels": "bug,autenticación",
    "assignee_ids": [1]
  }' \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/issues"

# Cerrar un issue (state_event)
curl --request PUT \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"state_event":"close"}' \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/issues/$ISSUE_IID"
```

### Merge Requests

```bash
# Listar MRs abiertos
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/merge_requests?state=opened"

# Crear MR
curl --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "source_branch": "feature/login",
    "target_branch": "main",
    "title": "feat: implementar nuevo login",
    "description": "Closes #42",
    "assignee_id": 1
  }' \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/merge_requests"

# Hacer merge de un MR
curl --request PUT \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/merge_requests/$MR_IID/merge"
```

### Pipelines

```bash
# Listar pipelines fallidos (últimos 5)
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/pipelines?status=failed&per_page=5"

# Disparar pipeline con variables
curl --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "ref": "main",
    "variables": [
      {"key": "DEPLOY_ENV", "value": "staging"},
      {"key": "FORCE_REBUILD", "value": "true"}
    ]
  }' \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/pipeline"

# Cancelar pipeline en ejecución
curl --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/pipelines/$PIPELINE_ID/cancel"
```

### Ramas y Tags

```bash
# Crear rama desde main
curl --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"branch":"feature/nueva-funcion","ref":"main"}' \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/repository/branches"

# Crear tag de release
curl --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"tag_name":"v2.0.0","ref":"main","message":"Release 2.0.0"}' \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/repository/tags"
```

---

## Manejo de errores HTTP

| Código | Significado | Acción |
|--------|-------------|--------|
| 200 / 201 | OK / Creado | Éxito |
| 204 | Sin contenido | Éxito en DELETE |
| 400 | Bad Request | Revisar payload JSON |
| 401 | Unauthorized | Token inválido o expirado |
| 403 | Forbidden | Permisos insuficientes |
| 404 | Not Found | ID de recurso incorrecto o sin acceso |
| 409 | Conflict | Recurso ya existe (ej: tag duplicado) |
| 422 | Unprocessable Entity | Validación fallida (ej: título vacío) |
| 429 | Too Many Requests | Rate limit — esperar `Retry-After` |
| 500 | Server Error | Error interno de GitLab |

```bash
# ¿QUÉ HACE?: Verifica el código HTTP y actúa según el resultado
# ¿POR QUÉ?: curl por defecto no falla aunque reciba 404 o 500
# ¿PARA QUÉ?: Scripts robustos que detectan y manejan errores de la API

HTTP_CODE=$(curl --silent --output /dev/null --write-out "%{http_code}" \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID")

case "$HTTP_CODE" in
  200) echo "✅ Proyecto accesible" ;;
  401) echo "❌ Token inválido o expirado" ;;
  403) echo "❌ Sin permisos sobre el proyecto" ;;
  404) echo "❌ Proyecto no encontrado (o sin acceso)" ;;
  429) echo "⚠️ Rate limit alcanzado — esperar Retry-After" ;;
  *)   echo "⚠️ Código inesperado: $HTTP_CODE" ;;
esac
```

---

## Filtros y ordenamiento

La mayoría de endpoints de listado aceptan parámetros de filtro:

```bash
# Issues asignados al usuario actual, ordenados por fecha de actualización descendente
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/issues?\
assignee_username=mi-usuario&\
state=opened&\
order_by=updated_at&\
sort=desc&\
per_page=20"

# Buscar proyectos por nombre
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects?search=bootcamp&order_by=last_activity_at&sort=desc"
```

---

➡️ **Siguiente:** [02 — GraphQL API](./02-graphql-api.md)

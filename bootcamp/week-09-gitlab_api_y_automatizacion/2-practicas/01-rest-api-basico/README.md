# Práctica 01 — REST API Básico

## Objetivo

Realizar operaciones CRUD contra la API REST de GitLab usando `curl`.

## Instrucciones

1. Crea un Personal Access Token con scope `api`
2. Exporta el token y la URL base como variables de entorno:
   ```bash
   export GITLAB_URL="http://localhost:8080"
   export GITLAB_TOKEN="tu-token-aqui"
   ```
3. Realiza las siguientes operaciones:

### Crear proyecto
```bash
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects" \
  --data "name=api-test-project&visibility=private"
```

### Listar issues de un proyecto
```bash
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/:id/issues"
```

### Crear un issue
```bash
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/:id/issues" \
  --data "title=Bug via API&description=Reportado desde curl"
```

### Listar miembros del grupo
```bash
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/groups/:id/members"
```

## Preguntas de reflexión
- ¿Qué headers de paginación recibiste?
- ¿Qué código HTTP devuelve la API al crear un recurso exitosamente?
- ¿Qué pasa si omites el header de autenticación?

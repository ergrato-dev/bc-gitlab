# 01 — Introducción a la API REST de GitLab

La API REST de GitLab permite interactuar programáticamente con casi todos los recursos de la plataforma. El endpoint base es:

```
https://gitlab.example.com/api/v4/
```

## Autenticación

La API soporta cuatro métodos de autenticación:

| Método | Uso típico |
|--------|-----------|
| Personal Access Token (PAT) | Scripts y automatización personal |
| OAuth2 Token | Aplicaciones de terceros |
| Session Cookie | Uso en navegador |
| GitLab CI_JOB_TOKEN | Dentro de pipelines |

Para autenticar con PAT, se envía el header `PRIVATE-TOKEN: <tu-token>` en cada petición. Alternativamente, se puede usar `?private_token=<token>` como parámetro de query, aunque no es recomendado porque el token queda expuesto en logs.

## Paginación

GitLab usa paginación basada en `page` y `per_page`. Por defecto devuelve 20 items por página con un máximo de 100. La respuesta incluye headers HTTP como `X-Total`, `X-Total-Pages`, `X-Page`, `X-Per-Page`, `X-Next-Page` y `X-Prev-Page` para navegar los resultados. Para obtener listados completos, se debe iterar incrementando el parámetro `page` hasta que no se reciban más resultados.

## Rate Limits

En GitLab CE auto-administrado, el rate limit por defecto es de 300 peticiones por minuto para usuarios autenticados y 10 para no autenticados. Los headers `RateLimit-Limit` y `RateLimit-Remaining` informan el estado del límite en cada respuesta. Cuando se excede, la API devuelve HTTP 429 con un header `Retry-After` que indica los segundos de espera.

## Endpoints principales por recurso

- `/projects` — CRUD de proyectos
- `/projects/:id/issues` — Gestión de issues
- `/projects/:id/merge_requests` — Merge requests
- `/projects/:id/pipelines` — Ejecución y consulta de pipelines
- `/projects/:id/repository/branches` — Ramas
- `/groups` — Grupos y subgrupos
- `/users` — Administración de usuarios (requiere permisos admin)

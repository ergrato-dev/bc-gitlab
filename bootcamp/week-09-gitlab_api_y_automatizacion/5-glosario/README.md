# 📖 Glosario — Semana 09: GitLab API y Automatización

Términos ordenados alfabéticamente. Los términos marcados con ↗ remiten a conceptos relacionados en este glosario.

---

## A

**API (Application Programming Interface)**
Conjunto de endpoints HTTP que permiten interactuar programáticamente con GitLab. La API v4 de GitLab (la versión actual) expone prácticamente toda la funcionalidad de la plataforma. Endpoint base: `http://gitlab.host/api/v4/`. Ver también: ↗ REST, ↗ GraphQL.

**Authorization: Bearer**
Header HTTP para autenticación OAuth2 y GraphQL. Formato: `Authorization: Bearer <token>`. Diferente de `PRIVATE-TOKEN` (usado en REST) — aunque GitLab acepta ambos en la API GraphQL para compatibilidad.

---

## B

**Backoff Exponencial**
Estrategia de reintentos donde el tiempo de espera aumenta exponencialmente con cada intento fallido: 2¹=2s, 2²=4s, 2³=8s, etc. Se añade jitter (variación aleatoria) para evitar que múltiples clientes reintenten al mismo tiempo. Usado para manejar rate limits (HTTP 429) sin saturar el servidor.

---

## C

**CI_JOB_TOKEN**
Token efímero generado automáticamente por GitLab para cada job de CI/CD. Disponible como `$CI_JOB_TOKEN` en todos los jobs. Se usa con el header `JOB-TOKEN: $CI_JOB_TOKEN`. Expira cuando el job termina. Por defecto, solo tiene acceso al proyecto que contiene el pipeline. Ver también: ↗ Personal Access Token.

**Cursor (paginación GraphQL)**
Marcador opaco que indica la posición en un conjunto de resultados. A diferencia de la paginación numérica de REST (`page=2`), los cursores de GraphQL son tokens base64 que apuntan a un elemento específico. Se obtiene de `pageInfo.endCursor` y se pasa en el siguiente query como `after: $cursor`.

---

## E

**Endpoint**
URL específica de la API que expone un recurso o funcionalidad. En REST: `GET /api/v4/projects/:id/issues`. En GraphQL hay un único endpoint (`/api/graphql`) y el recurso se especifica en el cuerpo de la petición.

---

## F

**Fragment (GraphQL)**
Conjunto reutilizable de campos que puede incluirse en múltiples queries. Se define con `fragment NombreFragment on Tipo { campos... }` y se usa con `...NombreFragment`. Evita duplicación cuando la misma estructura de campos se necesita en varios lugares del query.

---

## G

**GraphQL**
Lenguaje de query y runtime para APIs, desarrollado por Facebook (Meta) en 2012. A diferencia de REST (un endpoint por recurso), GraphQL usa un único endpoint y el cliente especifica exactamente qué campos quiere en la respuesta. Elimina el over-fetching (recibir campos innecesarios) y el under-fetching (necesitar múltiples peticiones). Ver también: ↗ REST, ↗ Query, ↗ Mutation.

**GraphiQL**
IDE web interactivo incluido en GitLab en `/-/graphql-explorer`. Permite escribir y ejecutar queries GraphQL con autocompletado del esquema, ver la documentación de cada tipo y campo, y guardar queries en el historial del navegador. El punto de partida recomendado para explorar la API GraphQL.

**Group Access Token**
Token a nivel de grupo que otorga acceso a todos los proyectos del grupo y sus subgrupos. Se crea en `Group → Settings → Access Tokens`. Actúa como un bot member del grupo con el rol asignado. Ideal para scripts de auditoría o automatización cross-proyecto. Ver también: ↗ Project Access Token, ↗ Personal Access Token.

---

## H

**HTTP Status Code**
Código numérico en la respuesta HTTP que indica el resultado de la operación. Códigos relevantes en la API de GitLab: 200 (OK), 201 (creado), 204 (sin contenido — DELETE exitoso), 400 (bad request), 401 (no autenticado), 403 (sin permisos), 404 (no encontrado), 409 (conflicto), 422 (validación fallida), 429 (rate limit), 500 (error interno).

---

## I

**Idempotencia**
Propiedad de una operación que produce el mismo resultado sin importar cuántas veces se ejecute. Los métodos HTTP GET, PUT y DELETE son idempotentes. POST no lo es (crear el mismo issue dos veces crea dos issues diferentes). Importante en scripts de automatización: una operación idempotente puede reintentarse sin riesgo de crear duplicados.

**Introspección (GraphQL)**
Capacidad de un servidor GraphQL para responder queries sobre su propio esquema. Usando `__schema`, `__type` y `__field`, se puede descubrir programáticamente qué tipos, campos y mutations existen. La introspección es la base de GraphiQL y de la generación automática de tipos TypeScript.

---

## M

**Mutation (GraphQL)**
Operación GraphQL que modifica datos: crear, actualizar o eliminar. Equivalente a POST/PUT/DELETE de REST. Ejemplo: `mutation { createIssue(input: { projectPath: "..." }) { issue { iid } errors } }`. A diferencia de las queries, las mutations tienen efectos secundarios y no deben ejecutarse en paralelo si son interdependientes.

---

## N

**ngrok**
Herramienta que crea un túnel seguro entre un servidor local y una URL pública temporal. Permite que GitLab (que puede correr en un contenedor o en la red local) envíe webhooks al servidor de desarrollo sin necesitar desplegar en producción. URL de formato: `https://abc123.ngrok-free.app`.

---

## O

**Over-fetching**
Problema de la API REST donde el servidor devuelve más campos de los que el cliente necesita. Ejemplo: `GET /projects/:id` devuelve 50+ campos aunque el cliente solo necesite `name` y `web_url`. GraphQL elimina este problema — el cliente especifica exactamente qué campos quiere.

---

## P

**Paginación**
Técnica para dividir respuestas grandes en páginas. REST de GitLab usa paginación numérica (`page` + `per_page`, máx 100 items/página). GraphQL de GitLab usa paginación basada en cursores (`first` + `after`). Los headers de respuesta REST (`X-Total`, `X-Next-Page`) informan cuántas páginas hay en total.

**Payload (Webhook)**
Cuerpo JSON de la petición HTTP que GitLab envía al receptor de webhook cuando ocurre un evento. Contiene campos comunes (`object_kind`, `project`, `user`) y campos específicos del evento en `object_attributes`. Ver también: ↗ Webhook.

**Personal Access Token (PAT)**
Token de autenticación personal que sustituye a la contraseña en llamadas a la API. Se crea en `Settings → Access Tokens`. Tiene scopes configurables y fecha de expiración. Se usa con el header `PRIVATE-TOKEN: <token>`. Diferente de ↗ CI_JOB_TOKEN (efímero) y ↗ Project Access Token (no ligado a usuario).

**PRIVATE-TOKEN**
Header HTTP usado para autenticación PAT en la API REST de GitLab. Formato: `PRIVATE-TOKEN: <token>`. También aceptado en la API GraphQL como alternativa a `Authorization: Bearer`. Nunca pasar el token como query parameter (`?private_token=`) — queda expuesto en logs del servidor.

**Project Access Token**
Token a nivel de proyecto, no ligado a ningún usuario humano. Se crea en `Project → Settings → Access Tokens`. Actúa como un bot member del proyecto con el rol asignado. Sigue funcionando aunque los developers del equipo cambien. Ideal para bots de CI/CD y scripts de automatización. Ver también: ↗ Group Access Token.

**python-gitlab**
Librería Python de facto para interactuar con la API REST de GitLab. Proporciona una interfaz orientada a objetos: `gl.projects.get()`, `proyecto.issues.create()`, `pipeline.cancel()`. Maneja la paginación automáticamente con `all=True` y reintenta errores transitorios con `retry_transient_errors=True`.

---

## Q

**Query (GraphQL)**
Operación GraphQL de solo lectura que obtiene datos. Equivalente a GET de REST. Las queries pueden tener parámetros (variables), pueden solicitar múltiples recursos en una sola petición, y solo devuelven los campos explícitamente pedidos. Ver también: ↗ Mutation.

---

## R

**Rate Limit**
Límite de peticiones por minuto que la API impone para prevenir abusos. GitLab CE auto-administrado: 300 peticiones/min para autenticados (REST), 600 para GraphQL, 10 para anónimos. Al excederse: HTTP 429 con header `Retry-After` indicando los segundos de espera. Ver también: ↗ Backoff Exponencial.

**REST (Representational State Transfer)**
Estilo arquitectónico para APIs donde cada recurso tiene su propia URL y se manipula con métodos HTTP estándar (GET/POST/PUT/DELETE). En GitLab: `GET /api/v4/projects/:id/issues` lista issues, `POST` crea uno, `PUT` actualiza, `DELETE` elimina. Alternativa a ↗ GraphQL para operaciones simples.

---

## S

**Scope**
Permiso específico asignado a un token que limita qué operaciones puede realizar. Ejemplos: `api` (acceso completo), `read_api` (solo lectura), `read_repository` (clonar), `write_registry` (publicar imágenes Docker). Principio de mínimo privilegio: usar siempre el scope mínimo necesario para la tarea.

**Secret Token (Webhook)**
Valor secreto configurado al crear un webhook. GitLab lo envía en el header `X-Gitlab-Token` en cada petición. El receptor debe validarlo con `hmac.compare_digest()` (comparación en tiempo constante para evitar timing attacks) antes de procesar el payload. Sin esta validación, cualquier tercero puede enviar payloads falsos.

---

## U

**Under-fetching**
Problema de la API REST donde una sola petición no devuelve todos los datos relacionados que el cliente necesita, obligando a hacer N peticiones adicionales. Ejemplo: listar proyectos con sus últimas pipelines requiere `GET /projects` + N × `GET /projects/:id/pipelines`. GraphQL resuelve esto consolidando todo en una query.

---

## W

**Webhook**
Callback HTTP que GitLab dispara automáticamente cuando ocurre un evento configurado (push, MR, issue, pipeline, etc.). GitLab envía un HTTP POST con un payload JSON al URL receptor. El receptor debe responder en menos de 10 segundos con HTTP 2xx; de lo contrario GitLab marca la entrega como fallida. Ver también: ↗ Payload, ↗ Secret Token.

---

## X

**X-Gitlab-Token**
Header HTTP que GitLab incluye en cada petición de webhook. Contiene el secret token configurado al crear el webhook. El receptor debe compararlo contra el secreto esperado para validar la autenticidad de la petición. Ver también: ↗ Secret Token.

**X-Total / X-Next-Page**
Headers de respuesta HTTP que informan el estado de la paginación en la API REST de GitLab. `X-Total` indica el total de items en todas las páginas. `X-Next-Page` indica el número de la siguiente página (vacío si la página actual es la última). Ver también: ↗ Paginación.

---

⬅️ **Proyecto:** [3-proyecto/README.md](../3-proyecto/README.md)
➡️ **Rúbrica:** [rubrica-evaluacion.md](../rubrica-evaluacion.md)

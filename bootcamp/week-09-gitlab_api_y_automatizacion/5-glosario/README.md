# Glosario — Semana 09

| Término | Definición |
|---------|-----------|
| **API** | Application Programming Interface: conjunto de endpoints que permiten interactuar programáticamente con GitLab |
| **REST** | Representational State Transfer: estilo arquitectónico para APIs que usa métodos HTTP y URLs como recursos |
| **GraphQL** | Lenguaje de query para APIs que permite al cliente especificar exactamente los datos que necesita |
| **Endpoint** | URL específica de la API que expone un recurso o funcionalidad |
| **Personal Access Token (PAT)** | Token de autenticación personal que sustituye a la contraseña en llamadas a la API |
| **Scope** | Alcance o permiso específico asignado a un token (api, read_api, read_repository, etc.) |
| **Webhook** | Callback HTTP que GitLab dispara automáticamente cuando ocurre un evento configurado |
| **Payload** | Cuerpo JSON de la petición webhook que contiene los datos del evento |
| **Paginación** | Técnica para dividir respuestas grandes en páginas, usando parámetros page y per_page |
| **Rate Limit** | Límite de peticiones por minuto que la API impone para prevenir abusos |
| **HTTP Status Code** | Código numérico en la respuesta HTTP que indica el resultado (200 OK, 401 Unauthorized, 429 Too Many Requests) |
| **GraphiQL** | IDE web integrado en GitLab para explorar y probar queries GraphQL interactivamente |
| **Query** | En GraphQL, operación de solo lectura que obtiene datos |
| **Mutation** | En GraphQL, operación que modifica datos (crear, actualizar, eliminar) |
| **Fragment** | En GraphQL, conjunto reutilizable de campos que evita duplicación entre queries |
| **Project Access Token** | Token a nivel de proyecto, no ligado a un usuario, ideal para automatización CI/CD |
| **Group Access Token** | Token a nivel de grupo que otorga acceso a todos los proyectos del grupo y subgrupos |
| **python-gitlab** | Librería Python oficial para interactuar con la API REST de GitLab de forma programática |
| **Idempotencia** | Propiedad de una operación que produce el mismo resultado sin importar cuántas veces se ejecute |
| **CI_JOB_TOKEN** | Token efímero disponible dentro de un job de CI/CD para autenticarse contra la API |

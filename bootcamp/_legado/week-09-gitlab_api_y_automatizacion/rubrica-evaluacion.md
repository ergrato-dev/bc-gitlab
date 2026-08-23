# Rúbrica de Evaluación — Semana 09: GitLab API y Automatización

**Mínimo para aprobar:** 70 puntos (sobre 100)
**Penalización por entrega tardía:** -5 puntos por día hábil
**Bonificación por reto adicional:** +5 puntos (máx 1 reto)

---

## Criterio 1: API REST (20 puntos)

| Nivel | Puntos | Descripción |
|-------|--------|-------------|
| Excelente | 20 | CRUD completo (proyectos, issues, MRs, ramas) con curl. Interpreta headers de paginación (`X-Total`, `X-Next-Page`). Maneja códigos HTTP 401, 404, 429 en un script. Construye URLs con filtros y ordenamiento. |
| Bien | 15 | CRUD básico de al menos 2 tipos de recursos. Entiende e implementa paginación. Detecta el código HTTP de la respuesta. |
| Suficiente | 10 | GET y POST a la API con curl usando el header correcto. Sin paginación ni manejo de errores. |
| Insuficiente | 0 | No logra autenticarse. No distingue `PRIVATE-TOKEN` (REST) de `Authorization: Bearer` (OAuth/GraphQL). |

---

## Criterio 2: GraphQL (20 puntos)

| Nivel | Puntos | Descripción |
|-------|--------|-------------|
| Excelente | 20 | Usa GraphiQL para explorar el esquema. Queries con variables. Al menos una mutation (`createIssue`). Paginación cursor-based en Python. Explica over-fetching y cuándo preferir GraphQL vs REST. |
| Bien | 15 | Queries simples en GraphiQL con variables. Entiende query vs mutation. Paginación cursor implementada. |
| Suficiente | 10 | Copia y adapta una query del explorador. Sin variables ni paginación. Sin mutations propias. |
| Insuficiente | 0 | No puede ejecutar ninguna query funcional. Confunde REST con GraphQL. |

---

## Criterio 3: Tokens y Seguridad (15 puntos)

| Nivel | Puntos | Descripción |
|-------|--------|-------------|
| Excelente | 15 | Distingue PAT, Project Token, Group Token, CI_JOB_TOKEN y cuándo usar cada uno. Aplica mínimo privilegio al asignar scopes. Rota tokens de forma segura. Usa `.env` — nunca hardcodea tokens. |
| Bien | 11 | Distingue PAT vs CI_JOB_TOKEN. Usa `.env`. Configura fecha de expiración. |
| Suficiente | 7 | Crea y usa un PAT correctamente. Scope `api` para todo sin considerar mínimo privilegio. |
| Insuficiente | 0 | Hardcodea el token en el código o en el README. No conoce la diferencia entre tipos de tokens. |

---

## Criterio 4: Webhooks (20 puntos)

| Nivel | Puntos | Descripción |
|-------|--------|-------------|
| Excelente | 20 | Receptor Flask con validación del secret token via `hmac.compare_digest()`. Routing por `object_kind`. Webhook configurado via API. Verificado: 401 con token incorrecto, 200 con correcto. ngrok para exposición local. |
| Bien | 15 | Receptor Flask funcional con validación del secret token. Webhook configurado en UI. Eventos recibidos correctamente. |
| Suficiente | 10 | Servidor Flask recibe eventos sin validar el secret token. Webhook configurado via UI. |
| Insuficiente | 0 | No recibe ningún evento. No implementa validación del secret token. |

---

## Criterio 5: Automatización Python (25 puntos)

| Nivel | Puntos | Descripción |
|-------|--------|-------------|
| Excelente | 25 | Bot con 3 módulos (stale, reporter, notifier). Excepciones específicas (`GitlabAuthenticationError`, `GitlabGetError`). Retry con backoff exponencial para 429. Al menos 2 tests con pytest que pasan. Todo configurado via `.env`. |
| Bien | 19 | Al menos 2 de los 3 módulos. Manejo de excepciones. `retry_transient_errors=True`. Sin tests pero script robusto. |
| Suficiente | 13 | Script funcional con al menos 1 tarea. `except Exception` genérico. Sin paginación `all=True`. |
| Insuficiente | 0 | No conecta `python-gitlab` a la instancia local. Script sin paginación ni manejo de errores. |

---

## Penalizaciones

| Situación | Penalización |
|-----------|-------------|
| Token hardcodeado en código fuente | -15 puntos |
| `?private_token=` en lugar del header `PRIVATE-TOKEN` | -3 puntos |
| `except Exception` genérico para todo el script | -5 puntos |
| Webhook sin validación del secret token | -5 puntos |
| Script que falla con traceback no controlado ante token inválido | -5 puntos |

---

## Bonificaciones (máx. +5 puntos, solo 1 reto)

| Reto | Bonificación |
|------|-------------|
| CLI con `argparse` para el bot (`--task stale|report|all`, `--dry-run`, `--project-id`) | +5 |
| GraphQL: query de dashboard con datos de 3+ proyectos en una sola petición | +5 |
| Bot dockerizado: `Dockerfile` + instrucciones para `docker run` | +5 |

---

## Tabla de calificación

| Puntos | Calificación |
|--------|-------------|
| 90-100 | Excelente |
| 80-89  | Muy bien |
| 70-79  | Bien |
| 60-69  | Suficiente (requiere revisión) |
| 0-59   | Insuficiente (no aprueba) |

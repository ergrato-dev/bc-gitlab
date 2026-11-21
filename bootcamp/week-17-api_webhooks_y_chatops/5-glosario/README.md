# 📖 Glosario — Semana 17

Términos que aparecen esta semana. El nombre real de la feature va en inglés entre paréntesis, y el **tier** cuando aplica.

El glosario acumulado de toda la plataforma está en [glosario-global](../../../docs/glosario-global.md).

---

## A

**`alert_status`** — Campo de un webhook: `executable`, `temporarily_disabled` o `disabled`. En esta instancia siempre `executable`, porque la autodesactivación está apagada.

**Autodesactivación de webhooks** (*auto-disabling webhooks*) — Free. Tras varios fallos seguidos, GitLab aparta el webhook un tiempo creciente y al final lo desactiva. En autohospedado depende de la marca de función `auto_disabling_web_hooks`, apagada por defecto.

## C

**`chat_reply`** — Sección del log de un job de chat (`section_start:…:chat_reply` / `section_end`) cuyo contenido GitLab devuelve al canal. Si el job falla, al canal solo llega que ha fallado.

**ChatOps** — Free. Ejecutar jobs de CI desde un chat con `run <job>`. Crea un pipeline de origen `chat` en la rama por defecto con solo ese job.

**`CHAT_INPUT`** — Variable de un job de chat: el texto que sigue al nombre del job. También llegan `CHAT_CHANNEL` y `CHAT_USER_ID`.

**Complejidad de consulta** (*query complexity*) — Lo que GraphQL calcula antes de ejecutar una consulta. Límite de 200 anónimo, 250 con usuario y 300 para administradores. Se consulta con `queryComplexity { score limit }`.

**Cursor** — Marca opaca de GraphQL que dice dónde sigue un listado. Se pasa en `after` con el `endCursor` de la página anterior.

## E

**Explorador de GraphQL** (*GraphiQL*) — `/-/graphql-explorer` en tu instancia: escribe consultas con autocompletado y con tu sesión.

## G

**GraphQL** — Free. La segunda API de GitLab: una sola URL (`/api/graphql`), consultas que piden exactamente los campos que quieren, errores con HTTP 200 en `errors`.

## H

**HMAC** — Firma con clave secreta compartida. GitLab firma con HMAC-SHA256 sobre `id.timestamp.cuerpo`; el receptor la recalcula y compara en tiempo constante.

## I

**`Idempotency-Key`** — Cabecera de un webhook, igual que `webhook-id`: identifica el evento y se mantiene en los reenvíos. El receptor deduplica por ella.

**Integración de slash commands de Mattermost** (*Mattermost slash commands*) — Free. La integración que recibe comandos de chat (`issue`, `deploy`, `run`). Es la que usa este bootcamp, con `curl` en el papel de Mattermost.

## L

**Lista de hosts permitidos** (*Local IP addresses and domain names that hooks and integrations can access*) — `outbound_local_requests_whitelist` en los ajustes de la instancia: las únicas direcciones de la red local a las que pueden llamar webhooks e integraciones.

## P

**Paginación por claves** (*keyset pagination*) — `pagination=keyset&order_by=id`: cada página pide "lo que va después del ID tal". No da `X-Total`; la siguiente página llega en la cabecera `Link`.

**Paginación por desplazamiento** (*offset pagination*) — `page` y `per_page` (100 como mucho). Da `X-Total`, `X-Total-Pages` y `X-Next-Page`; si el listado cambia mientras se recorre, puede saltar o repetir elementos.

**Programación de pipeline** (*pipeline schedule*) — Free. Un pipeline que se lanza solo con una expresión cron. Corre con los permisos de su dueño.

## R

**Red local** (*local network*) — Las direcciones privadas y de bucle local. Por defecto, GitLab no deja que webhooks ni integraciones las llamen, para evitar SSRF.

**Registro de entregas** (*recent events*) — `GET /projects/:id/hooks/:hook_id/events`: cada entrega de un webhook con cabeceras, cuerpo, código y duración. Hasta 20 por página.

**Reenvío** (*resend*) — `POST …/events/:id/resend`: repite una entrega con la misma `Idempotency-Key` y firma nueva. No funciona si la URL del webhook ha cambiado.

**Rotación** (*rotate*) — `POST /groups/:id/access_tokens/:id/rotate`: token nuevo para el mismo bot, con id nuevo, y el anterior revocado.

## S

**`signing_token`** — Free. La clave con la que GitLab firma un webhook (`whsec_` y 32 bytes en base64). Viaja solo al crearlo; después el webhook muestra `signing_token_present`.

**SSRF** (*Server-side request forgery*) — Conseguir que un servidor haga peticiones por ti a sitios que tú no alcanzas. Es lo que evita cerrar la red local.

## T

**Token de grupo** (*group access token*) — Free en autohospedado. Token de un usuario bot que es miembro del grupo con el rol elegido. Caducidad obligatoria, de un año como mucho.

## V

**Variable oculta** (*masked and hidden variable*) — Free. Enmascarada en los logs y que nadie puede volver a leer: la API devuelve `"value": null`. Se elige al crearla.

## W

**Webhook** — Free. Una petición HTTP que GitLab envía a tu URL cuando pasa algo. Los de proyecto son Free; los de grupo, Premium; los de sistema, de administrador.

**`webhook-signature`** — Cabecera con `v1,<firma en base64>`. Junto a `webhook-id` y `webhook-timestamp`, sigue la especificación Standard Webhooks.

## X

**`X-Gitlab-Token`** — Cabecera con el `token` del webhook, en claro. Autentica, pero no protege el cuerpo ni impide repetir la petición.

---

[← Volver a la Semana 17](../README.md)

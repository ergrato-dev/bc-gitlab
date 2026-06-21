# 04 — Webhooks en GitLab

Los webhooks permiten que GitLab notifique a sistemas externos cuando ocurren eventos específicos. Se configuran a nivel de proyecto o grupo y envían una petición HTTP POST a una URL definida por el usuario.

## Tipos de eventos

| Evento | Disparador |
|--------|-----------|
| Push events | Push a cualquier rama o tag |
| Tag events | Creación o eliminación de tags |
| Issues events | Creación, actualización, cierre de issues |
| Merge request events | Apertura, actualización, merge de MR |
| Pipeline events | Inicio, éxito, fallo de pipeline |
| Job events | Cambios de estado en jobs individuales |
| Release events | Creación de releases |
| Wiki page events | Creación/edición de páginas wiki |
| Deployment events | Despliegues a environments |
| Confidential note events | Notas confidenciales en issues |

## Estructura del payload

Cada evento envía un JSON con información contextual. El payload incluye campos como `object_kind` (tipo de evento), `project` (datos del proyecto), `user` (quién disparó el evento) y campos específicos según el tipo de evento.

## Secret token

Al configurar un webhook se puede definir un token secreto. GitLab lo envía en el header `X-Gitlab-Token`. El receptor debe validarlo para asegurar que la petición realmente proviene de GitLab y no de un tercero malicioso.

## Pruebas

Desde la interfaz de configuración del webhook, el botón "Test" permite enviar un evento de prueba a la URL configurada. También se pueden reenviar eventos fallidos desde el historial de entregas.

## Consideraciones de red

- La URL del webhook debe ser accesible desde la instancia GitLab
- Para entornos locales, usar herramientas como ngrok para exponer un túnel público
- Timeout por defecto: 10 segundos
- Si la URL responde con 4xx/5xx, GitLab reintentará (hasta cierto límite)

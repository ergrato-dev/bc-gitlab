# Superficie y auditoría

> Una instancia de GitLab hace peticiones hacia fuera: webhooks, hooks de sistema, integraciones, importaciones. Cada una es una URL que alguien escribe, y una URL escrita por un usuario puede apuntar a `http://localhost:5432` o a tu red interna. Y hacia dentro, hay rutas que solo debería ver el monitoreo. Esta teoría cierra esas dos superficies y responde a la pregunta que llega después de cualquier incidente: ¿quién hizo qué, y cuándo?, sin los eventos de auditoría de Premium.

---

## 🎯 Objetivos

- Explicar el riesgo de SSRF de los webhooks y cómo lo cierran los ajustes de red local
- Configurar un hook de sistema firmado y saber qué eventos manda aunque no marques ninguno
- Decidir qué va en `monitoring_whitelist` en el laboratorio y en producción
- Activar la autodesactivación de webhooks que fallan, que viene apagada
- Reconstruir quién cambió un ajuste con `api_json.log`, `audit_json.log` y `GET /users/:id/events`

---

## 1. Qué problema resuelve

Dos superficies:

| Superficie | Ataque | Qué la cierra |
|---|---|---|
| **Salida**: GitLab llama a URL que escriben los usuarios | SSRF: un webhook a `http://redis:6379` o `http://169.254.169.254` hace que GitLab hable con servicios internos en nombre del atacante | `allow_local_requests_from_web_hooks_and_services=false`, `allow_local_requests_from_system_hooks=false` y una lista corta de excepciones |
| **Entrada**: rutas de salud y métricas | `/-/readiness?all=1` y `/-/metrics` cuentan versiones, componentes y estado interno a quien pregunte | `monitoring_whitelist` en `gitlab.rb` |

Y una pregunta: si mañana `signup_enabled` vuelve a estar en `true`, ¿quién lo cambió? En Premium hay eventos de auditoría con API. En CE, la respuesta está en los logs, y hay que saber cuál mirar.

---

## 2. Cómo funciona

### 2.1 Red local y excepciones

| Ajuste | Por defecto en 19.2.4 | Qué hace |
|---|---|---|
| `allow_local_requests_from_web_hooks_and_services` | `false` | Webhooks de proyecto y grupo e integraciones no pueden llamar a direcciones privadas ni a `localhost` |
| `allow_local_requests_from_system_hooks` | **`true`** | Lo mismo para los hooks de sistema. Viene abierto: los crea un admin |
| `outbound_local_requests_whitelist` | `[]` | Las excepciones, para los dos: host, IP o rango, con puerto opcional |
| `dns_rebinding_protection_enabled` | `true` | Resuelve el nombre una vez y conecta a esa IP: un DNS que cambia de respuesta no cuela una IP interna |

En la Semana 17 añadiste `destino` a las excepciones para que los webhooks llegasen al receptor. Esta semana cierras también los hooks de sistema: la misma excepción sirve, y cualquier otra dirección local queda bloqueada. La comprobación ocurre dos veces. Al crear el hook, una URL que resuelve a una dirección local se rechaza con `Invalid url given`. Al entregar, se vuelve a comprobar, y un hook que apuntaba a un nombre que entonces no resolvía, o creado antes de cerrar la red, falla con `URL is blocked: Requests to the local network are not allowed`.

### 2.2 Hooks de sistema

Un hook de sistema (`POST /hooks`, `Admin → System hooks`) es un webhook de toda la instancia. **Free.** Tiene los flags de siempre (`push_events`, `tag_push_events`, `merge_requests_events`, `repository_update_events`), pero hay eventos que manda **siempre**, marques lo que marques: altas y bajas de usuarios, proyectos, grupos y miembros (`user_create`, `project_create`, `user_add_to_team`…).

Eso los hace la auditoría barata de CE: un hook de sistema con todos los flags apagados avisa cada vez que aparece una cuenta o alguien entra en un proyecto. Llega con las mismas cabeceras que los webhooks de la Semana 17 (`webhook-id`, `webhook-timestamp`, `webhook-signature` si tiene `signing_token`), y con `X-Gitlab-Event: System Hook`. El cuerpo dice qué pasó en `event_name`.

### 2.3 `monitoring_whitelist`

`/-/health`, `/-/readiness`, `/-/liveness` y `/-/metrics` solo contestan a las IP de `gitlab_rails['monitoring_whitelist']`. A las demás les devuelven `404`, no `403`: ni confirman que existan. Por defecto, solo `127.0.0.0/8` y `::1/128`.

El laboratorio abre los rangos privados enteros (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`), porque desde tu terminal las peticiones llegan con la IP del gateway de Docker y porque Prometheus (Semana 21) va en otro contenedor. Es una decisión del laboratorio, y está en el comentario del `docker-compose.yml`. En producción la lista son las IP del servidor de monitoreo y del balanceador, nada más. Esta semana no la cambias: la escribes en `docs/endurecimiento.md` como diferencia conocida entre laboratorio y producción.

### 2.4 Webhooks que fallan

Un webhook que apunta a un receptor caído reintenta y llena las colas de Sidekiq. La autodesactivación los apaga temporalmente tras varios fallos seguidos y, si siguen fallando, del todo. En 19.2.4 está detrás de la marca `auto_disabling_web_hooks`, de tipo `ops`, **apagada** por defecto. Las marcas de tipo `ops` son interruptores operativos pensados para que el admin los decida: no se retiran solas.

```bash
curl -s -H "$H" "$API/features/definitions" \
  | jq -c '.[] | select(.name == "auto_disabling_web_hooks") | {type, default_enabled, milestone}'
# {"type":"ops","default_enabled":false,"milestone":"18.10"}
```

### 2.5 Auditar en CE

| Pregunta | Dónde mirar | Qué trae |
|---|---|---|
| Quién cambió un ajuste por API | `api_json.log` | Una línea por petición: `method`, `path`, `params`, `username`, `token_id`, `meta.remote_ip` |
| Quién cambió un ajuste por la web | `production_json.log` | `controller`, `action`, `params` y `username` de cada petición web |
| Quién entró y cómo | `audit_json.log` | Inicios de sesión: `details.with` (`standard` u `openid_connect`), usuario e IP |
| A quién frenó un límite | `auth.log` | Una línea con `"message":"Rack_Attack"` por cada `429` (teoría 05) |
| Qué hizo un usuario en proyectos | `GET /users/:id/events` | Push, issues, MR, comentarios. `GET /events` solo da **tus** eventos |
| Cuándo apareció una cuenta | El hook de sistema | `user_create` en el canal del receptor |

Los logs están en `/var/log/gitlab/gitlab-rails/` dentro del contenedor, rotan, y no tienen API. Retenerlos y buscarlos es trabajo de Loki, en la Semana 21. Los eventos de auditoría de instancia con API y filtros son **Premium**.

---

## 3. Cómo se configura

Cerrar los hooks de sistema a la red local, manteniendo la excepción de la Semana 17:

```bash
curl -s --request PUT "$API/application/settings" -H "$H" \
  --data allow_local_requests_from_system_hooks=false \
  | jq -c '{allow_local_requests_from_web_hooks_and_services, allow_local_requests_from_system_hooks, outbound_local_requests_whitelist}'
# {"allow_local_requests_from_web_hooks_and_services":false,"allow_local_requests_from_system_hooks":false,"outbound_local_requests_whitelist":["destino"]}
```

**Con la UI**: `Admin → Settings → Network → Outbound requests`.

Un hook de sistema firmado, sin flags:

```bash
curl -s --request POST "$API/hooks" -H "$H" -H 'Content-Type: application/json' \
  -d "$(jq -nc --arg k "$RECEPTOR_SIGNING_KEY" '{name: "receptor-sistema",
        url: "http://destino:8080/receptor/webhook", signing_token: $k,
        push_events: false, tag_push_events: false, merge_requests_events: false}')" \
  | jq -c '{id, url, signing_token_present}'
```

Quién hizo el último `PUT` de ajustes:

```bash
docker compose exec gitlab grep '"method":"PUT","path":"/api/v4/application/settings"' \
  /var/log/gitlab/gitlab-rails/api_json.log | tail -n 1 \
  | jq -c '{time, username, token_id, params: [.params[].key]}'
# {"time":"2026-11-24T20:49:06.502Z","username":"root","token_id":52,"params":["outbound_local_requests_whitelist"]}
```

No hay `jq` dentro del contenedor: el `grep` va dentro y el `jq`, en tu terminal. `token_id` es el ID del token: `GET /personal_access_tokens/:id` dice de quién es y cómo se llama.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| `allow_local_requests_from_web_hooks_and_services=true` para que llegue un webhook | Cualquier maintainer puede apuntar un webhook a Redis o a PostgreSQL | Una excepción con el host concreto |
| Dejar los hooks de sistema abiertos "porque los crea un admin" | Un token de admin robado tiene un SSRF de toda la instancia | Cerrados, con la misma lista de excepciones |
| `monitoring_whitelist` con `0.0.0.0/0` | `/-/metrics` da a cualquiera el mapa de la instancia | Solo las IP del monitoreo |
| Buscar quién cambió algo en `production_json.log` cuando se hizo por API | Las peticiones de API van a otro log y no aparece nada | `api_json.log` para API; `production_json.log` para la web |
| Fiarse de los logs del contenedor como auditoría | Rotan y desaparecen con el volumen | Enviarlos fuera (Semana 21) y escribir las decisiones en `infra/plataforma` |

---

## 5. Trucos

- `POST /hooks/:id` prueba un hook de sistema con un cuerpo de ejemplo (`project_create` de un proyecto `Ruby` que no existe). Si el receptor anota ese `project_create`, la entrega y la firma funcionan.
- Tras cambiar `outbound_local_requests_whitelist`, la primera entrega puede seguir bloqueada: es la caché de ajustes de la teoría 01.
- `GET /users/:id/events?action=pushed&after=2026-11-01` filtra los eventos de un usuario por tipo y fecha.
- `docker compose exec gitlab grep -c '"with":"openid_connect"' /var/log/gitlab/gitlab-rails/audit_json.log` cuenta los inicios de sesión por Keycloak.

---

## 📚 Recursos Adicionales

- [Filtering outbound requests](https://docs.gitlab.com/security/webhooks/) — red local, excepciones y protección contra DNS rebinding
- [System hooks](https://docs.gitlab.com/administration/system_hooks/) — los eventos que manda siempre y su formato
- [IP allowlist](https://docs.gitlab.com/administration/monitoring/ip_allowlist/) — `monitoring_whitelist` y las rutas que protege
- [Log system](https://docs.gitlab.com/administration/logs/) — qué guarda cada log de `gitlab-rails`

---

## ✅ Checklist de Verificación

- [ ] Sabes explicar un SSRF por webhook con un ejemplo de tu laboratorio
- [ ] Sabes qué eventos manda un hook de sistema aunque no marques ninguno
- [ ] Puedes decir por qué el laboratorio abre `monitoring_whitelist` y qué pondrías en producción
- [ ] Sabes en qué log buscar un cambio de ajustes hecho por API y uno hecho por la web

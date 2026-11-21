# Práctica 03 — Los webhooks

> Das al receptor su clave de firma, abres la red local de GitLab a `destino` y a nada más, y conectas los webhooks firmados de `app` y `ci/automatizacion`. Después atacas tu propio receptor: sin firma, con firma inventada, con una firma auténtica de hace diez minutos, y con la misma petición dos veces. Por último lo tiras, provocas avisos que se pierden, compruebas que nadie los reintenta, y los recuperas desde el registro de entregas sin duplicar nada en el canal.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 02 completada · Teoría [04](../1-teoria/04-webhooks-firmados.md) y [05](../1-teoria/05-cuando-la-entrega-falla.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 0 | Variables, el repositorio del bootcamp al día y dos funciones | — |
| 1 | La clave de firma y el token del canal, en `destino` | — |
| 2 | La red local cerrada salvo `destino` | `solo-destino-permitido` |
| 3 | Los webhooks firmados de `app` y `ci/automatizacion` | `webhook-app-firmado`, `webhook-automatizacion-firmado` |
| 4 | Peticiones sin firma y con firma inventada, rechazadas | — |
| 5 | Una firma auténtica fuera de tiempo, rechazada; dentro, aceptada una vez | — |
| 6 | El receptor caído y avisos perdidos | — |
| 7 | Nadie reintenta ni desactiva | — |
| 8 | Los avisos recuperados con `resend` | — |
| 9 | Un reenvío repetido que no duplica | — |
| 10 | Por qué la URL no se toca | — |
| 11 | El canal limpio | — |

Lo que demuestran los pasos 4 a 11 (que el receptor rechaza lo falso y no duplica) no lo ve la API: lo evalúa la rúbrica. Guarda sus salidas.

---

## Paso 0: Preparar el terreno

**Por qué**: esta semana el servicio `destino` del compose recibe dos variables nuevas, `RECEPTOR_SIGNING_KEY` y `RECEPTOR_CANAL_TOKEN`. Vienen en el `docker-compose.yml` y el `.env.example` del repositorio del bootcamp: actualízalo.

```bash
source ~/.bc-gitlab; source ~/.bc-gitlab-s17
export H="PRIVATE-TOKEN: $GITLAB_TOKEN" API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
export R="http://localhost:${DESTINO_PORT:-8095}/receptor"
cd /ruta/al/repositorio/bc-gitlab && git pull --ff-only
```

Dos funciones. `canal` cuenta y enseña las últimas líneas del canal. `firmar` hace lo mismo que GitLab con la clave de firma (teoría 04, apartado 2.3), con `openssl`. Las usarás desde el paso 4.

```bash
canal() { curl -s "$R/" | jq -r 'length as $n | "\($n) líneas", (.[-3:][] | "  \(.resumen)")'; }

firmar() {   # $1 = webhook-id, $2 = timestamp, $3 = cuerpo
  printf '%s.%s.%s' "$1" "$2" "$3" | openssl dgst -sha256 -binary -mac HMAC \
    -macopt "hexkey:$(printf '%s' "${RECEPTOR_SIGNING_KEY#whsec_}" | base64 -d | od -An -tx1 | tr -d ' \n')" \
    | base64
}
```

Y `esperar`, del paso 0 de la [práctica 01](01-el-bot-auditor.md#paso-0-preparar-el-terreno).

**Verifica**:

```bash
grep -c RECEPTOR_ docker-compose.yml
grep -c '^RECEPTOR_' .env
```

`2` en el compose. Si `.env` da `0`, tu `.env` es anterior a esta semana: añade al final las dos líneas vacías de `.env.example`:

```bash
grep '^RECEPTOR_' .env.example >> .env
```

---

## Paso 1: Las dos claves del receptor

**Por qué**: el receptor necesita dos secretos. La **clave de firma** la comparten GitLab (en cada webhook, como `signing_token`) y el receptor (para verificar): con el formato `whsec_` y 32 bytes aleatorios en base64 (teoría 04, apartado 2.3). El **token del canal** es el secreto de la ruta por la que ChatOps contesta (práctica 04), porque esas respuestas no llegan firmadas. Los dos van al `.env`, fuera de Git, y `destino` los lee al arrancar.

```bash
umask 077
sed -i "s|^RECEPTOR_SIGNING_KEY=.*|RECEPTOR_SIGNING_KEY=whsec_$(head -c 32 /dev/urandom | base64)|" .env
sed -i "s|^RECEPTOR_CANAL_TOKEN=.*|RECEPTOR_CANAL_TOKEN=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')|" .env
chmod 600 .env
docker compose --profile base up -d destino
```

`firmar` necesita la clave en tu terminal:

```bash
source <(grep '^RECEPTOR_SIGNING_KEY=' .env)
```

**Verifica**:

```bash
docker compose exec destino sh -c 'echo "${RECEPTOR_SIGNING_KEY%%_*} ${#RECEPTOR_SIGNING_KEY} ${#RECEPTOR_CANAL_TOKEN}"'
```

`whsec 50 32`: el prefijo, y las longitudes, sin enseñar los valores.

---

## Paso 2: Solo `destino`

> [!WARNING]
> Es un ajuste de toda la instancia y lo hace un administrador. Antes, apunta cómo está: `curl -s -H "$H" "$API/application/settings" | jq -c '{allow_local_requests_from_web_hooks_and_services, outbound_local_requests_whitelist}' > ~/bc-s17/red-local-antes.json`.

**Por qué**: un webhook a `http://destino:8080` da `Invalid url given`: GitLab no llama a tu red local (teoría 04, apartado 2.5). En vez de abrirla entera, se permite un host.

**Con la UI**: `Admin → Settings → Network → Outbound requests`. *Allow requests to the local network from webhooks and integrations* **sin** marcar, y en *Local IP addresses and domain names that hooks and integrations can access*, `destino`.

**Con la API**:

```bash
curl -s --request PUT "$API/application/settings" -H "$H" -H 'Content-Type: application/json' \
  -d "$(jq -c '{allow_local_requests_from_web_hooks_and_services: false,
               outbound_local_requests_whitelist: (.outbound_local_requests_whitelist + ["destino"] | unique)}' \
        ~/bc-s17/red-local-antes.json)" \
  | jq -c '{allow_local_requests_from_web_hooks_and_services, outbound_local_requests_whitelist}'
```

La llamada sustituye la lista entera: por eso se construye desde la copia, con lo que ya hubiera más `destino`.

**Verifica**: `{"allow_local_requests_from_web_hooks_and_services":false,"outbound_local_requests_whitelist":["destino"]}`, con los hosts que ya tuvieras delante.

---

## Paso 3: Los webhooks firmados

**Por qué**: dos proyectos avisan al receptor. `app`, de sus pipelines y despliegues: lo que el equipo necesita saber a las 3:12. `ci/automatizacion`, de sus pipelines: así una auditoría en rojo llega al canal sin que nadie abra GitLab. Los dos con `signing_token`, sin `token` en claro, y sin `push_events`, que viene activado por defecto.

```bash
for PR in "$P" "$PA"; do
  DEPLOY=$([ "$PR" = "$P" ] && echo true || echo false)
  curl -s --request POST "$API/projects/$PR/hooks" -H "$H" -H 'Content-Type: application/json' \
    -d "$(jq -nc --arg k "$RECEPTOR_SIGNING_KEY" --argjson d "$DEPLOY" '{
          url: "http://destino:8080/receptor/webhook", name: "receptor",
          signing_token: $k, push_events: false, pipeline_events: true, deployment_events: $d}')" \
    | jq -c '{id, url, signing_token_present, token_present}'
done
```

Guarda los dos `id`: `echo "export HOOK_APP=<id de app> HOOK_AUTO=<id de automatizacion>" >> ~/.bc-gitlab-s17 && source ~/.bc-gitlab-s17`.

Una prueba sin esperar a un pipeline, y una auditoría de verdad:

```bash
curl -s --request POST "$API/projects/$PA/hooks/$HOOK_AUTO/test/pipeline_events" -H "$H" | jq -r .message
curl -s --request POST "$API/projects/$PA/pipeline" -H "$H" --data ref=main | jq -r .id
sleep 60
canal
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$PA/hooks/$HOOK_AUTO/events" | jq -c '.[0:3][] | {trigger, response_status}'
```

`201 Created` de la prueba, en el canal la línea `…/ci/automatizacion: pipeline #N de main success`, y en el registro entregas con `"response_status":"200"`.

---

## Paso 4: Sin firma, y con firma inventada

**Por qué**: el receptor está en la red del laboratorio y su puerto en tu máquina. Cualquiera que llegue a él puede intentar escribir en el canal. Lo primero es comprobar que no puede.

```bash
CUERPO='{"object_kind":"pipeline","object_attributes":{"id":1,"status":"success","ref":"main"},"project":{"path_with_namespace":"yo/inventado"}}'

curl -s -w ' %{http_code}\n' "$R/webhook" -H 'X-Gitlab-Event: Pipeline Hook' -d "$CUERPO"

curl -s -w ' %{http_code}\n' "$R/webhook" -H 'X-Gitlab-Event: Pipeline Hook' \
  -H "webhook-id: falso-1" -H "webhook-timestamp: $(date +%s)" \
  -H "webhook-signature: v1,$(head -c 32 /dev/urandom | base64)" -d "$CUERPO"
```

**Verifica**: las dos, `{"error":"firma no válida"} 401`. `canal` sigue con el mismo número de líneas.

---

## Paso 5: Una firma auténtica, a destiempo

**Por qué**: ahora firmas bien, con la clave de verdad. Una firma de hace diez minutos es lo que tendría alguien que capturó un aviso auténtico y lo repite: el receptor la rechaza por la ventana de cinco minutos. Una firma de ahora pasa, una vez; la misma petición otra vez es un duplicado.

```bash
TS=$(( $(date +%s) - 600 )); ID=prueba-vieja
curl -s -w ' %{http_code}\n' "$R/webhook" -H 'X-Gitlab-Event: Pipeline Hook' \
  -H "webhook-id: $ID" -H "Idempotency-Key: $ID" -H "webhook-timestamp: $TS" \
  -H "webhook-signature: v1,$(firmar "$ID" "$TS" "$CUERPO")" -d "$CUERPO"

TS=$(date +%s); ID=prueba-$TS
for i in 1 2; do
  curl -s -w ' %{http_code}\n' "$R/webhook" -H 'X-Gitlab-Event: Pipeline Hook' \
    -H "webhook-id: $ID" -H "Idempotency-Key: $ID" -H "webhook-timestamp: $TS" \
    -H "webhook-signature: v1,$(firmar "$ID" "$TS" "$CUERPO")" -d "$CUERPO"
done
canal
```

**Verifica**: la vieja, `401`. La nueva, `{"ok":true} 200` y luego `{"repetido":"prueba-…"} 200`. En el canal, **una** línea más: `yo/inventado: pipeline #1 de main success`. Ese `yo/inventado` es la prueba de que la firma protege el canal de quien no tiene la clave, no de quien la tiene: por eso la clave vive en el `.env` con `chmod 600` y en el webhook, en ningún sitio más.

> [!NOTE]
> `curl -d` manda el cuerpo tal cual lo escribes, y `firmar` firma ese mismo texto. Si firmaras el JSON después de pasarlo por `jq`, no cuadraría: la firma es sobre los bytes, no sobre el significado.

---

## Paso 6: El receptor se cae

> [!WARNING]
> `docker compose stop destino` para también `staging`, `production` y las review apps de `app` hasta el paso 8.

**Por qué**: para ver qué pasa con los avisos que llegan mientras el receptor no está. Con `destino` parado, lanzas una auditoría: su pipeline avisa al empezar, al correr y al terminar, y ninguno de esos avisos llega.

```bash
cd /ruta/al/repositorio/bc-gitlab && docker compose stop destino
PIPE=$(curl -s --request POST "$API/projects/$PA/pipeline" -H "$H" --data ref=main | jq -r .id)
esperar "$PA" "$PIPE"
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$PA/hooks/$HOOK_AUTO/events?status=server_failure" \
  | jq -c '.[] | {id, trigger, response_status, created_at}'
```

Tres o cuatro entradas `pipeline_hooks` con `"response_status":"internal error"`, una por cambio de estado del pipeline.

---

## Paso 7: Nadie reintenta

**Por qué**: la teoría 05 dice que en tu instalación GitLab no reintenta ni desactiva. Compruébalo en vez de creerlo.

```bash
N1=$(curl -s -H "$H" "$API/projects/$PA/hooks/$HOOK_AUTO/events?status=server_failure" | jq length)
sleep 120
N2=$(curl -s -H "$H" "$API/projects/$PA/hooks/$HOOK_AUTO/events?status=server_failure" | jq length)
echo "$N1 -> $N2"
curl -s -H "$H" "$API/projects/$PA/hooks/$HOOK_AUTO" | jq -c '{alert_status, disabled_until}'
curl -s -H "$H" "$API/features" | jq -c '[.[] | select(.name == "auto_disabling_web_hooks")]'
```

**Verifica**: el mismo número antes y después (`4 -> 4`): dos minutos y ningún reintento. `{"alert_status":"executable","disabled_until":null}`. Y `[]`: la marca `auto_disabling_web_hooks` no está tocada, así que vale su valor por defecto, que en autohospedado es apagada.

---

## Paso 8: Vuelta y reenvío

**Por qué**: los avisos perdidos están en el registro, con su cuerpo. `resend` los manda otra vez, con la misma `Idempotency-Key` y una firma nueva (teoría 05, apartado 2.3).

```bash
docker compose start destino && sleep 5
curl -s "$R/salud"
for E in $(curl -s -H "$H" "$API/projects/$PA/hooks/$HOOK_AUTO/events?status=server_failure" | jq -r '.[].id'); do
  echo -n "$E "
  curl -s --request POST "$API/projects/$PA/hooks/$HOOK_AUTO/events/$E/resend" -H "$H"; echo
done
canal
```

**Verifica**: cada reenvío, `{"response_status":200}`. En el canal, una línea nueva: `…/ci/automatizacion: pipeline #<PIPE> de main success`. Solo una, aunque reenviaste tres o cuatro avisos: el receptor anota los pipelines terminados, y el resto (`pending`, `running`) los recibe, los acepta y no los anota.

---

## Paso 9: Reenviar lo ya reenviado

**Por qué**: alguien, mañana, vuelve a reenviar todo "por si acaso". El receptor tiene que contestar 200 y no anotar nada nuevo.

```bash
E=$(curl -s -H "$H" "$API/projects/$PA/hooks/$HOOK_AUTO/events?status=server_failure" | jq -r '.[0].id')
canal | head -1
curl -s --request POST "$API/projects/$PA/hooks/$HOOK_AUTO/events/$E/resend" -H "$H"; echo
canal | head -1
```

**Verifica**: `{"response_status":200}` y el mismo número de líneas antes y después.

El último de los reenvíos de este paso aparece en el registro como `successful`: el registro apunta entregas, no eventos. Lo que distingue "evento nuevo" de "el mismo otra vez" es la `Idempotency-Key`, y eso solo lo sabe el receptor.

---

## Paso 10: La URL no se toca

**Por qué**: si el receptor falla, la tentación es "mover" el webhook a otra URL. Pero el reenvío exige la misma URL, y un cambio deja todo el registro anterior sin poder reenviarse.

```bash
curl -s --request PUT "$API/projects/$PA/hooks/$HOOK_AUTO" -H "$H" \
  --data "url=http://destino:8080/receptor/webhook?movido=1" | jq -r .url
curl -s --request POST "$API/projects/$PA/hooks/$HOOK_AUTO/events/$E/resend" -H "$H"; echo
curl -s --request PUT "$API/projects/$PA/hooks/$HOOK_AUTO" -H "$H" \
  --data "url=http://destino:8080/receptor/webhook" | jq -r .url
curl -s --request POST "$API/projects/$PA/hooks/$HOOK_AUTO/events/$E/resend" -H "$H"; echo
```

**Verifica**: con la URL cambiada, `{"message":"The hook URL has changed. This log entry cannot be retried."}`. De vuelta a la original, `{"response_status":200}`.

---

## Paso 11: El canal limpio

**Por qué**: la línea `yo/inventado` del paso 5 es falsa y está en el canal. Un canal en el que hay que recordar qué líneas no valen no sirve. El canal es un archivo de `destino`: se quita la línea con un `sed` y punto.

```bash
cd /ruta/al/repositorio/bc-gitlab
docker compose exec -u deploy destino sed -i '/yo\/inventado/d' /srv/entornos/receptor/canal.jsonl
canal
unset RECEPTOR_SIGNING_KEY
```

**Verifica**: ninguna línea de `yo/inventado`.

---

## ✅ Resultado

- [ ] La clave de firma y el token del canal en el `.env`, y `destino` recreado con ellos
- [ ] La red local de la instancia cerrada salvo `destino`
- [ ] Los webhooks de `app` y `ci/automatizacion` firmados, y entregas con `200` en el registro
- [ ] Sin firma y con firma inventada: `401`, y el canal sin cambios
- [ ] Firma auténtica de hace diez minutos: `401`. De ahora: `200` una vez y `repetido` la segunda
- [ ] Con `destino` parado, avisos `internal error` en el registro, y ninguno reintentado en dos minutos
- [ ] `alert_status: executable` y la marca de autodesactivación sin tocar
- [ ] Los avisos perdidos recuperados con `resend`, sin duplicados en el canal
- [ ] Comprobado que un cambio de URL bloquea el reenvío

```bash
./scripts/verificar-semana.sh 17
```

En esta práctica pasan `solo-destino-permitido`, `webhook-app-firmado` y `webhook-automatizacion-firmado`.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `{"error":"Invalid url given"}` al crear el webhook | La red local está cerrada y `destino` no está en la lista | Paso 2 |
| Entregas con `"response_status":"401"` | La clave del `.env` y el `signing_token` del webhook no coinciden, o `destino` no se recreó | `docker compose --profile base up -d destino`; si cambiaste la clave, `PUT` del webhook con `url` y `signing_token` |
| La firma de ahora da `401` | `RECEPTOR_SIGNING_KEY` de tu terminal no es la de `destino` (¿regeneraste el `.env` y no recreaste?) | `docker compose --profile base up -d destino` y repite el `source` del paso 1 |
| `openssl: … -mac` no reconocido | `openssl` 1.0 o anterior | `openssl version`; con 1.1 o 3 funciona |
| `curl: (7) Failed to connect` | `destino` parado (paso 6) o `DESTINO_PORT` distinto | `docker compose start destino`; mira `DESTINO_PORT` en `.env` |
| El registro no tiene entradas `server_failure` | El pipeline terminó antes de que `destino` parara | Repite el paso 6 con `destino` ya parado |
| El reenvío da `200` pero el canal no cambia | Es lo esperado si el evento no era de un pipeline terminado, o si ya estaba anotado | `GET …/events/:id` y mira `request_data.object_attributes.status` |
| `The hook URL has changed` en un reenvío legítimo | Alguien cambió la URL del webhook | Devuélvela a la original (paso 10) |

---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| [Práctica 02 — El receptor](02-el-receptor.md) | [Práctica 04 — ChatOps](04-chatops.md) |

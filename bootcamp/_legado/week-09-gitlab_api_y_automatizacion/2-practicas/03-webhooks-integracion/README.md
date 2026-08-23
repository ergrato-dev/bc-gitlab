# Práctica 03 — Webhooks: Receptor Propio + Integración

**Duración estimada:** 40 minutos
**Dificultad:** ⭐⭐⭐ (Media-Alta)

## 🎯 Objetivo

Crear un servidor Flask que recibe webhooks de GitLab, valida el secret token, procesa los diferentes tipos de evento, y reenvía notificaciones a un sistema externo (Slack o log local). Configurar el webhook via API y probarlo disparando eventos reales.

---

## 📋 Prerrequisitos

```bash
pip install flask requests python-dotenv

# Variables necesarias del lab anterior
echo $GITLAB_URL       # http://localhost
echo $GITLAB_TOKEN
echo $GITLAB_PROJECT_ID
```

---

## Paso 1: Servidor Receptor de Webhooks

Crear el archivo `webhook_server.py`:

```python
#!/usr/bin/env python3
"""
Receptor de webhooks de GitLab.
Valida el secret token, procesa eventos y los registra.
"""

from flask import Flask, request, jsonify, abort
import hmac, json, logging, os
from datetime import datetime

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

WEBHOOK_SECRET = os.environ.get("GITLAB_WEBHOOK_SECRET", "bootcamp-secret-2026")
RECEIVED_EVENTS = []   # almacén en memoria para ver los eventos recibidos


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "events_received": len(RECEIVED_EVENTS)})


@app.route("/events", methods=["GET"])
def list_events():
    """Ver todos los eventos recibidos."""
    return jsonify(RECEIVED_EVENTS[-20:])   # últimos 20


@app.route("/webhook", methods=["POST"])
def receive_webhook():
    # ¿QUÉ HACE?: Valida que la petición proviene realmente de GitLab
    # ¿POR QUÉ?: Sin validación, cualquiera puede enviar payloads a la URL pública
    # ¿PARA QUÉ?: Solo procesar eventos auténticos de nuestra instancia GitLab

    received_token = request.headers.get("X-Gitlab-Token", "")
    if not hmac.compare_digest(received_token, WEBHOOK_SECRET):
        logger.warning(f"Token inválido recibido: '{received_token[:8]}...'")
        abort(401, description="Token inválido")

    payload = request.json
    if not payload:
        abort(400, description="Payload JSON requerido")

    event_kind = payload.get("object_kind", "unknown")
    project_name = payload.get("project", {}).get("path_with_namespace", "?")
    event_user = payload.get("user", {}).get("username", "?")

    # Registrar el evento
    event_record = {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "kind": event_kind,
        "project": project_name,
        "user": event_user,
    }

    # Procesar según tipo de evento
    if event_kind == "push":
        result = handle_push(payload)
    elif event_kind == "merge_request":
        result = handle_merge_request(payload)
    elif event_kind == "issue":
        result = handle_issue(payload)
    elif event_kind == "pipeline":
        result = handle_pipeline(payload)
    elif event_kind == "build":
        result = handle_job(payload)
    else:
        result = {"message": f"Evento '{event_kind}' registrado (sin handler específico)"}

    event_record["details"] = result
    RECEIVED_EVENTS.append(event_record)
    logger.info(f"Evento procesado: {event_kind} | {project_name} | user: {event_user}")

    return jsonify({"status": "processed", "event": event_kind, **result}), 200


def handle_push(payload):
    ref = payload.get("ref", "")
    commits = payload.get("commits", [])
    branch = ref.replace("refs/heads/", "")
    messages = [c.get("message", "")[:60] for c in commits[:3]]
    logger.info(f"  Push a '{branch}': {len(commits)} commit(s)")
    for msg in messages:
        logger.info(f"    - {msg}")
    return {"branch": branch, "commits": len(commits)}


def handle_merge_request(payload):
    attrs = payload.get("object_attributes", {})
    action = attrs.get("action")
    title = attrs.get("title")
    source = attrs.get("source_branch")
    target = attrs.get("target_branch")
    iid = attrs.get("iid")
    logger.info(f"  MR !{iid} {action}: '{title}' ({source} → {target})")
    return {"iid": iid, "action": action, "title": title}


def handle_issue(payload):
    attrs = payload.get("object_attributes", {})
    action = attrs.get("action")
    title = attrs.get("title")
    iid = attrs.get("iid")
    labels = [l.get("title") for l in payload.get("labels", [])]
    logger.info(f"  Issue #{iid} {action}: '{title}' labels={labels}")
    return {"iid": iid, "action": action, "title": title, "labels": labels}


def handle_pipeline(payload):
    attrs = payload.get("object_attributes", {})
    status = attrs.get("status")
    ref = attrs.get("ref")
    pipeline_id = attrs.get("id")
    duration = attrs.get("duration")
    logger.info(f"  Pipeline #{pipeline_id} [{status}] en '{ref}' duración: {duration}s")

    # Alerta especial en pipelines fallidos
    if status == "failed":
        logger.warning(f"  ⚠️ PIPELINE FALLIDO en '{ref}' — revisar jobs")

    return {"pipeline_id": pipeline_id, "status": status, "ref": ref}


def handle_job(payload):
    build_id = payload.get("build_id")
    build_name = payload.get("build_name")
    build_status = payload.get("build_status")
    logger.info(f"  Job #{build_id} '{build_name}' → {build_status}")
    return {"build_id": build_id, "name": build_name, "status": build_status}


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    logger.info(f"Servidor webhook iniciado en http://0.0.0.0:{port}")
    logger.info(f"Secret token: {WEBHOOK_SECRET[:4]}{'*' * (len(WEBHOOK_SECRET)-4)}")
    app.run(host="0.0.0.0", port=port, debug=False)
```

---

## Paso 2: Arrancar el Servidor

```bash
# Exportar el secret
export GITLAB_WEBHOOK_SECRET="bootcamp-secret-2026"
export PORT=5000

# Arrancar el servidor
python3 webhook_server.py &
SERVER_PID=$!

# Verificar que responde
sleep 1
curl --silent "http://localhost:5000/health" | python3 -m json.tool
```

---

## Paso 3: Exponer con ngrok

GitLab (que corre en un contenedor o en la red local) necesita una URL accesible para enviar los webhooks:

```bash
# En otra terminal — arrancar ngrok
ngrok http 5000

# ngrok muestra la URL pública temporal:
# Forwarding  https://abc123.ngrok-free.app → http://localhost:5000

# Copiar la URL https (por ejemplo: https://abc123.ngrok-free.app)
export NGROK_URL="https://abc123.ngrok-free.app"
```

Si GitLab y el servidor están en la misma máquina (Docker con host networking), puede funcionar directamente con `http://172.17.0.1:5000` (IP del host desde el contenedor):

```bash
# Detectar la IP del host accesible desde Docker
docker inspect $(docker ps -q --filter name=gitlab) \
  --format '{{range .NetworkSettings.Networks}}{{.Gateway}}{{end}}' 2>/dev/null \
  || echo "Usar ngrok si GitLab corre en contenedor"
```

---

## Paso 4: Registrar el Webhook en GitLab via API

```bash
# ¿QUÉ HACE?: Registra el servidor como destino de webhooks del proyecto
# ¿POR QUÉ?: Automatizar la configuración sin tocar la UI
# ¿PARA QUÉ?: Reproducible en scripts de bootstrap de nuevos proyectos

WEBHOOK_URL="${NGROK_URL:-http://localhost:5000}/webhook"
echo "Registrando webhook en: $WEBHOOK_URL"

HOOK_ID=$(curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{
    \"url\": \"$WEBHOOK_URL\",
    \"token\": \"$GITLAB_WEBHOOK_SECRET\",
    \"push_events\": true,
    \"merge_requests_events\": true,
    \"issues_events\": true,
    \"pipeline_events\": true,
    \"job_events\": true,
    \"enable_ssl_verification\": false
  }" \
  "$GITLAB_URL/api/v4/projects/$GITLAB_PROJECT_ID/hooks" \
  | python3 -c "
import sys, json
h = json.load(sys.stdin)
print(h.get('id', h))
")

echo "Webhook ID: $HOOK_ID"
```

---

## Paso 5: Disparar Eventos y Observar los Webhooks

```bash
# ¿QUÉ HACE?: Crea un issue para disparar el webhook de "Issues events"
# ¿POR QUÉ?: Necesitamos un evento real para ver el payload completo
# ¿PARA QUÉ?: Verificar que el receptor procesa correctamente el evento

# Crear un issue (dispara "issue created")
curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"title":"Issue para probar webhook","labels":"webhook,practica"}' \
  "$GITLAB_URL/api/v4/projects/$GITLAB_PROJECT_ID/issues" \
  | python3 -c "import sys,json; i=json.load(sys.stdin); print(f'Issue #{i[\"iid\"]} creado')"

# Esperar el webhook
sleep 2

# Ver eventos recibidos en el servidor
curl --silent "http://localhost:5000/events" \
  | python3 -c "
import sys, json
events = json.load(sys.stdin)
print(f'Eventos recibidos: {len(events)}')
for e in events[-5:]:
    print(f'  [{e[\"timestamp\"][:19]}] {e[\"kind\"]} | {e[\"project\"]} | {e[\"user\"]}')
    details = e.get('details', {})
    for k, v in details.items():
        print(f'    {k}: {v}')
"

# Enviar test de push event desde la API de GitLab
curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$GITLAB_PROJECT_ID/hooks/$HOOK_ID/test/push_events" \
  | python3 -c "import sys; print('Test webhook:', sys.stdin.read()[:100])"
```

---

## Paso 6: Validar el Secret Token

```bash
# ¿QUÉ HACE?: Envía una petición sin el secret token para verificar que el servidor rechaza
# ¿POR QUÉ?: La validación del token es crítica para la seguridad del webhook
# ¿PARA QUÉ?: Confirmar que solo GitLab (con el token correcto) puede disparar acciones

# Petición sin token (debe devolver 401)
HTTP_NO_TOKEN=$(curl --silent --output /dev/null --write-out "%{http_code}" \
  --request POST \
  --header "Content-Type: application/json" \
  --data '{"object_kind":"push"}' \
  "http://localhost:5000/webhook")
echo "Sin token: HTTP $HTTP_NO_TOKEN (esperado: 401)"

# Petición con token incorrecto (debe devolver 401)
HTTP_WRONG_TOKEN=$(curl --silent --output /dev/null --write-out "%{http_code}" \
  --request POST \
  --header "Content-Type: application/json" \
  --header "X-Gitlab-Token: token-incorrecto" \
  --data '{"object_kind":"push"}' \
  "http://localhost:5000/webhook")
echo "Token incorrecto: HTTP $HTTP_WRONG_TOKEN (esperado: 401)"

# Petición con token correcto (debe devolver 200)
HTTP_CORRECT=$(curl --silent --output /dev/null --write-out "%{http_code}" \
  --request POST \
  --header "Content-Type: application/json" \
  --header "X-Gitlab-Token: $GITLAB_WEBHOOK_SECRET" \
  --data '{"object_kind":"issue","object_attributes":{"action":"open","title":"Test","iid":99},"project":{"path_with_namespace":"test/test"},"user":{"username":"tester"},"labels":[]}' \
  "http://localhost:5000/webhook")
echo "Token correcto: HTTP $HTTP_CORRECT (esperado: 200)"
```

---

## Paso 7: Historial de entregas via API

```bash
# Ver las entregas del webhook (historial de requests enviados por GitLab)
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$GITLAB_PROJECT_ID/hooks/$HOOK_ID" \
  | python3 -c "
import sys, json
h = json.load(sys.stdin)
print(f'Webhook ID: {h[\"id\"]}')
print(f'URL: {h[\"url\"]}')
print(f'Eventos activos:')
for k, v in h.items():
    if k.endswith('_events') and v:
        print(f'  ✅ {k}')
"
```

---

## ✅ Checklist de verificación

- [ ] Servidor Flask arrancado y respondiendo en `http://localhost:5000/health`
- [ ] Webhook registrado en el proyecto via API
- [ ] Evento `issue` recibido al crear un issue (ver en `/events`)
- [ ] Test de `push_events` enviado desde la API de GitLab y recibido
- [ ] HTTP 401 confirmado con token incorrecto
- [ ] HTTP 200 confirmado con token correcto
- [ ] Log del servidor muestra el routing correcto por tipo de evento

---

## 🏆 Reto adicional

Añadir al servidor un endpoint que reenvíe notificaciones de pipelines fallidos a un webhook de Slack o Discord:

```python
import requests

SLACK_WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_URL", "")

def notify_failed_pipeline(pipeline_id, ref, project_name):
    if not SLACK_WEBHOOK_URL:
        return
    message = {
        "text": f"❌ Pipeline fallido en `{project_name}`",
        "attachments": [{
            "color": "danger",
            "fields": [
                {"title": "Rama", "value": ref, "short": True},
                {"title": "Pipeline", "value": f"#{pipeline_id}", "short": True},
            ]
        }]
    }
    requests.post(SLACK_WEBHOOK_URL, json=message, timeout=5)
```

---

⬅️ **Práctica anterior:** [02 — GraphQL](../02-graphql-consultas/README.md)
➡️ **Siguiente práctica:** [04 — Python Automatización](../04-python-automatizacion/README.md)

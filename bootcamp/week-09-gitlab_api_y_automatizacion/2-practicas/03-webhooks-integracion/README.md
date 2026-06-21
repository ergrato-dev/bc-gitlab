# Práctica 03 — Webhooks: Integración con Slack

## Objetivo

Configurar un webhook que publique notificaciones en Slack cuando ocurran eventos en GitLab.

## Requisitos previos
- Un webhook URL de Slack (Slack App con Incoming Webhook)

## Instrucciones

### Paso 1: Crear webhook en GitLab
1. Ve a tu proyecto → Settings → Webhooks
2. URL: Pega la URL del webhook de Slack
3. Secret Token: Define un token secreto (ej: `mi-secreto-2024`)
4. Triggers: selecciona Push events, Issues events, Merge request events
5. Desmarca "Enable SSL verification" si usas HTTP local
6. Haz clic en "Add webhook"

### Paso 2: Probar el webhook
1. Despliega la sección "Test" y selecciona "Push events"
2. Haz clic en "Test" y verifica la respuesta HTTP
3. Revisa el canal de Slack para confirmar que llegó la notificación

### Paso 3: Crear un endpoint receptor propio (avanzado)
Si no tienes Slack, puedes crear un receptor local con Python Flask:
```python
from flask import Flask, request
app = Flask(__name__)

@app.route("/webhook", methods=["POST"])
def webhook():
    event = request.json
    print(f"Evento: {event.get('object_kind')}")
    print(f"Proyecto: {event.get('project', {}).get('name')}")
    return "OK", 200

if __name__ == "__main__":
    app.run(port=5000)
```
Usa ngrok para exponer el endpoint: `ngrok http 5000`

## Preguntas de reflexión
- ¿Qué headers incluye la petición del webhook?
- ¿Cómo validarías que el webhook realmente viene de GitLab?
- ¿Qué limitaciones encontraste?

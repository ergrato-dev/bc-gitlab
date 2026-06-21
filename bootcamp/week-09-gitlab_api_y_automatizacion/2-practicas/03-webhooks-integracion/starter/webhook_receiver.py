#!/usr/bin/env python3
# ============================================
# Practica 03 — Webhook Receiver (Flask)
# ============================================
# Ejecutar: pip install flask
# Ejecutar: python webhook_receiver.py
# Exponer:  ngrok http 5000
# ============================================

import os
from flask import Flask, request, jsonify

app = Flask(__name__)

# Configurar en GitLab Webhook: un token secreto
WEBHOOK_SECRET = os.environ.get("WEBHOOK_SECRET", "mi-secreto-2024")

@app.route("/webhook", methods=["POST"])
def webhook():
    # Validar token secreto
    token = request.headers.get("X-Gitlab-Token", "")
    if token != WEBHOOK_SECRET:
        return jsonify({"error": "Token invalido"}), 403

    event = request.json
    event_type = event.get("object_kind", "desconocido")

    print(f"\n{'='*50}")
    print(f"Evento: {event_type}")

    if event_type == "push":
        print(f"Rama: {event.get('ref', 'N/A')}")
        print(f"Commits: {len(event.get('commits', []))}")
        print(f"Autor: {event.get('user_name', 'N/A')}")

    elif event_type == "issue":
        attrs = event.get("object_attributes", {})
        print(f"Issue: #{attrs.get('iid')} - {attrs.get('title')}")
        print(f"Estado: {attrs.get('state')}")
        print(f"Autor: {event.get('user', {}).get('name')}")

    elif event_type == "merge_request":
        attrs = event.get("object_attributes", {})
        print(f"MR: !{attrs.get('iid')} - {attrs.get('title')}")
        print(f"Estado: {attrs.get('state')}")
        print(f"Source: {attrs.get('source_branch')} → {attrs.get('target_branch')}")

    elif event_type == "pipeline":
        attrs = event.get("object_attributes", {})
        print(f"Pipeline: #{attrs.get('id')} - {attrs.get('status')}")
        print(f"Ref: {attrs.get('ref')}")

    else:
        print(f"Payload keys: {list(event.keys())}")

    return jsonify({"status": "received", "event": event_type}), 200

@app.route("/health")
def health():
    return jsonify({"status": "ok"}), 200

if __name__ == "__main__":
    print(f"Webhook receiver en http://0.0.0.0:5000/webhook")
    print(f"Secret token: {WEBHOOK_SECRET}")
    app.run(host="0.0.0.0", port=5000, debug=True)

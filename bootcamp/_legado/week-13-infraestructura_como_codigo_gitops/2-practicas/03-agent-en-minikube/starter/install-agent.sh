#!/usr/bin/env bash
# ============================================
# Practica 03 — Instalar GitLab Kubernetes Agent
# ============================================
# Uso: completar KAS_ADDRESS y AGENT_TOKEN, luego ./install-agent.sh

set -euo pipefail

AGENT_NAME="minikube-bootcamp"
KAS_ADDRESS="grpc://$(minikube ip):30051"   # ajustar puerto/host segun tu instalacion de kas
AGENT_TOKEN="${AGENT_TOKEN:-}"              # export AGENT_TOKEN=glagent-XXXX antes de correr

if [ -z "${AGENT_TOKEN}" ]; then
  echo "Error: exporta AGENT_TOKEN con el token obtenido en el Paso 3 del README"
  exit 1
fi

echo "=== Instalando ${AGENT_NAME} en Minikube ==="

helm repo add gitlab https://charts.gitlab.io
helm repo update

kubectl create namespace gitlab-agent --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install "${AGENT_NAME}" gitlab/gitlab-agent \
  --namespace gitlab-agent \
  --set image.tag=v17.2.0 \
  --set config.token="${AGENT_TOKEN}" \
  --set config.kasAddress="${KAS_ADDRESS}" \
  --wait --timeout 120s

echo "=== Verificando pod ==="
kubectl get pods -n gitlab-agent

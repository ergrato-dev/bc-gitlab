#!/usr/bin/env bash
# ============================================
# Proyecto Semana 13 — Makefile de Comandos Utiles
# ============================================
# Uso: make <comando>
#   make tf-init      — Inicializar Terraform con backend remoto
#   make tf-plan      — Generar plan
#   make tf-apply     — Aplicar plan generado
#   make agent-status — Verificar estado del Kubernetes Agent
#   make gitops-verify — Verificar imagen desplegada vs manifiesto

.PHONY: tf-init tf-plan tf-apply agent-status gitops-verify

tf-init:
	cd terraform && terraform init \
		-backend-config="username=terraform-bot" \
		-backend-config="password=$$TF_VAR_gitlab_token"

tf-plan:
	cd terraform && terraform plan -out=tfplan

tf-apply:
	cd terraform && terraform apply tfplan

agent-status:
	kubectl get pods -n gitlab-agent
	kubectl logs -n gitlab-agent deployment/minikube-bootcamp --tail 20

gitops-verify:
	@echo "=== Imagen desplegada en el clúster ==="
	kubectl get deployment demo-app -n produccion -o jsonpath='{.spec.template.spec.containers[0].image}'
	@echo ""
	@echo "=== Imagen declarada en el manifiesto ==="
	grep "image:" manifests/produccion/demo-app/deployment.yaml

#!/usr/bin/env bash
# ============================================
# Proyecto Final — Makefile de Comandos Utiles
# ============================================
# Uso: make <comando>
#   make up         — Levantar plataforma
#   make down       — Detener plataforma
#   make logs       — Ver logs GitLab
#   make backup     — Ejecutar backup
#   make restore T=timestamp — Restaurar backup
#   make verify     — Verificar estado

.PHONY: up down logs backup restore verify clean

up:
	docker compose up -d
	@echo "Esperando que GitLab este healthy..."
	@sleep 30
	docker compose ps

down:
	docker compose down

logs:
	docker compose logs -f gitlab

backup:
	@echo "Ejecutando backup..."
	docker compose exec gitlab gitlab-backup create STRATEGY=copy
	@echo "Backup completado."

restore:
ifndef T
	@echo "Uso: make restore T=<timestamp>"
	@echo "Listar backups: docker compose exec gitlab ls /var/opt/gitlab/backups/"
	@exit 1
endif
	docker compose exec gitlab gitlab-ctl stop puma
	docker compose exec gitlab gitlab-ctl stop sidekiq
	docker compose exec gitlab gitlab-backup restore BACKUP=$(T)
	docker compose exec gitlab gitlab-ctl reconfigure
	docker compose exec gitlab gitlab-ctl restart

verify:
	@echo "=== Docker Status ==="
	@docker compose ps
	@echo ""
	@echo "=== GitLab Health ==="
	@docker compose exec gitlab gitlab-ctl status 2>/dev/null || echo "GitLab aun iniciando..."
	@echo ""
	@echo "=== HTTP Check ==="
	@curl -s -o /dev/null -w "HTTP: %{http_code}\n" http://localhost || echo "No responde"

stats:
	docker stats --no-stream

clean:
	docker compose down -v
	@echo "Todos los datos eliminados."

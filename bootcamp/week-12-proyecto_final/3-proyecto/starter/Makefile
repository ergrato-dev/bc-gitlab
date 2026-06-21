# ============================================
# Proyecto Final — Skeleton
# ============================================
# Copia este Makefile y docker-compose como base.
# Personaliza segun tu proyecto.

.PHONY: up down logs backup restore verify clean all

all: up

up:
	docker compose up -d
	@echo "Esperando healthcheck..."
	@sleep 20
	@docker compose ps

down:
	docker compose down

logs:
	docker compose logs -f gitlab

backup:
	docker compose exec gitlab gitlab-backup create STRATEGY=copy
	@echo "✓ Backup completado"

restore:
	@test -n "$(T)" || (echo "Uso: make restore T=<timestamp>"; exit 1)
	docker compose exec gitlab gitlab-ctl stop puma sidekiq
	docker compose exec gitlab gitlab-backup restore BACKUP=$(T)
	docker compose exec gitlab gitlab-ctl reconfigure restart

verify:
	@echo "=== Servicios ==="
	@docker compose ps
	@echo ""
	@echo "=== HTTP ==="
	@curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost

stats:
	docker stats --no-stream

clean:
	docker compose down -v
	@echo "⚠ Todos los datos han sido eliminados"

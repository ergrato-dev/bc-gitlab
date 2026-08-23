# ============================================
# Practica 01 — Prometheus + Grafana Setup
# ============================================
# Requiere: docker compose --profile monitoring up -d

echo "=== Practica 01: Monitoreo ==="
echo ""

# ── PASO 1: Levantar monitoreo ──
echo "--- Paso 1: Levantar Prometheus + Grafana ---"
# docker compose --profile monitoring up -d
echo "Prometheus: http://localhost:9090"
echo "Grafana: http://localhost:3000 (admin/admin)"
echo ""

# ── PASO 2: Verificar metricas GitLab ──
echo "--- Paso 2: Metricas de GitLab ---"
echo "Endpoint de metricas de GitLab:"
# curl -s http://localhost/-/metrics | head -20
echo ""
echo "Metricas clave para verificar:"
echo "  http_requests_total"
echo "  ruby_gc_stat"
echo "  sidekiq_jobs_executed_total"
echo ""

# ── PASO 3: Configurar Grafana ──
echo "--- Paso 3: Configurar datasource Prometheus en Grafana ---"
echo "1. http://localhost:3000 → Configuration → Data Sources → Add"
echo "2. Prometheus → URL: http://prometheus:9090 → Save & Test"
echo ""
echo "3. Dashboards → Import → ID: 20916 (GitLab Omnibus)"
echo "   Select Prometheus datasource → Import"
echo ""

# ── PASO 4: Metricas clave para dashboard ──
echo "--- Paso 4: Metricas esenciales ---"
cat << 'METRICS'
PromQL queries utiles:
  rate(http_requests_total[5m])              → Requests/s
  histogram_quantile(0.95, rate(...)[5m])    → Latencia P95
  rate(sidekiq_jobs_executed_total[5m])      → Jobs Sidekiq/s
  gitlab_sql_duration_seconds_bucket         → Duracion queries SQL
  ruby_file_descriptors                      → FDs abiertos Puma
METRICS
echo ""

echo "=== Practica 01 completada ==="

# 05 — Presentación y Defensa del Proyecto

La defensa es la última evaluación del bootcamp. 15 minutos donde demuestras que puedes administrar GitLab CE en producción. No es un examen de memoria — es una demo de competencia práctica. Prepara el entorno, ensaya la secuencia y ten un plan B para cada punto de fallo.

---

## Estructura de los 15 minutos

| Segmento | Tiempo | Objetivo |
|---------|:------:|---------|
| 1. Introducción | 2 min | Contexto del proyecto y stack elegido |
| 2. Arquitectura | 2 min | Diagrama y decisiones técnicas |
| 3. Demo en vivo | 7 min | Infraestructura → Pipeline → Seguridad → Monitoreo |
| 4. Lecciones aprendidas | 2 min | Dificultades, sorpresas, mejoras futuras |
| 5. Preguntas | 2 min | Respuestas concisas (30-45 seg cada una) |

---

## Script de la demo (los 7 minutos críticos)

Preparar y ensayar EXACTAMENTE esta secuencia. No improvisar durante la demo.

```bash
# ─── DEMO SCRIPT ─────────────────────────────────────────────────────────────
# Ensayar 3 veces antes de la presentación real. Cronometrar.

# 0. Pre-demo (antes de que el evaluador entre)
cd ~/proyecto-final
docker compose up -d                       # Infraestructura levantada
# Verificar que todo está UP antes de empezar
docker compose ps

# ─── BLOQUE 1: INFRAESTRUCTURA (1:30 min) ─────────────────────────────────────
echo "=== Infraestructura ==="
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
# → Mostrar todos los servicios en estado "healthy"

# Abrir GitLab en el navegador: http://localhost
# Hacer login como admin, mostrar el dashboard
# Mostrar Admin Area → Runners (runner online)
# Mostrar el Container Registry del proyecto

# ─── BLOQUE 2: PIPELINE EN VIVO (2:30 min) ───────────────────────────────────
echo "=== Iniciando pipeline en vivo ==="
cd ~/proyecto-final/app
git checkout -b demo/$(date +%H%M) 2>/dev/null || git checkout demo/$(date +%H%M)
echo "# Demo commit $(date)" >> src/app.py
git add src/app.py
git commit -m "demo: trigger pipeline para defensa"
git push origin demo/$(date +%H%M)

# Abrir en navegador: CI/CD → Pipelines
# Mostrar los stages ejecutándose: build → test → security → deploy
# Si el pipeline ya corrió antes, mostrar el resultado del último exitoso

# ─── BLOQUE 3: SEGURIDAD (1:30 min) ──────────────────────────────────────────
# En GitLab UI: Security → Vulnerability Report
# Mostrar hallazgos de SAST (deben existir al menos 1-2 hallazgos en la app de demo)
# Explicar qué es cada hallazgo y por qué no se resolvió o cómo se resolvería

# ─── BLOQUE 4: MONITOREO (1:30 min) ──────────────────────────────────────────
# Abrir Grafana: http://localhost:3000
# Mostrar dashboard con métricas en tiempo real de GitLab
# Señalar: HTTP requests/sec, latencia P95, uso de disco
# Si hay alertas configuradas, mostrarlas en Alerting → Alert rules

# ─── BLOQUE 5: BACKUP (0:30 min) ─────────────────────────────────────────────
echo "=== Backup rápido ==="
docker exec gitlab gitlab-backup create 2>&1 | tail -5
ls -lh /var/opt/gitlab/backups/*.tar 2>/dev/null | tail -3
echo "Backup disponible en MinIO:"
docker exec minio mc ls local/gitlab-backups/ 2>/dev/null | tail -3
```

---

## Preparación técnica del entorno

```bash
# ¿QUÉ HACE?: Script de pre-validación antes de la defensa
# ¿POR QUÉ?: Detectar problemas 30 minutos antes de que el evaluador entre
# ¿PARA QUÉ?: Tener tiempo de corregir o activar el plan B sin entrar en pánico

#!/bin/bash
echo "=== Pre-validación para defensa ==="

checks_ok=0
checks_fail=0

check() {
  local name="$1"
  local cmd="$2"
  if eval "$cmd" > /dev/null 2>&1; then
    echo "✅ $name"
    ((checks_ok++))
  else
    echo "❌ $name — FALLA: verificar antes de la presentación"
    ((checks_fail++))
  fi
}

check "GitLab accesible" "curl -sf http://localhost/-/health"
check "Grafana accesible" "curl -sf http://localhost:3000/api/health"
check "Prometheus scrapea" "curl -sf http://localhost:9090/-/healthy"
check "MinIO accesible" "curl -sf http://localhost:9000/minio/health/live"
check "Runner online" "docker exec gitlab-runner gitlab-runner verify 2>&1 | grep -q 'is alive'"
check "Último pipeline exitoso" "
  curl -s --header 'PRIVATE-TOKEN: $ADMIN_TOKEN' \
  'http://localhost/api/v4/projects/1/pipelines?status=success&per_page=1' | \
  jq '.[0].status' | grep -q success"
check "Backup reciente (< 24h)" "
  find /var/opt/gitlab/backups -name '*.tar' -newer /tmp/.check_anchor 2>/dev/null | grep -q ."

echo ""
echo "Resultado: $checks_ok OK / $checks_fail FALLOS"
[ $checks_fail -eq 0 ] && echo "✅ Listo para la defensa" || echo "⚠️  Corregir $checks_fail puntos antes de empezar"
```

---

## Plan B: screenshots de respaldo

Preparar estas capturas antes de la presentación (en caso de fallo técnico):

1. **`screenshot-01-infra.png`**: `docker compose ps` con todos los servicios UP
2. **`screenshot-02-gitlab-ui.png`**: Pantalla principal de GitLab con proyectos visibles
3. **`screenshot-03-pipeline-success.png`**: Pipeline con todos los stages en verde
4. **`screenshot-04-security.png`**: Security Dashboard con hallazgos de SAST
5. **`screenshot-05-grafana.png`**: Dashboard Grafana con métricas con datos reales
6. **`screenshot-06-backup.png`**: Archivo de backup en MinIO o directorio local

```bash
# ¿QUÉ HACE?: Toma screenshots automáticos de todos los puntos de la demo
# ¿POR QUÉ?: Si algo falla en vivo, tienes evidencia de que funcionó
# ¿PARA QUÉ?: Plan B para la defensa — mostrar screenshots con explicación verbal

# Con gnome-screenshot o scrot en Linux:
mkdir -p ./docs/screenshots-defensa

# Capturas manuales recomendadas (hacer con el entorno completamente levantado):
# 1. Terminal con docker compose ps
# 2. Navegador: GitLab dashboard
# 3. Navegador: Pipeline exitoso con stages
# 4. Navegador: Security → Vulnerability Report
# 5. Navegador: Grafana con datos en tiempo real
# 6. Terminal: ls -lh del directorio de backups
```

---

## Preguntas frecuentes y respuestas preparadas

Responder en 30-45 segundos cada una. Practicar en voz alta.

**"¿Cómo manejarías un pico de 1000 usuarios repentinos?"**

> En el diseño actual (single-node) el cuello de botella sería Rails (Puma workers) y PostgreSQL. La solución inmediata es escalar verticalmente (más CPU/RAM al servidor). A largo plazo: separar GitLab Rails en múltiples nodos con HAProxy, y Gitaly en un cluster. Redis Cache reduce la carga de BD en lecturas repetitivas.

**"¿Qué pasaría si se corrompe la base de datos?"**

> El backup diario contiene un dump de PostgreSQL. El proceso es: detener GitLab, restaurar con `gitlab-backup restore BACKUP=<id>`, reconfigure y restart. El RPO es el tiempo desde el último backup — en este diseño, máximo 24 horas. Para RPO menor, necesitaría PostgreSQL con replicación streaming (Patroni).

**"¿Cómo actualizarías GitLab sin downtime?"**

> Con este docker-compose de single-node, hay downtime durante la actualización (típicamente 5-10 minutos). Para zero-downtime necesitaría GitLab en múltiples instancias con un load balancer. En la práctica, la ventana de mantenimiento nocturna es aceptable para equipos de hasta 200 personas.

**"¿Por qué no usaste GitLab SaaS en lugar de self-hosted?"**

> Para aprender administración. En GitLab.com no puedes configurar RBAC a nivel de instancia, gestionar runners propios, ajustar límites de recursos o configurar backup personalizado. Self-hosted da control total y es lo que se usa en empresas con requerimientos de compliance o con código que no puede salir de las instalaciones.

**"¿Cómo aseguras que los secrets no se filtren en el pipeline?"**

> Tres capas: Secret Detection en el pipeline detecta secretos en el código nuevo. Las variables CI/CD sensibles están marcadas como Masked (no aparecen en logs) y Protected (solo en ramas protegidas). El `.env` está en `.gitignore`. Para detectar secretos en el historial, se ejecuta el modo `historic` de Secret Detection o truffleHog.

**"¿Qué métricas son más importantes para ti?"**

> Depende del momento. Para operaciones diarias: latencia P95 de HTTP requests y tamaño de colas Sidekiq — si Sidekiq se acumula, los pipelines dejan de ejecutarse. Para capacidad: uso de disco de `/var/opt/gitlab` — si llega al 90%, los backups fallan. Para SLA: disponibilidad de la instancia medida con el healthcheck `/-/health`.

---

## Criterios de evaluación de la defensa

| Criterio | Peso | Descripción |
|---------|:----:|-------------|
| Demo funcional | 40% | Todo lo mostrado funciona durante la presentación |
| Dominio técnico | 30% | Responde preguntas con seguridad y precisión |
| Estructura | 20% | Presentación ordenada, tiempo respetado |
| Lecciones aprendidas | 10% | Reflexión genuina sobre desafíos y aprendizajes |

Para el criterio de "dominio técnico", lo que diferencia al estudiante que pasó las semanas leyendo del que experimentó es la capacidad de explicar *por qué* no solo *qué*. "Uso Patroni porque etcd garantiza que no haya dos primarios simultáneos" muestra comprensión; "uso Patroni porque es para HA" no.

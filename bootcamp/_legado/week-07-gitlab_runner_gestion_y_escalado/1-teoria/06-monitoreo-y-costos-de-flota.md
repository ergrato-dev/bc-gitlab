# 📖 06 — Monitoreo de Flota y Costos

## 🎯 Objetivos de aprendizaje

- ✅ Entender por qué monitorear una flota de runners es distinto a monitorear un runner individual
- ✅ Conocer las métricas Prometheus que expone `gitlab-runner` y qué preguntas responden
- ✅ Escribir queries PromQL para detectar colas, jobs lentos y errores
- ✅ Razonar el trade-off de costo entre autoscaling agresivo y colas largas
- ✅ Aplicar right-sizing de instancias y uso de Spot/Preemptibles con criterio

---

## 🤔 De un Runner a una Flota

Con un solo runner, "¿está funcionando?" se responde mirando la UI de GitLab. Con una flota de 20-100 instancias autoescaladas (Fleeting) o cientos de pods (Kubernetes Executor), esa pregunta cambia de forma:

- ¿Cuántos jobs están esperando en cola **ahora mismo**, y desde hace cuánto?
- ¿La flota está creciendo porque hay demanda real, o porque algo está reintentando jobs fallidos?
- ¿Cuánto cuesta la flota este mes, y ese costo corresponde a trabajo útil o a instancias idle?

Ninguna de estas preguntas se responde mirando runners uno por uno. Se necesita **series de tiempo agregadas** — que es exactamente lo que expone `gitlab-runner` en su endpoint de métricas.

---

## 📡 El Endpoint de Métricas

Todo `gitlab-runner` (Runner Manager, no cada worker) expone métricas en formato Prometheus:

```toml
# config.toml — habilitar el listener de métricas (si no está ya activo)
listen_address = ":9252"
```

```bash
# ¿QUÉ HACE?: Consulta el endpoint de métricas crudo, sin agregación
# ¿POR QUÉ?: Para verificar que el runner expone métricas antes de conectar Prometheus
# ¿PARA QUÉ?: Diagnóstico rápido sin depender de un servidor Prometheus ya desplegado

curl --silent http://localhost:9252/metrics | grep -v "^#"
```

### Métricas clave

| Métrica | Tipo | Qué mide |
|---------|------|----------|
| `gitlab_runner_jobs` | Gauge | Jobs corriendo ahora mismo en este runner |
| `gitlab_runner_jobs_total` | Counter | Total histórico de jobs procesados |
| `gitlab_runner_job_duration_seconds` | Histogram | Distribución de duración de jobs — permite calcular p50/p95/p99 |
| `gitlab_runner_job_queue_duration_seconds` | Histogram | Tiempo que un job esperó **en cola** antes de que un worker lo tomara |
| `gitlab_runner_concurrent` | Gauge | Valor configurado de `concurrent` en `config.toml` |
| `gitlab_runner_limit` | Gauge | Límite de jobs simultáneos por runner (`[[runners]] limit`) |
| `gitlab_runner_errors_total` | Counter | Errores del runner por tipo (`fatal`, `warning`) |
| `gitlab_runner_request_concurrency` | Gauge | Solicitudes de nuevos jobs en curso hacia GitLab |
| `gitlab_runner_request_concurrency_exceeded_total` | Counter | Veces que se alcanzó el límite de solicitudes concurrentes — señal de saturación |

> `gitlab_runner_job_queue_duration_seconds` es la métrica más importante para capacidad: si crece, la flota **no tiene suficientes workers** para la demanda actual, sin importar qué tan ocupados estén los que ya existen.

### Scrape config de Prometheus

```yaml
# ¿QUÉ HACE?: Configura Prometheus para scrapear cada Runner Manager de la flota
# ¿POR QUÉ?: Sin scrape config, las métricas existen pero nadie las recolecta ni las persiste
# ¿PARA QUÉ?: Tener series de tiempo históricas para dashboards y alertas

scrape_configs:
  - job_name: "gitlab-runner-fleet"
    static_configs:
      - targets:
          - "runner-manager-01:9252"
          - "runner-manager-02:9252"
        labels:
          fleet: "production"
    scrape_interval: 15s
```

En Kubernetes, se prefiere `ServiceMonitor` (si hay Prometheus Operator) apuntando al Service del Deployment del runner manager, en vez de `static_configs` con IPs fijas.

---

## 🔍 Queries PromQL de Ejemplo

```promql
# Jobs en cola ahora mismo (aproximación: jobs que llevan tiempo en el histograma de queue_duration
# sin haber transicionado — en la práctica se combina con gitlab_runner_jobs vs concurrent)
gitlab_runner_jobs / gitlab_runner_concurrent

# p95 del tiempo en cola de los últimos 15 minutos — alerta si supera el SLA del equipo
histogram_quantile(0.95, rate(gitlab_runner_job_queue_duration_seconds_bucket[15m]))

# p95 de duración de jobs — para detectar degradación de performance de la flota
histogram_quantile(0.95, rate(gitlab_runner_job_duration_seconds_bucket[15m]))

# Tasa de errores por minuto — cualquier valor sostenido > 0 amerita revisión
rate(gitlab_runner_errors_total[5m])

# Utilización de la flota: jobs corriendo sobre el límite configurado
sum(gitlab_runner_jobs) / sum(gitlab_runner_limit)

# Saturación de solicitudes — señal temprana de que hace falta más capacidad de autoscaling
increase(gitlab_runner_request_concurrency_exceeded_total[10m]) > 0
```

**Regla de lectura:** utilización sostenida cerca del 100% con cola creciendo (`job_queue_duration_seconds` subiendo) significa **falta capacidad**. Utilización baja (<30%) de forma sostenida con `max_instances` alto significa **sobra capacidad** — ahí es donde se desperdicia dinero.

---

## 📊 Dashboard Mínimo (Grafana)

Un dashboard de flota útil no necesita más de 4 paneles:

1. **Jobs en ejecución vs límite** (`gitlab_runner_jobs` / `gitlab_runner_concurrent`) — serie temporal
2. **p95 de tiempo en cola** (`gitlab_runner_job_queue_duration_seconds`) — alerta si cruza un umbral (ej. 2 minutos)
3. **Tasa de errores** (`rate(gitlab_runner_errors_total[5m])`) — alerta ante cualquier sostenido
4. **Número de instancias/pods activos** (si el proveedor cloud o Kubernetes expone esa métrica: `kube_pod_status_phase` para Kubernetes Executor, o métrica del Fleeting plugin/ASG para instancias)

El cuarto panel es el puente entre monitoreo y costo: cruza "instancias activas" contra "jobs en cola" y "utilización" para ver si el autoscaling está bien calibrado.

---

## 💰 Costo de la Flota

Autoscaling no elimina el costo — lo mueve de "runners fijos idle 24/7" a "picos de instancias bajo demanda". El objetivo es minimizar el costo total: **instancias idle desperdiciadas + tiempo de developers esperando en cola**.

### Autoscaling agresivo vs colas largas

| Configuración | Costo de infraestructura | Costo de espera (developers) |
|---------------|--------------------------|-------------------------------|
| `idle_count = 0`, `max_instances` bajo | Mínimo | Alto — cada pico genera cola + boot de VM (1-3 min) |
| `idle_count` alto, `max_instances` alto | Alto — muchas instancias pagadas sin trabajar | Mínimo — casi nunca hay cola |
| `idle_count` moderado, `idle_time` corto | Balanceado | Bajo, con algo de latencia en picos extremos |

No existe una configuración "correcta" universal — depende de si el equipo valora más el gasto cloud o el tiempo de los developers. Un equipo de 5 personas puede tolerar 2 minutos de cola ocasional; un equipo de 200 con pipelines en el camino crítico del deploy, no.

### Right-sizing de instancias

Un error común es usar el mismo tamaño de instancia para todos los jobs. Si el 90% de los jobs son builds livianos (`cpu_request = 500m`) y el 10% son builds pesados (compilación de monorepo), un solo tipo de instancia sobre-dimensionada para el caso común desperdicia capacidad en el 90% del tráfico.

```toml
# ¿QUÉ HACE?: Define dos pools de autoscaling con tamaños distintos de instancia
# ¿POR QUÉ?: Evita pagar instancias grandes para jobs que solo necesitan una fracción de esos recursos
# ¿PARA QUÉ?: Reducir el costo por job sin sacrificar velocidad de los builds pesados

[[runners]]
  name = "pool-liviano"
  executor = "docker-autoscaler"
  [runners.autoscaler]
    plugin_config = { instance_type = "t3.medium" }
    max_instances = 15

[[runners]]
  name = "pool-pesado"
  executor = "docker-autoscaler"
  [runners.autoscaler]
    plugin_config = { instance_type = "c5.2xlarge" }
    max_instances = 3
```

Enrutar cada job al pool correcto se hace con ↗ tags (ver [04 — Tags y Job Routing](./04-tags-y-job-routing.md)): `tags: [liviano]` vs `tags: [pesado]`.

### Instancias Spot / Preemptibles

Las instancias Spot (AWS) o Preemptibles (GCP) cuestan 60-90% menos que instancias on-demand, a cambio de que el proveedor puede interrumpirlas con poco aviso (2 minutos en AWS).

**Cuándo conviene:**
- Pools de jobs cortos y reintentables (tests, lint) — una interrupción solo reintenta el job
- `max_use_count` bajo, para minimizar el estado acumulado que se pierde en una interrupción

**Cuándo evitarlo:**
- Jobs largos y no idempotentes (deploys, migraciones de base de datos) — una interrupción a mitad de un deploy puede dejar el sistema en estado inconsistente
- Runners con `Specific Runner` para producción, donde la disponibilidad importa más que el ahorro

**Buena práctica:** mezclar pools — Spot para el pool liviano de tests, on-demand para el pool de deploys.

---

## 💡 Buenas Prácticas de Monitoreo y Costo

- Alertar sobre `gitlab_runner_job_queue_duration_seconds` p95, no solo sobre "instancia caída" — la cola es la señal que le importa al developer
- Revisar semanalmente la utilización real de la flota (`gitlab_runner_jobs / gitlab_runner_limit`) antes de subir `max_instances`
- Etiquetar el gasto cloud de los runners por separado del resto de la infraestructura, para poder atribuir costo de CI/CD a nivel de equipo o proyecto
- Combinar `idle_time` corto con `idle_count` bajo pero no cero, para el punto medio entre costo y latencia de arranque
- Revisar `max_use_count` y errores tras cambios en instancias Spot — una tasa de error creciente puede indicar interrupciones no manejadas

---

## 🤔 Preguntas de reflexión

1. Un dashboard muestra utilización de flota al 95% sostenido, pero `job_queue_duration_seconds` en 0. ¿Es esto un problema? ¿Qué pasaría si la demanda subiera un 10% más?

2. Un equipo decide mover su pool de tests a instancias Spot para ahorrar costo. Las interrupciones suben la tasa de reintentos de jobs un 15%. ¿Cómo calcularías si el ahorro de Spot compensa el costo de los reintentos (tiempo de CI + minutos de instancia gastados en jobs interrumpidos)?

3. `gitlab_runner_request_concurrency_exceeded_total` empieza a crecer. ¿Qué significa esto sobre la capacidad de la flota, y qué parámetro de `config.toml` revisarías primero?

4. Dos pools de autoscaling (liviano y pesado) comparten el mismo `max_instances` global implícito por budget del equipo. ¿Cómo decidirías cuánto presupuesto de instancias asignar a cada pool si no tenés datos históricos de uso?

---

## 📚 Recursos adicionales

- [GitLab Runner — Monitoring the Runner](https://docs.gitlab.com/runner/monitoring/)
- [Prometheus — Querying basics (PromQL)](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [AWS Spot Instances — Best Practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-best-practices.html)
- [GCP Preemptible VMs](https://cloud.google.com/compute/docs/instances/preemptible)
- [GitLab Runner Autoscaler (Fleeting)](https://docs.gitlab.com/runner/runner_autoscale/)

---

⬅️ **Lección anterior:** [05 — Autoscaling](./05-autoscaling.md)
➡️ **Prácticas:** [01 — Instalar Runner](../2-practicas/01-instalar-runner/README.md)

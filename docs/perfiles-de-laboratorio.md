# 🧪 Perfiles de Laboratorio

GitLab CE come unos 4 GB por sí solo. Añadir Kubernetes, un stack de observabilidad o seis contenedores de alta disponibilidad no cabe todo junto en 16 GB.

Por eso el laboratorio está partido en **perfiles de Docker Compose**. Cada semana declara el que necesita. Levantar el que no toca es la causa número uno de que la instancia se arrastre.

---

## Los perfiles

| Perfil | Qué levanta | Semanas | RAM aprox. | Estado |
|---|---|---|:--:|---|
| `base` | GitLab CE, GitLab Runner, cache de registry | Todas | ~5 GB | ✅ en `docker-compose.yml` |
| `observabilidad` | Prometheus, Grafana, Loki, Promtail | 21 | +4 GB | ✅ en `docker-compose.yml` |
| `ha` | Praefect, 3 Gitaly, PostgreSQL primario y réplica, PgBouncer | 23 | +8 GB | ⬜ se añade al escribir la Semana 23 |

```bash
docker compose --profile base up -d
docker compose --profile observabilidad up -d     # se suma a base
docker compose --profile observabilidad down      # apaga solo ese perfil
```

> [!NOTE]
> El perfil `ha` está declarado aquí porque el presupuesto de memoria de todo el
> bootcamp depende de él, pero **todavía no existe en `docker-compose.yml`**: sus
> seis servicios se añaden en la tanda de la Semana 23, junto con el material que
> los explica. Hasta entonces, `docker compose --profile ha up -d` no levanta nada.

> [!IMPORTANT]
> **`observabilidad` y `ha` nunca se levantan a la vez.** Juntos superan los 16 GB y GitLab empieza a devolver 502 sin decirte por qué.

### Kubernetes no es un perfil

Las semanas 16 y 25 usan **k3d**, que crea su propio clúster fuera de Docker Compose. No hay perfil que lo cubra. Antes de levantarlo, apaga observabilidad:

```bash
docker compose --profile observabilidad down
k3d cluster create bootcamp --servers 1 --agents 1
```

---

## Presupuesto de memoria por semana

Las semanas que aprietan de verdad son cuatro. Estas son las cuentas y qué apagar en cada una.

### Semana 16 — Runners en Kubernetes (~11-12 GB)

`base` + k3d (1 server + 1 agent) + el runner ejecutándose en un pod.

Antes de empezar, baja el consumo de GitLab en `.env` y reconfigura:

```ruby
puma['worker_processes'] = 2
sidekiq['concurrency'] = 8
prometheus_monitoring['enable'] = false
```

Y crea el clúster pequeño: `k3d cluster create bootcamp --servers 1 --agents 1`.

### Semana 21 — Observabilidad (~10 GB)

`base` + `observabilidad`. Es la combinación cómoda: cabe sin tocar nada.

La retención de Loki está en 24 h y el scrape de Prometheus en 30 s a propósito. Subirlos llena el disco en un fin de semana.

### Semana 23 — Alta disponibilidad (~13-14 GB, sin margen)

**La semana más ajustada del bootcamp.** `base` + `ha` son seis contenedores nuevos.

Obligatorio antes de empezar:

1. `docker compose --profile observabilidad down` — el stack de la S21 no puede estar levantado.
2. Apagar registry, Pages y el Prometheus interno de GitLab en la configuración de Omnibus.
3. Gitaly a 512 MB cada uno y `postgresql['shared_buffers'] = '128MB'`.
4. Repositorios de laboratorio **por debajo de 50 MB**. Si tu `app/` pesa más, la reconciliación de Praefect tarda de más.

Si tu máquina tiene exactamente 16 GB y algo más abierto (navegador con muchas pestañas, un IDE pesado), cierra antes. Aquí no hay holgura.

### Semana 25 — GitOps (~11 GB)

`base` + k3d + el agente + la app desplegada.

**Reutiliza el clúster de la Semana 16** en vez de crear uno nuevo, y ten observabilidad apagada.

---

## Comprobar dónde estás

```bash
docker compose ps                    # qué está levantado
docker stats --no-stream             # cuánta memoria come cada contenedor
docker compose exec gitlab /opt/lab/lab-health
```

Si GitLab devuelve 502 o el navegador se queda colgando, casi siempre es memoria. Mira `docker stats` antes de tocar nada más.

---

## Empezar de cero

Si la instancia queda inservible y prefieres reconstruirla:

```bash
docker compose --profile base --profile observabilidad down -v
docker compose --profile base up -d
```

> [!WARNING]
> `down -v` borra los volúmenes: **se pierde tu proyecto entero**, con su historia de issues, merge requests y pipelines. Ese histórico es el entregable del bootcamp. Haz backup primero (`/opt/lab/lab-backup`, y copia también `gitlab-secrets.json`) o asume que empiezas de nuevo desde la Semana 01.

---

[← Volver a docs](README.md)

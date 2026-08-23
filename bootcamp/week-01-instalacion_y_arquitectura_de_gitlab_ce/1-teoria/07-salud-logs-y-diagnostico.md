# Salud, logs y diagnóstico

> `/-/health` te dice que Nginx contesta. `/-/readiness` te dice si GitLab sirve para algo. No son lo mismo y la diferencia importa.

## 🎯 Objetivos

- Distinguir los tres endpoints de salud y saber cuál usar en cada caso
- Leer la salida de `gitlab-ctl status` y detectar un proceso que se reinicia
- Saber en qué archivo de log está cada tipo de error
- Aplicar un orden de diagnóstico en vez de reiniciar a ciegas

---

## 1. Qué problema resuelve

"GitLab no va" no es un diagnóstico. Puede significar seis cosas distintas y cada una se arregla en un sitio.

El objetivo de este archivo es darte un **orden**: una secuencia de comprobaciones que va de lo barato a lo caro y que en tres o cuatro pasos te deja delante del proceso culpable.

---

## 2. Los tres endpoints de salud

GitLab expone tres, y confundirlos es la causa del error de diagnóstico más frecuente.

### `/-/health` — ¿hay alguien ahí?

```bash
curl -s http://localhost:8888/-/health
# GitLab OK
```

Devuelve texto plano y responde **sin arrancar la lógica de la aplicación**. Es barato y rápido.

> [!WARNING]
> **`/-/health` puede decir OK con la base de datos caída.** Solo confirma que el servidor web contesta. Es útil como healthcheck de Docker —queremos algo barato cada 60 segundos— y es engañoso como comprobación de que GitLab funciona.

### `/-/readiness` — ¿funciona de verdad?

```bash
curl -s http://localhost:8888/-/readiness | jq
```

```json
{
  "status": "ok",
  "master_check": [{ "status": "ok" }]
}
```

Este sí comprueba las dependencias reales: base de datos, Redis, Gitaly. Es el que responde a "¿puedo empezar a trabajar?".

Con `?all=1` da el detalle completo, componente por componente:

```bash
curl -s "http://localhost:8888/-/readiness?all=1" | jq
```

Ahí verás entradas separadas para `db_check`, `redis_check`, `gitaly_check` y alguna más. **Cuando algo falla, esta salida te dice directamente cuál.**

### `/-/liveness` — ¿está vivo el proceso?

```bash
curl -s http://localhost:8888/-/liveness
```

Comprueba que el proceso de la aplicación responde, sin mirar dependencias. En Kubernetes es lo que decide si hay que reiniciar el pod. En este laboratorio lo usarás poco.

| Endpoint | Comprueba | Úsalo para |
|---|---|---|
| `/-/health` | Que el servidor web contesta | Healthcheck barato y frecuente |
| `/-/readiness` | Base de datos, Redis, Gitaly | Saber si GitLab sirve para algo |
| `/-/liveness` | Que la aplicación responde | Decidir si reiniciar |

---

## 3. `gitlab-ctl status`, leído bien

```bash
docker compose exec gitlab gitlab-ctl status
```

```
run: gitaly: (pid 512) 3212s; run: log: (pid 400) 3230s
run: nginx: (pid 560) 3208s; run: log: (pid 430) 3230s
run: postgresql: (pid 480) 3220s; run: log: (pid 390) 3230s
run: puma: (pid 590) 42s; run: log: (pid 440) 3230s
run: sidekiq: (pid 610) 3200s; run: log: (pid 450) 3230s
```

Todo dice `run:`, así que a primera vista está bien. Y no lo está: **Puma lleva 42 segundos y el resto más de 3200**. Puma se acaba de reiniciar.

Un proceso que se reinicia solo se está muriendo. Si vuelves a mirar en un minuto y sigue teniendo un tiempo bajo, está en bucle, y la causa casi siempre es memoria.

Ese es el detalle que convierte `gitlab-ctl status` de "una lista de `run:`" en una herramienta útil: **no mires los estados, mira los tiempos**.

---

## 4. Dónde está cada log

Todos cuelgan de `/var/log/gitlab/<proceso>/`:

| Archivo | Qué contiene | Cuándo mirarlo |
|---|---|---|
| `gitlab-rails/production.log` | Todas las peticiones de Rails | Un 500 en la interfaz |
| `gitlab-rails/api_json.log` | Peticiones a la API v4, en JSON | Un endpoint que no responde como esperas |
| `gitlab-rails/application.log` | Eventos de la aplicación: logins, creación de proyectos | Auditoría básica |
| `gitlab-rails/exceptions_json.log` | Excepciones con su traza | Un error que no entiendes |
| `sidekiq/current` | Trabajos en segundo plano | Un pipeline que no arranca |
| `gitaly/current` | Operaciones de Git | Clones que fallan |
| `nginx/gitlab_access.log` | Todas las peticiones HTTP | ¿Llegó siquiera la petición? |
| `nginx/gitlab_error.log` | Errores de Nginx | 502 y 504 |
| `postgresql/current` | Base de datos | GitLab no arranca |
| `reconfigure/` | Salida de `gitlab-ctl reconfigure` | Un cambio de configuración que falló |

La forma cómoda de seguirlos:

```bash
docker compose exec gitlab gitlab-ctl tail sidekiq
docker compose exec gitlab gitlab-ctl tail          # todos a la vez, muy ruidoso
```

### Los logs son JSON

La mayoría son JSON por línea, lo que los hace incómodos de leer y cómodos de filtrar:

```bash
docker compose exec gitlab tail -100 /var/log/gitlab/gitlab-rails/production.log \
  | jq -c 'select(.status >= 500) | {path, status, duration_s}'
```

Eso saca solo los errores de servidor de las últimas 100 peticiones. Sin `jq` sería ilegible.

**Las peticiones más lentas:**

```bash
docker compose exec gitlab tail -500 /var/log/gitlab/gitlab-rails/production.log \
  | jq -c 'select(.duration_s > 1) | {path, duration_s}'
```

---

## 5. El orden de diagnóstico

De lo barato a lo caro. No te saltes pasos: cada uno descarta un grupo entero de causas.

**1. ¿El contenedor está arriba?**

```bash
docker compose ps
```

**2. ¿GitLab está listo, no solo vivo?**

```bash
curl -s "http://localhost:8888/-/readiness?all=1" | jq
```

Si aquí ya te dice qué componente falla, has terminado el diagnóstico en dos pasos.

**3. ¿Qué proceso está mal, o se está reiniciando?**

```bash
docker compose exec gitlab gitlab-ctl status
```

Mira los tiempos, no los estados.

**4. ¿Es memoria?**

```bash
docker stats --no-stream
```

Si el contenedor está rozando su límite, ya sabes la causa: no hay bug, hay RAM insuficiente. Casi siempre es haber levantado dos perfiles a la vez.

**5. El log del proceso concreto.**

```bash
docker compose exec gitlab gitlab-ctl tail <proceso>
```

**6. Y si nada encaja, la comprobación general:**

```bash
docker compose exec gitlab gitlab-rake gitlab:check
```

Tarda un par de minutos y comprueba permisos, conectividad con Gitaly, migraciones pendientes y una lista larga de cosas. Es el último recurso porque es el más lento, no porque sea el menos útil.

El atajo del laboratorio hace los pasos 2, 3 y parte del 4 de una vez:

```bash
docker compose exec gitlab /opt/lab/lab-health
```

---

## 6. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Usar `/-/health` como prueba de que GitLab funciona | Devuelve OK con la base de datos caída | `/-/readiness?all=1` |
| Reiniciar antes de diagnosticar | A veces arregla y nunca enseña; vuelve a pasar | Los seis pasos, en orden |
| Leer `production.log` a pelo | Es JSON: ilegible sin filtrar | `jq` con `select()` |
| Mirar solo los estados de `gitlab-ctl status` | Un proceso en bucle aparece como `run:` | Comparar los tiempos de actividad |
| Dar por buggeada una instancia lenta | Casi siempre es memoria | `docker stats` antes que nada |
| `gitlab-rake gitlab:check` como primer paso | Tarda minutos y suele haber respuestas más rápidas | Déjalo para el paso 6 |

---

## 7. Trucos

**Un vistazo completo en una línea:**

```bash
docker compose exec gitlab /opt/lab/lab-health
```

**Detectar procesos reiniciados sin leer toda la salida:**

```bash
docker compose exec gitlab gitlab-ctl status | awk '{print $2, $4}' | sort -t: -k2 -n
```

**Los errores 500 recientes, legibles:**

```bash
docker compose exec gitlab tail -200 /var/log/gitlab/gitlab-rails/production.log \
  | jq -c 'select(.status >= 500) | {path, status, exception: .exception_class}'
```

**Comprobar solo Gitaly, sin el `gitlab:check` completo:**

```bash
docker compose exec gitlab gitlab-rake gitlab:gitaly:check
```

**Ver el tamaño de las colas de Sidekiq sin abrir la interfaz:**

```bash
docker compose exec gitlab gitlab-rails runner \
  'puts Sidekiq::Queue.all.map { |q| "#{q.name}: #{q.size}" }'
```

Arranca una consola de Rails, así que tarda unos segundos. Pero responde a "¿está Sidekiq atascado?" sin salir de la terminal.

---

## 📚 Recursos Adicionales

- [Comprobaciones de estado](https://docs.gitlab.com/ee/administration/monitoring/health_check.html) — los tres endpoints y qué comprueba cada uno
- [Logs de GitLab](https://docs.gitlab.com/ee/administration/logs/) — el catálogo completo, muchos más de los diez de la tabla
- [Solución de problemas](https://docs.gitlab.com/ee/administration/troubleshooting/) — casos concretos y sus síntomas
- [Comandos de `gitlab-rake`](https://docs.gitlab.com/ee/administration/raketasks/) — todas las tareas de mantenimiento y diagnóstico

---

## ✅ Checklist de Verificación

- [ ] Sabes por qué `/-/health` puede mentir y `/-/readiness` no
- [ ] Sabes detectar un proceso que se reinicia en bucle
- [ ] Sabes en qué log mirar si un pipeline no arranca, y en cuál si hay un 502
- [ ] Puedes recitar el orden de diagnóstico de seis pasos
- [ ] Sabes filtrar `production.log` con `jq` para ver solo los errores

---

| Anterior | Siguiente |
|---|---|
| [← 06 — Dónde viven los datos](06-donde-viven-los-datos.md) | [08 — Tokens y la API v4 →](08-tokens-y-api-v4.md) |

[← Volver a la Semana 01](../README.md)

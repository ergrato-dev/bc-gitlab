# Práctica 04 — Escalar y medir

> Bajas `concurrent` a 2 y ves cómo los jobs esperan en GitLab sin fallar. Pones una `ResourceQuota` y ves lo contrario: los jobs que no caben fallan. Mides cuánta memoria gasta de verdad cada contenedor de un job, sacas los minutos de job de cada runner para el proyecto, y eliges el `concurrent` definitivo. El archivo de valores, con esa cifra, queda versionado en `infra/entornos` junto a la plantilla de la Semana 15.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 03 completada · Teoría [04](../1-teoria/04-el-pod-de-un-job.md) y [05](../1-teoria/05-escalar-con-la-cola.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | `concurrent = 2`, y la cola que provoca | — |
| 2 | Una cuota, y los jobs que rompe | — |
| 3 | Lo que gasta de verdad cada contenedor | — |
| 4 | Los minutos de job de cada runner | — |
| 5 | El `concurrent` definitivo, aplicado | — |
| 6 | El archivo de valores en `infra/entornos` | `values-en-infra`, `values-sin-secretos` |

Desde la terminal de la práctica 03, o repitiendo el paso 0 de la práctica 01.

---

## Paso 1: `concurrent = 2`

**Por qué**: es el freno bueno. Lo que no cabe espera en `pending` y entra cuando se libera un hueco (teoría 05, apartado 2.1). Se cambia en el archivo, no con `--set`, para que lo aplicado y lo escrito no se separen.

```bash
cd ~/bc-s16
sed -i 's/^concurrent: 6$/concurrent: 2/' k8s-app.values.yaml
helm upgrade k8s-app gitlab/gitlab-runner --version 0.91.2 -n gitlab-runner -f k8s-app.values.yaml
kubectl -n gitlab-runner rollout status deploy/k8s-app-gitlab-runner --timeout=120s
kubectl -n gitlab-runner get cm k8s-app-gitlab-runner -o jsonpath='{.data.config\.toml}' | grep concurrent
```

**Verifica**: `concurrent = 2`. Ahora un pipeline, y la cola de cada job:

```bash
PIPE=$(curl -s --request POST "$API/projects/$P/pipeline" -H "$H" --data-urlencode ref=main | jq -r .id)
esperar "$P" "$PIPE"
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | "\(.name)  cola=\(.queued_duration // 0 | floor) s"'
```

`success`, y en el stage `test` dos jobs con unos segundos de cola y el resto con casi lo que dura un `test`: esperaron a que acabaran los primeros. Ninguno falló.

---

## Paso 2: Una cuota no es una cola

**Por qué**: una `ResourceQuota` parece el mismo freno que `concurrent`, pero el gestor no la conoce. Acepta el job y es el clúster el que le niega el pod (teoría 05, apartado 2.2). Vuelve primero a 6 para que `concurrent` no frene antes que la cuota:

```bash
sed -i 's/^concurrent: 2$/concurrent: 6/' k8s-app.values.yaml
helm upgrade k8s-app gitlab/gitlab-runner --version 0.91.2 -n gitlab-runner -f k8s-app.values.yaml
kubectl -n gitlab-runner rollout status deploy/k8s-app-gitlab-runner --timeout=120s
kubectl -n gitlab-runner create quota ci --hard=pods=3
PIPE=$(curl -s --request POST "$API/projects/$P/pipeline" -H "$H" --data-urlencode ref=main | jq -r .id)
esperar "$P" "$PIPE"
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | "\(.name)  \(.status)  \(.failure_reason // "")"'
```

**Verifica**: `failed`, con varios jobs `failed` y `runner_system_failure`. El log de uno lo explica:

```bash
J=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs?scope=failed" | jq -r '.[0].id')
curl -s -H "$H" "$API/projects/$P/jobs/$J/trace" | grep -o 'exceeded quota: ci[^.]*'
kubectl -n gitlab-runner describe quota ci | tail -2
```

`exceeded quota: ci, requested: pods=1, used: pods=3, limited: pods=3`. Quita la cuota y relanza los jobs que fallaron:

```bash
kubectl -n gitlab-runner delete quota ci
curl -s --request POST "$API/projects/$P/pipelines/$PIPE/retry" -H "$H" > /dev/null
sleep 10    # el pipeline tarda unos segundos en dejar de estar en failed
esperar "$P" "$PIPE"
```

`success`. Sin el `sleep`, `esperar` puede leer el `failed` de antes del reintento y volver al instante. Una cuota así en el namespace de un runner solo tiene sentido muy por encima de `concurrent`, como seguro.

---

## Paso 3: Lo que gasta cada contenedor

**Por qué**: `memory_request = "128Mi"` y `memory_limit = "1Gi"` son cifras de partida. La buena es la que gastan tus jobs. k3s trae `metrics-server`, y `kubectl top` da el consumo de cada contenedor mientras corre (teoría 04, trucos).

```bash
PIPE=$(curl -s --request POST "$API/projects/$P/pipeline" -H "$H" --data-urlencode ref=main | jq -r .id)
: > ~/bc-s16/top.log
until curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE" | jq -e '.status | IN("success","failed","canceled")' > /dev/null; do
  kubectl -n gitlab-runner top pod --containers --no-headers 2>/dev/null | grep '^runner-' >> ~/bc-s16/top.log
  sleep 5
done
awk '{ if ($4 + 0 > m[$2] + 0) m[$2] = $4 } END { for (c in m) print c, m[c] }' ~/bc-s16/top.log
```

**Verifica**: una línea por contenedor (`build`, `helper`, y los servicios si los hay) con el máximo que se vio. `metrics-server` muestrea cada pocos segundos: un pico corto se le puede escapar, así que toma la cifra como orientación. Si `build` pasa de 128 Mi, el `request` se queda corto y el clúster puede meter más pods de los que caben; si se acerca a 1 Gi, el `limit` está a punto de matar el job. Apunta las dos cifras: van a `docs/finops.md`.

---

## Paso 4: Los minutos de cada runner

**Por qué**: el coste de la teoría 06 empieza por el trabajo. `GET /runners/:id/jobs` da los últimos jobs de cada runner, con su duración y su cola.

```bash
for R in $RID_DOCKER $RID_K8S $RID_DIND $RID_DEPLOY; do
  curl -s -H "$H" "$API/runners/$R/jobs?per_page=100" | jq -r --arg r "$(curl -s -H "$H" "$API/runners/$R" | jq -r .description)" \
    '"\($r): \(length) jobs, \(map(select(.status == "success")) | length) en verde, \(([.[].duration // 0] | add) / 60 | floor) min de job, cola media \(([.[].queued_duration // 0] | add) / ([length, 1] | max) | floor) s"'
done
```

**Verifica**: cuatro líneas. `docker-app` con lo que hizo hasta el relevo, `k8s-app` con lo de esta semana, y los otros dos con lo suyo. `per_page=100` corta en los cien últimos: es una muestra, y así lo dirá `docs/finops.md`.

---

## Paso 5: El `concurrent` definitivo

**Por qué**: el número sale de lo medido, no de una costumbre. Con los máximos del paso 3, ¿cuántos pods de job caben en la memoria que te queda libre con todo levantado? Ese es el techo; `concurrent` va por debajo.

```bash
free -m | awk '/Mem/ {print $7 " MB disponibles"}'
```

Un ejemplo: 3000 MB disponibles, `memory_limit = 1Gi` y un `build` que gasta 300 Mi. Seis pods en el peor caso (todos en el límite) son 6 GiB: no caben. Seis pods con el gasto medido son unos 2 GB: caben. `concurrent = 6` es razonable si aceptas que, en el peor caso, un job falle por memoria; `concurrent = 3` si no. Escribe tu cifra en el archivo y aplícala:

```bash
sed -i 's/^concurrent: [0-9]*$/concurrent: <tu cifra>/' k8s-app.values.yaml
helm upgrade k8s-app gitlab/gitlab-runner --version 0.91.2 -n gitlab-runner -f k8s-app.values.yaml
kubectl -n gitlab-runner rollout status deploy/k8s-app-gitlab-runner --timeout=120s
```

**Verifica**: `kubectl -n gitlab-runner get cm k8s-app-gitlab-runner -o jsonpath='{.data.config\.toml}' | grep concurrent` dice tu cifra. La justificación va en `docs/finops.md` (proyecto).

---

## Paso 6: El archivo de valores, versionado

**Por qué**: es infraestructura y se revisa como tal, igual que la plantilla del `config.toml` de la Semana 15. No lleva ningún secreto: los dos están en `Secret` del clúster.

```bash
cd /ruta/a/tus/clones/entornos && git switch main && git pull --ff-only
cp ~/bc-s16/k8s-app.values.yaml runners/k8s-app.values.yaml
grep -c 'glrt-' runners/k8s-app.values.yaml      # 0
git add runners/k8s-app.values.yaml
git commit -S -m "docs: values de Helm del runner k8s-app, sin secretos"
git push origin main
```

**Verifica**: `0` coincidencias, y el push aceptado. La prueba de que el archivo versionado es lo que corre: renderizar el chart con él y compararlo con lo que Helm dice que está aplicado.

```bash
helm get manifest k8s-app -n gitlab-runner > ~/bc-s16/aplicado.yaml
helm template k8s-app gitlab/gitlab-runner --version 0.91.2 -n gitlab-runner \
  -f runners/k8s-app.values.yaml > ~/bc-s16/versionado.yaml
diff -B ~/bc-s16/aplicado.yaml ~/bc-s16/versionado.yaml && echo "lo versionado es lo que corre"
```

`lo versionado es lo que corre`. Reconstruir el runner tras perder el clúster son la práctica 01, los dos `Secret` y este archivo: lo que la Semana 22 ensaya.

---

## ✅ Resultado

- [ ] Con `concurrent = 2`, los jobs esperan y ninguno falla
- [ ] Con una cuota, los jobs que no caben fallan; la cuota, borrada
- [ ] El máximo de memoria de `build` y `helper`, apuntado
- [ ] Los minutos de job de los cuatro runners, apuntados
- [ ] Tu `concurrent`, aplicado y justificado con cifras
- [ ] `runners/k8s-app.values.yaml` en `main` de `infra/entornos`, sin tokens, idéntico a lo que corre

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| En el paso 1 todos los `test` arrancan a la vez | El gestor viejo sigue vivo con `concurrent = 6` | `kubectl -n gitlab-runner get pods`: espera a que solo quede el nuevo |
| En el paso 2 no falla nada | El pipeline cupo en la cuota | Comprueba `kubectl -n gitlab-runner get quota`; con `pods=3` y cuatro `test`, alguno no cabe |
| `kubectl top` dice `Metrics API not available` | `metrics-server` aún arranca | Espera un minuto: `kubectl -n kube-system get pods \| grep metrics` |
| `top.log` vacío | El pipeline acabó antes de la primera muestra, o los pods no empiezan por `runner-` | Relanza; `kubectl -n gitlab-runner get pods` mientras corre |
| `diff` enseña diferencias | Cambiaste algo con `--set`, o editaste `~/bc-s16` después de copiar | `helm upgrade … -f runners/k8s-app.values.yaml` y repite el `diff` |
| El push a `main` de `infra/entornos` se rechaza | Tu usuario no es Maintainer, o falta la firma | Como en la Semana 15, práctica 04, paso 5 |

---

[← Volver a la Semana 16](../README.md)

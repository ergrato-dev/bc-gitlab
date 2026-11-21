# Práctica 03 — El relevo

> Mides tres pipelines de `main` con `docker-app`, el runner de la Semana 09. Haces el relevo: despausas `k8s-app` y pausas `docker-app`, sin tocar una línea del `.gitlab-ci.yml`. Mides otros tres con Kubernetes, miras nacer y morir un pod por job, y versionas las dos medidas en `docs/linea-base-s16.json` de `app`. Ese archivo es lo que la Semana 21 y la defensa de la Semana 26 comparan.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 02 completada · Teoría [05](../1-teoria/05-escalar-con-la-cola.md) y [06](../1-teoria/06-finops-de-ci.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | Nada en marcha que falsee las medidas | — |
| 2 | La función `medir` | — |
| 3 | Tres pipelines medidos con `docker-app` | — |
| 4 | El relevo: `k8s-app` activo, `docker-app` en pausa | `runner-kubernetes-en-linea`, `docker-app-en-pausa`, `un-solo-runner-docker-activo` |
| 5 | Tres pipelines medidos con Kubernetes | `main-en-kubernetes`, `dind-sigue-en-linea` |
| 6 | La línea base, versionada en `app` | `linea-base-versionada`, `linea-base-compara-runners`, `linea-base-en-verde` |

Desde la terminal de la práctica 02, o repitiendo el paso 0 de la práctica 01.

---

## Paso 1: Nada más en marcha

**Por qué**: una medida con otro pipeline corriendo a la vez mide la competencia por los huecos, no el runner. Y la primera medida, con la caché fría, saldría peor sin culpa del runner (teoría 06, apartado 3).

```bash
curl -s -H "$H" "$API/projects/$P/pipelines?scope=running" | jq length
curl -s -H "$H" "$API/projects/$PI/pipelines?scope=running" | jq length
```

**Verifica**: `0` y `0`. Si no, espera o cancela lo que corre. Lanza un pipeline de `main` y espera a que acabe, para que la caché de `npm` esté caliente en `cache-s3`:

```bash
esperar "$P" "$(curl -s --request POST "$API/projects/$P/pipeline" -H "$H" --data-urlencode ref=main | jq -r .id)"
```

`success`.

---

## Paso 2: La función `medir`

**Por qué**: las tres cifras de la teoría 06, apartado 2.1, por pipeline, más quién corrió los jobs. Tres pipelines seguidos, uno detrás de otro.

```bash
medir() {   # tres pipelines de main, uno detrás de otro: duración, cola, minutos de job y runners
  local PIPE
  for i in 1 2 3; do
    PIPE=$(curl -s --request POST "$API/projects/$P/pipeline" -H "$H" --data-urlencode "ref=main" | jq -r .id)
    esperar "$P" "$PIPE" > /dev/null
    curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs?per_page=100" \
      | jq -c --argjson p "$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE")" \
        '{id: $p.id, estado: $p.status, duracion: $p.duration, cola: ($p.queued_duration // 0),
          runners: ([.[].runner.description] | unique), jobs: length,
          minutos_de_job: (([.[].duration // 0] | add) / 60 * 100 | round / 100)}'
  done | jq -s '{pipelines: ., media_duracion: (map(.duracion) | add / length | round)}'
}
```

| Campo | De dónde |
|---|---|
| `duracion`, `cola` | `duration` y `queued_duration` del pipeline |
| `runners` | La `description` del runner de cada job, sin repetir |
| `minutos_de_job` | La suma de `duration` de sus jobs, en minutos, con dos decimales |

Los jobs `trigger` (el despliegue en `infra/entornos`) no salen en `/jobs`: los minutos de `deploy-infra` se cuentan en `infra/entornos`, no aquí.

**Verifica**: `type medir | head -1` dice `medir is a shell function` (zsh añade `from …`).

---

## Paso 3: Antes, con `docker-app`

**Por qué**: es la línea base. `k8s-app` está en pausa desde la práctica 02, así que todo lo que no pide `dind` lo coge `docker-app`. Tarda tres pipelines completos de `main`, con sus despliegues en `staging`: entre 10 y 15 minutos.

```bash
medir > ~/bc-s16/antes.json
jq -c '.media_duracion, (.pipelines[] | [.id, .estado, .duracion, .cola, .runners, .minutos_de_job])' ~/bc-s16/antes.json
```

**Verifica**: tres pipelines `success`, cada uno con `["dind-app","docker-app"]` en `runners`. Si sale `k8s-app`, no estaba en pausa: repite la práctica 02, paso 2, y vuelve a medir. Apunta la media: es el número que tiene que mejorar.

---

## Paso 4: El relevo

**Por qué**: `docker-app` no se borra. Pausado, sigue registrado con su token y su configuración, y deshacer el relevo son las dos mismas llamadas al revés (teoría 01, antipatrones). Primero se despausa el nuevo: así nunca hay un momento sin runner para la etiqueta `docker`.

```bash
curl -s --request PUT "$API/runners/$RID_K8S" -H "$H" --data paused=false | jq -c '{description, paused}'
curl -s --request PUT "$API/runners/$RID_DOCKER" -H "$H" --data paused=true | jq -c '{description, paused}'
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/runners?type=project_type" | jq -c '.[] | {description, paused, status}'
```

`k8s-app` con `paused: false` y `status: online`; `docker-app` con `paused: true` y `status: paused`; `dind-app` sin cambios.

`docker-app` también ejecutaba los pipelines de `ci/componentes` (Semana 12). Pausado, esos jobs se quedarían en `pending`: asigna `k8s-app` a ese proyecto también.

```bash
curl -s --request POST "$API/projects/plataforma-<tu-dominio>%2Fci%2Fcomponentes/runners" -H "$H" \
  --data "runner_id=$RID_K8S" | jq -r .description
curl -s -H "$H" "$API/runners/$RID_K8S" | jq -r '.projects[].path_with_namespace'
```

`k8s-app`, y después `app` y `ci/componentes`.

---

## Paso 5: Después, con Kubernetes

**Por qué**: las mismas tres medidas, con el mismo pipeline. Antes, un pipeline de calentamiento: la primera vez, cada nodo baja las imágenes de los jobs (en el lab, ese pipeline tardó 65 s y los dos siguientes 46 s). Con la medida de `antes` hiciste lo mismo en el paso 1. En otra terminal (con `source ~/.bc-gitlab-s16`), mira el clúster mientras tanto:

```bash
kubectl -n gitlab-runner get pods -w
```

Y en la de siempre:

```bash
esperar "$P" "$(curl -s --request POST "$API/projects/$P/pipeline" -H "$H" --data-urlencode ref=main | jq -r .id)"
medir > ~/bc-s16/despues.json
jq -c '.media_duracion, (.pipelines[] | [.id, .estado, .duracion, .cola, .runners, .minutos_de_job])' ~/bc-s16/despues.json
```

**Verifica**: tres `success` con `["dind-app","k8s-app"]`. En la otra terminal, pods `runner-…-project-<id>-concurrent-<n>-…` que pasan por `Pending`, `Running` y `Terminating`, varios a la vez en `test`. `probar-imagen` sigue en `dind-app`, como debe (teoría 01, apartado 2.4):

```bash
PIPE=$(jq -r '.pipelines[-1].id' ~/bc-s16/despues.json)
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | "\(.name) → \(.runner.description)"'
```

Compara las dos medias. En el pipeline de prueba del autor, `docker-app` con `limit = 2` daba 70 s y Kubernetes 44 s, con los mismos minutos de job. El tuyo tiene más jobs y despliegues: la diferencia será otra, y puede ser pequeña. Lo que cuenta es que esté medida.

---

## Paso 6: La línea base, versionada

**Por qué**: un número en tu terminal no lo puede revisar nadie. En `docs/` de `app`, por merge request, como el resto de la documentación (Semana 08).

```bash
cd /ruta/a/tus/clones/app && git switch main && git pull --ff-only
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Línea base de la ejecución en Kubernetes (S16)" | jq -r .iid)
git switch -c docs/linea-base-s16
jq -n --slurpfile a ~/bc-s16/antes.json --slurpfile d ~/bc-s16/despues.json \
  '{medido: (now | todate), pipeline: "main de app, tres seguidos con la caché caliente",
    antes: ($a[0] + {runner: "docker-app"}), despues: ($d[0] + {runner: "k8s-app"})}' > docs/linea-base-s16.json
git add docs/linea-base-s16.json
git commit -S -m "docs: línea base de la ejecución en Kubernetes"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="docs: línea base de la ejecución en Kubernetes" \
  -o merge_request.description="Closes #$IID"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
fusionar "$P" "$MR"
git switch main && git pull --ff-only
```

**Verifica**: `state: merged`, y en `main`:

```bash
jq -c '{antes: .antes.media_duracion, despues: .despues.media_duracion}' docs/linea-base-s16.json
```

Las dos medias. El pipeline de esa merge request corrió entero en `k8s-app`: la plataforma ya trabaja en Kubernetes.

---

## ✅ Resultado

- [ ] `~/bc-s16/antes.json`: tres pipelines `success` en `docker-app`
- [ ] `k8s-app` activo y `docker-app` en pausa, sin borrar
- [ ] `~/bc-s16/despues.json`: tres pipelines `success` en `k8s-app`, con `probar-imagen` en `dind-app`
- [ ] `docs/linea-base-s16.json` en `main` de `app`, por merge request

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| Un job de `despues` en `pending` mucho rato | El gestor no está `online` | `kubectl -n gitlab-runner get pods`; si el gestor no está `Running`, la tabla de la práctica 02 |
| Un job falla con `runner_system_failure` y `Insufficient memory` | El clúster no tiene sitio para el pod | `docker stats` y libera memoria; teoría 04, apartado 2.4 |
| `build` falla en `restore_cache` con `no such host` | El pod no llega a `cache-s3` | La práctica 01, paso 5 |
| `imagen` falla con `El registry no ha dado token` | `CI_SERVER_URL` no llega desde el pod | La variable de instancia de la Semana 09 debe ser `http://gitlab:8888`: el pod resuelve `gitlab` |
| Hay que deshacer el relevo | El clúster falla y hay que seguir trabajando | Paso 4 al revés: `docker-app` con `paused=false` primero, `k8s-app` con `paused=true` después |
| `una-gestora-para-app` de la Semana 15 sale en rojo | `k8s-app` es otro proceso: ahora hay dos `system_id` | Es lo esperado: esa comprobación describía la flota de la Semana 15 |

---

[← Volver a la Semana 16](../README.md)

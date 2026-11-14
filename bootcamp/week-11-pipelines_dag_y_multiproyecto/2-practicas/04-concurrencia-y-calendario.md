# Práctica 04 — Concurrencia y calendario

> Pones un candado por entorno a los despliegues, dejas que `staging` atienda solo a la versión más nueva y lanzas dos despliegues a `production` a la vez para ver cómo uno espera al otro. Después programas `caducidades` cada mañana, no sin antes sacar de los programados todo lo que despliega o dispara.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 03 completada · Teoría [07](../1-teoria/07-resource-groups.md) y [08](../1-teoria/08-pipelines-programados.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | `resource_group` en los despliegues | — |
| 2 | `.fuera-de-programados` y el job `caducidades`, fusionados | `resource-groups-de-despliegue`, `programados-sin-despliegue` |
| 3 | `staging` en `newest_first`, con los despliegues obsoletos prevenidos | `staging-despliega-lo-mas-nuevo` |
| 4 | Dos despliegues a `production` a la vez: uno espera | — |
| 5 | El programado de caducidades | `programa-de-caducidades` |
| 6 | El programado ejecutado: solo `caducidades`, en verde | `programado-en-verde` |

Si has cerrado la terminal, repite el paso 0 de la práctica 01 y `source ~/.bc-gitlab-s11`.

---

## Paso 1: Un candado por entorno

**Por qué**: con `concurrent = 2` desde la práctica 01, dos pipelines de `main` pueden llegar a `deploy-staging` a la vez, y el más viejo puede terminar el último (teoría 07, apartado 1).

```bash
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Candados de despliegue y vigilancia programada de caducidades" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=resource_group por entorno; caducidades en un pipeline programado que no despliega ni dispara nada. Ver Semana 11." \
  | jq -r .iid)
git switch -c "$IID-candados-y-programado"
```

En `.gitlab-ci.yml`, una línea en cada despliegue. El nombre es el del **recurso**, no el del job:

```yaml
deploy-staging:
  extends: .deploy
  resource_group: staging
  # … sin más cambios

deploy-production:
  extends: .deploy
  resource_group: production
  # … sin más cambios
```

---

## Paso 2: Fuera de los programados, y el job del programado

**Por qué**: un programado sobre `main` cumple todas las reglas que dicen "en `main`". Sin esto, cada mañana desplegarías `staging` y dispararías `infra/entornos` (teoría 08, apartado 2.4).

Al principio del archivo, después de `workflow`:

```yaml
.fuera-de-programados:
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: never
```

Y como **primera** regla de `.npm`, `package`, `deploy-staging`, `deploy-production` e `infra`:

```yaml
  rules:
    - !reference [.fuera-de-programados, rules]
    # … las reglas que ya tenía, sin cambios
```

`gobernanza` y `docs` no la necesitan: solo entran en merge requests.

El job del programado, junto a `gobernanza`:

```yaml
caducidades:
  stage: test
  image: alpine:3.24.2
  needs: []
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule" && $TAREA == "caducidades"
  script:
    - scripts/caducidades.sh
```

Es el mismo script que el hijo de documentación ejecuta en cada merge request que toca un `.md`: allí vigila que nadie rompa el formato; aquí, que el tiempo no pase sin que nadie mire.

Valida lo que entra en un push a `main`: lo mismo que antes, ni más ni menos.

```bash
jq -n --rawfile c .gitlab-ci.yml '{content: $c, dry_run: true, ref: "main", include_jobs: true}' \
  | curl -s --request POST "$API/projects/$P/ci/lint" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -c '{valid, errors, jobs: [.jobs[]?.name]}'
# {"valid":true,"errors":[],"jobs":["build","test","package","deploy-staging","deploy-production","infra"]}
```

`dry_run` simula un push: no puede enseñarte el programado. Eso lo compruebas en el paso 6.

```bash
git add .gitlab-ci.yml
git commit -S -m "ci: candados de despliegue y job programado de caducidades"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="ci: candados de despliegue y job programado de caducidades"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
fusionar "$MR"
git switch main && git pull --ff-only
sleep 10
PIPE=$(curl -s -H "$H" "$API/projects/$P/pipelines?ref=main&source=push&per_page=1" | jq -r '.[0].id')
esperar "$P" "$PIPE"
curl -s -H "$H" "$API/projects/$P/resource_groups" | jq -c '.[] | {key, process_mode}'
```

**Verifica**: `success`, y los dos grupos, creados por el primer pipeline que los usó:

```
{"key":"staging","process_mode":"unordered"}
{"key":"production","process_mode":"unordered"}
```

`production` existe aunque `deploy-production` siga en `manual`: el grupo se asigna al crear el job, no al ejecutarlo.

---

## Paso 3: `staging` atiende primero a lo más nuevo

**Por qué**: `staging` se despliega en cada fusión y solo importa la última. Con `newest_first`, el despliegue más nuevo pasa primero; la protección contra despliegues obsoletos hace fallar al viejo cuando llega su turno, en lugar de desplegarlo encima (teoría 07, apartado 2.3).

```bash
curl -s --request PUT "$API/projects/$P/resource_groups/staging" -H "$H" \
  --data "process_mode=newest_first" | jq -c '{key, process_mode}'
curl -s -H "$H" "$API/projects/$P" | jq '{ci_forward_deployment_enabled, ci_forward_deployment_rollback_allowed}'
```

**Verifica**: `{"key":"staging","process_mode":"newest_first"}` y los dos ajustes en `true`. Si `ci_forward_deployment_enabled` es `false`, `newest_first` no basta:

```bash
curl -s --request PUT "$API/projects/$P" -H "$H" \
  --data "ci_forward_deployment_enabled=true" | jq .ci_forward_deployment_enabled
```

`production` se queda en `unordered`: sus despliegues son manuales y rara vez hay dos en cola. Lo que importa allí es que no vayan a la vez, y eso lo hace el candado con cualquier modo.

---

## Paso 4: Dos despliegues a `production` a la vez

**Por qué**: hasta que no ves un job en `waiting_for_resource`, el candado es una línea de YAML más.

Necesitas dos pipelines de `main` con `deploy-production` creado **después** del paso 2: los anteriores no tienen candado, porque el grupo se asigna al crear el job. Tienes uno del paso 2; crea otro:

```bash
medir "con candados"
JOBS=($(curl -s -H "$H" "$API/projects/$P/jobs?scope=manual&per_page=20" \
  | jq -r '[.[] | select(.name == "deploy-production")] | sort_by(.id) | .[-2:] | .[].id'))
echo "${JOBS[@]}"
```

**Verifica**: dos IDs. `JOBS` es un array, no una cadena: en zsh, `for j in $JOBS` no separa los IDs. Lánzalos uno detrás de otro, sin esperar, y mira la cola en seguida:

```bash
for j in "${JOBS[@]}"; do curl -s --request POST "$API/projects/$P/jobs/$j/play" -H "$H" | jq -r '"\(.id) \(.status)"'; done
sleep 3
for j in "${JOBS[@]}"; do curl -s -H "$H" "$API/projects/$P/jobs/$j" | jq -r '"\(.id) \(.status)"'; done
curl -s -H "$H" "$API/projects/$P/resource_groups/production/upcoming_jobs" \
  | jq -r '.[] | "\(.id) \(.name) pipeline \(.pipeline.id) \(.status)"'
```

**Verifica**: al lanzarlos, los dos responden `waiting_for_resource`; tres segundos después, uno `running` y el otro todavía `waiting_for_resource`, que aparece en `upcoming_jobs`. Con un runner de dos huecos había sitio para los dos: el que espera, espera al candado, no al runner.

Cuando terminen:

```bash
for j in "${JOBS[@]}"; do
  until curl -s -H "$H" "$API/projects/$P/jobs/$j" | jq -e '.status | IN("success","failed")' > /dev/null; do sleep 5; done
  curl -s -H "$H" "$API/projects/$P/jobs/$j" | jq -r '"\(.id) \(.status) \(.started_at[11:19]) → \(.finished_at[11:19])"'
done
```

**Verifica**: los dos `success`, y el segundo empezó después de que terminara el primero.

---

## Paso 5: El programado

**Por qué**: `caducidades` ya está en el YAML, pero ningún pipeline cumple su regla hasta que exista un programado con `TAREA=caducidades`.

```bash
SID=$(curl -s --request POST "$API/projects/$P/pipeline_schedules" -H "$H" \
  --data-urlencode "description=Caducidades de secretos: falla 30 días antes de cada fecha de docs/secretos.md" \
  --data "ref=main" --data-urlencode "cron=0 7 * * 1-5" --data "cron_timezone=UTC" \
  --data "active=true" | jq -r .id)
[[ "$SID" =~ ^[0-9]+$ ]] || { echo "No se creó el programado"; return 1 2>/dev/null || exit 1; }
curl -s --request POST "$API/projects/$P/pipeline_schedules/$SID/variables" -H "$H" \
  --data "key=TAREA" --data "value=caducidades" | jq -c '{key, value}'
echo "export SID=$SID" >> ~/.bc-gitlab-s11

curl -s -H "$H" "$API/projects/$P/pipeline_schedules/$SID" \
  | jq '{description, cron, cron_timezone, active, next_run_at, owner: .owner.username}'
```

**Verifica**: `active: true`, `next_run_at` el próximo día laborable a las `07:0x` UTC, y `owner` tu usuario. Es con tus permisos con lo que se ejecutará. La variable `TAREA` es una variable de pipeline: se acepta porque eres Maintainer o más en `app` (Semana 10, `ci_pipeline_variables_minimum_override_role`).

---

## Paso 6: Ejecutarlo ahora

**Por qué**: no vas a esperar a mañana para saber si el programado despliega algo que no debe.

```bash
curl -s --request POST "$API/projects/$P/pipeline_schedules/$SID/play" -H "$H" -o /dev/null -w '%{http_code}\n'   # 201
sleep 15
PROG=$(curl -s -H "$H" "$API/projects/$P/pipelines?source=schedule&per_page=1" | jq -r '.[0].id')
esperar "$P" "$PROG"
curl -s -H "$H" "$API/projects/$P/pipelines/$PROG" | jq -r .name
curl -s -H "$H" "$API/projects/$P/pipelines/$PROG/jobs" | jq -c '[.[].name]'
curl -s -H "$H" "$API/projects/$P/pipelines/$PROG/bridges" | jq length
```

**Verifica**:

```
success
schedule · main
["caducidades"]
0
```

Un solo job, ningún disparo. Si ves `build`, `deploy-staging` o un `infra` en la lista, a ese job le falta `!reference [.fuera-de-programados, rules]` como primera regla. Y el log:

```bash
JOB=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PROG/jobs" | jq -r '.[0].id')
curl -s -H "$H" "$API/projects/$P/jobs/$JOB/trace" | grep -E 'Aviso|ok$|PRONTO'
```

---

## ✅ Resultado

- [ ] `resource_group` `staging` y `production` en los despliegues
- [ ] `staging` en `newest_first`, con la protección contra despliegues obsoletos activada
- [ ] Viste un `deploy-production` en `waiting_for_resource` y el orden en que terminaron los dos
- [ ] `.fuera-de-programados` como primera regla en los cinco jobs que despliegan, empaquetan o disparan
- [ ] El programado con `TAREA=caducidades`, a tu nombre, ejecutado con un solo job y en verde

```bash
./scripts/verificar-semana.sh 11
```

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `resource_groups` vacío tras el paso 2 | El pipeline de `main` aún no había creado los jobs | Espera a que exista; los crea la creación del pipeline |
| `404` al cambiar el modo de `staging` | El grupo todavía no existe | Paso 2 |
| En el paso 4, los dos `running` a la vez | Uno de los dos jobs se creó antes del paso 2, sin candado | `GET .../jobs/<id>` no lo dice: usa dos pipelines posteriores |
| `JOBS` trae menos de dos IDs | Ya lanzaste los `deploy-production` manuales | `medir` otra vez y repite |
| El programado tiene `build` o `deploy-staging` | Falta `!reference` en ese job, o no es su primera regla | Paso 2 |
| El programado no tiene ningún job: `400` al hacer `play`, o ningún pipeline | La regla de `caducidades` no coincide: falta la variable `TAREA` | Paso 5 |
| `caducidades` en rojo | Una fecha de `docs/secretos.md` está a menos de 30 días | Es la alarma funcionando: rota el secreto o corrige la fecha |

---

## 🔗 Navegación

[← Anterior: El disparo a `infra`](03-disparo-a-infra.md) · [Volver a la Semana 11](../README.md)

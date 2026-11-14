# Práctica 01 — De stages a DAG

> Mides el pipeline de `main` tal como está, lo conviertes en un DAG con `needs` y lo vuelves a medir: primero con el runner de la Semana 09, que ejecuta un job cada vez, y después con dos huecos. La diferencia entre las tres medidas es la lección.

**Duración estimada**: 50 min
**Prerrequisitos**: Semana 10 completada · Teoría [01](../1-teoria/01-de-stages-a-dag.md) y [02](../1-teoria/02-needs-artefactos-y-opcionales.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 0 | El token de `revisor`, `fusionar` y `medir` | — |
| 1 | La medida del pipeline por stages | — |
| 2 | `needs` en `app`, fusionado | `test-no-espera-a-build`, `gobernanza-no-espera`, `package-espera-a-build-y-test` |
| 3 | La medida del DAG con `concurrent = 1` | — |
| 4 | El runner con dos huecos y la medida del DAG | — |

---

## Paso 0: Preparar el terreno

**Por qué**: esta semana vuelve a haber merge requests a `main` que necesitan la aprobación de `revisor`, y vas a lanzar varios pipelines de medida. Las dos cosas se repiten: las conviertes en funciones.

```bash
source ~/.bc-gitlab
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
export HA="PRIVATE-TOKEN: ${GITLAB_ADMIN_TOKEN:-$GITLAB_TOKEN}"
export REV=revisor-<tu-dominio>

export UID_REV=$(curl -s -H "$H" "$API/users?username=$REV" | jq -r '.[0].id // empty')
[[ "$UID_REV" =~ ^[0-9]+$ ]] || { echo "Falta $REV: NO sigas"; return 1 2>/dev/null || exit 1; }
T_REV=$(curl -s --request POST "$API/users/$UID_REV/personal_access_tokens" -H "$HA" \
  --data-urlencode "name=flujo-s11" --data-urlencode "scopes[]=api" \
  --data-urlencode "expires_at=$(date -d '+7 days' +%F)" | jq -r '.token')
[ -n "$T_REV" ] && [ "$T_REV" != null ] || { echo "No se creó el token: revisa GITLAB_ADMIN_TOKEN y NO sigas"; return 1 2>/dev/null || exit 1; }
export HR="PRIVATE-TOKEN: $T_REV"
grep -qs UID_REV ~/.bc-gitlab-s11 || echo "export REV=$REV UID_REV=$UID_REV" >> ~/.bc-gitlab-s11

esperar() {   # espera a que un pipeline termine y escribe su estado
  until curl -s -H "$H" "$API/projects/$1/pipelines/$2" \
          | jq -e '.status | IN("success","failed","canceled","skipped")' > /dev/null; do sleep 10; done
  curl -s -H "$H" "$API/projects/$1/pipelines/$2" | jq -r .status
}

fusionar() {   # aprueba como revisor, relanza el pipeline y fusiona solo si gobernanza está en verde
  local MR=$1 PIPE SHA
  curl -s --request POST "$API/projects/$P/merge_requests/$MR/approve" -H "$HR" > /dev/null
  PIPE=$(curl -s --request POST "$API/projects/$P/merge_requests/$MR/pipelines" -H "$H" | jq -r .id)
  esperar "$P" "$PIPE" > /dev/null
  curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" \
    | jq -e '.[] | select(.name == "gobernanza") | .status == "success"' > /dev/null \
    || { echo "gobernanza no está en verde en el pipeline $PIPE: lee su log"; return 1; }
  SHA=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .sha)
  curl -s --request PUT "$API/projects/$P/merge_requests/$MR/merge" -H "$H" \
    --data-urlencode "sha=$SHA" --data-urlencode "squash=true" | jq '{state, squash_commit_sha}'
}

medir() {   # lanza un pipeline de main, espera, y anota su duración y la línea de tiempo de sus jobs
  local ETIQUETA=$1 PIPE
  PIPE=$(curl -s --request POST "$API/projects/$P/pipeline" -H "$H" --data "ref=main" | jq -r .id)
  [[ "$PIPE" =~ ^[0-9]+$ ]] || { echo "No se creó el pipeline"; return 1; }
  echo "$ETIQUETA: pipeline $PIPE $(esperar "$P" "$PIPE")" | tee -a ~/medidas-s11.txt
  curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE" \
    | jq -r '"  duration=\(.duration)s queued=\(.queued_duration // 0 | floor)s"' | tee -a ~/medidas-s11.txt
  curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs?per_page=100" \
    | jq -r '[.[] | select(.started_at)] | sort_by(.started_at) | .[]
             | "  \(.name)\t\(.started_at[11:19]) → \(.finished_at[11:19])\t\(.duration | floor)s"' \
    | tee -a ~/medidas-s11.txt
}
```

`~/medidas-s11.txt` guarda las tres medidas para el proyecto. Fuera del repositorio, como `~/.bc-gitlab-s11`, que solo guarda identificadores.

**Verifica**:

```bash
curl -s -H "$HR" "$API/user" | jq -r .username                                # revisor-<tu-dominio>
curl -s -H "$H" "$API/projects/$P/merge_requests?state=opened" | jq length     # 0
type fusionar medir | grep -c function                                       # 2
```

---

## Paso 1: El pipeline por stages, medido

**Por qué**: sin la medida de antes, cualquier mejora es una opinión.

```bash
medir "stages, concurrent=1"
```

**Verifica**: una línea de tiempo como esta (tus segundos serán otros):

```
stages, concurrent=1: pipeline 412 success
  duration=163s queued=2s
  build           10:02:11 → 10:02:52   41s
  test            10:02:55 → 10:04:01   66s
  package         10:04:04 → 10:04:24   20s
  deploy-staging  10:04:27 → 10:04:53   26s
```

Cada job empieza cuando termina el anterior. Calcula ya el camino crítico que tendría un DAG (teoría 01, apartado 2.5): `max(build, test) + package + deploy-staging`. Es la duración a la que aspiras.

Y el pipeline lanza `deploy-staging` otra vez: el despliegue es simulado e idempotente, no pasa nada. `deploy-production` queda en `manual` y no cuenta.

---

## Paso 2: `needs` en `app`

**Por qué**: `test` y `gobernanza` no usan nada de `build`. `package` y los despliegues sí dependen de lo anterior, pero solo de un job cada uno.

```bash
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Pipeline en DAG: cada job espera solo a lo que necesita" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=test y gobernanza sin esperar a build; package tras build y test; despliegues encadenados. Medida antes y después en ~/medidas-s11.txt. Ver Semana 11." \
  | jq -r .iid)
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
git switch -c "$IID-pipeline-en-dag"
```

En `.gitlab-ci.yml`, añade una línea `needs` a cada job. Solo `needs`; todo lo demás se queda igual:

```yaml
test:
  stage: test
  extends: .npm
  needs: []                      # no usa nada de build
  # … script, coverage y artifacts sin cambios

package:
  stage: package
  needs: [build, test]           # solo se empaqueta lo que compila y pasa los tests
  # … rules, script y artifacts sin cambios

gobernanza:
  stage: test
  needs: []                      # dice si se puede fusionar: cuanto antes, mejor
  # … sin cambios

deploy-staging:
  extends: .deploy
  needs: [package]
  # … sin cambios

deploy-production:
  extends: .deploy
  needs: [deploy-staging]        # nunca a production lo que no pasó por staging
  # … sin cambios
```

`build` no lleva `needs`: está en el primer stage y no espera a nadie.

Valida y comprueba que el grafo cierra en `main`:

```bash
jq -n --rawfile c .gitlab-ci.yml '{content: $c, dry_run: true, ref: "main", include_jobs: true}' \
  | curl -s --request POST "$API/projects/$P/ci/lint" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -c '{valid, errors, jobs: [.jobs[]?.name]}'
# {"valid":true,"errors":[],"jobs":["build","test","package","deploy-staging","deploy-production"]}
```

Rompe el grafo a propósito, sin guardarlo: cambia `needs: [build, test]` por `needs: [build, lint]` y repite el `lint`. **Verifica**: `"errors":["package job: undefined need: lint"]`. Deshaz el cambio.

```bash
git add .gitlab-ci.yml
git commit -S -m "ci: pipeline en DAG con needs"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="ci: pipeline en DAG con needs"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
sleep 10
PIPE=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/pipelines" | jq -r '.[0].id')
esperar "$P" "$PIPE"
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" \
  | jq -r 'sort_by(.started_at) | .[] | "\(.name)\t\(.started_at[11:19])"'
```

**Verifica**: en la merge request, `build`, `test` y `gobernanza` quedan pendientes a la vez desde el principio. Con un solo hueco de runner van de uno en uno, pero ya no en el orden de los stages: `gobernanza` puede ser el primero. Fusiona:

```bash
fusionar "$MR"
git switch main && git pull --ff-only
```

**Verifica**: `state: merged`. En la UI, el pipeline de `main` con **Group jobs by → Job dependencies** dibuja las flechas de `needs`.

---

## Paso 3: El DAG con un solo hueco

**Por qué**: la teoría 01 dice que el DAG no acelera nada con `concurrent = 1`. Compruébalo antes de creerlo.

```bash
medir "dag, concurrent=1"
```

**Verifica**: `test` ya no espera a `build`, pero `build` y `test` siguen sin solaparse: uno empieza cuando el otro deja el hueco libre. La `duration` es parecida a la del paso 1, con unos segundos de diferencia que son ruido.

---

## Paso 4: Dos huecos

**Por qué**: con un segundo hueco, `build` y `test` corren a la vez y el camino crítico manda.

> [!WARNING]
> Cada hueco más es un contenedor de Node a la vez en tu máquina. Con 16 GB, dos es prudente. La Semana 15 dimensiona la flota; hoy subes de 1 a 2 y no más.

```bash
cd /ruta/a/bc-gitlab
docker compose exec gitlab-runner grep '^concurrent' /etc/gitlab-runner/config.toml   # concurrent = 1
docker compose exec gitlab-runner sed -i 's/^concurrent = 1$/concurrent = 2/' /etc/gitlab-runner/config.toml
sleep 5
docker compose logs --since 1m gitlab-runner | grep -i 'configuration loaded' | tail -1
```

El runner relee `config.toml` solo, sin reiniciar.

```bash
medir "dag, concurrent=2"
```

**Verifica**: `build` y `test` empiezan con segundos de diferencia y se solapan. La `duration` se acerca al camino crítico que calculaste en el paso 1.

Compara las tres:

```bash
grep -E '^(stages|dag)|duration' ~/medidas-s11.txt
```

Lo que tienes que poder explicar con tus números: por qué el paso 3 no mejoró y el 4 sí, y cuál es ahora el job que, si fuera más rápido, acortaría el pipeline.

---

## ✅ Resultado

- [ ] Tres medidas en `~/medidas-s11.txt`: stages, DAG con un hueco, DAG con dos
- [ ] `test` y `gobernanza` con `needs: []`; `package` con `needs: [build, test]`; los despliegues encadenados
- [ ] Viste el error de `ci/lint` con un `needs` hacia un job inexistente
- [ ] El runner con `concurrent = 2`
- [ ] Sabes cuál es el camino crítico de `app` con tus duraciones

```bash
./scripts/verificar-semana.sh 11      # las tres primeras comprobaciones, en verde
```

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `medir` dice `No se creó el pipeline` | `workflow` rechazó el pipeline, o tu token no tiene permiso | `POST .../pipeline` devuelve el motivo: lánzalo sin `jq` |
| La merge request no tiene pipeline: *does not exist in the pipeline* | Un `needs` hacia un job que no entra en las merge requests | En la merge request entran `build`, `test` y `gobernanza`, según `changes`: ningún job de la merge request puede necesitar `package` |
| `build` y `test` siguen sin solaparse en el paso 4 | El runner no ha releído la configuración | `docker compose restart gitlab-runner` |
| `sed` no cambia nada | Tu `config.toml` ya tenía otro valor | Edítalo con `docker compose exec gitlab-runner vi /etc/gitlab-runner/config.toml` |
| `deploy-staging` falla en `medir` | `DEPLOY_TOKEN` no llega a un pipeline de origen `api` | Llega: `main` está protegida. Lee el log; casi siempre es la variable borrada |

---

## 🔗 Navegación

[Volver a la Semana 11](../README.md) · [Siguiente: Un pipeline hijo para la documentación →](02-un-pipeline-hijo-para-la-documentacion.md)

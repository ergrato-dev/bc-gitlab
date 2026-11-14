# Práctica 01 — Las reglas de `app`

> Pones nombre a cada pipeline, haces que un commit nuevo cancele el trabajo obsoleto, sacas `build` y `test` de las merge requests que no tocan código y dejas `package` solo donde se publica. Lo compruebas con una merge request de documentación que no gasta un minuto de runner en compilar.

**Duración estimada**: 50 min
**Prerrequisitos**: Semana 09 completada · Teoría [01](../1-teoria/01-rules-cuando-entra-un-job.md) y [02](../1-teoria/02-workflow-cuando-nace-un-pipeline.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 0 | El token de `revisor` y la función `fusionar` | — |
| 1 | Lo que entra hoy en cada pipeline, medido | — |
| 2 | `workflow` con nombre y cancelación automática | `workflow-con-nombre`, `auto-cancel-interrumpible` |
| 3 | `rules` en `.npm` y en `package`, fusionadas | `build-y-test-con-changes` |
| 4 | Una merge request de documentación, sin build | — |

---

## Paso 0: Preparar el terreno, el token del revisor y `fusionar`

**Por qué**: esta semana hay cuatro merge requests a `main` que necesitan la aprobación de `revisor`. El ciclo de fusión de la Semana 09 (aprobar, relanzar el pipeline, fusionar solo si `gobernanza` está en verde) se repite en todas: lo conviertes en una función.

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
  --data-urlencode "name=flujo-s10" --data-urlencode "scopes[]=api" \
  --data-urlencode "expires_at=$(date -d '+7 days' +%F)" | jq -r '.token')
[ -n "$T_REV" ] && [ "$T_REV" != null ] || { echo "No se creó el token: revisa GITLAB_ADMIN_TOKEN y NO sigas"; return 1 2>/dev/null || exit 1; }
export HR="PRIVATE-TOKEN: $T_REV"
grep -qs UID_REV ~/.bc-gitlab-s10 || echo "export REV=$REV UID_REV=$UID_REV" >> ~/.bc-gitlab-s10

fusionar() {   # aprueba como revisor, relanza el pipeline y fusiona solo si gobernanza está en verde
  local MR=$1 PIPE SHA
  curl -s --request POST "$API/projects/$P/merge_requests/$MR/approve" -H "$HR" > /dev/null
  PIPE=$(curl -s --request POST "$API/projects/$P/merge_requests/$MR/pipelines" -H "$H" | jq -r .id)
  until curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE" \
          | jq -e '.status | IN("success","failed","canceled")' > /dev/null; do sleep 10; done
  curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" \
    | jq -e '.[] | select(.name == "gobernanza") | .status == "success"' > /dev/null \
    || { echo "gobernanza no está en verde en el pipeline $PIPE: lee su log"; return 1; }
  SHA=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .sha)
  curl -s --request PUT "$API/projects/$P/merge_requests/$MR/merge" -H "$H" \
    --data-urlencode "sha=$SHA" --data-urlencode "squash=true" | jq '{state, squash_commit_sha}'
}
```

Como en las Semanas 08 y 09: el token no se guarda en ningún archivo. Si cierras la terminal, repites este paso entero, función incluida. `~/.bc-gitlab-s10` solo guarda identificadores.

**Verifica**:

```bash
curl -s -H "$HR" "$API/user" | jq -r .username                                # revisor-<tu-dominio>
curl -s -H "$H" "$API/projects/$P/merge_requests?state=opened" | jq length     # 0
type fusionar | head -1                                                       # fusionar is a shell function
```

---

## Paso 1: Lo que entra hoy

**Por qué**: antes de cambiar las reglas, mide qué hacen. Así sabrás qué ha cambiado y qué no.

Los jobs de la última merge request fusionada (la del proyecto de la Semana 09, que solo cambiaba documentación) y su duración:

```bash
MRU=$(curl -s -H "$H" "$API/projects/$P/merge_requests?state=merged&per_page=1" | jq -r '.[0].iid')
PIPE=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MRU/pipelines" | jq -r '.[0].id')
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | "\(.name) \(.status) \(.duration // 0 | floor)s"'
```

**Verifica**: `build`, `test`, `package` y `gobernanza`. Anota la suma de las duraciones de los tres primeros: es lo que cuesta hoy **cualquier** merge request, aunque solo cambie una coma de un `.md`.

Y lo que entraría en un push a `main`, sin crear nada:

```bash
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
jq -n --rawfile c .gitlab-ci.yml '{content: $c, dry_run: true, ref: "main", include_jobs: true}' \
  | curl -s --request POST "$API/projects/$P/ci/lint" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -c '[.jobs[].name]'
# ["build","test","package"]
```

---

## Paso 2: Nombre y cancelación automática

**Por qué**: con nombre, `GET .../pipelines` dice qué es cada pipeline sin abrirlo. Con `auto_cancel`, tres pushes seguidos a una merge request no dejan tres pipelines en cola.

```bash
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Reglas del pipeline: solo lo que hace falta en cada pipeline" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=Nombre y auto_cancel en workflow; build y test solo si cambia el código; package solo donde se publica. Ver Semana 10." \
  | jq -r .iid)
git switch -c "$IID-reglas-del-pipeline"
```

Abre `.gitlab-ci.yml` y deja el bloque `workflow` así (solo añades `name` y `auto_cancel`; las cuatro reglas no cambian):

```yaml
workflow:
  name: "$CI_PIPELINE_SOURCE · $CI_COMMIT_REF_NAME"
  auto_cancel:
    on_new_commit: interruptible
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS
      when: never
    - if: $CI_COMMIT_BRANCH
    - if: $CI_COMMIT_TAG
```

`default` ya tiene `interruptible: true` desde la Semana 09: con `interruptible`, un commit nuevo cancela cualquier job de la merge request, esté donde esté.

---

## Paso 3: `changes` en `.npm`, y `package` donde se publica

**Por qué**: `build` y `test` heredan de `.npm`. Si la regla vive allí, se escribe una vez. `package` genera un `.tgz` que solo tiene sentido en `main`, `release/*` y los tags.

Añade `rules` al principio de `.npm`:

```yaml
.npm:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        paths:
          - src/**/*
          - package.json
          - package-lock.json
          - tsconfig.json
          - .gitlab-ci.yml
    - if: $CI_PIPELINE_SOURCE != "merge_request_event"
  cache:
    # … sin cambios
```

Y `rules` en `package`, encima de `script`:

```yaml
package:
  stage: package
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_BRANCH =~ /^release\//
    - if: $CI_COMMIT_TAG
  script:
    - npm pack
```

`gobernanza` ya tenía su regla. Si tus tests no viven en `src/`, añade su carpeta a `paths`: un test que cambia también tiene que ejecutarse.

Valida y pregunta qué entraría en `main`:

```bash
jq -n --rawfile c .gitlab-ci.yml '{content: $c, dry_run: true, ref: "main", include_jobs: true}' \
  | curl -s --request POST "$API/projects/$P/ci/lint" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -c '{valid, errors, jobs: [.jobs[]?.name]}'
# {"valid":true,"errors":[],"jobs":["build","test","package"]}
```

Commit, push y merge request:

```bash
git add .gitlab-ci.yml
git commit -S -m "ci: nombre, auto_cancel y reglas por job"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="ci: nombre, auto_cancel y reglas por job"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
sleep 10
PIPE=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/pipelines" | jq -r '.[0].id')
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE" | jq -r '"\(.name) \(.source)"'
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -c '[.[].name] | sort'
```

**Verifica**: el nombre es `merge_request_event · <IID>-reglas-del-pipeline`, y los jobs son `["build","gobernanza","test"]`: la merge request toca `.gitlab-ci.yml`, así que `build` y `test` entran; `package` ya no.

Fusiona:

```bash
fusionar "$MR"
git switch main && git pull --ff-only
sleep 10
curl -s -H "$H" "$API/projects/$P/pipelines?ref=main&per_page=1" | jq -r '.[0] | "\(.id) \(.name)"'
```

**Verifica**: `state: merged` y un pipeline `push · main`. Cuando termine, con `build`, `test` y `package` en verde.

---

## Paso 4: Una merge request de documentación

**Por qué**: es la prueba de que las reglas valen algo. Y de paso dejas escrito para los demás qué hace el pipeline desde hoy.

```bash
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=CONTRIBUTING: qué ejecuta el pipeline según lo que cambias" \
  --data-urlencode "labels=tipo::mantenimiento" | jq -r .iid)
git switch -c "$IID-contributing-reglas"
cat >> CONTRIBUTING.md <<'EOF'

### Qué se ejecuta en cada merge request

- Si cambias `src/`, `package.json`, `package-lock.json`, `tsconfig.json` o `.gitlab-ci.yml`: `build`, `test` y `gobernanza`.
- Si solo cambias documentación u otros archivos: solo `gobernanza`.
- `package` solo se ejecuta en `main`, en `release/*` y en los tags.
EOF
git add CONTRIBUTING.md
git commit -S -m "docs: qué ejecuta el pipeline en cada merge request"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="docs: qué ejecuta el pipeline en cada merge request"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
```

Y antes de que termine, un segundo commit, para ver `auto_cancel`:

```bash
sed -i 's/u otros archivos: solo/u otros archivos, solo/' CONTRIBUTING.md
git commit -S -am "docs: puntuación"
git push
sleep 15
curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/pipelines" | jq -r '.[] | "\(.id) \(.status)"'
```

**Verifica**: dos pipelines. El más reciente, en marcha o en `success`; el anterior, en `canceled`. Si el primero ya había terminado cuando empujaste el segundo commit, no había nada que cancelar: no es un fallo.

```bash
PIPE=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/pipelines" | jq -r '.[0].id')
until curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE" | jq -e '.status | IN("success","failed","canceled")' > /dev/null; do sleep 10; done
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | "\(.name) \(.status) \(.duration // 0 | floor)s"'
```

**Verifica**: un solo job, `gobernanza`. Compara con el paso 1: la merge request se ahorra el tiempo de `build`, `test` y `package` entero.

```bash
fusionar "$MR"
git switch main && git pull --ff-only
```

---

## ✅ Resultado

- [ ] Token de `revisor` creado sin guardarlo, y la función `fusionar` en tu terminal
- [ ] El coste de una merge request antes de las reglas, anotado
- [ ] `workflow` con `name` y `auto_cancel:on_new_commit: interruptible`
- [ ] `build` y `test` solo en merge requests que tocan código; `package` solo en `main`, `release/*` y tags
- [ ] Una merge request de documentación con un solo job, `gobernanza`, y su pipeline anterior cancelado

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| La merge request no tiene pipeline | `workflow:rules` sin la primera regla, o un error de YAML | `POST .../ci/lint` con el archivo de la rama |
| `build` y `test` no entran en la merge request del paso 3 | `.gitlab-ci.yml` no está en `paths` | Añádelo: un cambio en el pipeline tiene que probar el pipeline |
| El pipeline de `main` no tiene `package` | La regla compara con `"main"` y la rama se llama de otra forma, o falta `$` | `$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH` |
| `fusionar` dice que `gobernanza` no está en verde | Falta la aprobación del dueño de `.gitlab-ci.yml`, o el issue | Lee el log de `gobernanza` en ese pipeline |
| `detailed_merge_status` dice `ci_must_pass` | El pipeline que GitLab mira es el anterior, cancelado | `fusionar` relanza uno nuevo: repítela |
| `fusionar: command not found` | Terminal nueva | Repite el paso 0 entero |

---

## 🔗 Navegación

[Volver a la Semana 10](../README.md) · [Siguiente: Variables y precedencia →](02-variables-y-precedencia.md)

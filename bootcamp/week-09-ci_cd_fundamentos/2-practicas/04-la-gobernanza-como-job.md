# Práctica 04 — La gobernanza como job

> `gobernanza.sh` deja de depender de que te acuerdes: un token de proyecto de solo lectura, una variable que nadie puede volver a leer, un job que se ejecuta en cada merge request, y *Pipelines must succeed* activado por fin. Lo compruebas con la merge request en rojo que dejaste abierta.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 03 completada, con su merge request en rojo abierta · Teoría [04](../1-teoria/04-la-vida-de-un-job.md) y [07](../1-teoria/07-la-gobernanza-en-el-pipeline.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | El token de proyecto y la variable | `token-de-gobernanza`, `variable-de-gobernanza` |
| 2 | El job `gobernanza` y `.gitlab-ci.yml` en `CODEOWNERS` | `gobernanza-ejecutable`, `pipeline-con-dueno` |
| 3 | El primer veredicto, antes de aprobar | — |
| 4 | Aprobada, auditada por el job y fusionada | `gobernanza-en-verde-en-una-mr` |
| 5 | *Pipelines must succeed* | `pipelines-must-succeed` |
| 6 | La regresión, cerrada sin fusionar | — |

---

## Paso 0: Preparar el terreno

```bash
source ~/.bc-gitlab && source ~/.bc-gitlab-s09
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
[ -n "${HR:-}" ] || echo "Falta \$HR: repite el paso 0 de la práctica 01"
```

---

## Paso 1: El token y la variable, sin que el token se vea

**Por qué**: el token pasa de la respuesta de una API a la petición de otra por una tubería. No se imprime, no se guarda en una variable de tu shell y no aparece en los argumentos de ningún proceso: `--data-urlencode "value@-"` lo lee de la entrada estándar.

```bash
curl -s --request POST "$API/projects/$P/access_tokens" -H "$H" \
  --data-urlencode "name=gobernanza-ci" \
  --data "scopes[]=read_api" \
  --data "access_level=20" \
  --data "expires_at=$(date -d '+180 days' +%F)" \
  | jq -j '.token // empty' \
  | curl -s --request POST "$API/projects/$P/variables" -H "$H" \
      --data "key=GOBERNANZA_TOKEN" \
      --data-urlencode "value@-" \
      --data "masked_and_hidden=true" --data "masked=true" --data "protected=false" \
  | jq '{key, masked, hidden, protected, value}'
```

`jq -j` escribe el token sin salto de línea al final. Con `-r`, el salto entraría en el valor y la variable no se podría enmascarar.

**Verifica**:

```json
{ "key": "GOBERNANZA_TOKEN", "masked": true, "hidden": true, "protected": false, "value": null }
```

```bash
curl -s -H "$H" "$API/projects/$P/access_tokens" \
  | jq -r '.[] | select(.active) | "\(.name) \(.access_level) \(.scopes | join(",")) \(.expires_at)"'
# gobernanza-ci 20 read_api 2027-...
```

Si la variable sale con `400` y `value is invalid`, el token no llegó (el primer `curl` falló): revoca el token que se haya creado (`DELETE .../access_tokens/<id>`) y repite.

---

## Paso 2: El job y su dueño

**Por qué**: desde hoy `.gitlab-ci.yml` decide qué se comprueba antes de fusionar. Cambiarlo es cambiar las reglas, y en `app` las reglas las aprueba `revisor`.

```bash
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=La auditoría de gobernanza, en cada merge request" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=scripts/gobernanza.sh pasa a ser un job. Detecta, no bloquea (ADR-005). Ver Semana 09." \
  | jq -r .iid)

git switch main && git pull --ff-only
git switch -c "$IID-gobernanza-como-job"

cat >> .gitlab-ci.yml <<'EOF'

gobernanza:
  stage: test
  image: alpine:3.24.2
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  allow_failure: true
  before_script:
    - apk add --no-cache bash curl jq
  script:
    - scripts/gobernanza.sh
EOF

printf '/.gitlab-ci.yml @%s\n' "$REV" >> CODEOWNERS
tail -4 CODEOWNERS
git ls-files -s scripts/gobernanza.sh | cut -c1-6        # 100755
```

Si el modo no es `100755`: `git update-index --chmod=+x scripts/gobernanza.sh`. El job lo ejecuta directamente, no con `bash`.

Valida antes del commit, como en la práctica 02:

```bash
jq -n --rawfile c .gitlab-ci.yml '{content: $c}' \
  | curl -s --request POST "$API/projects/$P/ci/lint" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq '{valid, errors}'

git add .gitlab-ci.yml CODEOWNERS scripts/gobernanza.sh
git commit -S -m "ci: ejecutar la auditoría de gobernanza en cada merge request"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="ci: ejecutar la auditoría de gobernanza en cada merge request"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
echo "export MR_GOB=$MR" >> ~/.bc-gitlab-s09
```

---

## Paso 3: El primer veredicto, antes de aprobar

**Por qué**: el job se ejecuta en cuanto se abre la merge request, cuando nadie la ha aprobado todavía. Tiene que decirlo, y el pipeline tiene que seguir en verde.

```bash
PIPE=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/pipelines" | jq -r '.[0].id')
until curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE" | jq -e '.status | IN("success","failed","canceled")' > /dev/null; do sleep 10; done
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE" | jq -r .status
JOB=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | select(.name == "gobernanza") | .id')
curl -s -H "$H" "$API/projects/$P/jobs/$JOB" | jq -r '"\(.status) allow_failure=\(.allow_failure)"'
curl -s -H "$H" "$API/projects/$P/jobs/$JOB/trace" | sed 's/\x1b\[[0-9;]*m//g' | grep -E '✅|❌|➖|problema'
```

**Verifica**:

```
success
failed allow_failure=true
✅ cierra un issue
❌ nadie distinto de @<tú> la ha aprobado
❌ .gitlab-ci.yml: falta la aprobación de @<tú> @revisor-<dominio>
❌ CODEOWNERS: falta la aprobación de @revisor-<dominio>
3 problema(s) en !N
```

El pipeline está en `success` con un job fallido: es lo que hace `allow_failure`. Y el job llegó a la API de tu instancia con su propio token, que no aparece en el log.

Los dueños salen del `CODEOWNERS` de `main`, no del de la rama: la línea `/.gitlab-ci.yml` que acabas de añadir aún no cuenta. Es el diseño de la Semana 07: una merge request no puede nombrarse dueña de lo que toca.

---

## Paso 4: Aprobar, auditar con el job y fusionar

**Por qué**: es el ciclo de la teoría 07, apartado 2.5, y el que usarás desde ahora en cada merge request.

```bash
curl -s --request POST "$API/projects/$P/merge_requests/$MR/approve" -H "$HR" | jq -r '.approved_by[].user.username'

PIPE=$(curl -s --request POST "$API/projects/$P/merge_requests/$MR/pipelines" -H "$H" | jq -r .id)
until curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE" \
        | jq -e '.status | IN("success","failed","canceled")' > /dev/null; do sleep 10; done
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" \
  | jq -e '.[] | select(.name == "gobernanza") | .status == "success"' > /dev/null && {
  SHA=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .sha)
  curl -s --request PUT "$API/projects/$P/merge_requests/$MR/merge" -H "$H" \
    --data-urlencode "sha=$SHA" --data-urlencode "squash=true" | jq '{state, squash_commit_sha}'
} || echo "gobernanza no está en verde: lee su log antes de fusionar"
```

**Verifica**: `state: merged`. Y el log del segundo `gobernanza`:

```bash
JOB=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | select(.name == "gobernanza") | .id')
curl -s -H "$H" "$API/projects/$P/jobs/$JOB/trace" | sed 's/\x1b\[[0-9;]*m//g' | grep -E '✅|❌|problema'
# ✅ cierra un issue
# ✅ aprobada por: revisor-<dominio>
# ✅ .gitlab-ci.yml: aprobado por su dueño
# ✅ CODEOWNERS: aprobado por su dueño
# 0 problema(s) en !N
```

```bash
git switch main && git pull --ff-only
```

---

## Paso 5: *Pipelines must succeed*

**Por qué**: la Semana 06 lo dejó preparado y sin activar, porque sin pipeline ninguna merge request se habría podido fusionar. Ahora hay pipeline en todas.

```bash
curl -s --request PUT "$API/projects/$P" -H "$H" \
  --data "only_allow_merge_if_pipeline_succeeds=true" \
  --data "allow_merge_on_skipped_pipeline=false" \
  | jq '{only_allow_merge_if_pipeline_succeeds, allow_merge_on_skipped_pipeline}'
```

Pruébalo con la merge request en rojo de la práctica 03. Primero quítale el borrador, que es otro motivo para no fusionar y taparía el que quieres ver:

```bash
curl -s --request PUT "$API/projects/$P/merge_requests/$MR_ROJA" -H "$H" \
  --data-urlencode "title=chore: regresión a propósito, no fusionar" > /dev/null
sleep 5
curl -s -H "$H" "$API/projects/$P/merge_requests/$MR_ROJA" | jq -r .detailed_merge_status
SHA=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR_ROJA" | jq -r .sha)
curl -s -o /dev/null -w '%{http_code}\n' --request PUT "$API/projects/$P/merge_requests/$MR_ROJA/merge" -H "$H" \
  --data-urlencode "sha=$SHA"
```

**Verifica**: `ci_must_pass` y `405`. Aunque el ajuste fallara, la fusión no llegaría a `main`: el hook de la Semana 07 la rechazaría por no llevar `Approved-by:`. Son dos capas, y esta es la que se ve en la merge request antes de intentarlo.

---

## Paso 6: Cerrar la regresión

```bash
curl -s --request PUT "$API/projects/$P/merge_requests/$MR_ROJA" -H "$H" \
  --data "state_event=close" | jq -r .state                                  # closed
git push origin --delete regresion-a-proposito
git branch -D regresion-a-proposito
```

---

## ✅ Resultado

- [ ] Token `gobernanza-ci`, Reporter, `read_api`, con caducidad, sin haberse visto nunca en la terminal
- [ ] `GOBERNANZA_TOKEN` enmascarada y oculta, no protegida
- [ ] Job `gobernanza` en `.gitlab-ci.yml` y `/.gitlab-ci.yml` con `revisor` como dueño
- [ ] Un `gobernanza` en `❌` antes de aprobar, con el pipeline en verde
- [ ] Un `gobernanza` en `0 problema(s)` tras aprobar, y la merge request fusionada
- [ ] *Pipelines must succeed* activado, comprobado con un `405`
- [ ] La merge request de la regresión cerrada y su rama borrada

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `gobernanza` falla con `GITLAB_TOKEN: unbound variable` | `GOBERNANZA_TOKEN` no llegó al job, y el script busca el siguiente | Paso 1; si la variable es protegida, no llega a ramas de merge request |
| `gobernanza` falla sin escribir nada, con `exit code 7` | No llega a la API: `CI_API_V4_URL` sigue apuntando a `localhost` | Paso 2 de la práctica 01 |
| `gobernanza` falla sin escribir nada, con `exit code 22` | La API respondió con error: el token caducó, se revocó o no es de este proyecto | `DELETE .../variables/GOBERNANZA_TOKEN` y repite el paso 1 |
| `gobernanza` falla con `Permission denied` | El script no tiene el bit de ejecución en Git | `git update-index --chmod=+x scripts/gobernanza.sh` |
| `gobernanza` sigue en `❌` tras aprobar | El pipeline que miras es el de antes de la aprobación | Paso 4: un pipeline **nuevo** de la merge request |
| `detailed_merge_status` dice `draft_status` | La merge request sigue siendo borrador | Quita el borrador como en el paso 5 |

---

## 🔗 Navegación

[← Anterior: Artefactos y caché, medidos](03-artefactos-y-cache-medidos.md) · [Volver a la Semana 09](../README.md)

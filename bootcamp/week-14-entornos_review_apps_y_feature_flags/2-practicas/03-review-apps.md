# Práctica 03 — Review apps

> Una clave más, la de las review apps, que el destino limita a `review-*`. `app` gana dos jobs: uno despliega cada merge request en su propio entorno y otro lo para. La merge request que los añade es la primera que tiene review app. Al fusionarla, su entorno se para solo y el destino lo borra.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 02 completada · Teoría [04](../1-teoria/04-review-apps.md) leída

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | La clave de las review apps, en el destino y en `app` | `review-con-clave-propia` |
| 2 | `package` también en merge requests, y `review` y `parar-review` en `ci/deploy.yml` | `review-app-dinamica` |
| 3 | La primera review app, viva | `review-desplegada` |
| 4 | Dos merge requests, dos copias | — |
| 5 | La fusión, que para la review app | `review-parada` |
| 6 | La limpieza de lo parado | — |

Si has cerrado la terminal: `source ~/.bc-gitlab`, `source ~/.bc-gitlab-s14`, las variables `H`, `API`, `P` y `HR`, y `esperar` y `fusionar`.

---

## Paso 1: La clave de las review apps

**Por qué**: las review apps salen de ramas de merge request, que no son protegidas. Su clave no puede ir protegida, así que su límite lo pone el destino: `review-*` y nada más (teoría 03, apartado 2.1). La pública se **añade** a `authorized_keys`, sin tocar las de `staging` y `production`.

```bash
ssh-keygen -q -t ed25519 -N '' -C "destino-review" -f ~/.ssh/destino-review
cd /ruta/a/bc-gitlab
echo "command=\"/usr/local/bin/desplegar review-*\",restrict $(cat ~/.ssh/destino-review.pub)" \
  | docker compose exec -T destino sh -c 'cat >> /home/deploy/.ssh/authorized_keys'
docker compose exec destino grep -c restrict /home/deploy/.ssh/authorized_keys
```

En `app`, la clave y la huella:

```bash
var() {   # $1 clave, $2 archivo, $3 protegida, $4 ámbito
  curl -s --request POST "$API/projects/$P/variables" -H "$H" \
    --data-urlencode "key=$1" --data-urlencode "value@$2" \
    --data-urlencode "variable_type=file" --data-urlencode "protected=$3" \
    --data-urlencode "environment_scope=$4" | jq -c '{key, environment_scope, protected, variable_type}'
}
var REVIEW_SSH_KEY ~/.ssh/destino-review false 'review/*'
var DESTINO_KNOWN_HOSTS ~/.ssh/destino-known-hosts false '*'
```

**Verifica**: `3` líneas con `restrict` en el destino, y dos variables en `app`, `REVIEW_SSH_KEY` con `"environment_scope":"review/*"` y `"protected":false`. Y la prueba que justifica que esté sin proteger:

```bash
docker run --rm --network bc-gitlab-network \
  -v ~/.ssh/destino-review:/k:ro -v ~/.ssh/destino-known-hosts:/kh:ro alpine:3.24.2 sh -c '
  apk add -q --no-cache openssh-client > /dev/null; cp /k /tmp/k && chmod 600 /tmp/k
  ssh -i /tmp/k -o UserKnownHostsFile=/kh -o BatchMode=yes deploy@destino parar staging; echo "parar staging: $?"'
# esta clave no para 'staging'
# parar staging: 3
```

Añade la fila de `REVIEW_SSH_KEY` a `docs/secretos.md` en la merge request del paso 2: sin proteger, por qué, y que se revoca en el destino.

---

## Paso 2: Los dos jobs

**Por qué**: hasta hoy `package` no corría en merge requests: nadie necesitaba el `.tgz` de una rama. La review app sí. `publicar-paquete` heredaba las reglas de `package` con `!reference`; ahora necesita las suyas, porque una rama de merge request no publica en el registro de paquetes.

```bash
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Una review app por merge request" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=review/\$CI_MERGE_REQUEST_IID en el destino, con on_stop y auto_stop_in. REVIEW_SSH_KEY limitada a review-* en el destino. Ver Semana 14." \
  | jq -r .iid)
git switch -c "$IID-review-apps"
```

En `.gitlab-ci.yml`, `package` gana una regla y `publicar-paquete` deja de copiar las de `package`:

```yaml
package:
  # …
  rules:
    - !reference [.fuera-de-programados, rules]
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_BRANCH =~ /^release\//
    - if: $CI_COMMIT_TAG

publicar-paquete:
  # …
  rules:
    - !reference [.fuera-de-programados, rules]
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_BRANCH =~ /^release\//
    - if: $CI_COMMIT_TAG
```

Y al final de `ci/deploy.yml`:

```yaml
# Review apps (Semana 14): una copia viva por merge request, en el destino.
.destino:
  image: ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/alpine:3.24.2
  interruptible: false
  variables:
    GIT_STRATEGY: none
  before_script:
    - apk add --no-cache openssh-client
    - chmod 600 "$REVIEW_SSH_KEY"

review:
  extends: .destino
  stage: deploy
  needs: [package]
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  environment:
    name: review/$CI_MERGE_REQUEST_IID
    url: http://localhost:8095/$CI_ENVIRONMENT_SLUG/salud
    on_stop: parar-review
    auto_stop_in: 3 days
  script:
    - cat *.tgz | ssh -i "$REVIEW_SSH_KEY" -o UserKnownHostsFile="$DESTINO_KNOWN_HOSTS" -o BatchMode=yes
        deploy@destino desplegar "$CI_ENVIRONMENT_SLUG" "$CI_COMMIT_SHA" "$CI_ENVIRONMENT_NAME"

parar-review:
  extends: .destino
  stage: deploy
  needs: [review]
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: manual
  allow_failure: true
  environment:
    name: review/$CI_MERGE_REQUEST_IID
    action: stop
  script:
    - ssh -i "$REVIEW_SSH_KEY" -o UserKnownHostsFile="$DESTINO_KNOWN_HOSTS" -o BatchMode=yes
        deploy@destino parar "$CI_ENVIRONMENT_SLUG"
```

| Línea | Por qué |
|---|---|
| `.destino` con `interruptible: false` | `default` tiene `interruptible: true` desde la Semana 09. Un commit nuevo no debe cortar un `parar` a medias |
| `GIT_STRATEGY: none` | `review` recibe el `.tgz` como artefacto de `package`; `parar-review` corre cuando la rama puede no existir |
| `cat *.tgz \|` | `< *.tgz` no expande el comodín en `sh` (teoría 04, apartado 2.1) |
| Sin `!reference [.fuera-de-programados]` | Un pipeline programado nunca es `merge_request_event` |

La línea larga de `script` sigue en la siguiente con más sangría: YAML la une en una sola.

```bash
jq -n --rawfile c .gitlab-ci.yml '{content: $c, dry_run: true, ref: "main"}' \
  | curl -s --request POST "$API/projects/$P/ci/lint" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -c '{valid, errors}'
git add .gitlab-ci.yml ci/deploy.yml docs/secretos.md
git commit -S -m "ci: una review app por merge request en el destino"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.remove_source_branch \
  -o merge_request.title="ci: una review app por merge request" \
  -o merge_request.description="Closes #$IID"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
echo "$MR"
```

**Verifica**: `{"valid":true,"errors":[]}` y el número de la merge request. `dry_run` con `ref` lee `ci/deploy.yml` de la rama, aunque aún no esté en `main` (Semana 12).

---

## Paso 3: La primera review app

**Por qué**: la merge request que añade las review apps ya corre en un pipeline de merge request, así que tiene la suya.

```bash
PIPE=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/pipelines" | jq -r '.[0].id')
esperar "$P" "$PIPE"
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -c '.[] | select(.name | test("review")) | {name, status}'
curl -s -H "$H" "$API/projects/$P/environments?search=review/" | jq -c '.[] | {name, slug, state, external_url, auto_stop_at}'
```

**Verifica**: `review` en `success`, `parar-review` en `manual`, y un entorno `review/<MR>` con un slug como `review-<MR>-a1b2c3`, la URL con ese slug y `auto_stop_at` dentro de tres días. Ahora pregúntale al destino:

```bash
URL=$(curl -s -H "$H" "$API/projects/$P/environments?search=review/$MR" | jq -r '.[0].external_url')
curl -s "$URL" | jq -c '{entorno, sha}'
curl -s localhost:8095/ | jq -c 'keys'
```

`"entorno":"review/<MR>"`, el SHA del último commit de la rama, y tres entornos vivos en el destino: `production`, `review-<MR>-…` y `staging`. En la merge request, el widget del pipeline tiene un botón *View app* con esa URL.

---

## Paso 4: Dos merge requests, dos copias

**Por qué**: es la razón de ser de las review apps. Una segunda rama, desde la primera, con un cambio visible en `/salud`.

```bash
git switch -c "$IID-review-prueba"
sed -i "s|estado: 'ok', version|estado: 'ok', revision: 'prueba', version|" src/http.ts
git commit -S -am "test: una segunda review app"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="Draft: prueba de review app" -o merge_request.description="Para cerrar sin fusionar."
MR2=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
PIPE2=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR2/pipelines" | jq -r '.[0].id')
esperar "$P" "$PIPE2"
curl -s localhost:8095/ | jq -c 'keys'
```

**Verifica**: cuatro entornos en el destino. `review-<MR2>-…/salud` responde con `"revision":"prueba"`; `review-<MR>-…/salud`, sin ella. Cada merge request ve lo suyo.

Ahora ciérrala sin fusionar, y comprueba que GitLab la para igual:

```bash
curl -s --request PUT "$API/projects/$P/merge_requests/$MR2" -H "$H" --data-urlencode "state_event=close" | jq -r .state
sleep 30
curl -s -H "$H" "$API/projects/$P/environments?search=review/$MR2" | jq -r '.[0].state'
git push origin --delete "$IID-review-prueba" && git switch "$IID-review-apps"
```

**Verifica**: `closed` y `stopped`, y el destino vuelve a tener tres entornos.

---

## Paso 5: Fusionar, y que se pare sola

**Por qué**: la merge request del paso 2 se fusiona con su rama borrada (`remove_source_branch`). GitLab lanza `parar-review` sin que nadie lo pulse.

```bash
fusionar "$P" "$MR"
git switch main && git pull --ff-only
sleep 30
curl -s -H "$H" "$API/projects/$P/environments?search=review/$MR" | jq -c '.[0] | {name, state}'
curl -s localhost:8095/ | jq -c 'keys'
```

**Verifica**: `state: merged`, el entorno en `stopped` y el destino con `production` y `staging` solamente. El pipeline de `main` ha desplegado además la versión nueva en `staging`, como cualquier fusión.

---

## Paso 6: La limpieza

**Por qué**: un entorno parado no gasta nada en el destino, pero llena la lista de GitLab. Se borran de golpe, primero en simulación.

```bash
ANTES=$(date -u -d '+1 minute' +%FT%TZ)
curl -s --request DELETE -H "$H" "$API/projects/$P/environments/review_apps?before=$ANTES" \
  | jq -c '{simulado: [.scheduled_entries[].name]}'
```

**Verifica**: los dos `review/…` parados en la lista y nada se ha borrado todavía: sin `dry_run=false`, solo simula. Déjalos: la comprobación `review-parada` los necesita. En tu plataforma de verdad, este borrado iría en el pipeline programado de cada mañana.

---

## ✅ Checklist

- [ ] `REVIEW_SSH_KEY` sin proteger, limitada a `review/*` en GitLab y a `review-*` en el destino
- [ ] `package` en merge requests, `publicar-paquete` solo en `main`, `release/*` y tags
- [ ] Una review app viva con su URL, y dos a la vez con respuestas distintas
- [ ] Una parada al cerrar sin fusionar y otra al fusionar, sin pulsar nada
- [ ] El borrado de las paradas, simulado

---

## 🧯 Problemas frecuentes

| Síntoma | Causa | Solución |
|---|---|---|
| `review` no aparece en el pipeline de la merge request | El pipeline es de rama, no de merge request | El `workflow` de la Semana 10 crea el de merge request si la rama tiene una abierta |
| `review` falla con `can't open app-*.tgz` | Pusiste `< *.tgz` | `cat *.tgz \|` |
| `review` falla: no hay `.tgz` | `package` no tiene la regla de merge request | Paso 2 |
| `REVIEW_SSH_KEY no ha llegado` o `Permission denied` | La variable está protegida, o el ámbito no es `review/*` | Sin proteger, con ese ámbito exacto |
| La merge request publica un paquete por SHA | `publicar-paquete` sigue con `!reference [package, rules]` | Sus propias reglas, sin merge request |
| El entorno no se para al fusionar | La rama no se borró | `remove_source_branch`, o *Stop* a mano; `auto_stop_in` la parará igual |
| `parar-review` falla al clonar | Falta `GIT_STRATEGY: none` | Está en `.destino` |

---

[← Anterior: Producción y rollback](02-produccion-y-rollback.md) · [Volver a la Semana 14](../README.md) · [Siguiente: El feature flag y Pages →](04-feature-flag-y-pages.md)

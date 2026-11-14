# Práctica 03 — Secretos por entorno

> Creas `DEPLOY_TOKEN` dos veces, una para `staging` y otra para `production`, sin ver ninguna. Escribes `scripts/deploy.sh`, que se niega a desplegar sin su secreto, y dos jobs: uno que despliega en `staging` en cada fusión y otro que espera a que alguien lo lance. Compruebas que una merge request no recibe nada, que `dev` no puede lanzar el despliegue y que `production` falla por una razón que arreglas en la práctica 04.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 02 completada · Teoría [04](../1-teoria/04-proteger-enmascarar-ocultar.md) y [05](../1-teoria/05-entornos-como-ambito.md) leídas

---

## Contexto

`deploy.sh` es un despliegue **simulado**: no hay ningún servidor detrás. Comprueba que recibe sus secretos, los de su entorno y solo los de su entorno, y lo dice sin enseñarlos. En la Semana 14, el mismo job desplegará de verdad sin cambiar cómo recibe los secretos.

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | `DEPLOY_TOKEN` en dos ámbitos | `deploy-token-por-entorno`, `secretos-enmascarados` |
| 2 | `scripts/deploy.sh` y los dos jobs, en una merge request | — |
| 3 | La merge request no ve los secretos; fusionada | `despliegue-a-produccion-manual` |
| 4 | `staging` desplegado; `dev` no puede lanzar `production` | `entornos-staging-y-production`, `desplegado-en-staging`, `ultimo-pipeline-de-main-en-verde` |
| 5 | `production`, lanzado y fallido por la razón correcta | — |

---

## Paso 0: Preparar el terreno

```bash
source ~/.bc-gitlab && source ~/.bc-gitlab-s10
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
[ -n "${HR:-}" ] && type fusionar > /dev/null || echo "Falta \$HR o fusionar: repite el paso 0 de la práctica 01"
[ -n "${HD:-}" ] || echo "Falta \$HD: repite el bloque del token de dev del paso 4 de la práctica 02"
```

---

## Paso 1: `DEPLOY_TOKEN`, dos veces, sin verlo

**Por qué**: misma clave, dos ámbitos, protegida y enmascarada. El valor lo genera `openssl` y viaja por una tubería: nunca está en tu pantalla, en tu historial ni en los argumentos de un proceso.

```bash
for e in staging production; do
  openssl rand -hex 32 | tr -d '\n' \
    | curl -s --request POST "$API/projects/$P/variables" -H "$H" \
        --data "key=DEPLOY_TOKEN" --data "environment_scope=$e" \
        --data-urlencode "value@-" --data "protected=true" \
        --data "masked_and_hidden=true" --data "masked=true" \
    | jq -c '{key, environment_scope, protected, masked, hidden, value}'
done
```

**Verifica**:

```
{"key":"DEPLOY_TOKEN","environment_scope":"staging","protected":true,"masked":true,"hidden":true,"value":null}
{"key":"DEPLOY_TOKEN","environment_scope":"production","protected":true,"masked":true,"hidden":true,"value":null}
```

Oculta, como `GOBERNANZA_TOKEN`: ni tú ni otro Maintainer podréis volver a leerla. Si hace falta cambiarla, se sustituye. La longitud (64) la comprobarás en el log de `deploy-staging`.

> [!NOTE]
> En la Semana 14, `DEPLOY_TOKEN` será la credencial que te dé el sistema donde despliegues. Lo que no cambia es cómo llega al job.

---

## Paso 2: `deploy.sh` y los dos jobs

**Por qué**: el script no sabe a qué entorno despliega: se lo dicen `CI_ENVIRONMENT_NAME` y `DEPLOY_TOKEN`. Y se niega a seguir sin secreto, para que una variable protegida que no llega (práctica 02, paso 3b) sea un error y no un despliegue vacío.

```bash
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Despliegue a staging y production con un secreto por entorno" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=deploy-staging automático en main, deploy-production manual. DEPLOY_TOKEN protegida, un valor por entorno. Despliegue simulado hasta la Semana 14." \
  | jq -r .iid)
git switch main && git pull --ff-only
git switch -c "$IID-despliegue-por-entorno"

cat > scripts/deploy.sh <<'EOF'
#!/bin/sh
# Despliegue simulado de app. El destino real llega en la Semana 14: hoy el job
# solo demuestra que recibe sus secretos, y solo los de su entorno.
set -eu

: "${CI_ENVIRONMENT_NAME:?deploy.sh solo se ejecuta en un job con environment}"
: "${DEPLOY_TOKEN:?DEPLOY_TOKEN no ha llegado: ¿ref protegida y environment dentro de su ámbito?}"

echo "Entorno: $CI_ENVIRONMENT_NAME ($CI_ENVIRONMENT_URL)"
echo "Commit:  $CI_COMMIT_SHORT_SHA"
echo "Token:   ${#DEPLOY_TOKEN} caracteres"

if [ "$CI_ENVIRONMENT_NAME" = production ]; then
  : "${DEPLOY_SSH_KEY:?DEPLOY_SSH_KEY no ha llegado}"
  echo "Clave:   $(ssh-keygen -lf "$DEPLOY_SSH_KEY" | cut -d' ' -f1-2)"
fi

echo "Despliegue simulado: correcto"
EOF
chmod +x scripts/deploy.sh
```

`production` necesita además una clave SSH, `DEPLOY_SSH_KEY`, que todavía no existe. Es a propósito: el paso 5 lo comprueba.

En `.gitlab-ci.yml`, añade `deploy` a los stages:

```yaml
stages: [build, test, package, deploy]
```

Y al final del archivo:

```yaml
.deploy:
  stage: deploy
  image: alpine:3.24.2
  interruptible: false
  before_script:
    - apk add --no-cache openssh-keygen
  script:
    - scripts/deploy.sh

deploy-staging:
  extends: .deploy
  environment:
    name: staging
    url: https://staging.<tu-dominio>.example
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

deploy-production:
  extends: .deploy
  environment:
    name: production
    url: https://<tu-dominio>.example
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: manual
      allow_failure: true
```

Las URL no son secretas: van en el YAML, no en una variable del proyecto (teoría 03). `.example` es un dominio reservado que no resuelve a nada.

Valida y pregunta qué entraría en `main`:

```bash
jq -n --rawfile c .gitlab-ci.yml '{content: $c, dry_run: true, ref: "main", include_jobs: true}' \
  | curl -s --request POST "$API/projects/$P/ci/lint" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -c '{valid, errors, jobs: [.jobs[]?.name]}'
# {"valid":true,"errors":[],"jobs":["build","test","package","deploy-staging","deploy-production"]}

git add .gitlab-ci.yml scripts/deploy.sh
git ls-files -s scripts/deploy.sh | cut -c1-6                         # 100755
git commit -S -m "ci: despliegue a staging y production con un secreto por entorno"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="ci: despliegue a staging y production con un secreto por entorno"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
```

---

## Paso 3: La merge request no ve los secretos

**Por qué**: el pipeline de la merge request se ejecuta con este YAML, que tú acabas de escribir. Si los jobs de despliegue entraran en él, `deploy.sh` se ejecutaría con lo que la rama quisiera.

```bash
sleep 10
PIPE=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/pipelines" | jq -r '.[0].id')
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -c '[.[].name] | sort'
```

**Verifica**: `["build","gobernanza","test"]`. Ningún `deploy-*`: sus reglas solo coinciden en `main`. Y aunque alguien añadiera a la rama un job con `environment: production`, `DEPLOY_TOKEN` es protegida: llegaría vacía (lo compruebas en la práctica 04).

`scripts/` es de `revisor` en `CODEOWNERS` desde la Semana 07, y `.gitlab-ci.yml` desde la 09: su aprobación cubre los dos.

```bash
fusionar "$MR"
git switch main && git pull --ff-only
```

---

## Paso 4: `staging`, desplegado; `production`, esperando

**Por qué**: el primer pipeline de `main` con despliegue. `deploy-staging` corre solo; `deploy-production` se queda esperando, y el pipeline termina en verde igualmente.

```bash
sleep 10
PIPE=$(curl -s -H "$H" "$API/projects/$P/pipelines?ref=main&per_page=1" | jq -r '.[0].id')
until curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE" | jq -e '.status | IN("success","failed","canceled")' > /dev/null; do sleep 10; done
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE" | jq -r '"\(.name) \(.status)"'
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | "\(.name) \(.status)"'
JOB=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | select(.name == "deploy-staging") | .id')
curl -s -H "$H" "$API/projects/$P/jobs/$JOB/trace" | sed 's/\x1b\[[0-9;]*m//g' | grep -v '\$ ' | grep -E '^(.* )?(Entorno|Commit|Token|Despliegue)'
```

**Verifica**:

```
push · main success
deploy-production manual
deploy-staging success
package success
test success
build success
… Entorno: staging (https://staging.<tu-dominio>.example)
… Commit:  <sha>
… Token:   64 caracteres
… Despliegue simulado: correcto
```

Los entornos y el despliegue, por API:

```bash
curl -s -H "$H" "$API/projects/$P/environments" | jq -r '.[] | "\(.name) \(.tier) \(.state)"'
curl -s -H "$H" "$API/projects/$P/deployments?environment=staging&status=success" | jq -r '.[] | "\(.id) \(.ref) \(.sha[0:8])"'
```

Y `dev` intenta lanzar el despliegue a `production`:

```bash
export JOB_PROD=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs?scope=manual" | jq -r '.[] | select(.name == "deploy-production") | .id')
curl -s -o /dev/null -w 'dev lanza deploy-production: %{http_code}\n' --request POST "$API/projects/$P/jobs/$JOB_PROD/play" -H "$HD"
```

**Verifica**: `403`. Lanzar un job de una rama protegida exige poder fusionar en ella, y en `main` solo fusionan los Maintainers. Es el sustituto de CE para los entornos protegidos (teoría 05), y su límite: lo que valga la protección de `main`.

---

## Paso 5: `production`, lanzado

**Por qué**: el despliegue a `production` tiene que fallar por la razón correcta, y el pipeline de `main` no tiene que ponerse en rojo por ello.

```bash
curl -s --request POST "$API/projects/$P/jobs/$JOB_PROD/play" -H "$H" | jq -r .status
until curl -s -H "$H" "$API/projects/$P/jobs/$JOB_PROD" | jq -e '.status | IN("success","failed")' > /dev/null; do sleep 5; done
curl -s -H "$H" "$API/projects/$P/jobs/$JOB_PROD" | jq -c '{status, failure_reason, allow_failure}'
curl -s -H "$H" "$API/projects/$P/jobs/$JOB_PROD/trace" | sed 's/\x1b\[[0-9;]*m//g' | grep -E 'Token|no ha llegado' | grep -v '\$ '
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE" | jq -r .status
echo "export JOB_PROD=$JOB_PROD" >> ~/.bc-gitlab-s10
```

**Verifica**:

```
{"status":"failed","failure_reason":"script_failure","allow_failure":true}
… Token:   64 caracteres
… scripts/deploy.sh: line 14: DEPLOY_SSH_KEY: DEPLOY_SSH_KEY no ha llegado
success
```

`DEPLOY_TOKEN` de `production` llegó (otro valor que el de `staging`, de la misma longitud). La clave no existe todavía, el script se negó a seguir y el pipeline sigue en `success` gracias a `allow_failure: true`. La práctica 04 crea la clave y reintenta este mismo job.

---

## ✅ Resultado

- [ ] `DEPLOY_TOKEN` con ámbitos `staging` y `production`, protegida y enmascarada, sin haberla visto
- [ ] `scripts/deploy.sh` ejecutable, que falla con un mensaje claro si le falta un secreto
- [ ] La merge request sin jobs de despliegue
- [ ] `deploy-staging` correcto en `main`, con el entorno y el despliegue visibles por API
- [ ] `dev` recibió `403` al lanzar `deploy-production`
- [ ] `deploy-production` lanzado, fallido por `DEPLOY_SSH_KEY`, y el pipeline de `main` en verde

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `deploy-staging` falla con `DEPLOY_TOKEN no ha llegado` | La variable no es del ámbito `staging`, o `main` no está protegida | Paso 1; `GET .../protected_branches` |
| `deploy-staging` falla con `Permission denied` | `deploy.sh` sin bit de ejecución en Git | `git update-index --chmod=+x scripts/deploy.sh` en una merge request |
| El pipeline de `main` queda en `manual`, no en `success` | Falta `allow_failure: true` en la regla de `deploy-production` | Añádelo en la misma regla, no en el job |
| `400` al crear la segunda `DEPLOY_TOKEN`: `has already been taken` | Las dos con el mismo ámbito | `environment_scope` distinto en cada una |
| `400` al crear `DEPLOY_TOKEN`: `value is invalid` | El valor llegó vacío: `openssl` no estaba instalado | Instálalo y repite solo ese ámbito. Para borrar una de las dos: `DELETE .../variables/DEPLOY_TOKEN?filter%5Benvironment_scope%5D=staging`; sin el filtro no sabes cuál borra |
| `fusionar` no fusiona: `gobernanza` en rojo | Falta la aprobación del dueño de `scripts/` | Lee el log de `gobernanza` |

---

## 🔗 Navegación

[← Anterior: Variables y precedencia](02-variables-y-precedencia.md) · [Volver a la Semana 10](../README.md) · [Siguiente: Archivos secretos y fugas →](04-archivos-secretos-y-fugas.md)

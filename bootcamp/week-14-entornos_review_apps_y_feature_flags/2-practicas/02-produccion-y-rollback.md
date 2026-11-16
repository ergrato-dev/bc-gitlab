# Práctica 02 — Producción y rollback

> `app` suelta los despliegues simulados de la Semana 10 y sus credenciales, y gana un botón que dispara `production` en `infra/entornos`. Compruebas que `revisor`, que manda en `app`, no puede pulsarlo. Despliegas en `production`, fusionas un error que tumba `staging`, lo deshaces en un minuto reintentando el despliegue anterior, y lo arreglas después con calma.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 01 completada · Teoría [03](../1-teoria/03-secretos-en-infra.md) y [05](../1-teoria/05-despliegue-reversible.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | `ci/deploy.yml` sin despliegues simulados, con `infra-production` | `produccion-manual-desde-app` |
| 2 | `app` sin `DEPLOY_TOKEN` ni `DEPLOY_SSH_KEY`, y sus entornos viejos parados | `app-sin-secretos-de-entornos` |
| 3 | `revisor` no puede desplegar en `production` | — |
| 4 | `production` desplegado | `production-desplegado` |
| 5 | Un error en `staging` | — |
| 6 | El rollback | `rollback-en-staging` |
| 7 | El arreglo | — |

Si has cerrado la terminal: `source ~/.bc-gitlab`, `source ~/.bc-gitlab-s14`, las variables `H`, `API`, `P` y `HR` del paso 0 de la práctica 01, y `esperar` y `fusionar`.

---

## Paso 1: `ci/deploy.yml`, solo disparos

**Por qué**: `deploy-staging` y `deploy-production` desplegaban en ningún sitio con credenciales de `app` (Semana 10). Ahora despliega `infra/entornos`. A `app` le quedan dos disparos: `infra`, automático, para `staging`, y `infra-production`, manual, para `production`.

```bash
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=production se despliega desde infra/entornos" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=Fuera deploy-staging, deploy-production y scripts/deploy.sh. infra-production manual dispara infra/entornos con entorno=production. DEPLOY_TOKEN y DEPLOY_SSH_KEY salen de app. Ver Semana 14." \
  | jq -r .iid)
git switch -c "$IID-produccion-desde-infra"
git rm -q scripts/deploy.sh

cat > ci/deploy.yml <<'EOF'
# El despliegue es de infra/entornos (Semana 14): app solo dice qué versión y adónde.
infra:
  stage: deploy
  needs: [publicar-paquete]
  rules:
    - !reference [.fuera-de-programados, rules]
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  variables:
    APP_SHA: $CI_COMMIT_SHA
    APP_PROJECT_ID: $CI_PROJECT_ID
  trigger:
    project: plataforma-<tu-dominio>/infra/entornos
    branch: main
    strategy: mirror
    inputs:
      entorno: staging

# production, a mano y después de staging. Quien lo pulse tiene que poder
# actualizar main de infra/entornos (teoría 03, apartado 2.4).
infra-production:
  stage: deploy
  needs: [infra]
  rules:
    - !reference [.fuera-de-programados, rules]
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: manual
      allow_failure: true
  variables:
    APP_SHA: $CI_COMMIT_SHA
    APP_PROJECT_ID: $CI_PROJECT_ID
  trigger:
    project: plataforma-<tu-dominio>/infra/entornos
    branch: main
    strategy: mirror
    inputs:
      entorno: production
EOF
```

| Línea | Por qué |
|---|---|
| `needs: [infra]` | `production` solo después de que `staging` termine en verde: con `strategy: mirror`, `infra` espera al pipeline de abajo |
| `when: manual` y `allow_failure: true` | Que nadie lo pulse no deja el pipeline de `main` bloqueado |
| Las mismas `variables` | El mismo `APP_SHA`: `production` recibe exactamente lo que pasó por `staging` |
| Sin `environment` | El entorno es de `infra/entornos`; aquí no hay despliegue que registrar |

El inventario de secretos cambia también. En `docs/secretos.md`, sustituye las filas de `DEPLOY_TOKEN` y `DEPLOY_SSH_KEY` por estas, con tu fecha de rotación en la columna de caducidad (la que lee `scripts/caducidades.sh` desde la Semana 11):

```markdown
| `DEPLOY_SSH_KEY` | Archivo | `infra/entornos` · `staging` | ✅ | Maintainers de `infra/entornos`; jobs de `main` con `environment: staging` | `~/.ssh/destino-staging`; se revoca en `authorized_keys` del destino | Rotar antes del AAAA-MM-DD | Solo despliega en `staging` |
| `DEPLOY_SSH_KEY` | Archivo | `infra/entornos` · `production` | ✅ | Maintainers de `infra/entornos`; jobs de `main` con `environment: production` | `~/.ssh/destino-production`; se revoca en `authorized_keys` del destino | Rotar antes del AAAA-MM-DD | Solo despliega en `production` |
```

Y debajo de la tabla, la historia: `DEPLOY_TOKEN se borró en la Semana 14: el destino no lo pide. Las DEPLOY_SSH_KEY de app, también; las de hoy son claves nuevas.`

```bash
git add ci/deploy.yml docs/secretos.md
git commit -S -m "ci: production se dispara a mano en infra/entornos y app deja de desplegar"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="ci: production se despliega desde infra/entornos" \
  -o merge_request.description="Closes #$IID"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
fusionar "$P" "$MR"
git switch main && git pull --ff-only
PIPE=$(curl -s -H "$H" "$API/projects/$P/pipelines?ref=main&source=push&per_page=1" | jq -r '.[0].id')
esperar "$P" "$PIPE"
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/bridges" | jq -c '.[] | {name, status}'
```

**Verifica**: `state: merged`, `success`, e `infra` en `success` con `infra-production` en `manual`. El pipeline ya no tiene `deploy-staging` ni `deploy-production`.

---

## Paso 2: Las credenciales salen de `app`

**Por qué**: con el paso 1 fusionado, ningún job de `app` las usa. Borrarlas es el paso que convierte la mudanza en mudanza (teoría 03, apartado 2.3).

> [!WARNING]
> Lo que sigue borra variables. `DEPLOY_TOKEN` y `DEPLOY_SSH_KEY` de `app` no abren nada (nunca se instalaron en el destino), así que no hay copia que guardar. Si en tu caso abren algo real, apunta antes dónde revocarlas.

```bash
curl -s -H "$H" "$API/projects/$P/variables?per_page=100" | jq -c '.[] | {key, environment_scope}'
for v in "DEPLOY_TOKEN staging" "DEPLOY_TOKEN production" "DEPLOY_SSH_KEY production"; do
  set -- $v
  curl -s -o /dev/null -w "$1 $2: %{http_code}\n" --request DELETE -H "$H" \
    "$API/projects/$P/variables/$1?filter%5Benvironment_scope%5D=$2"
done
```

Los entornos `staging` y `production` de `app` guardan el historial de la Semana 10. No se borran: se paran, y quedan como registro.

```bash
for id in $(curl -s -H "$H" "$API/projects/$P/environments?states=available" \
    | jq -r '.[] | select(.name == "staging" or .name == "production") | .id'); do
  curl -s --request POST "$API/projects/$P/environments/$id/stop" -H "$H" | jq -c '{name, state}'
done
```

Si aún guardas la privada de la Semana 10 (`deploy_app_prueba`), bórrala ahora.

**Verifica**: tres `204`, los dos entornos `stopped`, y en las variables de `app` ya no hay `DEPLOY_`:

```bash
curl -s -H "$H" "$API/projects/$P/variables?per_page=100" | jq -r '.[].key' | grep -c DEPLOY_   # 0
```

---

## Paso 3: Quién pulsa el botón

**Por qué**: `revisor` es Maintainer de `app` (Semana 03): puede fusionar en `main` y lanzar sus jobs manuales. En `infra/entornos` hereda Guest del grupo, y un Guest no crea pipelines de ningún modo: un `403` así no probaría nada. Para que lo que se ponga a prueba sea la rama protegida, `revisor` sube a Developer en `infra/entornos` durante la prueba. La teoría 03 dice que ni así puede desplegar en `production`. Compruébalo.

```bash
curl -s --request POST "$API/projects/$PI/members" -H "$H" \
  --data-urlencode "user_id=$UID_REV" --data-urlencode "access_level=30" | jq -c '{username, access_level}'
BR=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/bridges" | jq -r '.[] | select(.name == "infra-production") | .id')
curl -s --request POST "$API/projects/$P/jobs/$BR/play" -H "$HR" | jq -c .
curl -s --request DELETE "$API/projects/$PI/members/$UID_REV" -H "$H" -o /dev/null -w 'vuelve a Guest: %{http_code}\n'
```

**Verifica**: `{"message":"403 Forbidden"}` siendo Developer, y `204` al quitarle el rol directo. En `app` manda; en `production`, no, porque no puede actualizar `main` de `infra/entornos`. Es lo que haría un entorno protegido de Premium, hecho con una rama protegida.

---

## Paso 4: `production`

**Por qué**: ahora tú, que eres Maintainer de `infra/entornos`. Lo que llega a `production` es el mismo `APP_SHA` que está en `staging`.

```bash
curl -s --request POST "$API/projects/$P/jobs/$BR/play" -H "$H" | jq -c '{name, status}'
sleep 15
PIPE_I=$(curl -s -H "$H" "$API/projects/$PI/pipelines?source=pipeline&per_page=1" | jq -r '.[0].id')
curl -s -H "$H" "$API/projects/$PI/pipelines/$PIPE_I" | jq -r .name
esperar "$PI" "$PIPE_I"
curl -s localhost:8095/production/salud | jq -c '{entorno, sha}'
curl -s localhost:8095/staging/salud | jq -c '{entorno, sha}'
curl -s --request PUT "$API/projects/$PI/resource_groups/production" -H "$H" \
  --data-urlencode "process_mode=oldest_first" | jq -c '{key, process_mode}'
```

**Verifica**: el pipeline se llama `app <SHA> → production`, termina en `success`, y los dos entornos responden con el **mismo** SHA. El resource group de `production` nació con este job; queda en `oldest_first`.

---

## Paso 5: Un error en `staging`

**Por qué**: un rollback se entiende cuando hace falta. Este cambio añade la versión de `app` a `/salud`, con un error de los que pasan una revisión: la ruta a `package.json` sube un nivel de más. Los tests no lo ven, porque no prueban `http.ts`.

```bash
git switch main && git pull --ff-only
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=/salud dice la versión de app" \
  --data-urlencode "labels=tipo::mejora" \
  --data-urlencode "description=La versión de package.json en /salud. Ver Semana 14." | jq -r .iid)
git switch -c "$IID-version-en-salud"
python3 - <<'EOF'
p = 'src/http.ts'
s = open(p).read()
s = s.replace("import type { IncomingMessage", "import { readFileSync } from 'node:fs';\nimport type { IncomingMessage", 1)
s = s.replace("    return responder(200, { estado: 'ok', entorno",
  "    const { version } = JSON.parse(readFileSync(new URL('../../package.json', import.meta.url), 'utf8'));\n"
  "    return responder(200, { estado: 'ok', version, entorno", 1)
open(p, 'w').write(s)
EOF
git diff --stat
git commit -S -am "feat: la versión de app en /salud"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="feat: la versión de app en /salud" -o merge_request.description="Closes #$IID"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
fusionar "$P" "$MR"
git switch main && git pull --ff-only
PIPE=$(curl -s -H "$H" "$API/projects/$P/pipelines?ref=main&source=push&per_page=1" | jq -r '.[0].id')
esperar "$P" "$PIPE"
curl -s localhost:8095/staging/salud
```

**Verifica**: el pipeline de `main` termina en `failed`, e `infra` también. `staging` responde:

```text
{"error":"ENOENT: no such file or directory, open '/srv/entornos/staging/versiones/package.json'"}
```

Mira las dos cosas a la vez. El destino **sirve la versión rota**: `desplegar` cambió `actual` antes de que la comprobación de `desplegar.sh` fallara. Y GitLab dice que el último despliegue correcto de `staging` es el anterior. Las dos son verdad; por eso el rollback se comprueba en el destino.

---

## Paso 6: El rollback

**Por qué**: hay que parar el daño antes de arreglar nada. El último despliegue correcto de `staging` tiene su job; reintentarlo vuelve a desplegar su `APP_SHA` (teoría 05, apartado 2.1).

**Con la UI**: `Operate → Environments → staging`, el despliegue anterior al fallido, *Rollback*.

**Con la API**:

```bash
JOB=$(curl -s -H "$H" "$API/projects/$PI/deployments?environment=staging&status=success&order_by=id&sort=desc&per_page=1" \
  | jq -r '.[0].deployable.id')
NUEVO=$(curl -s --request POST "$API/projects/$PI/jobs/$JOB/retry" -H "$H" | jq -r .id)
until curl -s -H "$H" "$API/projects/$PI/jobs/$NUEVO" | jq -e '.status | IN("success","failed")' > /dev/null; do sleep 5; done
curl -s -H "$H" "$API/projects/$PI/jobs/$NUEVO" | jq -r .status
curl -s localhost:8095/staging/salud | jq -c '{sha, desplegado}'
curl -s localhost:8095/production/salud | jq -r .sha
```

**Verifica**: `success`, y `staging` responde otra vez con el SHA que tiene `production`, con una fecha de despliegue de hace un momento. Un minuto, sin tocar el código.

---

## Paso 7: El arreglo, con calma

**Por qué**: el error sigue en `main`. Ahora sí, una merge request normal, revisada sin prisa. La ruta correcta es `../package.json`: `http.ts` está en `src/`, y `package.json` un nivel por encima.

```bash
git switch -c "$IID-arreglo-version"
sed -i "s|new URL('../../package.json'|new URL('../package.json'|" src/http.ts
node --experimental-strip-types -e "
  import('./src/http.ts').then(async ({ default: atender }) => {
    const res = { writeHead() {}, end: (b) => console.log(b.trim()) };
    await atender({}, res, { entorno: 'local', sha: 'x', desplegado: 'ahora', ruta: '/salud', url: new URL('http://x/salud') });
  })"
git commit -S -am "fix: la ruta a package.json desde src/http.ts"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="fix: la ruta a package.json en /salud" -o merge_request.description="Closes #$IID"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
fusionar "$P" "$MR"
git switch main && git pull --ff-only
PIPE=$(curl -s -H "$H" "$API/projects/$P/pipelines?ref=main&source=push&per_page=1" | jq -r '.[0].id')
esperar "$P" "$PIPE"
curl -s localhost:8095/staging/salud | jq -c '{version, sha}'
```

**Verifica**: la prueba local imprime `{"estado":"ok","version":"…",…}` antes de abrir la merge request, el pipeline termina en `success`, y `staging` responde con `version` y el SHA nuevo. `production` sigue en la versión del paso 4 hasta que alguien pulse `infra-production`.

---

## ✅ Checklist

- [ ] `ci/deploy.yml` solo con `infra` e `infra-production`, y `scripts/deploy.sh` borrado
- [ ] `app` sin variables `DEPLOY_`, sus entornos viejos parados y `docs/secretos.md` al día
- [ ] `revisor` recibió `403` al pulsar `infra-production`
- [ ] `production` desplegado, con su resource group en `oldest_first`
- [ ] `staging` roto, devuelto a la versión anterior con un reintento, y arreglado después

---

## 🧯 Problemas frecuentes

| Síntoma | Causa | Solución |
|---|---|---|
| `infra-production` responde `403` también a ti | No puedes actualizar `main` de `infra/entornos` | Tienes que ser Maintainer u Owner allí |
| `infra` falla con `insufficient permissions to create a downstream pipeline` (`failure_reason: insufficient_bridge_permissions`) | Quien fusionó en `app` no puede actualizar `main` de `infra/entornos` | Teoría 03, nota del apartado 2.4 |
| El borrado de una variable da `404` | El `environment_scope` no coincide | Lista las variables y copia el ámbito exacto |
| El borrado da `409` o borra la que no era | Falta `filter[environment_scope]` y hay varias con la misma clave | Usa el filtro, como en el paso 2 |
| El reintento del paso 6 vuelve a desplegar la versión rota | Cogiste el último despliegue, no el último **correcto** | `status=success` en la consulta |
| `staging` sigue roto tras un reintento en `success` | Miraste antes de que terminara | Espera al `success` y vuelve a preguntar al destino |

---

[← Anterior: El destino y staging](01-el-destino-y-staging.md) · [Volver a la Semana 14](../README.md) · [Siguiente: Review apps →](03-review-apps.md)

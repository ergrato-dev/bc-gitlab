# Práctica 01 — `include` en `app`

> Partes el `.gitlab-ci.yml` de `app` en dos archivos sin cambiar nada de lo que se ejecuta, y lo demuestras: el YAML fusionado de antes y el de después tienen exactamente las mismas líneas. Por el camino ves, sin guardarlo, cómo una lista redefinida borra la que traía el archivo incluido.

**Duración estimada**: 50 min
**Prerrequisitos**: Semana 11 completada · Teoría [01](../1-teoria/01-include.md) y [02](../1-teoria/02-extends-y-reference.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 0 | El token de `revisor`, `esperar` y `fusionar` | — |
| 1 | La foto del YAML fusionado de `main` | — |
| 2 | `ci/deploy.yml` y el `include`, en una rama | — |
| 3 | La prueba de que no cambia nada | — |
| 4 | La fusión de listas, vista sin guardarla | — |
| 5 | La merge request fusionada y `main` en verde | `despliegue-en-su-archivo`, `app-incluye-deploy` |

---

## Paso 0: Preparar el terreno

**Por qué**: esta semana vuelve a haber merge requests a `main` de `app` que necesitan la aprobación de `revisor`, y el proyecto de la Semana 11 revocó su token y borró `~/.bc-gitlab-s11`. Las mismas funciones, con un token nuevo y su propio archivo de identificadores, fuera del repositorio.

```bash
source ~/.bc-gitlab
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
export HA="PRIVATE-TOKEN: ${GITLAB_ADMIN_TOKEN:-$GITLAB_TOKEN}"
export GRUPO=${PROYECTO%%/*}
export PI=$(printf '%s' "$GRUPO/infra/entornos" | jq -sRr @uri)
export REV=revisor-<tu-dominio>
export UID_REV=$(curl -s -H "$H" "$API/users?username=$REV" | jq -r '.[0].id // empty')
[[ "$UID_REV" =~ ^[0-9]+$ ]] || { echo "Falta $REV: NO sigas"; return 1 2>/dev/null || exit 1; }

T_REV=$(curl -s --request POST "$API/users/$UID_REV/personal_access_tokens" -H "$HA" \
  --data-urlencode "name=flujo-s12" --data-urlencode "scopes[]=api" \
  --data-urlencode "expires_at=$(date -d '+7 days' +%F)" | jq -r '.token')
[ -n "$T_REV" ] && [ "$T_REV" != null ] || { echo "No se creó el token: revisa GITLAB_ADMIN_TOKEN y NO sigas"; return 1 2>/dev/null || exit 1; }
export HR="PRIVATE-TOKEN: $T_REV"
grep -qs GRUPO ~/.bc-gitlab-s12 || echo "export GRUPO=$GRUPO PI=$PI REV=$REV UID_REV=$UID_REV" >> ~/.bc-gitlab-s12

esperar() {   # espera a que un pipeline termine y escribe su estado
  until curl -s -H "$H" "$API/projects/$1/pipelines/$2" \
          | jq -e '.status | IN("success","failed","canceled","skipped")' > /dev/null; do sleep 10; done
  curl -s -H "$H" "$API/projects/$1/pipelines/$2" | jq -r .status
}

fusionar() {   # $1 = proyecto, $2 = MR: aprueba como revisor, relanza y fusiona si gobernanza está en verde
  local PR=$1 MR=$2 PIPE SHA
  curl -s --request POST "$API/projects/$PR/merge_requests/$MR/approve" -H "$HR" > /dev/null
  PIPE=$(curl -s --request POST "$API/projects/$PR/merge_requests/$MR/pipelines" -H "$H" | jq -r .id)
  esperar "$PR" "$PIPE" > /dev/null
  curl -s -H "$H" "$API/projects/$PR/pipelines/$PIPE/jobs" \
    | jq -e '.[] | select(.name == "gobernanza") | .status == "success"' > /dev/null \
    || { echo "gobernanza no está en verde en el pipeline $PIPE: lee su log"; return 1; }
  SHA=$(curl -s -H "$H" "$API/projects/$PR/merge_requests/$MR" | jq -r .sha)
  curl -s --request PUT "$API/projects/$PR/merge_requests/$MR/merge" -H "$H" \
    --data-urlencode "sha=$SHA" --data-urlencode "squash=true" | jq '{state, squash_commit_sha}'
}
```

`fusionar` recibe ahora el proyecto como primer argumento: en la práctica 02 también fusionarás en `ci/componentes`.

**Verifica**:

```bash
curl -s -H "$HR" "$API/user" | jq -r .username                                # revisor-<tu-dominio>
curl -s -H "$H" "$API/projects/$P/merge_requests?state=opened" | jq length     # 0
type esperar fusionar | grep -c function                                     # 2
```

---

## Paso 1: La foto de antes

**Por qué**: "no cambia nada" es una afirmación que se puede comprobar. Guardas el YAML fusionado de `main` tal como está, para compararlo después.

```bash
curl -s -H "$H" "$API/projects/$P/ci/lint?include_merged_yaml=true" \
  | jq -r .merged_yaml > ~/s12-antes.yml
wc -l < ~/s12-antes.yml
grep -c '^[a-z.]' ~/s12-antes.yml
```

`GET .../ci/lint` sin más parámetros lee `.gitlab-ci.yml` de la rama por defecto.

**Verifica**: más de cien líneas, y unas quince claves de primer nivel: `workflow`, `.fuera-de-programados`, `stages`, `variables`, `default`, los jobs y los ocultos.

---

## Paso 2: `ci/deploy.yml`

**Por qué**: el despliegue y el disparo a `infra` cambian cuando cambia un entorno, no cuando cambia la construcción. Son las últimas piezas del archivo desde la Semana 11: `.deploy`, `deploy-staging`, `deploy-production` e `infra`.

```bash
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Separar el despliegue en ci/deploy.yml" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=include:local de ci/deploy.yml con .deploy, los dos despliegues e infra. Sin cambios en lo que se ejecuta: merged_yaml igual antes y después. Ver Semana 12." \
  | jq -r .iid)
git switch -c "$IID-include-del-despliegue"

grep -n '^[a-z.][a-z.-]*:' .gitlab-ci.yml | tail -5
```

**Verifica** antes de cortar: las cuatro últimas claves son `.deploy`, `deploy-staging`, `deploy-production` e `infra`, en ese orden. Si alguna no está al final (porque la añadiste en otro sitio), muévela al final a mano antes de seguir.

Corta desde `.deploy:` hasta el final:

```bash
N=$(grep -n '^\.deploy:' .gitlab-ci.yml | cut -d: -f1)
{ echo "# Despliegues de app y disparo a infra/entornos. Lo incluye .gitlab-ci.yml."
  echo "# .fuera-de-programados vive en .gitlab-ci.yml: !reference lo encuentra tras el include."
  echo
  tail -n +"$N" .gitlab-ci.yml; } > ci/deploy.yml
head -n $((N - 1)) .gitlab-ci.yml > .gitlab-ci.tmp && mv .gitlab-ci.tmp .gitlab-ci.yml
```

Y el `include`, justo encima de `stages`:

```yaml
include:
  - local: ci/deploy.yml

stages: [build, test, package, deploy]
```

`ci/` ya tiene dueño en CODEOWNERS desde la Semana 11: `ci/deploy.yml` lo hereda.

```bash
tail -3 .gitlab-ci.yml                         # el final de caducidades, no el de infra
head -6 ci/deploy.yml
git add .gitlab-ci.yml ci/deploy.yml
git commit -S -m "ci: separar el despliegue en ci/deploy.yml"
git push -u origin HEAD
```

**Verifica**: el `lint` de la rama recién empujada. `content_ref` es la rama de la que se leen `.gitlab-ci.yml` y sus `include:local`:

```bash
RAMA=$(git branch --show-current)
curl -s -H "$H" "$API/projects/$P/ci/lint?content_ref=$RAMA&include_merged_yaml=true" \
  | tee ~/s12-lint.json | jq -c '{valid, errors, includes: [.includes[] | {type, location}]}'
# {"valid":true,"errors":[],"includes":[{"type":"local","location":"ci/deploy.yml"}]}
```

---

## Paso 3: Nada ha cambiado

**Por qué**: si el resultado fuera distinto, el cambio no sería de orden sino de comportamiento, y una merge request de "orden" no lo diría.

```bash
jq -r .merged_yaml ~/s12-lint.json > ~/s12-despues.yml
diff ~/s12-antes.yml ~/s12-despues.yml | head -5
diff <(sort ~/s12-antes.yml) <(sort ~/s12-despues.yml) && echo "mismas líneas"
```

**Verifica**: el primer `diff` no está vacío: lo incluido se fusiona primero, así que `.deploy` y compañía aparecen ahora **arriba** en `merged_yaml`. El segundo dice `mismas líneas`: con las líneas ordenadas, no sobra ni falta ninguna. Mismo contenido, otro orden. El orden de las claves no cambia lo que se ejecuta.

---

## Paso 4: Una lista redefinida, sin guardarla

**Por qué**: la teoría 01 dice que las listas no se fusionan. Compruébalo con el job que más reglas tiene, sin tocar la rama: `POST .../ci/lint` con un `content` inventado, `dry_run` y `ref`, lee los `include:local` de esa rama. Sin `dry_run`, los buscaría en la rama por defecto y no encontraría `ci/deploy.yml`.

```bash
{ cat .gitlab-ci.yml
  printf '\ndeploy-staging:\n  rules:\n    - if: $CI_COMMIT_BRANCH =~ /^release\\//\n'; } \
  | jq -Rs --arg r "$RAMA" '{content: ., dry_run: true, ref: $r}' \
  | curl -s --request POST "$API/projects/$P/ci/lint" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -r .merged_yaml | awk '/^deploy-staging:/{f=1; print; next} /^[^ ]/{f=0} f' | grep -A3 'rules:'
```

**Verifica**: `deploy-staging` sale con **una** regla, la de `release/`. La de `.fuera-de-programados` y la de `main` han desaparecido sin ningún error. Si de verdad quisieras añadir la de `release/*`, la forma es repetir las que había, con `!reference` para la primera (teoría 02, apartado 2.4). No guardes nada: el `content` solo existió en esa petición.

---

## Paso 5: La merge request

**Por qué**: un cambio de `ci/` pasa por el revisor y por `gobernanza` como cualquier otro.

```bash
glab mr create --source-branch "$RAMA" --target-branch main \
  --title "ci: separar el despliegue en ci/deploy.yml" \
  --description "Closes #$IID" --yes
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$RAMA&state=opened" | jq -r '.[0].iid')
fusionar "$P" "$MR"
git switch main && git pull --ff-only
PIPE=$(curl -s -H "$H" "$API/projects/$P/pipelines?ref=main&source=push&per_page=1" | jq -r '.[0].id')
esperar "$P" "$PIPE"
```

**Verifica**: `state: merged` y el pipeline de `main` en `success`, con los mismos jobs que antes: `build`, `test`, `package`, `deploy-staging`, `deploy-production` (manual) e `infra`, que dispara `infra/entornos`.

```bash
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '[.[].name] | sort | join(" ")'
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/bridges" | jq -r '.[].name'
# build deploy-production deploy-staging package test
# infra
```

---

## ✅ Resultado

- [ ] `ci/deploy.yml` con `.deploy`, los dos despliegues e `infra`, incluido desde `.gitlab-ci.yml`
- [ ] `diff` de las líneas ordenadas vacío: el pipeline hace lo mismo
- [ ] Viste desaparecer dos reglas de `deploy-staging` al redefinir su lista
- [ ] La merge request fusionada y `main` en verde, disparando `infra/entornos`

```bash
./scripts/verificar-semana.sh 12
```

`despliegue-en-su-archivo` y `app-incluye-deploy` en verde; el resto llega con las prácticas siguientes.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| ``Local file `ci/deploy.yml` does not exist!`` | El `lint` lee una rama donde aún no está el archivo, o un `POST` con `content` sin `dry_run` | Empuja la rama; `content_ref=<rama>` en `GET`, `dry_run` y `ref` en `POST` |
| `includes` vacío en el `lint` | Leíste `main`, no la rama: `GET .../ci/lint?ref=` no cambia de rama | `content_ref=<rama>` |
| `!reference [".fuera-de-programados", "rules"] could not be found` | Cortaste también `.fuera-de-programados` | Devuélvelo a `.gitlab-ci.yml`, debajo de `workflow` |
| El `diff` ordenado tiene líneas | Se perdió o se duplicó algo al cortar | `git diff main -- .gitlab-ci.yml ci/deploy.yml` y compara con el paso 2 |
| `infra` falla en el pipeline de `main` | Lo mismo que en la Semana 11: lee el log del pipeline de `infra/entornos` | Semana 11, práctica 03 |
| `fusionar` dice que `gobernanza` no está en verde | La descripción no cierra el issue, o falta la aprobación del dueño de `ci/` | `Closes #$IID` y el revisor como dueño de `/ci/` |

---

## 🔗 Navegación

[Volver a la Semana 12](../README.md) · [Siguiente: Los dos componentes →](02-los-dos-componentes.md)

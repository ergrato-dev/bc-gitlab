# Práctica 04 — El primer parche

> Aparece un bug en la `0.1.0`. Lo arreglas en `main`, creas `release/0.1` desde el tag, llevas el arreglo con `cherry-pick -x` por merge request, generas el CHANGELOG de la `0.1.1` en la rama de release y publicas la `v0.1.1` sin que entre nada de lo que haya en `main`.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 03 completada · Teoría [05](../1-teoria/05-ramas-de-release-y-cherry-pick.md) leída

---

## Contexto

Es *upstream first* de principio a fin: el arreglo entra en `main`, y de ahí baja a `release/0.1`. Son tres merge requests, cada una con su revisión:

| Merge request | Destino | Qué lleva |
|---|---|---|
| El arreglo | `main` | El test que reproduce el bug y el arreglo, con `Changelog: fixed` |
| El parche | `release/0.1` | El commit de squash del arreglo, traído con `cherry-pick -x` |
| El CHANGELOG de la `0.1.1` | `release/0.1` | La sección `0.1.1`, generada por la API |

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 2 | El arreglo en `main` | `tres-cambios-con-changelog` |
| 3 | `release/0.1` con el arreglo | `rama-release-0-1`, `cherry-pick-en-release` |
| 4 | CHANGELOG de la `0.1.1` en `release/0.1` | — (lo evalúa la rúbrica) |
| 5 | Tag `v0.1.1` en `release/0.1` | `v0-1-1-sale-de-la-rama-de-release` |
| 6 | Release `v0.1.1` | `release-v0-1-1-con-notas` |

---

## Paso 0: Preparar el terreno

```bash
source ~/.bc-gitlab
source ~/.bc-gitlab-s08
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
```

**Verifica**:

```bash
curl -s -H "$HR" "$API/user" | jq -r .username                     # revisor-<tu-dominio>
curl -s -H "$H" "$API/projects/$P/releases/permalink/latest" | jq -r .tag_name   # v0.1.0
git describe --tags --abbrev=0 --match 'v*'                          # v0.1.0
```

---

## Paso 1: El bug

**Por qué**: un parche sin issue es un cambio que nadie puede rastrear. El issue `tipo::bug` es, además, la fuente del tiempo de restauración de `scripts/metricas.sh`.

Busca un caso límite real que la `0.1.0` maneje mal: un número negativo, una entrada vacía, una fecha en el borde. Escríbelo primero como test y comprueba que falla contra `v0.1.0`:

```bash
git switch --detach v0.1.0
# añade el test, ejecútalo: tiene que fallar
git stash -u && git switch main
```

Con el fallo reproducido, el issue:

```bash
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=<qué falla, en una línea>" \
  --data-urlencode "labels=tipo::bug,area::<la tuya>" \
  --data-urlencode "description=Afecta a v0.1.0. Pasos: <cómo reproducirlo>. Esperado: <x>. Obtenido: <y>." \
  | jq -r .iid)
echo "export IID_BUG=$IID" >> ~/.bc-gitlab-s08
```

**Verifica**: `curl -s -H "$H" "$API/projects/$P/issues/$IID" | jq -r '.labels[]'` incluye `tipo::bug`.

---

## Paso 2: El arreglo, en `main`

**Por qué**: *upstream first*. Si el arreglo solo entrara en `release/0.1`, la `0.2.0` volvería a tener el bug.

```bash
git switch -c "$IID-<descripcion-corta>"
git stash pop                                   # el test del paso 1
# el arreglo; tests en verde
git add -A
git commit -S -m "fix(<area>): <qué deja de fallar>" -m "Changelog: fixed"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="fix(<area>): <qué deja de fallar>"

MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
curl -s --request POST "$API/projects/$P/merge_requests/$MR/approve" -H "$HR" > /dev/null
bash scripts/gobernanza.sh "$MR" && {
  SHA=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .sha)
  curl -s --request PUT "$API/projects/$P/merge_requests/$MR/merge" -H "$H" \
    --data-urlencode "sha=$SHA" --data-urlencode "squash=true" | jq -r .state
}
```

El commit que hay que llevar a la rama de release es el de **squash**, no el de fusión (teoría [05](../1-teoria/05-ramas-de-release-y-cherry-pick.md), apartado 2.3):

```bash
FIX=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r '.squash_commit_sha // .merge_commit_sha')
echo "export FIX=$FIX" >> ~/.bc-gitlab-s08
git switch main && git pull --ff-only
git log -1 --format='%(trailers:key=Changelog)' "$FIX"       # Changelog: fixed
```

**Verifica**: el issue se cerró solo (`state: closed`) y `git cat-file -p "$FIX" | grep -c '^parent'` da `1`: un solo padre, se puede llevar con `cherry-pick` sin `-m`.

---

## Paso 3: `release/0.1` y el `cherry-pick`

**Por qué**: la rama de release nace hoy, cuando hace falta el primer parche, desde el tag. Antes habría sido una rama que nadie mantenía.

```bash
curl -s --request POST "$API/projects/$P/repository/branches" -H "$H" \
  --data-urlencode "branch=release/0.1" --data-urlencode "ref=v0.1.0" \
  | jq '{name, protected, commit: .commit.short_id}'
```

Funciona porque eres Maintainer o más, lo haces por API, y `v0.1.0` apunta a un commit que ya está en `main`, que es una rama protegida. Las tres condiciones de la teoría 05, apartado 2.2.

El parche, en una rama corta desde `release/0.1`:

```bash
git fetch origin
git switch -c "$IID_BUG-parche-0.1" origin/release/0.1
git cherry-pick -x "$FIX"
git log -1 --format='%G? %s'                                   # G fix(<area>): ... (!N)
git log -1 --format=%B | tail -n 3                             # Changelog: fixed y (cherry picked from commit …)
# ejecuta los tests: el arreglo tiene que funcionar sobre el código de la 0.1
```

Si `cherry-pick` da conflicto, el código de la `0.1` ya es distinto del de `main` en esa zona. Resuélvelo, `git add` y `git cherry-pick --continue`: el `-x` se mantiene.

```bash
git push -u origin HEAD -o merge_request.create -o merge_request.target=release/0.1 \
  -o merge_request.title="$(git log -1 --format=%s | sed 's/ (![0-9]*)$//')"

MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
curl -s --request POST "$API/projects/$P/merge_requests/$MR/approve" -H "$HR" > /dev/null
echo "export MR_PARCHE=$MR" >> ~/.bc-gitlab-s08
bash scripts/gobernanza.sh "$MR"
```

La auditoría marca `❌ no cierra ningún issue`, y es un **falso positivo**: GitLab solo asocia issues a cerrar cuando el destino es la rama por defecto (`closes_issues` devuelve `[]` para cualquier otro), y el issue ya lo cerró la merge request de `main`. Lo demás tiene que salir `✅`. El proyecto de la semana corrige el script para que no aplique esa regla fuera de `main`; hasta entonces, la guarda no puede ser `gobernanza.sh`. En `release/*` el hook no exige `Approved-by:`, así que la única puerta es comprobar la aprobación antes de fusionar:

```bash
curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/approvals" | jq -e '.approved_by | length > 0' > /dev/null && {
  SHA=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .sha)
  curl -s --request PUT "$API/projects/$P/merge_requests/$MR/merge" -H "$H" \
    --data-urlencode "sha=$SHA" --data-urlencode "squash=true" | jq -r .state
} || echo "Sin aprobación de revisor: NO fusiono"
```

**Verifica** en la rama de release:

```bash
curl -s -H "$H" "$API/projects/$P/repository/commits?ref_name=release%2F0.1&per_page=3" \
  | jq -r '.[] | .message | select(test("cherry picked from")) | split("\n")[0]'
```

Sale el asunto del parche. El commit de squash de esta merge request contiene el cuerpo entero del commit original, incluido `(cherry picked from commit …)`, porque es el primer commit con cuerpo de la merge request.

---

## Paso 4: El CHANGELOG de la `0.1.1`

**Por qué**: el mismo flujo que el de la `0.1.0`, con dos diferencias: la rama sale de `release/0.1`, y no hace falta `from`, porque ya existe `v0.1.0`.

```bash
RAMA="$IID_BUG-changelog-0.1.1"
curl -s --request POST "$API/projects/$P/repository/branches" -H "$H" \
  --data-urlencode "branch=$RAMA" --data-urlencode "ref=release/0.1" | jq -r .name

curl -s -G -H "$H" "$API/projects/$P/repository/changelog" \
  --data-urlencode "version=0.1.1" --data-urlencode "to=$RAMA" | jq -r .notes      # vista previa

curl -s --request POST "$API/projects/$P/repository/changelog" -H "$H" \
  --data-urlencode "version=0.1.1" --data-urlencode "branch=$RAMA" \
  --data-urlencode "message=docs: changelog de la 0.1.1" -o /dev/null -w '%{http_code}\n'

MR=$(curl -s --request POST "$API/projects/$P/merge_requests" -H "$H" \
  --data-urlencode "source_branch=$RAMA" --data-urlencode "target_branch=release/0.1" \
  --data-urlencode "title=docs: changelog de la 0.1.1" \
  --data-urlencode "description=Relacionado con #$IID_BUG" \
  --data-urlencode "remove_source_branch=true" | jq -r .iid)
curl -s --request POST "$API/projects/$P/merge_requests/$MR/approve" -H "$HR" > /dev/null
curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/approvals" | jq -e '.approved_by | length > 0' > /dev/null && {
  SHA=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .sha)
  curl -s --request PUT "$API/projects/$P/merge_requests/$MR/merge" -H "$H" \
    --data-urlencode "sha=$SHA" --data-urlencode "squash=true" | jq -r .state
} || echo "Sin aprobación de revisor: NO fusiono"
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/repository/files/CHANGELOG.md/raw?ref=release%2F0.1" | grep '^## '
# ## 0.1.1 (<hoy>)
# ## 0.1.0 (<fecha de la práctica 03>)
curl -s -H "$H" "$API/projects/$P/repository/files/CHANGELOG.md/raw?ref=main" | grep '^## '
# ## 0.1.0 (...)
```

`main` no tiene la sección `0.1.1`, y está decidido así en el ADR-006: las secciones de los parches viven en su rama de release.

---

## Paso 5: El tag `v0.1.1`

**Por qué**: el tag del parche va en la punta de `release/0.1`. Si lo pusieras en `main`, la `v0.1.1` llevaría todo lo que haya en `main`.

```bash
git fetch origin
git switch release/0.1 2>/dev/null || git switch -c release/0.1 origin/release/0.1
git pull --ff-only
git log -1 --format='%h %s'
git tag -s v0.1.1 -m "v0.1.1"
git tag -v v0.1.1 2>&1 | grep -c Good           # 1
git push origin v0.1.1
```

**Verifica** que la `v0.1.1` tiene lo que `main` no tiene, y nada más:

```bash
curl -s -H "$H" "$API/projects/$P/repository/compare?from=main&to=v0.1.1" | jq -r '.commits[].title'
```

Solo el parche, el CHANGELOG de la `0.1.1` y, con `rebase_merge`, sus commits de fusión. Si sale cualquier otro commit, algo entró en `release/0.1` que no debía.

---

## Paso 6: La release `v0.1.1`

**Por qué**: quien usa la `0.1.0` se entera del parche por aquí.

```bash
NOTAS=$(curl -s -G -H "$H" "$API/projects/$P/repository/changelog" \
  --data-urlencode "version=0.1.1" --data-urlencode "to=v0.1.1" | jq -r .notes)

curl -s --request POST "$API/projects/$P/releases" -H "$H" \
  --data-urlencode "tag_name=v0.1.1" \
  --data-urlencode "name=v0.1.1" \
  --data-urlencode "description=$NOTAS" \
  --data-urlencode "assets[links][][name]=CHANGELOG.md" \
  --data-urlencode "assets[links][][url]=$GITLAB_URL/$PROYECTO/-/blob/v0.1.1/CHANGELOG.md" \
  | jq '{tag_name, released_at, commit: .commit.title}'
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/releases" | jq -r '.[] | "\(.tag_name)  \(.released_at)"'
curl -s -H "$H" "$API/projects/$P/releases/permalink/latest" | jq -r .tag_name     # v0.1.1
```

Las notas de la `v0.1.1` tienen una sola sección, `Corregido (1 cambio)`, con el asunto del arreglo. Si añadiste la insignia de última versión que propone la teoría 07 de la Semana 04 (`release.svg`), ya muestra `v0.1.1` en la página del proyecto.

---

## ✅ Resultado

- [ ] Issue `tipo::bug` con el fallo reproducido por un test, cerrado por la merge request de `main`
- [ ] `release/0.1` creada desde `v0.1.0`, protegida, con el arreglo traído por `cherry-pick -x`
- [ ] `CHANGELOG.md` de `release/0.1` con las secciones `0.1.1` y `0.1.0`
- [ ] Tag `v0.1.1` firmado en la punta de `release/0.1`, y su release con notas
- [ ] Sabes por qué la auditoría marcó `❌` en la merge request del parche y por qué es un falso positivo

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 08
```

Tras esta práctica, solo deberían faltar `script-de-metricas` y `metricas-documentadas`: son el proyecto. El token de `revisor` **no se revoca todavía**: el proyecto tiene dos merge requests más, y lo revoca en su punto 5.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `You can only use an existing protected branch ref as the basis of a new protected branch` | El `ref` no está en ninguna rama protegida: usaste un SHA de una rama de trabajo | `ref=v0.1.0` |
| `You are not allowed to create protected branches on this project` | Tu rol efectivo no llega a Maintainer | `GET .../members/all/<tu-id>` |
| `cherry-pick` dice `is a merge but no -m option was given` | `FIX` es el commit de fusión: la merge request se fusionó sin squash | Usa el commit del cambio: `git log --no-merges -1 <fix>^2` |
| El commit del `cherry-pick` sale con `N` en vez de `G` | Tu clon no tiene `commit.gpgsign=true` | `git commit --amend -S --no-edit` antes del `push`, y la Semana 02 |
| El `push` del parche falla con `no está firmado` | Lo mismo, y el hook lo detectó | Igual que la fila anterior |
| El `POST` del CHANGELOG da `422` con `no previous tag` | `v0.1.0` no existe o no sigue SemVer | `git ls-remote --tags origin 'v*'` |
| La vista previa de la `0.1.1` sale `Sin cambios.` | El commit de squash del parche perdió el trailer | `git log -1 --format=%B` en `release/0.1`: el último párrafo tiene que ser `Changelog: fixed` y la línea del `cherry-pick` |
| `compare` muestra commits que no son el parche | Se fusionó en `release/0.1` algo que no venía de un `cherry-pick` | Revierte en `release/0.1` por merge request; no publiques hasta que solo quede el parche |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Práctica 03 — La primera versión](03-la-primera-version.md) | **Práctica 04** | [Proyecto](../3-proyecto/README.md) |

# Práctica 02 — Cambios que cuentan

> Cierras dos issues del hito `v0.1.0` con merge requests cuyo commit lleva el trailer `Changelog:`, compruebas que el trailer sobrevive al squash y ves por primera vez el CHANGELOG de la `0.1.0` con contenido.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 01 completada · Teoría [04](../1-teoria/04-changelog-generado.md) leída

---

## Contexto

Las merge requests de las Semanas 06 y 07 no llevaban trailer, así que no aparecerán en el CHANGELOG. Es lo normal el día que se adopta la convención: el CHANGELOG empieza a contar desde que alguien decide qué cuenta.

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | Los dos issues elegidos | — |
| 2-3 | Primer cambio fusionado con `Changelog:` | `tres-cambios-con-changelog` (1 de 3) |
| 4 | Segundo cambio fusionado con `Changelog:` | `tres-cambios-con-changelog` (2 de 3) |
| 5 | Vista previa del CHANGELOG de la `0.1.0` | — |

El tercero llega con el arreglo de la práctica 04.

---

## Paso 0: Preparar el terreno

```bash
source ~/.bc-gitlab
source ~/.bc-gitlab-s08
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
cd /ruta/a/tu/clon/de/app
```

Si abriste una terminal nueva, repite el paso 0 de la práctica 01 para tener `$HR`.

**Verifica**:

```bash
curl -s -H "$HR" "$API/user" | jq -r .username                                     # revisor-<tu-dominio>
curl -s -H "$H" "$API/projects/$P" | jq -r .squash_commit_template | tail -n 1       # %{first_multiline_commit_description}
```

---

## Paso 1: Elegir dos issues del hito

**Por qué**: la `0.1.0` es lo que el hito `v0.1.0` prometía. Lo que no dé tiempo a cerrar pasa a la `0.2.0` en la práctica 03.

```bash
curl -s -H "$H" "$API/projects/$P/issues?milestone=v0.1.0&state=opened&per_page=100" \
  | jq -r '.[] | "#\(.iid)  \(.labels | join(","))  \(.title)"'
```

Elige **dos** que puedas cerrar en unos veinte minutos cada uno, con su test. Al menos uno, `tipo::feature`. Si el hito no tiene dos así, crea un issue pequeño y real en el hito (un caso límite que tu dominio no contempla, una función auxiliar que falta) con la etiqueta de tipo que le corresponda.

```bash
I1=<número del primer issue>
I2=<número del segundo issue>
echo "export I1=$I1 I2=$I2" >> ~/.bc-gitlab-s08
```

Decide ya la categoría de cada uno (teoría [04](../1-teoria/04-changelog-generado.md), apartado 2.1): `added` para una funcionalidad nueva, `fixed` para un arreglo, `changed` para un cambio de comportamiento visible.

**Verifica**: los dos issues están abiertos, en el hito `v0.1.0`, y tienes clara la categoría de cada uno.

---

## Paso 2: El primer cambio, con su trailer

**Por qué**: el trailer va en el **primer commit con cuerpo** de la rama, porque es el que la plantilla de squash copia. La forma más segura es que la merge request tenga un solo commit con cuerpo, y que ese cuerpo sea el trailer.

```bash
git switch main && git pull --ff-only
git switch -c "$I1-<descripcion-corta>"
```

Escribe el test primero, comprueba que falla, y después el código. Con los tests en verde:

```bash
git add -A
git commit -S -m "feat(<area>): <qué hace, en una línea que entienda quien usa app>" -m "Changelog: added"
git log -1 --format='%(trailers:key=Changelog)'      # Changelog: added
```

Si necesitaste más commits para llegar ahí (`test: ...`, `refactor: ...`), que sean **sin cuerpo**: solo `-m` una vez. Así el único commit con cuerpo es el del trailer.

```bash
git push -u origin HEAD \
  -o merge_request.create \
  -o merge_request.target=main \
  -o merge_request.title="feat(<area>): <el mismo asunto>"
```

El título de la merge request es el texto que aparecerá en el CHANGELOG, seguido de la referencia `(!N)`. Léelo como si fueras quien usa `app`.

**Verifica**:

```bash
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
echo "export MR1=$MR" >> ~/.bc-gitlab-s08
curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/closes_issues" | jq -r '.[].iid'   # $I1
git log --format='%h %G? %s' origin/main..HEAD                                          # todos con G
```

---

## Paso 3: Revisión, fusión y el trailer en `main`

**Por qué**: el paso que demuestra que la práctica 01 funcionó. Si el trailer no está en `main` después del squash, el CHANGELOG no lo verá nunca.

```bash
curl -s --request POST "$API/projects/$P/merge_requests/$MR/approve" -H "$HR" | jq -r '.approved_by[].user.username'
bash scripts/gobernanza.sh "$MR" && {
  SHA=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .sha)
  curl -s --request PUT "$API/projects/$P/merge_requests/$MR/merge" -H "$H" \
    --data-urlencode "sha=$SHA" --data-urlencode "squash=true" | jq '{state, squash_commit_sha}'
}
```

**Verifica** en Git y en la API:

```bash
git switch main && git pull --ff-only
git log -3 --format='%h %(trailers:key=Changelog,valueonly,separator=) %s'
curl -s -H "$H" "$API/projects/$P/repository/commits?ref_name=main&trailers=true&per_page=5" \
  | jq -r '.[] | "\(.short_id) \(.trailers.Changelog // "-") \(.title)"'
```

El commit de squash muestra `added`. Míralo entero con `git log -1 --format=%B <sha>`: el título con `(!N)`, `Closes #…`, `Reviewed-by:` y `Approved-by:`, una línea en blanco y `Changelog: added` al final.

Si en lugar de `added` sale `-`, **para**: la plantilla no tiene el marcador, o el commit con el trailer no era el primero con cuerpo. Revisa el paso 3 de la práctica 01 antes de fusionar nada más.

---

## Paso 4: El segundo cambio

**Por qué**: el mismo flujo, ahora sin explicaciones. Si te sale de corrido, el proceso está bien diseñado.

```bash
git switch -c "$I2-<descripcion-corta>"
# test, código, tests en verde
git add -A
git commit -S -m "<tipo>(<area>): <asunto>" -m "Changelog: <categoría>"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="<tipo>(<area>): <asunto>"

MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
echo "export MR2=$MR" >> ~/.bc-gitlab-s08
curl -s --request POST "$API/projects/$P/merge_requests/$MR/approve" -H "$HR" > /dev/null
bash scripts/gobernanza.sh "$MR" && {
  SHA=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .sha)
  curl -s --request PUT "$API/projects/$P/merge_requests/$MR/merge" -H "$H" \
    --data-urlencode "sha=$SHA" --data-urlencode "squash=true" | jq -r .state
}
```

`bash scripts/gobernanza.sh ... && { ... }` solo fusiona si la auditoría pasa: es el comportamiento que tendrá el job de la Semana 09.

**Verifica**: `merged`, y dos commits con trailer en `main`:

```bash
git switch main && git pull --ff-only
git log --format='%(trailers:key=Changelog,valueonly)' | grep -c .     # 2
```

---

## Paso 5: La vista previa de la `0.1.0`

**Por qué**: el `GET` no escribe nada. Es la forma de ver qué saldría antes de comprometerse a publicarlo.

```bash
curl -s -G -H "$H" "$API/projects/$P/repository/changelog" \
  --data-urlencode "version=0.1.0" --data-urlencode "from=$PRIMERO" | jq -r .notes
```

**Verifica**: una cabecera `## 0.1.0 (<hoy>)`, una sección por categoría (`### Añadido (1 cambio)`, por ejemplo), y en cada entrada el título de la merge request con enlace al commit y a la merge request.

Si una entrada se lee mal, aún estás a tiempo: el texto es el asunto del commit de squash, que ya está en `main` y no se puede cambiar. Lo que sí puedes hacer es corregirlo a mano en la merge request del CHANGELOG de la práctica 03, y anotar en la rúbrica por qué.

---

## ✅ Resultado

- [ ] Dos issues del hito `v0.1.0` cerrados por merge request, aprobadas por `revisor`
- [ ] Los dos commits de squash en `main` con su trailer `Changelog:`
- [ ] La vista previa del CHANGELOG de la `0.1.0` muestra las dos entradas en español

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 08
```

`tres-cambios-con-changelog` sigue fallando: el tercero es el arreglo de la práctica 04.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| El commit de squash no lleva `Changelog:` | Otro commit con cuerpo era más antiguo que el del trailer | Para las siguientes: un solo commit con cuerpo. Este cambio ya no saldrá en el CHANGELOG; anótalo en las notas a mano en la práctica 03 |
| `Changelog:` aparece en el mensaje pero `%(trailers)` no lo ve | Hay texto en el mismo párrafo que no es un trailer | Cuerpo del commit solo con trailers; la explicación, en la descripción de la merge request |
| `closes_issues` vacío | La rama no empieza por el número del issue y la plantilla `Default` no puso `Closes #` | Edita la descripción y añade `Closes #<IID>` |
| `gobernanza.sh` da `❌` por dueños | Tocaste `/src/` y `revisor` no aprobó, o tocaste una ruta sin dueño | Que apruebe; si falta una regla en `CODEOWNERS`, es otra merge request |
| La fusión falla con `el asunto no sigue Conventional Commits` | El título de la merge request no es convencional | `PUT .../merge_requests/$MR` con `title=...` y vuelve a fusionar |
| La vista previa muestra `added` en vez de `Añadido` | El YAML no está en `main`, o la clave tiene otro nombre | Práctica 01, paso 4 |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Práctica 01 — GitLab Flow en `app`](01-gitlab-flow-en-app.md) | **Práctica 02** | [Práctica 03 — La primera versión](03-la-primera-version.md) |

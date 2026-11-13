# Práctica 03 — La revisión con otra identidad

> `revisor-<dominio>` lee la merge request de la práctica 02, deja una sugerencia y un hilo que bloquea, y envía la revisión pidiendo cambios. Tú aplicas, corriges y respondes. El revisor resuelve, aprueba, y la merge request entra en `main` con un commit que dice quién la revisó.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 02 completada · Teoría [03](../1-teoria/03-la-revision-en-gitlab.md) y [04](../1-teoria/04-sugerencias-de-codigo.md) leídas

---

## Contexto

Vas a hacer dos papeles con dos tokens. Para no mezclarlos, cada comando dice con cuál va:

| Papel | Variable | Identidad |
|---|---|---|
| **Autor** | `$H` | Tú |
| **Revisor** | `$HR` | `revisor-<dominio>` |

Si un comando del revisor se ejecuta con `$H`, el hilo queda a tu nombre y la aprobación sería tuya: la comprobación `mr-aprobada-por-otro` fallaría, y con razón.

---

## Paso 0: Preparar el terreno y el token del revisor

**Por qué**: `revisor-<dominio>` no tiene contraseña conocida, y no hace falta. Igual que en la práctica 03 de la Semana 03, un token creado por la API de administración te deja actuar como él, con fecha de caducidad.

```bash
source ~/.bc-gitlab
source ~/.bc-gitlab-s06          # IID y MR de la práctica 02

export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)

UID_REV=$(curl -s -H "$H" "$API/users?username=revisor-<tu-dominio>" | jq -r '.[0].id')

T_REV=$(curl -s --request POST "$API/users/$UID_REV/personal_access_tokens" -H "$H" \
  --data-urlencode "name=revision-s06" \
  --data-urlencode "scopes[]=api" \
  --data-urlencode "expires_at=$(date -d '+7 days' +%F)" \
  | jq -r '.token')
[ "$T_REV" != null ] || echo "No se creó el token: revisa permisos de administrador"
export HR="PRIVATE-TOKEN: $T_REV"
```

Si tu `GITLAB_TOKEN` no es de administrador, usa `GITLAB_ADMIN_TOKEN` en la creación, como en la Semana 03.

**Verifica**, sin imprimir nunca el token:

```bash
curl -s -H "$H"  "$API/user" | jq -r .username   # tú
curl -s -H "$HR" "$API/user" | jq -r .username   # revisor-<tu-dominio>
```

---

## Paso 1: El revisor lee el issue antes que el diff

**Por qué**: el orden de la teoría [07](../1-teoria/07-el-oficio-de-revisar.md). Lo primero es saber qué tenía que resolver el cambio.

```bash
# [revisor] Qué issue cierra, y qué pedía
curl -s -H "$HR" "$API/projects/$P/merge_requests/$MR/closes_issues" | jq -r '.[] | "#\(.iid) \(.title)"'
curl -s -H "$HR" "$API/projects/$P/issues/$IID" | jq -r .description

# [revisor] El diff
curl -s -H "$HR" "$API/projects/$P/merge_requests/$MR/diffs?per_page=100" | jq -r '.[] | .new_path, .diff'
```

Lee el diff con el sombrero de revisor. ¿Hay un caso que los dos tests no cubren? (Pista: ¿qué pasa si el libro **se devuelve** en domingo?)

**Verifica**: puedes decir en una frase qué hace `diasCobrables` y qué caso falta.

---

## Paso 2: Las coordenadas del diff

**Por qué**: un comentario sobre una línea necesita decir **en qué versión del diff** está: los tres SHA de `diff_refs` y el número de línea en el archivo nuevo.

```bash
# [revisor]
REFS=$(curl -s -H "$HR" "$API/projects/$P/merge_requests/$MR" | jq -c .diff_refs)
BASE=$(jq -r .base_sha <<<"$REFS"); START=$(jq -r .start_sha <<<"$REFS"); HEAD_SHA=$(jq -r .head_sha <<<"$REFS")

LINEA=$(curl -s -H "$HR" "$API/projects/$P/repository/files/src%2Fprestamos.ts/raw?ref=$HEAD_SHA" \
  | grep -n 'Dias de retraso que se cobran' | cut -d: -f1)
echo "línea $LINEA"
```

**Verifica**: `LINEA` es un número, el de la línea del comentario `/** Dias de retraso que se cobran. */`.

---

## Paso 3: La revisión en borrador

**Por qué**: el revisor escribe todo antes de publicar nada, para que el autor reciba la revisión entera de una vez (teoría [03](../1-teoria/03-la-revision-en-gitlab.md), sección 3). Dos comentarios: una sugerencia que no bloquea y un hilo que sí.

````bash
# [revisor] Sugerencia sobre la línea del comentario
SUGERENCIA=$(cat <<'EOF'
suggestion (non-blocking): el comentario no dice la regla, que es lo único que no se ve leyendo el bucle.

```suggestion
/** Dias de retraso que se cobran: la biblioteca cierra los domingos y ese dia no cuenta. */
```
EOF
)

curl -s --request POST "$API/projects/$P/merge_requests/$MR/draft_notes" -H "$HR" \
  --data-urlencode "note=$SUGERENCIA" \
  --data-urlencode "position[position_type]=text" \
  --data-urlencode "position[base_sha]=$BASE" \
  --data-urlencode "position[start_sha]=$START" \
  --data-urlencode "position[head_sha]=$HEAD_SHA" \
  --data-urlencode "position[new_path]=src/prestamos.ts" \
  --data-urlencode "position[new_line]=$LINEA" \
  | jq '{id, position: .position.new_line}'

# [revisor] Hilo general que bloquea
curl -s --request POST "$API/projects/$P/merge_requests/$MR/draft_notes" -H "$HR" \
  --data-urlencode "note=issue (blocking): falta el caso en que el libro se devuelve en domingo. Vence el viernes 2026-11-06 y vuelve el domingo 2026-11-08: debería cobrarse 1 día (el sábado). Añade ese test." \
  | jq '.id'

# [revisor] Lo que lleva pendiente
curl -s -H "$HR" "$API/projects/$P/merge_requests/$MR/draft_notes" | jq length
````

**Verifica**: el último comando dice `2`. Y desde tu identidad, la merge request **no muestra nada nuevo** todavía:

```bash
curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq .user_notes_count
```

---

## Paso 4: Enviar la revisión

**Por qué**: publicar los dos comentarios a la vez, con un resumen y el veredicto. Además, es lo que hace que `revisor` cuente como `Reviewed-by:` en el commit de squash.

```bash
# [revisor]
curl -s --request POST "$API/projects/$P/merge_requests/$MR/draft_notes/bulk_publish" -H "$HR" \
  --data-urlencode "reviewer_state=requested_changes" \
  --data-urlencode "note=Bien resuelto y bien probado. Falta un caso límite antes de fusionar; la sugerencia es opcional." \
  -o /dev/null -w '%{http_code}\n'
```

**Verifica**, como autor:

```bash
curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/discussions?per_page=100" \
  | jq -r '.[] | select(.notes[0].resolvable) | "\(.notes[0].resolved)\t\(.notes[0].author.username)\t\(.notes[0].body | split("\n")[0])"'

curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .detailed_merge_status
```

Dos hilos sin resolver de `revisor-<tu-dominio>`, y el estado es `discussions_not_resolved`: el ajuste de la práctica 01 está trabajando. En la UI, el revisor aparece con el estado *Requested changes*.

---

## Paso 5: El autor aplica la sugerencia

**Por qué**: la sugerencia es correcta y no hay nada que discutir. Aplicarla es un clic, o una llamada.

```bash
# [autor]
SID=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/discussions?per_page=100" \
  | jq -r '[.[].notes[] | .suggestions[]? | select(.applied | not)] | .[0].id')

curl -s --request PUT "$API/suggestions/$SID/apply" -H "$H" | jq '{id, applied}'
```

GitLab acaba de crear un commit en tu rama. Mira su mensaje:

```bash
curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/commits" | jq -r '.[0].message'
```

**Verifica**: `applied: true`, y el mensaje es `fix: apply 1 review suggestion(s)` seguido de una línea `Co-authored-by:` con el revisor. Es la plantilla de la práctica 01.

---

## Paso 6: El autor corrige lo que bloquea

**Por qué**: el hilo bloqueante pide un test. Antes de tocar nada en local, trae el commit que GitLab acaba de crear, o el siguiente `push` chocará contigo mismo.

```bash
# [autor]
git pull --rebase

cat >> src/prestamos.test.ts <<'EOF'

test("devolver en domingo no cobra el domingo", () => {
  assert.equal(diasCobrables(new Date("2026-11-06"), new Date("2026-11-08")), 1);
});
EOF

npm test
git add src/prestamos.test.ts
git commit -m "test(multas): cover a Sunday return date"
git push
```

Y responde en el hilo, para que el revisor sepa dónde mirar:

```bash
DID=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/discussions?per_page=100" \
  | jq -r '[.[] | select(.notes[0].resolvable and (.notes[0].resolved | not)) | select(.notes[0].body | startswith("issue"))] | .[0].id')

curl -s --request POST "$API/projects/$P/merge_requests/$MR/discussions/$DID/notes" -H "$H" \
  --data-urlencode "body=Hecho en $(git rev-parse --short HEAD). El test falla si se quita el salto del domingo." \
  | jq -r .body
```

**Verifica**: `npm test` en verde y la respuesta publicada. **No resuelvas el hilo**: lo abrió el revisor, lo resuelve él.

---

## Paso 7: El revisor comprueba, resuelve y aprueba

**Por qué**: el revisor solo necesita ver lo que cambió desde su revisión (teoría [03](../1-teoria/03-la-revision-en-gitlab.md), sección 5). Si está bien, resuelve sus hilos y deja su aprobación registrada.

```bash
# [revisor] Versiones del diff: una por cada push
curl -s -H "$HR" "$API/projects/$P/merge_requests/$MR/versions" \
  | jq -r '.[] | "\(.id)\t\(.head_commit_sha[:8])\t\(.created_at)"'
```

Tres versiones: la original, la de la sugerencia y la del test. En la UI, *Changes → Compare* entre la primera y la última enseña solo esas dos diferencias.

```bash
# [revisor] Resolver sus hilos abiertos
for d in $(curl -s -H "$HR" "$API/projects/$P/merge_requests/$MR/discussions?per_page=100" \
             | jq -r '.[] | select(.notes[0].resolvable and (.notes[0].resolved | not)) | .id'); do
  curl -s --request PUT "$API/projects/$P/merge_requests/$MR/discussions/$d" -H "$HR" \
    --data-urlencode "resolved=true" | jq -r '"\(.id[:8]) resuelto: \(.notes[0].resolved)"'
done

# [revisor] Aprobar
curl -s --request POST "$API/projects/$P/merge_requests/$MR/approve" -H "$HR" \
  | jq -r '.approved_by[].user.username'
```

**Verifica**: los hilos resueltos y `revisor-<tu-dominio>` en la lista de aprobaciones. Y como autor, el estado ya es `mergeable`:

```bash
curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .detailed_merge_status
```

---

## Paso 8: Fusionar lo que se revisó

**Por qué**: con `sha`, la fusión falla si alguien empujó después de la aprobación. Con `squash=true`, entra un solo commit con la plantilla de la práctica 01.

```bash
# [autor]
SHA=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .sha)

curl -s --request PUT "$API/projects/$P/merge_requests/$MR/merge" -H "$H" \
  --data-urlencode "sha=$SHA" \
  --data-urlencode "squash=true" \
  --data-urlencode "should_remove_source_branch=true" \
  | jq '{state, merge_commit_sha, squash_commit_sha}'
```

**Verifica**: `state` es `merged`, y `squash_commit_sha` y `merge_commit_sha` tienen valor: con `rebase_merge` y squash entran los dos (teoría [05](../1-teoria/05-estrategias-de-fusion.md), sección 3.1). Con `ff`, `merge_commit_sha` queda a `null`: no hay commit de fusión.

---

## Paso 9: Lo que quedó

**Por qué**: comprobar las tres consecuencias de la fusión: el issue cerrado, la rama borrada y una historia que cuenta quién revisó.

```bash
# El issue
curl -s -H "$H" "$API/projects/$P/issues/$IID" | jq '{state, closed_by: .closed_by.username}'
curl -s -H "$H" "$API/projects/$P/issues/$IID/closed_by" | jq -r '.[] | "!\(.iid) \(.title)"'

# La historia
git switch main && git pull --ff-only
git fetch --prune
git log --graph --oneline -6
git show -s --format=%B HEAD^2
```

**Verifica**:

- El issue está `closed`, y `closed_by` lista tu merge request
- La rama de trabajo ya no existe en `origin`
- Con `rebase_merge`, `git log --graph` muestra la burbuja: el commit de fusión con dos padres. Con `ff`, un solo commit nuevo en línea
- El mensaje del commit de squash (`HEAD^2` con `rebase_merge`, `HEAD` con `ff`) tiene el título con `(!N)`, `Closes #<IID>`, `Reviewed-by:` y `Approved-by:` del revisor

**No revoques todavía el token del revisor**: lo usa la práctica 04.

---

## ✅ Resultado

- [ ] La revisión se escribió en borrador y se publicó de una vez, con veredicto
- [ ] Una sugerencia aplicada, con el revisor como `Co-authored-by:`
- [ ] Un hilo bloqueante que impidió fusionar hasta que el revisor lo resolvió
- [ ] La aprobación es de `revisor-<dominio>`, no tuya
- [ ] La merge request entró con squash, `sha` y la rama borrada
- [ ] El issue se cerró solo y el commit de squash dice quién revisó y quién aprobó

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `draft_notes` con posición devuelve `400` | Algún SHA vacío o `LINEA` vacía | Repetir el paso 2; `echo "$BASE $START $HEAD_SHA $LINEA"` |
| La sugerencia se ve como bloque de código sin botón *Apply* | El comentario no está sobre una línea del diff, o la línea no es la del archivo nuevo | Paso 2: `new_line` sobre la versión `HEAD` |
| `suggestions/:id/apply` devuelve `400` | La línea cambió desde la sugerencia (`appliable: false`) | Pedir al revisor que la vuelva a escribir sobre la versión actual |
| `git push` rechazado tras aplicar la sugerencia | No hiciste `git pull --rebase` | Hacerlo y volver a empujar |
| `approve` devuelve `401` | Se ejecutó con `$H` o el token caducó | `curl -H "$HR" .../user` debe decir `revisor-...` |
| `merge` devuelve `409` | Se empujó algo después de leer el `sha` | Leer el `sha` de nuevo, tras revisar lo nuevo |
| `merge` devuelve otro error | La merge request no está en `mergeable`: hilos abiertos, borrador o rebase pendiente | `detailed_merge_status` dice cuál |
| No hay `Reviewed-by:` en el commit | La revisión no se envió con `bulk_publish`, o la plantilla de squash no tiene `%{reviewed_by}` | Paso 4, y práctica 01, paso 3 |
| `HEAD^2` no existe | El método es `ff`: no hay commit de fusión | `git show -s --format=%B HEAD` |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Práctica 02 — De issue a merge request](02-de-issue-a-merge-request.md) | **Práctica 03** | [Práctica 04 — Historia y conflictos](04-historia-y-conflictos.md) |

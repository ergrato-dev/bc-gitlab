# Práctica 04 — Historia y conflictos

> Dos merge requests abiertas a la vez sobre la misma función. Fusionar la primera rompe la segunda. Vas a ver el bloqueo por API, comprobar que el rebase del servidor no puede con él, resolverlo en local sin perder la firma, y leer la historia que deja todo esto.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 03 completada · Teoría [05](../1-teoria/05-estrategias-de-fusion.md) y [06](../1-teoria/06-las-condiciones-para-fusionar.md) leídas

---

## Contexto

Con una sola merge request abierta, la historia lineal no cuesta nada. El precio aparece cuando hay dos: la segunda queda atrás en cuanto se fusiona la primera, y si las dos tocan las mismas líneas, además chocan.

Los ejemplos usan dos issues de la biblioteca que tocan `puedePrestar`:

| Rama | Issue | Cambio |
|---|---|---|
| **B** | "Un socio con un préstamo vencido puede pedir otro" | Añade una condición: sin préstamos vencidos |
| **C** | "Una multa de céntimos bloquea los préstamos" | Cambia una condición: se tolera una multa pequeña |

Las dos modifican la misma línea de `return`. Con tu dominio, elige dos issues de tu backlog que obliguen a tocar la misma función.

---

## Paso 0: Preparar el terreno

**Por qué**: las variables de siempre, y `$HR` de la práctica 03. Si abriste una terminal nueva, repite el paso 0 de la práctica 03: crea otro token con el mismo nombre, y el paso 9 los revocará todos.

```bash
source ~/.bc-gitlab
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
UID_REV=$(curl -s -H "$H" "$API/users?username=revisor-<tu-dominio>" | jq -r '.[0].id')

cd /ruta/a/tu/clon/de/app
git switch main && git pull --ff-only
```

**Verifica**: `curl -s -H "$HR" "$API/user" | jq -r .username` dice `revisor-<tu-dominio>`.

---

## Paso 1: Los dos issues

**Por qué**: cada merge request nace de un issue. Si tu backlog no tiene dos que toquen la misma función, créalos con su clasificación; es lo que harías en un equipo real.

```bash
curl -s -H "$H" "$API/projects/$P/issues?state=opened&issue_type=issue&per_page=100" \
  | jq -r '.[] | "\(.iid)\t\(.title)"'

export IID_B=9    # préstamo vencido
export IID_C=11   # multa tolerada

for i in "$IID_B" "$IID_C"; do
  curl -s --request PUT "$API/projects/$P/issues/$i" -H "$H" \
    --data-urlencode "add_labels=estado::en-curso" \
    --data-urlencode "remove_labels=estado::preparado" | jq -r '"#\(.iid) \(.title)"'
done
```

**Verifica**: los dos issues existen, están abiertos y en `estado::en-curso`.

---

## Paso 2: Dos ramas desde el mismo `main`

**Por qué**: las dos salen del mismo commit, sin saber nada la una de la otra. Es exactamente lo que pasa cuando dos personas empiezan a la vez.

**Rama B**: un socio con un préstamo vencido no puede llevarse otro.

```bash
git switch -c "$IID_B-prestamo-vencido-bloquea" main

sed -i 's/^  multaPendienteCentimos: number;$/&\n  tienePrestamoVencido?: boolean;/' src/prestamos.ts
sed -i 's/^    && socio.multaPendienteCentimos === 0;$/    \&\& socio.multaPendienteCentimos === 0\n    \&\& !socio.tienePrestamoVencido;/' src/prestamos.ts

cat >> src/prestamos.test.ts <<'EOF'

test("un prestamo vencido impide llevarse otro", () => {
  assert.equal(puedePrestar({ id: "s4", prestamosAbiertos: 0, multaPendienteCentimos: 0, tienePrestamoVencido: true }), false);
});
EOF

git diff --stat && npm test
git commit -am "fix(prestamos): block new loans while one is overdue"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main
```

**Rama C**: una multa de hasta un euro no bloquea.

```bash
git switch -c "$IID_C-multa-tolerada" main

sed -i 's/^export const LIMITE_PRESTAMOS = 3;$/&\n\n\/** Multa pendiente que todavia permite prestar, en centimos. *\/\nexport const MULTA_TOLERADA_CENTIMOS = 100;/' src/prestamos.ts
sed -i 's/^    && socio.multaPendienteCentimos === 0;$/    \&\& socio.multaPendienteCentimos <= MULTA_TOLERADA_CENTIMOS;/' src/prestamos.ts

cat >> src/prestamos.test.ts <<'EOF'

test("una multa de centimos no impide prestar", () => {
  assert.equal(puedePrestar({ id: "s5", prestamosAbiertos: 0, multaPendienteCentimos: 50 }), true);
});
EOF

git diff --stat && npm test
git commit -am "feat(prestamos): tolerate fines up to one euro"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main
```

Si `git diff --stat` sale vacío, el `sed` no encontró la línea: tu `puedePrestar` no es idéntica a la de la Semana 02. Haz el cambio con el editor; lo que importa es que las dos ramas toquen la misma línea.

**Verifica**: dos merge requests abiertas, y `npm test` pasaba en cada rama por separado. El test existente de la multa de 150 céntimos sigue fallando a propósito en C: 150 es más que la tolerancia.

---

## Paso 3: Revisor e issues a revisión

**Por qué**: lo mismo que en la práctica 02, para las dos de golpe.

```bash
MR_B=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$IID_B-prestamo-vencido-bloquea&state=opened" | jq -r '.[0].iid')
MR_C=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$IID_C-multa-tolerada&state=opened" | jq -r '.[0].iid')

for m in "$MR_B" "$MR_C"; do
  curl -s --request PUT "$API/projects/$P/merge_requests/$m" -H "$H" \
    --data-urlencode "reviewer_ids[]=$UID_REV" | jq -r '"!\(.iid) \(.detailed_merge_status) revisor=\(.reviewers[0].username)"'
done

for i in "$IID_B" "$IID_C"; do
  curl -s --request PUT "$API/projects/$P/issues/$i" -H "$H" \
    --data-urlencode "add_labels=estado::en-revision" --data-urlencode "remove_labels=estado::en-curso" -o /dev/null
done
```

Abre las dos en la UI y rellena la plantilla: qué, por qué y cómo se prueba.

**Verifica**: las dos con revisor y en `mergeable` (o `checking`, unos segundos). Cada una, por separado, se podría fusionar.

---

## Paso 4: El revisor revisa y aprueba B, y B entra

**Por qué**: una revisión corta, enviada, para que el revisor cuente en `Reviewed-by:`. Esta vez sin cambios pedidos.

```bash
# [revisor]
curl -s --request POST "$API/projects/$P/merge_requests/$MR_B/draft_notes" -H "$HR" \
  --data-urlencode "note=praise: el campo opcional mantiene válidos los socios que ya existen en los tests." -o /dev/null
curl -s --request POST "$API/projects/$P/merge_requests/$MR_B/draft_notes/bulk_publish" -H "$HR" \
  --data-urlencode "reviewer_state=reviewed" -o /dev/null -w '%{http_code}\n'
curl -s --request POST "$API/projects/$P/merge_requests/$MR_B/approve" -H "$HR" | jq -r '.approved_by[].user.username'

# [autor]
SHA=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR_B" | jq -r .sha)
curl -s --request PUT "$API/projects/$P/merge_requests/$MR_B/merge" -H "$H" \
  --data-urlencode "sha=$SHA" --data-urlencode "squash=true" --data-urlencode "should_remove_source_branch=true" \
  | jq -r .state
```

**Verifica**: `merged`.

---

## Paso 5: Lo que le pasó a C

**Por qué**: C no ha cambiado, pero `main` sí. Antes de mirar la UI, predice qué dirá la API.

```bash
curl -s -H "$H" "$API/projects/$P/merge_requests/$MR_C" | jq '{detailed_merge_status, has_conflicts}'
```

**Verifica**: el estado es `need_rebase`, **no** `conflict`, y `has_conflicts` es `true`.

Es la sorpresa de esta práctica. GitLab ejecuta las comprobaciones en orden y devuelve la primera que falla; en la 19.2.4 (`MergeRequest.all_mergeability_checks`) la de rebase va **antes** que la de conflicto. Con `rebase_merge` o `ff`, una rama atrasada siempre dice `need_rebase`, tenga conflicto o no. Lo que distingue los dos casos es `has_conflicts`.

### 5.1 ¿Puede el servidor?

```bash
curl -s --request PUT "$API/projects/$P/merge_requests/$MR_C/rebase" -H "$H" -o /dev/null -w '%{http_code}\n'
sleep 5
curl -s -H "$H" "$API/projects/$P/merge_requests/$MR_C?include_rebase_in_progress=true" \
  | jq '{rebase_in_progress, merge_error}'
```

**Verifica**: `rebase_in_progress` es `false` y `merge_error` dice que el rebase falló. El servidor no resuelve conflictos: `/rebase` solo sirve cuando `has_conflicts` es `false`.

---

## Paso 6: El rebase en local

**Por qué**: un conflicto es una decisión, y la toma una persona. Además, el rebase en local conserva tu firma en los commits de la rama (teoría [06](../1-teoria/06-las-condiciones-para-fusionar.md), sección 4).

```bash
git switch "$IID_C-multa-tolerada"
git fetch origin
git rebase origin/main
```

Git se para con conflicto en `src/prestamos.ts`, y probablemente también en `src/prestamos.test.ts`, porque las dos ramas añadieron un test al final. Abre los dos.

En `src/prestamos.ts` verás algo así:

```text
  return socio.prestamosAbiertos < LIMITE_PRESTAMOS
<<<<<<< HEAD
    && socio.multaPendienteCentimos === 0
    && !socio.tienePrestamoVencido;
=======
    && socio.multaPendienteCentimos <= MULTA_TOLERADA_CENTIMOS;
>>>>>>> feat(prestamos): tolerate fines up to one euro
```

`HEAD` es `main` con B dentro; lo de abajo es tu commit de C. La resolución correcta **no es elegir uno**: son las dos reglas a la vez.

```ts
  return socio.prestamosAbiertos < LIMITE_PRESTAMOS
    && socio.multaPendienteCentimos <= MULTA_TOLERADA_CENTIMOS
    && !socio.tienePrestamoVencido;
```

En el archivo de tests, quédate con los dos tests y borra las marcas. Después:

```bash
grep -n '<<<<<<<\|>>>>>>>' src/*.ts    # no debe imprimir nada
npm test
git add src/prestamos.ts src/prestamos.test.ts
git rebase --continue
git log --show-signature -1 | head -3
git push --force-with-lease
```

**Verifica**: `npm test` en verde con los tests de B y C juntos, el commit rebasado sigue firmado, y el `push` con `--force-with-lease` se acepta. Si alguien hubiera empujado a la rama mientras tanto, se habría rechazado en vez de borrar su trabajo.

---

## Paso 7: El revisor revisa la resolución, y C entra

**Por qué**: la resolución de un conflicto **es código nuevo**: ni B ni C, tal como se revisaron, contenían esa línea combinada. El revisor tiene que verla.

```bash
# [revisor] Solo lo que cambió desde la versión anterior
curl -s -H "$HR" "$API/projects/$P/merge_requests/$MR_C/versions" | jq length

curl -s --request POST "$API/projects/$P/merge_requests/$MR_C/draft_notes" -H "$HR" \
  --data-urlencode "note=question: la resolución aplica las dos reglas a la vez. ¿Un socio con préstamo vencido y multa de 50 céntimos queda bloqueado? Creo que sí, por el vencido, que es lo que pide el issue #$IID_B." -o /dev/null
curl -s --request POST "$API/projects/$P/merge_requests/$MR_C/draft_notes/bulk_publish" -H "$HR" \
  --data-urlencode "reviewer_state=reviewed" -o /dev/null -w '%{http_code}\n'
```

Como autor, responde al hilo confirmándolo, y como revisor, resuélvelo y aprueba, igual que en el paso 7 de la práctica 03. Después fusiona:

```bash
# [autor]
SHA=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR_C" | jq -r .sha)
curl -s --request PUT "$API/projects/$P/merge_requests/$MR_C/merge" -H "$H" \
  --data-urlencode "sha=$SHA" --data-urlencode "squash=true" --data-urlencode "should_remove_source_branch=true" \
  | jq -r .state
```

**Verifica**: `merged`, y los issues `IID_B` e `IID_C` cerrados.

---

## Paso 8: La historia

**Por qué**: es el resultado visible de la estrategia que elegiste en el ADR-004. Con `rebase_merge`, tres merge requests son tres burbujas; con `ff`, tres commits.

```bash
git switch main && git pull --ff-only && git fetch --prune
git log --graph --oneline -9
git log --no-merges -3 --format='%h %s%n%(trailers:key=Reviewed-by)'
```

**Verifica**:

- Con `rebase_merge`, `git log --graph` muestra tres commits de fusión, cada uno con su commit de squash al lado, en línea: ninguna rama se cruza con otra. Con `ff`, tres commits en línea recta y ningún commit de fusión
- Los tres commits de squash tienen `Reviewed-by:` del revisor
- `git branch -r` ya no lista ninguna de las tres ramas de trabajo

Compara con lo que habría salido con `merge`: B y C habrían salido del mismo commit y la historia tendría dos líneas paralelas que se juntan, con una fusión que nadie probó como tal.

---

## Paso 9: Revocar el token del revisor

**Por qué**: era para estas dos prácticas y ya terminaron. Un token que sobra es un acceso que sobra.

```bash
for id in $(curl -s -H "$H" "$API/personal_access_tokens?user_id=$UID_REV" \
              | jq -r '.[] | select(.name == "revision-s06" and .active) | .id'); do
  curl -s --request DELETE "$API/personal_access_tokens/$id" -H "$H" -o /dev/null -w "revocado $id: %{http_code}\n"
done
unset T_REV HR
rm -f ~/.bc-gitlab-s06
```

**Verifica**: cada revocación responde `204`.

---

## ✅ Resultado

- [ ] Dos merge requests abiertas a la vez, desde el mismo `main`
- [ ] Has visto `need_rebase` con `has_conflicts: true` antes de abrir la UI, y sabes por qué no dice `conflict`
- [ ] Has comprobado que el rebase del servidor no resuelve conflictos
- [ ] Has resuelto el conflicto combinando las dos reglas, no eligiendo una
- [ ] El commit rebasado sigue firmado y el `push` fue con `--force-with-lease`
- [ ] Tres merge requests fusionadas, y la historia que predice tu ADR-004: tres burbujas con `rebase_merge`, tres commits en línea con `ff`
- [ ] El token del revisor está revocado

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 06
```

Con las prácticas 01 a 04 hechas, las 16 comprobaciones deberían pasar.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `has_conflicts` es `false` | Las dos ramas no tocan la misma línea | Repetir el paso 2 comprobando `git diff` en cada una; sin conflicto, `/rebase` lo arregla |
| `npm test` falla tras resolver | Se eligió una de las dos condiciones, o quedó una marca | La resolución lleva las tres condiciones |
| `push` rechazado con *stale info* | Alguien empujó a la rama mientras hacías el rebase | `git fetch`, revisar lo nuevo, y repetir el rebase |
| El commit rebasado sale *Unverified* | El clon no tiene `commit.gpgsign` | `git config commit.gpgsign true` y `git rebase --exec 'git commit --amend --no-edit -S' origin/main` |
| `DELETE` del token devuelve `404` | Ya estaba revocado | Nada que hacer |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Práctica 03 — La revisión con otra identidad](03-la-revision-con-otra-identidad.md) | **Práctica 04** | [Proyecto de la semana](../3-proyecto/README.md) |

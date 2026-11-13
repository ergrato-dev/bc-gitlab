# Práctica 02 — De issue a merge request

> Un bug del backlog recorre el camino entero hasta quedar listo para revisar: rama con su número, commit firmado, merge request en borrador abierta desde la terminal, plantilla aplicada sola, issue en la columna de revisión y revisor asignado.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 01 completada · Teoría [01](../1-teoria/01-la-merge-request-como-unidad-de-cambio.md) leída

---

## Contexto

Vas a resolver un `tipo::bug` de tu backlog. Los ejemplos usan el de la biblioteca, **"La multa cuenta los domingos"**: la biblioteca cierra los domingos, y un libro que vence el sábado y se devuelve el lunes no debería pagar el domingo. Si tu dominio es otro, elige un bug de tu backlog que toque una de las funciones de la Semana 02 y adapta el código; los pasos son los mismos.

Esta práctica termina con la merge request **lista para revisar, sin fusionar**. La revisión y la fusión son la práctica 03.

---

## Paso 0: Preparar el terreno

**Por qué**: las variables de siempre, y el clon al día con la plantilla de la práctica 01.

```bash
source ~/.bc-gitlab

export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)

cd /ruta/a/tu/clon/de/app
git switch main && git pull --ff-only
ls .gitlab/merge_request_templates/
```

**Verifica**: el `ls` muestra `Default.md`.

---

## Paso 1: Elegir el issue

**Por qué**: la merge request nace de un issue, no al revés. Si no hay issue, el cambio no estaba planificado, y lo primero es escribirlo.

```bash
curl -s -H "$H" "$API/projects/$P/issues?state=opened&issue_type=issue&labels=tipo::bug&per_page=100" \
  | jq -r '.[] | "\(.iid)\t\([.labels[] | select(startswith("estado::"))] | join(","))\t\(.title)"'
```

Elige uno y guarda su número:

```bash
export IID=7   # el tuyo
curl -s -H "$H" "$API/projects/$P/issues/$IID" | jq -r '.title, "", .description'
```

**Verifica**: has leído los criterios de aceptación del issue. Son lo que el revisor va a comprobar, así que son lo que tu cambio tiene que cumplir.

---

## Paso 2: La rama, con el número delante

**Por qué**: una rama que empieza por `<número>-` hace que GitLab añada `Closes #<número>` a la merge request y copie las etiquetas y el hito del issue (teoría [01](../1-teoria/01-la-merge-request-como-unidad-de-cambio.md), sección 4.1). Es la trazabilidad gratis.

```bash
git switch -c "$IID-la-multa-cuenta-los-domingos"
```

Y el issue pasa a la columna de trabajo del tablero de la Semana 05:

```bash
curl -s --request PUT "$API/projects/$P/issues/$IID" -H "$H" \
  --data-urlencode "add_labels=estado::en-curso" \
  --data-urlencode "remove_labels=estado::preparado" \
  | jq -r '[.labels[] | select(startswith("estado::"))] | join(",")'
```

**Verifica**: `git branch --show-current` empieza por el número del issue, y la salida de la API es `estado::en-curso`.

---

## Paso 3: El cambio, con su test

**Por qué**: el test primero, y fallando. Es la prueba de que el test detecta el bug; si pasara sin el cambio, no probaría nada (teoría [07](../1-teoria/07-el-oficio-de-revisar.md), sección 2).

```bash
cat >> src/prestamos.test.ts <<'EOF'

import { diasCobrables } from "./prestamos.ts";

test("el domingo no se cobra: vence el sabado y vuelve el lunes", () => {
  assert.equal(diasCobrables(new Date("2026-11-07"), new Date("2026-11-09")), 1);
});

test("devolver a tiempo no cobra ningun dia", () => {
  assert.equal(diasCobrables(new Date("2026-11-07"), new Date("2026-11-07")), 0);
});
EOF

npm test   # falla: diasCobrables no existe
```

Ahora la función:

```bash
cat >> src/prestamos.ts <<'EOF'

/** Dias de retraso que se cobran. */
export function diasCobrables(vencimiento: Date, devolucion: Date): number {
  let dias = 0;
  const dia = new Date(vencimiento);
  while (dia < devolucion) {
    dia.setUTCDate(dia.getUTCDate() + 1);
    if (dia.getUTCDay() !== 0) dias++;
  }
  return dias;
}
EOF

npm test
```

El comentario de la función es deliberadamente pobre: el revisor tendrá algo que sugerir en la práctica 03.

**Verifica**: `npm test` en verde, con los dos tests nuevos entre los que pasan.

---

## Paso 4: Commit firmado y push que abre la merge request

**Por qué**: las *push options* abren la merge request en el mismo `push`, en borrador, con la plantilla `Default` aplicada y el `Closes` añadido, sin abrir el navegador.

```bash
git add src/prestamos.ts src/prestamos.test.ts
git commit -m "fix(multas): do not charge late fees on Sundays"
git log --show-signature -1 | head -3

git push -u origin HEAD \
  -o merge_request.create \
  -o merge_request.target=main \
  -o merge_request.draft
```

**Verifica**: el `git log` muestra la firma válida, y la salida del `push` incluye un bloque `remote:` con *View merge request for ...* y un enlace.

---

## Paso 5: Lo que GitLab rellenó solo

**Por qué**: para comprobar que la trazabilidad funciona sin que hayas escrito nada. Si falta el `Closes`, la fusión no cerrará el issue, y es mejor saberlo ahora que después.

```bash
export MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" \
  | jq -r '.[0].iid')
echo "MR !$MR"

curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" \
  | jq '{title, draft, labels, milestone: .milestone.title, assignee: .assignees[0].username}'

curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .description | tail -3
curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/closes_issues" | jq -r '.[].iid'
```

**Verifica**:

- `title` empieza por `Draft:` y `draft` es `true`
- `labels` y `milestone` son los del issue
- `assignee` eres tú, por el `/assign me` de la plantilla; si sale `null`, asígnatela desde la barra lateral
- La descripción tiene las secciones de la plantilla y termina en `Closes #<IID>`
- `closes_issues` devuelve tu `IID`

Abre la merge request en el navegador y **rellena las secciones de la plantilla**: qué cambia, por qué, y cómo se prueba (`npm test` y el nombre de los dos tests). No borres la línea `Closes`.

---

## Paso 6: El revisor

**Por qué**: el revisor es `revisor-<dominio>`, la identidad con Maintainer en `app` que creaste en la Semana 03 precisamente para esto. En CE, uno solo.

```bash
UID_REV=$(curl -s -H "$H" "$API/users?username=revisor-<tu-dominio>" | jq -r '.[0].id')

curl -s --request PUT "$API/projects/$P/merge_requests/$MR" -H "$H" \
  --data-urlencode "reviewer_ids[]=$UID_REV" \
  | jq -r '.reviewers[].username'
```

**Verifica**: imprime `revisor-<tu-dominio>`.

---

## Paso 7: Leer tu propio diff

**Por qué**: es la última casilla de la plantilla y la que más se salta. El primer revisor de una merge request es su autor, y lo que tú encuentres ahora no le cuesta una ronda a nadie.

En la pestaña *Changes*, lee el diff entero como si fuera de otro, siguiendo el orden de la teoría [07](../1-teoria/07-el-oficio-de-revisar.md): ¿resuelve el issue?, ¿es correcto?, ¿está probado?

Mide el tamaño:

```bash
curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/diffs?per_page=100" \
  | jq '[.[].diff | split("\n")[] | select(test("^[+-]"))] | length'
```

**Verifica**: menos de cincuenta líneas, y marcas en la descripción las casillas que de verdad has comprobado.

---

## Paso 8: Fuera de borrador y a revisión

**Por qué**: hasta ahora era trabajo en curso. Al sacarla de borrador le dices al revisor que puede empezar, y el issue pasa a la columna `estado::en-revision`.

```bash
TITULO=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .title | sed 's/^Draft: *//')
curl -s --request PUT "$API/projects/$P/merge_requests/$MR" -H "$H" \
  --data-urlencode "title=$TITULO" | jq '{title, draft}'

curl -s --request PUT "$API/projects/$P/issues/$IID" -H "$H" \
  --data-urlencode "add_labels=estado::en-revision" \
  --data-urlencode "remove_labels=estado::en-curso" \
  | jq -r '[.labels[] | select(startswith("estado::"))] | join(",")'
```

En la UI es el botón *Mark as ready*, o `/ready` en un comentario.

**Verifica**: `draft` es `false`, y el issue está en `estado::en-revision`.

---

## Paso 9: Lista, pero no fusionada

**Por qué**: comprobar que nada técnico impide fusionar, y **no hacerlo**. Que se pueda fusionar no significa que se deba: falta la revisión.

```bash
curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .detailed_merge_status
```

**Verifica**: `mergeable`. Si sale `checking`, repite en unos segundos.

Guarda `IID` y `MR` para la práctica 03:

```bash
echo "export IID=$IID MR=$MR" > ~/.bc-gitlab-s06
```

---

## ✅ Resultado

- [ ] El issue estaba en el backlog antes que la rama
- [ ] La rama empieza por el número del issue
- [ ] El test falló antes del cambio y pasa después
- [ ] La merge request se abrió con el `push`, en borrador, con la plantilla y el `Closes`
- [ ] `revisor-<dominio>` es el revisor
- [ ] El issue está en `estado::en-revision` y la merge request en `mergeable`, sin fusionar

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| El `push` no muestra el enlace a la merge request | Las *push options* no llegaron: Git anterior a 2.10, o un alias de `push` que las pierde | `git --version`, y escribir el comando completo |
| La descripción está vacía | `Default.md` no está en `main` | Práctica 01, paso 4 |
| No aparece `Closes #N` | La rama no empieza por `<número>-` | Escribirlo a mano en la descripción |
| `closes_issues` vacío con `Closes #N` escrito | El número no es de un issue de este proyecto, o está dentro de un comentario `<!-- -->` | Fuera del comentario, con el número correcto |
| `reviewer_ids` no asigna a nadie | El usuario no es miembro de `app` | Comprobar sus membresías de la Semana 03 |
| `detailed_merge_status` es `draft_status` | El título sigue empezando por `Draft:` | Paso 8 |
| `npm test` no falla antes del cambio | El test no prueba el bug | Revisar las fechas: tiene que haber un domingo entre las dos |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Práctica 01 — El proyecto preparado para revisar](01-el-proyecto-preparado-para-revisar.md) | **Práctica 02** | [Práctica 03 — La revisión con otra identidad](03-la-revision-con-otra-identidad.md) |

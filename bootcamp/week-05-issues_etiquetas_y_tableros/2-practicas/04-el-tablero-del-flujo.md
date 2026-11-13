# Práctica 04 — El tablero del flujo

> Un tablero con tres columnas de `estado::`, un issue llevado de punta a punta, y la prueba de que el tablero solo dice la verdad mientras las etiquetas la digan.

**Duración estimada**: 50 min
**Prerrequisitos**: Prácticas 01 a 03 completadas · Teoría [05](../1-teoria/05-tableros.md) leída

---

## Contexto

Ya tienes la taxonomía, el backlog, el hito y las plantillas. Falta la vista que el equipo abre cada mañana: el tablero.

La idea central de esta práctica es una sola, y se comprueba varias veces: **el tablero no guarda nada**. Sus columnas son etiquetas, y mover una tarjeta es cambiar una etiqueta. Si lo entiendes, sabes predecir qué pasa en cada movimiento; si no, el tablero hace cosas "raras".

---

## Paso 0: Preparar el terreno

**Por qué**: las variables de siempre.

```bash
source ~/.bc-gitlab

export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
```

**Verifica**: `curl -s -H "$H" "$API/projects/$P" | jq -r '.path_with_namespace'`.

---

## Paso 1: ¿Cuántos tableros hay ya?

**Por qué**: abrir `Plan → Issue boards` en la UI **crea un tablero por defecto** si no hay ninguno. Si en alguna semana anterior entraste ahí, ya tienes uno. Crear otro por API dejaría dos, y `/board_move` deja de estar disponible con más de un tablero (teoría [05](../1-teoria/05-tableros.md), sección 3).

```bash
curl -s -H "$H" "$API/projects/$P/boards" \
  | jq -r '.[] | "\(.id)\t\(.name)\t\([.lists[].label.name] | join(", "))"'
```

**Verifica**, y decide:

| Si la salida tiene… | Haz |
|---|---|
| Ninguna línea | Sigue al paso 2: lo creas tú |
| Una línea | Exporta su `id` como `BID` y salta al paso 3 |
| Dos o más | Borra los que sobren (paso 2, al final) y quédate con uno |

---

## Paso 2: Crear el tablero (o quedarse con uno)

**Por qué**: un tablero con nombre que dice qué muestra. "Development", el nombre por defecto, no dice nada.

**Si no había ninguno**, créalo:

```bash
export BID=$(curl -s --request POST "$API/projects/$P/boards" -H "$H" \
  --data-urlencode "name=Flujo" | jq -r '.id')
echo "$BID"
```

**Si había uno**, aprovéchalo y renómbralo:

```bash
export BID=<id-del-paso-1>
curl -s --request PUT "$API/projects/$P/boards/$BID" -H "$H" \
  --data-urlencode "name=Flujo" | jq -r '.name'
```

**Si había varios**, borra los que sobran. Un tablero no tiene datos propios —las etiquetas de los issues no se tocan—, así que borrarlo no pierde nada:

```bash
curl -s --request DELETE "$API/projects/$P/boards/<id-que-sobra>" -H "$H" -o /dev/null -w '%{http_code}\n'
# 204
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/boards" | jq 'length == 1'
# true
```

---

## Paso 3: Las columnas, en el orden del flujo

**Por qué**: las columnas de etiqueta van de izquierda a derecha en el orden en que el trabajo avanza. `estado::bloqueado` no es una etapa del flujo, así que **no** es columna: un issue bloqueado lleva esa etiqueta además de la de su etapa, y se ve por el color.

**Con la UI**: `Plan → Issue boards → Flujo → New list → Label`, y elige `estado::preparado`. Repite con `estado::en-curso` y `estado::en-revision`.

**Con la API**:

```bash
for nombre in "estado::preparado" "estado::en-curso" "estado::en-revision"; do
  lid=$(curl -s -H "$H" "$API/projects/$P/labels?search=$nombre&per_page=100" \
        | jq -r --arg n "$nombre" '.[] | select(.name == $n) | .id')
  curl -s --request POST "$API/projects/$P/boards/$BID/lists" -H "$H" \
    --data-urlencode "label_id=$lid" | jq -r '"\(.position)\t\(.label.name // .message)"'
done
```

```
0	estado::preparado
1	estado::en-curso
2	estado::en-revision
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/boards/$BID" \
  | jq -r '"Open → \([.lists[].label.name] | join(" → ")) → Closed"'
# Open → estado::preparado → estado::en-curso → estado::en-revision → Closed
```

Open y Closed no salen en `lists`: no son listas de etiqueta, se ocultan con `hide_backlog_list` y `hide_closed_list`.

---

## Paso 4: Predecir antes de mover

**Por qué**: la mejor forma de comprobar que entiendes el tablero es predecir el resultado de cada movimiento **antes** de hacerlo. Rellena la columna "Predicción" en papel y luego compruébala.

Elige un issue del hito que esté en `estado::preparado` (los creados con la plantilla `Bug` lo están). Apunta su `iid`.

| Movimiento | Predicción: etiquetas `estado::` y estado del issue |
|---|---|
| `estado::preparado` → `estado::en-curso` | |
| `estado::en-curso` → `estado::en-revision` | |
| `estado::en-revision` → Closed | |
| Closed → `estado::en-curso` | |

Ahora haz los cuatro movimientos **arrastrando la tarjeta en la UI**, y después de cada uno:

```bash
estado() {
  curl -s -H "$H" "$API/projects/$P/issues/$1" \
    | jq -r '"\(.state)\t\([.labels[] | select(startswith("estado::"))] | join(","))"'
}
estado <iid>
```

**Verifica**: tus cuatro predicciones coinciden con la salida. La última es la que más sorprende: arrastrar desde Closed **reabre** el issue.

---

## Paso 5: Mover sin abrir el tablero

**Por qué**: el tablero se mantiene al día cuando moverlo cuesta poco. `/board_move` mueve la tarjeta desde el comentario donde ya estás explicando qué has hecho.

En el mismo issue, que ahora está en `estado::en-curso`, comenta:

```
Hecho en local, pendiente de revisión.

/board_move ~"estado::en-revision"
```

**Verifica**:

```bash
estado <iid>
# opened	estado::en-revision
```

Si la línea `/board_move` se quedó en el comentario como texto, el proyecto tiene más de un tablero: vuelve al paso 1.

---

## Paso 6: Romper el tablero con una etiqueta

**Por qué**: para ver con tus ojos qué pasa cuando alguien cambia el estado **sin** el tablero, con un `/label` descuidado. Es el error que hace que un tablero deje de ser creíble.

En un issue de `estado::preparado`, comenta:

```
/label ~"estado::en-curso"
```

Abre el tablero. El issue aparece **en dos columnas** a la vez.

Ahora la comprobación por API, la misma que usa el autograding:

```bash
curl -s -H "$H" "$API/projects/$P/issues?issue_type=issue&state=opened&per_page=100" \
  | jq -r '.[] | select([.labels[] | select(startswith("estado::"))] | length > 1)
           | "#\(.iid)\t\([.labels[] | select(startswith("estado::"))] | join(","))"'
# #9	estado::en-curso,estado::preparado
```

Arréglalo con `/board_move`, que quita todas las etiquetas de columna y pone una:

```
/board_move ~"estado::en-curso"
```

**Verifica**: la comprobación vuelve a no imprimir nada, y la tarjeta está en una sola columna.

---

## Paso 7: Un límite WIP a mano

**Por qué**: el límite de trabajo en curso es Premium. La idea, no: si hay más de tres cosas empezadas, no se empieza otra. Se comprueba con una línea.

```bash
curl -s -H "$H" "$API/projects/$P/issues?state=opened&labels=estado::en-curso&per_page=100" \
  | jq '{en_curso: length, dentro_del_limite: (length <= 3)}'
```

Y un vistazo al tablero entero sin abrirlo:

```bash
curl -s -H "$H" "$API/projects/$P/labels?with_counts=true&per_page=100" \
  | jq -r '.[] | select(.name | startswith("estado::")) | "\(.open_issues_count)\t\(.name)"'
```

**Verifica**: sabes cuántos issues hay en cada columna y si `estado::en-curso` respeta el límite.

---

## Paso 8: Dejar el tablero como punto de partida

**Por qué**: el tablero es lo que abrirás al empezar cada sesión de trabajo durante la fase de colaboración. Tiene que reflejar el estado real, y tiene que ser fácil de encontrar.

1. Coloca los issues del hito en su columna real. Lo normal ahora: casi todos en `estado::preparado`, uno en `estado::en-curso` como mucho.
2. Los issues fuera del hito pueden quedarse en Open: no están preparados, y está bien que no lo estén.
3. Filtra el tablero por el hito `v0.1.0` en su barra de búsqueda, copia la URL que queda en el navegador —el filtro viaja en ella— y enlázala desde la portada de la wiki como "Tablero de v0.1.0".

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/boards" \
  | jq 'map(select([.lists[] | select(.label.name | startswith("estado::"))] | length >= 3)) | length > 0'
# true
```

---

## ✅ Resultado

- [ ] `app` tiene un solo tablero, llamado con un nombre que dice algo
- [ ] Sus columnas son `estado::preparado`, `estado::en-curso` y `estado::en-revision`, en ese orden
- [ ] Has predicho y comprobado cuatro movimientos, incluido el que reabre un issue
- [ ] Has movido una tarjeta con `/board_move`
- [ ] Has visto un issue en dos columnas, lo has detectado por API y lo has arreglado
- [ ] Sabes si tu columna `estado::en-curso` respeta un límite de tres

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 05
```

Esta práctica cubre dos comprobaciones: el tablero de estados y la exclusividad de `estado::`.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `/board_move` no aparece en el autocompletado | El proyecto tiene dos o más tableros | Paso 1 y paso 2: dejar uno |
| `/board_move` dice *label was not found* | La etiqueta no es columna de ningún tablero | Añadirla como lista (paso 3) |
| `POST .../lists` devuelve `400` | `label_id` de una etiqueta que no existe o mal copiado | Repetir la búsqueda de `lid` y comprobar que no sale vacío |
| La columna se crea pero sale al final | Las listas se crean en orden de llamada | `PUT .../lists/:list_id` con `position` |
| `tablero-de-estados` falla con el tablero bien en la UI | Hay dos tableros y el bueno tiene menos de tres columnas `estado::` | Revisar `GET /projects/:id/boards` |
| Un issue aparece en dos columnas | Lleva dos `estado::` | `/board_move` a la columna correcta |
| Arrastrar a Closed no cierra | Es la lista Open, no la Closed | Closed está a la derecha del todo; si no se ve, `hide_closed_list` está a `true` |
| `ningun-estado-doble` falla | Un `/label ~"estado::..."` sin quitar el anterior | La comprobación del paso 6 dice cuál |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Práctica 03 — Plantillas y acciones rápidas](03-plantillas-y-acciones-rapidas.md) | **Práctica 04** | [Proyecto de la semana](../3-proyecto/README.md) |

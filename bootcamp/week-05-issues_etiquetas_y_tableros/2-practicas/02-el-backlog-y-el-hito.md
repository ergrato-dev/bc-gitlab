# Práctica 02 — El backlog y el hito

> Doce a quince problemas reales de tu dominio, escritos como datos, creados de una vez y planificados contra una fecha. Y la exclusividad comprobada antes de que nadie la rompa.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 01 completada · Teorías [01](../1-teoria/01-el-issue-como-unidad-de-trabajo.md) y [04](../1-teoria/04-hitos.md) leídas

---

## Contexto

Con la taxonomía en pie, toca el contenido: el trabajo de `app` para las próximas semanas. No es un ejercicio de relleno. Estos issues son los que vas a resolver con merge requests en la Semana 06, los que vas a proteger en la Semana 07 y los que cerrarán la versión `v0.1.0` en la Semana 08.

Por eso importa que sean **problemas reales de tu dominio**, y no "issue de prueba 1" a "issue de prueba 15".

---

## Paso 0: Preparar el terreno

**Por qué**: las mismas variables que en la práctica 01.

```bash
source ~/.bc-gitlab

export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
```

**Verifica**: `curl -s -H "$H" "$API/projects/$P" | jq -r '.path_with_namespace'` devuelve tu proyecto.

---

## Paso 1: Inventario de issues existentes

**Por qué**: en semanas anteriores pudiste crear algún issue de prueba. Un issue sin `tipo::` hará fallar la comprobación de exclusividad, así que hay que saber qué hay antes de empezar.

```bash
curl -s -H "$H" "$API/projects/$P/issues_statistics" | jq '.statistics.counts'

curl -s -H "$H" "$API/projects/$P/issues?state=opened&issue_type=issue&per_page=100" \
  | jq -r '.[] | "#\(.iid)\t\(.labels | join(","))\t\(.title)"'
```

**Verifica**: sabes qué es cada issue abierto. Los que sean de prueba, ciérralos con un comentario que lo diga:

```bash
curl -s --request POST "$API/projects/$P/issues/<iid>/notes" -H "$H" \
  --data-urlencode "body=Issue de prueba, sin trabajo asociado.
/close" | jq -r '.id'
```

---

## Paso 2: Crear el hito `v0.1.0`

**Por qué**: el hito va antes que los issues para poder asignarlos al crearlos. Y lleva fecha desde el principio: un hito sin `due_date` no aparece en los filtros por fecha y no compromete a nada.

La fecha razonable es el final de la Semana 08, cuando publicarás `v0.1.0`: unas tres semanas desde hoy.

**Con la UI**: `app → Plan → Milestones → New milestone`.

**Con la API**:

```bash
curl -s --request POST "$API/projects/$P/milestones" -H "$H" \
  --data-urlencode "title=v0.1.0" \
  --data-urlencode "description=Primera versión publicable. Las funciones del núcleo, con tests y documentadas." \
  --data-urlencode "start_date=$(date +%F)" \
  --data-urlencode "due_date=$(date -d '+21 days' +%F)" \
  | jq '{id, title, start_date, due_date}'
```

En macOS, `date -v+21d +%F` en vez de `date -d '+21 days' +%F`.

**Verifica**:

```bash
export MID=$(curl -s -H "$H" "$API/projects/$P/milestones?title=v0.1.0" | jq -r '.[0].id')
curl -s -H "$H" "$API/projects/$P/milestones/$MID" | jq '{title, due_date, state}'
# { "title": "v0.1.0", "due_date": "2026-12-04", "state": "active" }
```

`MID` es el `id` global del hito, que es el que usan las rutas de la API (teoría [04](../1-teoria/04-hitos.md), sección 4).

---

## Paso 3: Escribir el backlog en papel

**Por qué**: un backlog escrito directamente en el formulario sale con títulos-solución ("Añadir validación"). Uno pensado antes sale con títulos-problema. Veinte minutos aquí ahorran reescribir la mitad después.

Para cada issue, cinco datos:

| Dato | Regla |
|---|---|
| Título | El comportamiento observable, no la solución |
| `tipo::` | Exactamente uno |
| `prioridad::` | Uno |
| `area::` | Uno o dos |
| ¿Entra en `v0.1.0`? | Solo lo que de verdad cabe en tres semanas: entre cinco y ocho |

Mezcla tipos: unos cuantos `bug` sobre las funciones que ya existen (Semana 02), varias `feature` nuevas, algún `mantenimiento` y algún `docs`. Un backlog solo de features no es creíble.

**Verifica**: lees tus títulos sin abrir nada y cada uno dice qué falla o qué falta.

---

## Paso 4: Pasar el backlog a datos

**Por qué**: como con las etiquetas, los datos se revisan de un vistazo y se crean de una vez. Y el archivo queda como registro de cómo se planificó.

El ejemplo es del dominio biblioteca. **Sustitúyelo por el tuyo**: títulos, áreas y descripciones.

```bash
cat > /tmp/backlog.json <<'EOF'
[
 {"t":"La multa se calcula sobre días naturales en vez de hábiles","l":"tipo::bug,prioridad::alta,area::multas","h":true,
  "d":"## Qué pasa\ncalcularMulta() cuenta sábados y domingos.\n\n## Criterios de aceptación\n- Un préstamo devuelto el lunes tras vencer el viernes suma 1 día\n- Hay un test que lo cubre"},
 {"t":"Un socio con un préstamo vencido puede pedir otro","l":"tipo::bug,prioridad::alta,area::prestamos","h":true,
  "d":"## Qué pasa\npuedePrestar() solo mira cuántos préstamos activos hay.\n\n## Criterios de aceptación\n- puedePrestar() devuelve false si algún préstamo está vencido"},
 {"t":"estaDisponible devuelve true para un libro dado de baja","l":"tipo::bug,prioridad::media,area::catalogo","h":true,
  "d":"## Criterios de aceptación\n- Un libro con baja=true nunca está disponible"},
 {"t":"No hay forma de renovar un préstamo","l":"tipo::feature,prioridad::alta,area::prestamos","h":true,
  "d":"## Problema\nEl socio tiene que devolver y volver a pedir.\n\n## Criterios de aceptación\n- renovar(prestamo) amplía 14 días si no hay reservas"},
 {"t":"La multa no tiene tope y puede superar el precio del libro","l":"tipo::feature,prioridad::media,area::multas","h":true,
  "d":"## Criterios de aceptación\n- calcularMulta() nunca devuelve más que el precio del libro"},
 {"t":"El README no explica cómo ejecutar un solo test","l":"tipo::docs,prioridad::baja","h":true,
  "d":"## Criterios de aceptación\n- El README tiene el comando para un archivo de test concreto"},
 {"t":"Las reservas no existen: un libro prestado no se puede apartar","l":"tipo::feature,prioridad::media,area::prestamos","h":false,
  "d":"## Problema\nQuien llega segundo tiene que volver a mirar cada día."},
 {"t":"Un socio no puede consultar su historial de préstamos","l":"tipo::feature,prioridad::baja,area::prestamos","h":false,"d":""},
 {"t":"La tarifa de multa está escrita en el código","l":"tipo::mantenimiento,prioridad::media,area::multas","h":false,
  "d":"## Problema\nCambiar la tarifa obliga a publicar una versión."},
 {"t":"Las fechas se comparan como texto en vez de como fechas","l":"tipo::bug,prioridad::media,area::prestamos","h":false,"d":""},
 {"t":"Las dependencias de desarrollo no están fijadas a versión exacta","l":"tipo::mantenimiento,prioridad::baja","h":false,"d":""},
 {"t":"La búsqueda del catálogo distingue mayúsculas","l":"tipo::bug,prioridad::baja,area::catalogo","h":false,"d":""},
 {"t":"No hay glosario de términos del dominio en la wiki","l":"tipo::docs,prioridad::baja","h":false,"d":""}
]
EOF
```

`t` es el título, `l` las etiquetas separadas por comas, `h` si entra en el hito y `d` la descripción con `\n` para los saltos de línea.

**Verifica** que el JSON es válido y que cada issue tiene exactamente un `tipo::`:

```bash
jq 'length' /tmp/backlog.json
# 13
jq -r '.[] | select((.l | split(",") | map(select(startswith("tipo::"))) | length) != 1) | .t' /tmp/backlog.json
# (sin salida)
```

---

## Paso 5: Crear los issues

**Por qué**: con un bucle, en vez de trece formularios. El orden de creación es el orden de los `iid`, así que los del hito van primero y tendrán los números bajos.

```bash
jq -c '.[]' /tmp/backlog.json | while read -r issue; do
  titulo=$(jq -r '.t' <<< "$issue")
  etiquetas=$(jq -r '.l' <<< "$issue")
  descripcion=$(jq -r '.d' <<< "$issue")
  extra=()
  [ "$(jq -r '.h' <<< "$issue")" = "true" ] && extra=(--data-urlencode "milestone_id=$MID")

  curl -s --request POST "$API/projects/$P/issues" -H "$H" \
    --data-urlencode "title=$titulo" \
    --data-urlencode "labels=$etiquetas" \
    --data-urlencode "description=$descripcion" \
    "${extra[@]}" \
    | jq -r '"#\(.iid)\t\(.milestone.title // "-")\t\(.title)"'
done
```

El array `extra` añade `milestone_id` solo a los issues del hito. Funciona igual en `bash` y en `zsh`; el atajo `${var:+...}` no, porque `zsh` no parte en palabras el resultado y `curl` recibiría un único argumento con un espacio dentro.

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/issues?issue_type=issue&state=all&per_page=100" | jq length
# 13   (o más, si tenías alguno de antes)
```

---

## Paso 6: Revisar el hito

**Por qué**: el hito es un compromiso. Antes de darlo por bueno, mira si lo que hay dentro cabe en la fecha y si falta algo.

```bash
curl -s -H "$H" "$API/projects/$P/issues?milestone=v0.1.0&state=all&per_page=100" \
  | jq -r '.[] | "#\(.iid)\t\([.labels[] | select(startswith("prioridad::"))][0])\t\(.title)"'
```

Si quieres sacar uno, desde un comentario del issue: `/remove_milestone`. Para meter otro: `/milestone %"v0.1.0"`.

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/issues?milestone=v0.1.0&issue_type=issue&state=all&per_page=100" \
  | jq 'length >= 5'
# true
```

---

## Paso 7: Romper la exclusividad a propósito

**Por qué**: en CE nada impide que un issue tenga dos `prioridad::`. Es mejor verlo pasar una vez, de forma controlada, que descubrirlo en un filtro que devuelve lo que no debe.

Primero, la comprobación con el backlog sano:

```bash
comprobar() {
  curl -s -H "$H" "$API/projects/$P/issues?issue_type=issue&state=opened&per_page=100" \
    | jq -r '.[] | select(
        ([.labels[] | select(startswith("tipo::"))] | length) != 1 or
        ([.labels[] | select(startswith("prioridad::"))] | length) > 1)
      | "#\(.iid)\t\(.labels | join(","))"'
}
comprobar
# (sin salida)
```

Ahora rómpela. `add_labels` **añade** sin quitar nada, igual que `/label`:

```bash
IID=$(curl -s -H "$H" "$API/projects/$P/issues?labels=prioridad::alta&state=opened" | jq -r '.[0].iid')

curl -s --request PUT "$API/projects/$P/issues/$IID" -H "$H" \
  --data-urlencode "add_labels=prioridad::baja" | jq -r '.labels | join(",")'

comprobar
# #1	area::multas,prioridad::alta,prioridad::baja,tipo::bug
```

Y arréglala como se arregla de verdad, quitando la que sobra:

```bash
curl -s --request PUT "$API/projects/$P/issues/$IID" -H "$H" \
  --data-urlencode "remove_labels=prioridad::baja" | jq -r '.labels | join(",")'
```

**Verifica**: `comprobar` vuelve a no imprimir nada.

---

## Paso 8: Leer el backlog

**Por qué**: un backlog se consulta mucho más de lo que se escribe. Estas son las cuatro preguntas que harás cada semana, y cada una es una llamada.

```bash
# ¿Cuánto hay?
curl -s -H "$H" "$API/projects/$P/issues_statistics" | jq '.statistics.counts'

# ¿Qué está sin triar? (sin ninguna etiqueta)
curl -s -H "$H" "$API/projects/$P/issues?labels=None&state=opened" | jq length

# ¿Qué está sin planificar?
curl -s -H "$H" "$API/projects/$P/issues?milestone_id=None&state=opened&issue_type=issue" | jq length

# ¿Qué hago ahora? El primero por prioridad de etiqueta
curl -s -H "$H" "$API/projects/$P/issues?state=opened&order_by=label_priority&sort=asc&per_page=1" \
  | jq -r '.[0] | "#\(.iid) \(.title)"'
```

**Verifica**: la última llamada devuelve un issue con `prioridad::alta`. Si no, revisa la priorización de la práctica 01, paso 6.

---

## ✅ Resultado

- [ ] Existe el hito `v0.1.0` con fecha de inicio y de vencimiento
- [ ] El backlog tiene entre 12 y 15 issues de tu dominio, con títulos-problema
- [ ] Entre cinco y ocho están en el hito
- [ ] Cada issue abierto tiene exactamente un `tipo::` y como mucho una `prioridad::`
- [ ] Has roto la exclusividad a propósito, la has visto en la comprobación y la has arreglado
- [ ] Sabes contestar por API "cuánto hay", "qué está sin triar", "qué está sin planificar" y "qué hago ahora"

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 05
```

Esta práctica cubre seis comprobaciones: el hito, su fecha, el tamaño del backlog, los issues del hito y la exclusividad de `tipo::` y `prioridad::`.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| Los issues se crean sin hito | `MID` vacío: se abrió otra terminal después del paso 2 | Volver a exportar `MID` y asignar con `/milestone %"v0.1.0"` |
| `400` *milestone_id is invalid* | Se pasó el `iid` del hito en vez del `id` | `MID` sale de `.[0].id`, no de `.[0].iid` |
| `jq: parse error` en el paso 4 | Comillas sin escapar o salto de línea real dentro de `d` | Saltos como `\n`; comillas dobles como `\"` |
| `cada-issue-abierto-un-tipo` falla | Un issue de semanas anteriores sin `tipo::` | La función `comprobar` del paso 7 dice cuál |
| La comprobación falla con un issue que no ves en el listado | Es una tarea hija o un incidente sin tipo | Filtrar con `issue_type=issue`, como el autograding |
| `order_by=label_priority` no pone primero la alta | Las etiquetas no están priorizadas en `app` | Práctica 01, paso 6 |
| `date: invalid date '+21 days'` | `date` de BSD (macOS) | `date -v+21d +%F` |
| Se crearon los issues dos veces | El bucle se ejecutó dos veces | Cerrar los duplicados con `/duplicate #N` desde el más nuevo |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Práctica 01 — La taxonomía de etiquetas](01-la-taxonomia-de-etiquetas.md) | **Práctica 02** | [Práctica 03 — Plantillas y acciones rápidas](03-plantillas-y-acciones-rapidas.md) |

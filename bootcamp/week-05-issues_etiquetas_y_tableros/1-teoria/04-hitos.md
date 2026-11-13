# Hitos

> Una etiqueta dice qué es un issue. Un hito dice para cuándo. Son preguntas distintas y por eso son campos distintos.

## 🎯 Objetivos

- Explicar qué responde un hito que no responde una etiqueta
- Elegir entre hito de proyecto y hito de grupo
- Crear un hito con fechas, asignarle issues y leer su progreso por API
- Filtrar issues por hito, incluidos los comodines `None`, `Upcoming` y `Started`
- Decir qué son epics, iteraciones y burndown, en qué tier están y con qué se sustituyen en CE

---

## 1. Qué problema resuelve

"¿Qué entra en la próxima versión?" es una pregunta que se hace cada semana y que, sin hitos, se contesta en una reunión. Con una etiqueta `v0.1.0` parece que se resuelve, pero no: una etiqueta no tiene fecha, no tiene progreso, y nada impide que un issue tenga `v0.1.0` y `v0.2.0` a la vez.

Un **hito** (*milestone*) es un contenedor con fechas. Un issue pertenece **a uno solo**, y el hito sabe cuántos de sus issues están cerrados. Eso convierte "¿qué entra?" y "¿cómo vamos?" en una consulta.

---

## 2. Cómo funciona

### 2.1 Qué tiene un hito

| Campo | Qué es | Obligatorio |
|---|---|:--:|
| `title` | El nombre. En este bootcamp, la versión: `v0.1.0` | ✅ |
| `description` | El objetivo del hito en una o dos frases | — |
| `start_date` | Cuándo empieza | — |
| `due_date` | Cuándo se entrega | — |
| `state` | `active` o `closed` | Automático |

El progreso no se guarda: se calcula a partir de los issues asignados, cerrados frente a totales. La página del hito lo muestra como porcentaje, con las listas *Unstarted*, *Ongoing* y *Completed*.

> [!NOTE]
> Sin `due_date` el hito no aparece en los comodines por fecha (`Upcoming`, `Started`) ni ordena bien en los listados. Un hito sin fecha es una etiqueta con otro nombre. El autograding de esta semana comprueba que `v0.1.0` la tenga.

### 2.2 Un issue, un hito

Es la diferencia fundamental con las etiquetas. Asignar un issue a `v0.2.0` lo saca de `v0.1.0` automáticamente. No hay que vigilar la exclusividad: la da el modelo de datos.

### 2.3 Proyecto o grupo

| Hito de… | Contiene issues de… | Cuándo usarlo |
|---|---|---|
| **Proyecto** | Ese proyecto | Una versión de un componente: `v0.1.0` de `app` |
| **Grupo** | Todos los proyectos del grupo y subgrupos | Una entrega coordinada entre `app` e `infra` |

Los dos son **Free**. En este bootcamp el hito de la Semana 05 es de **proyecto**, porque `v0.1.0` es la versión de `app` que publicarás en la Semana 08, y cada proyecto versiona por su cuenta. Los hitos de grupo tienen sentido cuando hay una fecha común que cruza proyectos, y a ti todavía no te pasa.

Un proyecto ve también los hitos de sus grupos padre. Para listarlos juntos:

```bash
curl -s -H "$H" "$API/projects/$P/milestones?include_ancestors=true" \
  | jq -r '.[] | "\(.title)\t\(.due_date // "sin fecha")"'
```

---

## 3. Lo que es de pago

Varias herramientas de planificación conocidas viven por encima de CE. Ninguna es imprescindible, y todas tienen un sustituto razonable con lo que ya tienes:

| Feature | Tier | Qué hace | Sustituto en CE |
|---|---|---|---|
| **Epics** | Premium | Agrupa issues de varios proyectos bajo un objetivo, con jerarquía | Un hito de grupo, o una etiqueta `area::` |
| **Iteraciones** y cadencias | Premium | Sprints automáticos de duración fija | Un hito por sprint, con `start_date` y `due_date` |
| **Gráfico de burndown / burnup** | Premium | Evolución diaria del trabajo pendiente del hito | El porcentaje del hito y, en la Semana 08, métricas propias por API |
| **Roadmap** | Premium | Epics e hitos en una línea temporal | La lista de hitos ordenada por fecha |
| **Peso** (*weight*) | Premium | Tamaño relativo de cada issue | Estimación de tiempo, Free (teoría [07](07-acciones-rapidas-y-cierre-automatico.md)) |

> [!TIP]
> Si te encuentras echando de menos el burndown, pregúntate qué decisión tomarías con él. Casi siempre la respuesta es "quitar issues del hito". Para esa decisión basta con el porcentaje y la fecha.

---

## 4. Cómo se configura

**Con la UI**: `Plan → Milestones → New milestone`.

**Con la API**:

```bash
source ~/.bc-gitlab
H="PRIVATE-TOKEN: $GITLAB_TOKEN"; API="$GITLAB_URL/api/v4"
P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)

curl -s --request POST "$API/projects/$P/milestones" -H "$H" \
  --data-urlencode "title=v0.1.0" \
  --data-urlencode "description=Primera versión publicable: cálculo de multas y disponibilidad" \
  --data-urlencode "start_date=$(date +%F)" \
  --data-urlencode "due_date=$(date -d '+21 days' +%F)" \
  | jq '{id, iid, title, start_date, due_date, state}'
```

Como pasa con los issues, el hito tiene `id` (global) e `iid` (dentro del proyecto). Las rutas de la API usan el **`id`**: `GET /projects/:id/milestones/:milestone_id`. Es una inconsistencia con los issues, y es habitual equivocarse.

Asignar un issue al hito, por `id`:

```bash
MID=$(curl -s -H "$H" "$API/projects/$P/milestones?title=v0.1.0" | jq -r '.[0].id')

curl -s --request PUT "$API/projects/$P/issues/7" -H "$H" \
  --data-urlencode "milestone_id=$MID" | jq '{iid, milestone: .milestone.title}'
```

O desde un comentario del issue: `/milestone %"v0.1.0"`.

### 4.1 Leer el progreso

```bash
curl -s -H "$H" "$API/projects/$P/milestones/$MID/issues?per_page=100" \
  | jq '{total: length, cerrados: map(select(.state == "closed")) | length}'
```

```json
{ "total": 6, "cerrados": 1 }
```

### 4.2 Filtrar por hito

El listado de issues acepta el título del hito en `milestone`, y cuatro comodines en `milestone_id`:

| Filtro | Devuelve |
|---|---|
| `milestone=v0.1.0` | Los issues de ese hito |
| `milestone_id=None` | Los que no tienen hito: el backlog sin planificar |
| `milestone_id=Any` | Los que tienen alguno |
| `milestone_id=Started` | Los de hitos cuya `start_date` ya pasó y no están cerrados |
| `milestone_id=Upcoming` | Los del próximo hito por fecha |

```bash
# ¿Qué hay abierto sin planificar?
curl -s -H "$H" "$API/projects/$P/issues?state=opened&issue_type=issue&milestone_id=None" | jq length
```

`milestone` y `milestone_id` son mutuamente excluyentes: la API rechaza la petición si llegan los dos.

### 4.3 Cerrar un hito

Cuando se publica la versión, el hito se cierra. Los issues que quedaron abiertos **no se mueven solos**: hay que decidir a dónde van.

```bash
# Primero: lo que queda abierto
curl -s -H "$H" "$API/projects/$P/issues?state=opened&milestone=v0.1.0" | jq -r '.[] | "#\(.iid) \(.title)"'

# Después, una vez movidos
curl -s --request PUT "$API/projects/$P/milestones/$MID" -H "$H" \
  --data-urlencode "state_event=close" | jq '.state'
```

---

## 5. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Etiqueta `v0.1.0` en vez de hito | Sin fecha, sin progreso, sin exclusividad | Hito |
| Hito sin `due_date` | No ordena, no aparece en `Upcoming` | Fecha siempre, aunque se mueva |
| Meter todo el backlog en el hito | El porcentaje no baja nunca y deja de informar | Solo lo que se compromete; el resto, `milestone_id=None` |
| Hito "Backlog" o "Algún día" | Es lo mismo que no tener hito, con un nombre | Sin hito |
| Mover la fecha cada semana sin quitar issues | El hito miente sobre el plan | Quitar alcance antes que mover fecha |
| Cerrar el hito con issues abiertos dentro | Quedan en un hito cerrado, invisibles | Moverlos antes de cerrar |
| Hito de grupo para una versión de un solo proyecto | Mezcla versiones de componentes distintos | Hito de proyecto |

---

## 6. Trucos

- **Referencia en Markdown**: `%"v0.1.0"` en un comentario enlaza al hito.
- **Las merge requests también van al hito**: `GET /projects/:id/milestones/:milestone_id/merge_requests`. En la Semana 06 el hito pasa a contar issues y MRs.
- **El hito alimenta las releases**: en la Semana 08, al crear la release `v0.1.0` la asociarás a este hito, y la página de la release enlazará a sus issues.
- **Ordenar el listado por fecha del hito**: `order_by=milestone_due` en `GET /projects/:id/issues`.

---

## 📚 Recursos Adicionales

- [Hitos](https://docs.gitlab.com/ee/user/project/milestones/) — proyecto y grupo, progreso, cierre
- [API de hitos de proyecto](https://docs.gitlab.com/ee/api/milestones.html) — `include_ancestors`, `state_event`, issues del hito
- [Iteraciones](https://docs.gitlab.com/ee/user/group/iterations/) — marcado como Premium, para saber qué se sustituye

---

## ✅ Checklist de Verificación

- [ ] Sabes por qué un hito no es una etiqueta con fecha
- [ ] Has creado `v0.1.0` con `start_date` y `due_date`
- [ ] Sabes cuándo una ruta de la API usa `id` y cuándo `iid`
- [ ] Puedes listar los issues sin hito con un comodín
- [ ] Sabes qué hacer con los issues abiertos antes de cerrar un hito

---

[← Anterior: Etiquetas priorizadas y exclusividad](03-etiquetas-priorizadas-y-exclusividad.md) · [Volver a la Semana 05](../README.md) · [Siguiente: Tableros →](05-tableros.md)

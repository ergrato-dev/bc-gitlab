# Práctica 03 — Plantillas y acciones rápidas

> Que el issue nazca bien clasificado sin que nadie se acuerde, y que se actualice y se cierre desde donde ya estás escribiendo: el comentario y el commit.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 02 completada · Teorías [06](../1-teoria/06-plantillas-de-descripcion.md) y [07](../1-teoria/07-acciones-rapidas-y-cierre-automatico.md) leídas · Clon local de `app` al día

---

## Contexto

Las prácticas 01 y 02 dejaron el backlog bien hecho **una vez**. Esta práctica se ocupa de que siga bien hecho cuando lo toquen otros, o tú con prisa:

- **Plantillas** que ponen las preguntas y las etiquetas en el formulario.
- **Acciones rápidas** para cambiar etiqueta, hito, estimación y vínculos sin salir del comentario.
- **Patrones de cierre** para que el issue se cierre con el commit que lo resuelve.

Las plantillas son archivos del repositorio, así que esta práctica sí lleva commits. Todavía directos a `main`: a partir de la Semana 06, por merge request.

---

## Paso 0: Preparar el terreno

**Por qué**: las variables de la API, y el clon local actualizado, porque vas a empujar.

```bash
source ~/.bc-gitlab

export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)

cd /ruta/a/tu/clon/de/app
git switch main && git pull --ff-only
```

**Verifica**: `git status` dice *up to date* y sin cambios pendientes. Y que la firma sigue activa (Semana 02):

```bash
git config --get commit.gpgsign
# true
```

---

## Paso 1: Comprobar que no hay plantillas

**Por qué**: saber de dónde partes. Y ver la respuesta vacía de la API, para reconocerla cuando una plantilla "no sale".

```bash
curl -s -H "$H" "$API/projects/$P/templates/issues" | jq .
# []
```

**Verifica**: un array vacío. Si ya hay plantillas, léelas antes de seguir: `jq -r '.[].key'`.

---

## Paso 2: Escribir las tres plantillas

**Por qué**: `Bug` y `Feature` cubren los dos tipos con preguntas distintas. `Default` atrapa todo lo demás, y es la que se preselecciona sola.

```bash
mkdir -p .gitlab/issue_templates
```

`.gitlab/issue_templates/Bug.md`:

```markdown
<!-- Título: el comportamiento observable, no la solución.
     "La multa cuenta los domingos", no "Arreglar multas". -->

## Qué pasa

<!-- Qué hiciste, qué esperabas y qué obtuviste. -->

## Cómo reproducirlo

1.
2.

## Qué debería pasar

## Versión

<!-- Salida de `git describe --tags --always`. -->

## Criterios de aceptación

- [ ] El caso de "Cómo reproducirlo" da el resultado de "Qué debería pasar"
- [ ] Hay un test que falla sin el arreglo y pasa con él

/label ~"tipo::bug" ~"estado::preparado"
```

`.gitlab/issue_templates/Feature.md`:

```markdown
<!-- Título: el problema de quien lo usa, no la funcionalidad.
     "No se puede renovar un préstamo", no "Añadir renovación". -->

## Problema

<!-- Quién lo sufre y en qué situación. -->

## Cómo sabremos que está resuelto

- [ ]
- [ ]

## Fuera de alcance

<!-- Lo que alguien podría esperar y no entra. -->

/label ~"tipo::feature" ~"estado::preparado"
```

`.gitlab/issue_templates/Default.md`:

```markdown
<!-- ¿Es un fallo o algo nuevo? Usa la plantilla Bug o Feature.
     Esta es para lo demás: mantenimiento, documentación, dudas. -->

## Qué y por qué

## Criterios de aceptación

- [ ]
```

`Default.md` **no** lleva ninguna acción rápida de `tipo::`. Todo issue que alguien abra con prisa sin elegir plantilla pasará por ella, y clasificarlo es trabajo del triaje (teoría [06](../1-teoria/06-plantillas-de-descripcion.md), sección 3.2).

**Verifica** que las etiquetas que citan existen exactamente con ese nombre:

```bash
G=$(printf '%s' "${PROYECTO%%/*}" | jq -sRr @uri)
for e in $(grep -ho '~"[^"]*"' .gitlab/issue_templates/*.md | tr -d '~"' | sort -u); do
  curl -s -H "$H" "$API/groups/$G/labels?per_page=100" \
    | jq -e --arg n "$e" 'any(.[]; .name == $n)' >/dev/null && echo "ok  $e" || echo "FALTA $e"
done
```

---

## Paso 3: Publicarlas en la rama por defecto

**Por qué**: GitLab lee las plantillas **solo de la rama por defecto**. En una rama de trabajo no existen para el formulario.

```bash
git add .gitlab/issue_templates
git commit -m "docs: add bug, feature and default issue templates"
git push origin main
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/templates/issues" | jq -r '.[].key'
# Bug
# Default
# Feature
```

---

## Paso 4: Crear un issue con la plantilla `Bug`

**Por qué**: comprobar que la plantilla hace lo que promete: preguntas en el formulario y etiquetas puestas al crear.

**Con la UI**: `app → Plan → Issues → New issue`. El desplegable *Description* ya muestra **Default** seleccionada. Cámbiala a **Bug**, rellena un fallo real de tu dominio que no esté en el backlog, y crea el issue.

**Con la API**, la misma mecánica: la descripción con acciones rápidas se ejecuta al crear.

```bash
plantilla=$(curl -s -H "$H" "$API/projects/$P/templates/issues/Bug" | jq -r '.content')

curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=La búsqueda del catálogo ignora los acentos" \
  --data-urlencode "description=$plantilla" \
  | jq '{iid, labels}'
```

**Verifica**: el issue nace con `tipo::bug` y `estado::preparado`, y la descripción **no** contiene la línea `/label`:

```bash
curl -s -H "$H" "$API/projects/$P/issues/<iid>" | jq '{labels, quedo_la_accion: (.description | contains("/label"))}'
# { "labels": ["estado::preparado", "tipo::bug"], "quedo_la_accion": false }
```

Le falta la `prioridad::`, y es correcto: la prioridad la decide quien tría, no quien informa.

---

## Paso 5: Una lista de tareas que se pueda seguir

**Por qué**: un issue del hito con varios pasos se sigue mejor con casillas. GitLab cuenta las marcadas y lo muestra en el listado.

Elige un issue del hito con más de un paso —en el ejemplo, "No hay forma de renovar un préstamo"— y añade a su descripción:

```markdown
## Tareas

- [ ] Función `renovar(prestamo)` con la regla de 14 días
- [ ] Rechazar la renovación si hay una reserva
- [ ] Tests de los dos casos
- [ ] Documentar en el README
```

Por la UI, edita la descripción (`e` en la página del issue). Por la API:

```bash
IID=<iid-del-issue>
actual=$(curl -s -H "$H" "$API/projects/$P/issues/$IID" | jq -r '.description')

curl -s --request PUT "$API/projects/$P/issues/$IID" -H "$H" \
  --data-urlencode "description=$actual

## Tareas

- [ ] Función renovar(prestamo) con la regla de 14 días
- [ ] Rechazar la renovación si hay una reserva
- [ ] Tests de los dos casos
- [ ] Documentar en el README" | jq '.task_completion_status'
```

Marca la primera casilla con un clic en la UI.

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/issues/$IID" | jq '.task_completion_status'
# { "count": 4, "completed_count": 1 }
```

---

## Paso 6: Estimar desde un comentario

**Por qué**: el peso es Premium; la estimación de tiempo es Free y la usarás en la Semana 08 para comparar lo previsto con lo invertido. Y es la ocasión de usar varias acciones rápidas en un solo comentario.

En el mismo issue, deja este comentario:

```
Lo empiezo esta semana. La regla de reservas depende de #<iid-de-reservas>.

/estimate 4h
/relate #<iid-de-reservas>
/assign me
```

Por la API, el comentario es una nota:

```bash
curl -s --request POST "$API/projects/$P/issues/$IID/notes" -H "$H" \
  --data-urlencode "body=Lo empiezo esta semana. La regla de reservas depende de #7.

/estimate 4h
/relate #7
/assign me" | jq -r '.body'
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/issues/$IID" \
  | jq '{estimado: .time_stats.human_time_estimate, asignado: .assignee.username}'
# { "estimado": "4h", "asignado": "root" }

curl -s -H "$H" "$API/projects/$P/issues/$IID/links" | jq -r '.[] | "#\(.iid) \(.link_type)"'
# #7 relates_to
```

Prueba también `/weight 3` en otro comentario. Verás que la línea **se queda** en el texto publicado: en CE no existe, y no da error.

---

## Paso 7: Cambiar una prioridad sin romper la familia

**Por qué**: es el error de exclusividad más habitual, y se evita con dos líneas en vez de una.

En un issue de `prioridad::media` que haya subido de urgencia:

```
Un socio lo ha sufrido hoy en el mostrador.

/unlabel ~"prioridad::media"
/label ~"prioridad::alta"
```

**Verifica** que tiene una sola:

```bash
curl -s -H "$H" "$API/projects/$P/issues/<iid>" \
  | jq '[.labels[] | select(startswith("prioridad::"))]'
# ["prioridad::alta"]
```

---

## Paso 8: Cerrar un issue desde un commit

**Por qué**: es la forma correcta de cerrar trabajo de código: el issue se cierra **porque** el cambio llegó a `main`, y queda enlazado al commit que lo resolvió.

Elige el issue de documentación del hito —en el ejemplo, "El README no explica cómo ejecutar un solo test"—, haz el cambio de verdad en el `README.md` y confírmalo con el patrón de cierre **en inglés**:

```bash
$EDITOR README.md      # añade el comando para ejecutar un archivo de test concreto

git add README.md
git commit -m "docs: explain how to run a single test file

Closes #<iid>"
git push origin main
```

> [!WARNING]
> `Cierra #<iid>` no cierra nada. El patrón por defecto de GitLab solo reconoce `Close`, `Fix`, `Resolve` e `Implement` y sus variantes en inglés (teoría [07](../1-teoria/07-acciones-rapidas-y-cierre-automatico.md), sección 3.1).

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/issues/<iid>" \
  | jq '{state, closed_by: .closed_by.username, closed_at}'
# { "state": "closed", "closed_by": "root", "closed_at": "2026-11-13T..." }
```

En la página del issue, la nota de sistema dice *closed via commit* con el SHA enlazado.

---

## ✅ Resultado

- [ ] `Bug.md`, `Feature.md` y `Default.md` en `.gitlab/issue_templates/` de `main`
- [ ] Un issue creado con `Bug` nació con `tipo::bug` y `estado::preparado`
- [ ] Un issue del hito tiene lista de tareas con una casilla marcada
- [ ] Ese issue tiene estimación, asignado y un vínculo `relates_to`, puestos con un solo comentario
- [ ] Has visto que `/weight` no hace nada en CE
- [ ] Un issue se cerró solo con `Closes #N` en un commit de `main`

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 05
```

Esta práctica cubre cuatro comprobaciones: las plantillas, la lista de tareas, la estimación y el issue cerrado.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `templates/issues` devuelve `[]` tras el push | La carpeta está mal escrita o el push fue a otra rama | `.gitlab/issue_templates/` exacta, en `main` |
| El issue nace sin etiquetas | El nombre de la etiqueta en la plantilla no existe | El bucle del paso 2 dice cuál falta |
| La línea `/label` aparece en la descripción publicada | Espacios antes de la `/`, o sin permiso para etiquetar | La acción tiene que empezar en la columna 1 |
| `task_completion_status.count` es 0 | Las casillas no están en formato de lista | `- [ ] texto`, con espacio dentro de los corchetes |
| `/estimate 4` no estima nada | Falta la unidad | `4h` |
| El issue sigue abierto tras el push | Verbo en español, o el commit no llegó a `main` | `git log origin/main --oneline -1` y el mensaje con `Closes` |
| Sigue abierto con `Closes` y en `main` | El proyecto tiene el cierre automático desactivado | `GET /projects/:id \| jq .autoclose_referenced_issues` |
| El commit aparece como *Unverified* | La firma de la Semana 02 no está configurada en este clon | `git config commit.gpgsign true` y la clave SSH de la Semana 02 |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Práctica 02 — El backlog y el hito](02-el-backlog-y-el-hito.md) | **Práctica 03** | [Práctica 04 — El tablero del flujo](04-el-tablero-del-flujo.md) |

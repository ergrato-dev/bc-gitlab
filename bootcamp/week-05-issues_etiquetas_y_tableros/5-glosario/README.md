# 📖 Glosario — Semana 05

Términos que aparecen esta semana. El nombre real de la feature va en inglés entre paréntesis, y el **tier** cuando aplica.

El glosario acumulado de toda la plataforma está en [glosario-global](../../../docs/glosario-global.md).

---

## A

**Acción rápida** (*quick action*) — Free, salvo las marcadas. Línea que empieza por `/` en un comentario, una descripción o una plantilla, y que cambia el issue al guardar: `/label`, `/milestone`, `/estimate`, `/close`. La línea desaparece del texto publicado.

**Área** — Convención de este bootcamp. Familia de etiquetas `area::` que dice qué parte del producto toca un issue. No es exclusiva y vive en el proyecto, no en el grupo.

## B

**Backlog** — El conjunto de issues abiertos pendientes de hacer. En GitLab no es un objeto: es una consulta sobre los issues.

**Burndown** (*burndown chart*) — **Premium**. Gráfico de la evolución diaria del trabajo pendiente de un hito. Sustituto en CE: el porcentaje del hito y su fecha.

## C

**Cierre automático** (*automatic issue closing*) — Free. Un commit o una merge request con `Closes #N` cierra el issue N cuando llega a la rama por defecto. Solo reconoce verbos en inglés: `Close`, `Fix`, `Resolve`, `Implement` y sus variantes.

**Criterio de aceptación** — Frase de un issue que se responde con sí o no y que tiene que ser cierta para cerrarlo.

## E

**Epic** — **Premium**. Agrupación de issues de varios proyectos bajo un objetivo, con jerarquía. Sustituto en CE: un hito de grupo o una etiqueta `area::`.

**Estimación de tiempo** (*time estimate*) — Free. Duración prevista de un issue, con `/estimate 3h`. En la API, en segundos dentro de `time_stats`. En este bootcamp sustituye al peso.

**Etiqueta** (*label*) — Free. Marca con nombre, color y descripción que se pone en issues y merge requests. Vive en un grupo (y se hereda) o en un proyecto.

**Etiqueta con ámbito** (*scoped label*) — **Premium**. Etiqueta con `::` en el nombre que GitLab trata como exclusiva dentro de su ámbito: poner `prioridad::baja` quita `prioridad::alta`. En CE, `::` es un carácter más del nombre y no hay exclusividad.

**Etiqueta priorizada** (*prioritized label*) — Free. Etiqueta marcada con estrella en un proyecto, con un orden. Ordena los listados por *Label priority*. Es del proyecto, aunque la etiqueta sea del grupo; en la API solo se puede priorizar una etiqueta del propio proyecto.

## F

**Familia de etiquetas** — Convención de este bootcamp. Conjunto de etiquetas con el mismo prefijo que contestan una sola pregunta: `tipo::`, `prioridad::`, `estado::`, `area::`.

## H

**Hito** (*milestone*) — Free. Contenedor con fechas al que pertenece un issue, uno solo. Calcula su progreso a partir de los issues cerrados. Existe en proyecto y en grupo.

## I

**`iid`** — Número de un issue o de un hito **dentro de su proyecto** (`#7`). Las rutas de la API de issues usan el `iid`; las de hitos usan el `id` global.

**Issue** — Free. Unidad de trabajo de GitLab: título, descripción, etiquetas, hito, asignado. En GitLab 19 es un *work item* de tipo `issue`.

**Iteración** (*iteration*) — **Premium**. Periodo de trabajo de duración fija, con cadencia automática. Sustituto en CE: un hito con fechas cortas.

## L

**Límite WIP** (*work in progress limit*) — **Premium** en el tablero. Número máximo de tarjetas en una columna. Sustituto en CE: una comprobación por API del número de issues con `estado::en-curso`.

**Lista de tablero** (*board list*) — Free para listas de etiqueta. Columna de un tablero. Las listas de asignado, hito e iteración son **Premium**.

**Lista de tareas** (*task list*) — Free. Casillas `- [ ]` en la descripción de un issue, interactivas. La API las cuenta en `task_completion_status`.

## P

**Patrón de cierre** (*issue closing pattern*) — La expresión regular que decide qué frases cierran un issue. Configurable para toda la instancia en `gitlab.rb` con `gitlab_rails['gitlab_issue_closing_pattern']`.

**Peso** (*weight*) — **Premium**. Tamaño relativo de un issue. En CE el campo no existe en la API y `/weight` no hace nada. Sustituto: la estimación de tiempo.

**Plantilla de descripción** (*description template*) — Free a nivel de proyecto, en `.gitlab/issue_templates/` de la rama por defecto. Las plantillas de grupo e instancia, y el ajuste de plantilla por defecto del proyecto, son **Premium**. La plantilla llamada `Default` se preselecciona sola, y eso es Free.

**Promover una etiqueta** (*promote label*) — Free. Convertir una etiqueta de proyecto en etiqueta del grupo padre, conservando sus usos.

## R

**Referencia cruzada** (*cross-reference*) — Free. Nota de sistema que GitLab deja en un issue cuando se le menciona (`#7`) desde un commit, una merge request u otro issue.

## T

**Tablero** (*issue board*) — Free. Vista de issues en columnas definidas por etiquetas. No guarda estado: mover una tarjeta es cambiar una etiqueta. En CE, varios por proyecto y uno por grupo.

**Tarea** (*task*) — Free. *Work item* hijo de un issue, con su propio asignado y estado. Alternativa a la lista de casillas cuando cada paso necesita discusión propia.

**Taxonomía de etiquetas** — El sistema de familias, valores, colores y descripciones de un grupo. En este bootcamp vive en el grupo raíz y se documenta en el ADR-003.

**Triaje** (*triage*) — Revisar los issues nuevos para darles tipo, prioridad y, si procede, hito.

## V

**Vínculo de issues** (*linked issues*) — `relates_to` es Free. `blocks` e `is_blocked_by` son **Premium**: en CE la API solo acepta `relates_to`.

---

[← Volver a la Semana 05](../README.md)

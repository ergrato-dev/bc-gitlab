# Rúbrica de Evaluación — Semana 05

## 📊 Distribución de Evidencias

| Tipo | Peso | Instrumento | Quién juzga |
|---|:--:|---|---|
| 🧠 Conocimiento | 30% | 10 preguntas conceptuales, 10 pts cada una | Autoevaluación |
| 💪 Desempeño | 40% | Las 4 prácticas, 10 pts cada una | La API de tu instancia |
| 📦 Producto | 30% | La capa 5 de tu plataforma: 60 pts por API + 40 pts de calidad | Mixto |

**Criterio de aprobación: mínimo 70% en cada evidencia**, no en el promedio.

---

## 🧠 Conocimiento (30%)

| # | Pregunta |
|:--:|---|
| 1 | Una etiqueta `v0.1.0` y un hito `v0.1.0` parecen servir para lo mismo. ¿Qué tres cosas da el hito que la etiqueta no puede dar, y por qué una de ellas viene del modelo de datos y no de una convención? |
| 2 | En CE, `prioridad::alta` y `prioridad-alta` se comportan exactamente igual. ¿Por qué entonces este bootcamp exige `::`, y qué pasaría con cada una el día que la instancia pasara a Premium? |
| 3 | Un issue aparece a la vez en las columnas `estado::preparado` y `estado::en-curso` del tablero. ¿Cómo ha podido pasar, por qué el tablero no lo impidió, y por qué `/board_move` lo arregla y `/label` no? |
| 4 | La API REST deja priorizar una etiqueta del proyecto pero devuelve `404` con una del grupo, aunque las dos aparecen en `GET /projects/:id/labels`. ¿Qué explica la diferencia, y por qué no es un fallo de diseño tan absurdo como parece? |
| 5 | ¿Por qué la plantilla `Default` no debería llevar ninguna etiqueta `tipo::`, si las plantillas `Bug` y `Feature` sí la llevan? |
| 6 | Un compañero cierra issues con `Cierra #12` en el commit y luego los cierra a mano "porque no funciona". ¿Qué se pierde con el cierre manual que no se perdería con `Closes #12`? |
| 7 | Un proyecto puede tener varios tableros en CE. ¿Por qué entonces este bootcamp insiste en tener uno solo? Da dos razones, una técnica y una de equipo. |
| 8 | Epics, iteraciones, pesos y burndown son Premium. Para cada uno, di qué decisión ayuda a tomar y si su sustituto en CE permite tomar la misma decisión. |
| 9 | Encuentras un issue con dos `prioridad::`. ¿Qué tres preguntas te haces antes de quitar una, y por qué arreglar solo el dato puede ser un error? |
| 10 | ¿Por qué el título de un issue debería describir el comportamiento observable y no la solución, si al final alguien tendrá que decidir la solución igualmente? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** El hito da **fecha**, **progreso** y **exclusividad**. La fecha (`start_date`, `due_date`) permite los filtros `Started` y `Upcoming` y ordena por vencimiento; una etiqueta no tiene ningún campo temporal. El progreso se calcula solo, issues cerrados frente a totales, y la página del hito lo muestra; con una etiqueta habría que contarlo a mano. Y la exclusividad viene del modelo de datos: un issue tiene **un** campo `milestone`, así que asignarlo a `v0.2.0` lo saca de `v0.1.0` sin que nadie tenga que acordarse. Con etiquetas, un issue puede estar en `v0.1.0` y `v0.2.0` a la vez, que es exactamente el tipo de incoherencia que esta semana obliga a vigilar en `prioridad::`. Lo que el modelo garantiza no hay que vigilarlo.

**2.** Por tres razones, y la tercera decide. `::` se lee como "familia: valor", así que la etiqueta dice a qué pregunta contesta. Permite filtrar la familia entera por prefijo con una regla única. Y en Premium, `::` activa las *scoped labels*: la exclusividad pasa a imponerla GitLab, sin renombrar nada. `prioridad-alta` seguiría siendo una etiqueta normal en Premium, y habría que renombrar toda la taxonomía para aprovecharlo, con el riesgo de romper las plantillas que la citan por nombre. Elegir `::` hoy no cuesta nada y deja abierta una puerta que de otro modo habría que reconstruir.

**3.** Alguien usó `/label ~"estado::en-curso"` (o el campo de etiquetas) en vez de mover la tarjeta. `/label` **añade** sin quitar, y CE no impone una etiqueta por familia, así que el issue quedó con dos `estado::`. El tablero no lo impidió porque el tablero no tiene estado propio: es una vista que pinta cada issue en cada columna cuya etiqueta lleva. Solo impone exclusividad **cuando se usa para mover**, porque mover hace un reetiquetado atómico: quita la de origen y pone la de destino. `/board_move` hace lo mismo desde un comentario: quita todas las etiquetas que son columna de algún tablero del proyecto y pone una. `/label` no sabe nada de columnas.

**4.** El endpoint `PUT /projects/:id/labels/:label_id` sirve sobre todo para **editar** la etiqueta —nombre, color, descripción—, y por eso busca solo entre las del proyecto: un proyecto no debe poder cambiar el color de una etiqueta que es del grupo y que usan otros proyectos. El parámetro `priority` comparte ese endpoint, y hereda su búsqueda restringida, aunque la prioridad sí es del proyecto y no afectaría a nadie más. No es absurdo: es una consecuencia de meter dos permisos distintos (editar la etiqueta y ordenarla en mi proyecto) en la misma ruta. La UI usa otra ruta específica para prioridades. La lección general es que **la API no siempre cubre lo que la UI permite**, y hay que comprobarlo antes de prometer una automatización.

**5.** Porque `Default` es la que se aplica **cuando nadie elige**, y quien no elige es justo quien tiene prisa y no ha pensado qué está informando. Si `Default` pusiera `tipo::bug`, cada sugerencia de mejora abierta con prisa nacería como fallo, y el filtro "bugs abiertos" mentiría. `Bug` y `Feature` pueden clasificar porque quien las elige **ya ha decidido** qué es. La regla general: una plantilla solo pone las etiquetas que la propia elección de la plantilla justifica. Para `Default`, como mucho una que no clasifica, y mejor ninguna: que el issue quede sin `tipo::` hace que aparezca en la consulta de "sin triar", que es donde tiene que estar.

**6.** Se pierde el **enlace entre el issue y el cambio que lo resolvió**. Con `Closes #12`, la nota de sistema del issue dice "closed via commit abc123" y enlaza al SHA: quien llegue al issue dentro de un año ve qué cambio lo arregló, y desde el commit se llega al issue. Con el cierre manual el issue dice solo "closed", y hay que buscar en el historial cuál de los commits que lo mencionan era el bueno. Se pierde también la **garantía**: con `Closes`, el issue se cierra porque el código llegó a `main`; a mano, se puede cerrar con el commit todavía en una rama que nunca se fusiona. Y en la Semana 08, cuando midas el tiempo de ciclo, el cierre desde el commit es un dato fiable y el manual no.

**7.** Técnica: `/board_move` solo está disponible si el proyecto tiene **exactamente un** tablero, porque con dos no sabría qué columnas considerar; con varios tableros se pierde la forma barata de mantener `estado::` exclusiva desde un comentario. De equipo: dos tableros con columnas distintas sobre los mismos issues reetiquetan en direcciones contrarias, y el estado deja de tener una sola definición. Además, el tablero solo funciona si **todo el mundo mira el mismo**; con dos, cada uno mira el suyo y la conversación de "¿por dónde va esto?" vuelve al chat. Lo que se quiere ver distinto —por persona, por hito— se consigue con un filtro sobre el mismo tablero.

**8.** **Epic**: decide qué objetivo de producto avanza y qué falta para cumplirlo; un hito de grupo o una etiqueta `area::` permiten la misma consulta, aunque sin jerarquía. **Iteración**: decide qué entra en el ciclo de trabajo de dos semanas; un hito con fechas cortas sirve igual, solo que hay que crearlo a mano cada vez. **Peso**: decide cuánto cabe en un hito; la estimación de tiempo permite la misma suma, con la desventaja de que el tiempo se presta a leerse como compromiso individual. **Burndown**: decide si hay que recortar alcance antes de la fecha; el porcentaje del hito y la fecha dan la misma señal, solo que sin la curva diaria. En los cuatro casos el sustituto permite la decisión; lo que se pierde es comodidad, no información.

**9.** Primera: **¿cuál es la correcta?** No se quita la más antigua ni la más nueva por defecto; se mira la descripción y los comentarios. Segunda: **¿es un caso aislado o se repite?** Si pasa cada semana en issues nuevos, es un error de proceso —alguien usa `/label` para cambiar de prioridad— y arreglar el dato solo garantiza que volverá. Tercera: **¿quién o qué lo introdujo?** Si fue un script de la API, el problema está en el script. Arreglar solo el dato convierte la comprobación en una tarea de limpieza semanal y oculta la causa; la comprobación existe para detectar procesos rotos, no para generar trabajo de mantenimiento.

**10.** Porque el título-solución **decide antes de entender**. "Añadir validación de cupo" obliga a quien lo resuelve a validar el cupo, aunque la mejor solución fuera otra (bloquear la reserva en la interfaz, cambiar el modelo). El título-problema, "Se puede reservar con el cupo lleno", deja abierta la solución y fija lo único que no se discute: qué comportamiento es inaceptable. También sirve para **cerrar**: se sabe que el issue está resuelto cuando el comportamiento desaparece, mientras que un título-solución se cierra cuando se hizo lo que decía, aunque el problema siga. Y se busca mejor: quien sufre el fallo busca por el síntoma, no por la solución que alguien imaginó.

</details>

---

## 💪 Desempeño (40%)

| Práctica | Criterio | Puntos |
|---|---|:--:|
| [01 — La taxonomía de etiquetas](2-practicas/01-la-taxonomia-de-etiquetas.md) | Familias en el grupo raíz con color y descripción, áreas en el proyecto, prioridad puesta en `app` y ADR-003 en la wiki | 10 |
| [02 — El backlog y el hito](2-practicas/02-el-backlog-y-el-hito.md) | Hito con fechas, 12-15 issues de tu dominio creados desde datos, cinco a ocho en el hito, y la exclusividad rota y arreglada | 10 |
| [03 — Plantillas y acciones rápidas](2-practicas/03-plantillas-y-acciones-rapidas.md) | Tres plantillas en `main`, un issue nacido etiquetado, lista de tareas, estimación y vínculo en un comentario, y un cierre desde commit | 10 |
| [04 — El tablero del flujo](2-practicas/04-el-tablero-del-flujo.md) | Un solo tablero con tres columnas `estado::`, cuatro movimientos predichos, `/board_move` usado y la doble columna detectada y arreglada | 10 |

---

## 📦 Producto (30%)

### Verificable por API — 60 puntos

| Requisito | Comprobación | Puntos |
|---|---|:--:|
| Familia `tipo::` en el grupo | `etiquetas-tipo-en-el-grupo` | 3 |
| Familia `prioridad::` en el grupo | `etiquetas-prioridad-en-el-grupo` | 3 |
| Familia `estado::` en el grupo | `etiquetas-estado-en-el-grupo` | 3 |
| Etiquetas con descripción | `etiquetas-con-descripcion` | 4 |
| Etiquetas priorizadas en `app` | `etiquetas-priorizadas` | 4 |
| Hito `v0.1.0` | `hito-v010` | 3 |
| Hito con fecha | `hito-con-fecha` | 3 |
| Backlog de doce issues | `backlog-doce-issues` | 4 |
| Cinco issues en el hito | `issues-en-el-hito` | 3 |
| Un `tipo::` por issue abierto | `cada-issue-abierto-un-tipo` | 5 |
| Sin `prioridad::` duplicada | `ninguna-prioridad-doble` | 4 |
| Sin `estado::` duplicado | `ningun-estado-doble` | 4 |
| Lista de tareas | `issue-con-lista-de-tareas` | 3 |
| Estimación de tiempo | `issue-con-estimacion` | 3 |
| Plantillas de issue | `plantillas-de-issue` | 4 |
| Issue cerrado | `issue-cerrado` | 3 |
| Tablero de estados | `tablero-de-estados` | 4 |

### Calidad — 40 puntos

| Criterio | Qué se mira | Puntos |
|---|---|:--:|
| El backlog es de tu dominio y creíble | Problemas concretos, mezcla de tipos, bugs que salen de las funciones de la Semana 02 | 10 |
| Los títulos describen problemas | Ninguno es una solución disfrazada ni un "mejorar X" | 7 |
| Los criterios de aceptación se comprueban | Frases de sí o no en los issues del hito | 7 |
| El ADR-003 explica el sistema | Familias, exclusividad, dónde vive cada etiqueta y cómo se vigila en CE | 6 |
| El hito es un compromiso | Cinco a ocho issues, los que caben; el resto sin hito | 5 |
| El tablero dice la verdad | Lo que está en `estado::en-curso` se está haciendo; un solo tablero | 5 |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Una etiqueta suelta sin familia en el grupo raíz | −3 |
| `Default.md` con una etiqueta `tipo::` | −5 |
| Hito con más de la mitad del backlog dentro | −5 |
| Dos o más tableros en `app` | −5 |
| Las mismas etiquetas de familia creadas en el proyecto y en el grupo | −8 |
| Backlog de relleno: "Issue 1", "Prueba", "Tarea X" | −15 |
| Datos personales reales en un issue no confidencial | −20 |
| Un token —cualquiera— en un issue, un comentario o una plantilla | −25 |

---

[← Volver a la Semana 05](README.md)

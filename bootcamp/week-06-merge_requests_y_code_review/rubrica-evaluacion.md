# Rúbrica de Evaluación — Semana 06

## 📊 Distribución de Evidencias

| Tipo | Peso | Instrumento | Quién juzga |
|---|:--:|---|---|
| 🧠 Conocimiento | 30% | 10 preguntas conceptuales, 10 pts cada una | Autoevaluación |
| 💪 Desempeño | 40% | Las 4 prácticas, 10 pts cada una | La API de tu instancia |
| 📦 Producto | 30% | La capa 6 de tu plataforma: 60 pts por API + 40 pts de calidad | Mixto |

**Criterio de aprobación: mínimo 70% en cada evidencia**, no en el promedio.

---

## 🧠 Conocimiento (30%)

| # | Pregunta |
|:--:|---|
| 1 | Un commit y una merge request pueden contener exactamente el mismo cambio. ¿Qué guarda la merge request que el commit no puede guardar, y por qué eso importa más dentro de un año que hoy? |
| 2 | En CE, una aprobación no bloquea nada y el autor puede aprobar lo suyo. ¿Para qué sirve entonces, y qué ajuste de CE es el que de verdad garantiza que alguien ha revisado? |
| 3 | El revisor dejó diez comentarios sueltos en vez de una revisión enviada. El código es el mismo. ¿Qué diferencias hay para el autor durante la revisión, y cuál queda en la historia de Git? |
| 4 | Con `rebase_merge`, la merge request C sale en `need_rebase` aunque choca con `main`. ¿Por qué no dice `conflict`, y qué campo hay que mirar para no intentar un `/rebase` inútil? |
| 5 | Compara `ff` con squash obligatorio y `merge` sin squash: ¿qué ve alguien que lee `git log` un año después, y qué ve alguien que hace `git bisect`? |
| 6 | Una sugerencia aplicada, un squash y un rebase en el servidor producen commits sin tu firma SSH. ¿Por qué no los puede firmar GitLab con tu clave, y cómo se reconcilia eso con un `CONTRIBUTING.md` que exige commits firmados? |
| 7 | La plantilla `Default` se aplica sola al abrir la merge request con *push options*, pero no por `POST /merge_requests`. ¿Qué explica la diferencia, y qué consecuencia tiene para un script que abre merge requests en serie? |
| 8 | Al resolver un conflicto entre dos merge requests ya revisadas, ¿por qué la resolución necesita otra revisión, si cada parte ya se revisó por separado? |
| 9 | ¿Por qué esta semana no se activa *Pipelines must succeed*, y qué pasaría exactamente si se activara? |
| 10 | Una merge request de 900 líneas recibe dos comentarios y una de 40 recibe seis. ¿Qué dice eso de las dos revisiones, y de quién es la responsabilidad de que no vuelva a pasar? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** El commit guarda el cambio y un mensaje que escribió una sola persona. La merge request guarda además **el porqué discutido**: la descripción con el problema y cómo se prueba, la conversación con las objeciones y cómo se resolvieron, las alternativas descartadas, quién revisó y quién aprobó, las versiones intermedias del diff y el issue que cerró. Hoy todo eso está en la cabeza de quien lo hizo. Dentro de un año esa persona no se acuerda, o ya no está, y la pregunta "¿por qué esto es así?" solo tiene respuesta si quedó escrita. `git blame` lleva al commit, el commit lleva a la merge request por su referencia (`!12`), y la merge request lleva al issue: es la cadena que permite reconstruir una decisión.

**2.** Sirve para **registrar** una decisión: quién dio el visto bueno, cuándo y sobre qué versión, y para dejarlo en el commit con `%{approved_by}`. Es información, no control. Lo que en CE garantiza que alguien ha revisado es **`only_allow_merge_if_all_discussions_are_resolved`**: el revisor abre un hilo con lo que bloquea, y mientras ese hilo esté abierto `detailed_merge_status` es `discussions_not_resolved` y nadie puede fusionar. No garantiza que la revisión haya sido buena, pero sí que lo que el revisor señaló como bloqueante se atendió. La aprobación obligatoria es Premium; en la Semana 07 se sustituye con un job que la comprueba por API.

**3.** Para el autor, diez notificaciones en vez de una, y la tentación de empezar a corregir el primer comentario antes de que el revisor termine, a veces en una dirección que el comentario siete contradice. Tampoco sabe cuándo ha terminado el revisor ni qué opina del conjunto: no hay resumen ni veredicto. En la historia, la diferencia es concreta: `%{reviewed_by}` se rellena con `reviewed_by_users`, que sale de la tabla de **revisiones**, y esa tabla solo se escribe al enviar una revisión. Diez comentarios sueltos no producen ninguna línea `Reviewed-by:`; una revisión enviada, sí.

**4.** Porque GitLab ejecuta las comprobaciones en orden y devuelve la primera que falla, y en la 19.2.4 la de rebase va antes que la de conflicto. Con `rebase_merge` o `ff`, una rama que no contiene la punta de `main` falla ya en `need_rebase`, y la comprobación de conflicto ni siquiera se consulta para el estado. El campo que distingue los dos casos es **`has_conflicts`**. Si es `false`, `/rebase` lo arregla en el servidor. Si es `true`, el rebase del servidor fallará y dejará el motivo en `merge_error`: hay que hacer el rebase en local, decidir la resolución y empujar con `--force-with-lease`.

**5.** Con `ff` y squash obligatorio, `git log` es una línea recta con **un commit por merge request**, cada uno con un título que describe un cambio completo. Con `merge` sin squash, `git log --graph` es una trenza: los commits de cada rama, incluidos los de "arreglo test" y "aplicar sugerencia", y un commit de fusión por merge request, con ramas que se cruzan. Para `git bisect`, la primera da la merge request culpable en pocos pasos, y cada paso es un estado de `main` que existió y se probó. La segunda puede caer en commits intermedios de una rama que nunca fueron un estado válido, o en una fusión que combinó dos ramas sin que nadie probara el resultado, y hay que guiar a `bisect` con `--first-parent`.

**6.** Porque GitLab no tiene tu clave privada, y no debe tenerla: la firma prueba que el commit lo hizo quien tiene la clave, y si el servidor la tuviera dejaría de probar nada. Esos commits los crea el servidor en tu nombre, y lo honesto es que salgan sin tu firma. Se reconcilia escribiendo la regla con precisión: **los commits que escribes tú van firmados**; los que crea GitLab como resultado de una acción en la merge request quedan registrados en la merge request, que dice quién pulsó qué. Si un equipo no acepta eso, la alternativa es hacer en local lo que hace el servidor: aplicar las sugerencias a mano, hacer el rebase en local y no usar squash.

**7.** Las tres vías de la UI, el botón del issue y las *push options* construyen la merge request con `MergeRequests::BuildService`, que es quien busca la plantilla `Default` y añade `Closes #N` si la rama empieza por un número. La API llama directamente al servicio de creación y guarda lo que recibe. Para un script, la consecuencia es que sus merge requests salen **sin plantilla y sin trazabilidad** salvo que él mismo las ponga: tiene que leer la plantilla con `GET /templates/merge_requests/Default` y escribir el `Closes #N`, o abrirlas con *push options*. Y si no lo hace, las comprobaciones de trazabilidad fallan y con razón.

**8.** Porque la resolución **es código que no existía** en ninguna de las dos. B se revisó como "añadir una condición" y C como "cambiar una condición"; la línea resultante, con las tres condiciones combinadas, no la vio nadie. Además, la resolución es una decisión de negocio: qué pasa cuando se cumplen las dos reglas a la vez. En el ejemplo, un socio con un préstamo vencido y una multa de 50 céntimos: la resolución lo bloquea, y es lo correcto, pero podría no serlo en otro dominio. Una resolución que elige una rama y descarta la otra pasa los tests de esa rama y rompe silenciosamente la regla de la otra.

**9.** Porque `app` todavía no tiene `.gitlab-ci.yml`, y la comprobación de CI no distingue entre "pipeline en rojo" y "no hay pipeline": `mergeable_ci_state?` devuelve `false` si no hay pipeline de cabeza. Con el ajuste activado, todas las merge requests quedarían en `ci_must_pass` y nadie podría fusionar nada. Es un ajuste que depende de otra pieza, y se activa en la Semana 09, cuando el pipeline exista y esté en verde.

**10.** Que la de 900 líneas probablemente no se revisó: se aprobó por cansancio. La atención cae con el tamaño, y lo habitual es que las merge requests grandes reciban menos comentarios por línea, no más, porque el revisor deja de leer y empieza a pasar páginas. La de 40 líneas recibió una lectura de verdad. La responsabilidad de que no vuelva a pasar es **del autor**: partir el cambio antes de abrir la merge request, en piezas que cada una tenga sentido por sí sola. El revisor puede pedirlo, pero si lo tiene que pedir, el trabajo ya se hizo dos veces.

</details>

---

## 💪 Desempeño (40%)

| Práctica | Criterio | Puntos |
|---|---|:--:|
| [01 — El proyecto preparado para revisar](2-practicas/01-el-proyecto-preparado-para-revisar.md) | Método de fusión, squash, hilos y borrado de rama configurados por API; plantillas de commit con *trailers*; `Default.md` en `main`; ADR-004 en la wiki | 10 |
| [02 — De issue a merge request](2-practicas/02-de-issue-a-merge-request.md) | Rama con el número del issue, test que falla antes del cambio, merge request abierta con *push options*, plantilla y `Closes` aplicados solos, revisor asignado | 10 |
| [03 — La revisión con otra identidad](2-practicas/03-la-revision-con-otra-identidad.md) | Revisión en borrador enviada con veredicto, sugerencia aplicada, hilo bloqueante respondido y resuelto por el revisor, aprobación de otra identidad, fusión con `sha` y squash | 10 |
| [04 — Historia y conflictos](2-practicas/04-historia-y-conflictos.md) | `need_rebase` con `has_conflicts` leído por API, rebase del servidor fallido, conflicto resuelto en local con las dos reglas, `--force-with-lease`, la historia que corresponde al método elegido (tres burbujas con `rebase_merge`, tres commits en línea con `ff`) y token revocado | 10 |

---

## 📦 Producto (30%)

### Verificable por API — 60 puntos

| Requisito | Comprobación | Puntos |
|---|---|:--:|
| Historia lineal o semilineal | `metodo-de-fusion-lineal` | 4 |
| Squash por defecto | `squash-por-defecto` | 3 |
| Hilos obligatorios | `hilos-resueltos-para-fusionar` | 4 |
| Rama borrada al fusionar | `borrar-rama-al-fusionar` | 3 |
| Squash con revisores | `plantilla-de-squash-con-revisores` | 4 |
| Plantilla `Default` | `plantilla-de-mr-default` | 3 |
| La plantilla pide el issue | `plantilla-de-mr-enlaza-issue` | 3 |
| ADR-004 | `adr-004-en-la-wiki` | 4 |
| Tres merge requests fusionadas | `tres-mr-fusionadas` | 4 |
| Trazadas a issues | `mr-trazadas-a-issues` | 5 |
| Revisor distinto del autor | `mr-con-revisor-distinto` | 5 |
| Conversación | `mr-con-conversacion` | 3 |
| Squash | `mr-fusionada-con-squash` | 3 |
| Aprobación de otro | `mr-aprobada-por-otro` | 4 |
| Sugerencia de código | `mr-con-sugerencia` | 4 |
| Issues cerrados | `issues-cerrados-por-mr` | 4 |

### Calidad — 40 puntos

| Criterio | Qué se mira | Puntos |
|---|---|:--:|
| Las merge requests se entienden solas | Una cosa cada una, título convencional, las cuatro preguntas de la plantilla respondidas | 8 |
| La revisión dice qué bloquea | Comentarios con etiqueta, hilos para lo que bloquea, resueltos por quien los abrió | 8 |
| El conflicto se resolvió bien | Las dos reglas aplicadas, un test que lo prueba y el revisor vio la resolución | 7 |
| El ADR-004 tiene las dos caras | Decisión, ventajas y el precio pagado en la práctica 04 | 6 |
| `CONTRIBUTING.md` describe el flujo real | Cambiado por merge request; nada que no hagas, nada que hagas y falte | 6 |
| La historia se lee | Commits de squash con título, referencia, issue y *trailers*; sin casillas de plantilla | 5 |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Un issue abierto en `estado::en-revision` sin merge request abierta | −3 |
| Una merge request cerrada sin comentario que explique por qué | −3 |
| *Pipelines must succeed* activado sin pipeline | −5 |
| Hilos del revisor resueltos por el autor sin respuesta | −5 |
| Un cambio en `main` posterior a la práctica 01 sin merge request | −10 |
| Aprobación o revisión hecha con tu propio token haciéndola pasar por la del revisor | −15 |
| El token del revisor sin revocar al terminar | −15 |
| Un token —cualquiera— en una merge request, un comentario o un commit | −25 |

---

[← Volver a la Semana 06](README.md)

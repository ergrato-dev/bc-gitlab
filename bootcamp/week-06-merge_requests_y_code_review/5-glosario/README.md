# 📖 Glosario — Semana 06

Términos que aparecen esta semana. El nombre real de la feature va en inglés entre paréntesis, y el **tier** cuando aplica.

El glosario acumulado de toda la plataforma está en [glosario-global](../../../docs/glosario-global.md).

---

## A

**Aprobación** (*approval*) — Free como botón y endpoint (`POST .../approve`). En CE es opcional, no bloquea la fusión y puede darla cualquier miembro que pueda editar la merge request, incluido su autor. Las reglas de aprobación obligatoria y el impedir que el autor apruebe lo suyo son **Premium**.

**Asignado** (*assignee*) — Quien lleva la merge request hasta el final. En CE, uno solo; varios es **Premium**.

## B

**Borrador** (*draft*) — Free. Merge request visible pero que no se puede fusionar. Título que empieza por `Draft:`, o `/draft`; se sale con `/ready`.

## C

**Comentario** (*comment*) — Nota suelta en una merge request. No se resuelve y no bloquea nada.

**Commit de fusión** (*merge commit*) — Commit con dos padres que marca dónde entró una rama. Lo crean los métodos `merge` y `rebase_merge`; `ff` no.

**Commit de squash** (*squash commit*) — Commit único que sustituye a todos los de la rama al fusionar. Lo crea el servidor, sin la firma del autor.

**Comprobaciones de fusión** (*merge checks*) — Lo que GitLab verifica antes de permitir fusionar. Se leen en `detailed_merge_status`. Las de aprobación, *code owners* y *external status checks* son **Premium** o **Ultimate**.

**Conventional Comments** — Convención externa a GitLab: una etiqueta al principio del comentario (`issue:`, `suggestion:`, `nitpick:`, `question:`, `praise:`) y un decorador opcional (`(blocking)`).

## D

**`detailed_merge_status`** — Campo de la API con el motivo, en una palabra, por el que una merge request se puede o no fusionar: `mergeable`, `draft_status`, `discussions_not_resolved`, `need_rebase`, `conflict`, `ci_must_pass`, entre otros. Devuelve la primera comprobación que falla.

**Diff refs** — Los tres SHA (`base_sha`, `start_sha`, `head_sha`) que identifican una versión del diff. Hacen falta para comentar sobre una línea por API.

**Draft note** — Comentario pendiente de una revisión en borrador. Solo lo ve su autor hasta que se publica con `bulk_publish`.

## F

**Fast-forward** (`ff`) — Método de fusión sin commit de fusión: `main` avanza hasta la punta de la rama. Exige que la rama contenga la punta de `main`.

## H

**Hilo** (*thread*, *discussion*) — Free. Conversación que se puede resolver. Con `only_allow_merge_if_all_discussions_are_resolved`, un hilo abierto impide fusionar. Un comentario sobre una línea del diff es siempre un hilo.

## M

**Merge request** — Free. Propuesta de fusionar una rama en otra, con descripción, revisión, conversación y el enlace al issue que cierra.

**Método de fusión** (*merge method*) — Ajuste del proyecto: `merge`, `rebase_merge` (semilineal) o `ff`. Decide si hay commit de fusión y si la rama tiene que estar al día.

## P

**Plantilla de commit** (*commit template*) — Free. `merge_commit_template` y `squash_commit_template`: el mensaje que GitLab genera al fusionar, con variables como `%{title}`, `%{issues}`, `%{reviewed_by}` y `%{approved_by}`.

**Plantilla de merge request** (*merge request template*) — Free en `.gitlab/merge_request_templates/` de la rama por defecto. `Default.md` se aplica sola desde la UI, el issue y las *push options*, no desde la API. La plantilla por defecto en los ajustes del proyecto es **Premium**.

**Push options** — Free. Opciones que se mandan al servidor con `git push -o`. Las `merge_request.*` abren y configuran la merge request en el mismo `push`.

## R

**Rebase en el servidor** — Free. `/rebase` o `PUT .../rebase`: GitLab reescribe la rama sobre la punta de `main`. No resuelve conflictos y los commits resultantes no llevan la firma del autor.

**Revisión** (*review*) — Free. Conjunto de comentarios en borrador publicados a la vez, con resumen y veredicto (*Comment*, *Approve*, *Request changes*). Solo las revisiones enviadas cuentan para `%{reviewed_by}`.

**Revisor** (*reviewer*) — Quien lee la merge request y da su opinión. En CE, uno solo; varios es **Premium**.

## S

**Semilineal** (`rebase_merge`, *merge commit with semi-linear history*) — Método de fusión que crea commit de fusión pero exige que la rama contenga la punta de `main`. La historia se lee en línea, con una burbuja por merge request.

**Squash** — Free. Aplastar los commits de la rama en uno al fusionar. El proyecto decide con `squash_option`: `never`, `default_off`, `default_on` o `always`.

**Sugerencia** (*suggestion*) — Free. Bloque ` ```suggestion ` en un comentario sobre el diff, con el texto de reemplazo. Se aplica con un clic y crea un commit con `Co-authored-by:` de quien sugirió. Varias líneas: ` ```suggestion:-1+2 `.

## T

**Trailer** — Línea `Clave: valor` al final de un mensaje de commit, como `Reviewed-by:` o `Co-authored-by:`. Git las extrae con `git log --format='%(trailers)'`.

**Tren de fusión** (*merge train*) — **Premium**. Cola que fusiona merge requests en orden, probando cada una sobre el resultado de las anteriores. Sustituto en CE: rebase y fusión de una en una.

## V

**Versión del diff** (*merge request diff version*) — Cada `push` a la rama crea una. *Compare* entre versiones enseña solo lo que cambió desde la última revisión.

---

[← Volver a la Semana 06](../README.md)

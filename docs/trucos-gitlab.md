# 🎩 Trucos de GitLab

Cheatsheet **acumulativo**. Cada semana añade su sección aquí, copiada de la sección "Trucos y atajos" de su `README.md`.

No es documentación: es lo que no viene en la documentación, o viene enterrado en la página 4.

---

## Atajos de teclado

Funcionan en cualquier pantalla de GitLab. Pulsa `?` para ver la lista completa de la versión que tengas.

| Atajo | Qué hace |
|---|---|
| `s` | Foco en la búsqueda global |
| `?` | Lista de atajos de la pantalla actual |
| `g` `p` | Ir a tus proyectos |
| `g` `i` | Ir a tus issues |
| `g` `m` | Ir a tus merge requests |
| `g` `t` | Ir a tus tareas pendientes (To-Do) |
| `p` `b` | Mostrar u ocultar la barra de rendimiento |
| `.` | Abrir el Web IDE en el proyecto actual |
| `y` | Convertir la URL del archivo en un enlace permanente al commit |
| `r` | Citar el texto seleccionado en el cuadro de respuesta |

> [!TIP]
> `y` es el más útil de todos. Un enlace a `blob/main/archivo.rb#L42` apunta a una línea que se moverá; `y` lo convierte en `blob/<sha>/archivo.rb#L42`, que apunta para siempre a lo que estabas mirando.

---

## URLs que no están en ningún menú

Sustituye `<host>` por tu instancia y `<ruta>` por `grupo/proyecto`.

| URL | Qué muestra |
|---|---|
| `<host>/-/profile/personal_access_tokens` | Tus tokens, sin buscar por Preferences |
| `<host>/admin` | Área de administración |
| `<host>/admin/background_migrations` | Migraciones en curso. Lo primero que hay que mirar tras actualizar |
| `<host>/-/health` | Salud básica, sin arrancar Rails |
| `<host>/-/readiness` | Salud real: base de datos, cache y colas |
| `<host>/-/metrics` | Métricas en formato Prometheus |
| `<host>/<ruta>/-/graphs/main/charts` | Estadísticas de commits del repositorio |
| `<host>/<ruta>/-/network/main` | Grafo de ramas, que no aparece en la barra lateral |
| `<host>/<ruta>/-/pipelines/charts` | Tasa de éxito y duración de los pipelines |
| `<host>/-/graphql-explorer` | Explorador de GraphQL con autocompletado y esquema |

El explorador de GraphQL merece un párrafo aparte: es la forma más rápida de descubrir qué campos existen sin leer la documentación. Autocompleta con `Ctrl+Espacio` y trae el esquema entero de tu versión, no de la última.

---

## Secciones por semana

_Se añaden a medida que se publica cada semana._

<!-- Cada semana inserta aquí su sección, con el mismo contenido que la sección
     "🎩 Trucos y atajos" de su README. El skill `sincronizar-trucos` mantiene
     los dos lados de acuerdo; si difieren, gana el README de la semana. -->

## Semana 01 — Instalación y arquitectura de GitLab CE

| Truco | Cómo |
|---|---|
| Ver el arranque sin adivinar | `docker compose logs -f gitlab` y espera a la línea `gitlab Reconfigured!` |
| Saber si está listo de verdad | `curl -s localhost:8888/-/readiness \| jq` — `/-/health` miente, solo dice que Nginx contesta |
| Estado de todos los procesos de golpe | `docker compose exec gitlab gitlab-ctl status` |
| Seguir un solo componente | `docker compose exec gitlab gitlab-ctl tail sidekiq` |
| Ver la configuración **efectiva**, no la que escribiste | `docker compose exec gitlab cat /var/opt/gitlab/gitlab-rails/etc/gitlab.yml` |
| Comprobar la versión sin abrir el navegador | `curl -s localhost:8888/api/v4/version -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \| jq` |
| Contraseña inicial de `root` | `docker compose exec gitlab grep 'Password:' /etc/gitlab/initial_root_password` — el archivo se autodestruye a las 24 h |
| Explorar la API sin leer la documentación | `http://localhost:8888/-/graphql-explorer`, autocompleta con `Ctrl+Espacio` |
| Ver todas las tareas de mantenimiento disponibles | `docker compose exec gitlab gitlab-rake -T \| less` |
| Ver cuánta memoria come cada cosa | `docker stats --no-stream` |
| Reiniciar un solo proceso, no todo | `docker compose exec gitlab gitlab-ctl restart sidekiq` |
| Encontrar un repositorio en disco | Saca el ID por API y calcula la ruta: `H=$(echo -n "<id>" \| sha256sum \| cut -c1-64); echo @hashed/${H:0:2}/${H:2:2}/$H.git` |

---

## Semana 02 — Git quirúrgico y commits firmados

| Truco | Cómo |
|---|---|
| Auditar de un vistazo qué está firmado | `git log --pretty='%h %G? %s' -20` — `N` es sin firma, `G` es correcto |
| Encontrar lo no firmado antes de empujar | `git log --pretty='%h %G? %s' origin/main..HEAD \| grep -v '^\S* G '` |
| Colocar los arreglos solos, sin tocar el editor | `git commit --fixup <sha>` y luego `git rebase -i --autosquash <base>` |
| Que `--autosquash` sea el comportamiento normal | `git config --global rebase.autosquash true` |
| Comprobar que **cada** commit pasa los tests | `git rebase --exec "npm test" main` |
| Revisar tu propia reescritura antes de forzar | `git range-diff respaldo...HEAD` |
| Deshacer el último `reset`, `rebase` o `merge` | `git reset --hard ORIG_HEAD` |
| Recuperar una rama borrada sin saber su SHA | `git reflog \| grep <nombre-de-la-rama>` |
| Volver a la rama anterior, como `cd -` | `git switch -` |
| Ver la historia de una función concreta | `git log -L :nombreDeLaFuncion:archivo.ts` |
| Encontrar quién tocó una línea sin cambiar el recuento | `git log -G "patron"` — `-S` no lo ve |
| `blame` que no señale a quien reindentó | `git blame -w -C -C archivo.ts` |
| Bisecar sin responder a nada | `git bisect start HEAD <bueno>` y `git bisect run npm test` |
| Saltar un commit que no se puede probar en un bisect | Que el script salga con **código 125** |
| Los diez blobs más grandes de la historia | `git rev-list --objects --all \| git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' \| awk '$1=="blob"{print $3,$4}' \| sort -rn \| head` |
| Buscar un token en **toda** la historia, no solo en HEAD | `git grep "glpat-" $(git rev-list --all) --` |
| Por qué exactamente sale "Unverified" | `curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/projects/$P/repository/commits/main/signature" \| jq -r .verification_status` |
| Ver el uso de todas tus claves de golpe | `curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/user/keys" \| jq -r '.[] \| "\(.usage_type)\t\(.title)"'` |
| Dos ramas a la vez sin clonar dos veces | `git worktree add ../app-hotfix main` |
| Que Git recuerde cómo resolviste un conflicto | `git config --global rerere.enabled true` |

## Semana 03 — Grupos, subgrupos, roles y namespaces

| Truco | Cómo |
|---|---|
| Ver el árbol entero de un grupo de una vez | `curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/groups/$G/descendant_groups" \| jq -r '.[].full_path'` |
| Saber si una ruta está libre antes de crear | `curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/namespaces/infra/exists?parent_id=<id>" \| jq` |
| El rol **efectivo** de alguien aquí, herencia incluida | `.../projects/$P/members/all/<user_id>` — `members/<user_id>` a secas solo ve los directos |
| Qué toca una persona en toda la instancia | `.../users/<id>/memberships` — solo administradores |
| Dónde soy al menos Developer | `.../groups?min_access_level=30` — también vale para `/projects` |
| Ver qué añade **exactamente** cada rol en tu versión | `docker compose exec gitlab cat /opt/gitlab/embedded/service/gitlab-rails/config/authz/roles/developer.yml` |
| Comparar dos roles sin leerlos enteros | `docker compose exec gitlab bash -c 'cd /opt/gitlab/embedded/service/gitlab-rails/config/authz/roles && comm -13 reporter.yml developer.yml'` |
| Buscar un namespace por ruta completa, no por nombre | `.../namespaces?search=plataforma/app&full_path_search=true` |
| Listar solo los grupos raíz | `.../groups?top_level_only=true` |
| Los proyectos del grupo **sin** los que solo están compartidos | `.../groups/$G/projects?with_shared=false&include_subgroups=true` |
| Quién invitó a quién a este proyecto | `.../projects/$P \| jq '.shared_with_groups'` |
| Los grupos invitados de un grupo, directos y heredados | `.../groups/$G/invited_groups?relation=direct,inherited` |
| A dónde puedo mover este grupo | `.../groups/$G/transfer_locations` — la lista real, no la que te imaginas |
| Recuperar un grupo borrado por error | `curl --request POST .../groups/$G/restore` — el `DELETE` solo lo **programa** para borrado |
| Filtrar la lista de miembros por herencia, en la interfaz | `Group → Manage → Members`, filtro *Membership: Inherited* |
| Ver un miembro sin conocer su ID | `.../groups/$G/members?query=revisor` |
| Contar de golpe cuántos Owners tiene el árbol | `.../groups/$G/members/all \| jq '[.[] \| select(.access_level==50)] \| length'` |

---

## Semana 04 — El repositorio como producto

| Truco | Cómo |
|---|---|
| Un `logo.png` en la raíz **es** el avatar del proyecto | GitLab lo detecta solo: nada que subir, y viaja con el repositorio (`Gitlab::FileDetector`) |
| Índice automático en cualquier archivo Markdown | `[[_TOC_]]` en una línea suya. También funciona en las páginas de la wiki |
| Alertas de colores sin HTML | `> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]`, `> [!CAUTION]` |
| Diagramas que se renderizan sin subir imágenes | Bloque ```` ```mermaid ```` — Mermaid es nativo; PlantUML y Kroki necesitan servidor configurado en la instancia |
| Clonar la wiki como lo que es | `git clone <url-del-proyecto>.wiki.git` — es un repositorio Git normal |
| Ver el árbol de la wiki sin navegar | `.../projects/$P/wikis?with_content=true \| jq -r '.[].slug'` |
| Cuánto ocupan wiki, LFS y artefactos | `.../projects/$P?statistics=true \| jq '.statistics'` |
| Comprobar que un archivo está en LFS y no en Git | `.../projects/$P/repository/files/<ruta>?ref=main \| jq -r '.content \| @base64d' \| head -1` |
| Descargar el contenido **real** de un archivo en LFS | `.../projects/$P/repository/files/<ruta>/raw?ref=main&lfs=true` |
| Los puntos de la ruta de un archivo se codifican | `assets%2Flogo%2Epng` — sin `%2E`, Rails se come `.png` como formato de respuesta |
| Plantillas de licencia servidas por tu propia instancia | `.../templates/licenses/mit?project=app&fullname=Tu%20Nombre` |
| Ver qué licencia ha detectado GitLab, y con qué confianza | `.../projects/$P?license=true \| jq '.license'` |
| Insignias que sobreviven a un cambio de ruta | `%{project_path}`, `%{project_id}`, `%{default_branch}`, `%{commit_sha}`, `%{latest_tag}`, tras `$GITLAB_URL/` |
| Ver la URL final de una insignia, ya sustituida | `.../projects/$P/badges \| jq -r '.[].rendered_image_url'` |
| Probar una insignia antes de crearla | `.../projects/$P/badges/render?link_url=...&image_url=...` |
| Qué archivos ocupan LFS en tu clon | `git lfs ls-files --size` |
| Traer un clon sin descargar los binarios | `GIT_LFS_SKIP_SMUDGE=1 git clone <url>` — luego `git lfs pull` cuando los necesites |


## Semana 05 — Issues, etiquetas y tableros

| Truco | Cómo |
|---|---|
| Los patrones de cierre solo están en inglés | `Closes #12`, `Fixes #12`, `Resolves #12`, `Implements #12`. `Cierra #12` no hace nada |
| Mover una tarjeta desde el comentario, sin abrir el tablero | `/board_move ~"estado::en-curso"` — solo si el proyecto tiene **un** tablero |
| Reemplazar todas las etiquetas de golpe | `/relabel ~"tipo::bug" ~"prioridad::alta"` |
| Copiar etiquetas e hito de otro issue | `/copy_metadata #12` |
| Atajos de teclado en la página de un issue | `l` etiquetas, `m` hito, `a` asignado, `e` editar descripción, `r` citar la selección |
| Issues sin ninguna etiqueta: el backlog sin triar | `.../projects/$P/issues?labels=None&state=opened \| jq length` |
| Issues **sin** una familia concreta | `.../projects/$P/issues?not[labels]=tipo::bug&state=opened` |
| Cuántos issues abiertos tiene cada etiqueta | `.../projects/$P/labels?with_counts=true \| jq -r '.[] \| "\(.open_issues_count)\t\(.name)"'` |
| Recuento del backlog en una sola llamada | `.../projects/$P/issues_statistics \| jq '.statistics.counts'` |
| Subir una etiqueta de proyecto al grupo | `PUT .../projects/$P/labels/<id>/promote` — los issues que la usan la conservan |
| Un enlace que abre un issue ya rellenado | `.../-/issues/new?issuable_template=Bug&issue[title]=...` |
| Referenciar etiquetas e hitos en Markdown | `~"tipo::bug"` y `%"v0.1.0"` se convierten en enlaces filtrados |
| Ver qué plantillas detecta GitLab | `.../projects/$P/templates/issues \| jq -r '.[].key'` |

## Semana 06 — Merge requests y code review

| Truco | Cómo |
|---|---|
| Crear la merge request al empujar, sin abrir el navegador | `git push -o merge_request.create -o merge_request.target=main -o merge_request.draft` |
| Saber en una palabra por qué no se puede fusionar | `.../merge_requests/<iid> \| jq -r .detailed_merge_status` |
| Sugerir un cambio que abarca la línea anterior y las dos siguientes | Bloque ` ```suggestion:-1+2 ` en un comentario sobre la línea |
| Pedir revisión desde un comentario | `/assign_reviewer @revisor-<dominio>` |
| Sacar de borrador o volver a meter | `/ready` y `/draft` |
| Enviar la revisión con veredicto desde un comentario | `/submit_review requested_changes` |
| Rebase sin salir de GitLab, cuando no hay conflictos | `/rebase` en un comentario, o `PUT .../merge_requests/<iid>/rebase` |
| Qué issues va a cerrar una MR, antes de fusionarla | `.../merge_requests/<iid>/closes_issues \| jq -r '.[].iid'` |
| Qué MR cerró un issue | `.../issues/<iid>/closed_by \| jq -r '.[].web_url'` |
| Fusionar solo si nadie empujó mientras revisabas | `PUT .../merge` con `sha=<el commit que revisaste>` |
| Ver la MR en local sin crear rama a mano | `git fetch origin merge-requests/<iid>/head:mr-<iid>` |
| Atajos de teclado en el diff | `]` y `[` siguiente y anterior archivo, `n` y `p` siguiente y anterior hilo sin resolver |
| Dar crédito a quien revisó en la historia | `%{reviewed_by}` en la plantilla del commit de squash |

## Semana 07 — Gobernanza de ramas y aprobaciones

| Truco | Cómo |
|---|---|
| Ver qué te deja hacer una rama, con todas las reglas combinadas | `.../repository/branches/main \| jq '{protected, can_push}'` |
| Cambiar los roles de una rama protegida en CE | `DELETE` y `POST` seguidos: no hay `PATCH` para los niveles |
| Proteger todas las versiones, también las futuras | Tag protegido con comodín `v*` |
| Borrar un tag protegido cuando de verdad hace falta | `DELETE .../repository/tags/<tag>`: por `git push` no se puede |
| Los dueños de un archivo según `CODEOWNERS` | La función `duenos` de una línea de `awk`: gana la última regla que coincide |
| La ruta en disco de un proyecto | `printf '%s' <id> \| sha256sum`: `@hashed/<2>/<2>/<hash>.git` |
| Instalar un server hook en un repositorio | `gitaly hooks set --storage default --repository <ruta> --config /var/opt/gitlab/gitaly/config.toml < hooks.tar` |
| Que el mensaje del hook se vea en la UI | Cada línea con el prefijo `GL-HOOK-ERR:` |
| Probar un hook sin GitLab | `git init --bare` en `/tmp` y el hook en `hooks/pre-receive` |
| Saber por qué falló una fusión | `.../merge_requests/<iid> \| jq -r .merge_error` |
| Ir de un commit de `main` a su merge request | `.../repository/commits/<sha>/merge_requests \| jq -r '.[].iid'` |
| Detectar que cambió una protección | Una foto con `jq -S` y `diff <(foto) foto-guardada.json` |

## Semana 08 — GitLab Flow, releases y métricas de flujo

| Truco | Cómo |
|---|---|
| Ver el CHANGELOG de la próxima versión sin escribir nada | `GET .../repository/changelog?version=0.2.0` devuelve `notes` y no hace commits |
| Generar el CHANGELOG cuando no hay tag anterior | Pasa `from=<sha del primer commit>`: sin tag ni `from`, la API responde `422` |
| Conservar el trailer `Changelog:` con squash | `%{first_multiline_commit_description}` en la última línea de la plantilla de squash |
| Commits que entrarán en el CHANGELOG | `git log --format='%h %(trailers:key=Changelog,valueonly,separator=) %s' v0.1.0..main` |
| La siguiente versión según los tipos | `git log --format=%s v0.1.0..main \| grep -Eq '^feat(\(.+\))?!?:'` y sube `MENOR` |
| Crear un tag anotado y firmado | `git tag -s v0.1.0 -m "v0.1.0"` y `git tag -v v0.1.0` |
| Distinguir un tag anotado de uno ligero por API | Anotado si `.target != .commit.id` en `.../repository/tags/<tag>` |
| Llevar un arreglo de `main` a una rama de release | `git cherry-pick -x <sha>`: deja `(cherry picked from commit …)` en el mensaje |
| Saber qué lleva una versión que no está en `main` | `GET .../repository/compare?from=main&to=v0.1.1` |
| Crear una rama protegida desde un tag | Solo por API o web, y desde un commit que ya esté en una rama protegida |
| La última release, sin saber su tag | `GET .../releases/permalink/latest` |
| Mediana de duraciones con `jq` | `sort \| .[length/2 \| floor]` sobre los segundos de cada intervalo |

---

## Semana 09 — CI/CD: fundamentos, runner, artifacts y cache

| Truco | Cómo |
|---|---|
| Validar `.gitlab-ci.yml` sin empujarlo | `jq -n --rawfile c .gitlab-ci.yml '{content: $c}'` y `POST .../ci/lint` |
| Ver el YAML final con `extends` resuelto | `GET .../ci/lint?ref=main&include_merged_yaml=true \| jq -r .merged_yaml` |
| Leer el log de un job sin colores | `GET .../jobs/<id>/trace \| sed 's/\x1b\[[0-9;]*m//g'` |
| Por qué falló un job, sin abrir el log | `GET .../jobs/<id> \| jq .failure_reason` |
| Esperar a que termine un pipeline | `until ... jq -e '.status \| IN("success","failed","canceled")'; do sleep 10; done` |
| Relanzar el pipeline de una merge request | `POST .../merge_requests/<iid>/pipelines` |
| El último paquete de `main`, sin saber el job | `GET .../jobs/artifacts/main/download?job=package` |
| El test que falló, sin leer el log | `GET .../pipelines/<id>/test_report \| jq '.test_suites[].test_cases[] \| select(.status=="failed") \| .name'` |
| Saber si un job usó la caché | `grep -E 'Checking cache\|Successfully extracted'` en su log |
| Pasar un token de una API a otra sin verlo | `jq -j .token \| curl ... --data-urlencode "value@-"` |
| Registrar un runner sin el token en los argumentos | `CI_SERVER_TOKEN="$RT" docker compose exec -e CI_SERVER_TOKEN gitlab-runner gitlab-runner register ...` |
| Por qué no se puede fusionar | `GET .../merge_requests/<iid> \| jq -r .detailed_merge_status` |

## Semana 10 — Reglas, variables y secretos

| Truco | Cómo |
|---|---|
| Qué jobs entrarían en el pipeline de un push, sin crearlo | `POST .../ci/lint` con `dry_run=true`, `ref=<rama>` e `include_jobs=true`, y `.jobs[].name` |
| Saber por qué no nació un pipeline | El `400` de `POST .../pipeline` dice `Review the workflow:rules` |
| Ver los nombres de los pipelines | `GET .../pipelines \| jq -r '.[] \| "\(.id) \(.name)"'` |
| Qué variables tiene el proyecto, sin valores | `GET .../variables \| jq -r '.[] \| "\(.key) \(.environment_scope) p=\(.protected) m=\(.masked) h=\(.hidden)"'` |
| Cambiar una variable con ámbito | `PUT .../variables/<key>?filter%5Benvironment_scope%5D=production` (los corchetes codificados: `curl` los toma por un patrón) |
| Leer la longitud de un secreto en un job, no el secreto | `echo "${#DEPLOY_TOKEN}"` |
| Leer el último despliegue de un entorno | `GET .../deployments?environment=production&status=success&order_by=id&sort=desc&per_page=1` |
| Lanzar un job manual | `POST .../jobs/<id>/play` |
| Rotar un token de proyecto sin verlo | `POST .../access_tokens/<id>/rotate \| jq -j .token \| curl ... PUT .../variables/<key> --data-urlencode "value@-"` |
| Restringir quién pasa variables a un pipeline | `PUT /projects/:id` con `ci_pipeline_variables_minimum_override_role=maintainer` |

## Semana 11 — Pipelines DAG y multiproyecto

| Truco | Cómo |
|---|---|
| Ver los pipelines hijos por API | `GET .../pipelines?source=parent_pipeline`: sin el `source`, la lista los esconde |
| Ir del job de disparo al pipeline que creó | `GET .../pipelines/<id>/bridges \| jq '.[] \| {name, d: .downstream_pipeline.web_url}'` |
| Ver qué jobs esperan a un recurso | `GET .../resource_groups/<key>/upcoming_jobs` |
| Saber quién ejecuta un programado | `GET .../pipeline_schedules \| jq '.[] \| {description, owner: .owner.username}'` |
| Quedarte con un programado huérfano | `POST .../pipeline_schedules/<id>/take_ownership` |
| Lanzar un programado ahora, sin esperar al cron | `POST .../pipeline_schedules/<id>/play` o `glab schedule run <id>` |
| Pasar un dato de un job al pipeline de otro proyecto | `artifacts:reports:dotenv` en el job y `variables: { X: $X }` en el de disparo, con `needs` sobre él |
| Probar la regla de un programado sin crear el programado | `POST .../ci/lint` con `dry_run=true` no simula `schedule`: lanza el programado con `play` sobre una rama de prueba |

---

[← Volver a docs](README.md)

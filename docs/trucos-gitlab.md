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

[← Volver a docs](README.md)

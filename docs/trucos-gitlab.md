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

---

[← Volver a docs](README.md)

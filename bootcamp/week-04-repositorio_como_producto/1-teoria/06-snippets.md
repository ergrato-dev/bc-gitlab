# Snippets

> Un snippet es un repositorio Git diminuto con una URL. Eso lo hace útil, y también lo hace peligroso.

## 🎯 Objetivos

- Distinguir snippet personal de snippet de proyecto, y saber quién ve cada uno
- Crear un snippet con varios archivos por API y leerlo en crudo
- Elegir la visibilidad con criterio y entender por qué `public` casi nunca lo es
- Decidir cuándo un snippet es la herramienta correcta y cuándo es un repositorio que nadie creó

---

## 1. Qué problema resuelve

Hay trozos de código que no son de nadie: el `curl` con la cabecera correcta para llamar a la API interna, el `docker compose` de desarrollo que todos copian, el bloque de `jq` que nadie recuerda. Viven en el chat del equipo y se buscan cada vez.

Un snippet les da tres cosas que el chat no tiene: **una URL estable**, **historial de versiones** y **permisos**. Y como es un repositorio Git de verdad, se clona y se versiona.

Lo que resuelve, con precisión: **el fragmento que se comparte muchas veces y no pertenece a ningún archivo**. Si pertenece a un archivo, va al repositorio. Si no se comparte, va a tus notas.

> [!NOTE]
> Desde GitLab 13.5 cada snippet es un repositorio Git con varios archivos, no un cuadro de texto. Se puede `git clone` de un snippet, y en el bootcamp lo vas a hacer.

---

## 2. Cómo funciona

### 2.1 Los dos tipos

| Tipo | Dónde vive | Quién lo administra | Cuándo usarlo |
|---|---|---|---|
| **Personal** | Tu perfil (`/-/snippets`) | Tú | Utilidades tuyas, apuntes con comandos |
| **De proyecto** | Dentro del proyecto | Quien tenga rol suficiente en el proyecto | Fragmentos del equipo, ligados a ese proyecto |

La diferencia práctica no es dónde aparecen, es **quién los hereda**: un snippet de proyecto lo ven los miembros del proyecto y desaparece con él; uno personal es tuyo y sobrevive a los proyectos, pero también se va contigo el día que te vas.

Para lo del equipo, snippet de proyecto. Siempre.

### 2.2 Visibilidad

Los tres valores de siempre, y las mismas consecuencias que en un proyecto:

| Visibilidad | Quién lo ve |
|---|---|
| `private` | Solo quien tiene acceso al proyecto (o solo tú, si es personal) |
| `internal` | Cualquier usuario **autenticado** de la instancia, excepto los marcados como externos |
| `public` | Cualquiera, sin autenticarse |

> [!WARNING]
> Un snippet `public` en una instancia expuesta a internet es una página web con tu código y sin control de acceso. Es una de las formas más comunes de filtrar una credencial: el snippet se crea "un momento, para pasártelo", y se queda ahí años. En este bootcamp **ningún snippet es público**, y el autograding lo comprueba.

Además de la visibilidad del snippet, el proyecto tiene un interruptor propio:

```bash
source ~/.bc-gitlab
H="PRIVATE-TOKEN: $GITLAB_TOKEN"; API="$GITLAB_URL/api/v4"
P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)

curl -s --request PUT "$API/projects/$P" -H "$H" \
  --data-urlencode "snippets_access_level=private" | jq '.snippets_access_level'
```

Los valores son `disabled`, `private` y `enabled`.

### 2.3 Crear un snippet con varios archivos

La API acepta dos formas y conviene usar la moderna. La antigua —`content` más `file_name`— crea un snippet de un solo archivo y se mantiene por compatibilidad; son **mutuamente excluyentes**, y hay que enviar exactamente una de las dos.

```bash
curl -s --request POST "$API/projects/$P/snippets" -H "$H" \
  --data-urlencode "title=Arranque local de la app" \
  --data-urlencode "description=Los tres comandos que hacen falta tras clonar" \
  --data-urlencode "visibility=private" \
  --data-urlencode "files[][file_path]=arranque.sh" \
  --data-urlencode "files[][content]=#!/usr/bin/env bash
set -euo pipefail
npm ci
npm test" \
  --data-urlencode "files[][file_path]=README.md" \
  --data-urlencode "files[][content]=# Arranque local

Ejecuta ./arranque.sh tras clonar." \
  | jq '{id, title, visibility, files: [.files[].path]}'
```

```json
{
  "id": 3,
  "title": "Arranque local de la app",
  "visibility": "private",
  "files": ["README.md", "arranque.sh"]
}
```

**Con la interfaz**: `Proyecto → Code → Snippets → New snippet`, con el botón *Add another file* para los siguientes.

### 2.4 Leerlo

Tres formas, y cada una sirve para algo distinto:

```bash
# El snippet completo, con metadatos
curl -s -H "$H" "$API/projects/$P/snippets/3" | jq '{title, visibility, files}'

# El contenido en crudo del primer archivo
curl -s -H "$H" "$API/projects/$P/snippets/3/raw"

# Un archivo concreto, por rama y ruta
curl -s -H "$H" "$API/projects/$P/snippets/3/files/main/arranque%2Esh/raw"
```

La tercera es la que se usa en scripts, porque no depende del orden de los archivos.

> [!IMPORTANT]
> En la ruta del archivo, el punto se codifica: `arranque%2Esh`. Sin `%2E`, Rails interpreta `.sh` como formato de la respuesta y devuelve un error que no menciona la causa. Es el mismo detalle que en `repository/files`.

Y como es un repositorio Git, se puede clonar. La URL exacta la da el propio snippet, en el botón *Clone* de su página: no la escribas de memoria, porque la ruta del repositorio de un snippet no es la misma que la de su página web.

### 2.5 Lo que un snippet no es

- **No es un repositorio.** No tiene issues, ni merge requests, ni pipelines, ni ramas protegidas. Si el fragmento crece hasta necesitar revisión, ya es un proyecto.
- **No es documentación.** Un snippet con instrucciones es un README fuera de sitio.
- **No pasa por la detección de secretos.** El escaneo de la Semana 19 mira el repositorio del proyecto, no sus snippets. Lo que se pega en un snippet no lo revisa nadie.
- **No se incrusta si no es público.** GitLab ofrece incrustar un snippet en una página externa con `<script src=".../snippets/3.js">`, pero solo funciona si un usuario anónimo puede leerlo: snippet público **y** proyecto público. En este bootcamp nunca se cumple, y está bien que no se cumpla.

### 2.6 Cuándo snippet y cuándo repositorio

| Situación | Herramienta | Por qué |
|---|---|---|
| Un `curl` que el equipo repite | Snippet de proyecto | No pertenece a ningún archivo |
| Un script de utilidad que va creciendo | Repositorio (`ci/automatizacion`, S17) | Necesita revisión y pruebas |
| Un ejemplo de configuración del propio proyecto | Repositorio (`docs/ejemplos/`) | Tiene que envejecer con el código |
| Un volcado de logs para una incidencia | Snippet personal, o adjunto del issue | Es temporal |
| Una plantilla de mensaje o de informe | Snippet de proyecto | Se reutiliza y no es código |

La pregunta que resuelve el empate: **¿esto necesita que alguien lo revise antes de cambiarlo?** Si sí, no es un snippet.

---

## 3. Cómo se configura

Nada que configurar más allá del interruptor de `snippets_access_level`. Lo que sí hace falta es una convención, porque los snippets se acumulan sin que nadie los mire:

1. **Título que empieza por el verbo**: "Arrancar la app en local", no "arranque".
2. **Descripción con el cuándo**: en qué situación se usa esto.
3. **Un archivo `README.md` dentro del snippet** cuando tiene más de un archivo.
4. **Visibilidad `private`** salvo justificación escrita.
5. **Revisión anual**: lo que ya no se usa, se borra. Un snippet obsoleto es peor que ninguno, porque alguien lo va a ejecutar.

Inventario rápido de lo que hay:

```bash
curl -s -H "$H" "$API/projects/$P/snippets" \
  | jq -r '.[] | "\(.id)\t\(.visibility)\t\(.title)"'
```

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Snippet público "que es más cómodo" | Es una página web sin control de acceso, indexable | `private`, y si hace falta compartir, comparte el proyecto |
| Un token o una contraseña en un snippet | No pasa por la detección de secretos y nadie lo revisa | Variables de CI (S10) o secure files |
| Snippet personal para algo del equipo | Se va contigo el día que te vas | Snippet de proyecto |
| Snippet que en realidad es documentación | Se busca en el sitio equivocado | Wiki o `README.md` |
| Snippet que en realidad es un proyecto | Sin revisión, sin tests, sin historial útil | Un repositorio de verdad |
| Diecisiete snippets sin descripción | Nadie sabe cuál sirve, y se crea el dieciocho | Descripción obligatoria y limpieza anual |
| Copiar el snippet en vez de enlazarlo | Se corrige el original y las copias siguen mal | Enlaza la URL; es estable |

---

## 5. Trucos

- **Es un repositorio Git**: el botón *Clone* de la página del snippet da la URL. Se edita en local y se empuja como cualquier repositorio.
- **Un archivo concreto en crudo**, sin depender del orden: `GET /projects/:id/snippets/:sid/files/main/<ruta>/raw`, con el punto como `%2E`.
- **Buscar entre los snippets del proyecto**: `GET /projects/:id/snippets | jq -r '.[] | select(.title | test("docker";"i")) | "\(.id) \(.title)"'`.
- **Auditar visibilidades de golpe**: `GET /projects/:id/snippets | jq -r '.[] | select(.visibility != "private") | .title'`. Debería no devolver nada.
- **Cuánto ocupan**: `GET /projects/:id?statistics=true | jq '.statistics.snippets_size'`.
- **Los tuyos, en toda la instancia**: `GET /snippets` devuelve tus snippets personales; `GET /snippets/public`, los públicos de la instancia. El segundo es un buen susto en una instancia con historia.

---

## 📚 Recursos Adicionales

- [Snippets](https://docs.gitlab.com/ee/user/snippets.html) — tipos, visibilidad, multiarchivo e incrustación
- [API de snippets de proyecto](https://docs.gitlab.com/ee/api/project_snippets.html) — los parámetros exactos, `files[]` incluido
- [API de snippets personales](https://docs.gitlab.com/ee/api/snippets.html) — la variante de perfil

---

## ✅ Checklist de Verificación

- [ ] Sabes en qué se diferencia un snippet personal de uno de proyecto
- [ ] Has creado un snippet con más de un archivo por API
- [ ] Sabes por qué el punto de la ruta se codifica como `%2E`
- [ ] Ninguno de tus snippets es público, y lo has comprobado con una llamada
- [ ] Puedes decidir en un segundo si algo es un snippet o un repositorio

---

[← Anterior: Decisiones como ADR](05-decisiones-como-adr.md) · [Volver a la Semana 04](../README.md) · [Siguiente: Insignias →](07-insignias.md)

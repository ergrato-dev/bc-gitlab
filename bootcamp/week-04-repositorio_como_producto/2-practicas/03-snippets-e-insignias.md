# Práctica 03 — Snippets e insignias

> Un snippet multiarchivo con lo que el equipo repite, y dos insignias que sobreviven a un cambio de ruta. Lo accesorio, hecho bien.

**Duración estimada**: 50 min
**Prerrequisitos**: Prácticas 01 y 02 completadas · Teorías [06](../1-teoria/06-snippets.md) y [07](../1-teoria/07-insignias.md) leídas

---

## Contexto

Quedan los dos elementos de la portada que no son archivos del repositorio: los **snippets**, para lo que se comparte y no pertenece a ningún archivo, y las **insignias**, para el estado que se lee de un vistazo.

Los dos tienen la misma trampa: son fáciles de hacer mal y el error no da ningún aviso. Un snippet público es una página web sin control de acceso. Una insignia con la ruta escrita a mano se convierte en una imagen rota el día que el proyecto se mueve, y nadie se entera.

Esta práctica los hace bien: snippet privado, y URLs con marcadores servidas por tu propia instancia.

---

## Paso 0: Preparar el terreno

**Por qué**: las mismas variables de las prácticas anteriores, más el identificador numérico del proyecto, que hace falta para leer las insignias.

```bash
source ~/.bc-gitlab

export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
export PID=$(curl -s -H "$H" "$API/projects/$P" | jq -r '.id')

echo "proyecto: $PROYECTO (id $PID)"
```

**Verifica**: `PID` es un número y no `null`.

---

## Paso 1: Ver qué hay antes de crear nada

**Por qué**: los snippets y las insignias se acumulan sin que nadie los mire. Empezar por el inventario es la costumbre que en la Semana 18 convierte una auditoría en dos comandos.

```bash
echo "== snippets"
curl -s -H "$H" "$API/projects/$P/snippets" | jq -r '.[] | "\(.id)\t\(.visibility)\t\(.title)"'

echo "== insignias, propias y heredadas del grupo"
curl -s -H "$H" "$API/projects/$P/badges" | jq -r '.[] | "\(.kind)\t\(.name)"'
```

**Verifica**: las dos listas están vacías. Si hay algo de la Semana 01, míralo antes de seguir.

Y comprueba que los snippets no estén desactivados en el proyecto:

```bash
curl -s -H "$H" "$API/projects/$P" | jq -r '.snippets_access_level'
# private
```

Si sale `disabled`:

```bash
curl -s --request PUT "$API/projects/$P" -H "$H" \
  --data-urlencode "snippets_access_level=private" | jq -r '.snippets_access_level'
```

---

## Paso 2: Decidir qué merece ser un snippet

**Por qué**: la mitad de los snippets de cualquier instancia deberían ser un archivo del repositorio, y la otra mitad no deberían existir. Antes de crear el tuyo, pasa el filtro.

La pregunta que decide: **¿esto necesita que alguien lo revise antes de cambiarlo?** Si sí, es un archivo del repositorio.

| Candidato | ¿Snippet? | Dónde va si no |
|---|:--:|---|
| Los tres comandos para dejar el clon listo | ✅ | — |
| El `curl` de diagnóstico contra la API de la instancia | ✅ | — |
| El script de auditoría de accesos de la Semana 03 | ❌ | `scripts/` del repositorio: tiene lógica y se revisa |
| El `Dockerfile` de la aplicación | ❌ | Raíz del repositorio: envejece con el código |
| El volcado de un error para pedir ayuda | ❌ | Adjunto del issue: es temporal |

El snippet de esta práctica es el primero: **el arranque local**, que es lo que todo el mundo copia el primer día y nadie recuerda dónde está.

---

## Paso 3: Crear el snippet, con varios archivos

**Por qué**: un snippet de un solo archivo obliga a explicar en el título lo que el archivo no dice. Con dos —el script y su `README.md`— se documenta solo.

**Con la interfaz**: `Proyecto → Code → Snippets → New snippet`, y el botón *Add another file* para el segundo.

**Con la API**, en la forma moderna con `files[]`:

```bash
curl -s --request POST "$API/projects/$P/snippets" -H "$H" \
  --data-urlencode "title=Arrancar la app en local" \
  --data-urlencode "description=Los comandos que hacen falta tras clonar el repositorio por primera vez" \
  --data-urlencode "visibility=private" \
  --data-urlencode "files[][file_path]=arranque.sh" \
  --data-urlencode 'files[][content]=#!/usr/bin/env bash
# Deja el clon listo para trabajar. Se ejecuta desde la raiz del repositorio.
set -euo pipefail

command -v node >/dev/null || { echo "falta node"; exit 1; }
command -v git-lfs >/dev/null || echo "aviso: git-lfs no instalado, los binarios seran punteros"

npm ci
npm test
echo "listo"' \
  --data-urlencode "files[][file_path]=README.md" \
  --data-urlencode 'files[][content]=# Arranque local

Tras clonar el repositorio:

    bash arranque.sh

Comprueba node y git-lfs, instala dependencias y ejecuta los tests.' \
  | jq '{id, title, visibility, files: [.files[].path]}'
```

```json
{
  "id": 1,
  "title": "Arrancar la app en local",
  "visibility": "private",
  "files": ["README.md", "arranque.sh"]
}
```

**Verifica**: hay dos archivos y la visibilidad es `private`.

```bash
export SID=$(curl -s -H "$H" "$API/projects/$P/snippets" | jq -r '.[0].id')
curl -s -H "$H" "$API/projects/$P/snippets/$SID" | jq '{title, visibility, files: [.files[].path]}'
```

---

## Paso 4: Leer el snippet como lo leería un script

**Por qué**: el valor de un snippet es su URL estable. Si solo se puede leer abriendo el navegador, es un pantallazo con más pasos.

```bash
# El primer archivo, en crudo
curl -s -H "$H" "$API/projects/$P/snippets/$SID/raw" | head -3

# Un archivo concreto, sin depender del orden. Ojo al %2E del punto
curl -s -H "$H" "$API/projects/$P/snippets/$SID/files/main/arranque%2Esh/raw" | head -3
```

**Verifica**: las dos llamadas devuelven texto del script, no JSON ni un error.

> [!IMPORTANT]
> Si en la segunda llamada escribes `arranque.sh` con el punto literal, Rails interpreta `.sh` como formato de la respuesta y devuelve un error que no menciona la causa. El punto va como `%2E`. Es el mismo detalle que aparece en `repository/files`, y el que hace fallar la comprobación de LFS de la práctica 04 si se olvida.

Y comprueba lo que el autograding va a mirar: que nada sea público.

```bash
curl -s -H "$H" "$API/projects/$P/snippets" | jq 'all(.[]; .visibility != "public")'
# true
```

> [!WARNING]
> Un snippet `public` en una instancia accesible desde internet es una página web con tu código y sin control de acceso. Es una de las formas más comunes de filtrar una credencial: se crea "un momento, para pasártelo" y se queda ahí años. En este bootcamp ningún snippet es público, y el autograding lo comprueba.

---

## Paso 5: Probar una insignia antes de crearla

**Por qué**: crear, mirar, borrar y repetir es el ciclo lento. GitLab tiene un endpoint que sustituye los marcadores y te devuelve las URLs finales sin crear nada.

```bash
curl -s -H "$H" --get "$API/projects/$P/badges/render" \
  --data-urlencode 'link_url=%{gitlab_server}/%{project_path}/-/pipelines' \
  --data-urlencode 'image_url=%{gitlab_server}/%{project_path}/badges/%{default_branch}/pipeline.svg' \
  | jq '{rendered_link_url, rendered_image_url}'
```

```json
{
  "rendered_link_url": "http://localhost:8888/plataforma-biblioteca/app/-/pipelines",
  "rendered_image_url": "http://localhost:8888/plataforma-biblioteca/app/badges/main/pipeline.svg"
}
```

**Verifica**: en las dos URLs no queda ningún `%{` sin sustituir. Si queda alguno, el marcador está mal escrito y la insignia se mostrará rota.

---

## Paso 6: Crear las dos insignias

**Por qué**: la de pipeline es la que se mira primero, y la de licencia es la que responde "¿puedo usar esto?" sin abrir ningún archivo. Las dos con marcadores, para que sobrevivan a un cambio de ruta o de rama por defecto.

**Con la interfaz**: `Settings → General → Badges`. El formulario tiene vista previa en vivo.

**Con la API**:

```bash
# 1. Estado del pipeline. Dira "unknown" hasta la Semana 09, y eso es correcto
curl -s --request POST "$API/projects/$P/badges" -H "$H" \
  --data-urlencode "name=Pipeline" \
  --data-urlencode 'link_url=%{gitlab_server}/%{project_path}/-/pipelines' \
  --data-urlencode 'image_url=%{gitlab_server}/%{project_path}/badges/%{default_branch}/pipeline.svg' \
  | jq '{id, name, rendered_image_url}'

# 2. Licencia, con la insignia personalizada que sirve tu propia instancia
curl -s --request POST "$API/projects/$P/badges" -H "$H" \
  --data-urlencode "name=Licencia" \
  --data-urlencode 'link_url=%{gitlab_server}/%{project_path}/-/blob/%{default_branch}/LICENSE' \
  --data-urlencode 'image_url=%{gitlab_server}/%{project_path}/-/badges/custom.svg?key_text=license&key_width=50&value_text=MIT&value_color=blue' \
  | jq '{id, name, rendered_image_url}'
```

**Verifica**: hay dos insignias de tipo `project` y sus URLs renderizadas no llevan marcadores sin sustituir.

```bash
curl -s -H "$H" "$API/projects/$P/badges" \
  | jq -r '.[] | "\(.kind)\t\(.name)\t\(.rendered_image_url)"'
```

Y que las imágenes existen de verdad, que es distinto de que la URL esté bien formada:

```bash
for url in $(curl -s -H "$H" "$API/projects/$P/badges" | jq -r '.[].rendered_image_url'); do
  printf '%s ' "$(curl -s -o /dev/null -w '%{http_code}' -H "$H" "$url")"
  echo "$url"
done
# 200 http://localhost:8888/plataforma-biblioteca/app/badges/main/pipeline.svg
# 200 http://localhost:8888/plataforma-biblioteca/app/-/badges/custom.svg?...
```

**Verifica**: los dos códigos son `200`. Abre además la portada del proyecto en el navegador: las insignias tienen que verse encima del árbol de archivos.

> [!NOTE]
> La insignia de pipeline mostrará *unknown* hasta que exista el primer pipeline, en la Semana 09. No es un fallo: es el estado real, y el día que el pipeline pase a verde se verá sin tocar nada.

---

## Paso 7: Ver por qué los marcadores importan

**Por qué**: el argumento "usa marcadores" se entiende de verdad cuando ves lo que pasa sin ellos. Este paso no cambia nada: solo lo demuestra.

```bash
# Como se veria una insignia escrita a mano hoy, si el proyecto se moviera manana
echo "escrita a mano:  $GITLAB_URL/$PROYECTO/badges/main/pipeline.svg"
echo "con marcadores:  %{gitlab_server}/%{project_path}/badges/%{default_branch}/pipeline.svg"
```

La primera deja de funcionar en tres situaciones, y ninguna avisa: si el proyecto cambia de ruta (Semana 03, teoría 07), si la rama por defecto deja de ser `main`, o si copias la insignia a otro proyecto.

**Verifica**: sabrías explicar por qué la segunda sobrevive a las tres. Si la respuesta no te sale sola, vuelve a la teoría [07](../1-teoria/07-insignias.md), sección 2.2.

---

## ✅ Resultado

- [ ] Existe un snippet de proyecto con al menos dos archivos
- [ ] Su visibilidad es `private`, y ninguno del proyecto es público
- [ ] Sabes leer un archivo concreto del snippet por API, con el punto como `%2E`
- [ ] Hay dos insignias de tipo `project`
- [ ] Al menos una usa marcadores
- [ ] Las dos URLs de imagen devuelven `200` y se ven en la portada
- [ ] Puedes explicar por qué una insignia de un servicio externo es mala idea aquí

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 04
```

Esta práctica cubre cuatro comprobaciones: el snippet, su visibilidad, las dos insignias y el marcador.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `POST /snippets` devuelve 400 | Se enviaron `files[]` y `content` a la vez | Son mutuamente excluyentes: envía solo `files[]` |
| El snippet se crea con un solo archivo | Se usó la forma antigua `content` + `file_name` | Usa `files[][file_path]` y `files[][content]`, repetidos |
| `404` al leer un archivo del snippet | El punto de la ruta va literal | `arranque%2Esh`, con `%2E` |
| La comprobación `ningun-snippet-publico` falla | Algún snippet quedó en `public` | `PUT /projects/:id/snippets/:sid` con `visibility=private` |
| `snippets_access_level` está en `disabled` | El proyecto tiene los snippets apagados | `PUT /projects/:id` con `snippets_access_level=private` |
| La insignia sale con un `%{` en la URL | El marcador está mal escrito | Compáralo con la tabla de la teoría 07; pruébalo con `/badges/render` |
| La imagen de la insignia da `404` | La ruta del SVG no es la que genera GitLab | `badges/<rama>/pipeline.svg` va **sin** `/-/`; `custom.svg` y `release.svg` van **con** `/-/` |
| La insignia no aparece en la portada | Se creó en otro proyecto, o es del grupo y el proyecto no cuelga de él | `GET /projects/:id/badges` y mira el campo `kind` |
| No se puede borrar una insignia desde el proyecto | Es heredada del grupo | Se borra en el grupo donde se creó |
| La insignia de pipeline dice *unknown* | Todavía no hay ningún pipeline | Correcto hasta la Semana 09 |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Práctica 02 — La wiki y el primer ADR](02-la-wiki-y-el-primer-adr.md) | **Práctica 03** | [Práctica 04 — Binarios con Git LFS](04-binarios-con-git-lfs.md) |

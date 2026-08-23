# Práctica 04 — Hablar con la API

> Todo lo que hace la interfaz lo hace llamando a la API. Aquí aprendes a llamarla tú, y a descubrir solo mirando qué endpoint necesitas.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 03 completada — grupo, proyecto y `~/.bc-gitlab` con `PROYECTO=`

---

## Contexto

Dentro de tres semanas alguien te pedirá "un listado de todos los proyectos con su visibilidad y su rama por defecto". A clics son diez minutos y un error de transcripción. Por API son treinta segundos y un `jq`.

Esta práctica es la que convierte la API en una herramienta que usas, no en documentación que consultas.

---

## Paso 1: Confirmar tu token y sus permisos

**Por qué**: la mitad de los errores 401 y 403 son un token sin el scope adecuado o caducado. Comprobarlo primero descarta esa familia entera.

```bash
source ~/.bc-gitlab

curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/personal_access_tokens/self" \
  | jq '{name, scopes, expires_at, active}'
```

```json
{
  "name": "bootcamp",
  "scopes": ["api"],
  "expires_at": "2027-08-22",
  "active": true
}
```

> [!TIP]
> `personal_access_tokens/self` devuelve el token **con el que estás llamando**. Es la forma rápida de resolver "tengo tres tokens y no sé cuál es este".

**Verifica**:

```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/personal_access_tokens/self" | jq -e '.active == true' > /dev/null \
  && echo "token activo"
```

---

## Paso 2: Las tres formas de identificar un proyecto

**Por qué**: es el atasco número uno de quien empieza con la API de GitLab. Un 404 aquí parece un proyecto que no existe, y casi siempre es una barra sin codificar.

Por ID numérico:

```bash
ID=$(curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/plataforma-biblioteca%2Fapp" | jq '.id')

curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$ID" | jq '.path_with_namespace'
```

Por ruta codificada:

```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/plataforma-biblioteca%2Fapp" | jq '.path_with_namespace'
```

Y ahora el error, para que lo reconozcas cuando te pase:

```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/plataforma-biblioteca/app" | jq
# {"message":"404 Project Not Found"}
```

El proyecto existe. Lo que falla es la barra sin codificar: la API cree que `app` es un subrecurso.

**Verifica** que las dos formas correctas devuelven lo mismo:

```bash
A=$(curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/projects/$ID" | jq -r '.id')
B=$(curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/projects/plataforma-biblioteca%2Fapp" | jq -r '.id')
[ "$A" = "$B" ] && echo "coinciden: $A"
```

---

## Paso 3: Leer las cabeceras y descubrir la paginación

**Por qué**: la API devuelve 20 elementos por defecto y **no avisa de que hay más**. Es la causa silenciosa de scripts que dan resultados incompletos sin dar ningún error.

```bash
curl -s -D- -o /dev/null -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects" | grep -iE '^(x-total|x-page|x-per-page|x-next-page)'
```

```
x-total: 1
x-page: 1
x-per-page: 20
x-next-page:
```

Con un solo proyecto no hay paginación, pero ya sabes dónde mirarla. Súbelo al máximo:

```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects?per_page=100&membership=true" | jq 'length'
```

**Verifica**:

```bash
curl -s -D- -o /dev/null -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects" | grep -ci '^x-total'
# 1
```

---

## Paso 4: Consultas útiles con `jq`

**Por qué**: la API devuelve objetos enormes. `jq` es lo que convierte 200 campos en la respuesta a tu pregunta.

Tus proyectos, con lo que importa:

```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects?membership=true&per_page=100" \
  | jq -r '.[] | "\(.path_with_namespace)\t\(.visibility)\t\(.default_branch)"'
```

El tamaño real de tu proyecto, con el parámetro que casi nadie conoce:

```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/plataforma-biblioteca%2Fapp?statistics=true" \
  | jq '.statistics'
```

```json
{
  "commit_count": 1,
  "storage_size": 21514,
  "repository_size": 1024,
  "lfs_objects_size": 0,
  "job_artifacts_size": 0,
  ...
}
```

Los miembros del grupo:

```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/groups/plataforma-biblioteca/members" \
  | jq -r '.[] | "\(.username)\t\(.access_level)"'
```

`access_level` es un número: 10 Guest, 20 Reporter, 30 Developer, 40 Maintainer, 50 Owner. La Semana 03 trabaja esto a fondo.

**Verifica**:

```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/plataforma-biblioteca%2Fapp?statistics=true" \
  | jq -e '.statistics.commit_count > 0' > /dev/null && echo "hay commits"
```

---

## Paso 5: Escribir, no solo leer

**Por qué**: hasta ahora solo has consultado. La API también modifica, y así es como se automatiza la plataforma a partir de la Semana 17.

Vas a añadir un topic al proyecto, que es un cambio inofensivo y reversible:

```bash
curl -s --request PUT "$GITLAB_URL/api/v4/projects/plataforma-biblioteca%2Fapp" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data-urlencode "topics[]=bootcamp-gitlab" \
  --data-urlencode "topics[]=hilo-conductor" \
  | jq '.topics'
```

```json
["bootcamp-gitlab", "hilo-conductor"]
```

**Con la UI** sería: `Settings → General → Topics`.

**Verifica**:

```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/plataforma-biblioteca%2Fapp" \
  | jq -e '.topics | length >= 2' > /dev/null && echo "topics aplicados"
```

---

## Paso 6: Lo mismo con `glab`

**Por qué**: `glab` gestiona la autenticación y resuelve el proyecto desde el directorio actual. Para el trabajo diario es más cómodo; para aprender qué endpoint hay debajo, `curl` enseña más.

Autentica `glab` contra tu instancia:

```bash
glab auth login --hostname localhost:8888
```

Elige el token que ya tienes cuando lo pida.

```bash
glab api user | jq '.username'
glab api "projects/plataforma-biblioteca%2Fapp" | jq '.visibility'
```

Y desde dentro del repositorio clonado, sin decirle cuál es el proyecto:

```bash
cd /ruta/a/app
glab repo view
```

**Verifica**:

```bash
glab api user | jq -e '.username' > /dev/null && echo "glab autenticado"
```

---

## Paso 7: Descubrir un endpoint sin leer documentación

**Por qué**: es el truco que más tiempo te va a ahorrar en veintiséis semanas. La interfaz de GitLab llama a su propia API, así que puedes espiarla.

1. Abre `http://localhost:8888` en el navegador
2. Abre las herramientas de desarrollo (`F12`) → pestaña **Red**
3. Filtra por `api`
4. Navega a tu proyecto y entra en `Settings → General`
5. Cambia algo pequeño (la descripción) y guarda

Verás la petición: método `PUT`, ruta `/api/v4/projects/<id>`, y el cuerpo con el campo exacto. Eso es lo que tendrías que escribir en `curl`.

**Verifica** reproduciendo por API lo que acabas de hacer por la interfaz:

```bash
curl -s --request PUT "$GITLAB_URL/api/v4/projects/plataforma-biblioteca%2Fapp" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data-urlencode "description=Gestion de prestamos de biblioteca. Producto del hilo conductor del Bootcamp GitLab CE." \
  | jq '.description'
```

---

## Paso 8: Probar GraphQL en su explorador

**Por qué**: para datos anidados, REST obliga a encadenar llamadas. GraphQL trae todo en una, y su explorador autocompleta con el esquema de **tu** versión.

Abre `http://localhost:8888/-/graphql-explorer` y pega:

```graphql
query {
  project(fullPath: "plataforma-biblioteca/app") {
    name
    visibility
    repository {
      rootRef
    }
    group {
      name
      description
    }
  }
}
```

Pulsa ejecutar. En una sola llamada tienes datos del proyecto, del repositorio y del grupo.

Prueba `Ctrl+Espacio` dentro de las llaves: te lista los campos disponibles. Eso es el esquema de tu instancia, no el de la documentación de otra versión.

Lo mismo desde la terminal:

```bash
curl -s -X POST "$GITLAB_URL/api/graphql" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"query { project(fullPath: \"plataforma-biblioteca/app\") { name visibility } }"}' \
  | jq '.data.project'
```

**Verifica**:

```bash
curl -s -X POST "$GITLAB_URL/api/graphql" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" -H "Content-Type: application/json" \
  -d '{"query":"query { project(fullPath: \"plataforma-biblioteca/app\") { name } }"}' \
  | jq -e '.data.project.name == "app"' > /dev/null && echo "GraphQL responde"
```

---

## Paso 9: Cerrar la semana

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 01
```

**Verifica**:

```
12 de 12 verificaciones superadas.
```

Y mira el `checks.json` de esta semana: ahora que sabes leer la API, entiendes exactamente qué está comprobando cada línea.

```bash
jq -r '.checks[] | "\(.descripcion)\n   → \(.api // .graphql)"' \
  bootcamp/week-01-*/checks.json
```

---

## ✅ Resultado

- [ ] Sabes comprobar los scopes y la validez de tu token
- [ ] Sabes identificar un proyecto por ID y por ruta codificada, y reconoces el 404 de la barra
- [ ] Sabes detectar si una respuesta viene paginada
- [ ] Has consultado proyectos, estadísticas y miembros con `jq`
- [ ] Has modificado el proyecto por API, no solo leído
- [ ] Tienes `glab` autenticado contra tu instancia
- [ ] Sabes descubrir un endpoint espiando la interfaz
- [ ] Has ejecutado una consulta en el explorador de GraphQL

```bash
./scripts/verificar-semana.sh 01
```

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `401 Unauthorized` | Token mal copiado o caducado | `curl .../personal_access_tokens/self` y créalo de nuevo si hace falta |
| `403 Forbidden` | Al token le falta el scope | Necesita `api` para escribir; `read_api` solo lee |
| `404 Project Not Found` y el proyecto existe | Barra sin codificar | `%2F` en lugar de `/` |
| `jq: error: Cannot index array` | La respuesta es un array, no un objeto | Usa `.[0]` o `.[] \|` |
| `glab auth login` no acepta el host | Falta el puerto | `--hostname localhost:8888`, con el puerto |
| `glab repo view` no encuentra el proyecto | No estás dentro del repositorio clonado | `cd` al repositorio, o usa `glab api` con la ruta |
| El explorador de GraphQL da 401 | No has iniciado sesión en el navegador | Entra en la interfaz primero: usa tu sesión, no el token |
| `--data-urlencode` manda literalmente `topics[]` | Comillas del shell | Entrecomilla el argumento entero como en los ejemplos |
| La respuesta llega vacía y sin error | Filtro de `jq` que no casa | Quita el `jq` y mira la respuesta cruda |

---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| [← Práctica 03 — Crear tu plataforma](03-crear-tu-plataforma.md) | — |

[← Volver a la Semana 01](../README.md)

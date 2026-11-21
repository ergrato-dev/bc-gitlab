# GraphQL para operar

> Auditar el grupo por REST es una petición por proyecto y otra por cada cosa que miras de él: con diez proyectos y tres comprobaciones, cuarenta peticiones. GraphQL pide exactamente los campos que quieres, de todos los proyectos, en una. Pero tiene sus reglas: pagina con cursores, cobra cada consulta en puntos de complejidad, contesta 200 aunque falle, y a veces, cuando no tienes permiso, no dice nada.

---

## 🎯 Objetivos

- Escribir una consulta con variables que recorre todos los proyectos de un grupo con cursores
- Medir la complejidad de una consulta antes de que la instancia la rechace
- Detectar los errores de una respuesta que llega con código 200
- Saber cuándo GraphQL calla y hay que volver a REST

---

## 1. Qué problema resuelve

El auditor de la práctica 01 necesita, de cada proyecto del grupo y sus subgrupos: la ruta, la visibilidad, si está marcado para borrar y su rama por defecto. Por REST, `GET /groups/:id/projects` trae casi noventa campos por proyecto, de los que usa cuatro, paginados de cien en cien. Por GraphQL:

```graphql
query($grupo: ID!, $tras: String) {
  group(fullPath: $grupo) {
    projects(includeSubgroups: true, first: 50, after: $tras) {
      pageInfo { hasNextPage endCursor }
      nodes {
        fullPath visibility markedForDeletion
        repository { rootRef }
      }
    }
  }
}
```

Una petición por cada cincuenta proyectos, y la respuesta tiene la forma de la consulta.

---

## 2. Cómo funciona

### 2.1 Un endpoint, un `POST`

Todo va a `POST /api/graphql` con un cuerpo JSON: `query` y `variables`. Los mismos tokens que REST, en `Authorization: Bearer` o en `PRIVATE-TOKEN`.

```bash
Q='query($p: ID!) { project(fullPath: $p) { visibility } }'
curl -s "$GITLAB_URL/api/graphql" -H "$H" -H 'Content-Type: application/json' \
  -d "$(jq -nc --arg q "$Q" '{query: $q, variables: {p: "plataforma-biblioteca/app"}}')" | jq -c .
# {"data":{"project":{"visibility":"internal"}}}
```

Las variables van aparte, nunca pegadas dentro de la consulta: así una ruta con comillas no rompe nada, y la consulta es un texto fijo que puedes versionar.

Para explorar el esquema, `http://localhost:8888/-/graphql-explorer`: autocompleta campos y argumentos con tu sesión.

### 2.2 Cursores

Cada listado es una *connection*: `nodes` con los elementos y `pageInfo` con dónde seguir. El bucle es siempre el mismo:

1. Pide con `after: null`.
2. Si `pageInfo.hasNextPage`, repite con `after: pageInfo.endCursor`.
3. Si no, se acabó.

El cursor es opaco: no se construye, se copia. Funciona como la paginación por claves de REST: no se salta elementos aunque el listado cambie. La documentación fija el máximo de `first` en 100.

### 2.3 Complejidad

Cada campo suma puntos, y los listados multiplican. La instancia rechaza la consulta que pasa del límite, antes de ejecutarla. Puedes preguntarlo en la propia consulta:

```graphql
query { queryComplexity { score limit } }
```

| Quién pregunta | `limit` en 19.2.4 |
|---|:--:|
| Sin token | 200 |
| Token de usuario o de bot | 250 |
| Administrador | 300 |

Pedir los proyectos y, dentro de cada uno, sus pipelines y, dentro, sus jobs dispara la cuenta. Si te pasas, baja `first` o parte la consulta en dos.

### 2.4 Errores con código 200

REST falla con un 4xx. GraphQL contesta **200** y mete los errores en el cuerpo:

```json
{"errors":[{"message":"Field 'nombreMal' doesn't exist on type 'Project'", "...": "..."}]}
```

Un script que solo mira el código HTTP da por buena una consulta rota. La regla: si la respuesta tiene `errors`, ha fallado, aunque también traiga `data` (puede traer datos parciales y errores a la vez).

### 2.5 El silencio por permisos

Esta es la trampa que tumba auditores. Pide las reglas de rama de `app` con tu token (Owner) y con el del bot auditor (Reporter):

```graphql
query { project(fullPath: "plataforma-biblioteca/app") { branchRules { nodes { name } } } }
```

| Token | Respuesta |
|---|---|
| El tuyo | `[{"name":"All branches"},{"name":"main"}]` |
| El del bot, Reporter | `[]`, sin `errors` |

Lista vacía, sin error. Para GraphQL, "no tienes permiso para ver las reglas" y "no hay reglas" se escriben igual. Un auditor que se fíe de ese campo informa de que `main` no está protegida en todos los proyectos, o peor: si la comprobación fuera al revés, de que todo está bien. REST, con el mismo token, sí contesta:

```bash
curl -s -H "$H_BOT" "$API/projects/plataforma-biblioteca%2Fapp/protected_branches/main" | jq -c '{name, allow_force_push}'
# {"name":"main","allow_force_push":false}
```

Por eso el auditor mezcla: GraphQL para listar los proyectos y sus ajustes, REST para la rama protegida de cada uno. Antes de fiarte de un campo de GraphQL con un token restringido, compara su respuesta con la de un token que seguro lo ve.

### 2.6 Mutaciones

GraphQL también escribe: `mutation { … }`, con nombres como `pipelineScheduleCreate` o `projectCiCdSettingsUpdate`. El auditor no escribe nada, y las correcciones de la práctica 01 van por REST, que es lo que ya conoces. Para escribir, una sola regla: el token del bot de lectura no puede, y está bien que no pueda.

---

## 3. Cómo se configura

En el cliente, nada: un `POST` con `fetch` o `curl`. En la UI, el explorador de `/-/graphql-explorer`. Los límites de complejidad y de profundidad no se tocan desde la API.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Mirar solo el código HTTP | Una consulta con errores contesta 200 | Fallar si la respuesta trae `errors` |
| Pegar valores dentro del texto de la consulta | Una comilla rompe la consulta; no se puede versionar | `variables` |
| Pedir `first: 100` en tres niveles anidados | La complejidad se dispara y la instancia la rechaza | `queryComplexity` antes, y consultas más planas |
| Fiarse de una lista vacía con un token restringido | Puede ser "no tienes permiso" | Contrastar con REST o con un token con más rol |
| Construir el cursor a mano | Es opaco; cambia entre versiones | Copiar `endCursor` |

---

## 5. Trucos

- El explorador muestra la documentación de cada campo al pasar el ratón: es la forma rápida de saber qué argumentos admite `pipelines` o `projects`.
- Un campo que devuelve una interfaz (`job { pipeline { … } }` devuelve `PipelineInterface`) necesita un fragmento: `pipeline { ... on Pipeline { name } }`.
- `pipelines(source: "schedule", ref: "main", first: 1)` da el último pipeline programado, con sus jobs y artefactos, en una sola consulta: es lo que usa `verificar-semana.sh` esta semana.

---

## 📚 Recursos Adicionales

- [GraphQL API](https://docs.gitlab.com/api/graphql/) — límites, paginación y el explorador
- [GraphQL API reference](https://docs.gitlab.com/api/graphql/reference/) — todos los tipos y campos; elige la versión 19.2 arriba a la derecha

---

## ✅ Checklist de Verificación

- [ ] Has recorrido los proyectos de tu grupo con `first: 2` hasta `hasNextPage: false`
- [ ] Conoces la complejidad de la consulta del auditor y el límite de tu token
- [ ] Has visto una respuesta 200 con `errors`
- [ ] Has comparado `branchRules` con tu token y con el del bot

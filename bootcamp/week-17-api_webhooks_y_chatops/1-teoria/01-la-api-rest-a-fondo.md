# La API REST a fondo

> Llevas dieciséis semanas usando `curl` contra `/api/v4` para comprobar lo que hacías en la UI. Esta semana la API deja de ser la forma de comprobar y pasa a ser la forma de operar: un script que recorre todos los proyectos del grupo cada mañana. Para eso hacen falta tres cosas que una consulta suelta no enseña: recorrer listados largos sin perder elementos, leer los errores sin adivinar, y no tumbar la instancia a peticiones.

---

## 🎯 Objetivos

- Recorrer un listado con paginación por desplazamiento y por conjunto de claves, y saber cuál usar
- Leer un código de error y saber si el problema es el token, el permiso o el recurso
- Reconocer el 404 que en realidad es "no puedes verlo"
- Escribir peticiones que se pueden repetir sin efectos dobles

---

## 1. Qué problema resuelve

Un script que audita "todos los proyectos del grupo" hace esto:

```bash
curl -s -H "$H" "$API/groups/plataforma-biblioteca/projects?include_subgroups=true" | jq length
# 20
```

El grupo tiene 23 proyectos. El script dice 20 y no avisa: la API devuelve **una página**, de 20 elementos por defecto, y el resto hay que pedirlo. Un auditor que no pagina da por buenos proyectos que nunca ha mirado. Es el fallo más común de la automatización por API, y no da ningún error.

---

## 2. Cómo funciona

### 2.1 Rutas e identificadores

Todo recurso cuelga de `/api/v4`. Un proyecto se nombra por su ID numérico o por su ruta completa codificada:

```bash
# La barra de la ruta va como %2F: si no, la API lee dos segmentos.
curl -s -H "$H" "$API/projects/plataforma-biblioteca%2Fci%2Fautomatizacion" | jq -r .id
# 51
```

En scripts, `jq -sRr @uri` codifica la ruta, como en `P` desde la Semana 09. La ruta es estable para quien lee el script; el ID es estable si alguien renombra el proyecto. Los scripts que guardan estado (como `linea-base-s16.json`) guardan el ID.

### 2.2 Paginación por desplazamiento

`page` y `per_page`. El máximo de `per_page` es 100, y pedir más **no da error**: la API lo deja en 100 y lo dice en una cabecera.

```bash
curl -sI -H "$H" "$API/projects?per_page=500" | grep -iE '^x-(next|page|per|total)'
# X-Next-Page: 2
# X-Page: 1
# X-Per-Page: 100
# X-Total: 230
# X-Total-Pages: 3
```

| Cabecera | Para qué sirve |
|---|---|
| `X-Total`, `X-Total-Pages` | Saber cuánto falta sin descargarlo. En listados de más de 10 000 elementos no vienen: contarlos es caro |
| `X-Next-Page` | Vacía en la última página. Es la condición de parada del bucle |
| `Link` | La URL de la página siguiente ya hecha (`rel="next"`) |

El desplazamiento tiene un defecto: si entre la página 1 y la 2 se crea un proyecto, todo se corre un puesto y uno se ve dos veces o ninguna.

### 2.3 Paginación por conjunto de claves

`pagination=keyset`, con un orden por una columna única (`order_by=id`). En vez de "dame la página 2", la siguiente petición dice "dame lo que va después del ID 2":

```bash
curl -sI -H "$H" "$API/projects?pagination=keyset&order_by=id&sort=asc&per_page=2" | grep -i '^link'
# Link: <…/api/v4/projects?id_after=2&…&pagination=keyset…>; rel="next"
```

No hay `X-Total` ni `X-Next-Page`: solo `Link`, y cuando no trae `rel="next"`, se acabó. No se salta elementos aunque cambie el listado, y su coste no crece con el número de página. No todos los endpoints la admiten: proyectos, grupos y unos cuantos más, cada uno con sus `order_by` permitidos (ver [Keyset-based pagination](https://docs.gitlab.com/api/rest/#keyset-based-pagination)).

| | Desplazamiento | Conjunto de claves |
|---|---|---|
| Saber el total | Sí, hasta 10 000 | No |
| Saltar a la página 7 | Sí | No |
| Listado que cambia mientras lo recorres | Duplicados u omisiones | Correcto |
| Listados enormes | Cada página cuesta más | Coste constante |

El auditor de la práctica 01 no usa ninguna de las dos para listar proyectos: usa GraphQL, que pagina con cursores (teoría 02). Pero usa REST para las ramas protegidas, y ahí cada proyecto tiene pocas.

### 2.4 Leer un error

La API contesta con un código HTTP y un cuerpo JSON con `message` o `error`. Cada código apunta a un sitio distinto:

| Código | Qué significa | Dónde mirar |
|---|---|---|
| `400` | La petición está mal formada o falta un parámetro | El `message`: suele nombrar el campo |
| `401` | El token no vale: no existe, caducó o está revocado | El token, no los permisos |
| `403` `{"message":"403 Forbidden"}` | El token vale, pero el rol no llega | El rol del usuario o del bot en ese proyecto |
| `403` `{"error":"insufficient_scope"}` | El rol llegaría, pero el token no tiene ese scope | Los scopes del token (teoría 03) |
| `404` | No existe, **o no puedes verlo** | Prueba con un token que seguro lo ve |
| `409`, `422` | Conflicto con el estado actual (ya existe, no es válido ahora) | El recurso, no la petición |
| `429` | Demasiadas peticiones | La cabecera `Retry-After`: cuántos segundos esperar |

El `404` merece su línea propia. Pide `app` (visibilidad `internal`) sin token:

```bash
curl -s "$API/projects/plataforma-biblioteca%2Fapp" | jq .
# { "message": "404 Project Not Found" }
```

El proyecto existe. GitLab contesta "no existe" a quien no puede verlo para no confirmar que existe: es una decisión de seguridad, no un fallo. Un script que trata el 404 como "no hay nada que auditar" se salta en silencio lo que su token no ve.

### 2.5 Repetir sin efectos dobles

Un script que falla a mitad se relanza entero. Las operaciones tienen que aguantarlo:

- `GET`, `PUT` y `DELETE` son repetibles: poner `only_allow_merge_if_pipeline_succeeds=true` dos veces deja lo mismo.
- `POST` crea: dos veces son dos issues, dos webhooks, dos tokens. Antes de un `POST`, el script busca si ya existe.

---

## 3. Cómo se configura

No hay nada que configurar en el cliente. En la instancia, los límites de peticiones (por usuario, por IP, para usuarios sin sesión) son de administración: Semana 18. Lo que te toca es comportarte: `per_page=100`, una petición tras otra, y si llega un `429`, esperar lo que diga `Retry-After`.

Con la UI no se pagina nada: la UI es otro cliente de esta misma API.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Leer solo la primera página | El script da por auditados proyectos que nunca vio, sin error | Bucle hasta que `X-Next-Page` esté vacía o `Link` no traiga `next` |
| `per_page=1000` "para no paginar" | La API lo deja en 100 sin avisar en el cuerpo | `per_page=100` y paginar |
| Tratar el `404` como "no hay nada" | Lo que el token no ve desaparece del informe | Contar los proyectos vistos y compararlos con lo esperado |
| Reintentar en bucle ante un `429` | Cada reintento cuenta para el mismo límite | Esperar `Retry-After` |
| `POST` sin mirar antes | Duplicados en cada relanzamiento | Buscar, y crear solo si no está |

---

## 5. Trucos

- `curl -sI` (solo cabeceras) dice cuántos elementos y páginas hay sin descargar ninguno.
- `?simple=true` en `/projects` devuelve una veintena de campos en vez de casi noventa: menos bytes por página.
- `--fail-with-body` en `curl` hace que un 4xx o 5xx salga con código distinto de cero y aun así muestre el `message`.

---

## 📚 Recursos Adicionales

- [REST API](https://docs.gitlab.com/api/rest/) — paginación, códigos de estado y codificación de rutas
- [Rate limits](https://docs.gitlab.com/security/rate_limits/) — qué límites existen y las cabeceras de una respuesta `429`

---

## ✅ Checklist de Verificación

- [ ] Sabes cuántos proyectos tiene tu grupo por la cabecera `X-Total`, sin descargarlos
- [ ] Has recorrido `/projects` con `pagination=keyset` hasta que `Link` dejó de traer `next`
- [ ] Puedes decir qué te falta ante un `401`, un `403 Forbidden` y un `insufficient_scope`
- [ ] Has visto el `404` de un proyecto que existe

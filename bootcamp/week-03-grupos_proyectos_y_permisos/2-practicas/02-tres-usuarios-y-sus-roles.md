# Práctica 02 — Tres usuarios y sus roles

> Tres identidades con permisos distintos, una elevación puntual y la primera lectura seria de `members` contra `members/all`.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 01 completada · Teorías [03](../1-teoria/03-los-roles-y-que-puede-cada-uno.md) y [04](../1-teoria/04-herencia-de-membresia.md) leídas

---

## Contexto

Hasta ahora tu instancia tiene un usuario: tú, que además eres administrador. Con un solo usuario no se puede aprender nada de permisos, porque todo funciona siempre.

Vas a crear tres identidades de laboratorio con tres necesidades distintas, repartir los roles con criterio de menor privilegio, y comprobar cómo se ve el resultado desde la API. En la práctica 03 pondrás a prueba ese reparto con tokens reales.

| Identidad | Necesita | Rol | Dónde |
|---|---|---|---|
| `dev-<dominio>` | Empujar código y abrir merge requests | Developer (30) | Grupo raíz |
| `revisor-<dominio>` | Administrar solo `app`, nada más del árbol | Guest (10) en el grupo, **Maintainer (40) en `app`** | Grupo + proyecto |
| `auditor-<dominio>` | Leer issues durante una revisión temporal | Guest (10) **con caducidad** | Grupo raíz |

El caso de `revisor` es el interesante: es la única forma de dar un rol alto en un proyecto sin darlo en todo el árbol.

---

## Paso 0: Recuperar el entorno de trabajo

**Por qué**: son las mismas variables de la práctica 01. Si abriste una terminal nueva, se han perdido.

```bash
source ~/.bc-gitlab
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export RUTA_GRUPO="${PROYECTO%/*}"
export G=$(printf '%s' "$RUTA_GRUPO" | jq -sRr @uri)
export P=$(printf '%s' "$PROYECTO"   | jq -sRr @uri)
export GID=$(curl -s -H "$H" "$API/groups/$G" | jq -r '.id')
export DOM="${RUTA_GRUPO#plataforma-}"   # biblioteca, cine, gimnasio...
echo "grupo $RUTA_GRUPO (id $GID) · dominio $DOM"
```

**Verifica**: `GID` es un número y `DOM` es tu dominio, sin el prefijo `plataforma-`.

---

## Paso 1: Crear los tres usuarios

**Por qué**: crear usuarios es API **de administración**: en el laboratorio la tienes porque eres `root`. Los tres nacen con contraseña aleatoria y confirmados, porque no hay servidor de correo que confirme nada.

```bash
for rol in dev revisor auditor; do
  curl -s --request POST "$API/users" -H "$H" \
    --data-urlencode "email=$rol-$DOM@example.test" \
    --data-urlencode "username=$rol-$DOM" \
    --data-urlencode "name=${rol^} $DOM" \
    --data-urlencode "force_random_password=true" \
    --data-urlencode "skip_confirmation=true" \
    | jq -c '{id, username, is_admin, external, state}'
done
```

```json
{"id":2,"username":"dev-biblioteca","is_admin":false,"external":false,"state":"active"}
{"id":3,"username":"revisor-biblioteca","is_admin":false,"external":false,"state":"active"}
{"id":4,"username":"auditor-biblioteca","is_admin":false,"external":false,"state":"active"}
```

**Verifica**: los tres salen con `is_admin: false` y `state: "active"`. Si alguno sale `is_admin: true`, lo creaste con `admin=true` y no sirve para esta semana: un administrador se salta todos los permisos que vas a probar.

Guarda los identificadores, que hacen falta en cada paso siguiente:

```bash
export UID_DEV=$(curl -s -H "$H" "$API/users?username=dev-$DOM" | jq -r '.[0].id')
export UID_REV=$(curl -s -H "$H" "$API/users?username=revisor-$DOM" | jq -r '.[0].id')
export UID_AUD=$(curl -s -H "$H" "$API/users?username=auditor-$DOM" | jq -r '.[0].id')
echo "dev=$UID_DEV revisor=$UID_REV auditor=$UID_AUD"
```

> [!NOTE]
> `force_random_password=true` significa que nadie conoce esas contraseñas, tú incluido. No importa: en la práctica 03 estos usuarios actúan por token, no por navegador. Si quisieras entrar como uno de ellos en la interfaz, `PUT /users/:id` con `password=` te deja poner una.

---

## Paso 2: Comprobar que no tienen acceso a nada

**Por qué**: un usuario recién creado no es miembro de nada. Es el punto de partida correcto —y conviene verlo, porque es lo que hace que el paso siguiente signifique algo.

```bash
curl -s -H "$H" "$API/groups/$GID/members/all" | jq -r '.[] | "\(.access_level)\t\(.username)"'
# 50	root
```

**Verifica**: en la lista solo estás tú, con `50`.

---

## Paso 3: Dar a `dev` el rol que necesita, donde toca

**Por qué**: `dev` trabaja en todo lo de la plataforma, presente y futuro. Ese es exactamente el caso en el que la membresía va en el **grupo raíz**: una sola operación, y cubre `infra` y `ci` cuando tengan proyectos.

**Con la UI**: `Grupo → Manage → Members → Invite members`, usuario `dev-<dominio>`, rol *Developer*.

**Con la API**:

```bash
curl -s --request POST "$API/groups/$GID/members" -H "$H" \
  --data-urlencode "user_id=$UID_DEV" \
  --data-urlencode "access_level=30" \
  | jq '{username, access_level, expires_at}'
```

```json
{ "username": "dev-biblioteca", "access_level": 30, "expires_at": null }
```

**Verifica**: `access_level` es `30`. Comprueba además que la herencia ya funciona, sin tocar nada más:

```bash
curl -s -H "$H" "$API/projects/$P/members/all" | jq -r '.[] | "\(.access_level)\t\(.username)"'
# 50	root
# 30	dev-biblioteca
```

`dev` no es miembro de `app`: es miembro del grupo, y `app` lo hereda.

---

## Paso 4: Dar a `revisor` y a `auditor` el mínimo en el grupo

**Por qué**: ninguno de los dos necesita el árbol entero. `revisor` va a administrar `app` y lo recibirá en el paso 6; `auditor` solo lee issues, y su acceso tiene fecha de fin porque la revisión termina.

```bash
# revisor: Guest en el grupo. Su rol real llega en el paso 6, y solo en app.
curl -s --request POST "$API/groups/$GID/members" -H "$H" \
  --data-urlencode "user_id=$UID_REV" \
  --data-urlencode "access_level=10" | jq '{username, access_level}'

# auditor: Guest con caducidad
curl -s --request POST "$API/groups/$GID/members" -H "$H" \
  --data-urlencode "user_id=$UID_AUD" \
  --data-urlencode "access_level=10" \
  --data-urlencode "expires_at=2026-12-31" | jq '{username, access_level, expires_at}'
```

```json
{ "username": "revisor-biblioteca", "access_level": 10 }
{ "username": "auditor-biblioteca", "access_level": 10, "expires_at": "2026-12-31" }
```

**Verifica**: `expires_at` aparece **solo** en `auditor`.

```bash
curl -s -H "$H" "$API/groups/$GID/members" \
  | jq -r '.[] | "\(.access_level)\t\(.username)\t\(.expires_at // "sin caducidad")"' | sort -rn
```

```
50	root	sin caducidad
30	dev-biblioteca	sin caducidad
10	revisor-biblioteca	sin caducidad
10	auditor-biblioteca	2026-12-31
```

> [!TIP]
> La fecha del ejemplo es un día concreto porque `expires_at` no admite duraciones. Si quieres treinta días desde hoy: `--data-urlencode "expires_at=$(date -d '+30 days' +%F)"`.

---

## Paso 5: Comprobar que Guest no es "solo lectura del código"

**Por qué**: es la confusión más extendida sobre los roles, y aquí se ve con datos antes de sufrirla. `revisor` y `auditor` son Guest: ven el proyecto y los issues, **no ven el código**.

```bash
docker compose exec gitlab bash -c \
  'cd /opt/gitlab/embedded/service/gitlab-rails/config/authz/roles && grep -c "^  - read_code$" guest.yml reporter.yml'
```

```
guest.yml:0
reporter.yml:1
```

**Verifica**: `guest.yml` no declara `read_code` y `reporter.yml` sí. En la práctica 03 lo comprobarás por el otro lado: con el token de `auditor` y un `404` de la API.

---

## Paso 6: La elevación directa en `app`

**Por qué**: `revisor` tiene que administrar `app` —ajustes, miembros del proyecto, protecciones de la Semana 07— y **nada más** del árbol. Subirlo a Maintainer en el grupo le daría también `infra` y `ci`. La única forma de acotarlo es el rol directo en el proyecto.

**Con la UI**: `Proyecto app → Manage → Members → Invite members`, rol *Maintainer*.

**Con la API**:

```bash
curl -s --request POST "$API/projects/$P/members" -H "$H" \
  --data-urlencode "user_id=$UID_REV" \
  --data-urlencode "access_level=40" | jq '{username, access_level}'
```

```json
{ "username": "revisor-biblioteca", "access_level": 40 }
```

**Verifica**: el rol efectivo en `app` es `40`, y en el grupo sigue siendo `10`.

```bash
echo -n "en app:   "; curl -s -H "$H" "$API/projects/$P/members/all/$UID_REV" | jq -r '.access_level'
echo -n "en grupo: "; curl -s -H "$H" "$API/groups/$GID/members/all/$UID_REV" | jq -r '.access_level'
```

```
en app:   40
en grupo: 10
```

Es la regla de la teoría 04 en funcionamiento: gana el más alto de las fuentes que alcanzan a ese recurso, y el rol de proyecto no alcanza al grupo.

---

## Paso 7: Leer la diferencia entre directo y heredado

**Por qué**: es la lectura que hace posible auditar. `members` responde "¿a quién invité aquí?"; `members/all` responde "¿quién tiene acceso a esto?".

```bash
echo "== directos del proyecto app"
curl -s -H "$H" "$API/projects/$P/members" | jq -r '.[] | "\(.access_level)\t\(.username)"'

echo "== efectivos sobre app"
curl -s -H "$H" "$API/projects/$P/members/all" | jq -r '.[] | "\(.access_level)\t\(.username)"' | sort -rn

echo "== efectivos sobre el subgrupo ci"
curl -s -H "$H" "$API/groups/$G%2Fci/members/all" | jq -r '.[] | "\(.access_level)\t\(.username)"' | sort -rn
```

```
== directos del proyecto app
40	revisor-biblioteca
== efectivos sobre app
50	root
40	revisor-biblioteca
30	dev-biblioteca
10	auditor-biblioteca
== efectivos sobre el subgrupo ci
50	root
30	dev-biblioteca
10	auditor-biblioteca
10	revisor-biblioteca
```

**Verifica** tres cosas en esa salida:

1. `app` tiene **un** miembro directo, la excepción documentada.
2. En `ci`, `revisor` vuelve a ser Guest: su Maintainer no sale de `app`.
3. El subgrupo `ci`, que no ha recibido ni una sola invitación, ya tiene cuatro personas con acceso. Eso es la herencia, y es la razón por la que auditar mirando solo `members` no sirve.

Y el detalle que confunde a todo el mundo:

```bash
curl -s -o /dev/null -w '%{http_code}\n' -H "$H" "$API/projects/$P/members/$UID_DEV"
# 404
curl -s -o /dev/null -w '%{http_code}\n' -H "$H" "$API/projects/$P/members/all/$UID_DEV"
# 200
```

**Verifica**: el `404` no significa "no tiene acceso": significa "no es miembro **directo**".

---

## Paso 8: Dejar constancia

**Por qué**: un reparto de roles que solo existe en la base de datos se reinterpreta cada vez que alguien mira. La documentación vive con el código.

En tu clon de `app`, crea `docs/organizacion.md` con el árbol y la tabla de identidades (la plantilla está en la [teoría 08](../1-teoria/08-disenar-el-arbol-con-menor-privilegio.md), sección 3). Commit firmado, como todo desde la Semana 02:

```bash
git add docs/organizacion.md
git commit -m "docs(org): documentar el arbol de namespaces y el reparto de roles"
git push
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/repository/files/docs%2Forganizacion.md?ref=main" | jq -r '.file_name'
# organizacion.md
```

---

## ✅ Resultado

- [ ] Existen tres usuarios de laboratorio, ninguno administrador
- [ ] El grupo raíz tiene cuatro miembros directos
- [ ] `dev` es Developer (30) en el grupo raíz
- [ ] `revisor` y `auditor` son Guest (10) en el grupo raíz
- [ ] `auditor` tiene `expires_at`
- [ ] `revisor` es Maintainer (40) directo en `app` y sigue siendo Guest en el grupo
- [ ] `members/all` del subgrupo `ci` devuelve cuatro personas sin haber invitado a nadie
- [ ] `docs/organizacion.md` está en `main`

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 03
```

Esta práctica cubre las comprobaciones 7 a 13.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `403 Forbidden` al crear usuarios | El token no es de un administrador o le falta scope `api` | En el laboratorio eres `root`: crea un token con scope `api` desde tu perfil |
| `{"message":{"email":["has already been taken"]}}` | Ya creaste ese usuario en un intento anterior | Recupera su ID con `GET /users?username=...` y sigue |
| `{"message":"400 Bad request - Not a valid username"}` | El dominio lleva mayúsculas, acentos o espacios | El `username` es kebab-case ASCII; el `name` admite lo demás |
| El `POST /members` responde `409` | Esa persona ya es miembro de ese recurso | `PUT /groups/:id/members/:user_id` para cambiarle el rol |
| `expires_at` sale `null` en la respuesta | El parámetro no llegó, o el formato no es `YYYY-MM-DD` | Reenvía con `PUT` y la fecha en formato ISO |
| `revisor` sale con 40 también en el grupo | Se le invitó al grupo con 40, no al proyecto | `PUT /groups/:id/members/:user_id` con `access_level=10` |
| Falla `un-solo-owner` | Algún usuario de laboratorio acabó con 50 | `PUT` a su membresía con el rol correcto; Owner solo tú |
| `members/all` del subgrupo devuelve menos de cuatro | Las membresías se pusieron en el subgrupo, no en la raíz | Quítalas del subgrupo y ponlas en el grupo raíz |
| No aparece `docs/organizacion.md` | El push no llegó, o la ruta no está codificada en la consulta | `git log origin/main -1` y usa `docs%2Forganizacion.md` |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Práctica 01 — El árbol de la organización](01-el-arbol-de-la-organizacion.md) | **Práctica 02** | [Práctica 03 — Probar los permisos de verdad](03-probar-los-permisos-de-verdad.md) |

# Práctica 03 — Probar los permisos de verdad

> Un token por identidad y once peticiones reales. Los permisos no se leen en una tabla: se prueban, y la prueba es un código HTTP.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 02 completada · Teorías [03](../1-teoria/03-los-roles-y-que-puede-cada-uno.md) y [04](../1-teoria/04-herencia-de-membresia.md) leídas

---

## Contexto

Repartir roles es fácil. Saber qué hiciste al repartirlos es otra cosa: la documentación de permisos tiene cientos de filas, va por detrás del código y no distingue tu versión de la siguiente.

En esta práctica creas un token para cada usuario de laboratorio y compruebas, petición a petición, dónde está la frontera de cada rol. Todo es de lectura o reversible, y todo devuelve un número que no admite interpretación: `200` es "puede", `403` es "no puede", `404` es "ni siquiera sabe que existe".

> [!IMPORTANT]
> Los tokens que creas aquí son reales y dan acceso a tu instancia. Se guardan en variables de la terminal, **no** en el repositorio, y se revocan al final de la práctica. Ninguno se escribe en un archivo del proyecto ni aparece en un commit.

---

## Paso 0: Recuperar el entorno

**Por qué**: se reutilizan las variables de las prácticas anteriores, más los identificadores de los tres usuarios.

```bash
source ~/.bc-gitlab
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export RUTA_GRUPO="${PROYECTO%/*}"
export G=$(printf '%s' "$RUTA_GRUPO" | jq -sRr @uri)
export P=$(printf '%s' "$PROYECTO"   | jq -sRr @uri)
export GID=$(curl -s -H "$H" "$API/groups/$G" | jq -r '.id')
export DOM="${RUTA_GRUPO#plataforma-}"
export UID_DEV=$(curl -s -H "$H" "$API/users?username=dev-$DOM" | jq -r '.[0].id')
export UID_REV=$(curl -s -H "$H" "$API/users?username=revisor-$DOM" | jq -r '.[0].id')
export UID_AUD=$(curl -s -H "$H" "$API/users?username=auditor-$DOM" | jq -r '.[0].id')
echo "grupo $GID · dev $UID_DEV · revisor $UID_REV · auditor $UID_AUD"
```

**Verifica**: los tres identificadores son números.

---

## Paso 1: Un token por identidad

**Por qué**: no puedes iniciar sesión como esos usuarios —tienen contraseña aleatoria— y tampoco hace falta. La API de administración permite crear un token personal en nombre de otro usuario, que es exactamente lo que necesita una prueba de permisos.

```bash
crear_token() {   # $1 = user_id, $2 = etiqueta
  curl -s --request POST "$API/users/$1/personal_access_tokens" -H "$H" \
    --data-urlencode "name=prueba-permisos-$2" \
    --data-urlencode "scopes[]=api" \
    --data-urlencode "expires_at=$(date -d '+2 days' +%F)" \
    | jq -r '.token'
}

export T_DEV=$(crear_token "$UID_DEV" dev)
export T_REV=$(crear_token "$UID_REV" revisor)
export T_AUD=$(crear_token "$UID_AUD" auditor)
```

**Verifica** que los tres tokens funcionan y que cada uno es quien dice ser. Nunca imprimas su valor:

```bash
for t in "$T_DEV" "$T_REV" "$T_AUD"; do
  curl -s -H "PRIVATE-TOKEN: $t" "$API/user" | jq -r '.username'
done
```

```
dev-biblioteca
revisor-biblioteca
auditor-biblioteca
```

Si alguna línea sale vacía o `null`, el token no se creó: revisa que tu propio token sea de administrador y tenga scope `api`.

> [!NOTE]
> **Scope y rol son dos límites distintos y se aplican los dos.** El scope `api` dice qué **tipo** de operaciones admite el token; el rol dice sobre **qué** recursos. Un token con scope `api` de un usuario Guest sigue siendo Guest: el scope no eleva nada. Por eso aquí se usa `api` en los tres: para que lo único que limite sea el rol, que es lo que se está midiendo. En un uso real se elegiría el scope mínimo (`read_api`).

---

## Paso 2: Preparar la función de prueba

**Por qué**: vas a hacer once peticiones y lo único que importa de cada una es el código. Una función corta lo deja legible y repetible.

```bash
probar() {   # $1 = etiqueta, $2 = token, $3 = método, $4 = url, $5... = datos
  local etiqueta="$1" token="$2" metodo="$3" url="$4"; shift 4
  local datos=()
  for d in "$@"; do datos+=(--data-urlencode "$d"); done
  local codigo
  codigo=$(curl -s -o /dev/null -w '%{http_code}' --request "$metodo" \
             -H "PRIVATE-TOKEN: $token" "${datos[@]}" "$url")
  printf '%-46s %s\n' "$etiqueta" "$codigo"
}
```

**Verifica** que funciona con la petición más inocente que existe:

```bash
probar "auditor: ¿quién soy?" "$T_AUD" GET "$API/user"
# auditor: ¿quién soy?                           200
```

---

## Paso 3: Lo que puede un Guest

**Por qué**: es la frontera peor entendida del modelo. Guest ve el proyecto y participa en los issues; **no ve el código**. Quien pide "solo lectura del repositorio" está pidiendo Reporter.

```bash
probar "auditor: ver el proyecto"        "$T_AUD" GET "$API/projects/$P"
probar "auditor: listar issues"          "$T_AUD" GET "$API/projects/$P/issues"
probar "auditor: leer el árbol de código" "$T_AUD" GET "$API/projects/$P/repository/tree"
```

```
auditor: ver el proyecto                       200
auditor: listar issues                         200
auditor: leer el árbol de código               403
```

**Verifica**: el tercero es `403`. Es el mismo hecho que viste en `guest.yml` en la práctica anterior, ahora desde el otro lado: el permiso `read_code` empieza en Reporter.

---

## Paso 4: Lo que añade Developer

**Por qué**: `dev` es Developer del grupo, y `app` lo hereda. Puede leer y escribir código; no puede administrar el proyecto.

```bash
probar "dev: leer el árbol de código"    "$T_DEV" GET "$API/projects/$P/repository/tree"
probar "dev: ver las variables de CI/CD" "$T_DEV" GET "$API/projects/$P/variables"
probar "dev: cambiar la descripción"     "$T_DEV" PUT "$API/projects/$P" "description=Cambio no autorizado"
```

```
dev: leer el árbol de código                   200
dev: ver las variables de CI/CD                403
dev: cambiar la descripción                    403
```

**Verifica**: el primero pasa y los otros dos no. Las variables de CI/CD son `admin_cicd_variables` y los ajustes del proyecto son `admin_project`: los dos empiezan en Maintainer. Es la razón por la que en la Semana 10 los secretos del pipeline pueden vivir en variables de proyecto sin que todo el equipo los lea.

---

## Paso 5: Lo que da un Maintainer de proyecto, y hasta dónde llega

**Por qué**: `revisor` es Guest en el grupo y Maintainer directo en `app`. Es la elevación puntual de la práctica 02, y aquí se comprueba que hace lo que debía: manda en `app` y no manda en nada más.

```bash
probar "revisor: cambiar la descripción"      "$T_REV" PUT "$API/projects/$P" "description=Plataforma de $DOM"
probar "revisor: ver las variables de CI/CD"  "$T_REV" GET "$API/projects/$P/variables"
probar "revisor: añadir miembros al GRUPO"    "$T_REV" POST "$API/groups/$GID/members" "user_id=$UID_AUD" "access_level=30"
probar "revisor: ver el subgrupo ci"          "$T_REV" GET "$API/groups/$G%2Fci"
probar "revisor: leer el árbol de código"     "$T_REV" GET "$API/projects/$P/repository/tree"
```

```
revisor: cambiar la descripción                200
revisor: ver las variables de CI/CD            200
revisor: añadir miembros al GRUPO              403
revisor: ver el subgrupo ci                    200
revisor: leer el árbol de código               200
```

**Verifica** las tres lecciones de esa tabla:

1. En `app` administra: cambia ajustes y ve las variables.
2. En el **grupo** no: añadir miembros al grupo es `admin_group_member`, que empieza en Owner. Su Maintainer no sale del proyecto.
3. En el subgrupo `ci` entra, pero como Guest heredado: ve que existe, y poco más.

Ese `403` de la tercera línea es la razón de ser de la elevación directa. Si a `revisor` le hubieras dado Maintainer en el grupo, ese `403` habría sido un `201`, y con él la capacidad de repartir accesos a todo el árbol.

---

## Paso 6: Lo que ve alguien sin credenciales

**Por qué**: es la comprobación de visibilidad de la teoría 06, y la que conviene repetir cada vez que se toca un ajuste de visibilidad.

```bash
printf '%-46s %s\n' "anónimo: ver el proyecto" \
  "$(curl -s -o /dev/null -w '%{http_code}' "$API/projects/$P")"
printf '%-46s %s\n' "anónimo: ver el grupo" \
  "$(curl -s -o /dev/null -w '%{http_code}' "$API/groups/$G")"
```

```
anónimo: ver el proyecto                       404
anónimo: ver el grupo                          404
```

**Verifica**: los dos son `404`. GitLab no distingue entre "no existe" y "no puedes verlo", precisamente para no confirmar la existencia de recursos privados. **Si alguno devuelve `200`, tienes algo público que no querías**: revisa la visibilidad antes de seguir.

---

## Paso 7: Confirmar que nada se rompió

**Por qué**: dos de las pruebas escribían (`PUT` de descripción). Conviene comprobar el estado real después de una práctica que toca la instancia.

```bash
curl -s -H "$H" "$API/projects/$P" | jq '{description, visibility}'
curl -s -H "$H" "$API/groups/$GID/members" | jq -r '.[] | "\(.access_level)\t\(.username)"' | sort -rn
```

**Verifica**: la descripción es la que puso `revisor` en el paso 5 —o la que quieras dejar— y los miembros del grupo siguen siendo cuatro, con `auditor` en `10`. Si `auditor` aparece con `30`, el `403` del paso 5 no fue tal: repasa qué token usaste.

---

## Paso 8: Revocar los tokens

**Por qué**: eran para una prueba y la prueba terminó. Un token de más es un acceso de más, y este además pertenece a un usuario cuya contraseña no conoce nadie.

```bash
for u in "$UID_DEV" "$UID_REV" "$UID_AUD"; do
  for id in $(curl -s -H "$H" "$API/personal_access_tokens?user_id=$u" \
                | jq -r '.[] | select(.name | startswith("prueba-permisos")) | .id'); do
    curl -s --request DELETE "$API/personal_access_tokens/$id" -H "$H" -o /dev/null -w "revocado $id: %{http_code}\n"
  done
done
```

**Verifica**: cada revocación responde `204`, y los tokens ya no valen:

```bash
curl -s -o /dev/null -w '%{http_code}\n' -H "PRIVATE-TOKEN: $T_DEV" "$API/user"
# 401

unset T_DEV T_REV T_AUD
```

`401` es la respuesta correcta: el token ya no existe. Compáralo con el `403` de los pasos anteriores —ahí el token era válido y el rol no llegaba— y con el `404` del paso 6, donde no había credencial ninguna sobre un recurso privado. Los tres números cuentan historias distintas y conviene no confundirlos:

| Código | Qué significa de verdad |
|:--:|---|
| `401` | La credencial no vale: no existe, caducó o fue revocada |
| `403` | La credencial vale, el rol no llega |
| `404` | O no existe, o no puedes verlo. GitLab no dice cuál |

---

## ✅ Resultado

- [ ] Has creado y usado un token para cada usuario de laboratorio
- [ ] Guest ve el proyecto y los issues, y recibe `403` al pedir el código
- [ ] Developer lee el código y recibe `403` en variables y en ajustes del proyecto
- [ ] El Maintainer de `app` administra el proyecto y recibe `403` al tocar los miembros del grupo
- [ ] Sin token, el proyecto y el grupo responden `404`
- [ ] Los tres tokens están revocados y responden `401`
- [ ] Sabes distinguir `401`, `403` y `404` sin dudar

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 03
```

Esta práctica no añade comprobaciones automáticas: comprueba que las de las prácticas 01 y 02 significan lo que crees. Su evidencia está en la rúbrica.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `crear_token` devuelve `null` | Tu token no es de administrador, o le falta scope `api` | Crea uno nuevo desde tu perfil con scope `api` |
| `{"message":"400 Bad request - Expires at is invalid"}` | La fecha no está en `YYYY-MM-DD`, o excede el máximo de la instancia | `date -d '+2 days' +%F`; si sigue fallando, prueba con 7 días |
| Todas las pruebas devuelven `200` | Estás usando tu propio token en todas | Comprueba con `curl -H "PRIVATE-TOKEN: $T_AUD" "$API/user"` antes de empezar |
| Todas las pruebas devuelven `401` | La variable del token está vacía (terminal nueva) | Repite el paso 1: los tokens no se guardan en ningún archivo |
| El `403` esperado sale `404` | El usuario no es miembro de nada, así que ni ve el recurso | Repasa el paso 4 de la práctica 02 |
| El `403` esperado sale `201` o `200` | Ese usuario tiene más rol del previsto | `GET /projects/:id/members/all/:user_id` y corrige la membresía |
| El anónimo devuelve `200` | El proyecto o el grupo son públicos o internos | `PUT` con `visibility=private`, primero el proyecto y luego el grupo |
| `DELETE /personal_access_tokens/:id` devuelve `404` | Ya estaba revocado, o el `id` no es el del token | Lista otra vez con `?user_id=` y repite |
| No sabes si te quedan tokens sueltos | Es fácil perder la cuenta | `GET /personal_access_tokens?user_id=<id>` por cada usuario de laboratorio |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Práctica 02 — Tres usuarios y sus roles](02-tres-usuarios-y-sus-roles.md) | **Práctica 03** | [Práctica 04 — Compartir, auditar y recortar](04-compartir-auditar-y-recortar.md) |

# Práctica 01 — El árbol de la organización

> Dos subgrupos, dos ajustes de creación y una comprobación de que nada se movió de sitio. Es la estructura sobre la que van a nacer `infra` y `ci`.

**Duración estimada**: 50 min
**Prerrequisitos**: Semana 02 completada · Teorías [01](../1-teoria/01-namespaces-y-rutas.md) y [02](../1-teoria/02-grupos-y-subgrupos.md) leídas

---

## Contexto

La Semana 01 dejó un grupo con un proyecto dentro. Eso basta para trabajar solo; no basta para que trabajen tres identidades con permisos distintos, que es lo que vas a montar en las prácticas siguientes.

Hoy creas los dos namespaces donde van a nacer los proyectos de las semanas 11, 12 y 17, y —más importante— decides **quién puede crear cosas** dentro de tu plataforma. Ese ajuste es el que impide que dentro de tres meses aparezca un proyecto que nadie recuerda haber creado, sin protecciones y fuera del inventario.

`app` no se toca. Su ruta está en tu `~/.bc-gitlab`, en tus remotos de Git y en las quince comprobaciones de esta semana.

---

## Paso 0: Preparar el terreno

**Por qué**: todos los pasos de esta semana necesitan las mismas tres cosas —la URL, el token y los identificadores del grupo y del proyecto—. Definirlas una vez evita la mitad de los errores de copiar y pegar.

```bash
source ~/.bc-gitlab

export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export RUTA_GRUPO="${PROYECTO%/*}"                          # plataforma-biblioteca
export G=$(printf '%s' "$RUTA_GRUPO" | jq -sRr @uri)        # ruta del grupo, codificada
export P=$(printf '%s' "$PROYECTO"   | jq -sRr @uri)        # ruta del proyecto, codificada
export GID=$(curl -s -H "$H" "$API/groups/$G" | jq -r '.id')

echo "grupo:    $RUTA_GRUPO (id $GID)"
echo "proyecto: $PROYECTO"
```

**Verifica**: el `id` es un número y no `null`.

```bash
curl -s -H "$H" "$API/groups/$G" | jq '{id, full_path, visibility, project_creation_level, subgroup_creation_level}'
```

```json
{
  "id": 5,
  "full_path": "plataforma-biblioteca",
  "visibility": "private",
  "project_creation_level": "maintainer",
  "subgroup_creation_level": "maintainer"
}
```

Si `id` sale `null`, la ruta del grupo no es la que crees: mira `PROYECTO` en `~/.bc-gitlab`. Los valores de creación pueden ser distintos a los del ejemplo; el paso 5 los fija.

---

## Paso 1: Mirar el árbol antes de tocarlo

**Por qué**: toda operación estructural empieza por saber qué hay. Es la costumbre que en la Semana 22 evita restaurar un backup sobre algo que no era lo que pensabas.

```bash
echo "== subgrupos"
curl -s -H "$H" "$API/groups/$GID/descendant_groups" | jq -r '.[].full_path'

echo "== proyectos, subgrupos incluidos, sin contar lo solo compartido"
curl -s -H "$H" "$API/groups/$GID/projects?include_subgroups=true&with_shared=false" \
  | jq -r '.[].path_with_namespace'
```

**Verifica**: la primera lista está vacía y la segunda tiene una sola línea, tu proyecto `app`.

---

## Paso 2: Comprobar que las rutas están libres

**Por qué**: crear con una ruta ocupada devuelve `400` con un mensaje de validación. Preguntar antes cuesta dos segundos y hace que el script sea repetible.

```bash
for ruta in infra ci; do
  echo -n "$ruta: "
  curl -s -H "$H" "$API/namespaces/$ruta/exists?parent_id=$GID" | jq -c '.'
done
```

```
infra: {"exists":false,"suggests":[]}
ci: {"exists":false,"suggests":[]}
```

**Verifica**: los dos responden `"exists": false`. Si alguno sale `true`, ya tienes un grupo **o un proyecto** con ese nombre ahí dentro: mira el paso 1 y decide antes de seguir.

> [!NOTE]
> `exists` mira rutas de grupo **y** de proyecto: comparten espacio de nombres dentro del mismo padre.

---

## Paso 3: Crear los dos subgrupos

**Por qué**: `infra` y `ci` son decisiones de organización y de permisos, no carpetas. Crearlos ahora significa que en la Semana 11 el proyecto `infra` nace en un namespace que ya tiene los permisos pensados.

**Con la UI**: `Grupo → New subgroup`. El formulario hereda la visibilidad del padre y valida la ruta mientras escribes.

**Con la API**:

```bash
curl -s --request POST "$API/groups" -H "$H" \
  --data-urlencode "name=Infra" \
  --data-urlencode "path=infra" \
  --data-urlencode "parent_id=$GID" \
  --data-urlencode "visibility=private" \
  --data-urlencode "description=Terraform, manifiestos y estado remoto. Su proyecto nace en la Semana 11" \
  | jq '{id, full_path, parent_id, visibility}'

curl -s --request POST "$API/groups" -H "$H" \
  --data-urlencode "name=CI" \
  --data-urlencode "path=ci" \
  --data-urlencode "parent_id=$GID" \
  --data-urlencode "visibility=private" \
  --data-urlencode "description=Componentes CI/CD y automatizacion de la plataforma. Sus proyectos nacen en las Semanas 12 y 17" \
  | jq '{id, full_path, parent_id, visibility}'
```

```json
{ "id": 6, "full_path": "plataforma-biblioteca/infra", "parent_id": 5, "visibility": "private" }
{ "id": 7, "full_path": "plataforma-biblioteca/ci",    "parent_id": 5, "visibility": "private" }
```

**Verifica**: `full_path` lleva el prefijo de tu grupo y `parent_id` coincide con `$GID`. Si `parent_id` sale `null`, se te olvidó el parámetro y acabas de crear dos grupos raíz: bórralos y repite.

```bash
curl -s -H "$H" "$API/groups/$GID/descendant_groups" | jq -r '.[] | "\(.full_path)\t\(.visibility)"'
# plataforma-biblioteca/ci	private
# plataforma-biblioteca/infra	private
```

---

## Paso 4: Confirmar que `app` sigue donde estaba

**Por qué**: es la comprobación que impide el error más caro de la semana. Mover `app` a un subgrupo "para que quede ordenado" cambia su ruta, y con ella el remoto de tu clon, la configuración del autograding y todo lo que la Semana 13 va a publicar en el registry.

```bash
curl -s -H "$H" "$API/projects/$P" \
  | jq '{path_with_namespace, namespace: {full_path: .namespace.full_path, parent_id: .namespace.parent_id}}'
```

```json
{
  "path_with_namespace": "plataforma-biblioteca/app",
  "namespace": { "full_path": "plataforma-biblioteca", "parent_id": null }
}
```

**Verifica**: `namespace.parent_id` es `null`, es decir, el proyecto cuelga directamente del grupo raíz. Es exactamente lo que comprueba `app-sigue-en-la-raiz`.

---

## Paso 5: Decidir quién puede crear cosas

**Por qué**: por defecto, un Developer puede crear proyectos en el grupo. Un proyecto creado así nace sin las protecciones que la Semana 07 va a exigir, con su creador como Owner, y fuera de cualquier inventario. La estructura la crea quien la administra.

**Con la UI**: `Grupo → Settings → General → Permissions and group features`, campos *Roles allowed to create projects* y *Roles allowed to create subgroups*.

**Con la API**:

```bash
curl -s --request PUT "$API/groups/$GID" -H "$H" \
  --data-urlencode "project_creation_level=maintainer" \
  --data-urlencode "subgroup_creation_level=owner" \
  | jq '{project_creation_level, subgroup_creation_level}'
```

```json
{ "project_creation_level": "maintainer", "subgroup_creation_level": "owner" }
```

**Verifica**: los dos valores son los del ejemplo. Los subgrupos heredan estos ajustes salvo que se cambien explícitamente en cada uno:

```bash
for sub in infra ci; do
  curl -s -H "$H" "$API/groups/$G%2F$sub" | jq -r '"\(.full_path)\t\(.project_creation_level)"'
done
```

---

## Paso 6: Poner descripción a todo lo que has creado

**Por qué**: dentro de dos meses vas a tener cuatro namespaces y ninguna pista de por qué existe cada uno. La descripción aparece en la interfaz, en la API y en la búsqueda; es la documentación más barata que hay.

```bash
curl -s --request PUT "$API/groups/$G%2Fci" -H "$H" \
  --data-urlencode "description=Componentes CI/CD y automatizacion de la plataforma. Sus proyectos nacen en las Semanas 12 y 17" \
  | jq -r '.description'
```

**Verifica**: los tres namespaces tienen descripción no vacía.

```bash
curl -s -H "$H" "$API/groups/$GID/descendant_groups" | jq -r '.[] | "\(.full_path)\t\(.description)"'
curl -s -H "$H" "$API/groups/$G" | jq -r '"\(.full_path)\t\(.description)"'
```

---

## Paso 7: Ensayar el borrado en un grupo de pruebas

**Por qué**: el borrado de grupos en la versión fijada **está programado, no es inmediato**. Conviene descubrirlo aquí, con un grupo vacío que no importa, y no en la Semana 22 con algo que sí.

```bash
# Un subgrupo desechable
PRUEBA_ID=$(curl -s --request POST "$API/groups" -H "$H" \
  --data-urlencode "name=Pruebas" --data-urlencode "path=pruebas" \
  --data-urlencode "parent_id=$GID" | jq -r '.id')
echo "id de pruebas: $PRUEBA_ID"

# Programar su borrado
curl -s --request DELETE "$API/groups/$PRUEBA_ID" -H "$H" -o /dev/null -w '%{http_code}\n'
# 202

# Ya está marcado, pero sigue existiendo
curl -s -H "$H" "$API/groups/$PRUEBA_ID" | jq '{full_path, marked_for_deletion_on}'
```

**Verifica**: el código es `202 Accepted` y `marked_for_deletion_on` trae una fecha. Ahora deshazlo y bórralo de verdad:

```bash
curl -s --request POST "$API/groups/$PRUEBA_ID/restore" -H "$H" | jq '{full_path, marked_for_deletion_on}'

# Borrado inmediato: exige repetir la ruta completa. Es la confirmación de GitLab.
curl -s --request DELETE \
  "$API/groups/$PRUEBA_ID?permanently_remove=true&full_path=$RUTA_GRUPO%2Fpruebas" \
  -H "$H" -o /dev/null -w '%{http_code}\n'
# 202

curl -s -H "$H" "$API/groups/$GID/descendant_groups" | jq -r '.[].full_path'
```

> [!WARNING]
> `permanently_remove=true` no tiene deshacer y se lleva **todo** lo que hubiera dentro: proyectos, issues, paquetes y registros. Aquí es seguro porque el grupo está vacío y lo acabas de crear. Fuera del laboratorio, antes de un borrado inmediato: `GET /groups/:id/projects?include_subgroups=true` y mira qué hay dentro.

**Verifica**: la lista final tiene solo `infra` y `ci`.

---

## ✅ Resultado

- [ ] Existe el subgrupo `infra`, privado y con descripción
- [ ] Existe el subgrupo `ci`, privado y con descripción
- [ ] Los dos cuelgan del grupo raíz: su `parent_id` es el `id` del grupo
- [ ] `app` sigue con `namespace.parent_id: null`
- [ ] El grupo raíz tiene `project_creation_level=maintainer`
- [ ] El grupo raíz tiene `subgroup_creation_level=owner`
- [ ] El grupo de pruebas ya no existe
- [ ] Sabes qué devuelve `DELETE /groups/:id` y cómo se restaura

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 03
```

De las quince comprobaciones, esta práctica cubre las seis primeras. Las demás llegan con las prácticas 02 y 04.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `{"message":"404 Group Not Found"}` | La ruta del grupo va sin codificar, o el token no ve el grupo | Recalcula `G` con `jq -sRr @uri`; comprueba `curl -s -H "$H" "$API/user"` |
| `{"path":["has already been taken"]}` | Ya existe un grupo **o proyecto** con esa ruta ahí | `namespaces/<ruta>/exists?parent_id=$GID` y elige otra o borra la anterior |
| El subgrupo aparece con `parent_id: null` | Faltó `parent_id` en el `POST` | Bórralo y vuelve a crearlo; no hay forma de "meterlo dentro" salvo transferirlo |
| `403 Forbidden` al hacer `PUT` sobre el grupo | El token no es de un Owner del grupo | En el laboratorio eres `root`: comprueba que el token es el tuyo y tiene scope `api` |
| `subgroup_creation_level=developer` da error de validación | Solo admite `owner` y `maintainer` | Usa uno de esos dos (teoría 02, sección 2.4) |
| El `DELETE` devuelve 202 pero el grupo sigue ahí | Es el comportamiento correcto: el borrado se programa | `POST /groups/:id/restore` para deshacer; `permanently_remove=true` para borrar ya |
| `permanently_remove` devuelve 400 | Falta `full_path`, está mal escrito, o el grupo es raíz | La opción solo vale para subgrupos y exige la ruta completa exacta |
| La comprobación `subgrupos-privados` falla | El subgrupo se creó con otra visibilidad | `PUT /groups/:id` con `visibility=private` |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Semana 03](../README.md) | **Práctica 01** | [Práctica 02 — Tres usuarios y sus roles](02-tres-usuarios-y-sus-roles.md) |

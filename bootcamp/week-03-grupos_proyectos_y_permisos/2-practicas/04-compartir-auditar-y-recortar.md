# Práctica 04 — Compartir, auditar y recortar

> Un grupo invitado con techo y con fecha, una auditoría que cabe en un script, y la parte que casi nunca se hace: quitar lo que sobra.

**Duración estimada**: 50 min
**Prerrequisitos**: Prácticas 01 a 03 completadas · Teorías [05](../1-teoria/05-compartir-grupos-y-proyectos.md) y [08](../1-teoria/08-disenar-el-arbol-con-menor-privilegio.md) leídas

---

## Contexto

Llega una revisión externa: gente que no es de tu equipo necesita leer `app` durante un tiempo limitado. Podrías invitarlos uno a uno y apuntarte en algún sitio que hay que darlos de baja en diciembre. Nadie hace esa segunda parte.

La alternativa que tiene CE es el **grupo invitado**: una sola operación, con un techo de acceso que no se puede superar y una fecha de fin que se cumple sola. Es el único mecanismo del modelo de permisos que limita hacia abajo en vez de sumar.

Y ya que hoy montas accesos, cierras la semana haciendo lo contrario: una auditoría de todo lo que hay y la retirada de lo que ya no hace falta.

---

## Paso 0: Recuperar el entorno

```bash
source ~/.bc-gitlab
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export RUTA_GRUPO="${PROYECTO%/*}"
export G=$(printf '%s' "$RUTA_GRUPO" | jq -sRr @uri)
export P=$(printf '%s' "$PROYECTO"   | jq -sRr @uri)
export GID=$(curl -s -H "$H" "$API/groups/$G" | jq -r '.id')
export DOM="${RUTA_GRUPO#plataforma-}"
export UID_AUD=$(curl -s -H "$H" "$API/users?username=auditor-$DOM" | jq -r '.[0].id')
echo "grupo $GID · auditor $UID_AUD"
```

**Verifica**: los dos identificadores son números.

---

## Paso 1: Crear el grupo de los externos

**Por qué**: el grupo invitado es de **ellos**, no tuyo: su gracia es que quien administra esa lista de personas es quien la conoce. Aquí lo creas tú porque estás solo en el laboratorio, pero el modelo mental importa: tú controlas el techo, no la lista.

Va en la raíz de la instancia, **fuera** de tu plataforma: un subgrupo de tu propio árbol no serviría de ejemplo, porque sus miembros ya heredarían acceso.

```bash
export GID_EXT=$(curl -s --request POST "$API/groups" -H "$H" \
  --data-urlencode "name=Contratistas $DOM" \
  --data-urlencode "path=contratistas-$DOM" \
  --data-urlencode "visibility=private" \
  --data-urlencode "description=Revisores externos. Acceso temporal por invitacion al proyecto app" \
  | jq -r '.id')

echo "grupo invitado: $GID_EXT"
```

**Verifica**: es un grupo raíz, sin padre.

```bash
curl -s -H "$H" "$API/groups/$GID_EXT" | jq '{full_path, parent_id, visibility}'
# { "full_path": "contratistas-biblioteca", "parent_id": null, "visibility": "private" }
```

---

## Paso 2: Poner a alguien dentro, con rol alto

**Por qué**: para ver el techo funcionar hace falta alguien cuyo rol en el grupo invitado sea **mayor** que el techo. `auditor` va a ser Owner de su propio grupo y aun así solo podrá leer.

```bash
curl -s --request POST "$API/groups/$GID_EXT/members" -H "$H" \
  --data-urlencode "user_id=$UID_AUD" \
  --data-urlencode "access_level=50" | jq '{username, access_level}'
```

```json
{ "username": "auditor-biblioteca", "access_level": 50 }
```

**Verifica**: `access_level` es `50` **en su grupo**. En tu plataforma sigue siendo Guest; eso no cambia.

---

## Paso 3: Compartir `app` con techo y con fecha

**Por qué**: es la operación de la semana. El `group_access` es el máximo que puede alcanzar cualquier miembro del grupo invitado, y `expires_at` hace que la relación termine sin que nadie se acuerde.

**Con la UI**: `Proyecto app → Manage → Members → Invite a group`, grupo `contratistas-<dominio>`, rol máximo *Reporter*, fecha de caducidad.

**Con la API**:

```bash
curl -s --request POST "$API/projects/$P/share" -H "$H" \
  --data-urlencode "group_id=$GID_EXT" \
  --data-urlencode "group_access=20" \
  --data-urlencode "expires_at=2026-12-31" -o /dev/null -w '%{http_code}\n'
# 201
```

**Verifica** el resultado en el propio proyecto:

```bash
curl -s -H "$H" "$API/projects/$P" \
  | jq '.shared_with_groups[] | {group_full_path, group_access_level, expires_at}'
```

```json
{
  "group_full_path": "contratistas-biblioteca",
  "group_access_level": 20,
  "expires_at": "2026-12-31"
}
```

El campo se envía como `group_access` y se lee como `group_access_level`. Las comprobaciones `app-compartido-con-un-grupo` y `comparticion-de-solo-lectura` miran el segundo.

---

## Paso 4: Comprobar que el techo es un techo

**Por qué**: es la propiedad que justifica todo el mecanismo, y se comprueba en dos peticiones. `auditor` es Owner de su grupo y Guest en el tuyo; por la compartición le llega Reporter, y Reporter es lo que puede.

```bash
T_AUD=$(curl -s --request POST "$API/users/$UID_AUD/personal_access_tokens" -H "$H" \
  --data-urlencode "name=prueba-techo" \
  --data-urlencode "scopes[]=api" \
  --data-urlencode "expires_at=$(date -d '+2 days' +%F)" | jq -r '.token')

printf '%-46s %s\n' "auditor: leer el árbol de código" \
  "$(curl -s -o /dev/null -w '%{http_code}' -H "PRIVATE-TOKEN: $T_AUD" "$API/projects/$P/repository/tree")"
printf '%-46s %s\n' "auditor: cambiar la descripción" \
  "$(curl -s -o /dev/null -w '%{http_code}' --request PUT -H "PRIVATE-TOKEN: $T_AUD" \
       --data-urlencode "description=No deberia poder" "$API/projects/$P")"
```

```
auditor: leer el árbol de código               200
auditor: cambiar la descripción                403
```

**Verifica**: el primero pasó a `200` —en la práctica 03 era `403`— porque ahora le llega Reporter por la compartición. El segundo sigue en `403`: ser Owner de su grupo no le sube el techo.

Y así se ve desde tu lado:

```bash
curl -s -H "$H" "$API/projects/$P/members/all" \
  | jq -r '.[] | "\(.access_level)\t\(.username)"' | sort -rn
```

```
50	root
40	revisor-biblioteca
30	dev-biblioteca
20	auditor-biblioteca
```

`auditor` aparece con `20`, no con `10` ni con `50`: el máximo entre lo que hereda de tu grupo (Guest) y lo que le llega con techo (Reporter).

Revoca ese token, que ya cumplió:

```bash
for id in $(curl -s -H "$H" "$API/personal_access_tokens?user_id=$UID_AUD" \
              | jq -r '.[] | select(.name == "prueba-techo") | .id'); do
  curl -s --request DELETE "$API/personal_access_tokens/$id" -H "$H" -o /dev/null -w '%{http_code}\n'
done
unset T_AUD
```

---

## Paso 5: La auditoría, en un script

**Por qué**: una auditoría que no está escrita no se repite. Este script responde a las tres preguntas de la [teoría 08](../1-teoria/08-disenar-el-arbol-con-menor-privilegio.md) y vive en el repositorio, que es donde se encuentra dentro de seis meses.

Créalo en tu clon de `app` como `scripts/auditar-accesos.sh`:

```bash
#!/usr/bin/env bash
# Audita quién tiene acceso al árbol de la plataforma.
# Uso: scripts/auditar-accesos.sh
set -euo pipefail

source ~/.bc-gitlab
API="$GITLAB_URL/api/v4"
H="PRIVATE-TOKEN: $GITLAB_TOKEN"
G=$(printf '%s' "${PROYECTO%/*}" | jq -sRr @uri)
P=$(printf '%s' "$PROYECTO"      | jq -sRr @uri)

echo "== 1. Acceso efectivo al grupo raíz"
curl -s -H "$H" "$API/groups/$G/members/all?per_page=100" \
  | jq -r '.[] | "\(.access_level)\t\(.username)\t\(.expires_at // "sin caducidad")"' | sort -rn

echo
echo "== 2. Excepciones: miembros directos del proyecto"
curl -s -H "$H" "$API/projects/$P/members?per_page=100" \
  | jq -r '.[] | "\(.access_level)\t\(.username)"' | sort -rn

echo
echo "== 3. Accesos desde fuera: grupos invitados"
curl -s -H "$H" "$API/projects/$P" \
  | jq -r '.shared_with_groups[] | "\(.group_access_level)\t\(.group_full_path)\t\(.expires_at // "SIN CADUCIDAD")"'

echo
echo "== Hallazgos"
owners=$(curl -s -H "$H" "$API/groups/$G/members/all?per_page=100" | jq '[.[] | select(.access_level == 50)] | length')
[ "$owners" -gt 1 ] && echo "AVISO: $owners Owners en el grupo raíz"
curl -s -H "$H" "$API/projects/$P" \
  | jq -r '.shared_with_groups[] | select(.expires_at == null) | "AVISO: \(.group_full_path) comparte sin caducidad"'
echo "Auditoría del $(date +%F)"
```

```bash
chmod +x scripts/auditar-accesos.sh
./scripts/auditar-accesos.sh
```

**Verifica**: las tres secciones traen datos y la sección de hallazgos no avisa de nada. Si avisa, arréglalo antes de seguir: para eso está.

> [!NOTE]
> El script lee `~/.bc-gitlab`, que tiene tu token. **No** lo copies dentro del repositorio ni pongas el token en el script: lo que se versiona es el procedimiento, nunca la credencial.

---

## Paso 6: Recortar lo que sobra

**Por qué**: es la parte que nunca se hace, y es la única que reduce riesgo de verdad. Tres comprobaciones y sus retiradas.

**Un solo Owner**:

```bash
curl -s -H "$H" "$API/groups/$GID/members/all" | jq -r '.[] | select(.access_level == 50) | .username'
# root
```

Si aparece alguien más, bájalo al rol que le corresponda:

```bash
# curl -s --request PUT "$API/groups/$GID/members/<user_id>" -H "$H" --data-urlencode "access_level=30"
```

**Accesos externos sin fecha**: la salida de la sección 3 del script no debe tener ningún `SIN CADUCIDAD`. Si lo tiene, se le pone:

```bash
# La compartición se actualiza volviéndola a crear: retira y comparte otra vez con fecha
# curl -s --request DELETE "$API/projects/$P/share/<group_id>" -H "$H"
```

**Elevaciones directas que ya no hacen falta**: la de `revisor` sigue siendo válida —administra `app`— así que se queda, y por eso está documentada. Para retirar una que no lo estuviera:

```bash
# curl -s --request DELETE "$API/projects/$P/members/<user_id>" -H "$H"
```

**Verifica**: vuelve a pasar el script y comprueba que la sección de hallazgos sale limpia.

---

## Paso 7: Cerrar la capa en el repositorio

**Por qué**: el estado de la instancia es el entregable, pero la decisión que hay detrás vive en el repositorio. `docs/organizacion.md` se creó en la práctica 02: ahora se completa con el acceso externo y la fecha de la auditoría.

Añade a `docs/organizacion.md`:

```markdown
## Accesos externos
| Grupo invitado | Alcance | Techo | Caduca |
|---|---|---|---|
| contratistas-<dominio> | proyecto app | Reporter (20) | 2026-12-31 |

## Última auditoría
2026-08-23 — sin hallazgos. Script: `scripts/auditar-accesos.sh`
```

```bash
git add docs/organizacion.md scripts/auditar-accesos.sh
git commit -m "feat(org): auditoria de accesos y acceso externo con caducidad"
git push
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/repository/files/scripts%2Fauditar-accesos.sh?ref=main" | jq -r '.file_name'
# auditar-accesos.sh
```

---

## ✅ Resultado

- [ ] Existe el grupo `contratistas-<dominio>`, fuera de tu plataforma
- [ ] `app` está compartido con él, con techo Reporter (20) y con `expires_at`
- [ ] Un miembro Owner del grupo invitado solo alcanza Reporter en `app`
- [ ] El árbol tiene un único Owner
- [ ] `scripts/auditar-accesos.sh` está en `main` y su sección de hallazgos sale limpia
- [ ] `docs/organizacion.md` documenta el acceso externo y la fecha de la auditoría
- [ ] No queda ningún token de prueba vivo

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 03
```

```
15 de 15 verificaciones superadas.
```

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `POST /projects/:id/share` devuelve `404` | El `group_id` no existe o tu usuario no lo ve | Recupera el `id` con `GET /groups/contratistas-<dominio>` |
| El `share` devuelve `409` con "already shared" | Ya compartiste ese proyecto con ese grupo | `DELETE /projects/:id/share/<group_id>` y vuelve a compartir con los valores buenos |
| No se puede compartir con un grupo antepasado | Sus miembros ya tienen acceso por herencia | Usa un grupo de fuera de tu árbol |
| `comparticion-de-solo-lectura` falla | El techo se puso por encima de 20 | Retira la compartición y vuelve a crearla con `group_access=20` |
| `auditor` sigue sin ver el código | La compartición no llegó, o el token es antiguo | Revisa `shared_with_groups` y crea el token después de compartir |
| `auditor` puede cambiar ajustes | El techo se puso en 40 | Retira y comparte con `group_access=20` |
| `un-solo-owner` falla | Algún usuario de laboratorio quedó como Owner del grupo raíz | `PUT /groups/:id/members/<user_id>` con el rol correcto |
| El script falla con `jq: error ... null` | El proyecto no tiene grupos invitados y `shared_with_groups` viene vacío | Es el estado antes del paso 3; repite tras compartir |
| `set -euo pipefail` corta el script sin mensaje | Una llamada devolvió vacío por token caducado | `curl -s -H "$H" "$API/user"` para comprobar el token |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Práctica 03 — Probar los permisos de verdad](03-probar-los-permisos-de-verdad.md) | **Práctica 04** | [Proyecto de la Semana 03](../3-proyecto/README.md) |

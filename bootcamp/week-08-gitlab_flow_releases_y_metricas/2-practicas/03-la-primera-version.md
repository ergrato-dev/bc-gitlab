# Práctica 03 — La primera versión

> Generas el CHANGELOG de la `0.1.0` contra una rama y lo fusionas por merge request, etiquetas `main` con un tag firmado, publicas la release con sus notas y su hito, y cierras el hito pasando lo pendiente a la `0.2.0`.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 02 completada · Teoría [02](../1-teoria/02-versionado-semantico.md), [03](../1-teoria/03-releases-en-gitlab.md) y [04](../1-teoria/04-changelog-generado.md) leídas

---

## Contexto

El orden de esta práctica importa. El tag tiene que apuntar al commit que ya incluye el CHANGELOG, y la release se crea sobre el tag:

```
CHANGELOG en una rama → merge request → main → tag firmado v0.1.0 → release → hito cerrado
```

Si inviertes los dos primeros, `v0.1.0` no contiene su propio CHANGELOG. Y los tags `v*` no se mueven (Semana 07): habría que borrarlo desde la API y repetir.

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1-2 | `CHANGELOG.md` con la `0.1.0` en `main` | `changelog-0-1-0-en-main` |
| 3 | Tag `v0.1.0` anotado y firmado | `tag-v0-1-0-anotado` |
| 4 | Release `v0.1.0` con notas e hito | `release-v0-1-0-con-notas`, `release-v0-1-0-con-hito` |
| 5 | Hito `v0.1.0` cerrado | `hito-v0-1-0-cerrado` |

---

## Paso 0: Preparar el terreno

```bash
source ~/.bc-gitlab
source ~/.bc-gitlab-s08
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
```

**Verifica**:

```bash
curl -s -H "$HR" "$API/user" | jq -r .username                                # revisor-<tu-dominio>
curl -s -H "$H" "$API/projects/$P/merge_requests?state=opened" | jq length       # 0: nada a medias
git tag -l 'v*'                                                                  # vacío
```

Si hay merge requests abiertas, decide ahora si entran en la `0.1.0` (fusiónalas con su trailer) o no (déjalas abiertas: no afectan). Lo que no puede pasar es que se fusionen **entre** el paso 2 y el 3.

---

## Paso 1: El CHANGELOG, contra una rama

**Por qué**: un `POST` contra `main` devolvería `403 Forbidden - You are not allowed to commit a changelog on this branch`, y es lo correcto (teoría 04, apartado 2.3). No lo pruebes: si alguna capa hubiera retrocedido, escribiría en `main`. El CHANGELOG entra por merge request como todo lo demás.

El issue, la rama y el `POST` contra ella:

```bash
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Publicar v0.1.0" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "milestone_id=$(curl -s -H "$H" "$API/projects/$P/milestones?title=v0.1.0" | jq -r '.[0].id')" \
  | jq -r .iid)
RAMA="$IID-changelog-0.1.0"
echo "export IID_REL=$IID" >> ~/.bc-gitlab-s08

curl -s --request POST "$API/projects/$P/repository/branches" -H "$H" \
  --data-urlencode "branch=$RAMA" --data-urlencode "ref=main" | jq -r .name

curl -s --request POST "$API/projects/$P/repository/changelog" -H "$H" \
  --data-urlencode "version=0.1.0" \
  --data-urlencode "from=$PRIMERO" \
  --data-urlencode "branch=$RAMA" \
  --data-urlencode "message=docs: changelog de la 0.1.0" \
  -o /dev/null -w '%{http_code}\n'
```

El `message` no es opcional en `app`: el commit lo escribe GitLab con `GL_PROTOCOL=web`, pasa por el hook de la Semana 07, y el mensaje por defecto (`Add changelog for version 0.1.0`) no es convencional.

**Verifica**: el último `POST` devuelve `200` y el archivo está en la rama:

```bash
curl -s -H "$H" "$API/projects/$P/repository/files/CHANGELOG.md/raw?ref=$RAMA"
```

Una cabecera `## 0.1.0 (<hoy>)` y las mismas secciones que la vista previa de la práctica 02.

Si tu lenguaje guarda la versión en un archivo (`package.json`, `pyproject.toml`), añade ahora un commit firmado a esta rama que la suba a `0.1.0`: `git fetch && git switch "$RAMA"`, edita, `git commit -S -m "chore: version 0.1.0"`, `git push`.

---

## Paso 2: La merge request del CHANGELOG

**Por qué**: es el último cambio de la `0.1.0`. La revisión aquí es leer las notas como si fueras quien usa `app`.

```bash
MR=$(curl -s --request POST "$API/projects/$P/merge_requests" -H "$H" \
  --data-urlencode "source_branch=$RAMA" \
  --data-urlencode "target_branch=main" \
  --data-urlencode "title=docs: changelog de la 0.1.0" \
  --data-urlencode "description=Closes #$IID" \
  --data-urlencode "remove_source_branch=true" \
  | jq -r .iid)

curl -s --request POST "$API/projects/$P/merge_requests/$MR/approve" -H "$HR" > /dev/null
bash scripts/gobernanza.sh "$MR" && {
  SHA=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .sha)
  curl -s --request PUT "$API/projects/$P/merge_requests/$MR/merge" -H "$H" \
    --data-urlencode "sha=$SHA" --data-urlencode "squash=true" | jq -r .state
}
```

**Verifica**:

```bash
git pull --ff-only
grep -n '^## ' CHANGELOG.md          # ## 0.1.0 (<hoy>)
git log -1 --no-merges --format='%G? %s'   # N docs: changelog de la 0.1.0 (!N)
```

`N` en la firma: el commit de squash lo escribe GitLab, no tú. El hook lo acepta porque llega por `web`. Lo que sí firmas es el tag del paso siguiente.

---

## Paso 3: El tag firmado

**Por qué**: la versión es el tag. Anotado para que diga quién y cuándo; firmado para que se pueda comprobar que lo hiciste tú.

```bash
git switch main && git pull --ff-only
git log -1 --format='%h %s'                    # el CHANGELOG, o su commit de fusión con rebase_merge
git tag -s v0.1.0 -m "v0.1.0"
git tag -v v0.1.0                              # Good "git" signature ...
git push origin v0.1.0
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/repository/tags/v0.1.0" \
  | jq '{name, protected, anotado: (.target != .commit.id), commit: .commit.title}'
```

`protected: true` (por el `v*` de la Semana 07), `anotado: true`, y el commit es el del CHANGELOG (o su commit de fusión).

Si `git tag -v` no dice `Good`, **no empujes**: `git tag -d v0.1.0`, revisa `user.signingkey` y `gpg.ssh.allowedSignersFile` (Semana 02) y repite. Un tag empujado sin firma ya no se corrige con `git push --force`: está protegido.

---

## Paso 4: La release

**Por qué**: el tag es para Git; la release es para quien usa `app`. Las notas salen del mismo generador que el CHANGELOG, así que no pueden contradecirlo.

```bash
NOTAS=$(curl -s -G -H "$H" "$API/projects/$P/repository/changelog" \
  --data-urlencode "version=0.1.0" --data-urlencode "from=$PRIMERO" --data-urlencode "to=v0.1.0" \
  | jq -r .notes)

curl -s --request POST "$API/projects/$P/releases" -H "$H" \
  --data-urlencode "tag_name=v0.1.0" \
  --data-urlencode "name=v0.1.0" \
  --data-urlencode "description=$NOTAS" \
  --data-urlencode "milestones[]=v0.1.0" \
  --data-urlencode "assets[links][][name]=CHANGELOG.md" \
  --data-urlencode "assets[links][][url]=$GITLAB_URL/$PROYECTO/-/blob/v0.1.0/CHANGELOG.md" \
  | jq '{tag_name, released_at, hitos: [.milestones[].title], enlaces: [.assets.links[].name], evidencias: (.evidences | length)}'
```

`to=v0.1.0` fija el final del rango en el tag: si alguien fusionara algo en `main` mientras tanto, no entraría en las notas.

**Verifica**: `hitos: ["v0.1.0"]`, un enlace, y en `Deploy → Releases` la página con las notas en español. Unos segundos después, la evidencia:

```bash
curl -s -H "$H" "$API/projects/$P/releases/v0.1.0" | jq '.evidences[] | {collected_at, filepath}'
```

---

## Paso 5: Cerrar el hito

**Por qué**: un hito abierto después de su release dice que la versión no está terminada. Lo que no entró pasa a la siguiente, explícitamente.

```bash
M1=$(curl -s -H "$H" "$API/projects/$P/milestones?title=v0.1.0" | jq -r '.[0].id')
M2=$(curl -s --request POST "$API/projects/$P/milestones" -H "$H" \
  --data-urlencode "title=v0.2.0" --data-urlencode "description=Siguiente versión MENOR. Ver ADR-006." \
  | jq -r .id)

for i in $(curl -s -H "$H" "$API/projects/$P/issues?milestone=v0.1.0&state=opened&per_page=100" | jq -r '.[].iid'); do
  curl -s --request PUT "$API/projects/$P/issues/$i" -H "$H" --data-urlencode "milestone_id=$M2" \
    | jq -r '"#\(.iid) → \(.milestone.title)"'
done

curl -s --request PUT "$API/projects/$P/milestones/$M1" -H "$H" --data-urlencode "state_event=close" | jq -r .state
```

**Verifica**: el último comando da `closed`, y el hito `v0.1.0` no tiene issues abiertos:

```bash
curl -s -H "$H" "$API/projects/$P/issues?milestone=v0.1.0&state=opened" | jq length     # 0
```

El tablero de la Semana 05 ya muestra los issues movidos bajo `v0.2.0`. Cambia el enlace "Tablero de v0.1.0" de la portada de la wiki por el mismo tablero filtrado por `v0.2.0`: el de `v0.1.0` ya solo enseña issues cerrados.

---

## ✅ Resultado

- [ ] `CHANGELOG.md` con la sección `0.1.0` en `main`, entrado por merge request
- [ ] Tag `v0.1.0` anotado, firmado con tu clave y protegido
- [ ] Release `v0.1.0` con notas generadas, el hito y un enlace al CHANGELOG
- [ ] Hito `v0.1.0` cerrado, lo pendiente en `v0.2.0`

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 08
```

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| El `POST` a la rama devuelve `422` con `no previous tag` | Falta `from` | `echo $PRIMERO`; si está vacío, `git rev-list --max-parents=0 main` |
| El `POST` devuelve `422` con `el asunto no sigue Conventional Commits` | El hook rechazó el commit: falta `message` o no es convencional | Repite con `message=docs: ...` |
| El `POST` devuelve `200` pero el archivo no cambia | Ya había una sección `## 0.1.0`: el `POST` no la duplica | Bórrala a mano en la rama o asume la que hay |
| `git push origin v0.1.0` rechazado con `You are not allowed to create this tag as it is protected` | Tu rol efectivo en `app` es menor que Maintainer | Comprueba `GET .../members/all/<tu-id>` |
| La release da `409 Release already exists` | Ya la creaste | `PUT .../releases/v0.1.0` con `description` |
| La release da `400 Milestone(s) not found` | El título del hito no es exactamente `v0.1.0` | `GET .../milestones` y usa el título exacto |
| `evidencias: 0` y no aparece nunca | Pasaste un `released_at` anterior: release histórica | Es correcto que no tenga; no lo repitas en la `v0.1.1` |
| El tag apunta a un commit anterior al CHANGELOG | Etiquetaste antes del `git pull` | **Solo si aún no hay release** (`GET .../releases/v0.1.0` da `404`): `DELETE .../repository/tags/v0.1.0` y repite desde el paso 3. Si ya está publicada, no la toques: déjala, publica la siguiente versión y anótalo en el ADR-006. Un número de versión no se reutiliza |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Práctica 02 — Cambios que cuentan](02-cambios-que-cuentan.md) | **Práctica 03** | [Práctica 04 — El primer parche](04-el-primer-parche.md) |

# Práctica 01 — GitLab Flow en `app`

> Escribes la decisión del modelo de ramas, proteges las ramas de release antes de que exista ninguna, cambias la plantilla de squash para que el trailer `Changelog:` sobreviva, y subes la configuración del CHANGELOG en español por merge request.

**Duración estimada**: 50 min
**Prerrequisitos**: Semana 07 completada · Teoría [01](../1-teoria/01-modelos-de-ramas.md), [02](../1-teoria/02-versionado-semantico.md) y [04](../1-teoria/04-changelog-generado.md) leídas

---

## Contexto

Esta práctica no publica nada. Prepara el terreno para que todo lo que se fusione a partir de ahora cuente: si la plantilla de squash no se cambia **antes** de la primera fusión de la semana, los trailers de esa fusión se pierden y no hay forma de recuperarlos sin reescribir `main`.

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | ADR-006 en la wiki | `adr-006-en-la-wiki` |
| 2 | `release/*` protegidas | `ramas-release-protegidas`, `release-solo-por-merge-request`, `release-sin-force-push` |
| 3 | Plantilla de squash con el cuerpo del primer commit | `plantilla-de-squash-con-trailers` |
| 4 | `.gitlab/changelog_config.yml` en `main` | `configuracion-del-changelog` |

---

## Paso 0: Preparar el terreno y el token del revisor

**Por qué**: esta semana hay nueve merge requests y todas necesitan la aprobación de `revisor`, porque el hook de la Semana 07 rechaza en `main` lo que no lleva `Approved-by:`. El token se revoca al final del proyecto (punto 5).

```bash
source ~/.bc-gitlab
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
export YO=$(curl -s -H "$H" "$API/user" | jq -r .username)
export REV=revisor-<tu-dominio>

export UID_REV=$(curl -s -H "$H" "$API/users?username=$REV" | jq -r '.[0].id // empty')
[[ "$UID_REV" =~ ^[0-9]+$ ]] || { echo "No existe $REV: revisa el nombre y NO sigas"; return 1 2>/dev/null || exit 1; }
T_REV=$(curl -s --request POST "$API/users/$UID_REV/personal_access_tokens" \
  -H "PRIVATE-TOKEN: ${GITLAB_ADMIN_TOKEN:-$GITLAB_TOKEN}" \
  --data-urlencode "name=flujo-s08" \
  --data-urlencode "scopes[]=api" \
  --data-urlencode "expires_at=$(date -d '+7 days' +%F)" \
  | jq -r '.token')
[ -n "$T_REV" ] && [ "$T_REV" != null ] || { echo "No se creó el token: revisa permisos de administrador y NO sigas"; return 1 2>/dev/null || exit 1; }
export HR="PRIVATE-TOKEN: $T_REV"

grep -qs UID_REV ~/.bc-gitlab-s08 || echo "export REV=$REV UID_REV=$UID_REV" >> ~/.bc-gitlab-s08
```

El token no se guarda en ningún archivo. Si cierras la terminal entre prácticas, repite este paso: se crea otro con el mismo nombre, y el punto 5 del proyecto los revoca todos. `~/.bc-gitlab-s08` no se sobrescribe: guarda las variables de toda la semana (`PRIMERO`, `FIX`…), y la última línea solo escribe si aún no existe.

**Verifica**:

```bash
curl -s -H "$HR" "$API/user" | jq -r .username                 # revisor-<tu-dominio>
curl -s -H "$H" "$API/projects/$P/merge_requests?state=opened" | jq length   # 0
```

Si hay merge requests abiertas de semanas anteriores, fusiónalas o ciérralas **después** del paso 3, nunca antes.

---

## Paso 1: El ADR-006

**Por qué**: el modelo de ramas, la numeración y qué se parchea son decisiones que alguien cuestionará dentro de seis meses. La respuesta tiene que estar escrita con sus razones, antes de la primera versión.

```bash
curl -s --request POST "$API/projects/$P/wikis" -H "$H" \
  --data-urlencode "title=ADR-006 Modelo de ramas y versiones" \
  --data-urlencode "content@-" <<'EOF' | jq -r .slug
# ADR-006: Modelo de ramas y versiones

**Estado**: aceptada · **Fecha**: <hoy> · **Decide**: <tú>, con revisión de revisor-<dominio>

## Contexto

app es una librería de dominio: quien la usa la fija a una versión concreta y necesita
parches sin cambios de comportamiento. Hasta ahora no había versiones, solo main.

## Decisión

- **Modelo**: GitLab Flow con ramas de release. main es la integración; todo entra
  primero en main por merge request (upstream first).
- **Ramas de release**: release/X.Y, creadas desde el tag vX.Y.0 cuando hace falta el
  primer parche, no antes. Protegidas igual que main. Se mantiene solo la última MENOR.
- **Parches**: el arreglo se fusiona en main y se lleva a release/X.Y con cherry-pick -x
  del commit de squash, por merge request.
- **Versiones**: SemVer con tags v* anotados y firmados. Mientras MAYOR sea 0: un cambio
  que rompe o un feat sube MENOR; fix y perf suben PARCHE; el resto no publica.
- **CHANGELOG**: generado con la API a partir del trailer Changelog: del primer commit con
  cuerpo de cada merge request. Las secciones de los parches viven en su rama de release.

## Consecuencias

- Cada parche son dos merge requests (main y release/X.Y) y dos revisiones.
- Un cambio fusionado sin trailer no aparece en el CHANGELOG, y no se puede añadir después
  sin reescribir main.
- Descartado Git Flow: la doble integración main/develop no aporta nada con una sola
  rama de integración y releases cada pocas semanas.
EOF
```

**Verifica**: la respuesta es un slug que empieza por `ADR-006`. Ábrelo en `Plan → Wiki` y sustituye `<hoy>`, `<tú>` y `<dominio>` si no lo has hecho antes de ejecutar el bloque.

---

## Paso 2: Proteger `release/*`

**Por qué**: la rama de release nace en la práctica 04, pero su protección se decide ahora. Una rama que nace protegida no pasa ni un minuto abierta.

```bash
curl -s --request POST "$API/projects/$P/protected_branches" -H "$H" \
  --data-urlencode "name=release/*" \
  --data-urlencode "push_access_level=0" \
  --data-urlencode "merge_access_level=40" \
  --data-urlencode "allow_force_push=false" \
  | jq '{name, push: [.push_access_levels[].access_level], merge: [.merge_access_levels[].access_level], allow_force_push}'
```

Ahora comprueba que una rama protegida no se crea con `git push`, aunque seas Owner:

```bash
cd /ruta/a/tu/clon/de/app
git switch main && git pull --ff-only
git push origin main:refs/heads/release/prueba 2>&1 | grep 'GitLab:'
```

**Verifica**:

- La protección devuelve `push: [0]`, `merge: [40]` y `allow_force_push: false`.
- El `push` responde `GitLab: You can only create protected branches using the web interface and API.` Puedes fusionar en `release/*`, y el commit está en `main`, que es una rama protegida: solo falla la vía. La teoría [05](../1-teoria/05-ramas-de-release-y-cherry-pick.md), apartado 2.2, explica las tres condiciones.
- `curl -s -H "$H" "$API/projects/$P/repository/branches?search=release" | jq length` da `0`.

---

## Paso 3: La plantilla de squash que conserva los trailers

**Por qué**: la teoría [04](../1-teoria/04-changelog-generado.md), apartado 2.4. Sin este marcador, el trailer `Changelog:` de tus commits se queda en la rama y no llega a `main`.

```bash
ACTUAL=$(curl -s -H "$H" "$API/projects/$P" | jq -r .squash_commit_template)
printf '%s\n---\n' "$ACTUAL"

curl -s --request PUT "$API/projects/$P" -H "$H" \
  --data-urlencode "squash_commit_template=$(printf '%s\n\n%s' "$ACTUAL" '%{first_multiline_commit_description}')" \
  | jq -r .squash_commit_template
```

**Verifica**: la plantilla nueva es la de la Semana 06 con una línea en blanco y `%{first_multiline_commit_description}` al final:

```
%{title} (%{local_reference})

%{issues}

%{reviewed_by}
%{approved_by}
%{co_authored_by}

%{first_multiline_commit_description}
```

`%{approved_by}` sigue ahí: sin él, el hook rechazaría todas las fusiones en `main`. Si tu método es `ff`, esta plantilla es la única que se usa; si es `rebase_merge`, el commit de fusión usa su propia plantilla (Semana 07) y no necesita cambios.

---

## Paso 4: `changelog_config.yml` por merge request

**Por qué**: la configuración vive en el repositorio y la lee la API desde la rama por defecto. Como `/.gitlab/` es de `revisor` en `CODEOWNERS`, la aprueba él.

El issue:

```bash
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=CHANGELOG generado en español" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=Configurar .gitlab/changelog_config.yml. Ver Semana 08 y ADR-006." \
  | jq -r .iid)
echo "issue #$IID"
```

El archivo, con el contenido exacto de la teoría [04](../1-teoria/04-changelog-generado.md), apartado 3:

```bash
git switch main && git pull --ff-only
git switch -c "$IID-changelog-config"
mkdir -p .gitlab
$EDITOR .gitlab/changelog_config.yml      # pega el YAML de la teoría 04

git add .gitlab/changelog_config.yml
git commit -S -m "chore: add changelog configuration"
git push -u origin "$IID-changelog-config" \
  -o merge_request.create \
  -o merge_request.target=main \
  -o merge_request.title="chore: add changelog configuration"
```

Este commit **no** lleva trailer: a quien usa `app` no le importa cómo se genera el CHANGELOG.

Antes de pedir la revisión, prueba la configuración **desde la rama**, sin fusionar nada. `config_file_ref` le dice a la API de qué rama leer el YAML:

```bash
PRIMERO=$(git rev-list --max-parents=0 main)
echo "export PRIMERO=$PRIMERO" >> ~/.bc-gitlab-s08
curl -s -G -H "$H" "$API/projects/$P/repository/changelog" \
  --data-urlencode "version=0.1.0" --data-urlencode "from=$PRIMERO" \
  --data-urlencode "config_file_ref=$IID-changelog-config" | jq -r '.notes // .message'
```

Sale `## 0.1.0 (<hoy>)` y `Sin cambios.`: en español, porque la plantilla es la tuya, y sin cambios, porque ningún commit de `main` lleva todavía el trailer. Si sale un `message` con `does not contain valid YAML` o un error de plantilla, corrige el archivo, `git commit --amend -S --no-edit`, `git push --force-with-lease` y repite.

Revisión, auditoría y fusión:

```bash
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$IID-changelog-config&state=opened" | jq -r '.[0].iid')
curl -s --request POST "$API/projects/$P/merge_requests/$MR/approve" -H "$HR" | jq -r '.approved_by[].user.username'
bash scripts/gobernanza.sh "$MR" && {
  SHA=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .sha)
  curl -s --request PUT "$API/projects/$P/merge_requests/$MR/merge" -H "$H" \
    --data-urlencode "sha=$SHA" --data-urlencode "squash=true" | jq -r .state
}
```

**Verifica**: `gobernanza.sh` termina con `0 problema(s)`, la fusión da `merged`, y el mismo `GET` **sin** `config_file_ref` ya responde en español, porque ahora lee de `main`:

```bash
git switch main && git pull --ff-only
curl -s -G -H "$H" "$API/projects/$P/repository/changelog" \
  --data-urlencode "version=0.1.0" --data-urlencode "from=$PRIMERO" | jq -r .notes
```

Sigue diciendo `Sin cambios.`. Eso lo arregla la práctica 02.

---

## ✅ Resultado

- [ ] ADR-006 en la wiki
- [ ] `release/*` protegida, y has visto que no se crea por `git push`
- [ ] La plantilla de squash termina en `%{first_multiline_commit_description}` y conserva `%{approved_by}`
- [ ] `.gitlab/changelog_config.yml` en `main`, y el `GET` del CHANGELOG responde en español

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 08
```

Tras esta práctica pasan las comprobaciones de los pasos 1 a 4. Las demás llegan con las prácticas siguientes.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `409` al proteger `release/*` | Ya existe una regla con ese nombre | Léela; si no es `0/40`, cámbiala en la UI (sin desproteger) o bórrala y créala seguidas: mientras no exista ninguna `release/X.Y`, esa ventana no expone nada |
| El `push` a `release/prueba` **funciona** | Hay otra regla que coincide y deja empujar, o el paso 2 falló | `GET .../protected_branches`, y borra la rama con `DELETE .../repository/branches/release%2Fprueba` |
| La plantilla nueva ha perdido `%{approved_by}` | `ACTUAL` estaba vacío: no tenías plantilla de la Semana 06 | Escribe la plantilla completa del apartado **Verifica** con `printf` |
| El `GET` con `config_file_ref` da `does not contain valid YAML` | Error de sangría: la plantilla tiene que ir indentada bajo `template: \|` | Copia otra vez el bloque de la teoría 04 sin cambiar los espacios |
| El `GET` responde en inglés (`No changes.`) | El YAML no está en `main` o tiene otro nombre | `GET .../repository/tree?path=.gitlab&ref=main` |
| El `GET` responde `422` con `does not contain valid YAML` | El archivo se fusionó con un error | Arréglalo en otra merge request; hasta entonces la API no genera nada |
| La fusión falla con `falta Approved-by` | `revisor` no aprobó, o el paso 3 perdió `%{approved_by}` | `GET .../merge_requests/$MR/approvals` y el paso 3 |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Semana 08](../README.md) | **Práctica 01** | [Práctica 02 — Cambios que cuentan](02-cambios-que-cuentan.md) |

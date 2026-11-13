# Práctica 02 — CODEOWNERS y la auditoría

> Nombras a los dueños de cada parte de `app` y escribes el script que comprueba que cada merge request la aprobó uno de ellos. Las dos cosas entran por merge request, ya con `main` protegida: es la primera vez que el flujo de la Semana 06 es el único camino.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 01 completada · Teoría [04](../1-teoria/04-codeowners-en-ce.md) y [07](../1-teoria/07-lo-que-no-se-puede-bloquear.md) leídas

---

## Contexto

Dos papeles, dos tokens, como en la Semana 06:

| Papel | Variable | Identidad |
|---|---|---|
| **Autor** | `$H` | Tú |
| **Revisor** | `$HR` | `revisor-<dominio>` |

El reparto de `CODEOWNERS` que vas a escribir:

| Ruta | Dueños | Por qué |
|---|---|---|
| `*` | Tú y `revisor` | Por defecto, cualquiera de los dos |
| `/src/` | `revisor` | La lógica del dominio la revisa siempre otra persona |
| `/CODEOWNERS`, `/scripts/`, `/.gitlab/` | `revisor` | Las reglas no las cambia solo quien las sufre |

---

## Paso 0: Preparar el terreno y el token del revisor

**Por qué**: `revisor` aprueba esta merge request. Igual que en la Semana 06, un token creado con la API de administración te deja actuar como él, con caducidad corta. Se revoca en la práctica 04.

```bash
source ~/.bc-gitlab
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
export YO=$(curl -s -H "$H" "$API/user" | jq -r .username)
export REV=revisor-<tu-dominio>

UID_REV=$(curl -s -H "$H" "$API/users?username=$REV" | jq -r '.[0].id')
T_REV=$(curl -s --request POST "$API/users/$UID_REV/personal_access_tokens" \
  -H "PRIVATE-TOKEN: ${GITLAB_ADMIN_TOKEN:-$GITLAB_TOKEN}" \
  --data-urlencode "name=gobernanza-s07" \
  --data-urlencode "scopes[]=api" \
  --data-urlencode "expires_at=$(date -d '+7 days' +%F)" \
  | jq -r '.token')
[ -n "$T_REV" ] && [ "$T_REV" != null ] || echo "No se creó el token: revisa permisos de administrador y NO sigas"
export HR="PRIVATE-TOKEN: $T_REV"
```

El token no se guarda en ningún archivo. Si cierras la terminal entre prácticas, vuelve a ejecutar este paso: se crea otro con el mismo nombre, y la práctica 04 los revoca todos.

**Verifica**:

```bash
curl -s -H "$HR" "$API/user" | jq -r .username     # revisor-<tu-dominio>
```

---

## Paso 1: El issue

**Por qué**: desde la Semana 06, todo cambio nace de un issue. Este también, aunque cambie las reglas del propio repositorio.

```bash
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Dueños de código y auditoría de gobernanza" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=Añadir CODEOWNERS y scripts/gobernanza.sh. Ver Semana 07." \
  | jq -r .iid)
echo "export IID_CO=$IID" > ~/.bc-gitlab-s07
echo "issue #$IID"
```

**Verifica**: `curl -s -H "$H" "$API/projects/$P/issues/$IID" | jq -r '.title, .labels[]'` devuelve el título y `tipo::mantenimiento`.

---

## Paso 2: `CODEOWNERS`

**Por qué**: la teoría [04](../1-teoria/04-codeowners-en-ce.md). Lo general arriba, lo específico abajo, y una línea que protege al propio archivo.

```bash
git switch main && git pull --ff-only
git switch -c "$IID-codeowners"

cat > CODEOWNERS <<EOF
# Dueños de código de app. En CE GitLab no lo lee: lo lee scripts/gobernanza.sh.
# Gana la última regla que coincide. Lo general arriba, lo específico abajo.

# Por defecto: cualquiera de los dos
*              @$YO @$REV

# La lógica del dominio la revisa siempre revisor
/src/          @$REV

# Las reglas no las cambia solo quien las sufre
/CODEOWNERS    @$REV
/scripts/      @$REV
/.gitlab/      @$REV
EOF
```

**Verifica** que las variables se sustituyeron y que la regla de la última coincidencia da lo esperado:

```bash
grep -c '@\$' CODEOWNERS     # 0: no quedó ningún $YO ni $REV sin sustituir
duenos() { awk -v f="/$1" '/^[[:space:]]*(#|$)/ {next} $1=="*" || index(f,$1)==1 {d=$0}
                          END {sub(/^[^ ]+ +/,"",d); print d}' CODEOWNERS; }
duenos README.md; duenos src/prestamos.ts; duenos CODEOWNERS
```

`README.md` sale con los dos dueños; los otros dos, solo con `revisor`.

---

## Paso 3: El script de auditoría

**Por qué**: es lo que convierte `CODEOWNERS` en algo comprobable. El código y sus decisiones están explicados en la teoría [07](../1-teoria/07-lo-que-no-se-puede-bloquear.md#22-el-script-gobernanza): cópialo de ahí tal cual.

```bash
mkdir -p scripts
$EDITOR scripts/gobernanza.sh        # pega el script de la teoría 07, apartado 2.2
chmod +x scripts/gobernanza.sh
```

**Verifica**:

```bash
bash -n scripts/gobernanza.sh && echo "sintaxis ok"
sed -n 2p scripts/gobernanza.sh                    # el comentario "Auditoría de gobernanza..."
[ -x scripts/gobernanza.sh ] && echo "ejecutable"
```

---

## Paso 4: Commits firmados y la merge request

**Por qué**: dos cambios, dos commits convencionales. El título de la merge request tiene que ser convencional también: con squash, es el asunto del commit que entra en `main`, y el hook de la práctica 03 lo exigirá.

```bash
git add CODEOWNERS && git commit -S -m "chore: add CODEOWNERS"
git add scripts/gobernanza.sh && git commit -S -m "chore: add governance audit script"

git push -u origin "$IID-codeowners" \
  -o merge_request.create \
  -o merge_request.target=main \
  -o merge_request.title="chore: add CODEOWNERS and governance audit"
```

Asigna a `revisor` como revisor:

```bash
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$IID-codeowners&state=opened" | jq -r '.[0].iid')
echo "export MR_CO=$MR" >> ~/.bc-gitlab-s07
curl -s --request PUT "$API/projects/$P/merge_requests/$MR" -H "$H" \
  --data-urlencode "reviewer_ids[]=$UID_REV" | jq -r '.reviewers[].username'
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/closes_issues" | jq -r '.[].iid'   # el número del issue
git log --format='%h %G? %s' origin/main..HEAD                                       # dos commits, los dos con G
```

Si `closes_issues` sale vacío, la plantilla `Default` no se aplicó (la rama no empieza por el número del issue): edita la descripción y añade `Closes #<IID>`.

---

## Paso 5: La auditoría antes de aprobar

**Por qué**: ver el script fallar por las razones correctas antes de verlo pasar.

```bash
bash scripts/gobernanza.sh "$MR"; echo "salida: $?"
```

**Verifica**: la salida dice `✅ cierra un issue`, `❌ nadie distinto de @<tú> la ha aprobado` y `❌ no hay CODEOWNERS en main`, y termina con código `1`.

El último es el huevo y la gallina: el script lee `CODEOWNERS` de `main`, y el archivo todavía no está ahí. Es deliberado (la teoría [04](../1-teoria/04-codeowners-en-ce.md), apartado 2.7): la merge request que introduce las reglas la valida una persona, no el script. A partir de ahora, cada cambio a `CODEOWNERS` lo valida el `CODEOWNERS` anterior.

---

## Paso 6: `revisor` aprueba, tú fusionas

**Por qué**: la aprobación de `revisor` es la que el squash convertirá en `Approved-by:`. Y fusionar con `sha` garantiza que entra exactamente lo que se revisó.

Como **revisor** (`$HR`):

```bash
curl -s --request POST "$API/projects/$P/merge_requests/$MR/approve" -H "$HR" \
  | jq -r '.approved_by[].user.username'
```

Como **autor** (`$H`):

```bash
SHA=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .sha)
curl -s --request PUT "$API/projects/$P/merge_requests/$MR/merge" -H "$H" \
  --data-urlencode "sha=$SHA" --data-urlencode "squash=true" \
  | jq '{state, squash_commit_sha, merge_commit_sha}'
```

**Verifica**: `state: "merged"` y un `squash_commit_sha` no nulo. El issue se cerró solo:

```bash
curl -s -H "$H" "$API/projects/$P/issues/$IID" | jq -r .state     # closed
```

---

## Paso 7: La aprobación, en la historia y en la auditoría

**Por qué**: comprobar las dos caras de la misma aprobación: el trailer que leerá el hook y la API que lee el script.

```bash
git switch main && git pull --ff-only
git log -3 --format='%h %s%n%(trailers:key=Approved-by,key=Reviewed-by)'
bash scripts/gobernanza.sh "$MR"; echo "salida: $?"
```

**Verifica**:

- El commit de squash lleva `Approved-by: <nombre de revisor> <correo>`. Si no tiene `Reviewed-by:` no pasa nada: `revisor` aprobó sin enviar una revisión con comentarios.
- El script dice `✅` en las cuatro líneas (issue, aprobación y los dos archivos, aprobados por su dueño) y sale con `0`.

---

## Paso 8: Auditar la Semana 06

**Por qué**: el script no es solo para lo nuevo. Pasarlo por lo que se fusionó antes de las reglas enseña qué habría detectado.

```bash
for iid in $(curl -s -H "$H" "$API/projects/$P/merge_requests?state=merged&per_page=100" | jq -r '.[].iid'); do
  printf '!%-4s ' "$iid"; bash scripts/gobernanza.sh "$iid" | tail -n 1
done
```

**Verifica**: una línea por merge request fusionada. Las de la Semana 06 que solo aprobó `revisor` y que tocaron `src/` deberían salir con `0 problema(s)`. Las que tocaron archivos con dos dueños también. Las que no tuvieron aprobación (la del `CONTRIBUTING.md` del proyecto 06, si no la aprobó `revisor`) salen con algún problema.

Apunta cuáles fallan y por qué: van al ADR-005 en la práctica 04, como "estado de partida". No se arreglan: ya están fusionadas, y reescribir `main` para arreglarlas sería peor que el problema.

---

## ✅ Resultado

- [ ] `CODEOWNERS` en `main`, con regla por defecto y dueño para `/CODEOWNERS`
- [ ] `scripts/gobernanza.sh` en `main`, ejecutable
- [ ] Una merge request más, aprobada por `revisor` y fusionada con squash
- [ ] El commit de squash lleva `Approved-by:`
- [ ] Has visto el script fallar antes de aprobar y pasar después
- [ ] Sabes qué merge requests de la Semana 06 no pasarían la auditoría de hoy

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 07
```

Tras esta práctica deberían pasar también las de `CODEOWNERS`, el script y la aprobación en la historia.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `git push` rechazado con `You are not allowed to push code to protected branches` | Empujaste a `main`, no a la rama | `git push -u origin "$IID-codeowners"` |
| El script dice `no hay CODEOWNERS en main` después de fusionar | El archivo se llama distinto (`codeowners`, `CODEOWNERS.md`) o no está en la raíz | `git ls-files | grep -i codeowners` |
| El script falla con `curl: (22)` y sale | El token no tiene permiso o `PROYECTO` está mal | `curl -s -H "$H" "$API/projects/$P" | jq .id` |
| `approve` devuelve `401` | El token del revisor caducó o no se creó | Repetir el paso 0 |
| `approve` devuelve `403` | `revisor` no tiene rol suficiente en `app` | Paso 7 de la práctica 01: tiene que ser Maintainer |
| `merge` devuelve `422` | La rama no está al día con `main` (`need_rebase`) o hay hilos abiertos | `detailed_merge_status` dice cuál (Semana 06, teoría 06) |
| Un archivo sale `falta la aprobación de @tú @revisor` aunque `revisor` aprobó | En `CODEOWNERS` hay un usuario mal escrito | Comparar con `curl -s -H "$H" "$API/users?username=..."` |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Práctica 01 — `main` y tags protegidos](01-main-y-tags-protegidos.md) | **Práctica 02** | [Práctica 03 — El server hook](03-el-server-hook.md) |

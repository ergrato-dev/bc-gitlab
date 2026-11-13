# Práctica 03 — El server hook

> Escribes el hook de la teoría 06, lo pruebas en local contra un repositorio desnudo, lo versionas por merge request y lo instalas en `app` con `gitaly hooks set`. Después intentas fusionar una merge request sin aprobar, y GitLab te dice por qué no.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 02 completada · Teoría [05](../1-teoria/05-server-hooks.md) y [06](../1-teoria/06-un-hook-de-gobernanza.md) leídas · Acceso a `docker exec` en el contenedor `gitlab`

---

## Contexto

Es la única práctica del bootcamp hasta ahora que necesita **dos permisos distintos**: el de Owner de `app` para la merge request, y el de administrador de la máquina para instalar el hook. En tu laboratorio los tienes los dos. En una organización real serían dos personas, y eso es exactamente lo que da fuerza al hook.

> [!WARNING]
> Un hook roto bloquea **todos** los cambios de `app`: `push`, fusiones, sugerencias. Por eso el paso 2 lo prueba en local antes de instalarlo, y el paso 9 dice cómo quitarlo en un comando.

---

## Paso 0: Preparar el terreno

```bash
source ~/.bc-gitlab
source ~/.bc-gitlab-s07
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
```

Si cerraste la terminal desde la práctica 02, repite también su paso 0 para tener `$HR`, `$YO`, `$REV` y `$UID_REV`.

**Verifica**:

```bash
docker exec gitlab /opt/gitlab/embedded/bin/gitaly hooks set --help | head -n 3   # NAME: gitaly hooks set
curl -s -H "$HR" "$API/user" | jq -r .username                                     # revisor-<tu-dominio>
```

---

## Paso 1: El issue, la rama y el hook

**Por qué**: el hook es código que decide qué entra en `main`. Va al repositorio, y por merge request, como cualquier otro cambio. `CODEOWNERS` ya dice que `/scripts/` es de `revisor`.

```bash
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Server hook con la política de entrada de app" \
  --data-urlencode "labels=tipo::mantenimiento" | jq -r .iid)
echo "export IID_HOOK=$IID" >> ~/.bc-gitlab-s07
git switch -c "$IID-server-hook"
mkdir -p scripts/hooks
$EDITOR scripts/hooks/pre-receive     # pega el hook de la teoría 06, apartado 2.1
chmod +x scripts/hooks/pre-receive
```

**Verifica**:

```bash
bash -n scripts/hooks/pre-receive && echo "sintaxis ok"
grep -c 'GL-HOOK-ERR' scripts/hooks/pre-receive       # 1: la función rechaza
grep -c 'viejo..\$nuevo' scripts/hooks/pre-receive    # 1: la regla de main usa lo que main gana
```

---

## Paso 2: Probarlo en local

**Por qué**: un repositorio desnudo con el hook en `hooks/` se comporta como el servidor. Aquí un error cuesta un `rm -rf /tmp/...`; en `app`, bloquear a todo el mundo.

```bash
PRUEBA=$(mktemp -d)
( set -e
git init -q --bare -b main "$PRUEBA/srv.git"
git clone -q "$PRUEBA/srv.git" "$PRUEBA/cli" && cd "$PRUEBA/cli"
git commit -q -S --allow-empty -m "chore: init" && git push -q origin main
cp /ruta/a/tu/clon/de/app/scripts/hooks/pre-receive "$PRUEBA/srv.git/hooks/pre-receive"

caso() { echo "--- $1"; shift; out=$("$@" 2>&1) && echo "aceptado" || { echo "$out" | grep GL-HOOK-ERR || echo "rechazado sin mensaje"; }; }

git switch -q -c f
git commit -q -S --allow-empty -m "feat: firmado";   caso "1 debe pasar"          git push origin f
git commit -q    --allow-empty -m "feat: sin firma"; caso "2 sin firma"           git push origin f; git reset -q --soft HEAD~1
git commit -q -S --allow-empty -m "arreglos";        caso "3 no convencional"     git push origin f; git reset -q --soft HEAD~1
caso "4 a main sin aprobación" git push origin f:main
git commit -q -S --allow-empty -m "fix: aprobado" -m "Approved-by: Revisor <r@example.com>"
caso "5 a main con aprobación" git push origin f:main
git commit -q    --allow-empty -m "fix: como GitLab"
GL_PROTOCOL=web caso "6 web sin firma" git push origin f
)
rm -rf "$PRUEBA"
```

**Verifica**: los casos 1, 5 y 6 dicen `aceptado`; el 2, el 3 y el 4 muestran la línea `GL-HOOK-ERR:` con el motivo. Si alguno no coincide, **no sigas**: el hook tiene un error y en `app` lo pagarían todos.

Todo el bloque va entre paréntesis con `set -e`: si algo falla (el clon, por ejemplo), el subshell se detiene y nada se ejecuta por error dentro de tu clon de `app`.

El caso 6 imita una fusión hecha por GitLab: `GL_PROTOCOL=web` llega al hook porque un `push` local hereda el entorno. Funciona igual en bash y en zsh.

---

## Paso 3: La plantilla del commit de fusión

**Por qué**: la teoría [06](../1-teoria/06-un-hook-de-gobernanza.md), apartado 2.4. Con squash la aprobación va en la plantilla de squash de la Semana 06. Si alguien desmarca el squash, entra en `main` un merge commit sin `Approved-by:` y el hook rechazaría la fusión. Esta plantilla lo evita. Es la plantilla por defecto de GitLab más una línea.

Si tu método es `ff`, este paso no aplica: cambia `squash_option` a `always` y explícalo en el ADR-005.

```bash
FUSION=$(printf '%s\n\n%s\n\n%s\n\n%s\n\n%s' \
  "Merge branch '%{source_branch}' into '%{target_branch}'" \
  '%{title}' '%{issues}' 'See merge request %{reference}' '%{approved_by}')

curl -s --request PUT "$API/projects/$P" -H "$H" \
  --data-urlencode "merge_commit_template=$FUSION" \
  | jq -r '.merge_method, "---", .merge_commit_template'
```

**Verifica**: la salida muestra `rebase_merge`, y la plantilla con sus saltos de línea y `%{approved_by}` en la última.

---

## Paso 4: El hook entra por merge request

**Por qué**: `revisor` es dueño de `/scripts/` y aprueba. Así el hook que se va a instalar es exactamente el que alguien revisó.

```bash
git add scripts/hooks/pre-receive
git commit -S -m "feat: add pre-receive governance hook"
git push -u origin "$IID-server-hook" -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="feat: add pre-receive governance hook"

MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$IID-server-hook&state=opened" | jq -r '.[0].iid')
curl -s --request PUT "$API/projects/$P/merge_requests/$MR" -H "$H" --data-urlencode "reviewer_ids[]=$UID_REV" -o /dev/null
curl -s --request POST "$API/projects/$P/merge_requests/$MR/approve" -H "$HR" -o /dev/null
SHA=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .sha)
curl -s --request PUT "$API/projects/$P/merge_requests/$MR/merge" -H "$H" \
  --data-urlencode "sha=$SHA" --data-urlencode "squash=true" | jq -r .state
bash scripts/gobernanza.sh "$MR" | tail -n 1
```

**Verifica**: `merged`, y la auditoría dice `0 problema(s)`.

---

## Paso 5: Instalarlo en `app`

**Por qué**: hasta ahora el hook es un archivo en `main`. Instalarlo es la parte que solo puede hacer quien tenga una shell en el servidor.

```bash
git switch main && git pull --ff-only

ID=$(curl -s -H "$H" "$API/projects/$P" | jq -r .id)
HASH=$(printf '%s' "$ID" | sha256sum | cut -d' ' -f1)
RUTA="@hashed/${HASH:0:2}/${HASH:2:2}/$HASH.git"
echo "export RUTA=$RUTA" >> ~/.bc-gitlab-s07

TMP=$(mktemp -d) && mkdir "$TMP/custom_hooks"
git show main:scripts/hooks/pre-receive > "$TMP/custom_hooks/pre-receive"
chmod +x "$TMP/custom_hooks/pre-receive"
tar -C "$TMP" -cf "$TMP/hooks.tar" custom_hooks

docker exec gitlab ls "/var/opt/gitlab/git-data/repositories/$RUTA/custom_hooks/" 2>/dev/null \
  && docker exec gitlab tar -C "/var/opt/gitlab/git-data/repositories/$RUTA" -cf - custom_hooks > ~/hooks-app-antes.tar
docker exec -i gitlab /opt/gitlab/embedded/bin/gitaly hooks set \
  --storage default --repository "$RUTA" \
  --config /var/opt/gitlab/gitaly/config.toml < "$TMP/hooks.tar"
rm -rf "$TMP"
```

`git show main:...` instala lo que está en `main`, no lo que tengas en el directorio de trabajo. `gitaly hooks set` **sustituye** los hooks que hubiera; la primera línea guarda los anteriores en `~/hooks-app-antes.tar` si existían (lo normal es que no haya ninguno y no se cree el archivo).

**Verifica**:

```bash
docker exec gitlab ls -l "/var/opt/gitlab/git-data/repositories/$RUTA/custom_hooks/"
# -rwxr-xr-x ... pre-receive
docker exec gitlab cat "/var/opt/gitlab/git-data/repositories/$RUTA/custom_hooks/pre-receive" \
  | diff - <(git show main:scripts/hooks/pre-receive) && echo "idéntico a main"
```

---

## Paso 6: Un `push` que el hook rechaza

**Por qué**: comprobar que está activo en el servidor de verdad, no solo copiado.

```bash
git switch -c prueba-hook
git commit -S --allow-empty -m "cambios varios"
git push origin prueba-hook
```

**Verifica**: el `push` falla con:

```
remote: GL-HOOK-ERR: 1a2b3c4d: el asunto no sigue Conventional Commits
 ! [remote rejected] prueba-hook -> prueba-hook (pre-receive hook declined)
```

Limpia la rama local, que nunca llegó al servidor:

```bash
git switch main && git branch -D prueba-hook
```

---

## Paso 7: Una fusión sin aprobar

**Por qué**: el hook también se ejecuta cuando fusiona GitLab. Esta es la prueba que importa: la aprobación deja de ser opcional.

Elige un issue pequeño del backlog (`tipo::docs` es ideal). Rama, cambio, commit firmado, merge request, revisor asignado. **Sin aprobar**, intenta fusionar:

```bash
IID=<número del issue>
git switch -c "$IID-<descripcion-corta>"
$EDITOR <el archivo que toque>
git commit -S -am "docs: <lo que cambia>"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main -o merge_request.title="docs: <lo que cambia>"

MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
curl -s --request PUT "$API/projects/$P/merge_requests/$MR" -H "$H" --data-urlencode "reviewer_ids[]=$UID_REV" -o /dev/null
SHA=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .sha)
curl -s --request PUT "$API/projects/$P/merge_requests/$MR/merge" -H "$H" \
  --data-urlencode "sha=$SHA" --data-urlencode "squash=true" -w '\n%{http_code}\n' | tail -n 1
curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r '.state, .merge_error'
```

**Verifica**: la fusión devuelve `422`, la merge request sigue `opened`, y `merge_error` dice:

```
Something went wrong during merge pre-receive hook. nada entra en main sin una aprobación: falta Approved-by en refs/heads/main
```

Abre la merge request en la UI: el widget muestra el mismo mensaje. Ahora `revisor` aprueba y vuelves a fusionar:

```bash
curl -s --request POST "$API/projects/$P/merge_requests/$MR/approve" -H "$HR" -o /dev/null
curl -s --request PUT "$API/projects/$P/merge_requests/$MR/merge" -H "$H" \
  --data-urlencode "sha=$SHA" --data-urlencode "squash=true" | jq -r .state     # merged
```

---

## Paso 8: Lo que quedó en la historia

**Por qué**: cerrar el círculo: el hook dejó pasar exactamente lo que llevaba la aprobación.

```bash
git switch main && git pull --ff-only
git log -4 --format='%h %G? %s%n%(trailers:key=Approved-by)'
```

**Verifica**: los commits de squash de esta semana llevan `Approved-by:` y `%G?` en `N` (los escribe GitLab, sin firma, y el hook lo acepta porque llegaron por `web`). Tus commits de rama, que sí van firmados, no aparecen en `main`: con squash, se quedan en la merge request.

---

## Paso 9: Cómo quitarlo, por si acaso

**Por qué**: el procedimiento de emergencia del ADR-005 lo necesita escrito y probado en seco. **No lo ejecutes ahora**: solo comprueba que el comando existe y que sabes construir el tarball vacío.

```bash
TMP=$(mktemp -d) && tar -C "$TMP" -cf "$TMP/vacio.tar" --files-from /dev/null
tar -tf "$TMP/vacio.tar" | wc -l      # 0: el tarball vacío que quitaría los hooks
rm -rf "$TMP"
```

El comando de emergencia sería el mismo `gitaly hooks set` del paso 5 con `vacio.tar`. Cópialo tal cual al ADR-005.

---

## ✅ Resultado

- [ ] `scripts/hooks/pre-receive` en `main`, aprobado por `revisor`
- [ ] Has probado en local los seis casos, antes de instalar
- [ ] La plantilla del commit de fusión incluye `%{approved_by}` (o `squash_option=always` con `ff`)
- [ ] El hook instalado en `app` es idéntico al de `main`
- [ ] Has visto el hook rechazar un `push` y una fusión sin aprobar, y aceptar la aprobada
- [ ] Sabes quitar el hook en un comando

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 07
```

Tras esta práctica solo debería faltar el ADR-005.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `gitaly hooks set` falla con `repository not found` | La ruta `@hashed` está mal: id equivocado o falta `.git` | `docker exec gitlab ls /var/opt/gitlab/git-data/repositories/@hashed/${HASH:0:2}/${HASH:2:2}/` |
| El `ls` del paso 5 dice `No such file or directory` pero `hooks set` no dio error | Gitaly guardó los hooks en otro sitio (almacenamiento con transacciones) | La prueba que cuenta es la del paso 6: si el `push` se rechaza con `GL-HOOK-ERR`, el hook está activo |
| Todas las fusiones fallan con un error genérico, sin tu mensaje | El hook falla antes de llegar a `rechaza`: `git` no está en el `PATH`, o error de bash | Quitar el hook (paso 9), probar en local con `bash -x`, reinstalar |
| El `push` de una rama correcta falla con `no está firmado` | Tu clon no firma (`commit.gpgsign`) o firma con otra clave | `git log --format='%h %G?' -3` y la Semana 02 |
| La fusión aprobada falla con `falta Approved-by` | Se fusionó sin squash y la plantilla de fusión no tiene `%{approved_by}` | Paso 3, o `squash=true` |
| La fusión falla con `el asunto no sigue Conventional Commits` | El título de la merge request no es convencional | Cambiar el título por API y volver a fusionar |
| El caso 6 del paso 2 sale rechazado | `GL_PROTOCOL=web` no llegó al hook: se exportó en otra línea o se escribió mal | Escribirlo justo delante de `caso`, en la misma línea, como en el bloque |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Práctica 02 — CODEOWNERS y la auditoría](02-codeowners-y-la-auditoria.md) | **Práctica 03** | [Práctica 04 — Quién se salta las reglas](04-quien-se-salta-las-reglas.md) |

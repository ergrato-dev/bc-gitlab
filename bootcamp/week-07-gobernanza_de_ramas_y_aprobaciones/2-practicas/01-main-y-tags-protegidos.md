# Práctica 01 — `main` y tags protegidos

> Cierras el agujero más grande: que tú mismo puedas empujar a `main`. Después proteges los tags `v*` antes de que exista la primera versión, y dejas la protección por defecto del grupo lista para los proyectos que vienen.

**Duración estimada**: 50 min
**Prerrequisitos**: Semana 06 completada · Teoría [02](../1-teoria/02-ramas-protegidas.md) y [03](../1-teoria/03-tags-protegidos.md) leídas

---

## Contexto

Al terminar la Semana 06, `main` tiene la protección que GitLab le puso al crear el proyecto: Maintainers pueden empujar y fusionar. Como eres Owner, pasas. Esta práctica lo cambia y lo comprueba con el único usuario al que de verdad hay que frenar: tú.

---

## Paso 0: Preparar el terreno

```bash
source ~/.bc-gitlab
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)

cd /ruta/a/tu/clon/de/app
git switch main && git pull --ff-only
```

**Verifica**:

```bash
curl -s -o /dev/null -w '%{http_code}\n' -H "$H" "$API/projects/$P"   # 200
git status -sb | head -n 1                                             # ## main...origin/main
curl -s -H "$H" "$API/projects/$P" | jq -r .squash_commit_template | grep -c '%{approved_by}'   # 1
```

La última línea comprueba un prerrequisito de toda la semana: la plantilla de squash de la Semana 06 tiene que incluir `%{approved_by}`. Si da `0`, vuelve a la práctica 01 de la Semana 06, paso 3, antes de seguir: sin esa variable, el hook de la práctica 03 rechazará todas las fusiones.

---

## Paso 1: Lo que hay hoy

**Por qué**: antes de cambiar una regla, se apunta cómo estaba. Si algo sale mal, sabes a qué volver.

**Con la UI**: `Settings → Repository → Protected branches` y `Protected tags`.

**Con la API**:

```bash
curl -s -H "$H" "$API/projects/$P/protected_branches" \
  | jq '[.[] | {name, push: [.push_access_levels[].access_level], merge: [.merge_access_levels[].access_level], allow_force_push}]' \
  | tee ~/.bc-gitlab-protecciones-antes.json
curl -s -H "$H" "$API/projects/$P/protected_tags" | jq '[.[].name]'
```

**Verifica**: lo esperable es una sola regla, `main` con `push: [40]` y `merge: [40]`, y ningún tag protegido. `allow_force_push` puede salir `true` o `false` según la protección por defecto de tu instancia y lo que hicieras en la Semana 02: el paso 2 lo deja en `false` en cualquier caso. Si hay otras reglas (un `*` de alguna prueba antigua), anótalas: por la regla de la más permisiva, pueden anular lo que hagas en el paso 2.

---

## Paso 2: `main`, solo por merge request

**Por qué**: es la decisión de la teoría [02](../1-teoria/02-ramas-protegidas.md): `push = No one` hace que la única forma de cambiar `main` sea fusionar una merge request. `merge = Maintainers` deja fusionar a ti y a `revisor`, no a `dev`.

En CE no se pueden cambiar los roles de una regla existente: hay que borrarla y crearla. Las dos llamadas van **seguidas, en el mismo bloque**, para que `main` no se quede abierta.

> [!WARNING]
> Entre el `DELETE` y el `POST`, `main` no está protegida. Ejecuta el bloque entero de una vez. Si el `POST` falla, la salida del `jq` saldrá vacía o con un error: en ese caso repite solo el `POST` hasta que devuelva la regla.

**Con la UI** (sin ventana abierta): en la fila de `main`, cambia los desplegables a *Allowed to merge: Maintainers* y *Allowed to push and merge: No one*, y deja apagado *Allowed to force push*. La UI edita la regla en el sitio; es la API la que obliga a borrar y crear.

**Con la API**:

```bash
curl -s --request DELETE "$API/projects/$P/protected_branches/main" -H "$H" -o /dev/null -w 'DELETE %{http_code}\n'
curl -s --request POST "$API/projects/$P/protected_branches" -H "$H" \
  --data-urlencode "name=main" \
  --data-urlencode "push_access_level=0" \
  --data-urlencode "merge_access_level=40" \
  --data-urlencode "allow_force_push=false" \
  | jq '{name, push: [.push_access_levels[].access_level], merge: [.merge_access_levels[].access_level], allow_force_push}'
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/repository/branches/main" | jq '{protected, can_push, developers_can_push}'
# { "protected": true, "can_push": false, "developers_can_push": false }
```

`can_push: false` es para ti, que eres Owner.

---

## Paso 3: Comprobar que ni tú puedes empujar

**Por qué**: una regla que no has visto rechazar nada no está probada. El commit de prueba está vacío, así que deshacerlo no pierde trabajo.

```bash
git commit -S --allow-empty -m "chore: probar la protección de main"
git push origin main
```

**Verifica**: la salida contiene estas dos líneas, y nada ha cambiado en el servidor:

```
remote: GitLab: You are not allowed to push code to protected branches on this project.
 ! [remote rejected] main -> main (pre-receive hook declined)
```

Deshaz el commit local. Era vacío, así que `--soft` no toca ningún archivo:

```bash
git reset --soft HEAD~1
git status -sb | head -n 1      # ## main...origin/main, sin "ahead"
```

---

## Paso 4: El borrado, tampoco

**Por qué**: un `git push origin :main` tecleado deprisa es la forma más rápida de destrozar un repositorio. La rama por defecto ya no se puede borrar, pero la protección añade una segunda barrera que conviene haber visto.

```bash
git push origin :main
```

**Verifica**: GitLab lo rechaza y `main` sigue en su sitio:

```bash
curl -s -o /dev/null -w '%{http_code}\n' -H "$H" "$API/projects/$P/repository/branches/main"   # 200
```

El mensaje exacto depende de qué comprobación salta primero: `You can only delete protected branches using the web interface.` o el de la rama por defecto. Cualquiera de los dos vale.

---

## Paso 5: Los tags `v*`

**Por qué**: la Semana 08 publica `v0.1.0`. Protegido desde antes, ese tag nace sin que nadie pueda moverlo ni borrarlo por Git, y solo los Maintainers pueden crear versiones.

**Con la UI**: `Settings → Repository → Protected tags`. *Tag*: `v*` → *Create wildcard v\**. *Allowed to create*: *Maintainers*. *Protect*.

**Con la API**:

```bash
curl -s --request POST "$API/projects/$P/protected_tags" -H "$H" \
  --data-urlencode "name=v*" \
  --data-urlencode "create_access_level=40" \
  | jq '{name, create: [.create_access_levels[].access_level]}'
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/protected_tags" | jq -r '.[] | "\(.name) create=\([.create_access_levels[].access_level])"'
# v* create=[40]
```

---

## Paso 6: Un tag de prueba que no se deja borrar

**Por qué**: comprobar las dos caras: como Maintainer puedes crear `v*`, pero ni así puedes borrarlo por Git.

```bash
git tag -a v0.0.0-prueba -m "prueba de protección de tags"
git push origin v0.0.0-prueba

curl -s -H "$H" "$API/projects/$P/repository/tags/v0.0.0-prueba" | jq '{name, protected}'
git push origin :refs/tags/v0.0.0-prueba
```

**Verifica**: el `GET` dice `"protected": true` y el borrado por Git falla con:

```
remote: GitLab: You can only delete protected tags using the web interface.
```

Ahora bórralo por la API, que a efectos de esta regla es la interfaz web, y en local:

```bash
curl -s --request DELETE "$API/projects/$P/repository/tags/v0.0.0-prueba" -H "$H" -o /dev/null -w '%{http_code}\n'   # 204
git tag -d v0.0.0-prueba
git ls-remote --tags origin | grep -c prueba                                                                         # 0
```

---

## Paso 7: Quién pasa cada regla

**Por qué**: una regla por rol solo se entiende sabiendo el rol efectivo de cada identidad en `app`. Lo que importa es el mayor entre el heredado del grupo y el directo.

```bash
for u in "$(curl -s -H "$H" "$API/user" | jq -r .username)" dev-<tu-dominio> revisor-<tu-dominio> auditor-<tu-dominio>; do
  id=$(curl -s -H "$H" "$API/users?username=$u" | jq -r '.[0].id')
  nivel=$(curl -s -H "$H" "$API/projects/$P/members/all/$id" | jq -r '.access_level // 0')
  printf '%-28s %3s  fusiona y crea v*: %s\n' "$u" "$nivel" "$([ "$nivel" -ge 40 ] && echo sí || echo no)"
done
```

**Verifica**: tú (50) y `revisor` (40) fusionan y crean versiones; `dev` (30) y `auditor` no. Nadie empuja a `main`. Si `revisor` sale con menos de 40, la práctica 02 de la Semana 03 (paso 6) no quedó como debía: corrígelo antes de la práctica 02, porque ahí aprueba como dueño de código.

---

## Paso 8: La protección de los proyectos que vienen

**Por qué**: en las semanas 11 y 12 nacen proyectos nuevos en el grupo. Si el grupo no dice otra cosa, heredan la protección de la instancia. *Fully protected* (Maintainers empujan y fusionan, sin forzar) es el punto de partida razonable: deja hacer el primer `push` y después cada proyecto se endurece como `app`.

**Con la UI**: en el grupo `plataforma-<tu-dominio>`, `Settings → Repository → Default branch` → *Initial default branch protection*: *Fully protected*.

**Con la API**:

```bash
G=$(curl -s -H "$H" "$API/projects/$P" | jq -r .namespace.full_path | cut -d/ -f1)
curl -s --request PUT "$API/groups/$G" -H "$H" -H "Content-Type: application/json" \
  --data '{"default_branch_protection_defaults": {
             "allowed_to_push":  [{"access_level": 40}],
             "allowed_to_merge": [{"access_level": 40}],
             "allow_force_push": false}}' \
  | jq .default_branch_protection_defaults
```

**Verifica**: la salida muestra `allowed_to_push` y `allowed_to_merge` con `access_level: 40` y `allow_force_push: false`. `app` no cambia: esto solo afecta a proyectos nuevos.

---

## Paso 9: La foto de referencia

**Por qué**: la teoría [07](../1-teoria/07-lo-que-no-se-puede-bloquear.md) compara las protecciones con una foto conocida para detectar cambios. Esta es la foto buena.

```bash
foto() {
  curl -s -H "$H" "$API/projects/$P/protected_branches" \
    | jq -S '[.[] | {name, push: [.push_access_levels[].access_level], merge: [.merge_access_levels[].access_level], allow_force_push}]'
  curl -s -H "$H" "$API/projects/$P/protected_tags" \
    | jq -S '[.[] | {name, create: [.create_access_levels[].access_level]}]'
}
foto > ~/.bc-gitlab-gobernanza.json
```

**Verifica**:

```bash
diff <(foto) ~/.bc-gitlab-gobernanza.json && echo "sin cambios"
```

Guarda la función `foto` en `~/.bc-gitlab` o en un archivo aparte: la práctica 04 la vuelve a usar.

---

## ✅ Resultado

- [ ] `main` con `push = No one`, `merge = Maintainers` y sin force push
- [ ] Has visto a GitLab rechazar tu propio `push` a `main`
- [ ] `v*` protegido, solo Maintainers crean
- [ ] Has creado un tag `v*` y comprobado que no se borra por Git
- [ ] Sabes qué rol efectivo tiene cada identidad en `app`
- [ ] La protección por defecto del grupo en *Fully protected*
- [ ] Una foto de las protecciones en `~/.bc-gitlab-gobernanza.json`

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 07
```

Tras esta práctica deberían pasar las seis primeras comprobaciones: la rama y los tags.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| El `POST` devuelve `409` | La regla no se borró: el `DELETE` falló o se ejecutó con otra ruta | `GET .../protected_branches` y repetir el `DELETE` |
| El `POST` devuelve `403` | Tu token no tiene Maintainer en `app` | Usa el token del Owner |
| El `push` del paso 3 entra | Hay otra regla más permisiva que también coincide con `main` | Listar todas las reglas del paso 1 y quitar la que sobra |
| `can_push: true` tras el paso 2 | El `POST` no se ejecutó o se ejecutó con `push_access_level` distinto de `0` | Repetir el paso 2 y leer la salida del `jq` |
| El tag de prueba se crea pero el `GET` dice `protected: false` | El patrón se creó como `v` sin el `*` | Borrar la regla `v` y crear `v*` |
| La plantilla de squash no tiene `%{approved_by}` (paso 0) | La Semana 06 se cerró con una plantilla que solo tenía `%{reviewed_by}` | Semana 06, práctica 01, paso 3 |
| El `PUT` del grupo devuelve `400` | El JSON no llega como JSON | Falta `-H "Content-Type: application/json"` |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Semana 07](../README.md) | **Práctica 01** | [Práctica 02 — CODEOWNERS y la auditoría](02-codeowners-y-la-auditoria.md) |

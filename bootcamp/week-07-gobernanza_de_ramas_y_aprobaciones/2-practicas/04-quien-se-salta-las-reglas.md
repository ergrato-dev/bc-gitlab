# Práctica 04 — Quién se salta las reglas

> `revisor` es Maintainer de `app`. Con su token quitas la protección de `main` e intentas escribir directamente. La protección cae en un segundo; el hook no. Después lo detectas, lo restauras, escribes el ADR-005 con lo aprendido y revocas el token.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 03 completada · Teoría [07](../1-teoria/07-lo-que-no-se-puede-bloquear.md) leída

---

## Contexto

Esta práctica ataca tus propias reglas. No es un ejercicio de seguridad ofensiva: es la forma de saber **cuál de tus controles aguanta** cuando alguien con permisos legítimos decide saltárselo, por prisa o por error.

| Capa | ¿La puede quitar `revisor`? | ¿Qué esperas ver? |
|---|:--:|---|
| Rama protegida | Sí | Cae |
| Server hook | No | Aguanta |
| Auditoría | No | Lo detecta |

> [!WARNING]
> Durante los pasos 2 a 4, `main` está sin proteger. Hazlos seguidos, sin pausas, y no cierres la terminal en medio. El paso 1 guarda el estado exacto al que volver.

---

## Paso 0: Preparar el terreno

```bash
source ~/.bc-gitlab
source ~/.bc-gitlab-s07
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
```

Si no tienes `$HR` de la práctica anterior, repite el paso 0 de la [práctica 02](02-codeowners-y-la-auditoria.md).

Recupera la función `foto` de la práctica 01, paso 9.

**Verifica**:

```bash
curl -s -H "$HR" "$API/user" | jq -r .username            # revisor-<tu-dominio>
diff <(foto) ~/.bc-gitlab-gobernanza.json && echo "sin cambios"
```

Y lo más importante antes de quitar ninguna protección: que el hook está activo. Si no lo está, el paso 3 escribiría de verdad en `main`.

```bash
git switch main && git pull --ff-only && git switch -c prueba-hook-activo
git commit -S --allow-empty -m "cambios varios"
git push origin prueba-hook-activo 2>&1 | grep -c 'GL-HOOK-ERR'      # 1
git switch main && git branch -D prueba-hook-activo
```

Si sale `0`, **para aquí**: vuelve a la práctica 03, paso 5, y no sigas hasta que el `push` se rechace.

---

## Paso 1: Lo que puede `revisor`

**Por qué**: antes de atacar, saber con qué permisos. El rol efectivo de `revisor` en `app` decide qué puede cambiar.

```bash
curl -s -H "$HR" "$API/projects/$P" | jq '.permissions'
curl -s -H "$HR" "$API/projects/$P/repository/branches/main" | jq '{protected, can_push}'
foto > ~/.bc-gitlab-protecciones-ok.json
```

**Verifica**: `project_access.access_level` es `40` (Maintainer), y `can_push: false`: con la protección puesta, `revisor` tampoco puede empujar a `main`. `~/.bc-gitlab-protecciones-ok.json` existe y es igual a `~/.bc-gitlab-gobernanza.json`.

---

## Paso 2: `revisor` quita la protección

**Por qué**: en CE no existe *Allowed to unprotect* (**Premium**). Cualquier Maintainer puede hacer esto. Verlo es la mejor explicación de por qué la rama protegida no basta.

Como **revisor** (`$HR`):

```bash
curl -s --request DELETE "$API/projects/$P/protected_branches/main" -H "$HR" -o /dev/null -w '%{http_code}\n'
curl -s -H "$HR" "$API/projects/$P/repository/branches/main" | jq '{protected, can_push}'
```

**Verifica**: el `DELETE` devuelve `204` y la rama sale `protected: false`, `can_push: true`. Un Maintainer acaba de quitar la regla que la Semana 07 tardó una práctica en poner.

---

## Paso 3: `revisor` escribe en `main`

**Por qué**: es lo que haría alguien con prisa después del paso 2. Se usa la API de commits, que no necesita clonar nada ni poner el token en una URL de Git. Para el hook llega con `GL_PROTOCOL=web`: no exige firma, pero sí formato y aprobación.

Como **revisor** (`$HR`):

```bash
curl -s --request POST "$API/projects/$P/repository/commits" -H "$HR" -H "Content-Type: application/json" \
  --data '{"branch": "main",
           "commit_message": "docs: urgent note",
           "actions": [{"action": "create", "file_path": "URGENTE.md", "content": "arreglo rapido\n"}]}' \
  -w '\n%{http_code}\n'
```

**Verifica**: código `400`, y el mensaje contiene `nada entra en main sin una aprobación`. El commit no existe:

```bash
curl -s -o /dev/null -w '%{http_code}\n' -H "$H" "$API/projects/$P/repository/files/URGENTE.md?ref=main"   # 404
```

La protección cayó, el hook no. Pero no te confíes: si `revisor` hubiera añadido `Approved-by: cualquiera` al `commit_message`, el hook lo habría aceptado (llega por `web`, así que no pide firma, y el trailer está). No lo hagas: escribiría en `main`. Lo que detecta ese caso es la auditoría de commits sin merge request del paso 6. El mensaje es convencional a propósito: si no lo fuera, el hook lo habría rechazado por el formato antes de llegar a la aprobación, y no se vería la regla que importa.

---

## Paso 4: Detectarlo y restaurarlo

**Por qué**: la foto de la práctica 01 existe para este momento. Primero se ve qué cambió; después se restaura exactamente lo que había, no lo que recuerdas.

```bash
diff <(foto) ~/.bc-gitlab-gobernanza.json
```

La salida muestra la regla de `main` que falta. Restáurala como **tú** (`$H`), con los valores de la foto:

```bash
curl -s --request POST "$API/projects/$P/protected_branches" -H "$H" \
  --data-urlencode "name=main" \
  --data-urlencode "push_access_level=0" \
  --data-urlencode "merge_access_level=40" \
  --data-urlencode "allow_force_push=false" -o /dev/null -w '%{http_code}\n'
```

**Verifica**:

```bash
diff <(foto) ~/.bc-gitlab-gobernanza.json && echo "sin cambios"
curl -s -H "$HR" "$API/projects/$P/repository/branches/main" | jq '{protected, can_push}'   # true, false
```

Si `diff` muestra algo más que la rama, alguien cambió otra cosa: no sigas hasta entender qué.

---

## Paso 5: La autoaprobación, a la vista

**Por qué**: el otro hueco de la teoría [07](../1-teoria/07-lo-que-no-se-puede-bloquear.md): el autor aprueba lo suyo y el hook lo deja pasar. No hace falta fusionar nada para verlo; basta con una merge request abierta.

Abre una merge request de prueba, apruébala **con tu token**, y pasa la auditoría:

```bash
git switch main && git pull --ff-only
git switch -c prueba-autoaprobacion
git commit -S --allow-empty -m "chore: probar la autoaprobación"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main -o merge_request.title="chore: probar la autoaprobación"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=prueba-autoaprobacion&state=opened" | jq -r '.[0].iid')

curl -s --request POST "$API/projects/$P/merge_requests/$MR/approve" -H "$H" | jq -r '.approved_by[].user.username'
bash scripts/gobernanza.sh "$MR"
```

**Verifica**: la aprobación se acepta (sale tu usuario: CE lo permite) y la auditoría dice `❌ nadie distinto de @<tú> la ha aprobado`. También `❌ no cierra ningún issue`, porque la rama no nace de uno; el commit vacío no toca archivos, así que no hay líneas de dueños. Si fusionaras, el hook vería `Approved-by:` y dejaría pasar. Por eso existe la auditoría.

Cierra la merge request sin fusionar y borra la rama:

```bash
curl -s --request PUT "$API/projects/$P/merge_requests/$MR" -H "$H" --data-urlencode "state_event=close" | jq -r .state   # closed
git push origin --delete prueba-autoaprobacion
git switch main && git branch -D prueba-autoaprobacion
```

---

## Paso 6: La auditoría de la semana

**Por qué**: el estado final de `app`, de un vistazo. Es lo que ejecutarás cada semana hasta que lo haga un pipeline.

```bash
diff <(foto) ~/.bc-gitlab-gobernanza.json && echo "protecciones: sin cambios"
for iid in $(curl -s -H "$H" "$API/projects/$P/merge_requests?state=merged&per_page=100" | jq -r '.[].iid'); do
  printf '!%-4s ' "$iid"; bash scripts/gobernanza.sh "$iid" | tail -n 1
done
desde=$(date -d '-30 days' --iso-8601=seconds)
for sha in $(curl -s -H "$H" "$API/projects/$P/repository/commits?ref_name=main&first_parent=true&since=$desde&per_page=100" | jq -r '.[].id'); do
  [ "$(curl -s -H "$H" "$API/projects/$P/repository/commits/$sha/merge_requests" | jq length)" -gt 0 ] \
    || echo "❌ ${sha:0:8} entró en main sin merge request"
done
```

El último bucle es el de la teoría [07](../1-teoria/07-lo-que-no-se-puede-bloquear.md), apartado 2.4: commits de la línea principal de `main` sin merge request.

**Verifica**: protecciones sin cambios, ningún commit de `main` sin merge request salvo el `push` directo de `Default.md` de la Semana 06 si cae en el rango, y las merge requests de esta semana (la de `CODEOWNERS`, la del hook y la del paso 7 de la práctica 03) con `0 problema(s)`. Las de la Semana 06 salen como en la práctica 02.

---

## Paso 7: El ADR-005

**Por qué**: un ADR por cada decisión que cuesta revertir. Esta semana hay varias, y lo que viste en los pasos 2 a 5 es la sección de consecuencias.

```bash
curl -s --request POST "$API/projects/$P/wikis" -H "$H" \
  --data-urlencode "title=ADR-005 Gobernanza de main" \
  --data-urlencode "content@-" <<'EOF'
# ADR-005: Gobernanza de main

**Estado**: aceptada · **Fecha**: <hoy> · **Decide**: <tú>, con revisión de revisor-<dominio>

## Contexto

En la Semana 06 el flujo por merge request era una convención: el Owner podía empujar a main, y la aprobación era opcional.
GitLab CE no tiene approval rules, Code Owners approval, push rules ni "Allowed to unprotect" (todo Premium).

## Decisión

1. main: push = No one, merge = Maintainers, sin force push. Tags v*: crean Maintainers.
2. CODEOWNERS en la raíz. /src/, /scripts/, /.gitlab/ y /CODEOWNERS son de revisor.
3. Server hook pre-receive (scripts/hooks/pre-receive), instalado con `gitaly hooks set`:
   historia lineal y firma en lo que empuja una persona, asunto convencional en todo,
   y Approved-by en todo lo que entra en main.
4. scripts/gobernanza.sh audita cada MR: issue, aprobación de otra persona, aprobación del dueño.
   Detecta, no bloquea. En la Semana 09 pasa a ser un job.

## Consecuencias

- Un Maintainer puede quitar la protección de main (comprobado: práctica 04, paso 2). El hook sigue exigiendo Approved-by, pero un Maintainer puede escribirlo a mano en un commit por API. Solo la auditoría de commits de main sin MR lo detecta.
- El autor puede aprobar su propia MR y el hook lo acepta. Solo la auditoría lo detecta.
- Quien fusiona puede escribir un Approved-by falso en el mensaje. Solo la auditoría lo detecta.
- Los commits que escribe GitLab (squash, fusión, sugerencias) no van firmados. Está aceptado.
- El botón Revert de la UI genera un asunto no convencional: hay que editarlo.
- Estado de partida: <MR de la Semana 06 que no pasan la auditoría, de la práctica 02 paso 8>.

## Emergencia

Quién: solo el Owner. Qué se salta: la aprobación de otra persona, nunca la MR.
Cómo: el Owner aprueba su propia MR. Queda un issue tipo::bug con la etiqueta emergencia, enlazado.
Después: revisor revisa la MR fusionada en 48 horas y lo deja escrito en el issue.
Nunca: quitar la protección de main ni el hook. Si el hook falla y bloquea todo, el administrador lo quita con
`gitaly hooks set` y un tarball vacío (práctica 03, paso 9), y lo reinstala en cuanto esté corregido.
EOF
```

Edita en la wiki los `<...>` con tus datos: la fecha, tu usuario y la lista del estado de partida.

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/wikis" | jq -r '.[].slug' | grep -i adr-005
```

---

## Paso 8: Revocar el token del revisor

**Por qué**: era para estas tres prácticas y ya terminaron. Usa la misma cabecera con la que lo creaste.

```bash
HA="PRIVATE-TOKEN: ${GITLAB_ADMIN_TOKEN:-$GITLAB_TOKEN}"

for id in $(curl -s -H "$HA" "$API/personal_access_tokens?user_id=$UID_REV" \
              | jq -r '.[] | select(.name == "gobernanza-s07" and .active) | .id'); do
  curl -s --request DELETE "$API/personal_access_tokens/$id" -H "$HA" -o /dev/null -w "revocado $id: %{http_code}\n"
done
```

**Verifica**, antes de borrar las variables, que el token ya no vale y que no queda ninguno activo:

```bash
curl -s -o /dev/null -w '%{http_code}\n' -H "$HR" "$API/user"     # 401
curl -s -H "$HA" "$API/personal_access_tokens?user_id=$UID_REV" \
  | jq '[.[] | select(.name == "gobernanza-s07" and .active)] | length'   # 0

unset T_REV HR HA
rm -f ~/.bc-gitlab-s07 ~/.bc-gitlab-protecciones-ok.json ~/.bc-gitlab-protecciones-antes.json
```

Si el primero no da `401` o el segundo no da `0`, el token sigue vivo: repite el bucle con la cabecera de administrador.

`~/.bc-gitlab-gobernanza.json` **no se borra**: es la foto de referencia para la auditoría de las próximas semanas.

---

## ✅ Resultado

- [ ] Has visto a un Maintainer quitar la protección de `main` en CE
- [ ] Has visto al hook rechazar el commit directo aunque la protección no estuviera
- [ ] Has detectado el cambio con la foto y restaurado la protección exacta
- [ ] Has visto la autoaprobación aceptada por GitLab y detectada por la auditoría
- [ ] ADR-005 en la wiki, con consecuencias y procedimiento de emergencia
- [ ] El token del revisor está revocado

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 07
```

Con las prácticas 01 a 04 hechas, las 15 comprobaciones deberían pasar.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| El `DELETE` del paso 2 devuelve `403` | `revisor` no es Maintainer en `app` | Práctica 01, paso 7; es el resultado bueno para la seguridad, pero entonces el paso 3 no prueba el hook |
| El commit del paso 3 entra (`201`) | El hook no está instalado o no tiene permiso de ejecución | **Restaura la protección ya** (paso 4), borra el commit con una MR de `revert:` y vuelve a la práctica 03, paso 5 |
| El paso 3 devuelve `400` con `You are not allowed to push` | La protección no se llegó a quitar | El paso 2 falló: revisa su salida |
| `diff` del paso 4 muestra más cambios que `main` | Alguien cambió otra protección, o la foto es anterior a la práctica 01 | Comparar con `~/.bc-gitlab-protecciones-ok.json` del paso 1 |
| La auditoría del paso 5 sale en verde | Tu token es el de `revisor`, no el tuyo | Repetir la aprobación con `$H` |
| El `POST` de la wiki devuelve `400` | El título ya existe | `PUT .../wikis/<slug>` con el mismo `content` |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Práctica 03 — El server hook](03-el-server-hook.md) | **Práctica 04** | [Proyecto Semana 07](../3-proyecto/README.md) |

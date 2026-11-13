# Lo que no se puede bloquear

> Toda regla tiene alguien que puede saltársela: un Maintainer quita la protección, un administrador quita el hook, quien fusiona escribe un trailer falso. Lo que no se puede bloquear se detecta, y el procedimiento para saltarse una regla a propósito se escribe antes de necesitarlo.

---

## 🎯 Objetivos

- Enumerar quién puede saltarse cada capa de gobernanza de `app` y cómo
- Leer el script `gobernanza` y saber qué comprueba de cada merge request
- Detectar que alguien cambió una protección, comparando con una foto conocida
- Escribir un procedimiento de emergencia (*break-glass*) que no dependa de improvisar

---

## 1. Qué problema resuelve

Al terminar la práctica 03, `app` tiene tres capas: rama y tags protegidos, `CODEOWNERS` y el server hook. Ninguna es absoluta:

| Quién | Qué puede hacer | Lo frena |
|---|---|---|
| **Autor** (Owner) | Aprobar su propia merge request | Nada: CE lo permite. El hook ve `Approved-by:` y deja pasar |
| **Quien fusiona** | Escribir el mensaje del squash con un `Approved-by:` inventado | Nada en el momento |
| **Maintainer** (`revisor`) | Quitar la protección de `main` y empujar | El hook, si el commit no lleva `Approved-by:` |
| **Maintainer** | Quitar la protección de `v*` y mover un tag | Nada: el hook no mira tags |
| **Administrador** | Quitar el hook con `gitaly hooks set` | Nada técnico |

Bloquear las cinco filas exigiría Premium (*Allowed to unprotect*, *Prevent approval by author*) o controles fuera de GitLab. Lo que sí se puede en CE es **verlo**: cada una de estas acciones deja rastro en la API, y una comprobación que se ejecuta con regularidad lo encuentra.

---

## 2. Cómo funciona

### 2.1 Tres preguntas, tres comprobaciones

| Pregunta | Dónde está la respuesta | Quién la hace |
|---|---|---|
| ¿Cada merge request la aprobó otra persona, dueña de lo que toca? | `.../merge_requests/<iid>/approvals`, `.../diffs` y `CODEOWNERS` | `scripts/gobernanza.sh` |
| ¿Las protecciones siguen como las dejamos? | `.../protected_branches`, `.../protected_tags` | `verificar-semana.sh 07`, o una foto comparada |
| ¿Las merge requests con `Approved-by:` tenían una aprobación real de otra persona? | `.../merge_requests/<iid>/approvals` | `gobernanza.sh` sobre las MR fusionadas |
| ¿Entró algo en `main` sin merge request? | `.../repository/commits/<sha>/merge_requests` de cada commit de `main` | El bucle del apartado 2.4 |

### 2.2 El script `gobernanza`

```bash
#!/usr/bin/env bash
# Auditoría de gobernanza de una merge request de app. Detecta, no bloquea: ver ADR-005.
# Uso: scripts/gobernanza.sh <iid>   (en la Semana 09 lo ejecuta un job con las variables CI_*)
set -euo pipefail

API=${CI_API_V4_URL:-$GITLAB_URL/api/v4}
P=${CI_PROJECT_ID:-$(printf '%s' "$PROYECTO" | jq -sRr @uri)}
IID=${1:-${CI_MERGE_REQUEST_IID:?uso: gobernanza.sh <iid>}}

api() { curl -sf -H "PRIVATE-TOKEN: ${GOBERNANZA_TOKEN:-$GITLAB_TOKEN}" "$API/projects/$P/$1"; }
fallos=0
falla() { echo "❌ $*"; fallos=$((fallos + 1)); }
bien()  { echo "✅ $*"; }

mr=$(api "merge_requests/$IID")
autor=$(jq -r .author.username <<<"$mr")
destino=$(jq -r .target_branch <<<"$mr")
aprobadores=$(api "merge_requests/$IID/approvals" \
  | jq -r --arg a "$autor" '.approved_by[].user.username | select(. != $a)')

[ "$(api "merge_requests/$IID/closes_issues" | jq length)" -gt 0 ] \
  && bien "cierra un issue" || falla "no cierra ningún issue"
[ -n "$aprobadores" ] \
  && bien "aprobada por: $(echo $aprobadores)" || falla "nadie distinto de @$autor la ha aprobado"

# CODEOWNERS de la rama de destino, no el de la MR: si no, la MR podría nombrarse dueña de lo que toca
co=$(mktemp); trap 'rm -f "$co"' EXIT
api "repository/files/CODEOWNERS/raw?ref=$destino" > "$co" \
  || { falla "no hay CODEOWNERS en $destino"; exit 1; }

# ponytail: solo prefijos (/dir/, /archivo) y *, sin globs ni secciones; gana la última regla que coincide
duenos() { awk -v f="/$1" '/^[[:space:]]*(#|$)/ {next} $1=="*" || index(f,$1)==1 {d=$0}
                          END {sub(/^[^ ]+ +/,"",d); print d}' "$co"; }

archivos=$(api "merge_requests/$IID/diffs?per_page=100" | jq -r '.[].new_path' | sort -u)
# ponytail: sin paginar; con 100 archivos o más la auditoría sería incompleta, así que falla en vez de mentir
[ "$(grep -c . <<<"$archivos")" -lt 100 ] || falla "100 archivos o más: auditoría incompleta, revísala a mano"

while read -r archivo; do
  d=$(duenos "$archivo")
  if [ -z "$d" ]; then falla "$archivo no tiene dueño"; continue; fi
  ok=no
  for a in $aprobadores; do [[ " $d " == *" @$a "* ]] && ok=si; done
  [ $ok = si ] && bien "$archivo: aprobado por su dueño" || falla "$archivo: falta la aprobación de $d"
done <<<"$archivos"

echo "$fallos problema(s) en !$IID"
[ "$fallos" -eq 0 ]
```

Tres decisiones de diseño:

- **Excluye al autor de los aprobadores.** El hook no puede distinguir una autoaprobación; el script sí, porque tiene la merge request entera.
- **Lee las aprobaciones reales**, no el trailer. Si alguien escribió `Approved-by:` a mano al fusionar, el script lo descubre: el commit dice una cosa y la API otra.
- **Falla cerrado.** Si la merge request toca 100 archivos o más, no los pagina: dice que la auditoría está incompleta en lugar de dar un `0 problema(s)` falso.
- **Su propio token si lo hay.** Lee `GOBERNANZA_TOKEN` antes que `GITLAB_TOKEN`. En el laboratorio usas el tuyo, que es el del autor de las merge requests auditadas: es la excepción que el antipatrón del apartado 4 describe, aceptada porque aquí eres la única persona. En la Semana 09, el job tendrá el suyo.
- **Las variables `CI_*` primero.** En la Semana 09 el mismo archivo se ejecuta como job sin cambiar una línea; esta semana lo ejecutas tú con las variables de `~/.bc-gitlab`.

Sale con código distinto de cero si encuentra algo. Esta semana eso solo significa que la terminal lo dice; cuando sea un job, el pipeline saldrá en rojo.

### 2.3 Auditar lo ya fusionado

El script mira una merge request. Para todas las fusionadas, un bucle:

```bash
for iid in $(curl -s -H "$H" "$API/projects/$P/merge_requests?state=merged&per_page=100" | jq -r '.[].iid'); do
  echo "== !$iid"; bash scripts/gobernanza.sh "$iid" | tail -n 1
done
```

Las de la Semana 06 fallarán en algo: se fusionaron antes de que existiera `CODEOWNERS`, y el script lee el de hoy. No es un problema que haya que arreglar; es la diferencia entre antes y después de la regla, y queda escrita en el ADR-005.

### 2.4 Detectar commits que no pasaron por una merge request

El script audita merge requests. Un commit que entró en `main` sin merge request (por ejemplo, un Maintainer que desprotege `main` y escribe por la API un mensaje con un `Approved-by:` inventado) no tiene merge request que auditar, y el hook lo habría dejado pasar. Se detecta al revés: cada commit de la línea principal de `main` tiene que venir de una merge request.

```bash
desde=$(date -d '-30 days' --iso-8601=seconds)
for sha in $(curl -s -H "$H" "$API/projects/$P/repository/commits?ref_name=main&first_parent=true&since=$desde&per_page=100" | jq -r '.[].id'); do
  [ "$(curl -s -H "$H" "$API/projects/$P/repository/commits/$sha/merge_requests" | jq length)" -gt 0 ] \
    || echo "❌ ${sha:0:8} entró en main sin merge request"
done
```

`first_parent=true` recorre solo la línea principal: los commits de fusión y de squash, no los de dentro de cada rama. Saldrá el último `push` directo de la Semana 06 (el de `Default.md`) si está dentro del rango: es conocido y está documentado.

### 2.5 Detectar que una protección cambió

Una foto de las protecciones, guardada fuera de GitLab, y una comparación:

```bash
foto() {
  curl -s -H "$H" "$API/projects/$P/protected_branches" \
    | jq -S '[.[] | {name, push: [.push_access_levels[].access_level], merge: [.merge_access_levels[].access_level], allow_force_push}]'
  curl -s -H "$H" "$API/projects/$P/protected_tags" \
    | jq -S '[.[] | {name, create: [.create_access_levels[].access_level]}]'
}
foto > ~/.bc-gitlab-gobernanza.json          # una vez, con todo bien
diff <(foto) ~/.bc-gitlab-gobernanza.json && echo "sin cambios"
```

`verificar-semana.sh 07` hace lo mismo con las comprobaciones de esta semana. Ejecutarlo cada lunes es la auditoría más barata que existe. En CE no hay registro de **quién** cambió la protección (los *audit events* son **Premium**): sabrás qué cambió, y lo tendrás que preguntar.

### 2.6 Romper el cristal a propósito

Habrá un día en que haga falta saltarse una regla: un incidente en producción a las tres de la mañana, `revisor` de vacaciones y un arreglo de una línea. Si no hay procedimiento, alguien quitará la protección, empujará, y quizá se acuerde de volver a ponerla.

Un procedimiento de emergencia (*break-glass*) responde antes de que pase:

| Pregunta | Respuesta en `app` |
|---|---|
| ¿Quién puede activarlo? | El Owner, y solo él |
| ¿Qué se salta? | La aprobación de otra persona. Nunca la merge request: el cambio sigue entrando por MR |
| ¿Cómo? | El Owner aprueba su propia MR. El hook pasa (ve `Approved-by:`), la auditoría lo marca |
| ¿Qué queda escrito? | Un issue `tipo::bug` con la etiqueta `emergencia`, enlazado desde la MR |
| ¿Qué pasa después? | En 48 horas, `revisor` revisa la MR ya fusionada y deja constancia en el issue |

El detalle importante: **la emergencia no quita ninguna capa**. Usa el hueco que ya existe (la autoaprobación de CE) y lo deja a la vista de la auditoría. Quitar la protección o el hook "un momento" es exactamente lo que el procedimiento evita.

---

## 3. Cómo se configura

No hay nada que configurar en GitLab. Se configura la costumbre:

1. `scripts/gobernanza.sh` en el repositorio, por merge request.
2. La foto de las protecciones en `~/.bc-gitlab-gobernanza.json`, tomada justo después de la práctica 01.
3. El procedimiento de emergencia en el ADR-005, en la wiki.
4. Un recordatorio para ejecutar los bucles de los apartados 2.3 y 2.4 y `verificar-semana.sh 07` cada semana, hasta que en la Semana 11 lo haga un pipeline programado.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Confiar en `Approved-by:` como prueba de aprobación | Se puede escribir a mano y el autor puede aprobar lo suyo | Contrastar con `.../approvals` y excluir al autor |
| Auditar con un token de quien está siendo auditado | Si su token puede cambiar las reglas, puede cambiar lo que la auditoría ve | Ejecutarla con un token de solo lectura (`read_api`) |
| Quitar la protección "un momento" en una emergencia | El momento se alarga, y nadie sabe qué entró mientras | Procedimiento escrito que no quite ninguna capa |
| Auditoría que nadie ejecuta | Detectar seis meses tarde es no detectar | Cada semana a mano; en la S11, programada |
| Un script de auditoría que solo dice "falla" | Nadie sabe qué arreglar | Una línea por problema, con la MR y el archivo |

---

## 5. Trucos

- **Un token solo para auditar**: los scripts de auditoría solo leen. `scopes[]=read_api` y caducidad corta: si se filtra, no puede cambiar nada.
- **La MR que creó un commit de `main`**: `GET .../repository/commits/<sha>/merge_requests | jq -r '.[].iid'`. Así se pasa de un `Approved-by:` sospechoso en `git log` a su merge request y sus aprobaciones reales.
- **El bucle de auditoría como alias** en `~/.bc-gitlab`: lo que es fácil de ejecutar se ejecuta.

---

## 📚 Recursos Adicionales

- [Merge request approvals API](https://docs.gitlab.com/api/merge_request_approvals/) — lo que CE expone de las aprobaciones
- [Commits API — merge requests de un commit](https://docs.gitlab.com/api/commits/#list-merge-requests-associated-with-a-commit) — del commit a su merge request
- [Google SRE — Emergency response](https://sre.google/sre-book/emergency-response/) — por qué se escribe el procedimiento antes del incidente

---

## ✅ Checklist de Verificación

- [ ] Puedes nombrar a quién puede saltarse cada capa de `app` y cómo lo verías después
- [ ] Sabes por qué `gobernanza.sh` excluye al autor y no confía en el trailer
- [ ] Tienes una foto de las protecciones guardada fuera de GitLab
- [ ] Sabes qué dice tu procedimiento de emergencia y por qué no quita ninguna capa

---

[← Anterior: Un hook de gobernanza](06-un-hook-de-gobernanza.md) · [Volver a la Semana 07](../README.md)

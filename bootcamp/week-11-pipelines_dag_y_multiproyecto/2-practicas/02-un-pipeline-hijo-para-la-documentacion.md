# Práctica 02 — Un pipeline hijo para la documentación

> Escribes `scripts/caducidades.sh`, que falla si un secreto de `docs/secretos.md` caduca pronto, y lo metes con `markdownlint` en un pipeline hijo, `ci/docs.yml`. El padre lo dispara solo cuando una merge request toca un `.md`, y su estado bloquea la fusión. Lo compruebas con una merge request que rompe la documentación a propósito.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 01 completada · Teoría [03](../1-teoria/03-pipelines-padre-hijo.md) leída

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | Fechas en `docs/secretos.md` y `scripts/caducidades.sh` | — |
| 2 | `ci/docs.yml` y la configuración de `markdownlint` | — |
| 3 | El job de disparo `docs` en el padre | `hijo-de-documentacion` |
| 4 | La merge request, con su hijo en verde, fusionada | `pipeline-hijo-correcto` |
| 5 | Una merge request que rompe la documentación, bloqueada | — |

Si has cerrado la terminal desde la práctica 01, repite su paso 0 entero.

---

## Paso 1: Fechas que una máquina pueda leer

**Por qué**: la columna "Caduca o se rota" de `docs/secretos.md` (Semana 10) está escrita para personas. Un job solo puede vigilarla si cada fila tiene una fecha `AAAA-MM-DD`.

```bash
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Revisión automática de la documentación en un pipeline hijo" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=markdownlint y caducidades de secretos en ci/docs.yml, disparado solo si cambia un .md. Ver Semana 11." \
  | jq -r .iid)
git switch main && git pull --ff-only
git switch -c "$IID-pipeline-hijo-docs"
```

La fecha de `GOBERNANZA_TOKEN` no la inventas: es la del token que rotaste en la Semana 10.

```bash
curl -s -H "$H" "$API/projects/$P/access_tokens" \
  | jq -r '.[] | select(.name == "gobernanza-ci" and .active) | .expires_at'
```

`DEPLOY_TOKEN` y `DEPLOY_SSH_KEY` no caducan solos: la fecha es la de tu política de rotación (por ejemplo, 180 días desde que los creaste). Edita la tabla para que cada fila lleve su fecha en esa columna, con el texto que quieras alrededor:

```markdown
| `GOBERNANZA_TOKEN` | … | Caduca el 2027-05-13 |
| `DEPLOY_TOKEN` | … | Rotar antes del 2027-05-10 |
```

Ahora el script. Lee las filas de la tabla que empiezan por un nombre de secreto entre comillas invertidas, toma la primera fecha de cada una y falla si alguna cae dentro del plazo de aviso, o si no encuentra ninguna:

```bash
cat > scripts/caducidades.sh <<'EOF'
#!/bin/sh
# Falla si algún secreto de docs/secretos.md caduca en menos de AVISO_DIAS días.
# Se ejecuta en el pipeline hijo de documentación y en el programado de cada mañana.
set -eu
AVISO_DIAS=${AVISO_DIAS:-30}
LIMITE=$(date -u -d "@$(( $(date +%s) + AVISO_DIAS * 86400 ))" +%F)
echo "Aviso si caduca antes de $LIMITE ($AVISO_DIAS días)"
awk -v limite="$LIMITE" '
  /^\| *`[A-Z0-9_]+`/ && match($0, /20[0-9][0-9]-[0-1][0-9]-[0-3][0-9]/) {
    n++; fecha = substr($0, RSTART, RLENGTH)
    split($0, c, "|"); nombre = c[2]; gsub(/[ `]/, "", nombre)
    if (fecha < limite) { pronto++; estado = "CADUCA PRONTO" } else { estado = "ok" }
    printf "%-20s %s  %s\n", nombre, fecha, estado
  }
  END {
    if (n == 0) { print "docs/secretos.md no tiene ninguna fila con fecha AAAA-MM-DD"; exit 1 }
    if (pronto > 0) { printf "%d secreto(s) caducan antes de %s: rótalos\n", pronto, limite; exit 1 }
  }' docs/secretos.md
EOF
chmod +x scripts/caducidades.sh
```

Las fechas `AAAA-MM-DD` se comparan bien como texto: por eso `awk` no necesita convertirlas.

**Verifica** en local, las dos caras:

```bash
scripts/caducidades.sh; echo "salida: $?"
# GOBERNANZA_TOKEN     2027-05-13  ok
# DEPLOY_TOKEN         2027-05-10  ok
# …
# salida: 0
AVISO_DIAS=400 scripts/caducidades.sh; echo "salida: $?"
# … CADUCA PRONTO …
# salida: 1
```

---

## Paso 2: `ci/docs.yml`

**Por qué**: el hijo es otro archivo, con su propio `workflow`. Sin él, el hijo no nacería en una merge request (teoría 03, apartado 2.3).

```bash
mkdir -p ci
cat > ci/docs.yml <<'EOF'
# Pipeline hijo de documentación. Lo dispara el job docs de .gitlab-ci.yml
# cuando una merge request cambia un .md. El workflow del padre no se aplica aquí.
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "parent_pipeline"

default:
  interruptible: true

markdownlint:
  image: node:22.23.3-alpine3.24
  script:
    - npx --yes markdownlint-cli2@0.24.0 "**/*.md"

caducidades:
  image: alpine:3.24.2
  script:
    - scripts/caducidades.sh
EOF

cat > .markdownlint-cli2.jsonc <<'EOF'
{
  // Reglas por defecto, salvo las que chocan con cómo se escribe este repositorio.
  "config": {
    "default": true,
    "MD013": false,                      // longitud de línea: la prosa no se corta a 80
    "MD033": false,                      // HTML: las insignias del README lo usan
    "MD041": false,                      // primera línea: las plantillas no empiezan por título
    "MD024": { "siblings_only": true }   // títulos repetidos solo entre hermanos
  },
  // Lo generado no se revisa: se regenera.
  "ignores": ["node_modules/**", "CHANGELOG.md"]
}
EOF
```

Antes de empujar, pásalo en local: si tu documentación tiene errores, los arreglas aquí y no en tres vueltas de pipeline.

```bash
npx --yes markdownlint-cli2@0.24.0 "**/*.md"
```

**Verifica**: `Summary: 0 error(s)`. Si salen errores, arréglalos en los `.md`. Desactivar una regla más es válido solo si puedes escribir su comentario de por qué, como los de arriba.

Valida el hijo como lo que es, un archivo de configuración aparte (sin `dry_run`: simularía un push, que su `workflow` rechaza):

```bash
jq -n --rawfile c ci/docs.yml '{content: $c}' \
  | curl -s --request POST "$API/projects/$P/ci/lint" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -c '{valid, errors}'
# {"valid":true,"errors":[]}
```

---

## Paso 3: El job de disparo

**Por qué**: el padre gana **un** job con **una** regla. Lo que pase dentro es asunto de `ci/docs.yml`.

En `.gitlab-ci.yml`, junto a `gobernanza`:

```yaml
docs:
  stage: test
  needs: []
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        paths:
          - "**/*.md"
          - .markdownlint-cli2.jsonc
          - ci/docs.yml
          - scripts/caducidades.sh
  trigger:
    include: ci/docs.yml
    strategy: mirror
```

`ci/` es configuración del pipeline: que tenga el mismo dueño que `.gitlab-ci.yml` (teoría 04, apartado 3.1).

```bash
printf '/ci/ @%s\n' "$REV" >> CODEOWNERS
tail -3 CODEOWNERS

jq -n --rawfile c .gitlab-ci.yml '{content: $c}' \
  | curl -s --request POST "$API/projects/$P/ci/lint" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -c '{valid, errors}'
# {"valid":true,"errors":[]}
```

---

## Paso 4: La merge request y su hijo

**Por qué**: esta merge request cambia un `.md`, así que es la primera con hijo.

```bash
git add .gitlab-ci.yml ci/docs.yml .markdownlint-cli2.jsonc scripts/caducidades.sh docs/secretos.md CODEOWNERS
git ls-files -s scripts/caducidades.sh | cut -c1-6                  # 100755
git commit -S -m "ci: pipeline hijo de documentación con markdownlint y caducidades"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="ci: pipeline hijo de documentación con markdownlint y caducidades"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
sleep 10
PIPE=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/pipelines" | jq -r '.[0].id')
esperar "$P" "$PIPE"
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/bridges" \
  | jq -c '.[] | {name, status, hijo: .downstream_pipeline.id}'
```

**Verifica**: `{"name":"docs","status":"success","hijo":<id>}`. El hijo y sus jobs:

```bash
HIJO=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/bridges" | jq -r '.[] | select(.name == "docs") | .downstream_pipeline.id')
curl -s -H "$H" "$API/projects/$P/pipelines/$HIJO" | jq -r '"\(.source) \(.status)"'          # parent_pipeline success
curl -s -H "$H" "$API/projects/$P/pipelines/$HIJO/jobs" | jq -r '.[] | "\(.name) \(.status)"'
curl -s -H "$H" "$API/projects/$P/pipelines?per_page=5" | jq -r '.[].id' | grep -c "^$HIJO$"   # 0
```

El último `0` es la teoría 03 en acción: la lista de pipelines no enseña al hijo si no lo pides con `source=parent_pipeline`.

Fusiona:

```bash
fusionar "$MR"
git switch main && git pull --ff-only
```

`fusionar` relanza el pipeline de la merge request, y con él otro hijo. **Verifica**: `state: merged`, y en `main` no hay job `docs`: su regla solo coincide en merge requests.

---

## Paso 5: Una documentación rota no entra

**Por qué**: un hijo que nunca falla no demuestra que `mirror` bloquee nada.

```bash
git switch -c prueba-docs-rotos
printf '\n#Sin espacio tras la almohadilla\n' >> README.md
git commit -S -am "docs: prueba de documentación rota (no fusionar)"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="Draft: prueba de documentación rota"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=prueba-docs-rotos&state=opened" | jq -r '.[0].iid')
sleep 10
PIPE=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/pipelines" | jq -r '.[0].id')
esperar "$P" "$PIPE"
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/bridges" | jq -c '.[] | {name, status}'
```

**Verifica**: el pipeline `failed` y `{"name":"docs","status":"failed"}`. En el log de `markdownlint` del hijo, `MD018/no-missing-space-atx`. *Pipelines must succeed* impide fusionarla.

Ciérrala sin fusionar y borra la rama:

```bash
curl -s --request PUT "$API/projects/$P/merge_requests/$MR" -H "$H" --data "state_event=close" | jq -r .state   # closed
git switch main && git branch -D prueba-docs-rotos && git push origin --delete prueba-docs-rotos
```

---

## ✅ Resultado

- [ ] `docs/secretos.md` con una fecha `AAAA-MM-DD` por secreto, la de `GOBERNANZA_TOKEN` sacada de la API
- [ ] `scripts/caducidades.sh` probado en local con éxito y con fallo
- [ ] `ci/docs.yml` con su propio `workflow`, y `ci/` en `CODEOWNERS`
- [ ] El job `docs` dispara el hijo solo si cambia la documentación, con `strategy: mirror`
- [ ] Un hijo en verde en la merge request fusionada, y uno en rojo que bloqueó la de prueba

```bash
./scripts/verificar-semana.sh 11      # hijo-de-documentacion y pipeline-hijo-correcto, en verde
```

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `docs` falla al instante, sin hijo | El `workflow` de `ci/docs.yml` no acepta `parent_pipeline`, o el archivo no está en la rama | Paso 2; `git ls-files ci/docs.yml` |
| `caducidades` falla con `no tiene ninguna fila con fecha` | Las filas no empiezan por el nombre del secreto entre comillas invertidas, o la fecha no es `AAAA-MM-DD` | Paso 1 |
| `caducidades` falla con `Permission denied` | El script sin bit de ejecución en Git | `git update-index --chmod=+x scripts/caducidades.sh` |
| `markdownlint` falla en el pipeline y no en local | Usaste otra versión en local | La misma: `markdownlint-cli2@0.24.0` en los dos sitios |
| El pipeline de la merge request en verde con el hijo en rojo | Falta `strategy: mirror` | Paso 3 |
| `fusionar` falla: `gobernanza` en rojo | Falta la aprobación del dueño de `ci/` o de `scripts/` | Lee el log de `gobernanza` |

---

## 🔗 Navegación

[← Anterior: De stages a DAG](01-de-stages-a-dag.md) · [Volver a la Semana 11](../README.md) · [Siguiente: El disparo a `infra` →](03-disparo-a-infra.md)

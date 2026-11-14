# Práctica 02 — Variables y precedencia

> Una sonda en una rama de prueba escribe de dónde le llega una variable. Defines la misma variable en el YAML, en el proyecto y al lanzar el pipeline, y ves cuál gana cada vez. Descubres qué pasa cuando una variable protegida no llega, y cierras la puerta a que un Developer pase variables a un pipeline.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 01 completada · Teoría [03](../1-teoria/03-variables-de-donde-salen.md) y [04](../1-teoria/04-proteger-enmascarar-ocultar.md) leídas

---

## Contexto

Esta práctica no fusiona nada. La rama `sonda-variables` vive sin merge request para que `POST .../pipeline` pueda lanzar pipelines de rama sobre ella (con merge request abierta, `workflow:rules` no lo permitiría), y se borra al final.

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | El inventario de lo que hay hoy | — |
| 2 | La sonda, con el valor del YAML | — |
| 3 | La precedencia, vista en tres pipelines | — |
| 4 | Variables de pipeline solo para Maintainer, comprobado con `dev` | `variables-de-pipeline-restringidas` |
| 5 | Nada de la sonda queda en `app` | `secretos-enmascarados` |

---

## Paso 0: Preparar el terreno

```bash
source ~/.bc-gitlab && source ~/.bc-gitlab-s10
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
export HA="PRIVATE-TOKEN: ${GITLAB_ADMIN_TOKEN:-$GITLAB_TOKEN}"
[ -n "${HR:-}" ] || echo "Falta \$HR: repite el paso 0 de la práctica 01"
```

---

## Paso 1: Qué hay hoy

**Por qué**: antes de añadir variables, sabe cuáles existen ya y en qué sitio. Solo nombres: nunca valores.

```bash
echo "== proyecto"; curl -s -H "$H" "$API/projects/$P/variables" \
  | jq -r '.[] | "\(.key) scope=\(.environment_scope) protected=\(.protected) masked=\(.masked) hidden=\(.hidden)"'
echo "== instancia"; curl -s -H "$HA" "$API/admin/ci/variables" | jq -r '.[].key'
for g in $(curl -s -H "$H" "$API/projects/$P" | jq -r '.namespace.full_path' | awk -F/ '{p=""; for(i=1;i<=NF;i++){p=(p?p"/":"")$i; print p}}'); do
  echo "== grupo $g"; curl -s -H "$H" "$API/groups/$(printf '%s' "$g" | jq -sRr @uri)/variables" | jq -r 'if type == "array" then .[].key else "(\(.message))" end'
done
echo "== rol mínimo para variables de pipeline"
curl -s -H "$H" "$API/projects/$P" | jq -r .ci_pipeline_variables_minimum_override_role
```

**Verifica**:

```
== proyecto
GOBERNANZA_TOKEN scope=* protected=false masked=true hidden=true
== instancia
CI_API_V4_URL
CI_SERVER_URL
== grupo plataforma-<dominio>
== grupo plataforma-<dominio>/app        (si `app` vive en un subgrupo)
== rol mínimo para variables de pipeline
developer
```

`developer` es el valor con el que 19.2.4 crea los proyectos: cualquier Developer de `app` puede lanzar, en las ramas donde puede ejecutar pipelines, un pipeline con variables que ganan a todas las demás.

---

## Paso 2: La sonda

**Por qué**: una variable que se llama igual en varios sitios, y un job que dice qué valor recibió. Es la única forma de saber la precedencia sin fiarse de la documentación.

```bash
git switch main && git pull --ff-only
git switch -c sonda-variables

cat >> .gitlab-ci.yml <<'EOF'

sonda:
  stage: build
  image: alpine:3.24.2
  rules:
    - if: $CI_COMMIT_BRANCH == "sonda-variables"
  variables:
    ORIGEN: yaml-job
  script:
    - echo "ORIGEN=$ORIGEN ref_protegida=$CI_COMMIT_REF_PROTECTED fuente=$CI_PIPELINE_SOURCE"
EOF
sed -i 's/^  GIT_LFS_SKIP_SMUDGE: "1".*/&\n  ORIGEN: yaml-global/' .gitlab-ci.yml
grep -n "ORIGEN" .gitlab-ci.yml

git commit -S -am "test: sonda de variables, no fusionar"
git push -u origin HEAD
```

La sonda va en el stage `build`, no en `.pre`: un pipeline cuyos únicos jobs están en `.pre` o `.post` se considera vacío y no se crea (`The resulting pipeline would have been empty`).

Una función para lanzar un pipeline de la rama y leer lo que dijo la sonda:

```bash
sonda() {   # $1: JSON extra para POST .../pipeline, opcional
  local EXTRA=${1:-'{}'} PIPE JOB
  PIPE=$(curl -s --request POST "$API/projects/$P/pipeline" -H "${2:-$H}" -H "Content-Type: application/json" \
    -d "$(jq -nc --argjson extra "$EXTRA" '{ref: "sonda-variables"} + $extra')" | jq -rc '.id // .message')
  [[ "$PIPE" =~ ^[0-9]+$ ]] || { echo "sin pipeline: $PIPE"; return 1; }
  JOB=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | select(.name == "sonda") | .id')
  until curl -s -H "$H" "$API/projects/$P/jobs/$JOB" | jq -e '.status | IN("success","failed")' > /dev/null; do sleep 5; done
  curl -s -H "$H" "$API/projects/$P/jobs/$JOB/trace" | sed 's/\x1b\[[0-9;]*m//g' | grep -v '\$ ' | grep -o 'ORIGEN=.*'
}
sonda
```

**Verifica**: `ORIGEN=yaml-job ref_protegida=false fuente=api`. La variable del job gana a la global del YAML. El push también creó un pipeline (`fuente=push`) con `build` y `test`: déjalo terminar, no estorba.

---

## Paso 3: La precedencia, en tres pipelines

**Por qué**: es la tabla de la teoría 03, vista en tu instancia. Y una sorpresa que la tabla no cuenta.

**3a.** Una variable de proyecto con el mismo nombre. No es un secreto: es una prueba, y la borras en el paso 5.

```bash
curl -s --request POST "$API/projects/$P/variables" -H "$H" \
  --data "key=ORIGEN" --data "value=proyecto" --data "protected=false" | jq -c '{key, protected}'
sonda
```

**Verifica**: `ORIGEN=proyecto`. El proyecto gana al YAML, y el YAML no dice nada.

**3b.** Ahora protégela, como harías con un secreto:

```bash
curl -s --request PUT "$API/projects/$P/variables/ORIGEN" -H "$H" --data "protected=true" | jq -c '{key, protected}'
sonda
```

**Verifica**: `ORIGEN=yaml-job`. La rama `sonda-variables` no es protegida, la variable del proyecto no llega, y el job usa **en silencio** el valor del YAML. Ningún aviso, ningún error.

Piensa qué significa con un secreto: si el YAML tuviera un valor por defecto para `DEPLOY_TOKEN` "para pruebas", un job fuera de `main` desplegaría con él sin quejarse. Por eso `scripts/deploy.sh` (práctica 03) empieza con `: "${DEPLOY_TOKEN:?...}"` y el YAML de `app` no define nunca un secreto, ni de mentira.

**3c.** Y una variable al lanzar el pipeline:

```bash
sonda '{"variables": [{"key": "ORIGEN", "value": "pipeline"}]}'
```

**Verifica**: `ORIGEN=pipeline`. Quien lanza el pipeline gana a todo. Hoy, en `app`, eso es cualquier Developer en una rama sin proteger.

---

## Paso 4: Variables de pipeline, solo para Maintainer

**Por qué**: en `main` un Developer ya no puede lanzar pipelines: la protección de la Semana 07 exige poder fusionar. Lo compruebas primero. El rol mínimo es la segunda barrera, para el día en que un Developer pueda fusionar en alguna rama protegida: sin ella, podría lanzar allí un pipeline con `CI_DEBUG_TRACE=true` y la traza volcaría las variables protegidas no enmascaradas, incluidas las de tipo archivo (teoría 07). Lo compruebas como `dev-<dominio>`.

Un token para `dev`, que también usarás en las prácticas 03 y 04:

```bash
export DEV=dev-<tu-dominio>
export UID_DEV=$(curl -s -H "$H" "$API/users?username=$DEV" | jq -r '.[0].id // empty')
[[ "$UID_DEV" =~ ^[0-9]+$ ]] || { echo "Falta $DEV: NO sigas"; return 1 2>/dev/null || exit 1; }
T_DEV=$(curl -s --request POST "$API/users/$UID_DEV/personal_access_tokens" -H "$HA" \
  --data-urlencode "name=flujo-s10" --data-urlencode "scopes[]=api" \
  --data-urlencode "expires_at=$(date -d '+7 days' +%F)" | jq -r '.token')
[ -n "$T_DEV" ] && [ "$T_DEV" != null ] || { echo "No se creó el token: NO sigas"; return 1 2>/dev/null || exit 1; }
export HD="PRIVATE-TOKEN: $T_DEV"
grep -qs UID_DEV ~/.bc-gitlab-s10 || echo "export DEV=$DEV UID_DEV=$UID_DEV" >> ~/.bc-gitlab-s10
curl -s -H "$HD" "$API/projects/$P" | jq -r '.permissions.group_access.access_level // .permissions.project_access.access_level'   # 30
```

Antes de cambiar nada, `dev` intenta un pipeline en `main`, y después pasa una variable en la rama de la sonda:

```bash
curl -s --request POST "$API/projects/$P/pipeline" -H "$HD" -H "Content-Type: application/json" -d '{"ref": "main"}' | jq -c .message
# {"base":["You do not have sufficient permission to run a pipeline on 'main'. ..."]}
sonda '{"variables": [{"key": "ORIGEN", "value": "dev"}]}' "$HD"
```

**Verifica**: `ORIGEN=dev`. Sube el rol mínimo:

```bash
curl -s --request PUT "$API/projects/$P" -H "$H" \
  --data "ci_pipeline_variables_minimum_override_role=maintainer" \
  | jq '{ci_pipeline_variables_minimum_override_role, restrict_user_defined_variables}'
sonda '{"variables": [{"key": "ORIGEN", "value": "dev"}]}' "$HD"
sonda '{}' "$HD"
sonda '{"variables": [{"key": "ORIGEN", "value": "maintainer"}]}'
```

**Verifica**, en este orden:

```
{ "ci_pipeline_variables_minimum_override_role": "maintainer", "restrict_user_defined_variables": true }
sin pipeline: {"base":["Insufficient permissions to set pipeline variables"]}
ORIGEN=yaml-job ref_protegida=false fuente=api
ORIGEN=maintainer ref_protegida=false fuente=api
```

`dev` sigue pudiendo lanzar pipelines, pero ya no puede pasarles variables. Lo que escriba en el YAML de su rama sigue siendo suyo: por eso importa que las protegidas no lleguen allí. Tú, sí puedes pasarlas.

---

## Paso 5: Recoger

**Por qué**: `ORIGEN` era una prueba. Si se queda, `secretos-enmascarados` falla (no está enmascarada), y es una variable de proyecto que no es un secreto: el tipo de cosa que la teoría 03 dice que va al YAML.

```bash
curl -s -o /dev/null -w 'ORIGEN borrada: %{http_code}\n' --request DELETE "$API/projects/$P/variables/ORIGEN" -H "$H"
for id in $(curl -s -H "$H" "$API/projects/$P/pipelines?ref=sonda-variables&per_page=100" \
              | jq -r '.[] | select(.status | IN("created","pending","running")) | .id'); do
  curl -s --request POST "$API/projects/$P/pipelines/$id/cancel" -H "$H" -o /dev/null
done
git switch main
git push origin --delete sonda-variables
git branch -D sonda-variables
curl -s -H "$H" "$API/projects/$P/variables" | jq -r '.[].key'          # GOBERNANZA_TOKEN
```

---

## ✅ Resultado

- [ ] El inventario de variables del proyecto, la instancia y los grupos, sin un solo valor
- [ ] La precedencia comprobada: job del YAML sobre global, proyecto sobre YAML, pipeline sobre proyecto
- [ ] Visto que una variable protegida que no llega deja paso al valor del YAML sin avisar
- [ ] `ci_pipeline_variables_minimum_override_role` en `maintainer`, comprobado con el `400` de `dev`
- [ ] Token de `dev` creado sin guardarlo
- [ ] `ORIGEN` borrada y la rama `sonda-variables` eliminada

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `sin pipeline: ... Review the workflow:rules` | Hay una merge request abierta desde `sonda-variables` | Ciérrala: esta rama vive sin merge request |
| `sin pipeline: ... would have been empty` | La sonda está en `.pre`, o su regla no coincide con el nombre de la rama | `stage: build` y el nombre exacto de la rama |
| `sonda` se queda esperando para siempre | El job no existe en ese pipeline: no hay `JOB` | `GET .../pipelines/<id>/jobs` y revisa la regla |
| El push de la rama falla con `no está firmado` | Tu clon no firma | `git commit --amend -S --no-edit` y repite el push |
| `GET .../groups/.../variables` devuelve `403` | No eres Owner de ese grupo | Normal en los subgrupos donde no lo eres: anótalo y sigue |
| `dev` recibe `403` al lanzar el pipeline | `dev` no es Developer en `app` | Revisa sus permisos (Semana 03) |

---

## 🔗 Navegación

[← Anterior: Las reglas de `app`](01-las-reglas-de-app.md) · [Volver a la Semana 10](../README.md) · [Siguiente: Secretos por entorno →](03-secretos-por-entorno.md)

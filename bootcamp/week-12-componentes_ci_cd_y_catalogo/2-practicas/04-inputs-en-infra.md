# Práctica 04 — Inputs en `infra`

> `infra/entornos` declara qué espera: un `entorno`, con dos valores posibles. Primero lo declaras mal, sin `default`, y ves cómo un simple push crea un pipeline fallido. Después lo arreglas, `app` pasa el entorno como input, y compruebas qué rechaza GitLab antes de que exista ningún pipeline. Las tres variables de la Semana 11 se quedan: son datos que solo existen al ejecutar.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 03 completada · Teoría [07](../1-teoria/07-inputs-de-pipeline.md) leída

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | El inventario de lo que viaja de `app` a `infra/entornos` | — |
| 2 | `entorno` sin `default`, y el pipeline fallido que provoca | — |
| 3 | `entorno` con `default: staging`, usado en el nombre y en el registro | `infra-declara-entorno` |
| 4 | El disparo de `app` con `trigger:inputs`, fusionado y en verde | `app-dispara-con-inputs`, `infra-sabe-su-entorno` |
| 5 | Lo que GitLab rechaza antes de crear el pipeline | — |

Si has cerrado la terminal, repite el paso 0 de la práctica 01 y `source ~/.bc-gitlab-s12`.

---

## Paso 1: Lo que viaja hoy

**Por qué**: antes de cambiar variables por inputs, la lista de lo que viaja y **cuándo se conoce** cada dato. Decide qué puede ser input y qué no (teoría 07, apartado 2.5).

```bash
curl -s -H "$H" "$API/projects/$P/ci/lint?include_merged_yaml=true" \
  | jq -r .merged_yaml | awk '/^infra:/{f=1; print; next} /^[^ ]/{f=0} f' | grep -A4 'variables:'
curl -s -H "$H" "$API/projects/$PI" | jq -r .ci_pipeline_variables_minimum_override_role
```

**Verifica**: `APP_SHA`, `APP_PROJECT_ID` y `APP_PACKAGE_JOB_ID`, y `maintainer`. Anota al lado de cada una cuándo existe su valor:

| Variable | Su valor existe | ¿Input? |
|---|---|:--:|
| `APP_SHA` | Cuando el job `infra` se ejecuta en `app` | ❌ |
| `APP_PROJECT_ID` | Ídem | ❌ |
| `APP_PACKAGE_JOB_ID` | Cuando termina `package`, por `dotenv` | ❌ |
| El entorno | Al escribir el YAML de `app` | ✅ |

Ninguna de las tres puede ser un input: `trigger:inputs` no expande variables y llegarían como texto. La restricción `maintainer` de `infra/entornos` se queda donde está.

---

## Paso 2: Un input obligatorio, a propósito

**Por qué**: la documentación dice "siempre con `default`". Lo ves en lugar de creerlo: un input sin `default` se valida antes que `workflow`, y el push que antes no creaba nada ahora crea un pipeline roto (teoría 07, apartado 2.2).

```bash
cd /ruta/a/tus/clones/entornos && git switch main && git pull --ff-only
```

Al **principio** de `.gitlab-ci.yml`, antes de todo lo demás:

```yaml
spec:
  inputs:
    entorno:
      description: Entorno al que va la versión de app
      options: [staging, production]
---
```

```bash
git add .gitlab-ci.yml
git commit -S -m "ci: declarar el entorno como input de pipeline"
git push origin main
sleep 15
curl -s -H "$H" "$API/projects/$PI/pipelines?source=push&per_page=1" | jq -c '.[0] | {id, iid, status}'
```

**Verifica**: un pipeline de `push` en `failed`, sin ningún job. El motivo, por GraphQL:

```bash
IIDP=$(curl -s -H "$H" "$API/projects/$PI/pipelines?source=push&per_page=1" | jq -r '.[0].iid')
jq -n --arg p "$GRUPO/infra/entornos" --arg i "$IIDP" \
  '{query: "query($p: ID!, $i: ID!) { project(fullPath: $p) { pipeline(iid: $i) { errorMessages { nodes { content } } } } }",
    variables: {p: $p, i: $i}}' \
  | curl -s "$GITLAB_URL/api/graphql" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -r '.data.project.pipeline.errorMessages.nodes[].content'
# `.gitlab-ci.yml`: `entorno` input: required value has not been provided
```

El `workflow` de la Semana 11 solo acepta `pipeline`, y no ha servido de nada: los inputs se comprobaron antes.

---

## Paso 3: `default`, y el entorno en uso

**Por qué**: el valor por defecto es el que se usa cuando nadie dice nada. Tiene que ser el menos peligroso.

Añade `default: staging` al input, y usa el entorno en el nombre del pipeline y en el job:

```yaml
spec:
  inputs:
    entorno:
      description: Entorno al que va la versión de app
      options: [staging, production]
      default: staging
---
# Este proyecto no se construye a sí mismo: lo dispara main de app.
workflow:
  name: "app $APP_SHA → $[[ inputs.entorno ]]"
  rules:
    - if: $CI_PIPELINE_SOURCE == "pipeline"

registrar:
  image: alpine:3.24.2
  variables:
    ENTORNO: $[[ inputs.entorno ]]
  # … before_script, script y artifacts sin cambios
```

`ENTORNO` es una variable **del job**, con el valor que el input tuvo al crear el pipeline. El script la lee como cualquier otra. En `scripts/registrar.sh`, una línea entre las comprobaciones y una en el registro:

```bash
sed -i 's|^: "${APP_PACKAGE_JOB_ID:?Falta APP_PACKAGE_JOB_ID}"$|&\n: "${ENTORNO:?Falta ENTORNO}"|' scripts/registrar.sh
sed -i 's|^  echo "app_sha=$APP_SHA"$|&\n  echo "entorno=$ENTORNO"|' scripts/registrar.sh
grep -n 'ENTORNO' scripts/registrar.sh

jq -n --rawfile c .gitlab-ci.yml '{content: $c}' \
  | curl -s --request POST "$API/projects/$PI/ci/lint" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -c '{valid, errors}'
git add .gitlab-ci.yml scripts/registrar.sh
git commit -S -m "ci: staging por defecto y el entorno en el registro"
git push origin main
sleep 15
curl -s -H "$H" "$API/projects/$PI/pipelines?source=push&per_page=1" | jq -r '.[0].sha[0:8]'
git rev-parse --short=8 HEAD~1
```

**Verifica**: tres líneas con `ENTORNO`, `{"valid":true,"errors":[]}`, y el último pipeline de `push` es del commit **anterior** (el del paso 2): este push no ha creado ninguno. Con `default`, el input ya no impide que `workflow` haga su trabajo.

---

## Paso 4: `app` dispara con el entorno

**Por qué**: hasta hoy, `infra/entornos` sabía **qué** versión llegaba; ahora sabe también **adónde**, y con un valor que no puede venir mal escrito.

```bash
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Pasar el entorno a infra/entornos como input" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=trigger:inputs entorno: staging. APP_SHA, APP_PROJECT_ID y APP_PACKAGE_JOB_ID siguen como variables: se conocen al ejecutar. Ver Semana 12." \
  | jq -r .iid)
git switch -c "$IID-entorno-como-input"
```

En `ci/deploy.yml`, el bloque `trigger` de `infra` gana `inputs`:

```yaml
  trigger:
    project: plataforma-<tu-dominio>/infra/entornos
    branch: main
    strategy: mirror
    inputs:
      entorno: staging
```

`variables` no se toca. Si te tienta poner ahí también `app_sha: $CI_COMMIT_SHA`, relee el paso 1.

```bash
git add ci/deploy.yml
git commit -S -m "ci: pasar el entorno a infra/entornos como input"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="ci: pasar el entorno a infra/entornos como input" \
  -o merge_request.description="Closes #$IID"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
fusionar "$P" "$MR"
git switch main && git pull --ff-only
PIPE=$(curl -s -H "$H" "$API/projects/$P/pipelines?ref=main&source=push&per_page=1" | jq -r '.[0].id')
esperar "$P" "$PIPE"
```

**Verifica**: `state: merged` y `success`. Y abajo:

```bash
curl -s -H "$H" "$API/projects/$PI/pipelines?source=pipeline&per_page=1" | jq -r '.[0] | "\(.status) \(.name)"'
git -C /ruta/a/tu/clon/de/app rev-parse HEAD
```

`success app <SHA> → staging`, con el mismo SHA que `main` de `app`: `APP_SHA` llegó expandido arriba, como variable; `entorno`, como input. El artefacto `registro.txt` del job `registrar` tiene ahora una línea `entorno=staging`.

---

## Paso 5: Lo que se rechaza antes de existir

**Por qué**: la validación de un input ocurre al crear el pipeline, antes de `workflow` y antes de cualquier job. Lánzalo por API para ver el orden.

```bash
for e in desarrollo production; do
  curl -s --request POST "$API/projects/$PI/pipeline" -H "$H" -H "Content-Type: application/json" \
    -d "{\"ref\": \"main\", \"inputs\": {\"entorno\": \"$e\"}}" | jq -r '.message.base[0]'
done
```

**Verifica**:

```text
`.gitlab-ci.yml`: `entorno` input: `desarrollo` cannot be used because it is not in the list of allowed options
The pipeline did not run. Review the workflow:rules configuration for the pipeline.
```

`desarrollo` no pasa de los inputs. `production` sí pasa, y lo para el `workflow`: lanzado por API, el origen es `api`, no `pipeline`. Dos barreras, en ese orden. Ninguna de las dos depende del rol de quien lanza el pipeline.

Abre `Build → Pipelines → Run pipeline` en `infra/entornos`: el formulario muestra `entorno` como un desplegable con `staging` seleccionado y la descripción debajo. Es la documentación más corta de lo que este pipeline acepta. No lo lances: el `workflow` lo rechazaría igual.

---

## ✅ Resultado

- [ ] Viste un push a `infra/entornos` crear un pipeline fallido por un input sin `default`
- [ ] `entorno` con `options` y `default: staging`, en el nombre del pipeline y en `registro.txt`
- [ ] `app` pasa `entorno: staging` con `trigger:inputs` y las tres variables de siempre
- [ ] El último pipeline multiproyecto de `infra/entornos` en verde, con `→ staging` en el nombre
- [ ] `infra/entornos` sigue en `maintainer` y sabes por qué

```bash
./scripts/verificar-semana.sh 12
```

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| El push del paso 3 vuelve a crear un pipeline fallido | Falta `default`, o está fuera de `spec` | `default: staging` dentro de `entorno` |
| `infra` falla en `app`: ``Given inputs not defined in the `spec` section`` | `infra/entornos` no tiene `spec:inputs` en `main` | Paso 3, empujado |
| `registrar` falla: `ENTORNO: Falta ENTORNO` | La variable del job no está, o el `sed` no encontró la línea | `variables: ENTORNO: $[[ inputs.entorno ]]` en `registrar` |
| `infra` falla en `app`: `Insufficient permissions to set pipeline variables` | Bajaste `infra/entornos` a `no_one_allowed` | `maintainer`: las variables siguen viajando |
| `infra-sabe-su-entorno` en rojo con el pipeline en verde | El último multiproyecto es anterior al paso 4 | Un pipeline nuevo de `main` en `app` |

---

## 🔗 Navegación

[← Anterior: Publicar y consumir](03-publicar-y-consumir.md) · [Volver a la Semana 12](../README.md)

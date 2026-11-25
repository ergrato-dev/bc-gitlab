# Práctica 03 — `app` detrás de los cuatro

> Con `1.3.0` publicada, poner a `app` detrás de los cuatro escáneres son diez líneas de `include`. La merge request que las añade es la primera que los sufre: Trivy encuentra en la imagen de la Semana 13 lo que ya viste en tu terminal, la puerta se cierra y la API responde `405`. La arreglas en la misma merge request, con dos líneas en el `Dockerfile`, y `main` no llega a ponerse en rojo.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 02 completada (`1.3.0` en el catálogo) · La lista de hallazgos de Trivy de la práctica 01, paso 3 · Teoría [05](../1-teoria/05-imagenes-con-trivy.md) y [06](../1-teoria/06-informes-umbrales-y-la-puerta.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | La puerta de la Semana 09, comprobada | `fusion-exige-pipeline` |
| 2 | `app` consumiendo `seguridad@1` | `app-usa-seguridad`, `cuatro-escaneres-bloquean` |
| 3 | La merge request en rojo y la fusión rechazada | `los-cuatro-han-parado-algo` (Trivy) |
| 4 | El `Dockerfile` corregido | `imagen-base-corregida` |
| 5 | La merge request fusionada | — |
| 6 | `main` escaneada, con sus cuatro informes | `main-escaneada`, `informes-junit` |

Si has cerrado la terminal, repite el paso 0 de la práctica 01 y pega `esperar` y `fusionar`.

---

## Paso 1: La puerta

**Por qué**: un escáner que falla solo para la fusión si `app` exige el pipeline en verde (teoría 06, apartado 2.4). Lo activaste en la Semana 09; esta semana depende de que siga así.

**Con la UI**: `Settings → Merge requests → Merge checks`: *Pipelines must succeed* marcado y *Skipped pipelines are considered successful* sin marcar.

**Con la API**:

```bash
curl -s -H "$H" "$API/projects/$P" | jq -c '{only_allow_merge_if_pipeline_succeeds, allow_merge_on_skipped_pipeline}'
```

**Verifica**: `{"only_allow_merge_if_pipeline_succeeds":true,"allow_merge_on_skipped_pipeline":false}`. Si no, vuelve a aplicarlo como en el [paso de la Semana 09](../../week-09-ci_cd_fundamentos/2-practicas/04-la-gobernanza-como-job.md):

```bash
curl -s --request PUT "$API/projects/$P" -H "$H" \
  --data "only_allow_merge_if_pipeline_succeeds=true" --data "allow_merge_on_skipped_pipeline=false" \
  | jq -c '{only_allow_merge_if_pipeline_succeeds, allow_merge_on_skipped_pipeline}'
```

---

## Paso 2: El `include`

**Por qué**: tres cambios en `.gitlab-ci.yml`. El stage `seguridad`, al final. `tar: true` en `imagen`, para que Trivy tenga qué leer. Y unas `rutas` explícitas, las mismas en los dos componentes, que **añaden** `.gitlab-ci.yml` a las de por defecto: un cambio en el pipeline cambia cómo se construye y cómo se escanea la imagen, así que esa MR tiene que construirla y escanearla. Sin esa ruta, esta misma merge request no ejecutaría Trivy, y el primer escaneo de la imagen sería el de `main`, ya fusionado.

```bash
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Escanear app con el componente seguridad" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=seguridad@1 de ci/componentes: Semgrep, Gitleaks, OSV-Scanner y Trivy, umbral alta. Ver Semana 19." \
  | jq -r .iid)
echo "export IID_S19=$IID" >> ~/.bc-gitlab-s19
git switch -c "$IID-escaneres"
grep -n 'stages:\|imagen@1' .gitlab-ci.yml
```

En `.gitlab-ci.yml`, `seguridad` al final de `stages` (el tuyo puede tener más, como `deploy`: `seguridad` va **antes** de `deploy`, para que no se despliegue lo que no ha pasado los escáneres):

```yaml
stages: [build, test, package, seguridad, deploy]
```

y el `include` de `imagen`, con el de `seguridad` debajo:

```yaml
  - component: $CI_SERVER_FQDN/plataforma-<tu-dominio>/ci/componentes/imagen@1
    inputs:
      needs: [build, test]
      registro: gitlab:5050      # solo laboratorio: el registry visto desde la red del compose
      inseguro: true             # solo laboratorio: HTTP
      tar: true
      rutas: &rutas-imagen [Dockerfile, .dockerignore, package.json, src/**/*, .gitlab-ci.yml]
  - component: $CI_SERVER_FQDN/plataforma-<tu-dominio>/ci/componentes/seguridad@1
    inputs:
      rutas_imagen: *rutas-imagen
```

El ancla de YAML (`&rutas-imagen`, `*rutas-imagen`) escribe la lista una vez: si mañana cambia, cambia en los dos sitios. Funciona dentro de un mismo archivo, que es el caso.

Si tus jobs de despliegue (Semana 14) tienen `needs`, añade `trivy` a los de producción: `needs` manda sobre el orden de los stages, y un job con `needs: [imagen]` no esperaría a los escáneres.

```bash
git add .gitlab-ci.yml
git commit -S -m "ci: escanear app con el componente seguridad"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="ci: escanear app con el componente seguridad" \
  -o merge_request.description="Closes #$IID"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
echo "export MR_S19=$MR" >> ~/.bc-gitlab-s19
curl -s -H "$H" "$API/projects/$P/ci/lint?content_ref=$(git branch --show-current)&include_jobs=true" \
  | jq -r '.valid, (.jobs[] | select(.stage == "seguridad") | "\(.name)\tallow_failure=\(.allow_failure)")'
```

**Verifica**: `true`, y los cuatro escáneres en `seguridad` con `allow_failure=false`. Si `valid` es `false`, `.errors` dice qué línea.

---

## Paso 3: La puerta, cerrada

**Por qué**: es la primera vez que la imagen de `app` pasa por Trivy en un pipeline. Ya sabes qué va a encontrar (práctica 01, paso 3); lo que vas a ver es dónde lo ve el revisor y qué pasa al intentar fusionar.

```bash
sleep 10
PIPE=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .head_pipeline.id)
esperar "$P" "$PIPE"
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r 'sort_by(.id) | .[] | "\(.stage)\t\(.name)\t\(.status)"'
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/test_report_summary" \
  | jq -r '.test_suites[] | "\(.name)\t\(.total_count) casos\t\(.failed_count) fallos"'
```

**Verifica**: `failed`. `imagen` en `success` (esta vez sí construyó: `.gitlab-ci.yml` está en sus rutas), `semgrep`, `gitleaks` y `osv-scanner` en `success`, y `trivy` en `failed` con unos trece fallos.

Ahora como lo ve el revisor. **Con la UI**: abre la merge request. Bajo el pipeline, *Test summary: N failed*; despliega `trivy` y verás cada CVE con su paquete. Y el botón *Merge* no está: en su lugar, *Merge blocked: pipeline must succeed*.

**Con la API**:

```bash
curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .detailed_merge_status
SHA=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .sha)
curl -s --request PUT "$API/projects/$P/merge_requests/$MR/merge" -H "$H" --data-urlencode "sha=$SHA" -w '  HTTP %{http_code}\n'
```

**Verifica**: `ci_must_pass` y `{"message":"405 Method Not Allowed"}  HTTP 405`. Eres `root` y no puedes fusionar: la puerta no distingue roles.

---

## Paso 4: El `Dockerfile`

**Por qué**: dos arreglos distintos para dos orígenes distintos (teoría 05, apartado 2.1). Las CVE de Alpine se arreglan con la base: `node:22.23.4-alpine3.24` (2026-11-05) trae Alpine 3.24.4; la última, `22.23.5`, no se fija. Las de Node.js no se arreglan subiendo: están en el `npm` que trae la imagen y que `app` no usa al ejecutarse, así que se quita.

```bash
sed -i 's/^FROM node:22.23.3-alpine3.24$/FROM node:22.23.4-alpine3.24/' Dockerfile
sed -i '/^FROM node:/a # npm, npx, corepack y yarn no hacen falta para ejecutar app, y traen sus propias CVE. Ver Semana 19.\nRUN rm -rf /usr/local/lib/node_modules /opt/yarn-* /usr/local/bin/npm /usr/local/bin/npx \\\n           /usr/local/bin/corepack /usr/local/bin/yarn /usr/local/bin/yarnpkg' Dockerfile
head -5 Dockerfile
```

**Verifica**:

```text
# Imagen de app. Sin RUN: app no tiene dependencias en ejecución. Ver Semana 13, teoría 02.
FROM node:22.23.4-alpine3.24
# npm, npx, corepack y yarn no hacen falta para ejecutar app, y traen sus propias CVE. Ver Semana 19.
RUN rm -rf /usr/local/lib/node_modules /opt/yarn-* /usr/local/bin/npm /usr/local/bin/npx \
           /usr/local/bin/corepack /usr/local/bin/yarn /usr/local/bin/yarnpkg
```

El comentario de la primera línea ya no es verdad: corrígelo a `Sin dependencias en ejecución; el único RUN quita lo que sobra de la base.` Un comentario que miente es peor que ninguno.

Antes de empujar, la misma prueba que hará el pipeline, en tu terminal (práctica 01, paso 3): que la imagen arranca y que Trivy no encuentra nada alto.

```bash
docker build -q -t app-s19 . && docker run --rm app-s19
docker save app-s19 -o ~/bc-s19/app.tar
docker run --rm -v ~/bc-s19:/w -w /w -v ~/bc-s19/trivy-cache:/cache "$I_TRIVY" \
  image --input app.tar --cache-dir /cache --severity HIGH,CRITICAL --exit-code 1 -q --format table
echo "salida: $?"
```

**Verifica**: los módulos de `src/` con sus funciones, como en la Semana 13: la imagen arranca sin `npm`. Después, el `Report Summary` de Trivy con `0` en la fila de Alpine y en la de `app/package.json`, y `salida: 0`.

---

## Paso 5: La merge request, en verde

```bash
git commit -S -am "fix: imagen de app sin CVE altas: base 22.23.4 y sin npm"
git push
sleep 10
PIPE=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .head_pipeline.id)
esperar "$P" "$PIPE"
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/test_report_summary" \
  | jq -r '.test_suites[] | "\(.name)\t\(.failed_count) fallos"'
fusionar "$P" "$MR"
```

**Verifica**: `success`, `0 fallos` en las cuatro suites de los escáneres, y `state: merged`. En la UI, el *Test summary* de la merge request dice ahora que los fallos de `trivy` están resueltos (*resolved*) frente al pipeline anterior.

`fusionar` relanza el pipeline después de la aprobación de `revisor` (Semana 13): la MR toca el `Dockerfile`, que es de `revisor` en tu `CODEOWNERS`, y `gobernanza` lo comprueba.

---

## Paso 6: `main`, escaneada

**Por qué**: en `main`, `imagen` sube la imagen **y** deja el tarball, y Trivy escanea exactamente lo que se acaba de subir. Es el pipeline que comprueban los checks.

```bash
git switch main && git pull --ff-only
PIPE=$(curl -s -H "$H" "$API/projects/$P/pipelines?ref=main&source=push&per_page=1" | jq -r '.[0].id')
esperar "$P" "$PIPE"
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" \
  | jq -r 'sort_by(.id) | .[] | select(.stage=="seguridad" or .name=="imagen") | "\(.name)\t\(.status)\t\(.duration | floor)s"'
J=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | select(.name=="trivy") | .id')
curl -s -H "$H" "$API/projects/$P/jobs/$J/artifacts/trivy.sarif" | jq '[.runs[].results[]] | length'
```

**Verifica**: `success`; `imagen`, `semgrep`, `gitleaks`, `osv-scanner` y `trivy` en `success`, con sus duraciones (Trivy, la primera vez en `app`, puede tardar un par de minutos si la caché aún no la tenía); y una cifra en la última línea: los hallazgos `MEDIUM` y `LOW` que el SARIF guarda aunque no paren el pipeline. Esa cifra es la que ordena `docs/seguridad.md` en el proyecto de la semana.

---

## ✅ Resultado

- [ ] `app` con el stage `seguridad` antes de `deploy` y `seguridad@1` con las mismas rutas que `imagen`
- [ ] La merge request rechazada con `405` y `ci_must_pass` mientras Trivy estaba en rojo
- [ ] El `Dockerfile` sobre `node:22.23.4-alpine3.24`, sin `npm`, y su comentario corregido
- [ ] El último pipeline de `main` en verde con los cuatro escáneres y sus cuatro informes

```bash
./scripts/verificar-semana.sh 19
```

Pasan además `app-usa-seguridad`, `cuatro-escaneres-bloquean`, `main-escaneada`, `informes-junit`, `imagen-base-corregida` y `fusion-exige-pipeline`. `los-cuatro-han-parado-algo` sigue en rojo hasta la práctica 04: de momento solo ha fallado Trivy.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| En la MR no aparece `trivy` | `.gitlab-ci.yml` no está en las rutas de `imagen` y `seguridad` | Paso 2: el ancla en los dos `include` |
| `'trivy' job needs 'imagen' job, but 'imagen' does not exist` | Las rutas de los dos `include` no coinciden | El ancla |
| `trivy`: `open imagen.tar: no such file or directory` | Falta `tar: true`, o `app` resolvió `imagen@1` a `1.2.0` | `tar: true`, y `1.3.0` publicada (práctica 02, paso 6) |
| La MR se fusiona con `trivy` en rojo | La puerta no está cerrada, o un job lleva `allow_failure` | Paso 1, y el `ci/lint` del paso 2 |
| `docker run app-s19` falla tras quitar `npm` | El `CMD` llama a `npm` | El `CMD` de la Semana 13 llama a `node`: vuelve a él |
| `fusionar`: `gobernanza no está en verde` | Falta la aprobación de `revisor` como dueño del `Dockerfile` | `T_REV` caducado o no creado: paso 0 de la práctica 01 |

---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| [Práctica 02 — El componente `seguridad`](02-el-componente-seguridad.md) | [Práctica 04 — La merge request envenenada](04-la-merge-request-envenenada.md) |

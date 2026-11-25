# Práctica 02 — El componente `seguridad`

> Lo que en la práctica 01 eran cuatro `docker run`, ahora son cuatro jobs que cualquier proyecto del grupo puede usar con una línea de `include`. El componente lleva las imágenes por digest, las reglas de la plataforma dentro y un umbral como input. Y como todo componente, se prueba a sí mismo antes de publicarse: la primera vez que se ejecuta, tumba la imagen de prueba del propio `ci/componentes`.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 01 completada (la rama `<iid>-componente-seguridad` con `tests/seguridad/` sin commit) · Teoría [05](../1-teoria/05-imagenes-con-trivy.md) y [06](../1-teoria/06-informes-umbrales-y-la-puerta.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | `imagen` con el input `tar` | `imagen-guarda-tar` |
| 2 | `templates/seguridad.yml` | `componente-seguridad`, `escaneres-por-digest`, `reglas-propias` |
| 3 | `ci/componentes` probando `seguridad` y sus reglas | — |
| 4 | La merge request: el primer hallazgo es tuyo | — |
| 5 | La imagen de prueba arreglada y `main` en verde | `componentes-sigue-en-verde` |
| 6 | `1.3.0` en el catálogo | `seguridad-publicada` |

Si has cerrado la terminal, repite el paso 0 de la práctica 01 (el bloque entero: crea otro token de `revisor`) y pega `esperar` y `fusionar`.

---

## Paso 1: `imagen` aprende a guardar lo que construye

**Por qué**: Trivy tiene que escanear **la misma** imagen que se sube, también en una merge request, donde `imagen` no sube nada (teoría 05, apartado 2.3). Kaniko la puede escribir como tarball a la vez que la sube. Es un input nuevo con `false` por defecto: quien ya usa `imagen@1` no nota nada, y por eso es una versión *minor*.

```bash
cd /ruta/a/tus/clones/componentes && git switch "$IIDC-componente-seguridad"
git apply <<'EOF'
--- a/templates/imagen.yml
+++ b/templates/imagen.yml
@@ -27,6 +27,10 @@ spec:
       description: Registry por HTTP, sin TLS. Solo laboratorio
       type: boolean
       default: false
+    tar:
+      description: Guardar la imagen como imagen.tar, un artefacto de una hora, para escanearla en el mismo pipeline
+      type: boolean
+      default: false
 ---
 imagen:
   stage: $[[ inputs.stage ]]
@@ -45,10 +49,15 @@ imagen:
   variables:
     NOMBRE: $[[ inputs.nombre ]]
     REGISTRO: $[[ inputs.registro ]]
+  artifacts:
+    paths: [imagen.tar]
+    expire_in: 1 hour
   script:
+    - TAR=""
+    - if [ "$[[ inputs.tar ]]" = true ]; then TAR="--tar-path imagen.tar"; fi
     - |
       if [ "$CI_PIPELINE_SOURCE" = merge_request_event ]; then
-        /kaniko/executor --context "$CI_PROJECT_DIR/$[[ inputs.contexto ]]" --dockerfile "$CI_PROJECT_DIR/$[[ inputs.contexto ]]/$[[ inputs.dockerfile ]]" --no-push
+        /kaniko/executor --context "$CI_PROJECT_DIR/$[[ inputs.contexto ]]" --dockerfile "$CI_PROJECT_DIR/$[[ inputs.contexto ]]/$[[ inputs.dockerfile ]]" --no-push ${TAR:+--destination imagen $TAR}
         exit 0
       fi
     - RUTA="${CI_REGISTRY_IMAGE#"$CI_REGISTRY"/}${NOMBRE:+/$NOMBRE}"
@@ -68,5 +77,6 @@ imagen:
       --label org.opencontainers.image.revision=$CI_COMMIT_SHA
       --label org.opencontainers.image.source=$CI_PROJECT_URL
       --digest-file imagen.digest
+      $TAR
       $([ "$[[ inputs.inseguro ]]" = true ] && echo --insecure)
     - echo "Subida $CI_REGISTRY/$RUTA@$(cat imagen.digest)"
EOF
git diff --stat
```

| Cambio | Por qué así |
|---|---|
| `--destination imagen` solo en la rama de MR | Kaniko exige un nombre para escribir el tarball, y en MR no hay destino real. En la rama de `main` el nombre lo dan los `--destination` de siempre |
| `artifacts` sin condición | Con `tar: false` no hay `imagen.tar`, y el runner escribe `no matching files` en el log, sin fallar el job. Es el precio de no duplicar el job |
| `expire_in: 1 hour` | El tarball solo sirve dentro del pipeline; la imagen que dura es la del registry |

**Verifica**: `templates/imagen.yml | 12 +++++++++++-` (11 líneas nuevas y 1 cambiada). Si `git apply` responde `patch does not apply`, tu `imagen.yml` no es el de la Semana 13: compáralo con el [paso 2 de su práctica 02](../../week-13-registry_de_contenedores_y_paquetes/2-practicas/02-el-componente-imagen.md#paso-2-templatesimagenyml).

---

## Paso 2: `templates/seguridad.yml`

**Por qué**: los cuatro escáneres de la práctica 01, con lo que cambia entre consumidores como input (teoría 06, apartado 2.3) y todo lo demás dentro. Las reglas de Semgrep se copian del archivo que probaste en la práctica 01: el componente se escribe en tres trozos para no teclearlas otra vez.

```bash
cat > templates/seguridad.yml <<'EOF'
spec:
  inputs:
    stage:
      description: Stage de los cuatro escáneres. Semgrep, Gitleaks y OSV-Scanner arrancan sin esperar (needs vacío)
      default: seguridad
    umbral:
      description: Severidad desde la que OSV-Scanner y Trivy hacen fallar el job
      options: [critica, alta, media]
      default: alta
    lockfile:
      description: Lockfile que lee OSV-Scanner, relativo a la raíz del repositorio
      default: package-lock.json
    imagen:
      description: Job que deja la imagen en imagen.tar (componente imagen con tar a true)
      default: imagen
    rutas_imagen:
      description: Las mismas rutas que el job de la imagen. Si cambian en una merge request, Trivy escanea
      type: array
      default: [Dockerfile, .dockerignore, package.json, src/**/*]
---
.componente-seguridad:
  stage: $[[ inputs.stage ]]
  needs: []
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: never
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_TAG
  variables:
    UMBRAL: $[[ inputs.umbral ]]
  before_script:
    - |
      case "$UMBRAL" in
        critica) SEVERIDADES=CRITICAL; CVSS_MIN=9.0 ;;
        alta)    SEVERIDADES=HIGH,CRITICAL; CVSS_MIN=7.0 ;;
        media)   SEVERIDADES=MEDIUM,HIGH,CRITICAL; CVSS_MIN=4.0 ;;
      esac

semgrep:
  extends: .componente-seguridad
  image: semgrep/semgrep:1.185.0@sha256:67518c174185a2043fdbed16c70631b79209499b3671178e7194379b48295a0d
  script:
    - |
      mkdir -p /plataforma && cat > /plataforma/semgrep.yml <<'REGLAS'
EOF
sed 's/^/      /' tests/seguridad/reglas.yaml >> templates/seguridad.yml
cat >> templates/seguridad.yml <<'EOF'
      REGLAS
    # La imagen da por hecho que el código está montado en /src; en un job está en $CI_PROJECT_DIR.
    - unset SEMGREP_IN_DOCKER
    - >-
      semgrep scan --config /plataforma/semgrep.yml --metrics=off --disable-version-check --error
      --junit-xml-output=semgrep.junit.xml --sarif-output=semgrep.sarif
  artifacts:
    when: always
    expire_in: 30 days
    paths: [semgrep.sarif]
    reports:
      junit: semgrep.junit.xml

gitleaks:
  extends: .componente-seguridad
  image:
    name: zricethezav/gitleaks:v8.30.0@sha256:691af3c7c5a48b16f187ce3446d5f194838f91238f27270ed36eef6359a574d9
    entrypoint: [""]
  variables:
    GIT_DEPTH: "0"
  script:
    - gitleaks git --redact --no-banner --exit-code 0 --report-format sarif --report-path gitleaks.sarif .
    - gitleaks git --redact --no-banner --report-format junit --report-path gitleaks.junit.xml .
  artifacts:
    when: always
    expire_in: 30 days
    paths: [gitleaks.sarif]
    reports:
      junit: gitleaks.junit.xml

osv-scanner:
  extends: .componente-seguridad
  image:
    name: ghcr.io/google/osv-scanner:v2.7.0@sha256:4f3b7e2c64b9d38a5febc5a7e4a3dfef1d1362f726dea7a2ef4762b46469fcd0
    entrypoint: [""]
  variables:
    LOCKFILE: $[[ inputs.lockfile ]]
  script:
    - |
      for formato in sarif markdown; do
        rc=0
        /osv-scanner scan source --lockfile "$LOCKFILE" --format $formato --output-file osv.$formato || rc=$?
        # 0: limpio · 1: hay vulnerabilidades · 128: el lockfile no tiene paquetes. Otro código es un error del escáner.
        case $rc in 0|1|128) ;; *) exit $rc ;; esac
      done
      touch osv.markdown
    - |
      # OSV-Scanner no escribe JUnit: cada fila de la tabla es un caso, y falla si su CVSS llega al umbral.
      awk -F' *\\| *' -v min="$CVSS_MIN" -v f="$LOCKFILE" '
        $2 ~ /^https:\/\/osv.dev\// {
          n++; id=$2; sub(/.*\//, "", id)
          bloquea = ($3 == "" || $3 + 0 >= min)
          caso = sprintf("<testcase classname=\"%s@%s\" name=\"[CVSS %s] %s\" file=\"%s\">", $5, $6, ($3 == "" ? "?" : $3), id, f)
          if (bloquea) { fallos++; caso = caso sprintf("<failure message=\"%s %s tiene %s; corregido en %s\">%s</failure>", $5, $6, id, $7, $2) }
          casos = casos caso "</testcase>\n"
        }
        END {
          printf "<testsuites><testsuite name=\"osv-scanner\" tests=\"%d\" failures=\"%d\">\n%s</testsuite></testsuites>\n", n, fallos, casos > "osv.junit.xml"
          printf "%d vulnerabilidades, %d desde CVSS %s\n", n, fallos, min
          exit (fallos > 0)
        }' osv.markdown
  artifacts:
    when: always
    expire_in: 30 days
    paths: [osv.sarif, osv.markdown]
    reports:
      junit: osv.junit.xml

trivy:
  extends: .componente-seguridad
  needs:
    - job: $[[ inputs.imagen ]]
      artifacts: true
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: never
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        paths: $[[ inputs.rutas_imagen ]]
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_TAG
  image:
    name: aquasec/trivy:0.76.2@sha256:8f6bb947dbc528902e11f2f5be52f7b519f6a39d5d148f41166f2040499768fb
    entrypoint: [""]
  variables:
    TRIVY_CACHE_DIR: .trivycache
    TRIVY_NO_PROGRESS: "true"
  cache:
    key: trivy-db
    when: always
    paths: [.trivycache/]
  script:
    - IGNORAR=""; if [ -f .trivyignore.yaml ]; then IGNORAR="--ignorefile .trivyignore.yaml"; fi
    - trivy image --input imagen.tar $IGNORAR --format json --output trivy.json
    - trivy convert --format sarif --output trivy.sarif trivy.json
    - trivy convert --format template --template @/contrib/junit.tpl --severity "$SEVERIDADES" --output trivy.junit.xml trivy.json
    - trivy convert --format table --severity "$SEVERIDADES" --exit-code 1 trivy.json
  artifacts:
    when: always
    expire_in: 30 days
    paths: [trivy.sarif]
    reports:
      junit: trivy.junit.xml
EOF
```

Lo que conviene mirar dos veces:

| Línea | Por qué así |
|---|---|
| `.componente-seguridad` con `needs: []` | Semgrep, Gitleaks y OSV-Scanner arrancan en el segundo cero (teoría 01, apartado 2.2). Trivy sobrescribe `needs` y `rules` |
| `rules` de Trivy con `rutas_imagen` | Trivy existe en una MR solo si existe `imagen`. Si no coinciden, el pipeline no se crea (`needs` a un job que no está) en vez de dejar una imagen sin escanear en silencio |
| `<<'REGLAS'` con comillas | Sin ellas, la shell expandiría `$X` y `$CMD` de los patrones de Semgrep |
| `awk -F' *\\| *'` | Dentro del bloque YAML, `\\|` llega a `awk` como `\|`: el separador es la barra vertical de la tabla |
| `|| rc=$?` | El runner ejecuta con `set -e`: sin capturar el código, el `1` de "hay vulnerabilidades" mataría el job antes de escribir el JUnit |
| Sin `allow_failure` en ningún job | Es la puerta (teoría 06, apartado 2.4) |

**Verifica** que las reglas del componente son exactamente las que probaste, y que las cuatro imágenes van por digest:

```bash
awk "/<<'REGLAS'/{f=1;next} /^ *REGLAS\$/{f=0} f" templates/seguridad.yml | sed 's/^      //' | diff - tests/seguridad/reglas.yaml && echo "reglas idénticas"
grep -cE '^ *(image|name): [a-z./-]+:[^ @]+@sha256:[0-9a-f]{64}$' templates/seguridad.yml
```

`reglas idénticas` y `4`.

---

## Paso 3: `ci/componentes` se prueba a sí mismo

**Por qué**: un componente se prueba en su propio pipeline, en el SHA del commit (Semana 12, teoría 06). Aquí, dos pruebas: que los cuatro escáneres corren y pasan sobre el propio `ci/componentes` (con la imagen de prueba de `imagen` como objetivo de Trivy y el lockfile de `tests/npm`), y que las reglas del componente siguen pasando sus pruebas. Esa segunda la ejecuta un job aparte, `reglas-semgrep`, que extrae las reglas de la plantilla como acabas de hacer tú.

En `.gitlab-ci.yml` de `ci/componentes`, el `include` de `imagen` gana `tar: true` y `templates/seguridad.yml` en sus `rutas`, y debajo van el `include` de `seguridad` y el job nuevo:

```yaml
  - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/imagen@$CI_COMMIT_SHA
    inputs:
      contexto: tests/imagen
      nombre: prueba
      stage: build
      rutas:
        - templates/imagen.yml
        - templates/seguridad.yml
        - tests/imagen/**/*
        - .gitlab-ci.yml
      registro: gitlab:5050      # solo laboratorio: el registry visto desde la red del compose
      inseguro: true             # solo laboratorio: HTTP
      tar: true
  - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/seguridad@$CI_COMMIT_SHA
    inputs:
      stage: test
      lockfile: tests/npm/package-lock.json
      rutas_imagen:
        - templates/imagen.yml
        - templates/seguridad.yml
        - tests/imagen/**/*
        - .gitlab-ci.yml

reglas-semgrep:
  stage: test
  needs: []
  image: semgrep/semgrep:1.185.0@sha256:67518c174185a2043fdbed16c70631b79209499b3671178e7194379b48295a0d
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        paths: [templates/seguridad.yml, tests/seguridad/**/*]
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_TAG
  script:
    # Las reglas viven dentro de la plantilla: se extraen y se prueban contra tests/seguridad/reglas.ts.
    - awk "/<<'REGLAS'/{f=1;next} /^ *REGLAS\$/{f=0} f" templates/seguridad.yml | sed 's/^      //' > tests/seguridad/reglas.yaml
    - unset SEMGREP_IN_DOCKER
    - semgrep --test --metrics=off tests/seguridad
```

Y un `.semgrepignore`: `tests/seguridad/reglas.ts` está lleno de `eval` y `exec` **a propósito**, y el job `semgrep` del propio `ci/componentes` lo encontraría.

```bash
cat > .semgrepignore <<'EOF'
# Código vulnerable a propósito: son las pruebas de las reglas (semgrep --test, job reglas-semgrep).
tests/seguridad/
EOF
```

`reglas-semgrep` repite la imagen de Semgrep con su digest: son dos sitios que actualizar cuando cambie. Es deliberado: el job prueba las reglas, no el job `semgrep` del componente.

No hay lint que valga antes de empujar: el `include` pide `seguridad` en el SHA de un commit que el servidor aún no tiene, y `ci/lint` contra `main` respondería `content not found`. Lo valida el pipeline de la merge request, en el paso 4.

---

## Paso 4: La merge request

**Por qué**: el pipeline de la MR es la primera ejecución real del componente, con el SHA de la rama.

```bash
cat >> README.md <<'EOF'

## seguridad

Cuatro escáneres con imagen fijada por digest: Semgrep (reglas de la plataforma, dentro del componente), Gitleaks (el historial completo), OSV-Scanner (el lockfile) y Trivy (la imagen que deja `imagen` con `tar: true`).
Cada uno deja un JUnit en el widget de tests de la merge request y un SARIF de 30 días. Ninguno admite fallo.

| Input | Por defecto | Para qué |
|---|---|---|
| `stage` | `seguridad` | Dónde aparecen; Semgrep, Gitleaks y OSV-Scanner no esperan a nadie |
| `umbral` | `alta` | `critica`, `alta` o `media`: desde dónde fallan OSV-Scanner (CVSS 9/7/4) y Trivy |
| `lockfile` | `package-lock.json` | Lo que lee OSV-Scanner |
| `imagen` | `imagen` | El job que deja `imagen.tar` |
| `rutas_imagen` | Las de `imagen` | Las mismas `rutas` que pases a `imagen` |

Excepciones: `.gitleaksignore`, `osv-scanner.toml` y `.trivyignore.yaml` en la raíz del proyecto que lo usa, con motivo y fecha.

## imagen: `tar`

Desde `1.3.0`, `tar: true` deja además la imagen en `imagen.tar`, un artefacto de una hora, también en merge requests. Es lo que escanea `seguridad`.
EOF

git add .gitignore .semgrepignore templates/ tests/seguridad/reglas.ts .gitlab-ci.yml README.md
git status --short
git commit -S -m "feat: componente seguridad e imagen como tarball"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="feat: componente seguridad" \
  -o merge_request.description="Closes #$IIDC"
MRC=$(curl -s -H "$H" "$API/projects/$PC/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
sleep 10
PIPE=$(curl -s -H "$H" "$API/projects/$PC/merge_requests/$MRC" | jq -r .head_pipeline.id)
esperar "$PC" "$PIPE"
curl -s -H "$H" "$API/projects/$PC/pipelines/$PIPE/jobs" | jq -r 'sort_by(.id) | .[] | "\(.stage)\t\(.name)\t\(.status)"'
```

**Verifica**: en `git status`, `tests/seguridad/reglas.yaml` **no** aparece (lo ignora `.gitignore`). El pipeline termina en `failed`, y es lo esperado: `imagen`, `reglas-semgrep`, `semgrep`, `gitleaks` y `osv-scanner` en `success`; `trivy` en `failed`.

```bash
curl -s -H "$H" "$API/projects/$PC/pipelines/$PIPE/test_report" \
  | jq -r '.test_suites[] | select(.failed_count > 0) | .name as $s | .test_cases[] | select(.status=="failed") | "\($s)\t\(.classname)\t\(.name)"'
```

**Verifica**: `trivy`, `musl-1.2.6-r2` (y `musl-utils`) con `[HIGH] CVE-2026-107891`, y posiblemente `zlib`. Es la imagen de prueba de la Semana 13, `alpine:3.24.2`. El componente acaba de encontrar su primer hallazgo, y es tuyo.

---

## Paso 5: Arreglar la imagen de prueba

**Por qué**: el arreglo de una CVE del sistema es cambiar de base (teoría 05, apartado 2.1). `alpine:3.24.3` (publicada el 2026-10-23) trae `musl` corregido; `3.24.4` es la última publicada y no se fija la última (lo explica [stack-versions](../../../docs/stack-versions.md)).

```bash
sed -i 's/^FROM alpine:3.24.2$/FROM alpine:3.24.3/' tests/imagen/Dockerfile
grep FROM tests/imagen/Dockerfile
git commit -S -am "fix: imagen de prueba sobre alpine 3.24.3, sin la CVE de musl"
git push
sleep 10
PIPE=$(curl -s -H "$H" "$API/projects/$PC/merge_requests/$MRC" | jq -r .head_pipeline.id)
esperar "$PC" "$PIPE"
fusionar "$PC" "$MRC"
git switch main && git pull --ff-only
PIPE=$(curl -s -H "$H" "$API/projects/$PC/pipelines?ref=main&source=push&per_page=1" | jq -r '.[0].id')
esperar "$PC" "$PIPE"
curl -s -H "$H" "$API/projects/$PC/pipelines/$PIPE/test_report_summary" | jq -c '[.test_suites[] | {name, total_count, failed_count}]'
```

**Verifica**: `FROM alpine:3.24.3`; el pipeline de la MR en `success`; `state: merged`; el de `main` en `success`, y las cuatro suites de los escáneres con `failed_count: 0` (además de las de `test`). `trivy` puede tener casos con `total_count` cero: bajo el umbral `alta`, los `MEDIUM` de `libssl3` no entran en el JUnit.

En el log del job `trivy` de `main`, `Saving cache for successful job`: la base de datos ya está en la caché compartida, y el siguiente escaneo no la descarga.

---

## Paso 6: `1.3.0`

**Por qué**: un componente nuevo y un input nuevo con valor por defecto no rompen a nadie: *minor* (Semana 12, teoría 06). `app` consume `@1`, así que en cuanto exista `1.3.0` la recibirá sola; la práctica 03 es la que la usa.

```bash
git tag -s 1.3.0 -m "1.3.0: componente seguridad, imagen como tarball"
git push origin 1.3.0
sleep 10
PIPE=$(curl -s -H "$H" "$API/projects/$PC/pipelines?ref=1.3.0&per_page=1" | jq -r '.[0].id')
esperar "$PC" "$PIPE"
jq -n '{query: "{ ciCatalogResources(search: \"componentes\") { nodes { fullPath versions(first: 1) { nodes { name components { nodes { name } } } } } } }"}' \
  | curl -s "$GITLAB_URL/api/graphql" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -c '.data.ciCatalogResources.nodes[] | select(.fullPath | endswith("/ci/componentes")) | .versions.nodes[] | {name, c: [.components.nodes[].name]}'
```

**Verifica**: `success` y `{"name":"1.3.0","c":["gobernanza","imagen","npm","seguridad"]}`, en cualquier orden. En `Explore → CI/CD Catalog`, la portada de `componentes` enseña la sección `seguridad` del README.

---

## ✅ Resultado

- [ ] `imagen` con el input `tar`, `false` por defecto
- [ ] `templates/seguridad.yml` con cuatro imágenes por digest y las reglas de la práctica 01 dentro
- [ ] `reglas-semgrep` en verde en `main` de `ci/componentes`
- [ ] La imagen de prueba sobre `alpine:3.24.3`, encontrada por el propio componente
- [ ] `1.3.0` publicada con `seguridad`

```bash
./scripts/verificar-semana.sh 19
```

Pasan `componente-seguridad`, `escaneres-por-digest`, `reglas-propias`, `imagen-guarda-tar`, `componentes-sigue-en-verde` y `seguridad-publicada`.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `git apply`: `patch does not apply` | Tu `templates/imagen.yml` no es el de la Semana 13 | Aplica los cuatro cambios a mano, con la tabla del paso 1 |
| El pipeline no se crea: `'trivy' job needs 'imagen' job, but 'imagen' does not exist in the pipeline` | `rutas_imagen` no coincide con las `rutas` de `imagen` | Las mismas rutas en los dos `include` |
| `semgrep`: `Detected Docker environment without a code volume` | Falta `unset SEMGREP_IN_DOCKER` | Paso 2 |
| `semgrep` falla en `ci/componentes` con hallazgos en `tests/seguridad/reglas.ts` | Falta `.semgrepignore` | Paso 3 |
| `reglas-semgrep`: `missed lines` | Las reglas de la plantilla y las pruebas no coinciden | El `diff` del paso 2 |
| `osv-scanner` sale con `128` en `ci/componentes` | El input `lockfile` no apunta a `tests/npm/package-lock.json` | Paso 3 |
| `trivy`: `open imagen.tar: no such file or directory` | El `include` de `imagen` no tiene `tar: true` | Paso 3 |
| `trivy` tarda dos minutos en cada pipeline | La caché no se guarda | `cache: when: always` en la plantilla y la caché compartida de la Semana 15 en `k8s-app` |
| `Failed to pull image … i/o timeout` | La red del laboratorio no resolvió Docker Hub en ese momento | Reintenta el job (`Retry`): no es el componente |

---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| [Práctica 01 — Las reglas y los escáneres](01-las-reglas-y-los-escaneres.md) | [Práctica 03 — `app` detrás de los cuatro](03-app-detras-de-los-cuatro.md) |

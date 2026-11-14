# Práctica 03 — Artefactos y caché, medidos

> No te fíes de la teoría: lees en los logs qué clave de caché usa cada pipeline y cuánto ahorra, descargas el paquete por su URL estable, creas la insignia de cobertura que la Semana 04 dejó pendiente, y rompes `app` a propósito para ver qué te enseña el pipeline cuando falla.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 02 completada · Teoría [04](../1-teoria/04-la-vida-de-un-job.md), [05](../1-teoria/05-artefactos.md) y [06](../1-teoria/06-cache.md) leídas

---

## Contexto

Esta práctica no fusiona nada. Deja una merge request en rojo **abierta**: la práctica 04 la necesita para comprobar que *Pipelines must succeed* la bloquea.

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | La clave de caché de `main` leída en el log | — |
| 2 | El efecto de la caché medido | — |
| 3 | El paquete descargado y abierto | `paquete-como-artefacto`, `informe-de-tests`, `cobertura-publicada` |
| 4 | La insignia de cobertura | `insignia-de-cobertura` |
| 5 | Una merge request en rojo por un test | — |

---

## Paso 0: Preparar el terreno

```bash
source ~/.bc-gitlab && source ~/.bc-gitlab-s09
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)

cache_log() {   # qué clave usó un job y si la encontró
  curl -s -H "$H" "$API/projects/$P/jobs/$1/trace" | sed 's/\x1b\[[0-9;]*m//g' \
    | grep -oE 'Checking cache for [^ ]+|Successfully extracted cache|Cache file does not exist|Created cache|Not uploading cache [^ ]+ due to policy|added [0-9]+ packages in [0-9.]+m?s'
}
job_id() {      # id de un job por nombre, en un pipeline
  curl -s -H "$H" "$API/projects/$P/pipelines/$1/jobs" | jq -r --arg n "$2" '.[] | select(.name == $n) | .id'
}
```

---

## Paso 1: La caché de `main`

**Por qué**: la teoría 06 dice que `main` y las merge requests no comparten caché. Aquí se ve.

```bash
PIPE_MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR_CI/pipelines" | jq -r '.[-1].id')
PIPE_MAIN=$(curl -s -H "$H" "$API/projects/$P/pipelines/latest?ref=main" | jq -r .id)
echo "== build de la merge request";  cache_log "$(job_id "$PIPE_MR" build)"
echo "== build de main";              cache_log "$(job_id "$PIPE_MAIN" build)"
echo "== test de main";               cache_log "$(job_id "$PIPE_MAIN" test)"
```

**Verifica**, más o menos así:

```
== build de la merge request
Checking cache for 0_package-lock-3e1f…-non_protected...
Cache file does not exist
added 4 packages in 2s
Created cache
== build de main
Checking cache for 0_package-lock-3e1f…-protected...
Cache file does not exist
added 4 packages in 2s
Created cache
== test de main
Checking cache for 0_package-lock-3e1f…-protected...
Successfully extracted cache
added 4 packages in 900ms
Not uploading cache 0_package-lock-3e1f…-protected due to policy
```

- El mismo hash en las tres claves: el mismo `package-lock.json`.
- `-non_protected` en la merge request, `-protected` en `main`. El `build` de `main` no aprovechó la caché que creó la merge request un minuto antes.
- `test` la extrajo, y no la volvió a subir (`policy: pull`).

Si ves `-protected` también en la merge request, estás usando un token de administrador: los administradores tienen siempre permiso de caché protegida (teoría 06, apartado 2.5).

---

## Paso 2: Lo que ahorra

**Por qué**: la caché tiene un coste (comprimir, subir, bajar) y un beneficio. Con 40 MB de dependencias, el beneficio se mide.

Lanza otro pipeline en `main`. Ahora la caché `-protected` ya existe:

```bash
PIPE2=$(curl -s --request POST "$API/projects/$P/pipeline?ref=main" -H "$H" | jq -r .id)
until curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE2" | jq -e '.status | IN("success","failed","canceled")' > /dev/null; do sleep 10; done
echo "== build, primera vez en main";  cache_log "$(job_id "$PIPE_MAIN" build)" | tail -2
echo "== build, segunda vez";          cache_log "$(job_id "$PIPE2" build)" | tail -2
```

Anota en una línea los dos tiempos de `added N packages in …`. Con un registro npm rápido, la diferencia es de uno o dos segundos; con uno lento o sin red, es la diferencia entre que el job funcione o no. Esa línea va al ADR-007 del proyecto.

> [!NOTE]
> El origen de este pipeline es `api`, no `push`, y pasa `workflow:rules` porque `CI_COMMIT_BRANCH` existe. Un pipeline lanzado a mano es la forma de comprobar algo de la plataforma sin crear commits.

---

## Paso 3: Los artefactos

**Por qué**: el `.tgz` es lo único que el pipeline produce para alguien de fuera. Hay que poder encontrarlo sin saber el ID de ningún job.

```bash
curl -sLo /tmp/app-main.zip -H "$H" "$API/projects/$P/jobs/artifacts/main/download?job=package"
unzip -o -q /tmp/app-main.zip -d /tmp/app-main && ls /tmp/app-main
tar tzf /tmp/app-main/*.tgz
```

**Verifica**: la lista de `tar` es la misma que dio `npm pack --dry-run` en la práctica 02, bajo `package/`. Sin tests, sin `assets/`.

El informe de tests y la cobertura del último pipeline de `main`:

```bash
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE2/test_report_summary" | jq .total
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE2" | jq .coverage
curl -s -H "$H" "$API/projects/$P/jobs/$(job_id "$PIPE2" test)" | jq '[.artifacts[] | {file_type, size}]'
```

`total.count` es tu número de tests y `failed` es `0`. Entre los artefactos de `test` hay uno de tipo `junit` y otro `trace` (el log). No hay `archive`: `junit.xml` va en `reports`, no en `paths`.

---

## Paso 4: La insignia de cobertura

**Por qué**: la Semana 04 la dejó pendiente a propósito, porque una insignia de cobertura sin pipeline que la publique dice *unknown* para siempre. Hoy hay número.

```bash
curl -s --request POST "$API/projects/$P/badges" -H "$H" \
  --data-urlencode "name=Cobertura" \
  --data-urlencode "link_url=$GITLAB_URL/%{project_path}/-/pipelines?ref=%{default_branch}" \
  --data-urlencode "image_url=$GITLAB_URL/%{project_path}/badges/%{default_branch}/coverage.svg" \
  | jq '{id, name, rendered_image_url}'
```

La URL empieza por `$GITLAB_URL` y no por `%{gitlab_server}`: ese marcador es solo el host, sin `http://` ni puerto, y la API rechaza la insignia (`is blocked: Only allowed schemes are http, https`).

**Verifica** en el navegador, en la portada de `app`: la insignia de pipeline dice `passed` y la de cobertura, un porcentaje.

---

## Paso 5: Una regresión que el pipeline detecta

**Por qué**: en la Semana 02 escribiste tests de borde "para la regresión de la Semana 09". Es esta. Rompes un límite de tu dominio y miras qué cuenta el pipeline, sin que nada llegue a `main`.

```bash
git switch main && git pull --ff-only
git switch -c regresion-a-proposito
```

Edita una función de `src/` y cambia **un** límite que un test cubra: un `<` por un `<=`, un `=== 0` por un `<= 0`. En la biblioteca, por ejemplo, `prestamosAbiertos < LIMITE_PRESTAMOS` por `<=`: el test "un socio en el límite no puede" tiene que caer.

```bash
npm test 2>&1 | grep -E '^ℹ (pass|fail)'      # fail 1, en local
git commit -S -am "chore: regresión a propósito para ver el pipeline en rojo"
git push -u origin HEAD \
  -o merge_request.create -o merge_request.target=main -o merge_request.draft \
  -o merge_request.title="chore: regresión a propósito, no fusionar"
```

`merge_request.draft` la marca como borrador: nadie la va a fusionar por despiste mientras dura la práctica.

```bash
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=regresion-a-proposito&state=opened" | jq -r '.[0].iid')
echo "export MR_ROJA=$MR" >> ~/.bc-gitlab-s09
PIPE=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/pipelines" | jq -r '.[0].id')
until curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE" | jq -e '.status | IN("success","failed","canceled")' > /dev/null; do sleep 10; done

curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | "\(.name)\t\(.status)\t\(.failure_reason // "-")"'
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/test_report" \
  | jq -r '.test_suites[].test_cases[] | select(.status == "failed") | .name'
cache_log "$(job_id "$PIPE" build)" | head -2
```

**Verifica**:

```
package   skipped  -
test      failed   script_failure
build     success  -
un socio en el limite no puede
Checking cache for 0_package-lock-3e1f…-non_protected...
Successfully extracted cache
```

Cuatro lecturas:

- `test` falló por `script_failure`: es el cambio, no la plataforma.
- `package` no se ejecutó (`skipped`): un stage no empieza si el anterior falla.
- El nombre del test que falla sale del informe JUnit, sin abrir el log. Existe porque `test` tiene `artifacts:when: always`.
- `build` usó la caché `-non_protected` que creó la merge request de la práctica 02: mismo lockfile, misma clave, y las dos ramas son no protegidas.

**No cierres esta merge request.** La práctica 04 la usa.

```bash
git switch main
```

---

## ✅ Resultado

- [ ] Las claves `-protected` y `-non_protected` vistas en los logs, con el mismo hash
- [ ] Los dos tiempos de `npm ci`, con y sin caché, anotados
- [ ] El `.tgz` descargado por la URL estable de `main`, sin tests dentro
- [ ] Informe de tests y cobertura leídos por API
- [ ] La insignia de cobertura con un porcentaje
- [ ] Una merge request en borrador, en rojo por un test, abierta

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `jobs/artifacts/main/download` da `404` | El último `package` de `main` no terminó bien, o el pipeline aún corre | `GET .../pipelines/latest?ref=main` y espera a `success` |
| `cache_log` no imprime nada | El job aún no ha terminado, o el ID está vacío | `echo` del ID; espera al pipeline |
| La insignia de cobertura dice *unknown* | El último pipeline de `main` no publicó `coverage` | Paso 3: `jq .coverage` tiene que dar un número |
| El pipeline de la regresión sale en verde | El límite que cambiaste no lo cubre ningún test | Elige otro, o añade el test que falta: eso también es una lección |
| `test_report` vacío | `test` no subió `junit.xml` | Comprueba `when: always` y que `test:ci` escribe `junit.xml` |

---

## 🔗 Navegación

[← Anterior: El primer pipeline](02-el-primer-pipeline.md) · [Volver a la Semana 09](../README.md) · [Siguiente: La gobernanza como job →](04-la-gobernanza-como-job.md)

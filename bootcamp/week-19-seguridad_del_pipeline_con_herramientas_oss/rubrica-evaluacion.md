# Rúbrica de Evaluación — Semana 19

## 📊 Distribución de Evidencias

| Tipo | Peso | Instrumento | Quién juzga |
|---|:--:|---|---|
| 🧠 Conocimiento | 30% | 10 preguntas conceptuales, 10 pts cada una | Autoevaluación |
| 💪 Desempeño | 40% | Las 4 prácticas, 10 pts cada una | La API de tu instancia |
| 📦 Producto | 30% | La capa 19 de tu plataforma: 60 pts por API + 40 pts de calidad | Mixto |

**Criterio de aprobación: mínimo 70% en cada evidencia**, no en el promedio.

---

## 🧠 Conocimiento (30%)

| # | Pregunta |
|:--:|---|
| 1 | Un compañero propone añadir `Jobs/SAST.gitlab-ci.yml` y `Jobs/Container-Scanning.gitlab-ci.yml` "porque son de GitLab y son gratis". ¿Es verdad que son gratis? ¿Qué le falta a esa solución en CE para ser una puerta, y qué tendrías que cambiarle a cada job para que lo fuera? |
| 2 | Una merge request añade `const r = eval(entrada)` y el pipeline pasa con `--config p/javascript --config p/typescript`. ¿Es un fallo de Semgrep? ¿Qué cuesta cada conjunto del registro en el pipeline, y por qué el componente lleva tres reglas propias en lugar de 74 ajenas? |
| 3 | Alguien pega una contraseña en un commit y la borra en el siguiente, dentro de la misma merge request. La pestaña *Changes* no la enseña. ¿Por qué Gitleaks sí, qué variable del job lo hace posible, y en qué orden se arregla? |
| 4 | Una merge request añade `lodash@4.17.20`. OSV-Scanner falla y Trivy pasa, sobre el mismo commit. ¿Se contradicen? ¿Qué mira cada uno, y en qué caso Trivy también habría fallado? |
| 5 | El job `trivy` de una merge request falla con `open imagen.tar: no such file or directory`, y en otra el pipeline ni siquiera se crea: `'trivy' job needs 'imagen' job, but 'imagen' does not exist`. ¿Qué falta en cada caso, y por qué el componente prefiere que el pipeline no se cree antes que dejar la imagen sin escanear? |
| 6 | Trivy marca trece CVE altas en la imagen de `app`. Tres son de `musl` y `zlib`; diez, de paquetes como `picomatch` y `sigstore` bajo `/usr/local/lib/node_modules/npm/`. ¿Por qué no se arreglan igual, y qué arreglo lleva cada grupo? |
| 7 | El umbral del componente es `alta`. ¿Qué hace OSV-Scanner con un aviso sin CVSS, por qué, y qué pasa con los `MEDIUM` que no paran el pipeline? |
| 8 | Eres `root`, el pipeline de la merge request está en rojo y la fusión por API responde `405`. ¿Qué ajuste del proyecto lo provoca, qué devuelve `detailed_merge_status`, y por qué la puerta no tiene excepción para administradores? |
| 9 | Una excepción en `osv-scanner.toml` tiene `ignoreUntil` de ayer. ¿Qué pasa en el siguiente pipeline, qué aviso deja el escáner en el log, y por qué una excepción sin fecha es peor que no tener escáner? |
| 10 | El `CODEOWNERS` de `app` asigna `/.gitleaksignore` a `revisor`, pero la primera merge request que crea `.gitleaksignore` se fusiona sin su aprobación. ¿Qué pasó, y por qué las líneas de dueño van en una merge request propia, antes que la excepción? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** Las plantillas sí son Free, pero en CE solo dejan un informe JSON que nadie lee: el widget de seguridad de la merge request y el *vulnerability report* que lo convierten en algo visible son Ultimate. Además, todos sus jobs llevan `allow_failure: true`, así que no paran nada, y sus imágenes van por etiqueta mayor (`semgrep:6`, `container-scanning:8`), que cambia sola. Para que fueran una puerta habría que sobrescribir cada job: `allow_failure: false`, una salida que falle con hallazgos, un informe que el revisor vea (JUnit) y la imagen por digest. A esas alturas has escrito el componente de esta semana. Y `Dependency-Scanning` ni siquiera corre en CE.

**2.** No es un fallo: las reglas de `eval` del registro están pensadas para código de navegador y otros contextos, y no cubren ese caso. Cada conjunto cuesta una descarga en cada job (de 4 a 82 s medidos, según la red), reglas que cambian sin que nadie lo decida y, con `--config auto`, telemetría obligatoria. Tres reglas propias son tres reglas que alguien habría necesitado, con su prueba (`semgrep --test`), que van con la versión del componente, no hacen peticiones y se entienden. Cien reglas importadas dan cien hallazgos el primer día, y el primer día decide si el equipo se toma el escáner en serio.

**3.** *Changes* enseña la diferencia final entre la rama y el destino: si el archivo entra y sale dentro de la MR, la diferencia es cero. Gitleaks con `gitleaks git` lee **cada commit** del historial, y el valor está en el segundo. `GIT_DEPTH: "0"` hace que el runner clone el historial completo; con la profundidad por defecto solo vería los últimos commits. El orden: rotar el secreto primero (estuvo en el servidor desde el push, y GitLab conserva la diff de la MR), quitarlo del código, y después decidir sobre el historial: reescribir o apuntar la huella con su motivo.

**4.** No se contradicen: miran cosas distintas. OSV-Scanner lee el lockfile, lo que el proyecto **declara**. Trivy lee la imagen, lo que **está instalado**. El `Dockerfile` de `app` solo copia `package.json` y `src/`, sin `npm ci`, así que en la imagen no hay ningún `lodash`. Trivy habría fallado si la imagen instalara dependencias de producción: entonces `lodash` estaría en `node_modules` dentro de la imagen.

**5.** En el primero, `imagen` corrió sin `tar: true` (o se resolvió a una versión anterior a `1.3.0`) y no dejó el tarball. En el segundo, `imagen` no existe en esa MR porque sus `rutas` no coinciden con las `rutas_imagen` de `seguridad`, y `needs` a un job que no está invalida el pipeline. Es deliberado: un pipeline que no se crea se ve y se arregla; uno que sale verde porque Trivy no tenía nada que escanear deja pasar una imagen sin mirar, y nadie se entera.

**6.** Las de `musl` y `zlib` son del sistema base, Alpine: se arreglan con una base que traiga los paquetes corregidos (`node:22.23.4-alpine3.24`, Alpine 3.24.4). Las otras diez son dependencias del `npm` que trae la imagen oficial de Node.js, no de `app`; subir de base no las quita porque cada versión trae su `npm`. `app` no usa `npm` al ejecutarse, así que el arreglo es borrarlo: el `RUN rm -rf /usr/local/lib/node_modules …`. Lo que no está no tiene CVE.

**7.** Un aviso sin CVSS **bloquea**: el componente no puede saber si es grave, y ante la duda la puerta se cierra; un humano lo mira y, si no aplica, lo apunta como excepción con fecha. Los `MEDIUM` no paran el pipeline pero se quedan en el SARIF de cada job, 30 días, y `docs/seguridad.md` les da un plazo: un issue con `due_date`. Sin ese plazo, un `MEDIUM` se queda para siempre.

**8.** *Pipelines must succeed* (`only_allow_merge_if_pipeline_succeeds: true`), con *Skipped pipelines are considered successful* desactivado. `detailed_merge_status` es `ci_must_pass`. La puerta no distingue roles porque su valor es precisamente que nadie la salta con prisa: una excepción legítima se escribe en un archivo con dueño y fecha, donde se revisa, no se resuelve con permisos.

**9.** La excepción deja de filtrar: el aviso vuelve a la tabla, con su CVSS, y si llega al umbral el job falla. El escáner avisa con `osv-scanner.toml has unused ignores` y el id. Una excepción sin fecha convierte un "lo miramos luego" en un "aceptado para siempre" por alguien que quizá ya no está: el escáner sigue en verde y da una seguridad que no existe, que es peor que saber que no hay escáner.

**10.** `gobernanza` lee el `CODEOWNERS` de la rama de **destino**. Si las líneas de dueño llegan en la misma merge request que crea `.gitleaksignore`, el `CODEOWNERS` de `main` todavía no las tiene, y nadie es dueño del archivo. Por eso van antes, en su propia merge request, que se fusiona con las reglas de siempre (`CODEOWNERS` ya es de `revisor` desde la Semana 07). A partir de ahí, cualquier excepción necesita a alguien que no es quien la pide.

</details>

---

## 💪 Desempeño (40%)

| Práctica | Criterio | Puntos |
|---|---|:--:|
| [01 — Las reglas y los escáneres](2-practicas/01-las-reglas-y-los-escaneres.md) | Las cuatro imágenes descargadas por digest; Gitleaks sobre el historial, OSV-Scanner sobre el lockfile y Trivy sobre la imagen ejecutados en local con su salida leída; las tres reglas con sus pruebas y `semgrep --test` en verde; las reglas probadas contra `app` y contra el código vulnerable | 10 |
| [02 — El componente `seguridad`](2-practicas/02-el-componente-seguridad.md) | El input `tar` en `imagen` con `false` por defecto; `templates/seguridad.yml` con las reglas idénticas a las probadas; `.semgrepignore` y `reglas-semgrep` en el autotest; el primer pipeline en rojo por la imagen de prueba, arreglada con `alpine:3.24.3`; `1.3.0` en el catálogo | 10 |
| [03 — `app` detrás de los cuatro](2-practicas/03-app-detras-de-los-cuatro.md) | La puerta comprobada; el stage `seguridad` antes de `deploy` y las rutas compartidas por ancla; el `405` visto con `ci_must_pass`; el `Dockerfile` corregido y probado en local antes de empujar, con su comentario al día; `main` en verde con los cuatro | 10 |
| [04 — La merge request envenenada](2-practicas/04-la-merge-request-envenenada.md) | Las líneas de dueño fusionadas antes; los tres escáneres en rojo a la vez y el `405`; el `eval` sustituido y `lodash` desinstalado (no subido); la contraseña tratada como quemada y su huella con motivo; la fusión aprobada por `revisor` y su token revocado | 10 |

---

## 📦 Producto (30%)

### Verificable por API — 60 puntos

| Requisito | Comprobación | Puntos |
|---|---|:--:|
| El componente `seguridad` existe | `componente-seguridad` | 4 |
| Imágenes por digest | `escaneres-por-digest` | 4 |
| Reglas propias, sin registro | `reglas-propias` | 4 |
| `imagen` deja el tarball | `imagen-guarda-tar` | 3 |
| `ci/componentes` en verde | `componentes-sigue-en-verde` | 3 |
| `1.3.0` publicada con `seguridad` | `seguridad-publicada` | 4 |
| `app` usa `seguridad@1` | `app-usa-seguridad` | 3 |
| Los cuatro sin `allow_failure` | `cuatro-escaneres-bloquean` | 5 |
| `main` escaneada y en verde | `main-escaneada` | 4 |
| Un JUnit por escáner | `informes-junit` | 3 |
| La imagen corregida | `imagen-base-corregida` | 4 |
| La fusión exige pipeline | `fusion-exige-pipeline` | 3 |
| Los cuatro han parado algo | `los-cuatro-han-parado-algo` | 4 |
| Huella con motivo | `excepcion-con-motivo` | 4 |
| Excepciones con dueño | `excepciones-con-dueno` | 3 |
| `docs/seguridad.md` | `politica-de-seguridad` | 5 |

### Calidad — 40 puntos

| Criterio | Qué se mira | Puntos |
|---|---|:--:|
| Las reglas se pueden mantener | Cada regla con al menos un `ruleid` y un `ok`; `message` con qué pasa, por qué importa y la CWE; `reglas-semgrep` en verde | 10 |
| La política sirve para decidir | `docs/seguridad.md` con plazos que tus excepciones cumplen; *Hallazgos abiertos* con un issue con `due_date` por cada `MEDIUM`; el ensayo de caducidad con lo que pasó de verdad | 14 |
| Las excepciones se defienden solas | El comentario de `.gitleaksignore` dice qué era, por qué no hay nada que rotar y que no llega a `main`; ninguna excepción sin fecha | 8 |
| El componente se entiende | La sección `seguridad` del README de `ci/componentes` con sus inputs; un comentario en cada línea que no es obvia (`unset SEMGREP_IN_DOCKER`, los códigos de salida de OSV-Scanner) | 8 |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| `allow_failure: true` en un escáner, o un `rules` que lo salta en las merge requests | −20 |
| Una imagen de escáner por etiqueta sin digest, o cualquier `:latest` | −10 |
| Un secreto real (no generado con `openssl` para la práctica) en un repositorio | −20 |
| Una huella en `.gitleaksignore` de un secreto que no se rotó | −15 |
| Una excepción de OSV-Scanner o Trivy sin fecha de caducidad | −10 |
| `// nosemgrep` sin motivo | −5 |
| La dependencia vulnerable "arreglada" con una versión de menos de siete días | −5 |

---

[← Volver a la Semana 19](README.md)

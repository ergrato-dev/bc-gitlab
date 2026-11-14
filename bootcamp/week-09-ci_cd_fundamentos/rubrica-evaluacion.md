# Rúbrica de Evaluación — Semana 09

## 📊 Distribución de Evidencias

| Tipo | Peso | Instrumento | Quién juzga |
|---|:--:|---|---|
| 🧠 Conocimiento | 30% | 10 preguntas conceptuales, 10 pts cada una | Autoevaluación |
| 💪 Desempeño | 40% | Las 4 prácticas, 10 pts cada una | La API de tu instancia |
| 📦 Producto | 30% | La capa 9 de tu plataforma: 60 pts por API + 40 pts de calidad | Mixto |

**Criterio de aprobación: mínimo 70% en cada evidencia**, no en el promedio.

---

## 🧠 Conocimiento (30%)

| # | Pregunta |
|:--:|---|
| 1 | GitLab y el runner se reparten el trabajo de un pipeline. ¿Qué decide cada uno, quién abre la conexión entre ellos y qué consecuencia de seguridad tiene ese reparto? |
| 2 | Sin `workflow:rules`, ¿cuántos pipelines crea un push a una rama con merge request abierta, de qué tipo es cada uno y qué hace exactamente cada línea del bloque que usa `app`? |
| 3 | `build` hace `extends: .npm` y define su propio `cache.policy`. ¿Qué hereda, qué sustituye, y qué pasaría si además definiera su propio `before_script`? |
| 4 | Un job del laboratorio no llega a `http://localhost:8888`. ¿Por qué, qué tres cosas lo arreglan, y por qué el arreglo de la API vive en la instancia y no en el `.gitlab-ci.yml` ni en el `config.toml`? |
| 5 | Antes del flujo actual, un runner se registraba con un *registration token*. ¿Qué problema tenía y qué cambia con el *authentication token*? |
| 6 | Un pipeline está en rojo. ¿Cómo distingues, sin leer el log, si es culpa del cambio o de la plataforma? Da dos `failure_reason` de cada tipo. |
| 7 | Formula la pregunta que separa un artefacto de una caché y aplícala a `junit.xml`, al `.tgz`, a `.npm/` y a `node_modules/`. |
| 8 | El primer pipeline de una merge request no encuentra la caché que `main` usa a diario. ¿Por qué, qué ataque evita, y por qué no deberías arreglarlo con `cache:unprotect`? |
| 9 | `gobernanza` no puede usar `CI_JOB_TOKEN`. ¿Por qué, qué token usa, con qué rol y scope, y qué riesgo se acepta al no proteger su variable? |
| 10 | Con *Pipelines must succeed* activado, ¿puede fusionarse una merge request con `gobernanza` en `❌`? ¿Por qué, y qué haría falta para que no pudiera? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** GitLab lee `.gitlab-ci.yml` del commit, decide qué jobs entran en el pipeline y los deja en cola; el runner pregunta cada pocos segundos si hay algo para él, lo ejecuta en su ejecutor y devuelve log, estado y artefactos. La conexión la abre siempre el runner (`POST /api/v4/jobs/request`), así que puede estar detrás de un NAT sin puertos abiertos. Y el código de cada merge request se ejecuta fuera del servidor de GitLab: un job malicioso o desbocado rompe su contenedor, no la instancia.

**2.** Dos: uno de rama (`push`) y otro de merge request (`merge_request_event`), los dos sobre el mismo commit. El bloque de `app`: si el pipeline viene de una merge request, se crea; si es un push a una rama que tiene merge requests abiertas (`CI_OPEN_MERGE_REQUESTS`), no, porque ese commit ya tiene su pipeline de merge request; cualquier otro push a una rama, se crea; un tag, se crea. Todo lo demás (por ejemplo, un pipeline que no encaja en ninguna regla) no se crea.

**3.** Hereda `cache.key` y `cache.paths` y el `before_script` de `.npm`, y sustituye `cache.policy` por `pull-push`: `extends` mezcla los mapas en profundidad. Las listas no se mezclan: si `build` tuviera su propio `before_script`, sustituiría entero el de `.npm` y el `npm ci` desaparecería, con lo que `npx tsc` fallaría por no tener TypeScript instalado.

**4.** Porque `localhost` dentro de un contenedor es el propio contenedor, y GitLab construye `CI_REPOSITORY_URL`, `CI_API_V4_URL` y `CI_SERVER_URL` con `external_url`, que es `http://localhost:8888`. Lo arreglan `clone_url` en el runner, para el clon, y dos variables CI/CD de instancia, `CI_API_V4_URL` y `CI_SERVER_URL`, con `http://gitlab:8888`, que resuelve en la red del compose. No va en el `.gitlab-ci.yml` porque es un problema del laboratorio, no de `app`: el YAML tiene que seguir funcionando en cualquier GitLab. No va en el `environment` del `config.toml` porque las variables que manda GitLab con el job pisan las del runner; una variable de instancia, en cambio, tiene más prioridad que la predefinida.

**5.** El *registration token* era uno por proyecto, compartido: cualquiera que lo viera podía colgar runners del proyecto, y la configuración (etiquetas, protección, si acepta jobs sin etiqueta) la decidía quien registraba, no el proyecto. Con el flujo actual, el runner se crea primero en GitLab con su configuración, y el *authentication token* (`glrt-`) es la identidad de ese runner concreto: registrarlo no da permiso para nada más. Se puede ver y auditar cada runner, y revocar uno sin afectar a los demás.

**6.** Con `failure_reason` del job. Del cambio: `script_failure` (un comando devolvió distinto de cero), y casi siempre `job_execution_timeout` si el job se volvió lento por el cambio. De la plataforma: `stuck_or_timeout_failure` (ningún runner lo recogió), `runner_system_failure` (el runner falló al preparar o limpiar), `unmet_prerequisites`. Un `missing_dependency_failure` es de configuración: el artefacto que necesitaba caducó.

**7.** "Si este archivo desapareciera, ¿el pipeline daría otro resultado?". `junit.xml`: sí, sin él no hay informe de tests: artefacto (de tipo `reports`). El `.tgz`: sí, es el producto del pipeline: artefacto. `.npm/`: no, `npm ci` lo vuelve a descargar y el resultado es el mismo, solo más lento: caché. `node_modules/`: ni una cosa ni otra en `app`; `npm ci` lo borra antes de instalar, así que cachearlo no ahorra nada, y pasarlo como artefacto sube y baja cientos de megas sin motivo.

**8.** Porque la clave de caché lleva el sufijo `-protected` en ramas protegidas y `-non_protected` en las demás, y los pipelines de merge request se ejecutan en la rama de origen, que no está protegida. Evita el envenenamiento de caché: si una rama cualquiera pudiera escribir en la caché que usa `main`, un Developer podría meter un paquete modificado en `.npm/` y esperar a que el `package` de `main` lo empaquetara. `cache:unprotect: true` juntaría las dos cachés y deshace justo esa protección; el coste de no hacerlo es un `npm ci` sin caché por merge request nueva.

**9.** Porque `CI_JOB_TOKEN` solo vale en los endpoints marcados para aceptarlo, y `approvals`, `diffs` y `closes_issues` de una merge request no lo están (comprobado en el código de 19.2.4). Usa un token de acceso de proyecto, `gobernanza-ci`, con rol Reporter (`20`) y scope `read_api`, que caduca en seis meses. Su variable no es protegida porque los pipelines de merge request no corren en ramas protegidas y el job no la recibiría. El riesgo aceptado: cualquier Developer puede abrir una merge request que cambie el YAML y enviar el token fuera, porque el pipeline de la merge request se ejecuta con su propio YAML antes de que nadie lo revise. Se acepta porque el token solo puede leer un proyecto; la Semana 10 lo trata.

**10.** Sí. `gobernanza` tiene `allow_failure: true`, y un job que falla con `allow_failure` deja el pipeline en `success` con un aviso; *Pipelines must succeed* solo mira el estado del pipeline. Es la decisión del ADR-005: detecta, no bloquea. Para que bloqueara habría que quitar `allow_failure`, y antes escribir un ADR que sustituya al 005, porque cambia el contrato: cada merge request tendría el pipeline en rojo hasta que alguien aprobara y se relanzara.

</details>

---

## 💪 Desempeño (40%)

| Práctica | Criterio | Puntos |
|---|---|:--:|
| [01 — El runner de `app`](2-practicas/01-el-runner-de-app.md) | Nada pendiente de Auto DevOps; variables de instancia correctas; runner creado por API y registrado sin el token en los argumentos; `sonda` en verde con `401` desde `gitlab:8888`; rama borrada | 10 |
| [02 — El primer pipeline](2-practicas/02-el-primer-pipeline.md) | Dependencias con versión exacta y lockfile; `.gitlab-ci.yml` validado por la API antes del commit; un solo pipeline en la merge request; `main` en verde con cobertura; issue cerrado | 10 |
| [03 — Artefactos y caché, medidos](2-practicas/03-artefactos-y-cache-medidos.md) | Las dos claves de caché leídas en los logs; los tiempos de `npm ci` anotados; el `.tgz` descargado por la URL estable y sin tests; insignia de cobertura; la regresión en rojo leída por `failure_reason` y por el informe JUnit | 10 |
| [04 — La gobernanza como job](2-practicas/04-la-gobernanza-como-job.md) | Token y variable creados sin que el token se viera; `gobernanza` en `❌` antes de aprobar y en `0 problema(s)` después; *Pipelines must succeed* comprobado con un `405`; la regresión cerrada sin fusionar | 10 |

---

## 📦 Producto (30%)

### Verificable por API — 60 puntos

| Requisito | Comprobación | Puntos |
|---|---|:--:|
| Runner de proyecto en línea | `runner-de-proyecto-en-linea` | 3 |
| Los jobs llegan a la API | `variable-de-instancia-api` | 2 |
| `.gitlab-ci.yml` en `main` | `gitlab-ci-en-main` | 2 |
| `.gitlab-ci.yml` válido | `ci-valido-en-main` | 2 |
| Stages en orden | `stages-build-test-package` | 3 |
| `workflow:rules` | `workflow-rules` | 3 |
| Imágenes fijadas | `imagenes-fijadas` | 3 |
| Caché por lockfile | `cache-por-lockfile` | 3 |
| Lockfile en `main` | `lockfile-en-main` | 2 |
| `main` en verde | `ultimo-pipeline-de-main-en-verde` | 3 |
| Los tres jobs en verde | `tres-jobs-en-main` | 3 |
| Informe de tests sin fallos | `informe-de-tests` | 3 |
| Cobertura publicada | `cobertura-publicada` | 2 |
| Paquete como artefacto | `paquete-como-artefacto` | 3 |
| Insignia de cobertura | `insignia-de-cobertura` | 2 |
| Token de proyecto mínimo | `token-de-gobernanza` | 3 |
| Variable enmascarada y oculta | `variable-de-gobernanza` | 3 |
| Script ejecutable | `gobernanza-ejecutable` | 2 |
| `.gitlab-ci.yml` con dueño | `pipeline-con-dueno` | 2 |
| `gobernanza` en verde en alguna merge request | `gobernanza-en-verde-en-una-mr` | 3 |
| *Pipelines must succeed* | `pipelines-must-succeed` | 3 |
| `CONTRIBUTING.md` con el pipeline | `contributing-con-el-pipeline` | 2 |
| ADR-007 | `adr-007-en-la-wiki` | 3 |

### Calidad — 40 puntos

| Criterio | Qué se mira | Puntos |
|---|---|:--:|
| El ADR-007 decide y descarta | Responde los siete puntos del proyecto, enlaza el ADR-005 y dice qué se descartó y por qué | 8 |
| Los números son medidos | Los tiempos de `npm ci` y las claves de caché del ADR-007 salen de tus logs, no de la teoría | 6 |
| El pipeline se reproduce en local | Cada comando de "El pipeline" en `CONTRIBUTING.md` funciona copiado en un clon limpio | 8 |
| El riesgo del token está escrito | El ADR-007 recoge lo que mostró el job `fuga`: qué ve un job, qué protege el enmascarado y qué no | 8 |
| Ningún token se vio | Ni el del runner ni el de `gobernanza` aparecen en el historial de la terminal ni en ningún archivo | 5 |
| La regresión cumplió su función | Rompió un test de borde; si no rompió ninguno, el test que faltaba está añadido | 5 |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Una imagen sin versión o con `latest` en `.gitlab-ci.yml` o en `config.toml` | −10 |
| `GOBERNANZA_TOKEN` creado con el token personal del alumno, o con rol o scope por encima de Reporter y `read_api` | −15 |
| El job `fuga` del proyecto fusionado en `main` | −15 |
| La merge request de la regresión fusionada | −15 |
| Un cambio en `main` sin merge request | −10 |
| El token del revisor sin revocar al terminar | −15 |
| Un token —cualquiera— en una merge request, un commit, un log de job sin enmascarar o un script | −25 |

---

[← Volver a la Semana 09](README.md)

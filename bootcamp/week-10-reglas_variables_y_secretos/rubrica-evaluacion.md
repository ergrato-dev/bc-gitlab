# Rúbrica de Evaluación — Semana 10

## 📊 Distribución de Evidencias

| Tipo | Peso | Instrumento | Quién juzga |
|---|:--:|---|---|
| 🧠 Conocimiento | 30% | 10 preguntas conceptuales, 10 pts cada una | Autoevaluación |
| 💪 Desempeño | 40% | Las 4 prácticas, 10 pts cada una | La API de tu instancia |
| 📦 Producto | 30% | La capa 10 de tu plataforma: 60 pts por API + 40 pts de calidad | Mixto |

**Criterio de aprobación: mínimo 70% en cada evidencia**, no en el promedio.

---

## 🧠 Conocimiento (30%)

| # | Pregunta |
|:--:|---|
| 1 | `package` tiene tres reglas: rama por defecto, `release/*` y tag. ¿Por qué no entra en un pipeline de merge request, y qué pasaría si alguien añadiera `- if: $CI_COMMIT_BRANCH == "main"` pensando en las merge requests a `main`? |
| 2 | ¿Por qué `.npm` usa `changes` solo en la regla de merge request? ¿Contra qué compara `changes` en un push a una rama nueva y en un pipeline lanzado a mano? |
| 3 | Lanzas `POST .../pipeline` sobre una rama con merge request abierta y recibes `Review the workflow:rules`. ¿Qué línea lo provoca, por qué existe y cómo relanzas el pipeline de esa merge request? |
| 4 | `workflow:auto_cancel:on_new_commit: interruptible`. ¿Qué cancela, qué no, y por qué los jobs de despliegue llevan `interruptible: false`? |
| 5 | `ORIGEN` está en el YAML del job, en el proyecto como variable protegida y en el pipeline. ¿Qué valor recibe la sonda en una rama sin proteger si lanzas el pipeline sin variables? ¿Y con ellas? ¿Qué lección de seguridad sacas del primer caso? |
| 6 | Explica qué protege y qué no protege cada uno de `protected`, `masked` y `hidden`. ¿Cuál decide si un secreto llega a una merge request? |
| 7 | Una variable **no protegida** con ámbito `production`. ¿Llega a un job de merge request que declara `environment: production`? ¿Por qué `environment_scope` no es una barrera de seguridad, y qué la convierte en una? |
| 8 | En CE no hay entornos protegidos. ¿Qué sustituye a esa protección en `app`, qué comprobaste con `dev` y qué hueco queda? |
| 9 | ¿Por qué `DEPLOY_SSH_KEY` es una variable de archivo protegida y no un *secure file*? Da dos pruebas que viste en la práctica 04. |
| 10 | ¿Qué escribe `CI_DEBUG_TRACE` en el log, qué sale en claro aunque sea protegido, y qué dos barreras de `app` impiden que un Developer lo active en un pipeline de `main`? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** En un pipeline de merge request `CI_COMMIT_BRANCH` no existe y `CI_COMMIT_TAG` tampoco, así que ninguna de las tres reglas coincide y el job no entra. La regla añadida tampoco coincidiría por el mismo motivo: en una merge request a `main` la variable que existe es `CI_MERGE_REQUEST_TARGET_BRANCH_NAME`. No cambiaría nada en las merge requests y, en los pushes a `main`, repetiría la primera regla.

**2.** Porque `changes` solo es fiable donde tiene algo con qué comparar: en una merge request compara con la rama de destino, es decir, con todo lo que trae la merge request. En un push a una rama nueva, en un tag o en un pipeline lanzado a mano o programado no hay referencia y `changes` es siempre cierto; en un push a una rama existente compara solo con el push anterior. En `main`, `release/*` y los tags, `build` y `test` tienen que correr siempre, y lo hace la segunda regla.

**3.** La línea `if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS` con `when: never`. Existe para que un push a una rama con merge request abierta no cree un pipeline de rama además del de merge request: dos pipelines del mismo commit. Un pipeline lanzado por API sobre esa rama también tiene `CI_COMMIT_BRANCH` y coincide. Se relanza con `POST .../merge_requests/<iid>/pipelines`, que crea un pipeline de merge request.

**4.** Cuando llega un commit nuevo a la misma ref, cancela del pipeline anterior todos los jobs con `interruptible: true`, estén donde estén, y deja seguir los que no lo son. Los despliegues no son interrumpibles porque un despliegue cortado a la mitad deja el entorno en un estado que nadie ha probado; un `npm ci` o un `tsc` cortados no dejan nada.

**5.** Sin variables de pipeline recibe `yaml-job`: la variable de proyecto es protegida y la rama no lo es, así que no llega, y el job usa en silencio el valor del YAML sin ningún aviso. Con una variable de pipeline recibe ese valor, que gana a todo. La lección: un secreto protegido que no llega no da error; por eso el YAML no define nunca un valor por defecto para un secreto y `deploy.sh` empieza con `: "${DEPLOY_TOKEN:?...}"`.

**6.** `protected` decide si la variable llega: solo a pipelines de refs protegidas; no protege contra quien puede fusionar en esas refs o crear tags protegidos. `masked` sustituye el valor exacto por `[MASKED]` en el log; no impide que el job lo use, lo transforme o lo envíe. `hidden` impide volver a leer el valor en la interfaz o la API; no impide que el job lo reciba. Solo `protected` decide si llega a una merge request.

**7.** Sí: en el laboratorio llegó entera a la merge request de un Developer. El nombre del entorno lo escribe el YAML del job, y quien escribe el YAML de la merge request escribe `environment: production`. `environment_scope` decide cuál de varias variables recibe un job; `protected` decide si sale de las refs protegidas. Protegida y con ámbito, la misma prueba la recibió vacía.

**8.** Que `deploy-production` solo corra en `main`, que es ref protegida, que sea `when: manual`, y que `DEPLOY_TOKEN` de `production` sea protegida. `dev` recibió `403` al lanzar el job manual: lanzar un job de una rama protegida exige poder fusionar en ella. El hueco: vale lo que valga la protección de `main`, y no hay segunda persona; quien puede fusionar puede desplegar solo, sin aprobación de nadie.

**9.** Porque los *secure files* no tienen protección ni ámbito: cualquier Developer los descarga. Pruebas: `dev` descargó la clave con su token personal por `GET .../secure_files/<id>/download` (`200`, misma huella), y el job de su merge request la descargó con `CI_JOB_TOKEN`. La variable de archivo protegida con ámbito `production` llegó vacía a esa misma merge request.

**10.** Todas las variables del job, una por línea, como `export`. Las enmascaradas salen como `[MASKED]`; las demás en claro, incluidas las protegidas no enmascaradas y el contenido de las variables de tipo archivo, como una clave SSH, en un job de `main`. La primera barrera es la protección de `main` (Semana 07): un Developer no puede lanzar ningún pipeline en una rama protegida donde no puede fusionar. La segunda, `ci_pipeline_variables_minimum_override_role=maintainer`: aunque algún día pudiera fusionar en una rama protegida, no podría pasar `CI_DEBUG_TRACE=true` como variable; en su propia merge request puede ponerla en el YAML, pero allí no llegan las variables protegidas.

</details>

---

## 💪 Desempeño (40%)

| Práctica | Qué se comprueba | Puntos |
|---|---|:--:|
| [01 — Las reglas de `app`](2-practicas/01-las-reglas-de-app.md) | `workflow` con nombre y `auto_cancel`; `build` y `test` con `changes`; `package` fuera de las merge requests; una merge request de documentación con solo `gobernanza` | 10 |
| [02 — Variables y precedencia](2-practicas/02-variables-y-precedencia.md) | La precedencia comprobada en tres pipelines; el valor del YAML cuando la protegida no llega; `400` de `dev` con el rol mínimo en `maintainer`; `ORIGEN` borrada | 10 |
| [03 — Secretos por entorno](2-practicas/03-secretos-por-entorno.md) | `DEPLOY_TOKEN` en dos ámbitos sin verla; la merge request sin despliegues; `staging` desplegado; `403` de `dev`; `production` fallido por la clave y `main` en verde | 10 |
| [04 — Archivos secretos y fugas](2-practicas/04-archivos-secretos-y-fugas.md) | El *secure file* descargado por `dev`; la fuga leída en tres columnas; la clave descartada y otra como variable de archivo; `production` desplegado; la fuga repetida y cerrada | 10 |

---

## 📦 Producto (30%)

### Verificable por API — 60 puntos

| Requisito | Comprobación | Puntos |
|---|---|:--:|
| `workflow` con nombre | `workflow-con-nombre` | 3 |
| Cancelación automática | `auto-cancel-interrumpible` | 3 |
| `changes` en `build` y `test` | `build-y-test-con-changes` | 4 |
| Despliegue manual a `production` | `despliegue-a-produccion-manual` | 4 |
| Entornos | `entornos-staging-y-production` | 3 |
| Desplegado en `staging` | `desplegado-en-staging` | 3 |
| Desplegado en `production` | `desplegado-en-production` | 3 |
| `DEPLOY_TOKEN` por entorno | `deploy-token-por-entorno` | 4 |
| Clave como archivo | `clave-ssh-como-archivo` | 4 |
| Secretos protegidos | `secretos-protegidos` | 4 |
| Secretos enmascarados | `secretos-enmascarados` | 3 |
| Ninguna clave en *secure files* | `ningun-secure-file-con-claves` | 3 |
| Variables de pipeline restringidas | `variables-de-pipeline-restringidas` | 3 |
| `GOBERNANZA_TOKEN` rotado | `gobernanza-rotado` | 4 |
| `main` en verde | `ultimo-pipeline-de-main-en-verde` | 3 |
| Ningún secreto en el YAML | `ningun-secreto-en-el-yaml` | 3 |
| Inventario de secretos | `inventario-de-secretos` | 3 |
| ADR-007 ampliado | `adr-007-ampliado` | 3 |

### Calidad — 40 puntos

| Criterio | Qué se mira | Puntos |
|---|---|:--:|
| El inventario dice la verdad | "Quién puede leerlo de verdad" recoge lo que mostró la práctica 04, también para `GOBERNANZA_TOKEN` | 10 |
| El ADR-007 decide y descarta | Responde los seis puntos del proyecto, dice qué no protege `environment_scope` y el hueco del despliegue manual | 10 |
| Ningún secreto se vio | Ni `DEPLOY_TOKEN`, ni el token rotado, ni la clave privada en el historial, en un archivo o en un log sin enmascarar | 10 |
| La clave expuesta se descartó | La clave del *secure file* no es la que está en `DEPLOY_SSH_KEY`: las huellas son distintas | 5 |
| "Si se filtra" se entiende | La columna la entiende alguien que no sabe qué es un token | 5 |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Un secreto, aunque sea de mentira, en el YAML o en un commit | −25 |
| Una clave privada en `docs/`, en la wiki o como *secure file* al terminar | −20 |
| `DEPLOY_TOKEN` o `DEPLOY_SSH_KEY` sin proteger, aunque sea un momento "para probar" | −15 |
| La merge request de la fuga fusionada | −15 |
| `deploy-production` automático en `main` | −10 |
| Un cambio en `main` sin merge request | −10 |
| Los tokens de `revisor` o `dev` sin revocar al terminar | −15 |
| `CI_DEBUG_TRACE` en el `.gitlab-ci.yml` de `main` | −15 |

---

[← Volver a la Semana 10](README.md)

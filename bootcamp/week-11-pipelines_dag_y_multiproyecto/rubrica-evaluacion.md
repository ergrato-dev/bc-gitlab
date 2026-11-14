# Rúbrica de Evaluación — Semana 11

## 📊 Distribución de Evidencias

| Tipo | Peso | Instrumento | Quién juzga |
|---|:--:|---|---|
| 🧠 Conocimiento | 30% | 10 preguntas conceptuales, 10 pts cada una | Autoevaluación |
| 💪 Desempeño | 40% | Las 4 prácticas, 10 pts cada una | La API de tu instancia |
| 📦 Producto | 30% | La capa 11 de tu plataforma: 60 pts por API + 40 pts de calidad | Mixto |

**Criterio de aprobación: mínimo 70% en cada evidencia**, no en el promedio.

---

## 🧠 Conocimiento (30%)

| # | Pregunta |
|:--:|---|
| 1 | Convertiste el pipeline de `app` en un DAG y con `concurrent = 1` no ganó nada. ¿Por qué? ¿Qué ganó de todas formas, aunque el pipeline no fuera más corto? |
| 2 | ¿Qué es el camino crítico de un pipeline? Con tus duraciones, ¿qué job de `app` acortarías primero, y por qué acortar `build` no cambiaría nada? |
| 3 | `package` tiene `needs: [build, test]`. ¿Qué pasaría si mañana alguien añade `changes` a `build` en los pushes a `main`, y por qué `needs: optional` sería la respuesta equivocada? |
| 4 | Copias el `workflow` de `app` en `ci/docs.yml`. ¿Qué pasa en una merge request y por qué? ¿Qué variable distingue a un hijo y qué recibe del padre? |
| 5 | ¿Qué diferencia hay entre un job de disparo sin `strategy`, con `strategy: depend` y con `strategy: mirror`? ¿Qué se rompería en `app` sin `mirror`? |
| 6 | ¿Cuándo compensa un pipeline hijo dinámico? ¿Qué pierde la revisión de código con él, y qué tiene que ver eso con `CODEOWNERS`? |
| 7 | El pipeline de `infra/entornos` lo dispara `app`. ¿Con la identidad de quién se crea, qué permisos necesita esa identidad, y qué pasa el día que esa persona deja la organización? |
| 8 | El primer `registrar` falló con `403`. ¿Qué lo rechazó, si tu usuario es miembro de los dos proyectos? ¿Qué lista se cambió, la de qué proyecto, y por qué en esa dirección? |
| 9 | ¿Por qué `infra/entornos` descarga el paquete por ID de job y no "el último artefacto de `main`"? ¿Qué sustituye todo esto a `needs:project` y en qué tier está esa palabra clave? |
| 10 | `staging` usa `newest_first` y `production` no. ¿Qué carrera evita `resource_group` que `interruptible: false` no evita, qué ajuste del proyecto completa a `newest_first`, y por qué un programado sobre `main` necesita `.fuera-de-programados` aunque `.npm` ya tenga `changes`? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** `needs` dice qué jobs **pueden** ejecutarse a la vez; que se ejecuten depende de que haya huecos de runner. Con `concurrent = 1`, el runner ejecuta un job cada vez, así que `build` y `test` siguen uno detrás de otro aunque ninguno espere al otro. Lo que sí se ganó: `gobernanza` y `test` quedan pendientes desde el principio y pueden ser los primeros, y si `build` falla, `test` se ejecuta igualmente y ves los dos fallos en el mismo pipeline en lugar de descubrirlos en dos vueltas.

**2.** Es la cadena más larga de jobs encadenados por `needs`: su suma es la duración mínima del pipeline aunque hubiera runners infinitos. En `app`, `max(build, test) + package + deploy-staging` (y en `main`, el disparo a `infra` en paralelo con `deploy-staging`). Si `test` dura más que `build`, `build` no está en el camino crítico: acortarlo deja el pipeline igual. Se acorta primero el job más largo del camino crítico, casi siempre `test`.

**3.** En un push a `main` que no tocara código, `build` no entraría, `package` lo necesitaría y el pipeline **no se crearía**: error de creación, `main` sin pipeline. Con `optional: true` el pipeline se crearía y `package` empaquetaría sin que nada hubiera compilado ese commit: un paquete que nadie ha comprobado. El error de creación es la señal correcta de que las reglas de los dos jobs dejaron de estar alineadas; `optional` es para jobs que legítimamente pueden faltar.

**4.** El hijo no nace y el job de disparo falla. En el hijo `CI_PIPELINE_SOURCE` vale siempre `parent_pipeline`, así que la regla de `merge_request_event` no coincide, y en un pipeline de merge request no hay `CI_COMMIT_BRANCH`, así que tampoco las de rama. El hijo recibe las variables del proyecto (con las mismas reglas de protección), las del job de disparo, las globales del YAML del padre y las `CI_MERGE_REQUEST_*`. No recibe `default`, ni los jobs ocultos, ni los artefactos del padre.

**5.** Sin `strategy`, el job de disparo termina en verde en cuanto el hijo se crea, falle o no después. Con `depend`, refleja el estado del hijo, pero un job del hijo con `allow_failure: true` que falla cuenta como verde; está desaconsejado. Con `mirror` (18.2), el job refleja exactamente el estado del hijo y espera a que termine. Sin `mirror`, un `markdownlint` en rojo o una caducidad cercana no impedirían fusionar la merge request: *Pipelines must succeed* vería el padre en verde.

**6.** Cuando la lista de jobs depende de algo que solo se sabe al ejecutar: qué servicios de un monorepo cambiaron, datos externos. Con tres jobs fijos, un `parallel:matrix` o hijos estáticos con `rules:changes` son legibles y validables antes de empujar. Con un generador, el revisor ve el script, no los jobs que produce; quien puede cambiar el generador puede añadir cualquier job al pipeline. Por eso el generador tiene que estar en `CODEOWNERS` con el mismo dueño que `.gitlab-ci.yml`.

**7.** Con la identidad de quien creó el pipeline de `main` de `app`: quien fusionó la merge request. Necesita poder ejecutar pipelines en `infra/entornos` (Developer o más), poder fusionar en `main` de `infra/entornos` si está protegida, y el rol mínimo de variables de pipeline de `infra/entornos`, porque el disparo pasa variables. Si esa persona se va y su usuario se bloquea, los disparos que dependan de ella fallan; el pipeline de `app` ya creado no se recrea. Es el mismo problema que el propietario de un programado.

**8.** No lo rechazaron los permisos del usuario, que es miembro de `app`, sino la lista de permitidos del job token de `app`: el job token venía de `infra/entornos`, que no estaba en ella. (Si el usuario no fuera miembro de `app`, el `GET` devolvería `404`: GitLab no confirma que existe un proyecto privado a quien no puede verlo.) La lista que se cambió es la de **`app`**, el proyecto al que se accede: la lista de permitidos de entrada dice "estos proyectos pueden usar su job token contra mí". Quien descarga es `infra/entornos`, pero es `app` quien decide quién le lee. Además, el usuario detrás del job token tiene que ser miembro de `app`.

**9.** Porque mientras `infra/entornos` se ejecuta, el pipeline de `app` que lo disparó sigue en marcha (esperando a `infra` por `mirror`): el último pipeline **terminado** de `main` es el anterior, y "el último artefacto" sería el paquete viejo, sin ningún error. El ID del job, pasado por `dotenv` y las variables del disparo, identifica este paquete exacto. Todo eso sustituye a `needs:project`, que es Premium y descarga artefactos de otro proyecto desde el YAML.

**10.** `interruptible: false` impide que un commit nuevo corte un despliegue a la mitad; `resource_group` impide que dos despliegues al mismo entorno corran a la vez, que es lo que deja `staging` con la versión vieja si el despliegue viejo termina el último. `newest_first` deja pasar primero al más nuevo, y **Prevent outdated deployment jobs** hace fallar al viejo cuando le toca en lugar de desplegarlo encima. En `production`, manual, rara vez hay dos en cola. Un programado sobre `main` cumple todas las reglas de `main`, y en un pipeline que no es de push ni de merge request `rules:changes` es siempre verdadero: sin `.fuera-de-programados`, cada mañana se desplegaría `staging` y se dispararía `infra/entornos`.

</details>

---

## 💪 Desempeño (40%)

| Práctica | Qué se comprueba | Puntos |
|---|---|:--:|
| [01 — De stages a DAG](2-practicas/01-de-stages-a-dag.md) | Tres medidas; `needs` en los cinco jobs; el error de `ci/lint` visto; `concurrent = 2` | 10 |
| [02 — Un pipeline hijo para la documentación](2-practicas/02-un-pipeline-hijo-para-la-documentacion.md) | Fechas reales en `docs/secretos.md`; `caducidades.sh` probado con éxito y con fallo; el hijo en verde y la merge request rota bloqueada y cerrada | 10 |
| [03 — El disparo a `infra`](2-practicas/03-disparo-a-infra.md) | `infra/entornos` restringido; el `403` antes de la lista; el registro con el `sha` de `main` y los dos pipelines en verde | 10 |
| [04 — Concurrencia y calendario](2-practicas/04-concurrencia-y-calendario.md) | Los candados; un `waiting_for_resource` visto; `staging` en `newest_first`; el programado con un solo job | 10 |

---

## 📦 Producto (30%)

### Verificable por API — 60 puntos

| Requisito | Comprobación | Puntos |
|---|---|:--:|
| `test` sin esperar | `test-no-espera-a-build` | 3 |
| `gobernanza` sin esperar | `gobernanza-no-espera` | 3 |
| `package` tras `build` y `test` | `package-espera-a-build-y-test` | 4 |
| `main` en verde | `ultimo-pipeline-de-main-en-verde` | 3 |
| Hijo de documentación | `hijo-de-documentacion` | 3 |
| Un hijo en verde | `pipeline-hijo-correcto` | 4 |
| `infra/entornos` | `infra-entornos-existe` | 3 |
| Variables restringidas en `infra/entornos` | `infra-variables-restringidas` | 3 |
| Disparo a `infra/entornos` | `disparo-a-infra` | 3 |
| Pipeline multiproyecto en verde | `pipeline-de-infra-desde-app` | 4 |
| Job token acotado | `job-token-de-app-acotado` | 3 |
| `infra/entornos` en la lista | `infra-en-la-lista-de-app` | 4 |
| Candados de despliegue | `resource-groups-de-despliegue` | 3 |
| `staging` en `newest_first` | `staging-despliega-lo-mas-nuevo` | 3 |
| Programado de caducidades | `programa-de-caducidades` | 3 |
| Programado en verde | `programado-en-verde` | 3 |
| Programados sin despliegue | `programados-sin-despliegue` | 4 |
| ADR-008 | `adr-008-topologia` | 4 |

### Calidad — 40 puntos

| Criterio | Qué se mira | Puntos |
|---|---|:--:|
| La medición es honrada | Tres medidas reales en `docs/metricas.md`, el DAG de un hueco sin maquillar y el camino crítico con tus segundos | 10 |
| El ADR-008 decide y descarta | Responde los siete puntos del proyecto, con el corte entre `app` e `infra` justificado por quién cambia qué | 10 |
| La identidad está nombrada | El ADR-008 dice con qué usuario se crean el disparo y el programado, y qué pasa cuando se va | 5 |
| La alarma se ensayó | Un programado en rojo con `AVISO_DIAS` y el siguiente en verde, con la variable borrada | 5 |
| La lista de permitidos es mínima | En `app`, solo `app` e `infra/entornos`; ningún grupo entero | 5 |
| Las fechas son las reales | La de `GOBERNANZA_TOKEN` en `docs/secretos.md` coincide con su `expires_at` | 5 |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Un token de proyecto o personal de `app` guardado en `infra/entornos` para leer el paquete | −20 |
| La restricción del job token de `app` desactivada al terminar | −20 |
| `infra/entornos` con variables de pipeline abiertas a Developer | −10 |
| `strategy` quitada del disparo a `infra` o del hijo para dejar `main` en verde | −15 |
| Un programado que despliega `staging` o dispara `infra/entornos` | −15 |
| `concurrent` por encima de 2 sin medir la memoria de la máquina | −5 |
| Un cambio en `main` de `app` sin merge request | −10 |
| El token de `revisor` sin revocar al terminar | −15 |

---

[← Volver a la Semana 11](README.md)

# Rúbrica de Evaluación — Semana 12

## 📊 Distribución de Evidencias

| Tipo | Peso | Instrumento | Quién juzga |
|---|:--:|---|---|
| 🧠 Conocimiento | 30% | 10 preguntas conceptuales, 10 pts cada una | Autoevaluación |
| 💪 Desempeño | 40% | Las 4 prácticas, 10 pts cada una | La API de tu instancia |
| 📦 Producto | 30% | La capa 12 de tu plataforma: 60 pts por API + 40 pts de calidad | Mixto |

**Criterio de aprobación: mínimo 70% en cada evidencia**, no en el promedio.

---

## 🧠 Conocimiento (30%)

| # | Pregunta |
|:--:|---|
| 1 | Partiste `.gitlab-ci.yml` con `include:local` y `diff` dijo que `merged_yaml` había cambiado. ¿Por qué eso no contradice que el pipeline sea el mismo, y qué comparación sí lo demuestra? |
| 2 | En el archivo principal redefines `rules` de un job que viene de `ci/deploy.yml` para añadirle una regla. ¿Qué reglas acaba teniendo el job y por qué? ¿Cómo lo harías bien, y por qué `extends` no resuelve el problema? |
| 3 | ¿Qué diferencia hay entre `include:project` sin `ref` y un componente con `@1`? Nombra tres cosas que tiene el componente y le faltan al `include`. |
| 4 | `$[[ inputs.x ]]` y `$X` parecen lo mismo. ¿Cuándo se sustituye cada uno, quién lo hace, y por qué un input puede ir en el nombre de un job y una variable no? |
| 5 | El componente `npm` llama a su job oculto `.componente-npm` y no `.npm`, y lleva su propia regla de fuera de programados en lugar de `!reference [.fuera-de-programados, rules]`. ¿Qué pasaría en `app` con cada una de las dos alternativas? |
| 6 | `gobernanza` descarga su script de `ci/componentes` en `$[[ component.sha ]]`. ¿Por qué no se queda el script en `app`, por qué no se descarga de `main`, y qué tuvo que cambiar en `ci/componentes` para que la descarga funcionara? |
| 7 | Publicas `v1.3.0` en vez de `1.3.0`. El catálogo la enseña. ¿Qué consumidores la reciben y cuáles no, y por qué este bootcamp usa `v` en las releases de `app` pero no en las de `ci/componentes`? |
| 8 | Un compañero renombra el input `build` a `comando` y publica `1.2.0`. ¿Qué le pasa a `app`, cuándo, y sin qué? ¿Qué número de versión tocaba y qué protección tenía `app` frente a ese cambio? |
| 9 | `infra/entornos` tiene `ci_pipeline_variables_minimum_override_role=maintainer` y recibe `entorno` como input. ¿Por qué el input no está sujeto a esa restricción y no es un agujero? ¿Por qué, aun así, no puedes pasar a `no_one_allowed`? |
| 10 | Pusiste `entorno` sin `default` y un push a `infra/entornos` creó un pipeline fallido, aunque su `workflow` solo acepta `pipeline`. ¿Por qué? ¿Qué `default` elegiste y por qué ese y no el otro? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** `merged_yaml` pone primero lo incluido y después el archivo principal: `.deploy`, los despliegues e `infra` suben al principio. El orden de las claves de un mapa YAML no cambia lo que se ejecuta: los jobs, sus `rules`, `needs` y `script` son los mismos. `diff` compara líneas en orden y ve un cambio; `diff <(sort antes) <(sort despues)` compara el conjunto de líneas, y vacío significa que no sobra ni falta ninguna. No es una prueba formal (dos líneas podrían cambiar de job), pero junto con la lista de jobs de `ci/lint` basta para una merge request que solo ordena.

**2.** Solo la nueva. La fusión de `include` es profunda en los mapas, pero una lista en los dos lados se sustituye entera por la del archivo principal: la regla de `.fuera-de-programados` y la de `main` desaparecen sin aviso, y el job entraría en los programados. Bien hecho: en el archivo principal no se toca el job; o, si hay que cambiarlo, se escribe la lista completa con `!reference [.fuera-de-programados, rules]` como primera regla y las demás detrás. `extends` tampoco ayuda: es la misma fusión profunda, y la lista del hijo sustituye a la del padre.

**3.** `include:project` sin `ref` lee la punta de la rama por defecto de otro proyecto: cambia cuando ese equipo empuja, sin merge request en tu lado, y no hay forma de saber qué parámetros acepta. Un componente tiene **contrato** (`spec:inputs`, con tipos, y error si sobra o falta algo), **versión con significado** (`@1` recibe las `1.x.y` publicadas, nunca una `2.0.0`) y **pruebas** en su propio pipeline antes de publicarse. Además, el catálogo lo hace encontrable, y el contexto `component.sha` le permite usar archivos de su propia versión.

**4.** `$[[ inputs.x ]]` lo sustituye el servidor al crear el pipeline, como texto, antes de evaluar `workflow` y `rules`. `$X` lo expande el shell del runner al ejecutar cada job, con las variables de ese job. El nombre de un job, su `stage` o sus `needs` se deciden al crear el pipeline, cuando ninguna variable de job existe todavía: ahí solo cabe algo que ya tenga valor, y eso es un input.

**5.** Con `.npm`, el componente se fusionaría con el `.npm` de cualquier consumidor que lo tuviera: un `app` a medio migrar acabaría con un job oculto mezcla de los dos, sin error. Con `!reference [.fuera-de-programados, rules]`, el componente solo funcionaría en proyectos que definan ese job oculto; en `ci/componentes` mismo, o en un proyecto nuevo, el pipeline no se crearía (`could not be found`). Un componente no sabe dónde va a vivir: nombres propios y todo lo que necesite, dentro.

**6.** En `app`, el script sería una copia por consumidor: la siguiente corrección llegaría a uno y no a los demás, y el YAML de una versión ejecutaría el script de otra. De `main`, la versión `1.0.0` ejecutaría código de `main` que nunca se publicó ni se probó como versión; con `component.sha` es el script exacto del commit publicado. La descarga va con el job token **del consumidor**, y `ci/componentes` es privado: hizo falta poner el grupo raíz en su lista de permitidos del job token. Si fuera interno funcionaría sin ella, a costa de que cualquier proyecto de la instancia pudiera leerlo sin figurar en ningún sitio.

**7.** La reciben quienes la piden entera, `@v1.3.0`. No la reciben `@1`, `@1.3` ni `@~latest`: las versiones parciales solo encuentran tags sin `v` (`@v1` da `content not found`). En `app`, el tag es la versión de un producto para personas, y la convención de la Semana 08 es `v1.2.0`; en `ci/componentes`, el tag es una dirección que resuelve GitLab, y su sintaxis de versiones parciales manda.

**8.** En el siguiente pipeline de `app`, cree quien lo cree, la creación falla con `unknown input arguments: build`, sin ningún commit en `app`. Renombrar un input es *major*: tocaba `2.0.0`, que `@1` no habría recibido hasta que alguien cambiara `app` a `@2` en una merge request. Frente a una *minor* mal numerada, `app` no tiene protección propia: la única está en `ci/componentes`, en su revisión y en su pipeline, que debería probar los inputs con valores distintos de los de por defecto.

**9.** La restricción es para **variables** de pipeline, que pueden tener cualquier nombre y cualquier valor, incluido uno que cambie el comportamiento de otro job. Un input solo existe si el YAML del proyecto lo declara, y solo toma los valores que permiten su tipo, sus `options` o su `regex`: lo que se puede pedir lo decide el propio `infra/entornos`. No puede pasar a `no_one_allowed` porque el disparo sigue llevando `APP_SHA`, `APP_PROJECT_ID` y `APP_PACKAGE_JOB_ID` como variables: sus valores solo existen al ejecutar, y `trigger:inputs` no expande variables, así que llegarían como texto.

**10.** Los inputs se validan al crear el pipeline, **antes** de evaluar `workflow:rules`: un push crea el pipeline sin inputs, el obligatorio falta y la creación falla con `required value has not been provided`, antes de que `workflow` pueda descartarlo. `default: staging`, porque es el menos peligroso: un lanzamiento sin parámetros nunca debería ir a `production`.

</details>

---

## 💪 Desempeño (40%)

| Práctica | Qué se comprueba | Puntos |
|---|---|:--:|
| [01 — `include` en `app`](2-practicas/01-include-en-app.md) | `ci/deploy.yml` incluido; el `diff` ordenado vacío; las reglas perdidas al redefinir la lista, vistas; `main` en verde | 10 |
| [02 — Los dos componentes](2-practicas/02-los-dos-componentes.md) | `ci/componentes` privado y con descripción; `npm` y `gobernanza`; `main` en verde con un test en el informe; los dos errores de un input mal pasado | 10 |
| [03 — Publicar y consumir](2-practicas/03-publicar-y-consumir.md) | Protecciones y `revisor` como Developer; `gobernanza` auditando a `ci/componentes`; `1.0.0` en el catálogo; `app` con `@1` y sin su script | 10 |
| [04 — Inputs en `infra`](2-practicas/04-inputs-en-infra.md) | El pipeline fallido por un input sin `default`, visto; `entorno` en el nombre y en el registro; los dos rechazos por API, en orden | 10 |

---

## 📦 Producto (30%)

### Verificable por API — 60 puntos

| Requisito | Comprobación | Puntos |
|---|---|:--:|
| Despliegue en su archivo | `despliegue-en-su-archivo` | 3 |
| `include` de `ci/deploy.yml` | `app-incluye-deploy` | 3 |
| `ci/componentes` | `componentes-existe` | 3 |
| Componente `npm` | `componente-npm` | 3 |
| Componente `gobernanza` | `componente-gobernanza` | 3 |
| `ci/componentes` se prueba en verde | `componentes-se-prueba` | 4 |
| En el catálogo | `componentes-en-el-catalogo` | 4 |
| Tags protegidos | `tags-de-componentes-protegidos` | 4 |
| Semver sin `v` | `versiones-semver-sin-v` | 4 |
| Dos versiones | `dos-versiones-publicadas` | 4 |
| El grupo lee `ci/componentes` | `grupo-lee-componentes` | 4 |
| `app` usa `npm` por versión | `app-usa-npm` | 3 |
| `app` usa `gobernanza` por versión | `app-usa-gobernanza` | 4 |
| `entorno` declarado | `infra-declara-entorno` | 3 |
| Disparo con inputs | `app-dispara-con-inputs` | 3 |
| `infra/entornos` sabe su entorno | `infra-sabe-su-entorno` | 4 |
| ADR-009 | `adr-009-ci-compartido` | 4 |

### Calidad — 40 puntos

| Criterio | Qué se mira | Puntos |
|---|---|:--:|
| `1.1.0` es una *minor* de verdad | El input nuevo tiene un `default` que conserva el comportamiento, y el pipeline de `ci/componentes` lo prueba con otro valor | 10 |
| El README sirve a un desconocido | Ejemplo de `include` con `@1`, tabla de inputs y lo que el consumidor pone de su parte, por componente | 10 |
| El ADR-009 decide y descarta | Responde los siete puntos del proyecto, con el momento en que existe cada dato del disparo | 10 |
| Los componentes no dependen de `app` | Sin `!reference` ni `extends` a nada del consumidor, sin claves globales, con ocultos de nombre propio | 5 |
| El secreto nuevo está inventariado | `GOBERNANZA_TOKEN` de `ci/componentes` en `docs/secretos.md` con su `expires_at` real | 5 |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| `ci/componentes` público o interno | −15 |
| `revisor` o cualquier otra persona con Maintainer en `ci/componentes` sin necesidad | −10 |
| Un consumidor con `@~latest` o con una rama | −10 |
| Una release publicada por API y no por el job `publicar` | −10 |
| `CI_SERVER_FQDN` sobrescrita fuera del job `publicar` | −10 |
| `infra/entornos` con variables de pipeline abiertas a Developer, o con `no_one_allowed` y el disparo en rojo | −10 |
| `scripts/gobernanza.sh` todavía en `app` | −5 |
| Un cambio en `main` de `app` o de `ci/componentes` sin merge request, salvo los de arranque de la práctica 02 y el CODEOWNERS de la práctica 03 | −10 |
| El token de `revisor` sin revocar al terminar | −15 |

---

[← Volver a la Semana 12](README.md)

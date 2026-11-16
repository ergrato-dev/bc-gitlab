# Rúbrica de Evaluación — Semana 16

## 📊 Distribución de Evidencias

| Tipo | Peso | Instrumento | Quién juzga |
|---|:--:|---|---|
| 🧠 Conocimiento | 30% | 10 preguntas conceptuales, 10 pts cada una | Autoevaluación |
| 💪 Desempeño | 40% | Las 4 prácticas, 10 pts cada una | La API de tu instancia |
| 📦 Producto | 30% | La capa 16 de tu plataforma: 60 pts por API + 40 pts de calidad | Mixto |

**Criterio de aprobación: mínimo 70% en cada evidencia**, no en el promedio.

---

## 🧠 Conocimiento (30%)

| # | Pregunta |
|:--:|---|
| 1 | El pod del gestor de `k8s-app` lleva una semana en `Running` y nunca ha ejecutado un `npm install`. ¿Dónde se ejecutan entonces los jobs, qué hace exactamente el gestor, y qué pasaría con los jobs en curso si borras su pod? |
| 2 | El `.gitlab-ci.yml` de `app` no cambió al pasar a Kubernetes. Nombra dos cosas que sí cambiaron para el `script` de un job, y explica por qué `probar-imagen` se queda en `dind-app` y `imagen` no. |
| 3 | Un compañero crea el clúster k3d sin `--network bc-gitlab-network` y pone `gitlabUrl: http://localhost:8888`. ¿Qué ve el gestor al arrancar, por qué, y qué otras dos cosas dejarían de funcionar aunque arreglara la URL? |
| 4 | El archivo de valores va a `infra/entornos` y el token no. ¿Dónde está el token, por qué `runners.config` no lleva `url` ni `token`, y qué tendrías que hacer si alguien pegara un `glrt-` en ese archivo y lo subiera? |
| 5 | Sin `rbac.rules`, el chart crea un rol que funciona. ¿Qué puede hacer con él el gestor que no necesita, y qué pasa si un atacante consigue el token de la cuenta de servicio del gestor en cada caso? |
| 6 | Un job pide `KUBERNETES_MEMORY_REQUEST: 2Gi` y el pod sale con `128Mi`. Otro pide `48Gi` y falla a los tres minutos con `runner_system_failure`. Explica los dos casos, y qué tiene que estar en `[runners.kubernetes]` para que el primero funcione. |
| 7 | Para que `app` no se coma el clúster, alguien propone una `ResourceQuota` de 4 pods en `gitlab-runner` en vez de bajar `concurrent`. ¿Qué pasa con el quinto job en cada caso? ¿Para qué sirve entonces una cuota en ese namespace? |
| 8 | En una nube, el clúster añade nodos cuando hay pods en `Pending`. ¿Qué parte de ese autoescalado tienes en k3d y cuál no, por qué añadir agentes a k3d no da más sitio, y qué valor del runner tendrías que revisar si el nodo nuevo tarda cuatro minutos? |
| 9 | Tu línea base dice 70 s antes y 46 s después, y los minutos de job son los mismos. ¿El CI es más barato? ¿En qué caso lo sería, y qué dato de `docs/finops.md` lo demuestra o lo desmiente? |
| 10 | La cuota de minutos de cómputo de GitLab es Premium. ¿Qué te daría, por qué no reduce el coste de un pipeline, y cómo sacas en CE los minutos de job de un runner en el último mes? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** Cada job corre en su propio pod (`runner-…-concurrent-<n>-…`), que el gestor crea al coger el job y borra al terminar. El gestor solo pide trabajo a GitLab, crea el pod con los contenedores `build`, `helper` y los de los servicios, ejecuta el `script` dentro por `exec` y sube el log. Si borras su pod, el Deployment crea otro (un gestor nuevo, con otro `system_id`), pero los jobs en curso pierden al proceso que los seguía y no terminan bien. Por eso un `helm upgrade` deja al pod viejo terminar sus jobs dentro de `terminationGracePeriodSeconds`.

**2.** No hay daemon de Docker: `docker build` no funciona sin `dind`. Y la caché local no existe, porque cada pod nace vacío: sin la caché S3 no se reutilizaría nunca. También cambia la red: el pod está en la red del clúster, que en el laboratorio llega a `gitlab`, `cache-s3` y `registry-cache` porque los nodos están en `bc-gitlab-network`. `probar-imagen` necesita un daemon y llevar `dind` al clúster es dar pods privilegiados a todo el namespace; kaniko construye sin privilegios, así que `imagen` se va a Kubernetes con el resto.

**3.** El gestor, dentro de un pod, resuelve `localhost` como el propio pod: no hay nada en el 8888 y `verify` falla con conexión rechazada. Aunque pusiera la IP del host, los jobs no resolverían `cache-s3` (la caché fallaría con `no such host`) ni `gitlab:5050` (kaniko no podría subir), y `$CI_SERVER_URL`, que es `http://gitlab:8888`, no llegaría: `imagen` no tendría token del registry. Con `--network bc-gitlab-network` los nodos están en la red del compose y el DNS de Docker resuelve todo eso desde los pods.

**4.** El token está en el `Secret` `runner-token` del namespace `gitlab-runner`, que el chart monta en el pod del gestor. `runners.config` es solo el `[[runners]]` de ejecución: `url`, `token` y `executor` los añade el chart al arrancar, a partir de `gitlabUrl`, del `Secret` y del ejecutor por defecto. Si alguien sube un `glrt-`, borrarlo del archivo no basta: está en el historial. Hay que rotar el token (`POST /runners/:id/reset_authentication_token`), poner el nuevo en el `Secret` y reiniciar el gestor, y luego limpiar el archivo.

**5.** Sin reglas, el rol da todos los verbos sobre todos los recursos del grupo core del namespace: listar y leer cualquier `Secret`, cambiar `ConfigMaps`, borrar el gestor y sus `Services`. Con `rbac.rules`, solo crear y borrar pods, crear y leer por nombre secretos (sin listarlos), `exec`/`attach` y leer logs y eventos. Con el token de la cuenta de servicio, en el primer caso el atacante controla el namespace entero; en el segundo, menos, pero no poco: puede lanzar pods y leer `runner-token` y `cache-s3` si conoce sus nombres, porque viven en el mismo namespace. Las reglas recortan; aislar de verdad pide los jobs en otro namespace (`runners.jobNamespace`). En ningún caso alcanza nada fuera de `gitlab-runner`.

**6.** En el primero, el runner no tiene `memory_request_overwrite_max_allowed`: la variable se ignora sin avisar y el pod sale con el `memory_request` del runner. En el segundo, con el techo puesto, el pod se crea pero ningún nodo tiene 48 GiB: se queda en `Pending` con `Insufficient memory`, y a los `poll_timeout` (180 s por defecto) el gestor se rinde con `timed out waiting for pod to start`. Para el primero: `memory_request_overwrite_max_allowed` (y `memory_limit_overwrite_max_allowed` si también sube el límite, porque un request mayor que el límite hace el pod inválido).

**7.** Con `concurrent = 4`, el quinto job espera en `pending` en GitLab y entra cuando acaba uno: nadie falla. Con la cuota, el gestor acepta el quinto job (tiene hueco en su `concurrent`), pide el pod, y Kubernetes lo rechaza con `exceeded quota`: el job falla con `runner_system_failure` y no vuelve a la cola. Una cuota en ese namespace sirve como seguro, muy por encima de `concurrent`, para que un error de configuración del runner no ocupe el clúster entero.

**8.** En k3d tienes el autoescalado de pods: nacen con cada job y desaparecen al terminar, y sin jobs solo queda el gestor. No tienes el de nodos: nadie crea máquinas cuando hay pods en `Pending`. Añadir agentes no da sitio porque todos los nodos de k3d son contenedores en tu máquina y comparten su memoria. Si un nodo nuevo tarda cuatro minutos, `poll_timeout` (180 s por defecto) vence antes y el job falla: hay que subirlo por encima de lo que tarda el nodo.

**9.** No necesariamente. Los minutos de job, que es el trabajo que ocupa máquina, son los mismos: el pipeline acaba antes porque hace más cosas a la vez, no menos. Sería más barato si el clúster se apaga cuando no hay jobs (nodos que bajan a cero en una nube) y el runner fijo pagaba horas vacías: la segunda parte de la fórmula de la teoría 06. `docs/finops.md` lo demuestra o lo desmiente con las horas encendidas sin jobs frente a los minutos de job del mes.

**10.** Te daría un límite de minutos por grupo o proyecto en los runners de instancia: cuando se acaba, los jobs dejan de correr en ellos. No reduce el coste de un pipeline: lo corta cuando se agota el presupuesto. En CE, `GET /runners/:id/jobs` con su `duration` sumada, filtrando por `finished_at` del último mes, o `GET /projects/:id/jobs` con el mismo cálculo por runner.

</details>

---

## 💪 Desempeño (40%)

| Práctica | Criterio | Puntos |
|---|---|:--:|
| [01 — El clúster](2-practicas/01-el-cluster.md) | Clúster de dos nodos en `v1.35.10+k3s1` en `bc-gitlab-network`; `kubeconfig` aparte; un pod que llega a los cuatro servicios; `library/alpine` en el catálogo de `registry-cache`; el `Secret` `cache-s3` sin imprimir la clave | 10 |
| [02 — El runner en el clúster](2-practicas/02-el-runner-en-el-cluster.md) | `k8s-app` creado en pausa con `docker`; el token solo en el `Secret`; el chart `0.91.2` con un gestor `19.2.2`; GraphQL con `kubernetes` y `docker`; `can-i` con tres `yes` y tres `no` | 10 |
| [03 — El relevo](2-practicas/03-el-relevo.md) | Tres medidas con `docker-app` y tres con `k8s-app`, con la caché caliente y sin nada más en marcha; el relevo sin momento sin runner; `probar-imagen` en `dind-app`; la línea base por merge request | 10 |
| [04 — Escalar y medir](2-practicas/04-escalar-y-medir.md) | La cola con `concurrent = 2`; los fallos con la cuota, y la cuota borrada; los máximos de memoria y los minutos por runner apuntados; tu `concurrent` aplicado; `diff -B` vacío | 10 |

---

## 📦 Producto (30%)

### Verificable por API — 60 puntos

| Requisito | Comprobación | Puntos |
|---|---|:--:|
| `k8s-app` en línea con ejecutor Kubernetes | `runner-kubernetes-en-linea` | 5 |
| La versión fijada | `runner-kubernetes-en-version-fijada` | 4 |
| `docker-app` en pausa, no borrado | `docker-app-en-pausa` | 5 |
| Un solo runner activo para `docker` | `un-solo-runner-docker-activo` | 5 |
| `dind-app` intacto | `dind-sigue-en-linea` | 3 |
| `main` construye en Kubernetes | `main-en-kubernetes` | 6 |
| La línea base versionada | `linea-base-versionada` | 6 |
| La línea base compara los dos runners | `linea-base-compara-runners` | 6 |
| La línea base en verde | `linea-base-en-verde` | 4 |
| Los values en `infra/entornos` | `values-en-infra` | 5 |
| Los values sin secretos | `values-sin-secretos` | 5 |
| `docs/finops.md` | `finops-versionado` | 6 |

### Calidad — 40 puntos

| Criterio | Qué se mira | Puntos |
|---|---|:--:|
| `docs/finops.md` se puede rehacer | Precio real con enlace y fecha; coste por minuto, por pipeline y por mes con la cuenta a la vista; las horas sin jobs de un runner fijo frente a un clúster que baja a cero | 15 |
| La línea base es honrada | Caché caliente y calentamiento antes de cada lado; nada más en marcha; si los minutos de job no bajaron, el texto lo dice | 10 |
| `concurrent` está justificado | La cifra de los values es la de `docs/finops.md`, y sale de los máximos de memoria medidos y de la memoria libre | 10 |
| Los secretos se quedan en casa | Ningún `glrt-` ni la clave de `cache-s3` en repositorios, en `~/bc-s16` ni en el historial de la terminal; `~/.bc-gitlab-s16` en `600` | 5 |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Un token `glrt-` en cualquier repositorio, aunque se borrara después sin rotarlo | −20 |
| `docker-app` borrado en vez de pausado | −10 |
| `rbac.create: true` sin `rbac.rules` | −10 |
| Pods privilegiados en el clúster, o `dind` en `k8s-app` | −15 |
| El chart instalado sin `--version`, o un runner de otra serie | −10 |
| `k3d cluster create` sin `--image`, o una imagen sin versión fijada en los values | −5 |
| Un precio inventado o sin fuente en `docs/finops.md` | −10 |
| Un cambio en `main` de `app` sin merge request | −10 |

---

[← Volver a la Semana 16](README.md)

# Rúbrica de Evaluación — Semana 15

## 📊 Distribución de Evidencias

| Tipo | Peso | Instrumento | Quién juzga |
|---|:--:|---|---|
| 🧠 Conocimiento | 30% | 10 preguntas conceptuales, 10 pts cada una | Autoevaluación |
| 💪 Desempeño | 40% | Las 4 prácticas, 10 pts cada una | La API de tu instancia |
| 📦 Producto | 30% | La capa 15 de tu plataforma: 60 pts por API + 40 pts de calidad | Mixto |

**Criterio de aprobación: mínimo 70% en cada evidencia**, no en el promedio.

---

## 🧠 Conocimiento (30%)

| # | Pregunta |
|:--:|---|
| 1 | `docker-app`, `dind-app` y `deploy-infra` tienen tres tokens distintos y el mismo `system_id`. ¿Qué es cada una de las dos cosas, qué pasa con los tres runners si reinicias el contenedor `gitlab-runner`, y qué pasa si copias el token de `dind-app` a otra máquina? |
| 2 | Tu `config.toml` tiene `concurrent = 3`, y los `limit` de los tres runners suman 5. ¿Es un error? ¿Qué protege cada número, y qué pasaría con una cola de diez jobs de `app` y un despliegue si `docker-app` no tuviera `limit`? |
| 3 | Cambias `tag_list` en el bloque de `dind-app` de `config.toml` y el runner sigue cogiendo lo mismo. ¿Por qué, qué otras tres cosas de un runner tampoco se cambian en ese archivo, y qué ganas con que estén en GitLab y no en tu máquina? |
| 4 | Un compañero propone el ejecutor `shell` para `dind-app`, "así no hace falta `dind`, se usa el Docker del host". ¿Qué alcanzaría entonces el `script` de un job de una rama cualquiera de `app`, y por qué es peor que montar el socket del host en un contenedor? |
| 5 | Un job de `app` con `tags: [docker, linux]` se queda en `pending` y `docker-app` está `online` con `tag_list: [docker]` y `run_untagged: true`. ¿Por qué no lo coge, y qué dos cambios distintos lo arreglarían? ¿Cuál es mejor? |
| 6 | Las variables de despliegue de `infra/entornos` ya estaban protegidas en la Semana 14. ¿Qué añade un runner `ref_protected`, si una rama sin proteger ya no podía leer `DEPLOY_SSH_KEY`? Pon un ejemplo de algo que una rama podía hacer en `docker-app` y no puede hacer en `deploy-infra`. |
| 7 | Eres administrador de tu instancia y ves `-protected` en la clave de caché de un job de `feat/add-late-fee`, que no está protegida. ¿Falla la separación de cachés? ¿Qué vería un Developer, y qué ataque evita esa separación? |
| 8 | `dind-app` tiene `privileged = true`, pero `probar-imagen` imprime `job sin privilegios`. ¿Qué parte del job es privilegiada y cuál no, por qué el cliente `docker` no necesita privilegios, y qué pasa si el job pide `docker:29.9-dind`? |
| 9 | Con `Shared = true`, `deploy-infra` baja la caché que subió `docker-app`. ¿Qué separa entonces la caché de `app` de la de `infra/entornos`, y por qué las credenciales de `cache-s3` no llegan nunca al `script` de un job? |
| 10 | Rotas el token de `dind-app` por API y te vas a comer. ¿Qué encuentras al volver, por qué la caducidad automática de los tokens no tiene ese problema, y qué parte de la flota no puedes reconstruir desde `runners/config.toml.plantilla`? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** El token es la identidad de cada runner ante GitLab: con él, el proceso pide trabajo en nombre de ese runner, y GitLab aplica sus etiquetas, su alcance y su protección. El `system_id` identifica al proceso que presenta los tokens, el gestor; tres runners con el mismo `system_id` son tres identidades de un solo proceso. Reiniciar el contenedor detiene a los tres a la vez y mata los jobs que estén corriendo en cualquiera de ellos, por eso se pausan y se espera a `idle`. Si copias el token de `dind-app` a otra máquina, GitLab ve un runner con dos gestores: cualquiera de las dos máquinas puede coger sus jobs, cada una con su propio `config.toml`, y deja de ser cierto que `dind` tiene el privilegio limitado, porque esa otra máquina puede no tener las listas.

**2.** No es un error. `concurrent` protege la máquina: nunca más de tres jobs a la vez en total, que es lo que caben en 16 GB con GitLab al lado. Cada `limit` reparte esos tres huecos: `docker-app` nunca ocupa más de dos, así que siempre queda uno para `dind-app` o `deploy-infra`. Que la suma pase de `concurrent` permite que, cuando un runner está ocioso, los otros usen sus huecos. Sin `limit` en `docker-app`, una cola de diez jobs de `app` ocuparía los tres huecos, y el despliegue esperaría detrás de los tests con el `resource_group` sin poder avanzar.

**3.** Con un token `glrt-`, lo que decide qué jobs coge un runner vive en GitLab: el proceso no lee `tag_list` del archivo, y por eso `register` se niega a recibirlo. Tampoco se cambian ahí `run_untagged`, `locked`, `access_level` ni `maximum_timeout`. Ganas que esas decisiones se puedan auditar por API (las comprobaciones de esta semana miran precisamente eso) y que quien opera la máquina no pueda, editando un archivo, hacer que el runner de despliegue acepte ramas sin proteger. Lo que sí está en `config.toml` es cómo se ejecuta: ejecutor, imagen, privilegios, caché, límites.

**4.** Con `shell`, el `script` corre en el host como el usuario del proceso: lee `config.toml` con los tokens de los tres runners y la clave de `cache-s3`, ve el sistema de archivos del host y lo que dejó el job anterior, y con acceso al Docker del host puede hacer `docker run -v /:/host` y ser root. Es peor que montar el socket en un contenedor porque ni siquiera hay contenedor: no hay imagen por job, no hay limpieza entre jobs, y los tokens del runner están a un `cat` de distancia. `dind` aísla el daemon del job del de tu máquina; `shell` le da la tuya.

**5.** Un runner coge un job solo si **todas** las etiquetas del job están en las suyas; el runner puede tener más, el job no. El job pide `linux` y `docker-app` no la tiene. Se arregla quitando `linux` del job, o añadiendo `linux` a `docker-app` con `PUT /runners/:id`. Lo segundo vale si `linux` describe una capacidad real que otros jobs pedirán; si nadie más la usa, lo primero: una etiqueta que no separa a ningún runner de otro solo añade una forma de quedarse en `pending`. `run_untagged` no entra: el job sí lleva etiquetas.

**6.** Las variables protegidas impiden **leer** un secreto; el runner protegido impide **ejecutarse** en la máquina que despliega. En `docker-app`, una rama cualquiera podía escribir la caché que luego restaura `main`, ocupar los dos huecos con un job eterno para que `production` esperase, o hacer un `curl` a `destino:8080` desde la red del runner. Nada de eso requiere `DEPLOY_SSH_KEY`. En `deploy-infra` no llega ningún job que no venga de una rama o tag protegido, es decir, que no haya pasado por la revisión que exige esa protección; un intento se queda en `pending` sin ejecutar una línea.

**7.** No falla. La clave lleva `-protected` si el pipeline es de una ref protegida **o** si quien lo lanza tiene el permiso `use_protected_cache`, y un administrador tiene todos los permisos. Un Developer que lanzara ese mismo pipeline vería `-non_protected`. La separación evita el envenenamiento de caché: que una rama sin revisar escriba, por ejemplo, un `node_modules` o un `.npm` manipulado bajo la misma clave que `main` restaura después, y que el código de `main` se ejecute con dependencias que nadie revisó. Con sufijos distintos, cada lado escribe y lee lo suyo.

**8.** El servicio `docker:29.9.3-dind` es privilegiado; el contenedor del `script`, `docker:29.9.3-cli`, no. `allowed_privileged_services` y `allowed_privileged_images` limitan el `privileged = true` del runner a las imágenes de la lista. El daemon necesita privilegios para crear contenedores (cgroups, espacios de nombres, `iptables`); el cliente solo habla con él por TCP en el puerto 2376 con TLS, y eso no requiere nada especial. Si el job pide `docker:29.9-dind`, que no está en la lista, el servicio arranca sin privilegios, el daemon no puede iniciarse y el job falla con `Cannot connect to the Docker daemon at tcp://docker:2376`: las listas también fijan la versión.

**9.** La ruta del objeto: `runner-cache/project/<id>/<clave>`. Cada proyecto tiene su prefijo y un job solo pide claves de su proyecto, así que `Shared = true` comparte entre **runners**, no entre proyectos. Las credenciales están en `config.toml`, en el proceso; para cada job, el proceso firma una URL que caduca y se la da al contenedor auxiliar, que es quien sube y baja `cache.zip`. El `script` del job no ve la clave ni la URL, y aunque la viera, la URL solo sirve para ese objeto y por poco tiempo.

**10.** `dind-app` sin coger jobs: el token viejo murió en el instante de la rotación, el proceso pide trabajo con él y recibe `403`, y `probar-imagen` se queda en `pending`, con lo que `imagen` no publica. Por eso la rotación manual se hace en un solo bloque: pedir el token y escribirlo en `config.toml`. Con caducidad, el proceso renueva el token por su cuenta antes de que venza y se reescribe el `config.toml`: no hay un momento en que GitLab y el archivo discrepen. La plantilla reconstruye todo el archivo menos sus secretos: los tokens (hay que crear o rotar los runners y sustituirlos) y la clave de `cache-s3`, que vive en `.env`; tampoco reconstruye lo que vive en GitLab, como las etiquetas o el `ref_protected`, que se recrean con los `POST /user/runners` de las prácticas.

</details>

---

## 💪 Desempeño (40%)

| Práctica | Criterio | Puntos |
|---|---|:--:|
| [01 — La caché compartida](2-practicas/01-la-cache-compartida.md) | `cache-s3` con clave propia; `concurrent = 3` y `docker-app` con `limit = 2` y caché S3 compartida; un job que sube y otro que baja; la clave con su índice tras vaciar | 10 |
| [02 — El runner dind](2-practicas/02-el-runner-dind.md) | `dind-app` bloqueado y solo con etiqueta; un proceso para los dos; el privilegio limitado al servicio y `job sin privilegios` en el log; `probar-imagen` en verde antes de `imagen`; `app` sin runners de instancia | 10 |
| [03 — El runner protegido](2-practicas/03-el-runner-protegido.md) | `deploy-infra` de grupo, `ref_protected` y 900 s; `infra/entornos` solo con él; `staging` desplegado desde él; el job de rama sin proteger en `pending`, cancelado y su rama borrada | 10 |
| [04 — Operar la flota](2-practicas/04-operar-la-flota.md) | La pausa con un pipeline en marcha; el token rotado con los tres `is valid`; `prueba-baja` fuera de `config.toml`; la plantilla que reconstruye el archivo idéntico; la caducidad de los tokens nuevos | 10 |

---

## 📦 Producto (30%)

### Verificable por API — 60 puntos

| Requisito | Comprobación | Puntos |
|---|---|:--:|
| `docker-app` en línea | `docker-app-en-linea` | 3 |
| Un proceso para los runners de `app` | `una-gestora-para-app` | 4 |
| La versión fijada | `flota-en-version-fijada` | 3 |
| `dind-app` en línea | `dind-en-linea` | 3 |
| `dind-app` solo con etiqueta | `dind-solo-etiquetado` | 4 |
| `probar-imagen` en `dind-app` | `imagen-probada-en-dind` | 4 |
| `app` sin runners de instancia | `app-sin-runners-compartidos` | 3 |
| `deploy-infra` en línea | `deploy-en-linea` | 3 |
| `deploy-infra` solo para ramas protegidas | `deploy-solo-ramas-protegidas` | 5 |
| `deploy-infra` con tiempo máximo | `deploy-con-tiempo-maximo` | 3 |
| `infra/entornos` sin `docker-app` | `infra-sin-runners-de-proyecto` | 4 |
| `infra/entornos` sin runners de instancia | `infra-sin-runners-compartidos` | 3 |
| Un despliegue desde `deploy-infra` | `desplegar-en-runner-protegido` | 5 |
| La plantilla con caché S3 | `plantilla-con-cache-s3` | 3 |
| La plantilla sin secretos | `plantilla-sin-secretos` | 5 |
| ADR-012 | `adr-012-flota` | 5 |

### Calidad — 40 puntos

| Criterio | Qué se mira | Puntos |
|---|---|:--:|
| El ADR-012 explica la flota | Con leerlo se sabe qué runner coge cualquier job de `app` o de `infra/entornos`; responde los seis puntos del proyecto y descarta tres alternativas con su porqué | 10 |
| Los números sostienen la caché | Una medida en frío y dos calientes de `build`, con la línea del log que prueba cada una, y lo que ha ejecutado cada runner | 10 |
| `config.toml` dice lo que dice el ADR | `concurrent` y los tres `limit` coinciden, justificados con la memoria de la máquina; las listas de privilegiados con la versión exacta; la plantilla reconstruye el archivo sin diferencias | 10 |
| La protección se probó | El job de la práctica 03, paso 6, quedó en `pending`; su rama está borrada; `deploy-infra` no tiene ningún job de una ref que no sea `main` | 5 |
| Los secretos se quedan en casa | Ningún token `glrt-` ni la clave de `cache-s3` fuera de `~/.bc-gitlab*` y `.env`; las copias de `config.toml` borradas o con `chmod 600` | 5 |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Un token `glrt-` en cualquier repositorio, aunque se borrara después sin rotarlo | −20 |
| `/var/run/docker.sock` montado en los jobs de cualquier runner | −20 |
| `privileged = true` en `docker-app` o en `deploy-infra` | −15 |
| `dind-app` sin las listas de privilegiados | −10 |
| `deploy-infra` con `run_untagged = true` o sin `ref_protected` | −15 |
| `RUNNER_CACHE_SECRET_KEY` con el valor de `.env.example` | −10 |
| El puerto de `cache-s3` publicado en el host | −5 |
| Un `.gitlab-ci.yml` de ejemplo sin `rules`, o una imagen sin versión fijada | −5 |
| Un cambio en `main` de `app` sin merge request | −10 |

---

[← Volver a la Semana 15](README.md)

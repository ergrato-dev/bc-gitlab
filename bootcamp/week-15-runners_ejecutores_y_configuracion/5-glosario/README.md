# 📖 Glosario — Semana 15

Términos que aparecen esta semana. El nombre real de la feature va en inglés entre paréntesis, y el **tier** cuando aplica.

El glosario acumulado de toda la plataforma está en [glosario-global](../../../docs/glosario-global.md).

---

## A

**`access_level`** — Free. Atributo de un runner: `not_protected` (coge jobs de cualquier ref) o `ref_protected` (solo de ramas y tags protegidos). Se fija en GitLab, no en `config.toml`.

**`allowed_privileged_images` / `allowed_privileged_services`** — Claves de `[runners.docker]` que limitan `privileged = true` a las imágenes o servicios de la lista. Con `["docker:29.9.3-dind"]` en las dos, el daemon es privilegiado y el `script` del job no.

## C

**Caché distribuida** (*Distributed cache*) — Free. Caché de runner guardada en un almacén S3, GCS o Azure en vez de en un volumen local. Con `Shared = true`, todos los runners contra el mismo bucket comparten la caché de cada proyecto.

**`concurrent`** — Clave global de `config.toml`: jobs a la vez en todo el proceso, sumando todos sus runners. Por defecto, `1`.

**`config.toml`** — El archivo de configuración del proceso `gitlab-runner`. Lleva los tokens de sus runners: nunca va a un repositorio.

## D

**Docker in Docker** (`dind`) — Un daemon de Docker que corre como servicio de un job, en un contenedor privilegiado, para jobs que necesitan `docker build` o `docker run`. Con TLS escucha en el puerto 2376.

**Docker Autoscaler** — Free. Ejecutor que crea máquinas virtuales según la cola y corre los jobs en contenedores dentro de ellas. Sustituye a Docker Machine, abandonado.

## E

**Ejecutor** (*Executor*) — Lo que crea el entorno donde corre cada job: `shell`, `docker`, `docker-autoscaler`, `instance`, `kubernetes`, `custom` y otros. Decide qué alcanza el `script`.

**Entorno protegido** (*Protected environment*) — Premium. Restringe quién puede desplegar en un entorno. En CE, el sustituto es la rama protegida de `infra/entornos` más el runner `ref_protected` de esta semana.

## G

**Gestor de runner** (*Runner manager*) — Free. Cada proceso que presenta el token de un runner. Se identifica por su `system_id`; un runner puede tener varios, y un proceso puede ser el gestor de varios runners.

## L

**`limit`** — Clave de un `[[runners]]`: jobs a la vez de ese runner. `0` es sin límite propio, solo el de `concurrent`.

**`locked`** — Free. Un runner de proyecto bloqueado no puede asignarse a otros proyectos. No frena a un administrador.

**Long polling** — GitLab retiene abierta la petición `POST /jobs/request` de un runner un tiempo por si aparece un job. Con `request_concurrency = 1`, el runner no pide otro mientras tanto.

## M

**`maximum_timeout`** — Free. Tiempo máximo de cualquier job en ese runner, en segundos, mínimo 600. Si es menor que el del proyecto o el del job, gana.

## P

**Panel de la flota de runners** (*Runner fleet dashboard*) — Ultimate. Vista de uso, colas y tiempos de espera de los runners. Sustituto en CE: la API de runners y, desde la Semana 21, Prometheus y Grafana.

**Plantilla de configuración** — En este bootcamp, `runners/config.toml.plantilla` de `infra/entornos`: el `config.toml` con los tokens y la clave S3 sustituidos por `${…}`. `envsubst` la convierte en el archivo real.

## R

**`request_concurrency`** — Clave de un `[[runners]]`: peticiones de trabajo abiertas a la vez. Por defecto, `1`.

**Runner** — La identidad, registrada en GitLab con su token `glrt-`, con la que un proceso pide jobs. Tiene tipo, etiquetas, protección y tiempo máximo.

**Runner de grupo** (*Group runner*) — Free. Lo crea un Owner del grupo y atiende a todos sus proyectos y subgrupos.

**Runner de instancia** (*Instance runner*, antes *shared runner*) — Free. Lo crea un administrador y atiende a todos los proyectos que no lo desactiven con `shared_runners_enabled = false`.

**Runner de proyecto** (*Project runner*) — Free. Lo crea un Maintainer, pertenece a un proyecto y puede asignarse a otros. Del dueño no se puede quitar: se borra.

**`run_untagged`** — Free. Si el runner coge jobs que no piden ninguna etiqueta.

## S

**SeaweedFS** — Almacén de objetos de código abierto con API S3. En este bootcamp, el servicio `cache-s3` en modo `weed mini`, que sustituye a MinIO.

**Separación de cachés** (*Separate caches for protected branches*) — Free. Ajuste del proyecto (`ci_separated_caches`, activo por defecto) que añade `-protected` o `-non_protected` a cada clave de caché, para que una rama sin proteger no escriba lo que restaura `main`.

**`system_id`** — Identificador de un proceso `gitlab-runner`, guardado en `.runner_system_id` junto a `config.toml`. Tres runners con el mismo `system_id` comparten proceso.

## T

**Token de autenticación de runner** (*Runner authentication token*) — Free. El `glrt-…` que identifica a un runner. Se rota con `POST /runners/:id/reset_authentication_token`, y el viejo deja de valer al instante.

---

[← Volver a la Semana 15](../README.md)

# 📖 Glosario — Semana 01

Términos que aparecen esta semana. El nombre real de la feature va en inglés entre paréntesis, y el **tier** cuando aplica.

El glosario acumulado de toda la plataforma está en [glosario-global](../../../docs/glosario-global.md).

---

## A

**`@hashed`** — Esquema de almacenamiento de repositorios en disco. La ruta se deriva del SHA-256 del ID numérico del proyecto, no de su nombre: `@hashed/93/50/9350c2b0....git`. Permite renombrar proyectos sin mover nada y reparte la carga en el sistema de archivos.

**API v4** — La API REST de GitLab, bajo `/api/v4/`. Todo lo que hace la interfaz web pasa por aquí. Free.

## C

**CE** (*Community Edition*) — La edición de código abierto de GitLab, licencia MIT. Contiene solo funcionalidad libre. Es lo que usa este bootcamp.

**Chef** — El gestor de configuración que usa Omnibus por dentro. Es quien traduce `gitlab.rb` en los archivos de configuración reales cuando ejecutas `reconfigure`.

## E

**EE** (*Enterprise Edition*) — La edición que contiene además el código propietario. Sin licencia se comporta como Free, pero no es lo mismo que CE: el código de pago está presente aunque inactivo.

**`external_url`** — La única opción de `gitlab.rb` sin prefijo, y la más importante. De ella se derivan el puerto de escucha, las URL de los correos y las de clonado.

## G

**Gitaly** — El servicio que atiende **todas** las operaciones de Git. Ningún otro proceso toca el disco de los repositorios: le hablan por gRPC. Free.

**`gitlab-ctl`** — La herramienta de control de Omnibus: `status`, `restart`, `reconfigure`, `tail`. Se ejecuta dentro del contenedor.

**`gitlab.rb`** — El archivo único de configuración de Omnibus, en `/etc/gitlab/`. En este laboratorio se genera desde `GITLAB_OMNIBUS_CONFIG`.

**`gitlab-secrets.json`** — Archivo en `/etc/gitlab/` con las claves de cifrado de la instancia. **No entra en el backup** y sin él la restauración deja los secretos ilegibles.

**`GITLAB_OMNIBUS_CONFIG`** — Variable de entorno de la imagen de Docker cuyo contenido se inyecta en `gitlab.rb` en cada arranque. Es donde vive la configuración permanente del laboratorio.

**`glab`** — El CLI oficial de GitLab. Estable frente a los cambios de la interfaz web, que se mueven cada pocas versiones.

**`glpat-`** — El prefijo de un token personal de GitLab. GitLab detecta este patrón como secreto filtrado, así que nunca aparece en el material ni en un repositorio, ni siquiera inventado.

## H

**`/-/health`** — Endpoint de salud barato: confirma que el servidor web contesta. **Puede devolver `OK` con la base de datos caída.**

**Healthcheck** — La comprobación periódica que Docker ejecuta para decidir si un contenedor está sano. En el laboratorio usa `/-/health` con `start_period: 300s`.

## L

**`/-/liveness`** — Endpoint que comprueba que el proceso de la aplicación responde, sin mirar dependencias. En Kubernetes decide si reiniciar el pod.

## N

**Namespace** — El contenedor de un proyecto: puede ser un usuario o un grupo. `namespace.kind` distingue `user` de `group`, y en este bootcamp tiene que ser `group`.

**Nginx** — El proxy inverso que recibe todas las peticiones HTTP y sirve los archivos estáticos.

## O

**Omnibus** — El empaquetado que instala GitLab y todas sus dependencias bajo `/opt/gitlab`, aislado del sistema operativo.

## P

**Paginación** — La API devuelve 20 elementos por defecto y no avisa de que hay más. Se controla con `per_page` (máximo 100) y `page`; las cabeceras `X-Total` y `X-Total-Pages` dicen cuántos hay.

**Perfil** (*Compose profile*) — Agrupación de servicios en `docker-compose.yml`. En este laboratorio: `base`, `observabilidad` y `ha`, mutuamente excluyentes en memoria.

**Puma** — El servidor web que ejecuta GitLab Rails. Atiende la interfaz y la API. Trabaja con un número fijo de workers y threads.

## R

**`/-/readiness`** — Endpoint que comprueba las dependencias reales: base de datos, Redis y Gitaly. Con `?all=1` desglosa cada componente. **Es el que responde a "¿funciona?".**

**`reconfigure`** — `gitlab-ctl reconfigure`. Ejecuta Chef, regenera los archivos de configuración desde `gitlab.rb` y reinicia los procesos afectados. **GitLab no lee su configuración en caliente**: sin esto no ha pasado nada.

**Redis** — Caché y colas. La caché se puede perder; las colas no, porque contienen los trabajos pendientes de Sidekiq.

**`runit`** — El supervisor de procesos dentro del contenedor. Es quien mantiene vivos los siete procesos y quien responde a `gitlab-ctl`.

## S

**Scope** — El permiso que acota lo que puede hacer un token. `api` concede lectura y escritura completas; `read_api` solo lectura.

**Sidekiq** — El procesador de trabajos en segundo plano: correos, webhooks, creación de pipelines, estadísticas. Cuando "algo no ocurre" tras un push, el sospechoso es este.

## T

**Tier** — El plan de GitLab: Free (lo que incluye CE), Premium y Ultimate. Este bootcamp usa solo Free y sustituye el resto con herramientas libres.

**Token personal** (*personal access token*) — Credencial que actúa **como tú**, con todos tus permisos. Cómodo para tu terminal, inadecuado para automatización.

## V

**Volumen** (*named volume*) — Almacenamiento gestionado por Docker que sobrevive a `docker compose down`. Solo se destruye con `down -v`. El laboratorio usa tres: config, data y logs.

## W

**Workhorse** — El proceso que se sienta entre Nginx y Puma e intercepta lo pesado: `git clone`, `git push` por HTTP, subidas y descargas de archivos. Existe porque Rails es malísimo moviendo archivos grandes.

---

[← Volver a la Semana 01](../README.md)

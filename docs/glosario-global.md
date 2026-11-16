# 📖 Glosario Global

Términos de toda la plataforma. Complementa —no sustituye— el glosario de cada semana, que va más al detalle del tema de esa semana.

**Convención**: el nombre real de la feature va en inglés entre paréntesis. Es como lo encontrarás en `docs.gitlab.com`, en la API y en la interfaz cuando esté en inglés. La columna de tier dice si está en CE (**Free**) o si es de pago; cuando es de pago, este bootcamp usa un sustituto libre y lo indica.

---

## A

**Agente de Kubernetes** (*GitLab Agent for Kubernetes*, `agentk`) — Free. Proceso que corre dentro de tu clúster y mantiene una conexión saliente con GitLab. Permite GitOps sin exponer el API server del clúster a internet. Sustituye al método legado de "clúster por certificado".

**Alta disponibilidad** (*high availability*) — Arquitectura en la que la caída de un componente no tira el servicio. En GitLab implica al menos Gitaly replicado, PostgreSQL con réplica y un pooler de conexiones.

**Aprobación** (*approval*) — Free como botón y API, pero opcional: en CE no bloquea la fusión y el autor puede aprobar lo suyo. Las aprobaciones obligatorias son **Premium**; en CE lo que bloquea es un hilo sin resolver (S06), y desde la S07 un server hook exige `Approved-by:` y la auditoría por API comprueba quién aprobó.

**Artefacto** (*artifact*) — Free. Archivo o directorio que un job produce y GitLab guarda. Se pasa a jobs posteriores y se puede descargar. No confundir con la caché: el artefacto es un **resultado**, la caché es una **optimización**.

**Auto DevOps** — Free. Pipeline preconfigurado que detecta el lenguaje del proyecto y aplica build, test, escaneo y despliegue sin escribir `.gitlab-ci.yml`. Poco usado porque se asume de pago; no lo es.

## C

**Caché** (*cache*) — Free. Directorio que se restaura entre ejecuciones para no repetir trabajo (`.npm`, `.m2`). Su clave lleva el sufijo `-protected` o `-non_protected`, así que las ramas no protegidas no comparten caché con `main`. Si se pierde, el pipeline sigue funcionando: solo tarda más. Si un artefacto se pierde, el pipeline se rompe.

**Caché distribuida** (*distributed cache*) — Free. Caché de runner en un almacén S3 en vez de en un volumen local; con `Shared = true` la ven todos los runners del bucket. En este bootcamp, SeaweedFS en el servicio `cache-s3` (Semana 15).

**Catálogo CI/CD** (*CI/CD Catalog*) — Free. Índice de componentes publicados que otros proyectos pueden buscar y consumir por versión.

**CHANGELOG generado** (*changelog*) — Free. Notas de una versión que GitLab construye con los commits que llevan el trailer `Changelog:`, configurables con `.gitlab/changelog_config.yml`. `GET .../repository/changelog` las devuelve; `POST` las escribe en un archivo.

**Cherry-pick** — Free en la UI y la API, y comando de Git. Aplica los cambios de un commit sobre otra rama en un commit nuevo; con `git cherry-pick -x` el mensaje dice de qué commit viene.

**`CI_JOB_TOKEN`** — Free. Token que recibe cada job mientras corre, con los permisos de quien lanzó el pipeline y solo en los endpoints que lo aceptan. No lee aprobaciones ni diffs de una merge request.

**Clave de firma** (*signing key*) — Free. Clave SSH registrada con `usage_type` `signing` o `auth_and_signing`. Una clave registrada solo con uso `auth` **no verifica firmas**, y el uso no se puede cambiar después: hay que borrarla y registrarla otra vez.

**Commit verificado** (*verified commit*) — Free. Commit cuya firma GitLab ha validado y atado a una cuenta de la instancia. Exige cuatro cosas: firma criptográficamente válida, clave registrada **con uso de firma**, correo del committer perteneciente al dueño de la clave, y ese correo confirmado. Se consulta en `GET /projects/:id/repository/commits/:sha/signature`.

**Componente CI/CD** (*CI/CD component*) — Free. Unidad reutilizable de configuración de pipeline, versionada y publicada en el catálogo. Es la respuesta de GitLab al copiar y pegar YAML entre proyectos.

**CODEOWNERS** — Archivo que asigna dueños a rutas del repositorio; gana la última regla que coincide. En **Premium** GitLab lo muestra y puede exigir la aprobación del dueño; en CE no lo lee en absoluto. Aquí lo lee el script de auditoría `gobernanza` (S07), que en la S09 pasa a ser un job.

**Conventional Commits** — Convención de mensaje `tipo(ambito): resumen`. No es de GitLab, pero es lo que permite decidir la versión sin discutirla. El CHANGELOG lo genera GitLab a partir de otro trailer, `Changelog:` (S08).

**Compute quota** — Premium. Límite de minutos de cómputo por grupo o proyecto en los runners de instancia; cuando se acaba, los jobs dejan de correr en ellos. En CE, los minutos se sacan sumando `duration` de los jobs por API y se convierten en coste en `docs/finops.md` (Semana 16).

## D

**DAG** (*directed acyclic graph*) — Free. Pipeline en el que los jobs declaran sus dependencias con `needs` en vez de esperar a que termine la etapa entera. Es lo que convierte un pipeline en serie en uno paralelo.

**Dependency Proxy** — Free. Cache de imágenes de Docker Hub de cada grupo raíz, servida por tu propia instancia. Se usa con `${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/imagen:versión` (S13). Evita el rate limit de los pulls anónimos.

**Docker in Docker** (`dind`) — Un daemon de Docker como servicio de un job, en un contenedor privilegiado. Con `allowed_privileged_services` el privilegio se queda en el daemon y no llega al `script` (Semana 15).

**Deploy token** — Free. Credencial de proyecto o grupo para máquinas fuera de GitLab, con `read_registry` y `read_package_registry`. No ocupa un usuario y no puede subir a lo protegido (S13).

**Digest** — Hash del manifiesto de una imagen (`sha256:…`). Un tag se puede mover; un digest no. Lo que se despliega y se firma (S13, S20).

**DORA** (*DevOps Research and Assessment*) — Las cuatro métricas de referencia: frecuencia de despliegue, tiempo de entrega, tasa de fallo del cambio y tiempo de restauración. Los gráficos y la API de DORA son **Ultimate**; en CE se calculan desde la API de merge requests, releases e issues y se documenta la definición usada (S08).

## E

**Ejecutor** (*executor*) — Free. Cómo ejecuta un runner sus jobs: `shell`, `docker`, `kubernetes`, `docker-autoscaler`. Con `docker`, un contenedor limpio por job.

**Entorno** (*environment*) — Free. Destino con nombre al que se despliega (`staging`, `production`). Guarda el historial de despliegues y habilita la reversión. Los **entornos protegidos** son Premium.

**`extends` y `!reference`** — Free. Reutilizar claves de otro job: `extends` hereda con fusión profunda; `!reference [.job, clave]` copia una clave concreta, también de un archivo incluido, y sirve para componer listas (S12).

**Entorno protegido** (*protected environment*) — **Premium**. Limita quién despliega en un entorno, con aprobaciones opcionales. En CE: job manual solo en rama protegida y variable protegida con ámbito (Semana 10).

**Épica** (*epic*) — **Premium**. Agrupación de issues por encima del hito. En CE se aproxima con hitos y etiquetas.

**Error budget** — Presupuesto de fallo que deja un SLO. Si el SLO es 99.9 % mensual, el error budget es de unos 43 minutos al mes. Se gasta, no se evita.

**Ejecutor Kubernetes** (*Kubernetes executor*) — Free. Ejecutor de GitLab Runner que crea un pod por job en un clúster y lo borra al terminar. En este bootcamp, el runner `k8s-app` en un clúster k3d, instalado con el chart oficial de Helm (Semana 16).

## F

**Feature flag** — Free. Interruptor que activa o desactiva una funcionalidad en tiempo de ejecución sin desplegar. GitLab CE incluye el servicio completo, basado en Unleash.

## G

**Gestor de runner** (*runner manager*) — Free. Cada proceso que presenta el token de un runner, identificado por su `system_id`. Un proceso puede ser el gestor de varios runners (Semana 15).

**Gitaly** — Free. Servicio que atiende todas las operaciones de Git. Ningún otro componente toca el disco de los repositorios directamente.

**Gitaly Cluster** — Free. Varios nodos Gitaly replicados y coordinados por Praefect. Es alta disponibilidad de repositorios sin licencia de pago, y casi nadie lo sabe.

**GitLab Flow** — Modelo de ramas de GitLab: `main` como integración, ramas de funcionalidad cortas, y ramas de larga vida solo cuando hacen falta, de entorno o de release (`release/X.Y`). Su regla es *upstream first*: todo entra primero en `main`. Más simple que Git Flow, más disciplinado que trunk-based puro.

## H

**Hito** (*milestone*) — Free. Agrupación de issues y merge requests con fecha. En CE es el nivel de planificación más alto disponible.

## I

**`include`** — Free. Mete en el pipeline el YAML de otro archivo: del mismo proyecto, de otro, de una URL, una plantilla o un componente. Las listas definidas en los dos lados no se suman: gana la última (S12).

**Input** (*CI/CD input*) — Free. Parámetro tipado que un archivo o un componente declara en `spec:inputs` y que se sustituye al crear el pipeline. Un input de pipeline se pasa por API, con `trigger:inputs` o con `git push -o ci.input=`, y no cuenta para la restricción de variables de pipeline (S12).

## J

**Job** — Free. Unidad de ejecución de un pipeline. Corre en un runner, en su propio entorno, y puede terminar en éxito o fallo.

## K

**kaniko** — Construye imágenes desde un `Dockerfile` en un contenedor sin privilegios y sin daemon. El original se archivó en junio de 2025; el bootcamp usa el fork mantenido `osscontainertools/kaniko` (S13).

**k3d** — Herramienta que ejecuta k3s, una distribución ligera de Kubernetes, en contenedores de Docker. En este bootcamp, el clúster `bootcamp` en la red `bc-gitlab-network`: desde la Semana 16 ejecuta los jobs de `app`, y en la 25 recibe sus despliegues.

## L

**Línea base** (*baseline*) — La medida de antes de un cambio, versionada, contra la que se compara la de después. Duración, cola y minutos de job de tres pipelines con cada runner en `docs/linea-base-s16.json` (Semana 16).

## M

**Merge method** (*método de fusión*) — Free. `merge`, `rebase_merge` (semilineal) o `ff`. Decide si queda commit de fusión y si la rama tiene que contener la punta de `main`. Este bootcamp usa `rebase_merge` con squash por defecto (ADR-004, S06).

**Merge request** (*MR*) — Free. La propuesta de cambio de GitLab; el equivalente al pull request de GitHub. La diferencia no es solo de nombre: el MR es también la unidad a la que se enganchan pipelines, entornos y aprobaciones.

**Merge train** — **Premium**. Cola que prueba cada MR contra el resultado de fusionar los anteriores. En CE se mitiga exigiendo rebase antes de fusionar.

## O

**Omnibus** — Free. El empaquetado que mete GitLab y todas sus dependencias en un solo paquete. Su configuración vive en `/etc/gitlab/gitlab.rb` y se aplica con `gitlab-ctl reconfigure`.

## P

**Push rule** — **Premium**. Regla de servidor que rechaza los pushes que incumplen una política: commits sin firmar, mensajes que no encajan con una expresión regular, archivos demasiado grandes, secretos. En CE se sustituye con un server hook `pre-receive`, que actúa en el mismo punto del recorrido.

**Pages** (*GitLab Pages*) — Free. Alojamiento de sitios estáticos publicados desde un job de pipeline. Gratis también en instancias autohospedadas.

**Paquete genérico** (*Generic package*) — Free. Cualquier archivo en el registro de paquetes, con nombre y versión en la URL. `app` publica el suyo por SHA (S13).

**PgBouncer** — Pooler de conexiones para PostgreSQL. Con muchos procesos de GitLab, sin él PostgreSQL se queda sin conexiones antes de quedarse sin CPU.

**Pipeline** — Free. El conjunto de jobs que se ejecuta ante un evento: un push, un MR, una programación o un disparo externo.

**Pipelines must succeed** — Free. Ajuste del proyecto (`only_allow_merge_if_pipeline_succeeds`) que impide fusionar sin pipeline en verde. Un job con `allow_failure` que falla no lo impide.

**Política de limpieza** (*Cleanup policy*) — Free. Reglas por proyecto que borran tags del registry por expresión, número y antigüedad. Desactivada por defecto; nunca borra `latest` ni los tags protegidos. El disco lo libera después la recolección de basura (S13).

**Praefect** — Free. Coordinador de Gitaly Cluster. Enruta las escrituras, replica a los demás nodos y decide qué nodo es válido cuando uno se queda atrás.

**Protected branch** (*rama protegida*) — Free. Regla que restringe quién puede empujar, fusionar o forzar sobre una rama. Es el mecanismo de gobernanza de CE, con un límite: cualquier Maintainer puede quitarla, porque *Allowed to unprotect* es **Premium** (S07).

**Protected tag** (*tag protegido*) — Free. Regla que decide quién puede crear tags que coinciden con un patrón, como `v*`. Un tag protegido no se puede mover y solo se borra desde la UI o la API (S07).

## R

**Rails console** — Free. Consola interactiva de la aplicación (`gitlab-rails console`). El último recurso del administrador y la forma más rápida de romper la instancia. Solo lectura salvo que sepas exactamente qué haces.

**Rama de release** (*release branch*) — Rama de larga vida `release/X.Y` que contiene una versión menor y sus parches. Se protege como `main` y solo recibe arreglos llevados desde `main` con *cherry-pick*.

**Realm** — URL a la que el registry manda a pedir el token, en la cabecera del `401`. Sale de `external_url` y tiene que alcanzarla el cliente: dentro de un job del laboratorio, no lo hace (S13).

**Registry** (*Container Registry*) — Free. Registro de imágenes Docker integrado en cada proyecto, con políticas de limpieza por etiqueta y antigüedad.

**Release** — Free. Página de GitLab asociada a un tag, con notas, hitos, enlaces a assets y evidencia. Borrarla no borra el tag; publicarla exige poder crear el tag.

**Review app** — Free. Entorno efímero que se despliega por cada merge request y se destruye al cerrarlo.

**Runner** (*GitLab Runner*) — Free. Agente que ejecuta los jobs. Puede ser de instancia, de grupo o de proyecto, se registra con un *authentication token* (`glrt-`), y usar distintos ejecutores (shell, docker, kubernetes).

**Rules** — Free. Palabra clave que decide si un job se crea y en qué condiciones. Sustituye a `only`/`except`, que sigue funcionando pero ya no se recomienda.

**Secure file** (*project-level secure file*) — Free. Archivo cifrado del proyecto, descargable con `CI_JOB_TOKEN`. Sin protección ni ámbito: lo descarga cualquier Developer. Nunca para claves privadas (Semana 10).

## S

**SAST** (*static application security testing*) — **Ultimate** el nativo. Análisis del código sin ejecutarlo. En CE se implementa con Semgrep en un job propio.

**SBOM** (*software bill of materials*) — Inventario de todo lo que compone un artefacto. Se genera con Syft y se firma junto a la imagen.

**Scoped label** (*etiqueta con ámbito*) — **Premium**. Etiquetas mutuamente excluyentes con la sintaxis `clave::valor`. En CE el `::` se acepta en el nombre pero no impone nada; este bootcamp usa igualmente `clave::valor` (para que Premium la active sin renombrar) y vigila la exclusividad con el tablero y una comprobación por API (S05).

**SemVer** (*Semantic Versioning*) — Convención `MAYOR.MENOR.PARCHE`: rompe, añade, arregla. Con `MAYOR = 0` no hay contrato, y cada proyecto fija su regla por escrito.

**Server hook** — Free. Script que Gitaly ejecuta antes o después de cada cambio en un repositorio, venga de un `push`, de una fusión en la UI o de la API. Es lo único en CE que **bloquea de verdad** un cambio que no cumple una regla, y lo único que un Maintainer no puede quitar: se instala con `gitaly hooks set` desde el servidor (S07).

**Sidekiq** — Free. El procesador de trabajos en segundo plano de GitLab. Cuando las colas crecen, es el primer sitio donde mirar.

**SLO** (*service level objective*) — Objetivo numérico de calidad de servicio sobre un indicador medible. Sin número y sin ventana temporal no es un SLO, es una intención.

**Squash** — Free. Aplastar los commits de una rama en uno al fusionar. Lo crea el servidor, sin la firma del autor; su mensaje sale de `squash_commit_template` (S06).

**Stage** — Free. Grupo de jobs de un pipeline. Los stages van en orden y uno no empieza hasta que el anterior termina bien.

## T

**Tag anotado y firmado** (*annotated / signed tag*) — Tag que es un objeto propio con autor, fecha y mensaje; firmado con `git tag -s`. Las versiones de `app` lo son desde la S08. Por API, es anotado si `target` y `commit.id` difieren.

**Tag protegido del registry** (*Protected container tag*) — Free. Rol mínimo para subir y borrar los tags de imagen que cumplen una expresión. Los inmutables, que nadie puede tocar, son **Ultimate** (S13).

**Terraform state backend** — Free. GitLab puede almacenar el estado de Terraform, con bloqueo incluido, sin necesidad de S3 ni Terraform Cloud.

**Tier** — El plan de GitLab: Free (lo que incluye CE), Premium y Ultimate. Este bootcamp usa solo Free y sustituye el resto.

**Token de acceso de proyecto** (*project access token*) — Free en self-managed, Premium en GitLab.com. Token de un usuario bot que solo es miembro de un proyecto, con rol, scopes y caducidad. El job `gobernanza` de `app` usa uno de Reporter con `read_api`.

## V

**Value Stream Analytics** (*VSA*) — Free a nivel de proyecto, **Premium** a nivel de grupo. Mide cuánto tarda el trabajo en recorrer cada etapa desde el issue hasta producción.

**Variable de instancia** (*instance CI/CD variable*) — Free. Variable CI/CD que llega a todos los pipelines de la instancia y tiene prioridad sobre las predefinidas.

**Variable de tipo archivo** (*file type variable*) — Free. El runner escribe el valor en un archivo temporal fuera del repositorio y el job recibe la ruta. Para claves y certificados.

**Variable oculta** (*hidden variable*) — Free. Variable enmascarada cuyo valor ya no se puede ver en la interfaz ni en la API. Se marca al crearla y no se puede desmarcar.

**Variable protegida** (*protected variable*) — Free. Solo llega a pipelines de ramas y tags protegidos. El único atributo que impide que un secreto llegue a una merge request.

---

[← Volver a docs](README.md)

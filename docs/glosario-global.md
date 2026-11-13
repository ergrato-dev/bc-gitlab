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

**Caché** (*cache*) — Free. Directorio que se restaura entre ejecuciones para no repetir trabajo (`node_modules`, `.m2`). Si se pierde, el pipeline sigue funcionando: solo tarda más. Si un artefacto se pierde, el pipeline se rompe.

**Catálogo CI/CD** (*CI/CD Catalog*) — Free. Índice de componentes publicados que otros proyectos pueden buscar y consumir por versión.

**CHANGELOG generado** (*changelog*) — Free. Notas de una versión que GitLab construye con los commits que llevan el trailer `Changelog:`, configurables con `.gitlab/changelog_config.yml`. `GET .../repository/changelog` las devuelve; `POST` las escribe en un archivo.

**Cherry-pick** — Free en la UI y la API, y comando de Git. Aplica los cambios de un commit sobre otra rama en un commit nuevo; con `git cherry-pick -x` el mensaje dice de qué commit viene.

**Clave de firma** (*signing key*) — Free. Clave SSH registrada con `usage_type` `signing` o `auth_and_signing`. Una clave registrada solo con uso `auth` **no verifica firmas**, y el uso no se puede cambiar después: hay que borrarla y registrarla otra vez.

**Commit verificado** (*verified commit*) — Free. Commit cuya firma GitLab ha validado y atado a una cuenta de la instancia. Exige cuatro cosas: firma criptográficamente válida, clave registrada **con uso de firma**, correo del committer perteneciente al dueño de la clave, y ese correo confirmado. Se consulta en `GET /projects/:id/repository/commits/:sha/signature`.

**Componente CI/CD** (*CI/CD component*) — Free. Unidad reutilizable de configuración de pipeline, versionada y publicada en el catálogo. Es la respuesta de GitLab al copiar y pegar YAML entre proyectos.

**CODEOWNERS** — Archivo que asigna dueños a rutas del repositorio; gana la última regla que coincide. En **Premium** GitLab lo muestra y puede exigir la aprobación del dueño; en CE no lo lee en absoluto. Aquí lo lee el script de auditoría `gobernanza` (S07), que en la S09 pasa a ser un job.

**Conventional Commits** — Convención de mensaje `tipo(ambito): resumen`. No es de GitLab, pero es lo que permite decidir la versión sin discutirla. El CHANGELOG lo genera GitLab a partir de otro trailer, `Changelog:` (S08).

## D

**DAG** (*directed acyclic graph*) — Free. Pipeline en el que los jobs declaran sus dependencias con `needs` en vez de esperar a que termine la etapa entera. Es lo que convierte un pipeline en serie en uno paralelo.

**Dependency Proxy** — Free. Cache de imágenes de Docker Hub servida por tu propia instancia. Evita el rate limit de los pulls anónimos.

**DORA** (*DevOps Research and Assessment*) — Las cuatro métricas de referencia: frecuencia de despliegue, tiempo de entrega, tasa de fallo del cambio y tiempo de restauración. Los gráficos y la API de DORA son **Ultimate**; en CE se calculan desde la API de merge requests, releases e issues y se documenta la definición usada (S08).

## E

**Entorno** (*environment*) — Free. Destino con nombre al que se despliega (`staging`, `production`). Guarda el historial de despliegues y habilita la reversión. Los **entornos protegidos** son Premium.

**Épica** (*epic*) — **Premium**. Agrupación de issues por encima del hito. En CE se aproxima con hitos y etiquetas.

**Error budget** — Presupuesto de fallo que deja un SLO. Si el SLO es 99.9 % mensual, el error budget es de unos 43 minutos al mes. Se gasta, no se evita.

## F

**Feature flag** — Free. Interruptor que activa o desactiva una funcionalidad en tiempo de ejecución sin desplegar. GitLab CE incluye el servicio completo, basado en Unleash.

## G

**Gitaly** — Free. Servicio que atiende todas las operaciones de Git. Ningún otro componente toca el disco de los repositorios directamente.

**Gitaly Cluster** — Free. Varios nodos Gitaly replicados y coordinados por Praefect. Es alta disponibilidad de repositorios sin licencia de pago, y casi nadie lo sabe.

**GitLab Flow** — Modelo de ramas de GitLab: `main` como integración, ramas de funcionalidad cortas, y ramas de larga vida solo cuando hacen falta, de entorno o de release (`release/X.Y`). Su regla es *upstream first*: todo entra primero en `main`. Más simple que Git Flow, más disciplinado que trunk-based puro.

## H

**Hito** (*milestone*) — Free. Agrupación de issues y merge requests con fecha. En CE es el nivel de planificación más alto disponible.

## J

**Job** — Free. Unidad de ejecución de un pipeline. Corre en un runner, en su propio entorno, y puede terminar en éxito o fallo.

## M

**Merge method** (*método de fusión*) — Free. `merge`, `rebase_merge` (semilineal) o `ff`. Decide si queda commit de fusión y si la rama tiene que contener la punta de `main`. Este bootcamp usa `rebase_merge` con squash por defecto (ADR-004, S06).

**Merge request** (*MR*) — Free. La propuesta de cambio de GitLab; el equivalente al pull request de GitHub. La diferencia no es solo de nombre: el MR es también la unidad a la que se enganchan pipelines, entornos y aprobaciones.

**Merge train** — **Premium**. Cola que prueba cada MR contra el resultado de fusionar los anteriores. En CE se mitiga exigiendo rebase antes de fusionar.

## O

**Omnibus** — Free. El empaquetado que mete GitLab y todas sus dependencias en un solo paquete. Su configuración vive en `/etc/gitlab/gitlab.rb` y se aplica con `gitlab-ctl reconfigure`.

## P

**Push rule** — **Premium**. Regla de servidor que rechaza los pushes que incumplen una política: commits sin firmar, mensajes que no encajan con una expresión regular, archivos demasiado grandes, secretos. En CE se sustituye con un server hook `pre-receive`, que actúa en el mismo punto del recorrido.

**Pages** (*GitLab Pages*) — Free. Alojamiento de sitios estáticos publicados desde un job de pipeline. Gratis también en instancias autohospedadas.

**PgBouncer** — Pooler de conexiones para PostgreSQL. Con muchos procesos de GitLab, sin él PostgreSQL se queda sin conexiones antes de quedarse sin CPU.

**Pipeline** — Free. El conjunto de jobs que se ejecuta ante un evento: un push, un MR, una programación o un disparo externo.

**Praefect** — Free. Coordinador de Gitaly Cluster. Enruta las escrituras, replica a los demás nodos y decide qué nodo es válido cuando uno se queda atrás.

**Protected branch** (*rama protegida*) — Free. Regla que restringe quién puede empujar, fusionar o forzar sobre una rama. Es el mecanismo de gobernanza de CE, con un límite: cualquier Maintainer puede quitarla, porque *Allowed to unprotect* es **Premium** (S07).

**Protected tag** (*tag protegido*) — Free. Regla que decide quién puede crear tags que coinciden con un patrón, como `v*`. Un tag protegido no se puede mover y solo se borra desde la UI o la API (S07).

## R

**Rails console** — Free. Consola interactiva de la aplicación (`gitlab-rails console`). El último recurso del administrador y la forma más rápida de romper la instancia. Solo lectura salvo que sepas exactamente qué haces.

**Rama de release** (*release branch*) — Rama de larga vida `release/X.Y` que contiene una versión menor y sus parches. Se protege como `main` y solo recibe arreglos llevados desde `main` con *cherry-pick*.

**Registry** (*Container Registry*) — Free. Registro de imágenes Docker integrado en cada proyecto, con políticas de limpieza por etiqueta y antigüedad.

**Release** — Free. Página de GitLab asociada a un tag, con notas, hitos, enlaces a assets y evidencia. Borrarla no borra el tag; publicarla exige poder crear el tag.

**Review app** — Free. Entorno efímero que se despliega por cada merge request y se destruye al cerrarlo.

**Runner** (*GitLab Runner*) — Free. Agente que ejecuta los jobs. Puede ser compartido, de grupo o de proyecto, y usar distintos ejecutores (shell, docker, kubernetes).

**Rules** — Free. Palabra clave que decide si un job se crea y en qué condiciones. Sustituye a `only`/`except`, que sigue funcionando pero ya no se recomienda.

## S

**SAST** (*static application security testing*) — **Ultimate** el nativo. Análisis del código sin ejecutarlo. En CE se implementa con Semgrep en un job propio.

**SBOM** (*software bill of materials*) — Inventario de todo lo que compone un artefacto. Se genera con Syft y se firma junto a la imagen.

**Scoped label** (*etiqueta con ámbito*) — **Premium**. Etiquetas mutuamente excluyentes con la sintaxis `clave::valor`. En CE el `::` se acepta en el nombre pero no impone nada; este bootcamp usa igualmente `clave::valor` (para que Premium la active sin renombrar) y vigila la exclusividad con el tablero y una comprobación por API (S05).

**SemVer** (*Semantic Versioning*) — Convención `MAYOR.MENOR.PARCHE`: rompe, añade, arregla. Con `MAYOR = 0` no hay contrato, y cada proyecto fija su regla por escrito.

**Server hook** — Free. Script que Gitaly ejecuta antes o después de cada cambio en un repositorio, venga de un `push`, de una fusión en la UI o de la API. Es lo único en CE que **bloquea de verdad** un cambio que no cumple una regla, y lo único que un Maintainer no puede quitar: se instala con `gitaly hooks set` desde el servidor (S07).

**Sidekiq** — Free. El procesador de trabajos en segundo plano de GitLab. Cuando las colas crecen, es el primer sitio donde mirar.

**SLO** (*service level objective*) — Objetivo numérico de calidad de servicio sobre un indicador medible. Sin número y sin ventana temporal no es un SLO, es una intención.

**Squash** — Free. Aplastar los commits de una rama en uno al fusionar. Lo crea el servidor, sin la firma del autor; su mensaje sale de `squash_commit_template` (S06).

## T

**Tag anotado y firmado** (*annotated / signed tag*) — Tag que es un objeto propio con autor, fecha y mensaje; firmado con `git tag -s`. Las versiones de `app` lo son desde la S08. Por API, es anotado si `target` y `commit.id` difieren.

**Terraform state backend** — Free. GitLab puede almacenar el estado de Terraform, con bloqueo incluido, sin necesidad de S3 ni Terraform Cloud.

**Tier** — El plan de GitLab: Free (lo que incluye CE), Premium y Ultimate. Este bootcamp usa solo Free y sustituye el resto.

## V

**Value Stream Analytics** (*VSA*) — Free a nivel de proyecto, **Premium** a nivel de grupo. Mide cuánto tarda el trabajo en recorrer cada etapa desde el issue hasta producción.

---

[← Volver a docs](README.md)

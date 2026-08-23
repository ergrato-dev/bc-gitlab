# 📖 Glosario Global

Términos de toda la plataforma. Complementa —no sustituye— el glosario de cada semana, que va más al detalle del tema de esa semana.

**Convención**: el nombre real de la feature va en inglés entre paréntesis. Es como lo encontrarás en `docs.gitlab.com`, en la API y en la interfaz cuando esté en inglés. La columna de tier dice si está en CE (**Free**) o si es de pago; cuando es de pago, este bootcamp usa un sustituto libre y lo indica.

---

## A

**Agente de Kubernetes** (*GitLab Agent for Kubernetes*, `agentk`) — Free. Proceso que corre dentro de tu clúster y mantiene una conexión saliente con GitLab. Permite GitOps sin exponer el API server del clúster a internet. Sustituye al método legado de "clúster por certificado".

**Alta disponibilidad** (*high availability*) — Arquitectura en la que la caída de un componente no tira el servicio. En GitLab implica al menos Gitaly replicado, PostgreSQL con réplica y un pooler de conexiones.

**Artefacto** (*artifact*) — Free. Archivo o directorio que un job produce y GitLab guarda. Se pasa a jobs posteriores y se puede descargar. No confundir con la caché: el artefacto es un **resultado**, la caché es una **optimización**.

**Auto DevOps** — Free. Pipeline preconfigurado que detecta el lenguaje del proyecto y aplica build, test, escaneo y despliegue sin escribir `.gitlab-ci.yml`. Poco usado porque se asume de pago; no lo es.

## C

**Caché** (*cache*) — Free. Directorio que se restaura entre ejecuciones para no repetir trabajo (`node_modules`, `.m2`). Si se pierde, el pipeline sigue funcionando: solo tarda más. Si un artefacto se pierde, el pipeline se rompe.

**Catálogo CI/CD** (*CI/CD Catalog*) — Free. Índice de componentes publicados que otros proyectos pueden buscar y consumir por versión.

**Componente CI/CD** (*CI/CD component*) — Free. Unidad reutilizable de configuración de pipeline, versionada y publicada en el catálogo. Es la respuesta de GitLab al copiar y pegar YAML entre proyectos.

**CODEOWNERS** — Free para el archivo y la asignación automática de revisores; **Premium** para que la aprobación del propietario sea obligatoria. Aquí se usa la parte libre y la obligatoriedad se aproxima con un job y un server hook.

## D

**DAG** (*directed acyclic graph*) — Free. Pipeline en el que los jobs declaran sus dependencias con `needs` en vez de esperar a que termine la etapa entera. Es lo que convierte un pipeline en serie en uno paralelo.

**Dependency Proxy** — Free. Cache de imágenes de Docker Hub servida por tu propia instancia. Evita el rate limit de los pulls anónimos.

**DORA** (*DevOps Research and Assessment*) — Las cuatro métricas de referencia: frecuencia de despliegue, tiempo de entrega, tasa de fallo del cambio y tiempo de restauración. La **API de DORA es Premium**; en CE se calculan a mano desde la API y se documenta la definición usada.

## E

**Entorno** (*environment*) — Free. Destino con nombre al que se despliega (`staging`, `production`). Guarda el historial de despliegues y habilita la reversión. Los **entornos protegidos** son Premium.

**Épica** (*epic*) — **Premium**. Agrupación de issues por encima del hito. En CE se aproxima con hitos y etiquetas.

**Error budget** — Presupuesto de fallo que deja un SLO. Si el SLO es 99.9 % mensual, el error budget es de unos 43 minutos al mes. Se gasta, no se evita.

## F

**Feature flag** — Free. Interruptor que activa o desactiva una funcionalidad en tiempo de ejecución sin desplegar. GitLab CE incluye el servicio completo, basado en Unleash.

## G

**Gitaly** — Free. Servicio que atiende todas las operaciones de Git. Ningún otro componente toca el disco de los repositorios directamente.

**Gitaly Cluster** — Free. Varios nodos Gitaly replicados y coordinados por Praefect. Es alta disponibilidad de repositorios sin licencia de pago, y casi nadie lo sabe.

**GitLab Flow** — Modelo de ramas de GitLab: `main` siempre desplegable, ramas de funcionalidad cortas y ramas de entorno o etiquetas para promocionar. Más simple que Git Flow, más disciplinado que trunk-based puro.

## H

**Hito** (*milestone*) — Free. Agrupación de issues y merge requests con fecha. En CE es el nivel de planificación más alto disponible.

## J

**Job** — Free. Unidad de ejecución de un pipeline. Corre en un runner, en su propio entorno, y puede terminar en éxito o fallo.

## M

**Merge request** (*MR*) — Free. La propuesta de cambio de GitLab; el equivalente al pull request de GitHub. La diferencia no es solo de nombre: el MR es también la unidad a la que se enganchan pipelines, entornos y aprobaciones.

**Merge train** — **Premium**. Cola que prueba cada MR contra el resultado de fusionar los anteriores. En CE se mitiga exigiendo rebase antes de fusionar.

## O

**Omnibus** — Free. El empaquetado que mete GitLab y todas sus dependencias en un solo paquete. Su configuración vive en `/etc/gitlab/gitlab.rb` y se aplica con `gitlab-ctl reconfigure`.

## P

**Pages** (*GitLab Pages*) — Free. Alojamiento de sitios estáticos publicados desde un job de pipeline. Gratis también en instancias autohospedadas.

**PgBouncer** — Pooler de conexiones para PostgreSQL. Con muchos procesos de GitLab, sin él PostgreSQL se queda sin conexiones antes de quedarse sin CPU.

**Pipeline** — Free. El conjunto de jobs que se ejecuta ante un evento: un push, un MR, una programación o un disparo externo.

**Praefect** — Free. Coordinador de Gitaly Cluster. Enruta las escrituras, replica a los demás nodos y decide qué nodo es válido cuando uno se queda atrás.

**Protected branch** (*rama protegida*) — Free. Regla que restringe quién puede empujar, fusionar o forzar sobre una rama. Es el mecanismo de gobernanza de CE.

## R

**Rails console** — Free. Consola interactiva de la aplicación (`gitlab-rails console`). El último recurso del administrador y la forma más rápida de romper la instancia. Solo lectura salvo que sepas exactamente qué haces.

**Registry** (*Container Registry*) — Free. Registro de imágenes Docker integrado en cada proyecto, con políticas de limpieza por etiqueta y antigüedad.

**Review app** — Free. Entorno efímero que se despliega por cada merge request y se destruye al cerrarlo.

**Runner** (*GitLab Runner*) — Free. Agente que ejecuta los jobs. Puede ser compartido, de grupo o de proyecto, y usar distintos ejecutores (shell, docker, kubernetes).

**Rules** — Free. Palabra clave que decide si un job se crea y en qué condiciones. Sustituye a `only`/`except`, que sigue funcionando pero ya no se recomienda.

## S

**SAST** (*static application security testing*) — **Ultimate** el nativo. Análisis del código sin ejecutarlo. En CE se implementa con Semgrep en un job propio.

**SBOM** (*software bill of materials*) — Inventario de todo lo que compone un artefacto. Se genera con Syft y se firma junto a la imagen.

**Scoped label** (*etiqueta con ámbito*) — **Premium**. Etiquetas mutuamente excluyentes con la sintaxis `clave::valor`. En CE se aproxima con la convención `clave/valor` y un job que valida que no haya dos.

**Server hook** — Free. Script que se ejecuta en el servidor antes o después de recibir un push. Es lo único en CE que **bloquea de verdad** un push que no cumple una regla.

**Sidekiq** — Free. El procesador de trabajos en segundo plano de GitLab. Cuando las colas crecen, es el primer sitio donde mirar.

**SLO** (*service level objective*) — Objetivo numérico de calidad de servicio sobre un indicador medible. Sin número y sin ventana temporal no es un SLO, es una intención.

## T

**Terraform state backend** — Free. GitLab puede almacenar el estado de Terraform, con bloqueo incluido, sin necesidad de S3 ni Terraform Cloud.

**Tier** — El plan de GitLab: Free (lo que incluye CE), Premium y Ultimate. Este bootcamp usa solo Free y sustituye el resto.

## V

**Value Stream Analytics** (*VSA*) — Free a nivel de proyecto, **Premium** a nivel de grupo. Mide cuánto tarda el trabajo en recorrer cada etapa desde el issue hasta producción.

---

[← Volver a docs](README.md)

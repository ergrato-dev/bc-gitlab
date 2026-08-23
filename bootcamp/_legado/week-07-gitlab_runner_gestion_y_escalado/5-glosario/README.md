# 📖 Glosario — Semana 07: GitLab Runner

Términos ordenados alfabéticamente. Los términos marcados con ↗ remiten a conceptos relacionados en este glosario.

---

## A

**Authentication Token (Runner)**
Token único asignado a un runner tras el registro, distinto del Registration Token. Autentica cada comunicación del runner con la API de GitLab. Comienza con `glrt-`. Desde GitLab 15.6, se prefiere crear el authentication token antes del registro (via API o UI) en lugar de usar el registration token global.

**Autoscaler (GitLab Runner Autoscaler)**
Componente de GitLab Runner que crea y destruye instancias de runner dinámicamente según la demanda de jobs. Reemplaza al ↗ Docker Machine deprecado. Funciona mediante plugins de ↗ Fleeting para interactuar con proveedores cloud (AWS, GCP, Azure). Disponible desde GitLab Runner 15.8.

---

## C

**capacity_per_instance**
Parámetro del ↗ Autoscaler que define cuántos jobs simultáneos puede ejecutar cada instancia del pool. Ejemplo: `capacity_per_instance = 2` con `max_instances = 10` permite hasta 20 jobs en paralelo.

**check_interval**
Parámetro global de ↗ config.toml que define cada cuántos segundos el runner consulta a GitLab buscando nuevos jobs (polling). Valor por defecto: 3 segundos. Reducirlo aumenta la carga en GitLab; aumentarlo introduce latencia en el inicio de jobs.

**concurrent**
Parámetro global de ↗ config.toml que define el número máximo de jobs que pueden ejecutarse simultáneamente en todos los runners del archivo. Si `concurrent = 4` y hay 10 runners, aún así solo 4 jobs corren a la vez. Valor crítico para el rendimiento de la infraestructura CI.

**config.toml**
Archivo de configuración principal del GitLab Runner. Contiene parámetros globales (concurrent, check_interval) y una sección `[[runners]]` por cada runner registrado. Ubicación por defecto: `/etc/gitlab-runner/config.toml`. El runner lo recarga automáticamente sin necesidad de reinicio (excepto cambios en parámetros globales).

---

## D

**DinD (Docker-in-Docker)**
Técnica que permite ejecutar comandos Docker dentro de un contenedor Docker. Requiere `privileged = true` en el ↗ Docker Executor, lo que otorga acceso casi total al host — riesgo de seguridad significativo. Alternativa segura: ↗ Kaniko.

**Docker Executor**
Executor que ejecuta cada job en un contenedor Docker nuevo y efímero. Al terminar el job, el contenedor se destruye — garantizando aislamiento entre jobs. Admite la directiva `services:` para levantar contenedores auxiliares (bases de datos, APIs). Requiere Docker instalado en el host del runner. Ver también: ↗ Shell Executor, ↗ Kubernetes Executor.

**Docker Machine**
Herramienta legacy que GitLab usó hasta 2021 para autoscaling de runners. **Deprecada en GitLab 14.0 y eliminada en GitLab Runner 15.0.** No debe usarse en instalaciones nuevas. Reemplazada por el ↗ Autoscaler con ↗ Fleeting.

---

## E

**Executor**
Define el entorno donde se ejecutan los comandos del job CI. El executor es parte de la configuración del runner (en ↗ config.toml) y no puede cambiarse por job. Los executors principales son: ↗ Docker Executor, ↗ Shell Executor, ↗ Kubernetes Executor. Hay también VirtualBox, SSH, Parallels e Instance (para autoscaling).

---

## F

**Fair Queuing**
Algoritmo de distribución de jobs que usa GitLab con ↗ Shared Runners. Detecta proyectos que consumen desproporcionadamente los runners y les da menor prioridad, distribuyendo la capacidad de forma equitativa entre todos los proyectos usuarios.

**Fleeting**
Plugin system que abstrae la interacción entre el ↗ Autoscaler y los proveedores cloud. Cada cloud tiene su plugin: `fleeting-plugin-aws`, `fleeting-plugin-googlecompute`, `fleeting-plugin-azure`. El autoscaler llama al plugin para crear/destruir instancias; el plugin habla con la API del cloud.

**Flota de Runners (Fleet)**
Conjunto de instancias o pods gestionados por el ↗ Autoscaler o el Kubernetes Executor que ejecutan jobs de CI/CD. Monitorear una flota requiere métricas agregadas (Prometheus) en vez de revisar runners uno por uno — ver `job_queue_duration_seconds`.

---

## G

**GitLab Runner**
Agente open-source escrito en Go que ejecuta los jobs de CI/CD de GitLab. Se instala independientemente de GitLab (en el mismo host o en servidores dedicados) y se comunica con GitLab via polling HTTPS. Un solo proceso puede gestionar múltiples runners (con diferentes tokens y configuraciones) definidos en el mismo ↗ config.toml.

**GitLab Runner Operator**
Alternativa al Helm chart para instalar runners en Kubernetes, basada en el patrón Kubernetes Operator. Declara cada runner como un recurso personalizado `Runner` que un controlador reconcilia continuamente contra el estado real del cluster — a diferencia del Helm chart, que solo actualiza recursos cuando se ejecuta `helm upgrade` manualmente. Se distribuye via ↗ Operator Lifecycle Manager (OLM); certificado para OpenShift, también usable en Kubernetes vanilla.

**Group Runner**
Runner disponible para todos los proyectos dentro de un grupo GitLab y sus subgrupos. Los owners del grupo pueden administrarlo. Nivel de aislamiento intermedio: más control que un ↗ Shared Runner, menos aislamiento que un ↗ Specific Runner. Se configura en `Group → Settings → CI/CD → Runners`.

---

## I

**idle_count**
Parámetro del ↗ Autoscaler que define cuántas instancias mantener siempre disponibles (idle), incluso cuando no hay jobs. Valor 0 = máximo ahorro pero latencia de arranque. Valor 2-5 = balance entre costo y velocidad de respuesta.

**idle_time**
Parámetro del ↗ Autoscaler que define cuánto tiempo puede estar una instancia sin ejecutar jobs antes de ser destruida. Ejemplo: `idle_time = "30m"` destruye instancias inactivas tras 30 minutos.

**Instance Runner**
Denominación moderna (GitLab 14+) para runners administrados a nivel de instancia GitLab. En GitLab.com, son los runners SaaS disponibles con cada plan de suscripción. En GitLab CE self-hosted, equivalente a ↗ Shared Runner.

---

## J

**job_queue_duration_seconds**
Métrica Prometheus (histogram) expuesta por `gitlab-runner` que mide cuánto tiempo espera un job **en cola** antes de que un worker lo tome. Es la señal principal de falta de capacidad en una ↗ Flota de Runners — si crece sostenidamente, hacen falta más workers, sin importar qué tan ocupados estén los existentes.

**Job Routing**
Mecanismo por el cual GitLab asigna jobs a runners basado en ↗ Tags y disponibilidad. Regla fundamental: el runner debe tener **todos** los tags declarados en el job. Si ningún runner disponible tiene los tags requeridos, el job queda en estado `pending` indefinidamente.

---

## K

**Kaniko**
Herramienta que construye imágenes Docker sin necesitar el daemon Docker ni modo privilegiado. Alternativa recomendada a ↗ DinD para builds de imágenes en ↗ Docker Executor.

**Kubernetes Executor**
Executor que ejecuta cada job como un pod efímero en un cluster Kubernetes. Cada job = un pod nuevo. Se destruye al terminar. Aprovecha el Cluster Autoscaler de K8s para escalar la capacidad. Configurado en la sección `[runners.kubernetes]` del ↗ config.toml. Se despliega típicamente con Helm.

---

## M

**max_instances**
Parámetro del ↗ Autoscaler que limita el número máximo de instancias en el pool. Control de costos crítico: sin este límite, una tormenta de jobs podría crear cientos de instancias cloud y generar una factura inesperada.

**max_use_count**
Parámetro del ↗ Autoscaler que define cuántos jobs puede ejecutar una instancia antes de ser destruida y reemplazada. Útil para prevenir acumulación de estado y garantizar entornos limpios periódicamente.

---

## O

**Operator Lifecycle Manager (OLM)**
Framework de Kubernetes para instalar, actualizar y gestionar Operators via catálogos (OperatorHub). Requerido para instalar el ↗ GitLab Runner Operator en un cluster Kubernetes vanilla; en OpenShift viene incluido por defecto.

---

## P

**Paused (estado del runner)**
Estado en el que el runner está conectado a GitLab pero no acepta nuevos jobs. Los jobs en ejecución se completan normalmente. Útil para mantenimiento sin interrumpir jobs activos. Se reactiva desde la UI o via API.

**Polling**
Mecanismo que usa el runner para consultar periódicamente a GitLab si hay nuevos jobs disponibles. Frecuencia configurada con ↗ check_interval. Cada runner usa long polling: GitLab mantiene la conexión abierta hasta que hay un job o expira el timeout.

**pull_policy**
Parámetro del ↗ Docker Executor que controla cuándo hacer pull de la imagen Docker. Opciones: `always` (siempre), `never` (solo usar imágenes locales), `if-not-present` (pull solo si no existe localmente). El valor `if-not-present` reduce latencia y uso de ancho de banda a costo de no detectar actualizaciones de imágenes automáticamente.

---

## R

**Registration Token**
Token del proyecto, grupo o instancia usado para registrar un runner. **Deprecado desde GitLab 15.6** — el método moderno es crear un runner authentication token via API antes del registro. Diferente del ↗ Authentication Token (Runner) que se obtiene tras el registro.

**Right-sizing**
Práctica de ajustar el tipo y tamaño de instancia de autoscaling al perfil real de recursos de los jobs, en vez de usar una única instancia grande para toda la ↗ Flota de Runners. Reduce costo dividiendo el pool en tipos de instancia distintos (liviano/pesado) enrutados por ↗ Tags.

**run_untagged**
Parámetro del runner (en ↗ config.toml y via API) que controla si el runner acepta jobs sin tags. `run_untagged = true`: acepta jobs con o sin tags. `run_untagged = false`: solo acepta jobs que tienen tags que coincidan con los del runner. Recomendado `false` para runners especializados de producción.

**Runner Manager**
En el contexto del ↗ Autoscaler, el proceso principal que coordina el pool de workers. No ejecuta jobs directamente — los delega a las instancias workers que crea dinámicamente.

---

## S

**Services**
Contenedores adicionales que el ↗ Docker Executor levanta para un job, accesibles via red por su alias. Ejemplo: `services: [postgres:15-alpine]` levanta PostgreSQL accesible como `postgres` o `db`. Solo funciona con Docker Executor.

**Shared Runner**
Runner disponible para todos los proyectos de la instancia GitLab. Administrado exclusivamente por administradores de la instancia. Usa ↗ Fair Queuing para distribuir jobs equitativamente. El nivel de aislamiento más bajo pero el más fácil de administrar. Ver también: ↗ Group Runner, ↗ Specific Runner.

**Shell Executor**
Executor que ejecuta los comandos del job directamente en la shell del host donde corre el runner. Sin contenedores, sin aislamiento — el job tiene acceso al filesystem, red y servicios del host. Apropiado solo para runners dedicados a proyectos específicos con acceso controlado. Ver también: ↗ Docker Executor.

**Specific Runner**
Runner asignado exclusivamente a un proyecto. Los maintainers del proyecto pueden registrar y administrar sus propios runners. Nivel de aislamiento máximo: el runner solo acepta jobs de ese proyecto. Recomendado para proyectos con requisitos especiales de hardware o acceso a secretos sensibles.

**Spot Instance / Preemptible VM**
Instancia cloud de bajo costo (60-90% más barata que on-demand) que el proveedor puede interrumpir con poco aviso (2 minutos en AWS). Recomendada para pools de autoscaling con jobs cortos y reintentables (tests, lint); evitarla para jobs largos y no idempotentes como deploys o migraciones de base de datos.

---

## T

**Tags**
Etiquetas asignadas a runners y declaradas en jobs para el ↗ Job Routing. El runner debe tener **todos** los tags del job (no viceversa: el runner puede tener más tags que los pedidos por el job). Estrategias comunes: por tecnología (nodejs, python), por entorno (production, staging), por arquitectura (amd64, arm64).

---

## V

**volumes**
Parámetro del ↗ Docker Executor en ↗ config.toml que define qué volúmenes se montan en cada contenedor de job. Uso común: `/var/run/docker.sock:/var/run/docker.sock` (acceso al daemon Docker del host) y `/cache` (cache persistente entre jobs).

---

⬅️ **Proyecto:** [3-proyecto/README.md](../3-proyecto/README.md)
➡️ **Rúbrica:** [rubrica-evaluacion.md](../rubrica-evaluacion.md)

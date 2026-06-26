# 📖 Glosario — Semana 05

Terminología de CI/CD, pipelines, Docker y GitLab Runner.

---

## A

### **Artifact / Artefacto**
Archivo o directorio generado por un job que se almacena en GitLab y puede ser descargado, pasado a jobs posteriores, o mostrado en la UI. A diferencia del cache, el artifact es garantizado: si el artifact no existe, el job que lo necesita falla. Ejemplos: el directorio `dist/` del build, el reporte `coverage/`, la imagen Docker compilada.

### **artifacts:reports**
Subconjunto especial de artifacts que GitLab interpreta para mostrar en la UI: `junit` (resultados de tests en el MR), `coverage_report` (cobertura por archivo en el diff), `sast` (vulnerabilidades en Security dashboard). No son solo archivos — GitLab los procesa activamente.

---

## B

### **before_script**
Lista de comandos que se ejecutan **antes** del `script` en cada job. Útil para instalación de herramientas, autenticación, o preparación del entorno. Puede definirse globalmente (aplica a todos los jobs) o por job individual (sobreescribe el global).

---

## C

### **Cache**
Mecanismo de persistencia entre ejecuciones del pipeline para acelerar builds. Almacena dependencias (como `node_modules/`) entre runs. Es "best effort" — GitLab no garantiza que el cache esté disponible. Si no está, el job debe poder funcionar igualmente (instalando desde cero). Ver también: [[Artifact / Artefacto]].

### **cache:key**
La clave que identifica un cache específico. Caches con diferente `key` son independientes. Se recomienda usar `key.files` para invalidar el cache automáticamente cuando cambia un archivo de dependencias (como `package-lock.json`).

### **cache:policy**
Controla si el job descarga (`pull`), actualiza (`push`), o ambas (`pull-push`, el default). Usar `policy: pull` en jobs que solo necesitan el cache sin modificarlo (más rápido).

### **CD — Continuous Delivery**
Práctica donde el código que pasa CI se mantiene en estado "deployable" en todo momento. El deploy a producción requiere aprobación humana (manual). Ver también: [[CD — Continuous Deployment]].

### **CD — Continuous Deployment**
Práctica donde cada commit que pasa CI se despliega automáticamente a producción sin intervención humana. Requiere alta confianza en el suite de tests y capacidad de rollback automático.

### **CI — Continuous Integration**
Práctica de integrar cambios de código frecuentemente (múltiples veces al día) en un repositorio compartido, con verificación automatizada en cada integración. El objetivo es detectar problemas de integración lo antes posible.

---

## D

### **DAG — Directed Acyclic Graph**
Tipo de pipeline donde los jobs tienen dependencias directas entre sí (via `needs`), en lugar de depender solo del orden de stages. Permite que un job de stage 3 empiece tan pronto como sus dependencias directas terminen, sin esperar a que toda la stage 2 complete.

### **Docker-in-Docker (DinD)**
Técnica para construir imágenes Docker dentro de un job de CI. Requiere ejecutar el daemon Docker (`docker:dind`) como service y el runner en modo privilegiado. Alternativas más seguras: Kaniko, Buildah.

---

## E

### **Environment / Entorno**
Destino de deploy configurado en GitLab (staging, production). Los jobs con `environment:` crean un historial de deploys visible en `Deployments → Environments`. Permite ver qué versión está desplegada en cada ambiente.

### **executor**
El motor de ejecución del GitLab Runner. Define cómo se ejecutan los jobs: `docker` (en contenedores), `shell` (directamente en el OS), `kubernetes` (como pods). El executor `docker` es el más común para proyectos con `image:` y `services:`.

### **expire_in**
Tiempo de retención de un artifact. Formatos: `1 hour`, `1 day`, `1 week`, `30 days`, `1 year`, `never`. Después de este tiempo, GitLab elimina el artifact para liberar espacio.

### **extends**
Keyword de GitLab CI que permite a un job heredar la configuración de otro job (o template). Similar a la herencia en programación orientada a objetos. Los jobs template se prefijan con `.` para que no se ejecuten directamente.

---

## I

### **image**
La imagen Docker que define el entorno de ejecución del job. Puede definirse globalmente (aplica a todos los jobs) o por job (sobreescribe el global). Cada job se ejecuta en un contenedor limpio basado en esta imagen.

---

## J

### **Job**
La unidad mínima de trabajo en un pipeline. Un job tiene un `stage`, un `script` (obligatorio), y opcionalmente `image`, `services`, `artifacts`, `cache`, `rules`, etc. Los jobs de la misma stage corren en paralelo (si hay runners disponibles).

### **JUnit Report**
Formato XML estándar para reportar resultados de tests. GitLab puede interpretar archivos JUnit y mostrar el resumen de tests pasados/fallidos directamente en la UI del MR o del pipeline, sin necesidad de leer los logs.

---

## K

### **Kaniko**
Herramienta para construir imágenes Docker sin necesitar el daemon Docker ni modo privilegiado. Alternativa a DinD más segura para entornos compartidos. La imagen base es `gcr.io/kaniko-project/executor`.

---

## N

### **needs**
Keyword que define dependencias directas entre jobs, creando un DAG en lugar de un pipeline lineal. Un job con `needs: ["job-a", "job-b"]` empieza tan pronto como `job-a` y `job-b` terminen, independientemente del orden de stages.

---

## P

### **Pipeline**
Secuencia automatizada de stages y jobs que se ejecuta automáticamente cuando se hace push al repositorio (o cuando se crea/actualiza un MR). La configuración vive en `.gitlab-ci.yml` en la raíz del repositorio.

### **Pipeline as Code**
El paradigma de definir el pipeline como código versionado en el repositorio (`.gitlab-ci.yml`), en lugar de configurarlo en una interfaz gráfica externa. Permite revisión en MRs, historial de cambios, y reproducibilidad.

### **policy (cache)**
Ver [[cache:policy]].

---

## R

### **rules**
Keyword para definir condiciones de ejecución de un job. Reemplaza a `only`/`except` (deprecados). Permite condiciones complejas con `if`, `changes`, y `when`. Controla si un job se ejecuta, se salta, o requiere aprobación manual.

### **Runner / GitLab Runner**
Agente que ejecuta los jobs del pipeline. Se registra en el servidor GitLab y "escucha" por jobs disponibles. Puede correr en la misma máquina que GitLab, en servidores separados, o en Kubernetes. Cada runner tiene un executor que define cómo ejecuta los jobs.

---

## S

### **services**
Contenedores Docker adicionales que corren junto al job. Accesibles por el job mediante su hostname (el nombre de la imagen o el `alias` configurado). Usados para bases de datos (PostgreSQL, MySQL, Redis), APIs de terceros, o cualquier servicio externo necesario durante los tests.

### **stage**
Agrupación lógica de jobs. Los stages se ejecutan en el orden definido en `stages:`. Los jobs dentro de la misma stage corren en paralelo. Si un job de una stage falla, los jobs de stages siguientes no se ejecutan (a menos que tengan `allow_failure: true`).

---

## T

### **timeout**
Tiempo máximo de ejecución de un job. Por defecto: 1 hora. Puede configurarse por job (`timeout: 30 minutes`) o a nivel del proyecto.

### **trigger**
Evento que dispara el pipeline: push a una rama, creación de un MR, push de un tag, ejecución manual, API, o timer (scheduled pipelines).

---

## V

### **variables**
Variables de entorno disponibles en los scripts del pipeline. Pueden ser: predefinidas por GitLab (`$CI_COMMIT_SHA`, `$CI_PROJECT_NAME`), definidas en el `.gitlab-ci.yml` (`variables:`), o configuradas en GitLab UI como secrets (`Settings → CI/CD → Variables`).

---

*Los términos con `[[nombre]]` tienen entradas propias en este glosario o en glosarios de semanas anteriores.*

---

⬅️ **Proyecto:** [3-proyecto/README.md](../3-proyecto/README.md)
➡️ **Rúbrica:** [rubrica-evaluacion.md](../rubrica-evaluacion.md)

# 📖 Glosario — Semana 06: Pipelines Avanzados

Terminología de variables CI/CD, ejecución condicional, modularización, environments y triggers.

---

## A

### **`action: stop`**
Valor del campo `environment.action` que marca un environment como detenido en la UI de GitLab. Se usa en el job de "limpieza" que destruye el entorno (ej: `helm uninstall`, `terraform destroy`). Ver también: [[on_stop]], [[review app]].

### **`allow_failure`**
Keyword que permite que un job falle sin detener ni bloquear el pipeline. Con `allow_failure: true`, el job muestra ⚠️ (warning) en lugar de ❌ (error). Con `allow_failure: false` (default en jobs manuales de deploy), un fallo bloquea el pipeline. Útil para jobs de calidad no críticos (lint, cobertura).

### **`auto_stop_in`**
Propiedad del `environment` que define el tiempo máximo de vida de un environment efímero. Formato: `1 hour`, `2 days`, `1 week`. GitLab ejecuta automáticamente el job `on_stop` al expirar.

---

## B

### **Bridge job**
Job especial de GitLab CI que no ejecuta scripts sino que dispara otro pipeline (downstream). Se configura con el keyword `trigger:`. La palabra "bridge" refleja que conecta dos pipelines.

---

## C

### **`changes`**
Cláusula de `rules` que evalúa si alguno de los archivos o patrones especificados cambió en el commit actual. Funciona con paths glob (`src/**/*.js`). En pipelines de MR, compara contra la rama target. Ver también: [[rules]].

### **`CI_COMMIT_REF_SLUG`**
Variable predefinida que convierte la rama o tag en una cadena segura para URLs (lowercase, solo alfanumérico y guiones). Ejemplo: `feature/JIRA-123-Login` → `feature-jira-123-login`. Útil para nombres de imágenes Docker, URLs de review apps.

### **`CI_ENVIRONMENT_NAME`**
Variable predefinida disponible en jobs con `environment:`. Contiene el nombre del environment donde se está desplegando. Ejemplo: `staging`, `production`, `review/42`.

### **`CI_JOB_TOKEN`**
Token temporal generado por GitLab para cada job. Permite autenticarse al Container Registry del mismo proyecto sin necesitar credenciales manuales (`CI_REGISTRY_USER` / `CI_REGISTRY_PASSWORD`). Expira al terminar el job. Ver también: [[CI_REGISTRY_USER]].

### **`CI_PIPELINE_SOURCE`**
Variable predefinida que indica qué disparó el pipeline. Valores comunes: `push` (git push), `merge_request_event` (MR abierto/actualizado), `schedule` (pipeline programado), `trigger` (disparado via API o trigger job), `api`, `web` (manual desde UI).

---

## D

### **Deployment**
Registro de un despliegue exitoso a un environment. GitLab crea un deployment automáticamente cuando un job con `environment:` termina con éxito. Cada deployment incluye: SHA del commit, usuario, fecha, duración, y enlace al job. Se visualiza en `Operate → Environments → [nombre] → Deployments`.

### **Deployment freeze**
Periodo configurado en `Settings → CI/CD → Deploy freezes` durante el cual no se permiten deployments a environments específicos. Los jobs de deploy que intenten ejecutarse durante el freeze fallan automáticamente.

---

## E

### **`environment`**
Keyword que define el destino de un despliegue en un job. Cuando está presente, GitLab registra el deployment, rastrea la versión activa, y habilita funciones como rollback y historial. Campos: `name` (obligatorio), `url` (opcional), `on_stop`, `action`, `auto_stop_in`.

### **`exists`**
Cláusula de `rules` que evalúa si un archivo específico existe en el repositorio. Útil para activar jobs solo cuando el proyecto tiene un `Dockerfile`, `Chart.yaml`, o `requirements.txt`. Ver también: [[rules]].

### **`extends`**
Keyword que permite a un job heredar la configuración de otro job o template. Los campos se fusionan (no se reemplazan). Los jobs template usan el prefijo `.` para no ejecutarse directamente. Ver también: [[ancla YAML]], [[!reference]].

---

## I

### **`include`**
Directiva de `.gitlab-ci.yml` para importar configuración desde otros archivos. Tipos: `local` (mismo repo), `remote` (URL HTTP/HTTPS), `template` (plantillas oficiales de GitLab), `project` (otro proyecto en la misma instancia). Ver también: [[include:local]], [[include:template]].

### **`include:local`**
Subtipo de `include` que referencia un archivo del mismo repositorio. La ruta es relativa a la raíz del repo. El archivo debe existir en el mismo commit que el `.gitlab-ci.yml`. Ejemplo: `- local: .gitlab/ci/build.yml`.

### **`include:project`**
Subtipo de `include` que importa un archivo de otro proyecto en la misma instancia GitLab. Soporta `ref:` para anclar a un tag o commit específico. Ideal para templates compartidos gestionados por un equipo de platform engineering.

### **`include:template`**
Subtipo de `include` que usa plantillas oficiales de GitLab (SAST, Dependency Scanning, Auto DevOps, etc.). Las plantillas se actualizan con cada versión de GitLab. Ver el catálogo en: Project → CI/CD → Editor → Browse templates.

---

## M

### **Masked variable**
Variable cuyo valor se reemplaza por `****` en los logs del pipeline. Requisito: mínimo 8 caracteres, sin espacios, sin `"'` `` ` `` `\`. GitLab realiza la sustitución en el output del runner antes de enviarlo a los logs. **No garantiza privacidad absoluta** si el script guarda el valor en un archivo o artifact.

### **Multi-project pipeline**
Pipeline de un proyecto que dispara el pipeline de otro proyecto diferente. El job que hace el disparo se llama "bridge job". El proyecto upstream puede esperar el resultado con `strategy: depend`. Ver también: [[parent-child pipeline]], [[trigger]].

---

## O

### **`on_stop`**
Campo del `environment` que especifica el nombre del job que destruye el environment. GitLab usa este job cuando se hace click en "Stop" desde la UI o cuando expira `auto_stop_in`. El job referenciado debe tener `environment.action: stop`.

### **`only` / `except`** *(legacy)*
Keywords de GitLab CI para controlar en qué ramas/tags se ejecuta un job. Deprecados en favor de `rules`. No soportan condiciones complejas con variables. Se recomienda migrar a `rules` en código nuevo.

---

## P

### **Parent-child pipeline**
Pipeline que dispara sub-pipelines dentro del **mismo proyecto**. El pipeline padre controla el flujo; los pipelines hijo pueden generarse dinámicamente desde artifacts. Útil para monorepos donde diferentes partes del código tienen pipelines independientes. Ver también: [[multi-project pipeline]].

### **Protected environment**
Environment que requiere aprobación manual de personas o roles específicos antes de que un deployment pueda ejecutarse. Configurado en `Settings → CI/CD → Protected environments`. Soporta múltiples approvers y reglas de quórum.

### **Protected variable**
Variable CI/CD marcada como "Protected" en Settings. Solo está disponible en ramas y tags protegidos. Los jobs en ramas no protegidas (feature branches) ven la variable como vacía. Usar para tokens de producción y credenciales sensibles.

---

## R

### **`!reference`**
Tag YAML especial de GitLab que permite reutilizar secciones específicas de otros jobs, incluso entre archivos incluidos. Más flexible que las anclas YAML (que solo funcionan en el mismo archivo). Sintaxis: `!reference [.job-name, section-name]`.

### **Review app**
Environment efímero creado automáticamente para cada Merge Request. Permite que reviewers vean los cambios funcionando en un entorno real antes del merge. Se destruye al cerrar o mergear el MR (via `on_stop`) o tras `auto_stop_in`. El nombre suele ser `review/$CI_MERGE_REQUEST_IID`.

### **`rules`**
Keyword moderna para definir condiciones de ejecución de un job. Evalúa cláusulas en orden ("primer match gana"). Cláusulas disponibles: `if` (expresión con variables), `changes` (archivos modificados), `exists` (archivo existe), `when` (comportamiento), `allow_failure`, `variables`. Reemplaza `only`/`except`.

---

## S

### **`strategy: depend`**
Opción del keyword `trigger` que hace que el bridge job espere a que el pipeline downstream termine. Si el downstream falla, el bridge job también se marca como fallido, propagando el estado al pipeline upstream. Sin `strategy: depend`, el bridge se marca exitoso inmediatamente.

---

## T

### **Trigger**
Mecanismo para iniciar un pipeline desde otra fuente. Tipos: (1) `trigger:project` en `.gitlab-ci.yml` (bridge job); (2) API de triggers con token; (3) CI_JOB_TOKEN para llamadas autenticadas entre proyectos. Ver también: [[bridge job]], [[multi-project pipeline]].

---

## V

### **Variable de archivo (type: file)**
Variable CI/CD de tipo File. En lugar de inyectar el valor como string en el entorno, GitLab crea un archivo temporal en el runner y la variable contiene la **ruta** al archivo. Útil para kubeconfig, certificados PEM, y archivos `.npmrc`.

### **Variable enmascarada**
Ver [[Masked variable]].

### **Variable protegida**
Ver [[Protected variable]].

### **`variables` (en rules)**
Sub-keyword de `rules` que permite sobreescribir variables según el contexto que hizo match. Ejemplo: si el job corre en `develop`, `ENVIRONMENT=staging`; si corre en `main`, `ENVIRONMENT=production`. Evita duplicar jobs solo por cambiar variables.

### **`when`**
Keyword que define cuándo ejecutar un job: `on_success` (si stage anterior pasó), `on_failure` (si falló), `always` (siempre), `manual` (requiere click), `delayed` (espera `start_in`), `never` (salta el job). Puede usarse a nivel global o dentro de cláusulas `rules`.

---

*Los términos con `[[nombre]]` tienen entradas propias en este glosario o en glosarios de semanas anteriores.*

---

⬅️ **Proyecto:** [3-proyecto/README.md](../3-proyecto/README.md)
➡️ **Rúbrica:** [rubrica-evaluacion.md](../rubrica-evaluacion.md)

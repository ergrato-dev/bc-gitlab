# 📖 Glosario — Semana 04

Terminología de Issues, Merge Requests, Code Review y GitLab Flow. Los términos en **negrita** son conceptos clave de la semana.

---

## A

### Approval / Aprobación
Acción de un reviewer en un MR que indica que el código está listo para mergear. En GitLab CE se configura en `Settings → Merge requests → Approval rules`. Un Approval no significa que el código sea perfecto — significa que es "merge safe" para el reviewer.

### Assignee
Persona asignada a resolver un issue o ser el autor responsable de un MR. Un issue puede tener múltiples assignees en GitLab. En el MR, el assignee es el autor (quien escribe el código), no el reviewer.

### Auto-close / Cierre Automático
Mecanismo por el cual GitLab cierra un issue automáticamente cuando el MR que lo referencia (con "Closes #N") es mergeado hacia la rama default. Ver también: [[closing-keywords]].

---

## B

### **Batch Suggestions**
Funcionalidad de GitLab que permite al autor de un MR marcar múltiples Suggested Changes y aplicarlas todas de una vez como un único commit. Reduce el número de commits de "apply suggestion" en el historial.

### Board / Issue Board
Vista Kanban en GitLab donde cada columna representa un label de workflow. Mover un issue entre columnas actualiza automáticamente sus labels. Disponible a nivel de proyecto y de grupo.

### Branch Protection / Protección de rama
Configuración que controla quién puede hacer push o merge hacia una rama específica. Las ramas protegidas no pueden recibir force pushes. Configurado en `Settings → Repository → Protected branches`.

---

## C

### **Changes Requested**
Estado de un review donde el reviewer ha enviado observaciones con la opción "Request changes", indicando que el MR NO debe mergearse hasta corregir los problemas señalados. El autor debe corregir y actualizar el MR.

### **Closing Keywords / Palabras de cierre**
Palabras especiales en la descripción de un MR o mensaje de commit que causan el cierre automático de issues al mergear: `Closes`, `Fixes`, `Resolves`, `Implements`. Sintaxis: `Closes #42` o `Closes namespace/project#42`.

### **Code Review**
Proceso de revisión de código por pares antes de integrar cambios. El reviewer lee el diff, identifica problemas, y da feedback. El autor corrige y el proceso itera hasta que el código es aceptable. Ver: [[suggested-changes]], [[conventional-comments]].

### **Commit Atómico**
Commit que hace exactamente una cosa lógica. Puede ser entendido, revisado, o revertido de forma independiente. Opuesto a un commit masivo que mezcla múltiples cambios no relacionados.

### **Conventional Comments**
Estándar de formato para comentarios de code review que clasifica el feedback por tipo: `[blocker]`, `[concern]`, `[nit]`, `[question]`, `[praise]`, `[suggestion]`. Ayuda al autor a priorizar qué comentarios son bloqueantes y cuáles son opcionales.

### **Conventional Commits**
Estándar de formato para mensajes de commit: `<tipo>(<scope>): <descripción>`. Tipos: `feat`, `fix`, `docs`, `test`, `chore`, `refactor`, `perf`, `ci`. Facilita la generación automática de changelogs y el entendimiento del historial.

---

## D

### **Default Branch**
La rama principal del repositorio a la cual apuntan los links del proyecto y desde donde se clonan los repos por defecto. GitLab usa `main` por defecto. Los issues se cierran automáticamente cuando el MR llega a la default branch.

### **Description Template / Template de descripción**
Archivo Markdown en `.gitlab/issue_templates/` o `.gitlab/merge_request_templates/` que pre-rellena la descripción al crear un issue o MR. Los templates pueden incluir Quick Actions que se ejecutan automáticamente al guardar.

### **Diff**
La vista de cambios entre dos versiones de un archivo. En el MR, muestra líneas añadidas (verde) y eliminadas (rojo). GitLab ofrece vista inline (mezclada) y side-by-side (comparativa).

### **Draft MR**
Merge Request marcado con "Draft:" en el título. No puede ser mergeado mientras tenga este prefijo. Úsalo para trabajo en progreso, feedback temprano, o ejecutar el CI antes de terminar. Se quita con "Mark as ready" o eliminando "Draft:" del título.

---

## F

### **Fast-forward Merge**
Estrategia de merge donde la rama target simplemente avanza hasta el último commit de la feature branch, sin crear un commit de merge. Solo funciona si el target no avanzó desde que se creó la feature branch. Produce historial perfectamente lineal.

### Feature Branch
Rama temporal para desarrollar una funcionalidad específica. Por convención se nombra `<issue-id>-descripcion-en-kebab-case`. Se elimina después del merge.

---

## G

### **GitLab Flow**
Metodología de GitLab que integra issues, feature branches, merge requests y code review en un ciclo cohesivo. Define convenciones para nombrar ramas, conectar issues a MRs, y gestionar ambientes (staging/production) con ramas de ambiente.

### Group Board
Issue Board a nivel de grupo que muestra issues de todos los proyectos del grupo en una sola vista. Permite al Scrum Master o PM ver el estado del sprint de todo el equipo sin importar en qué proyecto está cada tarea.

---

## I

### **Inline Comment / Comentario en Línea**
Comentario en una línea específica del diff de un MR. Se crea hoviando sobre el número de línea en la pestaña "Changes" y clickeando el ícono de burbuja de comentario.

### **Issue**
Unidad de trabajo rastreable en GitLab. Puede representar un bug, feature request, tarea de mantenimiento, o cualquier trabajo que el equipo necesita gestionar. Tiene título, descripción, labels, milestone, assignee, weight, due date.

### **Issue Board**
Ver [[Board / Issue Board]].

---

## K

### **Kanban**
Metodología de gestión de trabajo visual donde las tareas (issues) fluyen a través de columnas que representan estados del proceso. En GitLab, las columnas del Kanban son labels de workflow.

---

## L

### Label
Etiqueta aplicada a issues y MRs para categorizarlos. Permiten filtrar, organizar en boards, y crear flujos de trabajo. Los **Scoped Labels** (con `::`) son mutuamente excluyentes: aplicar `priority::1` elimina automáticamente `priority::2`.

### **Label de Workflow**
Labels que representan el estado del issue en el proceso: `workflow::todo`, `workflow::in-progress`, `workflow::review`, `workflow::done`. Al mover un issue en el board Kanban, estos labels se actualizan automáticamente.

---

## M

### Maintainer
Rol de GitLab con permisos para mergear MRs, gestionar ramas protegidas, administrar miembros del proyecto, y configurar el proyecto. Rol mínimo para aprobar MRs en proyectos con reglas de aprobación.

### **Merge Commit**
Commit especial creado cuando se integra una feature branch con su historial completo usando la estrategia "Merge commit". Tiene dos padres: el último commit de cada rama. Facilita el rollback completo con `git revert <merge-commit>`.

### **Merge Request (MR)**
Propuesta formal de integrar los cambios de una rama source hacia una rama target, pasando por revisión de código, CI/CD y aprobación. Equivalente al Pull Request de GitHub. Ver también: [[Draft MR]], [[Merge Commit]].

### Milestone
Agrupación de issues y MRs bajo un objetivo temporal (sprint, release, versión). Tienen fecha de inicio y fin. Pueden ser de proyecto (un solo proyecto) o de grupo (todos los proyectos del grupo).

---

## N

### **N+1 Query**
Anti-patrón de rendimiento donde se ejecuta una query SQL dentro de un loop, resultando en N+1 queries en lugar de una sola con JOIN. Es uno de los problemas más comunes a detectar en code reviews de código backend.

---

## P

### **Pipeline**
Secuencia automatizada de jobs (tests, lint, build, deploy) que se ejecuta automáticamente al hacer push o al crear/actualizar un MR. Configurada en `.gitlab-ci.yml`. Se cubre en Semana 05.

### **Praise / Feedback Positivo**
Tipo de comentario de code review (según Conventional Comments) que reconoce algo bien hecho. El feedback positivo es tan importante como el crítico — refuerza buenas prácticas y mejora la motivación del equipo.

### Protected Branch / Rama Protegida
Ver [[Branch Protection / Protección de rama]].

---

## Q

### **Quick Actions**
Comandos especiales en la descripción o comentarios de issues y MRs que ejecutan acciones automatizadas. Empiezan con `/`: `/label ~bug`, `/assign @usuario`, `/milestone %Sprint1`, `/close`, `/weight 5`. Se procesan al guardar.

---

## R

### **Rebase and Merge**
Estrategia de merge que reaplica los commits de la feature branch sobre el estado actual de la rama target. Produce historial lineal manteniendo la granularidad de los commits originales (aunque con diferentes SHAs).

### **Resolve Thread / Resolver Thread**
Acción de marcar un comentario de review como resuelto. Si el proyecto tiene "All threads must be resolved" en Merge checks, todos los threads deben resolverse antes de poder mergear.

### **Reviewer**
Persona asignada para revisar el código de un MR. Lee el diff, hace comentarios, usa Suggested Changes, y finalmente Aprueba o solicita cambios. Es diferente del Assignee del MR (que es el autor).

---

## S

### **Scoped Label**
Label con formato `scope::value` donde `::` indica que es mutuamente exclusivo dentro del mismo scope. `priority::1`, `priority::2`, `priority::3` son mutuamente excluyentes — aplicar uno elimina los otros del mismo scope.

### **Self-review**
Práctica de que el autor del MR lea su propio diff antes de asignar reviewers. Descubre errores obvios (console.log, TODOs abandonados, archivos de debug) y reduce el número de comentarios en el review.

### **Squash and Merge**
Estrategia de merge que combina todos los commits de la feature branch en uno solo antes de mergear. Produce historial limpio y lineal en la rama target. Los commits individuales quedan visibles dentro del MR pero no en `main`.

### **Start a Review**
Modo de GitLab para acumular comentarios de review sin publicarlos inmediatamente. Se envían todos juntos al hacer "Submit review". Útil para reviews largas donde el autor prefiere recibir todo el feedback a la vez.

### **Suggested Change / Cambio Sugerido**
Funcionalidad de GitLab que permite al reviewer proponer el código exacto que debería reemplazar una línea. El autor puede aplicar la sugerencia con un click, creando automáticamente un commit. Ver también: [[Batch Suggestions]].

---

## T

### **Thread**
Hilo de conversación en un MR que empieza con un comentario en línea y puede tener respuestas. Los threads pueden marcarse como "Resolved". Ver: [[Resolve Thread]].

### **Trazabilidad**
Capacidad de seguir la cadena issue → rama → commits → MR → merge en GitLab. La convención de nombrar ramas con el ID del issue (`42-feature-name`) y usar "Closes #42" en el MR crea esta trazabilidad automáticamente.

---

## W

### **Weight / Peso**
Campo numérico (1-9) en un issue que representa la estimación de complejidad relativa. No representa horas directamente: 1=trivial, 5=medio, 9=muy complejo. Útil para planificación de sprints.

### **Workflow Label**
Ver [[Label de Workflow]].

---

## Z

### **Zero-downtime Deploy**
Técnica de despliegue donde la nueva versión se despliega sin interrumpir el servicio actual. Requiere health checks correctamente implementados para que el load balancer sepa cuándo el nuevo pod está listo para recibir tráfico.

---

*Términos con `[[nombre]]` tienen entradas propias en este glosario o en glosarios de semanas anteriores.*

---

⬅️ **Proyecto:** [3-proyecto/instrucciones.md](../3-proyecto/instrucciones.md)
➡️ **Rúbrica:** [rubrica-evaluacion.md](../rubrica-evaluacion.md)

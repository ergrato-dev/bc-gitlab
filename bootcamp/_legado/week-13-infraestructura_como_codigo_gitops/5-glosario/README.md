# Glosario — Semana 13: Infraestructura como Código y GitOps

| Término | Definición |
|---------|-----------|
| **agentk** | Componente del GitLab Kubernetes Agent que corre dentro del clúster; inicia la conexión hacia `kas` y sincroniza manifiestos |
| **Apply** | Comando de Terraform (`terraform apply`) que ejecuta el plan calculado y modifica la infraestructura real |
| **Backend (Terraform)** | Mecanismo que define dónde y cómo se almacena el state; el backend `http` es el usado con GitLab Managed Terraform State |
| **Conftest** | Herramienta que evalúa políticas Rego (OPA) contra archivos estructurados como el JSON de un plan de Terraform |
| **Declarative (declarativo)** | Modelo donde se describe el estado deseado del sistema, no los pasos para llegar a él; contraste con imperativo |
| **Deploy Token** | Token de acceso de solo lectura/escritura limitado, usado para autenticar operaciones automatizadas sin usar credenciales personales |
| **Drift** | Divergencia entre el estado declarado (en Terraform o en manifiestos GitOps) y el estado real de la infraestructura/clúster |
| **Drift detection** | Proceso de detectar drift automáticamente, típicamente con `terraform plan -detailed-exitcode` en un job programado |
| **GitOps** | Metodología que usa Git como fuente única de verdad para el estado deseado de un sistema, con reconciliación automática pull-based |
| **HCL** | HashiCorp Configuration Language; el lenguaje declarativo en que se escriben los archivos `.tf` de Terraform |
| **Idempotencia** | Propiedad por la cual aplicar la misma operación múltiples veces produce el mismo resultado que aplicarla una sola vez |
| **Imperative (imperativo)** | Modelo donde se describen los pasos/acciones a ejecutar en orden; contraste con declarativo |
| **Impersonation** | Mecanismo por el cual el Kubernetes Agent actúa en el clúster bajo una identidad controlada (Service Account/RBAC), no con privilegios irrestrictos |
| **Import (`terraform import`)** | Comando/bloque que asocia un recurso ya existente (creado fuera de Terraform) con un `resource` declarado, sin recrearlo |
| **kas** | GitLab Kubernetes Agent Server; componente dentro de GitLab que recibe la conexión de `agentk` y sirve la configuración/manifiestos |
| **Kubernetes Agent** | Producto de GitLab (`agentk` + `kas`) que implementa GitOps pull-based conectando un clúster con proyectos de GitLab |
| **Lock (state locking)** | Mecanismo que impide que dos procesos apliquen cambios al mismo state de Terraform simultáneamente |
| **Manifest project** | Proyecto GitLab cuyos manifiestos Kubernetes son leídos y sincronizados por el Kubernetes Agent, declarado en `config.yaml` |
| **Module (módulo)** | Conjunto de archivos `.tf` reutilizable que encapsula recursos relacionados, con variables de entrada y outputs de salida |
| **OPA (Open Policy Agent)** | Motor de políticas de propósito general, usado para policy-as-code mediante su lenguaje Rego |
| **Plan** | Comando de Terraform (`terraform plan`) que calcula el diff entre el código declarado y el state/infraestructura real, sin aplicar cambios |
| **Policy-as-code** | Práctica de definir reglas de negocio/seguridad como código ejecutable, validado automáticamente en el pipeline antes de aplicar cambios |
| **Provider (Terraform)** | Plugin que traduce los recursos declarados en HCL a llamadas a la API de una plataforma específica (ej. GitLab, AWS) |
| **Pull-based** | Modelo donde el sistema objetivo (el clúster) extrae activamente los cambios desde la fuente, en vez de recibirlos empujados |
| **Push-based** | Modelo donde un sistema externo (el pipeline de CI) empuja activamente los cambios hacia el sistema objetivo |
| **Reconciliation loop** | Ciclo continuo mediante el cual un agente compara el estado deseado (Git) contra el estado real y corrige cualquier diferencia |
| **Remote state** | State de Terraform almacenado fuera del disco local, en un backend compartido (ej. GitLab Managed Terraform State) con locking |
| **Rego** | Lenguaje de políticas usado por Open Policy Agent para expresar reglas de validación (`deny[]`, `allow`) |
| **Resource (Terraform)** | Bloque HCL que declara un recurso administrado por un provider (ej. `gitlab_project`) |
| **Sentinel** | Lenguaje de policy-as-code de HashiCorp para Terraform Cloud/Enterprise; equivalente comercial de OPA/Conftest |
| **Single source of truth** | Principio por el cual una única fuente (el repositorio Git) representa el estado deseado autoritativo del sistema |
| **State (Terraform)** | Archivo que mapea los recursos declarados en el código contra los recursos reales, identificándolos por su ID |
| **State locking** | Ver Lock |
| **Terraform Cloud/GitLab Managed Terraform State** | Servicios que alojan el state de Terraform de forma remota con locking automático; GitLab lo implementa vía backend `http` nativo |
| **Variables CI/CD como código** | Práctica de declarar variables de pipeline (`gitlab_project_variable`) en Terraform en vez de configurarlas manualmente en la UI |

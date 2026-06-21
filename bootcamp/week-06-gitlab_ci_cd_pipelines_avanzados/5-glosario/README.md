# Glosario — Semana 06: Pipelines Avanzados

| Termino | Definicion |
|---------|------------|
| **Variable** | Valor configurable que se inyecta en el pipeline; puede ser de proyecto, grupo o instancia |
| **Variable protegida** | Variable solo accesible en ramas protegidas (main, develop) |
| **Variable enmascarada** | Variable cuyo valor se oculta en los logs para proteger secretos |
| **rules** | Keyword moderna para definir condiciones de ejecucion de jobs (reemplaza only/except) |
| **only / except** | Keywords legacy para controlar ejecucion; se recomienda migrar a `rules` |
| **when** | Clausula que define cuando ejecutar: `on_success`, `manual`, `delayed`, `always`, `never` |
| **allow_failure** | Permite que un job falle sin detener ni bloquear el pipeline |
| **include** | Directiva para importar configuracion CI de otros archivos o proyectos |
| **include:local** | Incluye un archivo del mismo repositorio |
| **include:remote** | Incluye un archivo via URL (HTTP/HTTPS) |
| **include:template** | Incluye una plantilla oficial de GitLab |
| **include:project** | Incluye un archivo de otro proyecto en la misma instancia |
| **environment** | Define el destino del despliegue; rastrea historial de deployments |
| **deployment** | Registro de un despliegue exitoso a un environment |
| **trigger** | Mecanismo para iniciar un pipeline downstream desde otro proyecto |
| **parent-child pipeline** | Pipeline dividido en sub-pipelines controlados por un pipeline principal |
| **strategy: depend** | Configuracion de trigger que espera el resultado del pipeline downstream |
| **deployment freeze** | Periodo configurado donde se prohiben despliegues a ciertos entornos |
| **review app** | Entorno efimero creado por MR para revision manual antes del merge |

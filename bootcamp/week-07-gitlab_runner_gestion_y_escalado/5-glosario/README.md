# Glosario — Semana 07: GitLab Runner

| Termino | Definicion |
|---------|------------|
| **GitLab Runner** | Agente que ejecuta jobs de CI/CD; se instala en una maquina y se conecta a GitLab |
| **Registration Token** | Token usado para registrar un Runner en GitLab; se obtiene de Settings → CI/CD → Runners |
| **Runner Token** | Token unico asignado al Runner tras el registro; autentica la comunicacion con GitLab |
| **Executor** | Define el entorno donde se ejecuta el job: Docker, Shell, Kubernetes, VirtualBox, etc. |
| **Docker Executor** | Ejecuta cada job en un contenedor Docker aislado, con imagen configurable |
| **Shell Executor** | Ejecuta comandos directamente en la terminal del host, sin aislamiento |
| **Kubernetes Executor** | Ejecuta jobs en pods de Kubernetes; cada job es un pod efimero |
| **Shared Runner** | Runner disponible para todos los proyectos de la instancia GitLab |
| **Group Runner** | Runner disponible para todos los proyectos de un grupo y sus subgrupos |
| **Specific Runner** | Runner asignado exclusivamente a un proyecto |
| **Tags** | Etiquetas en Runners y jobs para enrutar correctamente la ejecucion |
| **config.toml** | Archivo de configuracion principal del GitLab Runner (ubicado en /etc/gitlab-runner/) |
| **concurrent** | Parametro en config.toml que define cuantos jobs simultaneos puede ejecutar un Runner |
| **DIND** | Docker-in-Docker; ejecutar comandos Docker desde dentro de un contenedor |
| **Autoscaler** | Componente que crea y destruye instancias de Runners dinamicamente segun la demanda |
| **Fleeting Plugin** | Interfaz del GitLab Runner Autoscaler con proveedores cloud (AWS, GCP, Azure) |
| **Job Routing** | Mecanismo por el cual GitLab asigna jobs a Runners basado en tags y disponibilidad |
| **Idle Time** | Tiempo de inactividad antes de que el autoscaler destruya una instancia de Runner |
| **Fair Queuing** | Algoritmo de cola que distribuye jobs entre multiples Runners compartidos de forma equitativa |

# Glosario — Semana 08: Container Registry y Package Registry

| Termino | Definicion |
|---------|------------|
| **Container Registry** | Registro de imagenes Docker integrado en GitLab; cada proyecto tiene su propio espacio |
| **Package Registry** | Registro de paquetes de software (npm, Maven, PyPI, NuGet, etc.) integrado en GitLab |
| **DIND** | Docker-in-Docker; ejecuta comandos Docker desde dentro de un contenedor Docker |
| **Kaniko** | Herramienta para construir imagenes Docker sin privilegios de root ni daemon Docker |
| **Buildah** | Alternativa rootless a Docker build; construye imagenes OCI sin daemon |
| **Multi-stage build** | Tecnica de Dockerfile que usa multiples FROM para separar build y runtime, reduciendo tamano |
| **CI_JOB_TOKEN** | Token temporal generado por GitLab para autenticar el job en el Container/ Package Registry |
| **CI_REGISTRY_IMAGE** | Variable predefinida con la URL completa de la imagen del proyecto en el Container Registry |
| **SemVer** | Semantic Versioning: formato MAJOR.MINOR.PATCH (ej: 1.2.3) para versionado de software |
| **Tag cleanup policy** | Politica automatica de limpieza de tags de imagenes antiguos en el Container Registry |
| **SAST** | Static Application Security Testing; analiza codigo fuente buscando vulnerabilidades |
| **Dependency Scanning** | Analiza dependencias del proyecto (npm, Maven, pip) buscando CVEs conocidos |
| **Container Scanning** | Escanea imagenes Docker en busca de vulnerabilidades en paquetes del sistema y dependencias |
| **Secret Detection** | Busca secretos expuestos (API keys, passwords, tokens) en el codigo fuente |
| **CVE** | Common Vulnerabilities and Exposures; identificador unico para una vulnerabilidad conocida |
| **Severity Threshold** | Umbral de severidad (Critical, High, Medium, Low) que determina si un escaneo falla o pasa |
| **Personal Access Token** | Token de acceso personal usado para autenticarse en el registry desde fuera de CI/CD |
| **Deploy Token** | Token con scopes especificos (read_registry, write_registry) para acceso automatizado al registry |
| **Registry External URL** | URL publica configurada en gitlab.rb para exponer el Container Registry |
| **Caching (Kaniko)** | Kaniko soporta cache de capas almacenando las en el mismo registry para acelerar rebuilds |

# 📖 Glosario — Semana 08: Container Registry y Package Registry

Términos ordenados alfabéticamente. Los términos marcados con ↗ remiten a conceptos relacionados en este glosario.

---

## B

**Buildah**
Herramienta de Red Hat para construir imágenes de contenedores compatibles con OCI sin requerir un daemon Docker ni modo privilegiado. Alternativa rootless a DinD para entornos RHEL/OpenShift. Usa `vfs` como storage driver en contenedores sin privilegios. Ver también: ↗ DinD, ↗ Kaniko.

---

## C

**CI_JOB_TOKEN**
Token temporal generado automáticamente por GitLab para cada job de CI/CD. Tiene acceso al Container Registry y Package Registry del proyecto. Expira al terminar el job. El método recomendado para autenticación en pipelines — no requiere credenciales manuales.

**CI_REGISTRY**
Variable predefinida que contiene la URL del Container Registry de la instancia GitLab (ej: `registry.example.com`). Se usa como argumento en `docker login`.

**CI_REGISTRY_IMAGE**
Variable predefinida con la URL completa de la imagen del proyecto en el Container Registry (ej: `registry.example.com/mi-grupo/mi-proyecto`). Se usa como prefijo para todos los tags de la imagen.

**CI_REGISTRY_USER**
Variable predefinida que contiene el usuario para autenticarse al Container Registry desde CI. Su valor es `gitlab-ci-token` (literal) — no es el username del developer.

**Container Registry**
Registro privado de imágenes Docker integrado en GitLab. Cada proyecto tiene su propio espacio en `registry.<host>/<namespace>/<proyecto>`. Requiere activación en `gitlab.rb` con `registry_external_url`. Ver también: ↗ Package Registry.

**Container Scanning**
Tipo de security scanning que analiza una imagen Docker en busca de CVEs en los paquetes del sistema operativo y librerías de runtime. Usa Trivy como motor de análisis por defecto. Requiere que la imagen esté publicada en el registry antes de ejecutarse. Forma parte del stage `security` del pipeline. Ver también: ↗ CVE, ↗ Trivy.

**CVE (Common Vulnerabilities and Exposures)**
Identificador único y estandarizado para vulnerabilidades de seguridad conocidas. Formato: `CVE-YYYY-NNNNN` (ej: `CVE-2021-44228` para Log4Shell). Los scanners de seguridad de GitLab contrastan el software de las imágenes y dependencias contra la base de datos de CVEs.

---

## D

**Dependency Scanning**
Tipo de security scanning que analiza las dependencias del proyecto (package.json, requirements.txt, pom.xml, etc.) buscando versiones con CVEs conocidos. No escanea código fuente ni imágenes Docker — solo el grafo de dependencias. Soporta npm, pip, Maven, Gradle, Bundler, Go modules, Composer, NuGet y Conan.

**Deploy Token**
Token con scopes específicos (read_registry, write_registry, read_package_registry, etc.) para acceso automatizado al Container Registry o Package Registry sin requerir credenciales de usuario. Ideal para servidores de producción, Kubernetes imagePullSecrets, o pipelines de proyectos externos. Diferente de ↗ CI_JOB_TOKEN (que es temporal) — el deploy token persiste hasta su expiración.

**DinD (Docker-in-Docker)**
Método para construir imágenes Docker dentro de un job de CI que ya corre en un contenedor Docker. Funciona levantando un daemon Docker adicional como servicio (`docker:dind`). Requiere `privileged = true` en el runner — riesgo de seguridad. Alternativa recomendada: ↗ Kaniko.

---

## G

**Garbage Collection (Registry)**
Proceso de recuperación de espacio en disco en el Container Registry eliminando layers (capas) de imágenes que ya no son referenciadas por ningún tag. Eliminar un tag con la API libera la referencia, pero el garbage collection es necesario para recuperar el espacio físico. Se ejecuta con `gitlab-ctl registry-garbage-collect` en GitLab Omnibus.

**Generic Package**
Formato del Package Registry de GitLab para archivos arbitrarios que no encajan en ningún formato específico (npm, Maven, PyPI, etc.). Se publica y descarga via API REST. Útil para binarios compilados, scripts, configuraciones versionadas.

---

## K

**Kaniko**
Herramienta de Google para construir imágenes Docker sin necesitar un daemon Docker ni modo privilegiado. Ejecuta las instrucciones del Dockerfile en el filesystem del propio contenedor y sube la imagen resultante directamente al registry. Soporta cache de capas en el mismo registry. Método recomendado para Kubernetes Executor y entornos sin `privileged = true`. Ver también: ↗ DinD, ↗ Buildah.

---

## M

**Multi-stage Build**
Técnica de Dockerfile que usa múltiples instrucciones `FROM` para separar el entorno de compilación del entorno de ejecución. El stage de build puede incluir compiladores, devDependencies y herramientas de construcción; el stage de runtime solo contiene lo necesario para ejecutar la aplicación. Reduce significativamente el tamaño de la imagen final (típicamente 5×-10× más pequeña).

---

## O

**OCI (Open Container Initiative)**
Estándar abierto para formatos de contenedores e imágenes. Las imágenes Docker son compatibles con OCI. El formato OCI define la estructura de los manifests, layers y configuración de imágenes. Herramientas como Buildah generan imágenes OCI que son compatibles con Docker y Kubernetes.

**OCI Labels**
Metadatos estandarizados según la especificación `org.opencontainers.image.*` que se pueden embeber en imágenes Docker. Incluyen: `revision` (commit SHA), `created` (fecha de build), `source` (URL del repositorio), `version` (versión semántica). Permiten trazabilidad: dado cualquier imagen, puedo encontrar el commit exacto que la generó.

---

## P

**Package Registry**
Registro de paquetes de software integrado en GitLab que soporta múltiples formatos: npm, Maven, PyPI, NuGet, Conan, Composer, Helm, Generic y Terraform Modules. Cada proyecto tiene su propio espacio en `Deploy → Package Registry`. Diferente del ↗ Container Registry — almacena librerías y paquetes, no imágenes ejecutables.

**Personal Access Token (PAT)**
Token de acceso personal que un usuario de GitLab puede crear en `Settings → Access Tokens`. Para el Container Registry, necesita los scopes `read_registry` y/o `write_registry`. Para el Package Registry, necesita `read_api`, `write_api` o los scopes específicos. Diferente de ↗ CI_JOB_TOKEN (que es temporal por job) y ↗ Deploy Token (que es por proyecto).

**Pull Policy**
Configuración del runner que determina cuándo hacer pull de una imagen Docker: `always` (siempre descarga), `never` (solo usa local), `if-not-present` (pull solo si no existe localmente). El valor `if-not-present` reduce el tiempo de build al reusar imágenes en caché, pero puede usar versiones desactualizadas si la imagen base fue actualizada.

---

## R

**Registry External URL**
Parámetro en `gitlab.rb` (`registry_external_url`) que define la URL pública del Container Registry. Puede ser el mismo host que GitLab con puerto diferente (ej: `http://localhost:5050`) o un dominio separado (ej: `https://registry.mi-empresa.com`).

---

## S

**SAST (Static Application Security Testing)**
Tipo de security scanning que analiza el código fuente sin ejecutarlo, buscando patrones de código inseguro: SQL injection, XSS, path traversal, deserialization insegura, credenciales hardcodeadas, etc. GitLab activa automáticamente el analizador correcto según el lenguaje detectado (Bandit para Python, Semgrep para múltiples lenguajes, Gosec para Go, etc.).

**Secret Detection**
Tipo de security scanning que busca credenciales, tokens y secretos en el código fuente y en el historial de commits. Detecta: AWS keys, tokens de GitHub/GitLab/Slack, passwords hardcodeadas, URLs con credenciales embebidas. Escanea el historial completo de git — detecta secretos eliminados en commits posteriores.

**SemVer (Semantic Versioning)**
Convención de versionado con formato `MAJOR.MINOR.PATCH` (ej: `1.2.3`). MAJOR: cambio incompatible de API. MINOR: nueva funcionalidad compatible. PATCH: corrección de bugs compatible. En GitLab, los tags SemVer (ej: `v1.2.3`) típicamente disparan jobs de publish en el Package Registry y tags permanentes en el Container Registry.

**Severity Threshold**
Umbral de severidad configurable en los scanners de seguridad de GitLab. Determina a partir de qué nivel de severidad (Critical, High, Medium, Low) el job de scanning falla el pipeline. Ejemplo: `CS_SEVERITY_THRESHOLD: "high"` hace que el Container Scanning falle solo si encuentra vulnerabilidades HIGH o CRITICAL.

---

## T

**Tag (Container Registry)**
Etiqueta que apunta a una versión específica de una imagen Docker en el registry. Un mismo SHA de imagen puede tener múltiples tags. Los tags pueden ser inmutables (SHA de commit: `a1b2c3d4`) o movibles (branch: `main`, `latest`). Ver también: ↗ Tag Cleanup Policy.

**Tag Cleanup Policy**
Política automática de limpieza de tags en el Container Registry de GitLab. Se configura en `Settings → Packages & Registries → Cleanup policies`. Permite especificar: cuántos tags mantener por imagen, patrón regex de tags a conservar (ej: `v\d+\.\d+\.\d+`), antigüedad mínima para eliminar. Se ejecuta periódicamente según la cadencia configurada.

**Trivy**
Motor de análisis de vulnerabilidades de código abierto desarrollado por Aqua Security. Es el scanner por defecto del Container Scanning de GitLab (reemplazó a Clair). Analiza paquetes del sistema operativo y librerías de aplicación en imágenes Docker contra múltiples fuentes de CVEs (NVD, RHSA, Debian Security Advisories, etc.).

---

## V

**Vulnerability Report**
Vista consolidada en `Proyecto → Secure → Vulnerability Report` que muestra todas las vulnerabilidades detectadas por los scanners de seguridad. Permite gestionar el ciclo de vida de cada vulnerabilidad: confirmarla, dismissarla con una razón, o marcarla como resuelta. Las vulnerabilidades dismissadas no vuelven a aparecer como nuevas en el widget del MR.

---

⬅️ **Proyecto:** [3-proyecto/README.md](../3-proyecto/README.md)
➡️ **Rúbrica:** [rubrica-evaluacion.md](../rubrica-evaluacion.md)

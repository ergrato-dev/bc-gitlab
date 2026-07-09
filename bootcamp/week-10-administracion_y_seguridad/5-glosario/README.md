# Glosario — Semana 10: Administración y Seguridad

Términos ordenados alfabéticamente. Los términos marcados con ↗ remiten a conceptos relacionados en este glosario.

---

## A

**Access Level**
Valor numérico que representa el nivel de permiso de un usuario en un proyecto o grupo de GitLab. Los valores estándar son 10 (Guest), 20 (Reporter), 30 (Developer), 40 (Maintainer), 50 (Owner). La API usa estos valores numéricos directamente. Ver también: ↗ RBAC.

**AGPL (Affero General Public License)**
Licencia copyleft fuerte que extiende GPL para cubrir también software distribuido como servicio (SaaS). Si tu software usa una librería AGPL y lo distribuyes como servicio web, debes publicar tu código fuente. Especialmente problemática para startups SaaS. Ver también: ↗ Copyleft, ↗ GPL.

**Audit Event**
Registro inmutable de una acción relevante de seguridad realizada en GitLab. Incluye: quién lo hizo, qué hizo, cuándo, desde qué IP, en qué entidad. Accesibles desde Admin Area → Monitoring → Audit Events y via API `/audit_events`. En GitLab CE los audit events son básicos; EE añade retención prolongada y exportación avanzada.

---

## B

**Backup Code**
Código de recuperación de un solo uso generado al configurar MFA. GitLab genera 10 backup codes; cada uno puede usarse una vez si el usuario no tiene acceso a su app TOTP (dispositivo perdido, desinstalado, etc.). Deben guardarse en un lugar seguro separado del dispositivo MFA. Ver también: ↗ MFA, ↗ TOTP.

**Bandit**
Analizador de seguridad estático para Python, usado por GitLab SAST. Detecta vulnerabilidades como inyección de comandos (B602), deserialización insegura (B301), contraseñas hardcodeadas (B105), uso de MD5/SHA1 para hashing de contraseñas (B303), y más. Clasificaciones: B (bandit ID), nivel de severidad (Low/Medium/High) y confianza. Ver también: ↗ SAST.

---

## C

**CI_JOB_TOKEN**
Token de autenticación temporal generado automáticamente por GitLab para cada job de CI/CD. Tiene acceso limitado al proyecto actual y a proyectos configurados explícitamente. Debe usarse en lugar de PATs para operaciones dentro del pipeline (clonar dependencias privadas, hacer push al registry). Ver también: ↗ PAT.

**Compliance Pipeline**
Pipeline definido en un repositorio del grupo que GitLab inyecta automáticamente en todos los pipelines de los proyectos del grupo. Los desarrolladores no pueden modificarlo ni omitirlo, garantizando checks de seguridad uniformes (SAST, code review, etc.). Disponible nativamente en GitLab EE; en CE se puede implementar parcialmente con hooks. Ver también: ↗ Compliance Framework.

**Container Scanning**
Análisis de imágenes Docker en busca de CVEs en los paquetes del sistema operativo base y en las librerías instaladas. GitLab CE incluye el template `Security/Container-Scanning.gitlab-ci.yml`. Usa analizadores como Trivy o Grype. Complementario a ↗ Dependency Scanning: Container Scanning analiza la imagen compilada, Dependency Scanning analiza las dependencias del código fuente.

**Copyleft**
Licencia de software que exige que las obras derivadas se distribuyan bajo la misma licencia. Existe en dos variantes: **fuerte** (GPL, AGPL — todo el software que incorpore la librería debe ser GPL) y **débil** (LGPL, MPL — solo los cambios a la librería deben publicarse, el software que la usa puede ser propietario). Ver también: ↗ GPL, ↗ AGPL, ↗ LGPL, ↗ License Compliance.

**Cosign**
Herramienta del proyecto Sigstore (CNCF) para firmar y verificar imágenes de contenedor y otros artefactos OCI. Soporta firma con clave estática (`cosign sign --key`) o keyless (identidad OIDC del pipeline CI, certificado efímero emitido por Fulcio, registrado en el transparency log Rekor). Cierra el gap entre "imagen escaneada sin CVEs" e "imagen no alterada en el registry". Ver también: ↗ Image Signing, ↗ Container Scanning.

**CVE (Common Vulnerabilities and Exposures)**
Identificador único y estándar para vulnerabilidades de seguridad conocidas. Formato: `CVE-YYYY-NNNNN`. Ejemplos famosos: CVE-2021-44228 (Log4Shell), CVE-2022-22965 (Spring4Shell). Las bases de datos NVD (NIST) y OSV (Google) indexan CVEs con severidad CVSS y versiones afectadas/corregidas. Ver también: ↗ Dependency Scanning, ↗ CVSS.

**CVSS (Common Vulnerability Scoring System)**
Sistema estándar para calificar la severidad de vulnerabilidades de seguridad. Escala del 0 al 10: Critical (9.0-10.0), High (7.0-8.9), Medium (4.0-6.9), Low (0.1-3.9). Considera factores como vector de ataque, complejidad, privilegios requeridos e impacto. GitLab usa CVSS para clasificar hallazgos de SAST y Dependency Scanning.

**CWE (Common Weakness Enumeration)**
Diccionario categorizado de debilidades de software y hardware. Diferente de ↗ CVE: CVE es una vulnerabilidad específica en un producto concreto, CWE es la categoría de debilidad que la causó. Ejemplos: CWE-89 (SQL Injection), CWE-79 (XSS), CWE-798 (Hardcoded Credentials). Los reportes SAST de GitLab incluyen el CWE para cada hallazgo.

---

## D

**DAST (Dynamic Application Security Testing)**
Análisis de seguridad de la aplicación en ejecución, simulando ataques HTTP reales. Complementa ↗ SAST: SAST analiza el código sin ejecutarlo, DAST analiza el comportamiento en runtime. Detecta XSS, CSRF, SQL Injection, directory traversal y otras vulnerabilidades solo visibles en ejecución. GitLab Ultimate incluye DAST oficial; en CE se puede usar OWASP ZAP manualmente. Ver también: ↗ SAST.

**Deploy Key**
Clave SSH sin usuario asociado que otorga acceso de lectura (o lectura/escritura) a un repositorio específico. Ideal para servidores de producción que necesitan clonar el repositorio. No expira con el usuario ni requiere cuentas de servicio. Ver también: ↗ Deploy Token, ↗ PAT.

**Deploy Token**
Credencial username+password generada por GitLab para acceso a repositorios y container registry sin SSH. A diferencia de un ↗ PAT, no está asociado a un usuario real y puede tener fecha de expiración. Usado para acceso desde scripts de despliegue o sistemas de CD. Ver también: ↗ Deploy Key.

**Dependency Scanning**
Análisis de las dependencias declaradas en archivos de lock (`package-lock.json`, `Gemfile.lock`, `requirements.txt`, `go.sum`, etc.) para identificar CVEs conocidos. Usa la base de datos de vulnerabilidades de GitLab (Gemnasium). El template `Security/Dependency-Scanning.gitlab-ci.yml` está disponible en GitLab CE. Ver también: ↗ CVE, ↗ SBOM.

---

## G

**Gemnasium**
Base de datos de vulnerabilidades de GitLab usada por Dependency Scanning. Agrega datos de múltiples fuentes (NVD, GitHub Advisory Database, OSV) y los correlaciona con versiones específicas de paquetes en múltiples ecosistemas (npm, pip, Maven, Bundler, etc.). Se actualiza continuamente.

**GitLab Duo**
Conjunto de features de inteligencia artificial de GitLab: Code Suggestions (autocompletado de código), Duo Chat (asistente conversacional), Vulnerability Explanation, entre otros. La mayoría requiere licencia GitLab EE/Ultimate y, para varias capacidades, GitLab.com SaaS o GitLab Duo Self-Hosted — no está disponible en una instancia CE self-managed sin licencia adicional. Fuera del alcance de este bootcamp, centrado en GitLab CE self-managed.

**GPL (General Public License)**
Licencia copyleft fuerte. La versión 2 (GPL-2.0) y versión 3 (GPL-3.0) exigen que cualquier software que incorpore o enlace con código GPL sea también GPL. Populares en Linux, MySQL, WordPress. Incompatibles con software propietario sin excepciones explícitas. Ver también: ↗ AGPL, ↗ Copyleft, ↗ License Compliance.

**Grace Period (MFA)**
Período de tiempo (en horas) que GitLab permite a los usuarios para configurar MFA después de que el administrador activa la obligatoriedad. Durante el grace period, el usuario puede hacer login con contraseña, pero ve un banner de advertencia. Al expirar el grace period, el sistema redirige obligatoriamente a la pantalla de configuración de MFA. Típicamente 24-72 horas. Ver también: ↗ MFA.

**Grype**
Escáner de vulnerabilidades de imágenes de contenedor open source mantenido por Anchore. Alternativa a ↗ Trivy: analiza paquetes de sistema operativo y dependencias de aplicación dentro de una imagen, genera reportes en JSON/SARIF/CycloneDX. No es el scanner por defecto del template oficial de GitLab Container Scanning (ese usa Trivy), pero se puede integrar en un job custom como segunda fuente de verdad. Ver también: ↗ Container Scanning, ↗ Trivy.

**Guest**
Rol mínimo en GitLab (valor numérico: 10). Puede: ver y descargar el código fuente si el proyecto es público/internal, ver y comentar en issues, descargar releases. No puede: clonar repositorios privados, ver pipelines, hacer push. Útil para clientes externos que necesitan seguimiento de issues sin acceso al código. Ver también: ↗ RBAC.

---

## I

**Image Signing**
Práctica de firmar criptográficamente una imagen de contenedor para garantizar su integridad y procedencia: la imagen desplegada es exactamente la que construyó el pipeline, no una alterada o reemplazada en el registry. Herramienta de referencia: ↗ Cosign (Sigstore). Habilita enforcement en el clúster (rechazar imágenes sin firma válida) y es requisito creciente de marcos de cadena de suministro (SLSA, NIST SSDF). Ver también: ↗ SBOM.

**IP Restriction**
Configuración de GitLab que limita el acceso a la instancia (UI y API) a rangos de IP específicos en notación CIDR. Los accesos desde IPs no autorizadas reciben HTTP 404 (no 403), para no revelar la existencia del recurso. Configurable desde Admin Area → Settings → Network. Debe usarse con VPN para no bloquear trabajo remoto.

---

## L

**LDAP (Lightweight Directory Access Protocol)**
Protocolo estándar para acceder a directorios de usuarios corporativos (Active Directory, OpenLDAP). GitLab CE soporta autenticación LDAP: los usuarios pueden hacer login con sus credenciales corporativas. La sincronización automática de grupos LDAP a grupos GitLab requiere GitLab EE. Ver también: ↗ SAML.

**LGPL (Lesser General Public License)**
Licencia copyleft débil. Los cambios a la propia librería LGPL deben publicarse, pero el software que la usa puede ser propietario si se enlaza dinámicamente. Permite uso en software comercial, lo que la hace más flexible que ↗ GPL. Ver también: ↗ Copyleft, ↗ License Compliance.

**License Compliance**
Proceso de identificar las licencias de las dependencias de un proyecto y verificar que cumplan con las políticas corporativas (qué licencias están aprobadas, cuáles rechazadas). GitLab incluye el template `Security/Dependency-Scanning.gitlab-ci.yml` que también genera el reporte de licencias en formato SPDX. Ver también: ↗ SPDX, ↗ SBOM.

---

## M

**Maintainer**
Rol de liderazgo técnico en GitLab (valor numérico: 40). Puede: hacer merge a protected branches, gestionar CI/CD (variables, runners), añadir y remover miembros del proyecto, modificar settings del proyecto, gestionar protected branches y tags. No puede: eliminar el proyecto, transferirlo, o gestionar compliance. Ideal para tech leads. Ver también: ↗ RBAC.

**MFA (Multi-Factor Authentication)**
Autenticación que requiere dos o más factores independientes: algo que sabes (contraseña), algo que tienes (dispositivo TOTP), algo que eres (biometría). GitLab CE soporta MFA via ↗ TOTP. El admin puede forzarlo con `Enforce two-factor authentication` y configurar un ↗ Grace Period. Ver también: ↗ TOTP, ↗ Backup Code.

---

## O

**Owner**
Rol con acceso total en GitLab (valor numérico: 50). Puede hacer todo lo que un Maintainer más: eliminar el proyecto o grupo, transferirlo a otro namespace, gestionar compliance frameworks, impersonar miembros. Solo debe asignarse a responsables directos del grupo/proyecto. Ver también: ↗ RBAC, ↗ Maintainer.

**OWASP Top 10**
Lista de las 10 categorías de riesgo de seguridad más críticas en aplicaciones web, publicada por OWASP (Open Web Application Security Project). Actualizada periódicamente (2021 es la versión actual). Incluye: Broken Access Control, Cryptographic Failures, Injection (SQL, XSS), Insecure Design, Security Misconfiguration, Vulnerable Components, etc. Los analizadores SAST de GitLab mapean sus hallazgos al OWASP Top 10. Ver también: ↗ SAST, ↗ CWE.

---

## P

**PAT (Personal Access Token)**
Token de autenticación generado por un usuario en GitLab, con scopes específicos y fecha de expiración opcional. Alternativa a SSH para operaciones API y Git HTTPS. Scopes principales: `api` (todo), `read_api` (solo lectura), `read_repository`, `write_repository`, `read_registry`, `write_registry`. Deben tener expiración máxima (recomendado 90 días). Ver también: ↗ Deploy Key, ↗ Deploy Token.

**Personal Access Token** → Ver ↗ PAT.

**Protected Branch**
Rama del repositorio con restricciones configurables sobre quién puede hacer push directo, merge y force push. Se configura con patrones (ej: `main`, `release/*`) y niveles de acceso separados para push y merge. La política más restrictiva: push level 0 (nadie puede pushear directamente) + merge level 40 (solo Maintainers). Ver también: ↗ RBAC.

---

## R

**RBAC (Role-Based Access Control)**
Modelo de control de acceso donde los permisos se asignan a roles, y los usuarios se asignan a roles. En GitLab, los 5 roles son: Guest (10), Reporter (20), Developer (30), Maintainer (40), Owner (50). Se aplican en tres niveles: instancia (Admin global), grupo y proyecto. Los permisos se heredan del grupo padre al proyecto hijo. Ver también: ↗ Access Level.

**Reporter**
Rol de solo lectura extendida en GitLab (valor numérico: 20). Puede: clonar repositorios, ver issues y crear comentarios, ver pipelines y sus logs, descargar artifacts, ver analytics. No puede: hacer push, crear MRs, ejecutar pipelines. Adecuado para QA que solo hace testing manual, o para stakeholders que necesitan seguimiento. Ver también: ↗ RBAC.

---

## S

**SAML (Security Assertion Markup Language)**
Protocolo de federación de identidad que permite Single Sign-On (SSO) entre proveedores de identidad (IdP: Okta, Azure AD, Google Workspace) y proveedores de servicio (SP: GitLab). La integración SAML completa (sincronización de grupos, JIT provisioning) es GitLab EE. GitLab CE soporta autenticación SAML básica. Ver también: ↗ LDAP.

**SAST (Static Application Security Testing)**
Análisis del código fuente en busca de vulnerabilidades de seguridad, sin ejecutar la aplicación. GitLab CE incluye múltiples analizadores: Bandit (Python), Semgrep, ESLint Security (JS), Brakeman (Ruby), Gosec (Go), SpotBugs (Java). Se activa con `template: Security/SAST.gitlab-ci.yml`. El reporte se guarda en `gl-sast-report.json`. Ver también: ↗ DAST, ↗ CWE, ↗ OWASP Top 10.

**SBOM (Software Bill of Materials)**
Inventario completo y estructurado de todos los componentes de software de un producto: nombre, versión, licencia, origen. Análogo a la lista de ingredientes de un producto alimenticio. Formatos estándar: ↗ CycloneDX (OWASP, enfocado en seguridad) y ↗ SPDX (Linux Foundation, enfocado en licencias). Requisito regulatorio creciente (EO 14028 USA, CRA Europa). Ver también: ↗ Dependency Scanning.

**Secret Detection**
Herramienta de GitLab que detecta secretos hardcodeados (API keys, tokens, contraseñas, claves privadas) en el código fuente y en el historial de commits. Analiza más de 100 patrones: AWS, GCP, Azure, GitHub, GitLab, Stripe, JWT, RSA private keys, etc. Se activa con `template: Security/Secret-Detection.gitlab-ci.yml`. El escaneo histórico (`SECRET_DETECTION_HISTORIC_SCAN: "true"`) analiza todo el historial de git. Ver también: ↗ SAST.

**SOC2 (System and Organization Controls 2)**
Marco de auditoría de seguridad desarrollado por el AICPA para empresas de servicios tecnológicos. Define controles en 5 Trust Service Criteria: Seguridad, Disponibilidad, Integridad del procesamiento, Confidencialidad, Privacidad. SOC2 Type II verifica que los controles funcionan efectivamente durante un período (mínimo 6 meses). GitLab puede ser parte de los controles: RBAC, audit events, MR approvals, etc.

**SPDX (Software Package Data Exchange)**
Estándar ISO/IEC 5962:2021 para describir licencias de software de forma consistente y legible por máquinas. Define un conjunto de identificadores SPDX para cada licencia conocida (ej: `MIT`, `Apache-2.0`, `GPL-3.0`). GitLab usa identificadores SPDX en sus reportes de License Compliance para comparar contra políticas. Ver también: ↗ License Compliance, ↗ SBOM.

---

## T

**TOTP (Time-based One-Time Password)**
Algoritmo estándar (RFC 6238) que genera contraseñas temporales de 6 dígitos basadas en un secreto compartido y el tiempo actual (renovadas cada 30 segundos). Base de todas las apps de autenticación compatibles: Google Authenticator, Authy, Bitwarden, 1Password, Microsoft Authenticator. GitLab usa TOTP como implementación de ↗ MFA. Ver también: ↗ Backup Code.

**Trivy**
Escáner de vulnerabilidades open source de Aqua Security, usado por defecto en el template oficial `Security/Container-Scanning.gitlab-ci.yml` de GitLab (desde GitLab 15.0, en reemplazo de Clair). Analiza imágenes de contenedor, sistemas de archivos y repositorios Git en busca de CVEs en paquetes de SO y dependencias de aplicación. Ver también: ↗ Grype, ↗ Container Scanning.

---

## V

**Vulnerability Report**
Dashboard de GitLab (Security → Vulnerability Report) que centraliza todos los hallazgos de seguridad de un proyecto: SAST, Secret Detection, Dependency Scanning, Container Scanning. Permite gestionar el ciclo de vida de cada vulnerabilidad: detectada → confirmada → remediada → descartada (con motivo). En GitLab CE el dashboard es por proyecto; EE agrega una vista organizacional centralizada.

---

## W

**Wildcard (Protected Branch)**
Patrón con comodines para proteger múltiples ramas con una sola regla. Ejemplos: `release/*` protege `release/1.0`, `release/2.0`, etc.; `hotfix/*` protege todas las ramas de hotfix. GitLab evalúa las reglas de más específica a más general — una rama que coincide con múltiples patrones usa el nivel de la regla más específica.

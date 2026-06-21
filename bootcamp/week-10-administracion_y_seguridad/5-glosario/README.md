# Glosario — Semana 10

| Término | Definición |
|---------|-----------|
| **RBAC** | Role-Based Access Control: control de acceso basado en roles que define qué puede hacer cada usuario según su rol asignado |
| **Guest** | Rol mínimo en GitLab (nivel 10): puede ver issues y dejar comentarios, pero no acceder al código |
| **Reporter** | Rol de solo lectura extendida (nivel 20): puede clonar repositorios, ver pipelines y analytics |
| **Developer** | Rol de desarrollador (nivel 30): puede hacer push, crear MRs, gestionar issues |
| **Maintainer** | Rol de liderazgo técnico (nivel 40): puede mergear a protected branches, gestionar CI/CD, añadir miembros |
| **Owner** | Propietario del grupo/proyecto (nivel 50): control total incluyendo eliminación y transferencia |
| **Protected Branch** | Rama protegida con restricciones de quién puede hacer push, merge o force push |
| **MFA** | Multi-Factor Authentication: autenticación que requiere dos o más factores (contraseña + código TOTP) |
| **TOTP** | Time-based One-Time Password: algoritmo que genera códigos temporales para MFA |
| **SAST** | Static Application Security Testing: análisis de seguridad del código fuente sin ejecutarlo |
| **Secret Detection** | Herramienta que detecta secretos hardcodeados (tokens, contraseñas, claves) en el código |
| **DAST** | Dynamic Application Security Testing: análisis de seguridad de la aplicación en ejecución |
| **Dependency Scanning** | Análisis de dependencias del proyecto para identificar vulnerabilidades conocidas (CVEs) |
| **License Compliance** | Verificación de que las licencias de las dependencias cumplen con las políticas de la organización |
| **Compliance Pipeline** | Pipeline definido a nivel de grupo que se inyecta en todos los proyectos para garantizar cumplimiento |
| **Audit Event** | Registro de acciones realizadas en GitLab (login, cambios de permisos, modificaciones de configuración) |
| **IP Restriction** | Limitación de acceso a GitLab solo desde rangos de IP específicos (IP whitelist) |
| **SBOM** | Software Bill of Materials: inventario de todos los componentes y dependencias de un proyecto |
| **SPDX** | Software Package Data Exchange: estándar para identificar licencias de software de forma consistente |
| **CVE** | Common Vulnerabilities and Exposures: identificador estándar para vulnerabilidades conocidas |
| **Grace Period** | Período de gracia en horas que tienen los usuarios para activar MFA antes de ser bloqueados |

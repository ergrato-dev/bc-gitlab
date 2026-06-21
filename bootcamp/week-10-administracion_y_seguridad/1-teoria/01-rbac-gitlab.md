# 01 — RBAC en GitLab: Roles, Permisos y Control de Acceso

El control de acceso basado en roles (RBAC) es el mecanismo mediante el cual GitLab gestiona quién puede hacer qué en la plataforma. Se aplica en tres niveles: instancia, grupo y proyecto.

## Niveles de acceso

| Rol | Proyecto | Grupo | Descripción |
|-----|----------|-------|-------------|
| Guest (10) | Ver issues, dejar comentarios | Ver grupo y proyectos | Mínimo acceso |
| Reporter (20) | Clonar repo, ver pipelines, ver analytics | Ver members | Solo lectura extendida |
| Developer (30) | Push, crear MRs, gestionar issues | Acceso completo a desarrollo | Rol estándar de dev |
| Maintainer (40) | Merge a protected branches, gestionar CI/CD | Gestionar subgrupos | Liderazgo técnico |
| Owner (50) | Todo, incluyendo eliminar proyecto | Transferir grupo, eliminar | Propietario total |

## Permisos de Administrador

El rol `Admin` es global (no por proyecto/grupo) y otorga acceso total a todas las funciones administrativas: gestionar usuarios, ver todos los proyectos, modificar configuraciones de la instancia, impersonar usuarios y acceder al admin area.

## Protected Branches y Tags

Las ramas protegidas restringen quién puede hacer push, merge o force push. Se configuran con patrones (ej: `main`, `release/*`) y se asignan roles permitidos. Esto es crítico para flujos GitFlow y GitHub Flow con revisión obligatoria.

## Integración LDAP/SAML (EE, referencia)

Aunque LDAP y SAML son features Enterprise, GitLab CE permite sincronización básica con LDAP para autenticación. La configuración se realiza en `gitlab.rb` mediante los parámetros `ldap_servers`. Para SAML se requiere la edición Enterprise.

## Mejores prácticas RBAC

- Aplicar el principio de mínimo privilegio
- Usar grupos para gestionar permisos en lote
- Revisar membresías periódicamente
- Documentar la matriz de roles y responsabilidades
- Configurar protected branches con revisores obligatorios

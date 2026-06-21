# 02 — Seguridad de Cuenta: MFA, IP Restrictions y Auditoría

Proteger las cuentas de usuario es la primera línea de defensa en una plataforma DevOps. GitLab ofrece múltiples capas de seguridad a nivel de cuenta.

## Autenticación de Dos Factores (MFA)

GitLab CE soporta MFA mediante TOTP (Time-based One-Time Password) usando aplicaciones como Google Authenticator, Authy o Bitwarden. La configuración se realiza por usuario en Settings → Account → Two-Factor Authentication. Una vez habilitado, cada inicio de sesión requiere el código TOTP además de la contraseña.

El administrador puede hacer obligatorio el MFA desde Admin Area → Settings → General → Sign-up restrictions, marcando "Enforce two-factor authentication". Se puede configurar un período de gracia en horas para que los usuarios activen MFA antes de ser bloqueados.

## Restricciones de IP

En el Admin Area se puede configurar una lista blanca de rangos IP permitidos para acceder a la interfaz web y API. Esto es útil para limitar el acceso solo a la red corporativa o VPN. Los intentos desde IPs no autorizadas reciben HTTP 404 (no 403, para no revelar la existencia del recurso).

## Eventos de Auditoría

GitLab registra eventos de auditoría accesibles desde Admin Area → Monitoring → Audit Events. Los eventos incluyen: inicios de sesión, cambios de contraseña, cambios en permisos, adición/remoción de miembros, cambios en configuraciones de proyecto y más. En CE, los logs están disponibles vía interfaz y vía API (`/audit_events`).

## Claves SSH y Tokens de Acceso

Los usuarios pueden gestionar múltiples claves SSH con fechas de expiración. Como administrador, se puede forzar expiración de claves SSH desde la configuración general. Los Personal Access Tokens también deben revisarse periódicamente para identificar tokens inactivos o con scopes excesivos.

## Buenas Prácticas

- Forzar MFA para todos los usuarios con acceso a producción
- Restringir acceso IP al admin area
- Revisar audit events semanalmente
- Configurar expiración de tokens por defecto (máximo 90 días)
- Deshabilitar registro público si no es necesario

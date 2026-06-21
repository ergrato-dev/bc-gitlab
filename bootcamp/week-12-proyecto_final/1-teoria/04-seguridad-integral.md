# 04 — Stack de Seguridad Integral

La seguridad en el proyecto final debe cubrir cuatro dimensiones: pipeline, plataforma, acceso y datos.

## Seguridad en Pipeline

Integrar todos los escáneres disponibles en CE:
```yaml
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
```

Configurar umbrales para bloquear merges si hay vulnerabilidades críticas. En Settings → Merge requests → Merge checks, habilitar "Security approvals are required".

## Seguridad de Plataforma

**HTTPS obligatorio**: Configurar certificados TLS. En laboratorio se puede usar certificados auto-firmados. Para producción real, Let's Encrypt con certbot en un reverse proxy Nginx externo.

**Actualizaciones**: Documentar el proceso de actualización de GitLab CE. Usar siempre versiones específicas (`16.11.0-ce.0`), nunca `latest`.

**Red**: Exponer solo los puertos necesarios (443 para web, 2222 para SSH). Todo lo demás (PostgreSQL 5432, Redis 6379, Prometheus 9090) solo en red interna Docker.

## Seguridad de Acceso

**RBAC mínimo**:
- Administradores: 1-2 personas con rol Owner en el grupo raíz
- Developers: rol Developer en sus proyectos
- Lectura externa: rol Reporter (solo lectura de código)
- CI/CD: Project Access Tokens con scope mínimo

**MFA**: Habilitar y forzar desde Admin Area. Documentar el procedimiento de recuperación de MFA para administradores.

**Tokens**: Todos los tokens deben tener fecha de expiración. Auditar tokens activos semanalmente con script Python o consulta API.

## Seguridad de Datos

**Backup encriptado**: El backup de GitLab contiene datos sensibles (código fuente, base de datos con usuarios, issues). Si se sincroniza a S3, habilitar server-side encryption (SSE-S3 o SSE-KMS).

**Secretos**: `gitlab-secrets.json` debe respaldarse por separado y almacenarse en un gestor de secretos (Vault, 1Password, Bitwarden). Sin este archivo, los CI/CD variables encriptadas son irrecuperables.

**Variables CI/CD**: Revisar que todas las variables sensibles estén marcadas como "Masked" y "Protected". Las variables desprotegidas pueden ser leídas por cualquier rama, incluyendo forks.

## Verificación final

Antes de la entrega, ejecutar este checklist de seguridad:
- [ ] `curl -k https://gitlab.local` responde con HTTPS
- [ ] SAST job se ejecuta en cada pipeline
- [ ] Secret Detection no tiene falsos positivos sin revisar
- [ ] MFA requerido para todos los usuarios
- [ ] No hay usuarios sin grupo asignado
- [ ] `gitlab-secrets.json` respaldado fuera del backup automático
- [ ] Logs de auditoría accesibles vía API

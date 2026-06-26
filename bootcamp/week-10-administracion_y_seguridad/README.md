# Semana 10 — Administración y Seguridad

## Objetivos

- Administrar usuarios, grupos y permisos (RBAC)
- Configurar políticas de seguridad (MFA, IP restrictions)
- Implementar seguridad en pipelines (SAST, Secret Detection)
- Auditar actividad y compliance
- Gestionar licencias y dependencias

> **GitLab CE vs EE — features de seguridad disponibles:**
>
> | Feature | CE | EE/Ultimate |
> |---------|:--:|:-----------:|
> | SAST (via template `.gitlab-ci.yml`) | ✅ | ✅ |
> | Secret Detection (via template) | ✅ | ✅ |
> | Dependency Scanning (via template) | ✅ | ✅ |
> | Container Scanning (via template) | ✅ | ✅ |
> | DAST (Dynamic Application Security Testing) | ❌ | ✅ |
> | License Compliance avanzado (UI) | ❌ | ✅ |
> | Security Dashboard centralizado | ❌ | ✅ |
> | Compliance Pipelines (enforcement) | ❌ | ✅ |
>
> Los escaneos disponibles en CE se activan incluyendo los templates oficiales en `.gitlab-ci.yml`. No hay dashboard centralizado de seguridad en CE.

## Requisitos Previos

- GitLab CE administración básica
- CI/CD funcional

## Estructura de la Semana

| Componente | Tiempo | Descripción |
|-----------|--------|-------------|
| Teoría | 2h | RBAC, seguridad, compliance, auditoría |
| Prácticas | 3h | Configurar políticas, escaneos |
| Proyecto | 1h | Plan de seguridad DevOps |

## Contenidos

### Teoría
1. [01-rbac-gitlab.md](./1-teoria/01-rbac-gitlab.md) — Roles, permisos, grupos LDAP/SAML
2. [02-seguridad-cuenta.md](./1-teoria/02-seguridad-cuenta.md) — MFA, IP restrictions, audit events
3. [03-seguridad-pipelines.md](./1-teoria/03-seguridad-pipelines.md) — SAST, Secret Detection, Dependency Scanning (CE); DAST (EE)
4. [04-politicas-cumplimiento.md](./1-teoria/04-politicas-cumplimiento.md) — Audit events, MR approvals, branch protection
5. [05-license-management.md](./1-teoria/05-license-management.md) — Dependency scanning basico (CE); License Compliance UI (EE)

### Prácticas
1. [01-configurar-rbac/](./2-practicas/01-configurar-rbac/) — Roles y permisos
2. [02-mfa-y-seguridad/](./2-practicas/02-mfa-y-seguridad/) — MFA, restricciones IP
3. [03-security-scanning/](./2-practicas/03-security-scanning/) — SAST + Secret Detection en pipeline
4. [04-security-pipeline-ce/](./2-practicas/04-security-pipeline-ce/) — Pipeline de seguridad completo con templates CE (SAST + Secrets + Deps)

### Proyecto
- [3-proyecto/](./3-proyecto/) — Implementar stack de seguridad DevOps

## Entregables

- [ ] RBAC configurado con roles definidos
- [ ] MFA habilitado para usuarios
- [ ] SAST y Secret Detection en pipeline
- [ ] Reporte de auditoría generado

---

[← Semana 09](../week-09-gitlab_api_y_automatizacion/README.md) | [Semana 11 →](../week-11-monitoreo_backup_y_alta_disponibilidad/README.md)

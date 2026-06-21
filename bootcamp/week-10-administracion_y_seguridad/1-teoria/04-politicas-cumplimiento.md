# 04 — Políticas de Cumplimiento (Compliance)

Las políticas de cumplimiento aseguran que los proyectos cumplan con estándares organizacionales o regulatorios (SOC2, ISO 27001, PCI DSS). En GitLab CE estas políticas se implementan mediante pipelines de compliance y configuraciones obligatorias a nivel de grupo.

## Compliance Pipelines

Un compliance pipeline es un pipeline definido a nivel de grupo que se inyecta automáticamente en todos los proyectos del grupo. Se ejecuta antes o después del pipeline normal del proyecto, garantizando que ciertos checks no puedan ser omitidos por los desarrolladores.

Ejemplo de compliance pipeline que ejecuta SAST obligatorio:
```yaml
# Definido en el grupo → Settings → CI/CD → General pipelines
compliance:
  stage: compliance
  script:
    - echo "Ejecutando checks de cumplimiento..."
    - check_code_review_required
    - verify_license_compliance
```

## Merge Request Approvals

Las reglas de aprobación de MRs son una herramienta clave de compliance. Se configuran en Settings → Merge requests → Merge request approvals. Se puede:
- Exigir un número mínimo de aprobaciones
- Prevenir que el autor apruebe su propio MR
- Exigir aprobación de miembros específicos o grupos
- Bloquear merge hasta que todos los threads estén resueltos

## Push Rules (EE, referencia alternativa CE)

En CE, las push rules no están disponibles nativamente, pero se pueden implementar mediante server hooks personalizados o mediante jobs en el pipeline que validen nombres de ramas, formatos de commit message, tamaño de archivos con `pre-receive` hooks administrados directamente en el servidor.

## Audit Events Pipeline

Además de los eventos de auditoría a nivel de plataforma, se debe configurar logging de todas las ejecuciones de pipeline, cambios en variables CI/CD y aprobaciones de MR. Estos logs pueden exportarse vía API y almacenarse en un SIEM externo.

## Reportes de Cumplimiento

Los reportes se generan periódicamente (semanal/mensual) e incluyen:
- Proyectos sin SAST habilitado
- Vulnerabilidades sin resolver (aging report)
- Usuarios sin MFA
- Miembros con permisos excesivos
- Tokens sin fecha de expiración

## Mejores prácticas

- Definir compliance pipelines a nivel de grupo, no por proyecto
- Automatizar la generación de reportes vía API
- Revisar trimestralmente las políticas de compliance
- Mantener un runbook de remediación para hallazgos comunes

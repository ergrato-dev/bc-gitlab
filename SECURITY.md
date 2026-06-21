# Politica de Seguridad

## Versiones Soportadas

| Version | Soportada |
| ------- | --------- |
| main    | Si        |

## Reportar una Vulnerabilidad

La seguridad de este proyecto es importante para nosotros. Si descubres una vulnerabilidad de seguridad, te pedimos que la reportes de manera responsable.

### NO hacer publico el reporte

Por favor, **NO** abras un issue publico para reportar vulnerabilidades de seguridad.

### Como Reportar

1. **Abre un Security Advisory privado** en GitHub:
   - Ve a la pestana "Security" del repositorio
   - Haz clic en "Report a vulnerability"
   - Completa el formulario con los detalles

2. **Incluye en tu reporte**:
   - Descripcion detallada de la vulnerabilidad
   - Pasos para reproducir el problema
   - Impacto potencial
   - Sugerencias de solucion (si las tienes)

### Tiempo de Respuesta

- **Confirmacion inicial**: 48 horas
- **Evaluacion**: 7 dias
- **Resolucion**: Dependiendo de la severidad

### Reconocimiento

Agradecemos a todos los investigadores de seguridad que reportan vulnerabilidades de manera responsable. Tu nombre sera incluido en nuestros agradecimientos (si lo deseas).

## Mejores Practicas de Seguridad

Este bootcamp ensena las siguientes practicas de seguridad:

### Gestion de Secretos

```yaml
# Usar variables CI/CD en lugar de hardcodear secretos
deploy:
  script:
    - echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USER" --password-stdin
```

### Control de Acceso (RBAC)

```yaml
# Configurar permisos por rol en GitLab
# Maintainer, Developer, Reporter, Guest
# Minimun privilege principle
```

### Escaneo de Seguridad

```yaml
# GitLab SAST integrado
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml
```

### Seguridad de Infraestructura

```nginx
# Nginx: Headers de seguridad
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
```

### Backup y Recuperacion

```bash
# Backup automatico de GitLab CE
gitlab-backup create STRATEGY=copy
gitlab-ctl backup-etc
```

## Dependencias

Mantenemos las referencias actualizadas para evitar vulnerabilidades conocidas. Este bootcamp referencia:

- GitLab CE (ultima version estable)
- Docker y Docker Compose
- GitLab Runner
- Herramientas de seguridad integradas (SAST, Secret Detection)

---

Gracias por ayudar a mantener este proyecto seguro.

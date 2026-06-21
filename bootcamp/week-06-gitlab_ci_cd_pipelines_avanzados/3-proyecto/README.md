# Proyecto Semana 06 — Pipeline CI/CD Avanzado

## Descripcion

Evolucionar el pipeline de la Semana 05 a un pipeline CI/CD completo con variables protegidas, ejecucion condicional, modularizacion y entornos de despliegue.

## Requisitos del Proyecto

### 1. Variables y Secretos
- Configurar variables de proyecto para credenciales (registry, deploy)
- Variables enmascaradas y protegidas
- Usar variables predefinidas de GitLab (`CI_COMMIT_SHA`, `CI_COMMIT_REF_NAME`, etc.)

### 2. Pipeline Condicional
- Jobs diferentes segun la rama (feature, develop, main)
- Tag semantico (`v1.0.0`) dispara deploy a produccion
- Merge requests ejecutan tests pero no despliegan
- `changes` para correr solo jobs relevantes

### 3. Modularizacion
- Pipeline dividido en modulos con `include:local`
- Estructura:
  ```
  .gitlab/
    ci/
      stages.yml
      build.yml
      test.yml
      deploy.yml
      security.yml
  .gitlab-ci.yml
  ```

### 4. Environments
- Entorno `staging` (despliegue automatico desde `develop`)
- Entorno `production` (despliegue manual desde `main` o tag)
- Rollback habilitado
- URLs de entorno en la UI

### 5. Triggers (Extra)
- Pipeline en proyecto de libreria que dispara el pipeline de la app

## Estructura esperada del `.gitlab-ci.yml` principal

```yaml
include:
  - local: .gitlab/ci/stages.yml
  - local: .gitlab/ci/build.yml
  - local: .gitlab/ci/test.yml
  - local: .gitlab/ci/deploy.yml
  - local: .gitlab/ci/security.yml

variables:
  APP_NAME: "bootcamp-app"
```

## Entregables

- [ ] Variables protegidas y enmascaradas configuradas
- [ ] Pipeline con ejecucion condicional (rules)
- [ ] Pipeline modularizado con `include`
- [ ] Entornos staging y production funcionales
- [ ] Historial de deployments en GitLab

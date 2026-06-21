# 01 — Variables CI/CD

## Tipos de variables

GitLab CI/CD soporta varios tipos de variables con diferentes alcances:

### Variables de pipeline (definidas en `.gitlab-ci.yml`)
```yaml
variables:
  DEPLOY_ENV: "staging"
  API_URL: "https://api.staging.example.com"
```

### Variables de proyecto
Configuradas en Settings → CI/CD → Variables. Pueden ser:
- **Protegidas**: Solo disponibles en ramas protegidas
- **Enmascaradas**: Su valor se oculta en los logs (requiere cumplir requisitos de formato)
- **Expandibles**: El valor se expande en referencias `$VARIABLE`

### Variables predefinidas
GitLab expone variables automaticas como:
- `CI_COMMIT_SHA`: Hash del commit
- `CI_COMMIT_REF_NAME`: Rama o tag
- `CI_PIPELINE_ID`: ID del pipeline
- `CI_JOB_ID`: ID del job
- `CI_PROJECT_DIR`: Directorio del proyecto clonado
- `CI_REGISTRY_IMAGE`: URL del container registry

## Prioridad de variables

Cuando una variable se define en multiples lugares, prevalece la de mayor prioridad:
1. Variables del job (definidas en el mismo job)
2. Variables globales del pipeline (en `.gitlab-ci.yml`)
3. Variables de proyecto (CI/CD Settings)
4. Variables de grupo
5. Variables de instancia

## Buenas practicas
- Nunca hardcodear secretos en `.gitlab-ci.yml`
- Usar variables enmascaradas para tokens y passwords
- Documentar variables requeridas en el README del proyecto

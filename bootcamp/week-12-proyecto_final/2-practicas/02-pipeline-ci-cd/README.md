# Práctica 02 — Pipeline CI/CD Completo

## Objetivo

Crear el `.gitlab-ci.yml` completo con todos los stages y la integración con el Container Registry.

## Requisitos

- Aplicación de ejemplo con Dockerfile (puede ser la del proyecto de semanas anteriores)
- Runner registrado y funcional (Práctica 01)
- Container Registry configurado

## Instrucciones

### Paso 1: Preparar aplicación de ejemplo

Usa una app simple (Python Flask, Node.js Express, Go net/http) con:
- `Dockerfile` para construir la imagen
- Tests unitarios (pytest, jest, go test)
- Dependencias declaradas (requirements.txt, package.json, go.mod)

### Paso 2: Crear ci-templates

Extrae lógica reutilizable en templates:

**ci-templates/build.yml**:
```yaml
.build-template:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
```

**ci-templates/deploy.yml**:
```yaml
.deploy-template:
  stage: deploy
  script:
    - docker pull $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
    - docker stop app || true
    - docker rm app || true
    - docker run -d --name app -p 5000:5000 $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
```

### Paso 3: Crear .gitlab-ci.yml principal

```yaml
stages:
  - build
  - test
  - security
  - deploy

include:
  - local: ci-templates/build.yml
  - local: ci-templates/deploy.yml
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml

build:
  extends: .build-template

test:
  stage: test
  script:
    - echo "Ejecutando tests unitarios..."
    - python -m pytest tests/ --junitxml=report.xml
  artifacts:
    reports:
      junit: report.xml

deploy-staging:
  extends: .deploy-template
  environment:
    name: staging
  rules:
    - if: $CI_COMMIT_BRANCH == "main"

deploy-production:
  extends: .deploy-template
  environment:
    name: production
  when: manual
  rules:
    - if: $CI_COMMIT_TAG
```

### Paso 4: Configurar variables CI/CD

En Settings → CI/CD → Variables, agrega:
- `CI_REGISTRY_USER`: tu usuario del registry (protegida)
- `CI_REGISTRY_PASSWORD`: token del registry (protegida, masked)
- `CI_REGISTRY`: URL del registry

### Paso 5: Probar el pipeline

1. Crea un branch `feature/test-pipeline`
2. Agrega los archivos y haz push
3. Observa la ejecución en CI/CD → Pipelines
4. Espera que todos los stages pasen
5. Crea un MR a `main`, verifica el widget del MR con los resultados
6. Mergea y verifica deploy automático a staging
7. Crea un tag (`v1.0.0`) y ejecuta manualmente deploy a production

## Preguntas de reflexión
- ¿Por qué usar `extends` en lugar de duplicar la configuración?
- ¿Qué ventajas tiene separar los templates en una carpeta `ci-templates/`?
- ¿Cómo manejarías un rollback si el deploy a production falla?

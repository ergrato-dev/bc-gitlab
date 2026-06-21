# Proyecto Semana 05 — Pipeline CI Completo

## Descripcion

Implementar un pipeline CI completo para un proyecto Node.js (API REST) o Python (Flask/FastAPI) que automatice la construccion, pruebas y generacion de artifacts.

## Requisitos del Proyecto

### Pipeline CI (`.gitlab-ci.yml`)

1. **Stage `build`:**
   - Instalar dependencias del proyecto
   - Generar un artifact con las dependencias instaladas

2. **Stage `test`:**
   - Ejecutar pruebas unitarias (al menos 3 tests)
   - Ejecutar linting
   - Generar reporte de cobertura como artifact

3. **Stage `package`:**
   - Empaquetar la aplicacion lista para despliegue
   - Generar un artifact descargable con el build

4. **Requisitos tecnicos:**
   - Usar imagenes Docker apropiadas
   - Configurar cache para acelerar builds
   - Usar `before_script` para tareas comunes

### Ejemplo para Node.js

```yaml
stages:
  - build
  - test
  - package

variables:
  NODE_ENV: test

before_script:
  - npm config set registry https://registry.npmjs.org/

build:
  stage: build
  image: node:18-alpine
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
  script:
    - npm ci
  artifacts:
    paths:
      - node_modules/
    expire_in: 1 hour

lint:
  stage: test
  image: node:18-alpine
  script:
    - npm run lint
  allow_failure: true

unit-test:
  stage: test
  image: node:18-alpine
  script:
    - npm test
  artifacts:
    reports:
      junit: junit.xml

package:
  stage: package
  image: node:18-alpine
  script:
    - npm prune --production
    - tar -czf app.tar.gz .
  artifacts:
    paths:
      - app.tar.gz
    expire_in: 30 days
```

## Entregables

- [ ] Proyecto Node.js o Python con al menos 3 tests
- [ ] `.gitlab-ci.yml` con 3+ stages
- [ ] Pipeline ejecutandose exitosamente
- [ ] Artifacts generados y descargables

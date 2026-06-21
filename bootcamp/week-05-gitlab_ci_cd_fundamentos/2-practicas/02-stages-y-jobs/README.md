# Practica 02 — Multiples Stages y Jobs

## Objetivo

Definir un pipeline con 3 stages secuenciales que simulen un flujo de CI basico.

## Instrucciones

1. Crea un `.gitlab-ci.yml` con stages `build`, `test` y `deploy`:

```yaml
stages:
  - build
  - test
  - deploy

compilar:
  stage: build
  script:
    - echo "Compilando..."
    - mkdir -p dist
    - echo "v1.0.0" > dist/version.txt
    - echo "<h1>App</h1>" > dist/index.html
  artifacts:
    paths:
      - dist/

test-unitario:
  stage: test
  script:
    - echo "Ejecutando pruebas unitarias..."
    - test -f dist/index.html && echo "PASS" || echo "FAIL"

test-version:
  stage: test
  script:
    - echo "Verificando version..."
    - cat dist/version.txt

desplegar:
  stage: deploy
  script:
    - echo "Desplegando a staging..."
    - ls -la dist/
    - echo "Despliegue completado"
```

## Verificacion

- [ ] 3 stages visibles en la UI de pipelines
- [ ] `test-unitario` y `test-version` se ejecutan en paralelo
- [ ] `desplegar` solo se ejecuta si todos los tests pasan
- [ ] El artifact `dist/` esta disponible en el UI

## Reto adicional

Agrega un cuarto stage `notify` que envie una notificacion (simulada con `echo`) solo si el pipeline completo fue exitoso.

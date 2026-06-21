# Practica 01 — Primer Pipeline

## Objetivo

Crear el pipeline mas simple posible que se ejecute exitosamente en GitLab.

## Instrucciones

1. Crea un proyecto vacio en GitLab
2. Agrega un archivo `.gitlab-ci.yml` en la raiz con el siguiente contenido minimo:

```yaml
stages:
  - saludar

hola-mundo:
  stage: saludar
  script:
    - echo "Hola, CI/CD!"
    - date
    - whoami
```

3. Haz commit y push a GitLab
4. Ve a CI/CD → Pipelines y observa la ejecucion
5. Inspecciona los logs de cada paso del script

## Verificacion

- [ ] Pipeline aparece en CI/CD → Pipelines
- [ ] El job se ejecuta y muestra el output esperado
- [ ] Estado final: Passed

## Reto adicional

Agrega una variable personalizada y muestrala con `echo`:

```yaml
variables:
  SALUDO: "Desde GitLab CI"

hola-mundo:
  stage: saludar
  script:
    - echo "Hola, ${SALUDO}!"
```

# Practica 01 — Variables y Secretos

## Objetivo

Configurar variables de proyecto y pipeline, protegiendo datos sensibles.

## Instrucciones

### Parte 1: Variables en `.gitlab-ci.yml`

```yaml
variables:
  APP_NAME: "mi-aplicacion"
  APP_VERSION: "1.0.0"

mostrar-variables:
  stage: build
  script:
    - echo "Aplicacion: ${APP_NAME}"
    - echo "Version: ${APP_VERSION}"
    - echo "Commit: ${CI_COMMIT_SHORT_SHA}"
```

### Parte 2: Variables protegidas

1. Ve a Settings → CI/CD → Variables
2. Agrega `SECRET_TOKEN` con valor `super-secreto-123`
3. Marca "Mask variable" y "Protect variable"
4. Agrega en el pipeline:

```yaml
usar-secreto:
  stage: test
  script:
    - echo "El token tiene ${#SECRET_TOKEN} caracteres"
    - curl -H "Authorization: Bearer ${SECRET_TOKEN}" https://httpbin.org/get
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

### Parte 3: Variables de grupo

1. Crea un grupo en GitLab
2. Agrega una variable de grupo `DOCKER_REGISTRY_PASS`
3. Verifica que los proyectos del grupo la heredan

## Verificacion

- [ ] Variables definidas en `.gitlab-ci.yml` se muestran en logs
- [ ] `SECRET_TOKEN` aparece enmascarado (****) en los logs
- [ ] Variable de grupo accesible desde el proyecto
- [ ] Jobs en ramas no protegidas NO tienen acceso a variables protegidas

## Reto adicional

Usa `rules` para que el job `usar-secreto` solo ejecute cuando la variable `SECRET_TOKEN` esta definida:

```yaml
rules:
  - if: $SECRET_TOKEN != ""
```

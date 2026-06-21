# 02 — Estructura del archivo .gitlab-ci.yml

## Ubicacion

El archivo `.gitlab-ci.yml` debe colocarse en la raiz del repositorio. GitLab lo detecta automaticamente y ejecuta el pipeline definido en cada push.

## Keywords fundamentales

### `stages`
Define el orden de ejecucion de las etapas del pipeline. Los jobs en una misma stage se ejecutan en paralelo.

```yaml
stages:
  - build
  - test
  - deploy
```

### `script`
Lista de comandos que ejecuta el job. Es el unico campo obligatorio en un job.

```yaml
job-ejemplo:
  script:
    - echo "Ejecutando pruebas"
    - npm test
```

### `before_script` y `after_script`
- `before_script`: Comandos que se ejecutan antes del `script` en cada job. Util para preparar el entorno.
- `after_script`: Comandos que se ejecutan despues del `script`, incluso si el job falla. Util para limpieza.

```yaml
before_script:
  - apt-get update -qq && apt-get install -y -qq curl

job_principal:
  script:
    - ./ejecutar.sh
  after_script:
    - echo "Limpieza completada"
```

## Validacion YAML

La sintaxis debe ser YAML estricto. Errores comunes:
- Usar tabs en lugar de espacios
- Indentacion inconsistente
- Caracteres especiales no escapados

GitLab proporciona una herramienta de validacion en: Proyecto → CI/CD → Pipelines → CI Lint

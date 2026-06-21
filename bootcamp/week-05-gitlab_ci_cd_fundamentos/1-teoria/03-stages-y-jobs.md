# 03 — Stages y Jobs

## Stages (Etapas)

Las stages definen la secuencia de ejecucion del pipeline. Se ejecutan en el orden declarado. Una stage no comienza hasta que todos los jobs de la stage anterior hayan finalizado exitosamente.

```yaml
stages:
  - compilar    # Primero
  - probar      # Despues de compilar
  - desplegar   # Despues de probar
```

Si una stage falla, las stages posteriores no se ejecutan por defecto.

## Jobs (Trabajos)

Un job es una unidad de trabajo dentro de una stage. Caracteristicas:
- Se ejecutan en paralelo dentro de la misma stage
- Tienen un script, una imagen, y un stage asignado
- Pueden heredar configuracion global

```yaml
compilar-backend:
  stage: compilar
  script:
    - mvn compile

compilar-frontend:
  stage: compilar
  script:
    - npm run build

probar-backend:
  stage: probar
  script:
    - mvn test
```

## Dependencias entre jobs (`needs`)

La keyword `needs` permite crear relaciones directas entre jobs, ignorando el orden de stages. Esto permite ejecucion en DAG (grafo aciclico dirigido):

```yaml
probar-integracion:
  stage: probar
  needs: ["compilar-backend", "compilar-frontend"]
  script:
    - ./run-integration-tests.sh
```

Con `needs`, un job puede iniciar tan pronto como sus dependencias terminen, sin esperar a que toda la stage anterior complete.

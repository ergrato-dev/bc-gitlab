# Pipelines hijos dinámicos

> Un hijo dinámico es un pipeline cuyo YAML no está en el repositorio: lo escribe un job del padre, lo guarda como artefacto y otro job lo dispara. Es la única forma de que el número de jobs dependa de algo que solo se sabe al ejecutar. También es la forma más rápida de tener un pipeline que nadie puede leer antes de que corra.

---

## 🎯 Objetivos

- Disparar un hijo con `trigger:include:artifact`
- Reconocer los tres casos en que un hijo dinámico compensa
- Saber qué se pierde respecto a un YAML escrito a mano, y cómo recuperarlo en parte

---

## 1. Qué problema resuelve

`rules`, `parallel:matrix` y los hijos estáticos deciden **qué jobs** entran en un pipeline, pero los jobs posibles están escritos de antemano. A veces la lista sale de algo que solo existe al ejecutar:

- Un monorepo con un directorio por servicio: los servicios **que cambiaron en este commit**, cada uno con su build.
- Un job de pruebas por cada archivo de una carpeta que crece sola.
- Una matriz que depende de una consulta: las versiones de Node todavía soportadas, leídas de una API.

`parallel:matrix` cubre una lista fija. `rules:changes` cubre un conjunto conocido de rutas. Cuando ni la lista ni las rutas se conocen al escribir el YAML, el YAML tiene que escribirse en el pipeline.

---

## 2. Cómo funciona

### 2.1 Dos jobs

```yaml
generar:
  stage: build
  image: alpine:3.24.2
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  script:
    - scripts/generar-pipeline.sh > hijo.yml
  artifacts:
    paths: [hijo.yml]
    expire_in: 1 day

ejecutar:
  stage: test
  needs: [generar]
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  trigger:
    include:
      - artifact: hijo.yml
        job: generar
    strategy: mirror
```

`generar` es un job normal: se ejecuta en un runner, escribe un archivo y lo deja como artefacto. `ejecutar` dispara un hijo cuya configuración es ese artefacto. GitLab lo lee del artefacto, lo valida y crea el pipeline. Si el YAML generado es inválido, `ejecutar` falla con el error de validación.

### 2.2 Qué escribe el generador

Un `.gitlab-ci.yml` completo, con su `workflow`, como un hijo estático (teoría 03). Lo más simple que funciona: `printf` desde un script de shell.

```sh
#!/bin/sh
# Un job de pruebas por cada directorio de servicios/ que cambió respecto a main.
set -eu
cat <<'EOF'
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "parent_pipeline"
EOF
for s in $(git diff --name-only "origin/$CI_DEFAULT_BRANCH"...HEAD -- servicios/ | cut -d/ -f2 | sort -u); do
  printf 'test-%s:\n  image: node:22.23.3-alpine3.24\n  script:\n    - cd servicios/%s && npm ci && npm test\n' "$s" "$s"
done
```

Si no cambió ningún servicio, el YAML no tiene jobs y el hijo **no se crea**: `ejecutar` falla. Un generador serio añade siempre un job vacío de cortesía (`script: echo "nada que probar"`) para ese caso.

### 2.3 Lo que no cambia

El hijo dinámico es un hijo: mismo `CI_PIPELINE_SOURCE` (`parent_pipeline`), mismos límites de profundidad, mismas variables. La diferencia está solo en de dónde sale su YAML.

---

## 3. Cuándo compensa y cuándo no

| Señal | ¿Dinámico? |
|---|---|
| La lista de jobs depende de lo que cambió y es grande | ✅ |
| La lista depende de datos externos al repositorio | ✅ |
| Son tres servicios fijos | ❌ Tres hijos estáticos con `rules:changes`, o un `parallel:matrix` |
| Quieres "reutilizar" YAML | ❌ `include`, `extends` y componentes (Semana 12) |
| Quieres parametrizar un job | ❌ Variables o `spec:inputs` (Semana 12) |

En `app` no hay ningún caso: es una librería pequeña sin directorios por servicio. Esta semana no escribes un hijo dinámico; lo reconoces cuando lo necesites.

### 3.1 Lo que se pierde

| Con YAML a mano | Con YAML generado |
|---|---|
| Lo lees en la merge request | Lo lees en el artefacto de un pipeline ya ejecutado |
| `ci/lint` lo valida antes de empujar | Solo se valida al disparar |
| El revisor de `CODEOWNERS` ve cada job | El revisor ve el generador, no lo que genera |
| `git blame` dice quién añadió un job | `git blame` dice quién cambió el generador |

La tercera fila es la que importa en una plataforma gobernada: con un generador, quien puede cambiar el script puede añadir cualquier job al pipeline. El generador va en `CODEOWNERS` con el mismo dueño que `.gitlab-ci.yml`.

Para recuperar parte de lo perdido: que el propio `generar` valide su salida contra `POST .../ci/lint` antes de terminar, y que el artefacto se conserve lo bastante para auditarlo.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Generar YAML con plantillas de texto complejas | Un espacio mal puesto rompe el pipeline sin decir dónde | YAML simple, o generar JSON (que es YAML válido) con `jq` |
| Generador sin caso "lista vacía" | El hijo sin jobs no se crea y el padre falla | Un job de cortesía |
| Dinámico para evitar escribir tres jobs | El pipeline deja de ser legible en la merge request | Estático |
| El generador fuera de `CODEOWNERS` | Una vía para añadir jobs que el revisor del pipeline no ve | El mismo dueño que `.gitlab-ci.yml` |
| Artefacto con `expire_in` de minutos | Nadie puede auditar después qué se ejecutó | Al menos lo que se conservan los logs que importan |

---

## 5. Trucos

- **JSON en lugar de YAML**: `jq -n '{workflow: {rules: [{if: "$CI_PIPELINE_SOURCE == \"parent_pipeline\""}]}, "test-a": {script: ["true"]}}' > hijo.yml`. JSON es YAML válido y `jq` no se equivoca con la indentación.
- **Descargar el YAML que generó un pipeline**: `GET .../jobs/<id-de-generar>/artifacts/hijo.yml`.

---

## 📚 Recursos Adicionales

- [Dynamic child pipelines](https://docs.gitlab.com/ci/pipelines/downstream_pipelines/#dynamic-child-pipelines) — el mecanismo y su ejemplo
- [`trigger:include:artifact`](https://docs.gitlab.com/ci/yaml/#triggerincludeartifact)
- [`parallel:matrix`](https://docs.gitlab.com/ci/yaml/#parallelmatrix) — la alternativa estática

---

## ✅ Checklist de Verificación

- [ ] Sabes qué dos jobs forman un hijo dinámico y qué pasa entre ellos
- [ ] Sabes nombrar un caso en que compensa y dos en que no
- [ ] Sabes qué pierde la revisión de código con un YAML generado
- [ ] Sabes por qué el generador va en `CODEOWNERS`

---

[← Anterior: Pipelines padre-hijo](03-pipelines-padre-hijo.md) · [Volver a la Semana 11](../README.md) · [Siguiente: Pipelines multiproyecto →](05-pipelines-multiproyecto.md)

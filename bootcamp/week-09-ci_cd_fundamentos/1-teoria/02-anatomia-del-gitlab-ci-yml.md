# Anatomía de `.gitlab-ci.yml`

> Un archivo YAML en la raíz del repositorio describe el pipeline entero. Tiene más de cien palabras clave; para el pipeline de `app` hacen falta doce. Esta teoría las recorre en el orden en que aparecen en el archivo.

---

## 🎯 Objetivos

- Leer el `.gitlab-ci.yml` de `app` línea a línea
- Saber qué palabras clave son globales y cuáles de job, y qué hace `default`
- Reutilizar configuración con un job oculto y `extends`
- Usar las variables predefinidas `CI_*` en un script
- Validar el archivo con la API antes de empujarlo

---

## 1. Qué problema resuelve

Sin un archivo, cada pipeline sería una configuración en una pantalla que nadie revisa. Con `.gitlab-ci.yml` en el repositorio, el pipeline tiene historia, autor, revisión y versión: el de la `v0.1.1` es el que había en la `v0.1.1`.

---

## 2. Cómo funciona

### 2.1 El archivo completo

Es el que la práctica 02 fusiona y la 04 amplía con `gobernanza`:

```yaml
# Pipeline de app. Las decisiones, en el ADR-007 de la wiki.
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS
      when: never
    - if: $CI_COMMIT_BRANCH
    - if: $CI_COMMIT_TAG

stages: [build, test, package]

variables:
  GIT_LFS_SKIP_SMUDGE: "1"   # ningún job usa las imágenes de assets/

default:
  image: node:22.23.3-alpine3.24
  interruptible: true

.npm:
  cache:
    key:
      files: [package-lock.json]
    paths: [.npm/]
    policy: pull
  before_script:
    - npm ci --cache .npm --prefer-offline --no-audit --no-fund

build:
  stage: build
  extends: .npm
  cache:
    policy: pull-push
  script:
    - npx tsc

test:
  stage: test
  extends: .npm
  script:
    - npm run test:ci
  coverage: '/all files\s*\|\s*([\d.]+)/'
  artifacts:
    when: always
    expire_in: 1 week
    reports:
      junit: junit.xml

package:
  stage: package
  script:
    - npm pack
  artifacts:
    expire_in: 1 week
    paths: ["*.tgz"]
```

### 2.2 Las palabras clave globales

| Palabra clave | Qué hace | En `app` |
|---|---|---|
| `workflow:rules` | Decide si se crea el pipeline **entero** | Solo uno por cambio: de merge request si la hay, de rama si no |
| `stages` | El orden de los stages | `build`, `test`, `package` |
| `variables` | Variables para todos los jobs | `GIT_LFS_SKIP_SMUDGE` |
| `default` | Valores por defecto de cualquier palabra clave de job | La imagen y `interruptible` |

El bloque `workflow:rules` se copia tal cual esta semana y se desmonta en la Semana 10. En una frase: si el pipeline viene de una merge request, adelante; si es un push a una rama que **ya** tiene merge request abierta, no (ese cambio ya tiene su pipeline de merge request); cualquier otra rama o tag, adelante.

`GIT_LFS_SKIP_SMUDGE: "1"` es la promesa de la Semana 04: el runner clona `app` sin descargar los binarios de LFS, porque ningún job los usa. El repositorio trae los punteros; si un job los necesitara algún día, `git lfs pull` en ese job.

### 2.3 Las palabras clave de job

| Palabra clave | Qué hace | Ejemplo |
|---|---|---|
| `stage` | En qué stage va. Si falta, `test` | `stage: build` |
| `image` | En qué imagen se ejecuta | `alpine:3.24.2` en `gobernanza` |
| `before_script` | Comandos antes de `script`, en el mismo shell | `npm ci` |
| `script` | Lo que hace el job. **Obligatoria** | `npx tsc` |
| `rules` | Si el job entra en el pipeline | `gobernanza`, solo en merge requests |
| `allow_failure` | Si su fallo deja el pipeline en verde | `gobernanza` |
| `interruptible` | Si un pipeline más nuevo de la misma rama puede cancelarlo | Todos |
| `cache` | Teoría 06 | `.npm/` |
| `artifacts` y `coverage` | Teoría 05 | `junit.xml`, `*.tgz` |

Cada línea de `script` se ejecuta en orden, en el mismo shell. Si una devuelve un código distinto de cero, el job falla en ese punto: el runner ejecuta el script con `set -e` y, si el shell lo admite, con `pipefail`. Por eso `comando | head -2` falla si `comando` falla, aunque `head` funcione.

### 2.4 No repetirse: jobs ocultos y `extends`

Un job cuyo nombre empieza por punto (`.npm`) es **oculto**: no se ejecuta. Sirve de plantilla. `extends: .npm` copia su configuración en el job, y lo que el job define encima gana.

Los mapas se mezclan en profundidad: `build` hereda `cache.key` y `cache.paths` de `.npm` y solo cambia `cache.policy`. Las listas, en cambio, se sustituyen enteras: si `build` definiera su propio `before_script`, el `npm ci` de `.npm` desaparecería.

> [!NOTE]
> Las anclas de YAML (`&npm`, `<<: *npm`) hacen algo parecido, pero no funcionan entre archivos y se leen peor. `extends` es la forma de GitLab. En la Semana 12, cuando el YAML se comparta entre proyectos, llegan `include` y los componentes.

### 2.5 Las variables predefinidas

Cada job recibe más de cien variables `CI_*`. Las que usa `app`:

| Variable | Valor | Para qué |
|---|---|---|
| `CI_PIPELINE_SOURCE` | `push`, `merge_request_event`… | `workflow:rules` y `rules` |
| `CI_COMMIT_BRANCH` | La rama, si es un pipeline de rama | `workflow:rules` |
| `CI_COMMIT_TAG` | El tag, si es un pipeline de tag | `workflow:rules` |
| `CI_OPEN_MERGE_REQUESTS` | Merge requests abiertas desde esta rama | `workflow:rules` |
| `CI_MERGE_REQUEST_IID` | El número de la merge request | `gobernanza.sh` |
| `CI_PROJECT_ID` | El ID del proyecto | `gobernanza.sh` |
| `CI_API_V4_URL` | La URL de la API | `gobernanza.sh`; en el laboratorio, teoría 03 |
| `CI_JOB_TOKEN` | Un token que vive lo que dura el job | Teoría 04 |

`gobernanza.sh` se escribió en la Semana 07 leyendo `CI_*` primero. Por eso pasa a ser un job sin cambiar una línea.

---

## 3. Cómo se configura

### 3.1 Validar antes de empujar

```bash
jq -n --rawfile c .gitlab-ci.yml '{content: $c}' \
  | curl -s --request POST "$API/projects/$P/ci/lint" -H "$H" \
      -H "Content-Type: application/json" -d @- \
  | jq '{valid, errors, warnings}'
```

`POST .../ci/lint` valida el contenido en el contexto del proyecto: sabe qué stages existen, qué archivos incluye y qué variables hay. Un error típico:

```
"package job: chosen stage paquete does not exist; available stages are .pre, build, test, package, .post"
```

`.pre` y `.post` existen siempre: son stages que van antes y después de los que declares.

`GET .../ci/lint?ref=main` valida el archivo que ya está en una rama, sin enviar nada.

### 3.2 En la interfaz

`Build → Pipeline editor` valida mientras escribes, enseña el YAML ya mezclado con `extends` (`Full configuration`) y dibuja los stages. Es la forma rápida de ver qué hace `extends` sin imaginarlo.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Sin `workflow:rules` | Dos pipelines por cada push con merge request abierta | El bloque del apartado 2.1 |
| `image: node` o `node:latest` | Cada pipeline puede usar una versión distinta de Node | Versión completa: `node:22.23.3-alpine3.24` |
| `only`/`except` | Sintaxis heredada, no se combina con `rules` | `rules` |
| Copiar el mismo bloque en tres jobs | Se corrige en uno y se olvida en los otros | Un job oculto y `extends` |
| Comandos largos en el YAML | No se pueden ejecutar en local | Un script en `package.json` o en `scripts/` |
| Empujar para ver si el YAML es válido | Un pipeline roto en la historia | `POST .../ci/lint` primero |

---

## 5. Trucos

- **Ver el YAML final, con `extends` resuelto**: `GET .../ci/lint?ref=main&include_merged_yaml=true | jq -r .merged_yaml`.
- **Los nombres de las variables de un job**, sin sus valores: un job temporal con `script: [env | cut -d= -f1 | grep ^CI_ | sort]` en una rama de prueba. Nunca imprimas los valores: entre ellos está `CI_JOB_TOKEN`.
- **Desactivar un job sin borrarlo**: renómbralo con un punto delante (`.package`). Pasa a ser oculto.

---

## 📚 Recursos Adicionales

- [CI/CD YAML syntax reference](https://docs.gitlab.com/ci/yaml/) — todas las palabras clave
- [Predefined CI/CD variables](https://docs.gitlab.com/ci/variables/predefined_variables/) — la lista completa y en qué pipelines está cada una
- [Optimize GitLab CI/CD configuration files](https://docs.gitlab.com/ci/yaml/yaml_optimization/) — `extends`, anclas y `!reference`
- [CI Lint API](https://docs.gitlab.com/api/lint/) — validar contenido o la configuración de una rama

---

## ✅ Checklist de Verificación

- [ ] Sabes qué hace cada línea del `.gitlab-ci.yml` de `app`
- [ ] Sabes qué hereda `build` de `.npm` y qué cambia
- [ ] Sabes por qué una lista en `extends` no se mezcla
- [ ] Sabes validar el archivo sin crear un pipeline

---

[← Anterior: Del commit al pipeline](01-del-commit-al-pipeline.md) · [Volver a la Semana 09](../README.md) · [Siguiente: El runner →](03-el-runner.md)

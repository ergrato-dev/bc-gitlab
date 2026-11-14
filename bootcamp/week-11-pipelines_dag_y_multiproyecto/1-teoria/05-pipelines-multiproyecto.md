# Pipelines multiproyecto

> Un pipeline multiproyecto es un pipeline de **otro** proyecto, en su propia rama y con su propio YAML, que crea un job del tuyo. Es como `app` le dice a `infra/entornos` "hay una versión nueva". Lo que más confunde no es la sintaxis: es con los permisos de quién se ejecuta y qué variables llegan.

---

## 🎯 Objetivos

- Disparar el pipeline de otro proyecto con `trigger:project`
- Explicar con la identidad de quién se crea el pipeline de abajo y qué permisos necesita
- Pasar datos al proyecto de abajo y saber qué los puede bloquear
- Elegir entre `trigger:project`, la API con el job token y un token de disparo

---

## 1. Qué problema resuelve

`app` construye un paquete. Lo que se despliega, dónde y con qué configuración no es asunto de `app`: es de `infra`, un subgrupo que existe desde la Semana 03 y que esta semana tiene su primer proyecto, `infra/entornos`. Separarlos tiene sentido por tres razones:

| Razón | En `app` | En `infra/entornos` |
|---|---|---|
| Quién lo cambia | Quien desarrolla el producto | Quien opera la plataforma |
| Qué secretos ve | Ninguno de infraestructura | Los de los entornos (desde la Semana 14) |
| A qué ritmo cambia | Cada merge request | Cuando cambia un entorno |

Pero cuando `main` de `app` tiene un paquete nuevo, `infra/entornos` tiene que enterarse. Sin multiproyecto, alguien lo lanza a mano o un script consulta `app` cada cinco minutos.

---

## 2. Cómo funciona

### 2.1 El job de disparo

```yaml
infra:
  stage: deploy
  needs: [package]
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  variables:
    APP_SHA: $CI_COMMIT_SHA
    APP_PROJECT_ID: $CI_PROJECT_ID
    APP_PACKAGE_JOB_ID: $PACKAGE_JOB_ID
  trigger:
    project: plataforma-<tu-dominio>/infra/entornos
    branch: main
    strategy: mirror
```

Mismo tipo de job que el de un hijo (un *bridge*), mismas palabras clave permitidas. Cambia `project`, la ruta completa del otro proyecto, y `branch`, la rama de **ese** proyecto donde se crea el pipeline (sin `branch`, su rama por defecto). El pipeline de abajo usa el `.gitlab-ci.yml` de `infra/entornos` en esa rama, no el de `app`.

### 2.2 Con los permisos de quién

El pipeline de abajo **lo crea el usuario que creó el pipeline de arriba**: quien hizo el push, quien fusionó la merge request o quien lanzó el pipeline. No un usuario de servicio, no el job token.

| Para que el disparo funcione, ese usuario necesita | Si no |
|---|---|
| Poder ejecutar pipelines en `infra/entornos` (Developer o más) | El job `infra` falla: no hay pipeline de abajo |
| Si `branch` está protegida en `infra/entornos`, poder fusionar en ella | Ídem |
| Si se pasan variables, el rol mínimo de variables de pipeline de `infra/entornos` | Ídem |

Es una buena propiedad: un Developer de `app` que no es nadie en `infra` no puede hacer que `infra` ejecute nada, aunque cambie el YAML de `app`. Y es una trampa: el día que la persona que fusiona deje la organización, los disparos fallarán con su usuario bloqueado. Lo verás otra vez con los programados (teoría 08).

### 2.3 Qué ve el pipeline de abajo

| Variable | Vale |
|---|---|
| `CI_PIPELINE_SOURCE` | `pipeline` |
| `CI_COMMIT_*`, `CI_PROJECT_*` | Las de `infra/entornos` y su rama, **no** las de `app` |
| Las del bloque `variables:` del job de disparo | Llegan como **variables de pipeline** |

El `workflow` de `infra/entornos` tiene que aceptar ese origen:

```yaml
workflow:
  name: "app $APP_SHA"
  rules:
    - if: $CI_PIPELINE_SOURCE == "pipeline"
```

### 2.4 Las variables que pasas son variables de pipeline

Lo que pones en `variables:` del job de disparo llega abajo como si alguien hubiera lanzado el pipeline a mano con esas variables. Por eso se les aplica la restricción de la Semana 10 **del proyecto de abajo**: si `infra/entornos` tiene `ci_pipeline_variables_minimum_override_role=no_one_allowed`, ningún disparo con variables funciona.

| Configuración de `infra/entornos` | Disparo sin variables | Disparo con variables, usuario Maintainer |
|---|:--:|:--:|
| `no_one_allowed` | ✅ | ❌ |
| `maintainer` | ✅ | ✅ |
| `developer` | ✅ | ✅ (y también cualquier Developer a mano: demasiado) |

El valor con que nace un proyecto nuevo ha cambiado entre versiones y no es el mismo en gitlab.com que en una instancia propia (en la Semana 10 viste el de la tuya). Por eso en la práctica 03 lo fijas **explícitamente** en `maintainer`: que no dependa de un valor por defecto que una actualización puede cambiar.

`trigger:forward` decide qué más viaja: `yaml_variables` (las del YAML de arriba, activado por defecto) y `pipeline_variables` (las variables con que se lanzó el pipeline de arriba, desactivado). Lo prudente es no reenviar nada que no nombres.

> [!NOTE]
> En la Semana 12, `trigger:inputs` pasa datos tipados y validados a un proyecto cuyo YAML declara `spec:inputs`. Hoy usas variables, y por eso importa quién puede pasarlas.

### 2.5 Otras formas de disparar

| Forma | Quién la usa | Origen abajo |
|---|---|---|
| `trigger:project` en el YAML | Un pipeline de GitLab | `pipeline` |
| `POST /projects/:id/trigger/pipeline` con `token=$CI_JOB_TOKEN` | Un job, por API | `pipeline` |
| `POST /projects/:id/trigger/pipeline` con un token de disparo | Un sistema externo sin cuenta en GitLab | `trigger` |

Un **token de disparo** (`Settings → CI/CD → Pipeline trigger tokens`) es una credencial de larga vida que crea pipelines como el usuario que la creó: un secreto más para el inventario de `docs/secretos.md`. En `app` no hace falta: entre dos proyectos de tu instancia, `trigger:project` no necesita ningún secreto.

---

## 3. Cómo se configura

Después de un pipeline de `main`, el job de disparo apunta al pipeline de abajo:

```bash
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/bridges" \
  | jq -c '.[] | {name, status, abajo: .downstream_pipeline.web_url}'
```

Y en `infra/entornos`, sus pipelines disparados desde arriba:

```bash
PI=$(printf '%s' "plataforma-<tu-dominio>/infra/entornos" | jq -sRr @uri)
curl -s -H "$H" "$API/projects/$PI/pipelines?source=pipeline&per_page=3" \
  | jq -r '.[] | "\(.id) \(.status) \(.name)"'
```

En la UI: el grafo del pipeline de `app` muestra `infra` con una flecha al pipeline de abajo, y el de abajo, a su pipeline de arriba.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| `infra/entornos` con `workflow` que no acepta `pipeline` | El disparo falla: no se crea nada | Una regla para `CI_PIPELINE_SOURCE == "pipeline"` |
| Bajar la restricción de variables a `developer` para que "funcione" | Cualquier Developer de `infra` lanza su pipeline con variables arbitrarias | `maintainer`, y que fusione quien tiene el rol |
| Un token de disparo entre dos proyectos de la misma instancia | Un secreto que rotar sin necesidad | `trigger:project` |
| Disparar desde cada merge request | `infra` recibe paquetes que nunca llegarán a `main` | Solo desde `main` |
| `trigger` sin `strategy` hacia un despliegue | `main` en verde con el despliegue en rojo | `strategy: mirror` |

---

## 5. Trucos

- **El pipeline de arriba, desde abajo**: `GET .../pipelines/<id>` no lo dice; la vista del pipeline sí, y en GraphQL `pipeline { upstream { id project { fullPath } } }`.
- **Probar el pipeline de abajo sin pasar por `app`**: añade a su `workflow` una regla para `web` y lánzalo desde `Build → Pipelines → Run pipeline` con las variables a mano. Como Maintainer, la restricción te deja.

---

## 📚 Recursos Adicionales

- [Multi-project pipelines](https://docs.gitlab.com/ci/pipelines/downstream_pipelines/#multi-project-pipelines)
- [`trigger:project`](https://docs.gitlab.com/ci/yaml/#triggerproject) y [`trigger:forward`](https://docs.gitlab.com/ci/yaml/#triggerforward)
- [Restrict pipeline variables](https://docs.gitlab.com/ci/variables/#restrict-pipeline-variables) — se aplica a los disparos con variables
- [Trigger pipelines by using the API](https://docs.gitlab.com/ci/triggers/)

---

## ✅ Checklist de Verificación

- [ ] Sabes con la identidad de quién se crea el pipeline de `infra/entornos`
- [ ] Sabes por qué un disparo con variables depende de la configuración del proyecto de abajo
- [ ] Sabes qué valor tiene `CI_PROJECT_PATH` en el pipeline de abajo
- [ ] Sabes cuándo un token de disparo es la herramienta y cuándo sobra

---

[← Anterior: Pipelines hijos dinámicos](04-pipelines-hijos-dinamicos.md) · [Volver a la Semana 11](../README.md) · [Siguiente: El job token entre proyectos →](06-job-token-entre-proyectos.md)

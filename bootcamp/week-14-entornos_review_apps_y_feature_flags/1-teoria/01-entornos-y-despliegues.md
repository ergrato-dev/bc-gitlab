# Entornos y despliegues

> Desde la Semana 10, `app` tiene dos entornos, `staging` y `production`, y cada uno tiene un historial de despliegues que no han desplegado nada. Esta semana los despliegues son de verdad y conviene saber qué guarda GitLab de cada uno, porque es lo que se lee para volver atrás, para saber qué corre dónde y para medir. Todo es Free.

---

## 🎯 Objetivos

- Distinguir un entorno de un despliegue, y saber qué crea cada uno
- Leer el historial de un entorno por API y por la UI
- Elegir el `action` de un job que toca un entorno sin desplegar en él
- Explicar por qué el SHA de un despliegue de `infra/entornos` no es el de `app`

---

## 1. Qué problema resuelve

Sin entornos, la pregunta "¿qué versión hay en `production`?" se contesta abriendo el servidor, o preguntando a quien desplegó el viernes. Con entornos, GitLab la contesta solo, porque **cada job que despliega deja un registro**: quién, cuándo, desde qué pipeline y con qué resultado.

Ese registro es lo que esta semana usa todo lo demás:

| Lo que necesitas | Lo que lo da |
|---|---|
| Volver a la versión de ayer | El despliegue de ayer y su job, que se puede reintentar (teoría 05) |
| Parar la copia de una merge request al fusionarla | El entorno de la merge request y su job de parada (teoría 04) |
| Encender una función solo en `staging` | El nombre del entorno, que viaja hasta el destino (teoría 06) |
| Contar cuántas veces se despliega por semana | La lista de despliegues con éxito de `production` (teoría 08) |

---

## 2. Cómo funciona

### 2.1 Entorno y despliegue

| | Entorno | Despliegue |
|---|---|---|
| Qué es | Un sitio donde corre una versión: un nombre, una URL, un estado | Una vez que un job llevó una versión a ese sitio |
| Cuándo nace | La primera vez que un job lo nombra en `environment:name` | Cada vez que corre un job con `environment` y `action: start` |
| Cuántos hay | Pocos y estables, o uno por merge request | Uno por job, para siempre |
| Dónde se ve | `Operate → Environments` | Al pulsar el entorno: su historial |

Un entorno tiene **estado**: `available` mientras hay algo desplegado, `stopping` mientras corre su job de parada, `stopped` después. Solo un entorno parado se puede borrar.

### 2.2 El tier

GitLab clasifica cada entorno en uno de cinco *tiers*: `production`, `staging`, `testing`, `development` u `other`. Lo deduce del nombre con expresiones que prueba en orden (`guess_tier` en `app/models/environment.rb`): primero `dev|review|trunk`, luego las de pruebas, luego `stg|stag|pre|demo|model|non`, y al final `prod|prd|live`. `review/12` es `development`; `produccion` es `production`; pero `preproduccion` es **`staging`**, porque `pre` se prueba antes que `prod`. Si el nombre no dice lo que quieres, se fija a mano:

```yaml
environment:
  name: europa
  deployment_tier: production
```

El tier no da permisos. Lo usan las métricas (la teoría 08 cuenta solo `production`) y los paneles para ordenar.

### 2.3 Lo que hace cada `action`

| `action` | Crea despliegue | Para qué |
|---|:--:|---|
| `start` (por defecto) | Sí | Desplegar |
| `prepare` | No | Preparar algo antes, como una migración, sin que cuente como despliegue |
| `verify` | No | Comprobar el entorno después de desplegar |
| `access` | No | Leer del entorno, por ejemplo para sacar un log |
| `stop` | No | Pararlo: el entorno pasa a `stopped` |

Un job con `prepare`, `verify` o `access` recibe los secretos del entorno (su `environment_scope`, Semana 10) **sin aparecer en el historial**. Es la forma limpia de que un job de comprobación lea `DEPLOY_SSH_KEY` sin inflar la frecuencia de despliegue.

### 2.4 Las variables del job

| Variable | Valor en un job de `review/12` |
|---|---|
| `CI_ENVIRONMENT_NAME` | `review/12` |
| `CI_ENVIRONMENT_SLUG` | `review-12-a1b2c3`: el nombre apto para una URL o un directorio (teoría 04) |
| `CI_ENVIRONMENT_URL` | La `url` del job, ya expandida |
| `CI_ENVIRONMENT_TIER` | `development` |
| `CI_ENVIRONMENT_ACTION` | `start` |

### 2.5 El SHA que guarda un despliegue

Un despliegue guarda el SHA **del commit del pipeline que lo hizo**. En `app` eso es lo esperado. En `infra/entornos` no: el pipeline lo dispara `app`, pero corre sobre `main` de `infra/entornos`, así que el despliegue guarda el commit de `infra/entornos`. Diez despliegues seguidos de diez versiones de `app` tienen **el mismo SHA**.

```bash
glab api "projects/plataforma-<tu-dominio>%2Finfra%2Fentornos/deployments?environment=staging&per_page=3" \
  | jq -r '.[] | "\(.id) \(.sha[0:8]) \(.deployable.pipeline.id)"'
# 14 aa513d80 61
# 13 aa513d80 57
# 12 aa513d80 60
```

¿Dónde está entonces la versión de `app`? En dos sitios que sí la llevan: el **nombre del pipeline** de `infra/entornos` (`app 3ba2960a… → staging`, el `workflow:name` de la Semana 12) y el propio destino, que responde con el SHA que corre (teoría 02). La teoría 05 explica qué rompe esto en GitLab, y por qué no importa tanto.

---

## 3. Cómo se configura

Con la UI: `Operate → Environments`. Cada entorno enseña su último despliegue, y al pulsarlo, el historial con un botón para volver a desplegar cada uno.

Con `glab`, todo es API:

```bash
# Los entornos de infra/entornos, con su estado y su URL
glab api "projects/plataforma-<tu-dominio>%2Finfra%2Fentornos/environments" \
  | jq -c '.[] | {name, state, tier, external_url}'
# {"name":"staging","state":"available","tier":"staging","external_url":"http://localhost:8095/staging/salud"}

# Los despliegues con éxito de production, del más nuevo al más viejo
glab api "projects/plataforma-<tu-dominio>%2Finfra%2Fentornos/deployments?environment=production&status=success&order_by=id&sort=desc" \
  | jq -r '.[] | "\(.created_at[0:16]) \(.user.username) job \(.deployable.id)"'
```

Parar un entorno por API lanza su job de parada, si tiene uno:

```bash
glab api --method POST "projects/:id/environments/<id>/stop"
```

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Una rama por entorno (`staging`, `production`) para saber qué hay en cada uno | Fusiones que no son revisiones, historias que divergen (Semana 08) | Un entorno de GitLab por sitio, y `main` desplegándose en ellos |
| Un job de comprobación con `environment: production` y sin `action` | Cada comprobación cuenta como despliegue y la frecuencia se infla | `action: verify` |
| Buscar la versión de `app` en el SHA del despliegue de `infra/entornos` | Siempre es el commit de `infra/entornos` | El nombre del pipeline, o preguntar al destino |
| Borrar un entorno para "limpiar" | Se pierde el historial, y con él la medición y el rollback | Pararlo; borrar solo las review apps |

---

## 5. Trucos

- `GET /projects/:id/environments?states=stopped` lista los entornos parados; con `search=review/`, solo las review apps.
- El historial de un entorno en la UI agrupa por la parte del nombre antes de `/`: todas las `review/*` salen en una carpeta.
- `deployable.pipeline.id` de un despliegue dice de qué pipeline salió. Si un despliegue nuevo tiene un pipeline **más viejo** que el anterior, alguien volvió atrás (la comprobación `rollback-en-staging` mira justo eso).

---

## 📚 Recursos Adicionales

- [Environments](https://docs.gitlab.com/ci/environments/)
- [`environment` en `.gitlab-ci.yml`](https://docs.gitlab.com/ci/yaml/#environment)
- [API de despliegues](https://docs.gitlab.com/api/deployments/)

---

## ✅ Checklist de Verificación

- [ ] Sé qué crea un despliegue y qué no lo crea
- [ ] Sé qué `action` usar para un job que comprueba sin desplegar
- [ ] Sé dónde buscar la versión de `app` que desplegó un pipeline de `infra/entornos`
- [ ] Puedo listar el historial de `staging` por API

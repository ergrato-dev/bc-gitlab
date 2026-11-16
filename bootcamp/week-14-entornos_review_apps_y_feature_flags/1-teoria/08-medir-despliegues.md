# Medir despliegues

> En la Semana 08, `scripts/metricas.sh` medía la frecuencia de entrega contando releases, porque `app` no se desplegaba en ningún sitio y la release era el momento en que un cambio llegaba a alguien. Se dejó escrito que eso cambiaría con los entornos. Ahora un cambio llega a quien usa `app` cuando se despliega en `production`, y eso es lo que hay que contar.

---

## 🎯 Objetivos

- Explicar por qué una release y un despliegue no miden lo mismo
- Contar los despliegues con éxito de `production` por API
- Cambiar `scripts/metricas.sh` para que lea los despliegues de otro proyecto
- Saber qué daría el panel de DORA de pago y qué lo sustituye

---

## 1. Qué problema resuelve

| Pregunta de DORA | Semana 08 | Desde hoy |
|---|---|---|
| ¿Cada cuánto llega un cambio a producción? | Releases publicadas | **Despliegues con éxito en `production`** |
| ¿Cuánto tarda un cambio en llegar? | De abrir la merge request a fusionarla | Igual |
| ¿Qué parte de las entregas falla? | Releases con parche | Igual |
| ¿Cuánto se tarda en recuperar? | Issues `tipo::bug` cerrados | Igual |

Solo cambia la primera fila, que era la promesa. Una release y un despliegue pueden coincidir, pero no tienen por qué: con `infra-production` manual, `main` puede tener tres fusiones en `staging` antes de que alguien pulse el botón, y una release puede no desplegarse nunca. La frecuencia de despliegue mide lo que dice su nombre.

---

## 2. Cómo funciona

### 2.1 Los despliegues están en otro proyecto

`scripts/metricas.sh` pregunta a la API de `app`. Los despliegues de `production` son de `infra/entornos`. Eso cambia dos cosas:

| Qué | En `app` | En `infra/entornos` |
|---|---|---|
| El proyecto de la URL | `$CI_PROJECT_ID` o `$PROYECTO` | La ruta del grupo raíz más `/infra/entornos` |
| Quién puede leerlo | `METRICAS_TOKEN` o `GITLAB_TOKEN`, desde tu máquina | El mismo token, si su usuario es miembro de `infra/entornos` |

Desde tu máquina no hay nada más que hacer: tu token ve los dos proyectos. Dentro de un job, que es donde la Semana 08 quería llevar el script algún día, el `CI_JOB_TOKEN` de `app` puede leer los despliegues de `infra/entornos` **si `app` está en la lista de permitidos del job token de `infra/entornos`** (Semana 11, al revés que hasta ahora). Comprobado en `19.2.4`: con `app` en esa lista, `JOB-TOKEN` lee `deployments` y `environments` de `infra/entornos`. El script lo deja preparado y no se activa hasta que haga falta.

### 2.2 La consulta

```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/plataforma-<tu-dominio>%2Finfra%2Fentornos/deployments?environment=production&status=success&updated_after=$DESDE&per_page=100" \
  | jq length
# 3
```

| Parámetro | Por qué |
|---|---|
| `environment=production` | Solo `production`: un despliegue en `staging` no llega a nadie |
| `status=success` | Un despliegue fallido no entregó nada |
| `updated_after` | La ventana. `finished_after` también existe, pero exige `order_by=finished_at` (`400 Bad request` sin él) |

Un rollback **cuenta** como despliegue. Es correcto: cambió lo que corría en `production`. Si quieres separarlos, la teoría 05 da la pista (`deployable.pipeline.id` más viejo que el del anterior).

### 2.3 El cambio en `metricas.sh`

La sección 1 deja de leer releases y pasa a leer despliegues. El resto del script no cambia:

```bash
GRUPO_RAIZ=${CI_PROJECT_ROOT_NAMESPACE:-${PROYECTO%%/*}}
INFRA=$(printf '%s/infra/entornos' "$GRUPO_RAIZ" | jq -sRr @uri)
if [ -n "${CI_JOB_TOKEN:-}" ]; then CAB_INFRA="JOB-TOKEN: $CI_JOB_TOKEN"
else CAB_INFRA="PRIVATE-TOKEN: ${METRICAS_TOKEN:-$GITLAB_TOKEN}"; fi
despliegues=$(curl -sf -H "$CAB_INFRA" \
  "$API/projects/$INFRA/deployments?environment=production&status=success&updated_after=$DESDE&per_page=100") \
  || { echo "La API no respondió a los despliegues de infra/entornos" >&2; exit 1; }

# 1. Frecuencia de despliegue: despliegues con éxito en production en la ventana
jq -r --argjson dias "$DIAS" '
  "Frecuencia de despliegue: \(length * 70 / $dias | round / 10) por semana (n = \(length))"' <<<"$despliegues"
```

`CI_PROJECT_ROOT_NAMESPACE` es una variable predefinida: el grupo raíz del proyecto del job. Fuera de un job, el script la saca de `$PROYECTO` (`plataforma-<tu-dominio>/app`), igual que hacía con `P`.

La tasa de fallo **sigue** contando releases con parche. Podría pasar a contar despliegues seguidos de un rollback, pero con tan pocos despliegues el número saldría de dos o tres casos; se queda como está, y lo dice `docs/metricas.md`.

### 2.4 Lo que es de pago

| Feature | Tier | Qué da | Sustituto |
|---|---|---|---|
| Panel de DORA (*CI/CD analytics*, *Value streams dashboard*) | Ultimate | Las cuatro métricas calculadas, con su histórico | `scripts/metricas.sh` y `docs/metricas.md` |
| API de DORA (`/projects/:id/dora/metrics`) | Ultimate | Lo mismo por API. En CE responde `404 Not Found` | La API de despliegues, como arriba |
| *Value stream analytics* por etapas | Free (básico) / Premium | Tiempo en cada etapa del issue a producción | — |

El cálculo de GitLab hace lo mismo que el script: cuenta despliegues con éxito en entornos con tier `production` (teoría 01). Por eso el tier importa aunque no dé permisos.

---

## 3. Cómo se configura

En tu máquina, con `~/.bc-gitlab` cargado:

```bash
scripts/metricas.sh 30
# Frecuencia de despliegue: 0.7 por semana (n = 3)
# Tiempo de entrega:       mediana 2.1 h (n = 9)
# …
```

El día que el script corra en un job, la lista de permitidos de `infra/entornos` necesitará a `app`:

```bash
glab api --method POST "projects/plataforma-<tu-dominio>%2Finfra%2Fentornos/job_token_scope/allowlist" \
  -F target_project_id=<id de app> | jq -c .
# {"source_project_id":<infra>,"target_project_id":<app>}
```

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Contar los despliegues de `staging` | Mide fusiones, no entregas | Solo `production` |
| Contar todos los estados | Los fallidos inflan la frecuencia | `status=success` |
| Un token de proyecto de `app` para leer `infra/entornos` | Un token de proyecto solo es miembro de su proyecto: `404` | Tu token en local; `CI_JOB_TOKEN` y la lista de permitidos en un job |
| Comparar el número con el de otro equipo | Despliegues de tamaños distintos no se comparan | Compararlo contigo mismo, mes a mes |

---

## 5. Trucos

- `deployments?environment=production&status=success&per_page=1&order_by=id&sort=desc` da el último despliegue de `production` en una llamada: la respuesta a "¿qué hay en producción?" que no necesita abrir el destino.
- Un `404` de un job al leer `infra/entornos` es la lista de permitidos de **`infra/entornos`**, no la de `app` (Semana 13, teoría 07).

---

## 📚 Recursos Adicionales

- [DORA metrics (Ultimate)](https://docs.gitlab.com/user/analytics/dora_metrics/)
- [API de despliegues: listar](https://docs.gitlab.com/api/deployments/#list-all-project-deployments)
- [Variables predefinidas](https://docs.gitlab.com/ci/variables/predefined_variables/)

---

## ✅ Checklist de Verificación

- [ ] Sé por qué una release no es un despliegue
- [ ] Sé qué tres filtros lleva la consulta de despliegues
- [ ] Sé con qué token leería un job los despliegues de `infra/entornos`, y qué lista de permitidos lo dejaría
- [ ] Sé qué daría Ultimate y qué hace en su lugar el script

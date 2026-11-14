# La vida de un job

> Un job pasa por media docena de estados, deja un log que es la única prueba de lo que hizo, y recibe un token que caduca al terminar. Saber leer los tres es la diferencia entre "el pipeline está rojo" y "el pipeline está rojo porque…".

---

## 🎯 Objetivos

- Reconocer los estados de un job y las razones de fallo más comunes
- Leer el log de un job por API y entender sus secciones
- Reintentar y cancelar jobs, y saber quién puede hacerlo
- Distinguir `allow_failure`, `interruptible` y `timeout`
- Saber qué puede hacer `CI_JOB_TOKEN` y por qué `gobernanza` necesita otro token

---

## 1. Qué problema resuelve

Un pipeline rojo no dice nada por sí solo. Puede ser un test roto (culpa del cambio), un runner caído (culpa de la plataforma) o un job que tardó demasiado (culpa de nadie todavía). Cada caso pide una respuesta distinta, y GitLab las distingue: hay que saber dónde mirarlo.

---

## 2. Cómo funciona

### 2.1 Los estados

| Estado | Qué significa |
|---|---|
| `created` | En el pipeline, esperando a que termine el stage anterior |
| `pending` | Listo, esperando a que un runner lo recoja |
| `running` | Un runner lo está ejecutando |
| `success` | Terminó con código `0` |
| `failed` | Terminó con otro código, o algo lo tumbó |
| `canceled` | Alguien o algo lo canceló |
| `skipped` | No se ejecutó porque falló un stage anterior |
| `manual` | Espera a que alguien lo lance (Semana 14) |

Un job que se queda en `pending` no es un fallo del job: no hay runner que pueda cogerlo. Si sigue así una hora, GitLab lo da por perdido.

### 2.2 Por qué falló

`failure_reason` lo dice sin abrir el log:

| `failure_reason` | Qué pasó | De quién es |
|---|---|---|
| `script_failure` | Un comando del script devolvió distinto de `0` | Del cambio, casi siempre |
| `job_execution_timeout` | Superó su `timeout` | Del job o del runner |
| `stuck_or_timeout_failure` | Nadie lo recogió a tiempo | De la plataforma: no hay runner |
| `runner_system_failure` | El runner falló al preparar o limpiar | De la plataforma |
| `unmet_prerequisites` | No se pudo preparar algo que el job necesitaba | De la plataforma |

```bash
curl -s -H "$H" "$API/projects/$P/jobs?scope[]=failed&per_page=10" \
  | jq -r '.[] | "\(.id) \(.name) \(.failure_reason)"'
```

### 2.3 El log

El log (*job log*, en la API *trace*) es texto plano con códigos de color ANSI y marcas de sección. Las secciones de un job del ejecutor Docker, en orden:

| Sección | Qué hace |
|---|---|
| `prepare_executor` | Descarga la imagen |
| `get_sources` | Clona o actualiza el repositorio |
| `restore_cache` | Recupera la caché (teoría 06) |
| `download_artifacts` | Descarga los artefactos de stages anteriores (teoría 05) |
| `step_script` | `before_script` y `script` |
| `archive_cache`, `upload_artifacts_on_success` | Guarda caché y artefactos |

Para leerlo en la terminal sin colores:

```bash
curl -s -H "$H" "$API/projects/$P/jobs/$JOB/trace" \
  | sed 's/\x1b\[[0-9;]*m//g' | grep -v '^section_' | tail -30
```

El log se guarda como artefacto del job (tipo `trace`) y caduca con él.

### 2.4 Reintentar y cancelar

| Acción | API | Rol mínimo |
|---|---|---|
| Reintentar un job | `POST .../jobs/<id>/retry` | Developer |
| Cancelar un job | `POST .../jobs/<id>/cancel` | Developer |
| Reintentar los fallidos de un pipeline | `POST .../pipelines/<id>/retry` | Developer |
| Lanzar otro pipeline para una merge request | `POST .../merge_requests/<iid>/pipelines` | Developer |

Es lo que la Semana 03 apuntó como `update_build` y `cancel_build`. Reintentar crea un job **nuevo**, con otro ID, en el mismo pipeline.

### 2.5 Tres palabras clave que cambian el destino de un job

| Palabra clave | Efecto | En `app` |
|---|---|---|
| `allow_failure: true` | Si falla, el pipeline sigue en verde con un aviso (estado `success` con *warnings*) | `gobernanza`: detecta, no bloquea (ADR-005) |
| `interruptible: true` | Un pipeline más nuevo de la misma rama lo cancela si aún corre | Todos los jobs: el ajuste del proyecto `auto_cancel_pending_pipelines` está `enabled` por defecto |
| `timeout: 10m` | Límite propio del job, por debajo del del proyecto (1 h por defecto, `build_timeout`) | No hace falta todavía |

> [!WARNING]
> `allow_failure: true` **no** es "el job no importa". Con *Pipelines must succeed* activado, un job con `allow_failure` que falla no impide fusionar. Si `gobernanza` dice `❌`, hay que leerlo antes de fusionar: el pipeline no lo hará por ti.

### 2.6 `CI_JOB_TOKEN`

Cada job recibe un token que solo vale mientras el job corre y que actúa con los permisos de quien lanzó el pipeline, **pero solo sobre una lista corta de endpoints**: artefactos, paquetes, releases, despliegues, el registro de contenedores, archivos del repositorio y la lectura de merge requests, entre otros. Se envía en la cabecera `JOB-TOKEN`, no en `PRIVATE-TOKEN`.

`gobernanza.sh` necesita tres cosas que esa lista no incluye:

| Lo que lee `gobernanza.sh` | ¿Con `CI_JOB_TOKEN`? |
|---|:--:|
| `merge_requests/<iid>` | ✅ |
| `repository/files/CODEOWNERS/raw` | ✅ |
| `merge_requests/<iid>/approvals` | ❌ |
| `merge_requests/<iid>/diffs` | ❌ |
| `merge_requests/<iid>/closes_issues` | ❌ |

Comprobado en el código de 19.2.4: los endpoints que aceptan el token de job llevan `job_token_allowed: true`, y esos tres no. Por eso el job usa un **token de acceso de proyecto** propio, de solo lectura, guardado como variable enmascarada (teoría 07).

El acceso **entrante** de otros proyectos con su `CI_JOB_TOKEN` está limitado por defecto: `GET .../job_token_scope` dice `inbound_enabled: true`. Vuelve en la Semana 11, cuando `app` dispare pipelines en `infra`.

---

## 3. Cómo se configura

Nada nuevo: `allow_failure`, `interruptible` y `timeout` van en el job; `build_timeout` y `auto_cancel_pending_pipelines` son ajustes del proyecto (`Settings → CI/CD → General pipelines`, o `PUT /projects/:id`).

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Reintentar hasta que salga verde | Se esconde un test inestable que fallará en el peor momento | Leer el log; si es inestable, arreglarlo o aislarlo |
| `allow_failure: true` para "desbloquear" | El fallo deja de verse | Arreglar el job, o quitarlo |
| Jobs no interrumpibles en ramas de trabajo | Cada push deja pipelines viejos ocupando el runner | `interruptible: true` por defecto |
| Usar un token personal en un job | Si se filtra, actúa como tú en toda la instancia | `CI_JOB_TOKEN`, o un token de proyecto con el mínimo |
| Imprimir variables para depurar | Los tokens acaban en un log que lee cualquier Developer | Imprimir solo nombres, nunca valores |

---

## 5. Trucos

- **El estado de cada job del último pipeline de `main`**: `GET .../pipelines/latest?ref=main` para el ID, y `GET .../pipelines/<id>/jobs | jq -r '.[] | "\(.name) \(.status) \(.duration)"'`.
- **Esperar a que termine un pipeline** en un script: `until curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE" | jq -e '.status | IN("success","failed","canceled")' > /dev/null; do sleep 10; done`.
- **Quién lanzó un job**: `GET .../jobs/<id> | jq .user.username`. Es con sus permisos con los que actúa `CI_JOB_TOKEN`.

---

## 📚 Recursos Adicionales

- [Jobs](https://docs.gitlab.com/ci/jobs/) — estados, log y reintentos
- [Job logs](https://docs.gitlab.com/ci/jobs/job_logs/) — secciones, colores y secciones plegables propias
- [CI/CD job token](https://docs.gitlab.com/ci/jobs/ci_job_token/) — qué endpoints acepta y cómo se limita
- [Jobs API](https://docs.gitlab.com/api/jobs/) — listar, reintentar, cancelar y leer el log

---

## ✅ Checklist de Verificación

- [ ] Sabes distinguir por `failure_reason` un fallo del cambio de uno de la plataforma
- [ ] Sabes leer el log de un job sin abrir el navegador
- [ ] Sabes qué hace `allow_failure` con *Pipelines must succeed* activado
- [ ] Sabes por qué `gobernanza` no puede usar `CI_JOB_TOKEN`

---

[← Anterior: El runner](03-el-runner.md) · [Volver a la Semana 09](../README.md) · [Siguiente: Artefactos →](05-artefactos.md)

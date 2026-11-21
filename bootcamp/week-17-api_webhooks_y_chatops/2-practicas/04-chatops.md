# Práctica 04 — ChatOps

> Activas la integración de slash commands de Mattermost en `ci/automatizacion` y haces de Mattermost con `curl`: el mismo formulario, campo a campo, con el receptor como canal. Vinculas tu cuenta y verificas la petición en el navegador, escribes el job `estado`, y lanzas `run auditar` y `run estado production` desde el "chat". Provocas un hallazgo, lo ves llegar al canal, lo corriges por API. Las respuestas llegan al canal, junto a los avisos de los webhooks.

**Duración estimada**: 50 min
**Prerrequisitos**: Prácticas 01 a 03 completadas · Navegador con sesión en tu instancia · Teoría [06](../1-teoria/06-chatops.md) leída

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 0 | Variables y la función `chat` | — |
| 1 | La integración activa | `chatops-activo` |
| 2 | Tu cuenta del chat vinculada | — |
| 3 | La petición verificada | — |
| 4 | El job `estado` | — |
| 5 | `run auditar` desde el chat | `chatops-ejecutado` |
| 6 | Un hallazgo provocado, visto desde el chat y corregido por API | — |
| 7 | `run estado` y `run estado production` | `chatops-ejecutado` |
| 8 | Lo que el chat no puede hacer | — |
| 9 | La auditoría diaria | `auditoria-programada`, `auditoria-en-verde` |

---

## Paso 0: Preparar el terreno

**Por qué**: Mattermost genera el token de la integración cuando creas el slash command; aquí lo generas tú. La función `chat` manda lo que mandaría Mattermost (teoría 06, apartado 2.1): el token, el texto, quién eres en el chat, desde qué canal y dónde contestar. El `response_url` es la ruta `/canal/` del receptor, con el token del canal de la práctica 03.

```bash
source ~/.bc-gitlab; source ~/.bc-gitlab-s17
export H="PRIVATE-TOKEN: $GITLAB_TOKEN" API="$GITLAB_URL/api/v4"
export R="http://localhost:${DESTINO_PORT:-8095}/receptor"
grep -q SLASH_TOKEN ~/.bc-gitlab-s17 \
  || echo "export SLASH_TOKEN=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')" >> ~/.bc-gitlab-s17
source ~/.bc-gitlab-s17
source <(grep '^RECEPTOR_CANAL_TOKEN=' /ruta/al/repositorio/bc-gitlab/.env)

chat() {   # $1 = el texto que escribirías detrás de /gitlab automatizacion
  curl -s --request POST "$API/projects/$PA/integrations/mattermost_slash_commands/trigger" \
    --form-string "token=$SLASH_TOKEN" --form-string "text=$1" \
    --form-string "user_id=u-$(whoami)" --form-string "user_name=$(whoami)" \
    --form-string team_id=t-plataforma --form-string team_domain=plataforma \
    --form-string channel_id=c-operaciones --form-string channel_name=operaciones \
    --form-string "response_url=http://destino:8080/receptor/canal/$RECEPTOR_CANAL_TOKEN" \
    | jq -r .text
}
canal() { curl -s "$R/" | jq -r '.[-2:][] | "\(.hora) \(.resumen)\n\(.salida // "")"'; }
```

Y `esperar`, del paso 0 de la [práctica 01](01-el-bot-auditor.md#paso-0-preparar-el-terreno).

`--form-string`, no `-F`: el texto de un comando es entrada de usuario, y con `-F` un texto que empiece por `@` leería un archivo de tu disco.

**Verifica**: `echo ${#SLASH_TOKEN} ${#RECEPTOR_CANAL_TOKEN}` da `32 32`.

---

## Paso 1: La integración

**Por qué**: la integración es el enchufe del chat en el proyecto: sin ella, el endpoint `trigger` no existe para `ci/automatizacion`. Se activa con el token que Mattermost mandará en cada comando.

**Con la UI**: `Settings → Integrations → Mattermost slash commands` de `ci/automatizacion`. Pega `$SLASH_TOKEN` en *Token*, *Active* marcado, *Save changes*. La página muestra también los datos para crear el comando en Mattermost: no los necesitas.

**Con la API**:

```bash
curl -s --request PUT "$API/projects/$PA/integrations/mattermost-slash-commands" -H "$H" \
  --data "token=$SLASH_TOKEN" | jq -c '{active, title}'
```

**Verifica**: `{"active":true,"title":"Mattermost slash commands"}`. Y con un token equivocado, el endpoint no existe:

```bash
SLASH_TOKEN=otro chat help
# null   (la API contesta {"message":"404 Integration Not Found"})
```

---

## Paso 2: Vincular tu cuenta

**Por qué**: GitLab no sabe quién es `u-<tu usuario>` del chat. El primer comando de cada persona devuelve un enlace que solo funciona con tu sesión de GitLab: abrirlo y autorizar es lo que liga esa cuenta del chat a tu usuario (teoría 06, apartado 2.2).

```bash
chat help
```

Sale: `:wave: Hi there! Before I do anything for you, please <http://…/-/user_settings/integration_accounts/new?token=…|connect your GitLab account>.` Copia la URL (lo que va entre `<` y `|`), ábrela en el navegador y pulsa **Authorize** en *Authorize Mattermost slash commands (…) to use your account?*

**Verifica**:

```bash
chat help | head -3
```

Ya no pide vincular: pide verificar, o devuelve la lista de comandos.

En la UI: `User settings → Integration accounts`, una cuenta vinculada del equipo `plataforma`. Desde ahí se desvincula.

---

## Paso 3: Verificar la petición

**Por qué**: vincular dice quién eres; verificar dice que la petición viene del chat que dice venir. Es otra confirmación en la web, una vez mientras no cambie el token de la integración.

```bash
chat help
```

Sale: `To ensure the highest security standards, we verify the source of all slash commands. Please confirm the request by accessing <http://…/-/integrations/slash_commands?…|this link>`. Ábrela y pulsa **Authorize**.

**Verifica**:

```bash
canal
chat help | head -4
```

En el canal, `You've successfully verified! You now have access to slash commands…`: GitLab avisó al `response_url`. Y `help` ya contesta con `*Available commands*` y la lista: `issue show`, `issue new`, `deploy … to …`, `run <command> <arguments>`.

---

## Paso 4: El job `estado`

**Por qué**: `run <job>` ejecuta un job del `.gitlab-ci.yml`. `auditar` ya acepta `source: chat` desde la práctica 01. `estado` es nuevo: lee de `infra/entornos` lo último desplegado con éxito en cada entorno, por GraphQL y con el token del auditor, y devuelve una línea por entorno entre las marcas `chat_reply`. Si el comando trae argumento (`run estado production`), llega en `CHAT_INPUT` y filtra.

`src/estado.ts`:

```ts
// ChatOps: qué hay desplegado en cada entorno de infra/entornos (Semana 17).
// `run estado production` filtra por entorno; sin argumento, todos.
import { graphql, responderAlChat } from './gitlab.ts';

const CONSULTA = `query($proyecto: ID!) {
  project(fullPath: $proyecto) {
    environments {
      nodes {
        name
        lastDeployment(status: SUCCESS) { finishedAt job { pipeline { ... on Pipeline { name } } } }
      }
    }
  }
}`;

const proyecto = `${process.env.CI_PROJECT_ROOT_NAMESPACE}/infra/entornos`;
const filtro = (process.env.CHAT_INPUT ?? '').trim();
const { project } = await graphql(CONSULTA, { proyecto });
const lineas = project.environments.nodes
  .filter((e) => !filtro || e.name === filtro)
  .map((e) => e.lastDeployment
    ? `${e.name}: ${e.lastDeployment.job?.pipeline?.name ?? '?'} (${e.lastDeployment.finishedAt})`
    : `${e.name}: sin despliegues correctos`);
responderAlChat(lineas.length ? lineas : [`No hay ningún entorno ${filtro}`]);
```

`CHAT_INPUT` se compara, no se ejecuta: el texto del chat nunca llega a un `sh` (teoría 06, antipatrones).

Añade al final de `.gitlab-ci.yml`:

```yaml
estado:
  stage: operar
  script:
    - node --experimental-strip-types src/estado.ts
  rules:
    - if: $CI_PIPELINE_SOURCE == "chat"
```

```bash
cd /ruta/a/tus/clones/automatizacion
git add -A && git commit -S -m "feat: estado chat command"
git push
sleep 5
PIPE=$(curl -s -H "$H" "$API/projects/$PA/pipelines?per_page=1" | jq -r '.[0].id')
esperar "$PA" "$PIPE"
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$PA/pipelines/$PIPE/jobs" | jq -r '.[].name'
```

`test` y `desplegar-receptor`. Ni `estado` ni `auditar`: en un push no existen.

---

## Paso 5: `run auditar`

**Por qué**: la auditoría de cada mañana, a demanda, desde el canal donde se discute el problema. Corre el mismo job, con el mismo token, en `main`.

```bash
chat "run auditar"
sleep 60
canal
```

**Verifica**: `Your ChatOps job <…|#N> has been created!`, y en el canal `ChatOps job started by … completed successfully` con la salida: `Auditoría de plataforma-<tu-dominio>: 4 proyectos, 0 hallazgos`. Nada más: ni `npm`, ni los comandos del job, solo la sección `chat_reply`.

```bash
curl -s -H "$H" "$API/projects/$PA/pipelines?source=chat&per_page=1" | jq -c '.[0] | {source, ref, status, user: .user.username}'
```

`{"source":"chat","ref":"main","status":"success","user":"<tu usuario>"}`.

---

## Paso 6: Un hallazgo, por el chat

**Por qué**: un auditor que solo has visto en verde no sabes si mira. Relaja una protección como lo haría alguien con prisa y pide la auditoría desde el canal. Verás también un límite de ChatOps: cuando el job falla, al canal solo llega que ha fallado, no su salida.

```bash
PC=$(printf '%s' "$G/ci/componentes" | jq -sRr @uri)
curl -s --request PATCH "$API/projects/$PC/protected_branches/main" -H "$H" \
  --data allow_force_push=true | jq -c '{name, allow_force_push}'
chat "run auditar"
sleep 60
canal
```

En el canal, dos líneas: `ChatOps job started by … failed!`, sin salida, y el aviso del webhook de la práctica 03, `…/ci/automatizacion: pipeline #N de main failed`. El detalle está en el artefacto, que se guarda también cuando el job falla (`when: always`):

```bash
JOB=$(curl -s -H "$H" "$API/projects/$PA/jobs?scope=failed&per_page=1" | jq -r '.[0].id')
curl -s -H "$H" "$API/projects/$PA/jobs/$JOB/artifacts/auditoria.json" \
  | jq -c '.proyectos[] | select(.hallazgos | length > 0)'
```

`{"ruta":"plataforma-<tu-dominio>/ci/componentes","hallazgos":["main admite force push"]}`. Se corrige con la misma herramienta que lo encontró, por API, para que la corrección quede en el manual:

| Hallazgo | Corrección |
|---|---|
| `main admite force push` | `PATCH /projects/:id/protected_branches/main` con `allow_force_push=false` |
| `<rama> no está protegida` | `POST /projects/:id/protected_branches` con `name`, `push_access_level=40`, `merge_access_level=40`, `allow_force_push=false` |
| `el proyecto es público` | `PUT /projects/:id` con `visibility=private` |

```bash
curl -s --request PATCH "$API/projects/$PC/protected_branches/main" -H "$H" \
  --data allow_force_push=false | jq -c '{name, allow_force_push}'
chat "run auditar"
sleep 60
canal
```

**Verifica**: la última respuesta, `completed successfully` con `4 proyectos, 0 hallazgos`.

---

## Paso 7: `run estado`

```bash
chat "run estado"
sleep 45
canal
chat "run estado production"
sleep 45
canal
```

**Verifica**: la primera respuesta con una línea por entorno de `infra/entornos` (`staging`, `production`): el nombre del pipeline que desplegó (`app <sha> → staging`, el `workflow:name` de la Semana 14) y la hora. La segunda, solo `production`.

Si un entorno sale como `sin despliegues correctos`, es verdad: no hay ningún despliegue en verde en él. Si sale `No hay ningún entorno`, revisa que `infra/entornos` tenga entornos (`Operate → Environments`).

---

## Paso 8: Lo que el chat no puede hacer

**Por qué**: el chat ejecuta jobs con tus permisos. Antes de dar por buena la integración, comprueba sus bordes.

```bash
chat "run noexiste"
chat "run test"
```

**Verifica**:

- `run noexiste`: `The command could not be scheduled. Make sure that your project has a .gitlab-ci.yml that defines a job with the name "noexiste"`.
- `run test`: lo mismo. `test` existe, pero sus `rules` no aceptan `source: chat`, y un job que no entra en el pipeline es, para el chat, un job que no existe. Así decides qué se puede pedir desde el chat: solo los jobs cuya regla lo dice.

Y lo que haría falta para que otra persona lo use: ser al menos Developer de `ci/automatizacion`, vincular su cuenta y verificar. Un Guest del grupo vincula, verifica, y no lanza nada.

---

## Paso 9: Cada mañana

**Por qué**: el chat es la auditoría a demanda; falta la de todos los días. Un auditor que hay que acordarse de lanzar es un auditor que no se lanza. `play` ejecuta la programación ahora sin esperar a mañana, ese pipeline es el que mira `verificar-semana.sh`, y el webhook de la práctica 03 lo anuncia en el canal.

**Con la UI**: `Build → Pipeline schedules → New schedule`. Descripción `auditoria diaria`, `0 6 * * *`, tu zona horaria, rama `main`.

**Con la API**:

```bash
SID=$(curl -s --request POST "$API/projects/$PA/pipeline_schedules" -H "$H" \
  --data "description=auditoria diaria" --data ref=main --data "cron=0 6 * * *" \
  --data "cron_timezone=$(cat /etc/timezone 2>/dev/null || echo UTC)" | jq -r .id)
curl -s --request POST "$API/projects/$PA/pipeline_schedules/$SID/play" -H "$H" | jq -r .message
sleep 10
PIPE=$(curl -s -H "$H" "$API/projects/$PA/pipelines?source=schedule&per_page=1" | jq -r '.[0].id')
esperar "$PA" "$PIPE"
```

**Verifica**:

```bash
canal
curl -s -H "$H" "$API/projects/$PA/pipeline_schedules" | jq -c '.[] | {description, ref, cron, active, owner: .owner.username}'
```

En el canal, `…/ci/automatizacion: pipeline #N de main success`. Y la programación con `refs/heads/main`, `active: true` y tu usuario como `owner`. El pipeline programado corre con los permisos del dueño de la programación: si un día te vas del grupo, la programación se queda sin dueño y deja de correr. Va al manual del proyecto.

---

## ✅ Resultado

- [ ] La integración activa con un token que solo tú y "Mattermost" conocéis
- [ ] Tu cuenta del chat vinculada y la petición verificada, en el navegador
- [ ] `estado` y `auditar` solo existen en pipelines `chat` (y `auditar`, también programado)
- [ ] `run auditar` y `run estado` en verde, con su respuesta en el canal
- [ ] El hallazgo provocado visto en rojo, leído del artefacto, corregido por API y en verde otra vez
- [ ] Comprobado que el chat no lanza jobs cuyas `rules` no lo permiten
- [ ] La programación diaria activa, con su primer pipeline en verde y anunciado en el canal

```bash
./scripts/verificar-semana.sh 17
```

En esta práctica pasan `chatops-activo`, `chatops-ejecutado`, `auditoria-programada` y `auditoria-en-verde`.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `null` en vez de texto | La API contestó un error, no un mensaje de chat (`404 Integration Not Found`) | `SLASH_TOKEN` distinto del de la integración; repite el paso 1 |
| Cada comando vuelve a pedir verificar | Cambiaste el token de la integración: la verificación va ligada a él | Verifica otra vez (paso 3) |
| El enlace dice `The slash command verification request has expired` | Lo abriste tarde | Repite el comando y abre el enlace nuevo enseguida |
| El enlace dice `The slash command request is invalid` | Lo abriste con otro usuario de GitLab | Abre sesión con el usuario que vinculaste |
| `Your ChatOps job … has been created!` pero nada llega al canal | El token del canal del `response_url` no es el de `destino`, o `destino` no está en la lista de hosts permitidos | `RECEPTOR_CANAL_TOKEN` del `.env`; práctica 03, paso 2 |
| La respuesta llega vacía (solo marcas de hora) | El texto se escribió en la misma línea que `section_start` | Cada marca en su línea, como en `responderAlChat` |
| `AUDITOR_TOKEN no ha llegado` en el job de chat | La variable es protegida y el job no corrió en `main` | ChatOps siempre usa la rama por defecto: revisa que sea `main` |

---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| [Práctica 03 — Los webhooks](03-los-webhooks.md) | [Proyecto de la semana](../3-proyecto/README.md) |

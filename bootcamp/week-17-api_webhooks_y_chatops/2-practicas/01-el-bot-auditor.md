# Práctica 01 — El bot auditor

> Creas `ci/automatizacion`, el proyecto donde vivirá toda la automatización de la plataforma. Le das un bot de solo lectura con un token de grupo, miras el grupo con sus ojos (lo que ve, lo que no, y lo que GraphQL le calla), y escribes un auditor que recorre todos los proyectos cada mañana. En la práctica 04 le provocarás un hallazgo, lo verás desde el chat y lo programarás cada mañana.

**Duración estimada**: 50 min
**Prerrequisitos**: Semana 16 completada, clúster arrancado (`k3d cluster start bootcamp`) · Owner del grupo · Teoría [01](../1-teoria/01-la-api-rest-a-fondo.md), [02](../1-teoria/02-graphql-para-operar.md) y [03](../1-teoria/03-tokens-para-maquinas.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 0 | Variables de la semana | — |
| 1 | `ci/automatizacion`, privado, con `main` protegida y `k8s-app` | `automatizacion-existe`, `automatizacion-privado`, `automatizacion-en-kubernetes` |
| 2 | El token de grupo `auditor` | `token-auditor-solo-lectura`, `token-auditor-caduca` |
| 3 | El grupo visto por el bot | — |
| 4 | `AUDITOR_TOKEN`, oculta | `auditor-token-oculto` |
| 5 | El auditor y su job | — |
| 6 | La primera auditoría, por API | — |

---

## Paso 0: Preparar el terreno

**Por qué**: las variables de las semanas anteriores, más la ruta de `ci/automatizacion` codificada (`PA`), que esta semana aparece en casi todos los comandos.

```bash
source ~/.bc-gitlab
source ~/.bc-gitlab-s16
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
export G=${PROYECTO%%/*}
export PA=$(printf '%s' "$G/ci/automatizacion" | jq -sRr @uri)
{ echo "export G=$G"; echo "export PA=$PA"; } > ~/.bc-gitlab-s17
chmod 600 ~/.bc-gitlab-s17
mkdir -p ~/bc-s17 && chmod 700 ~/bc-s17
k3d cluster start bootcamp
```

Copia `esperar` del [paso 0 de la práctica 01 de la Semana 13](../../week-13-registry_de_contenedores_y_paquetes/2-practicas/01-el-registry-y-el-dockerfile.md#paso-0-preparar-el-terreno).

**Verifica**:

```bash
echo "$G $PA"
curl -s -H "$H" "$API/runners/$RID_K8S" | jq -c '{description, status, paused}'
```

`plataforma-<tu-dominio> plataforma-<tu-dominio>%2Fci%2Fautomatizacion`, y `k8s-app` `online`, sin pausar.

---

## Paso 1: `ci/automatizacion`

**Por qué**: la automatización es código, y el código vive en un proyecto con sus reglas. Privado, porque va a tener secretos. `main` protegida **antes** del primer push y sin force push, porque las variables protegidas solo llegan a ramas protegidas (teoría 03). Y un runner: `k8s-app` es de `app`, y se asigna también aquí, como en la Semana 12 con `ci/componentes`.

**Con la UI**: en el subgrupo `ci`, *New project → Create blank project*, privado, **sin** README. Luego `Settings → Repository → Protected branches` (`main`, push y merge Maintainers, force push apagado) y `Settings → CI/CD → Runners`, *Enable* en `k8s-app`.

**Con la API**:

```bash
NS=$(curl -s -H "$H" "$API/groups/$G%2Fci" | jq -r .id)
curl -s --request POST "$API/projects" -H "$H" \
  --data name=automatizacion --data "namespace_id=$NS" --data visibility=private \
  --data "description=Auditor, receptor de webhooks y ChatOps de la plataforma" | jq -r .path_with_namespace

curl -s --request POST "$API/projects/$PA/protected_branches" -H "$H" \
  --data name=main --data push_access_level=40 --data merge_access_level=40 \
  --data allow_force_push=false | jq -c '{name, allow_force_push}'

curl -s --request POST "$API/projects/$PA/runners" -H "$H" --data "runner_id=$RID_K8S" | jq -r .description
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$PA" | jq -c '{visibility, empty_repo}'
curl -s -H "$H" "$API/runners/$RID_K8S" | jq -r '.projects[].path_with_namespace'
```

`{"visibility":"private","empty_repo":true}`, y `k8s-app` con `app`, `ci/componentes` y `ci/automatizacion`. Proteger una rama que aún no existe es válido: la regla espera al primer push.

---

## Paso 2: El token de grupo `auditor`

**Por qué**: el auditor recorre todo el grupo, así que el token es **de grupo**, no de proyecto, y es de un bot, no tuyo (teoría 03, apartado 2.1). Reporter con `read_api`: lee proyectos y ramas protegidas, y nada más. Caduca en 90 días. El token sale una vez: va directo a un archivo que solo tú lees.

**Con la UI**: `Settings → Access tokens` del grupo raíz. Nombre `auditor`, caducidad dentro de 90 días, rol *Reporter*, scope `read_api`. Copia el token a `~/bc-s17/auditor.token`, sin salto de línea al final (una variable enmascarada no admite saltos de línea).

**Con la API**:

```bash
( umask 077
  curl -s --request POST "$API/groups/$G/access_tokens" -H "$H" \
    --data name=auditor --data access_level=20 --data "scopes[]=read_api" \
    --data "expires_at=$(date -d '+90 days' +%F)" | jq -r .token | tr -d '\n' > ~/bc-s17/auditor.token )
```

**Verifica**:

```bash
curl -s -H "$H" "$API/groups/$G/access_tokens" \
  | jq -c '.[] | select(.name == "auditor") | {id, active, scopes, access_level, expires_at}'
cut -c1-5 ~/bc-s17/auditor.token; stat -c %a ~/bc-s17/auditor.token
```

Una línea con `active: true`, `["read_api"]` y `20`; después `glpat` y `600`. Guarda el `id`: `echo "export TID_AUDITOR=<id>" >> ~/.bc-gitlab-s17`.

---

## Paso 3: El grupo con los ojos del bot

**Por qué**: antes de escribir el auditor, comprueba qué puede ver su token. Lo que ves tú no es lo que ve él, y la diferencia más peligrosa es la que no da error (teoría 02, apartado 2.5).

```bash
HB="PRIVATE-TOKEN: $(cat ~/bc-s17/auditor.token)"

# Lo que necesita: 200.
curl -s -o /dev/null -w '%{http_code} proyectos\n' -H "$HB" "$API/groups/$G/projects?include_subgroups=true"
curl -s -o /dev/null -w '%{http_code} rama protegida\n' -H "$HB" "$API/projects/$P/protected_branches/main"
# Lo que su rol no alcanza: 403 Forbidden.
curl -s -w ' webhooks\n' -H "$HB" "$API/projects/$P/hooks"
# Lo que su scope no alcanza: insufficient_scope.
curl -s --request POST -H "$HB" "$API/projects/$P/issues" --data title=prueba | jq -r .error
```

Y la misma pregunta por GraphQL, con tu token y con el suyo:

```bash
Q='query($p: ID!) { project(fullPath: $p) { branchRules { nodes { name } } } }'
for T in "$H" "$HB"; do
  curl -s "$GITLAB_URL/api/graphql" -H "$T" -H 'Content-Type: application/json' \
    -d "$(jq -nc --arg q "$Q" --arg p "$PROYECTO" '{query: $q, variables: {p: $p}}')" \
    | jq -c '.data.project.branchRules.nodes | map(.name)'
done
unset HB
```

**Verifica**: `200 proyectos`, `200 rama protegida`, `{"message":"403 Forbidden"} webhooks`, `insufficient_scope`. Y en GraphQL, `["All branches","main"]` con tu token y `[]` con el del bot. Esa lista vacía, sin `errors`, es el motivo de que el auditor pregunte las ramas por REST.

---

## Paso 4: `AUDITOR_TOKEN`, oculta

**Por qué**: enmascarada para que no salga en un log, oculta para que nadie la vuelva a leer, protegida para que solo llegue a `main` (teoría 03, apartado 2.5). Después, el archivo sobra: si alguna vez hace falta el token, se rota.

**Con la UI**: `Settings → CI/CD → Variables` de `ci/automatizacion` → *Add variable*. Visibilidad *Masked and hidden*, *Protect variable* marcado, clave `AUDITOR_TOKEN`.

**Con la API**:

```bash
curl -s --request POST "$API/projects/$PA/variables" -H "$H" \
  --data key=AUDITOR_TOKEN --data-urlencode "value@$HOME/bc-s17/auditor.token" \
  --data masked_and_hidden=true --data protected=true | jq -c '{key, masked, hidden, protected}'
shred -u ~/bc-s17/auditor.token
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$PA/variables/AUDITOR_TOKEN" | jq -c '{masked, hidden, protected, value}'
```

`{"masked":true,"hidden":true,"protected":true,"value":null}`. Ni tú la lees ya.

---

## Paso 5: El auditor

**Por qué**: tres comprobaciones sobre cada proyecto del grupo que no esté marcado para borrar: que no sea público, que su rama por defecto esté protegida, y que esa rama no admita force push. GraphQL lista los proyectos, paginando por cursor; REST mira la rama de cada uno. El resultado va a `auditoria.json` (artefacto), al log, y a una sección `chat_reply` que usarás en la práctica 04. Si hay hallazgos, el job sale con 1: una auditoría con problemas es un pipeline rojo.

Clona el proyecto vacío junto a tus otros clones:

```bash
cd /ruta/a/tus/clones
git clone "$(curl -s -H "$H" "$API/projects/$PA" | jq -r .ssh_url_to_repo)" automatizacion && cd automatizacion
mkdir -p src
```

`src/gitlab.ts`, lo que comparten todos los jobs de este proyecto:

```ts
// Lo que comparten los jobs de automatización: GraphQL con el token del auditor y
// la respuesta al chat (Semana 17).
// CI_SERVER_URL, no CI_API_GRAPHQL_URL: la instancia sobrescribe la primera para que
// los jobs lleguen a GitLab por la red del laboratorio, y la segunda dice localhost.
const URL_GRAPHQL = `${process.env.CI_SERVER_URL}/api/graphql`;

function cabeceras() {
  const token = process.env.AUDITOR_TOKEN;
  if (!token) throw new Error('AUDITOR_TOKEN no ha llegado: ¿rama protegida?');
  return { 'content-type': 'application/json', authorization: `Bearer ${token}` };
}

export async function graphql(query: string, variables: Record<string, unknown> = {}) {
  const res = await fetch(URL_GRAPHQL, {
    method: 'POST',
    headers: cabeceras(),
    body: JSON.stringify({ query, variables }),
  });
  // GraphQL contesta 200 aunque la consulta falle: los errores vienen en el cuerpo.
  const cuerpo = await res.json();
  if (!res.ok || cuerpo.errors) throw new Error(`GraphQL ${res.status}: ${JSON.stringify(cuerpo.errors ?? cuerpo)}`);
  return cuerpo.data;
}

// REST para lo que GraphQL no enseña a un Reporter. Devuelve null en un 404.
export async function rest(ruta: string) {
  const res = await fetch(`${process.env.CI_SERVER_URL}/api/v4/${ruta}`, { headers: cabeceras() });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`REST ${res.status} en ${ruta}`);
  return res.json();
}

// Lo que va entre estas dos marcas es lo único que ChatOps devuelve al canal.
export function responderAlChat(lineas: string[]) {
  const t = () => Math.floor(Date.now() / 1000);
  console.log(`section_start:${t()}:chat_reply\r\x1b[0K`);
  for (const l of lineas) console.log(l);
  console.log(`section_end:${t()}:chat_reply\r\x1b[0K`);
}
```

`src/auditar.ts`:

```ts
// Audita todos los proyectos del grupo (Semana 17): los lista por GraphQL, paginando,
// y mira la rama por defecto de cada uno por REST. Solo lee: el token es de un bot
// Reporter con read_api. Sale con 1 si hay hallazgos.
import { writeFileSync } from 'node:fs';
import { graphql, rest, responderAlChat } from './gitlab.ts';

const CONSULTA = `query($grupo: ID!, $tras: String) {
  group(fullPath: $grupo) {
    projects(includeSubgroups: true, first: 50, after: $tras) {
      pageInfo { hasNextPage endCursor }
      nodes {
        fullPath visibility markedForDeletion
        repository { rootRef }
      }
    }
  }
}`;

const grupo = process.env.CI_PROJECT_ROOT_NAMESPACE;
const proyectos = [];
let tras = null;
do {
  const { group } = await graphql(CONSULTA, { grupo, tras });
  if (!group) throw new Error(`el token no ve el grupo ${grupo}`);
  for (const p of group.projects.nodes) {
    if (p.markedForDeletion) continue; // borrado programado: ya no es de nadie
    const hallazgos = [];
    if (p.visibility === 'public') hallazgos.push('el proyecto es público');
    const rama = p.repository?.rootRef;
    if (rama) {
      // Por REST: a un Reporter, GraphQL le da branchRules vacío, sin error.
      const regla = await rest(`projects/${encodeURIComponent(p.fullPath)}/protected_branches/${encodeURIComponent(rama)}`);
      if (!regla) hallazgos.push(`${rama} no está protegida`);
      else if (regla.allow_force_push) hallazgos.push(`${rama} admite force push`);
    }
    proyectos.push({ ruta: p.fullPath, hallazgos });
  }
  tras = group.projects.pageInfo.hasNextPage ? group.projects.pageInfo.endCursor : null;
} while (tras);

const total = proyectos.reduce((n, p) => n + p.hallazgos.length, 0);
writeFileSync('auditoria.json', JSON.stringify({ fecha: new Date().toISOString(), grupo, proyectos }, null, 2) + '\n');
for (const p of proyectos) console.log(`${p.hallazgos.length ? '✗' : '✓'} ${p.ruta}${p.hallazgos.map((h) => `\n    - ${h}`).join('')}`);
responderAlChat([`Auditoría de ${grupo}: ${proyectos.length} proyectos, ${total} hallazgos`,
  ...proyectos.filter((p) => p.hallazgos.length).map((p) => `${p.ruta}: ${p.hallazgos.join('; ')}`)]);
process.exitCode = total ? 1 : 0;
```

`.gitlab-ci.yml`, con el primer job. Las prácticas 02 y 04 le añaden los suyos:

```yaml
# ci/automatizacion (Semana 17): auditor programado, receptor de webhooks y ChatOps.
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS && $CI_PIPELINE_SOURCE == "push"
      when: never
    - if: $CI_COMMIT_BRANCH

stages: [test, deploy, operar]

default:
  image: node:22.23.3-alpine3.24

auditar:
  stage: operar
  script:
    - node --experimental-strip-types src/auditar.ts
  artifacts:
    paths: [auditoria.json]
    when: always
    expire_in: 30 days
  rules:
    - if: $CI_PIPELINE_SOURCE =~ /^(schedule|chat|web|api)$/ && $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

`auditar` solo corre en `main` y cuando lo pide alguien o algo: una programación, el chat, la web o la API. En un push no corre: auditar no depende de lo que cambia este repositorio.

```bash
git add -A && git commit -S -m "feat: group auditor over GraphQL and REST"
git push -u origin main
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$PA/repository/tree?path=src" | jq -r '.[].name'
curl -s -H "$H" "$API/projects/$PA/pipelines" | jq length
```

`auditar.ts` y `gitlab.ts`, y `0` pipelines: el push no tiene ningún job que correr, y `workflow` no crea un pipeline vacío.

---

## Paso 6: La primera auditoría

**Por qué**: antes de programarlo, una ejecución a mano, por API, para ver su salida. Un pipeline creado por API tiene `source: api`, y `auditar` lo acepta.

```bash
PIPE=$(curl -s --request POST "$API/projects/$PA/pipeline" -H "$H" --data ref=main | jq -r .id)
esperar "$PA" "$PIPE"
JOB=$(curl -s -H "$H" "$API/projects/$PA/pipelines/$PIPE/jobs" | jq -r '.[] | select(.name == "auditar") | .id')
curl -s -H "$H" "$API/projects/$PA/jobs/$JOB/trace" | grep -a -E '✓|✗|    - |Auditoría' | cut -c33-
```

**Verifica**: `success`, una `✓` por proyecto (`app`, `infra/entornos`, `ci/componentes`, `ci/automatizacion`) y `Auditoría de plataforma-<tu-dominio>: 4 proyectos, 0 hallazgos`. Si sale algún `✗`, es real: alguna semana anterior dejó una rama sin proteger. Corrígelo con la tabla del [paso 6 de la práctica 04](04-chatops.md#paso-6-un-hallazgo-por-el-chat) y repite.

---

## ✅ Resultado

- [ ] `ci/automatizacion` privado, con `main` protegida sin force push y `k8s-app` asignado
- [ ] El token `auditor`: Reporter, `read_api`, caduca en 90 días, y el archivo borrado
- [ ] Has visto el `403`, el `insufficient_scope` y el `[]` de GraphQL del bot
- [ ] `AUDITOR_TOKEN` enmascarada, oculta y protegida
- [ ] La primera auditoría en verde, por API

```bash
./scripts/verificar-semana.sh 17
```

En esta práctica pasan `automatizacion-existe`, `automatizacion-privado`, `automatizacion-en-kubernetes`, `token-auditor-solo-lectura`, `token-auditor-caduca` y `auditor-token-oculto`. Las dos de la auditoría programada, en la práctica 04.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `400 Bad request - expires_at is missing` | La API exige caducidad | `--data expires_at=…` |
| `403 Forbidden` al crear el token | No eres Owner del grupo raíz | Pide el rol, o créalo quien lo tenga |
| `AUDITOR_TOKEN no ha llegado: ¿rama protegida?` | `main` no está protegida o la variable no es protegida en `main` | Paso 1 y paso 4 |
| `GraphQL 401: [{"message":"Invalid token"}]` | El token de la variable está revocado o caducado (¿lo rotaste?) | `PUT /projects/$PA/variables/AUDITOR_TOKEN` con el token nuevo |
| `fetch failed` … `ECONNREFUSED 127.0.0.1:8888` | El script usó `CI_API_GRAPHQL_URL`, que dice `localhost` | `src/gitlab.ts` construye la URL con `CI_SERVER_URL` |
| El pipeline se queda en `pending` | El clúster está parado o `k8s-app` no está asignado | `k3d cluster start bootcamp`; paso 1 |
| `The resulting pipeline would have been empty` | Lanzaste un pipeline en una rama que no es `main` | `ref=main` |
| `main no está protegida` en todos los proyectos | Cambiaste el auditor para leer `branchRules` por GraphQL | REST, como en `src/auditar.ts` (paso 5; el porqué, en el paso 3) |
| Un proyecto del grupo no aparece en la auditoría | Está marcado para borrar (`markedForDeletion`) | Es lo esperado |

---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| [Teoría 03 — Tokens para máquinas](../1-teoria/03-tokens-para-maquinas.md) | [Práctica 02 — El receptor](02-el-receptor.md) |

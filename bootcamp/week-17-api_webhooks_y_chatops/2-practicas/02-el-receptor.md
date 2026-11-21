# Práctica 02 — El receptor

> Escribes el receptor de webhooks de la plataforma: verifica la firma de cada aviso, descarta los repetidos, y anota en un canal lo que importa. Primero los tests de la firma, después el receptor, después su despliegue en `destino` con el mismo mecanismo que `app`. En la práctica 03 le das su clave y le conectas los webhooks.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 01 completada · `destino` en marcha (Semana 14) · Teoría [04](../1-teoria/04-webhooks-firmados.md) leída

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 0 | Variables | — |
| 1 | La verificación de la firma, con sus tests | `receptor-verifica-firma` |
| 2 | El receptor | — |
| 3 | Una clave SSH que solo despliega `receptor` | — |
| 4 | Las variables del despliegue | — |
| 5 | El receptor desplegado por su pipeline | `receptor-desplegado` |

---

## Paso 0: Preparar el terreno

```bash
source ~/.bc-gitlab; source ~/.bc-gitlab-s17
export H="PRIVATE-TOKEN: $GITLAB_TOKEN" API="$GITLAB_URL/api/v4"
cd /ruta/a/tus/clones/automatizacion && git pull --ff-only
mkdir -p test scripts
```

Y `esperar`, del paso 0 de la [práctica 01](01-el-bot-auditor.md#paso-0-preparar-el-terreno).

---

## Paso 1: La firma, con tests primero

**Por qué**: la verificación es la pieza de seguridad del receptor, y la que más fácil se rompe en silencio (teoría 04, antipatrones). Se escribe con sus tests: una firma buena pasa; un cuerpo cambiado, una firma vieja, una petición sin firma y un receptor sin clave, no.

`test/firma.test.ts`:

```ts
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createHmac, randomBytes } from 'node:crypto';
import { firmaValida } from '../src/firma.ts';

const bytes = randomBytes(32);
const clave = 'whsec_' + bytes.toString('base64');
const cuerpo = '{"object_kind":"push"}';
const ahora = 1_800_000_000;
const firmar = (c: string, ts = ahora) => ({
  'webhook-id': 'id-1',
  'webhook-timestamp': String(ts),
  'webhook-signature': 'v1,' + createHmac('sha256', bytes).update(`id-1.${ts}.${c}`).digest('base64'),
});

test('acepta una firma correcta', () => {
  assert.equal(firmaValida(clave, firmar(cuerpo), cuerpo, ahora), true);
});
test('rechaza un cuerpo cambiado', () => {
  assert.equal(firmaValida(clave, firmar(cuerpo), cuerpo.replace('push', 'tag_push'), ahora), false);
});
test('rechaza una firma de hace más de 5 minutos', () => {
  assert.equal(firmaValida(clave, firmar(cuerpo, ahora - 301), cuerpo, ahora), false);
});
test('rechaza una petición sin firma', () => {
  assert.equal(firmaValida(clave, { 'webhook-id': 'id-1', 'webhook-timestamp': String(ahora) }, cuerpo, ahora), false);
});
test('rechaza todo si el receptor no tiene clave', () => {
  assert.equal(firmaValida('', firmar(cuerpo), cuerpo, ahora), false);
});
```

`src/firma.ts`:

```ts
// Verifica la firma de un webhook de GitLab (formato Standard Webhooks, Semana 17).
// GitLab firma `${webhook-id}.${webhook-timestamp}.${cuerpo}` con HMAC-SHA256; la
// clave es lo que va detrás de `whsec_`, en base64.
import { createHmac, timingSafeEqual } from 'node:crypto';

const TOLERANCIA_S = 300; // una firma de hace más de 5 minutos es una repetición

type Cabeceras = Record<string, string | string[] | undefined>;

export function firmaValida(clave: string, cabeceras: Cabeceras, cuerpo: string, ahora = Date.now() / 1000): boolean {
  const id = cabeceras['webhook-id'];
  const ts = cabeceras['webhook-timestamp'];
  const firmas = cabeceras['webhook-signature'];
  if (!clave) return false; // sin clave configurada, HMAC con clave vacía: cualquiera firmaría
  if (typeof id !== 'string' || typeof ts !== 'string' || typeof firmas !== 'string') return false;
  if (!(Math.abs(ahora - Number(ts)) <= TOLERANCIA_S)) return false;
  const esperada = createHmac('sha256', Buffer.from(clave.replace(/^whsec_/, ''), 'base64'))
    .update(`${id}.${ts}.${cuerpo}`)
    .digest();
  // La cabecera puede traer varias firmas separadas por espacios (rotación de clave).
  return firmas.split(' ').some((f) => {
    const [version, b64 = ''] = f.split(',');
    const recibida = Buffer.from(b64, 'base64');
    return version === 'v1' && recibida.length === esperada.length && timingSafeEqual(recibida, esperada);
  });
}
```

Los tests corren con el Node de la imagen de CI, sin instalar nada:

```bash
docker run --rm -v "$PWD":/w:ro -w /w node:22.23.3-alpine3.24 \
  node --experimental-strip-types --test test/firma.test.ts 2>&1 | grep -E '^# (pass|fail)'
```

**Verifica**: `# pass 5` y `# fail 0`. Cambia `timingSafeEqual(recibida, esperada)` por `true` y vuelve a ejecutarlos: falla `rechaza un cuerpo cambiado`, porque la comparación era lo único que lo paraba. Deshaz el cambio.

> [!NOTE]
> `node --test test/` no encuentra archivos `.ts`: hay que nombrar el archivo.

---

## Paso 2: El receptor

**Por qué**: `destino` sirve cada entorno en `/<slug>/` y llama al `export default` de su `src/http.ts` (Semana 14). El receptor es eso: un módulo con cuatro rutas.

| Ruta | Qué hace |
|---|---|
| `POST /webhook` | Verifica la firma (401 si no vale), descarta duplicados por `Idempotency-Key` (200 sin anotar), anota una línea por evento terminado |
| `POST /canal/<token>` | Recibe las respuestas de ChatOps (práctica 04) |
| `GET /` | Las 50 últimas líneas del canal |
| `GET /salud` | El SHA desplegado, para que el job de despliegue sepa que ha terminado |

El canal es un archivo fuera de `versiones/`: sobrevive a cada despliegue.

`src/http.ts`:

```ts
// El receptor de webhooks y canal de ChatOps de la plataforma (Semana 17).
// Corre en el destino como entorno `receptor`: el servidor del destino llama a
// atender() con la petición y el despliegue (sha) en `ctx`.
import { appendFile, readFile } from 'node:fs/promises';
import { firmaValida } from './firma.ts';

// Fuera de versiones/: el canal sobrevive a cada despliegue del receptor.
const CANAL = '/srv/entornos/receptor/canal.jsonl';
// ponytail: deduplicación en memoria; un redespliegue la vacía. Persistirla si un reenvío tardío hace daño.
const vistos = new Set<string>();

const leer = (req): Promise<string> => new Promise((ok, mal) => {
  let cuerpo = '';
  req.setEncoding('utf8');
  req.on('data', (t: string) => { cuerpo += t; if (cuerpo.length > 1_000_000) req.destroy(); });
  req.on('end', () => ok(cuerpo));
  req.on('error', mal);
});

const responder = (res, codigo: number, cuerpo: unknown) => {
  res.writeHead(codigo, { 'content-type': 'application/json' });
  res.end(JSON.stringify(cuerpo) + '\n');
};

const anotar = (entrada: Record<string, unknown>) =>
  appendFile(CANAL, JSON.stringify({ hora: new Date().toISOString(), ...entrada }) + '\n');

// Una línea legible por evento. Pipelines y despliegues avisan en cada cambio de
// estado: solo interesan los que han terminado.
const FINALES = ['success', 'failed', 'canceled'];
function resumir(evento: string, e): string | null {
  const p = e.project?.path_with_namespace;
  switch (evento) {
    case 'Pipeline Hook': {
      const { id, status, ref } = e.object_attributes;
      return FINALES.includes(status) ? `${p}: pipeline #${id} de ${ref} ${status}` : null;
    }
    case 'Push Hook':
      return `${p}: ${e.total_commits_count} commits empujados a ${e.ref}`;
    case 'Deployment Hook':
      return FINALES.includes(e.status) ? `${p}: despliegue en ${e.environment} ${e.status}` : null;
    default:
      return `${p ?? '?'}: ${evento}`;
  }
}

export default async function atender(req, res, ctx) {
  if (req.method === 'GET' && ctx.ruta === '/salud') return responder(res, 200, { sha: ctx.sha });

  if (req.method === 'GET' && ctx.ruta === '/') {
    const lineas = (await readFile(CANAL, 'utf8').catch(() => '')).trim().split('\n').filter(Boolean);
    return responder(res, 200, lineas.slice(-50).map((l) => JSON.parse(l)));
  }

  if (req.method === 'POST' && ctx.ruta === '/webhook') {
    const cuerpo = await leer(req);
    if (!firmaValida(process.env.RECEPTOR_SIGNING_KEY ?? '', req.headers, cuerpo)) {
      return responder(res, 401, { error: 'firma no válida' });
    }
    // Un reenvío trae el mismo Idempotency-Key: se contesta 200 y no se procesa dos veces.
    const id = req.headers['idempotency-key'];
    if (vistos.has(id)) return responder(res, 200, { repetido: id });
    vistos.add(id);
    const resumen = resumir(String(req.headers['x-gitlab-event']), JSON.parse(cuerpo));
    if (resumen) await anotar({ tipo: 'webhook', id, resumen });
    return responder(res, 200, { ok: true });
  }

  // ChatOps contesta al response_url sin firma: el secreto va en la ruta.
  const canal = process.env.RECEPTOR_CANAL_TOKEN;
  if (req.method === 'POST' && canal && ctx.ruta === `/canal/${canal}`) {
    const m = JSON.parse(await leer(req));
    const salida = m.attachments?.[0]?.fields?.find((f) => f.title === 'Output')?.value;
    await anotar({ tipo: 'chat', resumen: m.attachments?.[0]?.text ?? m.text, salida });
    return responder(res, 200, { ok: true });
  }

  return responder(res, 404, { error: 'no existe' });
}
```

**Verifica**: que el módulo carga y exporta una función, en la misma imagen:

```bash
docker run --rm -v "$PWD":/w:ro -w /w node:22.23.3-alpine3.24 \
  node --experimental-strip-types -e 'import("/w/src/http.ts").then((m) => console.log(typeof m.default))'
```

`function`.

---

## Paso 3: Una clave que solo despliega `receptor`

**Por qué**: el despliegue usa el mecanismo de `app`: un paquete por SSH a `deploy@destino`, con un comando forzado que limita los entornos de cada clave (Semana 14, práctica 01). Esta clave es nueva y su patrón es `receptor`: no puede tocar `staging`, `production` ni las review apps.

```bash
ssh-keygen -q -t ed25519 -N '' -C receptor -f ~/.ssh/destino-receptor
cd /ruta/al/repositorio/bc-gitlab
echo "command=\"/usr/local/bin/desplegar receptor\",restrict $(cat ~/.ssh/destino-receptor.pub)" \
  | docker compose exec -T destino sh -c 'cat >> /home/deploy/.ssh/authorized_keys'
```

`>>`, no `>`: las claves de `staging`, `production` y review siguen ahí.

**Verifica**:

```bash
docker compose exec destino grep -c '^command=' /home/deploy/.ssh/authorized_keys
docker run --rm --network bc-gitlab-network \
  -v ~/.ssh/destino-receptor:/k:ro -v ~/.ssh/destino-known-hosts:/kh:ro alpine:3.24.2 sh -c '
  apk add -q --no-cache openssh-client >/dev/null
  cp /k /tmp/k && chmod 600 /tmp/k
  ssh -i /tmp/k -o UserKnownHostsFile=/kh -o BatchMode=yes deploy@destino parar staging; echo "staging: $?"'
```

Una línea más que antes (cuatro si tenías tres), y `esta clave no para 'staging'` con `staging: 3`.

---

## Paso 4: Las variables del despliegue

**Por qué**: la clave privada, como variable **de archivo** y protegida: una clave de varias líneas no se puede enmascarar (Semana 14). La huella del destino, también de archivo, para que `ssh` sepa que habla con `destino` y no con quien se haga pasar por él.

```bash
curl -s --request POST "$API/projects/$PA/variables" -H "$H" \
  --data key=RECEPTOR_SSH_KEY --data variable_type=file --data protected=true \
  --data-urlencode "value@$HOME/.ssh/destino-receptor" | jq -c '{key, variable_type, protected}'
curl -s --request POST "$API/projects/$PA/variables" -H "$H" \
  --data key=DESTINO_KNOWN_HOSTS --data variable_type=file \
  --data-urlencode "value@$HOME/.ssh/destino-known-hosts" | jq -c '{key, variable_type, protected}'
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$PA/variables" | jq -c '.[] | {key, variable_type, protected, hidden}'
```

Tres variables: `AUDITOR_TOKEN` (oculta), `RECEPTOR_SSH_KEY` (`file`, protegida) y `DESTINO_KNOWN_HOSTS` (`file`).

---

## Paso 5: El despliegue

**Por qué**: el receptor se despliega como cualquier cosa de la plataforma: por pipeline, con entorno, con `resource_group` para que dos despliegues no se pisen, y comprobando que lo que sirve `destino` es el SHA que se pidió. Solo cuando cambia su código. Y antes, sus tests.

`scripts/desplegar-receptor.sh`:

```sh
#!/bin/sh
# Lleva src/ al destino como entorno `receptor`, con el mismo mecanismo que app (Semana 14).
set -eu
: "${RECEPTOR_SSH_KEY:?RECEPTOR_SSH_KEY no ha llegado: ¿rama protegida?}"
: "${DESTINO_KNOWN_HOSTS:?Falta DESTINO_KNOWN_HOSTS}"

chmod 600 "$RECEPTOR_SSH_KEY"   # el runner escribe las variables de archivo con 0666
mkdir -p paquete && cp -r src paquete/ && tar -czf receptor.tgz paquete
ssh -i "$RECEPTOR_SSH_KEY" -o UserKnownHostsFile="$DESTINO_KNOWN_HOSTS" -o BatchMode=yes \
  deploy@destino desplegar receptor "$CI_COMMIT_SHA" receptor < receptor.tgz

# No ha terminado hasta que el destino sirve el SHA pedido.
curl -fsS --retry 3 --retry-delay 2 --retry-all-errors http://destino:8080/receptor/salud \
  | grep -q "\"sha\":\"$CI_COMMIT_SHA\""
```

Añade estos dos jobs al final de `.gitlab-ci.yml`:

```yaml
test:
  stage: test
  script:
    - node --experimental-strip-types --test test/firma.test.ts
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_PIPELINE_SOURCE == "push"

desplegar-receptor:
  stage: deploy
  image: alpine:3.24.2
  environment: receptor
  resource_group: receptor
  script:
    - apk add --no-cache openssh-client curl
    - sh scripts/desplegar-receptor.sh
  rules:
    - if: $CI_PIPELINE_SOURCE == "push" && $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      changes: [src/**/*, scripts/desplegar-receptor.sh]
```

```bash
git add -A && git commit -S -m "feat: signed webhook receiver deployed to destino"
git push
sleep 5
PIPE=$(curl -s -H "$H" "$API/projects/$PA/pipelines?per_page=1" | jq -r '.[0].id')
esperar "$PA" "$PIPE"
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$PA/pipelines/$PIPE/jobs" | jq -c '.[] | {name, status}'
curl -s "http://localhost:${DESTINO_PORT:-8095}/receptor/salud"
git rev-parse HEAD
```

`test` y `desplegar-receptor` en `success`, y el mismo SHA en `/receptor/salud` y en `HEAD`. En `Operate → Environments` de `ci/automatizacion`, el entorno `receptor`.

---

## ✅ Resultado

- [ ] Los cinco tests de la firma en verde, y fallando si la comparación se rompe
- [ ] El receptor desplegado por su pipeline, con el SHA de `main` en `/receptor/salud`
- [ ] La clave `destino-receptor` no puede tocar otros entornos

```bash
./scripts/verificar-semana.sh 17
```

En esta práctica pasan `receptor-verifica-firma` y `receptor-desplegado`.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `{"error":"no hay nada desplegado en receptor"}` | El job `desplegar-receptor` no corrió | Solo corre en un push a `main` que cambie `src/` o el script; *Run pipeline* no lo lanza |
| `RECEPTOR_SSH_KEY no ha llegado: ¿rama protegida?` | La variable es protegida y `main` no lo está | Práctica 01, paso 1 |
| `Permission denied (publickey)` | La pública no está en `authorized_keys` | Paso 3, con `>>` |
| `esta clave no despliega en 'receptor'` | Añadiste la pública con otro patrón | Corrige la línea en `authorized_keys` |
| `curl: (22) … 404` en el último paso del job | `destino` aún sirve la versión anterior | El `--retry` lo cubre; si persiste, `docker compose logs destino` |

---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| [Práctica 01 — El bot auditor](01-el-bot-auditor.md) | [Práctica 03 — Los webhooks](03-los-webhooks.md) |

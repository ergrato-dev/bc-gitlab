# Práctica 04 — El feature flag y Pages

> La multa progresiva llega a `main` y a los tres entornos, pero cada entorno decide en ejecución si la usa: `staging` y las review apps, sí; `production`, solo para dos socios. La apagas sin desplegar y la vuelves a encender. Después, la documentación de `app` se publica en Pages y compruebas que un visitante anónimo no la lee.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 03 completada · Teoría [06](../1-teoria/06-feature-flags.md) y [07](../1-teoria/07-gitlab-pages.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | El destino sabe preguntar a GitLab por los flags de `app` | — |
| 2 | `src/flags.ts`, `/multa` y la multa progresiva en `main`, y en los tres entornos | `app-lee-los-flags` |
| 3 | El flag `multa-progresiva`, distinto en cada entorno | `flag-por-entorno` |
| 4 | Apagado y encendido sin desplegar | — |
| 5 | La documentación en Pages | `pages-publicado` |
| 6 | Solo para miembros | `pages-solo-miembros` |

Si has cerrado la terminal: `source ~/.bc-gitlab`, `source ~/.bc-gitlab-s14`, las variables `H`, `API`, `P` y `HR`, y `esperar` y `fusionar`.

---

## Paso 1: El destino pregunta a GitLab

**Por qué**: el código que lee los flags corre en el destino, así que la URL y el identificador de instancia son configuración **del destino** (teoría 06, apartado 2.4). El identificador no se lee por API: se copia de la UI.

**Con la UI**: en `app`, `Deploy → Feature flags → Configure`. Copia el *Instance ID*. La *API URL* que enseña empieza por `http://localhost:8888`: desde el destino, eso es el propio destino. Se usa `gitlab:8888`.

En el `.env` del repositorio del bootcamp (fuera de Git: está en `.gitignore`), las dos líneas que trae vacías desde esta semana:

```bash
cd /ruta/a/bc-gitlab
sed -i "s|^UNLEASH_URL=.*|UNLEASH_URL=http://gitlab:8888/api/v4/feature_flags/unleash/$ID_APP|" .env
sed -i "s|^UNLEASH_INSTANCE_ID=.*|UNLEASH_INSTANCE_ID=<el Instance ID que copiaste>|" .env
chmod 600 .env
docker compose --profile base up -d destino
```

Si tu `.env` es anterior a esta semana y no tiene esas líneas, añádelas al final con los mismos nombres.

**Verifica**: el destino recibe las dos variables, y la API Unleash responde con ese identificador:

```bash
docker compose exec destino sh -c 'echo "$UNLEASH_URL ${#UNLEASH_INSTANCE_ID}"'
# http://gitlab:8888/api/v4/feature_flags/unleash/<id> <longitud>
source <(grep ^UNLEASH_INSTANCE_ID .env)
curl -s -H "UNLEASH-INSTANCEID: $UNLEASH_INSTANCE_ID" -H "UNLEASH-APPNAME: staging" \
  "$API/feature_flags/unleash/$ID_APP/client/features" | jq -c .
# {"version":1,"features":[]}
```

Lista vacía: no hay flags todavía. Con un identificador equivocado, la respuesta es `401 Unauthorized`.

---

## Paso 2: El código, apagado

**Por qué**: la multa progresiva entra en `main` en una merge request pequeña, con su test, y el `if` que la usa solo la elige si el flag lo dice. Sin flag, todo sigue como estaba.

```bash
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
IID_LIMPIEZA=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Borrar el flag multa-progresiva y calcularMulta vieja" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=Cuando multa-progresiva lleve un mes encendido para todos en production: borrar el flag, el if de /multa y lo que ya no se use. Ver Semana 14, teoría 06." \
  | jq -r .iid)
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Multa progresiva detrás de un feature flag" \
  --data-urlencode "labels=tipo::mejora" \
  --data-urlencode "description=Tarifa doble desde el octavo día. /multa la usa si multa-progresiva está activo para el entorno y el socio. Limpieza: #$IID_LIMPIEZA. Ver Semana 14." \
  | jq -r .iid)
git switch -c "$IID-multa-progresiva"

cat >> src/prestamos.ts <<'EOF'

/** Tarifa doble desde el octavo dia. La usa /multa si el flag multa-progresiva lo dice. */
export function calcularMultaProgresiva(diasRetraso: number): number {
  return calcularMulta(diasRetraso) + calcularMulta(Math.max(0, diasRetraso - 7));
}
EOF
sed -i 's/import { calcularMulta, /import { calcularMulta, calcularMultaProgresiva, /' src/prestamos.test.ts
cat >> src/prestamos.test.ts <<'EOF'

test("la multa progresiva cobra doble desde el octavo dia", () => {
  assert.equal(calcularMultaProgresiva(5), 5 * MULTA_POR_DIA_CENTIMOS);
  assert.equal(calcularMultaProgresiva(10), 13 * MULTA_POR_DIA_CENTIMOS);
});
EOF
```

El cliente de flags, como lo describe la teoría 06:

```bash
cat > src/flags.ts <<'EOF'
// Cliente mínimo de la API Unleash de GitLab (Semana 14). UNLEASH-APPNAME es el
// entorno: GitLab devuelve solo las estrategias cuyo ámbito encaja con él.
type Estrategia = { name: string; parameters: Record<string, string> };
type Flag = { name: string; enabled: boolean; strategies: Estrategia[] };
const cache = new Map<string, { hasta: number; flags: Flag[] }>();

async function flags(entorno: string): Promise<Flag[]> {
  const { UNLEASH_URL, UNLEASH_INSTANCE_ID } = process.env;
  if (!UNLEASH_URL || !UNLEASH_INSTANCE_ID) return [];
  const previo = cache.get(entorno);
  if (previo && previo.hasta > Date.now()) return previo.flags;
  try {
    const r = await fetch(`${UNLEASH_URL}/client/features`, {
      headers: { 'UNLEASH-INSTANCEID': UNLEASH_INSTANCE_ID, 'UNLEASH-APPNAME': entorno },
    });
    if (!r.ok) throw new Error(`HTTP ${r.status}`);
    const { features } = (await r.json()) as { features: Flag[] };
    cache.set(entorno, { hasta: Date.now() + 15_000, flags: features });
    return features;
  } catch {
    return previo?.flags ?? [];   // GitLab no responde: lo último conocido, o todo apagado
  }
}

export async function activo(nombre: string, entorno: string, usuario?: string): Promise<boolean> {
  const flag = (await flags(entorno)).find((f) => f.name === nombre);
  if (!flag?.enabled) return false;
  return flag.strategies.some((e) =>
    e.name === 'default' ||
    (e.name === 'userWithId' && usuario !== undefined && e.parameters.userIds.split(',').includes(usuario)));
}
EOF
```

Y en `src/http.ts`, dos imports arriba y la ruta `/multa` antes del `404`:

```typescript
import { calcularMulta, calcularMultaProgresiva } from './prestamos.ts';
import { activo } from './flags.ts';
```

```typescript
  if (d.ruta === '/multa') {
    const dias = Number(d.url.searchParams.get('dias') ?? 0);
    const socio = d.url.searchParams.get('socio') ?? undefined;
    const progresiva = await activo('multa-progresiva', d.entorno, socio);
    const multa = progresiva ? calcularMultaProgresiva(dias) : calcularMulta(dias);
    return responder(200, { dias, socio, progresiva, multa });
  }
```

```bash
npm test
git add src/
git commit -S -m "feat: multa progresiva detrás del flag multa-progresiva"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.remove_source_branch \
  -o merge_request.title="feat: multa progresiva detrás de un feature flag" -o merge_request.description="Closes #$IID"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
PIPE=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/pipelines" | jq -r '.[0].id')
esperar "$P" "$PIPE"
URL=$(curl -s -H "$H" "$API/projects/$P/environments?search=review/$MR" | jq -r '.[0].external_url' | sed 's|/salud$||')
curl -s "$URL/multa?dias=10" | jq -c .
```

**Verifica**: los tests pasan, y la review app de esta merge request responde `"progresiva":false` con la multa de siempre: el flag no existe, así que está apagado. El código nuevo está desplegado y no hace nada.

Fusiona, y lleva la versión a `production` como en la práctica 02:

```bash
fusionar "$P" "$MR"
git switch main && git pull --ff-only
PIPE=$(curl -s -H "$H" "$API/projects/$P/pipelines?ref=main&source=push&per_page=1" | jq -r '.[0].id')
esperar "$P" "$PIPE"
BR=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/bridges" | jq -r '.[] | select(.name == "infra-production") | .id')
curl -s --request POST "$API/projects/$P/jobs/$BR/play" -H "$H" > /dev/null; sleep 15
esperar "$PI" "$(curl -s -H "$H" "$API/projects/$PI/pipelines?source=pipeline&per_page=1" | jq -r '.[0].id')"
for e in staging production; do curl -s "localhost:8095/$e/multa?dias=10" | jq -c --arg e $e '{entorno: $e, progresiva, multa}'; done
```

`success`, y los dos entornos con `"progresiva":false`.

---

## Paso 3: El flag

**Por qué**: ahora se decide quién ve la multa nueva, sin tocar el código: todos en `staging` y en las review apps, y dos socios en `production`.

**Con la UI**: `Deploy → Feature flags → New feature flag`, nombre `multa-progresiva`, con dos estrategias: *All users* en `staging` y `review/*`, y *User IDs* `socio-7,socio-9` en `production`.

**Con la API**:

```bash
curl -s --request POST "$API/projects/$P/feature_flags" -H "$H" -H "Content-Type: application/json" -d @- <<EOF | jq -c '{name, active}'
{"name": "multa-progresiva", "version": "new_version_flag", "active": true,
 "description": "Tarifa doble desde el octavo día. Limpieza: #$IID_LIMPIEZA",
 "strategies": [
   {"name": "default", "parameters": {},
    "scopes": [{"environment_scope": "staging"}, {"environment_scope": "review/*"}]},
   {"name": "userWithId", "parameters": {"userIds": "socio-7,socio-9"},
    "scopes": [{"environment_scope": "production"}]}]}
EOF
sleep 16
curl -s "localhost:8095/staging/multa?dias=10" | jq -c '{progresiva, multa}'
curl -s "localhost:8095/production/multa?dias=10" | jq -c '{progresiva, multa}'
curl -s "localhost:8095/production/multa?dias=10&socio=socio-7" | jq -c '{progresiva, multa}'
```

**Verifica**: `staging` con `true` y la multa de 13 días; `production` con `false` para cualquiera y `true` para `socio-7`. Los 16 segundos son la caché de `flags.ts`. Ningún pipeline ha corrido.

---

## Paso 4: Apagar sin desplegar

**Por qué**: es lo que justifica un flag. Si la multa nueva cobra mal, se apaga en un clic y `production` vuelve al cálculo de siempre en lo que dura la caché.

```bash
curl -s --request PUT "$API/projects/$P/feature_flags/multa-progresiva" -H "$H" \
  --data-urlencode "active=false" | jq -c '{name, active}'
sleep 16
curl -s "localhost:8095/production/multa?dias=10&socio=socio-7" | jq -c '{progresiva, multa}'
curl -s -H "$H" "$API/projects/$PI/pipelines?per_page=1" | jq -r '.[0].created_at'
curl -s --request PUT "$API/projects/$P/feature_flags/multa-progresiva" -H "$H" \
  --data-urlencode "active=true" | jq -c '{name, active}'
```

**Verifica**: `socio-7` vuelve a `false`, y el último pipeline de `infra/entornos` es de antes del paso 3. Al encenderlo otra vez, las dos estrategias siguen ahí: `active` no las borra.

---

## Paso 5: La documentación en Pages

**Por qué**: `README.md` y `docs/` ya existen (Semanas 04 y 08). Un script los convierte en HTML con los enlaces entre ellos reescritos, y un job lo publica cuando cambian.

```bash
git switch main && git pull --ff-only
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=La documentación de app en Pages" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=README y docs/ en HTML con pandoc, publicados en Pages solo para miembros. Ver Semana 14." | jq -r .iid)
git switch -c "$IID-pages"

cat > scripts/sitio.sh <<'EOF'
#!/bin/sh
# Genera public/ para GitLab Pages: README.md y docs/*.md en HTML (Semana 14).
# Los enlaces entre archivos .md pasan a .html, y README pasa a ser index.
set -eu
mkdir -p public
cp logo.png public/
for f in README.md docs/*.md; do
  n=$(basename "$f" .md); [ "$n" = README ] && n=index
  sed -E 's#\((\.\./)?(docs/)?([A-Za-z0-9_-]+)\.md\)#(\3.html)#g; s#\(README\.html\)#(index.html)#g' "$f" \
    | pandoc -s --metadata title="$n" -o "public/$n.html"
done
EOF
chmod +x scripts/sitio.sh
```

Al final de `ci/deploy.yml`:

```yaml
# La documentación, en Pages (Semana 14). Solo para miembros: ver Settings → General.
pages:
  stage: deploy
  image:
    name: ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/pandoc/minimal:3.11.0-alpine
    entrypoint: [""]
  needs: []
  rules:
    - !reference [.fuera-de-programados, rules]
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      changes: [README.md, docs/**/*, logo.png, scripts/sitio.sh]
  script:
    - scripts/sitio.sh
  pages: true
  artifacts:
    paths: [public]
```

Y en `README.md`, una línea que diga dónde está la documentación publicada (la URL la sabrás en el paso 6; de momento, `Deploy → Pages`). Cambiar el README es además lo que hace que `pages` corra al fusionar.

```bash
git add scripts/sitio.sh ci/deploy.yml README.md
git commit -S -m "docs: publicar README y docs/ en GitLab Pages"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.remove_source_branch \
  -o merge_request.title="docs: la documentación de app en Pages" -o merge_request.description="Closes #$IID"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
fusionar "$P" "$MR"
git switch main && git pull --ff-only
PIPE=$(curl -s -H "$H" "$API/projects/$P/pipelines?ref=main&source=push&per_page=1" | jq -r '.[0].id')
esperar "$P" "$PIPE"
curl -s -H "$H" "$API/projects/$P/pages" | jq -c '{url, despliegues: (.deployments | length)}'
```

**Verifica**: `success`, y una URL `http://app-<sufijo>.pages.localhost:8090` con un despliegue.

---

## Paso 6: Solo para miembros

**Por qué**: `app` es privado; su documentación también tiene que serlo. Con el control de acceso de la instancia activo (el compose lo trae desde esta semana), el nivel del proyecto decide.

**Con la UI**: `Settings → General → Visibility, project features, permissions → Pages`: *Only Project Members*.

```bash
curl -s --request PUT "$API/projects/$P" -H "$H" --data-urlencode "pages_access_level=private" | jq -r .pages_access_level
SITIO=$(curl -s -H "$H" "$API/projects/$P/pages" | jq -r .url)
HOST=${SITIO#http://}; HOST=${HOST%%:*}
curl -s -o /dev/null -w '%{http_code} %{redirect_url}\n' --resolve "$HOST:8090:127.0.0.1" "$SITIO/"
```

**Verifica**: `private`, y el visitante anónimo recibe `302` hacia `projects.pages.localhost:8090/auth`. Abre `$SITIO` en el navegador con tu sesión de GitLab iniciada: GitLab te pide autorizar el acceso una vez, y ves el README con tu logo y los enlaces a `docs/` funcionando. Pon la URL en el README del paso 5 en tu próxima merge request.

---

## ✅ Checklist

- [ ] El destino con `UNLEASH_URL` en `gitlab:8888` y el identificador de instancia fuera del repositorio
- [ ] `calcularMultaProgresiva` con su test, `src/flags.ts` y `/multa` en los tres entornos, apagados
- [ ] `multa-progresiva` encendido en `staging` y en las review apps, y para dos socios en `production`
- [ ] Apagado y encendido sin ningún pipeline, y un issue de limpieza enlazado
- [ ] La documentación en Pages, con `302` para un visitante anónimo

---

## 🧯 Problemas frecuentes

| Síntoma | Causa | Solución |
|---|---|---|
| `"progresiva":false` en `staging` con el flag creado | La caché de 15 s, o el destino no tiene las variables | Espera; `docker compose exec destino env \| grep UNLEASH` |
| La API Unleash responde `401 Unauthorized` | El identificador de instancia no es el de `app` | Cópialo otra vez de `Deploy → Feature flags → Configure` |
| `flags.ts` nunca enciende nada y GitLab responde bien desde tu máquina | `UNLEASH_URL` con `localhost` | `gitlab:8888`: desde el destino, `localhost` es el destino |
| `production` enciende para todos | La estrategia `default` tiene `production` en su ámbito, o `*` | Un ámbito por estrategia, como en el paso 3 |
| `pages` no corre al fusionar | La merge request no cambió nada de su `changes` | Cambia el README, o lanza un pipeline de `main` |
| `pages` falla con `pandoc: … not found` o sin shell | Falta `entrypoint: [""]` | La imagen arranca `pandoc` si no se le quita |
| El visitante anónimo recibe `200` | El control de acceso no está activo en la instancia | `docker compose up -d gitlab` con el compose de esta semana |
| `curl` no resuelve `app-….pages.localhost` | `curl` anterior a las versiones que resuelven `*.localhost` | `--resolve`, como en el paso 6 |

---

[← Anterior: Review apps](03-review-apps.md) · [Volver a la Semana 14](../README.md) · [Ir al proyecto →](../3-proyecto/README.md)

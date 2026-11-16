# Práctica 01 — El destino y staging

> Levantas el destino, `app` aprende a responder por HTTP, generas una clave por entorno y la das de alta en los dos lados, e `infra/entornos` despliega de verdad en `staging`. Al terminar, `curl localhost:8095/staging/salud` responde con el SHA de `main` de `app`.

**Duración estimada**: 50 min
**Prerrequisitos**: Semana 13 completada · Teoría [01](../1-teoria/01-entornos-y-despliegues.md), [02](../1-teoria/02-el-destino.md) y [03](../1-teoria/03-secretos-en-infra.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 0 | Variables, el token de `revisor` y las funciones de siempre | — |
| 1 | El servicio `destino` en marcha | — |
| 2 | `src/http.ts` en `main` de `app` | — |
| 3 | Una clave por entorno, dada de alta en el destino y probada | — |
| 4 | Las claves y la huella en `infra/entornos` | `claves-por-entorno-en-infra`, `huella-del-destino` |
| 5 | `infra/entornos` con entorno, resource group y `scripts/desplegar.sh` | `resource-groups-en-infra` |
| 6 | El primer despliegue real en `staging` | `staging-desplegado` |

---

## Paso 0: Preparar el terreno

**Por qué**: las merge requests de `app` siguen necesitando la aprobación de `revisor`, y el token de la Semana 13 caducó. Las mismas funciones, con un token nuevo. Esta semana hacen falta además los ID numéricos de `app` y de `infra/entornos`.

```bash
source ~/.bc-gitlab
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
export HA="PRIVATE-TOKEN: ${GITLAB_ADMIN_TOKEN:-$GITLAB_TOKEN}"
export GRUPO=${PROYECTO%%/*}
export PI=$(printf '%s' "$GRUPO/infra/entornos" | jq -sRr @uri)
export ID_APP=$(curl -s -H "$H" "$API/projects/$P" | jq -r .id)
export ID_INFRA=$(curl -s -H "$H" "$API/projects/$PI" | jq -r .id)
export REV=revisor-<tu-dominio>
export UID_REV=$(curl -s -H "$H" "$API/users?username=$REV" | jq -r '.[0].id // empty')
[[ "$UID_REV" =~ ^[0-9]+$ ]] || { echo "Falta $REV: NO sigas"; return 1 2>/dev/null || exit 1; }

T_REV=$(curl -s --request POST "$API/users/$UID_REV/personal_access_tokens" -H "$HA" \
  --data-urlencode "name=flujo-s14" --data-urlencode "scopes[]=api" \
  --data-urlencode "expires_at=$(date -d '+7 days' +%F)" | jq -r '.token')
[ -n "$T_REV" ] && [ "$T_REV" != null ] || { echo "No se creó el token: revisa GITLAB_ADMIN_TOKEN y NO sigas"; return 1 2>/dev/null || exit 1; }
export HR="PRIVATE-TOKEN: $T_REV"
curl -s -H "$H" "$API/projects/$PI/protected_branches/main" \
  | jq -c '{push: [.push_access_levels[].access_level], merge: [.merge_access_levels[].access_level]}'
# {"push":[40],"merge":[40]}: main de infra/entornos, solo para Maintainer
grep -qs GRUPO ~/.bc-gitlab-s14 || echo "export GRUPO=$GRUPO PI=$PI ID_APP=$ID_APP ID_INFRA=$ID_INFRA REV=$REV UID_REV=$UID_REV" >> ~/.bc-gitlab-s14
chmod 600 ~/.bc-gitlab-s14
```

Y las dos funciones de la Semana 13, `esperar` y `fusionar`, tal cual: cópialas del [paso 0 de su práctica 01](../../week-13-registry_de_contenedores_y_paquetes/2-practicas/01-el-registry-y-el-dockerfile.md#paso-0-preparar-el-terreno).

**Verifica**:

```bash
curl -s -H "$HR" "$API/user" | jq -r .username        # revisor-<tu-dominio>
echo "$ID_APP $ID_INFRA"                               # dos números
type esperar fusionar | grep -c 'is a'                 # 2
```

---

## Paso 1: El destino

**Por qué**: el `docker-compose.yml` del bootcamp trae desde esta semana el servicio `destino` (teoría 02) y una línea más en Pages. `--build` construye la imagen de `destino/`; GitLab se reconfigura porque su configuración ha cambiado.

```bash
cd /ruta/a/bc-gitlab && git pull --ff-only
docker compose --profile base up -d --build
docker compose ps --format '{{.Service}} {{.Status}}'
```

Espera a que `gitlab` diga `healthy` (unos tres minutos).

**Verifica**:

```bash
curl -s localhost:8095/                                         # {}
docker compose exec destino ls -la /home/deploy/.ssh/authorized_keys
# -rw------- 1 deploy deploy 0 … authorized_keys
docker stats --no-stream --format '{{.Name}} {{.MemUsage}}' | grep destino   # unos 20 MiB
```

`{}`: ningún entorno desplegado. `authorized_keys` vacío: nadie entra todavía.

---

## Paso 2: `app` responde por HTTP

**Por qué**: el destino importa `src/http.ts` de la versión desplegada (teoría 02, apartado 2.6). Si no existe, cada petición da `500`. Esta práctica solo necesita `/salud`; la práctica 04 añade la ruta con el feature flag.

```bash
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=app responde por HTTP en el destino" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=src/http.ts con /salud: entorno, SHA y fecha del despliegue. Lo importa el servidor del destino. Ver Semana 14." \
  | jq -r .iid)
git switch -c "$IID-http"

cat > src/http.ts <<'EOF'
// Lo que app responde en el destino (Semana 14). El servidor del destino importa
// este módulo de la versión desplegada y le pasa el despliegue y la ruta.
import type { IncomingMessage, ServerResponse } from 'node:http';

export type Despliegue = { entorno: string; sha: string; desplegado: string; ruta: string; url: URL };

export default async function atender(_req: IncomingMessage, res: ServerResponse, d: Despliegue) {
  const responder = (codigo: number, cuerpo: object) => {
    res.writeHead(codigo, { 'content-type': 'application/json' });
    res.end(JSON.stringify(cuerpo) + '\n');
  };
  if (d.ruta === '/salud') {
    return responder(200, { estado: 'ok', entorno: d.entorno, sha: d.sha, desplegado: d.desplegado });
  }
  return responder(404, { error: `no existe ${d.ruta}` });
}
EOF
node --experimental-strip-types -e "import('./src/http.ts').then(m => console.log(typeof m.default))"
git add src/http.ts
git commit -S -m "feat: responder por HTTP en el destino con /salud"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="feat: responder por HTTP en el destino" \
  -o merge_request.description="Closes #$IID"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
fusionar "$P" "$MR"
git switch main && git pull --ff-only
```

**Verifica**: `function` y `state: merged`. El pipeline de `main` dispara `infra/entornos` como siempre, que todavía solo registra.

---

## Paso 3: Una clave por entorno

**Por qué**: dos claves nuevas, no las de la Semana 10 (teoría 03, apartado 2.3). Cada una entra en `authorized_keys` con su comando forzado: la de `staging` solo despliega en `staging`.

```bash
ssh-keygen -q -t ed25519 -N '' -C "destino-staging" -f ~/.ssh/destino-staging
ssh-keygen -q -t ed25519 -N '' -C "destino-production" -f ~/.ssh/destino-production

cd /ruta/a/bc-gitlab
{ for e in staging production; do
    echo "command=\"/usr/local/bin/desplegar $e\",restrict $(cat ~/.ssh/destino-$e.pub)"
  done
} | docker compose exec -T destino sh -c 'cat > /home/deploy/.ssh/authorized_keys'
# Sobrescribe a propósito: authorized_keys queda con estas dos claves y nada más.
# Si repites este paso después de la práctica 03, repite también su paso 1 (la clave de review).

docker compose exec destino cat /etc/ssh/claves/ssh_host_ed25519_key.pub \
  | awk '{print "destino", $1, $2}' > ~/.ssh/destino-known-hosts
cat ~/.ssh/destino-known-hosts
```

Ahora, la prueba de que cada clave hace solo lo suyo. Desde un contenedor en la red del compose, como lo hará el job:

```bash
docker run --rm --network bc-gitlab-network \
  -v ~/.ssh/destino-staging:/k:ro -v ~/.ssh/destino-known-hosts:/kh:ro alpine:3.24.2 sh -c '
  apk add -q --no-cache openssh-client > /dev/null
  cp /k /tmp/k && chmod 600 /tmp/k
  ssh -i /tmp/k -o UserKnownHostsFile=/kh -o BatchMode=yes deploy@destino estado; echo "estado: $?"
  ssh -i /tmp/k -o UserKnownHostsFile=/kh -o BatchMode=yes deploy@destino parar production; echo "parar production: $?"
  ssh -i /tmp/k -o UserKnownHostsFile=/kh -o BatchMode=yes deploy@destino "sh -c id"; echo "shell: $?"'
```

**Verifica**:

```text
estado: 0
esta clave no para 'production'
parar production: 3
uso: desplegar <slug> <sha> <entorno> | parar <slug> | estado
shell: 2
```

La clave de `staging` no toca `production` ni abre una shell. Si ves `Host key verification failed`, el archivo de la huella no tiene la línea `destino ssh-ed25519 …`.

---

## Paso 4: Las claves en `infra/entornos`

**Por qué**: cada clave privada va a `infra/entornos` como variable de tipo archivo, protegida, con su entorno. La huella va como archivo porque `ssh` la quiere en un archivo; no es secreta.

```bash
var() {   # $1 clave, $2 archivo, $3 protegida, $4 ámbito
  curl -s --request POST "$API/projects/$PI/variables" -H "$H" \
    --data-urlencode "key=$1" --data-urlencode "value@$2" \
    --data-urlencode "variable_type=file" --data-urlencode "protected=$3" \
    --data-urlencode "environment_scope=$4" | jq -c '{key, environment_scope, protected, variable_type}'
}
var DEPLOY_SSH_KEY ~/.ssh/destino-staging true staging
var DEPLOY_SSH_KEY ~/.ssh/destino-production true production
var DESTINO_KNOWN_HOSTS ~/.ssh/destino-known-hosts false '*'
```

**Verifica**: tres líneas, las dos primeras con `"protected":true` y su entorno. Una variable de varias líneas no se puede enmascarar: por eso es protegida y de archivo, no `masked`.

> [!WARNING]
> Las privadas siguen en `~/.ssh`. Si tu máquina es compartida, bórralas al terminar la semana: GitLab y el destino ya tienen lo que necesitan.

---

## Paso 5: `infra/entornos` despliega

**Por qué**: el job deja de solo registrar. Ahora tiene entorno (el del input), resource group por entorno (teoría 05) y un segundo script que lleva el paquete al destino y comprueba que responde con el SHA que se pidió.

```bash
cd /ruta/a/tus/clones/entornos && git switch main && git pull --ff-only

cat > scripts/desplegar.sh <<'EOF'
#!/bin/sh
# Lleva al destino el paquete que descargó registrar.sh, por SSH (Semana 14).
# Lo que esta clave puede hacer lo decide el destino, no este script.
set -eu
: "${DEPLOY_SSH_KEY:?DEPLOY_SSH_KEY no ha llegado: ¿rama protegida y entorno dentro de su ámbito?}"
: "${DESTINO_KNOWN_HOSTS:?Falta DESTINO_KNOWN_HOSTS}"

chmod 600 "$DEPLOY_SSH_KEY"   # el runner escribe las variables de archivo con 0666 y ssh las rechaza
ssh -i "$DEPLOY_SSH_KEY" -o UserKnownHostsFile="$DESTINO_KNOWN_HOSTS" -o BatchMode=yes \
  deploy@destino desplegar "$CI_ENVIRONMENT_SLUG" "$APP_SHA" "$CI_ENVIRONMENT_NAME" < app.tgz

# El despliegue no ha terminado hasta que el destino sirve el SHA pedido.
curl -fsS --retry 3 --retry-delay 2 --retry-all-errors "http://destino:8080/$CI_ENVIRONMENT_SLUG/salud" \
  | tee -a registro.txt | grep -q "\"sha\":\"$APP_SHA\""
EOF
chmod +x scripts/desplegar.sh
```

En `.gitlab-ci.yml`, todo lo que va debajo del `---` queda así (el bloque `spec` de arriba no cambia):

```yaml
# Este proyecto no se construye a sí mismo: lo dispara main de app.
workflow:
  name: "app $APP_SHA → $[[ inputs.entorno ]]"
  rules:
    - if: $CI_PIPELINE_SOURCE == "pipeline"

desplegar:
  image: alpine:3.24.2
  interruptible: false
  resource_group: $[[ inputs.entorno ]]
  environment:
    name: $[[ inputs.entorno ]]
    url: http://localhost:8095/$[[ inputs.entorno ]]/salud
  variables:
    ENTORNO: $[[ inputs.entorno ]]
  before_script:
    - apk add --no-cache curl openssh-client
  script:
    - scripts/registrar.sh
    - scripts/desplegar.sh
  artifacts:
    paths: [registro.txt]
    expire_in: 90 days
```

| Línea | Por qué |
|---|---|
| `registrar` pasa a llamarse `desplegar` | Es lo que hace ahora |
| `environment: name: $[[ inputs.entorno ]]` | El input elige el entorno, y con él qué `DEPLOY_SSH_KEY` recibe el job |
| `resource_group` | Dos despliegues en el mismo entorno no se pisan; en entornos distintos, sí pueden ir a la vez |
| `interruptible: false` | Un despliegue cancelado a medias deja el destino como esté |
| La URL con `localhost` | Es para ti, en el navegador. El job comprueba por `destino:8080` |

```bash
jq -n --rawfile c .gitlab-ci.yml '{content: $c}' \
  | curl -s --request POST "$API/projects/$PI/ci/lint" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -c '{valid, errors}'
git add .gitlab-ci.yml scripts/desplegar.sh
git commit -S -m "ci: desplegar en el destino por SSH, con entorno y resource group"
git push origin main
```

**Verifica**: `{"valid":true,"errors":[]}`. Como siempre, el push a `main` de `infra/entornos` no crea pipeline.

---

## Paso 6: El primer despliegue

**Por qué**: nada ha disparado todavía `infra/entornos` con el YAML nuevo. Un pipeline nuevo de `main` de `app`, sin cambiar nada, lo hace: vuelve a publicar el paquete del mismo SHA (la excepción de duplicados de la Semana 13) y dispara `staging`.

```bash
PIPE=$(curl -s --request POST "$API/projects/$P/pipeline" -H "$H" --data-urlencode "ref=main" | jq -r .id)
esperar "$P" "$PIPE"
PIPE_I=$(curl -s -H "$H" "$API/projects/$PI/pipelines?source=pipeline&per_page=1" | jq -r '.[0].id')
esperar "$PI" "$PIPE_I"
curl -s localhost:8095/staging/salud | jq -c .
git -C /ruta/a/tu/clon/de/app rev-parse HEAD
```

**Verifica**: `success` dos veces, y `/salud` con `"entorno":"staging"` y el SHA de `HEAD` de `app`. Ahora, lo que GitLab sabe:

```bash
curl -s -H "$H" "$API/projects/$PI/environments" | jq -c '.[] | {name, tier, external_url}'
curl -s -H "$H" "$API/projects/$PI/deployments?environment=staging" | jq -c '.[] | {status, sha: .sha[0:8]}'
git -C /ruta/a/tus/clones/entornos rev-parse --short=8 HEAD
```

`staging`, tier `staging`, y un despliegue `success` cuyo SHA es **el de `infra/entornos`**, no el de `app` (teoría 01, apartado 2.5).

Los resource groups existen desde que el job los usó. `staging` pasa a `oldest_first` (teoría 05, apartado 2.4); `production` nacerá en la práctica 02:

```bash
curl -s --request PUT "$API/projects/$PI/resource_groups/staging" -H "$H" \
  --data-urlencode "process_mode=oldest_first" | jq -c '{key, process_mode}'
```

---

## ✅ Checklist

- [ ] El destino en marcha, con `authorized_keys` vacío al empezar
- [ ] `src/http.ts` con `/salud` en `main` de `app`
- [ ] Dos claves nuevas; la de `staging` no para `production` ni abre una shell
- [ ] `DEPLOY_SSH_KEY` por entorno y `DESTINO_KNOWN_HOSTS` en `infra/entornos`
- [ ] `staging` responde con el SHA de `main` de `app`, y su resource group en `oldest_first`

---

## 🧯 Problemas frecuentes

| Síntoma | Causa | Solución |
|---|---|---|
| `curl localhost:8095` no responde | El servicio no se construyó | `docker compose --profile base up -d --build destino` y `docker compose logs destino` |
| `Host key verification failed` | La huella no tiene `destino` delante, o la clave de host cambió | Paso 3 otra vez: el `awk` escribe `destino ssh-ed25519 …` |
| `UNPROTECTED PRIVATE KEY FILE!` | Falta el `chmod 600` | Está en `desplegar.sh`; si lo pruebas a mano, cópialo a `/tmp` antes |
| `Permission denied (publickey)` | La pública no está en `authorized_keys`, o la variable no llegó | `docker compose exec destino cat /home/deploy/.ssh/authorized_keys`; el job dice `DEPLOY_SSH_KEY no ha llegado` si es lo segundo |
| `DEPLOY_SSH_KEY no ha llegado` | El entorno del job no encaja con el ámbito, o la variable está protegida y la rama no | El input `entorno` y el `environment_scope` tienen que coincidir |
| `/salud` responde `500` | La versión desplegada no tiene `src/http.ts` | El paso 2 tiene que estar fusionado antes del 6 |
| `esta clave no despliega en 'staging'` | Instalaste la pública de `production` con el patrón de `staging`, o al revés | Rehaz el `authorized_keys` del paso 3 |

---

[Volver a la Semana 14](../README.md) · [Siguiente: Producción y rollback →](02-produccion-y-rollback.md)

# Práctica 04 — Archivos secretos y fugas

> `production` necesita una clave SSH. Haces lo que proponen muchos tutoriales, subirla como *secure file*, y después te pones en el lugar de `dev`: una merge request de cuatro líneas se lleva la clave entera, y también `GOBERNANZA_TOKEN`, pero no `DEPLOY_TOKEN`. Das la clave por perdida, generas otra, la guardas como variable de archivo protegida y despliegas en `production`.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 03 completada, con `deploy-production` fallido · Teoría [06](../1-teoria/06-variables-de-archivo-y-secure-files.md) y [07](../1-teoria/07-secretos-fuera-del-yaml-y-del-log.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | La clave, como *secure file* | — |
| 2 | La fuga, desde la merge request de `dev` | — |
| 3 | La clave, dada por perdida; otra, como variable de archivo | `clave-ssh-como-archivo`, `ningun-secure-file-con-claves` |
| 4 | `production` desplegado | `desplegado-en-production` |
| 5 | La fuga, repetida y cerrada | `secretos-protegidos` |

Las claves de esta práctica no abren ninguna máquina: la Semana 14 pondrá la pública en un destino real. Trátalas como si abrieran `production`.

---

## Paso 0: Preparar el terreno

```bash
source ~/.bc-gitlab && source ~/.bc-gitlab-s10
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
export PID=$(curl -s -H "$H" "$API/projects/$P" | jq -r .id)
[ -n "${HD:-}" ] || echo "Falta \$HD: repite el bloque del token de dev del paso 4 de la práctica 02"
CLAVES=$(mktemp -d) && chmod 700 "$CLAVES"
```

`$CLAVES` es un directorio temporal solo tuyo, fuera del repositorio. Lo borras al final.

---

## Paso 1: La clave, como *secure file*

**Por qué**: es lo que muchas guías proponen para "archivos secretos": no pasa por Git, se guarda cifrado, y el job lo descarga con su token. Vas a comprobar quién más puede descargarlo.

```bash
ssh-keygen -q -t ed25519 -N '' -C "deploy-app-prueba" -f "$CLAVES/deploy_app_prueba"
ssh-keygen -lf "$CLAVES/deploy_app_prueba.pub" | cut -d' ' -f2                 # la huella, para comparar después
SF=$(curl -s --request POST "$API/projects/$P/secure_files" -H "$H" \
  --form "name=deploy_app_ed25519" --form "file=@$CLAVES/deploy_app_prueba" | jq -r .id)
echo "export SF=$SF" >> ~/.bc-gitlab-s10
curl -s -H "$H" "$API/projects/$P/secure_files" | jq -r '.[] | "\(.id) \(.name) \(.checksum[0:12])"'
```

**Verifica**: un *secure file* `deploy_app_ed25519`. Ahora, `dev`, con su token personal y sin ningún pipeline:

```bash
curl -s -o "$CLAVES/descargada_por_dev" -w 'dev descarga: %{http_code}\n' -H "$HD" \
  "$API/projects/$P/secure_files/$SF/download"
ssh-keygen -lf "$CLAVES/descargada_por_dev" | cut -d' ' -f2
```

**Verifica**: `200`, y la misma huella. Un Developer descarga la clave privada directamente. No le hace falta ni una merge request.

---

## Paso 2: La fuga, desde una merge request

**Por qué**: el paso 1 ya basta para descartar el *secure file*. Pero lo que quieres saber es qué más recibe un pipeline que escribe otra persona. `dev` abre una merge request cuyo `.gitlab-ci.yml` solo tiene un job, y ese job mira todo lo que puede.

`dev` lo hace por la API, como lo haría cualquiera con su token. El server hook de la Semana 07 exige firma a lo que empuja una persona, no a lo que se escribe por la web o la API, y el asunto es convencional: pasa.

```bash
cat > "$CLAVES/fuga.yml" <<'EOF'
fuga:
  image: alpine:3.24.2
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  environment:
    name: production
    action: prepare
  script:
    - apk add --no-cache curl openssh-keygen > /dev/null
    - echo "DEPLOY_TOKEN=${#DEPLOY_TOKEN} DEPLOY_SSH_KEY=${DEPLOY_SSH_KEY:-vacía} GOBERNANZA_TOKEN=${#GOBERNANZA_TOKEN}"
    - |
      for id in $(curl -s -H "JOB-TOKEN: $CI_JOB_TOKEN" "$CI_API_V4_URL/projects/$CI_PROJECT_ID/secure_files" | grep -o '"id":[0-9]*' | cut -d: -f2); do
        curl -s -H "JOB-TOKEN: $CI_JOB_TOKEN" -o f "$CI_API_V4_URL/projects/$CI_PROJECT_ID/secure_files/$id/download"
        echo "secure file $id: $(ssh-keygen -lf f 2>/dev/null | cut -d' ' -f2)"
      done
EOF
jq -n --rawfile c "$CLAVES/fuga.yml" '{branch: "fuga-s10", start_branch: "main",
    commit_message: "test: comprobar qué recibe una merge request, no fusionar",
    actions: [{action: "update", file_path: ".gitlab-ci.yml", content: $c}]}' \
  | curl -s --request POST "$API/projects/$P/repository/commits" -H "$HD" -H "Content-Type: application/json" -d @- \
  | jq -r '.short_id // .message'
MR_FUGA=$(curl -s --request POST "$API/projects/$P/merge_requests" -H "$HD" \
  --data "source_branch=fuga-s10" --data "target_branch=main" \
  --data-urlencode "title=Draft: test: qué recibe una merge request" | jq -r .iid)
echo "export MR_FUGA=$MR_FUGA" >> ~/.bc-gitlab-s10
```

El job usa `environment: production` a propósito, con `action: prepare` para no registrar un despliegue: es el intento de la teoría 05 de recibir los secretos de `production` declarando el entorno.

```bash
sleep 10
PIPE=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR_FUGA/pipelines" | jq -r '.[0].id')
until curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE" | jq -e '.status | IN("success","failed","canceled")' > /dev/null; do sleep 5; done
JOB=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[0].id')
curl -s -H "$H" "$API/projects/$P/jobs/$JOB/trace" | sed 's/\x1b\[[0-9;]*m//g' | grep -v '\$ ' | grep -oE '(DEPLOY_TOKEN|secure file).*'
```

**Verifica**:

```
DEPLOY_TOKEN=0 DEPLOY_SSH_KEY=vacía GOBERNANZA_TOKEN=<más de 0>
secure file <id>: SHA256:<la misma huella del paso 1>
```

Lee las tres columnas:

| Secreto | Llegó | Por qué |
|---|:--:|---|
| `DEPLOY_TOKEN` | ❌ | Protegida. Declarar `environment: production` no basta |
| `GOBERNANZA_TOKEN` | ✅ | No protegida, a propósito: es el riesgo escrito en el ADR-007 desde la Semana 09 |
| El *secure file* | ✅ | No hay protección posible: cualquier pipeline del proyecto lo descarga |

---

## Paso 3: Dar la clave por perdida, y guardar otra bien

**Por qué**: borrar el *secure file* no deshace la descarga de `dev` ni la del job. Esa clave queda descartada para siempre: se genera otra, que nunca pasa por un sitio que un Developer pueda leer.

```bash
[[ "${SF:-}" =~ ^[0-9]+$ ]] || SF=$(curl -s -H "$H" "$API/projects/$P/secure_files" | jq -r '.[] | select(.name == "deploy_app_ed25519") | .id')
[[ "$SF" =~ ^[0-9]+$ ]] || { echo "No encuentro el secure file: NO sigas"; return 1 2>/dev/null || exit 1; }
curl -s -o /dev/null -w 'secure file borrado: %{http_code}\n' --request DELETE "$API/projects/$P/secure_files/$SF" -H "$H"
rm -f "$CLAVES/deploy_app_prueba" "$CLAVES/deploy_app_prueba.pub" "$CLAVES/descargada_por_dev"

ssh-keygen -q -t ed25519 -N '' -C "deploy-app-production" -f "$CLAVES/deploy_app"
curl -s --request POST "$API/projects/$P/variables" -H "$H" \
  --data "key=DEPLOY_SSH_KEY" --data "variable_type=file" \
  --data "protected=true" --data "environment_scope=production" \
  --data-urlencode "value@$CLAVES/deploy_app" \
  | jq -c '{key, variable_type, protected, masked, environment_scope}'
rm -f "$CLAVES/deploy_app"
mkdir -p ~/.ssh && mv "$CLAVES/deploy_app.pub" ~/.ssh/deploy_app_<tu-dominio>.pub
ssh-keygen -lf ~/.ssh/deploy_app_<tu-dominio>.pub | cut -d' ' -f2
```

**Verifica**:

```
secure file borrado: 204
{"key":"DEPLOY_SSH_KEY","variable_type":"file","protected":true,"masked":false,"environment_scope":"production"}
SHA256:<la huella nueva>
```

`masked: false`: una clave tiene varias líneas y no se puede enmascarar (teoría 04). Por eso `deploy.sh` imprime su huella y nunca `cat`.

La clave privada ya **no está en tu disco**. Dentro de GitLab la pueden leer los Maintainers del proyecto (una variable de archivo de varias líneas no se puede ocultar) y cualquier job de `main` con `environment: production`. Eso es lo que va al inventario del proyecto. La pública te la quedas, para ponerla en el destino real en la Semana 14. Si la privada se pierde, se genera otra.

---

## Paso 4: `production`, desplegado

**Por qué**: el job que falló en la práctica 03 se reintenta tal cual. Nada cambia en el YAML: solo que ahora el secreto existe.

```bash
NUEVO=$(curl -s --request POST "$API/projects/$P/jobs/$JOB_PROD/retry" -H "$H" | jq -r .id)
until curl -s -H "$H" "$API/projects/$P/jobs/$NUEVO" | jq -e '.status | IN("success","failed")' > /dev/null; do sleep 5; done
curl -s -H "$H" "$API/projects/$P/jobs/$NUEVO/trace" | sed 's/\x1b\[[0-9;]*m//g' | grep -v '\$ ' | grep -oE '(Entorno|Token|Clave|Despliegue).*'
curl -s -H "$H" "$API/projects/$P/deployments?environment=production&status=success" | jq -r '.[] | "\(.id) \(.ref) \(.sha[0:8])"'
```

**Verifica**:

```
Entorno: production (https://<tu-dominio>.example)
Token:   64 caracteres
Clave:   256 SHA256:<la huella nueva, la misma del paso 3>
Despliegue simulado: correcto
<id> main <sha>
```

---

## Paso 5: La fuga, repetida y cerrada

**Por qué**: con la clave nueva en su sitio, repite la fuga. Es la prueba de que el arreglo funciona, no solo de que suena bien.

El pipeline lo relanza `dev`, con su token. El `CI_JOB_TOKEN` de un job tiene los permisos de quien lanzó el pipeline: si lo relanzaras tú, el YAML de `dev`, que nadie ha revisado y que está hecho para llevarse secretos, se ejecutaría con permisos de Maintainer. Nunca relances el pipeline de una merge request ajena sin leer antes su `.gitlab-ci.yml`.

```bash
PIPE=$(curl -s --request POST "$API/projects/$P/merge_requests/$MR_FUGA/pipelines" -H "$HD" | jq -r .id)   # lo lanza dev, no tú
until curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE" | jq -e '.status | IN("success","failed","canceled")' > /dev/null; do sleep 5; done
JOB=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[0].id')
curl -s -H "$H" "$API/projects/$P/jobs/$JOB/trace" | sed 's/\x1b\[[0-9;]*m//g' | grep -v '\$ ' | grep -oE '(DEPLOY_TOKEN|secure file).*'
```

**Verifica**: `DEPLOY_TOKEN=0 DEPLOY_SSH_KEY=vacía GOBERNANZA_TOKEN=<más de 0>`, y ninguna línea `secure file`. La clave nueva no llega a la merge request; `GOBERNANZA_TOKEN` sigue llegando, y así seguirá: el proyecto lo rota.

Cierra la merge request sin fusionar, borra la rama y recoge:

```bash
curl -s --request PUT "$API/projects/$P/merge_requests/$MR_FUGA" -H "$H" --data "state_event=close" | jq -r .state   # closed
curl -s -o /dev/null -w 'rama borrada: %{http_code}\n' --request DELETE "$API/projects/$P/repository/branches/fuga-s10" -H "$H"
rm -rf "$CLAVES"
curl -s -H "$H" "$API/projects/$P/variables" | jq -r '.[] | "\(.key) \(.environment_scope) protected=\(.protected) \(.variable_type)"'
curl -s -H "$H" "$API/projects/$P/secure_files" | jq length                                                       # 0
```

**Verifica**:

```
GOBERNANZA_TOKEN * protected=false env_var
DEPLOY_TOKEN staging protected=true env_var
DEPLOY_TOKEN production protected=true env_var
DEPLOY_SSH_KEY production protected=true file
0
```

---

## ✅ Resultado

- [ ] Visto que un Developer descarga un *secure file* por API y desde cualquier merge request
- [ ] Visto que una merge request recibe `GOBERNANZA_TOKEN` pero no `DEPLOY_TOKEN`, aunque declare `environment: production`
- [ ] El *secure file* borrado y su clave descartada, no reutilizada
- [ ] `DEPLOY_SSH_KEY` como variable de archivo protegida con ámbito `production`; la privada, fuera de tu disco
- [ ] `deploy-production` correcto, con la huella de la clave nueva
- [ ] La fuga repetida sin la clave, la merge request cerrada sin fusionar y la rama borrada

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| El commit de `dev` falla con `403` | `dev` no es Developer en `app` | Revisa sus permisos (Semana 03) |
| El commit de `dev` falla con el mensaje del hook | El asunto no es convencional | `test: ...` tal cual |
| La merge request de `dev` no tiene pipeline | El YAML de la rama tiene un error | `POST .../ci/lint` con `$CLAVES/fuga.yml` |
| `fuga` no imprime ninguna línea `secure file` en el paso 2 | El `curl` de la lista falló | Comprueba que `CI_API_V4_URL` apunta a `gitlab:8888` (Semana 09) |
| `400` al crear `DEPLOY_SSH_KEY` con `masked` | Una clave no se puede enmascarar | Sin `masked`: es de tipo archivo |
| El reintento falla con `error in libcrypto` | La clave perdió el salto de línea final | Genera otra y súbela con `value@archivo`, no con `value=$(cat ...)` |
| `JOB_PROD` vacío | Terminal nueva sin `~/.bc-gitlab-s10` cargado | `source ~/.bc-gitlab-s10`; si no está, búscalo: `GET .../jobs?scope=failed` |

---

## 🔗 Navegación

[← Anterior: Secretos por entorno](03-secretos-por-entorno.md) · [Volver a la Semana 10](../README.md)

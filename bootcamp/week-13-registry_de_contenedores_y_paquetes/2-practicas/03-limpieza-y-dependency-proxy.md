# Práctica 03 — Limpieza y dependency proxy

> Desde la práctica 02, cada commit de `main` deja una imagen en el registry de `app` y otra en el de `ci/componentes`. Hoy se pone el límite: una política que borra las imágenes por SHA y no toca las versiones, ensayada antes con el borrado masivo. Después, las imágenes de Docker Hub de tus jobs dejan de salir a Internet en cada pipeline.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 02 completada · Teoría [04](../1-teoria/04-la-limpieza.md) y [06](../1-teoria/06-el-dependency-proxy.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | La foto del registry antes de limpiar | — |
| 2 | Políticas de limpieza en `app` y en `ci/componentes` | `limpieza-activa` |
| 3 | El ensayo: un borrado masivo con los mismos criterios | — |
| 4 | La caché del dependency proxy con caducidad | `proxy-con-caducidad` |
| 5 | `app` descargando de Docker Hub a través del proxy | `app-usa-dependency-proxy` |

Si has cerrado la terminal, repite el paso 0 de la práctica 01 y `source ~/.bc-gitlab-s13`.

---

## Paso 1: Lo que hay

**Por qué**: una política se escribe para los tags que tienes, no para los que imaginas. Primero, la lista.

```bash
for PR in "$P" "$PC"; do
  curl -s -H "$H" "$API/projects/$PR/registry/repositories?tags=true" \
    | jq -r '.[] | "\(.id)\t\(.path)\t\([.tags[].name] | join(" "))"'
done
```

**Verifica**: en `app`, un repositorio en la raíz con uno o más SHA cortos. En `ci/componentes`, `…/ci/componentes/prueba` con un SHA corto y `1.2.0`. Guarda el ID de este último:

```bash
RID_PRUEBA=$(curl -s -H "$H" "$API/projects/$PC/registry/repositories" | jq -r '.[] | select(.path | endswith("/prueba")) | .id')
curl -s -H "$H" "$API/registry/repositories/$RID_PRUEBA?size=true" | jq '{path, size}'
```

---

## Paso 2: Las dos políticas

**Por qué**: la política por defecto tiene `name_regex: .*`. Activarla sin más haría candidatas a tus versiones (teoría 04, apartado 2.2). Aquí la expresión de borrado nombra solo los SHA cortos, y la de conservación, las versiones: dos defensas, además de los tags protegidos de `app`.

Antes de guardar, la expresión contra los tags reales. `grep -x` ancla igual que GitLab:

```bash
printf '3f2a9c1e\n1.2.0\nlatest\n1a2b3c4\n' | grep -xE '[0-9a-f]{8}'    # solo 3f2a9c1e
```

```bash
politica() {   # $1 = proyecto, $2 = keep_n, $3 = older_than
  jq -n --argjson n "$2" --arg o "$3" '{container_expiration_policy_attributes: {
      enabled: true, cadence: "1d", keep_n: $n, older_than: $o,
      name_regex: "[0-9a-f]{8}", name_regex_keep: "[0-9]+\\.[0-9]+\\.[0-9]+"}}' \
    | curl -s --request PUT "$API/projects/$1" -H "$H" -H "Content-Type: application/json" -d @- \
    | jq -c '.container_expiration_policy | {enabled, keep_n, older_than, name_regex, name_regex_keep, next_run_at}'
}
politica "$P" 10 30d
politica "$PC" 5 7d
```

**Verifica**: las dos con `enabled: true` y `next_run_at` dentro de un día. `ci/componentes` es más agresiva: sus imágenes de prueba no las despliega nadie.

---

## Paso 3: El ensayo

**Por qué**: `next_run_at` es mañana, y no hay botón para lanzar la política ahora (teoría 04, apartado 2.3). El borrado masivo acepta los mismos criterios y actúa ya. Lo ensayas sobre `ci/componentes/prueba`, donde equivocarse no cuesta nada.

> [!WARNING]
> El borrado es real y no se deshace. Sin `keep_n` ni `older_than`, borra **todo** lo que cumple la expresión: por eso se hace en `prueba` y nunca en `app`.

```bash
curl -s -H "$H" "$API/projects/$PC/registry/repositories/$RID_PRUEBA/tags" | jq -r '.[].name' | grep -xE '[0-9a-f]{8}'
curl -s --request DELETE "$API/projects/$PC/registry/repositories/$RID_PRUEBA/tags" -H "$H" \
  --data-urlencode 'name_regex_delete=[0-9a-f]{8}' \
  --data-urlencode 'name_regex_keep=[0-9]+\.[0-9]+\.[0-9]+' \
  -o /dev/null -w '%{http_code}\n'
sleep 15
curl -s -H "$H" "$API/projects/$PC/registry/repositories/$RID_PRUEBA/tags" | jq -r '.[].name'
```

**Verifica**:

- El `grep` lista lo que se va a borrar: los SHA cortos. Lo que no lista se queda.
- `202`: aceptado. El borrado ocurre en segundo plano.
- Después, solo `1.2.0`.

No lo repitas enseguida: el borrado masivo admite una llamada por hora y repositorio.

El tamaño del repositorio no baja todavía:

```bash
curl -s -H "$H" "$API/registry/repositories/$RID_PRUEBA?size=true" | jq .size
```

Las capas que ya no usa ningún tag las recoge la recolección de basura en línea, pasadas 24 horas (teoría 04, apartado 2.4). Vuelve a mirarlo mañana.

---

## Paso 4: La caducidad del dependency proxy

**Por qué**: el proxy viene activado en tu grupo, sin caducidad: guardaría para siempre cada imagen que alguien usó una vez. Treinta días sin uso es suficiente para la caché de un laboratorio.

```bash
q() { jq -n --arg q "$1" '{query: $q}' | curl -s "$GITLAB_URL/api/graphql" -H "$H" -H "Content-Type: application/json" -d @-; }

q "{ group(fullPath: \"$GRUPO\") { dependencyProxySetting { enabled } dependencyProxyImageTtlPolicy { enabled ttl } } }" \
  | jq -c .data.group
q "mutation { updateDependencyProxyImageTtlGroupPolicy(input: { groupPath: \"$GRUPO\", enabled: true, ttl: 30 }) {
     errors dependencyProxyImageTtlPolicy { enabled ttl } } }" | jq -c .data
```

**Verifica**: antes, `{"enabled":true}` y `{"enabled":false,"ttl":90}`. Después, `"errors":[]` y `{"enabled":true,"ttl":30}`. Si `errors` dice que no tienes permiso, no eres Owner del grupo raíz: la Semana 03 te dejó como Owner, compruébalo en `Manage → Members`.

---

## Paso 5: `app` a través del proxy

**Por qué**: cada job de `app` descarga `node:22.23.3-alpine3.24` de Docker Hub. Con el prefijo, la descarga va a tu instancia, y solo la primera sale a Internet.

```bash
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Imágenes de Docker Hub a través del dependency proxy" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX en default y en el input imagen de npm. Ver Semana 13." \
  | jq -r .iid)
git switch -c "$IID-dependency-proxy"
```

En `.gitlab-ci.yml`, dos cambios. El `default`:

```yaml
default:
  image: ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/node:22.23.3-alpine3.24
  interruptible: true
```

Y el input `imagen` del componente `npm`, que hasta hoy usaba su valor por defecto:

```yaml
  - component: $CI_SERVER_FQDN/plataforma-<tu-dominio>/ci/componentes/npm@1
    inputs:
      imagen: ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/node:22.23.3-alpine3.24
```

Si tu `npm@1` ya llevaba otros inputs, `imagen` se añade a ellos. El valor por defecto del componente **no** se toca: un consumidor sin grupo no tendría proxy (teoría 06, apartado 2.3).

```bash
git add .gitlab-ci.yml
git commit -S -m "ci: imágenes de Docker Hub a través del dependency proxy"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="ci: dependency proxy para las imágenes de Docker Hub" \
  -o merge_request.description="Closes #$IID"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
fusionar "$P" "$MR"
git switch main && git pull --ff-only
PIPE=$(curl -s -H "$H" "$API/projects/$P/pipelines?ref=main&source=push&per_page=1" | jq -r '.[0].id')
esperar "$P" "$PIPE"
JOB=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | select(.name == "build") | .id')
curl -s -H "$H" "$API/projects/$P/jobs/$JOB/trace" | grep -m1 'Pulling docker image'
q "{ group(fullPath: \"$GRUPO\") { dependencyProxyManifests { nodes { imageName } } } }" | jq -r '.data.group.dependencyProxyManifests.nodes[].imageName'
```

**Verifica**:

- `success`.
- `Pulling docker image localhost:8888/plataforma-<tu-dominio>/dependency_proxy/containers/node:22.23.3-alpine3.24`.
- `node:22.23.3-alpine3.24` en la caché del grupo.

El job `imagen` sigue descargando su base, el `FROM` del `Dockerfile`, de Docker Hub: kaniko no llega a `localhost:8888` (teoría 06, apartado 2.4).

---

## ✅ Checklist

- [ ] Políticas de limpieza en `app` (10, 30d) y en `ci/componentes` (5, 7d), con las dos expresiones
- [ ] El ensayo borró los SHA cortos de `prueba` y dejó `1.2.0`
- [ ] El dependency proxy del grupo, con `ttl` de 30 días
- [ ] Los jobs de `app` descargan `node` desde `localhost:8888/…/dependency_proxy/…`

---

## 🧯 Problemas frecuentes

| Síntoma | Causa | Solución |
|---|---|---|
| `PUT` responde `400` con `keep_n` u `older_than` | Un valor que no está en la lista | `1, 5, 10, 25, 50, 100` y `7d`, `14d`, `30d`… (teoría 04, apartado 2.2) |
| `400`: `This request has already been made. You can run this at most once an hour for a given container repository` | Un segundo borrado masivo en menos de una hora | Espera |
| `1.2.0` desapareció en el ensayo | La expresión de borrado no es la del paso | `[0-9a-f]{8}`, con `name_regex_keep` |
| El job falla con `pull access denied for localhost:8888/…` | El prefijo apunta a un grupo del que no eres miembro, o escribiste la ruta a mano | `${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}` |
| El log sigue diciendo `Pulling docker image node:…` | El job lleva su propio `image:` | El input `imagen` del componente, o el `image:` de ese job |

---

[← Anterior: El componente imagen](02-el-componente-imagen.md) · [Volver a la Semana 13](../README.md) · [Siguiente: El paquete por SHA →](04-el-paquete-por-sha.md)

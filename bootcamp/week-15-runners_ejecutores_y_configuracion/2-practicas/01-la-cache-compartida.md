# Práctica 01 — La caché compartida

> Levantas el servicio `cache-s3`, miras dónde guarda hoy `docker-app` la caché de `npm`, y la mueves al bucket `runner-cache` editando su bloque de `config.toml`. Compruebas en el log de un job que la caché sube y baja de S3, la ves dentro del almacén, y la vacías por API para ver cómo cambia la clave.

**Duración estimada**: 50 min
**Prerrequisitos**: Semana 14 completada · Teoría [01](../1-teoria/01-anatomia-del-runner.md), [02](../1-teoria/02-el-config-toml.md) y [07](../1-teoria/07-la-cache-distribuida.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 0 | Variables y funciones de la semana | — |
| 1 | El servicio `cache-s3`, con tu propia clave | — |
| 2 | La foto de antes: la caché local de `docker-app` | — |
| 3 | `config.toml` fuera del contenedor, para editarlo | — |
| 4 | `docker-app` con la caché en S3 y `concurrent = 3` | `docker-app-en-linea` |
| 5 | Un pipeline que sube la caché, y otro que la baja | — |
| 6 | La caché vaciada, y la clave nueva | — |

---

## Paso 0: Preparar el terreno

**Por qué**: las mismas variables que la Semana 14, más el ID numérico del grupo `infra`, que la práctica 03 necesita para crear su runner. `esperar` y `fusionar` son las de la Semana 13, sin cambios.

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
export GI=$(curl -s -H "$H" "$API/groups/$(printf '%s' "$GRUPO/infra" | jq -sRr @uri)" | jq -r .id)
grep -qs GI= ~/.bc-gitlab-s15 || echo "export GRUPO=$GRUPO PI=$PI ID_APP=$ID_APP ID_INFRA=$ID_INFRA GI=$GI" >> ~/.bc-gitlab-s15
chmod 600 ~/.bc-gitlab-s15
```

Copia `esperar` y `fusionar` del [paso 0 de la práctica 01 de la Semana 13](../../week-13-registry_de_contenedores_y_paquetes/2-practicas/01-el-registry-y-el-dockerfile.md#paso-0-preparar-el-terreno), con `HR`, el token de `revisor-<tu-dominio>` que se crea allí.

**Verifica**:

```bash
echo "$ID_APP $ID_INFRA $GI"            # tres números
type esperar fusionar | grep -c 'is a'  # 2
```

Si cierras la terminal a mitad de semana: `source ~/.bc-gitlab`, `source ~/.bc-gitlab-s15`, las cuatro primeras líneas de arriba y las dos funciones.

---

## Paso 1: El servicio `cache-s3`

**Por qué**: el `docker-compose.yml` del bootcamp trae desde esta semana `cache-s3` (teoría 07, apartado 2.3). Su identidad S3 sale de `.env`, y el valor de `.env.example` es público: está en este repositorio. Cámbialo antes de que el almacén guarde nada.

```bash
cd /ruta/a/bc-gitlab && git pull --ff-only
grep -E '^(SEAWEEDFS_VERSION|RUNNER_CACHE_)' .env.example >> .env
sed -i "s/^RUNNER_CACHE_SECRET_KEY=.*/RUNNER_CACHE_SECRET_KEY=$(openssl rand -hex 24)/" .env
grep -c '^RUNNER_CACHE_' .env                       # 2
docker compose --profile base up -d cache-s3
```

**Verifica**:

```bash
docker compose logs cache-s3 2>&1 | grep -E 'created bucket|Added admin identity' | cut -c1-120
# … Added admin identity from AWS environment variables: name=admin-runnerca, accessKey=runnercache
# … created bucket runner-cache
docker stats --no-stream --format '{{.Name}} {{.MemUsage}}' | grep cache-s3   # unos 100 MiB
```

Si `grep -c` da `4`, ya tenías las variables: deja una sola copia de cada una en `.env`.

---

## Paso 2: La foto de antes

**Por qué**: para saber que algo ha cambiado hay que haberlo visto antes. Hoy `docker-app` guarda la caché en un volumen de Docker que solo él ve.

```bash
J=$(curl -s -H "$H" "$API/projects/$P/jobs?scope[]=success&per_page=50" \
  | jq -r 'map(select(.name == "build"))[0].id')
curl -s -H "$H" "$API/projects/$P/jobs/$J/trace" | sed 's/\x1b\[[0-9;]*[mK]//g' \
  | grep -E 'Checking cache for|Creating cache|Created cache|Successfully extracted' | cut -c1-120
docker volume ls --format '{{.Name}}' | grep -E '^runner-.*-cache-' | head -3
```

**Verifica**: líneas como `Checking cache for 3f2a…-protected...` y `Created cache`, sin ninguna URL; y uno o varios volúmenes `runner-…-cache-…`. Esa es la caché local. El sufijo `-protected` es el de la teoría 05; como eres administrador, lo verás también en las ramas sin proteger.

---

## Paso 3: `config.toml` fuera del contenedor

**Por qué**: `register` añade bloques, no edita (teoría 02, apartado 3). El bloque de `docker-app` se cambia a mano, y es más cómodo con tu editor que con `vi` dentro del contenedor. La copia lleva el token de `docker-app`: fuera del repositorio y con `chmod 600`.

> [!WARNING]
> Haz una copia de seguridad antes de tocar nada. Si el archivo nuevo tiene un error, el proceso sigue con el viejo (teoría 02, apartado 2.4), pero si lo pierdes tienes que volver a registrar el runner.

```bash
cd /ruta/a/bc-gitlab
docker compose cp gitlab-runner:/etc/gitlab-runner/config.toml ~/.bc-gitlab-runner.toml
cp ~/.bc-gitlab-runner.toml ~/.bc-gitlab-runner.toml.antes-s15
chmod 600 ~/.bc-gitlab-runner.toml ~/.bc-gitlab-runner.toml.antes-s15
grep -nE '^\s*(concurrent|name|limit|executor) =' ~/.bc-gitlab-runner.toml
```

**Verifica**: `concurrent = 2` (Semana 11), un solo `name = "docker-app"` y su `executor = "docker"`. Si hay dos bloques `docker-app`, la Semana 09 se registró dos veces: borra el que no tenga el `id` que da `GET /projects/$P/runners?type=project_type`.

---

## Paso 4: `docker-app` contra S3

**Por qué**: tres cambios en el archivo. `concurrent = 3`, porque esta semana el proceso atiende tres runners (teoría 02, apartado 2.2). `limit = 2` en `docker-app`, para que nunca se quede todos los huecos. Y su caché en el bucket, con `Shared = true` para que los otros dos runners la vean (teoría 07, apartado 2.2).

Edita `~/.bc-gitlab-runner.toml`. La línea global:

```toml
concurrent = 3
```

Y dentro del bloque de `docker-app`, debajo de `executor = "docker"`, sustituye el `[runners.cache]` vacío que dejó `register` por este (pon tu clave de `.env`):

```toml
  limit = 2
  [runners.cache]
    Type = "s3"
    Shared = true
    [runners.cache.s3]
      ServerAddress = "cache-s3:8333"
      AccessKey = "runnercache"
      SecretKey = "<RUNNER_CACHE_SECRET_KEY de tu .env>"
      BucketName = "runner-cache"
      Insecure = true
```

Lo que había en `[runners.docker]` (imagen, `network_mode`, `volumes`) no cambia. Devuelve el archivo:

```bash
docker compose cp ~/.bc-gitlab-runner.toml gitlab-runner:/etc/gitlab-runner/config.toml
sleep 5
docker compose logs --since 1m gitlab-runner 2>&1 | grep -E 'Configuration loaded|Failed to load' | tail -1
```

**Verifica**:

```bash
# Configuration loaded …  max_builds=3
curl -s -H "$H" "$API/projects/$P/runners?type=project_type&tag_list=docker&status=online" \
  | jq -c '.[] | {description, status}'
# {"description":"docker-app","status":"online"}
```

Si el log dice `Failed to load config`, el TOML está mal: el error trae el número de línea. El runner sigue `online` con la configuración vieja.

---

## Paso 5: La caché viaja por S3

**Por qué**: el `online` de arriba no dice nada de la caché. Lo dice el log del siguiente job que la use. El primer pipeline no encuentra nada en el bucket (está vacío) y sube; el segundo baja.

```bash
for i in 1 2; do
  PIPE=$(curl -s --request POST "$API/projects/$P/pipeline" -H "$H" --data-urlencode "ref=main" | jq -r .id)
  esperar "$P" "$PIPE"
  J=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | select(.name == "build") | .id')
  curl -s -H "$H" "$API/projects/$P/jobs/$J/trace" | sed 's/\x1b\[[0-9;]*[mK]//g' \
    | grep -oE '(Downloading cache from|Uploading cache.zip to) http://cache-s3:8333/[^ ]*|No URL provided.*|Failed to extract cache'
done
```

**Verifica**: en la primera vuelta, `Uploading cache.zip to http://cache-s3:8333/runner-cache/project/<ID_APP>/<clave>-protected`; en la segunda, `Downloading cache from http://cache-s3:8333/…` con la misma ruta. `project/<ID_APP>`, sin nada del runner en medio: es `Shared = true`.

Ahora, dentro del almacén:

```bash
docker compose exec cache-s3 sh -c "echo 'fs.ls -l /buckets/runner-cache/project/$ID_APP' | weed shell" 2>/dev/null
# -rw-rw----   1 root root   18234567 /buckets/runner-cache/project/<ID_APP>/<clave>-protected
```

Los tamaños varían; lo importante es que el objeto está ahí y que los jobs no han necesitado credenciales para llegar a él (teoría 07, apartado 2.1).

---

## Paso 6: Vaciar la caché

**Por qué**: el botón *Clear runner caches* no borra objetos del almacén: cambia la clave (teoría 07, apartado 2.4). Verlo una vez evita buscar en el bucket una clave que ya no se usa.

```bash
jq -n --arg id "gid://gitlab/Project/$ID_APP" \
  '{query: "mutation($id: ProjectID!) { runnerCacheClear(input: {projectId: $id}) { errors } }", variables: {id: $id}}' \
  | curl -s --request POST "$GITLAB_URL/api/graphql" -H "$H" -H "Content-Type: application/json" -d @- | jq -c .
# {"data":{"runnerCacheClear":{"errors":[]}}}
PIPE=$(curl -s --request POST "$API/projects/$P/pipeline" -H "$H" --data-urlencode "ref=main" | jq -r .id)
esperar "$P" "$PIPE"
J=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | select(.name == "build") | .id')
curl -s -H "$H" "$API/projects/$P/jobs/$J/trace" | sed 's/\x1b\[[0-9;]*[mK]//g' | grep -o 'Checking cache for [^ ]*'
```

**Verifica**: `Checking cache for <clave>-1-protected...`. El `-1` es el índice nuevo: el job empieza en frío, sube una caché nueva, y la vieja se queda en el bucket sin que nadie la vuelva a pedir.

---

## ✅ Resultado

- [ ] `cache-s3` en marcha, con tu propia `RUNNER_CACHE_SECRET_KEY`
- [ ] `config.toml` con `concurrent = 3`, y `docker-app` con `limit = 2` y la caché en S3 compartida
- [ ] Un job que sube la caché a `cache-s3` y otro que la baja
- [ ] La caché vaciada por API, y la clave con su índice
- [ ] `~/.bc-gitlab-runner.toml` y su copia, fuera del repositorio y con `chmod 600`

```bash
./scripts/verificar-semana.sh 15     # docker-app-en-linea, en verde
```

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `docker compose up -d cache-s3` dice `no such service` | Tu clon del bootcamp no está al día | `git pull --ff-only` en el paso 1 |
| El log del job dice `No URL provided, cache will not be uploaded to shared cache server. Cache will be stored only locally.` | El bloque `[runners.cache]` no está dentro del de `docker-app`, o falta `Type = "s3"` | Revisa la sangría y que el bloque cuelgue de `[[runners]]` |
| `Uploading cache.zip … 403 Forbidden` | `AccessKey` o `SecretKey` no son las de `.env` | Copia la clave de `.env`; si la cambiaste después de levantar `cache-s3`, `docker compose up -d cache-s3` otra vez |
| `dial tcp: lookup cache-s3 … no such host` | El job no está en la red del laboratorio | `network_mode = "bc-gitlab-network"` en `[runners.docker]` (Semana 09) |
| La segunda vuelta vuelve a subir y no baja | La clave cambió entre las dos: `package-lock.json` distinto | Compara las dos líneas `Checking cache for` |
| `runnerCacheClear` devuelve un error de permisos | Tu token no es de Maintainer de `app` | Usa el de la Semana 01 |

---

[Volver a la Semana 15](../README.md) · [Siguiente: El runner dind →](02-el-runner-dind.md)

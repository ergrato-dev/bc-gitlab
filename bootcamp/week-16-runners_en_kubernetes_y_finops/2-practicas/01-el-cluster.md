# Práctica 01 — El clúster

> Levantas un clúster k3d de un `server` y un `agent` en la red del laboratorio, con su propio `kubeconfig` y con Docker Hub detrás de `registry-cache`. Compruebas desde un pod que llegas a GitLab, al registry y a `cache-s3`, y dejas preparado el namespace donde vivirá el runner, con la clave de la caché en un `Secret`.

**Duración estimada**: 50 min
**Prerrequisitos**: Semana 15 completada · `k3d` `5.9.0`, `kubectl` `1.34`-`1.36` y `helm` `3.22.1` instalados ([setup-entorno](../../../docs/setup-entorno.md#k3d-y-kubectl--desde-la-semana-16)) · Teoría [01](../1-teoria/01-por-que-kubernetes.md) y [02](../1-teoria/02-k3d-en-el-laboratorio.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 0 | Variables y funciones de la semana | — |
| 1 | Memoria para el clúster | — |
| 2 | El límite de inotify, si hace falta | — |
| 3 | El clúster `bootcamp`, con el espejo de Docker Hub | — |
| 4 | `kubectl` contra el clúster, sin tocar otros contextos | — |
| 5 | Un pod que llega a `gitlab`, `registry-cache` y `cache-s3` | — |
| 6 | El namespace `gitlab-runner` con el `Secret` de la caché | — |

---

## Paso 0: Preparar el terreno

**Por qué**: las variables de la Semana 15 (`~/.bc-gitlab-s15` guarda los IDs de los proyectos y de sus runners), más el `kubeconfig` del clúster, que esta semana va en cada terminal.

```bash
source ~/.bc-gitlab
source ~/.bc-gitlab-s15
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
export KUBECONFIG="$HOME/.config/k3d/kubeconfig-bootcamp.yaml"
echo "export KUBECONFIG=$KUBECONFIG" > ~/.bc-gitlab-s16
chmod 600 ~/.bc-gitlab-s16
mkdir -p ~/bc-s16
```

Copia `esperar` y `fusionar` del [paso 0 de la práctica 01 de la Semana 13](../../week-13-registry_de_contenedores_y_paquetes/2-practicas/01-el-registry-y-el-dockerfile.md#paso-0-preparar-el-terreno), con `HR`, el token de `revisor-<tu-dominio>`.

`~/bc-s16` es tu directorio de trabajo de la semana: el archivo de valores del runner y las medidas de la línea base viven ahí hasta que pasan a un repositorio.

**Verifica**:

```bash
echo "$ID_APP $RID_DOCKER $RID_DIND"    # tres números
type esperar fusionar | grep -c 'is a'  # 2
```

Si cierras la terminal a mitad de semana: `source ~/.bc-gitlab ~/.bc-gitlab-s15 ~/.bc-gitlab-s16` (uno por línea), las líneas de `H`, `API` y `P`, y las dos funciones.

---

## Paso 1: Memoria para el clúster

**Por qué**: el clúster suma alrededor de 1,5 GB a lo que ya tienes, y los pods de los jobs lo que cada uno gaste (teoría 02, apartado 2.4). Con observabilidad levantada no cabe.

```bash
cd /ruta/a/bc-gitlab
docker compose --profile observabilidad down 2>/dev/null
docker stats --no-stream --format '{{.Name}} {{.MemUsage}}' | sort -k2 -h | tail -5
free -g | awk '/Mem/ {print $7 " GB disponibles"}'
```

**Verifica**: al menos 4 GB disponibles. Si no, aplica la reducción de Puma y Sidekiq de [perfiles-de-laboratorio](../../../docs/perfiles-de-laboratorio.md#semana-16--runners-en-kubernetes-11-12-gb) y cierra lo que no uses.

---

## Paso 2: El límite de inotify

**Por qué**: k3s abre muchas instancias de inotify. Con el límite de 128 que traen muchas distribuciones y WSL, el clúster no arranca si ya hay otro (kind, minikube) o un IDE grande abierto (teoría 02, apartado 3).

```bash
sysctl -n fs.inotify.max_user_instances
```

Si sale menos de 512:

```bash
sudo sysctl -w fs.inotify.max_user_instances=512
echo 'fs.inotify.max_user_instances = 512' | sudo tee /etc/sysctl.d/99-inotify.conf
```

**Verifica**: `512`. La segunda línea lo deja fijo tras reiniciar; en WSL, tras `wsl --shutdown`.

---

## Paso 3: El clúster

**Por qué**: un `server` y un `agent`, en `bc-gitlab-network`, con la versión de Kubernetes fijada y Docker Hub detrás de `registry-cache` (teoría 02, apartados 2.1 y 2.3).

```bash
cat > ~/.config/k3d/registries-bootcamp.yaml <<'EOF'
mirrors:
  docker.io:
    endpoint:
      - http://registry-cache:5000
EOF
k3d cluster create bootcamp --servers 1 --agents 1 \
  --image rancher/k3s:v1.35.10-k3s1 \
  --network bc-gitlab-network \
  --registry-config "$HOME/.config/k3d/registries-bootcamp.yaml" \
  --k3s-arg "--disable=traefik@server:*" \
  --kubeconfig-update-default=false --kubeconfig-switch-context=false
```

Tarda uno o dos minutos la primera vez: baja la imagen de k3s.

**Verifica**:

```bash
docker ps --filter name=k3d-bootcamp --format '{{.Names}} {{.Status}}'
```

Tres contenedores `Up`: `server-0`, `agent-0` y `serverlb`. Si `k3d cluster create` no termina, mira `docker logs k3d-bootcamp-server-0 2>&1 | grep -m1 inotify` y vuelve al paso 2.

---

## Paso 4: `kubectl` contra el clúster

**Por qué**: el `kubeconfig` va en su propio archivo; `~/.kube/config` y el contexto de otros clústeres no se tocan (teoría 02, apartado 2.2).

```bash
k3d kubeconfig write bootcamp       # escribe el archivo de KUBECONFIG
kubectl get nodes
kubectl get --raw /version | jq -r .gitVersion
```

**Verifica**: dos nodos `Ready` (`k3d-bootcamp-server-0`, `k3d-bootcamp-agent-0`) y `v1.35.10+k3s1`. Si `kubectl` enseña otros nodos, falta el `export KUBECONFIG` del paso 0 en esta terminal.

---

## Paso 5: Desde un pod, el laboratorio

**Por qué**: el job, dentro de un pod, va a clonar de `gitlab:8888`, pedir su token del registry, subir a `gitlab:5050` y guardar la caché en `cache-s3:8333`. Si un pod de prueba no llega, un job tampoco llegará. La imagen del pod, además, baja por el espejo: es la primera prueba de que funciona.

```bash
kubectl run prueba-red --image=alpine:3.24.2 --restart=Never --rm -i --quiet -- sh -c '
  wget -qO- http://gitlab:8888/-/health; echo
  wget -qS -O /dev/null http://gitlab:5050/v2/ 2>&1 | grep -m1 HTTP
  wget -qS -O /dev/null http://cache-s3:8333/ 2>&1 | grep -m1 HTTP
  wget -qO- http://registry-cache:5000/v2/_catalog'
```

**Verifica**:

```
GitLab OK
  HTTP/1.1 401 Unauthorized
  HTTP/1.1 403 Forbidden
{"repositories":[…,"library/alpine",…]}
```

`401` del registry y `403` de `cache-s3` son las respuestas buenas: llegaste, y te pidieron credenciales que no llevabas. `library/alpine` en el catálogo de `registry-cache` es la imagen de este pod, bajada por el espejo. Si dice `bad address 'gitlab'`, el clúster no está en `bc-gitlab-network`: bórralo (`k3d cluster delete bootcamp`) y repite el paso 3.

---

## Paso 6: El namespace del runner

**Por qué**: el gestor y los pods de los jobs viven en `gitlab-runner`. La clave de `cache-s3` es la de tu `.env` (Semana 15) y va en un `Secret`, nunca en el archivo de valores (teoría 03, apartado 2.1). La parte secreta entra por la entrada estándar, para que no aparezca en `ps`; el nombre de usuario de S3 no es secreto.

```bash
kubectl create namespace gitlab-runner
grep '^RUNNER_CACHE_SECRET_KEY=' /ruta/a/bc-gitlab/.env | cut -d= -f2- | tr -d '\n' \
  | kubectl -n gitlab-runner create secret generic cache-s3 \
      --from-literal=accesskey="$(grep '^RUNNER_CACHE_ACCESS_KEY=' /ruta/a/bc-gitlab/.env | cut -d= -f2-)" \
      --from-file=secretkey=/dev/stdin
```

**Verifica**:

```bash
kubectl -n gitlab-runner get secret cache-s3 -o json | jq -r '.data | keys | join(" ")'   # accesskey secretkey
kubectl -n gitlab-runner get secret cache-s3 -o jsonpath='{.data.secretkey}' | base64 -d | wc -c
```

La segunda cifra es la longitud de tu clave (48 con `openssl rand -hex 24`), no un `0`. El valor no se imprime: un `Secret` se lee con `base64 -d`, y eso es justo lo que no quieres en el historial de tu terminal.

---

## ✅ Resultado

- [ ] `~/.bc-gitlab-s16` con el `KUBECONFIG`, en `600`
- [ ] El clúster `bootcamp` con dos nodos `Ready` en `v1.35.10+k3s1`
- [ ] Un pod llega a `gitlab:8888`, `gitlab:5050`, `cache-s3:8333` y `registry-cache:5000`
- [ ] Las imágenes de Docker Hub bajan por `registry-cache`
- [ ] El namespace `gitlab-runner` con el `Secret` `cache-s3`

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `k3d cluster create` se queda esperando | inotify agotado | Paso 2 |
| `network bc-gitlab-network not found` | El perfil `base` no está levantado | `docker compose --profile base up -d` y repite el paso 3 |
| `kubectl` responde `connection refused` en `0.0.0.0:<puerto>` | El clúster está parado | `k3d cluster start bootcamp` |
| `library/alpine` no sale en el catálogo | El pod bajó la imagen de Docker Hub: el espejo no se aplicó | `docker exec k3d-bootcamp-server-0 cat /etc/rancher/k3s/registries.yaml`; si no está, borra el clúster y repite el paso 3 con `--registry-config` |
| `ErrImagePull … toomanyrequests` | Límite de Docker Hub, sin espejo | Ídem |
| La longitud de la clave sale `0` | La variable no está en tu `.env`, o la ruta está mal | `grep -c '^RUNNER_CACHE_' /ruta/a/bc-gitlab/.env` debe dar `2` |

---

[← Volver a la Semana 16](../README.md)

# k3d en el laboratorio

> Un clúster de Kubernetes de verdad son varias máquinas. En tu portátil son contenedores: k3d arranca k3s, una distribución de Kubernetes ligera, dentro de contenedores de Docker. Lo que hace que sirva para esta semana es un solo flag, `--network`: los nodos nacen en la misma red que GitLab, y un pod llega a `gitlab:8888` igual que llegaba el contenedor del runner.

---

## 🎯 Objetivos

- Crear un clúster k3d de un `server` y un `agent` en `bc-gitlab-network`
- Mantener su `kubeconfig` aparte, sin tocar el contexto de otros clústeres
- Hacer que los pods bajen las imágenes de Docker Hub por `registry-cache`
- Saber cuánto cuesta en memoria y qué hacer si no arranca

---

## 1. Qué problema resuelve

El runner en Kubernetes necesita tres cosas del laboratorio, y las tres viven en la red del compose:

| Desde el pod | Para qué |
|---|---|
| `gitlab:8888` | Clonar, pedir el token del registry (`$CI_SERVER_URL/jwt/auth`), subir artefactos |
| `gitlab:5050` | Que kaniko suba la imagen |
| `cache-s3:8333` | La caché distribuida de la Semana 15 |

Un clúster en su propia red no resuelve esos nombres. Con `--network bc-gitlab-network`, k3d conecta los nodos a la red existente y el DNS de Docker los resuelve desde dentro de los pods.

---

## 2. Cómo funciona

### 2.1 Nodos que son contenedores

```bash
k3d cluster create bootcamp --servers 1 --agents 1 \
  --image rancher/k3s:v1.35.10-k3s1 \
  --network bc-gitlab-network \
  --registry-config "$HOME/.config/k3d/registries-bootcamp.yaml" \
  --k3s-arg "--disable=traefik@server:*" \
  --kubeconfig-update-default=false --kubeconfig-switch-context=false
```

| Flag | Por qué |
|---|---|
| `--servers 1 --agents 1` | El plano de control y un nodo de trabajo. Los pods de los jobs caben en los dos |
| `--image rancher/k3s:v1.35.10-k3s1` | La versión de Kubernetes fijada. Sin él, k3d `5.9.0` usa la que trae compilada, `v1.32.5` |
| `--network bc-gitlab-network` | Los nodos en la red del compose (apartado 1) |
| `--registry-config` | El espejo de Docker Hub (apartado 2.3) |
| `--disable=traefik` | k3s trae un ingress que esta semana no usa. Son unos 100 MB menos |
| `--kubeconfig-update-default=false --kubeconfig-switch-context=false` | No toca `~/.kube/config` ni cambia tu contexto actual |

Crea tres contenedores: `k3d-bootcamp-server-0`, `k3d-bootcamp-agent-0` y `k3d-bootcamp-serverlb`, el balanceador por el que `kubectl` llega a la API.

### 2.2 El `kubeconfig` aparte

```bash
export KUBECONFIG=$(k3d kubeconfig write bootcamp)   # ~/.config/k3d/kubeconfig-bootcamp.yaml
kubectl get nodes
```

Si ya tienes otros clústeres (kind, minikube, el de otro curso), `kubectl` sigue apuntando a ellos en las demás terminales. Esta semana, cada terminal nueva empieza por ese `export`.

### 2.3 Las imágenes, por `registry-cache`

Los pods no bajan las imágenes con el Docker de tu máquina, sino con el `containerd` de cada nodo. Sin espejo, cada `node:22.23.3-alpine3.24` va a Docker Hub y cuenta para su límite de descargas anónimas. k3s lee los espejos de `registries.yaml`:

```yaml
mirrors:
  docker.io:
    endpoint:
      - http://registry-cache:5000
```

Es el mismo `registry-cache` que usan `dind-app` y el contenedor del runner desde la Semana 09. El `helper` del runner viene de `registry.gitlab.com`, que no pasa por el espejo.

### 2.4 La memoria

| Pieza | Memoria aproximada |
|---|:--:|
| `k3d-bootcamp-server-0` (plano de control y nodo) | ~1 GB |
| `k3d-bootcamp-agent-0` | ~500 MB |
| El gestor del runner, dentro de uno de los dos | ~50 MB |
| Cada pod de job | Lo que pida su imagen; `memory_limit = 1Gi` como techo |

Con el perfil `base` (unos 5-6 GB) cabe en 16 GB, siempre que **observabilidad esté apagada**. Las cuentas y la reducción de Puma y Sidekiq están en [perfiles-de-laboratorio](../../../docs/perfiles-de-laboratorio.md#semana-16--runners-en-kubernetes-11-12-gb).

---

## 3. Si no arranca

| Síntoma | Causa | Solución |
|---|---|---|
| `k3d cluster create` no termina y el log del server dice `inotify_init: too many open files` | El límite de instancias de inotify (128 en muchas distribuciones y en WSL) lo agotan otros clústeres o el IDE | `sudo sysctl -w fs.inotify.max_user_instances=512`; permanente, en `/etc/sysctl.d/99-inotify.conf` |
| `network bc-gitlab-network not found` | El perfil `base` no está levantado | `docker compose --profile base up -d` |
| Los nodos `NotReady` un minuto después | Falta memoria | `docker stats --no-stream` y apaga lo que sobre |
| `kubectl` responde con otro clúster | Terminal sin el `export KUBECONFIG` | Apartado 2.2 |

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Crear el clúster en su red y publicar GitLab con la IP del host | `localhost` dentro del pod es el pod; la IP del host cambia con cada red de WSL | `--network bc-gitlab-network` |
| `k3d cluster create` sin `--image` | La versión de Kubernetes la decide el binario de k3d que tengas | `--image rancher/k3s:v1.35.10-k3s1` |
| Dejar que k3d cambie el contexto por defecto | El siguiente `kubectl delete` de otro curso cae en este clúster | `--kubeconfig-switch-context=false` y `KUBECONFIG` explícito |
| Varios agentes "para que haya más sitio" | Todos los nodos comparten la memoria de tu máquina: no hay más sitio, hay más contenedores | Un `agent` |

---

## 5. Trucos

- `k3d cluster stop bootcamp` libera la memoria sin borrar nada; `k3d cluster start bootcamp` lo devuelve tal cual, con el runner dentro.
- `kubectl get --raw /version | jq -r .gitVersion` confirma la versión de Kubernetes sin buscar en la salida de `kubectl version`.

---

## 📚 Recursos Adicionales

- [k3d — Networking](https://k3d.io/stable/design/networking/) y [`k3d cluster create`](https://k3d.io/stable/usage/commands/k3d_cluster_create/)
- [k3d — Registries](https://k3d.io/stable/usage/registries/)
- [k3s — Private registry configuration](https://docs.k3s.io/installation/private-registry)

---

## ✅ Checklist de Verificación

- [ ] Sé por qué el clúster va en `bc-gitlab-network`
- [ ] Sé dónde está el `kubeconfig` del clúster y qué pasa si no lo exporto
- [ ] Sé por qué los pods bajan las imágenes por `registry-cache`
- [ ] Sé qué hacer si k3s se queja de inotify

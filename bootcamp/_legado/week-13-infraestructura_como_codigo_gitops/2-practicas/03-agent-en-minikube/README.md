# Práctica 03 — Instalar y Registrar el GitLab Kubernetes Agent en Minikube

## Objetivo

Registrar un GitLab Kubernetes Agent contra un proyecto GitLab, instalar `agentk` en el clúster Minikube (reutilizando el entorno de la semana 07) usando Helm, y verificar que la conexión queda activa en la UI de GitLab.

## Requisitos

- Minikube corriendo (`minikube status`) — mismo clúster de la práctica de Runner en K8s (semana 07)
- `kubectl` y `helm` v3 instalados y apuntando al contexto `minikube`
- `kas` habilitado en la instancia GitLab CE (`sudo gitlab-ctl status gitlab-kas`)
- Tiempo estimado: 50-70 minutos

---

## Instrucciones

### Paso 1: Verificar el clúster y el servidor kas

```bash
minikube status
kubectl config current-context
# minikube

sudo gitlab-ctl status gitlab-kas
# run: gitlab-kas: (pid XXXX) NNs
```

Si `gitlab-kas` no está habilitado, añádelo a `/etc/gitlab/gitlab.rb` y reconfigura:

```ruby
gitlab_kas['enable'] = true
```

```bash
sudo gitlab-ctl reconfigure
```

### Paso 2: Crear el proyecto de configuración del agent

```bash
mkdir -p .gitlab/agents/minikube-bootcamp
cp /ruta/al/starter/config.yaml .gitlab/agents/minikube-bootcamp/config.yaml
git add .gitlab/agents/minikube-bootcamp/config.yaml
git commit -m "chore(agent): configurar minikube-bootcamp"
git push origin main
```

### Paso 3: Registrar el agent y obtener el token

```bash
# ¿QUÉ HACE?: Registra el agent contra el proyecto y devuelve su token de conexión
# ¿POR QUÉ?: Sin este token, agentk no puede autenticarse ante kas
# ¿PARA QUÉ?: Usarlo en el paso 4 al instalar el Helm chart
PROJECT_ID="<tu-project-id>"

curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data "name=minikube-bootcamp" \
  "http://localhost/api/v4/projects/${PROJECT_ID}/cluster_agents" | jq

AGENT_ID="<id-devuelto>"

curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/${PROJECT_ID}/cluster_agents/${AGENT_ID}/tokens" | jq -r '.token'
```

### Paso 4: Instalar `agentk` con Helm

Completa las variables en `starter/install-agent.sh` (dirección de kas y token) y ejecútalo:

```bash
chmod +x install-agent.sh
./install-agent.sh
```

### Paso 5: Verificar la conexión

```bash
kubectl get pods -n gitlab-agent
kubectl logs -n gitlab-agent deployment/minikube-bootcamp --tail 20
```

En la UI: **Operate → Kubernetes clusters** del proyecto debe mostrar `minikube-bootcamp` con estado **Connected** y un timestamp reciente de "Last contact".

### Paso 6: Configurar RBAC de mínimo privilegio

Aplica el `Role`/`RoleBinding` del starter para que el Service Account del agent solo pueda gestionar `Deployments`, `Services` y `ConfigMaps` en el namespace `produccion` — no `cluster-admin`:

```bash
kubectl apply -f starter/rbac-agent.yaml
kubectl auth can-i create deployments --namespace produccion \
  --as=system:serviceaccount:gitlab-agent:minikube-bootcamp
# yes
kubectl auth can-i delete namespaces \
  --as=system:serviceaccount:gitlab-agent:minikube-bootcamp
# no
```

---

## Preguntas de reflexión

1. ¿Por qué la conexión entre `agentk` y `kas` la inicia siempre el clúster y nunca GitLab?
2. Si revocas el token del agent desde la UI sin desinstalar el Helm release, ¿qué verás en los logs de `agentk`?
3. ¿Qué diferencia práctica hay entre el Service Account del Runner (semana 07) y el del Agent en términos de qué pueden hacer en el clúster?

---

## Entregables

- [ ] `config.yaml` del agent commiteado en `.gitlab/agents/minikube-bootcamp/`
- [ ] Agent registrado y visible en Operate → Kubernetes clusters con estado Connected
- [ ] Pod de `agentk` en estado `Running` en el namespace `gitlab-agent`
- [ ] RBAC de mínimo privilegio aplicado y verificado con `kubectl auth can-i`

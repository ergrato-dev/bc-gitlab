# 🔬 Práctica 04 — GitLab Runner en Kubernetes

**Duración estimada:** 50 minutos
**Dificultad:** ⭐⭐⭐⭐ (Alta)

## 🎯 Objetivo

Desplegar GitLab Runner en un cluster Kubernetes usando Helm, configurar recursos y node selectors, y ejecutar jobs que se materialicen como pods efímeros en el cluster.

---

## 📋 Prerrequisitos

- Cluster Kubernetes accesible (Minikube, kind, o cluster real)
- `kubectl` configurado y con acceso al cluster
- `helm` v3 instalado
- `$GITLAB_TOKEN` y `$GITLAB_PROJECT_ID` exportados

```bash
# Verificar acceso al cluster
kubectl cluster-info
kubectl get nodes -o wide

# Verificar Helm
helm version --short

# Verificar que GitLab es accesible desde el cluster
# Si usas Minikube, necesitas la IP del host, no localhost
GITLAB_INTERNAL_URL="http://$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type==\"InternalIP\")].address}'):80"
echo "GitLab desde el cluster: $GITLAB_INTERNAL_URL"
```

> **Minikube:** Si usas Minikube, `localhost` no funciona desde el cluster. Usa `minikube ip` para obtener la IP del host o configura el Ingress de GitLab.

---

## 🔑 Paso 1: Crear Token de Autenticación

```bash
# ¿QUÉ HACE?: Crea un runner authentication token para el runner de K8s
# ¿POR QUÉ?: El Helm chart del runner necesita este token para el registro
# ¿PARA QUÉ?: Vincular el runner de K8s con la instancia GitLab

curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "runner_type": "instance_type",
    "description": "bootcamp-k8s-runner",
    "tag_list": ["kubernetes","k8s","bootcamp"],
    "run_untagged": false
  }' \
  "http://localhost/api/v4/user/runners" \
  | python3 -c "
import sys, json
r = json.load(sys.stdin)
if 'token' in r:
    print(f'Token creado: {r[\"token\"]}')
    print(f'Exporta: export RUNNER_K8S_TOKEN=\"{r[\"token\"]}\"')
else:
    print(f'Error: {r}')
"

export RUNNER_K8S_TOKEN="glrt-XXXXXXXXXX"   # ← reemplazar con el token real
```

---

## 📦 Paso 2: Configurar Helm values

Crear el archivo `values.yaml` con la configuración del runner:

```yaml
# values.yaml
# ¿QUÉ HACE?: Configura el runner de K8s con sus parámetros de ejecución
# ¿POR QUÉ?: El Helm chart necesita estos valores para crear el Deployment y el RBAC
# ¿PARA QUÉ?: Controlar recursos, tags, namespaces y comportamiento de los pods de CI
```

Guardar como `/tmp/runner-k8s-values.yaml`:

```bash
cat > /tmp/runner-k8s-values.yaml << 'EOF'
# GitLab instance URL
gitlabUrl: http://GITLAB_URL_AQUI   # ← reemplazar con URL accesible desde el cluster

# Runner authentication token (del Paso 1)
runnerToken: "RUNNER_K8S_TOKEN_AQUI"    # ← reemplazar

# RBAC para que el runner pueda crear pods
rbac:
  create: true
  serviceAccountAnnotations: {}

# Número de jobs concurrentes
concurrent: 4

# Configuración de los runners
runners:
  # Tags para enrutamiento
  tags: "kubernetes,k8s,bootcamp"

  # No ejecutar jobs sin tags (solo los que pidan kubernetes explícitamente)
  runUntagged: false

  # Imagen por defecto para los pods de CI
  image: alpine:latest

  # Política de pull de imágenes
  imagePullPolicy: IfNotPresent

  # Namespace donde se crean los pods de CI
  namespace: gitlab-ci

  # Configuración de recursos para cada pod de job
  builds:
    cpuLimit: "2"
    memoryLimit: "2Gi"
    cpuRequests: "250m"
    memoryRequests: "256Mi"

  services:
    cpuLimit: "1"
    memoryLimit: "1Gi"
    cpuRequests: "100m"
    memoryRequests: "128Mi"

  # Node selector — solo nodos marcados para CI
  # Comentar si tu cluster no tiene nodos con este label
  # nodeSelector:
  #   role: ci

# Configuración del pod del runner manager
podAnnotations:
  cluster-autoscaler.kubernetes.io/safe-to-evict: "false"

resources:
  limits:
    memory: 256Mi
    cpu: 200m
  requests:
    memory: 128Mi
    cpu: 100m
EOF

# Editar la URL de GitLab en el archivo
# IMPORTANTE: Si usas Minikube, esta URL debe ser accesible desde dentro del cluster
GITLAB_URL="http://localhost"   # ← cambiar según tu entorno
sed -i "s|http://GITLAB_URL_AQUI|$GITLAB_URL|g" /tmp/runner-k8s-values.yaml
sed -i "s|RUNNER_K8S_TOKEN_AQUI|$RUNNER_K8S_TOKEN|g" /tmp/runner-k8s-values.yaml

cat /tmp/runner-k8s-values.yaml
```

---

## 🚀 Paso 3: Instalar con Helm

```bash
# ¿QUÉ HACE?: Instala el GitLab Runner en K8s via Helm
# ¿POR QUÉ?: Helm gestiona el ciclo de vida (install/upgrade/uninstall) del runner en K8s
# ¿PARA QUÉ?: Despliegue reproducible del runner con configuración versionada

# Agregar el repositorio de Helm de GitLab
helm repo add gitlab https://charts.gitlab.io
helm repo update

# Crear el namespace para el runner manager
kubectl create namespace gitlab-runners --dry-run=client -o yaml | kubectl apply -f -

# Crear el namespace para los pods de CI
kubectl create namespace gitlab-ci --dry-run=client -o yaml | kubectl apply -f -

# Instalar el runner
helm upgrade --install gitlab-k8s-runner gitlab/gitlab-runner \
  --namespace gitlab-runners \
  --values /tmp/runner-k8s-values.yaml \
  --wait \
  --timeout 120s

echo "Helm install completado"
```

---

## 🔍 Paso 4: Verificar el Despliegue

```bash
# ¿QUÉ HACE?: Verifica que el Deployment del runner manager está running
# ¿POR QUÉ?: El pod del runner manager debe estar en Running antes de recibir jobs
# ¿PARA QUÉ?: Confirmar la instalación antes de crear pipelines

# Estado del deployment
kubectl get all -n gitlab-runners

# Logs del runner manager (buscar "Starting multi-runner from config")
kubectl logs -n gitlab-runners deployment/gitlab-k8s-runner --tail 30

# Verificar que el runner aparece en GitLab
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/runners?status=online" \
  | python3 -c "
import sys, json
for r in json.load(sys.stdin):
    if 'k8s' in r.get('description','').lower() or 'kubernetes' in r.get('tag_list',[]):
        tags = ','.join(r.get('tag_list',[]))
        print(f'✅ Runner K8s online: #{r[\"id\"]} {r[\"description\"]} [{tags}]')
"
```

---

## ✈️ Paso 5: Pipeline para Kubernetes

Crear el siguiente `.gitlab-ci.yml` en el proyecto:

```yaml
stages:
  - info
  - multi-container

# ─── Job básico en K8s ─────────────────────────────────────────────────────────
k8s-environment:
  stage: info
  tags:
    - kubernetes
    - k8s
  image: alpine:latest
  script:
    # ¿QUÉ HACE?: Inspecciona el entorno del pod de CI creado por el K8s executor
    # ¿POR QUÉ?: Cada job es un pod efímero — hostname = nombre del pod de K8s
    # ¿PARA QUÉ?: Confirmar que los jobs corren como pods reales en el cluster
    - echo "=== POD DE KUBERNETES ==="
    - echo "Hostname (nombre del pod): $(hostname)"
    - echo "Namespace (variable K8s): $KUBERNETES_NAMESPACE_OVERWRITE_ALLOWED"
    - echo ""
    - echo "=== SISTEMA OPERATIVO ==="
    - cat /etc/os-release | grep PRETTY_NAME
    - echo ""
    - echo "=== RECURSOS DEL POD ==="
    - cat /proc/meminfo | grep MemTotal
    - nproc  # CPUs visibles al pod (según cpu_limit)
    - echo ""
    - echo "=== VARIABLES DE CI ==="
    - echo "Pipeline: $CI_PIPELINE_ID"
    - echo "Job: $CI_JOB_ID"
    - echo "Runner: $CI_RUNNER_DESCRIPTION"
    - echo "Commit: $CI_COMMIT_SHORT_SHA"
    - echo ""
    - echo "✅ Job ejecutado como pod en Kubernetes"

# ─── Job con imagen específica ──────────────────────────────────────────────────
k8s-node-job:
  stage: info
  tags:
    - kubernetes
  image: node:18-alpine
  script:
    - echo "=== POD CON NODE.JS ==="
    - echo "Pod: $(hostname)"
    - node --version
    - npm --version
    - echo "✅ Pod Node.js en K8s"

# ─── Múltiples pods en paralelo ─────────────────────────────────────────────────
parallel-k8s-1:
  stage: multi-container
  tags: [kubernetes]
  image: alpine:latest
  script:
    - echo "Pod 1: $(hostname)"
    - sleep 10
    - echo "Pod 1 completado"

parallel-k8s-2:
  stage: multi-container
  tags: [kubernetes]
  image: alpine:latest
  script:
    - echo "Pod 2: $(hostname)"
    - sleep 10
    - echo "Pod 2 completado"

parallel-k8s-3:
  stage: multi-container
  tags: [kubernetes]
  image: alpine:latest
  script:
    - echo "Pod 3: $(hostname)"
    - sleep 10
    - echo "Pod 3 completado"
```

---

## 👁️ Paso 6: Observar Pods de CI en Tiempo Real

Mientras el pipeline corre, en otra terminal:

```bash
# ¿QUÉ HACE?: Observa los pods de CI siendo creados y destruidos en tiempo real
# ¿POR QUÉ?: Visualizar el ciclo de vida de los pods efímeros que son los jobs
# ¿PARA QUÉ?: Confirmar que K8s crea pods nuevos y los destruye al terminar

# Watch en tiempo real (requiere otra terminal)
kubectl get pods -n gitlab-ci --watch

# Ver pods del namespace de CI (mientras corre el pipeline):
kubectl get pods -n gitlab-ci -o wide

# Inspeccionar un pod específico de CI (reemplazar POD_NAME con el nombre real):
kubectl describe pod -n gitlab-ci runner-XXXXXXXX-project-XXXXX-build

# Logs del contenedor de CI:
kubectl logs -n gitlab-ci runner-XXXXXXXX-project-XXXXX-build -c build
```

**Lo que deberías ver:**
- Los pods de CI aparecen en estado `ContainerCreating` → `Running` → `Completed`
- Para el stage `multi-container`, los tres pods corren simultáneamente
- Al terminar, los pods pasan a `Completed` y se limpian solos

---

## ⚙️ Paso 7: Configuración Avanzada — Node Selector y Tolerations

Si tu cluster tiene nodos dedicados para CI:

```bash
# ¿QUÉ HACE?: Etiqueta un nodo para que solo reciba pods de CI
# ¿POR QUÉ?: Separar la carga de CI del resto de workloads del cluster
# ¿PARA QUÉ?: Performance predecible y sin interferencia entre CI y producción

# Ver nodos del cluster
kubectl get nodes --show-labels

# Etiquetar un nodo para CI (reemplazar NOMBRE_NODO)
# kubectl label node NOMBRE_NODO role=ci

# Si el nodo tiene un taint para CI:
# kubectl taint nodes NOMBRE_NODO ci=true:NoSchedule

# Actualizar values.yaml con el node selector:
# runners:
#   nodeSelector:
#     role: ci
#   tolerations:
#     - key: "ci"
#       operator: "Equal"
#       value: "true"
#       effect: "NoSchedule"

# Aplicar la actualización:
# helm upgrade gitlab-k8s-runner gitlab/gitlab-runner \
#   --namespace gitlab-runners \
#   --values /tmp/runner-k8s-values.yaml
```

---

## 📊 Paso 8: Verificar Recursos Utilizados

```bash
# ¿QUÉ HACE?: Muestra el uso de CPU y memoria de los pods de CI
# ¿POR QUÉ?: Confirmar que los requests/limits del values.yaml están funcionando
# ¿PARA QUÉ?: Validar que los pods no exceden los recursos configurados

# Recursos del runner manager
kubectl top pods -n gitlab-runners 2>/dev/null || echo "metrics-server no instalado"

# Recursos de los pods de CI (solo mientras corren)
kubectl top pods -n gitlab-ci 2>/dev/null || echo "No hay pods de CI activos"

# Estado general del cluster después de la práctica
kubectl get all -n gitlab-runners
kubectl get all -n gitlab-ci
```

---

## 🧹 Limpieza (Opcional)

```bash
# ¿QUÉ HACE?: Desinstala el runner y limpia los namespaces de K8s
# ¿POR QUÉ?: Liberar recursos del cluster al terminar la práctica
# ¿PARA QUÉ?: Dejar el cluster en el estado inicial

# Desinstalar el Helm release
helm uninstall gitlab-k8s-runner --namespace gitlab-runners

# Eliminar los namespaces (elimina todos los recursos dentro)
kubectl delete namespace gitlab-runners
kubectl delete namespace gitlab-ci
```

---

## ✅ Checklist de verificación

- [ ] Helm chart instalado: `helm list -n gitlab-runners` muestra el release
- [ ] Pod del runner manager en estado `Running`: `kubectl get pods -n gitlab-runners`
- [ ] Runner `bootcamp-k8s-runner` aparece con ● verde en GitLab UI
- [ ] Job `k8s-environment` ejecutado exitosamente — hostname es un pod ID
- [ ] Durante `multi-container` stage: tres pods corriendo simultáneamente en K8s
- [ ] Pods se destruyen automáticamente al terminar los jobs
- [ ] Logs del runner manager sin errores de conexión

---

## 🏆 Reto adicional

Configurar pod annotations para integración con Prometheus (monitoreo) e implementar un `Job` de K8s separado para limpieza periódica de pods fallidos:

```yaml
# En values.yaml — annotations por pod de CI
runners:
  podAnnotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9252"

# Ver si el runner manager expone métricas:
kubectl port-forward -n gitlab-runners deployment/gitlab-k8s-runner 9252:9252 &
curl -s http://localhost:9252/metrics | grep gitlab_runner | head -20
```

---

⬅️ **Práctica anterior:** [03 — Tags y Routing](../03-tags-y-routing/README.md)
➡️ **Proyecto:** [Proyecto Semana 07](../../3-proyecto/README.md)

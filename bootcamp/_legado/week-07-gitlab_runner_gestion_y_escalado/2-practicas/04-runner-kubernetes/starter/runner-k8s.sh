# ============================================
# Practica 04 — Runner en Kubernetes
# ============================================
# Requiere: kubectl + Helm + cluster K8s (minikube/kind)
# NOTA: Esta practica es OPCIONAL si no tienes K8s.

echo "=== Practica 04: Runner en Kubernetes ==="
echo ""

# ── PASO 1: Verificar conexion a K8s ──
echo "--- Paso 1: Verificar cluster ---"
# kubectl cluster-info
# kubectl get nodes
echo ""

# ── PASO 2: Instalar con Helm ──
echo "--- Paso 2: Instalar GitLab Runner via Helm ---"
# helm repo add gitlab https://charts.gitlab.io
# helm repo update
# helm upgrade --install gitlab-runner gitlab/gitlab-runner \
#   --namespace gitlab-runners \
#   --create-namespace \
#   --set runnerRegistrationToken="TU_TOKEN" \
#   --set rbac.create=true \
#   --set runners.tags="kubernetes,k8s" \
#   --set runners.image="alpine:latest" \
#   --set concurrent=4
echo ""

# ── PASO 3: Verificar despliegue ──
echo "--- Paso 3: Verificar pods ---"
# kubectl get pods -n gitlab-runners
# kubectl logs -n gitlab-runners deployment/gitlab-runner
echo ""

# ── PASO 4: Crear pipeline que use runner K8s ──
cat << 'YAML'
# Copia a .gitlab-ci.yml en tu proyecto:
k8s-job:
  stage: test
  tags: [kubernetes, k8s]
  image: alpine:latest
  script:
    - echo "Ejecutando en Kubernetes!"
    - hostname
    - cat /etc/os-release | head -2
    - env | grep KUBERNETES
YAML
echo ""

# ── PASO 5: Commit, push y verificar ──
echo "--- Paso 5: Ejecutar pipeline ---"
echo "git add .gitlab-ci.yml && git commit -m 'ci: test runner k8s' && git push"
echo "CI/CD → Pipelines → Ver logs del job k8s-job"
echo ""

echo "=== Practica 04 completada ==="

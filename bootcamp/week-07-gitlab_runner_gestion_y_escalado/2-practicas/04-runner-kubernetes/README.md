# Practica 04 — Runner en Kubernetes

## Nota

Esta practica requiere un cluster Kubernetes. Si no tienes uno, puedes usar Minikube o kind.

## Objetivo

Desplegar GitLab Runner en Kubernetes usando Helm y ejecutar jobs en pods.

## Instrucciones

### Paso 1: Instalar con Helm

```bash
helm repo add gitlab https://charts.gitlab.io
helm repo update

helm upgrade --install gitlab-runner gitlab/gitlab-runner \
  --namespace gitlab-runners \
  --create-namespace \
  --set runnerRegistrationToken="TU_TOKEN_AQUI" \
  --set rbac.create=true \
  --set runners.tags="kubernetes,k8s" \
  --set runners.image="alpine:latest" \
  --set concurrent=4
```

### Paso 2: Verificar el despliegue

```bash
kubectl get pods -n gitlab-runners
kubectl logs -n gitlab-runners deployment/gitlab-runner
```

### Paso 3: Pipeline para Kubernetes

```yaml
k8s-job:
  stage: test
  tags:
    - kubernetes
    - k8s
  image: alpine:latest
  script:
    - echo "Ejecutando en Kubernetes"
    - cat /etc/os-release | head -1
    - hostname
    - echo "Pod info:"
    - env | grep KUBERNETES
```

### Paso 4: Configuracion avanzada

Helm values para recursos y afinidad:

```yaml
# values.yaml
runners:
  tags: "kubernetes,k8s,medium"
  builds:
    cpuLimit: "2"
    memoryLimit: "4Gi"
    cpuRequests: "500m"
    memoryRequests: "1Gi"
  nodeSelector:
    ci: "true"
  tolerations:
    - key: "ci"
      operator: "Equal"
      value: "true"
      effect: "NoSchedule"
```

## Verificacion

- [ ] Runner aparece en la UI de GitLab (Settings → CI/CD → Runners)
- [ ] El job `k8s-job` se ejecuta exitosamente
- [ ] Los pods se crean y destruyen automaticamente
- [ ] `kubectl get pods -n gitlab-runners` muestra pods de jobs completados

## Reto adicional

Configura `podAnnotations` para integracion con sistemas de monitoreo y `affinity` para scheduling especifico en el cluster.

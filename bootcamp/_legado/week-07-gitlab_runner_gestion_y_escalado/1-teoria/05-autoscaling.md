# 📖 05 — Autoscaling de Runners

## 🎯 Objetivos de aprendizaje

- ✅ Entender el problema que resuelve el autoscaling y cuándo aplicarlo
- ✅ Conocer la arquitectura moderna de autoscaling con Fleeting
- ✅ Distinguir el autoscaling de runners del autoscaling de Kubernetes
- ✅ Identificar los parámetros clave: `max_instances`, `idle_time`, `capacity_per_instance`
- ✅ Reconocer que Docker Machine está deprecado y no debe usarse en instalaciones nuevas
- ✅ Comparar el Helm chart y el GitLab Runner Operator para instalar runners en Kubernetes

---

## 🤔 El Problema de la Capacidad Fija

Un equipo con 2 runners fijos enfrenta dos problemas opuestos:

**Infra-provisionamiento (muy pocos runners):**
```
Lunes 9am (todos hacen push al iniciar la jornada):
  Job 1 → runner-01  (corriendo)
  Job 2 → runner-02  (corriendo)
  Job 3 → PENDING    ← espera 8 minutos
  Job 4 → PENDING    ← espera 16 minutos
  Job 5 → PENDING    ← espera 24 minutos
```

**Sobre-provisionamiento (demasiados runners):**
```
Sábado 3am (nadie trabaja):
  runner-01 → idle (pagando por la instancia EC2)
  runner-02 → idle (pagando por la instancia EC2)
  runner-03 → idle (pagando por la instancia EC2)
  ... 10 runners idle = dinero desperdiciado
```

**Autoscaling resuelve ambos:** crea runners bajo demanda y los destruye cuando no se usan.

---

## 🏗️ GitLab Runner Autoscaler (Fleeting)

Desde GitLab Runner 15.8+ (2023), el **GitLab Runner Autoscaler** con **Fleeting** es la solución oficial y moderna. Reemplaza el deprecado Docker Machine.

### Componentes

| Componente | Rol |
|-----------|-----|
| **Runner Manager** | Proceso principal; coordina el autoscaling, gestiona la cola |
| **Fleeting Plugin** | Interfaz con el proveedor cloud (AWS, GCP, Azure) |
| **Worker instances** | VMs o contenedores donde corren los jobs |

### Flujo de autoscaling

1. Runner Manager detecta un job en cola
2. Si no hay workers disponibles y `max_instances` no se alcanzó → solicita nueva instancia al plugin
3. Fleeting plugin crea la instancia en el cloud (EC2, VM, pod)
4. La instancia se registra como worker temporal
5. El job se ejecuta en la instancia
6. Si la instancia está idle por más de `idle_time` → Fleeting la destruye

---

## ⚙️ Configuración con Fleeting (AWS EC2)

```toml
# config.toml del Runner Manager

concurrent = 50          # máximo de jobs totales simultáneos

[[runners]]
  name = "autoscaler-aws"
  url = "http://gitlab.example.com"
  token = "glrt-XXXXXXXX"
  executor = "docker-autoscaler"   # ← executor especial para autoscaling

  [runners.docker]
    image = "alpine:latest"

  [runners.autoscaler]
    plugin = "fleeting-plugin-aws"         # ← plugin de AWS
    capacity_per_instance = 2              # jobs por instancia simultáneos
    max_instances = 20                     # máximo de instancias en el pool
    max_use_count = 100                    # jobs máximos por instancia (luego se destruye)
    idle_count = 2                         # mantener 2 instancias idle siempre
    idle_time = "30m"                      # destruir instancias idle tras 30 minutos

    [runners.autoscaler.connector_config]
      username = "ec2-user"
      use_external_addr = true

    [runners.autoscaler.plugin_config]
      # Configuración específica del plugin AWS
      name = "gitlab-autoscaler-asg"       # Auto Scaling Group de AWS
      region = "us-east-1"
```

### Configuración con Fleeting (GCP)

```toml
[[runners]]
  executor = "docker-autoscaler"
  [runners.autoscaler]
    plugin = "fleeting-plugin-googlecompute"
    max_instances = 10
    idle_time = "20m"
    [runners.autoscaler.plugin_config]
      project = "mi-proyecto-gcp"
      zone = "us-central1-a"
      instance_group = "gitlab-runners-mig"   # Managed Instance Group
```

---

## ☸️ Kubernetes Executor como Autoscaling

El **Kubernetes Executor** es otra forma de autoscaling, aprovechando el Cluster Autoscaler del proveedor cloud. Cada job es un pod efímero — K8s escala los nodos automáticamente.

```toml
[[runners]]
  name = "k8s-autoscaling"
  executor = "kubernetes"
  [runners.kubernetes]
    namespace = "gitlab-runners"
    image = "alpine:latest"
    
    # Recursos por pod (job)
    cpu_request = "500m"
    cpu_limit = "2"
    memory_request = "512Mi"
    memory_limit = "4Gi"
    
    # Solo pods en nodos marcados para CI
    [runners.kubernetes.node_selector]
      "cloud.google.com/gke-nodepool" = "ci-pool"
    
    # Spot/preemptibles para reducir costos
    [runners.kubernetes.pod_annotations]
      "cloud.google.com/gke-spot" = "true"
```

**Diferencia vs Fleeting:**

| Característica | Fleeting | Kubernetes Executor |
|---------------|---------|---------------------|
| **Qué escala** | VMs/instancias del cloud | Pods dentro de K8s |
| **Quién gestiona el cluster** | El plugin Fleeting | El proveedor cloud (GKE, EKS, AKS) |
| **Tiempo de arranque** | 1-3 minutos (VM boot) | 10-60 segundos (pod scheduling) |
| **Granularidad** | Instancias (múltiples jobs) | Pods (un job por pod) |
| **Mejor para** | Workloads con Docker/Shell | Workloads containerizados a escala |

---

## ⚓ GitLab Runner Operator (Kubernetes)

La práctica [04 — Runner en Kubernetes](../2-practicas/04-runner-kubernetes/README.md) instala el runner con el **Helm chart** oficial (`gitlab/gitlab-runner`). Existe una segunda forma de instalación en clusters Kubernetes: el **GitLab Runner Operator**, basado en el patrón [Kubernetes Operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) y distribuido via [Operator Lifecycle Manager (OLM)](https://olm.operatorframework.io/).

**Diferencia de fondo:** el Helm chart instala recursos K8s una vez y los actualiza cuando corres `helm upgrade` manualmente. El Operator añade un **controlador** que vigila un recurso personalizado (`Runner`) en el cluster y reconcilia continuamente el estado real contra el estado deseado — si alguien borra el Deployment del runner a mano, el Operator lo vuelve a crear.

### Instalación con OLM

```bash
# ¿QUÉ HACE?: Instala Operator Lifecycle Manager y suscribe el GitLab Runner Operator
# ¿POR QUÉ?: El Operator se distribuye via OperatorHub, que requiere OLM en el cluster
# ¿PARA QUÉ?: Tener el controlador del Operator corriendo antes de crear runners como CRs

# Instalar OLM (si el cluster no lo trae, como en OpenShift)
curl -sL https://github.com/operator-framework/operator-lifecycle-manager/releases/latest/download/install.sh | bash -s

# Namespace dedicado para el runner
kubectl create namespace gitlab-runner-system

# Suscribirse al operator desde OperatorHub (canal "stable")
kubectl apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: gitlab-runner-operator
  namespace: gitlab-runner-system
spec:
  channel: stable
  name: gitlab-runner-operator
  source: operatorhubio-catalog
  sourceNamespace: olm
EOF

# Verificar que el controlador quedó Running
kubectl get pods -n gitlab-runner-system
```

> **OpenShift:** el Operator viene certificado y disponible desde el OperatorHub embebido en la consola — no requiere instalar OLM manualmente, ya está incluido en la plataforma.

### El recurso personalizado `Runner`

Con el Operator corriendo, un runner se declara como un manifiesto Kubernetes, no como un `helm install`:

```yaml
# ¿QUÉ HACE?: Declara un runner de GitLab como recurso nativo de Kubernetes
# ¿POR QUÉ?: El Operator reconcilia este CR y crea/actualiza el Deployment, RBAC y ConfigMap asociados
# ¿PARA QUÉ?: Gestionar runners con GitOps (kubectl apply / ArgoCD / Flux) en vez de comandos imperativos

apiVersion: v1
kind: Secret
metadata:
  name: gitlab-runner-secret
  namespace: gitlab-runner-system
type: Opaque
stringData:
  runner-token: "glrt-XXXXXXXXXX"   # ← authentication token del runner (Paso 1 de la práctica 04)
---
apiVersion: apps.gitlab.com/v1beta2
kind: Runner
metadata:
  name: bootcamp-operator-runner
  namespace: gitlab-runner-system
spec:
  gitlabUrl: https://gitlab.example.com
  buildImage: alpine:latest
  token: gitlab-runner-secret       # ← referencia al Secret, no el token en texto plano
  tags: kubernetes,operator,bootcamp
  runUntagged: false
  concurrent: 4
```

```bash
kubectl apply -f runner.yaml

# El Operator crea el Deployment, ServiceAccount y RBAC automáticamente
kubectl get runner -n gitlab-runner-system
kubectl get deployment -n gitlab-runner-system
```

### Helm chart vs Operator

| Aspecto | Helm Chart | Runner Operator |
|--------|-----------|-----------------|
| **Instalación** | `helm install` / `helm upgrade` | `kubectl apply` de un CR `Runner` |
| **Gestión del ciclo de vida** | Manual — vos ejecutás cada `upgrade` | Automática — el controlador reconcilia continuamente |
| **Recuperación ante drift** | No — si alguien borra el Deployment, queda borrado | Sí — el Operator lo vuelve a crear |
| **Múltiples runners** | Un `values.yaml` con lista `runners:`, o un release por runner | Un recurso `Runner` por runner, todos visibles con `kubectl get runner` |
| **Plataforma objetivo** | Cualquier cluster con Helm v3 | Certificado para OpenShift; funciona en K8s vanilla con OLM instalado |
| **Integración GitOps** | Posible (Helm + ArgoCD/Flux) pero indirecta | Nativa — el CR es el estado deseado |
| **Curva de aprendizaje** | Baja si el equipo ya usa Helm | Media — requiere entender OLM y CRDs |
| **Cuándo usarlo** | Equipos con Helm ya en su flujo, control fino de `values.yaml` | Clusters OpenShift, o equipos que ya gestionan todo su cluster con Operators y GitOps |

> **Regla práctica:** si tu organización ya está en OpenShift o gestiona infraestructura con Operators/GitOps, usa el Runner Operator. Si venís de un flujo Helm estándar y no necesitás reconciliación continua, el Helm chart es más simple y suficiente — es lo que se usó en la [práctica 04](../2-practicas/04-runner-kubernetes/README.md).

---

## ❌ Docker Machine — Deprecado (No usar)

> **IMPORTANTE:** Docker Machine fue deprecado en **GitLab 14.0 (2021)** y eliminado del soporte oficial en **GitLab Runner 15.0 (2022)**. Si ves configuraciones con `executor = "docker+machine"` en documentación antigua, ignóralas.

Las instalaciones existentes con Docker Machine deben **migrar a Fleeting**. No iniciar nuevas instalaciones con Docker Machine.

```toml
# ❌ LEGACY — NO USAR en instalaciones nuevas
[[runners]]
  executor = "docker+machine"   # ← deprecado
  [runners.machine]
    MachineDriver = "amazonec2"
    # ...
```

---

## 💡 Buenas Prácticas de Autoscaling

**Dimensionar correctamente:**
- `idle_count = 0` → máximo ahorro, arranque más lento (VM boot)
- `idle_count = 2-5` → balance entre costo y latencia de arranque

**Control de costos:**
- Configurar `max_instances` para evitar sorpresas en la factura cloud
- Usar instancias Spot/Preemptibles (`max_use_count` pequeño para manejar interrupciones)
- Establecer alertas de billing cuando el número de instancias supere un umbral

**Seguridad:**
- Las instancias efímeras (`max_use_count`) reducen el riesgo de estado acumulado entre jobs
- Usar IAM roles con permisos mínimos para el plugin de autoscaling
- Separar el pool de runners de producción del de desarrollo

**Observabilidad:**
- GitLab Runner expone métricas Prometheus en el puerto 9252
- Monitorear: número de instancias activas, tiempo de cola, tasa de errores

```bash
# ¿QUÉ HACE?: Consulta las métricas del runner en formato Prometheus
# ¿POR QUÉ?: Para detectar problemas de autoscaling antes de que impacten a usuarios
# ¿PARA QUÉ?: Integrar con Grafana/AlertManager para alertas de capacidad

curl --silent http://localhost:9252/metrics \
  | grep -E "gitlab_runner_(jobs|workers|concurrent)" \
  | grep -v "^#"
```

---

## 🤔 Preguntas de reflexión

1. Con `idle_count = 0` e `idle_time = "10m"`, el primer job del día tarda 3 minutos extra en arrancar (VM boot). ¿Cuándo justifica el costo de mantener instancias idle? ¿Cómo calcularías el break-even entre costo de instancias idle vs tiempo perdido por developers?

2. `max_use_count = 100` significa que cada instancia se destruye después de 100 jobs. ¿Por qué destruir instancias que "siguen funcionando"? ¿Qué problema evita la destrucción periódica de workers?

3. La diferencia entre Fleeting y Kubernetes Executor es el nivel de abstracción. ¿En qué escenario usarías Fleeting sobre Kubernetes? ¿Y Kubernetes sobre Fleeting?

4. Un runner con autoscaling usa instancias Spot de AWS. AWS puede interrumpir estas instancias con 2 minutos de aviso. ¿Qué pasa con un job que llevaba 45 minutos corriendo cuando la instancia se interrumpe? ¿Cómo mitigas esto?

5. El Cluster Autoscaler de Kubernetes escala nodos cuando los pods no caben. Si tienes `cpu_request = "500m"` por pod y los nodos tienen 4 CPUs, ¿cuántos jobs en paralelo puedes tener por nodo? ¿Cómo cambiaría esto con `cpu_request = "2"`?

6. El Runner Operator reconcilia continuamente el CR `Runner` contra el estado real del cluster, mientras que el Helm chart solo actualiza cuando corrés `helm upgrade`. ¿Qué ventaja de confiabilidad da la reconciliación continua? ¿Qué riesgo introduce si alguien edita el Deployment generado directamente en vez de editar el CR?

---

## 📚 Recursos adicionales

- [GitLab Runner Autoscaler (Fleeting)](https://docs.gitlab.com/runner/runner_autoscale/)
- [Fleeting — Introducción](https://docs.gitlab.com/runner/fleet_scaling/fleeting.html)
- [Fleeting Plugin AWS](https://gitlab.com/gitlab-org/fleeting/plugins/aws)
- [Fleeting Plugin GCP](https://gitlab.com/gitlab-org/fleeting/plugins/googlecompute)
- [Kubernetes Executor](https://docs.gitlab.com/runner/executors/kubernetes/)
- [Migrar de Docker Machine a Fleeting](https://docs.gitlab.com/runner/runner_autoscale/migrate_from_docker_machine.html)
- [GitLab Runner Operator](https://docs.gitlab.com/runner/install/operator.html)
- [Operator Lifecycle Manager (OLM)](https://olm.operatorframework.io/)

---

⬅️ **Lección anterior:** [04 — Tags y Job Routing](./04-tags-y-job-routing.md)
➡️ **Siguiente lección:** [06 — Monitoreo de Flota y Costos](./06-monitoreo-y-costos-de-flota.md)

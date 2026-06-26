# 📖 05 — Autoscaling de Runners

## 🎯 Objetivos de aprendizaje

- ✅ Entender el problema que resuelve el autoscaling y cuándo aplicarlo
- ✅ Conocer la arquitectura moderna de autoscaling con Fleeting
- ✅ Distinguir el autoscaling de runners del autoscaling de Kubernetes
- ✅ Identificar los parámetros clave: `max_instances`, `idle_time`, `capacity_per_instance`
- ✅ Reconocer que Docker Machine está deprecado y no debe usarse en instalaciones nuevas

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

---

## 📚 Recursos adicionales

- [GitLab Runner Autoscaler (Fleeting)](https://docs.gitlab.com/runner/runner_autoscale/)
- [Fleeting — Introducción](https://docs.gitlab.com/runner/fleet_scaling/fleeting.html)
- [Fleeting Plugin AWS](https://gitlab.com/gitlab-org/fleeting/plugins/aws)
- [Fleeting Plugin GCP](https://gitlab.com/gitlab-org/fleeting/plugins/googlecompute)
- [Kubernetes Executor](https://docs.gitlab.com/runner/executors/kubernetes/)
- [Migrar de Docker Machine a Fleeting](https://docs.gitlab.com/runner/runner_autoscale/migrate_from_docker_machine.html)

---

⬅️ **Lección anterior:** [04 — Tags y Job Routing](./04-tags-y-job-routing.md)
➡️ **Prácticas:** [01 — Instalar Runner](../2-practicas/01-instalar-runner/README.md)

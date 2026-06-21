# 05 — Autoscaling de Runners

## Por que autoscaling

En entornos con carga variable, tener runners fijos genera:
- **Infra-provisionamiento**: Colas largas en picos de demanda
- **Sobre-provisionamiento**: Recursos ociosos la mayor parte del tiempo

## GitLab Runner Autoscaler

Desde GitLab Runner 15.0, el `GitLab Runner Autoscaler` es la solucion moderna.

### Arquitectura
- **Runner Manager**: Orquesta la creacion/destruccion de workers
- **Fleeting Plugin**: Interfaz con el proveedor cloud
- **Workers**: Instancias que ejecutan los jobs

### Soporte de proveedores
- AWS EC2 / ECS Fargate
- Google Cloud Compute Engine
- Azure Virtual Machines
- Kubernetes

### Configuracion conceptual
```toml
[[runners]]
  executor = "docker-autoscaler"
  [runners.docker]
    image = "alpine:latest"
  [runners.autoscaler]
    plugin = "fleeting-plugin-aws"
    capacity_per_instance = 2
    max_instances = 10
    max_use_count = 100
    idle_time = "30m"
    [runners.autoscaler.plugin_config]
      # Configuracion especifica del plugin
```

## Docker Machine (Legacy - Deprecado)

GitLab 14.0 marco Docker Machine como deprecado. Se recomienda migrar al Autoscaler.

```toml
# Configuracion legacy con Docker Machine
[[runners]]
  executor = "docker+machine"
  [runners.machine]
    MachineDriver = "amazonec2"
    MachineOptions = [
      "amazonec2-region=us-east-1",
      "amazonec2-instance-type=t3.medium"
    ]
    IdleCount = 0
    IdleTime = 1800
    MaxBuilds = 100
```

## Kubernetes Executor con autoscaling

El executor de Kubernetes escala automaticamente con el Cluster Autoscaler del proveedor:

```toml
[[runners]]
  executor = "kubernetes"
  [runners.kubernetes]
    namespace = "gitlab-runners"
    cpu_request = "500m"
    cpu_limit = "2"
    memory_request = "512Mi"
    memory_limit = "4Gi"
```

## Buenas practicas de autoscaling
- Configurar `idle_time` para evitar costos innecesarios
- Usar instancias spot/preemptibles para jobs no criticos
- Limitar `max_instances` para controlar costos
- Monitorear con `gitlab-runner status` y metricas

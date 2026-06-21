# 02 — Ejecutores (Executors)

Los ejecutores definen el entorno donde se ejecuta cada job.

## Docker Executor

El mas usado. Cada job se ejecuta en un contenedor Docker nuevo.

**config.toml:**
```toml
[[runners]]
  executor = "docker"
  [runners.docker]
    image = "alpine:latest"
    privileged = false
    volumes = ["/cache"]
```

Ventajas:
- Aislamiento completo entre jobs
- Facil manejo de dependencias via imagenes
- Soporte para servicios (bases de datos, etc.)
- Limpieza automatica

Desventajas:
- Overhead de crear contenedores
- Docker-in-Docker requiere privilegios
- No accede directamente al filesystem del host

## Shell Executor

Ejecuta comandos directamente en la shell del host.

```toml
[[runners]]
  executor = "shell"
```

Ventajas:
- Sin overhead de contenedores
- Acceso completo al filesystem del host
- Simple de configurar

Desventajas:
- Sin aislamiento (los jobs comparten entorno)
- Dependencias deben instalarse en el host manualmente
- Riesgo de seguridad (jobs pueden afectar al host)

## Kubernetes Executor

Cada job se ejecuta en un pod dentro de un cluster Kubernetes.

```toml
[[runners]]
  executor = "kubernetes"
  [runners.kubernetes]
    namespace = "gitlab-runners"
    [runners.kubernetes.node_selector]
      ci = "true"
```

Ventajas:
- Escalabilidad nativa de Kubernetes
- Aislamiento a nivel de pod
- Gestion de recursos con requests/limits

## Otros ejecutores
- **VirtualBox**: Jobs en VMs VirtualBox
- **Parallels**: Jobs en VMs Parallels (macOS)
- **SSH**: Ejecuta comandos via SSH en un servidor remoto
- **Docker Machine**: Creacion dinamica de VMs (legacy, reemplazado por autoscaling)
- **Instance**: Para GitLab Runner Manager en modo autoscaling

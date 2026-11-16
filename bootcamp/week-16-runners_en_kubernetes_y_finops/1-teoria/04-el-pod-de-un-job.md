# El pod de un job

> Con el ejecutor `docker`, un job era un contenedor y lo que gastaba no lo decía nadie. En Kubernetes, un job es un pod con varios contenedores, y cada uno declara cuánta CPU y memoria reserva y cuánta puede usar como máximo. Esas dos cifras deciden si el pod cabe en un nodo, cuántos caben a la vez, y qué hace el job cuando no cabe.

---

## 🎯 Objetivos

- Reconocer los contenedores de un pod de job y qué hace cada uno
- Fijar `requests` y `limits` para todos los jobs desde `[runners.kubernetes]`
- Dejar que un job pida más memoria, hasta un techo, con `KUBERNETES_MEMORY_REQUEST`
- Saber qué pasa cuando un pod no cabe en ningún nodo

---

## 1. Qué problema resuelve

Sin `requests`, el clúster programa los pods como si no gastaran nada: mete diez en un nodo con memoria para cuatro, y el kernel mata al que más gasta en mitad de un `npm install`. Sin `limits`, un job con una fuga de memoria se come el nodo, y con él los otros jobs que corren ahí. Los dos números son el contrato entre el job y el clúster.

---

## 2. Cómo funciona

### 2.1 Qué hay en el pod

Un pod de job de `app`, visto con `kubectl get pod <pod> -o json`:

| Contenedor | Imagen | Qué hace |
|---|---|---|
| `init-permissions` (init) | La del `helper` | Ajusta los permisos del directorio de trabajo antes de que arranque nada |
| `build` | La del job (`node:22.23.3-alpine3.24`) | Ejecuta `before_script`, `script` y `after_script` |
| `helper` | `registry.gitlab.com/gitlab-org/gitlab-runner/gitlab-runner-helper:x86_64-v19.2.2` | Clona, restaura y sube la caché, sube los artefactos |
| Uno por servicio, con el nombre de su `alias` | La de cada `services:` | Los servicios del job. Comparten red con `build`: se llega a ellos por `localhost` o por su alias |

Todos comparten el volumen del directorio del proyecto. El pod lleva la cuenta de servicio `default` del namespace, no la del gestor: el `script` de un job no puede crear pods.

### 2.2 `requests` y `limits`

```toml
[runners.kubernetes]
  cpu_request = "100m"
  memory_request = "128Mi"
  memory_limit = "1Gi"
  helper_memory_request = "32Mi"
```

| Valor | Qué significa | Si se pasa |
|---|---|---|
| `memory_request = "128Mi"` | El clúster reserva 128 MiB para `build` al elegir nodo | — (es una reserva, no un tope) |
| `memory_limit = "1Gi"` | `build` no puede pasar de 1 GiB | El kernel mata el proceso: `OOMKilled`, el job falla |
| `cpu_request = "100m"` | Una décima de CPU reservada | — |
| Sin `cpu_limit` | Puede usar toda la CPU libre del nodo | — (la CPU se reparte, no mata) |

Hay claves equivalentes para el `helper` (`helper_cpu_request`, `helper_memory_limit`…) y para los servicios (`service_memory_request`…).

### 2.3 Un job que pide más

Un job puede cambiar sus cifras con variables, **solo** si el runner pone un techo:

```toml
[runners.kubernetes]
  memory_request_overwrite_max_allowed = "2Gi"
  memory_limit_overwrite_max_allowed = "2Gi"
```

```yaml
test-pesado:
  variables:
    KUBERNETES_MEMORY_REQUEST: 1536Mi
    KUBERNETES_MEMORY_LIMIT: 2Gi
```

| Combinación | Resultado, comprobado en el lab |
|---|---|
| Sin `*_overwrite_max_allowed` en el runner | La variable se ignora sin avisar: el pod sale con el `cpu_request` del runner |
| Con techo | El log lo dice: `"MemoryRequest" overwritten with "1536Mi"` |
| `KUBERNETES_MEMORY_REQUEST` mayor que `memory_limit` | El pod es inválido: `requests: Invalid value: "48Gi": must be less than or equal to memory limit of 1Gi`. El job falla al momento |
| Request y limit dentro del techo, pero ningún nodo con sitio | El pod se queda en `Pending` (siguiente apartado) |

### 2.4 Cuando no cabe

El gestor crea el pod y espera a que arranque. Si el planificador no encuentra nodo, el log lo cuenta:

```
Unschedulable: "0/2 nodes are available: 2 Insufficient memory. …"
ERROR: Job failed (system failure): prepare environment: waiting for pod running: timed out waiting for pod to start (last phase: Pending)
```

El tiempo de espera es `poll_timeout` (180 s por defecto). El job termina con `failure_reason: runner_system_failure`: no es tu `script` el que ha fallado. En un clúster con autoescalado de nodos, esos 180 s son el margen para que llegue un nodo nuevo (teoría 05).

---

## 3. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Sin `memory_request` | El clúster no sabe cuánto ocupa un job y apila demasiados | Un `request` medido: lo que gasta el job típico |
| `memory_limit` igual a la memoria del nodo | Un job descontrolado tumba los demás pods del nodo | Un techo por job; el que necesite más, lo pide (apartado 2.3) |
| `*_overwrite_max_allowed` sin límite real | Cualquier job pide 48 GiB y se queda en `Pending` tres minutos | El techo que el nodo puede dar |
| Leer `runner_system_failure` como "GitLab falla" | El fallo está en el clúster: sitio, imagen o permisos | Leer la línea `Unschedulable`/`Invalid value` del log |

---

## 4. Trucos

- `kubectl -n gitlab-runner get events --sort-by=.lastTimestamp | tail` enseña por qué un pod no arranca antes de que el job falle.
- `kubectl -n gitlab-runner top pod` (con `metrics-server`, que k3s trae activo) da el consumo real de un job: es el número para fijar `memory_request`.

---

## 📚 Recursos Adicionales

- [Kubernetes executor — CPU and memory requests and limits](https://docs.gitlab.com/runner/executors/kubernetes/#cpu-requests-and-limits)
- [Overwrite container resources](https://docs.gitlab.com/runner/executors/kubernetes/#overwrite-container-resources)
- [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

---

## ✅ Checklist de Verificación

- [ ] Sé qué contenedores tiene un pod de job y cuál ejecuta el `script`
- [ ] Sé la diferencia entre `memory_request` y `memory_limit`, y qué pasa al pasar el límite
- [ ] Sé qué necesita el runner para que un job pida más memoria
- [ ] Sé qué significa `runner_system_failure` con `Insufficient memory` en el log

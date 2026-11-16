# Los ejecutores

> El ejecutor decide **dónde** corre un job: en la misma máquina que el runner, en un contenedor de usar y tirar, en una máquina virtual nueva o en un pod. Esa decisión es, antes que nada, una decisión de seguridad: lo que un job puede tocar es lo que su ejecutor no aísla. La velocidad y la comodidad vienen después.

---

## 🎯 Objetivos

- Conocer los ejecutores de GitLab Runner y qué aísla cada uno
- Elegir ejecutor por lo que el job necesita y por lo que no debe poder tocar
- Saber por qué este bootcamp usa `docker` hoy y `kubernetes` la semana que viene
- Reconocer los ejecutores obsoletos para no construir encima de ellos

---

## 1. Qué problema resuelve

Un job es código de una rama. En `app`, cualquiera con rol Developer puede abrir una rama, cambiar `.gitlab-ci.yml` y hacer que el runner ejecute lo que quiera. La pregunta no es si confías en tus compañeros: es **qué alcanza ese código si se equivoca o si alguien lo envenena**.

| Si el ejecutor es… | El `script` del job puede… |
|---|---|
| `shell` | Leer `config.toml` con los tokens de todos los runners, el `~/.ssh` del usuario `gitlab-runner` y lo que haya dejado el job anterior |
| `docker` sin privilegios | Lo que haya dentro de su contenedor, la red que le des y los volúmenes que montes |
| `docker` con `privileged = true` | Prácticamente todo el host: montar discos, cargar módulos del kernel, ver otros contenedores (teoría 06) |
| `kubernetes` | Lo que permitan el pod, su cuenta de servicio y las políticas del clúster |

---

## 2. Cómo funciona

### 2.1 El catálogo

| Ejecutor | Dónde corre el job | Aislamiento | Cuándo tiene sentido |
|---|---|---|---|
| `shell` | En el host del runner, como el usuario del proceso | Ninguno | Un runner dedicado a una sola máquina que el job tiene que tocar (por ejemplo, un equipo con hardware especial) |
| `ssh` | En otra máquina, por SSH | Ninguno en esa máquina | Casi nunca: no admite caché ni imágenes, y es el ejecutor menos mantenido |
| `docker` | Un contenedor nuevo por job, en el Docker del host | El de un contenedor | **El de este bootcamp**: reproducible, barato, imagen por job |
| `docker-autoscaler` | Contenedores en máquinas virtuales que se crean y destruyen según la cola | Contenedor más una VM que no se comparte con otros proyectos si así se configura | Flotas en la nube con colas variables |
| `instance` | Directamente en una VM de autoescalado, sin contenedor | La VM entera | Jobs que necesitan una máquina completa |
| `kubernetes` | Un pod por job | El del pod y las políticas del clúster | Cuando ya hay clúster (Semana 16) |
| `custom` | Lo que hagan tus scripts `prepare`, `run` y `cleanup` | El que construyas | Plataformas que GitLab no soporta |
| `virtualbox`, `parallels` | Una VM local clonada por job | La VM | Builds de escritorio, sobre todo macOS |
| `docker+machine` | Contenedores en VM creadas con Docker Machine | Como `docker-autoscaler` | **Obsoleto**: Docker Machine ya no se mantiene. Su sustituto es `docker-autoscaler` |

Los dos de autoescalado (`docker-autoscaler`, `instance`) necesitan un plugin de *fleeting* para el proveedor de máquinas (AWS, GCP, Azure…). En un portátil no tienen sentido; en la Semana 16 el autoescalado lo pone Kubernetes.

### 2.2 El ejecutor `docker`, por dentro

Cada job con el ejecutor `docker` crea, en el Docker del host:

1. Un contenedor **auxiliar** (`gitlab-runner-helper`) que clona el repositorio, restaura la caché y descarga artefactos.
2. Un contenedor por cada `services:` del job, en la misma red.
3. El contenedor del **job**, con la imagen de `image:` o la de `[runners.docker] image` si el job no dice nada, y el directorio de trabajo compartido con el auxiliar.

Al terminar, el auxiliar sube la caché y los artefactos, y los tres se borran. Lo único que sobrevive de un job al siguiente es lo que montes como volumen (`volumes = ["/cache"]`) o lo que guardes en la caché remota (teoría 07).

```bash
# Con un job en marcha: los contenedores que ha creado el ejecutor
docker ps --filter "name=runner-" --format '{{.Names}}\t{{.Image}}' | cut -c1-110
# runner-…-project-2-concurrent-0-…-build                  sha256:… (la imagen del job)
# runner-…-project-2-concurrent-0-…-docker-0               docker:29.9.3-dind
```

### 2.3 El ejecutor y el Docker del host

En el compose, el contenedor `gitlab-runner` monta `/var/run/docker.sock`. Así crea los contenedores de los jobs **en el Docker de tu máquina**, como hermanos de GitLab, no dentro de sí mismo. Es lo que permite que `network_mode = "bc-gitlab-network"` meta a los jobs en la red del laboratorio, donde `gitlab`, `destino`, `registry-cache` y `cache-s3` se resuelven por nombre.

Tiene un precio que conviene decir en voz alta: **el proceso `gitlab-runner` controla el Docker del host**. Por eso el contenedor del runner no debe ejecutar código de nadie, y por eso el socket nunca se monta dentro del contenedor de un job (teoría 06).

---

## 3. Cómo se configura

El ejecutor se elige en `register` (`--executor docker`) y vive en `config.toml`. No se puede cambiar por API: es una decisión de quien opera la máquina, no de quien escribe el pipeline. Lo que sí ve la API es la plataforma del gestor:

```bash
glab api "runners/<id>/managers" | jq -c '.[] | {version, platform, architecture}'
# {"version":"19.2.2","platform":"linux","architecture":"amd64"}
```

Y lo que sí puede pedir el job es la imagen y los servicios, dentro de lo que permitan `allowed_images` y `allowed_services` del runner:

```toml
[runners.docker]
  image = "alpine:3.24.2"                       # la de los jobs que no dicen nada
  allowed_images = ["alpine:*", "node:*", "docker:*"]
  pull_policy = ["if-not-present"]
```

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| `shell` en la máquina donde corre GitLab | Cualquier rama lee `gitlab-secrets.json` si el usuario puede | `docker` en la misma máquina, o `shell` solo en una máquina dedicada |
| Elegir `shell` "porque es más rápido" | Se ahorran segundos y se pierde la reproducibilidad: cada job hereda lo que dejó el anterior | `docker` con `pull_policy = ["if-not-present"]` |
| Construir una flota nueva sobre `docker+machine` | Docker Machine está abandonado | `docker-autoscaler` |
| Sin `allowed_images` en un runner compartido por varios equipos | Cualquiera ejecuta cualquier imagen de Docker Hub en tu host | Lista de imágenes permitidas, o un registry propio |

---

## 5. Trucos

- `[runners.docker] pull_policy = ["always", "if-not-present"]` intenta siempre la imagen nueva y, si Docker Hub no responde, usa la que haya en local. En un laboratorio con `registry-cache`, `if-not-present` basta.
- Un job puede ver qué ejecutor y qué runner le tocaron: `CI_RUNNER_DESCRIPTION`, `CI_RUNNER_TAGS` y `CI_RUNNER_EXECUTABLE_ARCH` están en todos los jobs.

---

## 📚 Recursos Adicionales

- [Executors](https://docs.gitlab.com/runner/executors/) — la tabla de compatibilidad completa
- [Docker executor](https://docs.gitlab.com/runner/executors/docker/)
- [Docker Autoscaler executor](https://docs.gitlab.com/runner/executors/docker_autoscaler/)

---

## ✅ Checklist de Verificación

- [ ] Sé qué puede alcanzar el `script` de un job con `shell`, con `docker` y con `docker` privilegiado
- [ ] Sé qué tres contenedores crea el ejecutor `docker` para un job con un servicio
- [ ] Sé por qué los contenedores de los jobs son hermanos de GitLab y no hijos del runner
- [ ] Sé cuál es el sustituto de `docker+machine`

# 📖 02 — Docker Build en CI/CD

## 🎯 Objetivos de aprendizaje

- ✅ Entender por qué construir imágenes Docker dentro de CI requiere consideraciones especiales
- ✅ Implementar builds con Docker-in-Docker (DinD) y conocer sus riesgos
- ✅ Implementar builds con Kaniko como alternativa rootless y segura
- ✅ Conocer Buildah como tercera opción para entornos sin Docker daemon
- ✅ Elegir el método correcto según el executor y los requisitos de seguridad del entorno

---

## 🤔 El Problema: Docker Dentro de Docker

Un job de CI que necesita construir una imagen Docker tiene un problema conceptual: el job **ya corre dentro de un contenedor** (cuando usa Docker Executor). ¿Cómo construyes imágenes Docker desde dentro de un contenedor Docker?

```
Host del runner
  └── gitlab-runner (proceso)
        └── Contenedor del job (Docker Executor)
              └── quiero ejecutar: docker build -t mi-app .
                    → ¿qué Docker daemon usa? El del contenedor no existe por defecto.
```

Hay tres soluciones a este problema. Cada una tiene un tradeoff diferente de seguridad, velocidad y compatibilidad.

---

## 🐳 Método 1: Docker-in-Docker (DinD)

DinD levanta un daemon Docker **dentro** de un contenedor de servicio (`docker:dind`), al que el job se conecta para construir.

```yaml
docker-build-dind:
  stage: build
  image: docker:24-cli                   # cliente Docker
  services:
    - name: docker:24-dind               # daemon Docker como servicio
      alias: docker
  variables:
    DOCKER_HOST: tcp://docker:2375       # conectar al daemon del servicio
    DOCKER_TLS_CERTDIR: ""               # deshabilitar TLS (más simple para dev)
    DOCKER_DRIVER: overlay2
  before_script:
    # ¿QUÉ HACE?: Login al registry antes de construir
    # ¿POR QUÉ?: El push requiere autenticación; hacerlo en before_script por claridad
    # ¿PARA QUÉ?: Evitar errores "unauthorized" al hacer docker push
    - docker login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY
  script:
    - docker build
        --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        --build-arg COMMIT_SHA=$CI_COMMIT_SHORT_SHA
        -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
        -t $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
        .
    - docker push $CI_REGISTRY_IMAGE --all-tags
  tags:
    - docker
    - privileged                          # ← el runner DEBE tener privileged = true
```

**Requisito crítico:** el runner debe tener `privileged = true` en `config.toml`:

```toml
[[runners]]
  executor = "docker"
  [runners.docker]
    privileged = true      # necesario para DinD
```

> **Riesgo de seguridad:** `privileged = true` da al contenedor acceso casi total al host del runner — puede ver y modificar namespaces, montar filesystems del host, etc. Usar DinD solo en runners dedicados y controlados, nunca en shared runners de CI general.

**Ventajas:**
- Compatibilidad total con cualquier Dockerfile y feature de Docker Build
- Soporte nativo para multi-stage builds, build secrets, SSH forwarding
- Logs de build detallados e idénticos al build local

**Desventajas:**
- Requiere `privileged = true` — riesgo de seguridad significativo
- Overhead adicional por arrancar el daemon Docker dentro del job
- No funciona en Kubernetes Executor sin SecurityContext adicional

---

## ⚡ Método 2: Kaniko (Recomendado)

Kaniko construye imágenes Docker **sin Docker daemon** ni modo privilegiado. Lee el Dockerfile, ejecuta cada instrucción en el filesystem del contenedor, y sube la imagen resultante directamente al registry.

```yaml
kaniko-build:
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:v1.23.0-debug
    entrypoint: [""]                     # sobreescribir el entrypoint del imagen
  script:
    # ¿QUÉ HACE?: Configura autenticación al registry en formato JSON esperado por Kaniko
    # ¿POR QUÉ?: Kaniko no usa el docker CLI — necesita el archivo config.json directamente
    # ¿PARA QUÉ?: Que el executor pueda push al registry al terminar el build
    - mkdir -p /kaniko/.docker
    - |
      echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_JOB_TOKEN\"}}}" \
        > /kaniko/.docker/config.json

    - /kaniko/executor
        --context $CI_PROJECT_DIR
        --dockerfile $CI_PROJECT_DIR/Dockerfile
        --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
        --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
        --cache=true
        --cache-repo $CI_REGISTRY_IMAGE/cache
        --cache-ttl 168h                 # TTL del cache: 7 días
        --build-arg COMMIT_SHA=$CI_COMMIT_SHORT_SHA
        --compressed-caching=false       # más rápido en la mayoría de casos
```

**Cómo funciona el cache de Kaniko:**

```
Primera ejecución:
  FROM node:18-alpine           → capa nueva → sube a registry/cache
  RUN npm ci                    → capa nueva → sube a registry/cache
  COPY . .                      → capa nueva → sube a registry/cache

Segunda ejecución (solo cambió código fuente):
  FROM node:18-alpine           → cache HIT → no descarga ni sube
  RUN npm ci                    → cache HIT → no re-ejecuta npm ci
  COPY . .                      → cache MISS → capa nueva (código cambió)
```

El cache se almacena en el mismo registry, sin filesystem local del runner. Esto hace que el cache funcione incluso en runners efímeros (Kubernetes).

**Ventajas:**
- Sin `privileged = true` — funciona en cualquier executor incluido Kubernetes
- Cache en registry — persiste entre runners y es compartible entre proyectos
- Rootless por diseño — mejora postura de seguridad

**Desventajas:**
- No soporta todas las features de Docker Build (ej.: `docker buildx`, emulación de plataformas)
- No soporta `--secret` de BuildKit de la misma forma
- Más lento que DinD en algunos escenarios sin cache (cold start)

---

## 🔧 Método 3: Buildah

Buildah construye imágenes compatibles con OCI (el estándar de Docker) sin daemon, de forma rootless. Popular en entornos RHEL/OpenShift.

```yaml
buildah-build:
  stage: build
  image: quay.io/buildah/stable:latest
  variables:
    STORAGE_DRIVER: vfs                  # storage driver compatible con contenedores sin privilegios
  script:
    # ¿QUÉ HACE?: Login al registry usando buildah (no docker)
    - buildah login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY

    # ¿QUÉ HACE?: Construye la imagen directamente desde el Dockerfile
    - buildah bud
        --format oci
        --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
        --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
        --build-arg COMMIT_SHA=$CI_COMMIT_SHORT_SHA
        .

    # ¿QUÉ HACE?: Push al registry GitLab
    - buildah push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
    - buildah push $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
```

**Cuándo usar Buildah:**
- Entornos RHEL/CentOS/OpenShift donde Buildah es el estándar
- Cuando necesitas integración con Podman o el stack de herramientas OCI de Red Hat
- Proyectos que ya usan Buildah y no quieren añadir Kaniko

---

## 📊 Comparación de Métodos

| Característica | DinD | Kaniko | Buildah |
|---------------|------|--------|---------|
| **Privilegios requeridos** | `privileged = true` | Ninguno | Ninguno |
| **Docker daemon** | Sí (en servicio) | No | No |
| **Compatibilidad Dockerfile** | Total | Alta (95%+) | Alta (95%+) |
| **BuildKit / multi-platform** | Sí (nativo) | Limitado | Limitado |
| **Cache** | Local + Registry | Registry (compartido) | Local |
| **Kubernetes Executor** | Complejo (SecurityContext) | Nativo | Nativo |
| **Velocidad (warm cache)** | Alta | Alta | Alta |
| **Velocidad (cold start)** | Alta | Media | Alta |
| **Mantenedor** | Docker Inc. | Google | Red Hat |
| **Recomendación** | Legacy / compatible | **Nueva instalación** | RHEL/OpenShift |

---

## 🏗️ Multi-Stage Build

Los multi-stage builds reducen el tamaño de la imagen final separando el entorno de build del de runtime:

```dockerfile
# Stage 1: Build (tiene node_modules de desarrollo, compiladores, etc.)
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci                                # instala todo (dev + prod dependencies)
COPY src/ ./src/
RUN npm run build                         # compila TypeScript, bundlea assets, etc.

# Stage 2: Runtime (solo lo necesario para ejecutar)
FROM node:18-alpine AS runtime
WORKDIR /app
COPY --from=builder /app/dist ./dist      # solo el resultado del build
COPY --from=builder /app/node_modules/production ./node_modules  # solo deps de prod
EXPOSE 3000
USER node                                  # no correr como root
CMD ["node", "dist/server.js"]
```

**Impacto en tamaño:**
```
Sin multi-stage:  node:18-alpine + devDependencies + compiladores = ~450 MB
Con multi-stage:  node:18-alpine + solo dist/ + prod deps         =  ~95 MB
```

Tanto DinD como Kaniko y Buildah soportan multi-stage builds.

---

## 🖼️ Diagrama: Build Methods y Registry Flow

![Diagrama del flujo de Container Registry con métodos de build](../0-assets/01-container-registry-flow.svg)

> **Diagrama:** La sección inferior muestra la comparación de los tres métodos de build en CI: DinD (privileged, compatible completo), Kaniko★ (rootless, cache en registry — recomendado), y Buildah (rootless OCI, sin daemon). Las secciones superiores muestran el flujo build→push→pull y las estrategias de versionado que se aplican independientemente del método de build elegido.

---

## 🤔 Preguntas de reflexión

1. Tu runner usa Kubernetes Executor y el cluster NO permite pods con `securityContext.privileged: true` por política de seguridad. ¿Qué método de build eliges? ¿Qué cambias en el pipeline?

2. Kaniko almacena el cache en el mismo registry (`--cache-repo $CI_REGISTRY_IMAGE/cache`). Si 50 developers hacen push simultáneamente y todos tienen cache MISS en la capa `RUN npm ci`, ¿qué pasa con las escrituras simultáneas al cache? ¿Kaniko maneja race conditions?

3. Un Dockerfile tiene la instrucción `RUN --mount=type=secret,id=npm_token npm ci`. ¿Funciona con Kaniko? ¿Con DinD? ¿Por qué es importante soportar esta feature? (Pista: considera qué pasa con secretos en las capas de la imagen.)

4. Multi-stage build con `--from=builder` copia solo los archivos del stage anterior. ¿Qué pasa si el stage de build falla? ¿El stage de runtime se ejecuta de todos modos?

5. Un build con DinD tarda 8 minutos porque descarga la imagen base cada vez. ¿Cómo optimizarías esto sin cambiar a Kaniko? (Pista: considera `pull_policy` del runner y `--cache-from` en docker build.)

---

## 📚 Recursos adicionales

- [Kaniko — Build Images in Kubernetes](https://github.com/GoogleContainerTools/kaniko)
- [GitLab — Using Kaniko to build Docker images](https://docs.gitlab.com/ee/ci/docker/using_kaniko.html)
- [GitLab — Build Docker images with DinD](https://docs.gitlab.com/ee/ci/docker/using_docker_build.html)
- [Buildah Documentation](https://buildah.io/)
- [Docker Multi-stage builds](https://docs.docker.com/build/building/multi-stage/)

---

⬅️ **Lección anterior:** [01 — Container Registry](./01-container-registry.md)
➡️ **Siguiente lección:** [03 — Package Registry](./03-package-registry.md)

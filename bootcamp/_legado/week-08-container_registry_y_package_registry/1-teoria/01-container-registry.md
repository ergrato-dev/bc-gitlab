# 📖 01 — GitLab Container Registry

## 🎯 Objetivos de aprendizaje

- ✅ Entender qué es el Container Registry y cómo se integra con cada proyecto GitLab
- ✅ Habilitar y configurar el registry en GitLab CE (Omnibus y Docker)
- ✅ Autenticarse al registry con los tres métodos: PAT, CI Job Token, Deploy Token
- ✅ Construir, etiquetar y publicar imágenes manualmente y desde pipelines
- ✅ Gestionar imágenes y tags desde la UI y via API
- ✅ Configurar el Dependency Proxy de grupo para cachear imágenes de Docker Hub y evitar rate limits

---

## 🤔 ¿Por Qué un Registry Privado?

Docker Hub es público por defecto y tiene límites de pull (100 pulls/6h en plan free). Un registry privado integrado en GitLab resuelve esto:

**Sin Container Registry:**
```
Cada equipo tiene sus propias imágenes en diferentes lugares:
  Dev A → Docker Hub (público, limitado)
  Dev B → ECR en AWS (requiere credenciales AWS)
  CI/CD → Siempre descarga desde internet (lento)
  Prod → No sabe qué versión exacta está corriendo
```

**Con Container Registry de GitLab:**
```
registry.gitlab.example.com/mi-empresa/mi-app:a1b2c3d4
  ↑ URL del registry ↑  ↑ grupo/proyecto ↑  ↑ versión exacta
  
  → Privado (solo quien tiene acceso al proyecto puede pull)
  → Trazable (cada imagen vinculada al commit que la generó)
  → Rápido (en la misma red que GitLab, sin salir a internet)
  → Integrado (CI_REGISTRY_IMAGE, CI_JOB_TOKEN — sin configurar credenciales)
```

**Analogía:** El Container Registry es como una bodega privada de la empresa. Docker Hub es el supermercado público — cualquiera puede entrar, hay límites de cuánto llevas, y no controlas qué hay ahí. Tu bodega privada solo tiene lo tuyo, sabes exactamente qué versión tomaste, y nadie de fuera puede acceder.

---

## ⚙️ Activación en GitLab CE

### Instalación Omnibus

```ruby
# /etc/gitlab/gitlab.rb

# URL externa del registry (port 5050 por defecto si no tienes dominio separado)
registry_external_url 'http://localhost:5050'

# Con dominio separado (requiere configurar DNS y TLS):
# registry_external_url 'https://registry.mi-empresa.com'

# Puerto del proceso interno del registry
registry['registry_http_addr'] = "0.0.0.0:5000"
```

```bash
# Aplicar la configuración
sudo gitlab-ctl reconfigure

# Verificar que el servicio registry está corriendo
sudo gitlab-ctl status | grep registry

# Ver logs del registry
sudo gitlab-ctl tail registry
```

### Instalación Docker Compose

```yaml
# En gitlab-ce, el registry necesita variables de entorno:
services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://localhost'
        registry_external_url 'http://localhost:5050'
    ports:
      - "80:80"
      - "5050:5050"
```

### Verificar el registry

```bash
# ¿QUÉ HACE?: Comprueba que el registry responde con un 200
# ¿POR QUÉ?: El registry tiene su propia API V2 independiente de la API de GitLab
# ¿PARA QUÉ?: Confirmar activación antes de intentar push/pull

curl --silent http://localhost:5050/v2/
# Respuesta esperada: {} (body vacío, HTTP 200 o 401 si requiere auth)

# Con autenticación:
curl --silent --user "root:$GITLAB_TOKEN" http://localhost:5050/v2/
# {}
```

---

## 🔐 Autenticación

Hay tres métodos para autenticarse al Container Registry de GitLab:

### Método 1: Personal Access Token (acceso manual / externo)

```bash
# ¿QUÉ HACE?: Login al registry usando un PAT con scope read_registry o write_registry
# ¿POR QUÉ?: Para push/pull manual desde la terminal de un developer
# ¿PARA QUÉ?: Debugging, tests locales, push de imágenes base desde workstation

# Crear PAT en: User Settings → Access Tokens → Scopes: read_registry + write_registry
docker login localhost:5050
# Username: tu-username-de-gitlab
# Password: glpat-XXXXXXXXXXXXXXXXXXXX  (el PAT)
```

### Método 2: CI Job Token (dentro de pipelines — recomendado)

```bash
# ¿QUÉ HACE?: Login al registry usando el token temporal del job CI
# ¿POR QUÉ?: CI_JOB_TOKEN se genera automáticamente por GitLab para cada job
# ¿PARA QUÉ?: No hardcodear credenciales; el token expira al terminar el job
docker login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY
```

`CI_REGISTRY_USER` es `gitlab-ci-token` (literal) y `CI_JOB_TOKEN` es el token temporal — ambos se inyectan automáticamente por GitLab.

### Método 3: Deploy Token (acceso automatizado no-CI)

```
Proyecto → Settings → Repository → Deploy Tokens → New deploy token
  → Scopes: read_registry (para pull) y/o write_registry (para push)
  → Nombre: "production-pull-token"
  → Expiración: (opcional)
  → Guarda el token — solo se muestra una vez
```

```bash
# Usar el deploy token:
docker login registry.example.com \
  --username <deploy-token-username> \
  --password <deploy-token-value>
```

**Cuándo usar cada uno:**

| Método | Cuándo usarlo |
|--------|---------------|
| Personal Access Token | Pull/push manual desde terminal del developer |
| CI Job Token | Dentro de cualquier job de CI/CD |
| Deploy Token | Sistemas de deploy externo, Kubernetes pull secrets, automatización no-CI |

---

## 🏷️ Nomenclatura de Imágenes

```
registry.example.com / grupo / subgrupo / proyecto / nombre-imagen : tag
     ↑ CI_REGISTRY          ↑────────── CI_REGISTRY_IMAGE ──────────↑
```

**Variables predefinidas clave:**

| Variable | Ejemplo | Cuándo usarla |
|----------|---------|---------------|
| `CI_REGISTRY` | `registry.example.com` | Para el login |
| `CI_REGISTRY_IMAGE` | `registry.example.com/mi-grupo/mi-app` | URL base de la imagen del proyecto |
| `CI_REGISTRY_USER` | `gitlab-ci-token` | Usuario del login CI |
| `CI_JOB_TOKEN` | `(token temporal)` | Password del login CI |

```yaml
# Ejemplo de uso en .gitlab-ci.yml
docker-build:
  script:
    # Login
    - docker login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY

    # Build con múltiples tags
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA .
    - docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA $CI_REGISTRY_IMAGE:latest

    # Push todos los tags a la vez
    - docker push $CI_REGISTRY_IMAGE --all-tags
```

Si la imagen necesita un nombre distinto al proyecto:

```yaml
variables:
  IMAGE_NAME: $CI_REGISTRY_IMAGE/api-server    # subdirectorio dentro del proyecto
  # Resultado: registry.example.com/mi-grupo/mi-app/api-server
```

---

## 🖥️ Gestión desde la UI

En `Proyecto → Packages & Registries → Container Registry`:

| Columna | Descripción |
|---------|-------------|
| Nombre de imagen | Path completo en el registry |
| Tags | Lista de tags publicados para esa imagen |
| Tamaño | Espacio en disco ocupado |
| Última publicación | Fecha del último push |
| Acciones | Copiar URL, eliminar imagen/tag |

**Eliminar tags manualmente:** Click en el tag → icono de papelera → confirmar. Esto elimina solo el tag, no los layers de la imagen si otro tag los referencia.

---

## 🔍 API del Container Registry

```bash
# ¿QUÉ HACE?: Lista todas las imágenes (repositories) del proyecto
# ¿POR QUÉ?: La UI puede ser lenta para proyectos con muchas imágenes
# ¿PARA QUÉ?: Automatizar auditorías de imágenes y políticas de limpieza

PROJECT_ID=7
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/registry/repositories?per_page=50" \
  | python3 -c "
import sys, json
repos = json.load(sys.stdin)
print(f'Imágenes en el registry: {len(repos)}')
for r in repos:
    print(f'  ID:{r[\"id\"]:4}  Nombre: {r[\"name\"]}')
    print(f'         Path: {r[\"path\"]}')
"

# ¿QUÉ HACE?: Lista los tags de un repository específico
REPO_ID=1
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/registry/repositories/$REPO_ID/tags?per_page=50" \
  | python3 -c "
import sys, json
tags = json.load(sys.stdin)
print(f'Tags: {len(tags)}')
for t in tags:
    size_mb = t.get('total_size', 0) / 1024 / 1024
    print(f'  {t[\"name\"]:<30} creado: {t.get(\"created_at\",\"?\")[:10]}  ({size_mb:.1f} MB)')
"
```

---

## 🌉 Dependency Proxy: Caché de Docker Hub a Nivel de Grupo

### ¿Qué es?

El **Dependency Proxy** es un caché *pull-through* a nivel de **grupo** para imágenes de Docker Hub (y otros registries compatibles con OCI). La primera vez que alguien pide una imagen a través del proxy, GitLab la descarga de Docker Hub y la guarda; las siguientes peticiones de esa misma imagen se sirven desde el caché local, sin volver a tocar Docker Hub.

```
Sin Dependency Proxy:
  Runner 1 → docker pull node:20-alpine → Docker Hub
  Runner 2 → docker pull node:20-alpine → Docker Hub   (mismo pull, mismo rate limit)
  Runner 3 → docker pull node:20-alpine → Docker Hub
  → 3 pulls consumidos del límite de Docker Hub por la MISMA imagen

Con Dependency Proxy:
  Runner 1 → docker pull gitlab.example.com/mi-grupo/dependency_proxy/.../node:20-alpine
               → GitLab no tiene la imagen cacheada → 1 pull a Docker Hub → la guarda
  Runner 2 → docker pull gitlab.example.com/.../node:20-alpine → sirve desde caché
  Runner 3 → docker pull gitlab.example.com/.../node:20-alpine → sirve desde caché
  → 1 solo pull consumido del límite de Docker Hub, sin importar cuántos runners la pidan
```

Es distinto del Container Registry: el Container Registry aloja **tus propias imágenes** (las que construyes); el Dependency Proxy cachea **imágenes de terceros** (las que usas como base o como servicio).

### 🤔 ¿Por Qué Existe?

Desde noviembre de 2020, Docker Hub impone límites de pull para reducir carga en su infraestructura:

| Tipo de cuenta | Límite de pulls |
|-----------------|------------------|
| Anónimo (sin login) | 100 pulls / 6 horas por IP |
| Autenticado, plan free | 200 pulls / 6 horas |
| Plan Pro/Team | Sin límite (o mucho más alto) |

En CI/CD esto es un problema serio: **cada job** que hace `docker pull node:20-alpine` o usa una imagen como `image:` o `services:` cuenta contra ese límite. Con varios runners compartiendo la misma IP saliente (típico en runners self-hosted o shared runners), es fácil golpear el límite de 100-200 pulls en pocas horas de actividad normal, y los pipelines empiezan a fallar con `429 Too Many Requests`.

El Dependency Proxy resuelve esto **sin pagar por Docker Hub Pro**: todos los pulls de un mismo grupo pasan por GitLab, que solo va a Docker Hub cuando la imagen no está en caché o cuando expira el TTL local.

**Analogía:** si el Container Registry es la bodega privada de la empresa, el Dependency Proxy es la compra al por mayor — en vez de que cada equipo vaya al supermercado (Docker Hub) por su cuenta y agote la cuota, un solo pedido abastece a todos desde una despensa compartida (el caché del grupo).

---

### ⚙️ Habilitarlo

El Dependency Proxy es una función a **nivel de grupo** (no de proyecto). En GitLab CE puede venir deshabilitada a nivel de instancia — se activa así:

```
1. A nivel de instancia (Admin Area), si está deshabilitada:
   Admin Area → Settings → General → Dependency Proxy → habilitar "Enable Dependency Proxy"

2. A nivel de grupo:
   Grupo → Settings → Packages and registries → Dependency Proxy → toggle "Enable Proxy"
```

Una vez habilitado, el grupo obtiene una URL propia del proxy, visible en la misma página:

```
gitlab.example.com/mi-grupo/dependency_proxy/containers
```

No requiere configuración adicional de infraestructura — GitLab expone el endpoint y gestiona el caché internamente (respaldado por el mismo object storage que usa el Container Registry).

---

### 🔐 Uso desde `.gitlab-ci.yml`

GitLab inyecta variables predefinidas específicas del Dependency Proxy en cada job, similares a las del Container Registry:

| Variable | Descripción |
|----------|-------------|
| `CI_DEPENDENCY_PROXY_SERVER` | Host del proxy (ej: `gitlab.example.com:443`) |
| `CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX` | Prefijo completo para el grupo del proyecto actual (ej: `gitlab.example.com/mi-grupo/dependency_proxy/containers`) |
| `CI_DEPENDENCY_PROXY_DIRECT_GROUP_IMAGE_PREFIX` | Igual, pero sin resolver subgrupos heredados — apunta al grupo directo del proyecto |
| `CI_DEPENDENCY_PROXY_USER` | Usuario para autenticarse al proxy (`gitlab-ci-token` dentro de CI) |
| `CI_DEPENDENCY_PROXY_PASSWORD` | Password/token para el login (equivalente a `CI_JOB_TOKEN`) |

```yaml
# ¿QUÉ HACE?: Hace login al Dependency Proxy del grupo y usa una imagen base a través de él
# ¿POR QUÉ?: docker.io/node:20-alpine cuenta contra el rate limit de Docker Hub;
#            $CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX/node:20-alpine no
# ¿PARA QUÉ?: Evitar 429 Too Many Requests en pipelines con muchos jobs concurrentes

build:
  image: docker:24-cli
  services:
    - docker:24-dind
  before_script:
    # Login al proxy — mismo patrón que el login al Container Registry
    - docker login -u $CI_DEPENDENCY_PROXY_USER -p $CI_DEPENDENCY_PROXY_PASSWORD $CI_DEPENDENCY_PROXY_SERVER
  script:
    # En vez de: docker pull node:20-alpine
    - docker pull $CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX/node:20-alpine
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
```

También se puede usar directamente como imagen del job, sin `docker pull` explícito — así el runner nunca toca Docker Hub para bajar la imagen base del propio job:

```yaml
# ¿QUÉ HACE?: Usa la imagen node vía el Dependency Proxy como imagen del job
# ¿POR QUÉ?: image: no soporta variables CI antes de que el runner las resuelva en
#            algunos executors — funciona en Docker/Kubernetes Executor con GitLab 13.7+
# ¿PARA QUÉ?: Que TODOS los jobs (no solo docker pull manuales) pasen por el caché
test:
  image: $CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX/node:20-alpine
  script:
    - npm ci
    - npm test
```

Para imágenes usadas como `services:` (por ejemplo, `postgres:16` o `redis:7`), aplica el mismo prefijo:

```yaml
services:
  - name: $CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX/postgres:16
    alias: postgres
```

---

### 🆚 Dependency Proxy vs Container Registry

| | Dependency Proxy | Container Registry |
|---|---|---|
| Qué almacena | Imágenes de **terceros** (Docker Hub, etc.) | Imágenes **propias** (las que construyes) |
| Nivel | Grupo | Proyecto |
| Quién publica | Nadie explícitamente — se llena solo con cada pull | El pipeline con `docker push` |
| Propósito | Evitar rate limits, acelerar pulls repetidos | Distribuir tus artefactos versionados |
| Autenticación CI | `CI_DEPENDENCY_PROXY_USER` / `CI_DEPENDENCY_PROXY_PASSWORD` | `CI_REGISTRY_USER` / `CI_JOB_TOKEN` |

---

## 🖼️ Diagrama: Flujo Container Registry

![Diagrama del flujo de Container Registry](../0-assets/01-container-registry-flow.svg)

> **Diagrama:** Muestra tres secciones: (1) flujo completo Dockerfile → docker build → docker push → Container Registry → docker pull en deploy; (2) las cuatro estrategias de versionado de imágenes: SHA inmutable, branch slug para dev/staging, SemVer para releases, y `latest` como tag movible; (3) comparación de métodos de build en CI: DinD (privileged), Kaniko (rootless, recomendado), y Buildah (rootless OCI).

---

## 🤔 Preguntas de reflexión

1. `CI_JOB_TOKEN` expira cuando termina el job. Si necesitas que un sistema de CD externo (no GitLab) haga `docker pull` de una imagen privada, ¿qué método de autenticación usas? ¿Por qué no el PAT del developer?

2. El registry privado de GitLab está en la misma red que el CI. ¿Qué ventajas de velocidad tiene sobre Docker Hub cuando el runner hace `docker pull` de la imagen base?

3. Si un proyecto tiene `CI_REGISTRY_IMAGE = registry.example.com/backend/api-gateway` y quieres publicar tres imágenes distintas (api, worker, scheduler) del mismo monorepo, ¿cómo nombrarías las imágenes? ¿Con subdirectorios o con nombres de tag?

4. Un deploy token con scope `read_registry` se filtra. ¿Qué puede hacer un atacante con ese token? ¿Qué NO puede hacer? ¿Cómo lo invalidas?

5. La API del registry devuelve `total_size` por tag. Si tienes 200 tags de la misma imagen base con solo un archivo diferente por tag, ¿cuánto espacio real ocupan vs lo que reporta la API? (Considera la reutilización de layers Docker.)

---

## 📚 Recursos adicionales

- [GitLab Container Registry Docs](https://docs.gitlab.com/ee/user/packages/container_registry/)
- [Container Registry API](https://docs.gitlab.com/ee/api/container_registry.html)
- [Deploy Tokens](https://docs.gitlab.com/ee/user/project/deploy_tokens/)
- [Habilitar Container Registry en Omnibus](https://docs.gitlab.com/ee/administration/packages/container_registry.html)

---

➡️ **Siguiente lección:** [02 — Docker Build en CI](./02-docker-build-en-ci.md)

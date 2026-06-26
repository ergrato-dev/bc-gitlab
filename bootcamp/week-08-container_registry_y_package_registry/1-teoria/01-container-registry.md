# 📖 01 — GitLab Container Registry

## 🎯 Objetivos de aprendizaje

- ✅ Entender qué es el Container Registry y cómo se integra con cada proyecto GitLab
- ✅ Habilitar y configurar el registry en GitLab CE (Omnibus y Docker)
- ✅ Autenticarse al registry con los tres métodos: PAT, CI Job Token, Deploy Token
- ✅ Construir, etiquetar y publicar imágenes manualmente y desde pipelines
- ✅ Gestionar imágenes y tags desde la UI y via API

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

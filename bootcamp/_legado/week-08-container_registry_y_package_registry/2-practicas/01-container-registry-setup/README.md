# 🔬 Práctica 01 — Container Registry Setup

**Duración estimada:** 35 minutos
**Dificultad:** ⭐⭐ (Media)

## 🎯 Objetivo

Habilitar el Container Registry en la instancia GitLab CE, verificar su funcionamiento, autenticarse con los tres métodos disponibles, y publicar una primera imagen manualmente para confirmar el flujo completo.

---

## 📋 Prerrequisitos

- Instancia GitLab CE corriendo en Docker
- `$GITLAB_TOKEN` exportado
- Docker instalado en el host

```bash
# Verificar que GitLab responde
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/version" \
  | python3 -c "import sys,json; v=json.load(sys.stdin); print(f'GitLab {v[\"version\"]}')"

# Verificar que el proyecto de práctica existe
echo "Project ID: $GITLAB_PROJECT_ID"
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID" \
  | python3 -c "import sys,json; p=json.load(sys.stdin); print(f'Proyecto: {p[\"path_with_namespace\"]}')"
```

---

## ⚙️ Paso 1: Habilitar el Container Registry

### Si usas GitLab CE en Docker Compose

```bash
# Verificar si el registry ya está habilitado
curl --silent http://localhost:5050/v2/

# Si devuelve {} o 401 → registry activo
# Si "connection refused" → necesita activarse
```

Si no está activo, editar `gitlab.rb` dentro del contenedor:

```bash
# ¿QUÉ HACE?: Habilita el Container Registry en el puerto 5050
# ¿POR QUÉ?: En GitLab CE Docker, el registry no siempre está activo por defecto
# ¿PARA QUÉ?: Exponer el registry para push/pull de imágenes

docker exec -it gitlab bash -c "
cat >> /etc/gitlab/gitlab.rb << 'EOF'
registry_external_url 'http://localhost:5050'
gitlab_rails['registry_enabled'] = true
EOF
"
docker exec gitlab gitlab-ctl reconfigure

# Verificar después de reconfigure:
docker exec gitlab gitlab-ctl status | grep registry
```

### Verificar via API de GitLab

```bash
# ¿QUÉ HACE?: Consulta el endpoint del registry via API de GitLab
# ¿POR QUÉ?: La API de GitLab devuelve el estado del registry para el proyecto
# ¿PARA QUÉ?: Confirmar que el proyecto tiene acceso al registry antes de hacer push

curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID" \
  | python3 -c "
import sys, json
p = json.load(sys.stdin)
print(f'Registry habilitado: {p.get(\"container_registry_enabled\", \"?\")}')
print(f'Registry URL: {p.get(\"container_registry_image_prefix\", \"?\")}')
"
```

---

## 🔑 Paso 2: Los Tres Métodos de Autenticación

### Método A: Personal Access Token (acceso manual)

```bash
# ¿QUÉ HACE?: Crea un PAT con permisos de read/write en el registry
# ¿POR QUÉ?: Necesitamos un token para hacer docker login desde la terminal
# ¿PARA QUÉ?: Subir imágenes manualmente sin pasar por el pipeline

# Crear PAT via API
PAT=$(curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "registry-access",
    "expires_at": "2026-12-31",
    "scopes": ["read_registry","write_registry"]
  }' \
  "http://localhost/api/v4/users/1/personal_access_tokens" \
  | python3 -c "import sys,json; t=json.load(sys.stdin); print(t.get('token','ERROR'))")

echo "PAT creado: $PAT"
export REGISTRY_PAT="$PAT"

# Login con PAT
docker login localhost:5050 \
  --username root \
  --password "$REGISTRY_PAT"
```

Salida esperada: `Login Succeeded`

### Método B: CI Job Token (automático en pipelines)

Este método no puede probarse manualmente — el CI_JOB_TOKEN solo existe dentro de un job de CI. Se verifica en los pasos siguientes del pipeline.

```yaml
# Ejemplo de uso en .gitlab-ci.yml (para referencia):
before_script:
  - docker login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY
```

### Método C: Deploy Token (acceso controlado sin credenciales personales)

```bash
# ¿QUÉ HACE?: Crea un deploy token con scope read_registry para pull en producción
# ¿POR QUÉ?: En producción, no queremos usar el PAT de un developer
# ¿PARA QUÉ?: Pull de imágenes en servidores de producción, CI de otros proyectos

curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "prod-pull-token",
    "scopes": ["read_registry"],
    "expires_at": "2027-01-01"
  }' \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/deploy_tokens" \
  | python3 -c "
import sys, json
t = json.load(sys.stdin)
print(f'Deploy token creado:')
print(f'  Username: {t[\"username\"]}')
print(f'  Token: {t.get(\"token\", \"(solo visible ahora)\")}')
print()
print(f'Login: docker login localhost:5050 --username {t[\"username\"]} --password <token>')
"
```

---

## 🐳 Paso 3: Push de Primera Imagen Manual

```bash
# ¿QUÉ HACE?: Descarga alpine:latest de Docker Hub, la re-etiqueta y la sube al registry privado
# ¿POR QUÉ?: Verificar que el flujo push funciona sin necesitar un Dockerfile propio
# ¿PARA QUÉ?: Confirmar autenticación, nomenclatura y que la imagen aparece en la UI

# Obtener el namespace del proyecto para la URL de la imagen
PROJECT_PATH=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['path_with_namespace'])")

export REGISTRY_IMAGE="localhost:5050/$PROJECT_PATH/mi-alpine"
echo "Registry image: $REGISTRY_IMAGE"

# Pull de Alpine desde Docker Hub
docker pull alpine:3.19

# Re-etiquetar con diferentes tags
docker tag alpine:3.19 $REGISTRY_IMAGE:latest
docker tag alpine:3.19 $REGISTRY_IMAGE:3.19
docker tag alpine:3.19 $REGISTRY_IMAGE:$(date +%Y%m%d)

# Push al registry privado
docker push $REGISTRY_IMAGE:latest
docker push $REGISTRY_IMAGE:3.19
docker push $REGISTRY_IMAGE:$(date +%Y%m%d)
```

Salida esperada:
```
The push refers to repository [localhost:5050/mi-grupo/mi-proyecto/mi-alpine]
latest: digest: sha256:... size: 3408
```

---

## 🌐 Paso 4: Verificar en la UI y via API

En GitLab:
- Ir a `Proyecto → Packages & Registries → Container Registry`
- Debe aparecer `mi-alpine` con los 3 tags (`latest`, `3.19`, `YYYYMMDD`)

Via API:

```bash
# ¿QUÉ HACE?: Consulta los repositories del registro del proyecto
# ¿POR QUÉ?: Confirmar que la imagen fue registrada en GitLab, no solo en el registry Docker
# ¿PARA QUÉ?: Verificar el estado del registry sin necesitar la UI

curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/registry/repositories" \
  | python3 -c "
import sys, json
repos = json.load(sys.stdin)
print(f'Imágenes en el registry: {len(repos)}')
for r in repos:
    print(f'  ID: {r[\"id\"]}  Nombre: {r[\"path\"]}')
" | tee /tmp/registry-repos.json

# Obtener el ID del repository para consultar tags
REPO_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/registry/repositories" \
  | python3 -c "import sys,json; repos=json.load(sys.stdin); print(repos[0]['id'])" 2>/dev/null)

# Listar tags del repository
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/registry/repositories/$REPO_ID/tags" \
  | python3 -c "
import sys, json
tags = json.load(sys.stdin)
print(f'Tags disponibles ({len(tags)}):')
for t in tags:
    size_kb = t.get('total_size', 0) // 1024
    print(f'  {t[\"name\"]:<20} {size_kb:>6} KB  {t.get(\"created_at\",\"\")[:10]}')
"
```

---

## 🔄 Paso 5: Pull de la Imagen Privada

```bash
# ¿QUÉ HACE?: Elimina la imagen local y la descarga nuevamente desde el registry privado
# ¿POR QUÉ?: Confirmar que el pull funciona (no solo el push) y que la autenticación persiste
# ¿PARA QUÉ?: Simular lo que hace el servidor de producción cuando necesita la imagen

# Eliminar imágenes locales
docker rmi $REGISTRY_IMAGE:latest $REGISTRY_IMAGE:3.19 alpine:3.19 2>/dev/null

# Pull desde el registry privado
docker pull $REGISTRY_IMAGE:latest

# Ejecutar para confirmar que funciona
docker run --rm $REGISTRY_IMAGE:latest \
  sh -c "echo 'Imagen desde registry privado de GitLab'; cat /etc/os-release | grep PRETTY"
```

---

## ✅ Checklist de verificación

- [ ] `curl http://localhost:5050/v2/` responde (sin "connection refused")
- [ ] `docker login localhost:5050` exitoso con PAT
- [ ] Deploy token creado con scope `read_registry`
- [ ] `docker push` exitoso: imagen `mi-alpine` con 3 tags en el registry
- [ ] Imagen visible en `Packages & Registries → Container Registry` de la UI
- [ ] API devuelve los tags del repository
- [ ] `docker pull` desde el registry privado exitoso
- [ ] `docker run` de la imagen privada funciona

---

## 🏆 Reto adicional

Configurar Kubernetes para hacer pull de imágenes del registry privado usando un imagePullSecret basado en el deploy token:

```bash
# Crear el secret de K8s para pull del registry privado
# (reemplazar DEPLOY_TOKEN_USERNAME y DEPLOY_TOKEN_VALUE con los del Paso 2C)

kubectl create secret docker-registry gitlab-registry-secret \
  --docker-server=localhost:5050 \
  --docker-username=DEPLOY_TOKEN_USERNAME \
  --docker-password=DEPLOY_TOKEN_VALUE \
  --namespace=default

# Referenciar en un Pod:
# spec:
#   imagePullSecrets:
#     - name: gitlab-registry-secret
#   containers:
#     - image: localhost:5050/mi-grupo/mi-proyecto/mi-alpine:latest
```

---

⬅️ **Prácticas:** [Índice](../README.md)
➡️ **Siguiente práctica:** [02 — Build y Push de Imágenes](../02-build-y-push-imagenes/README.md)

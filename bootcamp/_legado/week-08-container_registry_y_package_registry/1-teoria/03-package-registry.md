# 📖 03 — GitLab Package Registry

## 🎯 Objetivos de aprendizaje

- ✅ Entender qué resuelve el Package Registry vs un registry de imágenes Docker
- ✅ Publicar un paquete npm con CI Job Token desde un pipeline
- ✅ Publicar un paquete Maven y entender la configuración de `ci_settings.xml`
- ✅ Publicar un paquete Python (PyPI) usando twine en CI
- ✅ Instalar paquetes desde el Package Registry de GitLab en otros proyectos

---

## 🤔 Container Registry vs Package Registry

Son dos registries distintos con propósitos distintos:

| | Container Registry | Package Registry |
|---|---|---|
| **Qué almacena** | Imágenes Docker | Paquetes de código (librerías) |
| **Formato** | OCI/Docker image layers | npm, Maven JAR, Python wheel, NuGet, etc. |
| **Se usa con** | `docker pull`, deployment | `npm install`, `pip install`, `mvn dependency:get` |
| **Consumidores** | Servidores, Kubernetes, CD pipelines | Otros proyectos, developers, builds |
| **Versionado** | Docker tags | Versión semántica del paquete |

**Analogía:** El Container Registry es un almacén de máquinas virtuales listas para ejecutar. El Package Registry es una librería de componentes reutilizables — piezas que otros proyectos importan para construir su propia máquina.

---

## 📦 Formatos Soportados

GitLab Package Registry soporta nativamente:

| Formato | Ecosistema | Comando de publicación | Comando de instalación |
|---------|------------|----------------------|----------------------|
| **npm** | JavaScript/Node.js | `npm publish` | `npm install @scope/pkg` |
| **Maven** | Java/Kotlin | `mvn deploy` | `mvn dependency:get` |
| **PyPI** | Python | `twine upload` | `pip install pkg` |
| **NuGet** | .NET/C# | `dotnet nuget push` | `dotnet add package` |
| **Conan** | C/C++ | `conan upload` | `conan install` |
| **Composer** | PHP | `composer publish` | `composer require` |
| **Helm** | Kubernetes | `helm cm-push` | `helm install` |
| **Generic** | Cualquier archivo | API REST | API REST / `curl` |
| **Terraform Module** | Terraform | API REST | `source = "gitlab/..."` |

El Package Registry de cada proyecto está en `Deploy → Package Registry`.

---

## 📦 npm — JavaScript/Node.js

### Configuración del paquete

```json
// package.json
{
  "name": "@mi-org/bootcamp-utils",
  "version": "1.2.0",
  "description": "Utilidades compartidas del bootcamp",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "files": ["dist/"],
  "scripts": {
    "build": "tsc",
    "test": "jest"
  }
}
```

El scope `@mi-org` debe coincidir con el namespace del grupo o proyecto en GitLab.

### Publicar en CI

```yaml
publish-npm:
  stage: publish
  image: node:18-alpine
  script:
    # ¿QUÉ HACE?: Crea el .npmrc que apunta al registry de GitLab con autenticación
    # ¿POR QUÉ?: npm necesita saber a qué registry enviar paquetes scoped (@mi-org)
    # ¿PARA QUÉ?: El CI_JOB_TOKEN autentica de forma temporal sin credenciales hardcodeadas
    - |
      cat > .npmrc << EOF
      @mi-org:registry=${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/npm/
      ${CI_API_V4_URL#https:}//projects/${CI_PROJECT_ID}/packages/npm/:_authToken=${CI_JOB_TOKEN}
      EOF
    - npm run build
    - npm publish
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/   # solo en tags semánticos
```

### Instalar en otro proyecto

```bash
# En el proyecto consumidor, crear .npmrc:
@mi-org:registry=https://gitlab.example.com/api/v4/packages/npm/
//gitlab.example.com/api/v4/packages/npm/:_authToken=PERSONAL_ACCESS_TOKEN

# Luego instalar normalmente:
npm install @mi-org/bootcamp-utils
```

```yaml
# En CI del proyecto consumidor:
install-deps:
  script:
    - |
      echo "@mi-org:registry=${CI_API_V4_URL}/packages/npm/" > .npmrc
      echo "${CI_API_V4_URL#https:}//packages/npm/:_authToken=${CI_JOB_TOKEN}" >> .npmrc
    - npm ci
```

> **Nivel de URL:** `packages/npm/` (sin project ID) accede al registro a nivel de instancia — sirve paquetes de cualquier proyecto. `projects/$ID/packages/npm/` es específico del proyecto.

---

## ☕ Maven — Java/Kotlin

### Pipeline para publicar

```yaml
publish-maven:
  stage: publish
  image: maven:3.9-eclipse-temurin-17
  script:
    # ¿QUÉ HACE?: Ejecuta mvn deploy usando el settings.xml con el token del job
    # ¿POR QUÉ?: Maven usa settings.xml para las credenciales, no variables de entorno directamente
    # ¿PARA QUÉ?: Publicar el JAR/POM en el Package Registry de GitLab

    - mvn deploy
        --no-transfer-progress
        -s ci_settings.xml
        -DaltDeploymentRepository=gitlab::default::${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/maven
  rules:
    - if: $CI_COMMIT_TAG
```

### `ci_settings.xml` — autenticación Maven

```xml
<!-- ci_settings.xml (committear sin secretos — usa CI_JOB_TOKEN del environment) -->
<settings>
  <servers>
    <server>
      <id>gitlab</id>
      <configuration>
        <httpHeaders>
          <property>
            <name>Job-Token</name>
            <value>${CI_JOB_TOKEN}</value>
          </property>
        </httpHeaders>
      </configuration>
    </server>
  </servers>
</settings>
```

### `pom.xml` — configurar el repositorio de distribución

```xml
<project>
  ...
  <distributionManagement>
    <repository>
      <id>gitlab</id>
      <url>${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/maven</url>
    </repository>
    <snapshotRepository>
      <id>gitlab</id>
      <url>${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/maven</url>
    </snapshotRepository>
  </distributionManagement>
</project>
```

---

## 🐍 PyPI — Python

### Estructura del paquete

```
bootcamp-lib/
  pyproject.toml
  src/
    bootcamp_lib/
      __init__.py
      utils.py
```

```toml
# pyproject.toml (PEP 517/518 — formato moderno)
[build-system]
requires = ["setuptools>=68", "wheel"]
build-backend = "setuptools.backends.legacy:build"

[project]
name = "bootcamp-lib"
version = "1.0.0"
description = "Utilidades compartidas del bootcamp GitLab"
requires-python = ">=3.9"
dependencies = ["requests>=2.28"]
```

### Pipeline para publicar

```yaml
publish-pypi:
  stage: publish
  image: python:3.11-slim
  script:
    # ¿QUÉ HACE?: Instala las herramientas de build y publicación de Python
    - pip install --quiet build twine

    # ¿QUÉ HACE?: Construye el wheel y el source distribution
    # ¿POR QUÉ?: PyPI requiere ambos formatos para máxima compatibilidad
    # ¿PARA QUÉ?: Los archivos en dist/ son los que se suben al registry
    - python -m build

    # ¿QUÉ HACE?: Sube los artifacts a la URL del Package Registry de GitLab
    - TWINE_PASSWORD=${CI_JOB_TOKEN}
      TWINE_USERNAME=gitlab-ci-token
      python -m twine upload
        --repository-url ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/pypi
        dist/*
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
```

### Instalar en otro proyecto

```bash
# Con token de acceso personal
pip install bootcamp-lib \
  --index-url https://gitlab-ci-token:PERSONAL_ACCESS_TOKEN@gitlab.example.com/api/v4/projects/7/packages/pypi/simple

# En CI del proyecto consumidor:
pip install bootcamp-lib \
  --index-url https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.example.com/api/v4/projects/7/packages/pypi/simple
```

---

## 📦 Generic Package — Archivos Arbitrarios

Para binarios compilados, assets, archivos de configuración o cualquier cosa que no encaje en los formatos específicos:

```yaml
publish-binary:
  stage: publish
  image: alpine:latest
  script:
    - apk add --no-cache curl

    # ¿QUÉ HACE?: Sube un archivo binario al Package Registry como "generic package"
    # ¿POR QUÉ?: Los generic packages no requieren formato específico — sirve para cualquier artifact
    # ¿PARA QUÉ?: Distribuir binarios compilados, scripts, configuraciones como paquetes versionados
    - curl --header "JOB-TOKEN: $CI_JOB_TOKEN"
        --upload-file ./build/mi-binario
        "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/mi-app/${CI_COMMIT_TAG}/mi-binario-linux-amd64"

# Descargar en otro pipeline:
download-binary:
  script:
    - curl --header "JOB-TOKEN: $CI_JOB_TOKEN" -O
        "${CI_API_V4_URL}/projects/7/packages/generic/mi-app/v1.2.0/mi-binario-linux-amd64"
    - chmod +x mi-binario-linux-amd64
```

---

## 🔍 Consultar el Package Registry via API

```bash
# ¿QUÉ HACE?: Lista todos los paquetes publicados en el proyecto
# ¿POR QUÉ?: La UI puede ser limitada para proyectos con muchos paquetes
# ¿PARA QUÉ?: Auditoría, automatización, limpieza de versiones antiguas

curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/packages?per_page=50" \
  | python3 -c "
import sys, json
pkgs = json.load(sys.stdin)
print(f'Paquetes en el registry: {len(pkgs)}')
print()
for p in pkgs:
    print(f'  {p[\"package_type\"]:<10} {p[\"name\"]:<35} v{p[\"version\"]}')
    print(f'             Creado: {p.get(\"created_at\",\"?\")[:10]}')
"
```

---

## 🖼️ Diagrama: Package Registry — Formatos y Publicación npm

![Diagrama de Package Registry — formatos soportados](../0-assets/02-package-registry-formats.svg)

> **Diagrama:** Panel superior muestra los cuatro formatos principales (npm, Maven, PyPI, NuGet) y los secundarios (Conan, Composer, Helm, Generic, Terraform). Panel inferior muestra el flujo de publicación de un paquete npm en CI: configurar scope en package.json → crear .npmrc con auth → publicar con `npm publish` usando CI_JOB_TOKEN.

---

## 🤔 Preguntas de reflexión

1. El Package Registry de GitLab puede servir paquetes a nivel de proyecto (`/projects/7/packages/npm/`) o a nivel de instancia (`/packages/npm/`). ¿Cuáles son los tradeoffs? ¿En qué caso preferirías el endpoint de instancia?

2. Un paquete npm publicado con `version: "1.2.0"` en el tag `v1.2.0`. En la próxima release, el developer olvidó actualizar el `version` en `package.json` pero sí creó el tag `v1.3.0`. ¿Qué pasa cuando el pipeline intenta publicar? ¿Error o conflicto silencioso?

3. El `ci_settings.xml` de Maven se commitea al repositorio. Contiene `${CI_JOB_TOKEN}` — una variable que solo existe en CI. ¿Qué pasa si un developer intenta `mvn deploy` desde su máquina local usando ese settings.xml?

4. Un Generic Package con el mismo nombre y versión ya existe en el registry. ¿GitLab permite sobrescribirlo? ¿Por qué la inmutabilidad de versiones es importante en un registry de paquetes?

5. Tienes una librería Python usada por 8 proyectos en GitLab. ¿La publicas en el Package Registry de su propio proyecto (nivel proyecto) o creas un proyecto dedicado "shared-libs" para publicar ahí? ¿Qué ventajas tiene cada enfoque para la gestión de accesos?

---

## 📚 Recursos adicionales

- [GitLab Package Registry](https://docs.gitlab.com/ee/user/packages/package_registry/)
- [npm packages in GitLab](https://docs.gitlab.com/ee/user/packages/npm_registry/)
- [Maven packages in GitLab](https://docs.gitlab.com/ee/user/packages/maven_repository/)
- [PyPI packages in GitLab](https://docs.gitlab.com/ee/user/packages/pypi_repository/)
- [Generic packages](https://docs.gitlab.com/ee/user/packages/generic_packages/)

---

⬅️ **Lección anterior:** [02 — Docker Build en CI](./02-docker-build-en-ci.md)
➡️ **Siguiente lección:** [04 — Gestión de Versiones](./04-gestion-de-versiones.md)

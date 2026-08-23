# 🔬 Práctica 03 — Package Registry (npm + PyPI)

**Duración estimada:** 40 minutos
**Dificultad:** ⭐⭐⭐ (Media-Alta)

## 🎯 Objetivo

Publicar un paquete npm en el Package Registry de GitLab usando CI Job Token, verificar que puede instalarse desde otro proyecto, y repetir el proceso para un paquete Python (PyPI).

---

## 📋 Prerrequisitos

- Proyecto con runner Docker online
- `$GITLAB_TOKEN` y `$GITLAB_PROJECT_ID` exportados
- El nombre del grupo del proyecto (para el scope de npm)

```bash
# Obtener info del proyecto
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID" \
  | python3 -c "
import sys, json
p = json.load(sys.stdin)
print(f'Proyecto: {p[\"path_with_namespace\"]}')
print(f'Grupo: {p[\"namespace\"][\"path\"]}')
print(f'Ruta API: {p[\"_links\"][\"packages\"]}')
"
```

Exportar el grupo para usarlo como scope npm:

```bash
export GITLAB_GROUP=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['namespace']['path'])")

echo "Scope npm: @$GITLAB_GROUP"
```

---

## 📦 Parte A: Paquete npm

### Paso A1: Crear el paquete

Crear en el proyecto los siguientes archivos:

**`package.json`** (para el paquete librería, no la app):
```json
{
  "name": "@SCOPE/bootcamp-utils",
  "version": "1.0.0",
  "description": "Utilidades de ejemplo publicadas en GitLab Package Registry",
  "main": "index.js",
  "keywords": ["bootcamp", "gitlab"],
  "scripts": {
    "test": "node test.js"
  }
}
```

> Reemplazar `SCOPE` con el valor de `$GITLAB_GROUP` (ej: `@bootcamp-org`).

**`index.js`**:
```javascript
/**
 * Formatea una fecha en ISO 8601
 */
function formatDate(date = new Date()) {
  return date.toISOString().split('T')[0];
}

/**
 * Genera un ID corto único
 */
function shortId(length = 8) {
  return Math.random().toString(36).substring(2, 2 + length);
}

/**
 * Sanitiza un string para uso en URLs (tipo CI_COMMIT_REF_SLUG)
 */
function toSlug(text) {
  return text.toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
}

module.exports = { formatDate, shortId, toSlug };
```

**`test.js`** (pruebas simples):
```javascript
const { formatDate, shortId, toSlug } = require('./index.js');

let passed = 0;
let failed = 0;

function test(name, condition) {
  if (condition) {
    console.log(`  ✅ ${name}`);
    passed++;
  } else {
    console.log(`  ❌ ${name}`);
    failed++;
  }
}

console.log('Running tests...');
test('formatDate returns YYYY-MM-DD', /^\d{4}-\d{2}-\d{2}$/.test(formatDate()));
test('shortId returns 8 chars', shortId().length === 8);
test('shortId returns 4 chars', shortId(4).length === 4);
test('toSlug converts spaces', toSlug('Hello World') === 'hello-world');
test('toSlug handles special chars', toSlug('feature/Login-123') === 'feature-login-123');

console.log(`\n${passed} passed, ${failed} failed`);
if (failed > 0) process.exit(1);
```

### Paso A2: Pipeline de publicación npm

```yaml
# .gitlab-ci.yml
stages:
  - test
  - publish

variables:
  PACKAGE_SCOPE: "@SCOPE"   # ← reemplazar con @$GITLAB_GROUP

test-npm:
  stage: test
  image: node:18-alpine
  script:
    - npm test

publish-npm:
  stage: publish
  image: node:18-alpine
  script:
    # ¿QUÉ HACE?: Crea el .npmrc que apunta el scope al registry de GitLab
    # ¿POR QUÉ?: npm necesita saber que @SCOPE/* se instala desde GitLab, no desde npmjs.com
    # ¿PARA QUÉ?: Publicar el paquete en el Package Registry del proyecto
    - |
      # URL del registry npm del proyecto
      REGISTRY_URL="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/npm/"

      # Crear .npmrc con autenticación via CI_JOB_TOKEN
      cat > .npmrc << EOF
      ${PACKAGE_SCOPE}:registry=${REGISTRY_URL}
      ${REGISTRY_URL#https:}:_authToken=${CI_JOB_TOKEN}
      EOF

      echo "Registry configurado: $REGISTRY_URL"
      cat .npmrc

    - npm publish
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/   # solo en tags semánticos
```

### Paso A3: Crear el tag y publicar

```bash
# ¿QUÉ HACE?: Crea un tag semántico que dispara la publicación del paquete
# ¿POR QUÉ?: La rule del pipeline solo permite publish en tags v*
# ¿PARA QUÉ?: Simular una release real del paquete

# Crear el tag via API
curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"tag_name":"v1.0.0","ref":"main","message":"Primera release del paquete npm"}' \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/repository/tags" \
  | python3 -c "
import sys, json
t = json.load(sys.stdin)
print(f'Tag creado: {t.get(\"name\", t)}')
"
```

### Paso A4: Verificar el paquete publicado

```bash
# ¿QUÉ HACE?: Consulta los paquetes del proyecto via API
# ¿POR QUÉ?: Confirmar que la publicación fue exitosa antes de instalar
# ¿PARA QUÉ?: Ver el nombre, versión y URL de descarga del paquete

curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/packages?package_type=npm&per_page=10" \
  | python3 -c "
import sys, json
pkgs = json.load(sys.stdin)
print(f'Paquetes npm: {len(pkgs)}')
for p in pkgs:
    print(f'  {p[\"name\"]}@{p[\"version\"]}')
    print(f'  Publicado: {p.get(\"created_at\",\"\")[:19]}')
"
```

También en la UI: `Proyecto → Deploy → Package Registry`.

---

## 🐍 Parte B: Paquete Python (PyPI)

### Paso B1: Crear el paquete Python

**`pyproject.toml`**:
```toml
[build-system]
requires = ["setuptools>=68", "wheel"]
build-backend = "setuptools.backends.legacy:build"

[project]
name = "bootcamp-lib"
version = "1.0.0"
description = "Librería Python de ejemplo — Bootcamp GitLab"
requires-python = ">=3.9"
```

**`bootcamp_lib/__init__.py`**:
```python
"""Bootcamp GitLab — librería de ejemplo."""

__version__ = "1.0.0"
__all__ = ["format_date", "short_id", "to_slug"]


def format_date(dt=None):
    """Devuelve la fecha en formato YYYY-MM-DD."""
    from datetime import datetime
    return (dt or datetime.utcnow()).strftime("%Y-%m-%d")


def short_id(length=8):
    """Genera un ID corto alfanumérico."""
    import random, string
    chars = string.ascii_lowercase + string.digits
    return ''.join(random.choices(chars, k=length))


def to_slug(text):
    """Convierte texto a slug URL-safe (como CI_COMMIT_REF_SLUG)."""
    import re
    slug = re.sub(r'[^a-z0-9]+', '-', text.lower())
    return slug.strip('-')
```

### Paso B2: Pipeline de publicación PyPI

```yaml
publish-pypi:
  stage: publish
  image: python:3.11-slim
  script:
    # ¿QUÉ HACE?: Instala las herramientas de build de Python (moderna vía PEP 517)
    - pip install --quiet build twine

    # ¿QUÉ HACE?: Construye wheel (.whl) y source distribution (.tar.gz)
    # ¿POR QUÉ?: PyPI requiere estos formatos para distribución cross-platform
    # ¿PARA QUÉ?: Los archivos en dist/ son los que se suben al registry
    - python -m build
    - ls -la dist/

    # ¿QUÉ HACE?: Sube los artifacts al Package Registry del proyecto
    - TWINE_PASSWORD=${CI_JOB_TOKEN}
        TWINE_USERNAME=gitlab-ci-token
        python -m twine upload
          --repository-url "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/pypi"
          dist/*

    - echo "✅ Paquete Python publicado en el Package Registry"
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
```

### Paso B3: Verificar e instalar

```bash
# Verificar via API
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$GITLAB_PROJECT_ID/packages?package_type=pypi" \
  | python3 -c "
import sys, json
for p in json.load(sys.stdin):
    print(f'  {p[\"name\"]}=={p[\"version\"]}')
"

# Instalar desde el Package Registry (requiere PAT)
pip install bootcamp-lib \
  --index-url "http://gitlab-ci-token:${GITLAB_TOKEN}@localhost/api/v4/projects/${GITLAB_PROJECT_ID}/packages/pypi/simple" \
  --trusted-host localhost

# Verificar la instalación:
python3 -c "
import bootcamp_lib
print(f'versión: {bootcamp_lib.__version__}')
print(f'format_date: {bootcamp_lib.format_date()}')
print(f'short_id: {bootcamp_lib.short_id()}')
print(f'to_slug: {bootcamp_lib.to_slug(\"Hello World\")}')
"
```

---

## ✅ Checklist de verificación

- [ ] Paquete npm `@SCOPE/bootcamp-utils@1.0.0` visible en `Deploy → Package Registry`
- [ ] `npm publish` exitoso en el pipeline (job en estado passed)
- [ ] API devuelve el paquete npm via `GET /projects/:id/packages?package_type=npm`
- [ ] Paquete PyPI `bootcamp-lib==1.0.0` visible en `Deploy → Package Registry`
- [ ] `pip install` desde el Package Registry instala correctamente
- [ ] `python3 -c "import bootcamp_lib; print(bootcamp_lib.__version__)"` devuelve `1.0.0`

---

## 🏆 Reto adicional

Publicar el paquete npm con información de trazabilidad del build:

```javascript
// En package.json, agregar campo de metadatos de build:
// (esto se puede hacer con jq en el pipeline)
```

```yaml
# En el pipeline, actualizar el package.json con info del commit antes de publicar:
publish-npm-with-metadata:
  script:
    - apk add --no-cache jq
    - |
      # Agregar metadatos del build al package.json sin commitear
      jq --arg sha "$CI_COMMIT_SHORT_SHA" \
         --arg pipeline "$CI_PIPELINE_ID" \
         '. + {"gitlabBuild": {"sha": $sha, "pipeline": $pipeline}}' \
         package.json > package.json.tmp && mv package.json.tmp package.json
    - cat .npmrc
    - npm publish
```

---

⬅️ **Práctica anterior:** [02 — Build y Push de Imágenes](../02-build-y-push-imagenes/README.md)
➡️ **Siguiente práctica:** [04 — Security Scanning](../04-security-scanning/README.md)

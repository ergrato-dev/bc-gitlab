# 📖 05 — Security Scanning en Pipelines

## 🎯 Objetivos de aprendizaje

- ✅ Comprender los cuatro tipos de security scanning que integra GitLab: SAST, Secret Detection, Dependency Scanning, Container Scanning
- ✅ Integrar templates de seguridad usando `include:template` en el pipeline
- ✅ Interpretar los reportes de vulnerabilidades en la UI de GitLab
- ✅ Configurar umbrales de severidad para bloquear pipelines con vulnerabilidades críticas
- ✅ Entender las diferencias entre los tipos de scan y cuándo cada uno aplica

---

## 🤔 ¿Por Qué Security Scanning en CI/CD?

La seguridad "shift left" significa detectar vulnerabilidades lo más temprano posible — en el código, antes de llegar a producción.

**Sin scanning integrado:**
```
Dev escribe código vulnerable → CI pasa (solo tests funcionales) → Deploy a staging
→ Staging pasa (no hay testing de seguridad) → Deploy a producción
→ Semanas después: CVE reportado por un investigador externo → INCIDENTE
```

**Con scanning integrado:**
```
Dev escribe código vulnerable → CI detecta en merge request
→ Widget en el MR muestra: "2 vulnerabilidades HIGH encontradas"
→ Dev corrige antes del merge → producción nunca ve el código vulnerable
```

**Analogía:** El security scanning en CI es como el control de calidad en una fábrica — lo haces en la línea de producción, no cuando el producto ya está en la tienda.

---

## 🔍 Los Cuatro Tipos de Scan

### 1. SAST — Static Application Security Testing

Analiza el código fuente sin ejecutarlo, buscando patrones de código inseguro.

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml
```

**Qué detecta:**
- SQL injection (`query = "SELECT * FROM users WHERE id = " + user_input`)
- Cross-Site Scripting (XSS)
- Path traversal
- Deserialización insegura
- Uso de funciones criptográficas débiles (MD5, SHA1)
- Inyección de comandos del sistema

**Analizadores automáticos según el lenguaje detectado:**

| Lenguaje | Analizador SAST |
|---------|----------------|
| Python | Bandit |
| JavaScript/TypeScript | ESLint Security, Semgrep |
| Java | SpotBugs, Semgrep |
| Go | Gosec |
| Ruby | Brakeman |
| PHP | phpcs-security-audit |
| C/C++ | Flawfinder, Semgrep |

GitLab detecta el lenguaje automáticamente y activa los analizadores correspondientes.

### 2. Secret Detection

Busca credenciales, tokens y secretos en el historial de commits y en el código actual.

```yaml
include:
  - template: Security/Secret-Detection.gitlab-ci.yml
```

**Qué detecta:**
- AWS Access Keys (`AKIAIOSFODNN7EXAMPLE`)
- Tokens de GitHub, GitLab, Slack, Stripe, etc.
- Contraseñas hardcodeadas en código
- Claves SSH y certificados privados
- URLs con credenciales embebidas (`https://user:pass@api.example.com`)
- Variables de entorno con nombres sospechosos + valores con formato de token

> **Importante:** Secret Detection también escanea el historial de git — detecta secretos que fueron commiteados y luego eliminados. Si aparece un secreto en el historial, debe rotarse aunque ya no esté en el código actual.

### 3. Dependency Scanning

Analiza las dependencias del proyecto buscando versiones con CVEs conocidos.

```yaml
include:
  - template: Security/Dependency-Scanning.gitlab-ci.yml
```

**Ecosistemas soportados:**

| Archivo | Ecosistema |
|---------|-----------|
| `package.json` / `package-lock.json` | npm / Node.js |
| `requirements.txt` / `Pipfile.lock` | Python (pip) |
| `pom.xml` / `build.gradle` | Java (Maven/Gradle) |
| `Gemfile.lock` | Ruby (Bundler) |
| `go.sum` | Go Modules |
| `composer.lock` | PHP (Composer) |
| `*.csproj` / `packages.config` | .NET (NuGet) |
| `conan.lock` | C/C++ (Conan) |

**Qué detecta:**
- `lodash@4.17.4` tiene CVE-2019-10744 (prototype pollution) → recomienda `lodash@4.17.21`
- `log4j@2.14.1` tiene CVE-2021-44228 (Log4Shell) → recomienda `log4j@2.17.1`

### 4. Container Scanning

Escanea una imagen Docker publicada en el registry buscando CVEs en los paquetes del sistema operativo y las librerías de runtime.

```yaml
include:
  - template: Security/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA   # imagen a escanear
    CS_DOCKERFILE_PATH: Dockerfile                        # para contextualizar hallazgos
    CS_SEVERITY_THRESHOLD: "high"                        # ignorar LOW y MEDIUM
```

**Cómo funciona:**
1. El job de `docker-build` publica la imagen en el registry
2. `container_scanning` descarga esa imagen del registry
3. Trivy (el escáner por defecto) analiza todos los paquetes instalados en la imagen
4. Compara contra la base de datos de CVEs (NVD, RHSA, Debian Security, etc.)
5. Genera el reporte `gl-container-scanning-report.json`

**Requiere** que la imagen ya esté en el registry antes de ejecutarse (usar `needs: [docker-build]`):

```yaml
container_scanning:
  needs:
    - job: docker-build
      optional: false
```

---

## 🚀 Pipeline Completo de Seguridad

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml

stages:
  - build
  - test
  - security
  - publish

# ─── BUILD ───────────────────────────────────────────────────────────────────
docker-build:
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:v1.23.0-debug
    entrypoint: [""]
  script:
    - mkdir -p /kaniko/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_JOB_TOKEN\"}}}" > /kaniko/.docker/config.json
    - /kaniko/executor
        --context $CI_PROJECT_DIR
        --dockerfile $CI_PROJECT_DIR/Dockerfile
        --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
        --cache=true
        --cache-repo $CI_REGISTRY_IMAGE/cache
  tags: [docker]

# ─── SECURITY (jobs inyectados por los templates + configuración) ─────────────
container_scanning:
  # ¿QUÉ HACE?: Sobreescribe variables del template para escanear la imagen correcta
  # ¿POR QUÉ?: El template no sabe qué imagen construimos — hay que decirle el tag exacto
  # ¿PARA QUÉ?: Escanear exactamente el mismo binario que irá a producción
  variables:
    CS_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
    CS_SEVERITY_THRESHOLD: "high"                    # fallar solo por HIGH/CRITICAL
  needs:
    - docker-build                                   # la imagen debe existir primero

# Los jobs sast, secret_detection, dependency_scanning
# se inyectan automáticamente por los templates — no necesitan definirse

# ─── PUBLISH (solo en main, después de que pase security) ────────────────────
push-release:
  stage: publish
  image: alpine:latest
  script:
    - apk add --no-cache curl
    # Etiquetar el SHA ya publicado como "latest" via manifest copy (sin re-build)
    - |
      echo "Publicar tags adicionales para main/release..."
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: on_success
```

---

## 📊 Visualizar Resultados

### En el Merge Request

Cuando el pipeline corre en contexto de MR, el widget de seguridad aparece en la vista del MR:

```
Security scanning results:
  ● 2 Critical  ● 3 High  ○ 1 Medium
  
  Nuevas vulnerabilidades:
  CRITICAL  lodash 4.17.4 — Prototype Pollution (CVE-2019-10744)
  HIGH      Dockerfile: usando python:3.10 (EOL) — actualizar a python:3.11
  HIGH      app/auth.py:42 — SQL query construida con concatenación de strings
```

### En el Pipeline (Security Tab)

```
CI/CD → Pipelines → [pipeline #123] → Security

Lista de todas las vulnerabilidades encontradas por todos los scanners,
filtrable por severidad, tipo, y estado (confirmed/dismissed/resolved).
```

### Vulnerability Report

```
Proyecto → Secure → Vulnerability report

Vista consolidada de todas las vulnerabilidades del proyecto:
  - Estado: Detected / Confirmed / Dismissed / Resolved
  - Historial de cuando apareció cada una
  - Quién la dismissó y con qué justificación
```

---

## ⚙️ Configuración Avanzada

### Umbrales de severidad

```yaml
# Fallar el pipeline solo si hay vulnerabilidades CRITICAL o HIGH
container_scanning:
  variables:
    CS_SEVERITY_THRESHOLD: "high"    # values: critical, high, medium, low, unknown

# Para SAST, la severidad se configura diferente:
sast:
  variables:
    SAST_EXCLUDED_PATHS: "spec,test,tests,tmp"  # no escanear directorios de test
```

### Ignorar vulnerabilidades conocidas (false positives)

```yaml
# En el repositorio, crear .gitlab/security-policies.yml o usar el UI de Vulnerability Report:
# Vulnerability Report → [vulnerabilidad] → Dismiss → "False positive: librería interna"
# Una vez dismissada, no vuelve a aparecer como nueva en el widget del MR
```

### Exportar reportes como artifacts

```yaml
# Los templates ya configuran esto automáticamente, pero puedes añadir:
sast:
  artifacts:
    reports:
      sast: gl-sast-report.json
    paths:
      - gl-sast-report.json
    expire_in: 1 week

dependency_scanning:
  artifacts:
    reports:
      dependency_scanning: gl-dependency-scanning-report.json
```

---

## 🖼️ Diagrama: Security Scanning en el Pipeline

![Diagrama del pipeline de security scanning](../0-assets/03-security-scanning-pipeline.svg)

> **Diagrama:** Muestra el pipeline completo con 5 stages: build → test → security → publish → cleanup. La sección central amplía el stage `security` mostrando los 4 jobs en paralelo: SAST (análisis de código fuente), Secret Detection (API keys y tokens), Dependency Scan (CVEs en npm/Maven/pip), y Container Scan (CVEs en paquetes del sistema de la imagen, usando Trivy). Los reportes convergen en tres destinos: widget del MR, Security Dashboard del grupo, y Vulnerability Report del proyecto.

---

## 🤔 Preguntas de reflexión

1. SAST detecta código potencialmente inseguro con un análisis estático. ¿Por qué puede tener falsos positivos? ¿Qué impacto tienen los falsos positivos frecuentes en el comportamiento del equipo de desarrollo hacia el security scanning?

2. Secret Detection escanea el historial de git completo. Un developer committó una AWS key hace 6 meses y luego la eliminó en el siguiente commit. ¿La key sigue siendo válida? ¿El escaneo la detectará aunque el archivo actual no la tenga? ¿Qué acción inmediata tomas?

3. Container Scanning usa Trivy por defecto. Trivy reporta que `libc6 2.31` tiene un CVE de severidad MEDIUM. El CVE existe en la imagen base `debian:bullseye`. Tú no puedes parchear libc directamente. ¿Qué opciones tienes para resolver o mitigar esto?

4. `CS_SEVERITY_THRESHOLD: "high"` hace que el scan falle solo con HIGH o CRITICAL. Un dia aparece un CVE de severidad CRITICAL en `openssl` incluida en tu imagen. El parche no existe todavía. ¿El pipeline falla indefinidamente? ¿Qué mecanismos tiene GitLab para manejar vulnerabilidades conocidas sin parche?

5. Dependency Scanning detecta `log4j 2.14.1` con CVSS 10.0 (Log4Shell). La actualización a `log4j 2.17.1` requiere cambios en la API que romperían 3 proyectos internos dependientes. ¿Cómo comunicas este hallazgo? ¿Bajo qué criterio aceptarías temporalmente la vulnerabilidad y qué controles compensatorios implementarías?

---

## 📚 Recursos adicionales

- [GitLab Security Scanning Overview](https://docs.gitlab.com/ee/user/application_security/)
- [SAST — Static Application Security Testing](https://docs.gitlab.com/ee/user/application_security/sast/)
- [Secret Detection](https://docs.gitlab.com/ee/user/application_security/secret_detection/)
- [Dependency Scanning](https://docs.gitlab.com/ee/user/application_security/dependency_scanning/)
- [Container Scanning](https://docs.gitlab.com/ee/user/application_security/container_scanning/)
- [Trivy — Container Scanner](https://trivy.dev/)

---

⬅️ **Lección anterior:** [04 — Gestión de Versiones](./04-gestion-de-versiones.md)
➡️ **Prácticas:** [01 — Container Registry Setup](../2-practicas/01-container-registry-setup/README.md)

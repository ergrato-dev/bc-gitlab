# 05 — Gestión de Licencias: Dependency Scanning y License Compliance

La gestión de licencias permite identificar las dependencias de un proyecto y sus licencias asociadas, previniendo problemas legales por uso de software con licencias restrictivas. En entornos corporativos, usar una librería con licencia GPLv3 sin saberlo puede obligar a publicar el código propietario o enfrentar demandas legales.

---

## Tipos de licencias de software

Entender las categorías de licencias es fundamental para definir políticas:

| Categoría | Licencias | Obligaciones |
|-----------|-----------|-------------|
| **Permissive** | MIT, Apache 2.0, BSD 2/3-Clause, ISC | Mantener atribución. Compatible con software propietario |
| **Weak Copyleft** | LGPL 2.1/3.0, MPL 2.0, EUPL | Cambios a la librería deben publicarse. Software que la usa puede ser propietario |
| **Strong Copyleft** | GPL 2.0/3.0, AGPL 3.0 | Todo el software que incorpore esta librería debe ser GPL (o AGPL para SaaS) |
| **Propietaria** | Commercial licenses | Pago requerido; uso restringido por contrato |
| **Sin licencia** | (ninguna) | Automáticamente copyright del autor. No se puede usar legalmente |

**Regla práctica corporativa**: Permissive = ✅ generalmente OK. Weak Copyleft = ⚠️ consultar legal. Strong Copyleft (GPL/AGPL) en software propietario = ❌ peligro legal.

---

## Dependency Scanning en GitLab CE

Dependency Scanning analiza los archivos de lock (no los de manifiesto) para identificar versiones exactas y sus CVEs conocidos.

### Ecosistemas soportados

| Ecosistema | Archivos analizados | Herramienta |
|------------|---------------------|------------|
| npm / yarn | `package-lock.json`, `yarn.lock`, `npm-shrinkwrap.json` | Gemnasium |
| Python pip | `requirements.txt`, `Pipfile.lock`, `poetry.lock` | Gemnasium |
| Ruby Bundler | `Gemfile.lock` | Gemnasium |
| Java Maven | `pom.xml` | Gemnasium |
| Java Gradle | `build.gradle` + `gradle.lockfile` | Gemnasium |
| Go modules | `go.sum` | Gemnasium |
| PHP Composer | `composer.lock` | Gemnasium |
| .NET NuGet | `packages.lock.json`, `*.deps.json` | Gemnasium |
| Rust Cargo | `Cargo.lock` | Gemnasium |

```yaml
# ¿QUÉ HACE?: Habilita Dependency Scanning en el pipeline
# ¿POR QUÉ?: Las dependencias tienen CVEs — log4shell, Spring4Shell, lodash prototipo
# ¿PARA QUÉ?: Detectar y remediar vulnerabilidades en dependencias antes de producción
include:
  - template: Security/Dependency-Scanning.gitlab-ci.yml

variables:
  DS_EXCLUDED_PATHS: "spec,test,tests,fixtures,examples"
  DS_MAX_DEPTH: 3
  GEMNASIUM_DB_REF_NAME: "master"   # Rama de la base de datos de vulnerabilidades
```

### Interpretar el reporte

```bash
# ¿QUÉ HACE?: Extrae y resume vulnerabilidades por severidad
# ¿POR QUÉ?: El reporte JSON completo puede ser enorme — resumen ejecutivo primero
# ¿PARA QUÉ?: Priorizar qué dependencia actualizar primero
cat gl-dependency-scanning-report.json | jq '
  .vulnerabilities | 
  group_by(.severity) | 
  map({
    severity: .[0].severity, 
    count: length,
    packages: [.[].location.dependency.package.name] | unique
  })'
```

```bash
# ¿QUÉ HACE?: Lista vulnerabilidades con solución disponible (upgrade path conocido)
# ¿POR QUÉ?: Las vulnerabilidades sin fix disponible requieren estrategia diferente
# ¿PARA QUÉ?: Crear tareas de remediación solo para vulnerabilidades que tienen solución
cat gl-dependency-scanning-report.json | jq '
  .vulnerabilities[] | 
  select(.solution != null and (.severity == "Critical" or .severity == "High")) |
  {
    cve: .identifiers[0].value,
    severity,
    package: .location.dependency.package.name,
    version: .location.dependency.version,
    fix: .solution
  }'
```

---

## License Scanning

License Scanning identifica la licencia de cada dependencia y la compara contra la política de licencias de la organización.

```yaml
# ¿QUÉ HACE?: Habilita License Scanning (usa el mismo job que Dependency Scanning)
# ¿POR QUÉ?: El reporte de licencias es un artifact separado del de CVEs
# ¿PARA QUÉ?: Identificar dependencias con licencias problemáticas (GPL, AGPL, etc.)
include:
  - template: Security/Dependency-Scanning.gitlab-ci.yml

# El template Dependency-Scanning genera automáticamente gl-sbom-report.cdx.json
# con las licencias de cada dependencia en formato CycloneDX
```

### Política de licencias

La política se define en el archivo `.gitlab/dependency_decisions.yml` del proyecto:

```yaml
# ¿QUÉ HACE?: Define políticas de licencias aprobadas y rechazadas
# ¿POR QUÉ?: Formalizar qué licencias puede usar la organización sin revisión manual
# ¿PARA QUÉ?: Bloquear automáticamente dependencias con licencias no aprobadas

# Licencias explícitamente aprobadas (permissive)
- - :approve
  - MIT
  - :who: legal-team
    :why: Licencia permissive estándar, compatible con software propietario
    :versions: []

- - :approve
  - Apache-2.0
  - :who: legal-team
    :why: Compatible con software propietario, requiere mantener NOTICE

- - :approve
  - BSD-3-Clause
  - :who: legal-team
    :why: Licencia permissive ampliamente aceptada

- - :approve
  - ISC
  - :who: legal-team
    :why: Equivalente funcional a MIT

# Licencias rechazadas (copyleft fuerte)
- - :reject
  - GPL-2.0
  - :who: legal-team
    :why: Copyleft fuerte — incompatible con software propietario

- - :reject
  - GPL-3.0
  - :who: legal-team
    :why: Copyleft fuerte — incompatible con software propietario

- - :reject
  - AGPL-3.0
  - :who: legal-team
    :why: Copyleft fuerte + SaaS — obliga a publicar el código del servicio

# Dependencias específicas aprobadas (excepción puntual)
- - :approve
  - LGPL-2.1
  - :who: legal-team
    :why: Weak copyleft — aprobado para uso como librería dinámica
    :versions: []
```

---

## SBOM (Software Bill of Materials)

Un SBOM es un inventario completo de todos los componentes de software, sus versiones y sus licencias. Es requerido por algunos marcos regulatorios (EO 14028 en EE.UU., CRA en Europa).

### Formatos estándar

| Formato | Estándar | Caso de uso |
|---------|----------|------------|
| CycloneDX | OWASP | Seguridad: vulnerabilidades + licencias |
| SPDX | Linux Foundation | Legal: licencias y cumplimiento |
| SWID | ISO/IEC 19770-2 | Gestión de activos de software |

```yaml
# ¿QUÉ HACE?: Genera SBOM en formato CycloneDX como artifact del pipeline
# ¿POR QUÉ?: Requisito regulatorio creciente — demostrar qué software usa el producto
# ¿PARA QUÉ?: Auditorías, gestión de vulnerabilidades, análisis legal de licencias
generate-sbom:
  stage: security
  image: cyclonedx/cyclonedx-cli:latest
  script:
    - cyclonedx-cli convert --input-file gl-sbom-report.cdx.json \
        --output-file sbom-spdx.json --output-format json_spdx_v2_3
  artifacts:
    name: "sbom-$CI_COMMIT_SHORT_SHA"
    paths:
      - gl-sbom-report.cdx.json  # Formato CycloneDX (generado por Dependency Scanning)
      - sbom-spdx.json           # Formato SPDX (para legal)
    expire_in: 1 year
  needs:
    - gemnasium-dependency_scanning
```

```bash
# ¿QUÉ HACE?: Analiza el SBOM CycloneDX para extraer todas las licencias únicas
# ¿POR QUÉ?: Ver de un vistazo qué licencias usa el proyecto
# ¿PARA QUÉ?: Revisión legal periódica del inventario de licencias
cat gl-sbom-report.cdx.json | jq '
  .components[] | 
  select(.licenses != null) |
  .licenses[].license.id // .licenses[].license.name' | \
  sort | uniq -c | sort -rn
```

---

## Integración con Dependency-Track

Dependency-Track es una plataforma open source para gestión de SBOM y vulnerabilidades a nivel de organización.

```bash
# ¿QUÉ HACE?: Sube el SBOM a Dependency-Track via API
# ¿POR QUÉ?: Centraliza SBOMs de múltiples proyectos en una sola plataforma
# ¿PARA QUÉ?: Dashboard organizacional de vulnerabilidades y compliance de licencias
upload-to-deptrack:
  stage: compliance-post
  image: alpine:3.19
  before_script:
    - apk add --no-cache curl base64
  script:
    - |
      ENCODED_BOM=$(base64 -w 0 gl-sbom-report.cdx.json)
      curl --request PUT \
        --header "X-Api-Key: $DEPTRACK_API_KEY" \
        --header "Content-Type: application/json" \
        --data "{
          \"projectName\": \"$CI_PROJECT_NAME\",
          \"projectVersion\": \"$CI_COMMIT_REF_NAME\",
          \"bom\": \"$ENCODED_BOM\"
        }" \
        "https://deptrack.company.local/api/v1/bom"
  needs:
    - gemnasium-dependency_scanning
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

---

## Flujo de trabajo completo

```
1. Developer crea un MR añadiendo una nueva dependencia
   ↓
2. Pipeline ejecuta Dependency Scanning
   ↓
3a. ¿CVE crítico detectado? → MR bloqueado. Developer debe actualizar la versión
3b. ¿Licencia rechazada? → MR bloqueado. Developer debe buscar alternativa
3c. ¿Licencia nueva no catalogada? → Notificación a legal para revisión
   ↓
4. Aprobación manual de legal (si aplica)
   ↓
5. MR aprobado y mergeado → SBOM actualizado en Dependency-Track
   ↓
6. Monitoreo continuo: Dependency-Track alerta si aparece un nuevo CVE
   en una dependencia ya en producción
```

---

## Pipeline completo con license gate

```yaml
# ¿QUÉ HACE?: Pipeline con gate de licencias que bloquea si hay licencias rechazadas
# ¿POR QUÉ?: Prevenir que dependencias GPL lleguen a software propietario
# ¿PARA QUÉ?: Compliance legal automatizada sin revisión manual en cada MR

include:
  - template: Security/Dependency-Scanning.gitlab-ci.yml

license-gate:
  stage: security
  image: python:3.12-alpine
  needs:
    - gemnasium-dependency_scanning
  script:
    - pip install cyclonedx-bom --quiet
    - |
      python3 << 'PYEOF'
      import json, sys
      
      # Licencias rechazadas por política corporativa
      REJECTED = {"GPL-2.0", "GPL-3.0", "AGPL-3.0", "SSPL-1.0"}
      
      with open("gl-sbom-report.cdx.json") as f:
          sbom = json.load(f)
      
      violations = []
      for component in sbom.get("components", []):
          for lic in component.get("licenses", []):
              lic_id = lic.get("license", {}).get("id", "")
              if lic_id in REJECTED:
                  violations.append({
                      "package": component.get("name"),
                      "version": component.get("version"),
                      "license": lic_id
                  })
      
      if violations:
          print("❌ LICENSE GATE FAILED — Licencias rechazadas detectadas:")
          for v in violations:
              print(f"  - {v['package']}@{v['version']}: {v['license']}")
          sys.exit(1)
      else:
          print("✅ LICENSE GATE PASSED — Ninguna licencia rechazada")
      PYEOF
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

---

## Mejores prácticas

- Ejecutar Dependency Scanning en cada MR y en la rama default periódicamente (CVEs nuevos pueden afectar dependencias existentes)
- Mantener `.gitlab/dependency_decisions.yml` en control de versiones y revisado por legal
- Generar SBOM en formato CycloneDX como artifact permanente (expire_in: 1 year)
- Centralizar SBOMs en Dependency-Track para visibilidad organizacional
- Licencias sin catalogar = bloquear hasta revisión legal, no asumir que está OK
- Revisar dependencias sin mantenimiento activo — riesgo de licencia Y de seguridad
- Automatizar actualizaciones de parches de seguridad con Renovate o Dependabot (configurable para GitLab)

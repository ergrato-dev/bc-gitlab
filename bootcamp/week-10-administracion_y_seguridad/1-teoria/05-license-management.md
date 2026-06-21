# 05 — Gestión de Licencias: Dependency Scanning y License Compliance

La gestión de licencias en GitLab permite identificar las dependencias de un proyecto y sus licencias asociadas, previniendo problemas legales por uso de software con licencias restrictivas.

## Dependency Scanning

Dependency Scanning analiza las dependencias declaradas en archivos como `package.json`, `Gemfile`, `requirements.txt`, `pom.xml`, `go.mod`, etc., identificando cada dependencia, su versión y las vulnerabilidades conocidas (CVEs) asociadas.

Se habilita en CE con:
```yaml
include:
  - template: Security/Dependency-Scanning.gitlab-ci.yml
```

El reporte `gl-dependency-scanning-report.json` se integra en el MR widget mostrando todas las dependencias vulnerables, su severidad y la versión mínima que corrige la vulnerabilidad.

## License Compliance

License Compliance identifica las licencias de cada dependencia y las compara contra una política de licencias permitidas/denegadas definida por la organización. Por ejemplo, se puede denegar licencias copyleft fuertes como GPLv3 si la política corporativa no las permite.

La política se configura en el proyecto en Settings → CI/CD → License Compliance, definiendo qué licencias están aprobadas (`allowed`) y cuáles denegadas (`denied`).

## License Database

GitLab mantiene una base de datos de licencias que asigna identificadores SPDX (Software Package Data Exchange) a cada licencia detectada. Esto permite clasificarlas consistentemente según su tipo: permissive (MIT, Apache 2.0, BSD), weak copyleft (LGPL, MPL) o strong copyleft (GPL, AGPL).

## Flujo de trabajo

1. El job de Dependency Scanning se ejecuta en la etapa `test`
2. El job de License Scanning se ejecuta en paralelo
3. Los reportes se fusionan en el artefacto final
4. El MR widget muestra:
   - Dependencias nuevas introducidas por el MR
   - Licencias que violan la política
   - Vulnerabilidades en dependencias

## Integración con otros sistemas

Los reportes pueden exportarse vía API para integrarlos con herramientas de gestión de vulnerabilidades como DefectDojo, Dependency-Track o sistemas SBOM (Software Bill of Materials).

## Mejores prácticas

- Ejecutar Dependency Scanning en cada MR y en la rama default periódicamente
- Mantener una política de licencias documentada y aprobada por legal
- Automatizar la aprobación de licencias comunes (MIT, Apache 2.0) para no bloquear el desarrollo
- Generar SBOM en formato CycloneDX o SPDX como artefacto del pipeline

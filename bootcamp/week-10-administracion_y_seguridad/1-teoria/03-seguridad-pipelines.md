# 03 — Seguridad en Pipelines: SAST, Secret Detection y DAST

GitLab integra herramientas de seguridad directamente en el pipeline CI/CD, permitiendo detectar vulnerabilidades antes de que lleguen a producción sin necesidad de herramientas externas.

## SAST (Static Application Security Testing)

SAST analiza el código fuente en busca de vulnerabilidades conocidas (OWASP Top 10, CWE) sin ejecutar la aplicación. Se ejecuta en la etapa `test` del pipeline. GitLab CE incluye analizadores para múltiples lenguajes: bandit (Python), eslint (JavaScript), spotbugs (Java), brakeman (Ruby), gosec (Go), entre otros.

Para habilitar SAST, basta incluir el template en `.gitlab-ci.yml`:
```yaml
include:
  - template: Security/SAST.gitlab-ci.yml
```

Los resultados se almacenan en el artifact `gl-sast-report.json` y se visualizan en el Merge Request widget y en Security → Vulnerability Report.

## Secret Detection

Detecta secretos hardcodeados (API keys, tokens, contraseñas, claves SSH) en el código fuente y en el historial de commits. Se habilita con:
```yaml
include:
  - template: Security/Secret-Detection.gitlab-ci.yml
```

El escaneo busca patrones conocidos para AWS, GCP, Azure, GitHub, GitLab tokens, JWT, claves privadas y más de 100 tipos de secretos. Los hallazgos aparecen en el MR widget y en el pipeline security tab.

## DAST (Dynamic Application Security Testing)

DAST analiza la aplicación en ejecución simulando ataques reales. Está disponible en GitLab Ultimate, aunque en CE se puede integrar OWASP ZAP manualmente como un job personalizado. DAST es complementario a SAST: SAST analiza el código, DAST analiza el comportamiento en runtime.

## Security Dashboard

GitLab CE proporciona un dashboard básico de seguridad por proyecto en Security → Configuration y Security → Vulnerability Report. Se pueden ver las vulnerabilidades detectadas agrupadas por severidad (Critical, High, Medium, Low) y gestionar su ciclo de vida (detección, confirmación, resolución, dismiss).

## Mejores Prácticas

- Ejecutar SAST en cada push a cualquier rama
- Bloquear merges si se detectan vulnerabilidades críticas
- Revisar falsos positivos periódicamente
- Combinar SAST con Secret Detection en la etapa test
- Mantener los analizadores actualizados (usan imágenes docker con versiones periódicas)

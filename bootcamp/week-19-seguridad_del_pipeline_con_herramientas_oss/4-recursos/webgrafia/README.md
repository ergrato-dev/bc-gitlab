# 🔗 Enlaces — Semana 19

Comprobados en noviembre de 2026 contra la documentación de GitLab 19.2, Semgrep 1.185, Gitleaks 8.30, OSV-Scanner 2.7 y Trivy 0.76.

## Los que vas a tener abiertos toda la semana

| Enlace | Para qué |
|---|---|
| [Semgrep — Rule syntax](https://semgrep.dev/docs/writing-rules/rule-syntax) | Cada operador de una regla: `patterns`, `pattern-either`, `pattern-not`, metavariables |
| [Semgrep — Testing rules](https://semgrep.dev/docs/writing-rules/testing-rules) | `ruleid`, `ok` y `semgrep --test` |
| [Gitleaks](https://github.com/gitleaks/gitleaks#readme) | Subcomandos `git` y `dir`, `--redact`, formatos de informe y `.gitleaksignore` |
| [OSV-Scanner — Configuration](https://google.github.io/osv-scanner/configuration/) | `osv-scanner.toml`: `IgnoredVulns`, `ignoreUntil` y `reason` |
| [Trivy — Filtering](https://trivy.dev/docs/v0.76/guide/configuration/filtering/) | `--severity`, `--ignorefile` y `.trivyignore.yaml` con `expired_at` |
| [Unit test reports](https://docs.gitlab.com/ci/testing/unit_test_reports/) | Cómo llega un JUnit al widget de la merge request y cómo compara con la rama de destino |

## GitLab

| Enlace | Para qué |
|---|---|
| [Artifacts reports](https://docs.gitlab.com/ci/yaml/artifacts_reports/) | `reports:junit` (Free) frente a `reports:sast` y el resto, cuyo widget es Ultimate |
| [Auto-merge: require a successful pipeline](https://docs.gitlab.com/user/project/merge_requests/auto_merge/) | *Pipelines must succeed* y los pipelines saltados |
| [Merge requests API](https://docs.gitlab.com/api/merge_requests/) | `detailed_merge_status` y el `PUT …/merge` con `sha` |
| [Application security](https://docs.gitlab.com/user/application_security/) | Qué escáneres nativos hay y en qué tier: lo que esta semana sustituye |
| [CI/CD components](https://docs.gitlab.com/ci/components/) | `spec:inputs`, `type: array` y `options`, los del componente `seguridad` |

## Fuentes de datos

| Enlace | Para qué |
|---|---|
| [osv.dev](https://osv.dev/) | Cada aviso que cita OSV-Scanner, con sus versiones afectadas y corregidas |
| [OSV schema](https://ossf.github.io/osv-schema/) | El formato común de avisos que usan GitHub, PyPI, npm y Go |
| [SARIF 2.1.0](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html) | El formato del informe que guardan los cuatro jobs: `level`, `ruleId`, `locations` |
| [Trivy — Cache](https://trivy.dev/docs/v0.76/guide/configuration/cache/) | Dónde vive la base de datos y por qué la caché del job ahorra dos minutos |

---

[← Volver a la Semana 19](../../README.md)

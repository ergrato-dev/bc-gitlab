# 📖 Glosario — Semana 19

Términos que aparecen esta semana. El nombre real de la feature va en inglés entre paréntesis, y el **tier** cuando aplica.

El glosario acumulado de toda la plataforma está en [glosario-global](../../../docs/glosario-global.md).

---

## A

**Ancla de YAML** (`&nombre`, `*nombre`) — Escribe un valor una vez y lo repite en el mismo archivo. En `app`, las rutas de `imagen` y las `rutas_imagen` de `seguridad` son la misma lista, y tienen que serlo.

## C

**`ci_must_pass`** — Valor de `detailed_merge_status` de una merge request que no se puede fusionar porque su pipeline no está en verde. Con él, `PUT …/merge` responde `405`.

**Contraseña quemada** — Un secreto que estuvo en un commit empujado. Se da por comprometido aunque se borre en el commit siguiente: se rota primero y se decide después.

**CVSS** (*Common Vulnerability Scoring System*) — Puntuación de 0 a 10 de la gravedad de una vulnerabilidad. El umbral `alta` del componente bloquea en OSV-Scanner desde 7,0, y también cuando el aviso no tiene CVSS.

**CWE** (*Common Weakness Enumeration*) — Catálogo de tipos de debilidad. Las tres reglas del componente: CWE-95 (`eval`), CWE-78 (comando por shell) y CWE-295 (TLS sin verificar).

## D

**Dependency Scanning** — El escáner de dependencias nativo de GitLab. **Ultimate**: su plantilla comprueba `$GITLAB_FEATURES` y en CE no crea ningún job. En CE lo sustituye OSV-Scanner.

**Digest** (`@sha256:…`) — La huella del contenido de una imagen. Una etiqueta puede apuntar mañana a otra imagen; un digest, no. Las cuatro imágenes del componente van por etiqueta y digest.

## E

**Excepción** — Un hallazgo que se acepta por escrito, con motivo, fecha y dueño: `.gitleaksignore`, `osv-scanner.toml` (`ignoreUntil`, `reason`), `.trivyignore.yaml` (`expired_at`, `statement`) o `// nosemgrep: <regla> -- <motivo>`.

## F

**Falso positivo** — Un hallazgo que no es un problema. Se marca en la línea, con motivo; no se baja el umbral ni se quita la regla.

## G

**GHSA** — Identificador de un aviso de la base de datos de GitHub (`GHSA-35jh-r3h4-6jhm`). OSV-Scanner los cita junto a los CVE.

**Gitleaks** — Escáner de secretos de código abierto. `gitleaks git` lee cada commit del historial; necesita `GIT_DEPTH: "0"` en el job.

## H

**Huella** (*fingerprint*) — Identificador de un hallazgo de Gitleaks: `<commit>:<archivo>:<regla>:<línea>`. Es lo que va en `.gitleaksignore`, con el comentario del motivo justo encima.

## I

**`imagen.tar`** — La imagen que el componente `imagen` escribe como tarball con `tar: true` (Kaniko `--tar-path`), también en merge requests. Artefacto de una hora que lee Trivy.

## J

**JUnit** — Formato XML de resultados de pruebas. `artifacts:reports:junit` es **Free** y lleva cada hallazgo al *Test summary* de la merge request, comparado con la rama de destino.

## L

**Lockfile** — `package-lock.json`: las versiones exactas de todas las dependencias, también las transitivas. Es lo que lee OSV-Scanner.

## O

**OSV** (*Open Source Vulnerabilities*) — Base de datos y formato común de avisos de vulnerabilidades de paquetes de código abierto, en [osv.dev](https://osv.dev/).

**OSV-Scanner** — Escáner de Google que compara un lockfile con OSV. No escribe JUnit: el componente lo construye desde su salida en markdown.

## P

**Pipelines must succeed** — Ajuste del proyecto (`only_allow_merge_if_pipeline_succeeds`) que impide fusionar con el pipeline en rojo, para cualquier rol. **Free**. Es lo que convierte un escáner en una puerta.

**Puerta** — Un control que impide avanzar, no que avisa. Un escáner con `allow_failure: true` no es una puerta.

## R

**Regla de Semgrep** — Un patrón escrito en el lenguaje del código (`eval($X)`), con `patterns`, `pattern-either` y `pattern-not`. Se prueba con `semgrep --test` contra código anotado con `ruleid` y `ok`.

## S

**SARIF** (*Static Analysis Results Interchange Format*) — Formato JSON estándar de hallazgos de análisis. Los cuatro jobs lo guardan 30 días, también con los hallazgos bajo el umbral.

**SAST** (*Static Application Security Testing*) — Análisis del código fuente sin ejecutarlo. La plantilla `Jobs/SAST` de GitLab es **Free**, pero su widget en la merge request es **Ultimate** y su job lleva `allow_failure: true`. En CE, Semgrep con reglas propias.

**Secret push protection** — Bloqueo de un secreto en el momento del push. **Ultimate**. En CE, Gitleaks en el pipeline, con el secreto ya en el servidor, o un server hook (Semana 07).

**Semgrep** — Escáner de código que compara árboles de sintaxis, no texto. En el componente, con `--metrics=off` y solo reglas propias.

## T

**Trivy** — Escáner de Aqua Security para imágenes, sistemas de archivos y configuración. Distingue los paquetes del sistema base de las dependencias del lenguaje.

**Trivy DB** — La base de datos de vulnerabilidades de Trivy: 143 MB comprimida, 1,8 GB en disco. La caché del job (`when: always`) evita descargarla en cada pipeline.

## U

**Umbral** — Gravedad desde la que un escáner hace fallar el job. Input `umbral` del componente: `critica`, `alta` (por defecto) o `media`.

## V

**Vulnerability report** — La lista de vulnerabilidades de un proyecto en GitLab, con su estado. **Ultimate**. En CE, los SARIF de cada pipeline y un issue con `due_date` por hallazgo abierto.

---

[← Volver a la Semana 19](../README.md)

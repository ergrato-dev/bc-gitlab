# Semana 19 — Seguridad del pipeline con herramientas OSS

> Hasta ahora el pipeline de `app` respondía a una sola pregunta: ¿funciona? Esta semana responde también a otra: ¿es seguro fusionarlo? Cuatro escáneres libres, cada uno mirando una cosa distinta (el código, los secretos del historial, las dependencias declaradas y la imagen que se va a desplegar), empaquetados como el tercer componente de `ci/componentes` y con sus hallazgos dentro de la merge request. El primero que lo nota es la imagen que ya tienes: su base trae una CVE alta que nadie había mirado.

---

## 🎯 Objetivos de la Semana

Al terminar serás capaz de:

- Explicar qué ve y qué no ve cada clase de escáner (SAST, secretos, dependencias, imagen), y por qué hacen falta los cuatro
- Separar lo que GitLab CE da gratis (las plantillas de SAST, secretos y contenedores, que solo dejan un JSON) de lo que es Ultimate (el widget de seguridad, el informe de vulnerabilidades, el escaneo de dependencias)
- Escribir reglas de Semgrep propias, probarlas con `semgrep --test` y ejecutarlas sin red ni telemetría
- Escanear el historial completo con Gitleaks y saber por qué borrar un secreto en otro commit no lo arregla
- Leer un lockfile con OSV-Scanner y una imagen con Trivy, y explicar por qué el uno encuentra lo que el otro no
- Publicar un componente de seguridad con un umbral como input, y llevar sus hallazgos al widget de tests de la merge request con JUnit
- Decidir qué hacer con un hallazgo (arreglarlo, aceptarlo con fecha o rotar el secreto) y dejar la decisión versionada y con dueño

---

## 📋 Prerrequisitos

- **Semana 18 completada**: la instancia endurecida
- **Semana 16 completada**: `k8s-app` ejecuta los jobs de `app` y `ci/componentes`. Sus pods necesitan salida a internet: Trivy descarga su base de datos (143 MB comprimidos, 1,8 GB en disco) y OSV-Scanner consulta `api.osv.dev`
- **Semana 15 completada**: la caché compartida en SeaweedFS (la base de datos de Trivy viaja por ella)
- **Semana 13 completada**: `imagen@1` construye y sube la imagen de `app` en cada commit de `main`, a partir del `Dockerfile` de la práctica 01
- **Semana 12 completada**: sabes probar un componente en el SHA de su propio commit y publicar una versión; `main` de `ci/componentes` protegida sin force push
- **Semana 09 completada**: `app` no fusiona con el pipeline en rojo (`only_allow_merge_if_pipeline_succeeds`)
- **Semana 07 completada**: `main` de `app` protegida sin force push, `CODEOWNERS` en `app` y el job `gobernanza` que exige la aprobación de sus dueños
- **Perfil `base` levantado y el clúster k3d en marcha** — ver [perfiles](../../docs/perfiles-de-laboratorio.md). Esta semana no añade servicios: los escáneres son imágenes que se descargan al ejecutar el job
- Docker en tu máquina, para ejecutar los cuatro escáneres en local en la práctica 01

---

## 🗂️ Estructura de la Semana

```
week-19-seguridad_del_pipeline_con_herramientas_oss/
├── README.md                  # Este archivo
├── rubrica-evaluacion.md      # Cómo se evalúa
├── checks.json                # Las 16 comprobaciones automáticas
├── 0-assets/                  # Diagramas
├── 1-teoria/                  # 7 archivos, un concepto cada uno
├── 2-practicas/               # 4 prácticas sobre tu instancia
├── 3-proyecto/                # La capa 19 de tu plataforma
├── 4-recursos/                # Libros, vídeos y enlaces
└── 5-glosario/                # Términos de esta semana
```

---

## 📝 Contenidos

### Teoría

| Archivo | Tema | Duración |
|---|---|:--:|
| [01 — El pipeline como superficie](1-teoria/01-el-pipeline-como-superficie.md) | Las cuatro clases de escáner, qué ve cada una, qué da CE gratis y qué es Ultimate, por qué las herramientas directamente | 20 min |
| [02 — SAST con Semgrep](1-teoria/02-sast-con-semgrep.md) | Patrones, reglas propias frente al registro, `--test`, sin telemetría, `nosemgrep` | 20 min |
| [03 — Secretos con Gitleaks](1-teoria/03-secretos-con-gitleaks.md) | El historial entero, `GIT_DEPTH`, `--redact`, la huella, por qué borrar no basta y la rotación primero | 20 min |
| [04 — Dependencias con OSV-Scanner](1-teoria/04-dependencias-con-osv-scanner.md) | El lockfile, la base de datos OSV, CVSS, transitivas, códigos de salida y `osv-scanner.toml` | 20 min |
| [05 — Imágenes con Trivy](1-teoria/05-imagenes-con-trivy.md) | Paquetes del sistema y del lenguaje, la imagen base, lo que sobra dentro, el tarball, la base de datos y su caché | 20 min |
| [06 — Informes, umbrales y la puerta](1-teoria/06-informes-umbrales-y-la-puerta.md) | JUnit al widget de tests, SARIF como archivo, un umbral para todos, `allow_failure` y la fusión bloqueada | 20 min |
| [07 — Excepciones que caducan](1-teoria/07-excepciones-que-caducan.md) | Arreglar, aceptar con fecha o rotar; los cuatro archivos de excepción, su dueño y los plazos | 20 min |

### Prácticas

| Práctica | Qué haces | Duración |
|---|---|:--:|
| [01 — Las reglas y los escáneres](2-practicas/01-las-reglas-y-los-escaneres.md) | Los cuatro escáneres en tu terminal contra `app`, tres reglas de Semgrep propias y sus pruebas | 50 min |
| [02 — El componente `seguridad`](2-practicas/02-el-componente-seguridad.md) | `templates/seguridad.yml`, el input `tar` de `imagen`, la prueba en `ci/componentes` y `1.3.0` en el catálogo | 50 min |
| [03 — `app` detrás de los cuatro](2-practicas/03-app-detras-de-los-cuatro.md) | `app` consume `seguridad@1`, Trivy tumba la imagen base, la corriges y `main` queda escaneada | 50 min |
| [04 — La merge request envenenada](2-practicas/04-la-merge-request-envenenada.md) | Un `eval`, una dependencia vulnerable y una contraseña en una MR; la fusión rechazada; arreglo, dueño para las excepciones y una huella con motivo | 50 min |

### Proyecto

La **capa 19** de tu plataforma: nada se fusiona en `app` sin pasar cuatro escáneres. Detalles en [3-proyecto](3-proyecto/README.md).

---

## ⏱️ Distribución del Tiempo (8 horas)

| Bloque | Tiempo |
|---|:--:|
| Teoría (7 archivos) | 2 h 20 |
| Prácticas (4 × 50 min) | 3 h 20 |
| Proyecto | 1 h 40 |
| Revisión y verificación | 40 min |
| **Total** | **8 h 00** |

> [!NOTE]
> Los hallazgos que veas no van a ser exactamente los de este material. Las bases de datos de vulnerabilidades cambian a diario: una CVE que hoy es `HIGH` mañana tiene arreglo, y salen otras nuevas. Lo que sí es estable es la imagen base de la Semana 13, `node:22.23.3-alpine3.24`: no cambia, y sus CVE conocidas tampoco desaparecen.

---

## 🧭 Lo que entra esta semana y lo que espera

| Lo que quieres | Semana 19 | Después |
|---|---|---|
| Ver los hallazgos en la merge request | JUnit al widget de tests (Free), uno por escáner | El widget de seguridad con hallazgos nuevos y resueltos: Ultimate |
| Un inventario de vulnerabilidades por proyecto | Los SARIF de cada pipeline, 30 días | Vulnerability report y Security Dashboard: Ultimate |
| Saber qué lleva la imagen | Trivy enumera sus paquetes para escanearlos | El SBOM como artefacto firmado (Semana 20) |
| Que solo se despliegue lo escaneado | La fusión exige el pipeline en verde | Firma con Cosign y un gate de Conftest antes de desplegar (Semana 20) |
| Bloquear un secreto antes del push | Gitleaks en el pipeline, cuando ya está en el servidor | Secret push protection: Ultimate. En CE, un server hook (Semana 07) con Gitleaks |
| Volver a escanear sin commits nuevos | El pipeline de `main` en cada fusión | Un escaneo programado de la imagen publicada, con el SLO de la Semana 21 |

---

## 🎩 Trucos y atajos

| Truco | Cómo |
|---|---|
| El escáner del pipeline, en tu terminal y con la misma versión | `docker run --rm -v "$PWD:/src" -w /src <imagen@digest> …`: la misma línea que el job, antes de empujar |
| Probar una regla de Semgrep antes de publicarla | `semgrep --test <carpeta>`: `reglas.yaml` y `reglas.ts` con comentarios `// ruleid:` y `// ok:` |
| Semgrep dentro de un job de GitLab | `unset SEMGREP_IN_DOCKER`: la imagen da por hecho que el código está en `/src` y aborta si no |
| Secretos solo en lo que no has commiteado | `gitleaks dir .` lee la carpeta; `gitleaks git .` lee el historial |
| La huella exacta para `.gitleaksignore` | `Fingerprint` en el informe JSON o SARIF: `<commit>:<archivo>:<regla>:<línea>` |
| Volver a pintar un informe de Trivy sin escanear otra vez | `trivy convert --format table --severity HIGH,CRITICAL trivy.json` |
| La base de datos de Trivy que no se vuelve a bajar | `cache:` con `when: always`: sin él, un job que falla no la guarda y el siguiente la descarga entera |
| Todos los hallazgos de un pipeline por API | `GET /projects/:id/pipelines/:pipeline_id/test_report \| jq '.test_suites[].test_cases[] \| select(.status=="failed")'` |

---

## 📌 Entregables

1. `templates/seguridad.yml` en `ci/componentes`: cuatro escáneres con imagen fijada por digest, reglas de Semgrep propias y un umbral como input
2. El input `tar` en `templates/imagen.yml`, y `1.3.0` publicada en el catálogo con el componente `seguridad`
3. `app` consumiendo `seguridad@1`, con los cuatro escáneres en el stage `seguridad` y ninguno con `allow_failure`
4. El `Dockerfile` de `app` sobre una base sin CVE altas y sin npm dentro
5. El último pipeline de `main` en verde, con los cuatro informes JUnit
6. La merge request envenenada: rechazada en rojo, arreglada y fusionada en verde
7. `.gitleaksignore` con la huella y su motivo, y `CODEOWNERS` dando dueño a los tres archivos de excepción
8. `docs/seguridad.md` en `app`: umbral, plazos y proceso de excepciones (proyecto)

---

## ✅ Verificación

```bash
./scripts/verificar-semana.sh 19
```

Las 16 comprobaciones tienen que pasar.

Lo que el script **no** puede comprobar es que entiendas por qué falló cada escáner, que la contraseña de la práctica 04 se diera por quemada antes de escribir la excepción, ni que `docs/seguridad.md` sirva para decidir el próximo hallazgo. Lo evalúa la rúbrica.

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Semana 18 — Administración, hardening y actualizaciones](../week-18-administracion_hardening_y_actualizaciones/README.md) | **Semana 19** | Semana 20 — Cadena de suministro y políticas como código |

[← Volver al inicio del bootcamp](../README.md)

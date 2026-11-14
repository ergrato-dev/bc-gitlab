# Semana 09 — CI/CD: fundamentos, runner, artifacts y cache

> Hasta hoy "los tests pasan" significaba "los pasé yo, en mi máquina". Esta semana `app` tiene un runner propio y un pipeline que construye, prueba, empaqueta y audita cada cambio en un contenedor limpio, y una merge request en rojo deja de poder fusionarse.

---

## 🎯 Objetivos de la Semana

Al terminar serás capaz de:

- Explicar qué hace GitLab y qué hace el runner en un pipeline, y registrar un runner de proyecto con el flujo de *authentication token*
- Escribir un `.gitlab-ci.yml` con stages, jobs, `default`, jobs ocultos con `extends` y `workflow:rules`, y validarlo con la API antes de empujarlo
- Diagnosticar un job por su estado, su `failure_reason` y su log, y saber qué puede hacer `CI_JOB_TOKEN`
- Distinguir artefacto y caché por su función: publicar informes JUnit, cobertura y un paquete, y cachear dependencias con una clave por lockfile
- Explicar por qué una merge request no comparte caché con `main`
- Convertir un script de auditoría en un job con un token de proyecto mínimo y una variable enmascarada y oculta, y exigir el pipeline en verde para fusionar

---

## 📋 Prerrequisitos

- **Semana 08 completada**: `main`, `release/*` y `v*` protegidos, server hook activo, `scripts/gobernanza.sh` en `main` con la regla de issues solo para `main`
- **`app` con tests** que pasan con `npm test` (Semana 02) y **Node 22 o superior** en tu máquina
- **Perfil `base` levantado**, con el servicio `gitlab-runner` en marcha: `docker compose --profile base ps` — ver [perfiles-de-laboratorio](../../docs/perfiles-de-laboratorio.md)
- **`revisor-<dominio>` con Maintainer en `app`** y `GITLAB_ADMIN_TOKEN` en `~/.bc-gitlab`, como en las Semanas 06 a 08
- **`jq` instalado** y un clon local de `app` que firma commits

---

## 🗂️ Estructura de la Semana

```
week-09-ci_cd_fundamentos/
├── README.md                  # Este archivo
├── rubrica-evaluacion.md      # Cómo se evalúa
├── checks.json                # Las 23 comprobaciones automáticas
├── 0-assets/                  # Diagramas
├── 1-teoria/                  # 7 archivos, un concepto cada uno
├── 2-practicas/               # 4 prácticas sobre tu instancia
├── 3-proyecto/                # La capa 9 de tu plataforma
├── 4-recursos/                # Libros, vídeos y enlaces
└── 5-glosario/                # Términos de esta semana
```

---

## 📝 Contenidos

### Teoría

| Archivo | Tema | Duración |
|---|---|:--:|
| [01 — Del commit al pipeline](1-teoria/01-del-commit-al-pipeline.md) | CI, entrega y despliegue continuos; pipeline, stage, job y runner; qué crea un pipeline; Auto DevOps sin runner | 15 min |
| [02 — Anatomía de `.gitlab-ci.yml`](1-teoria/02-anatomia-del-gitlab-ci-yml.md) | El archivo de `app` línea a línea, `default`, `extends`, variables `CI_*` y la API de lint | 20 min |
| [03 — El runner](1-teoria/03-el-runner.md) | Tipos y ejecutores, el registro con *authentication token*, `config.toml` y el problema de `localhost` | 20 min |
| [04 — La vida de un job](1-teoria/04-la-vida-de-un-job.md) | Estados, `failure_reason`, el log, reintentos, `allow_failure`, `interruptible` y `CI_JOB_TOKEN` | 15 min |
| [05 — Artefactos](1-teoria/05-artefactos.md) | `paths`, `when`, `expire_in`, informes JUnit, cobertura y descargas por API | 20 min |
| [06 — Caché](1-teoria/06-cache.md) | Artefacto no es caché, `key:files`, `policy`, la caché local y las claves `-protected` | 15 min |
| [07 — La gobernanza en el pipeline](1-teoria/07-la-gobernanza-en-el-pipeline.md) | El job `gobernanza`, el token de proyecto, la variable oculta y *Pipelines must succeed* | 15 min |

### Prácticas

| Práctica | Qué haces | Duración |
|---|---|:--:|
| [01 — El runner de `app`](2-practicas/01-el-runner-de-app.md) | Limpiar lo pendiente, variables de instancia, crear y registrar el runner, y un job de prueba | 50 min |
| [02 — El primer pipeline](2-practicas/02-el-primer-pipeline.md) | TypeScript y lockfile, `.gitlab-ci.yml` validado, merge request y `main` en verde | 50 min |
| [03 — Artefactos y caché, medidos](2-practicas/03-artefactos-y-cache-medidos.md) | Claves de caché en los logs, el paquete descargado, la insignia de cobertura y una regresión en rojo | 50 min |
| [04 — La gobernanza como job](2-practicas/04-la-gobernanza-como-job.md) | Token de proyecto y variable oculta, el job `gobernanza`, *Pipelines must succeed* comprobado con un `405` | 50 min |

### Proyecto

La **capa 9** de tu plataforma: cada commit se construye y se prueba solo. Detalles en [3-proyecto](3-proyecto/README.md).

---

## ⏱️ Distribución del Tiempo (8 horas)

| Bloque | Tiempo |
|---|:--:|
| Teoría (7 archivos) | 2 h 00 |
| Prácticas (4 × 50 min) | 3 h 20 |
| Proyecto | 2 h 00 |
| Revisión y verificación | 40 min |
| **Total** | **8 h 00** |

> [!TIP]
> La primera vez, cada job descarga su imagen y la del *helper* del runner. Los primeros pipelines tardan minutos; los siguientes, segundos. No midas nada en el primero.

---

## 🧭 Lo que entra esta semana y lo que espera

El pipeline de esta semana es deliberadamente pequeño. Cada pieza que falta tiene su semana, y empezar por ella ahora sería aprenderla sin el problema que resuelve.

| Lo que quieres | Semana 09 | Después |
|---|---|---|
| Que no haya pipelines duplicados | `workflow:rules`, copiado | Las reglas desmontadas (Semana 10) |
| Secretos en el pipeline | Un token de solo lectura sin proteger, con el riesgo escrito | Variables protegidas y por entorno, *secure files* (Semana 10) |
| Que los jobs no esperen al stage entero | Stages en serie | `needs` y pipelines hijos (Semana 11) |
| No copiar el YAML en `infra` | Un job oculto y `extends` | Componentes del catálogo (Semana 12) |
| Publicar el paquete | Artefacto de una semana | Registro de paquetes (Semana 13) |
| Más de un runner | Uno de proyecto, `concurrent = 1` | Flota etiquetada y caché compartida (Semana 15) |

---

## 🎩 Trucos y atajos

| Truco | Cómo |
|---|---|
| Validar `.gitlab-ci.yml` sin empujarlo | `jq -n --rawfile c .gitlab-ci.yml '{content: $c}'` y `POST .../ci/lint` |
| Ver el YAML final con `extends` resuelto | `GET .../ci/lint?ref=main&include_merged_yaml=true \| jq -r .merged_yaml` |
| Leer el log de un job sin colores | `GET .../jobs/<id>/trace \| sed 's/\x1b\[[0-9;]*m//g'` |
| Por qué falló un job, sin abrir el log | `GET .../jobs/<id> \| jq .failure_reason` |
| Esperar a que termine un pipeline | `until ... jq -e '.status \| IN("success","failed","canceled")'; do sleep 10; done` |
| Relanzar el pipeline de una merge request | `POST .../merge_requests/<iid>/pipelines` |
| El último paquete de `main`, sin saber el job | `GET .../jobs/artifacts/main/download?job=package` |
| El test que falló, sin leer el log | `GET .../pipelines/<id>/test_report \| jq '.test_suites[].test_cases[] \| select(.status=="failed") \| .name'` |
| Saber si un job usó la caché | `grep -E 'Checking cache\|Successfully extracted'` en su log |
| Pasar un token de una API a otra sin verlo | `jq -j .token \| curl ... --data-urlencode "value@-"` |
| Registrar un runner sin el token en los argumentos | `CI_SERVER_TOKEN="$RT" docker compose exec -e CI_SERVER_TOKEN gitlab-runner gitlab-runner register ...` |
| Por qué no se puede fusionar | `GET .../merge_requests/<iid> \| jq -r .detailed_merge_status` |

---

## 📌 Entregables

1. Runner de proyecto `docker-app` registrado en el contenedor del compose, `online`, y las variables de instancia `CI_API_V4_URL` y `CI_SERVER_URL` apuntando a `http://gitlab:8888`
2. `package-lock.json`, `tsconfig.json` y el script `test:ci` en `main`
3. `.gitlab-ci.yml` con `workflow:rules`, stages `build`, `test` y `package`, imágenes con versión completa y caché por lockfile
4. El último pipeline de `main` en verde, con informe de tests, cobertura y el `.tgz` como artefacto
5. La insignia de cobertura
6. Token de proyecto `gobernanza-ci` y variable `GOBERNANZA_TOKEN` enmascarada y oculta; el job `gobernanza` y `/.gitlab-ci.yml` en `CODEOWNERS`
7. *Pipelines must succeed* activado
8. ADR-007 en la wiki y la sección "El pipeline" en `CONTRIBUTING.md`

---

## ✅ Verificación

```bash
./scripts/verificar-semana.sh 09
```

Las 23 comprobaciones tienen que pasar. La 2 lee una variable de instancia y necesita `GITLAB_ADMIN_TOKEN`.

Lo que el script **no** puede comprobar es que el ADR-007 diga qué se descartó, que sus números sean los que mediste, ni que el token de `gobernanza` no haya pasado nunca por tu terminal. Eso lo evalúa la rúbrica.

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Semana 08 — GitLab Flow, releases y métricas de flujo](../week-08-gitlab_flow_releases_y_metricas/README.md) | **Semana 09** | [Semana 10 — Reglas, variables y secretos](../week-10-reglas_variables_y_secretos/README.md) |

[← Volver al inicio del bootcamp](../README.md)

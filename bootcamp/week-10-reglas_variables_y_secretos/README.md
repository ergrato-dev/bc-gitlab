# Semana 10 — Reglas, variables y secretos

> Desde la Semana 09, `app` tiene un pipeline que corre igual en cada cambio. Esta semana decides qué job entra en cada pipeline y qué secreto llega a cada job. Al terminar, una merge request que solo cambia documentación no gasta un minuto de runner, `staging` y `production` reciben cada uno su credencial, y una merge request no recibe ninguna de las dos.

---

## 🎯 Objetivos de la Semana

Al terminar serás capaz de:

- Escribir `rules` con `if`, `changes` y `exists`, y predecir qué jobs entran en un pipeline antes de empujarlo
- Explicar línea a línea el `workflow:rules` de `app`, ponerle nombre a cada pipeline y cancelar los jobs obsoletos de forma automática
- Decir de dónde sale cada variable de un job y cuál gana cuando dos tienen el mismo nombre
- Elegir entre proteger, enmascarar y ocultar una variable, y demostrar qué recibe un pipeline de merge request
- Limitar un secreto a un entorno con `environment_scope`, y saber por qué eso no es una barrera de seguridad
- Elegir entre una variable de tipo archivo y un *secure file*, después de comprobar quién puede descargar cada uno
- Inventariar los secretos del pipeline y rotar uno sin que su valor aparezca nunca

---

## 📋 Prerrequisitos

- **Semana 09 completada**: runner `docker-app` en línea, `main` en verde con `build`, `test` y `package`, `gobernanza` en cada merge request, `GOBERNANZA_TOKEN` enmascarada y oculta, *Pipelines must succeed* activado
- **`main`, `release/*` y `v*` protegidos** (Semanas 07 y 08): las variables protegidas solo llegan a esas refs
- **`revisor-<dominio>` con Maintainer en `app`** y **`dev-<dominio>` con Developer** (Semana 03), y `GITLAB_ADMIN_TOKEN` en `~/.bc-gitlab`
- **Perfil `base` levantado** — ver [perfiles-de-laboratorio](../../docs/perfiles-de-laboratorio.md)
- **`jq` y `ssh-keygen`** instalados, y un clon local de `app` que firma commits

---

## 🗂️ Estructura de la Semana

```
week-10-reglas_variables_y_secretos/
├── README.md                  # Este archivo
├── rubrica-evaluacion.md      # Cómo se evalúa
├── checks.json                # Las 18 comprobaciones automáticas
├── 0-assets/                  # Diagramas
├── 1-teoria/                  # 7 archivos, un concepto cada uno
├── 2-practicas/               # 4 prácticas sobre tu instancia
├── 3-proyecto/                # La capa 10 de tu plataforma
├── 4-recursos/                # Libros, vídeos y enlaces
└── 5-glosario/                # Términos de esta semana
```

---

## 📝 Contenidos

### Teoría

| Archivo | Tema | Duración |
|---|---|:--:|
| [01 — `rules`: cuándo entra un job](1-teoria/01-rules-cuando-entra-un-job.md) | `if`, `changes`, `exists`, `when`, la primera regla que coincide y los errores que no avisan | 20 min |
| [02 — `workflow`: cuándo nace un pipeline](1-teoria/02-workflow-cuando-nace-un-pipeline.md) | Los orígenes de un pipeline, el bloque de `app` desmontado, `name` y `auto_cancel` | 15 min |
| [03 — Variables: de dónde salen y quién gana](1-teoria/03-variables-de-donde-salen.md) | YAML, proyecto, grupo, instancia y pipeline; la precedencia comprobada; quién puede pasar variables | 20 min |
| [04 — Proteger, enmascarar, ocultar](1-teoria/04-proteger-enmascarar-ocultar.md) | Qué hace cada atributo, qué recibe un pipeline de merge request y qué no protege ninguno | 20 min |
| [05 — Entornos como ámbito](1-teoria/05-entornos-como-ambito.md) | `environment`, `environment_scope`, el despliegue manual y lo que en CE sustituye a los entornos protegidos | 15 min |
| [06 — Variables de archivo y *secure files*](1-teoria/06-variables-de-archivo-y-secure-files.md) | `variable_type=file`, *secure files* y quién puede descargar cada uno | 15 min |
| [07 — Secretos fuera del YAML y del log](1-teoria/07-secretos-fuera-del-yaml-y-del-log.md) | Cómo se filtra un secreto, `CI_DEBUG_TRACE`, el inventario, la rotación y los gestores externos | 15 min |

### Prácticas

| Práctica | Qué haces | Duración |
|---|---|:--:|
| [01 — Las reglas de `app`](2-practicas/01-las-reglas-de-app.md) | Nombre y cancelación automática, `changes` en `build` y `test`, `package` solo donde se publica, y una merge request de documentación sin build | 50 min |
| [02 — Variables y precedencia](2-practicas/02-variables-y-precedencia.md) | Una sonda que enseña de dónde sale cada valor, la precedencia comprobada y las variables de pipeline restringidas | 50 min |
| [03 — Secretos por entorno](2-practicas/03-secretos-por-entorno.md) | `DEPLOY_TOKEN` por entorno, `scripts/deploy.sh`, `deploy-staging` automático y `deploy-production` manual | 50 min |
| [04 — Archivos secretos y fugas](2-practicas/04-archivos-secretos-y-fugas.md) | Un *secure file* descargado desde la merge request de un Developer, la clave como variable de archivo y el despliegue a `production` | 50 min |

### Proyecto

La **capa 10** de tu plataforma: cero secretos en el YAML, cero pipelines que no hacen falta. Detalles en [3-proyecto](3-proyecto/README.md).

---

## ⏱️ Distribución del Tiempo (8 horas)

| Bloque | Tiempo |
|---|:--:|
| Teoría (7 archivos) | 2 h 00 |
| Prácticas (4 × 50 min) | 3 h 20 |
| Proyecto | 2 h 00 |
| Revisión y verificación | 40 min |
| **Total** | **8 h 00** |

> [!IMPORTANT]
> Esta semana creas credenciales de mentira (`DEPLOY_TOKEN`) y una clave SSH que no abre ninguna máquina. Trátalas como si fueran de verdad: que no aparezcan en la terminal, en un archivo del repositorio ni en un log. Los hábitos se aprenden con lo que no importa.

---

## 🧭 Lo que entra esta semana y lo que espera

| Lo que quieres | Semana 10 | Después |
|---|---|---|
| Desplegar de verdad | `scripts/deploy.sh` simulado: demuestra qué secretos recibe | Despliegue real, review apps y *rollback* (Semana 14) |
| Que los jobs no esperen al stage entero | Stages en serie | `needs` y pipelines hijos (Semana 11) |
| Avisar antes de que caduque un token | La fecha en `docs/secretos.md` | Pipeline programado que la vigila (Semana 11) |
| Compartir las reglas entre proyectos | `.npm` y `.deploy` como jobs ocultos | Componentes del catálogo (Semana 12) |
| Detectar un secreto en un commit | La revisión y la comprobación del YAML | Gitleaks en el pipeline (Semana 19) |
| Secretos fuera de GitLab | `id_tokens` explicado, sin gestor | Vault u OpenBao con OIDC: fuera del alcance del bootcamp |

---

## 🎩 Trucos y atajos

| Truco | Cómo |
|---|---|
| Qué jobs entrarían en el pipeline de un push, sin crearlo | `POST .../ci/lint` con `dry_run=true`, `ref=<rama>` e `include_jobs=true`, y `.jobs[].name` |
| Saber por qué no nació un pipeline | El `400` de `POST .../pipeline` dice `Review the workflow:rules` |
| Ver los nombres de los pipelines | `GET .../pipelines \| jq -r '.[] \| "\(.id) \(.name)"'` |
| Qué variables tiene el proyecto, sin valores | `GET .../variables \| jq -r '.[] \| "\(.key) \(.environment_scope) p=\(.protected) m=\(.masked) h=\(.hidden)"'` |
| Cambiar una variable con ámbito | `PUT .../variables/<key>?filter%5Benvironment_scope%5D=production` (los corchetes codificados: `curl` los toma por un patrón) |
| Leer la longitud de un secreto en un job, no el secreto | `echo "${#DEPLOY_TOKEN}"` |
| Leer el último despliegue de un entorno | `GET .../deployments?environment=production&status=success&order_by=id&sort=desc&per_page=1` |
| Lanzar un job manual | `POST .../jobs/<id>/play` |
| Rotar un token de proyecto sin verlo | `POST .../access_tokens/<id>/rotate \| jq -j .token \| curl ... PUT .../variables/<key> --data-urlencode "value@-"` |
| Restringir quién pasa variables a un pipeline | `PUT /projects/:id` con `ci_pipeline_variables_minimum_override_role=maintainer` |

---

## 📌 Entregables

1. `workflow` con `name` y `auto_cancel:on_new_commit: interruptible`; `build` y `test` con `changes` en merge requests; `package` solo en `main`, `release/*` y tags
2. Variables de pipeline restringidas a Maintainer
3. `DEPLOY_TOKEN` para `staging` y para `production`, protegida y enmascarada; `DEPLOY_SSH_KEY` como variable de archivo protegida solo para `production`
4. `scripts/deploy.sh`, `deploy-staging` automático en `main` y `deploy-production` manual, no interrumpible y sin bloquear el pipeline; un despliegue correcto en cada entorno
5. Ningún *secure file* con una clave privada
6. `GOBERNANZA_TOKEN` rotado sin verse
7. `docs/secretos.md` con el inventario y el ADR-007 ampliado en la wiki

---

## ✅ Verificación

```bash
./scripts/verificar-semana.sh 10
```

Las 18 comprobaciones tienen que pasar.

Lo que el script **no** puede comprobar es que ningún secreto haya pasado por tu terminal o por un log, que el inventario diga quién puede leer cada secreto de verdad, ni que la merge request de la fuga se cerrara sin fusionar. Eso lo evalúa la rúbrica.

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Semana 09 — CI/CD: fundamentos, runner, artifacts y cache](../week-09-ci_cd_fundamentos/README.md) | **Semana 10** | Semana 11 — Pipelines DAG y multiproyecto |

[← Volver al inicio del bootcamp](../README.md)

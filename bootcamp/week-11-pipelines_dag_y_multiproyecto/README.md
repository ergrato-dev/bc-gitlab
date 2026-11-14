# Semana 11 — Pipelines DAG y multiproyecto

> Hasta hoy, el pipeline de `app` es un tren: ningún vagón sale hasta que llega el último del anterior. Esta semana cada job espera solo a lo que necesita, la documentación se revisa en un pipeline hijo, cada versión de `main` avisa a un proyecto nuevo, `infra/entornos`, y un pipeline programado te avisa antes de que caduque un secreto.

---

## 🎯 Objetivos de la Semana

Al terminar serás capaz de:

- Convertir un pipeline por stages en un DAG con `needs`, y medir cuánto tiempo ahorra de verdad
- Decidir qué artefactos descarga cada job y cuándo un `needs` tiene que ser opcional
- Separar una parte del pipeline en un pipeline hijo, con su propio `workflow` y su estado reflejado en el padre
- Explicar cuándo un pipeline hijo dinámico compensa y cuándo es complejidad gratuita
- Disparar el pipeline de otro proyecto, pasarle datos y entender con los permisos de quién se ejecuta
- Acotar el job token con la lista de permitidos y usarlo para leer un artefacto de otro proyecto, que es lo que CE ofrece en lugar de `needs:project`
- Impedir que dos despliegues al mismo entorno se pisen, con `resource_group` y su modo de proceso
- Programar un pipeline sin que ese pipeline despliegue nada que no debe

---

## 📋 Prerrequisitos

- **Semana 10 completada**: `workflow` con `name` y `auto_cancel`, `.npm` con `changes`, `package` solo en `main`, `release/*` y tags, `deploy-staging` automático y `deploy-production` manual con un despliegue correcto en cada entorno, y `docs/secretos.md` en `main`
- **Subgrupo `infra` vacío** dentro de tu grupo raíz (Semana 03): esta semana nace su primer proyecto
- **`revisor-<dominio>` con Maintainer en `app`** y la función `fusionar` de la práctica 01 de la Semana 10
- **Runner `docker-app` en línea** (Semana 09) y sin más trabajos en cola: esta semana mides duraciones
- **Perfil `base` levantado** — ver [perfiles-de-laboratorio](../../docs/perfiles-de-laboratorio.md)
- **`jq`** instalado y un clon local de `app` que firma commits

---

## 🗂️ Estructura de la Semana

```
week-11-pipelines_dag_y_multiproyecto/
├── README.md                  # Este archivo
├── rubrica-evaluacion.md      # Cómo se evalúa
├── checks.json                # Las 18 comprobaciones automáticas
├── 0-assets/                  # Diagramas
├── 1-teoria/                  # 8 archivos, un concepto cada uno
├── 2-practicas/               # 4 prácticas sobre tu instancia
├── 3-proyecto/                # La capa 11 de tu plataforma
├── 4-recursos/                # Libros, vídeos y enlaces
└── 5-glosario/                # Términos de esta semana
```

---

## 📝 Contenidos

### Teoría

| Archivo | Tema | Duración |
|---|---|:--:|
| [01 — De stages a DAG](1-teoria/01-de-stages-a-dag.md) | Qué espera cada job, `needs`, `needs: []` y el camino crítico | 15 min |
| [02 — `needs`: artefactos y opcionales](1-teoria/02-needs-artefactos-y-opcionales.md) | Qué se descarga, `optional`, `dotenv`, los límites y `needs:project` (Premium) | 15 min |
| [03 — Pipelines padre-hijo](1-teoria/03-pipelines-padre-hijo.md) | `trigger:include`, `strategy: mirror`, el `workflow` del hijo y las merge requests | 15 min |
| [04 — Pipelines hijos dinámicos](1-teoria/04-pipelines-hijos-dinamicos.md) | YAML generado por un job, cuándo compensa y cuándo no | 15 min |
| [05 — Pipelines multiproyecto](1-teoria/05-pipelines-multiproyecto.md) | `trigger:project`, los permisos de quién, las variables que viajan y las que no | 15 min |
| [06 — El job token entre proyectos](1-teoria/06-job-token-entre-proyectos.md) | `CI_JOB_TOKEN`, la lista de permitidos y leer un artefacto ajeno en CE | 15 min |
| [07 — `resource_group`](1-teoria/07-resource-groups.md) | Concurrencia por recurso, los cuatro modos de proceso y los despliegues obsoletos | 15 min |
| [08 — Pipelines programados](1-teoria/08-pipelines-programados.md) | Cron, propietario, frecuencia mínima y por qué un programado puede desplegar sin querer | 15 min |

### Prácticas

| Práctica | Qué haces | Duración |
|---|---|:--:|
| [01 — De stages a DAG](2-practicas/01-de-stages-a-dag.md) | Mides el pipeline de `main`, lo conviertes en DAG y vuelves a medir | 50 min |
| [02 — Un pipeline hijo para la documentación](2-practicas/02-un-pipeline-hijo-para-la-documentacion.md) | `ci/docs.yml` con `markdownlint` y `caducidades`, disparado solo si cambia un `.md` | 50 min |
| [03 — El disparo a `infra`](2-practicas/03-disparo-a-infra.md) | Creas `infra/entornos`, lo disparas desde `main` y lees el paquete de `app` con el job token | 50 min |
| [04 — Concurrencia y calendario](2-practicas/04-concurrencia-y-calendario.md) | `resource_group` en los despliegues y un pipeline programado que no despliega | 50 min |

### Proyecto

La **capa 11** de tu plataforma: el pipeline escala y deja de ser un tren en serie. Detalles en [3-proyecto](3-proyecto/README.md).

---

## ⏱️ Distribución del Tiempo (8 horas)

| Bloque | Tiempo |
|---|:--:|
| Teoría (8 archivos) | 2 h 00 |
| Prácticas (4 × 50 min) | 3 h 20 |
| Proyecto | 2 h 00 |
| Revisión y verificación | 40 min |
| **Total** | **8 h 00** |

> [!IMPORTANT]
> Esta semana `main` dispara un pipeline en otro proyecto. Si el pipeline de `infra/entornos` falla, el de `main` falla con él: es lo que pide `strategy: mirror`. No lo desactives para salir del paso; lee el log de abajo.

---

## 🧭 Lo que entra esta semana y lo que espera

| Lo que quieres | Semana 11 | Después |
|---|---|---|
| Reutilizar el YAML entre `app` e `infra` | Se copia, a sabiendas | Componentes del catálogo (Semana 12) |
| Que `infra/entornos` despliegue de verdad | Registra qué versión de `app` le llega | Despliegue real y *rollback* (Semana 14) |
| Pasar datos tipados entre pipelines | `variables` en el job de disparo | `spec:inputs` (Semana 12) |
| Descargar artefactos de otro proyecto con `needs:project` | Premium: el job token y la API de artefactos | — |
| Que la plataforma se cree desde código | `infra/entornos` creado por API | `infra/terraform` (Semana 24) |
| Avisar en un canal cuando el programado falla | El correo de pipeline fallido | Webhooks y ChatOps (Semana 17) |

---

## 🎩 Trucos y atajos

| Truco | Cómo |
|---|---|
| Ver los pipelines hijos por API | `GET .../pipelines?source=parent_pipeline`: sin el `source`, la lista los esconde |
| Ir del job de disparo al pipeline que creó | `GET .../pipelines/<id>/bridges \| jq '.[] \| {name, d: .downstream_pipeline.web_url}'` |
| Ver qué jobs esperan a un recurso | `GET .../resource_groups/<key>/upcoming_jobs` |
| Saber quién ejecuta un programado | `GET .../pipeline_schedules \| jq '.[] \| {description, owner: .owner.username}'` |
| Quedarte con un programado huérfano | `POST .../pipeline_schedules/<id>/take_ownership` |
| Lanzar un programado ahora, sin esperar al cron | `POST .../pipeline_schedules/<id>/play` o `glab schedule run <id>` |
| Pasar un dato de un job al pipeline de otro proyecto | `artifacts:reports:dotenv` en el job y `variables: { X: $X }` en el de disparo, con `needs` sobre él |
| Probar la regla de un programado sin crear el programado | `POST .../ci/lint` con `dry_run=true` no simula `schedule`: lanza el programado con `play` sobre una rama de prueba |

---

## 📌 Entregables

1. `test` y `gobernanza` con `needs: []`; `package` con `needs: [build, test]`; los despliegues encadenados con `needs`
2. `ci/docs.yml` disparado como pipeline hijo con `strategy: mirror`, solo si cambia un `.md`, y un pipeline hijo en verde
3. `infra/entornos` con variables de pipeline restringidas a Maintainer, disparado desde `main` y en verde
4. El job token de `app` acotado, con `infra/entornos` en su lista de permitidos
5. `resource_group` `staging` y `production`; `staging` en modo `newest_first`
6. Un pipeline programado activo que ejecuta `caducidades` y nada más, con una ejecución en verde
7. El ADR-008 en la wiki y la medición antes y después del DAG en `docs/metricas.md`

---

## ✅ Verificación

```bash
./scripts/verificar-semana.sh 11
```

Las 18 comprobaciones tienen que pasar.

Lo que el script **no** puede comprobar es que la medición del DAG sea honrada, que el ADR-008 diga por qué `infra/entornos` es un proyecto aparte y no una carpeta de `app`, ni que hayas visto fallar `caducidades` con una fecha cercana. Eso lo evalúa la rúbrica.

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Semana 10 — Reglas, variables y secretos](../week-10-reglas_variables_y_secretos/README.md) | **Semana 11** | Semana 12 — Componentes CI/CD y catálogo |

[← Volver al inicio del bootcamp](../README.md)

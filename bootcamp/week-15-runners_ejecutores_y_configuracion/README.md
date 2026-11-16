# Semana 15 — Runners: ejecutores y configuración

> Desde la Semana 09, un solo runner, `docker-app`, ejecuta todo: los tests de `app`, los componentes de `ci/componentes` y los despliegues de `infra/entornos`, con la misma caché local y los mismos permisos para el código de una rama cualquiera que para el de `main`. Esta semana se convierte en una flota: tres runners con un solo proceso, enrutados por etiquetas y por protección de rama, con un daemon de Docker solo donde hace falta y una caché en S3 que comparten todos. Todo es Free.

---

## 🎯 Objetivos de la Semana

Al terminar serás capaz de:

- Distinguir el proceso `gitlab-runner`, los runners que atiende y el ejecutor de cada uno, y saber cuál de los tres es la respuesta cuando un job no arranca
- Leer y escribir un `config.toml` sabiendo qué parte manda el servidor y qué parte vive solo en tu máquina
- Elegir ejecutor por lo que aísla, no por costumbre
- Enrutar jobs con etiquetas, alcance (instancia, grupo, proyecto) y `run_untagged`, y predecir qué runner coge cada uno
- Reservar un runner para las ramas protegidas y explicar por qué la caché también se separa por protección
- Dar a un job un daemon de Docker con el privilegio limitado al servicio `dind`, no al job
- Compartir la caché entre runners con un almacén S3 propio
- Rotar el token de un runner, pausarlo y retirarlo sin dejar restos en `config.toml`

---

## 📋 Prerrequisitos

- **Semana 09 completada**: `docker-app` de proyecto en `app`, con `tag_list=docker` y `run_untagged=true`, registrado en el servicio `gitlab-runner` del compose
- **Semana 11 completada**: `docker-app` asignado también a `infra/entornos`, y `concurrent = 2` en `config.toml`
- **Semana 13 completada**: el `Dockerfile` de `app` y su imagen construida con kaniko por el componente `imagen`
- **Semana 14 completada**: `infra/entornos` despliega en `staging` y `production` con el job `desplegar`, disparado desde `main` de `app`, y `main` de `infra/entornos` protegida
- **Perfil `base` levantado con el `docker-compose.yml` actual del repositorio**: trae el servicio `cache-s3` — ver [perfiles-de-laboratorio](../../docs/perfiles-de-laboratorio.md)
- **`jq`** y **`envsubst`** (paquete `gettext-base` en Debian y Ubuntu), y los clones locales de `app` e `infra/entornos` que firman commits

---

## 🗂️ Estructura de la Semana

```
week-15-runners_ejecutores_y_configuracion/
├── README.md                  # Este archivo
├── rubrica-evaluacion.md      # Cómo se evalúa
├── checks.json                # Las 16 comprobaciones automáticas
├── 0-assets/                  # Diagramas
├── 1-teoria/                  # 8 archivos, un concepto cada uno
├── 2-practicas/               # 4 prácticas sobre tu instancia
├── 3-proyecto/                # La capa 15 de tu plataforma
├── 4-recursos/                # Libros, vídeos y enlaces
└── 5-glosario/                # Términos de esta semana
```

---

## 📝 Contenidos

### Teoría

| Archivo | Tema | Duración |
|---|---|:--:|
| [01 — Anatomía del runner](1-teoria/01-anatomia-del-runner.md) | Proceso, runner y ejecutor; el gestor, el `system_id` y cómo pide trabajo | 15 min |
| [02 — El `config.toml`](1-teoria/02-el-config-toml.md) | Sección global y `[[runners]]`, `concurrent` y `limit`, qué decide el servidor y qué tu máquina | 15 min |
| [03 — Los ejecutores](1-teoria/03-los-ejecutores.md) | Shell, Docker, Docker Autoscaler, Instance, Kubernetes, Custom: qué aísla cada uno | 15 min |
| [04 — Etiquetas y alcance](1-teoria/04-etiquetas-y-alcance.md) | Runners de instancia, grupo y proyecto, `tags`, `run_untagged`, `locked` y cómo se elige runner | 15 min |
| [05 — Runners protegidos](1-teoria/05-runners-protegidos.md) | `ref_protected`, el tiempo máximo y por qué la caché se separa por protección | 15 min |
| [06 — Docker dentro de Docker](1-teoria/06-docker-in-docker.md) | `dind`, TLS, el privilegio limitado al servicio, el socket del host y cuándo basta kaniko | 15 min |
| [07 — La caché distribuida](1-teoria/07-la-cache-distribuida.md) | Caché en S3, `Shared`, la ruta de cada clave y SeaweedFS como almacén | 15 min |
| [08 — Operar la flota](1-teoria/08-operar-la-flota.md) | Estado y versión, pausa, rotación de tokens, `verify --delete` y la plantilla versionada | 15 min |

### Prácticas

| Práctica | Qué haces | Duración |
|---|---|:--:|
| [01 — La caché compartida](2-practicas/01-la-cache-compartida.md) | Levantas `cache-s3` y `docker-app` deja de guardar la caché en su disco | 50 min |
| [02 — El runner dind](2-practicas/02-el-runner-dind.md) | Un segundo runner en el mismo proceso, con Docker solo para `probar-imagen` | 50 min |
| [03 — El runner protegido](2-practicas/03-el-runner-protegido.md) | Un runner de grupo para `infra`, solo para ramas protegidas, que hace todos los despliegues | 50 min |
| [04 — Operar la flota](2-practicas/04-operar-la-flota.md) | Rotas un token, pausas un runner, limpias `config.toml` y versionas su plantilla | 50 min |

### Proyecto

La **capa 15** de tu plataforma: la ejecución está enrutada y la caché es compartida. Detalles en [3-proyecto](3-proyecto/README.md).

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
> Esta semana cambia el `docker-compose.yml`: hay un servicio nuevo, `cache-s3`, con su clave en `.env`. Actualiza tu clon del repositorio del bootcamp, copia las tres variables nuevas de `.env.example` a tu `.env`, cambia `RUNNER_CACHE_SECRET_KEY` y vuelve a levantar el perfil `base` antes de la práctica 01. GitLab no se reconfigura: solo arranca el servicio nuevo.

---

## 🧭 Lo que entra esta semana y lo que espera

| Lo que quieres | Semana 15 | Después |
|---|---|---|
| Runners que crecen con la cola y desaparecen al vaciarse | Tres runners fijos en un proceso | Ejecutor Kubernetes en k3d (Semana 16) |
| Saber cuánto cuesta cada pipeline | El tiempo de cada job por runner, por API | `docs/finops.md` con el coste por minuto (Semana 16) |
| Que solo las ramas protegidas lleguen a la máquina de despliegue | Runner `ref_protected` en el grupo `infra` | Entornos protegidos: Premium. Sustituto: el de esta semana más la rama protegida de la Semana 14 |
| Ver las métricas del runner en un panel | `gitlab-runner list`, la API y los logs | `listen_address` y Prometheus (Semana 21) |
| Construir imágenes sin privilegios | kaniko (Semana 13) | Igual: `dind` solo para lo que necesita un daemon |
| Runners de instancia para todos los grupos | Desactivados en `app` e `infra/entornos` | Gobierno de la instancia (Semana 24) |

---

## 🎩 Trucos y atajos

| Truco | Cómo |
|---|---|
| Qué proceso atiende a cada runner | `GET /runners/:id/managers`, campo `system_id`: si dos runners comparten `system_id`, comparten proceso |
| Por qué un job se queda en `pending` | En el job, `tag_list`; en los runners del proyecto, `GET /projects/:id/runners?tag_list=<tag>&status=online`. Vacío = nadie puede cogerlo |
| Limpiar de `config.toml` los runners que ya borraste en GitLab | `gitlab-runner verify --delete`, tras comprobar con `verify` a secas que solo sale inválido el que quieres quitar |
| Privilegio solo para `dind`, no para el job | `allowed_privileged_services` y `allowed_privileged_images` en `[runners.docker]` |
| Que `dind` no gaste el límite de Docker Hub | `command: ["--registry-mirror=http://registry-cache:5000"]` en el servicio |
| Ver si la caché viene del almacén compartido | En el log del job, `Downloading cache from http://cache-s3:8333/…` |
| Saber qué runners hay detrás de un proyecto, también los de grupo | GraphQL `project { runners { nodes { description runnerType } } }` |
| Pegar `gitlab-runner list` en un issue sin regalar tokens | No lo pegues: imprime el token de cada runner. Usa la API |

---

## 📌 Entregables

1. El servicio `cache-s3` en marcha y `docker-app` guardando la caché en él
2. El runner `dind-app` en `app`, en el mismo proceso que `docker-app`, sin jobs sin etiqueta y con el privilegio limitado al servicio `dind`
3. El job `probar-imagen` de `app` en verde en `dind-app`, y `app` sin runners de instancia
4. El runner de grupo `deploy-infra` en `infra`, solo para ramas protegidas, con tiempo máximo
5. `infra/entornos` desplegando desde `deploy-infra`, sin `docker-app` ni runners de instancia
6. `runners/config.toml.plantilla` en `infra/entornos`, sin tokens
7. El ADR-012 en la wiki de `app`

---

## ✅ Verificación

```bash
./scripts/verificar-semana.sh 15
```

Las 16 comprobaciones tienen que pasar.

Lo que el script **no** puede comprobar es que la caché viaje de verdad por `cache-s3`, que un job de una rama sin proteger no llegue nunca a `deploy-infra`, ni que `concurrent` y `limit` estén bien repartidos: eso vive en `config.toml` y en los logs, no en la API. Lo evalúa la rúbrica.

> [!NOTE]
> Ninguna comprobación de semanas anteriores se rompe. Lo que cambia es una pieza de la Semana 11: `infra/entornos` deja de tener `docker-app` asignado y solo usa `deploy-infra`. La práctica 03 de la Semana 11 lo sigue enseñando como paso intermedio.

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Semana 14 — Entornos, review apps y feature flags](../week-14-entornos_review_apps_y_feature_flags/README.md) | **Semana 15** | [Semana 16 — Runners en Kubernetes y FinOps](../week-16-runners_en_kubernetes_y_finops/README.md) |

[← Volver al inicio del bootcamp](../README.md)

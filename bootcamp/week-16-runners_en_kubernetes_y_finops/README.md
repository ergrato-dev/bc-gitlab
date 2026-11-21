# Semana 16 — Runners en Kubernetes y FinOps

> La flota de la Semana 15 tiene un techo fijo: `concurrent = 3` en una máquina que está encendida haya jobs o no. Esta semana, los jobs de `app` pasan a un runner con ejecutor Kubernetes, en un clúster k3d de tu laboratorio. Cada job es un pod que nace y muere con él, y el techo pasa a ser lo que quepa en el clúster. El `.gitlab-ci.yml` no cambia ni una línea. Antes del relevo mides, y después vuelves a medir, porque "más rápido" y "más barato" son dos preguntas distintas. `docs/finops.md` contesta la segunda con cifras. Todo es Free.

---

## 🎯 Objetivos de la Semana

Al terminar serás capaz de:

- Explicar qué hace el gestor del runner, qué hay en el pod de un job y qué cambia (y qué no) al pasar del ejecutor `docker` al `kubernetes`
- Levantar un clúster k3d en la red del laboratorio, con su propio `kubeconfig` y Docker Hub detrás de `registry-cache`
- Instalar el runner con el chart oficial de Helm en una versión fijada, con el token y la clave S3 en `Secret` y un rol limitado a lo que el ejecutor usa
- Fijar `requests` y `limits` para los jobs, y leer qué pasa cuando un pod no cabe
- Hacer un relevo de runner sin cortar el servicio y con vuelta atrás
- Distinguir `concurrent` de una `ResourceQuota`, y el autoescalado de pods del de nodos
- Medir duración, cola y minutos de job por API, y convertirlos en coste por minuto y por pipeline

---

## 📋 Prerrequisitos

- **Semana 15 completada**: `docker-app` (`docker`), `dind-app` (`dind`) y `deploy-infra` (`deploy`) en línea, la caché en `cache-s3`, y `RID_DOCKER`, `RID_DIND` y `RID_DEPLOY` en `~/.bc-gitlab-s15`
- **Semana 13 completada**: el componente `imagen` construye con kaniko y pide su token del registry a `$CI_SERVER_URL`
- **Perfil `base` levantado y observabilidad apagada** — ver [perfiles-de-laboratorio](../../docs/perfiles-de-laboratorio.md#semana-16--runners-en-kubernetes-11-12-gb)
- **`k3d` `5.9.0`, `kubectl` `1.34`-`1.36` y `helm` `3.22.1`** instalados — ver [setup-entorno](../../docs/setup-entorno.md#k3d-y-kubectl--desde-la-semana-16)
- **`sudo`** en tu máquina, por si hay que subir el límite de inotify (práctica 01, paso 2)
- Los clones locales de `app` e `infra/entornos` que firman commits, y `HR`, el token de `revisor-<tu-dominio>` (Semana 13)

---

## 🗂️ Estructura de la Semana

```
week-16-runners_en_kubernetes_y_finops/
├── README.md                  # Este archivo
├── rubrica-evaluacion.md      # Cómo se evalúa
├── checks.json                # Las 12 comprobaciones automáticas
├── 0-assets/                  # Diagramas
├── 1-teoria/                  # 6 archivos, un concepto cada uno
├── 2-practicas/               # 4 prácticas sobre tu instancia y tu clúster
├── 3-proyecto/                # La capa 16 de tu plataforma
├── 4-recursos/                # Libros, vídeos y enlaces
└── 5-glosario/                # Términos de esta semana
```

---

## 📝 Contenidos

### Teoría

| Archivo | Tema | Duración |
|---|---|:--:|
| [01 — Por qué un runner en Kubernetes](1-teoria/01-por-que-kubernetes.md) | Gestor, pod y clúster; qué cambia para el pipeline y qué se queda en `dind-app` | 20 min |
| [02 — k3d en el laboratorio](1-teoria/02-k3d-en-el-laboratorio.md) | Nodos que son contenedores, `--network`, el `kubeconfig` aparte, el espejo de Docker Hub y la memoria | 20 min |
| [03 — El chart del runner](1-teoria/03-el-chart-del-runner.md) | Versión del chart, archivo de valores, `Secret`, `rbac.rules` y qué pasa en cada `helm upgrade` | 20 min |
| [04 — El pod de un job](1-teoria/04-el-pod-de-un-job.md) | `build`, `helper` y servicios; `requests`, `limits`, cuánto puede pedir un job y qué pasa si no cabe | 20 min |
| [05 — Escalar con la cola](1-teoria/05-escalar-con-la-cola.md) | `concurrent` frente a `ResourceQuota`, autoescalado de nodos, Docker Autoscaler e `instance` | 20 min |
| [06 — FinOps de CI](1-teoria/06-finops-de-ci.md) | Duración, cola y minutos de job; coste por minuto y por pipeline; qué es de pago y qué se usa en CE | 20 min |

### Prácticas

| Práctica | Qué haces | Duración |
|---|---|:--:|
| [01 — El clúster](2-practicas/01-el-cluster.md) | Un clúster k3d en `bc-gitlab-network` que llega a GitLab, al registry y a `cache-s3` | 50 min |
| [02 — El runner en el clúster](2-practicas/02-el-runner-en-el-cluster.md) | `k8s-app` en pausa, el chart instalado y su cuenta de servicio con lo justo | 50 min |
| [03 — El relevo](2-practicas/03-el-relevo.md) | Mides con `docker-app`, lo pausas, mides con Kubernetes y versionas la línea base | 50 min |
| [04 — Escalar y medir](2-practicas/04-escalar-y-medir.md) | `concurrent` frente a una cuota, el consumo real de cada job y los values en `infra/entornos` | 50 min |

### Proyecto

La **capa 16** de tu plataforma: la ejecución autoescala y sabes lo que cuesta cada pipeline. Detalles en [3-proyecto](3-proyecto/README.md).

---

## ⏱️ Distribución del Tiempo (8 horas)

| Bloque | Tiempo |
|---|:--:|
| Teoría (6 archivos) | 2 h 00 |
| Prácticas (4 × 50 min) | 3 h 20 |
| Proyecto | 2 h 00 |
| Revisión y verificación | 40 min |
| **Total** | **8 h 00** |

> [!IMPORTANT]
> El clúster suma alrededor de 1,5 GB a tu laboratorio, más lo que gaste cada job. Esta semana **no** levantes observabilidad. Entre sesiones, `k3d cluster stop bootcamp` libera la memoria sin perder nada; `k3d cluster start bootcamp` lo devuelve con el runner dentro.
>
> **Desde la Semana 17, los pipelines de `app` corren en el clúster**: sin `k3d cluster start bootcamp`, sus jobs se quedan en `pending`. En las semanas que no caben con él (21 y 23, ver [perfiles-de-laboratorio](../../docs/perfiles-de-laboratorio.md)), la vuelta atrás de la práctica 03 al revés: `docker-app` activo, `k8s-app` en pausa, y el clúster parado.

---

## 🧭 Lo que entra esta semana y lo que espera

| Lo que quieres | Semana 16 | Después |
|---|---|---|
| Que la flota crezca con la cola | Un pod por job, con `concurrent` como techo | Autoescalado de nodos: solo con un proveedor de nube; fuera del laboratorio |
| Saber cuánto cuesta cada pipeline | `docs/finops.md` con coste por minuto y la línea base | Duración de pipeline como SLO, partiendo de esta media (Semana 21) |
| Cuota de minutos por grupo | La suma de `duration` por API | Compute quota: Premium |
| Panel con el uso de cada runner | `GET /runners/:id/jobs` y `kubectl top` | Runner fleet dashboard: Ultimate. Sustituto: Grafana (Semana 21) |
| Reconstruir el runner si se pierde el clúster | Práctica 01, dos `Secret` y `runners/k8s-app.values.yaml` | Ensayo de desastre (Semana 22) |
| Desplegar la aplicación en Kubernetes | Solo los jobs corren en el clúster | El agente de Kubernetes y GitOps en el mismo k3d (Semana 25) |
| Construir imágenes en el clúster | kaniko, sin privilegios | Igual. `dind` se queda en `dind-app` |

---

## 🎩 Trucos y atajos

| Truco | Cómo |
|---|---|
| Ver nacer y morir un pod por job | `kubectl -n gitlab-runner get pods -w` en otra terminal mientras corre un pipeline |
| Saber en qué pod y con qué gestor corrió un job | La línea `Running on <pod> via <gestor>` del log |
| De qué ejecutor es cada runner | GraphQL `runners { nodes { managers { nodes { executorName } } } }`: el campo está en el gestor, no en el runner |
| `kubectl` sin tocar otros clústeres | `--kubeconfig-switch-context=false` al crear, y `export KUBECONFIG=$(k3d kubeconfig write bootcamp)` |
| Imágenes de Docker Hub sin gastar su límite en k3d | `--registry-config` con un espejo `docker.io` en `http://registry-cache:5000` |
| Que lo versionado sea lo que corre | `diff -B` entre `helm get manifest` y `helm template … -f <archivo versionado>` |
| Por qué un pod no arranca antes de que falle el job | `kubectl -n gitlab-runner get events --sort-by=.lastTimestamp \| tail` |
| Liberar memoria sin perder el clúster | `k3d cluster stop bootcamp`, y `start` al volver |

---

## 📌 Entregables

1. El clúster `bootcamp` en `bc-gitlab-network`, con el espejo de Docker Hub
2. El runner `k8s-app` en `app`, etiqueta `docker`, instalado con el chart `0.91.2` y un rol limitado
3. `docker-app` en pausa, sin borrar, y `dind-app` sin cambios
4. `docs/linea-base-s16.json` en `app`: tres pipelines con `docker-app` y tres con `k8s-app`
5. `runners/k8s-app.values.yaml` en `infra/entornos`, sin tokens e idéntico a lo que corre
6. `docs/finops.md` en `app`, con el coste por minuto, por pipeline y por mes

---

## ✅ Verificación

```bash
./scripts/verificar-semana.sh 16
```

Las 12 comprobaciones tienen que pasar.

Lo que el script **no** puede comprobar es que el `concurrent` elegido quepa en tu máquina, que las medidas se tomaran con la caché caliente y sin nada más en marcha, ni que el precio de `docs/finops.md` sea real. Lo evalúa la rúbrica.

> [!NOTE]
> Una comprobación de la Semana 15 pasa a rojo a propósito: `una-gestora-para-app` exigía que todos los runners de `app` compartieran proceso, y `k8s-app` es otro proceso, en otra máquina. Esa comprobación describía la flota de la Semana 15. Las demás no cambian.

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Semana 15 — Runners: ejecutores y configuración](../week-15-runners_ejecutores_y_configuracion/README.md) | **Semana 16** | [Semana 17 — API, webhooks y ChatOps](../week-17-api_webhooks_y_chatops/README.md) |

[← Volver al inicio del bootcamp](../README.md)

# Bootcamp GitLab CE — Zero to Platform Engineer

<div align="center">
  <img src="./assets/bootcamp-header.svg" alt="Bootcamp GitLab CE — Zero to Platform Engineer" width="900"/>
</div>

[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/license-CC%20BY--NC--SA%204.0-lightgrey.svg)](./LICENSE)
[![26 Semanas](https://img.shields.io/badge/semanas-26-yellow.svg)](#)
[![208 Horas](https://img.shields.io/badge/horas-208-orange.svg)](#)
[![GitLab CE](https://img.shields.io/badge/GitLab-CE%2019.x-fc6d26?logo=gitlab&logoColor=white)](#)
[![Autohospedado](https://img.shields.io/badge/self--managed-Docker-2496ed?logo=docker&logoColor=white)](#)

---

## 📋 Descripción

Bootcamp de **26 semanas (~6 meses)** sobre **GitLab CE autohospedado**. Trata GitLab como **plataforma de ingeniería que tú operas**, no como el sitio donde se sube el código.

Modalidad: **autoestudio asincrónico**, 8 h/semana. Todo corre en tu máquina: levantas tu propia instancia en Docker, la administras, la rompes, la recuperas y la reconstruyes desde Terraform. Los entregables se verifican contra la API v4 de **tu** instancia.

**Nivel de entrada**: sabes `clone`, `commit`, `push` y qué es una rama. Nada más.
**Nivel de salida**: Platform Engineer — instancia en alta disponibilidad, pipelines reutilizables publicados en un catálogo, cadena de suministro firmada, SLO definidos, DR ensayado y toda la plataforma declarada en código.

### 🎯 Objetivos

Al terminar serás capaz de:

- ✅ Instalar, configurar y operar GitLab CE autohospedado, y explicar qué hace cada proceso interno
- ✅ Operar Git con precisión quirúrgica y firmar todo lo que entra al repositorio
- ✅ Modelar una organización en grupos y subgrupos con el menor privilegio posible
- ✅ Gobernar `main` con ramas protegidas, CODEOWNERS y server hooks que bloquean de verdad
- ✅ Escribir pipelines que no se ejecutan en serie ni caben en un solo YAML
- ✅ Publicar componentes CI/CD versionados en el catálogo y dejar de copiar YAML entre proyectos
- ✅ Construir, almacenar, firmar y limpiar imágenes y paquetes dentro de tu propia instancia
- ✅ Dar a cada merge request un entorno vivo y a cada despliegue una vuelta atrás
- ✅ Escalar la ejecución con una flota de runners y saber cuánto cuesta cada pipeline
- ✅ Automatizar la plataforma por REST, GraphQL, webhooks y ChatOps
- ✅ Cubrir SAST, secretos, dependencias e imágenes con herramientas libres
- ✅ Firmar artefactos, generar SBOM y bloquear lo que no cumple política
- ✅ Instrumentar la instancia con métricas y logs, y definir SLO con error budget
- ✅ Perder la instancia a propósito y recuperarla con el tiempo medido
- ✅ Montar alta disponibilidad real con Praefect, PostgreSQL replicado y PgBouncer
- ✅ Gestionar la plataforma como código con Terraform y estado remoto en GitLab
- ✅ Sincronizar un clúster desde Git y desplegar por fases con reversión automática

### 🚀 ¿Por qué un bootcamp entero sobre GitLab CE?

> **La mayoría sabe escribir un `.gitlab-ci.yml`. Muy pocos saben operar la plataforma que lo ejecuta.**

Los tutoriales de GitLab terminan donde empieza el trabajo real: el primer pipeline verde. Nadie te enseña qué hacer cuando Gitaly se queda sin disco, cuándo un runner compartido es más caro que uno propio, cómo se restaura un backup con el reloj corriendo, o por qué tu MR sale verde y `main` sale roja.

Este bootcamp asume que la instancia es tuya y que si se cae, la levantas tú.

---

## 🗓️ Estructura del Bootcamp

| Fase | Semanas | Horas | Temas principales | Nivel que consolida |
|---|:--:|:--:|---|---|
| **1. Fundamentos** | 01-04 | 32 h | Instalación en Docker, arquitectura interna, Git quirúrgico, firma SSH, grupos y roles, repo como producto | Usuario avanzado con instancia propia operativa |
| **2. Colaboración** | 05-08 | 32 h | Issues, etiquetas y tableros, merge requests, code review, gobernanza de ramas, GitLab Flow, releases, métricas | Dueño de repositorio: el cambio está gobernado y medido |
| **3. CI/CD** | 09-13 | 40 h | Pipelines, reglas y secretos, DAG y multi-proyecto, componentes y catálogo, registry y paquetes | Ingeniero de CI/CD |
| **4. Entrega, escala y automatización** | 14-17 | 32 h | Entornos, review apps, Pages, feature flags, ejecutores, runners en Kubernetes, FinOps, API y webhooks | Ingeniero de entrega |
| **5. Seguridad y cadena de suministro** | 18-20 | 24 h | Hardening, OIDC, actualizaciones, SAST y escaneo con OSS, SBOM, firma, política como código | Seguridad de plataforma con equivalentes libres |
| **6. Operación, observabilidad y HA** | 21-23 | 24 h | Métricas, logs y tuning, SLO y error budgets, backup y DR drill, incidentes, Praefect y PostgreSQL replicado | SRE |
| **7. IaC y GitOps** | 24-25 | 16 h | Terraform, estado remoto, módulos, Conftest, GitLab Agent, Auto DevOps, canario y rollback | Platform Engineer |
| **8. Capstone** | 26 | 8 h | Auditoría de las 25 capas, `v1.0.0`, documentación y defensa | Portafolio defendible |

**Total: 26 semanas · 208 horas**

---

## 📚 Contenido por Semana

Cada semana tiene esta forma:

```
bootcamp/week-XX-tema_principal/
├── README.md                 # Objetivos, contenidos, tiempos, trucos, entregables
├── rubrica-evaluacion.md     # Conocimiento 30% / Desempeño 40% / Producto 30%
├── checks.json               # Autograding declarativo contra la API v4
├── 0-assets/                 # Diagramas SVG
├── 1-teoria/                 # 7-8 archivos, un concepto por archivo
├── 2-practicas/              # 4 prácticas guiadas, cada paso verificable
├── 3-proyecto/               # La capa que esta semana añade al proyecto
├── 4-recursos/               # ebooks-free, videografia, webgrafia
└── 5-glosario/               # Términos clave A-Z con su tier
```

| Semana | Slug | Tema |
|:--:|---|---|
| 01 | `week-01-instalacion_y_arquitectura_de_gitlab_ce` | Levantas GitLab CE en Docker y entiendes qué proceso hace qué |
| 02 | `week-02-git_avanzado_y_firma_de_commits` | Git con precisión quirúrgica y todo lo que entra, firmado |
| 03 | `week-03-grupos_proyectos_y_permisos` | La organización modelada con el menor privilegio posible |
| 04 | `week-04-repositorio_como_producto` | Docs, wiki, snippets, insignias y LFS: que otro lo arranque solo |
| 05 | `week-05-issues_etiquetas_y_tableros` | Backlog real, taxonomía de etiquetas y un tablero que refleja el flujo |
| 06 | `week-06-merge_requests_y_code_review` | Nada llega a `main` salvo por MR revisada y trazada a un issue |
| 07 | `week-07-gobernanza_de_ramas_y_aprobaciones` | Reglas que no se saltan por descuido, reimplementadas en CE |
| 08 | `week-08-gitlab_flow_releases_y_metricas` | Modelo de ramas, primera versión y el flujo medido con datos propios |
| 09 | `week-09-ci_cd_fundamentos` | Primer pipeline verde con runner propio: artefacto no es caché |
| 10 | `week-10-reglas_variables_y_secretos` | Cuándo corre cada job y de dónde salen sus secretos |
| 11 | `week-11-pipelines_dag_y_multiproyecto` | Pipelines que dejan de ser un tren en serie |
| 12 | `week-12-componentes_ci_cd_y_catalogo` | Componentes versionados publicados en el catálogo |
| 13 | `week-13-registry_de_contenedores_y_paquetes` | Binarios construidos, versionados y limpiados dentro de la instancia |
| 14 | `week-14-entornos_review_apps_y_feature_flags` | Un entorno vivo por MR y un despliegue que se puede deshacer |
| 15 | `week-15-runners_ejecutores_y_configuracion` | Del runner de juguete a una flota configurada con criterio |
| 16 | `week-16-runners_en_kubernetes_y_finops` | Ejecución autoescalada en k3d y el coste por pipeline |
| 17 | `week-17-api_webhooks_y_chatops` | La plataforma se opera por API, no a clics |
| 18 | `week-18-administracion_hardening_y_actualizaciones` | La instancia administrada como producción |
| 19 | `week-19-seguridad_del_pipeline_con_herramientas_oss` | SAST, secretos, dependencias e imágenes sin licencia Ultimate |
| 20 | `week-20-cadena_de_suministro_y_politicas_como_codigo` | Se firma lo que se publica y se bloquea lo que no cumple |
| 21 | `week-21-observabilidad_slo_y_troubleshooting` | Qué hace la instancia por dentro y cuándo se considera que está mal |
| 22 | `week-22-backup_recuperacion_y_respuesta_a_incidentes` | Pierdes la instancia a propósito y mides cuánto tardas en volver |
| 23 | `week-23-alta_disponibilidad_con_praefect_y_postgresql` | Matas un nodo y no se pierde un solo commit |
| 24 | `week-24-terraform_y_estado_remoto_en_gitlab` | La plataforma como código, con planes que se pueden bloquear |
| 25 | `week-25-gitops_con_gitlab_agent_y_entrega_progresiva` | El clúster se sincroniza solo y despliega por fases |
| 26 | `week-26-capstone_plataforma_gitlab_completa` | Auditas, integras y defiendes lo construido en 25 semanas |

El índice con enlaces y el estado real de publicación está en [`bootcamp/README.md`](./bootcamp/README.md).

### 🔑 Componentes Clave

- **Teoría** — 7-8 archivos por semana, un concepto por archivo. Siempre en el mismo orden: qué problema resuelve, cómo se configura, antipatrones, trucos.
- **Práctica** — 4 prácticas guiadas. Cada paso dice **por qué** antes del comando y termina con una **verificación** que puedes ejecutar.
- **Trucos** — una sección por semana con lo que no sale en la documentación, replicada en un cheatsheet acumulativo.
- **Proyecto** — la capa que esa semana añade a tu plataforma. Nunca un ejercicio desechable.
- **Autograding** — la API v4 de tu instancia dice qué te falta y en qué paso lo arreglas.

---

## 🛠️ Herramientas

| Herramienta | Versión | Uso |
|---|---|---|
| GitLab CE | **19.2.4-ce.0** | La plataforma. Pinneada por reproducibilidad |
| Docker | **27+** | Todo el laboratorio |
| Docker Compose | **2.32+** | Orquestación por perfiles |
| GitLab Runner | **19.x** | Ejecución de pipelines. Misma serie que GitLab |
| Git | **2.46+** | Control de versiones |
| `glab` | **1.50+** | CLI oficial de GitLab. La UI cambia; el CLI es estable |
| `jq` | **1.7+** | Autograding y scripting de la API |
| k3d | **5.7+** | Kubernetes local (S16, S25) |
| `kubectl` | **1.32+** | Cliente de Kubernetes |
| Helm | **3.16+** | GitLab Runner y agente en el clúster |
| Terraform | **1.9+** | La plataforma como código (S24) |
| PostgreSQL | **16+** | Backend de GitLab; replicado en S23 |
| Prometheus · Grafana · Loki | **3.14.0 · 13.1.4 · 3.6.11** | Observabilidad (S21) |
| Keycloak | **26+** | OIDC para la instancia (S18) |
| Semgrep · Gitleaks · OSV-Scanner · Trivy | **1.173.0 · 8.30.1 · 2.5.1 · 0.74.0** | Seguridad del pipeline (S19) |
| Syft · Cosign · Conftest | **1.51.0 · 3.1.3 · 0.69.0** | SBOM, firma y política como código (S20) |
| SeaweedFS | **4.40** | Caché distribuida de runners (S15). Sustituye a MinIO — ver [stack-versions](./docs/stack-versions.md) |

### Requisitos de máquina

**16 GB de RAM.** No es una recomendación: las semanas 16, 21, 23 y 25 levantan Kubernetes, un stack de observabilidad o seis contenedores de alta disponibilidad. Con 8 GB se puede llegar hasta la Semana 15.

Los perfiles de Docker Compose son **mutuamente excluyentes en memoria**: `base`, `observabilidad` y `ha` no caben a la vez. Kubernetes **no es un perfil**: las semanas 16 y 25 levantan un clúster de k3d aparte, y antes hay que apagar observabilidad. Cada semana declara qué necesita — ver [perfiles-de-laboratorio.md](./docs/perfiles-de-laboratorio.md).

### Lo que GitLab CE no incluye

Este bootcamp usa **CE puro**: sin gitlab.com, sin licencia EE, sin trials. Varias features conocidas son de pago. No se ocultan: se explican, se dice qué tier las incluye, y **la práctica implementa un equivalente libre**.

| Feature de pago | Tier | Dónde se estudia | Con qué se sustituye aquí |
|---|---|:--:|---|
| Approval rules, Code Owners approvals | Premium | S07 | CODEOWNERS + job `gobernanza` (detecta, no bloquea) + server hook |
| Push rules | Premium | S07 | Server hook `pre-receive` |
| Scoped labels | Premium | S05 | Convención `tipo/` + job que valida exclusividad |
| Epics, iteraciones, roadmaps, weights | Premium | S05, S08 | Hitos + etiquetas + tablero único |
| Merge trains, merged results pipelines | Premium | S07 | Rebase obligatorio antes de fusionar |
| Protected environments, deployment approvals | Premium | S14, S25 | Jobs manuales sobre rama protegida |
| SAST, DAST, Dependency y Container Scanning nativos | Ultimate | S19 | Semgrep, Gitleaks, OSV-Scanner, Trivy |
| Security Dashboard, vulnerability management | Ultimate | S19, S20 | Artefactos SARIF + informes de pipeline |
| Compliance frameworks | Ultimate | S20 | OPA / Conftest como gate de pipeline |
| Audit events de instancia y grupo | Premium | S18 | Volcado de `/events` (menos campos, menos retención) |
| Geo, DR multi-región, maintenance mode | Premium | S22 | Backup frío de una región, con el RPO real medido |
| Pull mirroring | Premium | S23 | Push mirroring |
| DORA API, Insights, Value Stream Analytics de grupo | Premium | S08 | Métricas calculadas por API, con su definición documentada |

> [!TIP]
> **El error contrario también existe.** Praefect y Gitaly Cluster, los componentes CI/CD y su catálogo, los feature flags, el dependency proxy, el estado de Terraform y su registro de módulos, Auto DevOps, los server hooks y el Service Desk **son gratis en CE** y casi nadie los usa porque los da por premium. Este bootcamp los usa todos.

---

## 🚀 Inicio Rápido

### Prerrequisitos

- **Docker 27+** y **Docker Compose 2.32+**
- **Git 2.46+**
- **16 GB de RAM** (mínimo real, no recomendado)
- `glab`, `jq` y un navegador moderno
- Saber `clone`, `commit`, `push` y qué es una rama

Instalación paso a paso por sistema operativo: [`docs/setup-entorno.md`](./docs/setup-entorno.md).

### 1. Clonar

```bash
git clone https://github.com/ergrato-dev/bc-gitlab.git
cd bc-gitlab
cp .env.example .env
```

### 2. Levantar tu instancia

```bash
docker compose --profile base up -d
docker compose logs -f gitlab      # el primer arranque tarda ~5 min
```

### 3. Entrar

```bash
docker compose exec gitlab grep 'Password:' /etc/gitlab/initial_root_password
# http://localhost:8888 — usuario: root
```

Cambia la contraseña y crea un token personal con scope `api`.

### 4. Configurar el autograding

```bash
cat > ~/.bc-gitlab <<'EOF'
GITLAB_URL=http://localhost:8888
PROYECTO=plataforma-<tu-dominio>/app
GITLAB_TOKEN=<tu-token>
EOF

./scripts/verificar-semana.sh --doctor
```

### 5. Elegir dominio y empezar

Lee [`docs/proyecto-hilo-conductor.md`](./docs/proyecto-hilo-conductor.md), elige tu dominio y ve a `bootcamp/week-01-instalacion_y_arquitectura_de_gitlab_ce/`.

---

## ✅ Verificación Automática

En autoestudio nadie revisa tus entregables. Los revisa la API de tu instancia.

```bash
./scripts/verificar-semana.sh 07
```

```
== Semana 07 — Gobernanza de ramas y aprobaciones ==
   instancia: http://localhost:8888
   proyecto:  plataforma-biblioteca/app

✅ La rama main está protegida
✅ Nadie puede hacer push directo a main
❌ Los tags v* están protegidos
   → 2-practicas/02-proteger-tags.md, paso 3
✅ Existe un archivo CODEOWNERS en la raíz

3 de 4 verificaciones superadas.
```

Cómo funciona y qué **no** puede comprobar: [`docs/autograding.md`](./docs/autograding.md).

---

## 📊 Metodología de Aprendizaje

### Estrategias didácticas

- **Aprendizaje basado en proyectos** — una sola plataforma que crece 26 semanas
- **Práctica deliberada** — cada paso se verifica antes de pasar al siguiente
- **Operación real** — se rompe la instancia a propósito y se recupera con el reloj corriendo
- **Infraestructura como código** — lo que se configura a mano en la S03 se declara en Terraform en la S24
- **Sustitución honesta** — cuando la feature es de pago, se implementa el equivalente libre y se dice qué se pierde

### Distribución del tiempo (8 h/semana)

| Bloque | Tiempo |
|---|---|
| Teoría | ~2 h |
| Prácticas | ~3 h 20 min |
| Proyecto | ~2 h |
| Revisión y verificación | ~40 min |

La tabla de tiempos del README de cada semana suma exactamente 8 h. Si suma más, la semana está sobrecargada y se corrige.

### Evaluación

| Evidencia | Peso | Instrumento | Quién juzga |
|---|:--:|---|---|
| 🧠 Conocimiento | 30% | Cuestionario de 10 preguntas conceptuales con respuestas argumentadas | Autoevaluación |
| 💪 Desempeño | 40% | Las 4 prácticas, verificadas por `checks.json` | La API de tu instancia |
| 📦 Producto | 30% | La capa semanal de tu plataforma | 60 pts API + 40 pts rúbrica manual |

**Criterio de aprobación**: mínimo 70% en **cada** evidencia, no en el promedio.

### 🧵 Tu plataforma

Eliges un dominio en la Semana 01 y no lo sueltas. Un solo grupo, una sola instancia, 26 capas. Al terminar tienes una plataforma DevOps completa que puedes enseñar en una entrevista y defender. Ver [`docs/proyecto-hilo-conductor.md`](./docs/proyecto-hilo-conductor.md).

---

## 📞 Soporte

- **Discussions**: [GitHub Discussions](https://github.com/ergrato-dev/bc-gitlab/discussions)
- **Issues**: [GitHub Issues](https://github.com/ergrato-dev/bc-gitlab/issues)

---

## ⚠️ Exención de Responsabilidad

- Material con **fines exclusivamente educativos**, sin garantías de ningún tipo.
- **GitLab cambia.** Comandos, endpoints y nombres de features se comprobaron contra la versión pinneada; una versión posterior puede haberlos movido.
- Las configuraciones de seguridad son **ilustrativas** y están pensadas para un laboratorio local. No copies un `gitlab.rb` de aquí a producción sin revisarlo.
- Varias prácticas **destruyen datos a propósito** (S22, S23). Se ejecutan sobre tu instancia de laboratorio, nunca sobre nada que te importe.
- Este proyecto no está afiliado a GitLab Inc. GitLab es una marca registrada de GitLab Inc.

---

## 📄 Licencia

[CC BY-NC-SA 4.0](./LICENSE).

- **Puedes**: usar, copiar, adaptar y compartir el material.
- **No puedes**: usarlo con fines comerciales.
- **Debes**: atribuir la autoría y compartir las adaptaciones bajo la misma licencia.

---

## 📚 Documentación Adicional

- [Índice de semanas](./bootcamp/README.md)
- [Preparar el entorno](./docs/setup-entorno.md)
- [Proyecto hilo conductor](./docs/proyecto-hilo-conductor.md)
- [Autograding](./docs/autograding.md)
- [Perfiles de laboratorio](./docs/perfiles-de-laboratorio.md)
- [Trucos de GitLab](./docs/trucos-gitlab.md)
- [Glosario global](./docs/glosario-global.md)
- [Versiones del stack](./docs/stack-versions.md)
- [Guía de contribución](./CONTRIBUTING.md)
- [Código de conducta](./CODE_OF_CONDUCT.md)

---

<div align="center">

**Tu instancia. Tus pipelines. Tu guardia.**

[Empezar](./bootcamp/README.md) · [Entorno](./docs/setup-entorno.md) · [Licencia](./LICENSE)

</div>

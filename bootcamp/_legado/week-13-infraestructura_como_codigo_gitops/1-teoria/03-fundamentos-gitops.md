# 03 — Fundamentos de GitOps

GitOps aplica la misma idea declarativa de Terraform (teoría 01) a un dominio distinto: el despliegue de aplicaciones en Kubernetes. Donde Terraform declara y reconcilia la **estructura de GitLab**, GitOps declara y reconcilia el **estado de un clúster Kubernetes**, usando Git como única fuente de verdad. Esta teoría contrasta GitOps con el CI/CD push-based que ya conoces de las semanas 05-06, porque son modelos distintos y confundirlos es el error conceptual más común al empezar con GitOps.

![Reconciliation loop de GitOps comparado con un pipeline push-based tradicional](../0-assets/03-gitops-reconciliation.svg)

---

## Declarativo vs imperativo, aplicado a despliegues

Ya viste esta distinción para infraestructura de GitLab (teoría 01). En el contexto de Kubernetes:

- **Imperativo**: `kubectl apply -f deployment.yaml` ejecutado manualmente o desde un job de CI. Es una **acción puntual** — nadie garantiza que el clúster siga viéndose así mañana si alguien lo modifica con `kubectl edit`.
- **Declarativo (GitOps)**: un repositorio Git contiene los manifiestos YAML que describen el estado deseado del clúster. Un **agente** dentro del clúster los lee continuamente y corrige cualquier diferencia entre lo declarado y lo real.

```yaml
# manifests/api-pagos/deployment.yaml
# ¿QUÉ HACE?: Declara el estado deseado de un Deployment en el clúster
# ¿POR QUÉ?: Este archivo, no un comando ejecutado una vez, es la fuente de verdad del despliegue
# ¿PARA QUÉ?: Si alguien cambia el número de réplicas con kubectl directamente, el agente lo revierte a lo declarado aquí
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-pagos
  namespace: produccion
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-pagos
  template:
    metadata:
      labels:
        app: api-pagos
    spec:
      containers:
        - name: api-pagos
          image: registry.local/plataforma/api-pagos:v1.4.2
          ports:
            - containerPort: 8080
```

---

## Los cuatro principios de GitOps

La definición formal (OpenGitOps, proyecto de la CNCF) establece cuatro principios:

| Principio | Qué significa en la práctica |
|---|---|
| **Declarativo** | El estado deseado del sistema se expresa declarativamente (YAML de Kubernetes, no scripts) |
| **Versionado e inmutable** | El estado deseado se almacena de forma que garantice inmutabilidad, versionado y un historial de auditoría completo — es decir, en Git |
| **Extraído automáticamente (pulled)** | Los componentes de software agentes extraen automáticamente las declaraciones de estado deseado |
| **Reconciliado continuamente** | Agentes de software observan continuamente el estado real del sistema e intentan aplicar el estado deseado |

---

## Single source of truth

En un flujo GitOps, el repositorio Git **es** el estado deseado del clúster — no una aproximación, no una copia, la fuente única. Esto tiene una consecuencia práctica importante: **si algo no está en Git, no debería existir en el clúster**, y si algo se modifica manualmente en el clúster sin pasar por Git, el sistema lo revierte automáticamente en el siguiente ciclo de reconciliación.

Esto es radicalmente distinto de un entorno donde el estado "real" vive parcialmente en el clúster (cambios manuales de `kubectl`, hotfixes de emergencia no documentados) y Git es solo una referencia aproximada que se desactualiza con el tiempo.

---

## Reconciliation loop: el corazón de GitOps

El **reconciliation loop** (bucle de reconciliación) es el mecanismo que hace cumplir el principio 4. Funciona así, de forma continua:

```
┌─────────────────────────────────────────────────────────┐
│  1. Leer el estado deseado desde Git (manifiestos YAML)  │
│  2. Leer el estado real del clúster (vía API de K8s)     │
│  3. Calcular el diff entre deseado y real                │
│  4. Si hay diff: aplicar los cambios necesarios           │
│  5. Esperar (poll interval) y volver al paso 1             │
└─────────────────────────────────────────────────────────┘
```

Esto es conceptualmente idéntico al `plan`/`apply` de Terraform (teoría 01), pero con una diferencia crucial: Terraform reconcilia **bajo demanda** (cuando un humano o un pipeline ejecuta `apply`), mientras que un agente GitOps reconcilia **continuamente**, sin intervención humana, típicamente cada 1-5 minutos.

```bash
# Drift: alguien escala manualmente el deployment con kubectl
kubectl scale deployment api-pagos --replicas=10 -n produccion
# deployment.apps/api-pagos scaled

# El manifiesto en Git sigue diciendo replicas: 3
# En el siguiente ciclo de reconciliación (minutos después), el agente GitOps
# detecta el drift y revierte automáticamente a 3 réplicas — sin que nadie ejecute nada
```

---

## GitOps vs CI/CD push-based: la comparación explícita

En las semanas 05-06 construiste pipelines `.gitlab-ci.yml` con un job de tipo `deploy` que, al llegar a ese stage, ejecuta algo como `kubectl apply -f manifest.yaml` o `helm upgrade` contra un clúster remoto. Ese modelo se llama **push-based**: el pipeline de CI **empuja** el cambio activamente hacia el clúster.

| Aspecto | CI/CD push-based (semanas 05-06) | GitOps pull-based (esta semana) |
|---|---|---|
| Quién inicia el despliegue | El pipeline de CI, al llegar al job `deploy` | El agente dentro del clúster, en su próximo ciclo |
| Credenciales del clúster | Deben existir **fuera** del clúster, en GitLab CI/CD (kubeconfig como variable protegida) | Viven **dentro** del clúster; GitLab nunca tiene acceso directo de escritura |
| Superficie de ataque | El runner de CI necesita acceso de red y credenciales de escritura al clúster de producción | El clúster inicia la conexión hacia GitLab (outbound); no hay puerto de entrada expuesto |
| Detección de drift | Ninguna — si alguien cambia algo con `kubectl`, el pipeline no se entera hasta el próximo deploy | Automática y continua — el reconciliation loop lo corrige solo |
| Multi-clúster | Cada pipeline necesita credenciales separadas por clúster | Cada clúster tiene su propio agente que solo necesita saber a qué repo apuntar |
| Rollback | Re-ejecutar el job de deploy con un commit anterior | `git revert` en el repositorio de manifiestos; el agente reconcilia solo |

```yaml
# .gitlab-ci.yml — ejemplo de deploy push-based (lo que YA sabes hacer, semana 06)
# ¿QUÉ HACE?: El job deploy corre en el runner de CI y llama directamente a la API de K8s
# ¿POR QUÉ?: Requiere que el runner tenga kubeconfig con permisos de escritura sobre el clúster
# ¿PARA QUÉ?: Comparar contra el modelo pull de GitOps de abajo
deploy_produccion:
  stage: deploy
  image: bitnami/kubectl:1.30
  script:
    - kubectl config use-context produccion
    - kubectl apply -f k8s/deployment.yaml
  environment:
    name: produccion
  when: manual
```

```yaml
# .gitlab-ci.yml — con GitOps, el job de CI ya NO despliega — solo actualiza el manifiesto en Git
# ¿QUÉ HACE?: Actualiza el tag de imagen en el manifiesto y hace commit al repo de manifiestos
# ¿POR QUÉ?: El agente dentro del clúster es quien aplica el cambio, no este job
# ¿PARA QUÉ?: El pipeline nunca tiene credenciales de escritura hacia el clúster — cero superficie de ataque saliente
actualizar_manifiesto:
  stage: deploy
  image: alpine/git:latest
  script:
    - sed -i "s|image: .*|image: registry.local/plataforma/api-pagos:${CI_COMMIT_SHORT_SHA}|" k8s/deployment.yaml
    - git commit -am "deploy: api-pagos ${CI_COMMIT_SHORT_SHA}"
    - git push origin main
  environment:
    name: produccion
```

Este segundo pipeline es notablemente más simple porque **le entrega la responsabilidad de desplegar al agente GitOps**, no al runner de CI. La teoría 04 cubre exactamente ese agente para GitLab: el Kubernetes Agent.

---

## Por qué GitOps mejora la seguridad de los despliegues

El cambio de push a pull no es solo estilístico — reduce el radio de explosión ante una brecha:

- Si el runner de CI se compromete en un modelo push-based, el atacante hereda credenciales de escritura hacia producción.
- Si el runner de CI se compromete en un modelo GitOps pull-based, el atacante en el peor caso puede hacer `git push` de un manifiesto malicioso — pero eso queda **auditado en el historial de Git**, sujeto a revisión de MR, y el agente solo tiene los permisos que su Service Account de Kubernetes le otorga (RBAC dentro del clúster, no credenciales sueltas fuera de él).

---

## Cuándo NO usar GitOps

GitOps no reemplaza todo el CI/CD que ya conoces — solo la fase de **despliegue a Kubernetes**. Build, test, SAST, Container Scanning (semana 10) siguen ejecutándose en pipelines push-based normales, porque esas fases no modifican un clúster en ejecución. Un pipeline típico con GitOps combina ambos modelos:

```
build → test → SAST/scanning → package (push imagen a registry) → actualizar manifiesto (push a Git) → [agente reconcilia]
└──────────────── CI/CD push-based (semanas 05-06-10) ────────────┘   └────── GitOps pull-based ──────┘
```

Herramientas dedicadas para el rol de "agente reconciliador" incluyen Argo CD, Flux, y el GitLab Kubernetes Agent que cubre la próxima teoría — todos implementan el mismo reconciliation loop, con distintas integraciones nativas según la plataforma.

---

## Comparación de agentes GitOps

Ninguno de estos proyectos inventó GitOps — todos implementan los mismos cuatro principios (OpenGitOps), pero difieren en cómo se integran con la plataforma que los rodea:

| Agente | Origen | Integración nativa | Cómo se configura |
|---|---|---|---|
| **GitLab Kubernetes Agent** | GitLab Inc. | Nativa en GitLab CE/EE — sin instalar nada adicional en el lado de GitLab | `config.yaml` dentro de `.gitlab/agents/<nombre>/` en un proyecto GitLab |
| **Argo CD** | Intuit / CNCF | Requiere su propia UI y CRDs (`Application`) instalados en el clúster; se conecta a cualquier proveedor Git | CRDs `Application` que apuntan a un repo + path |
| **Flux** | Weaveworks / CNCF | CRDs (`Kustomization`, `HelmRelease`) instalados en el clúster; agnóstico de proveedor Git | CRDs declarados directamente como manifiestos en el clúster |

Para un bootcamp centrado en GitLab CE, el Kubernetes Agent es la elección natural porque no requiere instalar ni operar un sistema adicional (Argo CD o Flux tienen su propia UI, su propia base de datos de estado y su propio ciclo de actualización) — la sincronización queda dentro del mismo panel **Operate** de GitLab que ya usas para pipelines y environments.

---

## Namespaces y multi-tenancy en GitOps

Un mismo clúster suele alojar varios equipos o entornos (staging, producción, distintos microservicios). El patrón habitual es un **namespace de Kubernetes por equipo o entorno**, con manifiestos organizados en el repositorio siguiendo la misma estructura:

```
manifests/
├── produccion/
│   ├── api-pagos/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── api-notificaciones/
│       ├── deployment.yaml
│       └── service.yaml
└── staging/
    ├── api-pagos/
    └── api-notificaciones/
```

```yaml
# manifests/produccion/api-pagos/service.yaml
# ¿QUÉ HACE?: Declara el Service que expone el Deployment dentro del namespace produccion
# ¿POR QUÉ?: Cada carpeta de entorno mapea 1:1 a un namespace real del clúster
# ¿PARA QUÉ?: Aislar producción de staging tanto en Git (carpetas) como en el clúster (namespaces)
apiVersion: v1
kind: Service
metadata:
  name: api-pagos
  namespace: produccion
spec:
  selector:
    app: api-pagos
  ports:
    - port: 80
      targetPort: 8080
```

Esta estructura de carpetas por entorno es la razón por la que la teoría 02 recomendó un **state remoto por entorno** para Terraform — el mismo principio de separación aplica en ambas capas: infraestructura (Terraform) y despliegues (GitOps).

---

## Repo de manifiestos separado del repo de aplicación

Un patrón consolidado en equipos que usan GitOps en producción es mantener **dos repositorios distintos**:

- `plataforma/api-pagos` — código fuente de la aplicación, Dockerfile, tests, pipeline de build
- `plataforma/gitops-manifiestos` — solo YAML de Kubernetes, sin código de aplicación

```yaml
# .gitlab-ci.yml del repo de la APLICACIÓN (api-pagos)
# ¿QUÉ HACE?: Al final del pipeline, actualiza el tag de imagen en el repo de manifiestos, no despliega directamente
# ¿POR QUÉ?: Separar "quién construye la imagen" de "quién puede modificar qué corre en el clúster"
# ¿PARA QUÉ?: Un desarrollador de api-pagos con acceso de escritura a su propio repo NO tiene, por
#             ese solo hecho, permiso de escribir directamente en producción — el MR al repo de
#             manifiestos es un punto de control adicional, revisable por el equipo de plataforma
actualizar_manifiesto_gitops:
  stage: deploy
  image: alpine/git:latest
  script:
    - git clone "https://gitlab-ci-token:${CI_JOB_TOKEN}@localhost/plataforma/gitops-manifiestos.git"
    - cd gitops-manifiestos
    - sed -i "s|image: .*|image: registry.local/plataforma/api-pagos:${CI_COMMIT_SHORT_SHA}|" manifests/produccion/api-pagos/deployment.yaml
    - git commit -am "deploy(api-pagos): ${CI_COMMIT_SHORT_SHA}"
    - git push origin main
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

Esta separación tiene un costo (dos repos que mantener sincronizados en vez de uno) a cambio de un beneficio de gobernanza: el repositorio de manifiestos puede tener sus propias reglas de branch protection y sus propios approvers, distintos de los del código de aplicación — el mismo tipo de control granular que ya configuraste con `gitlab_branch_protection` en la teoría 02.

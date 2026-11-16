# 📖 Glosario — Semana 16

Términos que aparecen esta semana. El nombre real de la feature va en inglés entre paréntesis, y el **tier** cuando aplica.

El glosario acumulado de toda la plataforma está en [glosario-global](../../../docs/glosario-global.md).

---

## A

**Archivo de valores** (*values file*) — El YAML que pasa a un chart lo que no es su valor por defecto. `runners/k8s-app.values.yaml` en `infra/entornos`, sin secretos.

**Autoescalado de nodos** (*Node autoscaling*) — Un componente del clúster (Cluster Autoscaler, Karpenter o el del proveedor) que crea nodos cuando hay pods en `Pending` y quita los vacíos. No existe en k3d: sus nodos comparten tu máquina.

## C

**Chart** — Un paquete de Helm: plantillas de recursos de Kubernetes más sus valores por defecto. `gitlab/gitlab-runner` `0.91.2` instala el runner `19.2.2`.

**Compute quota** — Premium. Límite de minutos de cómputo por grupo o proyecto en los runners de instancia. Sustituto en CE: la suma de `duration` de los jobs por API.

**`concurrent`** — En el archivo de valores del chart: cuántos jobs a la vez acepta el gestor. Lo que no cabe espera en `pending` en GitLab, sin fallar.

**Coste por minuto de job** — En este bootcamp, el precio por hora de la máquina entre 60 y entre los jobs que caben a la vez. Multiplicado por los minutos de job de un pipeline, su coste.

## E

**Ejecutor Kubernetes** (*Kubernetes executor*) — Free. Ejecutor que crea un pod por job en un clúster y lo borra al terminar.

## G

**Gestor** (*Runner manager*) — Free. El proceso `gitlab-runner` que pide trabajo a GitLab. En Kubernetes, un pod del Deployment del chart; no ejecuta ningún `script`. Su `executorName` en GraphQL dice de qué ejecutor es.

## H

**Helm** — El gestor de paquetes de Kubernetes. `helm install`, `helm upgrade` y `helm template` con un archivo de valores (`-f`) y una versión de chart (`--version`).

**`helper`** — Contenedor de cada pod de job, con la imagen `gitlab-runner-helper` de la misma versión que el runner. Clona el repositorio y sube y baja la caché y los artefactos.

## K

**k3d** — Herramienta que ejecuta k3s, una distribución ligera de Kubernetes, en contenedores de Docker. En este bootcamp, el clúster `bootcamp` en `bc-gitlab-network`.

**`KUBECONFIG`** — Variable con la ruta del archivo que dice a `kubectl` a qué clúster hablar y con qué credenciales. Esta semana, `~/.config/k3d/kubeconfig-bootcamp.yaml`.

## L

**Línea base** — La medida de antes de un cambio, versionada, contra la que se compara la de después. En este bootcamp, `docs/linea-base-s16.json` de `app`.

## M

**Minutos de job** — La suma de la duración de los jobs de un pipeline. Mide el trabajo hecho, no lo que espera quien hizo el push.

## P

**Pod** — La unidad que programa Kubernetes: uno o varios contenedores que comparten red y volúmenes. Un job es un pod con `build`, `helper` y sus servicios.

**`poll_timeout`** — Clave de `[runners.kubernetes]`: lo que el gestor espera a que el pod arranque antes de dar el job por fallido. 180 s por defecto.

## Q

**`queued_duration`** — Campo de la API de pipelines y de jobs: segundos en `pending` esperando runner. `null` si no hubo espera.

## R

**RBAC** (*Role-based access control*) — Los permisos de Kubernetes: un `Role` dice qué verbos sobre qué recursos, y un `RoleBinding` a quién. Con `rbac.rules`, el rol del gestor tiene solo lo que el ejecutor usa.

**`requests` y `limits`** — Lo que un contenedor reserva al elegir nodo y lo máximo que puede usar. Pasar el límite de memoria mata el proceso (`OOMKilled`).

**`ResourceQuota`** — Límite de pods o de recursos en un namespace. Un pod que no cabe se rechaza: el job falla con `runner_system_failure`, no espera.

## S

**`Secret`** — Recurso de Kubernetes para datos sensibles. Esta semana, `runner-token` (el `glrt-`) y `cache-s3` (la clave del almacén).

---

[← Volver a la Semana 16](../README.md)

# 📖 Glosario — Semana 14

Términos que aparecen esta semana. El nombre real de la feature va en inglés entre paréntesis, y el **tier** cuando aplica.

El glosario acumulado de toda la plataforma está en [glosario-global](../../../docs/glosario-global.md).

---

## A

**Aprobación de despliegue** (*Deployment approval*) — Premium. Exige que N personas aprueben un despliegue a un entorno protegido antes de que corra. En CE, el sustituto es el job `trigger` manual y la rama protegida de `infra/entornos`.

**`auto_stop_in`** — Free. Palabra clave de `environment` que para el entorno pasado ese tiempo sin despliegues nuevos, lanzando su job `on_stop`. La red para las review apps olvidadas.

## C

**Comando forzado** (*Forced command*) — Opción `command="…"` de una línea de `authorized_keys`: esa clave solo ejecuta ese programa, reciba lo que reciba. Lo pedido llega en `SSH_ORIGINAL_COMMAND`. Con `restrict`, además, sin shell, sin reenvío de puertos y sin terminal.

**Control de acceso de Pages** (*Pages access control*) — Free. `gitlab_pages['access_control'] = true` en la instancia, más `pages_access_level` en cada proyecto. Sin lo primero, cualquier sitio se sirve a quien tenga la URL.

## D

**Despliegue** (*Deployment*) — Free. Registro de que un job con `environment` corrió: guarda el job, el SHA del commit de su pipeline, el estado y la fecha. En `infra/entornos`, el SHA es el de `infra/entornos`, no el de `app`.

**Despliegue obsoleto** (*Outdated deployment job*) — Free. Un despliegue cuyo SHA es más antiguo que el del último correcto. La protección *Prevent outdated deployment jobs* lo hace fallar; no actúa si el SHA coincide.

**Dominio único** (*Unique domain*) — Free. Cada proyecto con Pages en su propio subdominio (`app-<sufijo>.pages.localhost`), no bajo el del grupo. Activado por defecto en los proyectos nuevos; lo confirmaste en la práctica 04.

## E

**Entorno** (*Environment*) — Free. Destino con nombre (`staging`, `production`, `review/7-multa`) al que despliegan los jobs. Tiene tier, URL, historial de despliegues y estado (`available`, `stopping`, `stopped`).

**Entorno protegido** (*Protected environment*) — Premium. Limita quién despliega en un entorno, sea cual sea la rama o el proyecto. En CE, se sustituye por desplegar desde un proyecto con la rama protegida.

**Estrategia** (*Strategy*) — Free. Regla de un feature flag con su ámbito de entornos: `default` (todos), `userWithId`, `gradualRolloutUserId` (porcentaje), `flexibleRollout` o `gitlabUserList`.

## F

**Feature flag** — Free. Interruptor que el código consulta en ejecución, gestionado en `Deploy → Feature flags` y servido por una API compatible con Unleash. Separa desplegar de activar.

**Freeze period** (*Deploy freeze*) — Free. Ventana cron en la que no se debe desplegar. GitLab no bloquea nada: expone `CI_DEPLOY_FREEZE` y los jobs deciden.

## I

**Instance ID** — Identificador del cliente Unleash de un proyecto, en `Deploy → Feature flags → Configure`. Va en la cabecera `UNLEASH-INSTANCEID`. No se lee por API, y es un secreto de lectura: va en la configuración del destino, no en el repositorio.

## O

**`on_stop`** — Free. Nombre del job que para un entorno, con `environment:action: stop`. Lo lanza GitLab al fusionar o cerrar la merge request, al borrar la rama, o al vencer `auto_stop_in`.

## P

**Pages** (*GitLab Pages*) — Free. Sitio estático servido desde los artefactos de un job con `pages: true` y `artifacts: paths: [public]`. Los despliegues paralelos (una versión por rama) son Premium.

## R

**Review app** — Free. Entorno dinámico por merge request (`review/$CI_COMMIT_REF_SLUG`), con su URL enlazada en la propia merge request y su job de parada.

**Rollback** — Volver a una versión anterior. En GitLab, reintentar el job de un despliegue anterior con éxito: repite su pipeline con sus variables. Free.

## T

**Tier de despliegue** (*Deployment tier*) — Free. `production`, `staging`, `testing`, `development` u `other`. GitLab lo adivina por el nombre del entorno, o se fija con `deployment_tier`. Las métricas de DORA de pago cuentan el tier `production`.

## U

**Unleash** — Proyecto de feature flags de código abierto. GitLab implementa su API de cliente, así que cualquier SDK de Unleash habla con GitLab. El `appName` del cliente es el nombre del entorno.

---

[← Volver a la Semana 14](../README.md)

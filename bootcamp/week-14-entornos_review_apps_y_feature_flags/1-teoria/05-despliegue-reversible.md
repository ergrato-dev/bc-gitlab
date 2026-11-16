# El despliegue reversible

> Un despliegue que no se puede deshacer convierte cada fallo en una carrera: arreglar hacia delante, con prisa, en producción. Uno que se deshace en un minuto convierte el fallo en una molestia. En GitLab, deshacer es **volver a ejecutar el despliegue anterior**, y eso solo funciona si el despliegue anterior todavía tiene todo lo que necesita. Esta semana lo tiene, y hay un detalle de `infra/entornos` que cambia lo que la Semana 11 dio por resuelto.

---

## 🎯 Objetivos

- Hacer un rollback reintentando un job de despliegue, por la UI y por API
- Explicar qué necesita un despliegue viejo para poder repetirse
- Saber cuándo GitLab bloquea un despliegue obsoleto, y por qué en `infra/entornos` no lo hace
- Elegir el modo del resource group de cada entorno de `infra/entornos`
- Congelar los despliegues en las horas en que nadie debería desplegar

---

## 1. Qué problema resuelve

El viernes a las 17:00, `staging` responde `500` tras la última fusión. Hay tres salidas:

| Salida | Tiempo | Riesgo |
|---|---|---|
| Arreglar el código y fusionar | Lo que tarde el arreglo, la revisión y el pipeline | Un arreglo con prisa, sin revisar bien |
| `git revert` y fusionar | Revisión y pipeline enteros | Bajo, pero lento |
| **Volver a desplegar la versión de ayer** | Un job | Ninguno: esa versión ya funcionó |

La tercera no sustituye a las otras dos: el código roto sigue en `main` y alguien tiene que arreglarlo. Lo que hace es **separar la urgencia del arreglo**. Primero se para el daño; luego se arregla con calma.

---

## 2. Cómo funciona

### 2.1 Rollback es reintentar

Cada despliegue tiene su job. Reintentar ese job crea un despliegue nuevo con **las mismas variables** que tuvo el original. En `infra/entornos`, eso incluye `APP_SHA`: el job vuelve a descargar el paquete de esa versión y lo vuelve a desplegar.

```bash
# El despliegue anterior al último en staging, y su job
glab api "projects/plataforma-<tu-dominio>%2Finfra%2Fentornos/deployments?environment=staging&status=success&order_by=id&sort=desc&per_page=2" \
  | jq -r '.[1].deployable.id'
# 104
glab api --method POST "projects/plataforma-<tu-dominio>%2Finfra%2Fentornos/jobs/104/retry" | jq -r .id
curl -s localhost:8095/staging/salud | jq -r .sha       # el de ayer
```

En la UI, `Operate → Environments → staging`, cada despliegue tiene su botón de volver a desplegar (*Rollback* en los anteriores al actual).

### 2.2 Lo que necesita un despliegue viejo

Un reintento solo funciona si lo que el job usó sigue ahí:

| El job necesita | En `infra/entornos` | Se perdería si… |
|---|---|---|
| Sus variables | `APP_SHA`, guardadas con el pipeline | Nunca: viven con el pipeline |
| El binario | El paquete `app/<SHA>/app.tgz` (Semana 13) | Fuera un artefacto que caduca en una semana |
| La credencial | `DEPLOY_SSH_KEY` de hoy | Nunca: se lee al ejecutar, no al crear el pipeline |
| El código de `infra/entornos` | El commit de aquel pipeline | Nunca: se clona ese commit |

La segunda fila es la razón de fondo de la Semana 13. Si `infra/entornos` hubiera seguido descargando el artefacto del job `package`, un rollback de hace diez días fallaría con un `404`.

La cuarta tiene una cara B: si cambiaste `scripts/desplegar.sh` ayer, el rollback de anteayer ejecuta **el script de anteayer**. Casi siempre es lo que quieres; si no, el rollback es un pipeline nuevo, no un reintento.

### 2.3 Despliegues obsoletos

`Settings → CI/CD → General pipelines` tiene dos ajustes, activados por defecto:

| Ajuste | API | Qué hace |
|---|---|---|
| *Prevent outdated deployment jobs* | `ci_forward_deployment_enabled` | Un job que llega tarde, más viejo que el último despliegue correcto, falla sin ejecutarse |
| *Allow job retries for rollback deployments* | `ci_forward_deployment_rollback_allowed` | El reintento manual de un despliegue viejo no cuenta como obsoleto |

La Semana 11 se apoyó en el primero para que `newest_first` no volviera atrás. Funciona en `app`. **En `infra/entornos`, no**, y la razón está en el código (`older_than_last_successful_deployment?` en `app/models/deployment.rb`):

```ruby
return false if sha == environment.last_deployment&.sha
```

Un despliegue con **el mismo SHA** que el último nunca es obsoleto. Y en `infra/entornos` todos los despliegues tienen el mismo SHA, el del commit de `infra/entornos` (teoría 01). Comprobado en `19.2.4`: con `ci_forward_deployment_rollback_allowed` en `false`, el reintento de un despliegue viejo sigue funcionando.

### 2.4 El modo del resource group en `infra/entornos`

Sin la protección de obsoletos, `newest_first` es peligroso: B pasa primero, A espera, y cuando B termina, A despliega la versión vieja encima. En `infra/entornos` el modo correcto es otro:

| Modo | Con A y B en cola | En `infra/entornos` |
|---|---|---|
| `unordered` | Orden aleatorio: puede terminar en A | ❌ |
| `newest_first` | B, y luego A encima | ❌ sin la protección de obsoletos |
| `oldest_first` | A, luego B: termina en B | ✅ |

`oldest_first` pasa por cada versión, lo que tarda un poco más, pero **siempre termina en la última**. Los resource groups se crean con el primer job que los usa, así que el modo se cambia después del primer despliegue:

```bash
glab api --method PUT "projects/plataforma-<tu-dominio>%2Finfra%2Fentornos/resource_groups/staging" \
  -f process_mode=oldest_first | jq -c '{key, process_mode}'
# {"key":"staging","process_mode":"oldest_first"}
```

### 2.5 Congelar los despliegues

Una *deploy freeze* declara un intervalo en el que no se despliega. Es Free:

```bash
glab api --method POST "projects/plataforma-<tu-dominio>%2Finfra%2Fentornos/freeze_periods" \
  -f freeze_start="0 18 * * 5" -f freeze_end="0 8 * * 1" -f cron_timezone="Europe/Madrid"
```

GitLab no bloquea nada por sí solo: durante el intervalo, los jobs reciben `CI_DEPLOY_FREEZE`, y es el YAML el que decide:

```yaml
rules:
  - if: $CI_DEPLOY_FREEZE
    when: never
  - when: on_success
```

Esta semana no se congela nada: el laboratorio se despliega cuando tú trabajas, y eso suele ser fuera de horario. La sintaxis queda aquí para el día que tengas equipo.

---

## 3. Cómo se configura

Rollback en la UI: `Operate → Environments → staging → (despliegue) → Rollback`. Por API, el `retry` de 2.1. Lo que conviene comprobar después siempre es **el destino**, no GitLab:

```bash
curl -s localhost:8095/staging/salud | jq -c '{sha, desplegado}'
```

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Hacer el rollback con un `git revert` urgente | Mete prisa en una revisión que debería ser tranquila | Reintentar el despliegue anterior; el revert va después, con calma |
| Desplegar desde un artefacto que caduca | El rollback de la semana pasada da `404` | El paquete por SHA |
| `newest_first` en `infra/entornos` | Puede terminar en la versión vieja | `oldest_first` |
| Dar por hecho el rollback porque el job está verde | El job puede haber desplegado otra cosa | Preguntar al destino qué SHA sirve |

---

## 5. Trucos

- Un despliegue cuyo pipeline es **más viejo** que el del despliegue anterior es un rollback: `deployable.pipeline.id` lo delata.
- `GET …/freeze_periods` enseña las congelaciones activas; un job que "no sale" un viernes por la tarde casi siempre es una de ellas.

---

## 📚 Recursos Adicionales

- [Retry or roll back a deployment](https://docs.gitlab.com/ci/environments/deployments/#retry-or-roll-back-a-deployment)
- [Prevent outdated deployment jobs](https://docs.gitlab.com/ci/environments/deployment_safety/#prevent-outdated-deployment-jobs)
- [Deploy freezes](https://docs.gitlab.com/user/project/releases/#prevent-unintentional-releases-by-setting-a-deploy-freeze)

---

## ✅ Checklist de Verificación

- [ ] Sé hacer un rollback por API y comprobarlo en el destino
- [ ] Sé qué cuatro cosas necesita un despliegue viejo para repetirse
- [ ] Sé por qué la protección de obsoletos no actúa en `infra/entornos`
- [ ] Sé qué modo de resource group usa cada entorno de `infra/entornos`, y por qué

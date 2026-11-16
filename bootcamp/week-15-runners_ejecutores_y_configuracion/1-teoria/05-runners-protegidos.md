# Runners protegidos

> Las variables protegidas de la Semana 10 impiden que una rama cualquiera **lea** un secreto. No impiden que esa rama **se ejecute** en la máquina donde viven los despliegues, con su red, sus volúmenes y su caché. Un runner protegido cierra esa segunda puerta: solo coge jobs de ramas y tags protegidos. Y la caché, que viaja entre ramas sin pedir permiso, tiene su propia separación.

---

## 🎯 Objetivos

- Reservar un runner para ramas y tags protegidos con `access_level`
- Explicar qué añade un runner protegido a las variables protegidas
- Poner un tiempo máximo a los jobs de un runner y saber cuál gana frente al del proyecto
- Entender por qué la clave de la caché lleva `-protected` o `-non_protected`

---

## 1. Qué problema resuelve

Hasta hoy, `docker-app` ejecuta los despliegues de `infra/entornos` **y** los jobs de cualquier rama de `app`. Las variables de despliegue están protegidas, así que una rama sin proteger no ve `DEPLOY_SSH_KEY`. Pero sí puede:

| Desde una rama cualquiera de `app`, en `docker-app` | Consecuencia |
|---|---|
| Escribir en la caché que luego restaura `main` | `main` ejecuta, sin saberlo, un `node_modules` preparado por otra rama |
| Ocupar los dos huecos del runner con un job que no termina | El despliegue de `production` espera detrás |
| Usar la red del runner, que llega a `destino` | Un `curl` a `destino:8080` desde una rama que nadie ha revisado |

La rama protegida y su revisión son el control. Un runner que solo atiende ramas protegidas hace que **lo que llega a la máquina de despliegue haya pasado por ese control**.

---

## 2. Cómo funciona

### 2.1 `access_level`

| Valor | El runner coge jobs de… |
|---|---|
| `not_protected` (por defecto) | Cualquier rama, tag o merge request |
| `ref_protected` | Solo ramas y tags protegidos |

Un job de una rama sin proteger con `tags: [deploy]` no falla: se queda en `pending` con `runner: null`, esperando un runner que no va a llegar. Comprobado en `19.2.4`:

```bash
glab api "projects/<id>/jobs/<job>" | jq -c '{status, runner, failure_reason}'
# {"status":"pending","runner":null,"failure_reason":null}
```

Un pipeline de merge request **nunca** está en una rama protegida: corre sobre `refs/merge-requests/<iid>/head`. Ningún job de MR llegará a `deploy-infra`, y es lo que quieres.

### 2.2 Cuándo es protegido un pipeline de `infra/entornos`

Los despliegues de `infra/entornos` los dispara `main` de `app` con un `trigger` (Semana 11). El pipeline de abajo corre en `main` de `infra/entornos`, que está protegida desde que se creó (Semana 14), así que `CI_COMMIT_REF_PROTECTED` vale `true` y `deploy-infra` lo coge. Si alguien cambia el `trigger` para que apunte a otra rama de `infra/entornos`, el despliegue se queda en `pending`. Es el comportamiento correcto: la rama protegida es lo que hace de entorno protegido en CE.

| Premium | CE, en este bootcamp |
|---|---|
| Entornos protegidos: quién puede desplegar en `production` | `main` de `infra/entornos` protegida para Maintainer (Semana 14) |
| Aprobaciones de despliegue | El job manual `infra-production` de `app` (Semana 14) |
| — | **Runner `ref_protected`**: solo esa rama llega a la máquina que despliega |

### 2.3 El tiempo máximo

`maximum_timeout` (en segundos, mínimo 600) limita los jobs de **ese** runner. Cuando choca con el del proyecto (`build_timeout`, 3600 por defecto) o con el `timeout:` del job, gana el más corto que imponga el runner:

| Proyecto | Job (`timeout:`) | Runner (`maximum_timeout`) | El job muere a los |
|:--:|:--:|:--:|:--:|
| 60 min | — | — | 60 min |
| 60 min | — | 15 min | 15 min |
| 60 min | 45 min | 15 min | 15 min |
| 60 min | 10 min | 15 min | 10 min |

Un despliegue que tarda más de quince minutos ya no es un despliegue: es un job colgado esperando a un `ssh` que no responde, y mientras espera retiene el `resource_group` del entorno. `deploy-infra` corta a los 900 segundos.

### 2.4 La caché se separa por protección

La clave real de cada caché lleva un sufijo, y el código (`cache_suffix_for` en `app/models/ci/build.rb`) dice cuál:

```ruby
return 'non_protected' if entry[:unprotect]
return 'protected' if uses_protected_cache?
return 'protected' if pipeline&.protected_ref?
'non_protected'
```

| Pipeline | Clave en el almacén |
|---|---|
| `main` (protegida) | `node-modules-protected` |
| `feat/add-late-fee` (sin proteger) | `node-modules-non_protected` |
| Job con `cache: unprotect: true` | `node-modules-non_protected` siempre |

Así, una rama sin proteger no puede escribir la caché que restaura `main`. Lo controla el ajuste del proyecto `ci_separated_caches` (activo por defecto; `Settings → CI/CD → General pipelines → Use separate caches for protected branches`).

> [!WARNING]
> `uses_protected_cache?` es cierto para quien tiene permiso `use_protected_cache` en el proyecto, y un administrador lo tiene siempre. En tu laboratorio eres administrador: verás `-protected` también en tus ramas sin proteger. Un Developer normal, no. No concluyas que la separación no funciona porque a ti no te separa.

---

## 3. Cómo se configura

`access_level` y `maximum_timeout` se deciden al crear el runner, o después con `PUT /runners/:id`:

```bash
glab api --method POST user/runners \
  -f runner_type=group_type -f group_id="$GI" -f description=deploy-infra \
  -f tag_list=deploy -f run_untagged=false -f access_level=ref_protected -f maximum_timeout=900 \
  | jq -c '{id, access_level: .access_level}'
```

En la UI: `Settings → CI/CD → Runners` del grupo, `Protected` y `Maximum job timeout` en el formulario del runner.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Fiarse solo de las variables protegidas | La rama no lee la clave, pero se ejecuta en la máquina que despliega y escribe en su caché | Runner `ref_protected` para los despliegues |
| Un runner protegido con `run_untagged = true` | Cualquier job sin etiqueta de una rama protegida cae en la máquina de despliegue | `run_untagged = false` y una etiqueta propia |
| `cache: unprotect: true` "porque así se comparte más" | Devuelve el envenenamiento de caché que la separación evitaba | Dejar que `main` y las ramas tengan sus cachés |
| Sin `maximum_timeout` en el runner de despliegue | Un `ssh` colgado retiene el entorno una hora | 15 minutos o menos |

---

## 5. Trucos

- `CI_COMMIT_REF_PROTECTED` está en todos los jobs: un `echo` al principio del `script` te dice si el job podría haber caído en un runner protegido.
- En el log de cada job, `Checking cache for <clave>-protected...` enseña qué sufijo ha tocado: es la forma rápida de comprobar la separación.

---

## 📚 Recursos Adicionales

- [Prevent runners from revealing sensitive information](https://docs.gitlab.com/ci/runners/configure_runners/#prevent-runners-from-revealing-sensitive-information)
- [Set the maximum job timeout](https://docs.gitlab.com/ci/runners/configure_runners/#set-the-maximum-job-timeout)
- [Cache key names](https://docs.gitlab.com/ci/caching/#cache-key-names)

---

## ✅ Checklist de Verificación

- [ ] Sé qué pasa con un job de una rama sin proteger que pide la etiqueta de un runner protegido
- [ ] Sé qué añade un runner protegido a las variables protegidas
- [ ] Sé qué tiempo máximo gana entre proyecto, job y runner
- [ ] Sé por qué en mi laboratorio veo `-protected` en ramas que no lo están

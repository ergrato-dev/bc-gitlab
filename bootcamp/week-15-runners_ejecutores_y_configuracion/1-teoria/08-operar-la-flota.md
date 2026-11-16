# Operar la flota

> Una flota no se configura una vez: se vigila, se actualiza, se le cambian las credenciales y se retiran las piezas que sobran. Todo eso pasa en dos sitios a la vez, GitLab y `config.toml`, y la mitad de los problemas de operación son esos dos sitios desincronizados: un runner borrado en GitLab que el proceso sigue intentando usar, un token rotado que nadie copió, una versión del runner que se quedó atrás.

---

## 🎯 Objetivos

- Ver el estado, la versión y la actividad de la flota por API
- Pausar un runner sin perder jobs, y saber cuándo es seguro reiniciar el proceso
- Rotar el token de un runner y poner caducidad a los tokens nuevos
- Retirar runners sin dejar restos en `config.toml`
- Versionar la configuración de la flota sin versionar sus secretos

---

## 1. Qué problema resuelve

Tres runners en un proceso son tres tokens en un archivo que nadie más ve. Si el portátil se rompe, ¿cómo vuelves a montar la flota? Si alguien lee `config.toml`, ¿cuánto tardas en dejar sus tokens sin valor? Si actualizas GitLab a la `19.3`, ¿sabes qué versión corre cada runner? Las tres preguntas tienen respuesta por API, y la cuarta pieza, el propio `config.toml`, se resuelve con una plantilla en un repositorio.

---

## 2. Cómo funciona

### 2.1 El estado de la flota

| Pregunta | Dónde |
|---|---|
| ¿Qué runners tiene `app` y están vivos? | `GET /projects/:id/runners?type=project_type` → `status` |
| ¿Qué proceso los atiende y con qué versión? | `GET /runners/:id/managers` → `system_id`, `version` |
| ¿Está ejecutando algo ahora? | `GET /runners/:id` → `job_execution_status` (`idle` o `active`) |
| ¿Qué ha ejecutado? | `GET /runners/:id/jobs?per_page=5` |
| ¿Hay runners abandonados? | `GET /runners?status=stale` (los tuyos) o `GET /runners/all?status=stale` (administrador) |

`status` toma cuatro valores: `online` (ha preguntado en las últimas dos horas), `offline`, `stale` (ni una pregunta en siete días) y `never_contacted` (creado y nunca registrado). Un runner `never_contacted` de hace un mes es un token que alguien creó y no usó: bórralo.

### 2.2 La versión

El runner tiene que ir **en la misma serie que el servidor**: `19.2.x` con GitLab `19.2.4`. Un runner más nuevo que el servidor no está soportado; uno mucho más viejo puede no entender lo que el servidor le pide. En este laboratorio la versión está fijada en `.env` (`RUNNER_VERSION=alpine-v19.2.2`) y la comprobación `flota-en-version-fijada` mira la de cada gestor:

```bash
glab api "runners/<id>/managers" | jq -r '.[].version'
# 19.2.2
```

Cuando subas GitLab, `docs/stack-versions.md` explica el orden: primero el servidor, después la imagen del runner, y la versión es la misma en los tres repositorios.

### 2.3 Pausar y reiniciar

`paused=true` hace que GitLab deje de dar jobs a ese runner; los que ya corren terminan. Es la forma de vaciar un runner antes de tocarlo:

```bash
glab api --method PUT "runners/<id>" -f paused=true | jq -c '{paused, status}'
# {"paused":true,"status":"paused"}
glab api "runners/<id>" | jq -r .job_execution_status      # espera a "idle"
```

Reiniciar el proceso (`docker compose restart gitlab-runner`) afecta a **todos** sus runners a la vez: un proceso, tres identidades. Antes de reiniciar, los tres en `idle`.

### 2.4 Rotar el token

El token `glrt-` es la identidad del runner. Si `config.toml` ha estado donde no debía (un `gitlab-runner list` pegado en un issue, una copia en un portátil prestado), se rota:

```bash
NT=$(glab api --method POST "runners/<id>/reset_authentication_token" | jq -r .token)
```

El token viejo deja de valer **en ese instante**. Comprobado en `19.2.4`: justo después, `gitlab-runner verify` dice `is not valid` para ese runner, y no coge jobs hasta que pones el nuevo en su `token = …` de `config.toml`. Por eso la rotación es un paso de dos líneas que se hace junto, no dos tareas.

Para que los tokens no vivan para siempre, la instancia puede ponerles caducidad (en segundos), por tipo de runner, en `Admin → Settings → CI/CD → Runners`:

```bash
glab api --method PUT application/settings -f project_runner_token_expiration_interval=7776000
```

Se aplica a los tokens que se emitan después: los que ya existen conservan `token_expires_at: null`. Con caducidad, el proceso renueva el token solo antes de que venza y lo reescribe en `config.toml`.

### 2.5 Retirar un runner

Borrar un runner en GitLab no lo quita de `config.toml`. El proceso sigue preguntando con un token que ya no existe, y el log se llena de `ERROR: Checking for jobs... forbidden … 403 Forbidden`. `verify --delete` limpia el archivo:

> [!WARNING]
> `verify --delete` borra **todos** los bloques que salgan `is not valid`, no solo el que retiras. Si acabas de rotar un token y aún no está en `config.toml`, ese runner también desaparece. Antes: una copia del archivo y un `verify` sin `--delete` donde solo salga inválido el bloque que quieres quitar.

```bash
glab api --method DELETE "runners/<id>"
docker compose cp gitlab-runner:/etc/gitlab-runner/config.toml ~/.bc-gitlab-runner.toml.antes-delete
chmod 600 ~/.bc-gitlab-runner.toml.antes-delete
docker compose exec gitlab-runner gitlab-runner verify 2>&1 | grep 'is not valid'   # solo el que retiras
docker compose exec gitlab-runner gitlab-runner verify --delete 2>&1 | grep -E 'is (valid|not valid)'
# Verifying runner... is valid      runner_name=docker-app
# Verifying runner... is not valid  runner_name=tmp-reg     ← este bloque desaparece del archivo
```

### 2.6 La plantilla versionada

`config.toml` no puede ir a un repositorio: lleva tokens. Pero todo lo demás (los tres bloques, sus `limit`, la caché, las listas de privilegiados) es exactamente lo que hay que poder reconstruir y revisar. La solución es una **plantilla** con los tokens sustituidos por marcadores:

```toml
concurrent = 3

[[runners]]
  name = "docker-app"
  token = "${TOKEN_DOCKER_APP}"
  limit = 2
  ...
```

Vive en `infra/entornos`, en `runners/config.toml.plantilla`, y cambia por merge request como cualquier otra pieza de infraestructura. Las comprobaciones `plantilla-con-cache-s3` y `plantilla-sin-secretos` la miran. Reconstruir la flota es `envsubst` con los tokens que da GitLab al crear los runners.

---

## 3. Cómo se configura

En la UI: `Settings → CI/CD → Runners` del proyecto o del grupo; cada runner tiene sus botones de pausar y editar, y en su página, el de restablecer el token. La vista de administrador (`Admin → CI/CD → Runners`) filtra por estado, tipo y versión.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Reiniciar el proceso con jobs en marcha | Mata los jobs de los tres runners | Pausar, esperar a `idle`, reiniciar |
| Borrar un runner y olvidar `config.toml` | El proceso pide trabajo con un token muerto para siempre | `verify --delete` justo después |
| Rotar el token sin cambiar `config.toml` | El runner deja de coger jobs y nadie sabe por qué | Las dos cosas en el mismo paso |
| `config.toml` en un repositorio | Tokens en el historial | La plantilla con marcadores |
| Actualizar el runner antes que GitLab | Versión de runner por delante del servidor: no soportado | El orden de `docs/stack-versions.md` |

---

## 5. Trucos

- `gitlab-runner list` imprime el token de cada runner. Para enseñar la flota sin enseñar los tokens: `gitlab-runner list 2>&1 | awk '{print $1, $2}'`.
- `GET /runners/:id/jobs?status=running` dice qué está haciendo un runner `active` antes de pausarlo.
- Las métricas del proceso (jobs en marcha, errores, peticiones) se exponen con `listen_address` en la sección global. Se enciende en la Semana 21, con Prometheus.

---

## 📚 Recursos Adicionales

- [Runners API](https://docs.gitlab.com/api/runners/)
- [Manage runners](https://docs.gitlab.com/ci/runners/runners_scope/)
- [Runner authentication token expiration](https://docs.gitlab.com/ci/runners/configure_runners/#automatically-rotate-runner-authentication-tokens)
- [Upgrade GitLab Runner](https://docs.gitlab.com/runner/install/docker/#upgrade-version)

---

## ✅ Checklist de Verificación

- [ ] Sé ver la versión y la actividad de cada runner por API
- [ ] Sé vaciar un runner antes de reiniciar el proceso
- [ ] Sé rotar un token y qué hay que hacer en `config.toml` en el mismo paso
- [ ] Sé retirar un runner de GitLab y de `config.toml`
- [ ] Sé por qué la plantilla va al repositorio y `config.toml` no

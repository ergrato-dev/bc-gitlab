# El `config.toml`

> Todo lo que el proceso `gitlab-runner` sabe hacer está en un archivo: a quién pide trabajo, cuántos jobs corre a la vez, con qué imagen, con qué privilegios y dónde guarda la caché. La otra mitad de la configuración de cada runner vive en GitLab y no se toca desde aquí. Saber qué mitad es cuál ahorra la tarde que se pierde editando una línea que el servidor ignora.

---

## 🎯 Objetivos

- Leer las dos capas del archivo: la sección global y cada `[[runners]]`
- Repartir la capacidad con `concurrent`, `limit` y `request_concurrency`
- Saber qué se configura en GitLab y qué en `config.toml`, y por qué `register` se niega a mezclarlos
- Cambiar el archivo sin reiniciar nada

---

## 1. Qué problema resuelve

En la Semana 11 cambiaste `concurrent = 1` por `concurrent = 2` con un `sed` y el DAG empezó a solaparse. Era la única línea que necesitabas. Esta semana el archivo tiene tres runners, una caché remota y un runner privilegiado, y la tentación es tratarlo como un bloque opaco que se regenera con `register`. Eso funciona hasta el día en que hay que cambiar el `limit` de uno solo, y `register` no edita: añade.

---

## 2. Cómo funciona

### 2.1 Dos capas

```toml
concurrent = 3          # global: jobs a la vez en todo el proceso
check_interval = 3      # global: segundos entre rondas de preguntas a GitLab
shutdown_timeout = 0

[[runners]]             # uno por runner; el orden no importa
  name = "docker-app"
  url = "http://gitlab:8888"
  clone_url = "http://gitlab:8888"
  id = 35
  token = "<TOKEN>"     # glrt-…: quien lo lea se hace pasar por este runner
  executor = "docker"
  limit = 2             # jobs a la vez de ESTE runner
  [runners.cache]       # dónde guarda la caché (teoría 07)
  [runners.docker]      # cómo crea el contenedor de cada job (teoría 03)
    image = "alpine:3.24.2"
    network_mode = "bc-gitlab-network"
    privileged = false
    volumes = ["/cache"]
```

La sección global habla del **proceso**; cada `[[runners]]` habla de **una identidad** y de su ejecutor. Las secciones que cuelgan de un `[[runners]]` (`[runners.docker]`, `[runners.cache]`, `[runners.cache.s3]`) solo afectan a ese runner: el runner privilegiado de la práctica 02 lo es en su bloque y en ningún otro.

### 2.2 La capacidad, en tres números

| Clave | Ámbito | Por defecto | Qué limita |
|---|---|:--:|---|
| `concurrent` | Global | `1` | Jobs a la vez en todo el proceso, sumando todos los runners |
| `limit` | Por runner | `0` (sin límite propio) | Jobs a la vez de ese runner |
| `request_concurrency` | Por runner | `1` | Peticiones de trabajo abiertas a la vez de ese runner (teoría 01, 2.4) |

`concurrent` es el techo. Si `docker-app` tiene `limit = 2`, `dind-app` `limit = 1` y `deploy-infra` `limit = 2`, la suma es 5, pero con `concurrent = 3` nunca correrán más de tres jobs. Eso es intencionado: los límites por runner reparten, el global protege la máquina.

| Configuración | Qué pasa con una cola de 10 jobs de `app` y un despliegue |
|---|---|
| `concurrent = 3`, sin `limit` | `docker-app` se queda los tres huecos; el despliegue espera |
| `concurrent = 3`, `docker-app` con `limit = 2` | Siempre queda un hueco para `dind-app` o `deploy-infra` |
| `concurrent = 1` | Todo en fila; el DAG de la Semana 11 vuelve a ser una lista |

En este laboratorio, con 16 GB y GitLab ocupando cinco, tres jobs a la vez es el máximo razonable: un job `dind` arranca un daemon de Docker entero.

### 2.3 Lo que decide el servidor y lo que decide tu máquina

Desde que los runners se crean en GitLab y se registran con un token `glrt-` (Semana 09), la configuración está partida:

| En GitLab (UI o API) | En `config.toml` |
|---|---|
| `tag_list`, `run_untagged` | `executor` y todo `[runners.docker]` |
| `locked`, `access_level` (`ref_protected`) | `limit`, `request_concurrency`, `concurrent` |
| `maximum_timeout`, `paused`, `description` | `[runners.cache]` |
| A qué proyectos o grupo pertenece | `url`, `clone_url`, `environment`, `output_limit` |

`gitlab-runner register` lo hace cumplir. Con un token `glrt-`, pedirle una etiqueta falla:

```
FATAL: Runner configuration other than name and executor configuration is reserved
(specifically --locked, --access-level, --run-untagged, --maximum-timeout, --paused, --tag-list,
and --maintenance-note) and cannot be specified when registering with a runner authentication token.
```

La regla práctica: **lo que decide qué jobs coge el runner, en GitLab; lo que decide cómo los ejecuta, en tu máquina**. Lo primero se audita por API (y por eso tiene comprobaciones); lo segundo no se ve desde GitLab, y por eso va a la rúbrica y a la plantilla versionada (teoría 08).

### 2.4 Se recarga solo

El proceso vigila el archivo. Al guardar, el log dice:

```
Configuration loaded                                builds=0 max_builds=3
```

No hace falta reiniciar, y no hay que hacerlo: un `restart` con jobs en marcha los mata. Si el archivo tiene un error de sintaxis, el log dice `ERROR: Failed to load config decoding configuration file: toml: line 112 …` y el proceso **sigue con la versión anterior**, sin caerse: los runners siguen `online` y nadie se entera de que tu cambio no ha entrado. Mira siempre el log después de guardar.

---

## 3. Cómo se configura

`register` **añade** un `[[runners]]`; nunca modifica uno existente. Para crear un runner nuevo, `register` con todas las opciones locales en la línea:

```bash
docker compose exec gitlab-runner gitlab-runner register --non-interactive \
  --url http://gitlab:8888 --clone-url http://gitlab:8888 --token "$RT" \
  --name dind-app --executor docker --docker-image alpine:3.24.2 \
  --docker-network-mode bc-gitlab-network --docker-privileged \
  --docker-volumes /certs/client --docker-volumes /cache --limit 1
```

Para cambiar uno existente, se edita el archivo. Dentro del contenedor hay `vi`; desde fuera, `docker compose cp` en las dos direcciones:

```bash
docker compose cp gitlab-runner:/etc/gitlab-runner/config.toml ~/.bc-gitlab-runner.toml
chmod 600 ~/.bc-gitlab-runner.toml           # lleva los tokens
"${EDITOR:-vi}" ~/.bc-gitlab-runner.toml
docker compose cp ~/.bc-gitlab-runner.toml gitlab-runner:/etc/gitlab-runner/config.toml
docker compose logs --since 1m gitlab-runner | grep -c 'Configuration loaded'
```

El archivo copiado vive **fuera del repositorio**, como `~/.bc-gitlab`, y con `chmod 600`. Bórralo al terminar si no lo vas a reutilizar.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Volver a hacer `register` para cambiar el `limit` | Crea un segundo `[[runners]]`; si reutilizas el token, dos bloques para el mismo runner | Editar el bloque existente |
| Editar `tag_list` en `config.toml` | El servidor no lo lee: las etiquetas de un runner `glrt-` son las de GitLab | `PUT /runners/:id -d tag_list=…` |
| `concurrent` alto "para que vaya más rápido" | Cada job `dind` es un daemon de Docker; la máquina se queda sin memoria y GitLab con ella | `concurrent` según la RAM, y `limit` en el runner caro |
| `docker compose restart gitlab-runner` tras cada cambio | Mata los jobs en curso, y no hacía falta | Guardar y mirar `Configuration loaded` |
| Subir `config.toml` a un repositorio | Los tokens quedan en el historial para siempre | Una plantilla sin tokens (teoría 08) |

---

## 5. Trucos

- `docker compose exec gitlab-runner grep -nE '^\s*(name|limit|executor) =' /etc/gitlab-runner/config.toml` enseña la flota de un vistazo sin enseñar los tokens.
- Si dudas de cómo escribe `register` una opción, regístrala en un runner de usar y tirar, mira el bloque que añade y bórralo después (`DELETE /runners/:id` y `gitlab-runner verify --delete`, teoría 08). Es más fiable que adivinar el nombre de la clave TOML.

---

## 📚 Recursos Adicionales

- [Advanced configuration](https://docs.gitlab.com/runner/configuration/advanced-configuration/)
- [Register a runner with a runner authentication token](https://docs.gitlab.com/runner/register/)
- [Configuration reload](https://docs.gitlab.com/runner/configuration/advanced-configuration/#how-configuration-reload-works)

---

## ✅ Checklist de Verificación

- [ ] Sé qué hace `concurrent` frente a `limit`, y qué pasa si la suma de los `limit` lo supera
- [ ] Sé qué cuatro cosas de un runner se cambian en GitLab y no en `config.toml`
- [ ] Sé por qué `register` no sirve para modificar un runner
- [ ] Sé cambiar el archivo sin reiniciar el proceso y comprobar que se ha recargado

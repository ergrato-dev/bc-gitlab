# Rúbrica de Evaluación — Semana 13

## 📊 Distribución de Evidencias

| Tipo | Peso | Instrumento | Quién juzga |
|---|:--:|---|---|
| 🧠 Conocimiento | 30% | 10 preguntas conceptuales, 10 pts cada una | Autoevaluación |
| 💪 Desempeño | 40% | Las 4 prácticas, 10 pts cada una | La API de tu instancia |
| 📦 Producto | 30% | La capa 13 de tu plataforma: 60 pts por API + 40 pts de calidad | Mixto |

**Criterio de aprobación: mínimo 70% en cada evidencia**, no en el promedio.

---

## 🧠 Conocimiento (30%)

| # | Pregunta |
|:--:|---|
| 1 | `docker login localhost:5050` funciona desde tu terminal y kaniko, con las mismas credenciales, falla dentro de un job con `connection refused`. ¿Qué pide cada uno, a quién, y en qué paso de la autenticación se separan sus caminos? |
| 2 | ¿Por qué no se arregla la trampa cambiando `registry['token_realm']` a `http://gitlab:8888`? ¿Qué dejaría de funcionar, y por qué `registrytoken` no tiene ese problema? |
| 3 | Un compañero propone activar `privileged = true` en el runner de `app` para usar `docker build`, "porque kaniko está archivado". ¿Qué está bien en su argumento, qué está mal, y qué le respondes? |
| 4 | La imagen de un pipeline de `main` lleva un tag y la de un pipeline de `v0.2.0`, dos. ¿Cuáles, por qué la versión va sin `v`, y por qué una merge request no sube ninguna? |
| 5 | Activas la política de limpieza por defecto, sin tocar nada más, en un proyecto con imágenes `1.0.0` a `1.20.0` de hace un año. ¿Qué borra la primera vez que corre, y qué dos cosas lo habrían evitado? |
| 6 | Borras con la API cuarenta tags de `app` y el tamaño del repositorio no baja. ¿Por qué? ¿Cuándo bajará, y qué cambia si el registry no tuviera base de metadatos? |
| 7 | `app` podría publicar su `.tgz` en el registro npm, porque su `package.json` ya tiene nombre de ámbito. ¿Por qué esta semana publica un paquete genérico, y qué tendría que pasar para que el registro npm fuera la buena elección? |
| 8 | Prohibiste los duplicados genéricos con una excepción para `^[0-9a-f]{40}$`. ¿Qué falla sin la excepción, qué falla sin la prohibición, y por qué `$CI_COMMIT_SHORT_SHA` como versión rompería la regla? |
| 9 | `registrar` de `infra/entornos` responde `404` al descargar el paquete, y el paquete existe. ¿Qué miras primero, en qué proyecto, y por qué GitLab no responde `403`? |
| 10 | La release `v0.2.0` enlaza el paquete con `direct_asset_path` y la imagen por digest en el nombre del enlace. ¿Qué aporta cada decisión frente a enlazar la URL del paquete y `app:0.2.0`? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** Los dos piden primero al registry y reciben un `401` con `realm="http://localhost:8888/jwt/auth"`. El daemon del host va a ese realm y `localhost:8888` es el puerto publicado de GitLab: le dan el token y entra. Kaniko corre en la red del compose; allí llega al registry por `gitlab:5050`, pero el realm que recibe es el mismo, y dentro del contenedor del job `localhost` es el propio job. El camino se separa en el paso 3: ir al realm con las credenciales.

**2.** El realm es uno para todos los clientes. Con `gitlab:8888`, el job funcionaría y el host dejaría de poder autenticarse, porque no resuelve `gitlab`: ni `docker login` desde tu terminal ni el runner al descargar el `image:` de un job de tu registry. `registrytoken` no cambia nada del registry: el job pide el token a una URL que sí alcanza (`$CI_SERVER_URL`), y kaniko lo envía tal cual sin consultar el realm. El host sigue por su camino normal.

**3.** Bien: depender de una herramienta archivada sin parches es un riesgo que hay que gestionar. Mal: `privileged` hace a cualquiera que escriba un `.gitlab-ci.yml` root en el host del runner, y el runner de `app` ejecuta código de merge requests. La respuesta: el fork mantenido de kaniko resuelve el archivado sin abrir esa puerta, la decisión queda en el ADR-010 para revisarla, y si hace falta Docker de verdad, va en un runner `dind` aparte, etiquetado y aislado (Semana 15), no en el de todos.

**4.** En `main`, `:<SHA corto>`; en `v0.2.0`, el SHA corto y `:0.2.0`. Sin `v` por la convención de Docker y para que la limpieza y la protección reconozcan las versiones con una sola expresión, `[0-9]+\.[0-9]+\.[0-9]+`. Una merge request construye con `--no-push`: el código aún no está revisado, y subirlo llenaría el registry de imágenes que nadie va a desplegar.

**5.** La política por defecto tiene `name_regex: .*`, `keep_n: 10` y `older_than: 90d`. De `1.0.0` a `1.20.0`, las diez más nuevas sobreviven por `keep_n` y las otras once, de hace un año, se borran. Lo habrían evitado un `name_regex_keep` que nombre las versiones, o un `name_regex` que nombre solo los SHA, y los tags protegidos: la política no borra un tag protegido aunque cumpla todo lo demás.

**6.** Un tag apunta a un manifiesto y el manifiesto a capas, que pueden compartirse con otras imágenes. Borrar el tag deja las capas huérfanas, pero no las borra. Con la base de metadatos, la recolección de basura en línea las elimina cuando llevan 24 horas sin referencias, sin hacer nada. Sin ella, hay que lanzar `gitlab-ctl registry-garbage-collect` con el registry en solo lectura; con la base activa, ese comando se niega a ejecutarse.

**7.** Lo que necesita `infra/entornos` es el binario de **un commit concreto**, en cada commit de `main`. El registro npm exige una versión semver única por publicación: habría que inventar `0.2.0-main.<sha>` en cada build, y no aportaría nada que la URL genérica no dé. El registro npm sería la buena elección el día que otro proyecto instale `app` como dependencia con `npm install`, y entonces solo en los tags.

**8.** Sin la excepción, reintentar `publicar-paquete` vuelve a subir el mismo SHA y falla con `Duplicate package is not allowed`, aunque el contenido sea el mismo. Sin la prohibición, subir otra vez `0.2.0` añade un archivo y la descarga devuelve el último: la versión cambia de contenido sin cambiar de nombre. El SHA corto tiene 8 caracteres y la expresión exige 40: las versiones por SHA corto no tendrían excepción, y además el SHA corto puede repetirse entre commits.

**9.** La lista de permitidos del job token de **`app`**, el proyecto al que se entra, no la de `infra/entornos`. GitLab responde `404` y no `403` para no confirmar que existe un proyecto al que no tienes acceso. Después, que quien lanzó el pipeline tenga al menos Reporter en `app`.

**10.** `direct_asset_path` da una URL bajo la release que no cambia aunque el binario cambie de sitio, y que no exige saber el ID del proyecto ni que vive en el registro de paquetes. El digest dice exactamente qué imagen es `0.2.0`, para siempre: un tag protegido es difícil de mover, pero en CE un Maintainer puede; el digest no se mueve.

</details>

---

## 💪 Desempeño (40%)

| Práctica | Qué se comprueba | Puntos |
|---|---|:--:|
| [01 — El registry y el Dockerfile](2-practicas/01-el-registry-y-el-dockerfile.md) | Registry en `localhost:5050`; subida y borrado con un PAT de solo registry; `Dockerfile` por merge request; el `connection refused`, visto; la regla de tags protegidos | 10 |
| [02 — El componente `imagen`](2-practicas/02-el-componente-imagen.md) | El componente, probado con valores que no son los de por defecto; `imagen-arranca` en verde; `1.2.0` con tres componentes; la imagen de `app` arranca en tu máquina | 10 |
| [03 — Limpieza y dependency proxy](2-practicas/03-limpieza-y-dependency-proxy.md) | Dos políticas distintas; el ensayo deja `1.2.0`; caducidad de 30 días; `Pulling docker image localhost:8888/…/dependency_proxy/…` en el log | 10 |
| [04 — El paquete por SHA](2-practicas/04-el-paquete-por-sha.md) | La excepción de duplicados; `infra/entornos` antes que `app`; sin `APP_PACKAGE_JOB_ID`; el reintento pasa y la segunda subida se rechaza; el `sha256` coincide | 10 |

---

## 📦 Producto (30%)

### Verificable por API — 60 puntos

| Requisito | Comprobación | Puntos |
|---|---|:--:|
| `Dockerfile` y `.dockerignore` | `dockerfile-en-main` | 3 |
| Tags de versión protegidos | `tags-de-imagen-protegidos` | 4 |
| Componente `imagen` | `componente-imagen` | 3 |
| `ci/componentes` en verde | `componentes-sigue-en-verde` | 4 |
| `imagen` publicado | `imagen-publicada` | 4 |
| `app` usa `imagen` por versión | `app-usa-imagen` | 3 |
| Imagen por SHA | `imagen-por-sha` | 4 |
| Limpieza activa | `limpieza-activa` | 4 |
| Proxy con caducidad | `proxy-con-caducidad` | 3 |
| `app` usa el proxy | `app-usa-dependency-proxy` | 3 |
| Duplicados solo por SHA | `duplicados-solo-por-sha` | 4 |
| `infra/entornos` descarga del registro | `infra-baja-del-registry` | 3 |
| Paquete por SHA | `paquete-por-sha` | 3 |
| Sin ID de job | `app-sin-id-de-job` | 3 |
| `infra/entornos` en verde | `infra-en-verde` | 4 |
| La release enlaza | `release-enlaza-paquete` | 4 |
| ADR-010 | `adr-010-registry` | 4 |

### Calidad — 40 puntos

| Criterio | Qué se mira | Puntos |
|---|---|:--:|
| La imagen no lleva nada que sobre | `.dockerignore` que empieza por `*`; sin tests, sin `.git`, sin `assets/`; `USER node`; base con versión completa | 10 |
| El componente no depende de `app` | Sin nombres de proyecto ni rutas fijas; `registro` e `inseguro` con valores de producción por defecto; sin claves globales | 10 |
| El ADR-010 decide y descarta | Responde los siete puntos del proyecto, con la trampa del realm explicada para quien no la ha sufrido | 10 |
| La release es para siempre | El paquete por `direct_asset_path` y la imagen por digest, no por tag | 5 |
| Las políticas tienen un motivo | Valores distintos en `app` y `ci/componentes`, y el ADR dice por qué | 5 |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| `privileged = true` en el runner de `app`, o `/var/run/docker.sock` montado en sus jobs | −15 |
| Un tag `latest` en cualquier registry del grupo | −10 |
| Un PAT personal en una variable de CI para subir o descargar | −15 |
| `registry['token_realm']` cambiado en la instancia | −10 |
| La política de limpieza con `name_regex: .*` y sin `name_regex_keep` | −10 |
| Duplicados genéricos permitidos para las versiones semver | −5 |
| Un cambio en `main` de `app` o de `ci/componentes` sin merge request | −10 |
| Los tokens `flujo-s13` o `registry-s13` sin revocar al terminar | −15 |

---

[← Volver a la Semana 13](README.md)

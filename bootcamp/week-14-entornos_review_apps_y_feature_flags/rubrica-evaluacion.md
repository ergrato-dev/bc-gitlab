# Rúbrica de Evaluación — Semana 14

## 📊 Distribución de Evidencias

| Tipo | Peso | Instrumento | Quién juzga |
|---|:--:|---|---|
| 🧠 Conocimiento | 30% | 10 preguntas conceptuales, 10 pts cada una | Autoevaluación |
| 💪 Desempeño | 40% | Las 4 prácticas, 10 pts cada una | La API de tu instancia |
| 📦 Producto | 30% | La capa 14 de tu plataforma: 60 pts por API + 40 pts de calidad | Mixto |

**Criterio de aprobación: mínimo 70% en cada evidencia**, no en el promedio.

---

## 🧠 Conocimiento (30%)

| # | Pregunta |
|:--:|---|
| 1 | Los diez últimos despliegues de `staging` en `infra/entornos` tienen el mismo SHA, y los diez desplegaron versiones distintas de `app`. ¿Por qué, dónde está la versión de `app` de cada uno, y qué deja de funcionar en GitLab por culpa de ese SHA repetido? |
| 2 | `REVIEW_SSH_KEY` está sin proteger y `DEPLOY_SSH_KEY` de `production`, protegida. ¿Por qué no se pueden proteger las dos, y qué hace que la primera sea aceptable sin protección? |
| 3 | Un compañero propone `-o StrictHostKeyChecking=no` en los jobs "porque la huella del destino cambia cuando reconstruyes la imagen". ¿Qué está mal en su premisa, y qué riesgo acepta su solución? |
| 4 | `revisor` es Maintainer de `app`, puede fusionar en `main` y lanzar sus jobs manuales, y recibe `403` al pulsar `infra-production`. ¿Qué comprueba GitLab exactamente, en qué proyecto, y qué daría un entorno protegido de Premium que esto no da? |
| 5 | En la práctica 02, `staging` sirvió la versión rota mientras GitLab decía que su último despliegue correcto era el anterior. ¿Por qué las dos cosas eran verdad a la vez, y qué cambiarías en `desplegar` o en `desplegar.sh` para que no ocurriera? |
| 6 | El rollback de la práctica 02 fue un reintento. ¿Qué cuatro cosas necesitaba el despliegue viejo para poder repetirse, y cuál de ellas habría fallado si `infra/entornos` siguiera descargando el artefacto del job `package`? |
| 7 | En la Semana 11, `staging` de `app` usaba `newest_first`. En `infra/entornos` usa `oldest_first`. ¿Qué pasaría con `newest_first` si dos fusiones seguidas disparan `staging`, y por qué en `app` no pasaba? |
| 8 | Fusionas una merge request y su review app se para sola; cierras otra sin fusionar y también. ¿Para qué sirve entonces `auto_stop_in`, y qué pasa en el destino si `parar-review` falla? |
| 9 | `multa-progresiva` está encendido para `socio-7` en `production` y lo apagas. ¿Cuánto tarda en notarse, qué pipeline corre, y qué hace `app` si en ese momento GitLab no responde? |
| 10 | `app` es privado y su sitio de Pages respondía `200` a cualquiera antes de esta semana. ¿Qué lo permitía, qué dos ajustes lo cierran, y por qué el dominio único importa aunque el sitio sea privado? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** Un despliegue guarda el SHA del commit de su pipeline, y los pipelines de `infra/entornos` corren sobre `main` de `infra/entornos`, que no cambia cuando `app` publica una versión: diez disparos, diez pipelines sobre el mismo commit, el mismo SHA. La versión de `app` viaja como variable (`APP_SHA`) y se ve en el nombre del pipeline (`app <SHA> → staging`), en el registro del job y en lo que responde el destino. Lo que deja de funcionar es la protección de despliegues obsoletos: `older_than_last_successful_deployment?` devuelve `false` si el SHA coincide con el del último despliegue, así que en `infra/entornos` ningún despliegue es nunca obsoleto, y `ci_forward_deployment_rollback_allowed` tampoco bloquea nada. El orden lo tiene que dar el resource group.

**2.** Una variable protegida solo llega a jobs de ramas o tags protegidos. Las review apps salen de pipelines de merge request, sobre ramas que no son protegidas: con `REVIEW_SSH_KEY` protegida, `review` no la recibiría y no podría desplegar. La de `production` sí se protege porque solo la necesita `main` de `infra/entornos`. Lo que hace aceptable la primera es el segundo cerrojo: en el destino, esa clave tiene `command="desplegar review-*",restrict`, así que quien la robe solo puede crear y borrar review apps. Ni toca `staging` ni `production`, ni abre una shell.

**3.** La premisa es falsa: la clave de host del destino vive en un volumen (`destino-claves`) y `arranque.sh` solo la genera si no existe, así que reconstruir la imagen no la cambia. Solo cambiaría si borras el volumen, y entonces lo correcto es copiar la huella nueva por un camino de confianza. `StrictHostKeyChecking=no` acepta cualquier clave que responda en `destino:22`: si alguien se pone en medio, el job le entrega el paquete y, peor, se autentica ante él. La huella en `DESTINO_KNOWN_HOSTS` es lo que convierte "alguien responde" en "responde el destino".

**4.** Para lanzar un job `trigger`, GitLab comprueba que quien lo lanza puede actualizar la rama de destino en el proyecto de abajo (`can_update_downstream_branch` en `bridge_policy.rb`): poder hacer push o fusionar en `main` de `infra/entornos`. `main` está protegida para Maintainer, así que ni siendo Developer allí, como en la práctica 02, puede; siendo Guest, ni siquiera llega a esa comprobación. La comprobación de `app` (poder lanzar un manual de `main`) la pasa; la de `infra/entornos`, no. Un entorno protegido de Premium ataría el permiso al **entorno** y no a la rama: daría igual desde qué proyecto o qué rama se despliegue, y además permitiría exigir aprobaciones de N personas para un despliegue concreto. Con un solo `infra/entornos` y pocos Maintainers, la rama protegida cubre lo mismo.

**5.** `desplegar` cambia el enlace `actual` en cuanto el paquete está descomprimido, y es después cuando `desplegar.sh` pregunta a `/salud` y falla. Para el destino, la versión nueva está desplegada; para GitLab, el job falló y su despliegue también, así que el último correcto es el anterior. Las dos miden cosas distintas. Arreglos posibles: que `desplegar` compruebe la versión nueva antes de mover `actual` (cargar el módulo, o servirla en una ruta temporal y llamarla), o que `desplegar.sh`, si la comprobación falla, vuelva a apuntar `actual` a la versión anterior. Cualquiera de los dos hace que un despliegue fallido no deje nada roto.

**6.** Las variables del pipeline (`APP_SHA`), que viven con él; el binario de esa versión, el paquete `app/<SHA>/app.tgz` del registro de paquetes; la credencial del entorno, que se lee al ejecutar y es la de hoy; y el código de `infra/entornos` de aquel commit, que se vuelve a clonar. Con el artefacto del job `package`, el binario habría caducado en una semana y el reintento de un despliegue de hace diez días habría fallado con `404`: esa es la razón de fondo del paquete por SHA de la Semana 13.

**7.** Con `newest_first`, el despliegue de la segunda fusión pasa primero. El de la primera queda esperando y, cuando el recurso se libera, se ejecuta y despliega la versión vieja encima. En `app` no pasaba porque el despliegue viejo fallaba como obsoleto: su SHA era distinto y más antiguo que el del último despliegue correcto. En `infra/entornos` todos tienen el mismo SHA, nada es obsoleto, y `newest_first` puede terminar en la versión vieja. `oldest_first` pasa por las dos en orden y termina siempre en la última.

**8.** `auto_stop_in` es la red para lo que nadie cierra: una merge request abierta y olvidada durante semanas sigue gastando un directorio y un módulo cargado en el destino, y `auto_stop_in` la para igual. Si `parar-review` falla (la clave cambió, el destino no responde), el job sale en rojo y el destino conserva el directorio, diga lo que diga la lista de entornos: GitLab y el destino dejan de coincidir. Por eso conviene comparar de vez en cuando `curl localhost:8095/` con la lista de entornos `available`.

**9.** Tarda lo que dura la caché de `flags.ts`, 15 segundos como mucho, y no corre ningún pipeline: el código desplegado pregunta a GitLab en cada petición (pasada la caché) y la respuesta ha cambiado. Si GitLab no responde, `flags.ts` sigue con la última respuesta buena que tenga en memoria; si nunca tuvo una, todo apagado. Es la decisión correcta para `production`: un problema de GitLab no puede tumbar `app`, y "apagado" es el comportamiento de antes del flag.

**10.** El servidor de Pages, sin `gitlab_pages['access_control']`, sirve cualquier sitio a cualquiera que tenga la URL, sin mirar la visibilidad del proyecto. Lo cierran dos ajustes: `access_control = true` en la instancia (el compose de esta semana) y `pages_access_level = private` en el proyecto. El dominio único da a cada proyecto su propio origen: sin él, todos los sitios del grupo comparten `plataforma-<dominio>.pages.localhost`, y el JavaScript de uno puede leer lo que otro guardó en el navegador. Que el sitio sea privado protege de los de fuera, no de los otros sitios del grupo.

</details>

---

## 💪 Desempeño (40%)

| Práctica | Criterio | Puntos |
|---|---|:--:|
| [01 — El destino y staging](2-practicas/01-el-destino-y-staging.md) | Destino en marcha; dos claves nuevas con comando forzado y la prueba de que la de `staging` no para `production`; variables en `infra/entornos`; `staging` responde con el SHA de `main` de `app` | 10 |
| [02 — Producción y rollback](2-practicas/02-produccion-y-rollback.md) | `app` sin `DEPLOY_`; el `403` de `revisor`; `production` desplegado; `staging` roto, devuelto con un reintento y comprobado en el destino; el arreglo después | 10 |
| [03 — Review apps](2-practicas/03-review-apps.md) | Clave de review limitada a `review-*`; dos review apps a la vez con respuestas distintas; una parada al cerrar y otra al fusionar; el borrado simulado | 10 |
| [04 — El feature flag y Pages](2-practicas/04-feature-flag-y-pages.md) | El código apagado en los tres entornos; el flag por entorno y por socio; apagado sin pipeline; Pages con `302` para un anónimo | 10 |

---

## 📦 Producto (30%)

### Verificable por API — 60 puntos

| Requisito | Comprobación | Puntos |
|---|---|:--:|
| Una clave por entorno en `infra/entornos` | `claves-por-entorno-en-infra` | 4 |
| La huella del destino | `huella-del-destino` | 3 |
| Resource group por entorno | `resource-groups-en-infra` | 3 |
| `staging` desplegado | `staging-desplegado` | 4 |
| `app` sin credenciales de entornos | `app-sin-secretos-de-entornos` | 4 |
| `production` manual desde `app` | `produccion-manual-desde-app` | 3 |
| `production` desplegado | `production-desplegado` | 4 |
| Rollback en `staging` | `rollback-en-staging` | 4 |
| Clave propia para las review apps | `review-con-clave-propia` | 3 |
| Review app dinámica | `review-app-dinamica` | 3 |
| Review app desplegada | `review-desplegada` | 3 |
| Review app parada | `review-parada` | 3 |
| `app` lee los flags | `app-lee-los-flags` | 3 |
| Flag por entorno | `flag-por-entorno` | 4 |
| Pages publicado | `pages-publicado` | 3 |
| Pages solo para miembros | `pages-solo-miembros` | 3 |
| Frecuencia de despliegue | `metricas-cuentan-despliegues` | 3 |
| ADR-011 | `adr-011-entornos` | 3 |

### Calidad — 40 puntos

| Criterio | Qué se mira | Puntos |
|---|---|:--:|
| Cada clave hace solo lo suyo | `authorized_keys` con `command=` y `restrict` en las tres; ninguna variable de clave con ámbito `*`; ningún `StrictHostKeyChecking=no` | 10 |
| El ADR-011 decide y descarta | Responde los siete puntos del proyecto, con el `403` de `revisor` explicado para quien no conoce la regla | 10 |
| El rollback y el flag, probados donde importa | El rollback comprobado en el destino; el flag apagado sin pipeline y con su issue de limpieza | 10 |
| El inventario cuenta la verdad | `docs/secretos.md` con dónde vive cada clave hoy, lo que se borró, y fechas que `caducidades.sh` lee | 5 |
| La métrica cambia con su definición | `docs/metricas.md` explica qué cuenta ahora la frecuencia y por qué | 5 |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| `StrictHostKeyChecking=no` en cualquier job o script | −15 |
| Una clave en `authorized_keys` sin `command=` | −15 |
| `DEPLOY_SSH_KEY` o `DEPLOY_TOKEN` todavía en `app` | −10 |
| `main` de `infra/entornos` abierta a Developer para desplegar | −10 |
| El identificador de instancia de los flags en el repositorio | −10 |
| Pages de `app` en `public` | −5 |
| Un cambio en `main` de `app` sin merge request | −10 |
| El token `flujo-s14` sin revocar, o las claves privadas en `~/.ssh` al terminar | −15 |

---

[← Volver a la Semana 14](README.md)

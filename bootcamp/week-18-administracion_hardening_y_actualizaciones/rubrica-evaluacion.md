# Rúbrica de Evaluación — Semana 18

## 📊 Distribución de Evidencias

| Tipo | Peso | Instrumento | Quién juzga |
|---|:--:|---|---|
| 🧠 Conocimiento | 30% | 10 preguntas conceptuales, 10 pts cada una | Autoevaluación |
| 💪 Desempeño | 40% | Las 4 prácticas, 10 pts cada una | La API de tu instancia |
| 📦 Producto | 30% | La capa 18 de tu plataforma: 60 pts por API + 40 pts de calidad | Mixto |

**Criterio de aprobación: mínimo 70% en cada evidencia**, no en el promedio.

---

## 🧠 Conocimiento (30%)

| # | Pregunta |
|:--:|---|
| 1 | Cambias `disable_password_authentication_for_users_with_sso_identities` a `true`, pruebas en el acto a entrar con contraseña como un usuario vinculado, y entra. ¿Ha fallado el ajuste? ¿Qué harías antes de dar la prueba por mala, y por qué el mismo efecto no se da con una opción de `gitlab.rb`? |
| 2 | Un compañero quiere añadir el proveedor OIDC por `PUT /application/settings` "para no recrear el contenedor". ¿Por qué no puede, y qué regla te dice en qué sitio vive un ajuste? |
| 3 | Con el modo admin activo, tu script de administración empieza a recibir `403` en `application/settings` con el mismo token de `root` de siempre. ¿Qué le falta, y qué protege exactamente el modo admin que no protegía antes? |
| 4 | Keycloak vincula cuentas por email y el realm admite que cualquiera se registre. Describe el ataque, paso a paso, y los dos ajustes (uno en cada lado) que lo cierran. |
| 5 | En el laboratorio, GitLab llama a `keycloak:8080` para el token y el navegador a `localhost:8180` para el login. ¿Por qué no basta una de las dos, qué fija `KC_HOSTNAME`, y qué falla exactamente si el emisor del token no coincide con el `issuer` de GitLab? |
| 6 | Activas las rutas protegidas y el auditor de la Semana 17 sigue funcionando, pero ChatOps empieza a recibir `429` los lunes a las nueve. ¿Qué límite es probablemente, cómo lo confirmas sin adivinar, y por qué la respuesta no es meter su usuario en la lista de exentos? |
| 7 | Un maintainer crea un webhook a `http://keycloak:8080/`. ¿Qué podría conseguir si la red local estuviera abierta, qué le contesta tu instancia, y por qué los hooks de sistema se cierran aparte aunque solo los cree un admin? |
| 8 | Alguien cambió `signup_enabled` a `true` ayer por la tarde. Sin Premium, ¿dónde buscas quién fue y con qué token, según lo hiciera por API o por la web, y qué te impide encontrarlo dentro de un mes? |
| 9 | Tu instancia está en 19.1.10 y quieres llegar a 19.5. Escribe el camino, di qué tiene que estar terminado entre un salto y el siguiente, y qué dos archivos copias fuera antes del primero. |
| 10 | Tras subir a 19.2.4, la instancia arranca, los datos están, y todo `PUT /application/settings` falla con `{"importers":["must be a valid json schema"]}`. ¿Por qué no lo detectó el `reconfigure`, por qué no aparece en una instancia instalada en 19.2 desde cero, y qué tiene que haber antes de arreglarlo a mano? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** No ha fallado. Cada proceso de Puma y Sidekiq cachea los ajustes de `application/settings` y los relee aproximadamente cada minuto: la API devuelve el valor nuevo al instante, pero el proceso que atendió el login aún tenía el viejo. Antes de juzgar, se espera un minuto y se repite. Con `gitlab.rb` no pasa porque esos ajustes se cargan al arrancar: no hay valor nuevo hasta recrear el contenedor o hacer `reconfigure`, y entonces está en todos los procesos a la vez.

**2.** Porque los proveedores de OmniAuth se cargan al arrancar Rails: son infraestructura, no política, y viven en `gitlab.rb` (en el laboratorio, `GITLAB_OMNIBUS_CONFIG`). La regla: si cambia **qué se permite** (registro, contraseñas, límites), está en la base de datos y tiene API; si cambia **qué arranca o cómo se conecta** (proveedores, puertos, `monitoring_whitelist`), está en `gitlab.rb` y exige recrear.

**3.** Le falta el scope `admin_mode`: con el modo admin activo, un token de administrador solo llega a los endpoints de admin si lo tiene. En la web, protege que una sesión de `root` robada (una cookie, un navegador abierto) no pueda cambiar la política de la instancia sin volver a introducir la contraseña. En la API, separa los tokens que leen como `root` de los que administran: el que tenías en un script de lectura deja de poder cambiar ajustes.

**4.** El atacante se registra en el realm con el email de una persona que ya tiene cuenta en GitLab, por ejemplo la de un maintainer. Entra en GitLab con *Keycloak*; GitLab recibe un token válido con ese email, encuentra la cuenta y la vincula (`omniauth_auto_link_user`). Desde ese momento, el atacante entra como el maintainer. Lo cierran: en Keycloak, `registrationAllowed: false` en el realm (las identidades las crea un admin, con el email verificado); en GitLab, que las altas nuevas queden en espera (`omniauth_block_auto_created_users`), aunque esto solo protege las cuentas nuevas, no la vinculación. Por eso el primero es el imprescindible.

**5.** El navegador está en tu máquina y solo ve `localhost`; GitLab está dentro de la red del compose, donde `localhost` es el propio contenedor de GitLab. Cada uno necesita la dirección que puede alcanzar. `KC_HOSTNAME` fija el emisor (`iss`) de los tokens a `http://localhost:8180/realms/bootcamp`, aunque GitLab pida el token por `keycloak:8080`. Si el `iss` no coincide con el `issuer` de la configuración de GitLab, la validación del `id_token` falla y GitLab devuelve al usuario al login sin sesión, con el error en `application_json.log`.

**6.** Las rutas protegidas solo cuentan POST a login y registro: no es eso. Lo probable es `throttle_authenticated_api`, si ChatOps comparte token con otro script que también se lanza a esa hora. Se confirma con la cabecera `RateLimit-Name` del `429` y con las líneas `Rack_Attack` de `auth.log`, que dicen qué límite (`matched`) y para quién. La lista de exentos quita el freno a un token que, si se roba, ya no tiene ninguno; lo correcto es un token por automatización, menos peticiones, y respetar `Retry-After`.

**7.** Con la red local abierta, GitLab haría peticiones HTTP a Keycloak desde dentro de la red del compose, donde no hay balanceador ni cortafuegos delante: cada "Test" del webhook es una petición que el atacante elige, y la respuesta (código, tiempo, a veces el cuerpo en el registro de entregas) le dice qué servicios hay y qué contestan. Es un SSRF: usar el servidor de GitLab para llegar a donde el atacante no llega. Tu instancia rechaza crearlo con `Invalid url given`, porque `keycloak` resuelve a una IP privada y no está en la lista. Los hooks de sistema se cierran aparte porque vienen abiertos de fábrica y tienen su propio ajuste: que los cree un admin no ayuda si el token de un admin se filtra, y entonces el SSRF alcanza toda la red de la instancia.

**8.** Si fue por API, en `api_json.log`: la línea con `"method":"PUT","path":"/api/v4/application/settings"`, con `username`, `token_id` y la lista de `params`. Si fue por la web, en `production_json.log`: el controlador de ajustes de admin, con `username`. Dentro de un mes no lo encontrarás porque los logs del contenedor rotan, y nadie los ha sacado de él. Los eventos de auditoría con retención y API son Premium; en CE, el sustituto es enviar los logs a Loki (Semana 21) y que `docs/endurecimiento.md` diga cuál es el valor bueno de cada ajuste.

**9.** 19.1.10 → 19.2.x (parada obligatoria, el último parche) → 19.5.x. Entre los dos saltos, todas las `batched_background_migrations` en `finished`: las de 19.2 son trabajo que 19.5 da por hecho. Antes del primero, en 19.1.10: el backup (`gitlab-backup create`), y fuera del servidor `gitlab-secrets.json` y `gitlab.rb`, que no van dentro.

**10.** El `reconfigure` revisa la configuración de `gitlab.rb` y aplica las migraciones del esquema, pero no valida el contenido de los ajustes ya guardados: el problema está en un valor que 19.1 dejó en la base de datos (`import_jobs_concurrency_limit` dentro de `importers`) y que el esquema JSON de 19.2 ya no admite. Solo aparece al guardar, porque la validación se hace al escribir. Una instancia nueva en 19.2 nunca tuvo esa clave. Antes del `UPDATE` a mano: el backup de la versión de partida copiado fuera, con sus secretos, y la consulta exacta apuntada en el informe.

</details>

---

## 💪 Desempeño (40%)

| Práctica | Criterio | Puntos |
|---|---|:--:|
| [01 — La política de la instancia](2-practicas/01-la-politica-de-la-instancia.md) | `infra/plataforma` privado con `main` protegida antes del primer push; la foto de antes guardada antes del primer `PUT`; las siete reglas de la política aplicadas; `root` con 2FA configurado; Git por HTTP con contraseña rechazado; el `400` del periodo de 30 días visto | 10 |
| [02 — Login con Keycloak](2-practicas/02-login-con-keycloak.md) | El perfil `sso` con contraseña y secreto solo en `.env`; el realm sin registro y con protección contra fuerza bruta; el cliente confidencial con PKCE; dos cuentas vinculadas por email; un alta en espera; un vinculado rechazado con contraseña y `root` entrando | 10 |
| [03 — Límites y superficie](2-practicas/03-limites-y-superficie.md) | El uso medido antes de limitar; los límites activos y el auditor en verde; un `429` provocado y su línea en `auth.log`; los hooks de sistema cerrados y `receptor-sistema` firmado sin flags; `user_create` en el canal; la marca activada; `docs/endurecimiento.md` con la tabla de antes y después | 10 |
| [04 — El ensayo de actualización](2-practicas/04-el-ensayo-de-actualizacion.md) | El laboratorio parado antes del ensayo; datos sembrados; backup y secretos fuera del contenedor; el salto cronometrado; la variable cifrada intacta; migraciones esperadas hasta `finished`; la clave deprecada y el ajuste bloqueado encontrados; el informe; el ensayo borrado por nombre y el laboratorio en 19.2.4 | 10 |

---

## 📦 Producto (30%)

### Verificable por API — 60 puntos

| Requisito | Comprobación | Puntos |
|---|---|:--:|
| `main` de `infra/plataforma` protegida, sin force push | `plataforma-protege-main` | 2 |
| `infra/plataforma` privado | `plataforma-privado` | 2 |
| Registro cerrado | `registro-cerrado` | 3 |
| 2FA de administradores y modo admin | `admin-con-2fa` | 4 |
| Contraseñas y Git por HTTP | `contrasenas` | 3 |
| Visibilidad pública restringida | `visibilidad-publica-restringida` | 3 |
| Cuentas dormidas | `cuentas-dormidas` | 2 |
| Registro de runners heredado cerrado | `registro-runner-legado-cerrado` | 2 |
| Dos cuentas vinculadas por OIDC | `oidc-cuentas-vinculadas` | 5 |
| Un alta en espera | `oidc-alta-en-espera` | 4 |
| SSO sin contraseña | `sso-sin-contrasena` | 3 |
| Límites de peticiones | `limites-de-peticiones` | 3 |
| Rutas protegidas | `rutas-protegidas` | 3 |
| Hooks sin red local | `hooks-sin-red-local` | 4 |
| `docs/endurecimiento.md` | `endurecimiento-documentado` | 4 |
| El informe del ensayo | `informe-de-actualizacion` | 5 |
| El laboratorio en 19.2.4 | `laboratorio-en-version-fijada` | 3 |
| El manual de la instancia | `manual-de-la-instancia` | 5 |

### Calidad — 40 puntos

| Criterio | Qué se mira | Puntos |
|---|---|:--:|
| El informe sirve para la actualización real | Tiempos medidos, camino comprobado, comprobaciones de después y hallazgos reales con su arreglo exacto | 12 |
| El acceso de emergencia existe | `root` con 2FA y códigos fuera de los repositorios; el ensayo con Keycloak parado, con su resultado en el manual | 10 |
| La política está explicada | Cada fila de `docs/endurecimiento.md` con su valor de antes y un porqué; las diferencias entre laboratorio y producción (`monitoring_whitelist`, `trusted_proxies`) escritas | 10 |
| Los secretos se quedan en casa | Secreto del cliente, contraseña de Keycloak, contraseña del ensayo y token del ensayo solo en `.env` o en `~/bc-s18`, con `600`/`700`; nada en repositorios ni en el historial | 8 |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| El realm `bootcamp` con registro propio activado | −15 |
| `allow_local_requests_from_web_hooks_and_services` o `allow_local_requests_from_system_hooks` en `true` | −15 |
| `docker compose down -v` durante el ensayo, o el laboratorio actualizado en lugar del ensayo | −15 |
| Un secreto de esta semana (cliente de Keycloak, contraseñas, tokens) en un repositorio | −20 |
| El `UPDATE` de la base de datos hecho sin backup previo | −10 |
| Un usuario en la lista de exentos de los límites sin motivo escrito | −5 |
| Un token de administración sin caducidad | −5 |

---

[← Volver a la Semana 18](README.md)

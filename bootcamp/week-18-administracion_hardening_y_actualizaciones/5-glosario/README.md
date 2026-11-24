# 📖 Glosario — Semana 18

Términos que aparecen esta semana. El nombre real de la feature va en inglés entre paréntesis, y el **tier** cuando aplica.

El glosario acumulado de toda la plataforma está en [glosario-global](../../../docs/glosario-global.md).

---

## A

**Alta en espera** (*pending approval*) — Estado `blocked_pending_approval` de una cuenta que llegó por un proveedor de identidad (o por registro con aprobación) y que un admin aún no ha aprobado con `POST /users/:id/approve`. `GET /users?blocked=true` no la incluye.

**`application/settings`** — La API de los ajustes de la instancia que viven en la base de datos: 449 campos en 19.2.4. Se leen con `GET` y se cambian con `PUT`; su efecto tarda alrededor de un minuto por la caché de cada proceso.

**`auth.log`** — Log de `gitlab-rails` donde queda cada petición frenada por un límite (`"message":"Rack_Attack"`, con `matched`, IP y ruta).

**`api_json.log`** — Log de `gitlab-rails` con una línea por petición a la API: método, ruta, parámetros, usuario y `token_id`. En CE, la forma de saber quién cambió un ajuste por API.

## B

**Backup** (*`gitlab-backup create`*) — Free. Empaqueta base de datos, repositorios, artefactos, paquetes y uploads en un `.tar` con la versión en el nombre. No incluye `gitlab-secrets.json` ni `gitlab.rb`. Solo se restaura en la misma versión.

**Batched background migrations** — Migraciones de datos que GitLab hace por lotes en Sidekiq después de actualizar. Antes del siguiente salto de versión, todas en `finished`. Se ven en `GET /admin/batched_background_migrations`.

## C

**Caché de ajustes** — Cada proceso de Puma y Sidekiq guarda `application/settings` en memoria y lo relee aproximadamente cada minuto. La razón de esperar antes de juzgar un cambio.

**Cliente confidencial** (*confidential client*) — Cliente OIDC que tiene secreto y lo presenta al pedir el token. GitLab lo es: el secreto vive en el servidor, no en el navegador.

**Cuentas dormidas** (*dormant users*) — Free. Cuentas sin actividad durante `deactivate_dormant_users_period` días (90 como mínimo), que GitLab desactiva solo. Se reactivan al iniciar sesión.

## D

**Deprecations** — Lista al final de la salida de `gitlab-ctl reconfigure` con las claves de `gitlab.rb` que la versión ha deprecado y su sustituta.

## E

**Emisor** (*issuer*, `iss`) — Quién firma un token OIDC. GitLab compara el `iss` del `id_token` con el `issuer` de su configuración; en el laboratorio lo fija `KC_HOSTNAME`.

## G

**`gitlab-secrets.json`** — Las claves con que GitLab cifra variables de CI, tokens de runners y secretos 2FA. Va fuera del backup y hay que copiarlo junto a él.

## H

**Hook de sistema** (*system hook*) — Free. Webhook de toda la instancia, que crea un admin. Manda siempre las altas y bajas de usuarios, proyectos, grupos y miembros, aunque no se marque ningún evento.

## K

**Keycloak** — Proveedor de identidad de código abierto. En el laboratorio, la versión 26.8.2 en el perfil `sso`, con el realm `bootcamp`.

**`KC_HOSTNAME`** — Variable de Keycloak que fija la URL pública con la que firma los tokens y construye sus enlaces, sea cual sea la dirección por la que se le pregunte.

## L

**Límites de peticiones** (*rate limits*, `throttle_*`) — Free. Cuántas peticiones por periodo admite GitLab de un usuario o una IP, por tipo de tráfico. Al pasarse, `429` con `RateLimit-Name` y `Retry-After`.

## M

**Modo admin** (*Admin Mode*) — Free. Con `admin_mode` activo, entrar en `Admin` pide volver a autenticarse, y un token de administrador necesita el scope `admin_mode` para los endpoints de administración.

**`monitoring_whitelist`** — Opción de `gitlab.rb` con las IP que pueden consultar `/-/health`, `/-/readiness`, `/-/liveness` y `/-/metrics`. A las demás se les contesta `404`.

## O

**OIDC** (*OpenID Connect*) — Free. Capa de identidad sobre OAuth 2.0: el proveedor dice quién es el usuario con un `id_token` firmado. GitLab lo usa a través de OmniAuth.

**OmniAuth** — La librería con que GitLab integra proveedores de identidad externos. Se configura en `gitlab.rb` (`omniauth_providers`, `omniauth_auto_link_user`, `omniauth_block_auto_created_users`).

## P

**Parada obligatoria** (*required upgrade stop*) — Versión por la que hay que pasar al actualizar. En la serie 19: 19.2, 19.5, 19.8 y 19.11.

**PKCE** (*Proof Key for Code Exchange*) — Extensión de OAuth en la que el cliente manda un `code_challenge` al empezar y el `code_verifier` al cambiar el código: un código robado no sirve sin el verificador.

## R

**Realm** — En Keycloak, un espacio aislado de usuarios, clientes y políticas. `master` administra Keycloak; las aplicaciones van en uno propio.

**Rutas protegidas** (*protected paths*) — Free. Límite propio para los POST a login, recuperación de contraseña y registro: 10 por minuto por defecto.

## S

**SSO sin contraseña** — El ajuste `disable_password_authentication_for_users_with_sso_identities`: quien tiene una identidad del proveedor ya no entra en la web con contraseña de GitLab.

**SSRF** (*Server-Side Request Forgery*) — Hacer que el servidor haga peticiones en tu nombre a direcciones que tú no alcanzas. Es lo que cierran los ajustes de red local de webhooks y hooks de sistema.

## T

**Token de registro de runners** (*registration token*) — Sistema antiguo de alta de runners con un secreto compartido. Deprecado; se cierra con `allow_runner_registration_token=false`. Su sustituto es el token de autenticación de cada runner (`glrt-`).

## V

**Vinculación por email** (*auto link*) — `omniauth_auto_link_user`: si el email que manda el proveedor ya es el de una cuenta de GitLab, la identidad se añade a esa cuenta en lugar de crear otra.

---

[← Volver a la Semana 18](../README.md)

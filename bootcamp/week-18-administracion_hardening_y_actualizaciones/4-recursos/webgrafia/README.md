# 🔗 Enlaces — Semana 18

Comprobados en noviembre de 2026 contra la documentación de GitLab 19.2 y Keycloak 26.8.

## Los que vas a tener abiertos toda la semana

| Enlace | Para qué |
|---|---|
| [Application settings API](https://docs.gitlab.com/api/settings/) | Cada campo de `application/settings`, con su tipo y su valor por defecto |
| [Use OpenID Connect as an authentication provider](https://docs.gitlab.com/administration/auth/oidc/) | La configuración del proveedor en `gitlab.rb`, `discovery`, `pkce` y `client_options` |
| [OmniAuth](https://docs.gitlab.com/integration/omniauth/) | `auto_link_user`, `block_auto_created_users` y `allow_single_sign_on` |
| [Keycloak — Server Administration Guide](https://www.keycloak.org/docs/latest/server_admin/) | Realms, clientes, usuarios y la protección contra fuerza bruta |
| [Keycloak — Configuring the hostname](https://www.keycloak.org/server/hostname) | `KC_HOSTNAME`, el emisor y el canal de servidor a servidor |
| [User and IP rate limits](https://docs.gitlab.com/administration/settings/user_and_ip_rate_limits/) | Los `throttle_*`, las cabeceras, la lista de exentos y el modo de prueba |
| [Upgrade paths](https://docs.gitlab.com/update/upgrade_paths/) y la herramienta [Upgrade Path](https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/) | Las paradas obligatorias y el camino entre dos versiones |

## Para cuando lo necesites

| Enlace | Para qué |
|---|---|
| [Hardening recommendations](https://docs.gitlab.com/security/hardening/) | La lista de GitLab para endurecer una instancia, para comparar con tu política |
| [Sign-up restrictions](https://docs.gitlab.com/administration/settings/sign_up_restrictions/) y [Sign-in restrictions](https://docs.gitlab.com/administration/settings/sign_in_restrictions/) | Registro, aprobación, longitud de contraseña, 2FA, Git por HTTP y modo admin |
| [Users API](https://docs.gitlab.com/api/users/) | Filtros de `GET /users`, `approve`, `reject`, `block` y `activate` |
| [Protected paths](https://docs.gitlab.com/administration/settings/protected_paths/) | La lista de rutas y por qué solo cuenta POST |
| [Filtering outbound requests](https://docs.gitlab.com/security/webhooks/) | Red local, excepciones y DNS rebinding |
| [System hooks](https://docs.gitlab.com/administration/system_hooks/) | Los eventos que manda siempre y el cuerpo de cada uno |
| [IP allowlist](https://docs.gitlab.com/administration/monitoring/ip_allowlist/) | `monitoring_whitelist` |
| [Log system](https://docs.gitlab.com/administration/logs/) | `api_json.log`, `production_json.log`, `audit_json.log` y `auth.log` |
| [Background migrations](https://docs.gitlab.com/update/background_migrations/) | Ver, esperar y reintentar las migraciones en segundo plano |
| [Back up GitLab](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/) | Qué entra en el backup, qué no, y `STRATEGY=copy` |

---

[← Volver a la Semana 18](../../README.md)

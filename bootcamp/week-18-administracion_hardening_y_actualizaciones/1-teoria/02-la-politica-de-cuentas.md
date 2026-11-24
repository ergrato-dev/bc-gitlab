# La política de cuentas

> Una instancia recién instalada deja que cualquiera se registre, acepta contraseñas de ocho caracteres, deja clonar por HTTP con la contraseña de la cuenta y nunca desactiva a nadie. Nada de eso es un fallo: es una instancia pensada para arrancar rápido. Una política de cuentas son media docena de ajustes que deciden quién entra, con qué y hasta cuándo.

---

## 🎯 Objetivos

- Decidir cómo nacen las cuentas: registro abierto, cerrado o por un proveedor de identidad con aprobación
- Exigir 2FA a los administradores y entender qué protege y qué no
- Fijar la longitud de contraseña y cerrar Git por HTTP con contraseña
- Desactivar cuentas dormidas y saber qué límites tiene GitLab para los tokens
- Cerrar el registro de runners heredado sin romper la flota

---

## 1. Qué problema resuelve

Las cuentas son la puerta. Los permisos de proyecto (Semana 03) y las ramas protegidas (Semana 04) deciden qué puede hacer alguien **dentro**; la política de cuentas decide **quién llega a estar dentro** y qué pasa con quien deja de usarlo. Cada ajuste cierra un camino concreto:

| Camino | Ajuste que lo cierra |
|---|---|
| Alguien de fuera se crea una cuenta y ve todo lo `internal` | `signup_enabled=false` |
| Roban la contraseña de `root` | `require_admin_two_factor_authentication` |
| Fuerza bruta sin conexión sobre un volcado de contraseñas | `minimum_password_length` |
| La contraseña de la cuenta sirve también para clonar desde cualquier script | `password_authentication_enabled_for_git=false` |
| La cuenta de alguien que se fue hace un año sigue activa | `deactivate_dormant_users` |
| Un token sin caducidad olvidado en un script | `require_personal_access_token_expiry` |
| Un único secreto que registra runners sin límite | `allow_runner_registration_token=false` |

---

## 2. Cómo funciona

### 2.1 Cómo nacen las cuentas

Tres formas, que se combinan:

| Forma | Ajuste | Cuándo |
|---|---|---|
| Registro propio en `/users/sign_up` | `signup_enabled` (y `require_admin_approval_after_user_signup` para que esperen) | Instancias abiertas a una comunidad. En empresa, casi nunca |
| Un admin la crea | `POST /users` o `Admin → Users → New user` | Cuentas de servicio y casos sueltos |
| Llega por un proveedor de identidad | `omniauth_block_auto_created_users` en `gitlab.rb` | Lo normal en empresa: la cuenta existe porque existe en el directorio (práctica 02) |

Esta semana el registro se cierra y las cuentas llegan por Keycloak. Las que llegan nuevas quedan en `blocked_pending_approval` hasta que un admin las aprueba: el directorio dice quién eres, pero no que debas tener acceso a GitLab.

### 2.2 2FA para administradores

`require_admin_two_factor_authentication` obliga a configurar el 2FA a quien sea admin; `require_two_factor_authentication` lo obliga a todos. **Free.** Con `two_factor_grace_period` (48 h por defecto) GitLab da ese margen antes de bloquear la web a quien no lo haya hecho.

Qué protege: el login web con contraseña. Qué **no** protege:

- Los tokens. Un PAT robado no pide 2FA; por eso caducan y tienen scope.
- El login por SSO: ahí el segundo factor lo pone el proveedor (Keycloak). Si GitLab no debe pedir otro, `omniauth_allow_bypass_two_factor` en `gitlab.rb`.

Para los usuarios normales no lo exiges esta semana: llegan por Keycloak y su política de autenticación vive allí.

### 2.3 Contraseñas y Git por HTTP

`minimum_password_length` admite de 8 a 128. Se aplica al **crear o cambiar** una contraseña; las existentes siguen valiendo. Doce caracteres es la cifra habitual para una contraseña sin requisitos de complejidad.

`password_authentication_enabled_for_git=false` hace que Git por HTTP no acepte la contraseña de la cuenta: hay que usar un token. SSH no cambia, y los runners usan `CI_JOB_TOKEN`. Con OIDC es casi obligatorio: un usuario que entra por Keycloak no tiene contraseña de GitLab que usar.

### 2.4 Cuentas dormidas

`deactivate_dormant_users` desactiva cada día las cuentas sin actividad durante `deactivate_dormant_users_period` días. El mínimo es **90**. Desactivar no borra nada: el usuario no puede entrar ni usar sus tokens hasta que se reactiva, y se reactiva solo al iniciar sesión en la web, o un admin con `POST /users/:id/activate`.

No afecta a los bots de tokens de proyecto y grupo ni a las cuentas internas de GitLab.

### 2.5 Tokens

| Ajuste | Valor en 19.2.4 | Qué hace |
|---|---|---|
| `require_personal_access_token_expiry` | `true` | Todo PAT nuevo lleva fecha de caducidad |
| Caducidad máxima de un PAT | 365 días | Fijo en CE; un máximo menor (`max_personal_access_token_lifetime`) es **Ultimate** |
| `inactive_resource_access_tokens_delete_after_days` | `30` | Los tokens de proyecto o grupo revocados o caducados se borran (con su bot) a los 30 días |

En CE el sustituto del máximo menor es revisar los tokens como admin: `GET /personal_access_tokens?state=active` lista los de toda la instancia con su `expires_at`, y ahí se ve cuál caduca más tarde de lo que permite tu política.

### 2.6 Registro de runners

Desde la 16.0, un runner se crea con la API (`POST /user/runners`) y recibe su propio token de autenticación (`glrt-`). El token de registro de la instancia es el sistema antiguo: un solo secreto que registra todos los runners que quieras y que no dice quién creó cuál. `allow_runner_registration_token=false` lo apaga en la instancia y en todos los grupos y proyectos. Los runners ya registrados siguen funcionando.

---

## 3. Cómo se configura

Todo es `PUT /application/settings`, con las variables de la teoría 01. La política entera en una llamada:

```bash
curl -s --request PUT "$API/application/settings" -H "$H" \
  --data signup_enabled=false \
  --data require_admin_two_factor_authentication=true \
  --data minimum_password_length=12 \
  --data password_authentication_enabled_for_git=false \
  --data deactivate_dormant_users=true \
  --data deactivate_dormant_users_period=90 \
  --data allow_runner_registration_token=false \
  | jq -c '{signup_enabled, minimum_password_length, deactivate_dormant_users_period}'
# {"signup_enabled":false,"minimum_password_length":12,"deactivate_dormant_users_period":90}
```

En la práctica 01 va paso a paso para que veas el efecto de cada uno.

**Con la UI**: `Admin → Settings → General`: *Sign-up restrictions* (registro, longitud), *Sign-in restrictions* (2FA, Git por HTTP, modo admin), *Account and limit* (cuentas dormidas, caducidad de tokens). El registro de runners, en `Admin → Settings → CI/CD → Runners`.

Ver quién incumple la política:

```bash
curl -s -H "$H" "$API/users?admins=true&two_factor=disabled" | jq -r '.[].username'   # admins sin 2FA
curl -s -H "$H" "$API/users?per_page=100" \
  | jq -r '.[] | select(.state == "blocked_pending_approval") | .username'              # altas en espera
```

`GET /users` no tiene filtro por estado, y `blocked=true` no incluye las altas en espera: por eso el `select` de `jq`.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Registro abierto "porque solo conocemos la URL nosotros" | Las URL se filtran; una cuenta nueva ve todo lo `internal` | Registro cerrado y altas por el proveedor de identidad |
| 2FA obligatorio para todos sin SSO | Cada usuario gestiona su 2FA y el soporte de "perdí el móvil" es tuyo | 2FA para admins en GitLab; para el resto, en el proveedor |
| Requisitos de complejidad en lugar de longitud | Producen `Password1!`; doce letras normales son más fuertes | Longitud mínima de 12 |
| Dejar Git por HTTP con contraseña | La contraseña de la cuenta acaba en un `.netrc` o en una URL de un script | Tokens con scope y caducidad |
| Borrar cuentas de quien se va | Se pierde la autoría de issues y MR, y a veces el trabajo | Desactivar o bloquear; las dormidas, solas |
| Apagar el registro de runners heredado sin mirar la flota | Un script de alta de runners antiguo deja de funcionar a mitad de un incidente | Comprobar antes que todos tus runners usan `glrt-` |

---

## 5. Trucos

- `POST /users/:id/approve` aprueba un alta en espera; `POST /users/:id/reject` la rechaza y la borra.
- `GET /users?extern_uid=<sub>&provider=openid_connect` encuentra al usuario de GitLab que corresponde a una identidad de Keycloak.
- `GET /runners/all?per_page=100` con `jq '.[].description'` antes de apagar el registro heredado: si un runner no sabes de dónde salió, averígualo antes.
- `docker compose exec gitlab gitlab-rails runner 'User.find_by_username("root").disable_two_factor!'` quita el 2FA de `root` si pierdes el móvil y los códigos de recuperación. Que exista es la razón de que el acceso al servidor sea parte de la política.

---

## 📚 Recursos Adicionales

- [Sign-up restrictions](https://docs.gitlab.com/administration/settings/sign_up_restrictions/) — registro, aprobación, longitud de contraseña
- [Enforce two-factor authentication](https://docs.gitlab.com/security/two_factor_authentication/) — para admins, para todos y el periodo de gracia
- [Automatically deactivate dormant users](https://docs.gitlab.com/administration/moderate_users/#automatically-deactivate-dormant-users) — el periodo y qué cuentas excluye
- [Migrating to the new runner registration workflow](https://docs.gitlab.com/ci/runners/new_creation_workflow/) — por qué el token de registro está deprecado

---

## ✅ Checklist de Verificación

- [ ] Sabes por qué las cuentas nuevas de Keycloak esperan aprobación aunque Keycloak ya las conozca
- [ ] Puedes decir qué protege el 2FA de administradores y qué no
- [ ] Sabes qué pasa con una contraseña de 8 caracteres que ya existía al subir el mínimo a 12
- [ ] Sabes cómo se reactiva una cuenta dormida y por qué desactivar es mejor que borrar
- [ ] Sabes qué límite de tokens es de CE y cuál es de Ultimate

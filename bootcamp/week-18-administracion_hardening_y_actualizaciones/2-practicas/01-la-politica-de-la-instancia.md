# Práctica 01 — La política de la instancia

> Creas `infra/plataforma`, el proyecto donde se documenta la propia instancia, y aplicas por API la política de cuentas de la teoría 02: registro cerrado, 2FA para administradores, contraseñas largas, Git por HTTP sin contraseña, nada público sin un admin, cuentas dormidas que se desactivan y sin tokens de registro de runners. Antes del primer cambio guardas la foto de todos los ajustes; al final, su diff es la primera mitad de `docs/endurecimiento.md`.

**Duración estimada**: 50 min
**Prerrequisitos**: Semana 17 completada (`~/.bc-gitlab-s17`) · Teoría [01](../1-teoria/01-el-area-de-administracion.md) y [02](../1-teoria/02-la-politica-de-cuentas.md) leídas · Una app TOTP en el móvil

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 0 | Variables de la semana y un token con `admin_mode` | — |
| 1 | `infra/plataforma`, privado y con `main` protegida | `plataforma-protege-main`, `plataforma-privado` |
| 2 | La foto de los ajustes antes de tocar nada | — |
| 3 | Registro cerrado | `registro-cerrado` |
| 4 | 2FA para administradores y `root` con 2FA | `admin-con-2fa` |
| 5 | Contraseñas de 12 y Git por HTTP sin contraseña | `contrasenas` |
| 6 | Nada público sin un admin | `visibilidad-publica-restringida` |
| 7 | Cuentas dormidas a 90 días | `cuentas-dormidas` |
| 8 | Sin tokens de registro de runners | `registro-runner-legado-cerrado` |

---

## Paso 0: Preparar el terreno

**Por qué**: el grupo de siempre, la ruta codificada de `infra/plataforma` (`PP`) y un token que pueda administrar con el modo admin activo (teoría 01). Tu token del laboratorio es de `root`, pero si no tiene el scope `admin_mode`, esta semana entera devuelve `403`.

```bash
source ~/.bc-gitlab
source ~/.bc-gitlab-s17
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export PP=$(printf '%s' "$G/infra/plataforma" | jq -sRr @uri)
{ echo "export G=$G"; echo "export PP=$PP"; } > ~/.bc-gitlab-s18
chmod 600 ~/.bc-gitlab-s18
curl -s -H "$H" "$API/personal_access_tokens/self" | jq -c '{scopes, expires_at}'
```

Si `scopes` no incluye `admin_mode`, crea un token nuevo de `root` en `User settings → Access tokens` con `api` y `admin_mode` y caducidad de una semana, ponlo en `GITLAB_TOKEN` de `~/.bc-gitlab` (que sigue en `chmod 600`) y repite el bloque. Revoca el anterior.

**Verifica**:

```bash
curl -s -o /dev/null -w '%{http_code}\n' -H "$H" "$API/application/settings"
```

`200`. Un `403` es el scope.

---

## Paso 1: `infra/plataforma`

**Por qué**: la política de la instancia es una decisión, y las decisiones se escriben donde se revisan. Privado, porque describe cómo está protegida la instancia. `main` protegida **antes** del primer push y sin force push, como `ci/automatizacion` en la Semana 17.

**Con la UI**: en el subgrupo `infra`, *New project → Create blank project*, privado, **sin** README. Luego `Settings → Repository → Protected branches`: `main`, push y merge Maintainers, force push apagado.

**Con la API**:

```bash
NS=$(curl -s -H "$H" "$API/groups/$G%2Finfra" | jq -r .id)
curl -s --request POST "$API/projects" -H "$H" \
  --data name=plataforma --data "namespace_id=$NS" --data visibility=private \
  --data "description=Política, OIDC y actualizaciones de la instancia" | jq -r .path_with_namespace

curl -s --request POST "$API/projects/$PP/protected_branches" -H "$H" \
  --data name=main --data push_access_level=40 --data merge_access_level=40 \
  --data allow_force_push=false | jq -c '{name, allow_force_push}'
```

Clona el proyecto vacío junto a tus otros clones:

```bash
cd /ruta/a/tus/clones
git clone "$(curl -s -H "$H" "$API/projects/$PP" | jq -r .ssh_url_to_repo)" plataforma && cd plataforma
mkdir -p docs/actualizaciones
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$PP" | jq -c '{visibility, empty_repo}'
```

`{"visibility":"private","empty_repo":true}`. El repositorio se llena en las prácticas 03 y 04.

---

## Paso 2: La foto de antes

**Por qué**: es tu vuelta atrás y la evidencia de qué cambió (teoría 01). Se hace **antes** del primer `PUT`; después ya no hay forma de saber qué valía.

```bash
curl -s -H "$H" "$API/application/settings" | jq -S . > ~/ajustes-antes-s18.json
chmod 600 ~/ajustes-antes-s18.json
jq -c '{signup_enabled, require_admin_two_factor_authentication, minimum_password_length,
        password_authentication_enabled_for_git, restricted_visibility_levels,
        deactivate_dormant_users, allow_runner_registration_token}' ~/ajustes-antes-s18.json
```

**Verifica**: anota los valores de esa línea; son la columna *antes* de la tabla de `docs/endurecimiento.md`. En una instancia recién instalada, `signup_enabled` es `true` y `minimum_password_length`, `8`.

El archivo lleva `chmod 600` porque trae, por ejemplo, la lista de IP de monitoreo y las direcciones internas permitidas.

---

## Paso 3: Registro cerrado

**Por qué**: con el registro abierto, cualquiera que llegue a `/users/sign_up` tiene cuenta. Las altas, desde esta semana, son de dos tipos: las crea un admin, o llegan por Keycloak y esperan aprobación (práctica 02).

```bash
curl -s --request PUT "$API/application/settings" -H "$H" \
  --data signup_enabled=false | jq .signup_enabled
# false
```

**Con la UI**: `Admin → Settings → General → Sign-up restrictions`, desmarca *Sign-up enabled*.

**Verifica**, pasado un minuto (la caché de la teoría 01), en una ventana privada: `http://localhost:8888/users/sign_in` ya no tiene el enlace *Register now*.

---

## Paso 4: 2FA para administradores

**Por qué**: la contraseña de `root` es la llave de todo. Con `require_admin_two_factor_authentication`, cualquier administrador sin 2FA es obligado a configurarlo al entrar en la web. Y el modo admin, que la teoría 01 explica, se asegura aquí porque una instancia recién instalada lo trae apagado.

> [!WARNING]
> Antes del `PUT`, ten la app TOTP a mano. En tu próximo login web como `root`, GitLab no te deja hacer nada hasta configurar el 2FA. Guarda los códigos de recuperación que te da al final **fuera** del repositorio: son lo único que te devuelve la cuenta si pierdes el móvil.

```bash
curl -s --request PUT "$API/application/settings" -H "$H" \
  --data require_admin_two_factor_authentication=true \
  --data admin_mode=true \
  | jq -c '{require_admin_two_factor_authentication, admin_mode, two_factor_grace_period}'
# {"require_admin_two_factor_authentication":true,"admin_mode":true,"two_factor_grace_period":48}
```

`two_factor_grace_period` son las horas que GitLab da antes de bloquear del todo a un administrador sin 2FA. No esperes a que pasen: cierra sesión, entra como `root`, escanea el QR y guarda los códigos.

**Con la UI**: `Admin → Settings → General → Sign-in restrictions`, *Two-factor authentication* para administradores y *Admin Mode*.

**Verifica**:

```bash
curl -s -H "$H" "$API/users?admins=true&two_factor=disabled" | jq -r '.[].username'
```

Vacío. Si sale `root`, aún no has configurado el 2FA. Tu token sigue funcionando: el 2FA protege la web, y los tokens ya son un segundo factor por sí mismos.

---

## Paso 5: Contraseñas y Git por HTTP

**Por qué**: 12 caracteres como mínimo, porque 8 se rompen por fuerza bruta sin conexión en horas. Y Git por HTTP sin contraseña: quien clona por HTTP usa un token, que caduca y tiene scope; la contraseña de la cuenta no debería servir para todo. Tú empujas por SSH desde la Semana 02, y los runners usan `CI_JOB_TOKEN`, así que no se rompe nada.

```bash
curl -s --request PUT "$API/application/settings" -H "$H" \
  --data minimum_password_length=12 \
  --data password_authentication_enabled_for_git=false \
  | jq -c '{minimum_password_length, password_authentication_enabled_for_git}'
# {"minimum_password_length":12,"password_authentication_enabled_for_git":false}
```

**Con la UI**: *Minimum password length* está en `Sign-up restrictions`; *Allow password authentication for Git over HTTP(S)*, en `Sign-in restrictions`.

**Verifica**, pasado un minuto:

```bash
git ls-remote "http://root:una-contrasena-cualquiera@localhost:8888/$G/infra/plataforma.git" 2>&1 | tail -n 1
```

`fatal: Authentication failed`; la línea anterior, `remote: HTTP Basic: Access denied`, dice que hace falta un token en lugar de contraseña. La longitud mínima solo se exige al cambiar una contraseña; las cortas que ya existen siguen valiendo hasta entonces.

---

## Paso 6: Nada público sin un admin

**Por qué**: un proyecto público en una instancia de empresa es una fuga esperando a ocurrir. Restringir `public` significa que solo un administrador puede poner algo público; los proyectos y grupos nuevos nacen privados.

```bash
curl -s --request PUT "$API/application/settings" -H "$H" \
  --data 'restricted_visibility_levels[]=public' \
  --data default_project_visibility=private \
  --data default_group_visibility=private \
  | jq -c '{restricted_visibility_levels, default_project_visibility}'
# {"restricted_visibility_levels":["public"],"default_project_visibility":"private"}
```

**Con la UI**: `Admin → Settings → General → Visibility and access controls`.

**Verifica** qué hay ya público, porque la restricción no cambia lo que existe:

```bash
curl -s -H "$H" "$API/projects?visibility=public&per_page=100" | jq -r '.[].path_with_namespace'
```

Lo que salga, decide si debe seguir público y apúntalo en la tabla de excepciones de `docs/endurecimiento.md` (práctica 03).

---

## Paso 7: Cuentas dormidas

**Por qué**: la cuenta de alguien que se fue hace un año es la que nadie vigila. GitLab desactiva sola la que lleva el periodo sin actividad; desactivar no borra nada, y el usuario se reactiva entrando o un admin lo reactiva.

```bash
curl -s --request PUT "$API/application/settings" -H "$H" \
  --data deactivate_dormant_users=true \
  --data deactivate_dormant_users_period=90 \
  | jq -c '{deactivate_dormant_users, deactivate_dormant_users_period}'
# {"deactivate_dormant_users":true,"deactivate_dormant_users_period":90}
```

Prueba a poner `30`: la respuesta es `400` con `must be greater than or equal to 90`. Noventa es el mínimo que admite GitLab.

**Con la UI**: `Admin → Settings → General → Account and limit`, *Dormant users*.

**Verifica**:

```bash
curl -s -H "$H" "$API/application/settings" | jq -c '{require_personal_access_token_expiry, inactive_resource_access_tokens_delete_after_days}'
```

`true` y `30`: los tokens personales caducan siempre, y los tokens de proyecto o grupo revocados se borran a los 30 días. Los dos vienen bien de fábrica; apúntalos igualmente en la política, porque que vengan bien no significa que nadie los cambie.

---

## Paso 8: Sin tokens de registro de runners

**Por qué**: desde la Semana 05 creas runners con un token de autenticación, que nace de un runner concreto creado por API (`glrt-`). El token de registro antiguo de la instancia, en cambio, sirve para registrar cualquier número de runners con un solo secreto compartido. Nadie lo usa ya, así que se cierra.

```bash
curl -s --request PUT "$API/application/settings" -H "$H" \
  --data allow_runner_registration_token=false | jq .allow_runner_registration_token
# false
```

**Con la UI**: `Admin → Settings → CI/CD → Runners`, desmarca *Allow runner registration token*.

**Verifica** que tu flota sigue viva:

```bash
curl -s -H "$H" "$API/runners/all?per_page=100" | jq -r '.[] | "\(.description) \(.status)"'
```

Los runners que ya tenías siguen `online`: el ajuste solo afecta a registros nuevos con el token heredado.

---

## ✅ Resultado

- [ ] `~/.bc-gitlab-s18` con `G` y `PP`, en `chmod 600`, y un token con `admin_mode`
- [ ] `infra/plataforma` privado, vacío y con `main` protegida sin force push
- [ ] `~/ajustes-antes-s18.json` guardado antes del primer cambio
- [ ] Registro cerrado, 2FA de administradores, modo admin y `root` con 2FA configurado
- [ ] Contraseñas de 12 y Git por HTTP sin contraseña
- [ ] `public` restringido y proyectos que nacen privados
- [ ] Cuentas dormidas a 90 días y sin token de registro de runners

```bash
./scripts/verificar-semana.sh 18
```

En esta práctica pasan las ocho primeras comprobaciones, de `plataforma-protege-main` a `registro-runner-legado-cerrado`.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `403 Forbidden` en `application/settings` | El token no tiene `admin_mode` | Paso 0: token nuevo con `api` y `admin_mode` |
| `{"importers":["must be a valid json schema"]}` en cualquier `PUT` | Tu instancia viene de una actualización desde 19.1 con una clave que 19.2 ya no admite | La práctica 04 lo explica y lo arregla; es lo que encuentra el ensayo |
| El ajuste cambia en la API pero no en la web | La caché de un minuto | Espera y repite |
| `root` bloqueado sin 2FA y sin códigos de recuperación | Pasó el periodo de gracia | `docker compose exec gitlab gitlab-rails runner 'User.find_by_username("root").disable_two_factor!'` y configúralo de nuevo |
| `push_access_level` rechazado al proteger `main` | Ya existe la regla | `GET protected_branches/main` y comprueba `allow_force_push` |
| `git clone` por SSH pide contraseña | La clave SSH no está en tu usuario | Semana 02 |

---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| [README de la semana](../README.md) | [Práctica 02 — Login con Keycloak](02-login-con-keycloak.md) |

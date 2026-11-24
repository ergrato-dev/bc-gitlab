# Práctica 02 — Login con Keycloak

> Levantas Keycloak en el perfil `sso`, le creas el realm `bootcamp`, el cliente `gitlab` y las identidades de tus usuarios de laboratorio, y enciendes el OIDC en GitLab. `dev-<dominio>` y `revisor-<dominio>` se vinculan solos por email, alguien sin cuenta se queda esperando aprobación, y quien ya entra por SSO deja de poder entrar con contraseña. `root` no se toca: es tu acceso de emergencia.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 01 completada (`~/.bc-gitlab-s18`) · Teoría [03](../1-teoria/03-oidc-en-gitlab.md) y [04](../1-teoria/04-keycloak-como-proveedor.md) leídas · Una ventana privada del navegador

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | Keycloak en marcha, perfil `sso` | — |
| 2 | El realm `bootcamp` | — |
| 3 | El cliente `gitlab` y su secreto en `.env` | — |
| 4 | Las identidades en Keycloak | — |
| 5 | El OIDC encendido en GitLab | — |
| 6 | El primer login por Keycloak | — |
| 7 | Dos cuentas vinculadas | `oidc-cuentas-vinculadas` |
| 8 | Un alta en espera | `oidc-alta-en-espera` |
| 9 | El SSO sin contraseña | `sso-sin-contrasena` |

```bash
source ~/.bc-gitlab
source ~/.bc-gitlab-s18
# docker compose y .env: desde la carpeta de este repositorio, donde está docker-compose.yml
```

---

## Paso 1: El perfil `sso`

**Por qué**: Keycloak no está en `base` porque solo lo usan esta semana y la 26, y ocupa medio giga (teoría 04). Su contraseña de administrador va en `.env`, que no se versiona; la de `.env.example` es pública.

```bash
grep -q '^KEYCLOAK_ADMIN' .env || grep -E '^(KEYCLOAK|OIDC)_' .env.example >> .env
sed -i "s/^KEYCLOAK_ADMIN_PASSWORD=.*/KEYCLOAK_ADMIN_PASSWORD=$(openssl rand -hex 24)/" .env
grep -cE '^KEYCLOAK_ADMIN_PASSWORD=[0-9a-f]{48}$' .env
# 1
docker compose --profile base --profile sso up -d keycloak
until curl -sf -o /dev/null http://localhost:8180/realms/master; do sleep 3; done
docker stats --no-stream --format '{{.Name}} {{.MemUsage}}' keycloak
# keycloak 529.5MiB / 768MiB
```

La primera línea copia de `.env.example` las variables de Keycloak y OIDC si tu `.env` aún no las tiene. El `1` del `grep` es la comprobación de que la contraseña es la generada y no la pública de `.env.example`.

**Verifica**:

```bash
curl -s http://localhost:8180/realms/master/.well-known/openid-configuration | jq -r .issuer
# http://localhost:8180/realms/master
```

El emisor ya dice `localhost:8180`: es `KC_HOSTNAME`, del compose.

---

## Paso 2: El realm `bootcamp`

**Por qué**: `master` administra Keycloak; las aplicaciones van en un realm propio. Con protección contra fuerza bruta, que es la política de intentos que GitLab ya no aplica a estos usuarios, porque su contraseña no la ve.

```bash
kc() { docker exec keycloak /opt/keycloak/bin/kcadm.sh "$@"; }
grep ^KEYCLOAK_ADMIN_PASSWORD= .env | cut -d= -f2   # cópiala para el siguiente comando
docker exec -it keycloak /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 --realm master --user admin
# Enter password: (pégala; no se ve)
clear   # que la contraseña no se quede en pantalla
kc create realms -s realm=bootcamp -s enabled=true -s bruteForceProtected=true
# Created new realm with id 'bootcamp'
```

**Con la UI**: `http://localhost:8180/admin`, usuario `admin` y la contraseña de `.env`; desplegable de realms → *Create realm*. Después, *Realm settings → Security defenses → Brute force detection*.

**Verifica**:

```bash
kc get realms/bootcamp | jq -c '{realm, bruteForceProtected, registrationAllowed}'
# {"realm":"bootcamp","bruteForceProtected":true,"registrationAllowed":false}
```

`registrationAllowed: false` importa: si cualquiera pudiera crearse una cuenta en el realm con el email que quisiera, la vinculación por email del paso 7 le entregaría la cuenta de otro.

---

## Paso 3: El cliente `gitlab`

**Por qué**: confidencial (con secreto), solo con el flujo de código, PKCE obligatorio y la URI de redirección exacta. Teoría 04, sección 2.1.

```bash
CID=$(kc create clients -r bootcamp -s clientId=gitlab -s enabled=true -s publicClient=false \
  -s standardFlowEnabled=true -s directAccessGrantsEnabled=false \
  -s 'redirectUris=["http://localhost:8888/users/auth/openid_connect/callback"]' \
  -s 'webOrigins=["http://localhost:8888"]' \
  -s 'attributes={"pkce.code.challenge.method":"S256"}' -i)
echo "export CID=$CID" >> ~/.bc-gitlab-s18
```

El secreto va directo a `.env`, sin pasar por la pantalla:

```bash
SEC=$(kc get "clients/$CID/client-secret" -r bootcamp | jq -r .value)
sed -i "s/^OIDC_CLIENT_SECRET=.*/OIDC_CLIENT_SECRET=$SEC/" .env
unset SEC
```

**Verifica**:

```bash
kc get "clients/$CID" -r bootcamp \
  | jq -c '{publicClient, directAccessGrantsEnabled, redirectUris, pkce: .attributes["pkce.code.challenge.method"]}'
# {"publicClient":false,"directAccessGrantsEnabled":false,"redirectUris":["http://localhost:8888/users/auth/openid_connect/callback"],"pkce":"S256"}
grep -c '^OIDC_CLIENT_SECRET=.\+' .env
# 1
```

---

## Paso 4: Las identidades en Keycloak

**Por qué**: Keycloak tiene que conocer a `dev-<dominio>` y `revisor-<dominio>` con **el mismo email** que en GitLab, verificado, para que la vinculación del paso 7 funcione. Y a alguien que en GitLab no existe, `nuevo-<dominio>`, para ver qué hace GitLab con un desconocido.

```bash
DOM=${G#plataforma-}
for u in dev-$DOM revisor-$DOM; do
  email=$(curl -s -H "$H" "$API/users?username=$u" | jq -r '.[0].email')
  kc create users -r bootcamp -s username=$u -s "email=$email" -s emailVerified=true \
    -s enabled=true -s firstName=$u -s lastName=lab
done
kc create users -r bootcamp -s username=nuevo-$DOM -s "email=nuevo-$DOM@example.test" \
  -s emailVerified=true -s enabled=true -s firstName=nuevo -s lastName=lab
```

Las contraseñas, sin que queden en el historial ni en la lista de procesos:

```bash
for u in dev-$DOM revisor-$DOM nuevo-$DOM; do
  read -rs "pw?Contraseña para $u: "; echo
  kc set-password -r bootcamp --username "$u" --new-password "$pw"
done; unset pw
```

(En bash, `read -rsp "Contraseña para $u: " pw`.) Apúntalas en tu gestor de contraseñas: las usarás en el navegador.

**Verifica**:

```bash
kc get users -r bootcamp | jq -r '.[] | "\(.username) \(.email) \(.emailVerified)"'
# dev-biblioteca dev-biblioteca@example.test true
# nuevo-biblioteca nuevo-biblioteca@example.test true
# revisor-biblioteca revisor-biblioteca@example.test true
```

---

## Paso 5: El OIDC encendido en GitLab

**Por qué**: el proveedor ya está declarado en el `GITLAB_OMNIBUS_CONFIG` del compose (léelo: sección *Login con Keycloak por OIDC*), pero apagado. Es configuración de `gitlab.rb`, no de base de datos (teoría 01): encenderlo es recrear el contenedor.

> [!WARNING]
> Recrear el contenedor no borra datos (están en volúmenes), pero GitLab no responde durante unos minutos. No lo hagas con un pipeline a medias.

```bash
sed -i 's/^OIDC_ENABLED=.*/OIDC_ENABLED=true/' .env
docker compose --profile base --profile sso up -d gitlab
until [ "$(docker inspect -f '{{.State.Health.Status}}' gitlab)" = healthy ]; do sleep 10; done
```

**Verifica**:

```bash
curl -s "$GITLAB_URL/users/sign_in" | grep -o 'openid_connect\|Keycloak' | sort -u
# Keycloak
# openid_connect
```

---

## Paso 6: El primer login por Keycloak

**Por qué**: el flujo de la teoría 03, con tus ojos. Se hace en una ventana privada para que tu sesión de `root` no se mezcle.

**Con la UI**: ventana privada, `http://localhost:8888`, botón **Keycloak**. La barra de direcciones pasa a `localhost:8180/realms/bootcamp/...`: ahí, `revisor-<dominio>` y su contraseña de Keycloak. Vuelves a GitLab con la sesión de `revisor-<dominio>` abierta, sin haber escrito su contraseña de GitLab.

**Verifica**:

```bash
curl -s -H "$H" "$API/users?username=revisor-$DOM" | jq -c '.[0] | {state, identities}'
# {"state":"active","identities":[{"provider":"openid_connect","extern_uid":"411aee0e-..."}]}
kc get users -r bootcamp -q username=revisor-$DOM | jq -r '.[0].id'
# 411aee0e-...
```

El `extern_uid` es el `sub` de Keycloak, el `id` del usuario: `uid_field: 'sub'` del compose.

---

## Paso 7: Dos cuentas vinculadas

**Por qué**: una cuenta vinculada podría ser casualidad. Dos, con la misma regla, es la política funcionando.

**Con la UI**: cierra la ventana privada, abre otra, y entra igual como `dev-<dominio>`.

**Verifica**:

```bash
curl -s -H "$H" "$API/users?per_page=100" \
  | jq '[.[] | select(.state == "active" and any(.identities[]?; .provider == "openid_connect"))] | length'
# 2
```

---

## Paso 8: Un alta en espera

**Por qué**: `nuevo-<dominio>` existe en Keycloak pero no en GitLab. `omniauth_allow_single_sign_on` deja que GitLab le cree la cuenta; `omniauth_block_auto_created_users` la deja bloqueada hasta que un admin decida. Tener cuenta en el proveedor no es lo mismo que tener permiso para entrar en GitLab.

**Con la UI**: ventana privada, **Keycloak**, `nuevo-<dominio>`. Vuelves a la página de login de GitLab con el aviso *Your account is pending approval from your GitLab administrator and hence blocked.* En tu sesión de `root`, `Admin → Users → Pending approval` la muestra.

**Verifica**:

```bash
curl -s -H "$H" "$API/users?per_page=100" \
  | jq -c '.[] | select(.state == "blocked_pending_approval") | {username, p: [.identities[].provider]}'
# {"username":"nuevo-biblioteca","p":["openid_connect"]}
```

**No la apruebes.** Es la evidencia de que la puerta funciona, y una comprobación de la semana la busca.

---

## Paso 9: El SSO sin contraseña

**Por qué**: `revisor-<dominio>` sigue teniendo su contraseña de GitLab de la Semana 03, y con ella entra sin pasar por Keycloak, su bloqueo por fuerza bruta ni su política. Este ajuste se la quita a todo el que tenga identidad SSO. `root` no tiene: sigue entrando con contraseña y 2FA.

```bash
curl -s --request PUT "$API/application/settings" -H "$H" \
  --data disable_password_authentication_for_users_with_sso_identities=true \
  | jq .disable_password_authentication_for_users_with_sso_identities
# true
```

**Con la UI**: `Admin → Settings → General → Sign-in restrictions`, *Disable password authentication for users with an SSO identity*.

**Verifica**: espera un minuto (teoría 01, la caché de ajustes). En una ventana privada, intenta entrar como `revisor-<dominio>` **con usuario y contraseña de GitLab**, sin el botón: *Invalid login or password.* Con **Keycloak**, entra. Y `root`, con su contraseña y su código 2FA, también.

---

## ✅ Resultado

- [ ] Keycloak en marcha con el perfil `sso`, contraseña de admin y secreto del cliente solo en `.env`
- [ ] El realm `bootcamp` sin registro propio y con protección contra fuerza bruta
- [ ] El cliente `gitlab` confidencial, con PKCE y la redirección exacta
- [ ] `dev-<dominio>` y `revisor-<dominio>` entran por Keycloak y están activos
- [ ] `nuevo-<dominio>` espera aprobación
- [ ] Un usuario vinculado no entra con contraseña; `root` sí

```bash
./scripts/verificar-semana.sh 18
```

En esta práctica pasan `oidc-cuentas-vinculadas`, `oidc-alta-en-espera` y `sso-sin-contrasena`.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `(eval):1: no such file or directory: docker exec keycloak ...` | Guardaste el comando en una variable; zsh no la parte en palabras | La función `kc` del paso 2 |
| `HTTP 401 Unauthorized` en `kcadm.sh` | La sesión de `config credentials` caducó | Repite `kc config credentials` |
| El botón Keycloak no aparece | `OIDC_ENABLED` no es `true` en `.env`, o no recreaste `gitlab` | Paso 5 |
| Keycloak dice *Invalid parameter: redirect_uri* | La URI del cliente no coincide letra a letra con la de GitLab | Paso 3: `redirectUris` exacta |
| Vuelves al login de GitLab sin sesión y sin aviso | El emisor del token no coincide con `issuer`, o el secreto está mal | `docker compose exec gitlab tail -n 20 /var/log/gitlab/gitlab-rails/application_json.log`; teoría 04 |
| `Connection refused - connect(2) for "localhost" port 8180` en el log | Algún endpoint de servidor apunta a `localhost` | `token_endpoint`, `userinfo_endpoint` y `jwks_uri` van con `keycloak:8080` |
| Se crea un usuario nuevo en vez de vincular | El email de Keycloak no es el de GitLab | Paso 4: el email lo lee de la API |
| El usuario vinculado aún entra con contraseña | No ha pasado el minuto de la caché | Espera y repite |

---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| [Práctica 01 — La política de la instancia](01-la-politica-de-la-instancia.md) | [Práctica 03 — Límites y superficie](03-limites-y-superficie.md) |

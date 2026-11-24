# Práctica 03 — Límites y superficie

> Mides cuánto pide hoy tu automatización, enciendes los límites de la API, de la web y de las rutas protegidas, y provocas un `429` para leerlo. Cierras los hooks de sistema a la red local y conectas uno, firmado, al receptor de la Semana 17: desde hoy, cada cuenta nueva de la instancia aparece en el canal. Enciendes la autodesactivación de webhooks y escribes `docs/endurecimiento.md`, la política entera con su valor de antes.

**Duración estimada**: 50 min
**Prerrequisitos**: Prácticas 01 y 02 completadas · Teoría [05](../1-teoria/05-limites-de-peticiones.md) y [06](../1-teoria/06-superficie-y-auditoria.md) leídas · El receptor de la Semana 17 desplegado en `destino`

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 0 | Variables y funciones | — |
| 1 | Cuánto pide hoy cada usuario | — |
| 2 | Límites de la API y de la web | `limites-de-peticiones` |
| 3 | Rutas protegidas y un `429` provocado | `rutas-protegidas` |
| 4 | El `429` en el log | — |
| 5 | Hooks de sistema sin red local, y uno firmado al receptor | `hooks-sin-red-local` |
| 6 | El receptor entiende los hooks de sistema | — |
| 7 | Webhooks que fallan, desactivados solos | — |
| 8 | `docs/endurecimiento.md` | `endurecimiento-documentado` |

---

## Paso 0: Preparar el terreno

**Por qué**: las variables de la semana, la URL del receptor y las dos funciones de la Semana 17: `canal`, para ver lo que anota el receptor, y `esperar`, para los pipelines.

```bash
source ~/.bc-gitlab; source ~/.bc-gitlab-s17; source ~/.bc-gitlab-s18
export H="PRIVATE-TOKEN: $GITLAB_TOKEN" API="$GITLAB_URL/api/v4"
export R="http://localhost:${DESTINO_PORT:-8095}/receptor"
canal() { curl -s "$R/" | jq -r 'length as $n | "\($n) líneas", (.[-3:][] | "  \(.resumen)")'; }
k3d cluster start bootcamp   # los pipelines de ci/automatizacion corren en k8s-app
```

Copia `esperar` del [paso 0 de la práctica 01 de la Semana 13](../../week-13-registry_de_contenedores_y_paquetes/2-practicas/01-el-registry-y-el-dockerfile.md#paso-0-preparar-el-terreno).

**Verifica**:

```bash
curl -s "$R/salud" | jq -r .sha
canal
```

Un SHA y las últimas líneas del canal. Si `salud` da `404`, el receptor no está desplegado: [práctica 02 de la Semana 17](../../week-17-api_webhooks_y_chatops/2-practicas/02-el-receptor.md).

---

## Paso 1: Cuánto pide cada usuario

**Por qué**: antes de poner un límite, mira cuánto se usa (teoría 05, antipatrones). `api_json.log` tiene una línea por petición a la API; contarlas por usuario dice quién está más cerca de las 7200 por hora.

```bash
docker compose exec gitlab grep -o '"username":"[^"]*"' /var/log/gitlab/gitlab-rails/api_json.log \
  | sort | uniq -c | sort -rn | head -n 5
docker compose exec gitlab head -c 40 /var/log/gitlab/gitlab-rails/api_json.log; echo
```

**Verifica**: la primera lista son las peticiones de cada usuario desde que empieza el log; la segunda línea dice cuándo empieza. `root` irá primero, por la práctica 01; los bots de los tokens de grupo (`group_<id>_bot_…`) de la Semana 17, detrás. En el laboratorio nadie se acerca a 7200 en una hora: los valores por defecto valen.

---

## Paso 2: Límites de la API y de la web

**Por qué**: los valores por defecto (teoría 05) son generosos para una persona y suficientes para frenar un bucle roto. La web autenticada se queda sin límite: quien tiene sesión ya está identificado, y la API autenticada cubre los scripts.

```bash
curl -s --request PUT "$API/application/settings" -H "$H" \
  --data throttle_authenticated_api_enabled=true \
  --data throttle_unauthenticated_api_enabled=true \
  --data throttle_unauthenticated_web_enabled=true \
  | jq -c '{throttle_authenticated_api_requests_per_period, throttle_unauthenticated_api_requests_per_period,
            throttle_unauthenticated_web_requests_per_period}'
```

**Con la UI**: `Admin → Settings → Network → User and IP rate limits`.

**Verifica**: `7200`, `3600` y `3600`: por usuario y hora en la API con token, por IP y hora en la API y la web anónimas. Pasado un minuto, el auditor de la Semana 17 sigue funcionando (su `rules` admite pipelines lanzados por `api`):

```bash
curl -s --request POST "$API/projects/$PA/pipeline" -H "$H" --data ref=main | jq -r .id
```

Espera ese pipeline con `esperar "$PA" <id>`: `success`.

---

## Paso 3: Rutas protegidas y un `429`

**Por qué**: el login es lo que ataca un diccionario de contraseñas, y cada intento cuesta poco. Diez POST por minuto y por IP es mucho para una persona y nada para un ataque.

```bash
curl -s --request PUT "$API/application/settings" -H "$H" \
  --data throttle_protected_paths_enabled=true \
  | jq -c '{throttle_protected_paths_requests_per_period, throttle_protected_paths_period_in_seconds}'
# {"throttle_protected_paths_requests_per_period":10,"throttle_protected_paths_period_in_seconds":60}
```

**Con la UI**: `Admin → Settings → Network → Protected paths`.

Espera un minuto (la caché) y provoca el `429`, con un usuario que no existe:

```bash
for i in $(seq 1 12); do
  curl -s -o /dev/null -w '%{http_code} ' --request POST "$GITLAB_URL/users/sign_in" \
    --data 'user[login]=nadie' --data 'user[password]=nada'
done; echo
# 422 422 422 422 422 422 422 422 422 422 429 429
```

**Verifica** las cabeceras del siguiente:

```bash
curl -si --request POST "$GITLAB_URL/users/sign_in" --data 'user[login]=nadie' \
  | grep -i '^ratelimit-name\|^ratelimit-limit\|^retry-after'
```

`Ratelimit-Name: throttle_unauthenticated_protected_paths`, `Ratelimit-Limit: 10` y los segundos que faltan en `Retry-After`. Durante ese tiempo, tu IP no puede entrar en la web con contraseña: tampoco tú. Espera a que pase antes de seguir.

---

## Paso 4: El `429` en el log

**Por qué**: un `429` que nadie ve es un ataque que nadie sabe que hubo. Cada uno queda en `auth.log`, con la IP y el límite.

```bash
docker compose exec gitlab grep Rack_Attack /var/log/gitlab/gitlab-rails/auth.log | tail -n 1 \
  | jq -c '{time, matched, remote_ip, path}'
```

**Verifica**: `matched` es `throttle_unauthenticated_protected_paths` y `path`, `/users/sign_in`. La IP es la del gateway de Docker, no la de tu máquina: detrás de un balanceador, sin configurar `trusted_proxies`, todo el mundo tendría la misma IP y compartiría el límite. Apúntalo para `docs/endurecimiento.md`.

---

## Paso 5: Hooks de sistema sin red local

**Por qué**: los hooks de sistema vienen con la red local abierta (teoría 06). Se cierran, y la excepción `destino` de la Semana 17 sigue valiendo para los dos tipos de hook.

```bash
curl -s -H "$H" "$API/application/settings" | jq -c .outbound_local_requests_whitelist
curl -s --request PUT "$API/application/settings" -H "$H" \
  --data allow_local_requests_from_system_hooks=false \
  | jq -c '{allow_local_requests_from_web_hooks_and_services, allow_local_requests_from_system_hooks}'
# {"allow_local_requests_from_web_hooks_and_services":false,"allow_local_requests_from_system_hooks":false}
```

La primera línea tiene que incluir `"destino"`. Si no, vuelve al paso 3 de la práctica 03 de la Semana 17.

Ahora el hook de sistema, firmado con la misma clave que los webhooks y **sin ningún flag**: así manda solo los eventos que llegan siempre (altas de usuarios, proyectos, miembros), y no cada push de la instancia.

```bash
cd /ruta/al/repositorio/bc-gitlab
source <(grep '^RECEPTOR_SIGNING_KEY=' .env)
curl -s --request POST "$API/hooks" -H "$H" -H 'Content-Type: application/json' \
  -d "$(jq -nc --arg k "$RECEPTOR_SIGNING_KEY" '{name: "receptor-sistema",
        url: "http://destino:8080/receptor/webhook", signing_token: $k,
        push_events: false, tag_push_events: false, merge_requests_events: false}')" \
  | jq -c '{id, url, signing_token_present, push_events}'
unset RECEPTOR_SIGNING_KEY
```

**Con la UI**: `Admin → System hooks → Add new webhook`, con el *Signing token* y todos los *Triggers* desmarcados.

**Verifica** que la red local está cerrada de verdad: un hook a otro servicio del compose no se puede ni crear.

```bash
curl -s --request POST "$API/hooks" -H "$H" --data url=http://keycloak:8080/ | jq -c .
# {"error":"Invalid url given"}
```

---

## Paso 6: El receptor entiende los hooks de sistema

**Por qué**: el receptor ya verifica la firma de los hooks de sistema, que es la misma que la de los webhooks. Pero no sabe resumirlos: llegan con `X-Gitlab-Event: System Hook` y sin `project`, y caen en el `default` como `?: System Hook`. Un `case` más en `resumir`.

```bash
# El hook de prueba: un project_create de ejemplo (el proyecto "Ruby" no existe)
HID=$(curl -s -H "$H" "$API/hooks" | jq -r '.[] | select(.name == "receptor-sistema") | .id')
curl -s -o /dev/null -w '%{http_code}\n' --request POST "$API/hooks/$HID" -H "$H"
sleep 3; canal
```

La última línea dice `?: System Hook`. En `ci/automatizacion`, en `src/http.ts`, añade este `case` antes del `default:` de `resumir`:

```ts
    case 'System Hook':
      return `instancia: ${e.event_name} ${e.username ?? e.user_username ?? e.path_with_namespace ?? ''}`.trim();
```

```bash
cd /ruta/a/tus/clones/automatizacion
git add src/http.ts && git commit -S -m "feat: resumir los hooks de sistema en el canal"
git push
sleep 5
PIPE=$(curl -s -H "$H" "$API/projects/$PA/pipelines?per_page=1" | jq -r '.[0].id')
esperar "$PA" "$PIPE"
```

**Verifica** con un alta de verdad: una cuenta de sonda que borras después.

```bash
DOM=${G#plataforma-}
U=$(curl -s --request POST "$API/users" -H "$H" --data "username=sonda-$DOM" --data name=Sonda \
  --data "email=sonda-$DOM@example.test" --data reset_password=true | jq -r .id)
sleep 3; canal
curl -s -o /dev/null -w '%{http_code}\n' --request DELETE "$API/users/$U" -H "$H"
```

`instancia: user_create sonda-<dominio>` en el canal, y `204` al borrarla. El borrado también llega (`user_destroy`): compruébalo con otro `canal`.

---

## Paso 7: Webhooks que fallan

**Por qué**: un receptor caído hace que cada webhook reintente y llene Sidekiq. La autodesactivación los apaga solos tras varios fallos. Es una marca de tipo `ops` apagada por defecto (teoría 06): una decisión del admin, y la tomas.

```bash
curl -s --request POST "$API/features/auto_disabling_web_hooks" -H "$H" --data value=true \
  | jq -c '{name, state}'
# {"name":"auto_disabling_web_hooks","state":"on"}
```

**Verifica**:

```bash
curl -s -H "$H" "$API/features" | jq -c '.[] | select(.name == "auto_disabling_web_hooks") | {state}'
```

`{"state":"on"}`. Un webhook desactivado aparece en `Settings → Webhooks` del proyecto con un aviso y un botón para volver a activarlo. Si un receptor tuyo va a estar parado más de unos minutos, ahora ya sabes qué pasará.

---

## Paso 8: `docs/endurecimiento.md`

**Por qué**: todo lo que has cambiado esta semana, escrito donde se revisa, con su valor de antes y por qué. Es lo que lee quien herede la instancia, y lo que la Semana 24 convertirá en Terraform.

La foto de después y las filas de la tabla, generadas:

```bash
curl -s -H "$H" "$API/application/settings" | jq -S . > ~/ajustes-despues-s18.json
chmod 600 ~/ajustes-despues-s18.json
jq -rn --slurpfile a ~/ajustes-antes-s18.json --slurpfile d ~/ajustes-despues-s18.json \
  '$a[0] as $x | $d[0] as $y | $y | keys[] | select($x[.] != $y[.])
   | "| `\(.)` | `\($x[.] | tojson)` | `\($y[.] | tojson)` | |"'
```

Esas filas van a la primera tabla; la última columna, el porqué, es tuya. En el clon de `infra/plataforma`, `docs/endurecimiento.md`:

```markdown
# Endurecimiento de la instancia

Política de la instancia `http://localhost:8888`, GitLab CE 19.2.4. Aplicada el <fecha>.
Cualquier cambio de estos valores pasa por un merge request a este archivo.

## Ajustes de la instancia (`application/settings`)

| Ajuste | Antes | Después | Por qué |
|---|---|---|---|
<las filas generadas, con su porqué>

`admin_mode` está activo: los tokens que administran necesitan el scope `admin_mode`.

## Acceso: OIDC con Keycloak

- Proveedor: Keycloak 26.8.2, realm `bootcamp`, cliente confidencial `gitlab` con PKCE.
- Las cuentas existentes se vinculan por email; el realm no admite registro propio.
- Las cuentas nuevas quedan en espera de aprobación (`omniauth_block_auto_created_users`).
- Quien tiene identidad SSO no entra con contraseña.
- `root` entra con contraseña y 2FA: es el acceso de emergencia si Keycloak cae.

## Red y superficie

- Webhooks y hooks de sistema sin red local; única excepción: `destino`.
- Hook de sistema `receptor-sistema`, firmado, sin flags: altas y bajas al canal.
- `auto_disabling_web_hooks` activada.
- `monitoring_whitelist`: el laboratorio abre los rangos privados enteros para el
  terminal y Prometheus. En producción: solo las IP del monitoreo y del balanceador.
- Límites: la IP que ve GitLab es la del gateway de Docker. En producción, detrás de
  un balanceador, configurar `trusted_proxies`.

## Excepciones

| Qué | Por qué | Hasta cuándo |
|---|---|---|
<los proyectos públicos que decidiste mantener en la práctica 01, o "Ninguna">
```

```bash
cd /ruta/a/tus/clones/plataforma
git add docs/endurecimiento.md && git commit -S -m "docs: política de endurecimiento de la instancia"
git push -u origin main
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$PP/repository/files/docs%2Fendurecimiento.md?ref=main" \
  | jq -r '.content | @base64d' | grep -c 'OIDC\|monitoring_whitelist\|admin_mode'
```

Tres o más. Es el primer push a `infra/plataforma`, y `main` ya estaba protegida.

---

## ✅ Resultado

- [ ] Sabes quién usa más la API de tu instancia
- [ ] Límites de API autenticada, API anónima y web anónima activos, y el auditor sigue en verde
- [ ] Rutas protegidas activas, un `429` provocado y su línea en `auth.log`
- [ ] Hooks de sistema sin red local, y `receptor-sistema` firmado y sin flags
- [ ] El canal anota `instancia: user_create …`
- [ ] `auto_disabling_web_hooks` en `on`
- [ ] `docs/endurecimiento.md` en `main` de `infra/plataforma`

```bash
./scripts/verificar-semana.sh 18
```

En esta práctica pasan `limites-de-peticiones`, `rutas-protegidas`, `hooks-sin-red-local` y `endurecimiento-documentado`.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| Todos los POST dan `422`, ninguno `429` | La caché: el límite aún no se aplica | Espera un minuto y repite |
| No puedes entrar en la web tras el paso 3 | Tu IP gastó los 10 intentos | Espera los segundos de `Retry-After` |
| `{"error":"Invalid url given"}` al crear `receptor-sistema` | `destino` no está en `outbound_local_requests_whitelist` | Semana 17, práctica 03, paso 3 |
| El canal no anota nada del hook de sistema | El `signing_token` no es la clave del `.env`, o el receptor rechaza la firma con `401` | `PUT /hooks/:id` con `signing_token` y la clave buena |
| El canal sigue diciendo `?: System Hook` | El pipeline de `ci/automatizacion` no desplegó | `esperar "$PA" "$PIPE"` y mira el job de despliegue |
| `403` en `features` | El token no tiene `admin_mode` | Práctica 01, paso 0 |
| El auditor de la Semana 17 da `429` | Comparte token con otro script | Un token por automatización (teoría 05) |

---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| [Práctica 02 — Login con Keycloak](02-login-con-keycloak.md) | [Práctica 04 — El ensayo de actualización](04-el-ensayo-de-actualizacion.md) |

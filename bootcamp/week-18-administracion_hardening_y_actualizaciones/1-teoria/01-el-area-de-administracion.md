# El área de administración

> Desde la Semana 01 eres `root`, y casi todo lo que has hecho ha sido de proyecto o de grupo. La instancia tiene una tercera capa, la que nadie más ve: quién puede registrarse, cuánto dura una sesión, cuántas peticiones aguanta la API. Esta teoría es la de saber dónde vive cada ajuste, cómo se cambia sin clics y por qué un ajuste recién cambiado a veces parece que no ha hecho nada.

---

## 🎯 Objetivos

- Distinguir los ajustes que viven en la base de datos (`application/settings`) de los que viven en `gitlab.rb`
- Leer y cambiar la configuración de la instancia por API y guardar una foto antes de tocarla
- Explicar qué protege el modo admin y qué scope necesita un token para administrar con él activo
- Contar con la caché de ajustes antes de dar por fallida una prueba

---

## 1. Qué problema resuelve

Abre `Admin → Settings` y recorre sus páginas: General, Network, Repository, CI/CD… cada una con sus secciones desplegables. Detrás hay 449 campos en 19.2.4. Cambiarlos a clics tiene tres problemas:

| Problema | Consecuencia |
|---|---|
| No queda registro de qué valía antes | No sabes deshacer, ni explicar por qué la instancia se comporta distinto que ayer |
| No se puede repetir | La instancia de ensayo, la de producción y la de tu compañero divergen en silencio |
| Nadie lo revisa | Un ajuste de seguridad desactivado por error no pasa por ningún merge request |

La respuesta es la misma que en la Semana 17: **la instancia se opera por API**, y lo que se decide se escribe en un repositorio. Esta semana ese repositorio es `infra/plataforma`.

---

## 2. Cómo funciona

### 2.1 Dos sitios para la configuración

| Dónde | Qué guarda | Cómo se cambia | Ejemplos |
|---|---|---|---|
| **`application/settings`** (base de datos) | La política: lo que un admin decide en caliente | API o `Admin → Settings`; efecto sin reiniciar | `signup_enabled`, `minimum_password_length`, `throttle_*`, `restricted_visibility_levels` |
| **`gitlab.rb`** (en el laboratorio, `GITLAB_OMNIBUS_CONFIG` del compose) | La infraestructura: procesos, puertos, integraciones que se cargan al arrancar | Editar y `gitlab-ctl reconfigure` (en el laboratorio, recrear el contenedor) | `external_url`, `omniauth_providers`, `monitoring_whitelist`, `puma['worker_processes']` |

Regla práctica: si la opción cambia **qué se permite**, está en la base de datos; si cambia **qué arranca o cómo se conecta**, está en `gitlab.rb`. El OIDC de la práctica 02 cae en el segundo grupo: el proveedor se declara en `gitlab.rb`, y por eso hay que recrear el contenedor.

> [!WARNING]
> Una clave de `gitlab.rb` mal escrita **no da error**: Omnibus la ignora. Un ajuste de `application/settings` mal escrito sí: la API devuelve `400` con el campo que no entiende. Es una razón más para preferir la API cuando las dos vías existen.

### 2.2 El modo admin

Con el modo admin activo (`admin_mode`), ser administrador no basta para administrar: en la web hay que **volver a introducir la contraseña** (o pasar por el SSO) para entrar en `Admin`, y la sesión de administración caduca sola. Una sesión robada de `root` sirve para leer proyectos, no para cambiar la política de la instancia.

En la API, un token de administrador solo llega a los endpoints de admin si además tiene el scope **`admin_mode`**. Un PAT de `root` con solo `api` lee sus proyectos, pero `GET /application/settings` le devuelve `403`. Es la misma idea que el rol y el scope de la Semana 17: dos llaves, y la segunda se da solo a los tokens que administran.

### 2.3 La caché de ajustes

Cada proceso de Puma y de Sidekiq guarda los ajustes en memoria y los relee aproximadamente cada minuto. La API devuelve el valor nuevo al instante, pero el comportamiento tarda en cambiar:

```bash
# Activas el SSO sin contraseña y pruebas el login con contraseña en el mismo segundo:
# entra. Un minuto después, el mismo intento devuelve "Invalid login or password.".
```

Lo comprobaste o lo comprobarás en la práctica 02. No es un fallo: es la razón de que una prueba de ajustes espere un minuto antes de juzgar.

---

## 3. Cómo se configura

Las variables de siempre, con un token de `root` que tenga `api` y `admin_mode`:

```bash
source ~/.bc-gitlab
API="$GITLAB_URL/api/v4"
H="PRIVATE-TOKEN: $GITLAB_TOKEN"
```

**La foto de antes.** Antes del primer cambio de la semana, guarda todos los ajustes. Es tu vuelta atrás y la evidencia de qué cambió:

```bash
curl -s -H "$H" "$API/application/settings" | jq -S . > ~/ajustes-antes-s18.json
jq 'keys | length' ~/ajustes-antes-s18.json
# 449
```

**Leer varios campos a la vez**, sin perderte entre cuatrocientos:

```bash
curl -s -H "$H" "$API/application/settings" \
  | jq -c '{signup_enabled, admin_mode, minimum_password_length}'
# {"signup_enabled":true,"admin_mode":true,"minimum_password_length":8}
```

**Cambiar**: `PUT` con los campos que cambian, y la respuesta trae todos los ajustes ya con el valor nuevo:

```bash
curl -s --request PUT "$API/application/settings" -H "$H" \
  --data signup_enabled=false | jq .signup_enabled
# false
```

**Con la UI**: `Admin → Settings → General`, la sección que toque, *Save changes*. El nombre del campo en la API casi nunca coincide con la etiqueta de la UI: busca la etiqueta en la [referencia de la API de ajustes](https://docs.gitlab.com/api/settings/) para saber cuál es.

**El diff de la semana**, al terminar:

```bash
curl -s -H "$H" "$API/application/settings" | jq -S . > ~/ajustes-despues-s18.json
diff ~/ajustes-antes-s18.json ~/ajustes-despues-s18.json
```

Ese diff es la mitad de `docs/endurecimiento.md`: lo que cambiaste, con su valor de antes.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Administrar con un token de `root` sin caducidad guardado en un script | Es la llave maestra de la instancia en texto plano | Token con `admin_mode`, caducidad corta y solo cuando administras |
| Cambiar ajustes sin la foto de antes | No hay forma de saber qué valía ni de volver | `jq -S` de `application/settings` antes y después |
| Juzgar un ajuste nada más cambiarlo | Los procesos aún tienen el valor viejo en caché | Espera un minuto y repite la prueba |
| Desactivar el modo admin "porque pide la contraseña otra vez" | Una sesión robada de `root` pasa a poder cambiar toda la política | Dejarlo activo; es el coste de una sesión de administración separada |
| Meter en `gitlab.rb` lo que la API ya cubre | Una clave mal escrita se ignora sin avisar y exige reiniciar | API para la política; `gitlab.rb` solo para lo que no tiene API |

---

## 5. Trucos

- `jq -S` ordena las claves: sin él, dos volcados de los mismos ajustes pueden dar un diff enorme solo por el orden.
- `GET /personal_access_tokens/self | jq .scopes` dice si tu token tiene `admin_mode` antes de que un `403` te lo diga peor.
- Los campos con `_raw` (`protected_paths_raw`, `outbound_local_requests_allowlist_raw`) son la misma lista en texto, una línea por elemento: más cómodos de editar a mano, peores de comparar.

---

## 📚 Recursos Adicionales

- [Application settings API](https://docs.gitlab.com/api/settings/) — todos los campos, con su tipo y su valor por defecto
- [Admin Mode](https://docs.gitlab.com/administration/settings/sign_in_restrictions/#admin-mode) — qué protege y el scope `admin_mode` de los tokens
- [Omnibus GitLab settings](https://docs.gitlab.com/omnibus/settings/) — lo que va en `gitlab.rb`

---

## ✅ Checklist de Verificación

- [ ] Tienes `~/ajustes-antes-s18.json` guardado antes del primer cambio
- [ ] Tu token de la semana tiene `api` y `admin_mode`, y caduca
- [ ] Sabes decir, para un ajuste cualquiera, si vive en la base de datos o en `gitlab.rb`
- [ ] Has visto un ajuste tardar en aplicarse y sabes por qué

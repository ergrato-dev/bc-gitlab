# Límites de peticiones

> Tu instancia viene sin límite de peticiones en la API ni en la web. Un script de la Semana 17 con un bucle mal cerrado, un escáner que prueba contraseñas en `/users/sign_in` o un crawler que recorre cada archivo de cada commit: los tres tumban a Puma igual, y GitLab devuelve `502` a todo el mundo. Los límites no hacen la instancia más rápida; deciden **a quién** se le dice que no cuando no da para todos.

---

## 🎯 Objetivos

- Distinguir los límites por tipo de tráfico: API, web, Git, paquetes, archivos, y autenticado o anónimo
- Activar los límites de la API y de la web y las rutas protegidas, y saber qué valores trae cada uno
- Leer un `429`: qué límite saltó, cuántas peticiones contó y cuándo vuelve a dejar pasar
- Evitar que los límites frenen a tus propios runners y automatizaciones

---

## 1. Qué problema resuelve

Puma atiende con un número fijo de hilos (en el laboratorio, 2 procesos × 4 hilos). Cada petición ocupa uno mientras dura. Si un solo cliente ocupa todos, el resto espera, y a partir de cierto tiempo NGINX corta con `502`. Un límite por cliente convierte "nadie puede trabajar" en "ese cliente recibe `429` durante unos segundos".

Las rutas de login son un caso aparte: no hace falta tumbar la instancia para hacer daño. Diez intentos de contraseña por minuto ya son demasiados para un humano y muy pocos para un ataque de diccionario, y eso es exactamente lo que deja pasar el límite de rutas protegidas.

---

## 2. Cómo funciona

### 2.1 Las familias de límites

Todos están en `application/settings`, con el patrón `throttle_<quién>_<qué>_{enabled,requests_per_period,period_in_seconds}`. **Free.** En 19.2.4 vienen todos apagados:

| Límite | Cuenta por | Valor al activarlo (peticiones / periodo) | Qué protege |
|---|---|---|---|
| `throttle_unauthenticated_api` | IP | 3600 / 3600 s | La API anónima: crawlers, escáneres |
| `throttle_authenticated_api` | Usuario o token | 7200 / 3600 s | La API con token: scripts desbocados |
| `throttle_unauthenticated_web` | IP | — | La web sin sesión |
| `throttle_authenticated_web` | Usuario | — | La web con sesión |
| `throttle_protected_paths` | IP o usuario | 10 / 60 s | Login, recuperación de contraseña, registro |
| `throttle_*_git_http`, `_git_lfs`, `_packages_api`, `_files_api`, `_deprecated_api` | Según el caso | — | Clones por HTTP, LFS, registro de paquetes, archivos crudos |

Las rutas protegidas tienen su lista en `protected_paths_raw`, una ruta por línea. Por defecto incluye `/users/sign_in`, `/users/password` y el registro, y solo cuenta **POST**: cargar la página de login no gasta, enviar la contraseña sí.

### 2.2 Lo que devuelve el `429`

```
HTTP/1.1 429 Too Many Requests
RateLimit-Name: throttle_unauthenticated_protected_paths
RateLimit-Limit: 10
RateLimit-Observed: 13
RateLimit-Remaining: 0
RateLimit-ResetTime: Tue, 24 Nov 2026 19:36:00 GMT
Retry-After: 7
```

`RateLimit-Name` es lo más útil: dice **qué** límite saltó, y con él sabes qué ajuste mirar. `Retry-After` son los segundos que tiene que esperar el cliente; un cliente bien escrito lo respeta en lugar de reintentar en bucle, que solo alarga el castigo. El texto del cuerpo se cambia con `rate_limiting_response_text`.

### 2.3 Tus propias máquinas

Los límites autenticados cuentan por usuario. El auditor de la Semana 17 usa el bot de su token de grupo: tiene su propio contador y no comparte cupo contigo. Lo que sí comparte cupo es todo lo que use **el mismo token**: otra razón para un token por automatización.

Si una automatización legítima necesita más, la salida no es apagar el límite, sino:

1. Hacer menos peticiones: GraphQL en vez de cien `GET` (Semana 17), paginación por claves, caché.
2. Respetar `Retry-After`.
3. Como último recurso, la lista de usuarios exentos, que se declara con la variable de entorno `GITLAB_THROTTLE_USER_ALLOWLIST` en `gitlab.rb` (`gitlab_rails['env']`), con los ID de usuario separados por comas.

---

## 3. Cómo se configura

Activar los límites de la API, de la web anónima y de las rutas protegidas con sus valores por defecto:

```bash
curl -s --request PUT "$API/application/settings" -H "$H" \
  --data throttle_authenticated_api_enabled=true \
  --data throttle_unauthenticated_api_enabled=true \
  --data throttle_unauthenticated_web_enabled=true \
  --data throttle_protected_paths_enabled=true \
  | jq -c '{throttle_authenticated_api_requests_per_period, throttle_protected_paths_requests_per_period}'
# {"throttle_authenticated_api_requests_per_period":7200,"throttle_protected_paths_requests_per_period":10}
```

**Con la UI**: `Admin → Settings → Network`, secciones *User and IP rate limits* y *Protected paths*.

Provocar el `429` de rutas protegidas, desde tu terminal y sin credenciales reales:

```bash
for i in $(seq 1 12); do
  curl -s -o /dev/null -w '%{http_code} ' --request POST "$GITLAB_URL/users/sign_in" \
    --data 'user[login]=nadie' --data 'user[password]=nada'
done; echo
# 422 422 422 422 422 422 422 422 422 422 429 429
```

Los `422` son el login rechazado por falta de token CSRF; da igual: el límite cuenta el POST, no el resultado. A partir del undécimo, `429`. Recuerda la teoría 01: si acabas de activarlo, espera un minuto.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Dejarlos apagados "porque es interno" | Un script propio con un bucle roto tumba la instancia igual que un ataque | Activarlos con los valores por defecto y ajustar con datos |
| Bajar los valores a ojo | Los runners y el auditor empiezan a fallar con `429` el lunes a las nueve | Medir antes (Semana 21) y ajustar después |
| Un solo token para todas las automatizaciones | Comparten cupo: el auditor frena a ChatOps | Un token por automatización |
| Reintentar en bucle ante un `429` | Cada reintento cuenta y alarga el bloqueo | Esperar `Retry-After` |
| Meter usuarios en la lista de exentos para callar errores | Un token exento robado no tiene freno | Reducir peticiones primero; exentos solo con motivo escrito |

---

## 5. Trucos

- `curl -sI` a cualquier endpoint de la API no devuelve las cabeceras `RateLimit-*` mientras no te acerques al límite: lo que tienes es el `429` y sus cabeceras.
- `GITLAB_THROTTLE_DRY_RUN` (en `gitlab_rails['env']`) con el nombre de un límite lo pone en modo de prueba: registra en `auth.log` quién habría recibido `429` sin bloquear a nadie. Es la forma de bajar un valor sin romper nada el primer día.
- Las peticiones bloqueadas se registran en `/var/log/gitlab/gitlab-rails/auth.log`, una línea JSON por `429` con `"message":"Rack_Attack"`, el límite en `matched`, la IP y la ruta: `docker compose exec gitlab grep -c Rack_Attack /var/log/gitlab/gitlab-rails/auth.log` cuenta cuántas.

---

## 📚 Recursos Adicionales

- [Rate limits](https://docs.gitlab.com/security/rate_limits/) — el mapa completo de límites, configurables y fijos
- [User and IP rate limits](https://docs.gitlab.com/administration/settings/user_and_ip_rate_limits/) — cabeceras, lista de exentos y modo de prueba
- [Protected paths](https://docs.gitlab.com/administration/settings/protected_paths/) — la lista por defecto y por qué solo cuenta POST

---

## ✅ Checklist de Verificación

- [ ] Los límites de API autenticada, API anónima, web anónima y rutas protegidas están activos
- [ ] Has provocado un `429` y sabes qué límite lo produjo
- [ ] Sabes por qué el auditor de la Semana 17 no comparte cupo contigo
- [ ] Puedes explicar qué hace el modo de prueba y cuándo lo usarías

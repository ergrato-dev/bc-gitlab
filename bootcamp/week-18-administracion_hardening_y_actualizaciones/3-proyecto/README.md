# Proyecto — Semana 18: la instancia se administra como producción

> Hasta la Semana 17, la instancia era el sitio donde vivía la plataforma, configurada como venía de fábrica. Desde esta tiene una política escrita, la gente entra con su cuenta de Keycloak, los límites deciden a quién se le dice que no, y la próxima actualización tiene un procedimiento ensayado. Este proyecto deja todo eso en manos de otra persona: el manual de la instancia, en `infra/plataforma`, con un acceso de emergencia que has probado de verdad.

---

## 🎯 Objetivo

Dejar en pie la **capa 18** de tu plataforma: la política de cuentas aplicada, el login por Keycloak con altas en espera, los límites de peticiones y de rutas protegidas, los hooks cerrados a la red local, `docs/endurecimiento.md` y el informe del ensayo de actualización en `infra/plataforma`, el laboratorio en 19.2.4, y un `README.md` que explica cómo se entra cuando Keycloak cae, cómo se da de alta a alguien y cuál es la próxima actualización.

---

## 📦 Qué añade esta capa

| Lo que creas esta semana | Se usa a partir de |
|---|---|
| `infra/plataforma` | S21 (las alertas de la instancia se documentan aquí), S22 (el DR drill restaura siguiendo su manual), S23 (la arquitectura de varios nodos), S24 (Terraform aplica la política de `docs/endurecimiento.md`) |
| La política de cuentas y los límites | S19 (el escaneo de secretos cuenta con tokens que caducan), S26 (la auditoría final la comprueba entera) |
| Keycloak y el OIDC | S26 (el SSO de la plataforma final) |
| El hook de sistema al receptor | S21 (las altas y bajas de cuentas, junto a las alertas) |
| El informe de actualización | S22 (la vuelta atrás que aquí no se ensaya), S23 (la actualización con varios nodos) |

Lo que esta semana deja a medias, a propósito: la política se aplicó a mano por API, y nada impide que alguien la deshaga desde `Admin → Settings`. Los checks de esta semana la comprueban cuando los lanzas; la Semana 24 la declara en Terraform. Y la vuelta atrás del ensayo es restaurar un backup que todavía no has restaurado nunca: eso es la Semana 22.

---

## ✅ Requisitos verificables

Los comprueba `./scripts/verificar-semana.sh 18` contra la API de tu instancia.

1. infra/plataforma protege main y no admite force push
2. infra/plataforma es privado
3. El registro publico de usuarios esta desactivado
4. Los administradores necesitan 2FA y el modo admin esta activo
5. Las contrasenas tienen 12 caracteres o mas y Git por HTTP no acepta contrasena
6. Solo un admin puede hacer algo publico y los proyectos nacen privados
7. Las cuentas sin actividad durante 90 dias se desactivan solas
8. Los tokens de registro de runners heredados estan desactivados
9. Al menos dos usuarios activos entran con Keycloak por OIDC
10. Un usuario creado desde Keycloak queda pendiente de aprobacion
11. Quien tiene identidad SSO no puede entrar con contrasena
12. La API autenticada, la API anonima y la web anonima tienen limite de peticiones
13. El limite de rutas protegidas esta activo
14. Ni los webhooks ni los hooks de sistema llegan a la red local fuera de la lista permitida
15. infra/plataforma tiene docs/endurecimiento.md con la politica, el OIDC y la lista de monitoreo
16. infra/plataforma tiene el informe del ensayo de 19.1 a 19.2 con backup y migraciones
17. La instancia del laboratorio sigue en 19.2.4
18. infra/plataforma versiona un README con el acceso de emergencia, como aprobar altas y la proxima actualizacion

Las prácticas 01 a 04 dejan en verde los 17 primeros. El 18 es este proyecto.

---

## 🛠️ Lo que haces en el proyecto

### 0. Preparar el terreno

Desde la terminal de las prácticas, o repitiendo el paso 0 de la práctica 01. El laboratorio, con `base` y `sso` levantados.

### 1. Ensayar el acceso de emergencia

Un acceso de emergencia que nadie ha probado no existe. La pregunta es: si Keycloak cae un viernes por la tarde, ¿quién entra y cómo?

```bash
cd /ruta/al/repositorio/bc-gitlab
docker compose --profile sso stop keycloak
```

Con Keycloak parado, en dos ventanas privadas:

| Quién | Qué haces | Qué tiene que pasar |
|---|---|---|
| `dev-<dominio>` | Botón *Keycloak* | Error de conexión con `localhost:8180`: no entra |
| `dev-<dominio>` | Usuario y contraseña de GitLab | `Invalid login or password.`: el SSO sin contraseña lo impide |
| `root` | Usuario, contraseña y código TOTP | Entra, y llega a `Admin` tras confirmar la contraseña del modo admin |

Y por API, lo que sigue funcionando sin Keycloak:

```bash
curl -s -H "$H" "$API/users?username=dev-${G#plataforma-}" | jq -c '.[0] | {state}'
```

`active`: los tokens personales no dependen del proveedor. Un desarrollador sin web puede seguir empujando por SSH y usando sus tokens hasta que Keycloak vuelva. Apunta en el manual cuánto tardó Keycloak en volver:

```bash
date +%T; docker compose --profile base --profile sso up -d keycloak
until curl -sf -o /dev/null http://localhost:8180/realms/bootcamp; do sleep 3; done; date +%T
```

### 2. El `README.md` de `infra/plataforma`

En `main` de `infra/plataforma`, firmado. Tiene que contar, con tus comandos y tus nombres:

- **Qué hay aquí**: `docs/endurecimiento.md` y `docs/actualizaciones/`, y la regla de que un cambio de política pasa por merge request a este repositorio
- **Acceso de emergencia**: `root` con contraseña y 2FA, dónde están los códigos de recuperación (sin escribirlos), el ensayo del paso 1 y su tiempo, y el comando de `gitlab-rails runner` para quitar el 2FA si se pierde todo
- **Dar de alta a alguien**: la cuenta en Keycloak con el email correcto, su primer login, y `POST /users/:id/approve` para aprobarla; `reject` para rechazar una que no debía llegar
- **Dar de baja a alguien**: desactivar en Keycloak y bloquear en GitLab (`POST /users/:id/block`), por qué no se borra, y que sus tokens dejan de valer
- **El token de administración**: con `api` y `admin_mode`, caducidad corta, y cómo se rota
- **Cuando alguien recibe `429`**: qué cabecera mirar, dónde está la línea en `auth.log`, y por qué la respuesta no es apagar el límite
- **La próxima actualización**: de 19.2.4 a 19.5, directa, con su ensayo previo siguiendo `docs/actualizaciones/19.1-a-19.2.md`, y la clave de `nginx` ya movida antes de empezar

No apruebes a `nuevo-<dominio>`: es la comprobación `oidc-alta-en-espera`. El manual describe el procedimiento; si quieres verlo funcionar, crea otra identidad en Keycloak y apruébala.

```bash
cd /ruta/a/tus/clones/plataforma
git add README.md && git commit -S -m "docs: manual de la instancia"
git push
```

---

## 🎨 Criterios de calidad

Lo que la API no ve y la rúbrica sí:

- `root` tiene el 2FA configurado de verdad y los códigos de recuperación fuera de cualquier repositorio
- El acceso de emergencia se ensayó con Keycloak parado, y el manual tiene lo que pasó, no lo que debería pasar
- Cada fila de la tabla de `docs/endurecimiento.md` tiene su valor de antes y un porqué que no repite el nombre del ajuste
- El informe del ensayo tiene los tiempos medidos y los hallazgos reales, y basta para hacer la actualización sin haber hecho esta semana
- El secreto del cliente de Keycloak y la contraseña de su admin están solo en `.env`, con `chmod 600`; `~/ajustes-*-s18.json` y `~/bc-s18/ensayo/` también en `600` o `700`
- El realm `bootcamp` no admite registro propio
- El manual se entiende sin haber hecho esta semana

---

## 💡 Adaptación a tu dominio

| Dominio | Qué cambia |
|---|---|
| Biblioteca (el del ejemplo) | Los voluntarios de verano: cuentas que se usan tres meses al año. Las cuentas dormidas a 90 días las desactivan en otoño, y el manual dice que se reactivan solas al entrar |
| Clínica veterinaria | Datos de clientes en algún proyecto: la restricción de `public` es la línea más importante de la política, y su excepción, ninguna |
| Tienda en línea | En campaña, el tráfico anónimo a la API sube: el límite de la API anónima se revisa antes del Black Friday con los datos de `auth.log`, no durante |
| Gestión de incidencias | Los clientes que abren incidencias no tienen cuenta en el directorio de la empresa: el manual dice que no entran por Keycloak, y cómo se les da acceso |

---

## 🚦 Cómo entregarlo

No hay nada que subir a ningún sitio. El entregable **es el estado de tu instancia**: los ajustes, las identidades de los usuarios, los hooks y `infra/plataforma` con sus tres documentos.

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 18
```

```
18 de 18 verificaciones superadas.
```

---

## 🧯 Errores comunes

| Error | Cómo se detecta | Solución |
|---|---|---|
| `admin-con-2fa` en rojo | `admin_mode` está a `false` | Práctica 01, paso 4 |
| `oidc-cuentas-vinculadas` en rojo | Menos de dos usuarios activos con identidad `openid_connect` | Práctica 02, paso 7: el email de Keycloak tiene que ser el de GitLab |
| `oidc-alta-en-espera` en rojo | Aprobaste a `nuevo-<dominio>` | Crea otra identidad en Keycloak y entra con ella |
| `hooks-sin-red-local` en rojo | `allow_local_requests_from_system_hooks` sigue en `true` | Práctica 03, paso 5 |
| `informe-de-actualizacion` en rojo con el informe escrito | Le falta `gitlab-backup`, `19.2.4` o `batched_background_migrations`, o no está en `main` | El informe lleva los comandos, no los describe; y el `push` del paso 10 |
| `laboratorio-en-version-fijada` en rojo | Subiste el laboratorio en vez del ensayo | La vuelta atrás es restaurar: Semana 22. Avisa al instructor |
| `manual-de-la-instancia` en rojo con el README escrito | Faltan las palabras `emergencia`, `approve` o `19.5` | El manual lleva los comandos y la versión, no los describe |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Proyecto Semana 17](../../week-17-api_webhooks_y_chatops/3-proyecto/README.md) | **Proyecto Semana 18** | [Proyecto Semana 19](../../week-19-seguridad_del_pipeline_con_herramientas_oss/3-proyecto/README.md) |

[← Volver a la Semana 18](../README.md)

# Semana 18 — Administración, hardening y actualizaciones

> Hasta ahora has sido `root` y la instancia estaba abierta como venía de fábrica: cualquiera podía registrarse, la API no tenía límite de peticiones y cada cuenta guardaba su propia contraseña. Esta semana la administras como si fuera producción. Cierras la instancia con una política escrita, das de alta a la gente con Keycloak por OIDC y ensayas una actualización en una copia desechable antes de tocar la de verdad. Nace `infra/plataforma`, el proyecto donde se documenta la propia instancia. Todo es Free.

---

## 🎯 Objetivos de la Semana

Al terminar serás capaz de:

- Administrar la instancia por la API de ajustes (`application/settings`) con el modo admin activo, y saber cuánto tarda en aplicarse un cambio
- Escribir y aplicar una política de cuentas: registro cerrado, 2FA para administradores, contraseñas, cuentas dormidas y tokens que caducan
- Conectar GitLab a Keycloak por OIDC con PKCE, vincular las cuentas que ya existían y dejar en espera las que no
- Explicar por qué el laboratorio necesita dos URL para Keycloak (la del navegador y la de la red interna) y qué pasa con el emisor del token
- Activar los límites de peticiones y de rutas protegidas, provocar un `429` y leer sus cabeceras
- Cerrar la superficie de red de la instancia y auditar quién hizo qué sin los eventos de auditoría de Premium
- Ensayar una actualización de 19.1 a 19.2 con backup previo, migraciones en segundo plano y claves de configuración que cambian de sitio, y escribir su informe

---

## 📋 Prerrequisitos

- **Semana 17 completada**: el receptor desplegado en `destino`, la lista de hosts locales permitidos con solo `destino`, y los webhooks firmados de `app` y `ci/automatizacion`
- **Semana 03 completada**: los usuarios de laboratorio existen y cada uno tiene un email propio (Keycloak los vincula por email en la práctica 02)
- **Semana 01 completada**: empujas por SSH (práctica 03), no por HTTP con contraseña (la práctica 01 lo prohíbe)
- **Perfil `base` levantado y el clúster k3d en marcha** (los pipelines de `ci/automatizacion` corren en `k8s-app`). Esta semana añade el perfil `sso` (Keycloak, ~550 MB) y, solo en la práctica 04, el perfil `ensayo`, que **sustituye** a `base`, `sso` y el clúster ([perfiles-de-laboratorio](../../docs/perfiles-de-laboratorio.md#semana-18--administración-y-actualizaciones))
- Una app de autenticación (TOTP) en el móvil: tras la práctica 01, `root` necesita 2FA para entrar en la web
- Un navegador con sesión abierta en tu instancia y una ventana privada para entrar como otro usuario

---

## 🗂️ Estructura de la Semana

```
week-18-administracion_hardening_y_actualizaciones/
├── README.md                  # Este archivo
├── rubrica-evaluacion.md      # Cómo se evalúa
├── checks.json                # Las 18 comprobaciones automáticas
├── 0-assets/                  # Diagramas
├── 1-teoria/                  # 7 archivos, un concepto cada uno
├── 2-practicas/               # 4 prácticas sobre tu instancia
├── 3-proyecto/                # La capa 18 de tu plataforma
├── 4-recursos/                # Libros, vídeos y enlaces
└── 5-glosario/                # Términos de esta semana
```

---

## 📝 Contenidos

### Teoría

| Archivo | Tema | Duración |
|---|---|:--:|
| [01 — El área de administración](1-teoria/01-el-area-de-administracion.md) | Admin Area y `application/settings`, el modo admin, la caché de ajustes, qué va en la API y qué en `gitlab.rb` | 20 min |
| [02 — La política de cuentas](1-teoria/02-la-politica-de-cuentas.md) | Registro y aprobación, 2FA, contraseñas, Git por HTTP, cuentas dormidas, tokens que caducan, registro de runners | 20 min |
| [03 — OIDC en GitLab](1-teoria/03-oidc-en-gitlab.md) | El flujo de código con PKCE, OmniAuth, `uid_field`, vincular por email, bloquear las altas y el SSO sin contraseña | 20 min |
| [04 — Keycloak como proveedor](1-teoria/04-keycloak-como-proveedor.md) | Realm, cliente confidencial, el emisor, las dos URL del laboratorio y lo que `start-dev` no da en producción | 20 min |
| [05 — Límites de peticiones](1-teoria/05-limites-de-peticiones.md) | Los `throttle_*`, rutas protegidas, cabeceras `RateLimit`, `Retry-After`, la lista de excepciones y el coste de ponerlos mal | 20 min |
| [06 — Superficie y auditoría](1-teoria/06-superficie-y-auditoria.md) | Red local, hooks de sistema, `monitoring_whitelist`, la marca `auto_disabling_web_hooks`, y auditar en CE con logs y `/events` | 20 min |
| [07 — Actualizar sin perder datos](1-teoria/07-actualizar-sin-perder-datos.md) | Paradas obligatorias, backup y secretos, migraciones en segundo plano, claves deprecadas, sin vuelta atrás, el ensayo | 20 min |

### Prácticas

| Práctica | Qué haces | Duración |
|---|---|:--:|
| [01 — La política de la instancia](2-practicas/01-la-politica-de-la-instancia.md) | `infra/plataforma`, registro cerrado, 2FA de administradores, contraseñas, visibilidad, cuentas dormidas y registro de runners heredado | 50 min |
| [02 — Login con Keycloak](2-practicas/02-login-con-keycloak.md) | El perfil `sso`, el realm y el cliente con `kcadm.sh`, OIDC activado, dos cuentas vinculadas, un alta en espera y el SSO sin contraseña | 50 min |
| [03 — Límites y superficie](2-practicas/03-limites-y-superficie.md) | Límites de la API y de la web, un `429` provocado, hooks de sistema, la marca de autodesactivación y `docs/endurecimiento.md` | 50 min |
| [04 — El ensayo de actualización](2-practicas/04-el-ensayo-de-actualizacion.md) | Una instancia 19.1 desechable, datos sembrados, backup, salto a 19.2.4, migraciones, la clave movida y el informe | 50 min |

### Proyecto

La **capa 18** de tu plataforma: la instancia está administrada como producción. Detalles en [3-proyecto](3-proyecto/README.md).

---

## ⏱️ Distribución del Tiempo (8 horas)

| Bloque | Tiempo |
|---|:--:|
| Teoría (7 archivos) | 2 h 20 |
| Prácticas (4 × 50 min) | 3 h 20 |
| Proyecto | 1 h 40 |
| Revisión y verificación | 40 min |
| **Total** | **8 h 00** |

> [!IMPORTANT]
> La práctica 04 levanta un segundo GitLab. No caben los dos: antes de empezarla, `docker compose --profile base --profile sso stop` y `k3d cluster stop bootcamp`. Al terminar, borras el contenedor `gitlab-ensayo` y sus tres volúmenes **por nombre** (nunca `down -v`, que se llevaría también los del laboratorio) y vuelves a levantar `base`, `sso` y el clúster. El laboratorio principal no cambia de versión esta semana.

---

## 🧭 Lo que entra esta semana y lo que espera

| Lo que quieres | Semana 18 | Después |
|---|---|---|
| Saber quién cambió un ajuste | `api_json.log`: usuario, token y parámetros de cada `PUT`; `GET /users/:id/events` | Eventos de auditoría con API y retención: Premium. Los logs, a Loki (Semana 21) |
| Que la gente entre con su cuenta de empresa | OIDC con Keycloak, cuentas vinculadas por email | Grupos de Keycloak que se convierten en grupos de GitLab: Premium (SAML Group Sync) |
| Caducidad máxima de los tokens personales | `require_personal_access_token_expiry` (todos caducan, 365 días como mucho) | Fijar un máximo menor: Ultimate |
| Una política que no se pueda deshacer a mano | `docs/endurecimiento.md` y los checks de la semana | Terraform la declara y la reaplica (Semana 24); la auditoría final la comprueba entera (Semana 26) |
| Actualizar sin parar el servicio | El ensayo con parada, en una copia | Actualización sin parada con varios nodos (Semana 23) |
| Un backup que de verdad restaura | `gitlab-backup create` antes del salto | Restaurar, medir el tiempo y el DR drill (Semana 22) |

---

## 🎩 Trucos y atajos

| Truco | Cómo |
|---|---|
| Todos los ajustes de la instancia en un archivo | `GET /application/settings > ajustes.json` antes de tocar nada; `diff` con el de después |
| Un ajuste cambiado que "no hace nada" | Cada proceso cachea los ajustes alrededor de un minuto: espera antes de dar la prueba por fallida |
| Qué límite te ha frenado | La cabecera `RateLimit-Name` del `429` (`throttle_unauthenticated_protected_paths`, por ejemplo) |
| Quién entra por SSO y quién por contraseña | `GET /users?per_page=100` como admin y mira `identities[].provider`; las altas en espera, con `state == "blocked_pending_approval"` |
| Los administradores sin 2FA | `GET /users?admins=true&two_factor=disabled` |
| El emisor que Keycloak pone en los tokens | `curl -s http://localhost:8180/realms/bootcamp/.well-known/openid-configuration \| jq -r .issuer` |
| Las claves que una versión ha deprecado | La línea `Deprecations:` al final de `gitlab-ctl reconfigure` |
| Si quedan migraciones antes del siguiente salto | `GET /admin/batched_background_migrations` como admin: todo `finished` |

---

## 📌 Entregables

1. `infra/plataforma`, privado, con `main` protegida y sin force push
2. La política de cuentas aplicada: registro cerrado, 2FA de administradores, contraseñas de 12 caracteres, Git por HTTP sin contraseña, visibilidad pública restringida, cuentas dormidas a 90 días y sin tokens de registro de runners
3. El login con Keycloak: dos usuarios de laboratorio vinculados, un alta en espera de aprobación y el SSO sin contraseña
4. Los límites de peticiones y de rutas protegidas activos, y los hooks sin acceso a la red local
5. `docs/endurecimiento.md` en `infra/plataforma`: la política, el OIDC y la lista de monitoreo
6. `docs/actualizaciones/19.1-a-19.2.md` en `infra/plataforma`: el informe del ensayo
7. El laboratorio sigue en `19.2.4`
8. El `README.md` de `infra/plataforma`: el manual de la instancia (proyecto)

---

## ✅ Verificación

```bash
./scripts/verificar-semana.sh 18
```

Las 18 comprobaciones tienen que pasar.

Lo que el script **no** puede comprobar es que `root` tenga 2FA configurado de verdad, que el `429` lo hayas provocado tú, que el ensayo haya ocurrido ni que el informe sirva para hacer la actualización real. Lo evalúa la rúbrica.

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Semana 17 — API, webhooks y ChatOps](../week-17-api_webhooks_y_chatops/README.md) | **Semana 18** | Semana 19 — Seguridad del pipeline con herramientas OSS |

[← Volver al inicio del bootcamp](../README.md)

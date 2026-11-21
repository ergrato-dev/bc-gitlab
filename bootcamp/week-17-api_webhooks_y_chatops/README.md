# Semana 17 — API, webhooks y ChatOps

> Hasta ahora, comprobar que tu plataforma está bien era abrir pantallas, y enterarte de lo que pasa en ella era mirarlas a tiempo. Esta semana nace `ci/automatizacion`: un bot de solo lectura que audita el grupo entero cada mañana por la API, un receptor que recibe los eventos firmados de `app` y los anota en un canal, y dos comandos de chat que ejecutan jobs sin abrir GitLab. Todo es Free.

---

## 🎯 Objetivos de la Semana

Al terminar serás capaz de:

- Recorrer la API REST v4 con paginación por desplazamiento y por conjunto de claves, y leer sus errores sin adivinar
- Escribir consultas GraphQL paginadas por cursor, y saber cuándo GraphQL calla lo que REST sí te dice
- Elegir el token de una automatización: de grupo, de proyecto, personal o `CI_JOB_TOKEN`, con el rol y el scope mínimos, caducidad y rotación
- Configurar webhooks firmados, verificar su firma con HMAC y decidir a qué hosts de tu red puede llamar GitLab
- Operar un webhook que falla: ver el registro de entregas, reenviar, deduplicar y saber qué hace (y qué no) GitLab por ti
- Ejecutar jobs desde un chat con la integración de slash commands de Mattermost, sin Mattermost, y devolver al canal solo lo que importa

---

## 📋 Prerrequisitos

- **Semana 16 completada**: el clúster `bootcamp` arrancado y `k8s-app` en línea con la etiqueta `docker`, asignado a `app` y a `ci/componentes`; `RID_K8S` en `~/.bc-gitlab-s16`
- **Semana 14 completada**: el servicio `destino` en marcha, con `authorized_keys` y `~/.ssh/destino-known-hosts`, e `infra/entornos` con sus entornos `staging` y `production` desplegados al menos una vez
- **Semana 03 completada**: eres Owner del grupo `plataforma-<tu-dominio>` (los tokens de grupo y los webhooks se crean con ese rol)
- **Perfil `base` levantado, observabilidad apagada** — la misma memoria que la Semana 16 ([perfiles-de-laboratorio](../../docs/perfiles-de-laboratorio.md#semana-16--runners-en-kubernetes-11-12-gb))
- Un navegador con sesión abierta en tu instancia: ChatOps pide confirmar dos cosas en la web (práctica 04)

---

## 🗂️ Estructura de la Semana

```
week-17-api_webhooks_y_chatops/
├── README.md                  # Este archivo
├── rubrica-evaluacion.md      # Cómo se evalúa
├── checks.json                # Las 16 comprobaciones automáticas
├── 0-assets/                  # Diagramas
├── 1-teoria/                  # 6 archivos, un concepto cada uno
├── 2-practicas/               # 4 prácticas sobre tu instancia
├── 3-proyecto/                # La capa 17 de tu plataforma
├── 4-recursos/                # Libros, vídeos y enlaces
└── 5-glosario/                # Términos de esta semana
```

---

## 📝 Contenidos

### Teoría

| Archivo | Tema | Duración |
|---|---|:--:|
| [01 — La API REST a fondo](1-teoria/01-la-api-rest-a-fondo.md) | Rutas, paginación por desplazamiento y por claves, códigos de error, 404 que significa 403, límites de peticiones | 20 min |
| [02 — GraphQL para operar](1-teoria/02-graphql-para-operar.md) | Una consulta en vez de cien, cursores, complejidad, errores con 200 y el silencio por permisos | 20 min |
| [03 — Tokens para máquinas](1-teoria/03-tokens-para-maquinas.md) | Token de grupo, de proyecto, personal y `CI_JOB_TOKEN`; rol, scope, caducidad, rotación y variables ocultas | 20 min |
| [04 — Webhooks firmados](1-teoria/04-webhooks-firmados.md) | Eventos, cabeceras, `signing_token` con HMAC, `X-Gitlab-Token`, la red local y la lista de hosts permitidos | 20 min |
| [05 — Cuando la entrega falla](1-teoria/05-cuando-la-entrega-falla.md) | Registro de entregas, sin reintentos, la autodesactivación que aquí está apagada, reenvío e idempotencia | 20 min |
| [06 — ChatOps](1-teoria/06-chatops.md) | Slash commands de Mattermost, vincular cuenta y verificar, jobs `chat`, `CHAT_INPUT` y la sección `chat_reply` | 20 min |

### Prácticas

| Práctica | Qué haces | Duración |
|---|---|:--:|
| [01 — El bot auditor](2-practicas/01-el-bot-auditor.md) | `ci/automatizacion`, un token de grupo de solo lectura, el grupo visto por el bot y el auditor por GraphQL y REST | 50 min |
| [02 — El receptor](2-practicas/02-el-receptor.md) | La verificación de la firma con sus tests, el receptor, y su despliegue en `destino` con una clave que solo toca `receptor` | 50 min |
| [03 — Los webhooks](2-practicas/03-los-webhooks.md) | La clave de firma, la red local cerrada salvo `destino`, los webhooks firmados; ataques al receptor, una caída y el reenvío | 50 min |
| [04 — ChatOps](2-practicas/04-chatops.md) | La integración de slash commands, tu cuenta vinculada, `run auditar` y `run estado`, un hallazgo visto desde el canal y la auditoría diaria | 50 min |

### Proyecto

La **capa 17** de tu plataforma: la plataforma se opera por API, no a clics. Detalles en [3-proyecto](3-proyecto/README.md).

---

## ⏱️ Distribución del Tiempo (8 horas)

| Bloque | Tiempo |
|---|:--:|
| Teoría (6 archivos) | 2 h 00 |
| Prácticas (4 × 50 min) | 3 h 20 |
| Proyecto | 2 h 00 |
| Revisión y verificación | 40 min |
| **Total** | **8 h 00** |

> [!IMPORTANT]
> Los jobs de `ci/automatizacion` corren en `k8s-app`, en el clúster de la Semana 16: antes de cada sesión, `k3d cluster start bootcamp`. El receptor vive en `destino`, que ya estaba en tu perfil `base`. Esta semana no añade memoria.

---

## 🧭 Lo que entra esta semana y lo que espera

| Lo que quieres | Semana 17 | Después |
|---|---|---|
| Saber que nadie ha relajado una protección | El auditor diario por API, en rojo si hay hallazgos | La auditoría de las 25 capas (Semana 26) |
| Webhooks para todo el grupo de una vez | Un webhook por proyecto | Webhooks de grupo: Premium. Webhooks de sistema, de administrador, para toda la instancia (Semana 18) |
| Que el receptor no pierda eventos si cae | Registro de entregas y reenvío manual | Alertas sobre el registro y el receptor (Semana 21) |
| Desactivar solo un webhook que falla siempre | `alert_status` y la marca de función `auto_disabling_web_hooks`, apagada por defecto aquí | Su activación, como decisión de administración (Semana 18) |
| Un chat de verdad | `curl` hace de Mattermost; el receptor hace de canal | Mattermost Team Edition, si tu organización lo usa: la integración es la misma |
| Rotar tokens sin tocar el código | `rotate` por API y la variable actualizada | La política de tokens de toda la instancia (Semana 18) |
| Gestionar la plataforma como código | Scripts que leen y corrigen por API | Terraform con el proveedor de GitLab (Semana 24) |

---

## 🎩 Trucos y atajos

| Truco | Cómo |
|---|---|
| Cuántas páginas tiene un listado sin descargarlas | `curl -sI` y las cabeceras `X-Total` y `X-Total-Pages` (no existen en la paginación por claves) |
| Cuánto le cuesta tu consulta a GraphQL | Añade `queryComplexity { score limit }` a la propia consulta |
| Ver lo que GitLab envió y lo que contestaron | `GET /projects/:id/hooks/:hook_id/events`: cabeceras, código y duración de cada entrega |
| Probar un webhook sin provocar el evento | `POST /projects/:id/hooks/:hook_id/test/push_events` |
| Saber si un reenvío es un evento repetido | `Idempotency-Key` no cambia en el reenvío; `X-Gitlab-Event-UUID` sí |
| Una variable que ni tú puedes volver a leer | `masked_and_hidden=true` al crearla: la API devuelve `"value": null` |
| Qué token de grupo nadie usa | `GET /groups/:id/access_tokens` y su `last_used_at`: incluye los revocados, filtra por `active` |
| Ver las variables que recibe un job de chat | `env \| grep ^CHAT_` en el job: `CHAT_INPUT`, `CHAT_CHANNEL`, `CHAT_USER_ID` |

---

## 📌 Entregables

1. `ci/automatizacion`, privado, con `main` protegida y `k8s-app` asignado
2. El token de grupo `auditor` (`read_api`, Reporter, 90 días como mucho) en `AUDITOR_TOKEN`, enmascarada, oculta y protegida
3. El auditor programado cada día, con su último pipeline en verde y `auditoria.json` guardado
4. El receptor desplegado en `destino`, con su verificación de firma probada por tests
5. La instancia cerrada a la red local salvo `destino`, y los webhooks firmados de `app` y `ci/automatizacion`
6. La integración de slash commands activa, y `auditar` y `estado` ejecutados desde el chat
7. El `README.md` de `ci/automatizacion` como manual de operación

---

## ✅ Verificación

```bash
./scripts/verificar-semana.sh 17
```

Las 16 comprobaciones tienen que pasar.

Lo que el script **no** puede comprobar es que el receptor rechace una firma falsa, que el registro de entregas esté en verde, ni que el manual sirva a otra persona a las tres de la mañana. Lo evalúa la rúbrica.

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Semana 16 — Runners en Kubernetes y FinOps](../week-16-runners_en_kubernetes_y_finops/README.md) | **Semana 17** | Semana 18 — Administración, hardening y actualizaciones |

[← Volver al inicio del bootcamp](../README.md)

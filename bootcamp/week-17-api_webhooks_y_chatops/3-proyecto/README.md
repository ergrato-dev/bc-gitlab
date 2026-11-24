# Proyecto — Semana 17: la plataforma se opera por API

> Hasta la Semana 16, saber si la plataforma estaba bien era abrir pantallas, y enterarse de lo que pasaba en ella era mirarlas a tiempo. Desde esta, un bot sin privilegios la audita cada mañana, los proyectos avisan al canal con mensajes firmados, y dos comandos de chat responden en el sitio donde se discute el problema. Este proyecto deja todo eso operable por otra persona: el manual de `ci/automatizacion`.

---

## 🎯 Objetivo

Dejar en pie la **capa 17** de tu plataforma: `ci/automatizacion` con su auditor diario y su token de solo lectura, el receptor de webhooks desplegado en `destino`, los webhooks firmados de `app` y `ci/automatizacion`, la red local de la instancia cerrada salvo `destino`, ChatOps funcionando, y un `README.md` que explica a quien llegue después cómo se rota cada secreto y cómo se recupera un aviso perdido.

---

## 📦 Qué añade esta capa

| Lo que creas esta semana | Se usa a partir de |
|---|---|
| `ci/automatizacion` y su pipeline | S19 y S20 (las comprobaciones de seguridad de toda la plataforma se añaden al auditor), S24 (Terraform declara lo que hoy corrige el auditor) |
| El token de grupo `auditor` | S18 (la política de tokens de la instancia), S26 (la auditoría final de las 25 capas parte de este auditor) |
| El receptor y su canal | S21 (las alertas de Prometheus llegan al mismo canal), S22 (el postmortem cita la línea de tiempo del canal) |
| La lista de hosts permitidos | S18 (el endurecimiento de la instancia revisa esta lista) |
| ChatOps | S22 (`run estado` durante el ensayo de desastre) |

Lo que esta semana deja a medias, a propósito: la deduplicación del receptor vive en memoria, y un aviso perdido solo vuelve si alguien lo reenvía. Para un canal informativo basta; la Semana 21 pone alertas sobre lo que el canal no puede ver.

---

## ✅ Requisitos verificables

Los comprueba `./scripts/verificar-semana.sh 17` contra la API de tu instancia.

1. ci/automatizacion protege main y no admite force push
2. ci/automatizacion es privado
3. El grupo tiene un token de grupo auditor activo, solo con read_api y rol Reporter
4. El token auditor caduca en 90 dias o menos
5. AUDITOR_TOKEN es una variable enmascarada, oculta y protegida de ci/automatizacion
6. ci/automatizacion tiene activa una programacion sobre main
7. El ultimo pipeline programado de ci/automatizacion termino en verde y guardo auditoria.json
8. ci/automatizacion desplego el receptor en el entorno receptor
9. El receptor verifica webhook-signature con una comparacion de tiempo constante
10. La instancia bloquea las peticiones a la red local salvo a destino
11. app envia sus eventos de pipeline y despliegue al receptor, firmados
12. ci/automatizacion envia sus eventos de pipeline al receptor, firmados
13. ci/automatizacion tiene asignado el runner de Kubernetes de app
14. ci/automatizacion tiene activa la integracion de slash commands de Mattermost
15. ChatOps ha ejecutado en verde los jobs auditar y estado
16. ci/automatizacion versiona un README con como rotar el token y la clave de firma y como reenviar una entrega

Las prácticas 01 a 04 dejan en verde todos menos el 16. Ese es este proyecto.

---

## 🛠️ Lo que haces en el proyecto

### 0. Preparar el terreno

Desde la terminal de las prácticas, o repitiendo el paso 0 de la práctica 01.

### 1. Ensayar las dos rotaciones

Un manual que nadie ha seguido no es un manual. Antes de escribirlo, haz las dos rotaciones de verdad y apunta cada comando tal como lo ejecutaste.

**El token del auditor** (teoría 03, apartado 2.4): `rotate` con una caducidad nueva, el token que devuelve directo a la variable, y una auditoría por chat que lo demuestre.

```bash
( umask 077
  curl -s --request POST "$API/groups/$G/access_tokens/$TID_AUDITOR/rotate" -H "$H" \
    --data "expires_at=$(date -d '+90 days' +%F)" > ~/bc-s17/rotado.json )
jq -r .token ~/bc-s17/rotado.json | tr -d '\n' > ~/bc-s17/auditor.token
curl -s --request PUT "$API/projects/$PA/variables/AUDITOR_TOKEN" -H "$H" \
  --data-urlencode "value@$HOME/bc-s17/auditor.token" | jq -c '{key, hidden}'
sed -i "s/^export TID_AUDITOR=.*/export TID_AUDITOR=$(jq -r .id ~/bc-s17/rotado.json)/" ~/.bc-gitlab-s17
shred -u ~/bc-s17/auditor.token ~/bc-s17/rotado.json
```

El `id` del token cambia; el nombre (`auditor`) y el bot no. Si te saltas la variable, el siguiente `run auditar` falla con `GraphQL 401: [{"message":"Invalid token"}]`: compruébalo antes de dar la rotación por buena.

**La clave de firma** (teoría 04): clave nueva en el `.env`, `destino` recreado, y `signing_token` nuevo en los dos webhooks (el `PUT` exige `url`). Entre el primer cambio y el último, las entregas fallan con `401`: al terminar, búscalas con `status=client_failure` y reenvíalas (teoría 05).

### 2. El `README.md` de `ci/automatizacion`

En `main` de `ci/automatizacion`, firmado como todo lo demás. Tiene que contar, con tus comandos y tus nombres:

- **Qué hay aquí**: las tres piezas (auditor, receptor, ChatOps), qué hace cada una y qué token o clave usa
- **Quién es el dueño**: de la programación diaria (corre con sus permisos, y si se va, deja de correr) y del token de grupo
- **Rotar el token del auditor**: el `rotate` y la variable, con la caducidad máxima que habéis decidido
- **Rotar la clave de firma**: el orden de los pasos, el `signing_token` de cada webhook, y el reenvío de lo que falle mientras tanto
- **Recuperar avisos perdidos**: `status=server_failure`, `resend`, y por qué la URL de un webhook no se cambia para arreglar una caída
- **Dar acceso a ChatOps a otra persona**: el rol mínimo, la vinculación y la verificación, y qué puede lanzar desde el chat
- **Qué hacer si el canal se queda callado**: `destino` arriba, `/receptor/salud`, el registro de entregas de cada webhook, la lista de hosts permitidos

```bash
cd /ruta/a/tus/clones/automatizacion
git add README.md && git commit -S -m "docs: operations runbook"
git push
```

---

## 🎨 Criterios de calidad

Lo que la API no ve y la rúbrica sí:

- Las dos rotaciones se ensayaron: el manual tiene los comandos que funcionaron, no los de la teoría
- El receptor rechaza una petición sin firma, una con firma inventada y una auténtica de más de cinco minutos (práctica 03, pasos 4 y 5), y no anota dos veces un reenvío (pasos 8 y 9)
- El registro de entregas de los dos webhooks no tiene fallos sin reenviar
- `outbound_local_requests_whitelist` tiene `destino` y nada que no sepas explicar
- Ningún archivo de `~/bc-s17`, del clon ni del repositorio contiene el token del auditor, la clave de firma ni el token del canal; el `.env` tiene `chmod 600`
- Los jobs de chat solo leen: ninguno despliega, borra ni cambia ajustes
- El manual se entiende sin haber hecho esta semana

---

## 💡 Adaptación a tu dominio

| Dominio | Qué cambia |
|---|---|
| Biblioteca (el del ejemplo) | `run estado` es la pregunta del préstamo que no se puede renovar: ¿qué versión de `calcularMulta` hay en producción? |
| Clínica veterinaria | Si un proyecto guarda datos de clientes, `el proyecto es público` es el hallazgo más grave: el manual dice a quién se avisa y en cuánto tiempo |
| Tienda en línea | En campaña, el canal recibe muchos pipelines: el filtro de estados finales del receptor es lo que lo mantiene legible |
| Gestión de incidencias | El comando que más se usará es `issue new` de la propia integración: crea el issue desde el canal, sin pasar por CI |

---

## 🚦 Cómo entregarlo

No hay nada que subir a ningún sitio. El entregable **es el estado de tu instancia**: `ci/automatizacion`, sus variables, su programación y su integración, los webhooks de `app` y `ci/automatizacion`, el token del grupo y los ajustes de red.

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 17
```

```
16 de 16 verificaciones superadas.
```

---

## 🧯 Errores comunes

| Error | Cómo se detecta | Solución |
|---|---|---|
| `token-auditor-solo-lectura` en rojo | El token tiene `api`, o el rol no es Reporter, o hay dos tokens activos llamados `auditor` | Revoca el sobrante; crea uno nuevo con `read_api` y `access_level=20` |
| `token-auditor-caduca` en rojo | Caduca dentro de más de 90 días | Rótalo con `expires_at` dentro de 90 días |
| `auditoria-en-verde` en rojo | El último pipeline programado falló, o la programación no se ha ejecutado nunca | `play` de la programación (práctica 04, paso 9); si falla, mira los hallazgos del artefacto |
| `solo-destino-permitido` en rojo | `allow_local_requests_from_web_hooks_and_services` está a `true` | Ponlo a `false`: la lista de permitidos ya deja pasar a `destino` |
| `webhook-app-firmado` en rojo | El webhook de `app` no tiene `deployment_events` o no tiene `signing_token` | `PUT /projects/:id/hooks/:hook_id` con `url`, `deployment_events=true` y `signing_token` |
| `chatops-ejecutado` en rojo | Uno de los dos comandos terminó en rojo, o nunca se lanzó | `run auditar` y `run estado` hasta verlos en verde en el canal |
| `runbook-versionado` en rojo con el README escrito | Faltan las palabras `rotate`, `signing_token` o `resend` | El manual tiene que llevar los comandos, no describirlos |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Proyecto Semana 16](../../week-16-runners_en_kubernetes_y_finops/3-proyecto/README.md) | **Proyecto Semana 17** | [Proyecto Semana 18](../../week-18-administracion_hardening_y_actualizaciones/3-proyecto/README.md) |

[← Volver a la Semana 17](../README.md)

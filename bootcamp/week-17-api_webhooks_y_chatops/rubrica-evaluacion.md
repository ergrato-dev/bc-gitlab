# Rúbrica de Evaluación — Semana 17

## 📊 Distribución de Evidencias

| Tipo | Peso | Instrumento | Quién juzga |
|---|:--:|---|---|
| 🧠 Conocimiento | 30% | 10 preguntas conceptuales, 10 pts cada una | Autoevaluación |
| 💪 Desempeño | 40% | Las 4 prácticas, 10 pts cada una | La API de tu instancia |
| 📦 Producto | 30% | La capa 17 de tu plataforma: 60 pts por API + 40 pts de calidad | Mixto |

**Criterio de aprobación: mínimo 70% en cada evidencia**, no en el promedio.

---

## 🧠 Conocimiento (30%)

| # | Pregunta |
|:--:|---|
| 1 | Tu auditor recorre `/groups/:id/projects` sin paginar y dice "20 proyectos, 0 hallazgos". El grupo tiene 23. ¿Por qué no hubo ningún error, cómo lo habrías detectado desde las cabeceras, y por qué la paginación por conjunto de claves es mejor para un listado que cambia mientras lo recorres? |
| 2 | Un script recibe `404 Project Not Found` de un proyecto que sabes que existe. Otro recibe `403 Forbidden` y un tercero `403` con `insufficient_scope`. ¿Qué le falta a cada token, y por qué GitLab contesta 404 en vez de 403 en el primer caso? |
| 3 | El bot auditor consulta `branchRules` por GraphQL y recibe una lista vacía, sin `errors`. ¿Qué dos cosas puede significar, cómo distingues una de otra, y qué le habría pasado a un auditor que comprobara "no hay reglas que permitan force push" en vez de "main está protegida"? |
| 4 | ¿Por qué el auditor usa un token de grupo y no tu token personal ni el `CI_JOB_TOKEN`? Para cada alternativa, di qué se rompería o qué riesgo añadiría. |
| 5 | El bot es Reporter con `read_api`. Alguien propone subirlo a Maintainer con `api` "para que el auditor pueda arreglar lo que encuentra". ¿Qué ganaría, qué podría hacer un error o un atacante con ese token, y cómo resolverías la necesidad sin dárselo? |
| 6 | Un webhook tiene `token` (que llega en `X-Gitlab-Token`) y otro tiene `signing_token`. Describe tres ataques que el primero no detiene y el segundo sí, y di qué tres comprobaciones hace el receptor para detenerlos. |
| 7 | Para que los webhooks lleguen a `destino`, un compañero activa `allow_local_requests_from_web_hooks_and_services`. Funciona. ¿Qué acaba de permitir que no quería, y qué ajuste consigue lo mismo sin eso? |
| 8 | El receptor estuvo caído diez minutos. ¿Qué ha hecho GitLab con los avisos de esos diez minutos en tu instancia, qué habría hecho con la marca `auto_disabling_web_hooks` activada, y cuál es el procedimiento para recuperarlos sin duplicar nada en el canal? |
| 9 | Un reenvío trae la misma `Idempotency-Key` que el original pero un `webhook-timestamp` nuevo. ¿Por qué cada una de esas dos decisiones es la correcta, y qué pasaría si el receptor deduplicara por `X-Gitlab-Event-UUID`? |
| 10 | `run auditar` desde el chat ejecuta un job que recibe `AUDITOR_TOKEN`. ¿Quién decide quién puede lanzarlo, qué comprobaciones hace GitLab antes, y por qué un job de chat que despliega a producción es mala idea aunque esas comprobaciones existan? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** La API devuelve una página, de 20 elementos por defecto, y una página es una respuesta correcta: no hay error que detectar. Las cabeceras lo decían: `X-Total: 23`, `X-Total-Pages: 2` y un `X-Next-Page` con valor. Un bucle correcto sigue hasta que `X-Next-Page` está vacía, o hasta que `Link` no trae `rel="next"`. Con desplazamiento, si se crea o se borra un proyecto entre una página y otra, todo se corre un puesto y uno se ve dos veces o ninguna. Con conjunto de claves, la siguiente petición dice "lo que va después del ID tal", y eso no cambia aunque el listado cambie; además su coste no crece con el número de página.

**2.** El primero no tiene acceso al proyecto: o el token no es de nadie que lo vea, o el proyecto es privado o interno y la petición va sin token. GitLab contesta 404 para no confirmar que existe a quien no puede verlo; contestar 403 sería decir "existe, pero no es para ti". El segundo tiene un token válido con el scope suficiente, pero el rol de su usuario no alcanza (por ejemplo, Reporter pidiendo webhooks, que son de Maintainer). El tercero tiene el rol, pero el token no tiene el scope: un `read_api` intentando escribir.

**3.** Puede significar que no hay reglas, o que el token no tiene permiso para verlas: GraphQL escribe las dos cosas igual. Se distingue preguntando lo mismo con un token que seguro lo ve (el tuyo) o por REST con el mismo token, que sí contesta (`GET /projects/:id/protected_branches/main` da 200 a un Reporter). Un auditor que comprobara "ninguna regla permite force push" habría recibido una lista vacía de reglas, habría concluido que ninguna lo permite, y habría dado por buenos todos los proyectos: el silencio por permisos se habría convertido en un falso verde. Comprobar la presencia de lo que tiene que estar es más seguro que comprobar la ausencia de lo que no.

**4.** Tu token personal puede todo lo que puedes tú en toda la instancia, así que un error del script o una filtración tienen tu alcance; y si desactivan tu cuenta, el auditor deja de funcionar. El `CI_JOB_TOKEN` solo existe mientras dura un job, no alcanza los endpoints de proyectos y ramas protegidas que necesita el auditor, y actúa con los permisos de quien lanzó el pipeline. El token de grupo es de un bot que pertenece al grupo y no a una persona, alcanza solo el grupo, y se le da el rol y el scope justos.

**5.** Ganaría poder escribir: cambiar protecciones, visibilidad, crear issues. Pero también podría borrar ramas protegidas, leer variables y webhooks con sus secretos, y cambiar cualquier ajuste del grupo; un error en el script o una filtración del token se convierten en cambios en producción sin revisión. La necesidad se resuelve separando: el auditor lee y avisa, y la corrección la hace una persona con su propio token (como en la práctica 04), o un segundo proceso con su propio token de alcance mínimo y revisión de por medio. Leer y escribir con el mismo token mezcla dos riesgos que conviene tener separados.

**6.** Con `X-Gitlab-Token`: quien capture una petición (un proxy, un log) tiene el secreto para siempre y puede firmar cualquier cosa; quien esté en medio puede cambiar el cuerpo y dejar la cabecera intacta; y una petición auténtica capturada se puede repetir mañana. Con `signing_token`, el secreto no viaja; la firma cubre el cuerpo, así que un cambio la rompe; y cubre la hora, así que una repetición fuera de la ventana se rechaza. El receptor comprueba: que el `webhook-timestamp` tenga menos de cinco minutos, que la HMAC sobre `id.timestamp.cuerpo` coincida en una comparación de tiempo constante, y que la `Idempotency-Key` no se haya visto ya.

**7.** Ha permitido que cualquier webhook o integración de cualquier proyecto haga que el servidor de GitLab llame a cualquier dirección de la red interna: bases de datos, paneles de administración sin contraseña, servicios de metadatos. Es la puerta de un ataque SSRF para cualquiera que pueda crear un webhook. `outbound_local_requests_whitelist` con solo `destino` consigue lo mismo para el receptor y deja el resto bloqueado.

**8.** Los ha intentado entregar una vez cada uno, ha apuntado cada fallo en el registro de entregas (`internal error`, en `server_failure`) y no los ha vuelto a intentar. El webhook sigue activo. Con la marca activada, tras cuatro fallos seguidos lo habría apartado durante un tiempo creciente, y tras cuarenta lo habría desactivado: dejaría de mandar incluso cuando el receptor volviera. Para recuperarlos: levantar el receptor, `GET …/events?status=server_failure`, y `POST …/events/:id/resend` de cada uno. El receptor contesta 200 a lo que ya había visto y no lo anota otra vez, así que reenviar de más no duplica.

**9.** La `Idempotency-Key` es la identidad del evento: tiene que ser la misma para que el receptor sepa que es el mismo aviso. El `webhook-timestamp` es la hora del envío y entra en la firma: tiene que ser nuevo para que un reenvío legítimo de hace tres días pase la ventana de cinco minutos, que es la que impide que un tercero repita una petición capturada. Si el receptor deduplicara por `X-Gitlab-Event-UUID`, que cambia en cada reenvío, cada reenvío parecería un evento nuevo y el canal se llenaría de duplicados.

**10.** Lo decide GitLab con los permisos del usuario vinculado: la persona del chat tiene que tener su cuenta vinculada (en la web, con su sesión), la petición verificada, y poder crear pipelines en el proyecto (Developer o más); además, el token de la integración tiene que ser correcto y el job tiene que aceptar `source: chat` en sus `rules`. Aun así, un job de chat que despliega a producción salta todo lo que protege un despliegue: no hay merge request, ni revisión, ni la rama protegida de `infra/entornos` como barrera, y cualquier Developer de `ci/automatizacion` con chat lo puede lanzar. Los comandos de chat deben leer; lo que cambia, pasa por el camino gobernado.

</details>

---

## 💪 Desempeño (40%)

| Práctica | Criterio | Puntos |
|---|---|:--:|
| [01 — El bot auditor](2-practicas/01-el-bot-auditor.md) | `ci/automatizacion` privado, `main` protegida antes del primer push, `k8s-app` asignado; el token `auditor` Reporter con `read_api` y 90 días; el `403`, el `insufficient_scope` y el `[]` de GraphQL vistos; `AUDITOR_TOKEN` oculta y el archivo borrado; la primera auditoría en verde | 10 |
| [02 — El receptor](2-practicas/02-el-receptor.md) | Los cinco tests en verde y uno en rojo al romper la comparación; el receptor desplegado por pipeline con el SHA de `main` en `/receptor/salud`; la clave `destino-receptor` rechazada en `staging` | 10 |
| [03 — Los webhooks](2-practicas/03-los-webhooks.md) | Las claves en el `.env` sin imprimirlas; la red local cerrada salvo `destino`; los dos webhooks firmados con entregas en `200`; los cuatro ataques rechazados o deduplicados; los avisos perdidos recuperados con `resend` sin duplicar; la línea falsa quitada del canal | 10 |
| [04 — ChatOps](2-practicas/04-chatops.md) | La integración activa; cuenta vinculada y petición verificada; `run auditar` y `run estado` contestando en el canal; el hallazgo visto en rojo, leído del artefacto y corregido por API; `run test` rechazado; la auditoría diaria en verde | 10 |

---

## 📦 Producto (30%)

### Verificable por API — 60 puntos

| Requisito | Comprobación | Puntos |
|---|---|:--:|
| `main` de `ci/automatizacion` protegida, sin force push | `automatizacion-existe` | 3 |
| `ci/automatizacion` privado | `automatizacion-privado` | 3 |
| El token `auditor` de solo lectura | `token-auditor-solo-lectura` | 5 |
| El token caduca en 90 días o menos | `token-auditor-caduca` | 3 |
| `AUDITOR_TOKEN` enmascarada, oculta y protegida | `auditor-token-oculto` | 5 |
| La programación diaria | `auditoria-programada` | 3 |
| La auditoría programada en verde con su artefacto | `auditoria-en-verde` | 5 |
| El receptor desplegado | `receptor-desplegado` | 4 |
| El receptor verifica la firma | `receptor-verifica-firma` | 4 |
| La red local cerrada salvo `destino` | `solo-destino-permitido` | 5 |
| El webhook de `app`, firmado | `webhook-app-firmado` | 4 |
| El webhook de `ci/automatizacion`, firmado | `webhook-automatizacion-firmado` | 3 |
| `k8s-app` asignado | `automatizacion-en-kubernetes` | 2 |
| La integración de slash commands | `chatops-activo` | 3 |
| `auditar` y `estado` desde el chat | `chatops-ejecutado` | 4 |
| El manual versionado | `runbook-versionado` | 4 |

### Calidad — 40 puntos

| Criterio | Qué se mira | Puntos |
|---|---|:--:|
| El manual sirve a otra persona | Las tres piezas, sus dueños, las dos rotaciones con los comandos ensayados, la recuperación de avisos, el acceso a ChatOps y qué hacer si el canal calla | 15 |
| El receptor es de fiar | Rechaza sin firma, con firma inventada y fuera de tiempo; no anota dos veces un reenvío; contesta rápido; el registro de entregas no tiene fallos sin reenviar | 10 |
| Menor privilegio en todo | El bot con `read_api` y Reporter; la clave SSH solo para `receptor`; la lista de hosts con solo `destino`; los jobs de chat solo leen | 10 |
| Los secretos se quedan en casa | Ni el token del auditor, ni la clave de firma, ni el token del canal en repositorios, en `~/bc-s17` ni en el historial de la terminal; `.env` y `~/.bc-gitlab-s17` en `600` | 5 |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Un token personal o con scope `api` en `AUDITOR_TOKEN` | −15 |
| `allow_local_requests_from_web_hooks_and_services` activado | −15 |
| Un webhook al receptor sin `signing_token`, o el receptor aceptando peticiones sin firma | −15 |
| Cualquier token o clave de esta semana en un repositorio, aunque se borrara después sin rotarlo | −20 |
| Un job de chat que despliega, borra o cambia ajustes | −10 |
| La URL de un webhook cambiada para "arreglar" una caída, con entregas perdidas sin recuperar | −5 |
| El token `auditor` sin caducidad cercana ni rotación en el manual | −5 |

---

[← Volver a la Semana 17](README.md)

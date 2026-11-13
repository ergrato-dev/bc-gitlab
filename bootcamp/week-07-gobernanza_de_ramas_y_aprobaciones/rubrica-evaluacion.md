# Rúbrica de Evaluación — Semana 07

## 📊 Distribución de Evidencias

| Tipo | Peso | Instrumento | Quién juzga |
|---|:--:|---|---|
| 🧠 Conocimiento | 30% | 10 preguntas conceptuales, 10 pts cada una | Autoevaluación |
| 💪 Desempeño | 40% | Las 4 prácticas, 10 pts cada una | La API de tu instancia |
| 📦 Producto | 30% | La capa 7 de tu plataforma: 60 pts por API + 40 pts de calidad | Mixto |

**Criterio de aprobación: mínimo 70% en cada evidencia**, no en el promedio.

---

## 🧠 Conocimiento (30%)

| # | Pregunta |
|:--:|---|
| 1 | Con `push = No one` en `main`, ni el administrador de la instancia puede empujar. Pero cualquier Maintainer puede quitar la protección. ¿Qué protege entonces la regla, y frente a quién no protege? |
| 2 | ¿Por qué un tag de versión necesita una protección que no se aplica a las ramas (que nadie pueda moverlo, ni siquiera un Owner), y qué haces si un tag protegido apunta al commit equivocado? |
| 3 | En CE, GitLab no lee `CODEOWNERS`. ¿Qué ganas escribiéndolo, y por qué la auditoría lo lee de la rama de destino y no de la merge request? |
| 4 | La rama protegida y el server hook rechazan los dos un `push` a `main`. ¿Qué mira cada uno, quién puede desactivar cada uno, y por qué hacen falta los dos? |
| 5 | El hook exige firma a los commits que llegan por `ssh` y `http` pero no a los que llegan por `web`. ¿Qué operaciones llegan por `web`, y qué pasaría si también se les exigiera firma? |
| 6 | El hook usa `git rev-list "$nuevo" --not --all` para la firma y el formato, pero `git log "$viejo..$nuevo"` para la aprobación. ¿Qué hueco abriría usar el primero también para la aprobación, y qué fallo provocaría usar el segundo para la firma? |
| 7 | El hook comprueba que existe `Approved-by:`. Describe dos formas de que entre algo en `main` con ese trailer sin que otra persona lo haya aprobado de verdad, y qué parte de la gobernanza de esta semana detecta cada una. |
| 8 | Un hook con un error de sintaxis, instalado en `app`. ¿Qué deja de funcionar, por qué el usuario de la UI no ve un mensaje útil, y qué paso de la práctica 03 existe para evitarlo? |
| 9 | ¿Por qué el procedimiento de emergencia del ADR-005 usa la autoaprobación en lugar de quitar la protección o el hook, si las tres cosas permiten fusionar sin `revisor`? |
| 10 | El script `gobernanza` detecta pero no bloquea. ¿Por qué no se convierte en un bloqueo dentro del hook, que ya se ejecuta en cada fusión? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** Protege frente al descuido y frente a quien no es Maintainer. Con `push = No one`, nadie puede saltarse la merge request por accidente o por costumbre, incluido el Owner, que es justo quien más tentado está de hacerlo. Pero la regla vive en la base de datos de GitLab y en CE cualquier Maintainer la puede quitar, porque *Allowed to unprotect* es Premium. No protege frente a un Maintainer que decide saltársela: para eso hace falta una capa que no dependa de su rol, que es el server hook, y una auditoría que detecte que la protección cambió.

**2.** Porque la rama se mueve por diseño y el tag es una promesa de inmutabilidad: quien instaló `v0.1.0`, el pipeline que lo desplegó y la auditoría que lo revisa dan por hecho que apunta siempre al mismo commit. Si se pudiera mover, dos personas tendrían "la misma versión" con código distinto. Si el tag apunta al commit equivocado, no se corrige: se publica `v0.1.1` con el commit bueno y se documenta. Borrarlo es posible por la API como Maintainer, pero solo es aceptable si nadie lo ha descargado todavía.

**3.** Ganas un sitio versionado donde está escrito quién responde de cada ruta: la persona nueva sabe a quién pedir revisión, la auditoría tiene una fuente de verdad, y el archivo sirve tal cual si algún día se usa Premium o GitHub. Se lee de la rama de destino porque, si se leyera de la merge request, el autor podría añadirse como dueño de lo que toca en el mismo cambio y aprobarse a sí mismo. Leído de `main`, cualquier cambio a la lista de dueños tiene que aprobarlo el dueño actual de `/CODEOWNERS` antes de contar.

**4.** La rama protegida mira **quién**: si tu rol puede empujar o fusionar en esa rama. El hook mira **qué**: si los commits están firmados, si los asuntos son convencionales, si lo que entra en `main` lleva una aprobación. La protección la quita cualquier Maintainer desde la UI o la API; el hook solo quien tiene una shell en el servidor. Hacen falta los dos porque cubren cosas distintas: la protección convierte todo cambio en una merge request (el hook no sabe qué es una merge request), y el hook aguanta cuando alguien quita la protección (la protección no se defiende a sí misma).

**5.** Llegan por `web` las operaciones que hace el propio GitLab: fusionar una merge request (squash y commit de fusión), aplicar una sugerencia, el rebase del servidor, los commits desde la Web IDE o la API de archivos. Esos commits los escribe el servidor, que no tiene tu clave, así que no van firmados. Si el hook les exigiera firma, ninguna merge request se podría fusionar y ninguna sugerencia se podría aplicar: el hook bloquearía el propio flujo que quiere proteger.

**6.** Para la aprobación, `--not --all` solo ve commits que no estén en ninguna referencia. Bastaría empujar primero una rama (sin aprobación, porque no es `main`) y después esa misma rama a `main`: sus commits ya no serían nuevos, el hook no vería nada que comprobar y entrarían sin aprobación. Por eso la aprobación mira `$viejo..$nuevo`: lo que `main` gana. Al revés, usar `$viejo..$nuevo` para la firma rechazaría ramas correctas después de un rebase y un `--force-with-lease`, porque ese rango incluye los commits de `main` que GitLab escribió sin firma.

**7.** Una: el autor aprueba su propia merge request, cosa que CE permite; GitLab genera `Approved-by:` con su nombre y el hook lo acepta. Dos: quien fusiona escribe el mensaje del squash a mano, con `squash_commit_message` en la API o editándolo en la UI, e incluye un `Approved-by:` inventado. El hook ve texto, no aprobaciones. Las dos las detecta `scripts/gobernanza.sh`, que no lee el trailer sino las aprobaciones reales de la API y excluye al autor de la lista de aprobadores.

**8.** Deja de funcionar todo lo que cambia una rama de `app`: los `push`, las fusiones, las sugerencias y el rebase del servidor. El hook sale con error en cada intento, y como el error de bash no empieza por `GL-HOOK-ERR:`, GitLab lo descarta y la UI solo muestra un mensaje genérico. El paso 2 de la práctica 03 prueba el hook en local, contra un repositorio desnudo, con casos que deben pasar y casos que deben fallar, antes de instalarlo en el servidor.

**9.** Porque la autoaprobación no quita ninguna capa: la protección, el hook y la auditoría siguen funcionando, y la auditoría marca la merge request como autoaprobada, de modo que la emergencia queda a la vista. Quitar la protección o el hook abre una ventana en la que puede entrar cualquier cosa, no solo el arreglo urgente, y depende de que alguien se acuerde de volver a ponerlo. El procedimiento se diseña para que saltarse la regla sea posible y deje rastro, no para que sea imposible.

**10.** Porque el hook no debería llamar a la API de GitLab: se ejecuta dentro de cada operación de escritura, y una llamada lenta o un fallo de red bloquearía todos los `push` y todas las fusiones. Además, saber si alguien aprobó una merge request exige saber de qué merge request viene el cambio, algo que un hook ve solo como commits. El hook se queda con lo que puede comprobar mirando los commits; lo que necesita el contexto de la merge request va a la auditoría, que se puede ejecutar aparte y fallar sin bloquear a nadie.

</details>

---

## 💪 Desempeño (40%)

| Práctica | Criterio | Puntos |
|---|---|:--:|
| [01 — `main` y tags protegidos](2-practicas/01-main-y-tags-protegidos.md) | `main` con `push = 0`, `merge = 40`, sin force push; tu propio `push` rechazado; `v*` protegido y un tag de prueba que no se borra por Git; protección por defecto del grupo; foto de referencia guardada | 10 |
| [02 — CODEOWNERS y la auditoría](2-practicas/02-codeowners-y-la-auditoria.md) | `CODEOWNERS` con regla por defecto y dueño para sí mismo; `gobernanza.sh` ejecutable; auditoría vista fallar antes de aprobar y pasar después; commit de squash con `Approved-by:` | 10 |
| [03 — El server hook](2-practicas/03-el-server-hook.md) | Seis casos probados en local; plantilla de fusión con `%{approved_by}`; hook versionado por merge request e instalado idéntico al de `main`; `push` y fusión sin aprobar rechazados con `GL-HOOK-ERR` | 10 |
| [04 — Quién se salta las reglas](2-practicas/04-quien-se-salta-las-reglas.md) | Protección quitada por `revisor` y commit directo rechazado por el hook; cambio detectado con la foto y protección restaurada; autoaprobación detectada; ADR-005; token revocado y comprobado en negativo | 10 |

---

## 📦 Producto (30%)

### Verificable por API — 60 puntos

| Requisito | Comprobación | Puntos |
|---|---|:--:|
| `main` protegida | `rama-main-protegida` | 4 |
| Nadie empuja a `main` | `nadie-empuja-a-main` | 4 |
| Solo Maintainers fusionan | `solo-maintainers-fusionan` | 4 |
| Sin force push | `main-sin-force-push` | 4 |
| `v*` protegidos | `tags-v-protegidos` | 4 |
| Solo Maintainers crean versiones | `tags-v-solo-maintainers` | 4 |
| `CODEOWNERS` en la raíz | `codeowners-en-la-raiz` | 4 |
| Regla por defecto | `codeowners-dueno-por-defecto` | 4 |
| `CODEOWNERS` se protege a sí mismo | `codeowners-protege-las-reglas` | 4 |
| Script de auditoría | `script-de-gobernanza` | 4 |
| Hook versionado | `hook-versionado` | 4 |
| Plantilla de fusión con aprobaciones | `plantilla-de-fusion-con-aprobaciones` | 4 |
| Aprobación en la historia | `aprobacion-en-la-historia` | 4 |
| Cinco aprobaciones de otra persona (dos de la S06, tres de la S07) | `cinco-mr-aprobadas-por-otro` | 4 |
| ADR-005 | `adr-005-en-la-wiki` | 4 |

### Calidad — 40 puntos

| Criterio | Qué se mira | Puntos |
|---|---|:--:|
| El hook está instalado y es el de `main` | El `diff` de la práctica 03, paso 5, sin diferencias; el commit directo de la práctica 04 rechazado con `GL-HOOK-ERR` | 10 |
| El hook se probó antes de instalarlo | Los seis casos en local, con los resultados esperados | 5 |
| Los rechazos se entienden | Mensajes que dicen qué hacer; la tabla de mensajes en `CONTRIBUTING.md`, cambiado por merge request | 7 |
| `CODEOWNERS` está bien escrito | Lo general arriba, ningún dueño que no sea miembro, reglas por área o su plan en el ADR | 6 |
| El ADR-005 es honesto | Nombra los huecos (autoaprobación, trailer, Maintainer que desprotege) y el procedimiento de emergencia no quita ninguna capa | 7 |
| La auditoría es una costumbre | Función en `~/.bc-gitlab` y la primera entrada fechada al final del ADR-005 | 5 |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Una regla de rama `*` que anula la protección de `main` | −5 |
| `main` sin proteger al terminar la práctica 04 | −10 |
| Un hook instalado distinto del que está en `main` | −10 |
| Un cambio en `main` posterior a la práctica 01 sin merge request | −10 |
| Una merge request propia autoaprobada fuera del procedimiento de emergencia | −10 |
| Aprobación hecha con tu propio token haciéndola pasar por la del revisor | −15 |
| El token del revisor sin revocar al terminar | −15 |
| Un token —cualquiera— en una merge request, un comentario, un commit, el hook o el script | −25 |

---

[← Volver a la Semana 07](README.md)

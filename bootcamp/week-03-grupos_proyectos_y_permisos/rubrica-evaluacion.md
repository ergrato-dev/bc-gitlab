# Rúbrica de Evaluación — Semana 03

## 📊 Distribución de Evidencias

| Tipo | Peso | Instrumento | Quién juzga |
|---|:--:|---|---|
| 🧠 Conocimiento | 30% | 10 preguntas conceptuales, 10 pts cada una | Autoevaluación |
| 💪 Desempeño | 40% | Las 4 prácticas, 10 pts cada una | La API de tu instancia |
| 📦 Producto | 30% | La capa 3 de tu plataforma: 60 pts por API + 40 pts de calidad | Mixto |

**Criterio de aprobación: mínimo 70% en cada evidencia**, no en el promedio.

---

## 🧠 Conocimiento (30%)

| # | Pregunta |
|:--:|---|
| 1 | Alguien es Maintainer del grupo raíz y quieres que en un proyecto concreto solo pueda leer. ¿Cómo se hace, y por qué la respuesta obvia no funciona? |
| 2 | ¿Qué diferencia hay entre `GET /projects/:id/members` y `GET /projects/:id/members/all`, y por qué el primero devuelve `404` para alguien que sí tiene acceso? |
| 3 | Un usuario es Owner del grupo invitado y la compartición tiene techo Reporter. ¿Qué puede hacer en tu proyecto, y qué mecanismo del modelo de permisos explica ese resultado? |
| 4 | ¿Por qué Guest no sirve para "acceso de solo lectura al repositorio", y qué rol es el correcto? |
| 5 | La misma petición devuelve `401` para un compañero, `403` para otro y `404` para un tercero. ¿Qué le pasa a cada uno? |
| 6 | ¿En qué orden se cambia la visibilidad de un árbol para cerrarlo, y por qué el orden contrario falla? |
| 7 | Transfieres un proyecto a otro grupo y los pipelines empiezan a fallar al día siguiente, aunque las URLs siguen funcionando. Da dos causas y di qué se redirige y qué no. |
| 8 | ¿Por qué un token de grupo es mejor que tu token personal para un job que consulta la API, si los dos funcionan igual? |
| 9 | Aprobar una solicitud de acceso sin indicar rol, y crear un token de proyecto sin indicar rol, tienen algo en común. ¿Qué es, y qué consecuencia práctica tiene? |
| 10 | ¿Por qué la verificación de firmas es Free y los roles personalizados son Ultimate? Describe cómo se sustituye en CE lo que Ultimate resuelve con roles a medida. |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** No se puede rebajar: hay que **quitarle el Maintainer del grupo** y dárselo solo donde toque. El rol efectivo sobre un recurso es el **máximo** de todas las fuentes que lo alcanzan —membresía directa, herencia de cualquier antepasado, grupos invitados—, así que asignarle Guest directamente en el proyecto no baja nada: sigue ganando el 40 heredado. La respuesta obvia ("le pongo Guest en el proyecto") parte de suponer que gana el rol más específico, y lo que gana es el más alto. La única excepción es el acceso que llega por un grupo invitado, que sí tiene techo, y por eso es la herramienta correcta para el acceso externo.

**2.** `members` devuelve solo los miembros **directos** de ese recurso; `members/all` devuelve además los heredados de grupos antepasados y los que llegan por grupos invitados, ya resueltos al rol efectivo más alto. El `404` de `members/:user_id` para alguien que sí tiene acceso es correcto y literal: esa persona no es miembro *de ese recurso*, lo es de su grupo padre. Es la confusión que hace que una auditoría hecha con `members` deje fuera precisamente a la mayoría de la gente, que casi nunca es miembro directa de nada.

**3.** Puede **leer**: clonar el repositorio, ver los issues y descargar del registry. No puede empujar ni cambiar ajustes. El mecanismo es que el acceso que llega por una compartición es el **mínimo** entre el rol de la persona en el grupo invitado (50) y el techo fijado al compartir (20). Es el único punto del modelo de CE donde el acceso se acota hacia abajo en vez de sumarse, y es lo que permite dar acceso a un colectivo cuya lista de miembros administra otra persona.

**4.** Porque Guest **no incluye `read_code`**: ve el proyecto, los issues, los hitos y la wiki, pero no el repositorio de un proyecto privado. El permiso de leer y clonar código empieza en **Reporter**. La consecuencia práctica es la de siempre: se da Guest "para que solo lea", la persona no puede clonar, pide ayuda, y alguien la sube a Developer —que además escribe— porque es el siguiente rol que se recuerda de memoria.

**5.** El del `401` tiene una credencial que no vale: token inexistente, caducado o revocado. El del `403` tiene una credencial válida y un rol insuficiente: GitLab confirma que el recurso existe y le niega la operación. El del `404` o bien pide algo que no existe, o bien no tiene ni permiso para saber que existe: GitLab devuelve el mismo código en los dos casos a propósito, para no confirmar la existencia de recursos privados. Distinguirlos es lo que decide si el problema está en el token, en el rol o en la ruta.

**6.** Para **cerrar** —de público a privado— se va **de abajo arriba**: primero los proyectos, luego los subgrupos, luego el grupo raíz. Para **abrir**, al revés. El motivo es la validación que impide que un hijo sea más visible que su padre: si intentas poner privado un grupo que todavía contiene un proyecto público, GitLab rechaza el cambio porque el resultado sería inconsistente. Hacerlo en el orden equivocado no rompe nada, pero deja el trabajo a medias y con mensajes de error que no explican la regla.

**7.** Se redirigen las URLs web, los remotos de Git y las llamadas a la API con la ruta antigua. **No** se redirigen las rutas de las imágenes del registry, las de los paquetes ni los `include: component:` de otros proyectos, porque en todos esos casos la ruta del proyecto forma parte del identificador del artefacto. Y hay una causa que no es de rutas: al cambiar de padre, **las variables de CI/CD del grupo antiguo dejan de aplicar** y los runners de grupo dejan de servir al proyecto. Por eso el pipeline falla al día siguiente con un error sobre una variable vacía que no menciona la transferencia por ningún lado.

**8.** Porque un token personal lleva **todo lo que tú puedes hacer** en toda la instancia, y muere contigo: el día que te vas de la organización, o que rotas tu token, el pipeline se rompe en producción. Un token de grupo tiene un rol propio, un alcance limitado a ese grupo y sus descendientes, una caducidad y un usuario bot visible en la lista de miembros, que se puede auditar y revocar sin tocar a ninguna persona. Que los dos "funcionen igual" hoy es exactamente el problema: el coste de la diferencia solo aparece el día del incidente.

**9.** Que en los dos casos **el valor por defecto no es el mínimo, sino uno cómodo y alto**: aprobar una solicitud de acceso sin `access_level` concede Developer (30), y crear un token de proyecto o de grupo sin `access_level` lo crea con Maintainer (40). La consecuencia práctica es que la automatización escrita "sin pensar en el rol" reparte permisos de escritura y de administración en silencio, y que en cualquier llamada que cree accesos el rol se escribe explícitamente aunque coincida con el que habría salido solo.

**10.** Porque una cosa es **leer un dato y mostrarlo** y otra es **decidir la política de la organización**. Verificar una firma es comparar el commit con las claves registradas: está en el código abierto de CE, con su API y su distintivo. Los roles personalizados son un motor de políticas de permisos a medida —qué puede exactamente cada perfil— y ahí GitLab vende gobernanza. La sustitución en CE tiene dos piezas: **repartir bien los cinco roles estándar**, con la elevación directa en el proyecto como excepción documentada y grupos invitados con techo para lo externo; y **compensar con controles preventivos y detectivos** lo que un rol a medida haría por diseño: server hooks (S07), un job de pipeline que audita accesos por API (S17) y una revisión periódica escrita, que es la de `scripts/auditar-accesos.sh`.

</details>

---

## 💪 Desempeño (40%)

| Práctica | Criterio | Puntos |
|---|---|:--:|
| [01 — El árbol de la organización](2-practicas/01-el-arbol-de-la-organizacion.md) | `infra` y `ci` existen, privados, con descripción y colgando del grupo raíz; `app` no se movió; los dos niveles de creación restringidos | 10 |
| [02 — Tres usuarios y sus roles](2-practicas/02-tres-usuarios-y-sus-roles.md) | Tres usuarios no administradores, roles repartidos con menor privilegio, una caducidad y la elevación directa en `app` | 10 |
| [03 — Probar los permisos de verdad](2-practicas/03-probar-los-permisos-de-verdad.md) | Las once pruebas ejecutadas con el token correcto, los códigos interpretados, y los tokens revocados al terminar | 10 |
| [04 — Compartir, auditar y recortar](2-practicas/04-compartir-auditar-y-recortar.md) | Grupo invitado con techo y fecha, techo comprobado con un token real, script de auditoría en `main` y hallazgos a cero | 10 |

---

## 📦 Producto (30%)

### Verificable por API — 60 puntos

| Requisito | Comprobación | Puntos |
|---|---|:--:|
| Subgrupo `infra` | `subgrupo-infra` | 5 |
| Subgrupo `ci` | `subgrupo-ci` | 5 |
| Subgrupos privados | `subgrupos-privados` | 4 |
| `app` sigue en la raíz | `app-sigue-en-la-raiz` | 5 |
| Creación de proyectos restringida | `creacion-de-proyectos-restringida` | 4 |
| Creación de subgrupos restringida | `creacion-de-subgrupos-restringida` | 4 |
| Tres usuarios de laboratorio | `tres-usuarios-de-laboratorio` | 5 |
| Rol Developer en el grupo | `rol-developer-en-el-grupo` | 4 |
| Rol Guest en el grupo | `rol-guest-en-el-grupo` | 4 |
| Membresía con caducidad | `membresia-con-caducidad` | 4 |
| Un solo Owner | `un-solo-owner` | 5 |
| Elevación directa en `app` | `elevacion-directa-en-app` | 5 |
| Herencia visible en el subgrupo | `herencia-visible-en-el-subgrupo` | 2 |
| `app` compartido con un grupo | `app-compartido-con-un-grupo` | 2 |
| Compartición de solo lectura | `comparticion-de-solo-lectura` | 2 |

### Calidad — 40 puntos

| Criterio | Qué se mira | Puntos |
|---|---|:--:|
| Los roles responden a necesidades distintas | Las tres identidades no son intercambiables y cada una tiene justificación escrita | 8 |
| `docs/organizacion.md` se entiende sin haber hecho la semana | Árbol, tabla de identidades con el porqué, accesos externos y fecha de auditoría | 8 |
| El script de auditoría es ejecutable y limpio | Corre sin editarlo, no lleva credenciales dentro y sus hallazgos salen a cero | 8 |
| Las descripciones de los namespaces dicen para qué y desde cuándo | No se limitan a repetir el nombre | 6 |
| El árbol es el más plano que resuelve el problema | Sin subgrupos decorativos ni niveles de más | 6 |
| Higiene de credenciales | Ningún token de prueba vivo, ninguno versionado, `~/.bc-gitlab` fuera del repositorio | 4 |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Una descripción de namespace vacía o igual al nombre | −3 |
| Una elevación directa sin justificación en `docs/organizacion.md` | −5 |
| Un acceso externo sin `expires_at` | −8 |
| Un token de prueba de la práctica 03 sigue vivo | −10 |
| Más de un Owner sin decisión escrita que lo respalde | −10 |
| Un usuario de laboratorio creado como administrador | −10 |
| Un token —cualquiera— versionado en el repositorio | −25 |
| El grupo raíz o `app` con visibilidad distinta de `private` | −25 |

---

[← Volver a la Semana 03](README.md)

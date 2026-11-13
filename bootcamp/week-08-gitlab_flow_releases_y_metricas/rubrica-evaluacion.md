# Rúbrica de Evaluación — Semana 08

## 📊 Distribución de Evidencias

| Tipo | Peso | Instrumento | Quién juzga |
|---|:--:|---|---|
| 🧠 Conocimiento | 30% | 10 preguntas conceptuales, 10 pts cada una | Autoevaluación |
| 💪 Desempeño | 40% | Las 4 prácticas, 10 pts cada una | La API de tu instancia |
| 📦 Producto | 30% | La capa 8 de tu plataforma: 60 pts por API + 40 pts de calidad | Mixto |

**Criterio de aprobación: mínimo 70% en cada evidencia**, no en el promedio.

---

## 🧠 Conocimiento (30%)

| # | Pregunta |
|:--:|---|
| 1 | `app` usa GitLab Flow con ramas de release. ¿Qué tendría que cambiar en el producto para que GitHub Flow fuera mejor opción, y qué para que lo fuera trunk-based? |
| 2 | En `0.y.z`, el bootcamp sube `MENOR` cuando algo rompe la interfaz. ¿Qué dice SemVer de esa zona, por qué se fija una regla propia, y qué promete a quien fija `app` a `0.1.x`? |
| 3 | El tipo de Conventional Commits y el trailer `Changelog:` suelen coincidir (`feat` y `added`). ¿Por qué el CHANGELOG de GitLab no se genera directamente desde el tipo? Pon un ejemplo de cada desajuste. |
| 4 | Con squash, ¿por qué se perdía el trailer, qué hace `%{first_multiline_commit_description}`, y qué pasa si el primer commit con cuerpo de la merge request no es el que lleva el trailer? |
| 5 | La primera llamada a la API del CHANGELOG falla sin `from`, y la de la `0.1.1` funciona sin él. ¿Cómo elige la API el inicio del rango, y qué tags ignora? |
| 6 | ¿Por qué el `POST` del CHANGELOG contra `main` devuelve `403` en `app`, por qué es correcto que lo haga, y qué dos cosas hay que pasarle para que funcione contra una rama sin que el hook lo rechace? |
| 7 | Para crear `release/0.1` GitLab exige tres condiciones. ¿Cuáles son, y qué ataque o descuido impide la tercera? |
| 8 | ¿Por qué el arreglo se fusiona primero en `main` y se lleva después a `release/0.1`, qué commit de `main` se lleva, y por qué no el de fusión? |
| 9 | `scripts/metricas.sh` mide la tasa de fallo como "releases que tuvieron un parche". Da dos situaciones reales en las que ese número engañe, una por arriba y otra por abajo. |
| 10 | Se propone premiar al equipo que más reduzca su tiempo de entrega. ¿Qué ocurrirá, según la ley de Goodhart, y qué harías en su lugar con las mismas métricas? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** GitHub Flow sería mejor si `app` dejara de ser una librería que alguien fija a una versión y pasara a ser un servicio con un único despliegue: si nadie ejecuta la `0.1` mientras existe la `0.2`, no hay nada que parchear aparte y la rama de release sobra. Trunk-based exigiría además dos cosas que `app` todavía no tiene: un pipeline que pruebe cada commit antes de que alguien dependa de él (Semana 09) y *feature flags* para esconder lo incompleto en vez de dejarlo en una rama (Semana 14). Sin eso, integrar en `main` varias veces al día es integrar código a medias sin red.

**2.** SemVer dice que con `MAYOR = 0` cualquier cosa puede cambiar en cualquier momento: no hay contrato. Eso es inútil para quien depende de `app` desde ya, así que el ADR-006 fija una regla propia desplazada una posición: lo que rompería sube `MENOR`, lo que añade también sube `MENOR`, y solo los arreglos suben `PARCHE`. La promesa a quien fija `0.1.x` es que cualquier `0.1.z` posterior solo trae arreglos y nunca cambia el comportamiento que ya usa.

**3.** Porque el tipo responde a "qué clase de cambio es para quien mantiene el código" y el trailer a "qué le importa a quien usa la versión". Un `feat` que añade una función interna o una opción de depuración no le interesa a nadie de fuera: lleva tipo `feat` y ningún trailer. Un `refactor` que, de paso, cambia el texto de un error que alguien compara en sus tests sí le importa: es `refactor` por el código y `Changelog: changed` por el efecto. El tipo decide cuánto sube la versión; el trailer, qué se cuenta.

**4.** Con squash, a `main` llega un commit nuevo construido con la plantilla, y la de la Semana 06 solo tenía título, issues, revisores, aprobaciones y coautores: ningún marcador copiaba el cuerpo de los commits, así que el trailer se quedaba en la rama borrada. `%{first_multiline_commit_description}` inserta el cuerpo del commit más antiguo de la merge request que tenga cuerpo; al final de la plantilla, ese cuerpo es el último párrafo, donde Git busca los trailers. Si el primer commit con cuerpo es otro (uno con una explicación y sin trailer), es ese el que se copia y el trailer del commit posterior se pierde. Por eso la regla de `app` es un solo commit con cuerpo por merge request.

**5.** Si no recibe `from`, la API busca el tag inmediatamente anterior a la versión pedida: toma todos los tags que encajan con `tag_regex`, los ordena por SemVer, ignora los que tienen pre-release (`-rc.1`), y usa el que queda justo debajo. Para la `0.1.0` no hay ningún tag anterior y responde `422`; para la `0.1.1` encuentra `v0.1.0`. Los tags que no siguen el formato (`prueba`, `release-1`) ni siquiera se consideran.

**6.** Porque el `POST` comprueba si el usuario puede hacer `push` a la rama, y en `main` nadie puede desde la Semana 07. Es correcto porque el CHANGELOG es un cambio como cualquier otro: si entrara sin merge request, sería la puerta para meter en `main` cualquier contenido sin revisión. Contra una rama funciona pasando `branch` (la rama, que tiene que existir) y `message` con un asunto convencional: el commit lo escribe GitLab por `web`, el hook no le pide firma, pero sí rechazaría el `Add changelog for version …` por defecto.

**7.** Poder fusionar en la rama (Maintainer o más), hacerlo por la web o la API y no con `git push`, y que el commit de partida ya esté en otra rama protegida. La tercera impide crear una rama protegida desde un commit que nadie revisó: sin ella, alguien podría empujar una rama de trabajo con código arbitrario y "promocionarla" a `release/0.1`, y a partir de ese momento ese código quedaría protegido como si hubiera pasado por todas las reglas.

**8.** Porque `main` es el origen de todas las versiones futuras: si el arreglo solo entrara en `release/0.1`, la `0.2.0` saldría de `main` con el bug otra vez, y nadie lo notaría hasta que alguien actualizara. Se lleva el commit de squash, que contiene el cambio completo con su trailer en un solo commit de un padre. El de fusión tiene dos padres: `cherry-pick` exige `-m` para elegir contra cuál calcular el cambio, y su mensaje (`Merge branch …`) no describe nada.

**9.** Por arriba: una versión que necesitó un parche por un error de documentación o por una dependencia que se rompió fuera de `app` cuenta como fallo igual que una que perdía datos; o un parche que se publica por precaución sin que nadie haya sufrido el fallo. Por abajo: un bug grave que se arregla directamente en la siguiente `MENOR` sin parche no cuenta, ni un fallo que nadie ha reportado todavía; y con dos releases, cualquier número es 0 %, 50 % o 100 %, lo que dice poco.

**10.** El equipo optimizará el número, no el flujo: abrirá las merge requests cuando ya estén aprobadas en privado, partirá cambios en trozos sin sentido para que cada uno se fusione rápido, o revisará más deprisa y peor. El tiempo de entrega bajará y la tasa de fallo y el tiempo de restauración subirán, que es justo lo que miden en pareja. Con las mismas métricas: usarlas para hacer preguntas al equipo sobre su propia tendencia ("¿por qué esta semana tardaron tres días las revisiones?"), siempre las cuatro juntas, sin objetivos numéricos ni comparaciones entre equipos.

</details>

---

## 💪 Desempeño (40%)

| Práctica | Criterio | Puntos |
|---|---|:--:|
| [01 — GitLab Flow en `app`](2-practicas/01-gitlab-flow-en-app.md) | ADR-006 con descartes; `release/*` con `0/40` sin force push y el `git push` de prueba rechazado; plantilla de squash con el marcador y `%{approved_by}`; `changelog_config.yml` probado con `config_file_ref` antes de fusionar | 10 |
| [02 — Cambios que cuentan](2-practicas/02-cambios-que-cuentan.md) | Dos issues del hito cerrados por merge request aprobada por `revisor`; los dos commits de squash con su trailer en `main`; vista previa en español con dos entradas | 10 |
| [03 — La primera versión](2-practicas/03-la-primera-version.md) | `POST` a `main` visto fallar con `403`; CHANGELOG por rama y merge request; tag `v0.1.0` firmado sobre el commit del CHANGELOG; release con notas, hito y enlace; hito cerrado y lo pendiente en `v0.2.0` | 10 |
| [04 — El primer parche](2-practicas/04-el-primer-parche.md) | Bug reproducido con un test contra `v0.1.0`; arreglo en `main` primero; `release/0.1` desde el tag; `cherry-pick -x` firmado; CHANGELOG `0.1.1` en la rama de release; `v0.1.1` firmado y su release; el falso positivo de la auditoría explicado | 10 |

---

## 📦 Producto (30%)

### Verificable por API — 60 puntos

| Requisito | Comprobación | Puntos |
|---|---|:--:|
| `release/*` protegidas | `ramas-release-protegidas` | 3 |
| `release/*` solo por merge request | `release-solo-por-merge-request` | 3 |
| `release/*` sin force push | `release-sin-force-push` | 3 |
| Configuración del CHANGELOG | `configuracion-del-changelog` | 3 |
| Plantilla de squash con el marcador | `plantilla-de-squash-con-trailers` | 4 |
| Tres cambios con trailer en `main` | `tres-cambios-con-changelog` | 3 |
| CHANGELOG `0.1.0` en `main` | `changelog-0-1-0-en-main` | 4 |
| `v0.1.0` anotado | `tag-v0-1-0-anotado` | 3 |
| Release `v0.1.0` con notas | `release-v0-1-0-con-notas` | 4 |
| Release `v0.1.0` con hito | `release-v0-1-0-con-hito` | 3 |
| Hito cerrado | `hito-v0-1-0-cerrado` | 3 |
| `release/0.1` protegida | `rama-release-0-1` | 3 |
| Parche con `cherry-pick -x` | `cherry-pick-en-release` | 4 |
| `v0.1.1` sale de la rama de release | `v0-1-1-sale-de-la-rama-de-release` | 4 |
| Release `v0.1.1` con notas | `release-v0-1-1-con-notas` | 3 |
| Script de métricas | `script-de-metricas` | 3 |
| Métricas definidas | `metricas-documentadas` | 4 |
| ADR-006 | `adr-006-en-la-wiki` | 3 |

### Calidad — 40 puntos

| Criterio | Qué se mira | Puntos |
|---|---|:--:|
| Los tags están firmados | `git tag -v v0.1.0` y `git tag -v v0.1.1` dicen `Good` con tu clave | 8 |
| El CHANGELOG se entiende sin contexto | Cada entrada, leída por quien usa `app`, dice qué cambió para él | 6 |
| El parche es solo el parche | `compare?from=main&to=v0.1.1` no muestra nada más que el arreglo y su CHANGELOG; el SHA del `cherry picked from` está en `main` | 8 |
| `docs/metricas.md` es honesto | Define antes de medir, nombra lo que cada métrica no captura, y sus números coinciden con el script | 8 |
| La auditoría no tiene falsos positivos | `gobernanza.sh` ya no exige issue fuera de `main`, probado contra una merge request de cada destino | 5 |
| `CONTRIBUTING.md` explica cómo se publica | Los cinco puntos del proyecto, con el ADR-006 enlazado y no copiado | 5 |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Un tag `v*` borrado y recreado apuntando a otro commit después de publicar su release | −10 |
| El arreglo del parche hecho directamente en `release/0.1`, sin pasar por `main` | −10 |
| `main` fusionada en `release/0.1` | −10 |
| Un cambio en `main` o en `release/0.1` sin merge request | −10 |
| Números de `docs/metricas.md` escritos a mano, distintos de los del script | −10 |
| El token del revisor sin revocar al terminar | −15 |
| Un token —cualquiera— en una merge request, un commit, el CHANGELOG, la release o un script | −25 |

---

[← Volver a la Semana 08](README.md)

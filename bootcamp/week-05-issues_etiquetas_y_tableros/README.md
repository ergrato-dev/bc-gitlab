# Semana 05 — Issues, etiquetas y tableros

> Un backlog que vive en la cabeza de una persona no es un backlog: es una dependencia.
> Esta semana el trabajo de `app` pasa a estar escrito, clasificado y en un tablero que dice la verdad.

---

## 🎯 Objetivos de la Semana

Al terminar serás capaz de:

- Escribir un issue que otra persona puede cerrar sin preguntarte nada: título, contexto, criterios de aceptación y lista de tareas
- Diseñar una taxonomía de etiquetas en familias (`tipo::`, `prioridad::`, `estado::`, `area::`) y defender por qué cada familia existe
- Explicar qué hacen las etiquetas con `::` en CE, qué añade Premium con las *scoped labels*, y comprobar la exclusividad por API sin pagarla
- Decidir si una etiqueta va en el grupo o en el proyecto, y priorizar etiquetas de grupo desde el proyecto
- Montar un tablero cuyas columnas son etiquetas, y explicar por qué mover una tarjeta **es** cambiar una etiqueta
- Planificar con hitos y fechas, y decir qué sustituye en CE a epics, iteraciones, pesos y burndown
- Escribir plantillas de descripción con acciones rápidas dentro, incluida la plantilla `Default`
- Cerrar issues desde un commit con los patrones de cierre, y saber por qué `Cierra #12` no cierra nada
- Leer el estado del backlog por API en una línea: cuántos hay, cuántos sin clasificar, cuántos en el hito

---

## 📋 Prerrequisitos

- **Semana 04 completada**: `app` con `README.md`, `CONTRIBUTING.md`, licencia detectada y la wiki con `ADR-001`
- **El árbol de grupos de la Semana 03**: `plataforma-<tu-dominio>` con `app`, `infra` y `ci`, y tú como Owner del grupo raíz
- **Un clon local de `app`** con commits firmados funcionando (Semana 02): la práctica 03 cierra un issue desde un commit
- **`jq` instalado** y `~/.bc-gitlab` con `GITLAB_URL`, `PROYECTO` y `GITLAB_TOKEN`
- **Perfil de laboratorio**: `base` — ver [perfiles-de-laboratorio](../../docs/perfiles-de-laboratorio.md)

---

## 🗂️ Estructura de la Semana

```
week-05-issues_etiquetas_y_tableros/
├── README.md                  # Este archivo
├── rubrica-evaluacion.md      # Cómo se evalúa
├── checks.json                # Las 17 comprobaciones automáticas
├── 0-assets/                  # Diagramas
├── 1-teoria/                  # 7 archivos, un concepto cada uno
├── 2-practicas/               # 4 prácticas sobre tu instancia
├── 3-proyecto/                # La capa 5 de tu plataforma
├── 4-recursos/                # Libros, vídeos y enlaces
└── 5-glosario/                # Términos de esta semana
```

---

## 📝 Contenidos

### Teoría

| Archivo | Tema | Duración |
|---|---|:--:|
| [01 — El issue como unidad de trabajo](1-teoria/01-el-issue-como-unidad-de-trabajo.md) | Anatomía de un issue, criterios de aceptación, listas de tareas, tipos y lo que es de pago | 20 min |
| [02 — Taxonomía de etiquetas](1-teoria/02-taxonomia-de-etiquetas.md) | Familias, `::` en CE y en Premium, grupo o proyecto, colores y descripciones | 20 min |
| [03 — Etiquetas priorizadas y exclusividad](1-teoria/03-etiquetas-priorizadas-y-exclusividad.md) | Prioridad de etiqueta, orden del backlog y cómo se garantiza "una por familia" sin Premium | 15 min |
| [04 — Hitos](1-teoria/04-hitos.md) | Hitos de proyecto y de grupo, fechas, progreso y qué sustituye a epics e iteraciones | 15 min |
| [05 — Tableros](1-teoria/05-tableros.md) | Listas de etiqueta, mover es reetiquetar, `/board_move` y los límites de CE | 20 min |
| [06 — Plantillas de descripción](1-teoria/06-plantillas-de-descripcion.md) | `.gitlab/issue_templates/`, la plantilla `Default` y acciones rápidas dentro de la plantilla | 15 min |
| [07 — Acciones rápidas y cierre automático](1-teoria/07-acciones-rapidas-y-cierre-automatico.md) | Las acciones de CE, patrones de cierre, referencias cruzadas y control de tiempo | 15 min |

### Prácticas

| Práctica | Qué haces | Duración |
|---|---|:--:|
| [01 — La taxonomía de etiquetas](2-practicas/01-la-taxonomia-de-etiquetas.md) | Etiquetas de grupo en cuatro familias, con color y descripción, y tres priorizadas en `app` | 50 min |
| [02 — El backlog y el hito](2-practicas/02-el-backlog-y-el-hito.md) | Hito `v0.1.0` con fecha, backlog de 12-15 issues creado por API y la exclusividad comprobada | 50 min |
| [03 — Plantillas y acciones rápidas](2-practicas/03-plantillas-y-acciones-rapidas.md) | Plantillas `Bug`, `Feature` y `Default`, lista de tareas, estimación y un issue cerrado desde un commit | 50 min |
| [04 — El tablero del flujo](2-practicas/04-el-tablero-del-flujo.md) | Un tablero con columnas `estado::`, issues movidos de punta a punta y la coherencia comprobada | 50 min |

### Proyecto

La **capa 5** de tu plataforma: el trabajo de `app` está modelado, no improvisado. Detalles en [3-proyecto](3-proyecto/README.md).

---

## ⏱️ Distribución del Tiempo (8 horas)

| Bloque | Tiempo |
|---|:--:|
| Teoría (7 archivos) | 2 h 00 |
| Prácticas (4 × 50 min) | 3 h 20 |
| Proyecto | 2 h 00 |
| Revisión y verificación | 40 min |
| **Total** | **8 h 00** |

> [!TIP]
> Dedica los primeros veinte minutos del proyecto a escribir los títulos de los issues en papel, sin GitLab delante. Un backlog que se escribe directamente en el formulario sale con quince issues que dicen "mejorar X". Uno que se piensa antes sale con quince problemas concretos de tu dominio.

---

## 🧭 Tres herramientas, tres preguntas

Esta semana aparecen tres formas de agrupar issues y se confunden con facilidad, porque las tres "organizan el trabajo". Cada una contesta una pregunta distinta:

| Herramienta | Pregunta que contesta | Un issue puede estar en | Cambia cuando |
|---|---|---|---|
| **Etiqueta** | ¿Qué es esto y cómo de urgente? | Varias, una por familia | Cambia lo que sabemos del issue |
| **Hito** | ¿Para cuándo? | Uno solo | Cambia el plan |
| **Tablero** | ¿Por dónde va? | Una columna | Cambia el trabajo |

El tablero no tiene estado propio: sus columnas **son** etiquetas. Por eso esta semana empieza por la taxonomía y termina por el tablero, y no al revés. Un tablero montado sobre etiquetas improvisadas se rompe en cuanto alguien reetiqueta a mano.

---

## 🎩 Trucos y atajos

| Truco | Cómo |
|---|---|
| Los patrones de cierre solo están en inglés | `Closes #12`, `Fixes #12`, `Resolves #12`, `Implements #12`. `Cierra #12` no hace nada |
| Mover una tarjeta desde el comentario, sin abrir el tablero | `/board_move ~"estado::en-curso"` — solo si el proyecto tiene **un** tablero |
| Reemplazar todas las etiquetas de golpe | `/relabel ~"tipo::bug" ~"prioridad::alta"` |
| Copiar etiquetas e hito de otro issue | `/copy_metadata #12` |
| Atajos de teclado en la página de un issue | `l` etiquetas, `m` hito, `a` asignado, `e` editar descripción, `r` citar la selección |
| Issues sin ninguna etiqueta: el backlog sin triar | `.../projects/$P/issues?labels=None&state=opened \| jq length` |
| Issues **sin** una familia concreta | `.../projects/$P/issues?not[labels]=tipo::bug&state=opened` |
| Cuántos issues abiertos tiene cada etiqueta | `.../projects/$P/labels?with_counts=true \| jq -r '.[] \| "\(.open_issues_count)\t\(.name)"'` |
| Recuento del backlog en una sola llamada | `.../projects/$P/issues_statistics \| jq '.statistics.counts'` |
| Subir una etiqueta de proyecto al grupo | `PUT .../projects/$P/labels/<id>/promote` — los issues que la usan la conservan |
| Un enlace que abre un issue ya rellenado | `.../-/issues/new?issuable_template=Bug&issue[title]=...` |
| Referenciar etiquetas e hitos en Markdown | `~"tipo::bug"` y `%"v0.1.0"` se convierten en enlaces filtrados |
| Ver qué plantillas detecta GitLab | `.../projects/$P/templates/issues \| jq -r '.[].key'` |

---

## 📌 Entregables

1. Etiquetas de grupo en las familias `tipo::`, `prioridad::` y `estado::`, al menos tres en cada una
2. Todas las etiquetas del grupo con descripción
3. Tres etiquetas priorizadas en `app`
4. Hito `v0.1.0` con fecha de vencimiento
5. Backlog de 12 a 15 issues de tu dominio
6. Al menos cinco de ellos en el hito `v0.1.0`
7. Cada issue abierto con exactamente una etiqueta `tipo::`, y ninguno con dos `prioridad::` ni dos `estado::`
8. Al menos un issue con lista de tareas y uno con estimación de tiempo
9. Dos plantillas de issue como mínimo en `.gitlab/issue_templates/`
10. Al menos un issue cerrado
11. Un tablero con tres o más columnas `estado::`

---

## ✅ Verificación

```bash
./scripts/verificar-semana.sh 05
```

Las 17 comprobaciones tienen que pasar. Si alguna falla, la pista te dice en qué práctica y en qué paso se arregla.

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Semana 04 — El repositorio como producto](../week-04-repositorio_como_producto/README.md) | **Semana 05** | Semana 06 — Merge requests y code review |

[← Volver al inicio del bootcamp](../README.md)

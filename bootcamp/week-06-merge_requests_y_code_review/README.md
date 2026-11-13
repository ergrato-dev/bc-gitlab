# Semana 06 — Merge requests y code review

> Un cambio que nadie más ha leído es una apuesta. Esta semana cada cambio en `app` entra por una merge request que nace de un issue, la lee otra identidad, y se fusiona con una estrategia que alguien decidió.

---

## 🎯 Objetivos de la Semana

Al terminar serás capaz de:

- Abrir una merge request que se entiende sola: qué cambia, por qué, qué issue cierra y cómo se prueba
- Llevar un issue del backlog hasta su cierre pasando por rama, merge request, revisión y fusión, sin cerrar nada a mano
- Escribir una plantilla de merge request que obliga a trazar el cambio a un issue
- Revisar con hilos, comentarios sobre líneas concretas y revisiones en borrador, y saber qué deja rastro en el commit y qué no
- Proponer el cambio exacto con una sugerencia de código, de una o varias líneas, y aplicarlas en lote
- Elegir entre *merge commit*, historia semilineal y *fast-forward*, y entre squash sí o no, sabiendo lo que cada combinación hace con la historia
- Leer por API por qué una merge request no se puede fusionar, en una palabra: `detailed_merge_status`
- Decir qué partes de la revisión son de pago (aprobaciones obligatorias, varios revisores, dependencias, trenes de fusión) y qué las sustituye en CE

---

## 📋 Prerrequisitos

- **Semana 05 completada**: backlog en `app` con etiquetas `tipo::` y `estado::`, hito `v0.1.0` y el tablero `Flujo`
- **Las tres identidades de la Semana 03**, en especial `revisor-<dominio>` con Maintainer en `app`
- **Un token de administrador** para crear el token de `revisor`, como en la práctica 03 de la Semana 03
- **Un clon local de `app`** con commits firmados y `npm test` en verde (Semanas 02 y 04)
- **`jq` instalado** y `~/.bc-gitlab` con `GITLAB_URL`, `PROYECTO` y `GITLAB_TOKEN`
- **Perfil de laboratorio**: `base` — ver [perfiles-de-laboratorio](../../docs/perfiles-de-laboratorio.md)

---

## 🗂️ Estructura de la Semana

```
week-06-merge_requests_y_code_review/
├── README.md                  # Este archivo
├── rubrica-evaluacion.md      # Cómo se evalúa
├── checks.json                # Las 16 comprobaciones automáticas
├── 0-assets/                  # Diagramas
├── 1-teoria/                  # 7 archivos, un concepto cada uno
├── 2-practicas/               # 4 prácticas sobre tu instancia
├── 3-proyecto/                # La capa 6 de tu plataforma
├── 4-recursos/                # Libros, vídeos y enlaces
└── 5-glosario/                # Términos de esta semana
```

---

## 📝 Contenidos

### Teoría

| Archivo | Tema | Duración |
|---|---|:--:|
| [01 — La merge request como unidad de cambio](1-teoria/01-la-merge-request-como-unidad-de-cambio.md) | Anatomía, ciclo de vida, borradores, la rama que nace de un issue y las *push options* | 20 min |
| [02 — Plantillas de merge request](1-teoria/02-plantillas-de-merge-request.md) | `.gitlab/merge_request_templates/`, la plantilla `Default` y la trazabilidad al issue | 15 min |
| [03 — La revisión en GitLab](1-teoria/03-la-revision-en-gitlab.md) | Hilos, comentarios en el diff, revisiones en borrador, estados del revisor y aprobación opcional | 20 min |
| [04 — Sugerencias de código](1-teoria/04-sugerencias-de-codigo.md) | El bloque `suggestion`, varias líneas, aplicar en lote y el mensaje del commit | 15 min |
| [05 — Estrategias de fusión](1-teoria/05-estrategias-de-fusion.md) | Los tres métodos, las cuatro opciones de squash y las plantillas del commit | 20 min |
| [06 — Las condiciones para fusionar](1-teoria/06-las-condiciones-para-fusionar.md) | `detailed_merge_status`, hilos resueltos, rebase, conflictos y lo que es de pago | 15 min |
| [07 — El oficio de revisar](1-teoria/07-el-oficio-de-revisar.md) | Qué mirar, el tamaño de una MR, comentarios que se entienden y el reparto autor-revisor | 15 min |

### Prácticas

| Práctica | Qué haces | Duración |
|---|---|:--:|
| [01 — El proyecto preparado para revisar](2-practicas/01-el-proyecto-preparado-para-revisar.md) | Método de fusión, squash, hilos obligatorios, plantillas del commit y de la MR, y el ADR-004 | 50 min |
| [02 — De issue a merge request](2-practicas/02-de-issue-a-merge-request.md) | Un bug del backlog: rama, commit firmado, MR en borrador, revisor asignado y fusión que cierra el issue | 50 min |
| [03 — La revisión con otra identidad](2-practicas/03-la-revision-con-otra-identidad.md) | `revisor` revisa por API: hilo, sugerencia, revisión enviada y aprobación; tú respondes, aplicas y fusionas | 50 min |
| [04 — Historia y conflictos](2-practicas/04-historia-y-conflictos.md) | Dos MRs sobre la misma función: `need_rebase`, `conflict`, rebase local y la historia resultante | 50 min |

### Proyecto

La **capa 6** de tu plataforma: nada entra en `main` sin revisión. Detalles en [3-proyecto](3-proyecto/README.md).

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
> Haz la práctica 03 en dos ventanas: una con tu sesión y otra en privado con nada abierto, donde solo pegas los comandos de `revisor`. Separar físicamente los dos papeles evita el error más común de la semana: contestar como revisor con tu token, o aprobar tu propia merge request sin darte cuenta.

---

## 🧭 Esta semana pide, la siguiente obliga

Esta semana montas el **proceso**: plantillas, revisor, hilos que hay que resolver, una estrategia de fusión. Pero tú, como Owner, todavía puedes hacer `git push` directo a `main` saltándote todo, y una aprobación en CE no bloquea nada.

| Lo que quieres | Semana 06 | Semana 07 |
|---|---|---|
| Que nadie empuje a `main` | Convención en `CONTRIBUTING.md` | Rama protegida sin push para nadie |
| Que alguien revise | Revisor asignado y aprobación opcional | CODEOWNERS y un job que lo comprueba |
| Que los hilos se cierren | Ajuste del proyecto: bloquea la fusión | El mismo ajuste |
| Que el cambio esté trazado | Plantilla `Default` con `Closes #` | Un job que rechaza MRs sin issue |

Esa es la secuencia deliberada: primero se decide cómo se trabaja, y después se hace cumplir. Proteger una rama sin haber decidido el flujo solo produce bloqueos que nadie entiende.

---

## 🎩 Trucos y atajos

| Truco | Cómo |
|---|---|
| Crear la merge request al empujar, sin abrir el navegador | `git push -o merge_request.create -o merge_request.target=main -o merge_request.draft` |
| Saber en una palabra por qué no se puede fusionar | `.../merge_requests/<iid> \| jq -r .detailed_merge_status` |
| Sugerir un cambio que abarca la línea anterior y las dos siguientes | Bloque ` ```suggestion:-1+2 ` en un comentario sobre la línea |
| Pedir revisión desde un comentario | `/assign_reviewer @revisor-<dominio>` |
| Sacar de borrador o volver a meter | `/ready` y `/draft` |
| Enviar la revisión con veredicto desde un comentario | `/submit_review requested_changes` |
| Rebase sin salir de GitLab, cuando no hay conflictos | `/rebase` en un comentario, o `PUT .../merge_requests/<iid>/rebase` |
| Qué issues va a cerrar una MR, antes de fusionarla | `.../merge_requests/<iid>/closes_issues \| jq -r '.[].iid'` |
| Qué MR cerró un issue | `.../issues/<iid>/closed_by \| jq -r '.[].web_url'` |
| Fusionar solo si nadie empujó mientras revisabas | `PUT .../merge` con `sha=<el commit que revisaste>` |
| Ver la MR en local sin crear rama a mano | `git fetch origin merge-requests/<iid>/head:mr-<iid>` |
| Atajos de teclado en el diff | `]` y `[` siguiente y anterior archivo, `n` y `p` siguiente y anterior hilo sin resolver |
| Dar crédito a quien revisó en la historia | `%{reviewed_by}` en la plantilla del commit de squash |

---

## 📌 Entregables

1. Método de fusión `rebase_merge` o `ff`, squash por defecto, hilos obligatorios y borrado de rama al fusionar
2. Plantilla del commit de squash con `%{reviewed_by}`
3. Plantilla `Default.md` de merge request que pide el issue con `Closes #`
4. `ADR-004` en la wiki con la estrategia de fusión
5. Tres merge requests fusionadas, cada una cerrando un issue del backlog
6. Las tres con `revisor-<dominio>` como revisor
7. Al menos una con conversación, una sugerencia aplicada, aprobación de otra identidad y squash
8. Cuatro issues cerrados en total en `app`

---

## ✅ Verificación

```bash
./scripts/verificar-semana.sh 06
```

Las 16 comprobaciones tienen que pasar. Si alguna falla, la pista te dice en qué práctica y en qué paso se arregla.

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Semana 05 — Issues, etiquetas y tableros](../week-05-issues_etiquetas_y_tableros/README.md) | **Semana 06** | Semana 07 — Gobernanza de ramas y aprobaciones |

[← Volver al inicio del bootcamp](../README.md)

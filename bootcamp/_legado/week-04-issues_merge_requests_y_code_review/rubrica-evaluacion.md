# 📊 Rúbrica de Evaluación — Semana 04

**Issues, Merge Requests y Code Review**

---

## Información General

| Campo | Detalle |
|-------|---------|
| **Semana** | 04 — Issues, MRs y Code Review |
| **Puntos totales** | 100 puntos |
| **Peso en el bootcamp** | 8% de la nota final |
| **Modalidad** | Individual |
| **Entrega** | Al final de la semana vía GitLab (URL del proyecto) |

---

## Criterios de Evaluación

### 1. Sistema de Issues (25 puntos)

| Nivel | Descripción | Puntos |
|-------|-------------|--------|
| **Excelente** | 6+ issues creados con: título descriptivo, descripción completa (descripción, criterios de aceptación), labels correctos (tipo + prioridad + área + workflow), milestone asignado, weight definido, assignee asignado. Quick Actions usadas en al menos 2 issues. | 23-25 |
| **Bien** | 4-5 issues con al menos labels de tipo y prioridad, milestone y assignee. Descripción básica pero funcional. | 17-22 |
| **Suficiente** | 2-3 issues con labels básicos. Descripciones mínimas sin criterios de aceptación. | 10-16 |
| **Insuficiente** | Menos de 2 issues o issues sin labels, sin milestone, sin descripción útil. | 0-9 |

**Evidencia requerida:**
- Captura de la lista de issues con labels visibles
- Captura de al menos un issue abierto con su descripción completa

---

### 2. Merge Request Bien Configurado (20 puntos)

| Nivel | Descripción | Puntos |
|-------|-------------|--------|
| **Excelente** | MR con: descripción completa (¿qué hace? + issue relacionado con "Closes #N" + tipo de cambio + cambios realizados + cómo probar + checklist), reviewer asignado, labels, milestone. MR pasó por estado Draft antes de Ready. Opciones del proyecto configuradas (squash, delete branch, threads must resolve). | 18-20 |
| **Bien** | MR con descripción funcional y "Closes #N", reviewer asignado. Al menos un ciclo Draft → Ready. Merge method configurado. | 14-17 |
| **Suficiente** | MR básico vinculado a un issue. Descripción mínima. Sin Draft. | 8-13 |
| **Insuficiente** | MR sin descripción, sin vinculación a issue, o MR no creado. | 0-7 |

**Evidencia requerida:**
- Captura del MR en estado Draft (Merge desactivado)
- Captura del MR en estado Ready (Merge activo, con descripción completa)

---

### 3. Code Review Efectivo (30 puntos)

| Nivel | Descripción | Puntos |
|-------|-------------|--------|
| **Excelente** | Review enviado con "Request changes". Al menos 4 comentarios clasificados con Conventional Comments: [blocker], [nit], [question], [praise]. Al menos una Suggested Change usada. Autor respondió a todos los threads y los resolvió. Reviewer aprobó tras verificar los fixes. | 27-30 |
| **Bien** | Review con "Request changes". Al menos 3 tipos de comentarios. Al menos una sugerencia o fix commit. Todos los threads resueltos. MR aprobado. | 21-26 |
| **Suficiente** | Review con comentarios en línea (al menos 2). Algunos threads resueltos. MR aprobado aunque sea sin ciclo de Request changes. | 12-20 |
| **Insuficiente** | MR mergeado sin código review, o review superficial sin comentarios en línea. | 0-11 |

**Evidencia requerida:**
- Captura del review con comentarios clasificados por tipo
- Captura del MR con "Changes Requested" enviado
- Captura de threads resueltos
- Captura del MR aprobado ("Approved by...")

---

### 4. Merge y Trazabilidad (15 puntos)

| Nivel | Descripción | Puntos |
|-------|-------------|--------|
| **Excelente** | MR mergeado con Squash commits. Mensaje del squash commit es descriptivo e incluye "Closes #N". Issue cerrado automáticamente y verificado via API (`state: closed`). Rama feature eliminada. Historial de main limpio con un único commit. | 14-15 |
| **Bien** | MR mergeado. Issue cerrado (automáticamente o manualmente). Rama eliminada. | 10-13 |
| **Suficiente** | MR mergeado. Issue cerrado manualmente (no automáticamente). | 6-9 |
| **Insuficiente** | MR no mergeado o issue no cerrado. | 0-5 |

**Evidencia requerida:**
- Captura del issue cerrado con referencia al MR
- Output del API verificando `"state": "closed"` en el issue

---

### 5. Issue Board y Gestión Visual (10 puntos)

| Nivel | Descripción | Puntos |
|-------|-------------|--------|
| **Excelente** | Board configurado con 4 columnas (Open, workflow::todo, workflow::in-progress, workflow::review, Closed). Issues distribuidos entre al menos 3 columnas. Board de grupo configurado también. Script de resumen de sprint ejecutado. | 9-10 |
| **Bien** | Board con 3+ columnas. Issues en al menos 2 columnas. | 7-8 |
| **Suficiente** | Board configurado aunque sea con las columnas por defecto. | 4-6 |
| **Insuficiente** | Sin board configurado o board vacío. | 0-3 |

**Evidencia requerida:**
- Captura del board con issues distribuidos en varias columnas

---

## Penalizaciones

| Situación | Penalización |
|-----------|-------------|
| MR sin descripción (solo título) | −10 pts |
| Issues sin labels de ningún tipo | −8 pts |
| MR mergeado sin ningún comentario de review | −15 pts |
| Issue no cerrado tras merge con "Closes #N" | −5 pts |
| Credenciales o tokens en el código committeado | −20 pts (+ obligación de revocar el token) |
| Copiar código de IA sin revisión ni comprensión | −15 pts |

---

## Bonificaciones

| Situación | Bonificación |
|-----------|-------------|
| Templates de issue y MR creados en `.gitlab/` y mergeados | +5 pts |
| Script bash de setup de labels reutilizable y documentado | +3 pts |
| Más de 2 ciclos de review (Request changes → Fix → Approve) | +5 pts |
| Trazabilidad completa verificada via API para todos los issues | +3 pts |

*Puntuación máxima con bonificaciones: 116 pts. Se reporta sobre 100.*

---

## Escala de Calificación Final

| Rango | Calificación | Descripción |
|-------|-------------|-------------|
| 90-100 pts | **A — Excelente** | Dominio completo del flujo GitLab, código revisado exhaustivamente |
| 75-89 pts | **B — Bien** | Flujo correcto con áreas menores de mejora |
| 60-74 pts | **C — Suficiente** | Comprensión básica, ejecución incompleta o superficial |
| 40-59 pts | **D — Insuficiente** | Falta de comprensión de conceptos clave |
| 0-39 pts | **F — Reprobado** | Trabajo no entregado o sin evidencia de aprendizaje |

---

## Cómo Entregar

1. Subir evidencias (screenshots) a la wiki o `4-recursos/` del proyecto en GitLab
2. Compartir la URL del proyecto: `http://localhost/bootcamp-org/backend/api-gateway`
3. Asegurarse de que `maintainer1` tenga acceso para revisar

---

⬅️ **Glosario:** [5-glosario/README.md](./5-glosario/README.md)

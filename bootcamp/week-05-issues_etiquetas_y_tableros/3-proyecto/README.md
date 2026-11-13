# Proyecto Semana 05 — El trabajo modelado

> El trabajo de `app` deja de estar en tu cabeza. Está escrito como problemas, clasificado con un vocabulario que significa algo, planificado contra una fecha y visible en un tablero que dice la verdad.

---

## 🎯 Objetivo

Dejar en pie la **capa 5** de tu plataforma: una taxonomía de etiquetas en el grupo raíz, un backlog de 12 a 15 issues reales de tu dominio, el hito `v0.1.0` con fecha, plantillas que hacen que los issues nuevos nazcan bien clasificados, y un tablero cuyas columnas son el flujo de trabajo.

---

## 📦 Qué añade esta capa

La Semana 04 convirtió `app` en algo que un tercero entiende y arranca. Esta decide **qué se va a hacer con él, en qué orden y para cuándo**, y lo deja escrito de forma que se pueda consultar por API.

| Lo que creas esta semana | Se usa a partir de |
|---|---|
| Taxonomía `tipo::`, `prioridad::`, `estado::` en el grupo raíz | Todas: `infra` (S11) y `ci` (S12) heredan las mismas etiquetas |
| Áreas `area::` en `app` | S07 (CODEOWNERS por área), S17 (enrutado de webhooks) |
| ADR-003 de la taxonomía | S26 (auditoría) |
| Backlog de 12-15 issues | S06 (cada merge request nace de uno), S07, S08 |
| Hito `v0.1.0` con fecha | S08 (la release se asocia al hito y el changelog sale de sus issues) |
| Plantillas `Bug`, `Feature`, `Default` | S06 (plantilla de merge request con la misma lógica) |
| Estimaciones de tiempo | S08 (estimado frente a invertido, en `docs/metricas.md`) |
| Tablero `Flujo` | S06 (la columna `estado::en-revision` se llena de MRs), S08 (tiempo por columna) |
| Comprobación de exclusividad | S11 (pipeline programado), S17 (auditor por API) |

La decisión con más recorrido de esta semana es **la taxonomía**. Las etiquetas se renombran sin coste, pero las familias no: cambiar `prioridad::` de tres valores a cinco dentro de dos meses obliga a reetiquetar cada issue abierto y deja los cerrados con un vocabulario que ya no existe. Piénsala una vez, escríbela en el ADR-003, y no la toques salvo con otro ADR.

---

## ✅ Requisitos verificables

Los comprueba `./scripts/verificar-semana.sh 05` contra la API de tu instancia.

1. El grupo raiz tiene al menos tres etiquetas tipo::
2. El grupo raiz tiene al menos tres etiquetas prioridad::
3. El grupo raiz tiene al menos tres etiquetas estado::
4. Todas las etiquetas del grupo raiz tienen descripcion
5. El proyecto tiene al menos tres etiquetas priorizadas
6. Existe el hito v0.1.0 en el proyecto
7. El hito v0.1.0 tiene fecha de vencimiento
8. El proyecto tiene al menos doce issues
9. Al menos cinco issues estan asignados al hito v0.1.0
10. Cada issue abierto lleva exactamente una etiqueta tipo::
11. Ningun issue abierto lleva dos etiquetas prioridad::
12. Ningun issue abierto lleva dos etiquetas estado::
13. Al menos un issue tiene una lista de tareas en la descripcion
14. Al menos un issue tiene una estimacion de tiempo
15. El proyecto tiene al menos dos plantillas de issue
16. Al menos un issue del proyecto esta cerrado
17. Un tablero del proyecto tiene al menos tres listas de etiquetas estado::

---

## 🎨 Criterios de calidad

Lo que la API confirma que existe pero no puede juzgar:

- **Los títulos describen problemas, no soluciones.** "Un socio con un préstamo vencido puede pedir otro", no "Validar préstamos".
- **Los criterios de aceptación se responden con sí o no.** "El código queda limpio" no es un criterio.
- **El backlog es creíble para tu dominio.** Mezcla de tipos, prioridades repartidas, y ningún issue que sea relleno.
- **El hito es un compromiso, no un cajón.** Entre cinco y ocho issues, los que caben en tres semanas; el resto, sin hito.
- **Cada etiqueta tiene una descripción que dice cuándo se usa**, no que repite su nombre.
- **El ADR-003 explica el sistema**: por qué esas familias, cuáles son exclusivas y cómo se vigila la exclusividad en CE.
- **`Default.md` no clasifica.** No lleva ningún `tipo::`.
- **El tablero refleja el estado real.** Lo que está en `estado::en-curso` se está haciendo de verdad.

---

## 💡 Adaptación a tu dominio

La taxonomía de `tipo::`, `prioridad::` y `estado::` es la misma en todos los dominios. Lo que cambia son las áreas y los issues.

| Dominio | Áreas | Un `tipo::bug` creíble | Una `tipo::feature` creíble |
|---|---|---|---|
| 📖 Biblioteca | `prestamos`, `multas`, `catalogo` | La multa cuenta los domingos | No se puede renovar un préstamo |
| 🏋️ Gimnasio | `reservas`, `socios`, `clases` | Se puede reservar una clase con el cupo lleno | No hay lista de espera para clases llenas |
| 🎥 Cine | `funciones`, `asientos`, `entradas` | Dos personas pueden comprar el mismo asiento | No se puede cambiar una entrada de sesión |
| 💊 Farmacia | `inventario`, `lotes`, `alertas` | Un lote caducado sigue apareciendo como disponible | No hay aviso de lotes que caducan este mes |

El patrón se repite: **los bugs salen de las funciones que ya escribiste en la Semana 02**, porque son las únicas que pueden fallar; las features, de lo que un usuario real echaría de menos.

---

## 🚦 Cómo entregarlo

No hay nada que subir a ningún sitio. El entregable **es el estado de tu grupo, tu proyecto y su backlog**.

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 05
```

```
17 de 17 verificaciones superadas.
```

Si alguna falla, la pista dice en qué práctica y en qué paso se arregla.

---

## 🧯 Errores comunes

| Error | Cómo se detecta | Solución |
|---|---|---|
| Etiquetas creadas en `app` en vez de en el grupo | Fallan los requisitos 1 a 4 aunque las etiquetas se vean en `app` | Promoverlas: `PUT /projects/:id/labels/:label_id/promote` |
| Prioridad puesta en el grupo en vez de en `app` | Falla el requisito 5 | La estrella se pulsa en `app → Manage → Labels` |
| Intentar priorizar por API | `404 Label Not Found` | Solo la UI prioriza etiquetas de grupo |
| Hito sin fecha | Falla el requisito 7 | `PUT /projects/:id/milestones/:milestone_id` con `due_date` |
| Un issue creado a mano sin `tipo::` | Falla el requisito 10 | Clasificarlo o cerrarlo con un comentario |
| `/label` para cambiar la prioridad | Falla el requisito 11 | `/unlabel` y `/label` en el mismo comentario |
| `/label` para cambiar el estado | Falla el requisito 12, y la tarjeta sale en dos columnas | `/board_move` o arrastrar en el tablero |
| Plantillas en una rama sin fusionar | Falla el requisito 15 | Las plantillas se leen de la rama por defecto |
| `Cierra #N` en el commit | Falla el requisito 16: el issue sigue abierto | `Closes #N` |
| Dos tableros, y el bueno no es el primero | El requisito 17 pasa, pero `/board_move` no funciona | Dejar un solo tablero |
| Backlog de "Issue 1" a "Issue 15" | No lo detecta ninguna comprobación; lo detecta la rúbrica | Problemas reales de tu dominio |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Proyecto Semana 04](../../week-04-repositorio_como_producto/3-proyecto/README.md) | **Proyecto Semana 05** | Proyecto Semana 06 |

[← Volver a la Semana 05](../README.md)

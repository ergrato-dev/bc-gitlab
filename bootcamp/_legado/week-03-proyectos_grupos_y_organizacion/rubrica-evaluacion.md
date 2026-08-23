# 📊 Rúbrica de Evaluación — Semana 03

## Información general

| Campo | Valor |
|-------|-------|
| Semana | 03 — Proyectos, Grupos y Organización |
| Porcentaje del total | 8.33% (1/12 semanas) |
| Mínimo para aprobar | 70% en cada evidencia |
| Entrega | Antes del inicio de la Semana 04 |

---

## Evidencia de Conocimiento (30% de la nota)

Evalúa si el estudiante comprende los conceptos teóricos de la semana.

| Concepto | Peso | Criterios |
|----------|------|-----------|
| Tipos de proyectos en GitLab | 20% | Sabe crear proyectos en blanco, desde template y por importación. Entiende la diferencia entre namespace de usuario y de grupo |
| Jerarquía de grupos y subgrupos | 30% | Puede explicar cómo fluye la herencia de permisos. Entiende las restricciones de visibilidad entre niveles |
| Niveles de visibilidad y roles | 30% | Sabe qué puede hacer cada rol (Guest, Reporter, Developer, Maintainer, Owner). Entiende la diferencia entre Private, Internal y Public |
| Protección de ramas | 20% | Puede explicar por qué se protegen ramas, qué restricciones se pueden configurar y cómo se usa CODEOWNERS |

**Formato de evaluación:** Preguntas de reflexión de la teoría o breve entrevista oral.

---

## Evidencia de Desempeño (40% de la nota)

Evalúa si el estudiante puede ejecutar las tareas técnicas de la semana.

| Habilidad | Peso | Criterios |
|-----------|------|-----------|
| Crear proyectos con diferentes configuraciones | 30% | Crea proyectos en blanco, desde template y via API. Puede configurar features del proyecto (habilitar/deshabilitar Issues, Wiki, etc.) |
| Estructurar grupos y subgrupos | 35% | Crea jerarquía de grupos coherente. Puede crear proyectos dentro de los subgrupos correctos. Usa naming conventions apropiadas (kebab-case, nombres descriptivos) |
| Asignar permisos y roles a miembros | 20% | Asigna roles correctos a los miembros. Comprende y puede demostrar que la herencia funciona. Puede dar permisos directos que eleven el rol heredado |
| Configurar reglas de protección de ramas | 15% | Protege `main` correctamente (Nobody push, Maintainers merge). Configura wildcards. Crea y aplica CODEOWNERS |

**Formato de evaluación:** Revisión en vivo de la instancia GitLab del estudiante o capturas de pantalla del proyecto completado.

---

## Evidencia de Producto (30% de la nota)

Evalúa la calidad del proyecto integrador de la semana.

| Criterio | Peso | Nivel 4 (100%) | Nivel 3 (75%) | Nivel 2 (50%) | Nivel 1 (25%) |
|----------|------|----------------|---------------|---------------|---------------|
| Estructura organizacional coherente | 30% | Estructura clara que refleja la arquitectura del sistema. Nombres descriptivos en kebab-case. Profundidad adecuada (≤4 niveles) | Estructura presente pero con algunos nombres inconsistentes o profundidad excesiva | Estructura incompleta: faltan subgrupos o proyectos | Estructura incorrecta: proyectos en namespaces equivocados |
| Permisos correctamente asignados | 25% | Todos los roles asignados según la matriz del proyecto. Herencia funciona. Permisos directos donde corresponde | La mayoría correctos, 1-2 errores menores | Varios permisos incorrectos o faltantes | Permisos sin estructura coherente |
| Rama `main` protegida con reglas de merge | 25% | `main` protegida en todos los proyectos. Push=Nobody, Merge=Maintainers. Branches adicionales según los requisitos | `main` protegida en la mayoría de proyectos (≥8/10) | `main` protegida solo en algunos proyectos | Sin protección de ramas |
| Documentación de la estructura | 20% | `ORGANIZATION.md` completo con diagrama ASCII, matriz de permisos, reglas de ramas y flujo de trabajo | Documentación presente pero incompleta (falta alguna sección) | Solo diagrama de estructura sin explicación | Sin documentación |

**Formato de evaluación:** Revisión del script `verificar-technova.sh` y del `ORGANIZATION.md`.

---

## Penalizaciones

| Situación | Penalización |
|-----------|-------------|
| Grupos o proyectos con nombres en PascalCase o snake_case | -5% sobre la nota total |
| `main` sin protección en más de 2 proyectos | -10% sobre evidencia de producto |
| Token de acceso commiteado al repositorio | -20% sobre la nota total |
| Entrega tardía (por cada día) | -5% sobre la nota total |

---

## Bonificaciones

| Situación | Bonificación |
|-----------|-------------|
| CODEOWNERS implementado y funcionando en al menos 1 proyecto | +5% sobre la nota total |
| Prueba funcional documentada: push rechazado + MR mergeado exitosamente | +5% sobre la nota total |
| Estructura creada completamente via API (script reproducible) | +5% sobre la nota total |

---

## Escala de calificación

| Porcentaje | Calificación |
|-----------|-------------|
| 90-100% | Excelente — dominio completo de los conceptos |
| 80-89% | Muy bueno — comprende y puede aplicar con mínima guía |
| 70-79% | Aprobado — comprende lo fundamental, necesita práctica |
| 60-69% | En riesgo — debe reforzar antes de continuar |
| < 60% | Reprobado — requiere repetir la semana antes de avanzar |

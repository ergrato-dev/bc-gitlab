---
name: "Nueva semana"
description: "Genera el andamiaje completo de una semana del Bootcamp GitLab CE: checks.json, README con las 11 secciones, teoría, prácticas, proyecto, rúbrica, recursos y glosario, en el orden correcto."
argument-hint: "Número de semana (ej: 09) y su tema"
mode: "agent"
---

# Nueva semana — Bootcamp GitLab CE

Genera una semana completa. Lee antes `.github/copilot-instructions.md`: aquí
está el andamiaje, allí están las convenciones y no se duplican.

## Orden de generación

**No lo cambies.** Cada paso condiciona el siguiente.

1. **`checks.json`** — define qué es entregable y, por tanto, qué tienen que
   enseñar las prácticas. Usa el prompt `checks-json`.
2. **`README.md`** — las 11 secciones, con la tabla de tiempos cuadrando en 8 h.
3. **`1-teoria/`** — 7-8 archivos. Usa el prompt `nueva-teoria` para cada uno.
4. **`2-practicas/`** — 4 archivos. Usa el prompt `nueva-practica`.
5. **`3-proyecto/README.md`** — usa el prompt `nuevo-proyecto`.
6. **`rubrica-evaluacion.md`**
7. **`4-recursos/`** y **`5-glosario/`**
8. **`0-assets/`** — SVG. Usa el prompt `svg-diagrama`.
9. Sección de trucos en el README + réplica en `docs/trucos-gitlab.md`.

## Árbol

```
bootcamp/week-NN-tema_en_snake_case/
├── README.md
├── rubrica-evaluacion.md
├── checks.json
├── 0-assets/                       # 2-5 SVG, todos enlazados
├── 1-teoria/01..08-*.md            # 200-300 líneas cada uno
├── 2-practicas/01..04-*.md         # 200-310 líneas cada una
├── 3-proyecto/README.md
├── 4-recursos/
│   ├── ebooks-free/README.md
│   ├── videografia/README.md
│   └── webgrafia/README.md
├── 5-glosario/README.md
└── starter/                        # solo si la semana lleva código
```

## Plantilla del README de semana

```markdown
# Semana NN — Tema

> Dos líneas de gancho: qué sabrás hacer al terminar que hoy no sabes,
> y por qué eso importa en un trabajo real.

## 🎯 Objetivos de la Semana

Al terminar serás capaz de:

- Objetivo verificable 1
- …

## 📋 Prerrequisitos

- Semana NN-1 completada: <estado concreto, no "haber leído">
- <herramienta> instalada — ver [setup-entorno](../../docs/setup-entorno.md)
- Perfil de laboratorio: `base` — ver [perfiles](../../docs/perfiles-de-laboratorio.md)

## 🗂️ Estructura de la Semana

```
week-NN-tema/
├── 1-teoria/     # …
└── …
```

## 📝 Contenidos

### Teoría

| Archivo | Tema | Duración |
|---|---|:--:|
| [01-…](1-teoria/01-….md) | … | 20 min |

### Prácticas

| Práctica | Qué haces | Duración |
|---|---|:--:|
| [01-…](2-practicas/01-….md) | … | 50 min |

### Proyecto

Qué capa añade esta semana. Enlace a `3-proyecto/README.md`.

## ⏱️ Distribución del Tiempo (8 horas)

| Bloque | Tiempo |
|---|:--:|
| Teoría | 2 h 00 |
| Prácticas | 3 h 20 |
| Proyecto | 2 h 00 |
| Revisión y verificación | 40 min |
| **Total** | **8 h 00** |

## 🎩 Trucos y atajos

| Truco | Cómo |
|---|---|

## 📌 Entregables

1. …

## ✅ Verificación

```bash
./scripts/verificar-semana.sh NN
```

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [← Semana NN-1](../week-…/README.md) | **Semana NN** | [Semana NN+1 →](../week-…/README.md) |

[← Volver al inicio del bootcamp](../README.md)
```

## Rúbrica

Cinco secciones: distribución de evidencias, conocimiento (10 preguntas
conceptuales + respuestas argumentadas en `<details>`), desempeño (4 prácticas ×
10 pts), producto (tabla de 60 pts por API + tabla de 40 pts de calidad), y
penalizaciones tipificadas.

Una buena pregunta contrasta dos cosas y pide el porqué. Una mala pide recordar
un flag.

## Las 12 instrucciones

1. **Lee `.github/copilot-instructions.md` antes de escribir nada.**
2. **`checks.json` primero.** Sin él no sabes qué enseñar.
3. **Comprueba cada endpoint y cada comando** contra una instancia real. Es el
   fallo más probable de este repositorio.
4. **7-8 archivos de teoría**, un concepto cada uno, 200-300 líneas.
5. **La tabla de tiempos suma 8 h exactas.** Si no cabe, recorta alcance; no
   maquilles la tabla.
6. **Prerrequisitos concretos y encadenados** a semanas anteriores.
7. **Marca el tier** de toda feature de pago, con su sustituto libre en CE.
8. **Nunca un token con formato válido.** Nunca arte ASCII.
9. **Absorbe de `bootcamp/_legado/`** lo que corresponda según la tabla de
   `docs/decision-renombre-semanas.md`, reescribiéndolo al estándar actual, y
   borra la carpeta de origen cuando quede consumida.
10. **Marca la semana como ✅ y enlázala** en `bootcamp/README.md`.
11. **Pasa los dos agentes de revisión** y los tres skills.
12. **Deja `bash scripts/verificar-enlaces.sh` en verde** antes de cerrar.

$input

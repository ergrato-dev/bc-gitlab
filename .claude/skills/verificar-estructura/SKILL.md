---
name: verificar-estructura
description: Verifica que la estructura del bootcamp (nombres de carpeta week-NN-slug, enlaces relativos, navegación anterior/siguiente, secciones obligatorias del README de semana, SVG huérfanos, checks.json válido, presupuesto de 8 horas) sea consistente. Usar antes de cerrar cualquier cambio que cree, mueva o renombre contenido de una semana, o cuando se sospeche de un enlace roto.
allowed-tools: Bash(bash scripts/*) Bash(grep*) Bash(find*) Bash(jq*) Bash(awk*) Read Grep Glob
---

# Verificar estructura de una semana

Dos capas: lo que el script detecta solo, y lo que hay que mirar a mano.

## 1. Lo que detecta el script

```bash
bash scripts/verificar-enlaces.sh
```

Cubre cinco cosas: nombres de carpeta con el formato `week-NN-slug`, enlaces
relativos que resuelven, presencia de la sección Navegación, SVG de `0-assets/`
enlazados desde algún `.md`, y `checks.json` parseable.

Tiene que salir en verde. Si reporta un enlace roto que en realidad es una URL
con paréntesis anidados, es el falso positivo conocido y está documentado en el
propio script; cualquier otra cosa es un fallo real.

## 2. Lo que el script no ve

### Las 11 secciones del README de semana, en orden

```bash
grep -n '^#\{1,2\} ' bootcamp/week-NN-*/README.md
```

Orden esperado: título, gancho, `🎯 Objetivos de la Semana`, `📋 Prerrequisitos`,
`🗂️ Estructura de la Semana`, `📝 Contenidos`, `⏱️ Distribución del Tiempo`,
[sección temática opcional], `🎩 Trucos y atajos`, `📌 Entregables`,
`✅ Verificación`, `🔗 Navegación`.

**La que falta con más frecuencia es la de Trucos.** Míralaprimero.

### El presupuesto de 8 horas

La tabla de `⏱️ Distribución del Tiempo` tiene que sumar **8 h exactas**. Suma
las duraciones a mano y compara. Si suma 9 o 10, la semana está sobrecargada:
repórtalo, no lo maquilles.

Comprueba también que las duraciones de las tablas de teoría y prácticas de la
sección `📝 Contenidos` sean coherentes con esa distribución.

### La cadena de navegación

Cada `README.md` de semana enlaza a la anterior y a la siguiente. La semana 01 no
tiene anterior; la 26 no tiene siguiente. Comprueba que ninguna apunte a una
semana que todavía no existe.

Profundidad de `../` según dónde estés:

| Desde | A la raíz del repo | A otra semana |
|---|---|---|
| `bootcamp/week-NN/README.md` | `../../README.md` | `../week-MM-slug/README.md` |
| `bootcamp/week-NN/1-teoria/x.md` | `../../../README.md` | `../../week-MM-slug/README.md` |
| `bootcamp/week-NN/4-recursos/videografia/README.md` | `../../../../README.md` | — |

### Sincronía de las tres tablas maestras

La malla de 26 filas aparece en `README.md`, en
`.github/copilot-instructions.md` y en `docs/decision-renombre-semanas.md`. Los
26 slugs tienen que ser idénticos en las tres y coincidir con las carpetas reales:

```bash
find bootcamp -maxdepth 1 -type d -name 'week-*' | sed 's|.*/||' | sort
grep -oE 'week-[0-9]{2}-[a-z0-9_]+' README.md | sort -u
grep -oE 'week-[0-9]{2}-[a-z0-9_]+' .github/copilot-instructions.md | sort -u
grep -oE 'week-[0-9]{2}-[a-z0-9_]+' docs/decision-renombre-semanas.md | sort -u
```

### Coherencia `checks.json` ↔ `3-proyecto/README.md`

Cada `descripcion` del `checks.json` tiene que aparecer **literal** como
requisito verificable en el README del proyecto. Si difieren aunque sea en una
palabra, el alumno no sabe qué le falta cuando una comprobación falla.

```bash
jq -r '.checks[].descripcion' bootcamp/week-NN-*/checks.json
grep -A30 'Requisitos verificables' bootcamp/week-NN-*/3-proyecto/README.md
```

Comprueba también que cada `pista` apunte a un archivo que exista de verdad
dentro de esa semana.

### Trucos replicados

Cada truco del README de la semana tiene que estar en `docs/trucos-gitlab.md`,
en la sección de esa semana. Si difieren, gana el README (eso lo arregla el
skill `sincronizar-trucos`, no este).

### Estado en el índice

`bootcamp/README.md` tiene que marcar la semana como ✅ y enlazarla. Una semana
escrita que sigue en ⬜ es un fallo de cierre.

### Restos del legado

Si la semana absorbió contenido de `bootcamp/_legado/`, esa carpeta de origen
debería estar ya borrada. Compruébalo contra la tabla de correspondencia de
`docs/decision-renombre-semanas.md`.

## Salida

Lista de problemas, uno por línea, con ruta y qué falta. Sin prosa.

Si no hay ninguno: `OK: estructura consistente.`

**No inventes hallazgos para parecer exhaustivo.**

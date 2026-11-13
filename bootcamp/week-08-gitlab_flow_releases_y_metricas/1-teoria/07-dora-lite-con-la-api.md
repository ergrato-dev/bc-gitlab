# DORA-lite con la API

> Las métricas DORA de GitLab son de Ultimate. Los datos con los que se calculan, no: están en la API de CE, con fecha y hora. Cincuenta líneas de bash y `jq` sacan los cuatro números, y una página de Markdown dice exactamente qué significan.

---

## 🎯 Objetivos

- Leer `scripts/metricas.sh` y saber de qué endpoint y de qué campos sale cada métrica
- Calcular duraciones y medianas con `jq` a partir de las fechas de la API
- Escribir `docs/metricas.md` con la definición, la fuente y los límites de cada métrica
- Saber qué cambiará en el script cuando haya despliegues y pipelines

---

## 1. Qué problema resuelve

La teoría [06](06-metricas-dora.md) decidió qué aproxima cada métrica en `app`. Falta calcularlo de forma que:

- Cualquiera pueda repetirlo y obtener el mismo número.
- La definición esté en un sitio que se revisa por merge request, no en la cabeza de quien lo calculó.
- Pase a ser un job programado (Semana 11) sin reescribirlo.

---

## 2. Cómo funciona

### 2.1 El script

`scripts/metricas.sh` en `app`:

```bash
#!/usr/bin/env bash
# DORA-lite de app: las cuatro métricas, calculadas con la API v4 de CE.
# Las definiciones y sus límites están en docs/metricas.md.
# Uso: scripts/metricas.sh [días]      (por defecto, los últimos 30)
set -euo pipefail

API=${CI_API_V4_URL:-$GITLAB_URL/api/v4}
P=${CI_PROJECT_ID:-$(printf '%s' "$PROYECTO" | jq -sRr @uri)}
DIAS=${1:-30}
DESDE=$(date -u -d "-$DIAS days" +%FT%TZ)

api() { curl -sf -H "PRIVATE-TOKEN: ${METRICAS_TOKEN:-$GITLAB_TOKEN}" "$API/projects/$P/$1" \
    || { echo "La API no respondió a $1" >&2; return 1; }; }
# ponytail: una página de 100 por recurso; paginar cuando app pase de 100 en la ventana

# Funciones jq comunes: segundos de una fecha UTC de la API, mediana y horas legibles
JQ_LIB='def seg: .[0:19] + "Z" | fromdateiso8601;
        def mediana: sort | if length == 0 then null else .[length / 2 | floor] end;
        def horas: if . == null then "sin datos" else "\(. / 360 | round / 10) h" end;'

releases=$(api "releases?order_by=released_at&sort=desc&per_page=100")
mrs=$(api "merge_requests?state=merged&target_branch=main&updated_after=$DESDE&per_page=100")
bugs=$(api "issues?state=closed&labels=tipo::bug&updated_after=$DESDE&per_page=100")
for r in "$releases" "$mrs" "$bugs"; do
  [ "$(jq length <<<"$r")" -lt 100 ] || echo "Aviso: una consulta devolvió 100 resultados; puede faltar algo" >&2
done

# 1. Frecuencia de entrega: releases sin pre-release publicadas en la ventana
jq -r --arg d "$DESDE" --argjson dias "$DIAS" '
  [.[] | select(.upcoming_release | not) | select(.released_at >= $d) | select(.tag_name | test("-") | not)]
  | "Frecuencia de entrega:   \(length * 70 / $dias | round / 10) releases por semana (n = \(length))"' <<<"$releases"

# 2. Tiempo de entrega: de la creación a la fusión de cada merge request en main
jq -r --arg d "$DESDE" "$JQ_LIB"'
  [.[] | select(.merged_at >= $d) | (.merged_at | seg) - (.created_at | seg)]
  | "Tiempo de entrega:       mediana \(mediana | horas) (n = \(length))"' <<<"$mrs"

# 3. Tasa de fallo: releases de la ventana que tuvieron un parche (existe vX.Y.Z+1)
jq -r --arg d "$DESDE" '
  [.[].tag_name] as $todas
  | [.[] | select(.released_at >= $d) | .tag_name | select(test("-") | not)] as $ventana
  | [$ventana[] | capture("^(?<base>v?[0-9]+\\.[0-9]+\\.)(?<z>[0-9]+)$")
     | "\(.base)\(.z | tonumber + 1)" | select(IN($todas[]))] as $falladas
  | "Tasa de fallo:           "
    + (if ($ventana | length) > 0 then "\(($falladas | length) * 100 / ($ventana | length) | round) %" else "sin datos" end)
    + " (\($falladas | length) de \($ventana | length) releases con parche)"' <<<"$releases"

# 4. Tiempo de restauración: de la apertura al cierre de cada issue tipo::bug
jq -r --arg d "$DESDE" "$JQ_LIB"'
  [.[] | select(.closed_at >= $d) | (.closed_at | seg) - (.created_at | seg)]
  | "Tiempo de restauración:  mediana \(mediana | horas) (n = \(length))"' <<<"$bugs"
```

Ejecutado en `app` tras la práctica 04:

```
Frecuencia de entrega:   0.5 releases por semana (n = 2)
Tiempo de entrega:       mediana 2.4 h (n = 6)
Tasa de fallo:           50 % (1 de 2 releases con parche)
Tiempo de restauración:  mediana 0.6 h (n = 1)
```

Tus números serán otros. Lo que importa es poder explicar cada uno.

### 2.2 De dónde sale cada número

| Métrica | Endpoint | Campos | Filtro |
|---|---|---|---|
| Frecuencia de entrega | `releases?order_by=released_at&sort=desc` | `released_at`, `tag_name`, `upcoming_release` | En la ventana, sin pre-release, no futuras |
| Tiempo de entrega | `merge_requests?state=merged&target_branch=main` | `created_at`, `merged_at` | Fusionadas en la ventana |
| Tasa de fallo | `releases` | `tag_name`, `released_at` | Una release falló si existe la misma con `PARCHE + 1` |
| Tiempo de restauración | `issues?state=closed&labels=tipo::bug` | `created_at`, `closed_at` | Cerrados en la ventana |

`updated_after` reduce lo que devuelve la API, pero no filtra por la fecha que importa: una merge request fusionada hace meses y editada ayer pasaría. Por eso cada métrica vuelve a filtrar por su propio campo (`merged_at`, `closed_at`, `released_at`) dentro de `jq`.

### 2.3 Fechas y duraciones en `jq`

La API devuelve fechas UTC con milésimas: `2026-11-13T21:41:17.123Z`. `fromdateiso8601` no acepta las milésimas, así que `seg` se queda con los 19 primeros caracteres y añade la `Z`:

```bash
echo '"2026-11-13T21:41:17.123Z"' | jq '.[0:19] + "Z" | fromdateiso8601'   # 1794606077
```

Una duración es la resta de dos `seg`. Las comparaciones con la ventana (`.merged_at >= $d`) se hacen como texto: funciona porque las dos fechas son ISO 8601 en UTC, y en ese formato el orden alfabético es el cronológico.

`mediana` ordena y toma el elemento central. Con un número par de valores toma el superior de los dos centrales: con tan pocos datos, la diferencia no cambia ninguna decisión.

### 2.4 La tasa de fallo, paso a paso

```
$todas     = ["v0.1.0", "v0.1.1"]
$ventana   = ["v0.1.0", "v0.1.1"]
capture    → {base: "v0.1.", z: "0"} → "v0.1.1" ∈ $todas → falló
           → {base: "v0.1.", z: "1"} → "v0.1.2" ∉ $todas → no falló
$falladas  = ["v0.1.1"]   → 1 de 2 → 50 %
```

Busca el parche en **todas** las releases, no solo en las de la ventana: si la `v0.1.0` salió hace 31 días y su parche hace 2, la `v0.1.0` cae fuera y el parche no cuenta como fallo de nadie. Es una imprecisión en el borde de la ventana, y con ventanas de 30 días se acepta.

### 2.5 `docs/metricas.md`

El script calcula; el documento dice qué se está calculando. Sin el documento, `50 %` no significa nada.

```markdown
# Métricas de flujo de app (DORA-lite)

Calculadas con `scripts/metricas.sh` sobre la API v4 de GitLab CE. Ventana: 30 días. Estadístico: mediana.

## Frecuencia de entrega
- **Definición**: releases publicadas por semana, sin pre-release.
- **Fuente**: `releases`, campo `released_at`.
- **Límite**: una release no es un despliegue. Cambia en la Semana 14.

## Tiempo de entrega
- **Definición**: de la apertura a la fusión de cada merge request en `main`.
- **Fuente**: `merge_requests`, `created_at` y `merged_at`.
- **Límite**: no cuenta el trabajo antes de abrirla ni la espera hasta la release.

## Tasa de fallo de cambios
- **Definición**: releases que necesitaron un parche, entre releases publicadas.
- **Fuente**: `releases`, `tag_name`.
- **Límite**: un fallo que nadie parcheó no cuenta.

## Tiempo de restauración
- **Definición**: de la apertura al cierre de cada issue `tipo::bug`.
- **Fuente**: `issues`, `created_at` y `closed_at`.
- **Límite**: el issue se cierra al fusionar en `main`, antes de que el parche se publique.

## Mediciones

| Fecha | Frecuencia | Tiempo de entrega | Tasa de fallo | Restauración | Contexto |
|---|---|---|---|---|---|
| 2026-11-13 | 0.5 / semana | 2.4 h | 50 % (1 de 2) | 0.6 h | Primera medición: v0.1.0 y v0.1.1 |
```

La columna **Contexto** es la que hace útil la tabla dentro de seis meses.

---

## 3. Cómo se configura

| Variable | Para qué | Por defecto |
|---|---|---|
| `GITLAB_URL`, `PROYECTO` | La instancia y el proyecto | `~/.bc-gitlab` |
| `METRICAS_TOKEN` | Un token propio con `read_api` | `GITLAB_TOKEN`, solo para la primera ejecución |
| `CI_API_V4_URL`, `CI_PROJECT_ID` | Lo mismo, dentro de un job | Las pone GitLab |
| Primer argumento | Días de la ventana | `30` |

Las métricas solo leen, así que un token con `read_api` basta. Igual que `scripts/gobernanza.sh` de la Semana 07, el script prefiere `CI_*` cuando existen: en la Semana 11 será un pipeline programado sin cambiar una línea.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Filtrar solo con `updated_after` | Cuenta merge requests antiguas editadas hace poco | Filtrar además por `merged_at`, `closed_at` o `released_at` |
| Media en vez de mediana | Una merge request olvidada distorsiona todo | Mediana |
| Números sin definición | Cada lector entiende otra cosa | `docs/metricas.md` en el mismo repositorio |
| Sobrescribir la medición anterior | Se pierde la tendencia, que es lo único útil | Una fila nueva por medición |
| Un token de escritura para leer métricas | Si se filtra, permite mucho más que leer | `read_api` |
| Paginar "por si acaso" desde el primer día | Código que nadie necesita todavía | Una página de 100, marcada con `ponytail:` para cuando haga falta |

---

## 5. Trucos

- **Otra ventana**: `bash scripts/metricas.sh 7` para la última semana.
- **Las merge requests que más tardaron**: `.../merge_requests?state=merged | jq -r '.[] | "\(.iid) \(.created_at) \(.merged_at)"' | sort -k3`.
- **Medir la semana pasada sin esperar**: la API filtra por fechas, no por "ahora", así que puedes medir cualquier ventana pasada cambiando `DESDE`.

---

## 📚 Recursos Adicionales

- [Merge requests API](https://docs.gitlab.com/api/merge_requests/) — `created_at`, `merged_at` y los filtros por fecha
- [Issues API](https://docs.gitlab.com/api/issues/) — `labels`, `state` y `closed_at`
- [Releases API](https://docs.gitlab.com/api/releases/) — `order_by=released_at` y `upcoming_release`
- [jq Manual: dates](https://jqlang.org/manual/#dates) — `fromdateiso8601` y sus límites

---

## ✅ Checklist de Verificación

- [ ] Sabes qué endpoint y qué campos usa cada métrica
- [ ] Sabes por qué se vuelve a filtrar por fecha dentro de `jq`
- [ ] Sabes por qué `seg` recorta las milésimas
- [ ] Sabes cuándo una release cuenta como fallo
- [ ] Sabes qué tiene que decir `docs/metricas.md` de cada métrica

---

[← Anterior: Las métricas DORA](06-metricas-dora.md) · [Volver a la Semana 08](../README.md)

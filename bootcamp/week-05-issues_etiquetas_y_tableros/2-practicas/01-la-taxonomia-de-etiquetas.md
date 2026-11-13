# Práctica 01 — La taxonomía de etiquetas

> Cuatro familias en el grupo raíz, cada una con su pregunta, su color y su criterio escrito. Y la prioridad del proyecto, puesta donde la API no llega.

**Duración estimada**: 50 min
**Prerrequisitos**: Semana 04 completada · Teorías [02](../1-teoria/02-taxonomia-de-etiquetas.md) y [03](../1-teoria/03-etiquetas-priorizadas-y-exclusividad.md) leídas

---

## Contexto

Antes de escribir un solo issue, hace falta el vocabulario con el que se van a clasificar. Si la taxonomía llega después, los primeros quince issues se etiquetan a ojo y luego hay que reetiquetarlos.

La taxonomía vive en el **grupo raíz** `plataforma-<tu-dominio>`, para que `app`, `infra` y `ci` hablen el mismo idioma. Las áreas, que dependen del código, viven en `app`.

---

## Paso 0: Preparar el terreno

**Por qué**: las variables de siempre, más la ruta del grupo raíz codificada, que es la primera parte de `PROYECTO`.

```bash
source ~/.bc-gitlab

export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
export G=$(printf '%s' "${PROYECTO%%/*}" | jq -sRr @uri)

echo "grupo: ${PROYECTO%%/*}  proyecto: $PROYECTO"
```

**Verifica**:

```bash
curl -s -H "$H" "$API/groups/$G" | jq -r '.full_path'
# plataforma-biblioteca
```

---

## Paso 1: Inventario de lo que ya hay

**Por qué**: GitLab no crea etiquetas por defecto en un proyecto nuevo, pero en la Semana 01 o 03 pudiste crear alguna de prueba. Una etiqueta suelta que sobrevive al diseño de la taxonomía es la primera grieta.

```bash
echo "== grupo"
curl -s -H "$H" "$API/groups/$G/labels?per_page=100" | jq -r '.[].name'

echo "== solo del proyecto"
curl -s -H "$H" "$API/projects/$P/labels?include_ancestor_groups=false&per_page=100&with_counts=true" \
  | jq -r '.[] | "\(.open_issues_count)\t\(.name)"'
```

**Verifica**: las dos listas están vacías, o sabes qué es cada etiqueta que aparece. Si hay alguna de prueba con cero issues, bórrala:

```bash
curl -s --request DELETE "$API/projects/$P/labels/<nombre-o-id>" -H "$H" -o /dev/null -w '%{http_code}\n'
# 204
```

---

## Paso 2: Diseñar en papel

**Por qué**: el diseño se hace antes de crear nada, porque renombrar después es barato pero reetiquetar no. Rellena esta tabla con los valores de tu dominio; las tres primeras familias son fijas, la cuarta es tuya.

| Familia | Pregunta | Valores |
|---|---|---|
| `tipo::` | ¿Qué clase de trabajo es? | `bug`, `feature`, `mantenimiento`, `docs` |
| `prioridad::` | ¿Cuánto cuesta no hacerlo? | `alta`, `media`, `baja` |
| `estado::` | ¿Por dónde va? | `preparado`, `en-curso`, `en-revision`, `bloqueado` |
| `area::` | ¿Qué parte de **tu** producto toca? | Dos o tres, según las funciones de tu app |

Para `area::`, mira las funciones que escribiste en la Semana 02. Dominio biblioteca: `area::prestamos`, `area::multas`, `area::catalogo`.

**Verifica**: cada valor de la tabla se puede explicar en una frase que empieza por "se usa cuando…". Si alguno no, sobra.

---

## Paso 3: Escribir el catálogo como datos

**Por qué**: crear dieciséis etiquetas a mano es una tarde de clics y errores de color. Como datos, se revisan de un vistazo, se crean de una vez y se pueden repetir en otra instancia.

Crea el archivo **fuera del repositorio** —es una herramienta de esta práctica, no parte del producto—:

```bash
cat > /tmp/etiquetas-grupo.tsv <<'EOF'
tipo::bug	#1F75CB	Algo que funcionaba, o debería, y no lo hace. Incluye pasos para reproducirlo
tipo::feature	#5BA4E5	Capacidad nueva que un usuario puede notar
tipo::mantenimiento	#8FC1EE	Cambio interno sin efecto visible: dependencias, refactor, deuda
tipo::docs	#C2DDF6	Solo documentación: README, wiki, comentarios
prioridad::alta	#DD2B0E	Bloquea a un usuario o a otro trabajo. Se empieza antes que cualquier media
prioridad::media	#E9765A	Entra en el hito actual si cabe
prioridad::baja	#F2B7A8	Mejora deseable. Puede esperar un hito entero sin consecuencias
estado::preparado	#9DD4AE	Triado y con criterios de aceptación. Cualquiera puede empezarlo
estado::en-curso	#52B87A	Alguien lo está haciendo ahora. Tiene asignado
estado::en-revision	#108548	El cambio está hecho y espera revisión
estado::bloqueado	#554488	Depende de algo externo. La descripción dice de qué y desde cuándo
EOF
```

Los separadores son **tabuladores**. Si tu editor los convierte en espacios, el paso siguiente falla.

**Verifica**:

```bash
awk -F'\t' 'NF != 3 { print "línea " NR " mal formada" }' /tmp/etiquetas-grupo.tsv
# (sin salida)
```

---

## Paso 4: Crear las etiquetas en el grupo raíz

**Por qué**: en el grupo, y no en el proyecto, para que `infra` y `ci` hereden exactamente las mismas, con el mismo `id`. Si las creas en `app`, tendrás que promoverlas una a una.

**Con la UI**: `Grupo raíz → Manage → Labels → New label`, una por línea del archivo.

**Con la API**:

```bash
while IFS=$'\t' read -r nombre color descripcion; do
  curl -s --request POST "$API/groups/$G/labels" -H "$H" \
    --data-urlencode "name=$nombre" \
    --data-urlencode "color=$color" \
    --data-urlencode "description=$descripcion" \
    | jq -r '"\(.id // "ERROR")\t\(.name // .message)"'
done < /tmp/etiquetas-grupo.tsv
```

Si una línea dice `ERROR` con *Label already exists*, ya la tenías: no pasa nada, sigue.

**Verifica**:

```bash
curl -s -H "$H" "$API/groups/$G/labels?per_page=100" \
  | jq -r 'group_by(.name | split("::")[0])[] | "\(.[0].name | split("::")[0]): \(length)"'
# estado: 4
# prioridad: 3
# tipo: 4
```

Y que ninguna se quedó sin descripción:

```bash
curl -s -H "$H" "$API/groups/$G/labels?per_page=100" \
  | jq 'all(.[]; (.description // "") | length > 0)'
# true
```

---

## Paso 5: Las áreas, en el proyecto

**Por qué**: un área describe una parte del código de `app`. En `infra` no significa nada, así que no se hereda.

```bash
for area in prestamos multas catalogo; do       # ← cambia por las de tu dominio
  curl -s --request POST "$API/projects/$P/labels" -H "$H" \
    --data-urlencode "name=area::$area" \
    --data-urlencode "color=#666666" \
    --data-urlencode "description=Código de $area en src/" \
    | jq -r '"\(.id)\t\(.name)"'
done
```

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/labels?include_ancestor_groups=false&per_page=100" \
  | jq -r '.[] | select(.name | startswith("area::")) | .name'
```

> [!NOTE]
> Las áreas no son exclusivas: un issue puede tocar `area::prestamos` y `area::multas`. Por eso el autograding no comprueba nada sobre ellas, y por eso no van en el tablero.

---

## Paso 6: Priorizar la familia `prioridad::` en `app`

**Por qué**: para que "ordenar por prioridad de etiqueta" ponga primero los issues de prioridad alta. Y porque es el único paso de esta semana que **no se puede hacer por API**: el `PUT` de etiquetas del proyecto no encuentra las heredadas del grupo (teoría [03](../1-teoria/03-etiquetas-priorizadas-y-exclusividad.md), sección 2.3).

Compruébalo tú mismo antes de ir a la UI:

```bash
curl -s --request PUT "$API/projects/$P/labels/prioridad::alta" -H "$H" \
  --data-urlencode "priority=0" | jq -r '.message // "funcionó"'
# 404 Label Not Found
```

**Con la UI**: `app → Manage → Labels`. En la lista *Other labels*, pulsa la estrella de `prioridad::alta`, `prioridad::media` y `prioridad::baja`. Las tres suben a *Prioritized labels*. Arrástralas para que queden en ese orden: alta arriba.

Si en tu equipo un fallo va siempre antes que una funcionalidad, prioriza también `tipo::bug` y ponla la primera. Es una decisión; escríbela en la wiki si la tomas.

**Verifica**, por API, que es como lo lee el autograding:

```bash
curl -s -H "$H" "$API/projects/$P/labels?per_page=100" \
  | jq -r 'map(select(.priority != null)) | sort_by(.priority)[] | "\(.priority)\t\(.name)"'
# 0	prioridad::alta
# 1	prioridad::media
# 2	prioridad::baja
```

Los números exactos pueden ser otros; lo que importa es el **orden**.

---

## Paso 7: Documentar la taxonomía en la wiki

**Por qué**: las descripciones explican cada etiqueta, pero no explican el sistema: por qué hay cuatro familias, cuáles son exclusivas, quién puede crear una etiqueta nueva. Eso es una decisión, y las decisiones van a la wiki (Semana 04).

Añade a la wiki de `app` una página `ADR-003 — Taxonomía de etiquetas` con la plantilla de ADR de la Semana 04. Lo mínimo:

- **Contexto**: CE no impone exclusividad en las etiquetas con `::`
- **Decisión**: las cuatro familias, cuáles son exclusivas, que viven en el grupo raíz y que las áreas viven en el proyecto
- **Consecuencias**: la exclusividad se vigila por API; renombrar una etiqueta obliga a revisar las plantillas

```bash
curl -s -H "$H" "$API/projects/$P/wikis" | jq -r '.[].slug' | grep -i adr
```

**Verifica**: la lista incluye `ADR-003…`. Y enlaza la página desde la barra lateral `_sidebar`.

---

## ✅ Resultado

- [ ] El grupo raíz tiene cuatro `tipo::`, tres `prioridad::` y cuatro `estado::`
- [ ] Todas tienen color de su gama y descripción con criterio de uso
- [ ] `app` tiene dos o tres `area::` propias
- [ ] La familia `prioridad::` está priorizada en `app`, en su orden
- [ ] Has visto con tus ojos el `404` al intentar priorizar por API
- [ ] La wiki tiene el ADR de la taxonomía

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 05
```

Esta práctica cubre cinco comprobaciones: las tres familias del grupo, las descripciones y las etiquetas priorizadas.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `400` *Color is invalid* | Falta la `#` o el código no tiene seis cifras | `#1F75CB`, con almohadilla |
| La `#` del color llega vacía | Se envió con `-d` y el shell la interpretó | `--data-urlencode`, como en el ejemplo |
| `409` *Label already exists* | La etiqueta ya estaba, en el grupo o en el proyecto | Seguir; o borrar la del proyecto y quedarse con la del grupo |
| `403` al crear en el grupo | Tu usuario no es Owner o Maintainer del grupo raíz | En el laboratorio eres `root`; revisa que el token sea el tuyo |
| El `while read` crea etiquetas con el color en el nombre | El archivo tiene espacios en vez de tabuladores | `cat -A /tmp/etiquetas-grupo.tsv` debe mostrar `^I` entre campos |
| `etiquetas-priorizadas` falla | Se priorizaron en otro proyecto, o en el grupo | La estrella se pulsa en `app → Manage → Labels` |
| El campo `priority` no aparece | Se consultó `groups/:id/labels` | La prioridad solo sale en `projects/:id/labels` |
| `etiquetas-con-descripcion` falla | Una etiqueta del grupo quedó sin descripción | `PUT /groups/:id/labels/:label_id` con `description` |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| — | **Práctica 01** | [Práctica 02 — El backlog y el hito](02-el-backlog-y-el-hito.md) |

# Práctica 03 — Cirugía sobre la historia

> Vas a ensuciar la historia a propósito y luego dejarla presentable: unir, reescribir, dividir, reordenar y comprobar que ninguna firma se quedó por el camino.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 02 completada · Teorías [03](../1-teoria/03-reescribir-la-historia.md) y [04](../1-teoria/04-mover-y-recuperar-cambios.md) leídas

---

## Contexto

Esta es la única semana del bootcamp en la que se permite reescribir `main`: nadie más ha clonado tu repositorio y no hay nada que romper. A partir de la Semana 07, `main` queda protegida y esto deja de ser posible por diseño.

Aprovéchalo para practicar la operación completa sobre una rama de trabajo, y termina integrándola en `main` **sin generar un commit de fusión**, que es lo que mantiene la historia lineal que exige la semana.

> [!WARNING]
> Vas a reescribir commits. Antes de cada operación de este tipo, deja una marca del punto de partida: cuesta 41 bytes y ahorra el rescate. En el paso 3 se crea una, y si algo se tuerce en cualquier momento:
>
> ```bash
> git rebase --abort                       # si estás a media operación
> git reset --hard respaldo/antes-de-la-cirugia   # si ya terminó y salió mal
> ```
>
> Y si ni eso: `git reflog` tiene todos los sitios donde has estado (teoría 04).

---

## Paso 1: Ensuciar la historia a propósito

**Por qué**: hace falta material sobre el que operar, y conviene que se parezca a lo que sale de una tarde real de trabajo: un commit útil, un arreglo, un `wip` y una errata.

```bash
git switch -c feat/reservas
```

Cuatro commits, en este orden:

```bash
# 1. La funcionalidad, a medias.
cat >> src/prestamos.ts <<'EOF'

/** Dias que una reserva se mantiene viva antes de caducar. */
export const DIAS_DE_RESERVA = 2;

export function reservaVigente(diasDesdeLaReserva: number): boolean {
  return diasDesdeLaReserva < DIAS_DE_RESERVA;
}
EOF
git commit -am "feat(reservas): añadir la vigencia de una reserva"

# 2. Un wip que no dice nada.
cat >> src/prestamos.test.ts <<'EOF'

test("una reserva de hoy sigue vigente", () => {
  assert.equal(reservaVigente(0), true);
});
EOF
git commit -am "wip"

# 3. El arreglo del import que faltaba.
sed -i 's/import { calcularMulta, puedePrestar, ejemplaresDisponibles, MULTA_POR_DIA_CENTIMOS }/import { calcularMulta, puedePrestar, ejemplaresDisponibles, reservaVigente, MULTA_POR_DIA_CENTIMOS }/' src/prestamos.test.ts
git commit -am "arreglo el import"

# 4. Una errata en un comentario.
sed -i 's/Dias que una reserva se mantiene viva/Dias naturales que una reserva se mantiene viva/' src/prestamos.ts
git commit -am "typo"
```

**Verifica** el desastre:

```bash
npm test
git log --oneline -4
# 7b2a4e6 typo
# c4e8b1a arreglo el import
# 3a9d2f7 wip
# 9d1f3c5 feat(reservas): añadir la vigencia de una reserva
```

Cuatro commits, dos de los cuales no pasan sus propios tests si los pruebas por separado, y tres títulos que no significan nada. Así es como llega el trabajo de verdad.

---

## Paso 2: El arreglo hecho bien, con `--fixup`

**Por qué**: los tres commits sucios del paso 1 son la forma equivocada. Esta es la correcta: cuando corriges algo de un commit anterior, se lo dices a Git y él lo coloca solo. Vas a hacer las dos cosas para comparar.

Localiza el commit al que pertenece el arreglo:

```bash
BASE=$(git log --format=%H --grep='^feat(reservas)' -1)
git log --oneline -1 "$BASE"
```

Corrige algo de ese commit y compromételo como arreglo suyo:

```bash
# Una reserva con dias negativos no tiene sentido: el commit original no lo contemplaba.
sed -i 's|  return diasDesdeLaReserva < DIAS_DE_RESERVA;|  return diasDesdeLaReserva >= 0 \&\& diasDesdeLaReserva < DIAS_DE_RESERVA;|' src/prestamos.ts
git commit -a --fixup "$BASE"
```

**Verifica** el título que ha generado Git:

```bash
git log --oneline -1
# 5c1a8f2 fixup! feat(reservas): añadir la vigencia de una reserva
```

El prefijo `fixup!` más el título del commit destino es lo que `--autosquash` sabe leer. No hace falta escribir mensaje: el de un `fixup` se descarta al fundirlo, y lo único que importa es a qué commit pertenece el cambio.

---

## Paso 3: La operación

**Por qué**: cinco commits de trabajo tienen que salir de aquí convertidos en dos commits con sentido: la funcionalidad y sus tests.

Primero, la marca del punto de partida. Tiene doble uso: red de seguridad y término de comparación para el paso 6.

```bash
git branch respaldo/antes-de-la-cirugia
```

Y ahora la operación:

```bash
git rebase -i --autosquash main
```

Se abre la lista, del más antiguo al más reciente, y el `fixup!` del paso 2 **ya viene colocado** debajo de su commit destino y marcado como `fixup`. Eso lo ha hecho `--autosquash`; el resto lo colocas tú:

```
pick   9d1f3c5 feat(reservas): añadir la vigencia de una reserva
fixup  5c1a8f2 fixup! feat(reservas): añadir la vigencia de una reserva
fixup  7b2a4e6 typo
pick   3a9d2f7 wip
fixup  c4e8b1a arreglo el import
```

Tú has hecho dos cosas a mano: **mover** `typo` para que quede detrás del commit que corrige, y cambiar dos `pick` por `fixup`. Compara el trabajo que te ha costado eso con el que costó la línea del paso 2: esa es la razón de usar `--fixup` desde el principio. Guarda y cierra.

Ahora quedan dos commits, pero el segundo sigue titulándose `wip`. Reescríbelo:

```bash
git commit --amend -m "test(reservas): cubrir la vigencia de una reserva recien creada"
```

**Verifica**:

```bash
git log --oneline -2
# 2f8c3a1 test(reservas): cubrir la vigencia de una reserva recien creada
# 8e4b1d7 feat(reservas): añadir la vigencia de una reserva
```

```bash
npm test
# ℹ pass 10
```

---

## Paso 4: Comprobar que **cada** commit está sano

**Por qué**: es lo que hace que `git bisect` sirva de algo dentro de seis meses. Un commit intermedio que no pasa sus tests convierte la búsqueda binaria en adivinanza.

```bash
git rebase --exec "npm test" main
```

Con `--exec`, Git ejecuta `npm test` después de aplicar cada commit y **se detiene** en el primero que falle.

**Verifica**: el rebase termina sin pararse. Si se para, ese commit está roto:

```bash
# Arregla lo que haga falta en el directorio de trabajo, y:
git add -A
git commit --amend --no-edit
git rebase --continue
```

> [!TIP]
> Este es el comando que separa una historia que sirve para diagnosticar de una que solo sirve para almacenar. Vale la pena tenerlo en un alias:
>
> ```bash
> git config --global alias.comprobar-historia '!f() { git rebase --exec "npm test" "${1:-main}"; }; f'
> ```

---

## Paso 5: Las firmas después de la cirugía

**Por qué**: acabas de recrear cinco commits. Si `rebase.gpgSign` no estuviera activo, todos habrían salido sin firmar y nadie te habría avisado.

```bash
git log --pretty='%h %G? %s' main..HEAD
```

**Verifica**: los dos commits salen con `G`.

Si alguno sale con `N`, la firma se perdió. Se arregla refirmando toda la serie:

```bash
git config --global rebase.gpgSign true
git rebase --gpg-sign main
git log --pretty='%h %G? %s' main..HEAD
```

Y la comprobación general, la que conviene ejecutar antes de **cualquier** push tras reescribir:

```bash
git log --pretty='%h %G? %s' origin/main..HEAD | grep -v '^\S* G '
```

Si no imprime nada, todo lo que vas a empujar está firmado.

---

## Paso 6: Revisar tu propia cirugía con `range-diff`

**Por qué**: comparar la serie de antes con la de después es la única forma de estar seguro de que la reescritura **no cambió el contenido**, solo la forma.

```bash
git range-diff respaldo/antes-de-la-cirugia...HEAD
```

Lee la salida: empareja los commits de la serie vieja (cinco) con los de la nueva (dos). `=` significa idéntico, `!` que cambió, y un hueco que apareció o desapareció.

**Verifica** que el **estado final** de los archivos es exactamente el mismo por los dos lados:

```bash
git diff respaldo/antes-de-la-cirugia HEAD
```

Tiene que salir **vacío**. Eso es lo que demuestra que la cirugía cambió la forma de la historia y no el contenido del proyecto: cinco commits o dos, el árbol resultante es idéntico.

Si sale algo, alguna línea se perdió durante el rebase. Vuelve al punto de partida y repite:

```bash
git reset --hard respaldo/antes-de-la-cirugia
```

---

## Paso 7: Integrar en `main` sin commit de fusión

**Por qué**: uno de los requisitos verificables de la semana es que **ningún commit de `main` tenga dos padres**. Un `git merge` normal crea exactamente eso.

```bash
git switch main
git merge --ff-only feat/reservas
```

`--ff-only` es la clave: avanza el puntero de `main` si puede hacerlo sin fusionar, y **falla** si no puede. Es la forma de que Git te impida romper la linealidad por descuido.

Si falla porque `main` avanzó mientras tanto:

```bash
git switch feat/reservas
git rebase main          # reaplica tus commits encima; con rebase.gpgSign, firmados
git switch main
git merge --ff-only feat/reservas
```

**Verifica** que la historia sigue siendo lineal:

```bash
git log --pretty='%h %p %s' -5
```

La segunda columna es el padre. Un solo SHA por línea: lineal. Dos: hay una fusión.

---

## Paso 8: Empujar y limpiar

**Por qué**: la rama de trabajo ya no aporta nada y una de las comprobaciones de la semana exige que solo quede `main`. Las ramas huérfanas son el desorden que en la Semana 06 acaba escondiendo trabajo sin integrar.

```bash
git push
```

Si `main` diverge porque reescribiste commits que ya estaban empujados:

```bash
git fetch origin
git log --oneline main..origin/main    # si esto imprime algo, PARA y mira qué hay allí
git push --force-with-lease
```

> [!WARNING]
> `--force-with-lease` sobrescribe la rama remota **solo si** sigue donde tú creías. Aun así, en un repositorio compartido cualquiera que hubiera clonado tendría que rehacer su copia. Aquí eres el único, y es la última semana en que esto es aceptable sobre `main`.

Borra las ramas que sobran, local y remota:

```bash
git branch -d feat/reservas
git branch -D respaldo/antes-de-la-cirugia
git push origin --delete feat/reservas 2>/dev/null || true
```

**Verifica** el estado final en la instancia:

```bash
source ~/.bc-gitlab
P="${PROYECTO//\//%2F}"

curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$P/repository/branches" | jq -r '.[].name'
# main

curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$P/repository/commits?ref_name=main&per_page=100" \
  | jq '{commits: length,
         fusiones: (map(select(.parent_ids | length > 1)) | length),
         no_convencionales: (map(select((.title | test("^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\\(.+\\))?!?: .+")) | not)) | map(.title))}'
```

```json
{
  "commits": 11,
  "fusiones": 0,
  "no_convencionales": []
}
```

Si `no_convencionales` trae algún título, ese commit incumple la convención: vuelve a un `rebase -i` y córrígelo con `reword`.

---

## ✅ Resultado

- [ ] Los cinco commits de trabajo quedaron en dos, con títulos que significan algo
- [ ] `git rebase --exec "npm test" main` recorre la serie entera sin pararse
- [ ] Todos los commits reescritos siguen saliendo con `G`
- [ ] `range-diff` confirma que el contenido no cambió, solo la forma
- [ ] `main` no tiene ningún commit con dos padres
- [ ] Solo queda la rama `main`, en local y en el remoto
- [ ] Ningún título de `main` incumple Conventional Commits

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 02
```

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| El rebase se para con `CONFLICT` | Dos commits tocan las mismas líneas | Resolver, `git add <archivo>`, `git rebase --continue` |
| Quiero salir del rebase a medias | — | `git rebase --abort` |
| El rebase terminó y quiero deshacerlo | — | `git reset --hard ORIG_HEAD` |
| Perdí commits en la operación | — | `git reflog` y `git reset --hard HEAD@{n}` |
| Los commits salen con `N` tras el rebase | Falta `rebase.gpgSign true` | Ponerlo y `git rebase --gpg-sign main` |
| `fatal: Not possible to fast-forward` | `main` avanzó por su cuenta | `git rebase main` en la rama de trabajo, y repetir el `--ff-only` |
| `Updates were rejected` al empujar | Reescribiste historia ya empujada | `git fetch` + `git push --force-with-lease` |
| `--force-with-lease` es rechazado | Alguien (o tú, en otro clon) empujó después | `git fetch` y revisar `main..origin/main` antes de nada |
| `error: The branch 'feat/reservas' is not fully merged` | `-d` protege ramas sin integrar | Comprueba que la fusión pasó; si estás seguro, `-D` |
| Los tests fallan tras el `fixup` | Se fundió el arreglo del import en el commit equivocado | `git rebase -i` y mover el `fixup` de sitio |

---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| [← Práctica 02 — El producto mínimo](02-el-producto-minimo.md) | [Práctica 04 — Arqueología y auditoría →](04-arqueologia-y-auditoria.md) |

[← Volver a la Semana 02](../README.md)

# Mover y recuperar cambios

> El reflog es la diferencia entre "he roto el repositorio" y "he perdido treinta segundos". Casi nadie lo conoce hasta que ya es tarde.

## 🎯 Objetivos

- Trasplantar un commit concreto a otra rama con `cherry-pick`
- Distinguir `revert` de `reset` y saber cuál toca según quién más tenga esa historia
- Recuperar commits perdidos con `git reflog`, incluidos los de un `reset --hard`
- Entender cuándo un commit deja de ser recuperable

---

## 1. Qué problema resuelve

Hay dos preguntas distintas que la gente resuelve con el mismo comando equivocado:

1. *Este commit hace falta también en la otra rama.* → **`cherry-pick`**
2. *Este commit no tenía que haber entrado.* → **`revert`** si ya lo tiene alguien, **`reset`** si solo lo tienes tú.

Y una tercera que aparece con el pulso acelerado:

3. *Acabo de borrar dos horas de trabajo.* → **`reflog`**, casi siempre.

---

## 2. `cherry-pick`: llevar un commit a otro sitio

```bash
git switch main
git cherry-pick 8f0b6c1
```

Coge el **diff** de ese commit y lo aplica donde estés, creando un commit nuevo con **otro SHA** y el mismo mensaje.

| Opción | Para qué |
|---|---|
| `-x` | Añade `(cherry picked from commit <sha>)` al mensaje: deja rastro de dónde vino |
| `-n` | Aplica el cambio pero **no** comprometas: lo deja en el índice |
| `A..B` | Trasplanta un rango de commits |
| `-m 1` | Necesario para trasplantar un merge: dice respecto a qué padre calcular el diff |

```bash
git cherry-pick -x 8f0b6c1        # el que usarás en un backport
git cherry-pick 8f0b6c1..c4e8b1a  # un rango, sin incluir el primero
```

> [!TIP]
> Usa `-x` siempre que el trasplante cruce ramas de larga vida (un arreglo de `main` a una rama de mantenimiento). Dentro de seis meses, la línea que añade es la única forma de saber que ese commit y el otro son el mismo cambio.

Si hay conflicto: resolver, `git add`, y `git cherry-pick --continue`. Para abandonar, `--abort`.

**Cuándo *no* usar `cherry-pick`**: para traer una rama entera. Diez `cherry-pick` en fila son diez oportunidades de conflicto y una historia duplicada. Para eso está `rebase`.

---

## 3. `revert`: deshacer sin borrar

```bash
git revert 8f0b6c1
```

Crea un commit **nuevo** que aplica el cambio inverso. La historia crece, no se reescribe. Nadie tiene que rehacer su clon.

| | `revert` | `reset` |
|---|---|---|
| Qué hace | Añade un commit que deshace | Mueve la rama hacia atrás |
| Reescribe historia | No | Sí |
| Seguro en rama compartida | **Sí** | No |
| Deja constancia de que hubo un error | Sí | No |

La regla es de una línea: **si otros ya tienen ese commit, `revert`. Si no ha salido de tu máquina, `reset`.**

```bash
git revert --no-commit 8f0b6c1 c4e8b1a   # dos reverts en un solo commit
git revert -m 1 <sha-del-merge>          # revertir un merge: -m 1 = conservar el primer padre
```

> [!NOTE]
> Revertir un merge tiene una secuela conocida: la rama revertida no se puede volver a fusionar sin más, porque Git considera que esos commits ya están integrados. Hay que revertir el revert. Es una razón más para preferir historia lineal, que es lo que este bootcamp usa desde ahora hasta la Semana 26.

En GitLab, cada merge request y cada commit tienen un botón **Revert** que hace exactamente esto y abre una merge request con el resultado. Es Free, y se practica en la Semana 06.

---

## 4. `git reflog`: la red de seguridad

Cada vez que `HEAD` o una rama **se mueve**, Git anota el movimiento en `.git/logs/`. Ese registro es el reflog, y es local: no se clona, no se empuja, no lo ve nadie más.

```bash
git reflog
```

```
3a9d2f7 HEAD@{0}: rebase (finish): returning to refs/heads/main
c4e8b1a HEAD@{1}: rebase (squash): feat(prestamos): calcular la multa
8f0b6c1 HEAD@{2}: commit: wip
5d7e9f1 HEAD@{3}: reset: moving to HEAD~1
9c2e771 HEAD@{4}: commit: feat(socios): comprobar si puede prestar
```

Cada línea dice **qué operación** movió la referencia y **a dónde apuntaba antes**. Con eso se deshace cualquier cosa:

```bash
# "El rebase salió mal"
git reset --hard HEAD@{1}

# "Borré la rama sin fusionar"
git reflog | grep 'feat/multas'
git switch -c feat/multas 9c2e771

# "Hice reset --hard y perdí tres commits"
git reset --hard HEAD@{4}
```

También hay reflog **por rama**:

```bash
git reflog show main
git log -g --oneline main    # lo mismo, con formato de log
```

### Lo que el reflog no salva

| Situación | ¿Recuperable? |
|---|---|
| `reset --hard` de commits | ✅ Sí, están en el reflog |
| Rama borrada con `git branch -D` | ✅ Sí, su último SHA está en el reflog de `HEAD` |
| Rebase que salió mal | ✅ Sí, y además está `ORIG_HEAD` |
| Cambios **sin comprometer** descartados con `restore` o `reset --hard` | ❌ **No.** Nunca fueron un objeto |
| `git clean -fd` | ❌ No. Git nunca vio esos archivos |
| Un `git stash drop` | ⚠️ A veces: el objeto sigue suelto, se busca con `git fsck --unreachable` |

> [!IMPORTANT]
> **El reflog caduca.** Por defecto, 90 días para lo alcanzable y **30 días** para lo inalcanzable (`gc.reflogExpire` y `gc.reflogExpireUnreachable`). Pasado eso, `git gc` puede borrar los objetos de verdad. La red existe, pero no es eterna.

Y el rescate de último recurso, cuando ni el reflog tiene la entrada:

```bash
git fsck --full --no-reflogs --unreachable --lost-found
# dangling commit 9c2e771...
git show 9c2e771
```

`--lost-found` deja los objetos sueltos en `.git/lost-found/` para que los mires.

---

## 5. Las cuatro variantes de `reset`, otra vez y en contexto

Ya aparecieron en la teoría 02, pero aquí es donde se decide bien:

```
                    HEAD    índice   trabajo
git reset --soft      ✔        ·        ·      "rehacer el commit"
git reset [--mixed]   ✔        ✔        ·      "rehacer commit e índice"
git reset --hard      ✔        ✔        ✔      "que no haya pasado nada"
git reset --keep      ✔        ✔        ~      como --hard, pero aborta si pierdes trabajo
```

`--keep` es el desconocido útil: hace lo que la gente cree que hace `--hard`, pero se niega en vez de destruir cambios sin comprometer.

---

## 6. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| `reset --hard` sobre una rama que otros tienen | Les desapareces commits del historial compartido | `git revert` |
| Diez `cherry-pick` para traer una rama | Historia duplicada y diez conflictos | `git rebase` o una merge request |
| `cherry-pick` sin `-x` entre ramas de larga vida | Nadie sabe que ese arreglo ya existía en `main` | `cherry-pick -x` |
| Borrar el repositorio y volver a clonar tras un error | El reflog local, que es lo que te salvaba, se va con él | `git reflog` antes de nada |
| Confiar en el reflog para siempre | Caduca a los 30-90 días | Si importa, hazlo commit en una rama |
| Revertir un merge y esperar poder refusionar | Git ya considera integrados esos commits | Revertir el revert, o historia lineal desde el principio |

---

## 7. Trucos

**Ver el reflog con fecha legible:**

```bash
git reflog --date=iso
# 3a9d2f7 HEAD@{2026-08-23 09:14:02 -0500}: commit: feat(prestamos): calcular multa
```

**Volver a la rama anterior, como `cd -`:**

```bash
git switch -
```

**Ver qué había en un archivo antes del desastre, sin restaurar nada:**

```bash
git show HEAD@{5}:src/prestamos.ts | less
```

**Encontrar commits huérfanos de un `rebase` abortado:**

```bash
git fsck --unreachable --no-reflogs | grep commit | cut -d' ' -f3 \
  | xargs -n1 git log -1 --format='%h %ad %s' --date=short
```

**Guardar el punto de partida antes de operar** — más barato que cualquier rescate:

```bash
git branch respaldo/$(date +%Y%m%d-%H%M)
```

---

## 📚 Recursos Adicionales

- [Pro Git — Herramientas de Git: Reset desmitificado](https://git-scm.com/book/es/v2/Herramientas-de-Git-Reset-Desmitificado) — las tablas de los tres árboles, con dibujos
- [`git reflog`](https://git-scm.com/docs/git-reflog) — incluida la política de caducidad
- [`git cherry-pick`](https://git-scm.com/docs/git-cherry-pick) — `-x`, `-n` y el trasplante de merges
- [`git fsck`](https://git-scm.com/docs/git-fsck) — el rescate cuando el reflog ya no tiene la entrada

---

## ✅ Checklist de Verificación

- [ ] Sabes decidir entre `revert` y `reset` según quién más tenga el commit
- [ ] Has leído tu propio reflog y reconoces qué operación generó cada línea
- [ ] Sabes recuperar una rama borrada sin tener apuntado su SHA
- [ ] Entiendes qué tipo de pérdida **no** cubre el reflog
- [ ] Sabes cuándo `cherry-pick` necesita `-x`

---

| Anterior | Siguiente |
|---|---|
| [← 03 — Reescribir la historia](03-reescribir-la-historia.md) | [05 — Conventional Commits y trailers →](05-conventional-commits-y-trailers.md) |

[← Volver a la Semana 02](../README.md)

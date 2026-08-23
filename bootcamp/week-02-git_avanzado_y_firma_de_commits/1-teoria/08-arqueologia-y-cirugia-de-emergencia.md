# Arqueología y cirugía de emergencia

> Dos preguntas que llegan siempre: "¿desde cuándo está roto esto?" y "¿cómo saco de la historia una clave que se coló?". La primera la contesta `bisect`; la segunda tiene un primer paso que no es Git.

## 🎯 Objetivos

- Encontrar el commit que rompió algo con `git bisect run`, sin intervención manual
- Buscar en la historia por contenido con la lupa (`-S`, `-G`) y con `git blame`
- Trabajar en dos ramas a la vez con `git worktree`
- Saber qué hacer, y en qué orden, cuando un secreto entra al repositorio

---

## 1. Qué problema resuelve

El código funciona en la versión de hace tres meses y no funciona hoy. Entre medias hay 240 commits. Leerlos uno a uno son dos días; leer el que rompió, cinco minutos.

Y su gemelo desagradable: alguien comprometió un `.env` con una clave real. Borrarlo con un commit nuevo **no sirve**: sigue en la historia, en todos los clones, y cualquiera con acceso de lectura la saca en diez segundos.

---

## 2. `git bisect`: búsqueda binaria sobre la historia

Con 240 commits, la búsqueda binaria necesita **ocho** pruebas. Ese es todo el truco.

### A mano

```bash
git bisect start
git bisect bad                 # el actual está roto
git bisect good v0.1.0         # aquí funcionaba
# Git salta al commit de en medio; pruebas y respondes:
git bisect good     # o bad
# ... 8 veces ...
# 9c2e771 is the first bad commit
git bisect reset               # vuelve a donde estabas
```

### Automático, que es como se usa de verdad

```bash
git bisect start HEAD v0.1.0
git bisect run npm test
```

`bisect run` ejecuta el comando en cada commit y decide por el **código de salida**:

| Código de salida | Interpretación |
|---|---|
| `0` | `good` |
| `1`-`124`, `126`, `127` | `bad` |
| `125` | **`skip`**: este commit no se puede probar (no compila, falta una dependencia) |
| `128`-`255` | Aborta la bisección |

El `125` es el que hace falta conocer: si tu script no puede juzgar un commit, tiene que salir con 125 para que Git lo salte en vez de contarlo como roto.

```bash
#!/usr/bin/env bash
# prueba-bisect.sh
npm ci --silent || exit 125     # este commit ni siquiera instala: sáltalo
npm test --silent
```

```bash
git bisect run ./prueba-bisect.sh
```

> [!TIP]
> **`bisect` es la razón práctica de todo lo demás de esta semana.** Sobre una historia de `wip` y `ahora sí`, la mitad de los commits salen con 125 y la búsqueda no converge. Sobre una historia donde cada commit compila y pasa tests, `bisect` señala la línea exacta en ocho pruebas. Una historia limpia no es estética: es una herramienta de diagnóstico.

Extras que se usan poco y valen mucho:

```bash
git bisect skip                # este no se puede probar, y lo decides tú
git bisect log > sesion.txt    # guarda la sesión
git bisect replay sesion.txt   # la repite
git bisect visualize           # la ventana que queda por explorar
```

---

## 3. La lupa: buscar por contenido

`git log --grep` busca en los **mensajes**. Para buscar en el **código** hay dos opciones mejores:

```bash
git log -S "MULTA_POR_DIA" --oneline
```

`-S` (*pickaxe*) enseña los commits donde **cambia el número de apariciones** de esa cadena: es decir, dónde se introdujo y dónde se eliminó. Es el que quieres el 90% de las veces.

```bash
git log -G "calcularMulta\(.*\)" --oneline
```

`-G` acepta expresión regular y enseña los commits cuyo **diff** la contiene, aunque el número de apariciones no cambie (por ejemplo, un renombrado).

| Comando | Encuentra |
|---|---|
| `git log --grep="multa"` | Commits cuyo **mensaje** lo dice |
| `git log -S "multa"` | Commits donde ese texto **aparece o desaparece** |
| `git log -G "multa"` | Commits cuyo diff **menciona** ese patrón |
| `git log -- src/prestamos.ts` | Commits que tocan ese archivo |
| `git log -L 10,20:src/prestamos.ts` | La historia de **esas líneas** concretas |

`-L` es el desconocido más útil de la lista: te da la evolución de un bloque de código, salto de archivo incluido.

### `git blame`, sin las trampas

```bash
git blame -w -C -C src/prestamos.ts
```

| Opción | Qué evita |
|---|---|
| `-w` | Que un cambio de indentación te señale como autor de todo |
| `-C` | Sigue el código movido dentro del mismo archivo |
| `-C -C` | Y también el que viene de otro archivo del mismo commit |
| `-L 40,60` | Solo ese rango de líneas |
| `--ignore-rev <sha>` | Ignora un commit concreto (el del formateo masivo) |

Y para que el commit de "aplicar prettier a todo el repositorio" no contamine el blame para siempre:

```bash
echo "8f0b6c1e1c3f9b0e5a2d4c7e9f1a3b5d7e9f1a3b" >> .git-blame-ignore-revs
git config blame.ignoreRevsFile .git-blame-ignore-revs
```

Ese archivo se versiona y GitLab lo respeta en su vista de blame. Es Free.

---

## 4. `git worktree`: dos ramas a la vez, un solo clon

El caso: estás a medias de algo y llega un arreglo urgente. Las opciones malas son `stash` (y perder el contexto) o clonar otra vez (y duplicar el repositorio).

```bash
git worktree add ../app-hotfix -b fix/multa-negativa main
cd ../app-hotfix
# ... arreglas, comprometes, empujas ...
cd ../app
git worktree remove ../app-hotfix
```

Cada árbol de trabajo tiene sus propios archivos y su propio `HEAD`, pero **comparten la base de objetos**: no se duplica nada, y los commits que haces en uno se ven desde el otro al instante.

```bash
git worktree list
git worktree prune      # limpia los que borraste a mano
```

Restricción única: dos árboles no pueden tener la **misma rama** activa a la vez. Git lo impide, y es lo correcto.

---

## 5. Cuando entra un secreto

Un token, una contraseña, una clave privada. El orden importa y el primer paso **no es Git**:

> [!WARNING]
> **1. Revoca el secreto. Ahora.** Antes de tocar la historia, antes de avisar a nadie. Mientras la credencial siga siendo válida, el repositorio es lo de menos: puede estar ya en el portapapeles de alguien, en un log de CI, en un backup o en un fork. Reescribir la historia **no invalida un token**; revocarlo sí.
>
> **2. Rota lo que dependiera de él.** Si era una clave de despliegue, genera otra y actualízala donde se use.
>
> **3. Y solo entonces, limpia la historia.**

Para el paso 3, la herramienta es `git filter-repo` (sustituye al `filter-branch` que aún aparece en tutoriales viejos, y que la propia documentación de Git desaconseja por lento y por sus casos límite). No viene con Git: se instala aparte (`pipx install git-filter-repo`).

```bash
git filter-repo --path .env --invert-paths       # elimina ese archivo de toda la historia
git filter-repo --replace-text expresiones.txt   # sustituye cadenas por ***REMOVED***
```

Y ahora la parte que nadie cuenta: **las consecuencias**.

| Consecuencia | Detalle |
|---|---|
| **Cambian todos los SHA** desde el commit tocado | Cualquier enlace a un commit, cualquier referencia en un issue, deja de resolver |
| **Todas las firmas desaparecen** | `filter-repo` recrea los commits sin firmarlos: la historia entera queda `N` |
| **Todos los clones quedan inservibles** | Cada persona tiene que volver a clonar. Un `pull` mezcla las dos historias |
| **Hay que forzar el push** | Y en GitLab, `main` protegida lo impide: hay que desprotegerla, forzar y volver a protegerla |
| **GitLab conserva objetos huérfanos** | El commit sigue accesible por su SHA hasta que se ejecuta el mantenimiento del repositorio en `Settings → Repository` |

Por eso el orden es el que es. La limpieza de la historia es higiene; la revocación es la que para la sangre.

> [!NOTE]
> Lo que de verdad resuelve esto es que el secreto **no llegue a entrar**. La Semana 19 monta Gitleaks en el pipeline, y la Semana 07 un server hook que rechaza el push. Las dos son Free. La detección de secretos nativa de GitLab (*Secret Detection*) es **Ultimate**, y Gitleaks hace el mismo trabajo.

---

## 6. Mantenimiento del repositorio local

Un clon con años de historia se vuelve lento: miles de objetos sueltos, refs remotas que ya no existen, índices sin optimizar.

```bash
git maintenance start        # programa el mantenimiento en segundo plano
git maintenance run --auto   # una pasada ahora
git gc --prune=now           # empaqueta y purga lo inalcanzable
```

> [!WARNING]
> `git gc --prune=now` **borra ya** los objetos inalcanzables, sin esperar los 30 días de gracia. Es exactamente lo que quieres tras limpiar un secreto, y exactamente lo que no quieres si estabas a punto de rescatar algo del reflog.

Y el que evita repetir el mismo trabajo en un rebase con conflictos:

```bash
git config --global rerere.enabled true
```

*Reuse recorded resolution*: Git memoriza cómo resolviste un conflicto y lo reaplica solo la próxima vez que aparezca el mismo. En un rebase de diez commits sobre una rama que se movió, ahorra la tarde entera.

---

## 7. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Borrar el secreto con un commit nuevo | Sigue en la historia y en todos los clones | Revocar primero, `filter-repo` después |
| Limpiar la historia antes de revocar | El token sigue siendo válido mientras tanto | Revocar es el paso 1, siempre |
| `git filter-branch` | Lento y con casos límite; su propia documentación lo desaconseja | `git filter-repo` |
| `bisect` a mano con 200 commits | Ocho pruebas manuales y un despiste que invalida la sesión | `git bisect run` |
| Script de bisect sin código 125 | Los commits que no compilan cuentan como rotos y el resultado miente | `exit 125` cuando no se pueda juzgar |
| `git blame` sin `-w -C` | Señala a quien reindentó el archivo | `git blame -w -C -C`, y `.git-blame-ignore-revs` |
| Clonar otra vez para un arreglo urgente | Duplica el repositorio y descoloca el contexto | `git worktree add` |

---

## 8. Trucos

**Bisecar sin ejecutar tests, solo comprobando que un texto está presente:**

```bash
git bisect run grep -q "calcularMulta" src/prestamos.ts
```

**Ver quién ha tocado un archivo y cuánto:**

```bash
git shortlog -sn -- src/prestamos.ts
```

**La historia de un bloque de líneas concreto:**

```bash
git log -L 12,24:src/prestamos.ts
```

**Ver todo lo que Git recuerda de una rama borrada:**

```bash
git log -g --oneline --all
```

**Comprobar cuánto ocupa tu repositorio y si conviene un `gc`:**

```bash
git count-objects -vH
# count: 4210        <- objetos sueltos; por encima de unos miles, toca gc
# size-pack: 84.21 MiB
```

**Buscar por contenido en toda la historia, no solo en el estado actual:**

```bash
git grep "glpat-" $(git rev-list --all) -- | head
```

Este es el comando con el que se descubre que el token que revocaste el año pasado sigue en un commit de 2024.

---

## 📚 Recursos Adicionales

- [`git bisect`](https://git-scm.com/docs/git-bisect) — incluidos `run`, `skip` y el significado del código 125
- [`git filter-repo`](https://github.com/newren/git-filter-repo) — la herramienta y su manual de migración desde `filter-branch`
- [Eliminar datos sensibles de un repositorio](https://docs.gitlab.com/ee/user/project/repository/reducing_the_repo_size_using_git.html) — el procedimiento de GitLab, con la parte del mantenimiento del repositorio
- [`git worktree`](https://git-scm.com/docs/git-worktree) — el flujo completo, incluidos los árboles bloqueados
- [`git rerere`](https://git-scm.com/docs/git-rerere) — cómo memoriza y cuándo se equivoca

---

## ✅ Checklist de Verificación

- [ ] Has encontrado un commit roto con `git bisect run` sin responder a mano
- [ ] Sabes por qué un script de bisect necesita `exit 125`
- [ ] Sabes buscar por contenido con `-S` y por qué no es lo mismo que `--grep`
- [ ] Puedes enumerar, en orden, los tres pasos ante un secreto filtrado
- [ ] Sabes qué le pasa a las firmas después de un `filter-repo`

---

| Anterior | Siguiente |
|---|---|
| [← 07 — Cómo verifica GitLab una firma](07-como-verifica-gitlab-una-firma.md) | — |

[← Volver a la Semana 02](../README.md)

# Práctica 04 — Arqueología y auditoría

> Encontrar el commit que rompió algo sin leer los doscientos anteriores, y comprobar por API que toda tu historia está firmada.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 03 completada (`main` lineal, firmada y con al menos ocho commits) · Teoría [08](../1-teoria/08-arqueologia-y-cirugia-de-emergencia.md) leída

---

## Contexto

Las tres prácticas anteriores construyeron una historia limpia. Esta demuestra **para qué servía**: sobre una historia donde cada commit pasa sus tests, `git bisect` encuentra el culpable en unas pocas pruebas y sin intervención humana.

Y termina con la auditoría que cierra la semana: preguntarle a la instancia, commit a commit, si todo está firmado y verificado. Es el mismo tipo de comprobación que en la Semana 09 se convertirá en un job de pipeline.

---

## Paso 1: Fabricar el desastre

**Por qué**: hace falta un fallo real y enterrado. Se hace en una rama de usar y tirar para no ensuciar `main`.

```bash
cd ~/ruta/a/app
git switch -c pruebas/arqueologia
```

Seis commits inocentes y uno que rompe, escondido en medio:

```bash
for i in 1 2 3; do
  echo "// nota de mantenimiento $i" >> src/prestamos.ts
  git commit -qam "chore(prestamos): anotar mantenimiento $i"
done

# El commit culpable: relaja la comparacion y deja pasar un prestamo de mas.
sed -i 's/socio.prestamosAbiertos < LIMITE_PRESTAMOS/socio.prestamosAbiertos <= LIMITE_PRESTAMOS/' src/prestamos.ts
git commit -qam "refactor(prestamos): simplificar una comparacion redundante"

for i in 4 5 6; do
  echo "// nota de mantenimiento $i" >> src/prestamos.ts
  git commit -qam "chore(prestamos): anotar mantenimiento $i"
done
```

**Verifica** que ahora los tests fallan y que hay siete commits donde buscar:

```bash
npm test 2>&1 | tail -5
# ℹ fail 1

git log --oneline main..HEAD | wc -l
# 7
```

Un commit titulado `refactor: simplificar` que en realidad cambia el comportamiento. Es exactamente la clase de cambio que pasa una revisión y aparece tres semanas después.

---

## Paso 2: `git bisect run`

**Por qué**: siete commits son tres pruebas; doscientos serían ocho. La búsqueda binaria no depende del tamaño de la historia, y `run` la ejecuta sin que respondas nada.

```bash
git bisect start HEAD main
git bisect run npm test
```

`HEAD` es el estado roto; `main` es el último estado que sabes bueno.

**Verifica** que señala al commit correcto:

```
0f9bc98... is the first 'bad' commit
    refactor(prestamos): simplificar una comparacion redundante
```

```bash
git bisect reset
```

`reset` te devuelve a donde estabas. **No lo olvides**: mientras la bisección está abierta, `HEAD` está desprendido y cualquier commit que hagas ahí queda huérfano.

> [!TIP]
> Si tu comando de prueba no puede juzgar un commit —no compila, falta una dependencia— tiene que salir con **código 125** para que Git lo salte en vez de contarlo como roto:
>
> ```bash
> cat > /tmp/prueba-bisect.sh <<'EOF'
> #!/usr/bin/env bash
> node --experimental-strip-types --test 'src/*.test.ts' > /dev/null 2>&1 || exit 1
> exit 0
> EOF
> chmod +x /tmp/prueba-bisect.sh
> git bisect run /tmp/prueba-bisect.sh
> ```

---

## Paso 3: La lupa — buscar por contenido

**Por qué**: `bisect` contesta "cuándo". La lupa contesta "dónde y por qué", y no necesita tests.

Prueba las tres formas de buscar sobre el mismo fallo, **en este orden**:

```bash
# 1. Por el mensaje.
git log --grep="limite" --oneline

# 2. Por aparicion o desaparicion de un texto (pickaxe).
git log -S "LIMITE_PRESTAMOS" --oneline

# 3. Por el contenido del diff, con expresion regular.
git log -G "prestamosAbiertos.*LIMITE" --oneline
```

**Verifica** este resultado, que es la lección entera de la práctica:

| Comando | Qué encuentra | ¿Encuentra al culpable? |
|---|---|:--:|
| `--grep="limite"` | Commits cuyo **mensaje** lo dice | ❌ El mensaje habla de "simplificar una comparacion" |
| `-S "LIMITE_PRESTAMOS"` | Commits donde ese texto **aparece o desaparece** | ❌ Solo sale el que la introdujo |
| `-G "prestamosAbiertos.*LIMITE"` | Commits cuyo **diff** encaja con el patrón | ✅ |

`-S` falla aquí por una razón que conviene entender: el commit culpable cambió `<` por `<=`, y el **número de apariciones** de `LIMITE_PRESTAMOS` no varió. `-S` cuenta; `-G` mira el diff. Para "¿cuándo se introdujo esto?", `-S`. Para "¿quién tocó esta línea?", `-G`.

Y la historia de **esa función** concreta, que es lo que casi nadie sabe que existe:

```bash
git log -L :puedePrestar:src/prestamos.ts | head -40
```

`-L :funcion:archivo` sigue la evolución de esa función aunque se mueva de sitio dentro del archivo. Ahí el commit culpable sale el primero, con su diff delante.

---

## Paso 4: `git blame` sin las trampas

**Por qué**: el `blame` por defecto señala a quien reindentó el archivo, no a quien escribió la lógica.

```bash
git blame -w -C -C -L 1,20 src/prestamos.ts
```

| Opción | Qué evita |
|---|---|
| `-w` | Que un cambio de espacios te señale como autor |
| `-C -C` | Sigue el código movido, dentro del archivo y desde otros archivos del mismo commit |
| `-L 1,20` | Limita al rango que te interesa |

Un commit que solo añade ruido puede excluirse del `blame` de una vez:

```bash
SHA_NOTAS=$(git log --format=%H --grep='anotar mantenimiento 1' -1)
git blame -w --ignore-rev "$SHA_NOTAS" src/prestamos.ts | tail -3
```

**Verifica**: las líneas de ese commit pasan a atribuirse al commit **anterior**, el que de verdad las contextualiza.

Escribir `--ignore-rev` a mano cada vez no escala. La forma permanente es un archivo versionado que Git —y GitLab— leen solos:

```bash
cat > .git-blame-ignore-revs <<'EOF'
# Commits que no deben ensuciar git blame: formateos masivos, renombrados,
# reindentaciones. Un SHA completo por linea, y un comentario que diga cual es.
EOF

git config blame.ignoreRevsFile .git-blame-ignore-revs
git add .git-blame-ignore-revs
git commit -m "chore: preparar la lista de commits ignorados en git blame"
```

Nace vacío a propósito: todavía no hay ningún formateo masivo que ignorar. La línea se añadirá el día que lo haya, y el `blame` seguirá señalando a quien escribió la lógica.

> [!NOTE]
> GitLab lee ese mismo archivo, con ese mismo nombre, en su vista de *Blame*. Es Free y no hay nada que configurar en el servidor: basta con que `.git-blame-ignore-revs` esté versionado en la raíz.

---

## Paso 5: `git worktree` — dos ramas a la vez

**Por qué**: llega un arreglo urgente mientras tienes trabajo a medias. Ni `stash` (pierdes el contexto) ni clonar otra vez (duplicas el repositorio).

```bash
git worktree add ../app-hotfix main
cd ../app-hotfix
```

**Verifica** que es otro directorio, con otra rama activa, sobre el **mismo** repositorio:

```bash
git status -sb
# ## main...origin/main

git worktree list
# /home/tu/app          215293f [pruebas/arqueologia]
# /home/tu/app-hotfix   f30a1f7 [main]
```

Los objetos no se han duplicado: un commit hecho aquí se ve inmediatamente desde el otro árbol.

Vuelve y limpia:

```bash
cd ../app
git worktree remove ../app-hotfix
git worktree list
```

---

## Paso 6: Deshacer el experimento

**Por qué**: la rama de arqueología era de usar y tirar, y una de las comprobaciones de la semana exige que solo quede `main`. El commit del `blame` sí interesa conservarlo.

Rescata solo ese commit con `cherry-pick`, y tira el resto:

```bash
SHA_BLAME=$(git log --format=%H --grep='^chore: preparar la lista de commits ignorados' -1)

git switch main
git cherry-pick "$SHA_BLAME"
```

> [!NOTE]
> El `cherry-pick` crea un commit **nuevo** con otro SHA. Con `commit.gpgsign` activo sale firmado; compruébalo antes de seguir.

```bash
git log --pretty='%h %G? %s' -1
# 4d7e2a9 G chore: preparar la lista de commits ignorados en git blame
```

Borra la rama y empuja:

```bash
git branch -D pruebas/arqueologia
git push
```

**Verifica** que la instancia solo tiene `main`:

```bash
source ~/.bc-gitlab
P="${PROYECTO//\//%2F}"
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$P/repository/branches" | jq -r '.[].name'
# main
```

---

## Paso 7: Auditar las firmas por API

**Por qué**: `%G?` audita lo que hay en **tu** clon. Lo que cuenta es lo que la instancia da por bueno, que es lo que verá cualquiera que revise el repositorio, y lo que aplicará el server hook de la Semana 07.

```bash
source ~/.bc-gitlab
P="${PROYECTO//\//%2F}"

for sha in $(curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    "$GITLAB_URL/api/v4/projects/$P/repository/commits?ref_name=main&per_page=100" \
    | jq -r '.[].id'); do
  estado=$(curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    "$GITLAB_URL/api/v4/projects/$P/repository/commits/$sha/signature" \
    | jq -r '.verification_status // "sin-firma"')
  printf '%s  %s\n' "${sha:0:8}" "$estado"
done
```

**Verifica** que **todas** las líneas dicen `verified`:

```
4d7e2a9  verified
215293f  verified
003209e  verified
...
```

Recuerda que un commit sin firma devuelve `404`, y por eso el `// "sin-firma"` del `jq`: sin él verías un `null` que no explica nada.

Y el resumen en una línea, contando por estado:

```bash
for sha in $(curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    "$GITLAB_URL/api/v4/projects/$P/repository/commits?ref_name=main&per_page=100" \
    | jq -r '.[].id'); do
  curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    "$GITLAB_URL/api/v4/projects/$P/repository/commits/$sha/signature" \
    | jq -r '.verification_status // "sin-firma"'
done | sort | uniq -c
#      11 verified
```

> [!TIP]
> Si alguna línea dice `sin-firma`, ese commit viene de antes de la práctica 01 —probablemente el de la Semana 01— y es esperado. Los requisitos de la semana solo exigen que el **último** commit de `main` esté verificado. Si quieres la historia entera firmada, `git rebase --gpg-sign --root` y `git push --force-with-lease`: es la última semana en que puedes.

---

## Paso 8: Cerrar la semana

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 02
```

**Verifica**:

```
14 de 14 verificaciones superadas.
```

Si alguna falla, la pista dice en qué práctica y en qué paso se arregla.

---

## ✅ Resultado

- [ ] `git bisect run` señaló el commit culpable sin que respondieras a mano
- [ ] Sabes por qué `--grep` y `-S` no encontraban el culpable y `-G` sí
- [ ] Has usado `git blame -w -C -C` y `--ignore-rev`, y versionado `.git-blame-ignore-revs`
- [ ] Has creado y eliminado un árbol de trabajo secundario
- [ ] La auditoría por API devuelve `verified` para el último commit de `main`
- [ ] Solo queda la rama `main` en la instancia
- [ ] `./scripts/verificar-semana.sh 02` pasa las 14

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `You need to start by "git bisect start"` | La sesión no está abierta | `git bisect start <malo> <bueno>` |
| `bisect` termina señalando el commit equivocado | El commit "bueno" de referencia ya estaba roto | Elige uno anterior, o `git bisect log` para revisar la sesión |
| Todos los commits salen `bad` | El comando de prueba falla siempre (dependencias, ruta) | Pruébalo a mano en el commit bueno antes de bisecar |
| `HEAD` desprendido tras bisecar | Falta cerrar la sesión | `git bisect reset` |
| `git log -L` da `no such path` | El archivo se llamaba de otra forma antes | `git log --follow -- <archivo>` para ver los renombrados |
| `blame` sigue señalando el commit ignorado | Falta `blame.ignoreRevsFile` o el SHA está mal | El archivo lleva SHA **completos**, uno por línea |
| `fatal: '../app-hotfix' already exists` | Quedó un árbol de un intento anterior | `git worktree remove --force ../app-hotfix` o `git worktree prune` |
| `is already checked out` al crear el árbol | Esa rama ya está activa en otro árbol | Usa otra rama, o `-b <nueva>` |
| La auditoría devuelve `null` en vez de un estado | Ese commit no está firmado: la API devuelve 404 | Es correcto; el `// "sin-firma"` lo traduce |
| El `cherry-pick` sale sin firma | `commit.gpgsign` desactivado en este repositorio | `git commit --amend --no-edit -S` |

---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| [← Práctica 03 — Cirugía sobre la historia](03-cirugia-sobre-la-historia.md) | — |

[← Volver a la Semana 02](../README.md)

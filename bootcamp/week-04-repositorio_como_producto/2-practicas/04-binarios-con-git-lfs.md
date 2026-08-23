# Práctica 04 — Binarios con Git LFS

> Un patrón preciso, un `.gitattributes` que entra **antes** que el binario, y un puntero de 130 bytes verificado desde fuera.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 01 completada (`logo.png` en la raíz) · Teoría [08](../1-teoria/08-git-lfs.md) leída · Permiso para instalar paquetes en tu máquina

---

## Contexto

`app` todavía no tiene binarios en la historia. Ese es exactamente el momento de decidir cómo se guardan, porque es la única decisión de esta semana que **no tiene arreglo barato**: un binario que entra en la historia de Git solo sale reescribiéndola.

La práctica añade una imagen de más de un megabyte a `assets/`, la guarda en LFS, y comprueba desde fuera que lo que hay en el repositorio es un puntero y no la imagen. Por el camino aparece la trampa que se lleva por delante el avatar del proyecto: un patrón demasiado amplio.

> [!WARNING]
> Esta práctica **no** reescribe la historia. Si en algún punto te dan ganas de ejecutar `git lfs migrate import`, no lo hagas todavía: el paso 8 explica lo que implica y por qué aquí no hace falta.

---

## Paso 0: Preparar el terreno

**Por qué**: las mismas variables, y el clon de `app` en el que vas a trabajar. La wiki de la práctica 02 es otro repositorio: no lo confundas.

```bash
source ~/.bc-gitlab

export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)

cd /ruta/a/tu/clon/de/app
git switch main && git pull
git status --short
```

**Verifica**: estás en el clon de `app` —no en el de la wiki— y el árbol está limpio.

---

## Paso 1: Instalar Git LFS

**Por qué**: LFS no viene con Git. Sin él, `git add` guarda el binario entero en la historia sin avisar de nada, y para cuando te das cuenta ya está dentro.

```bash
# Debian, Ubuntu y derivados. Fedora: dnf install git-lfs.
# macOS: brew install git-lfs. Arch: pacman -S git-lfs.
sudo apt-get update && sudo apt-get install -y git-lfs
```

Y activa los filtros en tu configuración de Git. Se hace **una vez por máquina**, no por repositorio:

```bash
git lfs install
# Updated Git hooks.
# Git LFS initialized.
```

**Verifica**: la versión responde y los filtros están en tu configuración global.

```bash
git lfs version
git config --global --get-regexp 'filter.lfs'
```

```
filter.lfs.clean git-lfs clean -- %f
filter.lfs.smudge git-lfs smudge -- %f
filter.lfs.process git-lfs filter-process
filter.lfs.required true
```

Esos son los dos filtros de la teoría: `clean` al añadir, `smudge` al hacer checkout.

---

## Paso 2: Activar LFS en el proyecto

**Por qué**: hacen falta **dos interruptores**, y el error clásico es tener solo uno. La instancia ya lo trae activado en el `docker-compose.yml` del laboratorio; el del proyecto hay que ponerlo.

```bash
curl -s -H "$H" "$API/projects/$P" | jq '.lfs_enabled'
```

Si sale `false` o `null`:

**Con la interfaz**: `Settings → General → Visibility, project features, permissions → Git Large File Storage (LFS)`.

**Con la API**:

```bash
curl -s --request PUT "$API/projects/$P" -H "$H" \
  --data-urlencode "lfs_enabled=true" | jq '.lfs_enabled'
# true
```

**Verifica**: la respuesta es `true`. Si el proyecto lo tiene desactivado, el `push` del paso 6 falla con un error del servidor de LFS que no menciona este ajuste por ninguna parte.

---

## Paso 3: Elegir el patrón, que es la decisión de verdad

**Por qué**: el patrón decide qué se rastrea, y el amplio duele de una forma que no se ve hasta que es tarde. `*.png` captura **todos** los PNG del repositorio, incluido el `logo.png` de la raíz que GitLab lee como avatar del proyecto. Si ese archivo es un puntero, GitLab muestra el texto del puntero como si fuera una imagen: el avatar sale roto.

Comprueba primero qué PNG hay ya en el repositorio:

```bash
git ls-files '*.png'
# logo.png
```

Ahí está el motivo. El patrón correcto es por carpeta, no por extensión suelta:

| Patrón | Qué captura | Veredicto |
|---|---|---|
| `*.png` | Todos los PNG, `logo.png` incluido | ❌ Rompe el avatar |
| `assets/*.png` | Solo los de `assets/` | ✅ |
| `assets/**` | Todo lo que haya en `assets/`, incluido texto | ❌ Se lleva también los `.md` |

**Verifica**: sabes decir qué archivos del repositorio encajarían con tu patrón, y `logo.png` no está entre ellos.

---

## Paso 4: `.gitattributes` primero, antes que ningún binario

**Por qué**: es el paso cuyo orden importa. Si el binario entra en un commit **anterior** al `.gitattributes`, se queda en la historia de Git y solo lo saca reescribirla. Con el orden correcto no hay nada que arreglar.

```bash
git lfs track "assets/*.png"
git lfs track "assets/*.pdf"

cat .gitattributes
```

```
assets/*.png filter=lfs diff=lfs merge=lfs -text
assets/*.pdf filter=lfs diff=lfs merge=lfs -text
```

**Verifica**: el archivo está en la raíz y cada línea lleva los cuatro atributos.

Y entra en su propio commit, antes que nada:

```bash
git add .gitattributes
git commit -S -m "chore: track binary assets with git-lfs"
```

> [!IMPORTANT]
> Este commit va **solo**. Meter el `.gitattributes` y el binario en el mismo commit funciona, pero deja de ser evidente en la historia qué se decidió y cuándo, y con LFS esa fecha es la que separa "está en LFS" de "está en la historia para siempre".

---

## Paso 5: Crear el binario

**Por qué**: hace falta un archivo lo bastante grande para que la diferencia se note y se pueda medir. Un PNG de un megabyte sobra.

```bash
mkdir -p assets

# Con ImageMagick, si lo tienes
magick -size 1024x1024 gradient:'#FC6D26-#554488' assets/logo-grande.png

# Sin ImageMagick: un PNG valido generado con la libreria estandar de Python
python3 - <<'PY'
import zlib, struct
w = h = 1024
raw = b''.join(b'\x00' + bytes((x * 7 + y * 13) % 256 for x in range(w)) for y in range(h))

def chunk(tipo, datos):
    cuerpo = tipo + datos
    return struct.pack('>I', len(datos)) + cuerpo + struct.pack('>I', zlib.crc32(cuerpo))

png = (b'\x89PNG\r\n\x1a\n'
       + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 0, 0, 0, 0))
       + chunk(b'IDAT', zlib.compress(raw, 0))
       + chunk(b'IEND', b''))
open('assets/logo-grande.png', 'wb').write(png)
PY

ls -l assets/logo-grande.png
file assets/logo-grande.png
```

**Verifica**: el archivo pesa más de un megabyte y `file` lo reconoce como PNG.

```
-rw-r--r-- 1 tu tu 1049748 assets/logo-grande.png
assets/logo-grande.png: PNG image data, 1024 x 1024
```

---

## Paso 6: Añadirlo, empujarlo y comprobar que fue a LFS

**Por qué**: aquí es donde actúa el filtro `clean`. Lo que se añade al índice ya no es la imagen: es el puntero.

```bash
git add assets/logo-grande.png
git commit -S -m "feat: add large logo asset stored in lfs"
```

Antes de empujar, mira lo que hay realmente en el commit:

```bash
git show HEAD:assets/logo-grande.png
```

```
version https://git-lfs.github.com/spec/v1
oid sha256:4d7a214614ab2935c943f9e0ff69d22eadbb8f32b1258daaa5e2ca24d17e2393
size 1049748
```

**Verifica**: eso es el puntero, con sus tres líneas. Si en su lugar aparece un chorro de bytes ilegibles, el archivo **no** entró en LFS: revisa el patrón del paso 3 y que el `.gitattributes` sea anterior.

Y el inventario local:

```bash
git lfs ls-files --size
# 4d7a214614 * assets/logo-grande.png (1.0 MB)
```

Ahora empuja. El `push` sube dos cosas por caminos distintos: los commits a Git, y el binario al almacén de LFS.

```bash
git push origin main
```

```
Uploading LFS objects: 100% (1/1), 1.0 MB | 0 B/s, done.
```

**Verifica**: aparece la línea de *Uploading LFS objects*. Si no aparece, el archivo viajó dentro de la historia de Git.

---

## Paso 7: Verificarlo desde fuera, que es lo que cuenta

**Por qué**: `git lfs ls-files` responde por tu clon local. La comprobación real es qué guarda el servidor, y se hace sin clonar nada.

```bash
# Lo que hay en la historia de Git: el puntero
curl -s -H "$H" "$API/projects/$P/repository/files/assets%2Flogo-grande%2Epng?ref=main" \
  | jq -r '.content' | base64 -d
```

```
version https://git-lfs.github.com/spec/v1
oid sha256:4d7a214614ab2935c943f9e0ff69d22eadbb8f32b1258daaa5e2ca24d17e2393
size 1049748
```

**Verifica**: la primera línea es exactamente `version https://git-lfs.github.com/spec/v1`. Eso es lo que comprueba `binario-guardado-en-lfs`.

Y el binario de verdad, que GitLab resuelve si se lo pides:

```bash
curl -s -H "$H" \
  "$API/projects/$P/repository/files/assets%2Flogo-grande%2Epng/raw?ref=main&lfs=true" \
  | file -
# /dev/stdin: PNG image data, 1024 x 1024
```

Sin `lfs=true`, ese mismo `raw` devuelve el puntero. La diferencia entre las dos llamadas es la diferencia entre "lo que hay en Git" y "lo que representa".

Comprueba también que el `.gitattributes` llegó y que el avatar sigue vivo:

```bash
curl -s -H "$H" "$API/projects/$P/repository/tree?ref=main&per_page=100" \
  | jq -r '.[].name' | grep -E '^(\.gitattributes|logo\.png)$'

curl -s -H "$H" "$API/projects/$P/repository/files/logo%2Epng?ref=main" \
  | jq -r '.content' | base64 -d | file -
# /dev/stdin: PNG image data, 128 x 128
```

**Verifica**: la última línea dice *PNG image data*, no *ASCII text*. Si dijera texto, tu patrón se llevó el `logo.png` y el avatar del proyecto está roto.

---

## Paso 8: Medir el coste y ensayar la migración sin ejecutarla

**Por qué**: el valor de LFS es un número, y conviene verlo. Y conviene saber qué habría hecho falta si la decisión se hubiera tomado tarde.

```bash
curl -s -H "$H" "$API/projects/$P?statistics=true" \
  | jq '.statistics | {repository_size, lfs_objects_size, storage_size}'
```

**Verifica**: `lfs_objects_size` es del orden del megabyte y `repository_size` sigue siendo pequeño. Si `lfs_objects_size` sale `0`, espera unos segundos: las estadísticas se recalculan en segundo plano tras cada `push`.

Y el ensayo, que **no cambia nada**:

```bash
git lfs migrate info --everything
```

Devuelve, por extensión, cuánto ocupa en la historia. Es el comando que dice si un repositorio tiene un problema de binarios y de qué tamaño.

> [!WARNING]
> El comando que sí actúa es `git lfs migrate import`, y **reescribe la historia entera**: todos los SHA cambian y quien tenga un clon tendrá que rehacerlo. Aquí no hace falta, porque el `.gitattributes` entró antes que el binario. Si algún día lo necesitas: copia con `git clone --mirror` primero, avisa a todo el mundo, y cuenta con que las ramas protegidas rechazarán el `push --force` hasta que se desprotejan (Semana 07).

---

## Paso 9: Ver qué pasa sin `git-lfs`

**Por qué**: es el fallo que más desconcierta en un pipeline, y verlo una vez a propósito ahorra la tarde en que ocurra de verdad.

```bash
cd $(mktemp -d)
GIT_LFS_SKIP_SMUDGE=1 git clone "$GITLAB_URL/$PROYECTO.git" clon-sin-lfs
cd clon-sin-lfs
ls -l assets/logo-grande.png
file assets/logo-grande.png
```

```
-rw-r--r-- 1 tu tu 133 assets/logo-grande.png
assets/logo-grande.png: ASCII text
```

**Verifica**: el archivo pesa 133 bytes y es texto. Eso es exactamente lo que ve un runner cuya imagen no trae `git-lfs`, y por qué falla con un error sobre un archivo corrupto que no menciona LFS.

Y así se arregla, cuando el binario sí hace falta:

```bash
git lfs pull
file assets/logo-grande.png
# PNG image data, 1024 x 1024
```

> [!TIP]
> `GIT_LFS_SKIP_SMUDGE=1` no es solo un experimento: en un job de pipeline que no toca imágenes, ahorra descargar el almacén entero. Vuelve en la Semana 09.

---

## ✅ Resultado

- [ ] `git lfs version` responde y los filtros están en tu configuración global
- [ ] `lfs_enabled` es `true` en el proyecto
- [ ] `.gitattributes` en la raíz, con un patrón por carpeta y no por extensión suelta
- [ ] El `.gitattributes` entró en un commit **anterior** al del binario
- [ ] `assets/logo-grande.png` existe y pesa más de un megabyte en tu disco
- [ ] Lo que hay en el repositorio es un puntero de tres líneas, verificado por API
- [ ] `logo.png` de la raíz sigue siendo un PNG y el avatar se ve
- [ ] Sabes qué muestra un clon hecho sin `git-lfs`, y cómo arreglarlo

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 04
```

Con esta práctica se cierran las dieciséis comprobaciones de la semana.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `git: 'lfs' is not a git command` | `git-lfs` no está instalado | Paso 1, según tu sistema |
| El `push` no muestra *Uploading LFS objects* | El archivo no encaja con ningún patrón | `git check-attr filter -- assets/logo-grande.png` tiene que decir `filter: lfs` |
| `git show HEAD:<ruta>` saca bytes ilegibles | El binario entró antes que el `.gitattributes` | Deshaz el commit con `git reset --soft HEAD~1`, ordena los commits y repite |
| El `push` falla con un error del servidor de LFS | `lfs_enabled` está en `false` en el proyecto | Paso 2 |
| El avatar del proyecto sale roto | El patrón se llevó `logo.png` | Estrecha el patrón, y saca el archivo de LFS con `git lfs untrack "*.png"` y un commit nuevo |
| `404` al leer el archivo por API | El punto de la ruta va literal | `assets%2Flogo-grande%2Epng`, con `%2F` y `%2E` |
| La comprobación `binario-guardado-en-lfs` falla | El archivo no está en LFS, o la ruta no es esa | El nombre exacto es `assets/logo-grande.png` |
| `lfs_objects_size` sigue a `0` | Las estadísticas se recalculan en segundo plano | Espera unos segundos y repite la llamada |
| Un clon nuevo trae archivos de 133 bytes | Ese clon no tiene `git-lfs`, o se usó `GIT_LFS_SKIP_SMUDGE=1` | `git lfs install` y `git lfs pull` |
| Borraste el binario y el repositorio sigue igual de grande | La historia lo conserva | Es el comportamiento esperado; solo `git lfs migrate` lo cambia, y reescribe la historia |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Práctica 03 — Snippets e insignias](03-snippets-e-insignias.md) | **Práctica 04** | [Proyecto de la Semana 04](../3-proyecto/README.md) |

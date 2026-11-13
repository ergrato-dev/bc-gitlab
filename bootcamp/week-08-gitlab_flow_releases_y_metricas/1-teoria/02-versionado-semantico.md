# Versionado semántico

> Un número de versión es un contrato con quien usa tu código. `0.1.1` promete "lo mismo que la `0.1.0`, con menos fallos". Si dentro hay un cambio de comportamiento, el número miente, y quien confió en él lo descubre en producción.

---

## 🎯 Objetivos

- Leer y escribir versiones `MAYOR.MENOR.PARCHE` con pre-release y metadatos, y ordenarlas
- Aplicar las reglas especiales de la zona `0.y.z` y fijarlas por escrito
- Deducir la siguiente versión a partir de los tipos de Conventional Commits que garantiza el hook de la Semana 07
- Crear un tag anotado y firmado, verificarlo, y saber qué hace GitLab con él

---

## 1. Qué problema resuelve

Sin una regla, el número de versión lo decide el humor del día: "esta es grande, la llamo 2.0". Quien depende de tu código no puede saber si actualizar es seguro sin leer todos los cambios.

[SemVer](https://semver.org/lang/es/) convierte el número en información. Mirando solo el número, quien usa `app` sabe qué esperar de una actualización.

---

## 2. Cómo funciona

### 2.1 Las tres cifras

| Sube | Cuándo | Las de la derecha |
|---|---|---|
| `MAYOR` | Cambia algo que rompe a quien ya te usaba: quitas una función, cambias lo que devuelve | Vuelven a `0` |
| `MENOR` | Añades algo nuevo sin romper lo existente | `PARCHE` vuelve a `0` |
| `PARCHE` | Arreglas un fallo sin cambiar la interfaz | — |

La interfaz es lo que alguien usa desde fuera: en `app`, las funciones públicas del dominio (`calcularMulta`, `puedePrestar` o las tuyas) y lo que devuelven. Un cambio interno que no se ve desde fuera no sube nada por sí solo.

### 2.2 Pre-release y metadatos

- **Pre-release**: un guion y un identificador. `0.2.0-rc.1` es anterior a `0.2.0`. Sirve para publicar una candidata sin prometer estabilidad.
- **Metadatos de build**: un `+` y lo que quieras. `0.2.0+20261113` es **igual** a `0.2.0` a efectos de orden. Nadie debería depender de ellos.

El orden no es alfabético: `0.10.0` va después de `0.9.0`, y `1.0.0-rc.2` antes que `1.0.0`. Por eso `sort -V` y no `sort` cuando ordenas versiones en un script.

### 2.3 La zona `0.y.z`

SemVer dice que **con `MAYOR = 0` cualquier cosa puede cambiar**: es desarrollo inicial y no hay contrato. En la práctica, casi todos los proyectos adoptan una regla más útil, y el bootcamp la escribe en el ADR-006:

| Cambio | Con `MAYOR ≥ 1` | En `0.y.z` |
|---|---|---|
| Rompe la interfaz | `MAYOR` | `MENOR` |
| Añade sin romper | `MENOR` | `MENOR` |
| Arregla | `PARCHE` | `PARCHE` |

Así, quien fija `app` a `0.1.x` recibe arreglos y nunca un cambio de comportamiento. La `1.0.0` se publica el día que decides que la interfaz es estable y vas a pagar el coste de romperla.

### 2.4 La versión que dictan los commits

El hook de la Semana 07 garantiza que cada asunto que llega a `main` sigue Conventional Commits. Eso convierte la siguiente versión en algo que se deduce, no que se discute:

| En los commits desde la última versión | Siguiente versión (con `MAYOR ≥ 1`) |
|---|---|
| Algún `!` tras el tipo, o un trailer `BREAKING CHANGE:` | `MAYOR` |
| Algún `feat` | `MENOR` |
| Solo `fix` o `perf` | `PARCHE` |
| Solo `docs`, `chore`, `ci`, `test`, `refactor`, `style`, `build` | Ninguna: no hay nada que publicar |

Con `app` en `0.y.z`, la primera fila sube `MENOR` (apartado 2.3).

```bash
git log --format=%s v0.1.0..main | grep -Eq '^[a-z]+(\(.+\))?!:' && echo "rompe"
git log --format=%s v0.1.0..main | grep -Eq '^feat(\(.+\))?!?:'   && echo "añade"
git log --format=%s v0.1.0..main | grep -Eq '^(fix|perf)(\(.+\))?:' && echo "arregla"
```

El tipo decide **cuánto** sube la versión. **Qué** se cuenta en el CHANGELOG lo decide otra cosa, el trailer `Changelog:` (teoría [04](04-changelog-generado.md)), porque no todo `feat` le interesa a quien usa `app`, y a veces un `refactor` sí.

### 2.5 Tags ligeros, anotados y firmados

Una versión, en Git, es un tag. Hay tres clases:

| Tag | Qué guarda | Cómo se crea |
|---|---|---|
| Ligero | Solo un puntero al commit | `git tag v0.1.0` |
| Anotado | Un objeto propio: autor, fecha y mensaje | `git tag -a v0.1.0 -m "v0.1.0"` |
| Firmado | Un tag anotado con firma | `git tag -s v0.1.0 -m "v0.1.0"` |

Una versión siempre es anotada: tiene que decir quién la hizo y cuándo. Y en este bootcamp, firmada: con `gpg.format ssh` de la Semana 02, `git tag -s` firma con la misma clave SSH que los commits.

```bash
git tag -s v0.1.0 -m "v0.1.0"
git tag -v v0.1.0          # Good "git" signature for <tu-email> with ED25519 key ...
git cat-file -t v0.1.0     # tag   (un tag ligero diría commit)
```

`git tag -v` necesita el `allowedSignersFile` de la Semana 02. Si dice `No signature`, el tag no se firmó: bórralo en local y repítelo antes de empujarlo.

### 2.6 Lo que hace GitLab con un tag `v*`

- **Lo protege** (Semana 07): solo un Maintainer lo crea, nadie lo mueve, y solo se borra desde la web o la API.
- **No lo pasa por el hook**: el `pre-receive` de `app` ignora todo lo que no sea `refs/heads/*`.
- **Lo usa como límite del CHANGELOG**: busca el tag anterior por orden SemVer, ignorando los que tienen pre-release (teoría [04](04-changelog-generado.md)).
- **No crea una release por sí solo**. El tag es la versión; la release es la página que la explica (teoría [03](03-releases-en-gitlab.md)).

Por API, `.../repository/tags/v0.1.0` devuelve `target` (el objeto tag) y `commit.id` (el commit). Si son iguales, el tag es ligero.

---

## 3. Cómo se configura

No hay nada que activar: SemVer es una convención. Lo que sí se configura es su cumplimiento:

| Regla | Dónde |
|---|---|
| El formato del tag | Tags protegidos `v*` (Semana 07) y el `tag_regex` del CHANGELOG (teoría [04](04-changelog-generado.md)) |
| Qué sube cada tipo de commit | ADR-006, apartado "Versiones" |
| Que el tag sea anotado y firmado | La práctica 03 y la rúbrica. La API no distingue un tag firmado |

Si tu lenguaje guarda la versión en un archivo (`package.json`, `pyproject.toml`, `Cargo.toml`), súbela en la misma merge request que el CHANGELOG. El tag y el archivo tienen que decir lo mismo.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Subir `MAYOR` por marketing | Quien te usa espera una rotura y no la encuentra, o al revés | El número lo dictan los cambios |
| Un parche con un cambio de comportamiento "pequeño" | Rompe a quien fijó `0.1.x` confiando en el contrato | Sube `MENOR` |
| Tags ligeros para versiones | Sin autor, fecha ni mensaje; no se pueden firmar | `git tag -s` |
| Mover un tag ya publicado | Dos personas con la "misma" versión y código distinto | Nunca: publica la siguiente. La protección de `v*` lo impide |
| Quedarse en `0.y.z` para siempre | Nunca prometes nada, y nadie puede confiar en las actualizaciones | `1.0.0` cuando la interfaz se use de verdad |
| Ordenar versiones como texto | `0.10.0` antes de `0.9.0` | `sort -V` o una comparación SemVer |

---

## 5. Trucos

- **La última versión publicada**: `git describe --tags --abbrev=0 --match 'v*'`.
- **Qué entra en la siguiente**: `git log --oneline v0.1.0..main`. Si solo hay `docs` y `chore`, no hay nada que publicar.
- **Comprobar la firma de todos los tags**: `git tag -l 'v*' | xargs -n1 git tag -v 2>&1 | grep -c 'Good'`.

---

## 📚 Recursos Adicionales

- [Versionado Semántico 2.0.0](https://semver.org/lang/es/) — la especificación, en español
- [Conventional Commits 1.0.0](https://www.conventionalcommits.org/es/v1.0.0/) — la relación entre tipos y SemVer
- [Git — Etiquetado](https://git-scm.com/book/es/v2/Fundamentos-de-Git-Etiquetado) — tags ligeros y anotados
- [`git tag`](https://git-scm.com/docs/git-tag) — `-s`, `-v` y `gpg.format`

---

## ✅ Checklist de Verificación

- [ ] Sabes qué cifra sube un `feat`, un `fix` y un `feat!` con `MAYOR ≥ 1` y en `0.y.z`
- [ ] Sabes ordenar `0.9.0`, `0.10.0`, `1.0.0-rc.1` y `1.0.0`
- [ ] Sabes por qué una versión es un tag anotado y no uno ligero
- [ ] Has firmado y verificado un tag en un repositorio de prueba
- [ ] Sabes distinguir por API un tag anotado de uno ligero

---

[← Anterior: Modelos de ramas](01-modelos-de-ramas.md) · [Volver a la Semana 08](../README.md) · [Siguiente: Releases en GitLab →](03-releases-en-gitlab.md)

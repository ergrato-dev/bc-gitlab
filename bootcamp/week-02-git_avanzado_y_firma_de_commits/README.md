# Semana 02 — Git quirúrgico y commits firmados

> El autor de un commit es un campo de texto que escribe cualquiera. Esta semana aprendes a
> operar la historia con precisión y a firmarla, para que lo que dice tu repositorio sea
> además demostrable.

---

## 🎯 Objetivos de la Semana

Al terminar serás capaz de:

- Explicar el modelo de objetos de Git y por qué el SHA de un commit depende de toda su historia
- Partir un cambio grande en commits que significan algo, con `git add -p`
- Reescribir la historia con `rebase -i`, `--fixup` y `--autosquash`, y comprobar cada commit con `--exec`
- Recuperar commits, ramas y rebases perdidos con `git reflog`
- Escribir mensajes Conventional Commits con cuerpo y trailers, y leerlos por la API
- Firmar todos tus commits con SSH y no perder la firma en la siguiente reescritura
- Interpretar las cuatro comprobaciones que GitLab hace sobre una firma y diagnosticar cada fallo
- Encontrar el commit que rompió algo con `git bisect run`, sin responder a mano
- Buscar en la historia por contenido con `-S`, `-G`, `-L` y `blame`
- Saber qué hacer, y en qué orden, cuando un secreto entra al repositorio
- Dejar en `app` el código mínimo del producto, con tests y una historia lineal y firmada

---

## 📋 Prerrequisitos

- **Semana 01 completada**: instancia en `http://localhost:8888`, grupo `plataforma-<tu-dominio>`, proyecto `app` con al menos un commit y `~/.bc-gitlab` configurado con `PROYECTO=` y `GITLAB_TOKEN=`
- **Git 2.34 o superior** — la firma SSH no existe antes. `git --version`
- **Node.js 22 o superior** — para el código y los tests. `node --version`
- **Tu correo de Git es el mismo que el de tu usuario de GitLab**: si no, ninguna firma se verificará
- **Perfil de laboratorio**: `base` — ver [perfiles-de-laboratorio](../../docs/perfiles-de-laboratorio.md)
- Saber `clone`, `commit`, `push` y qué es una rama. Todo lo demás se explica aquí

---

## 🗂️ Estructura de la Semana

```
week-02-git_avanzado_y_firma_de_commits/
├── README.md                  # Este archivo
├── rubrica-evaluacion.md      # Cómo se evalúa
├── checks.json                # Las 14 comprobaciones automáticas
├── 0-assets/                  # Diagramas
├── 1-teoria/                  # 8 archivos, un concepto cada uno
├── 2-practicas/               # 4 prácticas sobre tu repositorio y tu instancia
├── 3-proyecto/                # La capa 2 de tu plataforma
├── 4-recursos/                # Libros, vídeos y enlaces
└── 5-glosario/                # Términos de esta semana
```

---

## 📝 Contenidos

### Teoría

| Archivo | Tema | Duración |
|---|---|:--:|
| [01 — El modelo de objetos](1-teoria/01-el-modelo-de-objetos.md) | Blobs, trees, commits, referencias, y por qué el SHA lo cambia todo | 15 min |
| [02 — El índice y el commit quirúrgico](1-teoria/02-el-indice-y-el-commit-quirurgico.md) | `add -p`, `restore`, `reset`, `stash` y qué no debe entrar nunca | 15 min |
| [03 — Reescribir la historia](1-teoria/03-reescribir-la-historia.md) | `amend`, `rebase -i`, `--fixup`, `--autosquash`, `--onto`, `--force-with-lease` | 20 min |
| [04 — Mover y recuperar cambios](1-teoria/04-mover-y-recuperar-cambios.md) | `cherry-pick`, `revert`, `reset` y el reflog como red de seguridad | 15 min |
| [05 — Conventional Commits y trailers](1-teoria/05-conventional-commits-y-trailers.md) | Título, cuerpo, tipos, `BREAKING CHANGE`, `Signed-off-by` | 10 min |
| [06 — Firmar commits con SSH](1-teoria/06-firmar-commits-con-ssh.md) | `gpg.format ssh`, `allowed_signers`, `%G?` y el fallo silencioso del rebase | 20 min |
| [07 — Cómo verifica GitLab una firma](1-teoria/07-como-verifica-gitlab-una-firma.md) | Las cuatro comprobaciones, los estados, la API, y qué es Premium | 15 min |
| [08 — Arqueología y cirugía de emergencia](1-teoria/08-arqueologia-y-cirugia-de-emergencia.md) | `bisect run`, `-S`/`-G`/`-L`, `blame`, `worktree` y los secretos filtrados | 10 min |

### Prácticas

| Práctica | Qué haces | Duración |
|---|---|:--:|
| [01 — Firmar tus commits](2-practicas/01-firmar-tus-commits.md) | Clave dedicada, registro con uso de firma, primer commit verificado y un fallo provocado a propósito | 50 min |
| [02 — El producto mínimo](2-practicas/02-el-producto-minimo.md) | Tres funciones de tu dominio, nueve tests, y cada cambio en su propio commit firmado | 50 min |
| [03 — Cirugía sobre la historia](2-practicas/03-cirugia-sobre-la-historia.md) | Ensuciar la historia, limpiarla con `--fixup`/`--autosquash`, conservar las firmas e integrar en lineal | 50 min |
| [04 — Arqueología y auditoría](2-practicas/04-arqueologia-y-auditoria.md) | `bisect run`, la lupa, `blame`, `worktree` y auditar las firmas por API | 50 min |

### Proyecto

La **capa 2** de tu plataforma: el código mínimo del producto con sus tests, y la historia lineal, convencional y firmada con la que entrará todo lo demás durante veinticuatro semanas. Detalles en [3-proyecto](3-proyecto/README.md).

---

## ⏱️ Distribución del Tiempo (8 horas)

| Bloque | Tiempo |
|---|:--:|
| Teoría (8 archivos) | 2 h 00 |
| Prácticas (4 × 50 min) | 3 h 20 |
| Proyecto | 2 h 00 |
| Revisión y verificación | 40 min |
| **Total** | **8 h 00** |

> [!TIP]
> Lee las teorías 06 y 07 **antes** de la práctica 01. Es la única dependencia estricta de la semana: sin ellas, cuando la API devuelva `unknown_key` no vas a saber qué mirar, y ese estado no se explica solo.

---

## ⚠️ Los tres errores que cuestan la semana

1. **Registrar la clave de firma con uso `auth`.** Es la misma clave, el mismo archivo, y GitLab no la mira: todos tus commits salen `unknown_key`, la interfaz solo dice "Unverified" y no hay ninguna pista. Además, el uso **no se puede cambiar**: hay que borrar la clave y registrarla otra vez.
2. **Reescribir sin `rebase.gpgSign`.** El rebase recrea los commits con otro SHA, la firma cubría el anterior, y Git no vuelve a firmar ni avisa. Media historia se queda sin firmar en silencio.
3. **Hacer `npm install` antes del `.gitignore`.** `node_modules` entra al índice, entra a la historia, y sacarlo de ahí ya es cirugía mayor que cambia todos los SHA y borra todas las firmas.

---

## 🎩 Trucos y atajos

| Truco | Cómo |
|---|---|
| Auditar de un vistazo qué está firmado | `git log --pretty='%h %G? %s' -20` — `N` es sin firma, `G` es correcto |
| Encontrar lo no firmado antes de empujar | `git log --pretty='%h %G? %s' origin/main..HEAD \| grep -v '^\S* G '` |
| Colocar los arreglos solos, sin tocar el editor | `git commit --fixup <sha>` y luego `git rebase -i --autosquash <base>` |
| Que `--autosquash` sea el comportamiento normal | `git config --global rebase.autosquash true` |
| Comprobar que **cada** commit pasa los tests | `git rebase --exec "npm test" main` |
| Revisar tu propia reescritura antes de forzar | `git range-diff respaldo...HEAD` |
| Deshacer el último `reset`, `rebase` o `merge` | `git reset --hard ORIG_HEAD` |
| Recuperar una rama borrada sin saber su SHA | `git reflog \| grep <nombre-de-la-rama>` |
| Volver a la rama anterior, como `cd -` | `git switch -` |
| Ver la historia de una función concreta | `git log -L :nombreDeLaFuncion:archivo.ts` |
| Encontrar quién tocó una línea sin cambiar el recuento | `git log -G "patron"` — `-S` no lo ve |
| `blame` que no señale a quien reindentó | `git blame -w -C -C archivo.ts` |
| Bisecar sin responder a nada | `git bisect start HEAD <bueno>` y `git bisect run npm test` |
| Saltar un commit que no se puede probar en un bisect | Que el script salga con **código 125** |
| Los diez blobs más grandes de la historia | `git rev-list --objects --all \| git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' \| awk '$1=="blob"{print $3,$4}' \| sort -rn \| head` |
| Buscar un token en **toda** la historia, no solo en HEAD | `git grep "glpat-" $(git rev-list --all) --` |
| Por qué exactamente sale "Unverified" | `curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/projects/$P/repository/commits/main/signature" \| jq -r .verification_status` |
| Ver el uso de todas tus claves de golpe | `curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/user/keys" \| jq -r '.[] \| "\(.usage_type)\t\(.title)"'` |
| Dos ramas a la vez sin clonar dos veces | `git worktree add ../app-hotfix main` |
| Que Git recuerde cómo resolviste un conflicto | `git config --global rerere.enabled true` |

---

## 📌 Entregables

1. Clave SSH dedicada a firmar, con contraseña, registrada en GitLab con `usage_type=signing`
2. Firma configurada en global: `gpg.format`, `user.signingkey`, `commit.gpgsign`, `tag.gpgsign` y `rebase.gpgSign`
3. `allowed_signers` configurado y `git verify-commit HEAD` en verde
4. `.gitignore` en la raíz, cubriendo `node_modules/`, `dist/` y `.env`
5. `package.json` en la raíz, con el script `test`
6. `src/` con al menos tres funciones de tu dominio y su archivo de tests, `npm test` en verde
7. `.git-blame-ignore-revs` versionado en la raíz
8. `main` con ocho commits o más, todos con título Conventional Commits
9. Historia lineal: ningún commit con dos padres
10. Al menos un commit con cuerpo que explica el porqué, y al menos uno con `Signed-off-by`
11. El último commit de `main` con `verification_status: "verified"` en la API
12. Solo la rama `main` en la instancia

---

## ✅ Verificación

```bash
./scripts/verificar-semana.sh 02
```

Las 14 comprobaciones tienen que pasar. Si alguna falla, la pista te dice en qué práctica y en qué paso se arregla.

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Semana 01 — Instalación y arquitectura](../week-01-instalacion_y_arquitectura_de_gitlab_ce/README.md) | **Semana 02** | [Semana 03 — Grupos, subgrupos, roles y namespaces](../week-03-grupos_proyectos_y_permisos/README.md) |

[← Volver al inicio del bootcamp](../README.md)

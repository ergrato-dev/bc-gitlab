# 📖 Glosario — Semana 02

Términos que aparecen esta semana. El nombre real de la feature va en inglés entre paréntesis, y el **tier** cuando aplica.

El glosario acumulado de toda la plataforma está en [glosario-global](../../../docs/glosario-global.md).

---

## A

**`allowed_signers`** — Archivo local que asocia claves públicas con correos, para que Git sepa **de quién** es una firma. Sin él, Git valida la firma pero responde `No principal matched.` y `%G?` devuelve `U`. Empareja por clave: el correo es solo la etiqueta que Git muestra.

**`--amend`** — Rehace el último commit. No lo modifica: crea uno nuevo con el mismo padre y mueve la rama. El anterior queda huérfano.

**`--autosquash`** — Opción de `git rebase -i` que coloca automáticamente cada commit `fixup!` o `squash!` detrás de su destino y lo marca. Se activa por defecto con `rebase.autosquash true`.

## B

**`bisect`** — Búsqueda binaria sobre la historia para encontrar el commit que introdujo un fallo. Con `git bisect run <comando>` se ejecuta sola: 240 commits son ocho pruebas.

**Blob** — El objeto que guarda el contenido de un archivo. **No** guarda su nombre: eso vive en el tree que lo referencia.

**`blame`** — Atribuye cada línea de un archivo al commit que la escribió. Se usa con `-w -C -C` para que no señale a quien reindentó, y con `.git-blame-ignore-revs` para excluir formateos masivos. Free, y GitLab lee ese archivo en su vista de *Blame*.

## C

**`cherry-pick`** — Aplica el cambio de un commit concreto donde estés, creando un commit nuevo con otro SHA. Con `-x` deja constancia del origen en el mensaje.

**Commit** — Objeto con un tree raíz, cero o más padres, autor, committer, mensaje y firma opcional. Es texto plano, y su SHA es el hash de ese texto.

**Committer** — Quien crea el commit, frente al **autor**, que escribió el cambio. Se separan al hacer `cherry-pick` o `rebase`. **GitLab verifica la firma contra el correo del committer**, no el del autor.

**Conventional Commits** — Convención de mensaje `tipo(ambito): resumen`. Free, y en la Semana 08 es lo que decide la versión. El CHANGELOG lo genera otro trailer, `Changelog:`.

## D

**DCO** (*Developer Certificate of Origin*) — Declaración de que tienes derecho a aportar el código, expresada con el trailer `Signed-off-by:`. Es texto plano: no demuestra identidad.

## F

**`fixup`** — Commit marcado para fundirse con otro anterior, descartando su mensaje. Se crea con `git commit --fixup <sha>` y se aplica con `rebase -i --autosquash`.

**`filter-repo`** — Herramienta externa para reescribir la historia entera (sacar un archivo, sustituir texto). Sustituye a `filter-branch`. Cambia todos los SHA, deja la historia sin firmar y obliga a que todos vuelvan a clonar.

**`--force-with-lease`** — Empuje forzado que solo se aplica si la rama remota sigue donde tú creías. Es la forma segura de `--force`, y no protege de quien ya clonó.

## G

**`%G?`** — Marcador de formato de `git log` con el estado de la firma: `G` buena, `B` mala, `U` válida de firmante desconocido, `X` clave caducada, `R` clave revocada, `E` no comprobable, `N` sin firma.

**`gpg.format ssh`** — Opción que le dice a Git que firme con SSH en vez de GPG. El prefijo `gpg.` es histórico.

## H

**`HEAD`** — Dónde estás. Normalmente contiene `ref: refs/heads/main`; si contiene un SHA directamente, está *desprendido* (**detached HEAD**) y los commits que hagas no los sigue ninguna rama.

## I

**Índice** (*staging area*) — Archivo binario `.git/index` con lo que entrará en el próximo commit. Es la herramienta que permite el commit quirúrgico con `git add -p`.

## O

**`ORIG_HEAD`** — Referencia que Git escribe automáticamente antes de `reset`, `rebase` y `merge`. Un "deshacer" gratis: `git reset --hard ORIG_HEAD`.

**`other_user`** — Estado de verificación: la firma es válida y la clave está registrada, pero el correo del committer no pertenece a su dueño.

## P

**Pickaxe** (`-S`) — Busca commits donde **cambia el número de apariciones** de un texto. No encuentra modificaciones que no alteren ese recuento: para eso está `-G`.

**Push rule** — **Premium**. Regla de servidor que rechaza pushes que incumplen una política, incluida *Reject unsigned commits*. En CE se sustituye con un server hook `pre-receive` (Semana 07).

## R

**`range-diff`** — Compara dos versiones de una misma serie de commits. Es la forma de revisar tu propia reescritura antes de forzar el push.

**`rebase`** — Reaplica una serie de commits sobre otra base. Crea commits nuevos: otros SHA, y sin firma salvo que `rebase.gpgSign` esté activo.

**`reflog`** — Registro local de todos los movimientos de `HEAD` y de cada rama. Recupera commits perdidos por `reset --hard`, ramas borradas y rebases fallidos. **No** recupera cambios que nunca fueron un commit. Caduca a los 30-90 días.

**Referencia** (*ref*) — Archivo de 41 bytes con un SHA. Una rama es una referencia móvil; un tag ligero, una fija.

**`rerere`** (*reuse recorded resolution*) — Git memoriza cómo resolviste un conflicto y lo reaplica cuando vuelve a aparecer. Se activa con `rerere.enabled true`.

**`revert`** — Crea un commit que deshace otro. La historia crece en vez de reescribirse: es lo correcto cuando el commit ya lo tienen otros. GitLab lo ofrece con un botón, Free.

## S

**`same_user_different_email`** — Estado de verificación: la clave es tuya, pero el correo del commit no está confirmado en tu cuenta.

**Server hook** — **Free**. Script que se ejecuta en el servidor al recibir un push. Es lo único en CE que **bloquea de verdad** un push que incumple una regla.

**SHA-1** — El algoritmo de hash que identifica los objetos. Git admite además SHA-256 (`--object-format=sha256`) y GitLab puede crear proyectos con `repository_object_format=sha256`, pero los dos formatos no intercambian objetos entre sí.

**`Signed-off-by`** — Trailer de texto plano del DCO. **No es una firma**: cualquiera puede escribir el nombre de cualquiera.

**`signing`** — Valor de `usage_type` al registrar una clave SSH en GitLab. Los valores posibles son `auth`, `signing` y `auth_and_signing` (el de por defecto). Una clave con uso `auth` **no verifica firmas**, y no se puede cambiar el uso después: hay que borrarla y registrarla otra vez.

**`stash`** — Aparca cambios sin comprometerlos. Vive solo en tu clon: no viaja en un push.

## T

**Tag anotado** — Objeto con autor, mensaje y firma que apunta a un commit. Frente al **tag ligero**, que es solo una referencia y se puede mover sin dejar rastro.

**Trailer** — Línea `Clave: valor` en el último bloque del mensaje de un commit. GitLab los expone en la API, en el campo `trailers`.

**Tree** — Objeto que representa un directorio: una lista de nombres con sus permisos, apuntando a blobs y a otros trees.

## U

**`unknown_key`** — Estado de verificación: la firma es válida, pero la clave no está registrada en la instancia **con uso de firma**. Es el fallo más común al empezar.

**`usage_type`** — Ver **`signing`**.

## V

**`verified`** — Estado de verificación que produce el distintivo **Verified**. Exige las cuatro comprobaciones: firma válida, clave de firma registrada, correo del dueño de la clave, y correo confirmado. Free en CE.

**`verified_system`** — Firmado por la propia instancia, no por una persona. Es lo que ocurre con los commits hechos desde la interfaz web o el Web IDE.

## W

**`worktree`** — Árbol de trabajo adicional sobre el mismo repositorio: otro directorio, otra rama activa, los mismos objetos. Evita clonar dos veces para atender un arreglo urgente.

---

[← Volver a la Semana 02](../README.md)

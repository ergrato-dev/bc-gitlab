# Firmar commits con SSH

> El campo `author` de un commit es texto libre. Cualquiera puede escribir tu nombre y tu correo. La firma es lo único que convierte "dice que es de Ana" en "es de Ana".

## 🎯 Objetivos

- Explicar por qué la autoría de un commit no demuestra nada por sí sola
- Configurar la firma SSH: `gpg.format`, `user.signingkey`, `commit.gpgsign`
- Verificar firmas en local con `allowed_signers` y `git verify-commit`
- Evitar el fallo silencioso que deja media historia sin firmar tras un rebase

---

## 1. Qué problema resuelve

Prueba esto en un repositorio de juguete:

```bash
git -c user.name="Linus Torvalds" -c user.email="torvalds@linux-foundation.org" \
    commit --allow-empty -m "feat: parece de otra persona"
git log -1 --format='%an <%ae>'
# Linus Torvalds <torvalds@linux-foundation.org>
```

No hay ningún truco: **el autor de un commit es un campo de texto que escribe quien comete el commit**. Git nunca lo comprueba, y GitLab tampoco puede: recibe el objeto ya construido.

Las consecuencias no son teóricas. Si alguien consigue empujar a tu repositorio —un token filtrado, una sesión abierta, un runner comprometido—, puede insertar código con la autoría de quien quiera, y la auditoría posterior señalará a la persona equivocada.

La firma criptográfica cierra ese agujero: añade al commit una prueba de que quien lo creó tenía la **clave privada** de alguien concreto. Ese es el escalón entre un repositorio y una **cadena de suministro** auditable, que es donde acaba este bootcamp en la Semana 20 firmando también las imágenes con Cosign.

---

## 2. Tres formatos, uno recomendado

| Formato | Cómo se gestiona | Coste de arranque |
|---|---|---|
| **SSH** | La misma clave con la que ya empujas | Tres líneas de configuración |
| **GPG** | Llavero propio, servidores de claves, caducidades, subclaves | Alto, y es donde la gente abandona |
| **X.509 (S/MIME)** | Certificados emitidos por una CA | Alto, tiene sentido en empresas con PKI |

GitLab verifica los tres desde hace años. Este bootcamp usa **SSH**, y no por comodidad: la clave ya existe desde la Semana 01, la gestión de claves ya está resuelta, y el resultado en GitLab es exactamente el mismo distintivo **Verified**.

> [!NOTE]
> Git soporta firma SSH desde la versión **2.34** (noviembre de 2021). Compruébalo con `git --version`; el bootcamp asume 2.46 o superior.

---

## 3. Configurarlo

Tres opciones, y la cuarta que casi todo el mundo olvida:

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519_firma.pub
git config --global commit.gpgsign true
git config --global tag.gpgsign true
```

| Opción | Qué hace |
|---|---|
| `gpg.format ssh` | Usa SSH en vez de GPG. El nombre `gpg.*` es histórico |
| `user.signingkey` | La **clave pública** (`.pub`) con la que firmar. Git deduce la privada |
| `commit.gpgsign true` | Firma **todos** los commits sin escribir `-S` |
| `tag.gpgsign true` | Firma también los tags anotados |

Firmar un commit suelto sin activar el automático:

```bash
git commit -S -m "feat(prestamos): calcular la multa por retraso"
```

Y la que evita el desastre silencioso de la sección 6:

```bash
git config --global rebase.gpgSign true
```

> [!IMPORTANT]
> `user.signingkey` apunta a la clave **pública**. Es contraintuitivo —firma la privada— pero Git usa el `.pub` como identificador para localizar la privada correspondiente, sea un archivo en disco o una clave cargada en el agente. Si prefieres pegar la clave en línea, se admite el formato `key::ssh-ed25519 AAAA...`.

Si la clave privada tiene contraseña, el agente evita escribirla en cada commit:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_firma
```

---

## 4. Verificar en local: `allowed_signers`

Aquí aparece la parte que sorprende: **Git no sabe de quién es una clave**. Puede comprobar que la firma es matemáticamente válida, pero no que esa clave sea tuya. Esa asociación vive en un archivo que tú controlas:

```bash
mkdir -p ~/.config/git
echo "ana@ejemplo.com $(cat ~/.ssh/id_ed25519_firma.pub)" >> ~/.config/git/allowed_signers
git config --global gpg.ssh.allowedSignersFile ~/.config/git/allowed_signers
```

El formato es `<correo o patrón> <tipo-de-clave> <clave>`, una línea por firmante.

Los dos fallos que verás, y que no significan lo mismo:

```bash
# El archivo no está configurado o no existe:
git log --show-signature -1
# error: gpg.ssh.allowedSignersFile needs to be configured and exist for ssh signature verification
# ...
# No signature

# El archivo existe pero esa clave no está dentro:
# Good "git" signature with ED25519 key SHA256:gEJWvoh...
# No principal matched.
```

En el segundo caso la firma **es** válida: Git dice *"esto está bien firmado, pero no sé de quién es esta clave"*, y `%G?` devuelve `U` en vez de `G`.

> [!NOTE]
> `allowed_signers` empareja por **clave**, no por correo. El correo de cada línea es la etiqueta con la que Git te informa de quién firmó, no una comprobación contra el autor del commit: si pones tu clave con el correo de otra persona, Git dirá alegremente `Good "git" signature for esa-otra-persona`. La comprobación de que la clave y el correo del commit pertenecen al mismo usuario la hace **GitLab**, y es el tema de la teoría 07.

Con el archivo correcto:

```bash
git log --show-signature -1
# Good "git" signature for ana@ejemplo.com with ED25519 key SHA256:gEJWvoh...

git verify-commit HEAD
# Good "git" signature for ana@ejemplo.com with ED25519 key SHA256:gEJWvoh...
```

### El indicador `%G?`, para revisar muchos commits de golpe

```bash
git log --pretty='%h %G? %aN %s' -10
```

| Valor | Significado |
|---|---|
| `G` | Firma buena |
| `B` | Firma **mala**: el commit se alteró después de firmarlo |
| `U` | Buena, pero de validez desconocida |
| `X` | Buena, de una clave **caducada** |
| `Y` | Buena, de una clave caducada en el momento de firmar |
| `R` | Buena, de una clave **revocada** |
| `E` | No se pudo comprobar (falta la clave, o `allowed_signers`) |
| `N` | **Sin firma** |

`N` es el que hay que perseguir. Auditar una rama entera es una línea:

```bash
git log --pretty='%h %G? %s' origin/main | grep -v '^\S* G '
```

Si no imprime nada, toda la rama está firmada y verificada.

> [!TIP]
> Deja `log.showSignature` en `false` (es lo que hace [setup-entorno](../../../docs/setup-entorno.md)). En `true`, **todos** los `git log` se llenan de bloques de firma y dejas de leerlos. Para comprobar, `--show-signature` explícito o `%G?`.

---

## 5. Firmar tags

Un tag anotado y firmado es lo que convierte `v1.0.0` en una afirmación verificable de que esa versión es la que tú publicaste. Es la base de la Semana 08 (releases) y de la Semana 20 (cadena de suministro).

```bash
git tag -s v0.1.0 -m "Primera version del calculo de multas"
git tag -v v0.1.0
```

Con `tag.gpgsign true`, `git tag -a` ya firma sin `-s`.

> [!WARNING]
> Un **tag ligero** (`git tag v0.1.0`, sin `-a` ni `-s`) no es un objeto: es una referencia suelta que apunta a un commit. No lleva autor, ni mensaje, ni firma, y se puede mover sin dejar rastro. Para versiones, siempre tag anotado y firmado.

---

## 6. El fallo silencioso: reescribir borra las firmas

Es el error que se lleva la mitad de las historias "firmadas" que hay por ahí, y es fácil de reproducir:

```bash
git log --pretty='%h %G? %s' -3
# 3a9d2f7 G feat(prestamos): calcular multa
# c4e8b1a G feat(socios): puede prestar
# 8f0b6c1 G docs: crear el README

git rebase -i HEAD~3      # reordenas dos commits

git log --pretty='%h %G? %s' -3
# 7e1b9d4 N feat(socios): puede prestar
# 2f8c3a1 N feat(prestamos): calcular multa
# 8f0b6c1 G docs: crear el README
```

La razón sale de la teoría 01: **el rebase no mueve commits, los recrea**. Los commits nuevos tienen otro SHA, y una firma que cubría el SHA anterior no vale para ellos. Git, por defecto, no vuelve a firmar.

Y no avisa. No hay error, no hay advertencia: la historia queda sin firmar y el distintivo **Verified** desaparece de GitLab sin que nadie lo note hasta la auditoría.

Las dos formas de evitarlo:

```bash
git config --global rebase.gpgSign true    # todos los rebase firman
git rebase -i --gpg-sign HEAD~3            # este rebase firma
```

Lo mismo pasa con `cherry-pick` (`-S`) y con `filter-repo`, que reescribe la historia entera y deja **todo** sin firmar.

> [!IMPORTANT]
> Tras cualquier reescritura, comprueba antes de empujar:
>
> ```bash
> git log --pretty='%h %G? %s' origin/main..HEAD
> ```
>
> Todo lo que vayas a empujar tiene que salir con `G`. Este comando es el que evita la única forma realista de suspender el proyecto de esta semana.

---

## 7. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Firmar "cuando toca" | Una historia con firmas sueltas no demuestra nada: el atacante no firma y ya está | `commit.gpgsign true` |
| Reescribir sin `rebase.gpgSign` | Media historia sin firmar y sin ningún aviso | `rebase.gpgSign true` |
| La misma clave para autenticar y firmar | Un compromiso afecta a las dos funciones a la vez, y la rotación obliga a rehacer las dos | Una clave por función (práctica 01) |
| Clave de firma sin contraseña en un portátil | Quien tenga el disco firma como tú para siempre | Contraseña + `ssh-agent` |
| `log.showSignature = true` | Tanto ruido que se deja de leer el log | `--show-signature` cuando haga falta |
| Tag ligero para una versión | Se mueve sin dejar rastro y no se puede verificar | `git tag -s` |
| Creer que `Signed-off-by` firma | Es texto plano | Firma SSH; el trailer es otra cosa (teoría 05) |

---

## 8. Trucos

**Firmar un commit ya hecho** (solo si no lo has empujado):

```bash
git commit --amend --no-edit -S
```

**Firmar de golpe toda la historia que aún no has empujado:**

```bash
git rebase --gpg-sign origin/main
```

**Ver la firma en crudo, dentro del objeto:**

```bash
git cat-file -p HEAD | head -20
# gpgsig -----BEGIN SSH SIGNATURE-----
```

Confirma que la firma **es parte del commit**, no un adorno externo. Por eso alterar el commit la invalida.

**Firmar y verificar un archivo cualquiera con la misma clave**, que es lo que hace Git por debajo:

```bash
ssh-keygen -Y sign -f ~/.ssh/id_ed25519_firma -n file informe.txt
ssh-keygen -Y verify -f ~/.config/git/allowed_signers -I ana@ejemplo.com \
  -n file -s informe.txt.sig < informe.txt
```

**Auditar quién ha firmado qué en el último mes:**

```bash
git log --since='1 month ago' --pretty='%G? %aN' | sort | uniq -c | sort -rn
```

---

## 📚 Recursos Adicionales

- [Firma SSH en la documentación de GitLab](https://docs.gitlab.com/ee/user/project/repository/signed_commits/ssh.html) — el procedimiento oficial, con la parte de registrar la clave
- [`git config` — sección `gpg.ssh`](https://git-scm.com/docs/git-config#Documentation/git-config.txt-gpgsshallowedSignersFile) — el formato exacto de `allowed_signers`
- [`ssh-keygen -Y`](https://man.openbsd.org/ssh-keygen#Y) — la primitiva de firma que Git usa por debajo
- [Anuncio de firma SSH en Git 2.34](https://github.blog/2021-11-15-highlights-from-git-2-34/) — por qué se añadió y qué resuelve

---

## ✅ Checklist de Verificación

- [ ] `git config --global --get-regexp 'gpg|sign'` muestra las cinco opciones
- [ ] `git verify-commit HEAD` dice `Good "git" signature`
- [ ] Tu `allowed_signers` tiene tu correo y tu clave de firma
- [ ] Sabes por qué un rebase deja los commits con `N` y cómo evitarlo
- [ ] Sabes distinguir un tag ligero de uno anotado y firmado

---

| Anterior | Siguiente |
|---|---|
| [← 05 — Conventional Commits y trailers](05-conventional-commits-y-trailers.md) | [07 — Cómo verifica GitLab una firma →](07-como-verifica-gitlab-una-firma.md) |

[← Volver a la Semana 02](../README.md)

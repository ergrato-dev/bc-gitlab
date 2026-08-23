# Práctica 01 — Firmar tus commits

> Una clave dedicada a firmar, registrada como tal, y la primera firma que GitLab da por buena. Con la comprobación de qué pasa cuando algo no cuadra.

**Duración estimada**: 50 min
**Prerrequisitos**: Semana 01 completada (instancia viva, grupo, proyecto `app` con un commit y `~/.bc-gitlab` configurado) · Teorías [06](../1-teoria/06-firmar-commits-con-ssh.md) y [07](../1-teoria/07-como-verifica-gitlab-una-firma.md) leídas

---

## Contexto

En la Semana 01 registraste una clave SSH para empujar código. Esa clave se creó con el uso por defecto, `auth_and_signing`, así que **técnicamente ya podría firmar**.

Aquí vas a hacer otra cosa: **una clave nueva, solo para firmar**. No es burocracia. Autenticar y firmar son dos funciones con vidas distintas:

- La clave de autenticación se usa a diario, viaja en el agente, se rota cuando cambias de máquina.
- La clave de firma respalda afirmaciones que quedan **para siempre** en la historia. Rotarla obliga a razonar sobre qué firmas siguen valiendo.

Mezclarlas significa que un compromiso de una compromete la otra, y que no puedes rotar una sin tocar la otra. Es el mismo principio de mínimo privilegio que en la Semana 01 aplicaste a los tokens.

---

## Paso 1: Comprobar el punto de partida

**Por qué**: la firma SSH necesita Git 2.34 o superior, y necesita que el correo de tus commits sea el mismo que tiene tu usuario de GitLab. Si algo de esto falla, lo demás falla después y con un mensaje que no lo explica.

```bash
git --version
# git version 2.46.0   (2.34 o superior)

source ~/.bc-gitlab
echo "Git:    $(git config --global user.email)"
echo "GitLab: $(curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/user" | jq -r '.email')"
```

**Verifica**: los dos correos son idénticos. Si no, corrige el que esté mal antes de seguir — un commit firmado con otro correo no se verifica.

Mira también qué claves tienes ya, y con qué uso:

```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/user/keys" \
  | jq -r '.[] | "\(.usage_type)\t\(.title)"'
# auth_and_signing	laboratorio-bootcamp
```

---

## Paso 2: Crear una clave dedicada a firmar

**Por qué**: separar funciones. Esta clave no se usará nunca para autenticar; solo para firmar.

```bash
ssh-keygen -t ed25519 -C "firma-bootcamp" -f ~/.ssh/id_ed25519_firma
```

Ponle contraseña. Es la clave que respalda tu identidad en la historia del repositorio: si alguien copia el archivo, firma como tú y no hay forma de distinguirlo.

Para no escribirla en cada commit, cárgala en el agente:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_firma
```

**Verifica**:

```bash
ssh-keygen -l -f ~/.ssh/id_ed25519_firma.pub
# 256 SHA256:gEJWvohpoKCHkSeHS4/9ygqCN8/otLj9dq5186reWsU firma-bootcamp (ED25519)
```

Apunta esa huella `SHA256:...`: es la que GitLab usará para reconocer tus firmas.

---

## Paso 3: Configurar Git para firmar

**Por qué**: sin `commit.gpgsign`, firmar depende de acordarte de escribir `-S`. Y `rebase.gpgSign` es el que evita que la próxima reescritura te deje media historia sin firma (teoría 06, sección 6).

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519_firma.pub
git config --global commit.gpgsign true
git config --global tag.gpgsign true
git config --global rebase.gpgSign true
```

**Verifica** las cinco de golpe:

```bash
git config --global --get-regexp 'gpg|signingkey'
```

```
gpg.format ssh
user.signingkey /home/tu/.ssh/id_ed25519_firma.pub
commit.gpgsign true
tag.gpgsign true
rebase.gpgsign true
```

Tienen que estar las cinco; el orden depende de en qué orden se escribieron en tu `~/.gitconfig` y da igual. Git guarda las claves en minúsculas: `rebase.gpgsign` es la misma opción que `rebase.gpgSign`. Si [setup-entorno](../../../docs/setup-entorno.md) ya te dejó las tres primeras, aquí solo cambia el valor de `user.signingkey`.

> [!NOTE]
> `user.signingkey` apunta a la clave **pública**, con `.pub`. Es contraintuitivo y es correcto: Git la usa como identificador para encontrar la privada.

---

## Paso 4: Registrar la clave en GitLab con uso de firma

**Por qué**: GitLab solo mira las claves registradas con uso `signing` o `auth_and_signing` (teoría 07, comprobación 2). Una clave con uso `auth` produce `unknown_key` en todos tus commits, sin ninguna pista en la interfaz.

**Con `curl`**:

```bash
source ~/.bc-gitlab
curl -s --request POST "$GITLAB_URL/api/v4/user/keys" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data-urlencode "title=firma-bootcamp" \
  --data-urlencode "usage_type=signing" \
  --data-urlencode "key=$(cat ~/.ssh/id_ed25519_firma.pub)" \
  | jq '{id, title, usage_type}'
```

```json
{
  "id": 3,
  "title": "firma-bootcamp",
  "usage_type": "signing"
}
```

**Con `glab`**, si lo prefieres:

```bash
glab api --method POST user/keys \
  -f title="firma-bootcamp" \
  -f usage_type=signing \
  -f key="$(cat ~/.ssh/id_ed25519_firma.pub)"
```

**Con la UI**: `Preferences → SSH Keys → Add new key`. Pega el contenido de `~/.ssh/id_ed25519_firma.pub`, y en **Usage type** elige `Signing`.

**Verifica** que ahora tienes dos claves con usos distintos:

```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/user/keys" \
  | jq -r '.[] | "\(.usage_type)\t\(.title)"'
# auth_and_signing	laboratorio-bootcamp
# signing	firma-bootcamp
```

> [!IMPORTANT]
> **El uso no se puede cambiar después.** No hay endpoint para editarlo: si te equivocas, hay que borrar la clave (`DELETE /user/keys/:id`) y volver a registrarla. Y una misma clave pública **no se puede registrar dos veces** en toda la instancia: su huella es única. Por eso hace falta un par de claves nuevo y no vale con volver a subir la de la Semana 01.

---

## Paso 5: Enseñarle a Git de quién es la clave

**Por qué**: Git verifica que la firma es válida, pero no sabe a quién pertenece la clave. Esa asociación vive en `allowed_signers`, y sin ella `git log --show-signature` da un error que parece un fallo de la firma y no lo es.

```bash
mkdir -p ~/.config/git
echo "$(git config --global user.email) $(cat ~/.ssh/id_ed25519_firma.pub)" \
  >> ~/.config/git/allowed_signers
git config --global gpg.ssh.allowedSignersFile ~/.config/git/allowed_signers
```

**Verifica** el contenido, que tiene que ser una sola línea con tu correo delante:

```bash
cat ~/.config/git/allowed_signers
# tu@correo.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... firma-bootcamp
```

---

## Paso 6: Tu primer commit firmado

**Por qué**: es el entregable central de la semana. Todo lo demás se apoya en que esto funcione.

```bash
cd ~/ruta/a/app     # el proyecto app de la Semana 01
git switch main
git pull --rebase
```

Actualiza el README con la capa que añade esta semana:

```bash
cat >> README.md <<'EOF'

## Convenciones del repositorio

- **Commits firmados**: todo commit de `main` va firmado con SSH y verificado por la instancia.
- **Conventional Commits**: `tipo(ambito): resumen en imperativo`.
- **Historia lineal**: sin commits de fusión. Se integra con rebase.
EOF

git add README.md
git commit -m "docs: declarar las convenciones de commits del repositorio"
```

Fíjate en que **no** has escrito `-S`: lo hace `commit.gpgsign`.

**Verifica en local** antes de empujar:

```bash
git log --show-signature -1 | head -3
# commit 3a9d2f7...
# Good "git" signature for tu@correo.com with ED25519 key SHA256:gEJWvoh...

git log --pretty='%h %G? %s' -1
# 3a9d2f7 G docs: declarar las convenciones de commits del repositorio
```

`G` significa firma buena y firmante conocido. Ahora empuja:

```bash
git push
```

**Verifica en GitLab**, que es la comprobación que cuenta:

```bash
source ~/.bc-gitlab
P="${PROYECTO//\//%2F}"
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$P/repository/commits/main/signature" \
  | jq '{signature_type, verification_status, clave: .key.title, uso: .key.usage_type}'
```

```json
{
  "signature_type": "SSH",
  "verification_status": "verified",
  "clave": "firma-bootcamp",
  "uso": "signing"
}
```

**Con la UI**: abre el proyecto → `Code → Commits`. Junto al commit hay un distintivo **Verified**. Púlsalo y verás la huella de la clave.

---

## Paso 7: Provocar un fallo, para reconocerlo cuando ocurra

**Por qué**: la interfaz muestra "Unverified" para tres fallos distintos. Verlo una vez a propósito, con la API delante, ahorra la tarde en que ocurra de verdad.

Vas a crear un commit firmado correctamente **pero con un correo que no es tuyo**, en una rama de usar y tirar:

```bash
git switch -c pruebas/firma
git -c user.email="fantasma@ejemplo.com" commit --allow-empty \
  -m "chore: commit de prueba con correo ajeno"
git push -u origin pruebas/firma
```

**Verifica** qué dice la API de ese commit:

```bash
SHA=$(git rev-parse HEAD)
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$P/repository/commits/$SHA/signature" \
  | jq '{verification_status, clave: .key.title}'
```

```json
{
  "verification_status": "other_user",
  "clave": "firma-bootcamp"
}
```

La firma es válida y la clave es la tuya. Lo que falla es la comprobación 3: **el correo del commit no pertenece al dueño de la clave**. Ese es el diagnóstico que la interfaz no te da.

Ahora limpia el experimento:

```bash
git switch main
git branch -D pruebas/firma
git push origin --delete pruebas/firma
```

**Verifica** que solo queda `main`:

```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$P/repository/branches" | jq -r '.[].name'
# main
```

---

## Paso 8: Comprobar que la reescritura no te deja sin firma

**Por qué**: es el fallo silencioso de la semana. Con `rebase.gpgSign` puesto en el paso 3, esto tiene que salir bien; comprobarlo ahora es lo que te asegura que la práctica 03 no te destroce las firmas.

```bash
git commit --allow-empty -m "chore: commit de prueba para el rebase"
git log --pretty='%h %G? %s' -2

# Reescribe el mensaje del último commit sin abrir el editor.
GIT_SEQUENCE_EDITOR="sed -i '1s/^pick/reword/'" GIT_EDITOR=true git rebase -i HEAD~1
git log --pretty='%h %G? %s' -2
```

**Verifica**: el commit reescrito sigue saliendo con `G`. Si sale `N`, `rebase.gpgSign` no está puesto: vuelve al paso 3.

Deshaz la prueba, que no aporta nada a la historia:

```bash
git reset --hard HEAD~1
git log --pretty='%h %G? %s' -1
```

---

## ✅ Resultado

- [ ] `git --version` es 2.34 o superior y tu correo de Git coincide con el de GitLab
- [ ] Existe `~/.ssh/id_ed25519_firma`, con contraseña
- [ ] Las cinco opciones de firma están en tu configuración global
- [ ] GitLab tiene dos claves: una `auth_and_signing` y otra `signing`
- [ ] `git log --show-signature -1` dice `Good "git" signature`
- [ ] La API devuelve `verification_status: "verified"` para `main`
- [ ] Has visto `other_user` con tus propios ojos y sabes qué comprobación falló
- [ ] Solo queda la rama `main` en el remoto

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 02
```

De momento pasarán las tres comprobaciones de firma y la de la rama única. Las demás llegan con las prácticas 02 y 03.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `error: gpg.ssh.allowedSignersFile needs to be configured` | Falta el paso 5 | Crea el archivo y apunta `gpg.ssh.allowedSignersFile` a él |
| `No principal matched.` y `%G?` da `U` | La clave no está en `allowed_signers` | Añade la línea con **esa** clave pública |
| `error: Load key ... invalid format` | `user.signingkey` apunta a la clave privada | Tiene que apuntar al archivo `.pub` |
| Pide la contraseña de la clave en cada commit | La clave no está en el agente | `ssh-add ~/.ssh/id_ed25519_firma` |
| La API devuelve `unknown_key` | La clave está registrada con uso `auth` | Bórrala (`DELETE /user/keys/:id`) y regístrala con `usage_type=signing` |
| La API devuelve `other_user` | El correo del commit no es de tu cuenta | `git config --global user.email` y volver a firmar el commit |
| La API devuelve `same_user_different_email` | El correo es tuyo pero no está confirmado | Confírmalo en `Preferences → Emails`, o usa el principal |
| `404` al pedir la firma | Ese commit no está firmado | Es la respuesta normal para un commit sin firma |
| `Key has already been taken` al registrar | Esa clave pública ya está registrada en la instancia | Genera un par nuevo: no se puede duplicar una clave |
| `%G?` da `N` tras un rebase | Falta `rebase.gpgSign true` | Ponlo y refirma: `git rebase --gpg-sign origin/main` |

---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| — | [Práctica 02 — El producto mínimo →](02-el-producto-minimo.md) |

[← Volver a la Semana 02](../README.md)

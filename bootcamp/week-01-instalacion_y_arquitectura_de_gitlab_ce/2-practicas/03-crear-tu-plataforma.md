# Práctica 03 — Crear tu plataforma

> El grupo, el proyecto y el primer commit que van a crecer durante veintiséis semanas.

**Duración estimada**: 50 min
**Prerrequisitos**: Prácticas 01 y 02 completadas · [proyecto-hilo-conductor](../../../docs/proyecto-hilo-conductor.md) leído y **dominio elegido**

---

## Contexto

Todo lo que construyas de aquí a la Semana 26 cuelga de lo que crees hoy. No es un ejercicio: es la primera capa de tu plataforma, y no se va a borrar.

Por eso hay una decisión que conviene tomar bien desde el principio: **el proyecto cuelga del grupo, no de tu espacio personal**. Funciona igual de las dos formas, y hacerlo mal significa rehacer permisos, rutas y URLs en la Semana 03.

> [!IMPORTANT]
> Si todavía no has elegido dominio, párate y lee [proyecto-hilo-conductor](../../../docs/proyecto-hilo-conductor.md). Necesitas uno sobre el que puedas inventar issues creíbles durante seis meses.

---

## Paso 1: Registrar tu identidad de Git

**Por qué**: si el correo de tus commits no coincide con el de tu usuario de GitLab, tus commits aparecen atribuidos a un desconocido. Y en la Semana 02, la verificación de firma fallará sin motivo aparente.

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu@correo.com"
```

**Verifica** que coincide con lo que registraste en tu perfil de GitLab:

```bash
source ~/.bc-gitlab
echo "Git:    $(git config --global user.email)"
echo "GitLab: $(curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/user" | jq -r '.email')"
```

Los dos valores tienen que ser el mismo. Si no, corrige el que esté mal.

---

## Paso 2: Registrar tu clave SSH

**Por qué**: vas a empujar código durante veintiséis semanas. Con SSH no escribes credenciales cada vez, y en la Semana 02 esta misma clave firmará tus commits.

Si aún no la tienes, créala:

```bash
ssh-keygen -t ed25519 -C "tu@correo.com" -f ~/.ssh/id_ed25519_gitlab
```

Súbela por API:

```bash
source ~/.bc-gitlab
curl -s --request POST "$GITLAB_URL/api/v4/user/keys" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data-urlencode "title=laboratorio-bootcamp" \
  --data-urlencode "key=$(cat ~/.ssh/id_ed25519_gitlab.pub)" | jq '{id, title}'
```

**Con la UI**, si lo prefieres: `Preferences → SSH Keys`, pegar el contenido de `~/.ssh/id_ed25519_gitlab.pub`.

Como el SSH de tu instancia escucha en el puerto 2224, díselo a tu cliente una vez:

```bash
cat >> ~/.ssh/config <<'EOF'

Host gitlab-lab
  HostName localhost
  Port 2224
  User git
  IdentityFile ~/.ssh/id_ed25519_gitlab
EOF
```

**Verifica**:

```bash
ssh -T git@gitlab-lab
# Welcome to GitLab, @root!
```

---

## Paso 3: Crear el grupo

**Por qué**: el grupo es el contenedor de todo. En la Semana 03 le colgarás subgrupos y usuarios con roles; en la 12, un proyecto de componentes; en la 24, la infraestructura. Empieza existiendo hoy.

Sustituye `biblioteca` por tu dominio en los comandos que siguen.

**Con `glab`**:

```bash
glab api --method POST groups \
  -f name="Plataforma Biblioteca" \
  -f path="plataforma-biblioteca" \
  -f description="Plataforma DevOps del sistema de prestamos de una biblioteca. Bootcamp GitLab CE." \
  -f visibility=private
```

**Con `curl`**:

```bash
source ~/.bc-gitlab
curl -s --request POST "$GITLAB_URL/api/v4/groups" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data-urlencode "name=Plataforma Biblioteca" \
  --data-urlencode "path=plataforma-biblioteca" \
  --data-urlencode "description=Plataforma DevOps del sistema de prestamos de una biblioteca. Bootcamp GitLab CE." \
  --data-urlencode "visibility=private" | jq '{id, path, description}'
```

**Con la UI**: el botón `+` de la barra superior → `New group`.

> [!NOTE]
> La descripción tiene que superar los 20 caracteres: es una de las comprobaciones automáticas. No es capricho, es la primera vez que se te pide que un recurso explique para qué existe. Vas a agradecerlo en la Semana 26, cuando audites las veinticinco capas.

**Verifica**:

```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/groups/plataforma-biblioteca" | jq '{id, path, description}'
```

---

## Paso 4: Crear el proyecto `app` dentro del grupo

**Por qué**: `app` es el producto. Es donde vivirá el código que los pipelines construyen, los escáneres analizan y los despliegues publican.

Necesitas el ID numérico del grupo:

```bash
GRUPO_ID=$(curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/groups/plataforma-biblioteca" | jq '.id')
echo "$GRUPO_ID"
```

Y lo creas dentro:

```bash
curl -s --request POST "$GITLAB_URL/api/v4/projects" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data-urlencode "name=app" \
  --data-urlencode "path=app" \
  --data-urlencode "namespace_id=$GRUPO_ID" \
  --data-urlencode "visibility=private" \
  --data-urlencode "default_branch=main" \
  --data-urlencode "initialize_with_readme=false" \
  --data-urlencode "description=Gestion de prestamos de biblioteca. Producto del hilo conductor del Bootcamp GitLab CE." \
  | jq '{id, path_with_namespace, visibility, default_branch, namespace: .namespace.kind}'
```

**Con la UI**: entra en el grupo → `New project` → `Create blank project`. Asegúrate de que arriba pone el grupo y no tu usuario.

**Verifica** las cuatro cosas que se comprueban:

```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/plataforma-biblioteca%2Fapp" \
  | jq '{visibility, default_branch, namespace_kind: .namespace.kind, descripcion_larga: ((.description // "") | length >= 20)}'
```

```json
{
  "visibility": "private",
  "default_branch": "main",
  "namespace_kind": "group",
  "descripcion_larga": true
}
```

> [!TIP]
> `namespace.kind` es la comprobación que separa hacerlo bien de hacerlo rápido. Si dice `user`, el proyecto está en tu espacio personal: bórralo y vuelve a crearlo dentro del grupo. Cuesta un minuto ahora y una hora en la Semana 03.

---

## Paso 5: Clonar y fijar la rama por defecto

**Por qué**: el proyecto está vacío y sin rama. La rama por defecto se establece con el primer push, así que hay que asegurarse de que se llame `main`.

```bash
git clone git@gitlab-lab:plataforma-biblioteca/app.git
cd app
git switch -c main 2>/dev/null || git checkout -b main
```

**Verifica**:

```bash
git branch --show-current
# main
```

---

## Paso 6: El primer commit

**Por qué**: un repositorio sin README es un repositorio que nadie sabe para qué existe. Y el `README.md` en la raíz es una de las comprobaciones de la semana.

```bash
cat > README.md <<'EOF'
# app — Gestión de préstamos de biblioteca

Producto del hilo conductor del **Bootcamp GitLab CE**.

## Dominio

Sistema de préstamos de una biblioteca: socios, libros y préstamos con fecha de
devolución. El dominio se eligió en la Semana 01 y no cambia durante las 26 semanas.

## Estado

| Semana | Capa añadida |
|:--:|---|
| 01 | El proyecto existe, dentro del grupo, con este README |

## Plataforma

Este proyecto es una de las piezas del grupo `plataforma-biblioteca`. La
plataforma que lo construye, lo prueba y lo despliega se monta a lo largo del
bootcamp.
EOF

git add README.md
git commit -m "docs: crear el README con el dominio del proyecto"
git push -u origin main
```

**Verifica** que el commit llegó y que el README está en la raíz:

```bash
source ~/.bc-gitlab
P=plataforma-biblioteca%2Fapp
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$P/repository/commits?ref_name=main" | jq -r '.[0].title'
# docs: crear el README con el dominio del proyecto

curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$P/repository/tree?ref=main" | jq -r '.[].name'
# README.md
```

---

## Paso 7: Anotar el proyecto en la configuración del bootcamp

**Por qué**: el autograding necesita saber contra qué proyecto verificar. Si no se lo dices, hay que pasárselo a mano en cada ejecución.

```bash
grep -q '^PROYECTO=' ~/.bc-gitlab \
  && sed -i 's|^PROYECTO=.*|PROYECTO=plataforma-biblioteca/app|' ~/.bc-gitlab \
  || echo 'PROYECTO=plataforma-biblioteca/app' >> ~/.bc-gitlab

cat ~/.bc-gitlab
```

**Verifica**:

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh --doctor | tail -3
```

Ya no debería avisar de que falta el proyecto.

---

## Paso 8: Localizar tu repositorio en el disco

**Por qué**: cierra el círculo con la Práctica 02. Ahora sí tienes un repositorio que encontrar bajo `@hashed`.

Consigue el ID del proyecto y calcula su ruta:

```bash
source ~/.bc-gitlab
ID=$(curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/plataforma-biblioteca%2Fapp" | jq '.id')
HASH=$(echo -n "$ID" | sha256sum | cut -d' ' -f1)
echo "ID: $ID"
echo "Ruta: @hashed/${HASH:0:2}/${HASH:2:2}/${HASH}.git"
```

**Verifica** que ese directorio existe de verdad:

```bash
docker compose exec gitlab ls "/var/opt/gitlab/git-data/repositories/@hashed/${HASH:0:2}/${HASH:2:2}/${HASH}.git" | head
# HEAD  config  hooks  objects  refs ...
```

> [!TIP]
> Acabas de recorrer el camino completo: de la ruta que ves en la interfaz, al ID en PostgreSQL, al hash, al directorio en disco que sirve Gitaly. Ese recorrido es lo que te va a permitir recuperar una instancia rota en la Semana 22.

---

## Paso 9: Comprobar la semana entera

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 01
```

**Verifica** que pasan las 12:

```
12 de 12 verificaciones superadas.
```

Si alguna falla, la pista dice en qué paso se arregla.

---

## ✅ Resultado

- [ ] Tu correo de Git coincide con el de tu usuario de GitLab
- [ ] Tienes una clave SSH registrada y `ssh -T git@gitlab-lab` responde con tu nombre
- [ ] Existe el grupo `plataforma-<tu-dominio>` con descripción
- [ ] Existe el proyecto `app` **dentro del grupo**, privado, con descripción y rama `main`
- [ ] Hay al menos un commit tuyo y un `README.md` en la raíz
- [ ] `~/.bc-gitlab` tiene `PROYECTO=`
- [ ] Has localizado tu repositorio bajo `@hashed`

```bash
./scripts/verificar-semana.sh 01
```

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `Permission denied (publickey)` | La clave no está registrada, o falta el puerto 2224 | Repite el paso 2 y usa el host `gitlab-lab` |
| `ssh -T` pide contraseña | Está usando otra clave | `ssh -T -i ~/.ssh/id_ed25519_gitlab git@gitlab-lab`; revisa `~/.ssh/config` |
| El proyecto salió en tu espacio personal | Faltó `namespace_id` | Bórralo y créalo de nuevo con el ID del grupo |
| `404` al consultar el proyecto por ruta | Falta codificar la barra | `plataforma-biblioteca%2Fapp`, no `/` |
| `default_branch` es `null` | El repositorio está vacío | Se fija con el primer push (paso 6) |
| `400 Bad Request` al crear el grupo | El `path` ya existe o tiene caracteres inválidos | Solo minúsculas, números y guiones |
| `descripcion_larga: false` | La descripción tiene menos de 20 caracteres | `curl --request PUT .../projects/<id> --data-urlencode "description=..."` |
| El push dice `main -> main (fetch first)` | El proyecto se creó con README desde la UI | `git pull --rebase origin main` y vuelve a empujar |
| `verificar-semana.sh` dice que falta el proyecto | `PROYECTO=` mal escrito en `~/.bc-gitlab` | Tiene que ser `<grupo>/<proyecto>`, sin URL ni `.git` |

---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| [← Práctica 02 — Recorrerla por dentro](02-recorrer-la-instancia-por-dentro.md) | [Práctica 04 — Hablar con la API →](04-hablar-con-la-api.md) |

[← Volver a la Semana 01](../README.md)

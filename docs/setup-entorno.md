# 🛠️ Preparar el Entorno

Todo el bootcamp corre en tu máquina. No instalas GitLab, ni Ruby, ni PostgreSQL, ni Redis: Docker levanta la instancia entera y tú la administras desde fuera.

Esta guía se hace **una vez**, antes de la Semana 01. Después no vuelves aquí salvo que algo se rompa.

---

## 1. Requisitos

| Requisito | Mínimo | Por qué |
|---|---|---|
| RAM | **16 GB** | Las semanas 16, 21, 23 y 25 levantan Kubernetes, observabilidad o alta disponibilidad |
| Disco | 40 GB libres | La instancia, las imágenes, los backups y el registry |
| CPU | 4 núcleos | GitLab arranca mal por debajo |
| Sistema | Linux, macOS o Windows con WSL2 | Docker Desktop en macOS y Windows |

> [!NOTE]
> Con 8 GB llegas hasta la Semana 15 y te quedas fuera de las cuatro semanas más interesantes. Ver [perfiles-de-laboratorio.md](perfiles-de-laboratorio.md).

**Conocimiento previo**: `clone`, `commit`, `push` y qué es una rama. Nada más. La Semana 02 se encarga del resto de Git.

---

## 2. Instalar las herramientas

### Docker

Instrucciones por sistema operativo en [docker-setup.md](docker-setup.md).

```bash
docker --version          # 27+
docker compose version    # 2.32+
docker run --rm hello-world
```

En Linux, añádete al grupo `docker` para no escribir `sudo` cien veces al día:

```bash
sudo usermod -aG docker "$USER"   # cierra sesión y vuelve a entrar
```

### Git

```bash
git --version    # 2.46+
```

| Sistema | Comando |
|---|---|
| Debian/Ubuntu | `sudo apt install git` |
| Fedora | `sudo dnf install git` |
| macOS | `brew install git` |
| Windows | Dentro de WSL2, como Ubuntu |

### `glab` — el CLI de GitLab

La interfaz web cambia de sitio los botones cada pocas versiones. El CLI es estable, y es lo que usan las prácticas.

| Sistema | Comando |
|---|---|
| Debian/Ubuntu | Descarga el `.deb` de [gitlab.com/gitlab-org/cli/-/releases](https://gitlab.com/gitlab-org/cli/-/releases) |
| Fedora | `sudo dnf install glab` |
| macOS | `brew install glab` |
| Arch | `sudo pacman -S glab` |

```bash
glab --version    # 1.50+
```

### `jq` — para el autograding

```bash
sudo apt install jq      # Debian/Ubuntu
sudo dnf install jq      # Fedora
brew install jq          # macOS
jq --version             # 1.7+
```

### k3d y kubectl — solo para las semanas 16 y 25

Puedes dejarlo para entonces, pero instalarlo ahora ahorra una interrupción a mitad de semana.

> [!WARNING]
> El instalador oficial de k3d se distribuye como `curl … | bash`, que ejecuta
> sin leer un script descargado de internet. Descárgalo, míralo y ejecútalo
> después: es un minuto y es el hábito que este bootcamp enseña.

```bash
curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh -o install-k3d.sh
less install-k3d.sh          # revísalo
bash install-k3d.sh
rm install-k3d.sh

k3d version                  # 5.7+
kubectl version --client     # 1.32+
```

En Fedora, macOS y Arch hay paquete y te ahorras el script: `dnf install k3d`,
`brew install k3d`, `pacman -S k3d`.

---

## 3. Clonar el bootcamp y levantar la instancia

```bash
git clone https://github.com/ergrato-dev/bc-gitlab.git
cd bc-gitlab
cp .env.example .env
```

Revisa `.env`. Si el puerto 8888 ya está ocupado en tu máquina, cámbialo aquí y no en el `docker-compose.yml`.

```bash
docker compose --profile base up -d
docker compose logs -f gitlab
```

El primer arranque tarda **unos 5 minutos**: GitLab compila su configuración, migra la base de datos y arranca una docena de servicios. Es normal que `docker compose ps` muestre `health: starting` un buen rato. Cuando el log deje de moverse y aparezca `gitlab Reconfigured!`, ya está.

```bash
docker compose exec gitlab /opt/lab/lab-health
```

---

## 4. Primer acceso

```bash
docker compose exec gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

Abre `http://localhost:8888` y entra como `root` con esa contraseña.

**Cámbiala inmediatamente** en `Preferences → Password`. El archivo `initial_root_password` se borra solo a las 24 h, así que si no la cambias y la pierdes, te toca resetearla desde la consola de Rails.

---

## 5. Tu identidad en Git

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu@correo.com"
```

El correo tiene que ser **el mismo** que registres en tu usuario de GitLab. Si no coincide, tus commits aparecen como de un desconocido y la verificación de firma falla.

---

## 6. Clave SSH

Se usa para dos cosas: empujar código sin escribir la contraseña, y firmar los commits.

```bash
ssh-keygen -t ed25519 -C "tu@correo.com" -f ~/.ssh/id_ed25519_gitlab
```

Pega la clave pública en GitLab, en `Preferences → SSH Keys`:

```bash
cat ~/.ssh/id_ed25519_gitlab.pub
```

Como la instancia escucha SSH en el puerto 2224, díselo a tu cliente SSH una vez:

```bash
cat >> ~/.ssh/config <<'EOF'

Host gitlab-lab
  HostName localhost
  Port 2224
  User git
  IdentityFile ~/.ssh/id_ed25519_gitlab
EOF
```

Comprueba:

```bash
ssh -T git@gitlab-lab
# Welcome to GitLab, @root!
```

---

## 7. Firmar los commits con esa misma clave

Firmar con SSH es mucho más simple que con GPG y GitLab lo verifica igual. Es la Semana 02 quien lo explica a fondo; aquí lo dejas configurado.

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519_gitlab.pub
git config --global commit.gpgsign true
```

Y registra la misma clave **otra vez** en GitLab, ahora en `Preferences → SSH Keys` con el uso **Signing** (o `Authentication & Signing`). Una clave registrada solo para autenticación no verifica firmas: es el fallo más común de este paso.

---

## 8. Tokens: cuál usar y cuándo

GitLab tiene tres tipos y se confunden constantemente.

| Tipo | Dónde se crea | Para qué | Vida |
|---|---|---|---|
| **Personal** | `Preferences → Access tokens` | `glab`, el autograding, scripts tuyos | La que le pongas |
| **De proyecto** | `Settings → Access tokens` del proyecto | Un pipeline que toca **ese** proyecto | Ligado al proyecto |
| **De grupo** | `Settings → Access tokens` del grupo | Automatización que cruza varios proyectos | Ligado al grupo |

Para empezar necesitas **uno personal con scope `api`**. Créalo ahora y guárdalo: GitLab lo enseña una sola vez.

Autentica `glab` contra tu instancia:

```bash
glab auth login --hostname localhost:8888
```

> [!WARNING]
> Un token de GitLab empieza por `glpat-`. **Nunca lo pegues en un archivo del repositorio**, ni siquiera de ejemplo, ni siquiera inventado: el propio GitLab lo detecta y lo marca. En el material del bootcamp los tokens siempre aparecen como `<TOKEN>` o `$CI_JOB_TOKEN`.

---

## 9. Configurar el autograding

```bash
cat > ~/.bc-gitlab <<'EOF'
GITLAB_URL=http://localhost:8888
PROYECTO=plataforma-<tu-dominio>/app
GITLAB_TOKEN=<tu-token-personal>
EOF
chmod 600 ~/.bc-gitlab
```

`PROYECTO` todavía no existe: lo creas en la Semana 01. Puedes dejar el valor puesto desde ya.

---

## 10. Configuración de Git recomendada

No es obligatoria, pero evita media docena de tropiezos a lo largo del bootcamp:

```bash
# Que 'git pull' rebase en vez de generar merges de mantenimiento
git config --global pull.rebase true

# Empujar solo la rama actual, nunca todas
git config --global push.default current

# Recordar cómo resolviste un conflicto y reaplicarlo
git config --global rerere.enabled true

# Colorear las diferencias por palabra, no por línea entera
git config --global diff.wsErrorHighlight all

# Ordenar las ramas por fecha del último commit
git config --global branch.sort -committerdate

# Que 'git log' muestre la firma sin pedirlo
git config --global log.showSignature false
```

La última está en `false` a propósito: en `true` ensucia todos los logs. La Semana 02 enseña `git log --show-signature` cuando de verdad hace falta.

---

## 11. Verificación final

```bash
cd bc-gitlab
./scripts/verificar-semana.sh --doctor
```

Salida esperada:

```
== Diagnóstico del entorno ==
✅ git version 2.46.0
✅ curl 8.5.0
✅ jq-1.7.1
✅ Docker version 27.3.1
✅ glab version 1.50.0
✅ instancia viva en http://localhost:8888 (GitLab 19.1.1)
✅ token válido, autenticado como root
✅ commit.gpgsign activo (formato: ssh)
⚠️  sin proyecto guardado — añade PROYECTO=<grupo>/<proyecto> a /home/tu/.bc-gitlab

Entorno listo.
```

El aviso del proyecto es esperado hasta que lo crees en la Semana 01.

---

## Problemas frecuentes

| Síntoma | Causa | Solución |
|---|---|---|
| `502 Whoops, GitLab is taking too much time to respond` | Todavía está arrancando, o falta memoria | Espera 5 min. Si persiste, `docker stats` y mira [perfiles-de-laboratorio.md](perfiles-de-laboratorio.md) |
| `port is already allocated` | Otro proceso ocupa 8888, 5050, 8090 o 2224 | Cambia el puerto en `.env` y `docker compose --profile base up -d` |
| `Permission denied (publickey)` al hacer push | La clave no está en GitLab, o falta el puerto 2224 | Revisa el paso 6 y usa el host `gitlab-lab` |
| Los commits salen como **Unverified** | La clave está registrada solo para autenticación | Regístrala también con uso *Signing* (paso 7) |
| `docker compose up -d` no levanta nada | Falta el perfil | `docker compose --profile base up -d` |
| El contenedor se reinicia en bucle | Poca memoria o `.env` mal formado | `docker compose logs gitlab \| tail -50` |
| `--doctor` dice que el token no autentica | Token caducado, o le falta el scope `api` | Créalo de nuevo en `Preferences → Access tokens` |
| Todo iba bien y ahora se arrastra | Levantaste dos perfiles a la vez | `docker compose --profile observabilidad down` |

Si nada de esto encaja, `docker compose exec gitlab /opt/lab/lab-health` suele decir qué servicio se cayó.

---

[← Volver a docs](README.md)

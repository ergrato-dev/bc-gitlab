# Práctica 01 — Levantar la instancia

> Vas a arrancar tu GitLab, confirmar que arrancó **de verdad** y dejarlo mínimamente endurecido.

**Duración estimada**: 50 min (unos 5 de trabajo tuyo y el resto esperando al primer arranque)
**Prerrequisitos**: [setup-entorno](../../../docs/setup-entorno.md) completado — Docker, Git, `glab` y `jq` instalados

---

## Contexto

Te acaban de dar una máquina y el encargo de montar el GitLab del equipo. Nadie te ha dicho cómo comprobar que funciona, y la primera vez que alguien te pregunte "¿ya está listo?" tendrás que responder algo mejor que "creo que sí".

Al terminar esta práctica sabrás responder con un comando.

---

## Paso 1: Preparar el repositorio del bootcamp

**Por qué**: el laboratorio entero (compose, scripts, material) vive en este repositorio. Los comandos de todas las prácticas se ejecutan desde su raíz.

```bash
git clone https://github.com/ergrato-dev/bc-gitlab.git
cd bc-gitlab
cp .env.example .env
```

**Verifica**:

```bash
ls docker-compose.yml .env scripts/verificar-semana.sh
# docker-compose.yml  .env  scripts/verificar-semana.sh
```

---

## Paso 2: Revisar la configuración antes de levantar nada

**Por qué**: `.env` decide la versión de GitLab y los puertos. Mirarlo ahora cuesta un minuto; descubrir un choque de puertos a mitad del arranque cuesta veinte.

```bash
grep -E '^(GITLAB_VERSION|GITLAB_HTTP_PORT|REGISTRY_PORT|PAGES_PORT|GITLAB_SSH_PORT)=' .env
```

```
GITLAB_VERSION=19.1.1-ce.0
GITLAB_HTTP_PORT=8888
REGISTRY_PORT=5050
PAGES_PORT=8090
GITLAB_SSH_PORT=2224
```

Comprueba que ninguno esté ocupado en tu máquina:

```bash
for p in 8888 5050 8090 2224; do
  ss -tln 2>/dev/null | grep -q ":$p " && echo "OCUPADO: $p" || echo "libre: $p"
done
```

Si alguno sale ocupado, cámbialo en `.env` —no en `docker-compose.yml`— y sigue.

**Verifica**:

```bash
docker compose --profile base config --quiet && echo "compose valido"
```

---

## Paso 3: Levantar el perfil base

**Por qué**: ningún servicio del laboratorio está fuera de un perfil, así que `docker compose up -d` a secas no levanta nada y no da error. Es deliberado: te obliga a elegir qué levantas.

```bash
docker compose --profile base up -d
```

**Verifica** que los tres contenedores existan:

```bash
docker compose ps --format 'table {{.Name}}\t{{.Status}}'
```

```
NAME             STATUS
gitlab           Up 20 seconds (health: starting)
gitlab-runner    Created
registry-cache   Up 19 seconds
```

`health: starting` es lo esperado. `gitlab-runner` aparece como `Created` porque espera a que GitLab esté sano antes de arrancar.

---

## Paso 4: Seguir el arranque en vez de adivinar

**Por qué**: el primer arranque tarda unos cinco minutos y pasa por cinco fases. Si no sabes cuál está corriendo, cinco minutos se parecen mucho a "está colgado".

```bash
docker compose logs -f gitlab
```

Verás pasar, en orden:

1. Líneas de Chef aplicando recetas — es `reconfigure`, la fase larga
2. `gitlab Reconfigured!` — la configuración ya está generada
3. Migraciones de la base de datos
4. Arranque de Puma, Sidekiq, Gitaly

Sal con `Ctrl+C` cuando veas `gitlab Reconfigured!`. El log sigue corriendo aunque dejes de mirarlo.

**Verifica** que el contenedor llegó a sano:

```bash
docker compose ps gitlab --format '{{.Status}}'
# Up 6 minutes (healthy)
```

Si sigue en `health: starting` pasados 8 minutos, salta a la sección final de esta práctica.

---

## Paso 5: Distinguir "responde" de "funciona"

**Por qué**: esta es la lección de la semana. `/-/health` te dice que Nginx contesta, y puede decir `OK` con la base de datos caída. `/-/readiness` comprueba base de datos, Redis y Gitaly.

```bash
curl -s http://localhost:8888/-/health
# GitLab OK
```

Eso no basta. Ahora la de verdad:

```bash
curl -s "http://localhost:8888/-/readiness?all=1" | jq
```

**Verifica** que todos los componentes digan `ok`:

```bash
curl -s "http://localhost:8888/-/readiness?all=1" \
  | jq -r 'to_entries[] | select(.value | type == "array") | "\(.key): \(.value[0].status)"'
```

```
db_check: ok
redis_check: ok
gitaly_check: ok
master_check: ok
```

> [!TIP]
> Guárdate este comando. Es la respuesta buena a "¿ya está listo?", y es el que usarás cada vez que la instancia se comporte de forma rara.

---

## Paso 6: Primer acceso y cambio de contraseña

**Por qué**: la contraseña inicial de `root` está en un archivo dentro del contenedor que **se autodestruye a las 24 horas**. Si no la cambias antes y la pierdes, hay que resetearla desde la consola de Rails, que es bastante más incómodo.

```bash
docker compose exec gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

Abre `http://localhost:8888` y entra como `root` con esa contraseña.

Cámbiala en `Preferences → Password` (o `http://localhost:8888/-/user_settings/password/edit`).

Aprovecha y rellena tu perfil en `Preferences → Profile`:

- **Full name** — tu nombre
- **Email** — **el mismo que tienes en `git config --global user.email`**

**Por qué el correo importa**: si no coincide, tus commits aparecerán como de un desconocido y en la Semana 02 la verificación de firma fallará sin motivo aparente.

**Verifica**:

```bash
git config --global user.email
# y compara con el que pusiste en el perfil
```

---

## Paso 7: Cerrar el registro público

**Por qué**: GitLab viene con el registro abierto. En una instancia expuesta a una red eso significa que cualquiera puede crearse una cuenta. Aunque tu laboratorio sea local, el hábito se practica ahora.

En la interfaz: `Admin → Settings → General → Sign-up restrictions`, desmarca **Sign-up enabled** y guarda.

La URL directa es `http://localhost:8888/admin/application_settings/general`.

**Verifica** — este es uno de los entregables de la semana:

```bash
curl -s http://localhost:8888/api/v4/application/settings \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" | jq '.signup_enabled'
# false
```

Todavía no tienes `$GITLAB_TOKEN`: lo creas en el paso siguiente. Vuelve a esta comprobación después.

---

## Paso 8: Crear tu token de acceso

**Por qué**: sin token no puedes usar la API, y sin API no hay autograding. Además es como vas a trabajar el resto del bootcamp.

En `Preferences → Access tokens` (`http://localhost:8888/-/user_settings/personal_access_tokens`):

- **Name**: `bootcamp`
- **Expiration date**: dentro de un año, o vacío
- **Scopes**: marca **`api`**

> [!NOTE]
> El autograding solo necesita `read_api`, que es de solo lectura. Marcamos `api` porque a partir de la Semana 03 vas a **crear** cosas por API. Si prefieres empezar con `read_api` y ampliarlo luego, es una decisión defendible.

GitLab enseña el token **una sola vez**. Cópialo ahora.

Guárdalo en la configuración del bootcamp:

```bash
cat > ~/.bc-gitlab <<'EOF'
GITLAB_URL=http://localhost:8888
GITLAB_TOKEN=PEGA_AQUI_TU_TOKEN
EOF
chmod 600 ~/.bc-gitlab
```

> [!WARNING]
> `~/.bc-gitlab` vive en tu directorio personal, **nunca dentro del repositorio**. Un token de GitLab empieza por `glpat-`, y el propio GitLab detecta ese patrón como secreto filtrado si aparece en un repositorio.

**Verifica**:

```bash
source ~/.bc-gitlab
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/user" | jq '.username'
# "root"
```

Y ahora sí, vuelve a la comprobación del paso 7.

---

## Paso 9: Confirmar la versión y dejar el diagnóstico a mano

**Por qué**: todo el material se comprobó contra la versión fijada. Confirmar que corres esa versión descarta de entrada una familia entera de problemas.

```bash
source ~/.bc-gitlab
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/version" | jq
```

```json
{
  "version": "19.1.1",
  "revision": "...",
  "enterprise": false
}
```

`"enterprise": false` confirma que es Community Edition.

Prueba también el atajo de diagnóstico del laboratorio:

```bash
docker compose exec gitlab /opt/lab/lab-health
```

**Verifica**:

```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/version" \
  | jq '.version | startswith("19.")'
# true
```

---

## ✅ Resultado

- [ ] Los tres contenedores del perfil `base` están arriba y `gitlab` aparece como `healthy`
- [ ] `/-/readiness?all=1` devuelve `ok` en todos los componentes
- [ ] La contraseña de `root` ya no es la inicial
- [ ] Tu correo en GitLab coincide con tu `git config --global user.email`
- [ ] El registro público está desactivado
- [ ] Tienes un token personal guardado en `~/.bc-gitlab` con `chmod 600`
- [ ] La versión es 19.x y `enterprise` es `false`

```bash
./scripts/verificar-semana.sh 01
```

De las 12 comprobaciones deberían pasar ya `instancia-viva` y `registro-cerrado`. El resto llegan en las prácticas 03 y 04.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `docker compose up -d` no levanta nada y no da error | Falta el perfil | `docker compose --profile base up -d` |
| `502 Whoops, GitLab is taking too much time to respond` | Sigue arrancando | Espera. Confirma la fase con `docker compose logs gitlab \| tail -5` |
| Sigue en `health: starting` pasados 10 min | Poca memoria | `docker stats --no-stream`. GitLab necesita ~4 GB solo para él |
| `port is already allocated` | Otro proceso ocupa el puerto | Cambia el puerto en `.env`, luego `docker compose --profile base up -d` |
| `readiness` da `db_check: failed` | PostgreSQL no arrancó | `docker compose exec gitlab gitlab-ctl tail postgresql` |
| El archivo `initial_root_password` no existe | Han pasado más de 24 h | `docker compose exec gitlab gitlab-rake "gitlab:password:reset[root]"` |
| El token no autentica | Mal copiado, o sin scope `api` | Créalo de nuevo. Comprueba con `curl .../api/v4/user` |
| `jq: command not found` | Falta `jq` | [setup-entorno](../../../docs/setup-entorno.md), sección 2 |
| El contenedor se reinicia en bucle | Poca memoria o `.env` mal formado | `docker compose logs gitlab \| tail -50` |

---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| — | [Práctica 02 — Recorrerla por dentro →](02-recorrer-la-instancia-por-dentro.md) |

[← Volver a la Semana 01](../README.md)

# Tokens y la API v4

> Todo lo que hace la interfaz web lo hace llamando a la API. Aprender la API es aprender a operar GitLab sin ratón.

## 🎯 Objetivos

- Elegir el tipo de token correcto para cada tarea
- Entender qué concede cada scope y por qué `api` no se reparte a la ligera
- Consultar la API v4 con `curl` y con `glab`
- Saber cuándo GraphQL responde mejor que REST

---

## 1. Qué problema resuelve

La interfaz web está bien para explorar y es pésima para repetir. Si tienes que comprobar la configuración de cuarenta proyectos, o crear veinte issues desde un CSV, o averiguar qué pipelines fallaron esta semana, hacerlo a clics es inviable.

Además, el autograding de este bootcamp funciona así: `verificar-semana.sh` no mira capturas de pantalla, le pregunta a la API por el estado real de tu instancia.

---

## 2. Los tipos de token

GitLab tiene varios y se confunden constantemente. Los tres que importan:

| Tipo | Dónde se crea | Actúa como | Para qué |
|---|---|---|---|
| **Personal** | `Preferences → Access tokens` | **Tú** | `glab`, el autograding, tus scripts |
| **De proyecto** | `Settings → Access tokens` del proyecto | Un bot con acceso a ese proyecto | Automatización que toca un solo proyecto |
| **De grupo** | `Settings → Access tokens` del grupo | Un bot con acceso al grupo | Automatización que cruza varios proyectos |

Hay más —de despliegue, de runner, de impersonación— que irán apareciendo cuando hagan falta.

### La regla para elegir

**Un token personal actúa como tú, con todos tus permisos.** Si lo pones en un pipeline, ese pipeline puede hacer todo lo que tú puedes hacer, en todos los proyectos donde tengas acceso. Es cómodo y es exactamente lo que no quieres en automatización.

| Situación | Token |
|---|---|
| Tu terminal, tus scripts, el autograding | Personal |
| Un pipeline que toca su propio proyecto | `CI_JOB_TOKEN` (te lo da GitLab, no lo creas) |
| Un pipeline que toca otro proyecto | De proyecto o de grupo |
| Una integración externa | De proyecto, con el mínimo scope |

En este bootcamp usarás uno personal hasta la Semana 09, donde aparecen los tokens de proyecto y `CI_JOB_TOKEN`.

---

## 3. Scopes

Un scope acota lo que el token puede hacer. Los relevantes:

| Scope | Concede |
|---|---|
| `api` | **Acceso completo de lectura y escritura a toda la API** |
| `read_api` | Toda la API, pero solo lectura |
| `read_user` | Leer el perfil del usuario |
| `read_repository` | Clonar y leer repositorios |
| `write_repository` | Además, empujar |
| `read_registry` | Descargar del Container Registry |
| `write_registry` | Subir al Container Registry |

> [!WARNING]
> **`api` lo concede todo.** Un token con scope `api` puede borrar tus proyectos, cambiar permisos y crear otros tokens. Trátalo como una contraseña, porque lo es.
>
> Para el autograding basta `read_api`, que es de solo lectura. Es lo que recomienda este bootcamp: el script solo hace `GET`, no necesita más.

### El formato del token

Un token personal es el prefijo `glpat`, un guion y veinte caracteres alfanuméricos. `glpat` significa *GitLab Personal Access Token*. GitLab lo enseña **una sola vez**, al crearlo. Si lo pierdes, se revoca y se crea otro.

Fíjate en que este párrafo describe el formato pero no escribe ninguno: ni siquiera un ejemplo inventado con veinte equis, porque **también casaría con el patrón de detección de secretos** y GitLab lo marcaría en el propio repositorio del bootcamp.

> [!IMPORTANT]
> **Nunca escribas un token en un archivo del repositorio, ni siquiera inventado.** GitLab detecta el patrón `glpat-` y lo marca como secreto filtrado. En el material de este bootcamp los tokens aparecen siempre como `<TOKEN>` o `$GITLAB_TOKEN`.
>
> En tu máquina viven en `~/.bc-gitlab`, con `chmod 600`, fuera del repositorio.

---

## 4. Llamar a la API con `curl`

La API v4 cuelga de `/api/v4/`. El token va en la cabecera `PRIVATE-TOKEN`:

```bash
source ~/.bc-gitlab

curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/user" | jq '.username'
# "root"
```

### Identificar un proyecto: el detalle que atasca a todo el mundo

Un proyecto se identifica por su ID numérico o por su **ruta completa URL-encoded**:

```bash
# Por ID
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/projects/7"

# Por ruta: la barra se codifica como %2F
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/plataforma-biblioteca%2Fapp"
```

Esa `%2F` es obligatoria. Con una barra literal, la API interpreta que `app` es un subrecurso y devuelve 404.

Por eso el `checks.json` del bootcamp usa el marcador `{proyecto}`: el script hace la codificación por ti.

### Consultas útiles

```bash
# Tus proyectos
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects?membership=true" | jq -r '.[].path_with_namespace'

# La versión de la instancia
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/version" | jq

# Los últimos commits de main
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/plataforma-biblioteca%2Fapp/repository/commits?ref_name=main" \
  | jq -r '.[] | "\(.short_id) \(.title)"'
```

### Paginación

La API devuelve 20 elementos por defecto y **no avisa de que hay más**. Es la causa silenciosa de la mitad de los scripts que dan resultados incompletos:

```bash
curl -s -D- -o /dev/null -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects" | grep -i '^x-total'
# X-Total: 47
# X-Total-Pages: 3
```

Se controla con `per_page` (máximo 100) y `page`.

---

## 5. Llamar a la API con `glab`

`glab` hace lo mismo con menos ceremonia, y es lo que usarás en las prácticas:

```bash
glab auth login --hostname localhost:8888

glab api user | jq '.username'
glab api "projects/plataforma-biblioteca%2Fapp" | jq '.visibility'
```

Ventajas sobre `curl`: gestiona la autenticación, resuelve el proyecto actual desde el directorio, y tiene subcomandos de alto nivel:

```bash
glab issue list
glab mr list
glab ci status
```

Este bootcamp usa `curl` cuando quiere enseñar **el endpoint** —porque el endpoint es lo transferible— y `glab` cuando el foco está en el trabajo.

> [!NOTE]
> El autograding usa `curl` por dentro, no `glab`. Un token en una variable de entorno funciona en cualquier máquina sin configurar nada; `glab` necesita su propia autenticación por host. Menos dependencias, menos cosas que fallar.

---

## 6. REST y GraphQL

GitLab expone las dos.

| | REST v4 | GraphQL |
|---|---|---|
| Endpoint | `/api/v4/...` | `/api/graphql` |
| Cada llamada devuelve | Todo el objeto | Solo lo que pidas |
| Datos anidados | Varias llamadas | Una sola |
| Cobertura | Prácticamente completa | Amplia, pero no total |
| Explorable | Con la documentación | **Con autocompletado, en el navegador** |

REST para lo simple. GraphQL cuando necesitas datos anidados y no quieres hacer N llamadas:

```bash
curl -s -X POST "$GITLAB_URL/api/graphql" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"query { project(fullPath: \"plataforma-biblioteca/app\") { name visibility } }"}' \
  | jq
```

**El explorador es lo que hace GraphQL usable:**

```
http://localhost:8888/-/graphql-explorer
```

Autocompleta con `Ctrl+Espacio` y trae el esquema de **tu** versión, no de la última. Es la forma más rápida de descubrir qué campos existen sin leer documentación.

La Semana 17 entra a fondo en las dos.

---

## 7. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Token con scope `api` para leer | Un script de solo lectura con permiso para borrarlo todo | `read_api` |
| Token personal en un pipeline | El pipeline actúa como tú en todos tus proyectos | `CI_JOB_TOKEN` o token de proyecto |
| El token en la línea de comandos | Queda en el historial del shell y en `ps` | Variable de entorno desde `~/.bc-gitlab` |
| Barra literal en la ruta del proyecto | 404 que parece un proyecto inexistente | `%2F` |
| Ignorar la paginación | Resultados incompletos sin ningún error | `per_page` y `X-Total-Pages` |
| Tokens sin fecha de caducidad | Credenciales eternas que nadie recuerda haber creado | Ponles caducidad y renuévalos |

---

## 8. Trucos

**Comprobar qué scopes tiene un token**, sin acordarte de qué marcaste:

```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/personal_access_tokens/self" | jq '{name, scopes, expires_at}'
```

`/self` devuelve el token con el que estás llamando. Muy útil cuando tienes tres y no sabes cuál es cuál.

**Ver las cabeceras sin el cuerpo:**

```bash
curl -s -D- -o /dev/null -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/projects"
```

Ahí están `X-Total`, `X-Total-Pages` y los límites de tasa.

**Codificar la ruta sin hacerlo a mano:**

```bash
python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" \
  "plataforma-biblioteca/app"
# plataforma-biblioteca%2Fapp
```

**Descubrir qué endpoint usa la interfaz.** Abre las herramientas de desarrollo del navegador, pestaña Red, filtra por `api`, y haz la acción en la interfaz. GitLab llama a su propia API: verás exactamente el endpoint, el método y el cuerpo que necesitas.

Es el truco que más tiempo ahorra de todos los de esta semana.

---

## 📚 Recursos Adicionales

- [Recursos de la API v4](https://docs.gitlab.com/ee/api/api_resources.html) — el índice de todos los endpoints. Tu referencia durante 26 semanas
- [Tokens de acceso personales](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html) — scopes y caducidad explicados uno a uno
- [API GraphQL](https://docs.gitlab.com/ee/api/graphql/) — y el explorador de tu propia instancia, que es mejor que la documentación
- [CLI `glab`](https://gitlab.com/gitlab-org/cli) — todos los subcomandos

---

## ✅ Checklist de Verificación

- [ ] Sabes qué tipo de token usar en un pipeline y por qué no el personal
- [ ] Sabes por qué el autograding pide `read_api` y no `api`
- [ ] Puedes consultar un proyecto por su ruta, con la codificación correcta
- [ ] Sabes comprobar si una respuesta viene paginada
- [ ] Sabes abrir el explorador de GraphQL de tu instancia
- [ ] Sabes descubrir qué endpoint usa una acción de la interfaz

---

| Anterior | Siguiente |
|---|---|
| [← 07 — Salud, logs y diagnóstico](07-salud-logs-y-diagnostico.md) | — |

[← Volver a la Semana 01](../README.md)

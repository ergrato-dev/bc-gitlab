# Visibilidad: quién ve qué

> La visibilidad decide quién ve algo **sin ser miembro**. Los roles empiezan a contar después. Confundir las dos capas es la vía más rápida a publicar un repositorio sin querer.

## 🎯 Objetivos

- Distinguir los tres niveles de visibilidad y qué permite cada uno a quien no es miembro
- Explicar por qué un hijo no puede ser más visible que su padre, y en qué orden se cambian
- Predecir qué ve exactamente un anónimo en un proyecto público
- Restringir en la instancia los niveles que no quieres que nadie use

---

## 1. Qué problema resuelve

Un proyecto tiene dos preguntas distintas que responder, y GitLab las separa a propósito:

1. **¿Quién puede verlo sin que nadie le invite?** → visibilidad
2. **¿Qué puede hacer quien está dentro?** → rol

Mezclarlas produce los dos errores clásicos. El primero: hacer un proyecto público "para que el equipo lo vea", cuando el equipo ya lo veía por su rol y a quien acabas de darle acceso es a internet. El segundo: dar rol de Guest a alguien para que "solo lea", cuando lo que necesitaba era leer código —que Guest no ve— y el proyecto ya era interno.

La regla de partida: **la visibilidad solo suma lectura para quien no es miembro**. Nunca quita nada a los miembros, y nunca da permiso de escritura a nadie.

---

## 2. Cómo funciona

### 2.1 Los tres niveles

| Nivel | Quién lo ve sin ser miembro | Cuándo se usa |
|---|---|---|
| **`private`** | Nadie. Solo miembros, directos o heredados | Todo lo de este bootcamp |
| **`internal`** | Cualquier usuario **autenticado** de la instancia, excepto usuarios externos | Instancias corporativas donde todo el mundo puede leer lo de todos |
| **`public`** | Cualquiera, sin cuenta | Software abierto, plantillas, documentación |

`internal` es el nivel que más se malinterpreta: no significa "de mi equipo", significa **"de cualquiera con cuenta en esta instancia"**. En un GitLab de empresa con 800 cuentas, eso son 800 lectores.

En una instancia autohospedada como la del laboratorio, `public` significa "cualquiera que llegue a `http://localhost:8888`". Hoy eso es tu máquina; el día que la instancia esté publicada, es internet. La visibilidad no se revisa el día que cambia la red.

### 2.2 El hijo nunca es más visible que el padre

GitLab valida la coherencia del árbol en las dos direcciones:

| Intento | Resultado |
|---|---|
| Proyecto `public` dentro de grupo `private` | **Rechazado**: `Visibility level public is not allowed in a private group` |
| Subgrupo `internal` dentro de grupo `private` | **Rechazado** por la misma razón |
| Proyecto `private` dentro de grupo `public` | **Permitido**: hacia abajo se puede restringir |
| Cambiar un grupo `public` a `private` teniendo proyectos públicos | **Rechazado**: hay que restringir los hijos primero |

De ahí el orden de operaciones, que no es obvio y se descubre a mitad del cambio:

- Para **abrir** el árbol: de arriba abajo. Primero el grupo, luego los hijos.
- Para **cerrar** el árbol: de abajo arriba. Primero los proyectos, luego el grupo.

```bash
source ~/.bc-gitlab
# Ver la visibilidad de todo el árbol de una vez, antes de tocar nada
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/groups/$GID/descendant_groups" \
  | jq -r '.[] | "\(.visibility)\t\(.full_path)"'
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/groups/$GID/projects?include_subgroups=true&with_shared=false" \
  | jq -r '.[] | "\(.visibility)\t\(.path_with_namespace)"'
```

### 2.3 Qué ve exactamente un anónimo

En un proyecto **público**, quien no tiene cuenta puede leer bastante más de lo que la gente supone. En la instancia se puede consultar el permiso exacto asignado al visitante sin cuenta:

```bash
docker compose exec gitlab bash -c \
  'grep -E "^  - (read_code$|download_code|read_issue$|read_wiki$)" \
   /opt/gitlab/embedded/service/gitlab-rails/config/authz/roles/public_anonymous.yml'
```

```
  - download_code
  - read_code
  - read_issue
  - read_wiki
```

Es decir: **código, historial completo, issues y wiki**, sin cuenta. Y con el código va toda la historia de Git, que es donde acaban los secretos que alguien comprometió una vez y borró en el commit siguiente (Semana 02).

Cada funcionalidad del proyecto tiene además su propio interruptor de visibilidad —`issues_access_level`, `wiki_access_level`, `repository_access_level`…—, con tres valores: `disabled`, `private` (solo miembros) y `enabled` (según la visibilidad del proyecto). Sirven para publicar el código y mantener privados los issues, o al revés.

```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/projects/$P" \
  | jq '{visibility, repository_access_level, issues_access_level, wiki_access_level, snippets_access_level}'
```

### 2.3.1 Usuarios externos

Hay un tercer factor, además de la visibilidad y del rol: la marca de **usuario externo**. Un usuario creado con `external: true` no ve los proyectos `internal` aunque tenga cuenta; solo llega a lo `public` y a aquello donde se le haya dado rol explícitamente.

```bash
# Crear un usuario externo (solo administradores)
curl -s --request POST "$GITLAB_URL/api/v4/users" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data-urlencode "email=contratista@example.test" \
  --data-urlencode "username=contratista" \
  --data-urlencode "name=Contratista" \
  --data-urlencode "external=true" \
  --data-urlencode "force_random_password=true" | jq '{id, username, external}'

# Listarlos: la respuesta de /users acepta el filtro
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/users?external=true" \
  | jq -r '.[].username'
```

Es la pieza que hace utilizable el nivel `internal` en una instancia con proveedores dentro: los de casa leen todo lo interno, los externos solo lo que se les da. Sin ella, `internal` es un interruptor de todo o nada.

### 2.4 La visibilidad se decide en tres sitios

| Sitio | Ajuste | Efecto |
|---|---|---|
| **Instancia** | `default_project_visibility`, `default_group_visibility` | Con qué nace lo que se crea |
| **Instancia** | `restricted_visibility_levels` | Niveles que **nadie** puede elegir, ni administradores desde la interfaz |
| **Grupo** | `visibility` | Techo para todo lo que cuelgue |
| **Proyecto** | `visibility` | Lo que ve el mundo de ese proyecto |

En el laboratorio, la Semana 01 dejó la instancia con el registro cerrado y todo privado. Endurecerla del todo —incluido `restricted_visibility_levels`— es materia de la Semana 18; lo que toca hoy es que **el árbol que creas nazca privado y siga privado**.

```bash
# Solo administradores: qué nivel es el de partida en esta instancia
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/application/settings" \
  | jq '{default_project_visibility, default_group_visibility, restricted_visibility_levels}'
```

---

## 3. Cómo se cambia

**Con la interfaz**: `Grupo → Settings → General → Visibility` y `Proyecto → Settings → General → Visibility, project features, permissions`.

**Con la API**:

```bash
# Un subgrupo, explícitamente privado
curl -s --request PUT "$GITLAB_URL/api/v4/groups/$SUBID" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data-urlencode "visibility=private" | jq '{full_path, visibility}'
```

> [!WARNING]
> Pasar un proyecto de `private` a `public` es **inmediato y no tiene deshacer útil**: mientras estuvo público, cualquiera pudo clonarlo, y volver a privado no recupera las copias. Antes de publicar cualquier repositorio: revisar la historia entera en busca de secretos (Semana 02) y confirmar la licencia (Semana 04). En este bootcamp no se hace público nada.

### 3.1 Comprobarlo como lo ve un desconocido

La forma honesta de verificar la visibilidad es **preguntar sin credenciales**. Una petición sin cabecera `PRIVATE-TOKEN` es exactamente lo que ve alguien que llega de fuera:

```bash
# Sin token: así responde tu instancia a quien no tiene cuenta
curl -s -o /dev/null -w '%{http_code}\n' "$GITLAB_URL/api/v4/projects/$P"
# 404
```

`404` es la respuesta correcta para un proyecto privado: GitLab **no distingue** entre "no existe" y "no puedes verlo", precisamente para no confirmar la existencia de recursos privados. Si esa misma petición devuelve `200`, el proyecto es visible para el mundo, digan lo que digan los ajustes que creías tener.

La misma comprobación vale para el grupo:

```bash
curl -s -o /dev/null -w '%{http_code}\n' "$GITLAB_URL/api/v4/groups/$GID"
# 404
```

Dos comandos, sin interfaz y sin suposiciones. Es lo que la práctica 03 convierte en método: **los permisos no se leen, se prueban**.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Usar `internal` como "privado del equipo" | Lo ve toda la instancia, que puede ser toda la empresa | `private` y miembros; `internal` solo cuando de verdad se quiere que todos lean |
| Hacer público para que un externo pueda leer | Se publica a todo el mundo para resolver un caso de una persona | Grupo invitado con techo Reporter (teoría [05](05-compartir-grupos-y-proyectos.md)) |
| Cambiar la visibilidad del grupo antes que la de los hijos | El cambio se rechaza a mitad y el árbol queda inconsistente | Cerrar de abajo arriba, abrir de arriba abajo |
| Suponer que "público" es solo el código | También la historia, los issues y la wiki, sin cuenta | Revisar los `*_access_level` uno a uno antes de publicar |
| Publicar un repositorio sin auditar su historia | El commit borrado sigue en la historia y ahora es público | `git grep` sobre toda la historia (Semana 02) antes de publicar |
| Confiar en que la instancia es local | Los laboratorios acaban expuestos por un túnel "temporal" | Que la visibilidad sea correcta aunque la red cambie mañana |

---

## 5. Trucos

- **Auditar el árbol en dos comandos**: la visibilidad de todos los descendientes y la de todos los proyectos, con los dos `jq` de la sección 2.2.
- **Nivel de cada funcionalidad, de un vistazo**: `jq 'to_entries | map(select(.key | endswith("_access_level")))' ` sobre la respuesta del proyecto.
- **Qué ve alguien sin cuenta**: abre el proyecto en una ventana privada del navegador. Es más rápido que razonarlo y no miente.
- **Buscar lo que no debería ser visible**: `GET /projects?visibility=public&simple=true` como administrador enumera todo lo público de la instancia.
- **El archivo `public_anonymous.yml`** del contenedor es la lista literal de lo que puede un visitante sin cuenta en tu versión.

---

## 📚 Recursos Adicionales

- [Visibilidad de proyectos y grupos](https://docs.gitlab.com/ee/user/public_access.html) — los tres niveles y sus matices
- [Funcionalidades y permisos de proyecto](https://docs.gitlab.com/ee/user/project/settings/) — los `*_access_level` uno a uno
- [Niveles de visibilidad restringidos](https://docs.gitlab.com/ee/administration/settings/visibility_and_access_controls.html) — el ajuste de instancia de la Semana 18

---

## ✅ Checklist de Verificación

- [ ] Sabes qué ve un usuario autenticado cualquiera en un proyecto `internal`
- [ ] Sabes en qué orden se cierra un árbol y en qué orden se abre
- [ ] Has comprobado que tu grupo, tus subgrupos y tu proyecto son `private`
- [ ] Sabes que un proyecto público expone también la historia, los issues y la wiki

---

[← Anterior: Compartir grupos y proyectos](05-compartir-grupos-y-proyectos.md) · [Volver a la Semana 03](../README.md) · [Siguiente: Mover y renombrar →](07-mover-y-renombrar-sin-romper.md)

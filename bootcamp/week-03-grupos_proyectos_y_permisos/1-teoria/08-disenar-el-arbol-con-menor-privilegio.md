# Diseñar el árbol con menor privilegio

> Un árbol de grupos bien diseñado se reconoce en que nadie pide permisos y nadie tiene de más. Los dos síntomas van juntos y salen del mismo sitio: decidir arriba lo que se puede decidir arriba, y nada más.

## 🎯 Objetivos

- Elegir entre los tres patrones de árbol y justificar la elección
- Colocar cada rol en el nivel correcto, con criterio y no por costumbre
- Usar identidades de bot en lugar de tokens personales para lo automático
- Ejecutar una auditoría de accesos periódica que quepa en diez minutos

---

## 1. Qué problema resuelve

El menor privilegio se enuncia en una línea —cada identidad tiene el mínimo acceso que le permite trabajar— y se incumple por una razón muy concreta: **conceder es rápido y revocar no lo pide nadie**. Nadie abre un ticket para que le quiten permisos.

El resultado, a los seis meses, es el estado en el que está la mayoría de las instancias: cuatro Owners, media docena de tokens personales corriendo en pipelines, y un grupo raíz con Developer para todo el mundo "porque era más fácil".

El diseño del árbol es la única defensa estructural contra eso, porque decide **cuánto se puede conceder de una vez**. Lo demás es disciplina, y la disciplina se cansa.

---

## 2. Cómo funciona

### 2.1 Los tres patrones de árbol

| Patrón | Forma | Cuándo encaja | Qué duele |
|---|---|---|---|
| **Por producto** | `plataforma/` → `app`, `infra/`, `ci/` | Un equipo, varios artefactos. **El de este bootcamp** | Si crecen los equipos, cada uno acaba viendo todo |
| **Por equipo** | `empresa/` → `equipo-a/`, `equipo-b/` | Varios equipos independientes, poco código compartido | Lo común no tiene sitio natural y se duplica |
| **Por entorno** | `empresa/` → `produccion/`, `desarrollo/` | Casi nunca | Separa lo que debería moverse junto; los permisos por entorno se resuelven mejor con entornos protegidos (S14) |

Regla práctica: **dos niveles bastan casi siempre, tres son el máximo razonable**. Cada nivel más es un sitio donde alguien puede conceder permisos sin que se vea desde arriba.

El árbol de esta semana sigue el primer patrón, con una decisión explícita: `app` cuelga de la raíz, no de un subgrupo `producto/`. El motivo es que un subgrupo con un solo proyecto no aporta ni un permiso distinto: aporta un segmento más de ruta en el remoto de Git, en la imagen del registry y en cada `include` de CI.

### 2.2 Dónde va cada rol

| Nivel | Qué se pone aquí | Qué **no** |
|---|---|---|
| **Grupo raíz** | Un Owner. El acceso base que de verdad necesita todo el mundo | Roles altos "por comodidad": bajan a todo el árbol y no se pueden recortar abajo |
| **Subgrupo** | El acceso de un área concreta | Nada que ya esté en la raíz: sería ruido duplicado |
| **Proyecto** | Elevaciones puntuales y documentadas | El acceso general del equipo: se pierde de vista |
| **Grupo invitado** | Todo lo externo y todo lo temporal | Relaciones permanentes que en realidad son propiedad: eso se mueve |

La pregunta operativa, cada vez, es una sola: **¿cuál es el nivel más bajo del árbol donde esta persona puede hacer su trabajo?** Ahí va la membresía.

Y una comprobación que resume la salud del árbol: `GET /groups/:id/members/all | jq '[.[]|select(.access_level==50)]|length'`. Si devuelve más de dos, el privilegio ya se está repartiendo por inercia.

### 2.3 Identidades que no son personas

Los pipelines, los scripts y los bots también son identidades, y en CE hay tres formas de dárselas. Elegir mal aquí es lo que deja tokens personales corriendo en producción tres años.

| Identidad | Alcance | Cuándo usarla |
|---|---|---|
| **`CI_JOB_TOKEN`** | El job que lo usa, mientras dura | Todo lo que un pipeline hace sobre su propio proyecto (S09) |
| **Token de proyecto** (*project access token*) | Un proyecto, con rol y scopes propios | Automatización de un solo proyecto |
| **Token de grupo** (*group access token*) | El grupo y sus descendientes | Automatización que cruza varios proyectos del grupo (S17) |
| **Token personal** | Todo lo que tú puedes | Tu trabajo interactivo. **Nunca** un pipeline |

```bash
# Un token de grupo con rol Reporter, caducidad y scope mínimo
curl -s --request POST "$GITLAB_URL/api/v4/groups/$GID/access_tokens" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data-urlencode "name=auditor-de-accesos" \
  --data-urlencode "scopes[]=read_api" \
  --data-urlencode "access_level=20" \
  --data-urlencode "expires_at=2026-12-31" | jq '{name, access_level, expires_at, scopes}'
```

> [!WARNING]
> **Si no indicas `access_level`, el token nace con rol Maintainer (40).** Es el valor por defecto del endpoint en 19.2, igual que aprobar una solicitud de acceso da Developer por defecto (teoría [04](04-herencia-de-membresia.md)). Los valores por defecto de GitLab son cómodos, no mínimos: en todo lo que cree accesos, el rol se escribe siempre, aunque coincida con el que habría salido solo.

Cada token de grupo o de proyecto crea un **usuario bot** asociado —con nombre de usuario del estilo `group_5_bot_<sufijo>` o `project_2_bot_<sufijo>`— que aparece en la lista de miembros con el rol que le diste. Eso es una ventaja de auditoría: el bot se ve, se le puede quitar el acceso y se sabe qué hace. Un token personal escondido en una variable de CI no se ve en ninguna lista de miembros.

> [!IMPORTANT]
> El token que ejecuta el autograding de este bootcamp es tuyo y personal, y está bien: eres tú quien lo ejecuta a mano. La regla —"ningún token personal en un pipeline"— empieza a aplicar en la Semana 09, cuando el pipeline empiece a llamar a la API por su cuenta.

### 2.4 La auditoría que sí se hace

Una auditoría que lleva media hora no se repite. Esta cabe en diez minutos y responde a las tres preguntas que importan:

```bash
source ~/.bc-gitlab
G=$(printf '%s' "${PROYECTO%/*}" | jq -sRr @uri)
P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
H="PRIVATE-TOKEN: $GITLAB_TOKEN"

echo "== 1. Quién tiene acceso al árbol, y con qué rol efectivo"
curl -s -H "$H" "$GITLAB_URL/api/v4/groups/$G/members/all?per_page=100" \
  | jq -r '.[] | "\(.access_level)\t\(.username)\t\(.expires_at // "sin caducidad")"' | sort -rn

echo "== 2. Excepciones: roles directos en el proyecto"
curl -s -H "$H" "$GITLAB_URL/api/v4/projects/$P/members?per_page=100" \
  | jq -r '.[] | "\(.access_level)\t\(.username)"'

echo "== 3. Quién entra desde fuera, y con qué techo"
curl -s -H "$H" "$GITLAB_URL/api/v4/projects/$P" \
  | jq -r '.shared_with_groups[] | "\(.group_access_level)\t\(.group_full_path)\t\(.expires_at // "sin caducidad")"'
```

Tres preguntas, tres respuestas, y un criterio para cada una:

1. **¿Hay más de un Owner?** Si lo hay, que sea una decisión, no un residuo.
2. **¿Hay elevaciones directas que ya no hacen falta?** Se conceden para una semana y se quedan para siempre.
3. **¿Hay acceso externo sin caducidad?** Es el hallazgo más común y el más fácil de arreglar.

La práctica 04 convierte esto en un script y lo deja en el repositorio. En la Semana 17 el mismo script se vuelve un job de pipeline que corre solo y avisa.

---

## 3. Cómo se documenta el árbol

Un árbol sin documentar se reinterpreta cada vez que alguien mira. Con documentarlo en el propio repositorio basta: `docs/organizacion.md` en `app`, con cuatro cosas.

```markdown
# Organización de la plataforma

## Árbol
plataforma-biblioteca/
├── app        proyecto principal
├── infra/     subgrupo, Terraform y manifiestos (desde la S11)
└── ci/        subgrupo, componentes y automatización (desde la S12)

## Roles
| Identidad | Nivel | Rol | Por qué |
|---|---|---|---|
| tu-usuario | grupo raíz | Owner | Administra la plataforma |
| dev-biblioteca | grupo raíz | Developer | Empuja código a app |
| revisor-biblioteca | proyecto app | Maintainer | Revisa y administra solo app |
| auditor-biblioteca | grupo raíz | Guest, caduca el 2026-12-31 | Lee issues, no ve el código |

## Accesos externos
| Grupo invitado | Alcance | Techo | Caduca |
|---|---|---|---|
| contratistas-biblioteca | proyecto app | Reporter | 2026-12-31 |

## Última auditoría
2026-08-23 — sin hallazgos. Script: `scripts/auditar-accesos.sh`
```

La fecha de la última auditoría es la línea más importante del documento: es la única que envejece sola y la única que delata que nadie ha mirado esto en un año.

### 3.1 Altas y bajas

Casi todo el privilegio que sobra entra por la puerta del alta y se queda porque la baja nunca se hizo del todo. Dos listas cortas, aplicadas siempre, evitan el 90%:

**Alta**

1. ¿Cuál es el nivel más bajo del árbol donde puede trabajar? Ahí va.
2. ¿Es externa o temporal? Grupo invitado y `expires_at`.
3. El rol se escribe explícitamente, aunque coincida con el valor por defecto.
4. Se anota en `docs/organizacion.md` si es una excepción.

**Baja**

1. `GET /users/:id/memberships` — todo lo que toca en la instancia.
2. Quitar las membresías, empezando por las directas del proyecto.
3. Revisar si dejó tokens de proyecto o de grupo creados a su nombre.
4. **Bloquear el usuario en vez de borrarlo**: `POST /users/:id/block` conserva la autoría de sus commits, issues y merge requests; borrarlo la reasigna a un usuario fantasma y estropea el historial que la Semana 08 va a medir.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Árbol que copia el organigrama | Cinco niveles, permisos ilegibles y reorganizaciones que mueven repositorios | Modelar el acceso, no la jerarquía de personas |
| Roles altos en la raíz "de momento" | Bajan a todo el árbol y no se pueden recortar en un hijo | El acceso mínimo arriba; las excepciones abajo |
| Token personal en un pipeline | Cuando la persona se va, se rompe producción; y el token puede todo lo que ella podía | Token de proyecto o de grupo, con rol y caducidad |
| Auditoría anual con hoja de cálculo | Se hace una vez y no se repite | Tres consultas a la API, guardadas en un script |
| Documentar el árbol en una wiki aparte | Se desincroniza y nadie la abre | `docs/organizacion.md` en el repositorio, junto al código |
| Un subgrupo por cada proyecto | Ruta más larga, cero permisos distintos | El subgrupo se justifica por permisos o por volumen |

---

## 5. Trucos

- **Salud del árbol en una línea**: `GET /groups/:id/members/all | jq '[.[]|select(.access_level>=40)]|length'` cuenta Maintainers y Owners de golpe.
- **Accesos sin caducidad**: `jq -r '.[] | select(.expires_at == null) | .username'` sobre los miembros. Para lo externo, debería salir vacío.
- **Antes de dar de baja a alguien**: `GET /users/:id/memberships` enumera todo lo que toca en la instancia.
- **Bots visibles**: los usuarios de token aparecen en la lista de miembros como `project_<id>_bot_…` o `group_<id>_bot_…`. Si ves uno que nadie reconoce, revócalo.
- **Documentación que no envejece sola**: pon la fecha de la última auditoría en `docs/organizacion.md` y revísala cuando abras el archivo.

---

## 📚 Recursos Adicionales

- [Buenas prácticas de permisos](https://docs.gitlab.com/ee/user/permissions.html) — la referencia de qué puede cada rol
- [Tokens de grupo](https://docs.gitlab.com/ee/user/group/settings/group_access_tokens.html) — alcance, scopes y usuario bot
- [Tokens de proyecto](https://docs.gitlab.com/ee/user/project/settings/project_access_tokens.html) — la variante de un solo proyecto

---

## ✅ Checklist de Verificación

- [ ] Sabes qué patrón de árbol usa tu plataforma y por qué
- [ ] Sabes en qué nivel va cada uno de tus tres usuarios de laboratorio
- [ ] Sabes qué identidad usar en un pipeline, y por qué no la tuya
- [ ] Tienes claro qué tres preguntas responde la auditoría y con qué comandos

---

[← Anterior: Mover y renombrar](07-mover-y-renombrar-sin-romper.md) · [Volver a la Semana 03](../README.md)

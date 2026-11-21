# Tokens para máquinas

> El auditor necesita leer todos los proyectos del grupo cada mañana, sin que nadie esté delante. Darle tu token personal es lo rápido: tiene `api`, eres Owner, funciona a la primera. También es darle a un script que corre en un pod la capacidad de borrar tu grupo, y atarlo a tu cuenta: el día que la desactives, la auditoría se para. Esta teoría es la de elegir con qué se autentica una máquina.

---

## 🎯 Objetivos

- Elegir entre token de grupo, de proyecto, personal, `CI_JOB_TOKEN` y token de despliegue para cada automatización
- Separar las dos llaves de un token: el rol del bot y el scope del token
- Fijar la caducidad y rotar sin tocar el código
- Guardar el token en una variable que nadie pueda volver a leer

---

## 1. Qué problema resuelve

Un token tiene tres preguntas detrás, y el token personal las contesta todas mal para una máquina:

| Pregunta | Token personal | Lo que quiere el auditor |
|---|---|---|
| ¿De quién es? | Tuyo. Si te vas, deja de funcionar | De nadie: del grupo |
| ¿Qué puede hacer? | Lo que puedas hacer tú, en toda la instancia | Leer, solo en este grupo |
| ¿Cuánto dura? | Lo que pusiste al crearlo | Poco, y que renovarlo sea una llamada |

---

## 2. Cómo funciona

### 2.1 Los cinco tipos

| Token | Pertenece a | Alcance | Tier | Úsalo para |
|---|---|---|---|---|
| **Personal** (PAT) | Una persona | Todo lo que esa persona ve | Free | Tus scripts en tu terminal |
| **De grupo** | Un usuario bot del grupo | El grupo y sus subgrupos y proyectos | Free en autohospedado | Automatizaciones que recorren el grupo: el auditor |
| **De proyecto** | Un usuario bot del proyecto | Un proyecto | Free en autohospedado | Una automatización que solo toca un proyecto |
| **`CI_JOB_TOKEN`** | El job, mientras dura | Los endpoints que admiten token de job, con los permisos de quien lanzó el pipeline | Free | Leer artefactos, paquetes o el registry desde otro job; disparar pipelines |
| **De despliegue** | El proyecto o grupo | Repositorio, registry y paquetes; **no** la API | Free | Clonar o descargar imágenes desde fuera |

Los tokens de grupo y de proyecto no son tuyos: al crearlos, GitLab crea un **usuario bot** (`group_<id>_bot_<hash>`) y lo hace miembro con el rol que elijas. El token es de ese bot. Puedes irte del grupo y el auditor sigue.

El `CI_JOB_TOKEN` no sirve aquí: solo existe mientras dura un job, no alcanza los endpoints de proyectos y ramas protegidas que necesita el auditor, y ejecutaría con los permisos de quien lanzó el pipeline, que en un pipeline programado es el dueño de la programación.

### 2.2 Dos llaves: rol y scope

Un token puede lo que permitan **a la vez** el rol de su bot y los scopes del token. Las dos tienen que dejar pasar:

| Bot auditor (Reporter, `read_api`) intenta… | Rol | Scope | Resultado |
|---|:--:|:--:|---|
| Listar los proyectos del grupo | ✅ | ✅ | `200` |
| Leer `protected_branches` de `app` | ✅ | ✅ | `200` |
| Leer los webhooks de `app` | ❌ (Maintainer) | ✅ | `403 Forbidden` |
| Crear un issue en `app` | ✅ | ❌ (`api`) | `403 insufficient_scope` |

Por eso el auditor es **Reporter con `read_api`**: con `api`, un fallo en el script podría escribir; con Maintainer, vería variables y webhooks que no necesita. Si mañana el auditor tiene que mirar los webhooks, sube el rol a Maintainer sabiendo lo que añade, no "por si acaso".

### 2.3 Caducidad

En 19.2.4, la API exige `expires_at` (`400 Bad request - expires_at is missing`), y no acepta más de un año desde hoy. Caducar no es un riesgo que evitar: es lo que convierte un token filtrado hace dos años en un token muerto. El auditor caduca en 90 días como mucho, y renovarlo está en su manual (proyecto de la semana).

### 2.4 Rotar

Rotar es pedir un token nuevo para el mismo bot y revocar el viejo en la misma llamada:

```bash
curl -s --request POST "$API/groups/$G/access_tokens/$TID/rotate" -H "$H" \
  --data "expires_at=$(date -d '+90 days' +%F)" | jq -c '{id, name, expires_at, active}'
# {"id":16,"name":"auditor","expires_at":"2027-02-19","active":true}
```

El `id` cambia, el bot no. El token viejo queda `revoked: true` en el listado. Lo único que hay que tocar después es la variable `AUDITOR_TOKEN`. Si el código lee el token de una variable, rotar no es un cambio de código.

`GET /groups/:id/access_tokens` también da `last_used_at`: un token que nadie usa desde hace un mes es un token que sobra.

### 2.5 Dónde vive: la variable oculta

| Ajuste de la variable | Qué impide |
|---|---|
| `masked` | Que el valor salga en el log de un job |
| `hidden` (con `masked_and_hidden=true`, solo al crearla) | Que nadie, ni tú, lo vuelva a leer en la UI o en la API: `"value": null` |
| `protected` | Que llegue a un pipeline de una rama no protegida, donde cualquiera con Developer podría hacer `echo` |

Oculta y protegida, el token solo existe en dos sitios: dentro de GitLab y en la memoria de los jobs de `main`. Si lo necesitas otra vez, no se lee: se rota.

---

## 3. Cómo se configura

**Con la UI**: `Settings → Access tokens` del grupo → *Add new token*. Nombre, fecha, rol `Reporter`, scope `read_api`. El token sale **una vez**.

**Con la API**:

```bash
( umask 077
  curl -s --request POST "$API/groups/$G/access_tokens" -H "$H" \
    --data name=auditor --data access_level=20 --data "scopes[]=read_api" \
    --data "expires_at=$(date -d '+90 days' +%F)" | jq -r .token | tr -d '\n' > ~/bc-s17/auditor.token )
```

Necesitas ser **Owner** del grupo. El token se escribe en un archivo con `umask 077` y se borra cuando está en la variable (práctica 01).

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Tu token personal en la variable del auditor | Puede todo lo que puedes tú; se rompe cuando te vas | Token de grupo con su bot |
| Scope `api` "por si acaso" | Un error del script escribe en producción | `read_api` mientras solo lea |
| Rol Maintainer para un script de lectura | Ve variables, webhooks y tokens que no necesita | Reporter, y subirlo con motivo |
| Token sin caducidad o a un año sin plan | Un token filtrado vale para siempre | 90 días y la rotación en el manual |
| Variable solo `masked` | Cualquiera con Maintainer la lee en la UI; una rama no protegida la recibe | `masked_and_hidden` y `protected` |
| Leer el token para "comprobar que está bien" | No se puede, y no hace falta | Un job que lo use; si falla, rotar |

---

## 5. Trucos

- `GET /personal_access_tokens/self` dice qué token estás usando, sus scopes y cuándo caduca, sin saber su ID.
- El nombre del bot (`group_<id>_bot_…`) aparece en el registro de auditoría y como autor de lo que haga: ponerle un nombre de token claro (`auditor`) es lo que lo hace legible.
- Un token por automatización, nunca uno compartido: si el receptor y el auditor usan el mismo, no puedes revocar uno sin parar el otro, ni saber por `last_used_at` cuál lo usó.

---

## 📚 Recursos Adicionales

- [Group access tokens](https://docs.gitlab.com/user/group/settings/group_access_tokens/) — roles, scopes y el usuario bot
- [Token overview](https://docs.gitlab.com/security/tokens/) — todos los tipos de token, qué alcanzan y su prefijo
- [CI/CD job token](https://docs.gitlab.com/ci/jobs/ci_job_token/) — qué endpoints admite y la lista de permitidos

---

## ✅ Checklist de Verificación

- [ ] El bot auditor es Reporter y su token solo tiene `read_api`
- [ ] Has visto el `403` y el `insufficient_scope` del bot, y sabes cuál es cada uno
- [ ] Sabes rotar el token sin buscar su bot y sin tocar el código
- [ ] `AUDITOR_TOKEN` devuelve `"value": null` por API

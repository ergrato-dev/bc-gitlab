# El job token entre proyectos

> Cada job recibe un `CI_JOB_TOKEN` que vive lo que vive el job y actúa en nombre del usuario que lanzó el pipeline. Dentro de su propio proyecto lo has usado sin saberlo: con él clona el runner. Entre proyectos es lo que CE ofrece en lugar de `needs:project`, y por eso tiene una lista de permitidos que hay que mantener corta.

---

## 🎯 Objetivos

- Explicar qué puede hacer `CI_JOB_TOKEN` y con los permisos de quién
- Configurar la lista de permitidos de entrada de un proyecto
- Descargar el artefacto de un job de otro proyecto con el job token
- Distinguir el job token de un token de proyecto y de uno personal

---

## 1. Qué problema resuelve

`infra/entornos` necesita el `.tgz` que generó `package` en `app`. Opciones:

| Opción | Problema |
|---|---|
| `needs:project` | Premium |
| Un token de proyecto de `app` guardado en `infra/entornos` | Otro secreto de larga vida, con fecha de caducidad y rotación |
| Hacer público el artefacto | `app` es privado y su paquete también |
| `CI_JOB_TOKEN` de `infra/entornos` | Ninguno, si `app` lo permite |

---

## 2. Cómo funciona

### 2.1 Qué es

| Propiedad | Valor |
|---|---|
| Vida | Lo que dura el job: al terminar deja de valer |
| Identidad | El usuario que lanzó el pipeline. En un disparo multiproyecto, el que lanzó el de arriba |
| Alcance | Un conjunto pequeño de endpoints: clonar, artefactos, registro de paquetes y de contenedores, releases… no toda la API |
| Formato | Un secreto enmascarado: no aparece en el log |

Que actúe como el usuario quiere decir que **nunca** tiene más permisos que él: si quien fusionó en `app` no es miembro de `infra/entornos`, el job token de un job de `app` no puede tocar `infra/entornos`.

### 2.2 La lista de permitidos de entrada

Además de los permisos del usuario, el **proyecto de destino** decide qué otros proyectos pueden usar su job token contra él. Es la *allowlist* de entrada (`Settings → CI/CD → Job token permissions`):

| Configuración de `app` | Un job de `infra/entornos` lee un artefacto de `app` |
|---|:--:|
| Restringida, lista con solo `app` | ❌ `404` |
| Restringida, lista con `app` e `infra/entornos` | ✅ si el usuario es miembro de `app` |
| Sin restringir (*All groups and projects*) | ✅ si el usuario es miembro de `app` |

La dirección importa y es la que confunde: **quien descarga** es `infra/entornos`, pero **la lista que se toca** es la de `app`, el proyecto al que se accede. La lista dice "a mí me pueden leer estos".

Un proyecto nuevo nace con la lista activada y con solo él mismo dentro. Un administrador puede imponerla en toda la instancia (`Admin → Settings → CI/CD → Job token permissions`), y entonces nadie puede desactivarla en su proyecto. Todo esto es CE.

### 2.3 Descargar un artefacto de otro proyecto

```sh
curl --fail -sS -o app.tgz --header "JOB-TOKEN: $CI_JOB_TOKEN" \
  "$CI_API_V4_URL/projects/$APP_PROJECT_ID/jobs/$APP_PACKAGE_JOB_ID/artifacts"
```

| Pieza | De dónde sale |
|---|---|
| `CI_API_V4_URL` | Predefinida: la API vista desde el runner |
| `APP_PROJECT_ID`, `APP_PACKAGE_JOB_ID` | Las variables del job de disparo (teoría 05), la segunda vía `dotenv` (teoría 02) |
| `--fail` | Sin él, un `404` guarda el JSON de error como `app.tgz` y el job sigue |

`.../jobs/<id>/artifacts` devuelve el archivo comprimido con todos los artefactos del job. Para uno solo: `.../jobs/<id>/artifacts/<ruta>`.

¿Por qué no `.../jobs/artifacts/main/download?job=package`, "el último de `main`"? Porque el último pipeline **terminado** de `main` puede ser el anterior al que disparó a `infra/entornos`: el de ahora sigue en marcha, esperando a `infra`. Descargarías la versión equivocada sin ningún error.

### 2.4 Los permisos finos

Además de la lista de proyectos, cada entrada puede limitar **qué endpoints** puede usar el job token de ese proyecto (*fine-grained permissions*). Cuando los configures, el mínimo para `infra/entornos` es leer artefactos de jobs. Hasta entonces, la lista de proyectos ya cierra la puerta a todos los demás.

---

## 3. Cómo se configura

Con la UI: en `app`, `Settings → CI/CD → Job token permissions`, **Add → Project**, ruta de `infra/entornos`.

Con la API (requiere Maintainer en `app`):

```bash
# ¿Está activada la restricción?
curl -s -H "$H" "$API/projects/$P/job_token_scope" | jq .
# {"inbound_enabled": true, "outbound_enabled": false}

# Añadir infra/entornos a la lista de app.
PI_ID=$(curl -s -H "$H" "$API/projects/$PI" | jq -r .id)
curl -s --request POST "$API/projects/$P/job_token_scope/allowlist" -H "$H" \
  --data "target_project_id=$PI_ID" | jq .

# Quién está en la lista.
curl -s -H "$H" "$API/projects/$P/job_token_scope/allowlist" | jq -r '.[].path_with_namespace'
```

`outbound_enabled` es un campo heredado que se va a retirar: la lista que cuenta es la de entrada.

Si `inbound_enabled` es `false`, actívala antes de nada:

```bash
curl -s --request PATCH "$API/projects/$P/job_token_scope" -H "$H" \
  --data "enabled=true" -o /dev/null -w '%{http_code}\n'      # 204
```

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Desactivar la restricción "porque falla" | Cualquier proyecto de la instancia, con un usuario miembro de `app`, puede leer sus artefactos | Añade solo el proyecto que lo necesita |
| Añadir el grupo entero a la lista | Cada proyecto futuro del grupo hereda el acceso | Proyectos, uno a uno, mientras sean pocos |
| Un token de proyecto en una variable de `infra` para leer `app` | Un secreto de larga vida para algo que el job token hace sin secreto | `CI_JOB_TOKEN` |
| `curl` sin `--fail` | Un error se guarda como el paquete | `--fail`, y comprobar el archivo |
| Descargar "el último artefacto de `main`" | Puede ser el de otro pipeline | El ID del job |

---

## 5. Trucos

- **Quién está autenticado con un job token**: desde un job, `GET $CI_API_V4_URL/job` con `JOB-TOKEN` devuelve el job, su pipeline y su `user`.
- **Diferenciar un `404` de permisos de uno de verdad**: prueba el mismo `GET` con tu token personal. Si a ti te responde y al job no, es la lista o la pertenencia del usuario.
- **Revisar las listas de todos tus proyectos**: un bucle sobre `GET /groups/:id/projects` con `GET .../job_token_scope/allowlist` para cada uno. La Semana 17 lo convierte en auditoría.

---

## 📚 Recursos Adicionales

- [GitLab CI/CD job token](https://docs.gitlab.com/ci/jobs/ci_job_token/) — qué puede hacer y la lista de permitidos
- [Project job token scope API](https://docs.gitlab.com/api/project_job_token_scopes/)
- [Download job artifacts](https://docs.gitlab.com/api/job_artifacts/) — los endpoints que acepta el job token

---

## ✅ Checklist de Verificación

- [ ] Sabes con los permisos de quién actúa el job token de un pipeline disparado
- [ ] Sabes qué proyecto tiene que tener a cuál en su lista, y por qué en esa dirección
- [ ] Sabes por qué se descarga por ID de job y no "el último de `main`"
- [ ] Sabes qué sustituye el job token cuando no tienes `needs:project`

---

[← Anterior: Pipelines multiproyecto](05-pipelines-multiproyecto.md) · [Volver a la Semana 11](../README.md) · [Siguiente: `resource_group` →](07-resource-groups.md)

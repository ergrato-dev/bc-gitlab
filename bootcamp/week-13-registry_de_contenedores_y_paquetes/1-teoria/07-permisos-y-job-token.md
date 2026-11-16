# Permisos y job token

> El registry y el registro de paquetes no tienen permisos propios: usan los del proyecto. Lo que sí cambia es **quién** pregunta. Una persona, un job del mismo proyecto, un job de otro proyecto y una máquina de despliegue piden lo mismo con credenciales distintas, y cada una tiene su forma de fallar. La más traicionera responde `404` cuando quiere decir "no tienes permiso".

---

## 🎯 Objetivos

- Predecir si un job puede descargar una imagen o un paquete de otro proyecto
- Interpretar el `404` de un job token como lo que es
- Elegir entre PAT, deploy token y job token para cada consumidor
- Ajustar la visibilidad del registry y del registro de paquetes por separado del código

---

## 1. Qué problema resuelve

En la Semana 11, `infra/entornos` descargaba el artefacto de `app` con su `CI_JOB_TOKEN`, y funcionó porque `app` tenía a `infra/entornos` en la lista de permitidos de su job token. Esta semana descarga un paquete en lugar de un artefacto. La pregunta es si la misma lista sirve, y qué ves si no.

---

## 2. Cómo funciona

### 2.1 Las dos comprobaciones de un job token

Un job de `infra/entornos` pide un paquete de `app`. GitLab comprueba **dos** cosas:

| Comprobación | Pregunta | Dónde se configura |
|---|---|---|
| El usuario | ¿Quien lanzó el pipeline tiene al menos Reporter en `app`? | Miembros de `app` |
| La lista de permitidos | ¿`app` deja entrar a los jobs de `infra/entornos`? | `Settings → CI/CD → Job token permissions` de **`app`** |

La lista es del proyecto **al que se entra**, no del que sale. Es la misma para artefactos, paquetes, imágenes y API: la que la Semana 11 configuró en `app` sirve sin cambiar nada.

### 2.2 El `404`

Probado en 19.2.4, descargando un paquete genérico de otro proyecto:

| Situación | Respuesta |
|---|---|
| El proyecto destino no está en la lista | `curl: (22) The requested URL returned error: 404` |
| Añadido con `POST /projects/:id/job_token_scope/allowlist` | `200` y el archivo |

GitLab no dice "prohibido" para no confirmar que el proyecto existe. Un `404` desde un job, con la URL bien escrita, se lee como **"mira la lista de permitidos"**.

### 2.3 Las imágenes de otro proyecto

Lo mismo vale para un `image:` que apunta al registry de otro proyecto: el runner la descarga con el job token del job. Si la Semana 12 no hubiera metido al grupo en la lista de `ci/componentes`, un componente que usara una imagen del registry de `ci/componentes` fallaría en cada consumidor al descargarla.

### 2.4 Qué credencial, para quién

| Consumidor | Credencial | Por qué |
|---|---|---|
| Tú, en tu terminal | PAT con `read_registry`/`write_registry` | Ligada a ti, con caducidad |
| Un job de este proyecto | `CI_JOB_TOKEN` | Ya está; caduca con el job |
| Un job de otro proyecto | `CI_JOB_TOKEN` + lista de permitidos | Sin secretos que guardar |
| Miembros de un grupo invitado a `app` (Semana 03) | La suya; manda el rol tope de la invitación | Con Reporter descargan imágenes y paquetes; no suben nada |
| Una máquina fuera de GitLab (un servidor de despliegue) | **Deploy token** con `read_registry` y `read_package_registry` | No es una persona: no ocupa un usuario ni se va cuando alguien deja el equipo |

Un deploy token se llama `gitlab+deploy-token-N`. Si lo creas con el nombre exacto `gitlab-deploy-token`, GitLab lo expone en los jobs como `CI_DEPLOY_USER` y `CI_DEPLOY_PASSWORD`. La Semana 25 lo usa para que el clúster descargue la imagen.

Un deploy token **no puede subir** a un repositorio de imágenes ni a un paquete protegido, tenga el scope que tenga (teoría 03).

### 2.5 La visibilidad, por separado

Un proyecto público puede tener el registry privado, y al revés:

| Campo del proyecto | Valores |
|---|---|
| `container_registry_access_level` | `enabled` (como el proyecto), `private` (solo miembros), `disabled` |
| `package_registry_access_level` | `enabled`, `private`, `public`, `disabled` |

`app` es privado: los dos en `enabled` equivalen a "solo miembros". Si algún día `app` se hiciera pública para enseñar el código, `private` en el registry evita publicar sin querer las imágenes.

---

## 3. Cómo se configura

```bash
# Quién puede entrar en app con su job token
curl -s -H "$H" "$API/projects/$P/job_token_scope/allowlist" | jq -r '.[].path_with_namespace'
curl -s -H "$H" "$API/projects/$P/job_token_scope/groups_allowlist" | jq -r '.[].full_path'

# La visibilidad de cada registry
curl -s -H "$H" "$API/projects/$P" | jq '{container_registry_access_level, package_registry_access_level}'
```

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Ante un `404` del job, revisar la URL una y otra vez | La URL estaba bien | La lista de permitidos del destino |
| Un PAT en una variable de CI para descargar de otro proyecto | Un secreto más, con tus permisos, que caduca | Job token y lista |
| Un PAT personal en el servidor de despliegue | Se rompe cuando la persona se va | Deploy token |
| Abrir la lista a toda la instancia | Cualquier job de cualquier proyecto entra | Proyectos o grupos concretos |
| Hacer el proyecto público para que otro lo descargue | Publicas también el código y las imágenes | La lista, o un deploy token |

---

## 5. Trucos

- **Probar el acceso de un job**: el job token solo existe dentro de un job, así que la prueba es un job de una línea con `curl -sS -o /dev/null -w '%{http_code}'`. `200` o `404`, sin más.
- **¿Está activa la lista?** `GET /projects/:id/job_token_scope` devuelve `inbound_enabled`. Con `false`, cualquier job de la instancia entra. En un proyecto nuevo de 19.2.4 viene en `true`.

---

## 📚 Recursos Adicionales

- [CI/CD job token](https://docs.gitlab.com/ci/jobs/ci_job_token/) — la lista de permitidos
- [Deploy tokens](https://docs.gitlab.com/user/project/deploy_tokens/)
- [Project visibility for the container registry](https://docs.gitlab.com/user/packages/container_registry/#container-registry-visibility-permissions)

---

## ✅ Checklist de Verificación

- [ ] Sabes qué dos cosas comprueba GitLab cuando un job pide algo de otro proyecto
- [ ] Sabes qué significa un `404` desde un job
- [ ] Sabes quién debe usar un deploy token y quién no
- [ ] Sabes cómo cerrar el registry de un proyecto sin cerrar su código

---

[← Anterior: El dependency proxy](06-el-dependency-proxy.md) · [Volver a la Semana 13](../README.md) · [Siguiente: Qué binario va dónde →](08-que-binario-va-donde.md)

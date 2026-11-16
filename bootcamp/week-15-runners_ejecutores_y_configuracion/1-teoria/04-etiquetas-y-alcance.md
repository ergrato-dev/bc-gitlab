# Etiquetas y alcance

> Un job no elige runner: se queda en la cola hasta que un runner que **puede** cogerlo pregunta. Que pueda depende de tres filtros que se aplican a la vez: el alcance del runner (a qué proyectos atiende), sus etiquetas (qué jobs acepta) y la protección de la rama (teoría 05). Con tres runners, saber predecir qué runner coge cada job es la diferencia entre una flota y una lotería.

---

## 🎯 Objetivos

- Distinguir runners de instancia, de grupo y de proyecto, y quién puede crear cada uno
- Predecir qué runner coge un job a partir de sus `tags` y del `run_untagged` de cada runner
- Saber qué hace `locked` y qué no
- Apagar los runners de instancia en un proyecto que tiene los suyos

---

## 1. Qué problema resuelve

`app` tiene, desde esta semana, dos runners: `docker-app` (sin privilegios) y `dind-app` (con Docker dentro). Si los dos aceptan cualquier job, la mitad de los tests de `app` acabará en el runner privilegiado sin necesitarlo, y el job que sí necesita Docker caerá a veces en `docker-app` y fallará con `Cannot connect to the Docker daemon`. Las etiquetas existen para que eso no dependa de quién pregunta primero.

---

## 2. Cómo funciona

### 2.1 Tres alcances

| Tipo | Lo crea | Atiende a | En este bootcamp |
|---|---|---|---|
| **Instancia** (`instance_type`) | Un administrador | Todos los proyectos que no lo desactiven | El de la Semana 01, si lo tienes. Esta semana se apaga en `app` e `infra/entornos` |
| **Grupo** (`group_type`) | Owner del grupo | Todos los proyectos del grupo y de sus subgrupos | `deploy-infra`, en el grupo `infra` |
| **Proyecto** (`project_type`) | Maintainer del proyecto | Su proyecto, y los que se le asignen | `docker-app` y `dind-app`, de `app` |

Un runner de proyecto **pertenece** a un proyecto y puede asignarse a otros (la Semana 11 asignó `docker-app` a `infra/entornos`). Del proyecto dueño no se puede quitar:

```
403 Forbidden - You cannot unassign a runner from the owner project. Delete the runner instead
```

De los demás, sí: es lo que hace la práctica 03 con `infra/entornos`.

### 2.2 Cómo se empareja un job

Para cada job, GitLab compara sus `tags` con las del runner que pregunta:

| El job pide | El runner tiene | ¿Lo coge? |
|---|---|:--:|
| Nada | `run_untagged = true` | ✅ |
| Nada | `run_untagged = false` | ❌ |
| `[dind]` | `[dind]` | ✅ |
| `[dind]` | `[docker]` | ❌ |
| `[docker]` | `[docker, linux]` | ✅ (las del job tienen que estar todas en el runner) |
| `[docker, linux]` | `[docker]` | ❌ |

La regla: **todas las etiquetas del job tienen que estar en el runner**; el runner puede tener más. Y un runner con `run_untagged = false` solo coge jobs que pidan alguna de las suyas.

Con eso, la flota de esta semana:

| Runner | `tag_list` | `run_untagged` | Coge |
|---|---|:--:|---|
| `docker-app` | `docker` | `true` | Todo lo de `app` sin etiqueta, y lo que pida `docker` |
| `dind-app` | `dind` | `false` | Solo `probar-imagen` |
| `deploy-infra` | `deploy` | `false` | Solo `desplegar`, y solo en ramas protegidas (teoría 05) |

Si un job no encaja con ningún runner `online` del proyecto, se queda en `pending`. GitLab lo marca en la UI como atascado (*stuck*) y no falla: espera a que aparezca un runner que sí pueda.

### 2.3 `locked`

`locked = true` en un runner de proyecto impide que **otros Maintainers** lo asignen a sus proyectos desde la UI o la API. No impide nada a un administrador (comprobado en `19.2.4`), y no tiene sentido en runners de grupo o de instancia. `dind-app` nace bloqueado: un runner privilegiado no debería acabar, sin que lo decidas, atendiendo a un proyecto que no es el tuyo.

### 2.4 Apagar los runners de instancia

Un proyecto con runners propios puede seguir recibiendo los de instancia. Si el de instancia acepta jobs sin etiqueta, compite con `docker-app` por ellos y tus jobs corren en una máquina que no controlas. Se apaga por proyecto:

```bash
glab api --method PUT "projects/plataforma-<tu-dominio>%2Fapp" -f shared_runners_enabled=false \
  | jq '.shared_runners_enabled'
# false
```

Y por grupo, con `shared_runners_setting` (`enabled`, `disabled_and_overridable`, `disabled_and_unoverridable`), para que un proyecto nuevo nazca sin ellos.

---

## 3. Cómo se configura

Las etiquetas, `run_untagged` y `locked` se cambian en GitLab, nunca en `config.toml` (teoría 02):

```bash
glab api --method PUT "runners/<id>" -f tag_list=dind -f run_untagged=false -f locked=true \
  | jq -c '{description, tag_list, run_untagged, locked}'
```

En la UI: `Settings → CI/CD → Runners → (runner) → Edit`.

En el job, `tags`. Admite variables, lo que permite elegir runner por entorno sin duplicar el job:

```yaml
probar-imagen:
  tags: [dind]
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

Para saber por qué un job no arranca, se pregunta lo mismo que se pregunta GitLab:

```bash
glab api "projects/plataforma-<tu-dominio>%2Fapp/jobs/<job>" | jq -c '{status, tag_list}'
glab api "projects/plataforma-<tu-dominio>%2Fapp/runners?tag_list=dind&status=online" | jq 'length'
# 0 → nadie puede cogerlo
```

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Todos los runners con `run_untagged = true` | Cualquier job cae en cualquier runner, también en el privilegiado | Un solo runner para lo genérico; los especiales, `run_untagged = false` |
| Etiquetas con el nombre de la máquina (`pc-de-ana`) | El día que esa máquina cambia, hay que tocar todos los pipelines | Etiquetas por capacidad: `docker`, `dind`, `deploy` |
| Dejar los runners de instancia encendidos "por si acaso" | Tus jobs corren donde no sabes, con una caché que no es la tuya | `shared_runners_enabled = false` en los proyectos con flota propia |
| Asignar el runner de proyecto a todo el grupo, uno por uno | Cada proyecto nuevo hay que acordarse de asignarlo | Si es para todo el grupo, que sea un runner de grupo |

---

## 5. Trucos

- `GET /groups/:id/runners?type=group_type` lista los runners del grupo; sin `type`, también los de instancia que ve el grupo.
- GraphQL `project { runners { nodes { description runnerType } } }` devuelve los runners que **ve** el proyecto, también los de grupo heredados, que la API REST de proyecto no enseña con `type=project_type`.

---

## 📚 Recursos Adicionales

- [Runner scopes](https://docs.gitlab.com/ci/runners/runners_scope/)
- [Control jobs that a runner can run](https://docs.gitlab.com/ci/runners/configure_runners/#control-jobs-that-a-runner-can-run)
- [`tags`](https://docs.gitlab.com/ci/yaml/#tags)

---

## ✅ Checklist de Verificación

- [ ] Sé quién puede crear un runner de cada tipo y a qué proyectos atiende
- [ ] Sé predecir si un runner coge un job a partir de las dos listas de etiquetas y de `run_untagged`
- [ ] Sé qué impide `locked` y qué no
- [ ] Sé apagar los runners de instancia en un proyecto y en un grupo

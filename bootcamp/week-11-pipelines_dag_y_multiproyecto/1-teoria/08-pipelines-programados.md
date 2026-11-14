# Pipelines programados

> Un pipeline programado es un pipeline normal que nadie empuja: lo crea GitLab a la hora que dice un cron, sobre una rama, con los permisos de su propietario. La trampa no está en el cron: está en que todas las reglas que dicen "en `main`" también coinciden a las siete de la mañana.

---

## 🎯 Objetivos

- Crear un pipeline programado con cron, zona horaria, rama y variables
- Explicar con los permisos de quién se ejecuta y qué pasa cuando esa persona se va
- Saber por qué un programado puede ejecutar menos a menudo de lo que dice su cron
- Escribir las reglas para que un programado ejecute **solo** lo que tiene que ejecutar

---

## 1. Qué problema resuelve

`docs/secretos.md` dice cuándo caduca cada secreto. Que lo diga no avisa a nadie: alguien tiene que leerlo a tiempo. Un job que lea las fechas y falle 30 días antes de cada caducidad convierte el inventario en una alarma. Ese job no tiene ningún commit que lo dispare: tiene que ejecutarse cada día, haya cambios o no.

Otros usos del mismo mecanismo: reconstruir la imagen cada semana para recoger los parches de la base, ejecutar las pruebas lentas de noche, limpiar entornos de revisión olvidados.

---

## 2. Cómo funciona

### 2.1 Qué es un programado

| Campo | Ejemplo | Nota |
|---|---|---|
| `description` | `Caducidades de secretos` | Es lo único que dice para qué existe |
| `cron` | `0 7 * * 1-5` | Sintaxis cron estándar de cinco campos |
| `cron_timezone` | `UTC` | Sin ella, la zona de la instancia. Con horario de verano, una hora "se mueve" |
| `ref` | `main` | La rama sobre la que se crea, con el último commit en ese momento |
| `active` | `true` | Uno inactivo no se ejecuta, y no avisa |
| variables | `TAREA=caducidades` | Variables de pipeline: distinguen un programado de otro |

El pipeline que crea tiene `CI_PIPELINE_SOURCE == "schedule"` y es un pipeline de rama: `CI_COMMIT_BRANCH` vale `main`.

### 2.2 Con los permisos de quién

Un programado tiene **propietario**: quien lo creó o quien lo tomó después. El pipeline se crea **como él**:

| Consecuencia | Por qué importa |
|---|---|
| En una rama protegida, el propietario tiene que poder fusionar en ella | Si no, el programado no se crea |
| Las variables del programado son variables de pipeline | Se les aplica la restricción de la Semana 10: el propietario necesita el rol mínimo |
| Un disparo multiproyecto desde el programado usa su identidad | Teoría 05 |
| Si el propietario es bloqueado o sale del proyecto, el programado **se desactiva** | En silencio. El día que alguien se va, sus programados dejan de ejecutarse |

Un Maintainer recupera un programado huérfano con **Take ownership**, y a partir de ese momento se ejecuta como él. La Semana 17 revisa por API los programados cuyo propietario ya no está.

### 2.3 Por qué no se ejecuta cuando dice el cron

Un proceso de Sidekiq revisa los programados pendientes con su propia frecuencia: en Omnibus, `gitlab_rails['pipeline_schedule_worker_cron']`, por defecto `"3-59/10 * * * *"` (cada diez minutos, en el minuto 3, 13, 23…). Un programado con `cron: "*/1 * * * *"` se ejecuta, como mucho, cada diez minutos. Y un programado a las `07:00` se ejecuta a las `07:03`.

Además, `Admin → Settings → CI/CD → CI/CD limits` limita cuántos pipelines programados puede crear un proyecto al día. En tu instancia mandas tú; en la de una empresa, pregunta antes de programar cada minuto.

### 2.4 La trampa: las reglas de `main` coinciden

El programado se crea sobre `main`. Mira las reglas de `app`:

| Job | Regla | ¿Entra en el programado? |
|---|---|:--:|
| `build`, `test` | `if: $CI_PIPELINE_SOURCE != "merge_request_event"` | ✅ |
| `package` | `if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH` | ✅ |
| `deploy-staging` | `if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH` | ✅ **Despliega cada mañana** |
| `infra` | `if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH` | ✅ Y dispara `infra/entornos` |

Y `rules:changes`, en un pipeline que no es de push ni de merge request, **siempre** se evalúa como verdadero: no hay un "antes" contra el que comparar. Lo que filtrabas por rutas también entra.

La solución es una regla al principio de cada job que no debe entrar, escrita una vez y referenciada:

```yaml
.fuera-de-programados:
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: never

deploy-staging:
  rules:
    - !reference [.fuera-de-programados, rules]
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

`!reference` inserta la lista de reglas de `.fuera-de-programados` y GitLab la aplana: el job ve primero el `when: never` del programado. Y el job del programado, al revés:

```yaml
caducidades:
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule" && $TAREA == "caducidades"
```

Con la variable `TAREA`, un segundo programado (por ejemplo, la reconstrucción semanal) no ejecuta `caducidades`, y al revés.

¿Y en `workflow`? No sirve: `workflow:rules` decide si el pipeline nace, no qué jobs tiene.

---

## 3. Cómo se configura

Con la UI: `Build → Pipeline schedules → New schedule`.

Con la API:

```bash
SID=$(curl -s --request POST "$API/projects/$P/pipeline_schedules" -H "$H" \
  --data-urlencode "description=Caducidades de secretos" \
  --data "ref=main" --data-urlencode "cron=0 7 * * 1-5" --data "cron_timezone=UTC" \
  --data "active=true" | jq -r .id)

curl -s --request POST "$API/projects/$P/pipeline_schedules/$SID/variables" -H "$H" \
  --data "key=TAREA" --data "value=caducidades" | jq -c '{key, value}'

# Ejecutarlo ahora, sin esperar al cron.
curl -s --request POST "$API/projects/$P/pipeline_schedules/$SID/play" -H "$H" | jq .

# Sus pipelines.
curl -s -H "$H" "$API/projects/$P/pipeline_schedules/$SID/pipelines" | jq -r '.[] | "\(.id) \(.status)"'
```

Con `glab`: `glab schedule list`, `glab schedule create --cron "0 7 * * 1-5" --description "…" --ref main` y `glab schedule run <id>`.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Programado sobre `main` sin revisar las reglas | Despliega y dispara cada vez que se ejecuta | `.fuera-de-programados` en cada job que no debe entrar |
| Confiar en `rules:changes` para dejar fuera un job del programado | Siempre es verdadero en un programado | `if` sobre `CI_PIPELINE_SOURCE` |
| Programado a nombre de una persona que puede irse | Se desactiva en silencio | Revisión periódica de propietarios (Semana 17) |
| Programado sin `description` útil | Dentro de seis meses nadie sabe si se puede borrar | Qué vigila y a quién avisa |
| Un programado cada minuto | Se ejecuta cada diez de todas formas, y llena la lista de pipelines | La frecuencia que de verdad necesitas |
| Un programado que falla y nadie lee | La alarma existe pero no suena | El aviso por correo de pipeline fallido, y en la Semana 17, un webhook |

---

## 5. Trucos

- **Quién es el propietario de cada programado**: `GET .../pipeline_schedules | jq -r '.[] | "\(.id) \(.description) \(.owner.username) active=\(.active)"'`.
- **Cuándo se ejecutará**: el campo `next_run_at` del programado. Si no coincide con lo que esperabas, mira la zona horaria.
- **Probar un programado sin tocar `main`**: crea otro con `ref` sobre una rama de prueba, ejecútalo con `play` y bórralo.

---

## 📚 Recursos Adicionales

- [Scheduled pipelines](https://docs.gitlab.com/ci/pipelines/schedules/) — propietario, *take ownership* y límites
- [Pipeline schedules API](https://docs.gitlab.com/api/pipeline_schedules/)
- [Run jobs for scheduled pipelines](https://docs.gitlab.com/ci/jobs/job_rules/#run-jobs-for-scheduled-pipelines)
- [`!reference`](https://docs.gitlab.com/ci/yaml/yaml_optimization/#reference-tags)

---

## ✅ Checklist de Verificación

- [ ] Sabes con los permisos de quién se ejecuta un programado y qué pasa cuando se va
- [ ] Sabes qué jobs de `app` entrarían en un programado sin `.fuera-de-programados`
- [ ] Sabes por qué `rules:changes` no sirve para dejar fuera un job de un programado
- [ ] Sabes por qué un cron de cada minuto se ejecuta cada diez

---

[← Anterior: `resource_group`](07-resource-groups.md) · [Volver a la Semana 11](../README.md)

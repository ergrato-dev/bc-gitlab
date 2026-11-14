# `workflow`: cuándo nace un pipeline

> `rules` decide qué jobs entran en un pipeline. `workflow:rules` decide antes si el pipeline nace. En la Semana 09 copiaste cuatro líneas sin desmontarlas. Hoy las lees una a una, les pones nombre a los pipelines y haces que un commit nuevo cancele el trabajo que ya no sirve.

---

## 🎯 Objetivos

- Distinguir los orígenes de un pipeline por `CI_PIPELINE_SOURCE`
- Explicar cada línea del `workflow:rules` de `app` y qué pasaría sin ella
- Dar nombre a cada pipeline con `workflow:name`
- Cancelar los jobs obsoletos con `workflow:auto_cancel`, y proteger los que no se deben cortar

---

## 1. Qué problema resuelve

Sin `workflow:rules`, un push a una rama con merge request abierta crea dos pipelines sobre el mismo commit: el de la rama y el de la merge request. Gastan el doble de runner, y la merge request muestra uno mientras el otro puede fallar en silencio. Y sin `auto_cancel`, tres pushes seguidos dejan tres pipelines en cola, aunque solo importe el último.

---

## 2. Cómo funciona

### 2.1 Los orígenes

`CI_PIPELINE_SOURCE` dice qué creó el pipeline. Los que verás en `app`:

| Valor | Quién lo crea |
|---|---|
| `push` | Un push a una rama o un tag |
| `merge_request_event` | Abrir una merge request, empujar a su rama o `POST .../merge_requests/<iid>/pipelines` |
| `web` | `Build → Pipelines → Run pipeline` |
| `api` | `POST .../pipeline` |
| `schedule` | Un pipeline programado (Semana 11) |
| `trigger`, `pipeline`, `parent_pipeline` | Otros pipelines (Semana 11) |

### 2.2 El bloque de `app`, desmontado

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"   # 1
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS     # 2
      when: never
    - if: $CI_COMMIT_BRANCH                               # 3
    - if: $CI_COMMIT_TAG                                  # 4
```

Funciona igual que `rules` de un job: la primera regla que coincide decide; si ninguna coincide, no hay pipeline.

| Línea | Qué deja pasar | Sin ella |
|:--:|---|---|
| 1 | Todo pipeline de merge request | Las merge requests no tendrían pipeline: *Pipelines must succeed* las bloquearía todas |
| 2 | Nada: un push a una rama **con merge request abierta** no crea pipeline de rama | Dos pipelines por push: el de rama y el de merge request |
| 3 | Cualquier otro push a una rama: `main`, `release/*`, ramas sin merge request | Un push a `main` no tendría pipeline: ni `package` ni despliegue |
| 4 | Los tags | Un tag `v*` no tendría pipeline |

¿Y los pipelines lanzados a mano (`web`) o por API (`api`) sobre una rama? Tienen `CI_COMMIT_BRANCH`, así que pasan por la 2 y la 3. Sobre una rama con merge request abierta, la 2 los bloquea:

```
The pipeline did not run. Review the workflow:rules configuration for the pipeline.
```

No es un error del laboratorio: es la línea 2 haciendo su trabajo. Para relanzar el pipeline de una merge request se usa `POST .../merge_requests/<iid>/pipelines`, como en la Semana 09.

### 2.3 El orden importa

Si la línea 3 fuera antes que la 2, cualquier push a una rama coincidiría con ella y la 2 no se evaluaría nunca: volverían los pipelines duplicados. Por eso `when: never` va antes que la regla general que lo contiene.

### 2.4 `workflow:name`

```yaml
workflow:
  name: "$CI_PIPELINE_SOURCE · $CI_COMMIT_REF_NAME"
```

Cada pipeline lleva ese nombre en la lista, en la API (`.name`) y en la variable `CI_PIPELINE_NAME`. Con él, `GET .../pipelines` dice de un vistazo qué es cada uno: `push · main`, `merge_request_event · 42-reglas`. Se puede cambiar desde una regla con `variables`, por ejemplo para marcar los pipelines de tag.

### 2.5 `workflow:auto_cancel`

```yaml
workflow:
  auto_cancel:
    on_new_commit: interruptible
```

Cuando llega un commit nuevo a la misma rama, GitLab puede cancelar el pipeline anterior, que ya prueba un código que nadie va a fusionar:

| `on_new_commit` | Qué cancela del pipeline anterior |
|---|---|
| `conservative` (por defecto) | Solo si ningún job no interrumpible ha empezado |
| `interruptible` | Los jobs con `interruptible: true`, estén donde estén; los demás siguen |
| `none` | Nada |

`app` usa `interruptible`: todos los jobs lo son por `default`, y los dos de despliegue lo desactivan (`interruptible: false` en `.deploy`). Un despliegue cortado a la mitad deja el entorno en un estado que nadie ha probado; un `npm ci` cortado no deja nada.

`auto_cancel:on_job_failure: all` cancela el resto del pipeline en cuanto falla un job. `app` no lo usa: con stages en serie, un fallo ya detiene los stages siguientes.

---

## 3. Cómo se configura

Los pipelines de una rama y su nombre:

```bash
curl -s -H "$H" "$API/projects/$P/pipelines?per_page=5" \
  | jq -r '.[] | "\(.id) \(.status) \(.source) \(.name)"'
```

Cuántos pipelines tiene un commit: si salen dos, `workflow:rules` no está haciendo su trabajo.

```bash
SHA=$(git rev-parse HEAD)
curl -s -H "$H" "$API/projects/$P/pipelines?sha=$SHA" | jq -r '.[] | "\(.id) \(.source)"'
```

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Sin `workflow:rules` | Pipelines duplicados en cada merge request | El bloque de `app` |
| `workflow:rules` sin regla para merge requests | Las merge requests no tienen pipeline y *Pipelines must succeed* las bloquea | La línea 1 |
| `when: never` después de la regla general | Nunca se evalúa | De lo particular a lo general |
| `auto_cancel` con un despliegue interrumpible | Un commit nuevo corta el despliegue a la mitad | `interruptible: false` en los despliegues |
| Las plantillas `Workflows/MergeRequest-Pipelines.gitlab-ci.yml` sin leerlas | Hacen algo parecido, pero no lo has decidido tú | Escribe las cuatro líneas y entiéndelas |

---

## 5. Trucos

- **Qué creó un pipeline**: `GET .../pipelines/<id> | jq -r .source`.
- **Nombre distinto para los tags**: una regla `- if: $CI_COMMIT_TAG` con `variables: {NOMBRE: "release $CI_COMMIT_TAG"}` y `name: $NOMBRE`.
- **Saber si `auto_cancel` actuó**: el pipeline anterior queda en `canceled` y sus jobs interrumpibles también.

---

## 📚 Recursos Adicionales

- [`workflow`](https://docs.gitlab.com/ci/yaml/#workflow) — `rules`, `name` y `auto_cancel`
- [Switch between branch pipelines and merge request pipelines](https://docs.gitlab.com/ci/yaml/workflow/#switch-between-branch-pipelines-and-merge-request-pipelines) — el bloque de `app` en la documentación
- [Auto-cancel redundant pipelines](https://docs.gitlab.com/ci/pipelines/settings/#auto-cancel-redundant-pipelines) — qué se cancela y cuándo

---

## ✅ Checklist de Verificación

- [ ] Sabes qué hace cada una de las cuatro líneas de `workflow:rules` y qué pasaría sin ella
- [ ] Sabes por qué `POST .../pipeline` sobre una rama con merge request abierta no crea nada
- [ ] Sabes qué jobs cancela `on_new_commit: interruptible` y por qué los despliegues no
- [ ] Sabes cómo comprobar que un commit tiene un solo pipeline

---

[← Anterior: `rules`: cuándo entra un job](01-rules-cuando-entra-un-job.md) · [Volver a la Semana 10](../README.md) · [Siguiente: Variables →](03-variables-de-donde-salen.md)

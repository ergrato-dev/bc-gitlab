# Las condiciones para fusionar

> El botón *Merge* está gris y el mensaje dice algo genérico. La API lo dice en una palabra. Saber leer esa palabra, y qué ajuste del proyecto la produce, es la diferencia entre arreglar el bloqueo en un minuto y desactivar el ajuste "porque molesta".

## 🎯 Objetivos

- Leer `detailed_merge_status` y saber qué hacer con cada valor
- Configurar las condiciones de fusión que CE ofrece, y saber cuál no activar todavía
- Resolver `need_rebase` sin salir de GitLab, y `conflict` en local
- Fusionar por API con la garantía de que nadie empujó mientras revisabas
- Distinguir lo que CE comprueba de lo que solo comprueba Premium

---

## 1. Qué problema resuelve

Una merge request puede no estar lista por muchos motivos: sigue en borrador, tiene hilos abiertos, choca con `main`, necesita rebase. La UI los resume en un mensaje que cambia de una versión a otra. La API los expone en un campo estable, pensado para scripts:

```bash
curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .detailed_merge_status
```

---

## 2. Los valores

Verificados en `app/services/merge_requests/mergeability/` de la 19.2.4. Cada servicio de comprobación tiene su identificador, y el primero que falla es el que se devuelve. Las de Git (rebase y conflicto) van al final, y **la de rebase va antes que la de conflicto**:

| Valor | Significa | Cómo se arregla |
|---|---|---|
| `mergeable` | Todo bien | Fusionar |
| `draft_status` | Está en borrador | `/ready` |
| `discussions_not_resolved` | Hay hilos abiertos y el proyecto lo exige | Responder y resolver |
| `need_rebase` | El método es `rebase_merge` o `ff` y la rama no contiene la punta de `main` | `/rebase`, o rebase local |
| `conflict` | La rama y `main` tocan las mismas líneas (con `rebase_merge` o `ff` casi nunca lo verás: sale antes `need_rebase`) | Resolver en la UI o en local |
| `not_open` | Está cerrada o ya fusionada | Reabrir, si procede |
| `ci_must_pass` | El proyecto exige pipeline en verde y no lo está | Semana 09 |
| `ci_still_running` | Hay pipeline y no ha terminado | Esperar |
| `commits_status` | La rama de origen no existe o no tiene commits nuevos | Empujar la rama |
| `locked_lfs_files` | Toca archivos LFS bloqueados por otra persona | Pedir que los libere |
| `merge_time` | Tiene una hora mínima de fusión programada y no ha llegado | Esperar |
| `checking`, `unchecked`, `preparing` | GitLab todavía lo está calculando | Volver a preguntar en unos segundos |

> [!NOTE]
> En Premium hay más valores, como `not_approved` o `requested_changes`. En CE no existen: ni la falta de aprobación ni un *Request changes* bloquean la fusión.

---

## 3. Los ajustes que la producen

En `Settings → Merge requests`, o por API sobre el proyecto:

| Ajuste | Campo | Esta semana |
|---|---|---|
| *All threads must be resolved* | `only_allow_merge_if_all_discussions_are_resolved` | **Activar** |
| *Enable "Delete source branch" option by default* | `remove_source_branch_after_merge` | **Activar** |
| *Pipelines must succeed* | `only_allow_merge_if_pipeline_succeeds` | **No activar todavía** |
| Método de fusión | `merge_method` | Teoría [05](05-estrategias-de-fusion.md) |
| Squash | `squash_option` | Teoría [05](05-estrategias-de-fusion.md) |

> [!WARNING]
> **No actives *Pipelines must succeed* esta semana.** `app` aún no tiene `.gitlab-ci.yml`, y sin pipeline la comprobación falla: ninguna merge request se podría fusionar. Se activa en la Semana 09, cuando el pipeline exista.

Borrar la rama al fusionar no es cosmético. Una rama fusionada que se queda es una rama que alguien reutiliza dos semanas después, con la base vieja, y cuyo `need_rebase` nadie entiende.

---

## 4. `need_rebase` y `conflict`

Con `rebase_merge` o `ff`, cada fusión deja atrás a todas las demás merge requests abiertas. Es el precio de la historia lineal, y se paga de dos formas según haya conflicto o no.

Como `need_rebase` se comprueba primero, el estado no te dice cuál de las dos es. Lo dice otro campo:

```bash
curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq '{detailed_merge_status, has_conflicts}'
```

### 4.1 Sin conflicto: rebase en el servidor

```bash
# Desde un comentario
/rebase

# Por API
curl -s --request PUT "$API/projects/$P/merge_requests/$MR/rebase" -H "$H"
curl -s -H "$H" "$API/projects/$P/merge_requests/$MR?include_rebase_in_progress=true" \
  | jq '{rebase_in_progress, merge_error, detailed_merge_status}'
```

GitLab reescribe la rama de origen sobre la punta de `main`. Si falla, `merge_error` dice por qué, casi siempre porque había conflicto. Y como reescribe la rama, tu clon local queda divergente: `git pull --rebase` antes de seguir.

> [!IMPORTANT]
> Igual que el squash, **los commits rebasados en el servidor no llevan tu firma**: GitLab los reescribe sin tu clave. Si quieres conservar la firma en los commits de la rama, haz el rebase en local.

### 4.2 Con conflicto: en local

```bash
git fetch origin
git switch 9-el-limite-de-prestamos
git rebase origin/main
# Git se para en el commit que choca. Editas, y:
git add src/prestamos.ts
git rebase --continue
npm test
git push --force-with-lease
```

`--force-with-lease` y no `--force`: si alguien empujó a la rama mientras hacías el rebase (por ejemplo, aplicando una sugerencia), el push falla en vez de borrar su commit. Es la Semana 02 aplicada.

Para conflictos sencillos, la UI ofrece *Resolve conflicts* con un editor en el navegador. Funciona, pero hace un commit de fusión de `main` sobre tu rama, que es justo lo que una historia lineal intenta evitar.

---

## 5. Fusionar por API sin sorpresas

```bash
SHA=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MR" | jq -r .sha)
# ... revisas ...
curl -s --request PUT "$API/projects/$P/merge_requests/$MR/merge" -H "$H" \
  --data-urlencode "sha=$SHA" \
  --data-urlencode "squash=true" \
  --data-urlencode "should_remove_source_branch=true" \
  | jq '{state, merge_commit_sha, squash_commit_sha}'
```

El parámetro `sha` hace que la fusión **falle si la punta de la rama ya no es la que revisaste**. Sin él, fusionas lo que haya, incluido un commit que alguien empujó hace diez segundos.

Si la merge request no se puede fusionar, o el `sha` no coincide, la respuesta es un error `4xx` con un mensaje corto. Mira `detailed_merge_status` antes de intentarlo: dice lo mismo, en una palabra que un script puede comparar.

---

## 6. Lo que es de pago

| Condición | Tier | En CE |
|---|---|---|
| Hilos resueltos | Free | ✅ |
| Pipeline en verde | Free | ✅ (Semana 09) |
| Aprobaciones obligatorias, reglas de aprobación | Premium | Aprobación opcional; comprobación por API en la Semana 07 |
| Aprobación de *code owners* | Premium | CODEOWNERS informativo y un job (Semana 07) |
| *Request changes* que bloquea | Premium | Un hilo abierto bloquea igual |
| Dependencias entre merge requests | Premium | "Depende de !12" en la descripción |
| Trenes de fusión | Premium | Rebase y fusión de una en una |
| *External status checks* | Ultimate | Un job del pipeline que consulta el servicio externo |

---

## 7. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Desactivar "hilos resueltos" porque bloquea | El ajuste existe precisamente para bloquear | Resolver los hilos, o no abrirlos para nada |
| Activar "pipeline en verde" sin pipeline | Nada se puede fusionar | Esperar a la Semana 09 |
| `--force` en vez de `--force-with-lease` | Borra commits de otros sin avisar | `--force-with-lease`, siempre |
| Fusionar sin `sha` desde un script | Entra lo que no se revisó | `sha=` del commit revisado |
| Dejar ramas fusionadas vivas | Se reutilizan con la base vieja | Borrado al fusionar por defecto |

---

## 📚 Recursos Adicionales

- [Comprobaciones de fusión](https://docs.gitlab.com/ee/user/project/merge_requests/merge_checks.html) — cuáles hay y cuáles son Premium
- [API de merge requests: estado detallado](https://docs.gitlab.com/ee/api/merge_requests.html#merge-status) — los valores de `detailed_merge_status`
- [Conflictos en merge requests](https://docs.gitlab.com/ee/user/project/merge_requests/conflicts.html) — resolverlos en la UI y en local

---

## ✅ Checklist de Verificación

- [ ] Sabes leer `detailed_merge_status` y qué hacer con cuatro de sus valores
- [ ] Sabes por qué *Pipelines must succeed* no se activa esta semana
- [ ] Sabes cuándo basta con `/rebase` y cuándo hay que hacer rebase en local
- [ ] Sabes qué protege el parámetro `sha` al fusionar por API

---

[← Anterior: Estrategias de fusión](05-estrategias-de-fusion.md) · [Volver a la Semana 06](../README.md) · [Siguiente: El oficio de revisar →](07-el-oficio-de-revisar.md)

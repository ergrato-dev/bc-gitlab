# Releases en GitLab

> El tag dice "esto es la `0.1.0`". La release dice qué hay dentro, qué issues cierra, dónde descargarla y qué se sabía de ella el día que salió. Las dos cosas son gratis en CE, y la segunda es la que lee quien usa `app`.

---

## 🎯 Objetivos

- Distinguir tag y release, y saber qué añade la release encima del tag
- Crear, leer, actualizar y borrar releases con la API v4
- Asociar una release a un hito y añadirle enlaces a artefactos
- Saber qué rol hace falta para publicar una versión `v*` y qué error devuelve GitLab si no lo tienes
- Entender la evidencia de una release y cuándo no se genera

---

## 1. Qué problema resuelve

Un tag es un nombre para un commit. Para saber qué cambió entre la `0.1.0` y la `0.1.1` con solo el tag, hay que clonar el repositorio y leer `git log`. Quien usa `app` no debería tener que hacerlo.

Una **release** es una página de GitLab colgada de un tag, con:

- **Notas** en Markdown: qué cambió, para quien usa la versión
- **Hitos** asociados: qué issues y merge requests entraron
- **Assets**: el código fuente empaquetado (automático) y enlaces a binarios, imágenes o paquetes
- **Evidencia**: una foto en JSON del hito y sus issues en el momento de publicar

Todo esto es **CE**. Lo único de pago cerca de las releases son los hitos de grupo asociados a una release (Premium); los de proyecto, que son los de `app`, funcionan en CE.

---

## 2. Cómo funciona

### 2.1 Tag y release

| | Tag | Release |
|---|---|---|
| Dónde vive | En Git | En la base de datos de GitLab |
| Se crea con | `git tag` + `git push`, o la API de tags | La API de releases o `Deploy → Releases` |
| Si se borra | Desaparece la versión | Desaparece la página; **el tag se queda** |
| Protección | Tags protegidos `v*` | La misma: publicar la release exige poder crear el tag |

Una release siempre tiene un tag. Si el tag no existe, la API lo crea desde `ref`. Si ya existe, lo usa tal cual.

### 2.2 Quién puede publicar

Antes de nada, el servicio de releases comprueba si el usuario **podría crear el tag**, aunque el tag ya exista. Con `v*` protegido para Maintainers (Semana 07), un Developer no puede publicar una release `v0.1.0`:

```
{"message":"You are not allowed to create this tag as it is protected."}   # 403
```

Otros errores que verás:

| Código | Mensaje | Causa |
|---|---|---|
| `409` | `Release already exists` | Ya hay una release para ese tag: usa `PUT` |
| `400` | `Milestone(s) not found: v0.1.0` | El hito no existe en el proyecto, o es de grupo |
| `422` | `Ref is not specified` | El tag no existe y no pasaste `ref` |

### 2.3 Los campos que importan

| Parámetro | Para qué |
|---|---|
| `tag_name` | La versión. Obligatorio |
| `ref` | Desde dónde crear el tag si no existe. En `app` no se usa: el tag firmado se empuja antes |
| `tag_message` | Mensaje si la API crea el tag: lo hace anotado. Firmado no puede hacerlo |
| `name` | El título de la página. Si falta, usa el tag |
| `description` | Las notas, en Markdown: en `app`, las que genera `GET .../repository/changelog` |
| `milestones[]` | Títulos de hitos del proyecto |
| `released_at` | Fecha de publicación. Por defecto, ahora |
| `assets[links][]` | `name`, `url`, `link_type` (`other`, `runbook`, `image`, `package`) y `direct_asset_path` opcional |

`direct_asset_path` da al enlace una URL estable: `.../-/releases/v0.1.0/downloads/<ruta>` siempre lleva al asset de esa versión, y `.../-/releases/permalink/latest/downloads/<ruta>` al de la última. En la Semana 13 la usarás para los paquetes.

### 2.4 Pasada, presente y futura

`released_at` cambia el tipo de release:

| `released_at` | Tipo | Evidencia |
|---|---|---|
| Omitido o ahora | Normal | Se genera al crearla |
| En el futuro | *Upcoming release*: la UI la marca como próxima | Se genera cuando llega la fecha |
| Anterior a la creación | *Historical release* | **No se genera** |

La evidencia es una foto JSON del proyecto, los hitos y sus issues en el momento de la publicación. Sirve para responder "¿qué se sabía cuando salió?" aunque después alguien edite los issues. Se ve en la API como `evidences[]`, con `sha`, `filepath` y `collected_at`.

### 2.5 Lo que la release calcula sola

- **`assets.sources`**: el código del tag en `zip`, `tar.gz`, `tar.bz2` y `tar`. No hay que subir nada.
- **`commit`**: el commit al que apunta el tag.
- **`_links`**: URLs a los issues y merge requests cerrados del hito, para navegar desde la release.

---

## 3. Cómo se configura

### 3.1 Con la UI

`Deploy → Releases → Create a new release`. Eliges el tag (o lo creas), el título, los hitos y las notas. La UI no genera notas: o las escribes, o las pegas de la API del CHANGELOG.

### 3.2 Con la API

Crear la release sobre un tag ya empujado:

```bash
NOTAS=$(curl -s -G -H "$H" "$API/projects/$P/repository/changelog" \
  --data-urlencode "version=0.1.0" --data-urlencode "from=$PRIMERO" | jq -r .notes)

curl -s --request POST "$API/projects/$P/releases" -H "$H" \
  --data-urlencode "tag_name=v0.1.0" \
  --data-urlencode "name=v0.1.0" \
  --data-urlencode "description=$NOTAS" \
  --data-urlencode "milestones[]=v0.1.0" \
  --data-urlencode "assets[links][][name]=CHANGELOG.md" \
  --data-urlencode "assets[links][][url]=$GITLAB_URL/$PROYECTO/-/blob/v0.1.0/CHANGELOG.md" \
  --data-urlencode "assets[links][][link_type]=other" \
  | jq '{tag_name, released_at, milestones: [.milestones[].title], links: [.assets.links[].name]}'
```

Leer, corregir y borrar:

```bash
curl -s -H "$H" "$API/projects/$P/releases" | jq -r '.[] | "\(.tag_name)  \(.released_at)"'
curl -s -H "$H" "$API/projects/$P/releases/permalink/latest" | jq -r .tag_name
curl -s --request PUT "$API/projects/$P/releases/v0.1.0" -H "$H" --data-urlencode "description=$NOTAS"
```

> [!WARNING]
> `DELETE .../releases/<tag>` existe y deja el tag, pero se pierden la fecha original y la evidencia. Corregir es `PUT`; borrar, solo una release que nadie ha visto todavía.

`glab release create v0.1.0 --notes-file notas.md` hace lo mismo desde la terminal, si usas `glab`.

### 3.3 En un pipeline

Cuando `app` tenga pipeline (Fase 3), la palabra clave `release:` de `.gitlab-ci.yml` crea la release desde un job. No cambia nada de lo anterior: llama a la misma API, con el `CI_JOB_TOKEN` del job.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Notas escritas a mano en la release | Se olvidan cambios y se cuelan los que no salieron | Notas desde `GET .../repository/changelog` |
| Dejar que la API cree el tag desde `ref=main` | El tag no va firmado, y `main` puede haber avanzado mientras tanto | Empujar antes el tag firmado y crear la release sobre él |
| Borrar y recrear una release para corregir las notas | Se pierden la fecha original y la evidencia | `PUT .../releases/<tag>` |
| `released_at` en el pasado para "ordenar" releases | Releases históricas sin evidencia | Publicar en su momento |
| Un hito de grupo en una release de CE | `400 Milestone(s) not found` | Hitos de proyecto |
| Subir binarios como enlaces a sitios externos efímeros | El enlace se rompe y la release queda coja | Package Registry y `direct_asset_path` (Semana 13) |

---

## 5. Trucos

- **La última release, sin saber su tag**: `GET .../releases/permalink/latest`.
- **Qué issues cerró una versión**: `GET .../releases/v0.1.0 | jq -r '._links.closed_issues_url'` y ábrela en el navegador.
- **La evidencia en una línea**: `GET .../releases/v0.1.0 | jq '.evidences[] | {collected_at, sha}'`.
- **Las releases por fecha**, para métricas: `GET .../releases?order_by=released_at&sort=asc`.

---

## 📚 Recursos Adicionales

- [Releases](https://docs.gitlab.com/user/project/releases/) — tipos, evidencia, permisos y enlaces
- [Releases API](https://docs.gitlab.com/api/releases/) — todos los parámetros
- [Release links API](https://docs.gitlab.com/api/releases/links/) — añadir y quitar assets después de publicar
- [`glab release create`](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/release/create.md) — la misma operación desde `glab`

---

## ✅ Checklist de Verificación

- [ ] Sabes qué se pierde y qué se queda al borrar una release
- [ ] Sabes por qué un Developer no puede publicar `v0.1.0` en `app`
- [ ] Sabes qué parámetros usarás para crear la release de `v0.1.0`
- [ ] Sabes cuándo no se genera evidencia
- [ ] Sabes corregir las notas de una release sin perder su fecha

---

[← Anterior: Versionado semántico](02-versionado-semantico.md) · [Volver a la Semana 08](../README.md) · [Siguiente: El CHANGELOG generado →](04-changelog-generado.md)

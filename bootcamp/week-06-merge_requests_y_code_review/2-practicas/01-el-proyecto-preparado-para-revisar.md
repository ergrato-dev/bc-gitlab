# Práctica 01 — El proyecto preparado para revisar

> Antes de la primera merge request, el proyecto tiene que saber cómo se fusiona, qué bloquea una fusión, qué mensaje deja el commit y qué plantilla ve el autor. Y la decisión tiene que quedar escrita.

**Duración estimada**: 50 min
**Prerrequisitos**: Semana 05 completada · Teoría [02](../1-teoria/02-plantillas-de-merge-request.md), [05](../1-teoria/05-estrategias-de-fusion.md) y [06](../1-teoria/06-las-condiciones-para-fusionar.md) leídas

---

## Contexto

Todo lo que hace esta práctica son ajustes y archivos que **no se ven hasta que alguien abre una merge request**. Por eso va primero: si configuras el método de fusión después de la primera merge request, la primera entra con el método por defecto y la historia de `main` empieza mezclando dos estilos.

Al terminar, `app` tendrá método de fusión, squash, hilos obligatorios, borrado de rama, plantillas de commit, la plantilla `Default` de merge request y el ADR-004 que lo explica.

---

## Paso 0: Preparar el terreno

**Por qué**: las variables de la API y el clon local al día, porque vas a empujar un archivo.

```bash
source ~/.bc-gitlab

export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)

cd /ruta/a/tu/clon/de/app
git switch main && git pull --ff-only
```

**Verifica**: `curl -s -H "$H" "$API/projects/$P" | jq -r '.path_with_namespace'` imprime tu proyecto, y `git status` dice que estás al día con `origin/main`.

---

## Paso 1: Lo que hay ahora

**Por qué**: para saber de dónde partes. Todo lo que vas a cambiar está en el objeto del proyecto.

```bash
curl -s -H "$H" "$API/projects/$P" | jq '{
  merge_method, squash_option,
  only_allow_merge_if_all_discussions_are_resolved,
  only_allow_merge_if_pipeline_succeeds,
  remove_source_branch_after_merge,
  merge_commit_template, squash_commit_template, suggestion_commit_message
}'
```

**Verifica**: lo esperable en un proyecto nuevo es `merge_method: "merge"`, `squash_option: "default_off"`, los dos `only_allow_*` a `false` y las tres plantillas a `null`. Si algo difiere, alguien lo cambió antes: anótalo, porque lo vas a sobrescribir.

---

## Paso 2: Las condiciones de fusión

**Por qué**: es la decisión de la teoría [05](../1-teoria/05-estrategias-de-fusion.md). Aquí se usa la recomendada, `rebase_merge` con squash por defecto; si eliges `ff`, cambia una palabra y explícalo en el ADR del paso 5.

```bash
curl -s --request PUT "$API/projects/$P" -H "$H" \
  --data-urlencode "merge_method=rebase_merge" \
  --data-urlencode "squash_option=default_on" \
  --data-urlencode "only_allow_merge_if_all_discussions_are_resolved=true" \
  --data-urlencode "remove_source_branch_after_merge=true" \
  | jq '{merge_method, squash_option, only_allow_merge_if_all_discussions_are_resolved, remove_source_branch_after_merge}'
```

> [!WARNING]
> **No toques `only_allow_merge_if_pipeline_succeeds`.** `app` no tiene pipeline todavía, y con ese ajuste activado ninguna merge request se podría fusionar. Va en la Semana 09.

**Verifica**: la salida muestra exactamente los cuatro valores que enviaste. Abre `Settings → Merge requests` en la UI y localiza cada uno: *Merge commit with semi-linear history*, *Encourage*, *All threads must be resolved* y *Enable "Delete source branch" option by default*.

---

## Paso 3: Las plantillas de los commits

**Por qué**: el commit de squash es lo que quedará en `git log` de cada merge request. Que diga qué issue cerró y quién lo revisó es lo que hace la historia trazable sin abrir GitLab. Y el de sugerencias aplicadas, que respete el formato convencional y conserve el crédito de quien sugirió.

```bash
SQUASH=$(printf '%s\n\n%s\n\n%s\n%s\n%s' \
  '%{title} (%{local_reference})' '%{issues}' '%{reviewed_by}' '%{approved_by}' '%{co_authored_by}')

SUGERENCIA=$(printf '%s\n\n%s' \
  'fix: apply %{suggestions_count} review suggestion(s)' '%{co_authored_by}')

curl -s --request PUT "$API/projects/$P" -H "$H" \
  --data-urlencode "squash_commit_template=$SQUASH" \
  --data-urlencode "suggestion_commit_message=$SUGERENCIA" \
  | jq -r '.squash_commit_template, "---", .suggestion_commit_message'
```

`printf` en vez de un literal con `\n` porque así los saltos de línea llegan como saltos de verdad, en bash y en zsh.

**Verifica**: la salida muestra las dos plantillas con sus saltos de línea, y la de squash contiene `%{reviewed_by}`.

> [!NOTE]
> No hace falta `merge_commit_template`: con squash por defecto, el commit que cuenta es el de squash. El de fusión se queda con su mensaje por defecto, que ya incluye la referencia a la merge request.

---

## Paso 4: La plantilla `Default` de merge request

**Por qué**: es la que se aplica sola al abrir una merge request desde la UI, el issue o la terminal (teoría [02](../1-teoria/02-plantillas-de-merge-request.md)). Tiene que estar en `main` antes de la primera merge request, o la primera nacerá sin ella.

```bash
mkdir -p .gitlab/merge_request_templates

cat > .gitlab/merge_request_templates/Default.md <<'EOF'
## Qué cambia

<!-- Una o dos frases. Lo que notará quien use la librería. -->

## Por qué

<!-- El problema, no la solución. Si está en el issue, no lo repitas. -->

## Cómo se prueba

<!-- Comandos exactos y resultado esperado. -->

## Issue

<!--
Closes #N. Si la rama empieza por el número del issue (7-la-multa-...),
GitLab añade "Closes #7" al final de esta descripción él solo.
Si el cambio no cierra ningún issue, explica aquí por qué existe.
-->

## Antes de pedir revisión

- [ ] `npm test` en verde en mi máquina
- [ ] Commits firmados y con mensaje convencional
- [ ] He leído mi propio diff entero
- [ ] La merge request hace una sola cosa

/assign me
EOF

git add .gitlab/merge_request_templates/Default.md
git commit -m "docs: add default merge request template"
git push origin main
```

> [!IMPORTANT]
> Es **el último push directo a `main`** de la plataforma. A partir de la práctica 02 todo entra por merge request, y en la Semana 07 `main` quedará protegida para que esta frase deje de depender de tu disciplina.

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/templates/merge_requests" | jq -r '.[].key'
curl -s -H "$H" "$API/projects/$P/templates/merge_requests/Default" | jq -r '.content' | grep -c 'Closes #'
```

La primera imprime `Default`. La segunda, `1`.

---

## Paso 5: El ADR-004

**Por qué**: la estrategia de fusión es una decisión con consecuencias que dura años, y quien llegue al proyecto se preguntará por qué la historia tiene burbujas o por qué no hay commits de "wip". Es exactamente lo que un ADR responde, en la wiki, junto a los de las Semanas 04 y 05.

```bash
curl -s --request POST "$API/projects/$P/wikis" -H "$H" \
  --data-urlencode "title=ADR-004 Estrategia de fusion" \
  --data-urlencode "content@-" <<'EOF' | jq -r '.slug'
# ADR-004 — Estrategia de fusión

- **Estado**: aceptado
- **Fecha**: AAAA-MM-DD

## Contexto

`app` empieza a recibir cambios por merge request. Hay que decidir cómo
entran en `main`: con o sin commit de fusión, con o sin squash, y qué
condiciones tiene que cumplir una merge request para poder fusionarse.

## Decisión

- Método de fusión: **merge commit with semi-linear history** (`rebase_merge`).
- Squash: **por defecto** (`default_on`); quien fusiona puede desmarcarlo
  si los commits de la rama merecen quedarse.
- Solo se fusiona con **todos los hilos resueltos**.
- La rama de origen **se borra al fusionar**.
- El commit de squash lleva el título, la referencia a la merge request,
  los issues que cierra y las líneas `Reviewed-by:` y `Approved-by:`.

## Consecuencias

- La historia de `main` se lee en línea, con un marcador por merge request.
- Lo que se fusiona es exactamente lo que se revisó, porque la rama tiene
  que contener la punta de `main`.
- **Precio**: cada fusión deja en `need_rebase` a las demás merge requests
  abiertas; hay que hacer rebase antes de fusionarlas.
- **Precio**: los commits de squash, fusión y rebase en el servidor no
  llevan firma SSH. Los commits firmados son los de la rama.
- La aprobación es opcional en CE: lo que bloquea son los hilos.
EOF
```

Cambia `AAAA-MM-DD` por la fecha de hoy antes de ejecutarlo, y si elegiste `ff`, reescribe la decisión y sus consecuencias: sin commit de fusión, sin burbujas, un commit por merge request.

**Verifica**:

```bash
curl -s -H "$H" "$API/projects/$P/wikis" | jq -r '.[].slug' | grep -i '^adr-004'
```

Añade el enlace al ADR en la barra lateral de la wiki (`_sidebar`), igual que hiciste con los anteriores.

---

## Paso 6: Una mirada de conjunto

**Por qué**: para confirmar que todo lo de esta práctica está en su sitio antes de abrir la primera merge request.

```bash
curl -s -H "$H" "$API/projects/$P" | jq '{
  merge_method, squash_option,
  hilos: .only_allow_merge_if_all_discussions_are_resolved,
  borrar_rama: .remove_source_branch_after_merge,
  pipeline: .only_allow_merge_if_pipeline_succeeds,
  squash_con_revisores: (.squash_commit_template | contains("%{reviewed_by}"))
}'
```

**Verifica**: `pipeline` sigue en `false` y todo lo demás tiene el valor que decidiste.

---

## ✅ Resultado

- [ ] `merge_method` es `rebase_merge` (o `ff`, y sabes por qué)
- [ ] `squash_option` es `default_on` (o `always`)
- [ ] Los hilos abiertos bloquean la fusión y la rama se borra al fusionar
- [ ] La plantilla de squash deja `Reviewed-by:` y `Approved-by:` en la historia
- [ ] `Default.md` está en `main` y GitLab la detecta
- [ ] El ADR-004 está en la wiki y enlazado desde la barra lateral

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 06
```

Esta práctica cubre las ocho primeras comprobaciones. Las demás fallan hasta que haya merge requests fusionadas.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `PUT` devuelve `400` con `merge_method does not have a valid value` | Valor mal escrito | `ff`, `rebase_merge` o `merge`, sin mayúsculas |
| La plantilla de squash sale en una sola línea con `\n` literales | Se escribió con comillas simples y `\n` dentro | Construirla con `printf`, como en el paso 3 |
| `templates/merge_requests` devuelve `[]` | La plantilla no está en la rama por defecto | `git log origin/main -1 --stat` y empujar si falta |
| `templates/merge_requests/Default` devuelve `404` | El archivo se llama `default.md` o está en otra carpeta | La ruta exacta es `.gitlab/merge_request_templates/Default.md` |
| El `push` a `main` se rechaza | `main` ya estaba protegida para tu rol | Comprueba que eres Owner o Maintainer en `app`; si lo eres, protegiste la rama antes de tiempo |
| El ADR sale con slug `ADR-004-Estrategia-de-fusion` | Es lo esperado: el slug conserva las mayúsculas | La comprobación no distingue mayúsculas |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Semana 06](../README.md) | **Práctica 01** | [Práctica 02 — De issue a merge request](02-de-issue-a-merge-request.md) |

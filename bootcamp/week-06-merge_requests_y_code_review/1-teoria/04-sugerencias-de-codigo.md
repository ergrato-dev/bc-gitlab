# Sugerencias de código

> "Creo que aquí sería mejor usar `getUTCDay`" obliga al autor a interpretar, escribir, empujar y esperar otra ronda. Una sugerencia es el cambio exacto, listo para aplicar con un clic. Convierte una opinión en un commit.

## 🎯 Objetivos

- Escribir una sugerencia de una línea y de varias líneas
- Saber quién hace el commit cuando se aplica una sugerencia, y con qué mensaje
- Aplicar varias sugerencias en un solo commit
- Decidir cuándo una sugerencia es la herramienta correcta y cuándo no

---

## 1. Qué problema resuelve

Muchos comentarios de revisión son pequeños y concretos: un nombre, un límite, un mensaje de error. Explicarlos con palabras cuesta más que escribirlos, y el autor puede entenderlos mal. Y cada ida y vuelta es un `push` y una notificación.

Una sugerencia es un comentario sobre una línea del diff que **contiene el texto de reemplazo**. GitLab lo muestra como un diff dentro del comentario, con un botón *Apply suggestion*. Al pulsarlo, GitLab crea un commit en la rama de origen con ese cambio.

---

## 2. La sintaxis

En un comentario sobre una línea del diff, un bloque de código con el lenguaje `suggestion`:

````markdown
Un domingo no es el único día de cierre: el issue habla de festivos.

```suggestion
  if (esDiaDeCierre(dia)) {
```
````

El contenido del bloque **sustituye la línea comentada**. Si el bloque está vacío, la sugerencia es borrar la línea.

### 2.1 Varias líneas

Para abarcar líneas alrededor de la comentada, `suggestion:-<arriba>+<abajo>`:

````markdown
```suggestion:-1+2
export function calcularMulta(diasRetraso: number, inicio: Date): number {
  if (!Number.isInteger(diasRetraso)) {
    throw new TypeError("diasRetraso tiene que ser un numero entero");
  }
```
````

`-1+2` significa "la línea anterior a la comentada, la comentada y las dos siguientes": cuatro líneas que el bloque reemplaza enteras. La sintaxis sale de `SUGGESTION_CONTEXT` en `lib/gitlab/diff/suggestions_parser.rb` de la 19.2.4.

> [!TIP]
> En la UI no hace falta escribir el bloque a mano. El botón **Insert suggestion** de la barra del comentario copia la línea y abre el bloque, y arrastrando el selector de líneas a la izquierda del diff se eligen varias.

---

## 3. Quién hace el commit

Lo crea **quien pulsa *Apply***, normalmente el autor de la merge request, y lo crea GitLab en el servidor. Tres consecuencias:

- **El commit no lleva tu firma SSH.** Lo genera el servidor, no tu Git local. Si tu `CONTRIBUTING.md` exige commits firmados, la regla tiene que admitir estos o pedir que las sugerencias se apliquen a mano.
- **El autor del commit es quien aplica**, no quien sugirió. El crédito al revisor va en el mensaje: el mensaje por defecto termina con `%{co_authored_by}`, que se convierte en una línea `Co-authored-by:` con quien escribió la sugerencia.
- **Tu clon local se queda atrás.** Antes del siguiente commit, `git pull --rebase` en la rama.

### 3.1 El mensaje

Por defecto, el mensaje es `Apply %{suggestions_count} suggestion(s) to %{files_count} file(s)` seguido de `%{co_authored_by}`. El proyecto puede fijar el suyo en `suggestion_commit_message`, con estas variables (verificadas en `lib/gitlab/suggestions/commit_message.rb`):

| Variable | Valor |
|---|---|
| `%{branch_name}` | Rama donde se aplica |
| `%{files_count}` | Número de archivos tocados |
| `%{file_paths}` | Rutas de esos archivos |
| `%{project_name}` / `%{project_path}` | Proyecto |
| `%{user_full_name}` / `%{username}` | Quien aplica |
| `%{suggestions_count}` | Cuántas sugerencias se aplican juntas |
| `%{co_authored_by}` | Una línea `Co-authored-by:` por cada autor de las sugerencias |

Un mensaje que respeta el formato convencional de la Semana 02 y conserva el crédito:

```bash
curl -s --request PUT "$API/projects/$P" -H "$H" \
  --data-urlencode "suggestion_commit_message=$(printf 'fix: aplicar %%{suggestions_count} sugerencia(s) de revision\n\n%%{co_authored_by}')" \
  | jq -r .suggestion_commit_message
```

Al aplicar desde la UI también se puede escribir un mensaje a mano.

---

## 4. Aplicar en lote

Si el revisor dejó cinco sugerencias, aplicarlas una a una son cinco commits. **Add suggestion to batch** en cada una, y **Apply suggestions** al final, las aplica en **un solo commit**.

Por API:

```bash
# Las sugerencias de una merge request, con su id
curl -s -H "$H" "$API/projects/$P/merge_requests/$MR/discussions?per_page=100" \
  | jq -r '.[].notes[] | select(.suggestions? | length > 0) | .suggestions[] | "\(.id)\t\(.applied)\t\(.appliable)"'

# Una
curl -s --request PUT "$API/suggestions/<id>/apply" -H "$H" | jq '.applied'

# Varias, en un commit
curl -s --request PUT "$API/suggestions/batch_apply" -H "$H" \
  --data-urlencode "ids[]=<id1>" --data-urlencode "ids[]=<id2>"
```

> [!NOTE]
> Una sugerencia deja de ser aplicable (`appliable: false`) si las líneas que toca cambiaron después de escribirla: el autor empujó otro commit encima. Hay que escribirla otra vez sobre la versión nueva.

---

## 5. Cuándo sí y cuándo no

| Sí | No |
|---|---|
| Un nombre, un límite, una condición | Un cambio de diseño |
| Un mensaje de error o un comentario | Algo que exige tocar otros archivos |
| Un test que falta y cabe en el bloque | Algo que el autor debe entender antes de aceptarlo |
| Un error tipográfico | Un "yo lo haría así" sin motivo |

La regla: **una sugerencia es para cuando el revisor sabe exactamente el texto correcto y el autor lo va a aceptar sin discutir**. Si el cambio necesita conversación, es un hilo sin bloque. Y si el revisor se encuentra escribiendo veinte sugerencias, lo que hay que hacer es hablar con el autor.

---

## 6. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Sugerencias de estilo que el formateador haría | Ruido en la revisión y commits de nada | Un formateador en el pipeline (Semana 09) |
| Aplicar veinte sugerencias una a una | Veinte commits de "aplicar sugerencia" | En lote, en un commit |
| Aplicar sin leer | Se acepta un error del revisor | La sugerencia se revisa como cualquier código |
| Seguir trabajando en local sin `pull` | Conflicto contigo mismo en el siguiente `push` | `git pull --rebase` tras aplicar |

---

## 📚 Recursos Adicionales

- [Sugerencias de código](https://docs.gitlab.com/ee/user/project/merge_requests/reviews/suggestions.html) — sintaxis, lote y mensaje
- [API de sugerencias](https://docs.gitlab.com/ee/api/suggestions.html) — aplicar una o varias

---

## ✅ Checklist de Verificación

- [ ] Puedes escribir una sugerencia que reemplace tres líneas
- [ ] Sabes quién figura como autor del commit de una sugerencia aplicada, y por qué no lleva tu firma
- [ ] Sabes cómo aplicar cinco sugerencias en un solo commit
- [ ] Sabes cuándo un comentario no debe ser una sugerencia

---

[← Anterior: La revisión en GitLab](03-la-revision-en-gitlab.md) · [Volver a la Semana 06](../README.md) · [Siguiente: Estrategias de fusión →](05-estrategias-de-fusion.md)

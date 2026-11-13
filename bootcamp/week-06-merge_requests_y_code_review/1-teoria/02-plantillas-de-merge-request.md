# Plantillas de merge request

> La descripción de una merge request es lo primero que lee el revisor y lo último que escribe el autor, con prisa. Una plantilla convierte "lo que se me ocurra" en las cuatro preguntas que el revisor necesita contestadas antes de abrir el diff.

## 🎯 Objetivos

- Saber dónde vive una plantilla de merge request y desde qué rama la lee GitLab
- Escribir una plantilla `Default` que sale sola y que obliga a trazar el cambio a un issue
- Usar variables y acciones rápidas dentro de la plantilla, sabiendo cuándo se sustituyen
- Generar el título de la merge request con una plantilla del proyecto
- Distinguir lo que es Free de lo que es Premium en las plantillas

---

## 1. Qué problema resuelve

Sin plantilla, la descripción de una merge request depende del humor del autor. El resultado típico es una línea, "arregla el bug", y un revisor que tiene que reconstruir el contexto leyendo el diff, el issue y, si tiene suerte, los commits.

El revisor necesita cuatro respuestas **antes** de mirar una línea de código:

| Pregunta | Por qué la necesita |
|---|---|
| **¿Qué cambia?** | Para saber qué buscar en el diff |
| **¿Por qué?** | Para juzgar si el cambio resuelve el problema, no solo si compila |
| **¿Cómo se prueba?** | Para reproducirlo sin preguntar |
| **¿Qué issue cierra?** | Para que el tablero y el hito se actualicen solos |

La plantilla hace que esas preguntas estén en la pantalla del autor en el momento de escribir. No garantiza buenas respuestas, pero garantiza que las preguntas se vean.

---

## 2. Dónde vive

Igual que las plantillas de issue de la Semana 05, en una carpeta del repositorio, **en la rama por defecto**:

```
app/
└── .gitlab/
    ├── issue_templates/          # Semana 05
    │   ├── Bug.md
    │   ├── Default.md
    │   └── Feature.md
    └── merge_request_templates/  # Esta semana
        └── Default.md
```

Cada archivo `.md` es una plantilla, y su nombre sin extensión es el que sale en el desplegable. GitLab las lee de la rama por defecto: una plantilla que solo existe en una rama de trabajo no aparece.

Para ver cuáles detecta:

```bash
curl -s -H "$H" "$API/projects/$P/templates/merge_requests" | jq -r '.[].key'
curl -s -H "$H" "$API/projects/$P/templates/merge_requests/Default" | jq -r '.content'
```

### 2.1 La plantilla `Default`

Una plantilla llamada `Default` **se aplica sola** al crear la merge request desde la UI, desde el botón del issue y con *push options*, siempre que la descripción esté vacía. Verificado en `MergeRequests::BuildService` de la 19.2.4: busca una plantilla cuyo nombre sea `default` sin distinguir mayúsculas. Es Free.

Por API (`POST /projects/:id/merge_requests`) **no** se aplica. Si abres merge requests por API, la descripción la mandas tú.

---

## 3. Una plantilla que traza

````markdown
## Qué cambia

<!-- Una o dos frases. Lo que verá alguien que use la librería. -->

## Por qué

<!-- El problema, no la solución. Si está en el issue, enlázalo y no lo repitas. -->

## Cómo se prueba

<!-- Comandos exactos y resultado esperado. -->

```bash
npm test
```

## Issue

<!--
Closes #N. Si la rama empieza por el número del issue (7-la-multa-...),
GitLab añade "Closes #7" al final de la descripción él solo.
Si el cambio no cierra nada, explica aquí por qué existe.
-->

## Antes de pedir revisión

- [ ] `npm test` en verde en mi máquina
- [ ] Commits firmados y con mensaje convencional
- [ ] He leído mi propio diff entero
- [ ] La merge request hace una sola cosa

/assign me
````

Tres decisiones de diseño:

- **Los comentarios HTML no se ven en la merge request publicada**, pero sí al editarla. Sirven de instrucción sin ensuciar el resultado.
- **La lista de casillas es para el autor**, no para el revisor. Son las cosas que se olvidan siempre, y GitLab muestra cuántas están marcadas en la lista de merge requests.
- **`/assign me` al final** asigna la merge request a quien la abre. Es una acción rápida: se ejecuta al guardar y desaparece del texto, como en las plantillas de issue.

---

## 4. Variables en la descripción

La descripción admite unas pocas variables que GitLab sustituye **al crear** la merge request. Las permitidas, según `ALLOWED_NEW_MR_PLACEHOLDERS` en la 19.2.4:

| Variable | Se sustituye por |
|---|---|
| `%{source_branch}` | Rama de origen |
| `%{target_branch}` | Rama de destino |
| `%{first_commit}` | Mensaje completo del primer commit |
| `%{first_multiline_commit}` | El primer commit con cuerpo, título incluido |
| `%{first_multiline_commit_description}` | Solo el cuerpo de ese commit |
| `%{co_authored_by}` | Líneas `Co-authored-by:` de los autores de los commits |
| `%{all_commits}` | Todos los mensajes de commit |

La más útil es `%{first_multiline_commit_description}`: si escribiste un buen cuerpo de commit en la Semana 02, la sección "Por qué" ya está escrita.

---

## 5. El título también se puede generar

En la 19.2.4, el proyecto admite una plantilla para el **título** de las merge requests nuevas, en `mr_default_title_template`. Variables permitidas: `%{source_branch}`, `%{target_branch}`, `%{title_from_branch}`, `%{first_commit_title}`, `%{issue_id}`, `%{issue_title}`.

```bash
curl -s --request PUT "$API/projects/$P" -H "$H" \
  --data-urlencode 'mr_default_title_template=%{first_commit_title}' \
  | jq -r .mr_default_title_template
```

Si tus commits siguen el formato convencional, `%{first_commit_title}` produce títulos como `fix(multas): no cobrar los domingos`, que es exactamente lo que acabará en el commit de squash (teoría [05](05-estrategias-de-fusion.md)). Es opcional: esta semana no se comprueba.

---

## 6. Lo que es de pago

| Feature | Tier | En CE |
|---|---|---|
| Plantillas en `.gitlab/merge_request_templates/` | Free | ✅ |
| Plantilla `Default` aplicada sola | Free | ✅ |
| Plantilla por defecto escrita en los ajustes del proyecto (`merge_requests_template`) | Premium | La plantilla `Default.md` del repositorio |
| Plantillas compartidas desde un proyecto del grupo o de la instancia | Premium | Copiar `Default.md` en cada proyecto; en la Semana 12 lo hará un componente |

---

## 7. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Plantilla de cuarenta líneas | Se borra entera y se escribe "ver issue" | Cuatro secciones y una lista corta |
| Casillas que nadie puede marcar con honestidad | Se marcan todas sin leer | Solo lo que el autor puede comprobar en un minuto |
| Repetir el issue en la descripción | Dos sitios con la misma información, que divergen | Enlazar el issue y contar solo lo nuevo |
| Plantilla solo en la rama de trabajo | No aparece en el desplegable | Fusionarla primero a `main` |
| `Closes #N` escrito a mano sin número | GitLab no cierra nada y nadie se da cuenta | Rama que empieza por el número del issue |

---

## 📚 Recursos Adicionales

- [Plantillas de descripción](https://docs.gitlab.com/ee/user/project/description_templates.html) — issues y merge requests, con la parte Premium marcada
- [API de plantillas de proyecto](https://docs.gitlab.com/ee/api/project_templates.html) — listar y leer las plantillas
- [Acciones rápidas](https://docs.gitlab.com/ee/user/project/quick_actions.html) — cuáles valen en una merge request

---

## ✅ Checklist de Verificación

- [ ] Sabes desde qué rama lee GitLab las plantillas
- [ ] Sabes en qué tres vías de creación se aplica sola la plantilla `Default`, y en cuál no
- [ ] Sabes qué hace GitLab con una rama que empieza por `7-`
- [ ] Puedes nombrar dos variables de descripción y decir cuándo se sustituyen

---

[← Anterior: La merge request como unidad de cambio](01-la-merge-request-como-unidad-de-cambio.md) · [Volver a la Semana 06](../README.md) · [Siguiente: La revisión en GitLab →](03-la-revision-en-gitlab.md)

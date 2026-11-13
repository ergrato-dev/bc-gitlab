# Plantillas de descripción

> Un buen issue no depende de que quien lo escribe se acuerde de qué poner. Depende de que el formulario ya traiga las preguntas.

## 🎯 Objetivos

- Crear plantillas de issue en `.gitlab/issue_templates/` y saber de qué rama las lee GitLab
- Hacer que una plantilla se aplique sola con el nombre `Default`
- Meter acciones rápidas dentro de una plantilla para que el issue nazca etiquetado
- Leer las plantillas de un proyecto por API
- Saber qué niveles de plantilla son Free y cuáles Premium

---

## 1. Qué problema resuelve

Los issues de fallo que llegan sin plantilla se parecen todos: "no funciona el cálculo de multas". Quien lo va a resolver tiene que preguntar qué entrada, qué salida esperaba, qué salida obtuvo y en qué versión. Cuatro mensajes de ida y vuelta antes de empezar, y a veces la persona que lo abrió ya no contesta.

Una plantilla pone esas cuatro preguntas en el formulario. No garantiza que se contesten bien, pero hace que contestarlas sea lo fácil y saltárselas lo difícil.

Y tiene un segundo efecto, menos obvio: **una plantilla puede etiquetar el issue al crearlo**. Un issue creado con la plantilla `Bug` nace con `tipo::bug` y `estado::preparado`, sin que nadie tenga que acordarse. Es la forma más barata de que la taxonomía se cumpla.

---

## 2. Cómo funciona

### 2.1 Dónde viven

Una plantilla es un archivo Markdown en una carpeta concreta del repositorio:

```
.gitlab/
└── issue_templates/
    ├── Bug.md
    ├── Feature.md
    └── Default.md
```

| Regla | Detalle |
|---|---|
| Carpeta | `.gitlab/issue_templates/` exacta. `.gitlab/issue-templates/` no se lee |
| Extensión | `.md`. El nombre del archivo sin extensión es el nombre de la plantilla |
| Rama | **La rama por defecto**. Una plantilla en una rama de trabajo no aparece hasta que se fusiona |

Que vivan en el repositorio tiene las ventajas de siempre: se revisan en un merge request, tienen historial, y viajan con el proyecto si se exporta.

> [!NOTE]
> Las plantillas de merge request siguen las mismas reglas en `.gitlab/merge_request_templates/`. Las verás en la Semana 06.

### 2.2 La plantilla `Default`

Si existe una plantilla llamada `Default` (sin distinguir mayúsculas: `Default.md`, `default.md`), GitLab **la preselecciona** al abrir el formulario de issue nuevo. Quien no elige otra, escribe sobre ella.

Comprobado en el código de la instancia: el helper `default_template_name` busca entre las plantillas la primera cuyo nombre sea `default` comparando sin mayúsculas. Es Free.

Lo que **no** es Free es la otra forma de tener una plantilla por defecto: el ajuste del proyecto *Default description template for issues*, que guarda el texto en la configuración y no en el repositorio. Es Premium. Con `Default.md` no hace falta.

### 2.3 Niveles de plantilla

| Nivel | Dónde se definen | Tier |
|---|---|---|
| **Proyecto** | `.gitlab/issue_templates/` del propio proyecto | Free |
| **Grupo** | Un proyecto del grupo elegido como repositorio de plantillas | Premium |
| **Instancia** | Un proyecto elegido en el Admin Area | Premium |

En CE, cada proyecto tiene sus plantillas. Si `infra` necesita las mismas que `app`, se copian. Es un coste pequeño mientras sean dos proyectos; en la Semana 17, un script de `ci/automatizacion` puede sincronizarlas por API.

---

## 3. Qué va dentro

### 3.1 Estructura

Una plantilla tiene tres partes: **las preguntas**, **los criterios de aceptación** y **las acciones rápidas** al final.

```markdown
<!-- Título: describe el comportamiento observable, no la solución. -->

## Qué pasa

<!-- Qué hiciste, qué esperabas y qué obtuviste. -->

## Cómo reproducirlo

1.
2.

## Qué debería pasar

## Versión

<!-- Salida de `git describe --tags` o el commit, si lo sabes. -->

## Criterios de aceptación

- [ ] El caso de "Cómo reproducirlo" da el resultado de "Qué debería pasar"
- [ ] Hay un test que falla sin el arreglo y pasa con él

/label ~"tipo::bug" ~"estado::preparado"
```

Los comentarios HTML `<!-- -->` son instrucciones para quien escribe: se ven al editar y **no se ven** en el issue publicado. Es la forma de guiar sin ensuciar el resultado.

### 3.2 Acciones rápidas dentro de la plantilla

Las líneas que empiezan por `/` al principio de línea se **ejecutan al crear el issue** y desaparecen de la descripción. Es la misma mecánica que en un comentario (teoría [07](07-acciones-rapidas-y-cierre-automatico.md)).

| En la plantilla | Efecto al crear |
|---|---|
| `/label ~"tipo::bug"` | El issue nace con esa etiqueta |
| `/label ~"estado::preparado"` | Entra directamente en la primera columna del tablero |
| `/milestone %"v0.1.0"` | Lo planifica. Úsalo con cuidado: no todo bug va al hito actual |
| `/confidential` | Útil en una plantilla `Seguridad` |
| `/assign @usuario` | Casi nunca en una plantilla: el asignado se decide en el triaje |

> [!WARNING]
> Una acción rápida en la plantilla `Default` se aplica a **todos** los issues que no eligen otra plantilla. Si `Default.md` lleva `/label ~"tipo::bug"`, cada feature que alguien abra con prisa nacerá como bug. La plantilla por defecto debería llevar como mucho `estado::preparado`, nunca un `tipo::`.

Y una advertencia de mantenimiento: si renombras una etiqueta, las plantillas que la usan **no se actualizan**, porque son texto. La acción rápida con un nombre que ya no existe se ignora en silencio y el issue nace sin etiqueta.

### 3.3 Cuántas plantillas

Una por cada `tipo::` que tenga preguntas distintas. Normalmente:

| Plantilla | Preguntas que la distinguen |
|---|---|
| `Bug` | Qué pasa, cómo reproducirlo, qué debería pasar, versión |
| `Feature` | Qué problema de quién resuelve, cómo se sabrá que funciona |
| `Default` | Las mínimas, para lo que no encaja en las otras |

`tipo::docs` y `tipo::mantenimiento` suelen apañarse con `Default`. Si un tipo nunca usa su plantilla, sobra.

---

## 4. Cómo se configura

Las plantillas son archivos: se crean con un commit, como cualquier otro.

```bash
mkdir -p .gitlab/issue_templates
$EDITOR .gitlab/issue_templates/Bug.md
git add .gitlab/issue_templates
git commit -S -m "docs: add bug and feature issue templates"
git push
```

Y se comprueban por API, que es lo que lee el formulario:

```bash
source ~/.bc-gitlab
H="PRIVATE-TOKEN: $GITLAB_TOKEN"; API="$GITLAB_URL/api/v4"
P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)

curl -s -H "$H" "$API/projects/$P/templates/issues" | jq -r '.[].key'
# Bug
# Default
# Feature
```

El contenido de una concreta:

```bash
curl -s -H "$H" "$API/projects/$P/templates/issues/Bug" | jq -r '.content' | head -5
```

Si el listado sale vacío, la plantilla no está en la rama por defecto, o la carpeta está mal escrita.

---

## 5. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Plantilla de cuarenta líneas | Se borra entera y se escribe encima | Cuatro o cinco preguntas, las que de verdad se usan |
| `tipo::` en la plantilla `Default` | Todo lo que no elige plantilla nace mal clasificado | `Default` sin `tipo::`; el triaje lo pone |
| Instrucciones en texto normal | Quedan en el issue publicado | Comentarios `<!-- -->` |
| Plantillas en una rama sin fusionar | No aparecen y parece que no funcionan | Siempre en la rama por defecto |
| Etiqueta renombrada sin tocar las plantillas | Los issues nacen sin etiqueta, sin aviso | Buscar el nombre viejo en `.gitlab/` al renombrar |
| Una plantilla por persona | No es una plantilla, es una preferencia | Plantillas por tipo de trabajo |

---

## 6. Trucos

- **Enlace a un issue nuevo con plantilla**: `.../-/issues/new?issuable_template=Bug`. Ponlo en el `CONTRIBUTING.md` de la Semana 04, en la sección "cómo informar de un fallo".
- **Comprobar las plantillas sin abrir el formulario**: `GET /projects/:id/templates/issues`. Es lo primero que se mira cuando "la plantilla no sale".
- **Buscar etiquetas huérfanas en las plantillas**: `grep -ho '~"[^"]*"' .gitlab/issue_templates/*.md | sort -u` y compáralo con `GET /groups/:id/labels`.

---

## 📚 Recursos Adicionales

- [Plantillas de descripción](https://docs.gitlab.com/ee/user/project/description_templates.html) — carpetas, plantilla por defecto, y los niveles Premium marcados
- [API de plantillas de proyecto](https://docs.gitlab.com/ee/api/project_templates.html) — `issues` y `merge_requests`
- [Acciones rápidas](https://docs.gitlab.com/ee/user/project/quick_actions.html) — todas las que se pueden usar dentro de una plantilla

---

## ✅ Checklist de Verificación

- [ ] Tus plantillas están en `.gitlab/issue_templates/` de la rama por defecto
- [ ] `Default.md` se preselecciona al abrir un issue nuevo
- [ ] `Default.md` no lleva ninguna etiqueta `tipo::`
- [ ] Un issue creado con la plantilla `Bug` nace con `tipo::bug`
- [ ] Has listado tus plantillas por API

---

[← Anterior: Tableros](05-tableros.md) · [Volver a la Semana 05](../README.md) · [Siguiente: Acciones rápidas y cierre automático →](07-acciones-rapidas-y-cierre-automatico.md)

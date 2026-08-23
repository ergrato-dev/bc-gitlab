# Decisiones como ADR

> El código dice **qué** se hizo. El ADR dice **por qué**, y es lo único que no se puede deducir leyendo el repositorio.

## 🎯 Objetivos

- Distinguir una decisión que merece un ADR de una que no
- Escribir un ADR con la plantilla mínima y en menos de veinte minutos
- Manejar el ciclo de vida: propuesta, aceptada, sustituida
- Explicar por qué un ADR no se corrige y por qué no vive en el README

---

## 1. Qué problema resuelve

Llegas a un proyecto y ves que la aplicación guarda las fechas como cadenas de texto y no como fechas. Tienes dos hipótesis:

1. Alguien no sabía hacerlo mejor
2. Hubo una razón: una API externa devolvía fechas sin zona horaria y convertirlas rompía el histórico

Sin ADR, resolver esa duda cuesta o bien preguntar a alguien que quizá ya no está, o bien "arreglarlo" y descubrir el motivo por la vía cara. Con ADR, cuesta treinta segundos.

Ese es todo el problema: **el contexto de una decisión se evapora y el código no lo conserva**. Un comentario en el código se borra en el primer refactor. Un mensaje de commit se pierde entre otros cuatro mil. Un hilo de chat no es indexable. El ADR es un archivo con nombre estable, fecha y estado.

> [!NOTE]
> El formato lo popularizó Michael Nygard en 2011 con un artículo de dos páginas. Que haya sobrevivido quince años sin herramientas ni certificaciones dice bastante: es un archivo de texto con cinco encabezados.

---

## 2. Cómo funciona

### 2.1 Qué merece un ADR

El criterio es **el coste de revertir**, no la importancia:

| Decisión | ¿ADR? | Por qué |
|---|:--:|---|
| PostgreSQL en vez de SQLite | ✅ | Cambiar después implica migrar datos y reescribir consultas |
| TypeScript en vez de JavaScript | ✅ | Afecta a todo el código y al pipeline |
| Trunk-based en vez de Git Flow | ✅ | Afecta a cómo trabaja todo el mundo, todos los días |
| Guardar el estado de Terraform en GitLab | ✅ | Migrarlo después es un procedimiento con riesgo |
| Poner el botón a la izquierda | ❌ | Se revierte en un commit |
| Usar `const` en vez de `let` | ❌ | Es estilo, y eso es el linter |
| Actualizar una dependencia menor | ❌ | Rutina; si rompe, se revierte |

La prueba: **si dentro de un año alguien pudiera querer cambiarlo y no supiera por qué está así, hay ADR**.

En el bootcamp aparecen unas quince decisiones de ese calibre en veintiséis semanas. Un ADR por semana es demasiado; uno cada dos o tres, lo normal.

### 2.2 La plantilla mínima

Cinco secciones. Ni una más:

```markdown
# ADR-001: Dominio y stack de la plataforma

- **Estado**: Aceptada
- **Fecha**: 2026-08-24
- **Decide**: <tu nombre>

## Contexto

Qué situación obliga a decidir. Hechos y restricciones, sin opinión.
Aquí van las cosas que dentro de un año nadie recordará: la instancia
es de 16 GB, el equipo es de una persona, no hay presupuesto de licencias.

## Decisión

Qué se decide, en una frase en presente y en voz activa.
"Usamos TypeScript con el runner de tests nativo de Node."

## Alternativas consideradas

| Alternativa | Por qué no |
|---|---|
| ... | ... |

## Consecuencias

Lo que esta decisión hace más fácil y lo que hace más difícil.
Las dos columnas. Un ADR sin consecuencias negativas no se ha pensado.
```

Las dos secciones que la gente se salta son las dos que dan valor: **alternativas** y **consecuencias negativas**. Sin ellas el ADR es un anuncio, y un anuncio no ayuda a nadie a decidir dentro de un año.

> [!TIP]
> Escribe el **contexto** como si el lector no supiera nada del proyecto ni del año en que estamos. Es literalmente el caso: el lector eres tú, en 2028.

### 2.3 El ciclo de vida

Un ADR tiene estado, y solo tres:

| Estado | Qué significa |
|---|---|
| **Propuesta** | Escrita, aún en discusión. Puede cambiar |
| **Aceptada** | Vigente. Es lo que se hace |
| **Sustituida por ADR-NNN** | Ya no se hace así. **El texto no se toca** |

La regla que más cuesta interiorizar: **un ADR aceptado no se edita nunca**. Si la decisión cambia, se escribe un ADR nuevo que sustituye al anterior, y en el anterior se cambia una sola cosa: el estado, con el enlace al que lo sustituye.

Parece burocracia y no lo es. Un ADR editado pierde justo lo que lo hacía útil: la foto de lo que se sabía **entonces**. La cadena `ADR-003 → ADR-011 → ADR-019` cuenta la evolución del criterio del equipo, que es información que no está en ningún otro sitio.

```markdown
# ADR-003: Ramas de larga vida por entorno

- **Estado**: Sustituida por [ADR-011](ADR-011-gitlab-flow)
- **Fecha**: 2026-09-14
```

### 2.4 Por qué en la wiki y no en el repositorio

Los dos sitios son defendibles y hay proyectos serios que usan `docs/adr/` dentro del repositorio. En este bootcamp van a la wiki, por tres razones concretas:

1. **No envejecen con el código.** Un ADR de marzo sigue siendo verdad en diciembre aunque el código haya cambiado entero. Ponerlo junto al código invita a "actualizarlo", que es exactamente lo que no hay que hacer.
2. **No necesitan revisión.** Un ADR no es una propuesta de cambio de código: es un registro. Meterlo en un merge request añade un ciclo de aprobación a algo que ya se decidió.
3. **Se leen sin clonar.** Quien busca "por qué esto es así" suele no tener el repositorio delante.

La contrapartida honesta: en la wiki **no se revisan en un merge request**, y para un equipo que quiere discutir la decisión antes de aceptarla, `docs/adr/` con un merge request es mejor herramienta. Si tu equipo trabaja así, muévelos: la decisión de dónde viven los ADR es, ella misma, un ADR.

### 2.5 Numeración y nombres

- **Números correlativos y sin reutilizar.** `ADR-001`, `ADR-002`. Si uno se descarta, su número muere con él.
- **Tres dígitos** desde el principio: `ADR-007` ordena bien junto a `ADR-011`; `ADR-7` no.
- **Título en el nombre de la página**: `ADR-001-dominio-y-stack`. El número solo no dice nada en una lista.
- **Enlazados desde la portada de la wiki**, en una tabla con estado y fecha. Es lo primero que se mira.

---

## 3. Cómo se configura

No hay nada que configurar: son páginas de wiki. Lo que hay es una rutina, y cabe en cuatro pasos:

1. Antes de tomar la decisión, escribe **contexto** y **alternativas**. Escribirlas cambia decisiones más veces de lo que parece.
2. Publica el ADR en estado **Propuesta**.
3. Cuando se aplique, cámbialo a **Aceptada** y enlázalo desde la portada de la wiki.
4. Cuando deje de valer, ADR nuevo, y en el viejo solo el estado.

Crear el primero por API, para tenerlo hecho hoy:

```bash
source ~/.bc-gitlab
H="PRIVATE-TOKEN: $GITLAB_TOKEN"; API="$GITLAB_URL/api/v4"
P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)

curl -s --request POST "$API/projects/$P/wikis" -H "$H" \
  --data-urlencode "title=ADR-001-dominio-y-stack" \
  --data-urlencode "content=$(cat adr-001.md)" \
  | jq '{slug, title}'
```

> [!IMPORTANT]
> El slug conserva las mayúsculas del título: `ADR-001-dominio-y-stack` produce el slug `ADR-001-dominio-y-stack`, no `adr-001-...`. Si escribes enlaces a mano, respétalas.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Editar un ADR aceptado | Se pierde la foto de lo que se sabía entonces, que es todo su valor | ADR nuevo, y en el viejo solo el estado |
| ADR sin consecuencias negativas | Es un anuncio, no una decisión: nadie decide sin renunciar a algo | Las dos columnas, siempre |
| ADR para cada cambio | Deja de leerse y se convierte en un diario | Solo lo caro de revertir |
| Escribirlo tres meses después | El contexto ya se ha reconstruido de memoria, y la memoria adorna | En el momento, aunque salga corto |
| Números reutilizados o de un dígito | Los enlaces apuntan a decisiones distintas según el día | Correlativos, tres dígitos, nunca reciclados |
| "Se decidió que" en pasiva | No se sabe quién decide ni a quién preguntar | Voz activa y un nombre en la cabecera |
| ADR que documenta el cómo, no el porqué | Eso es documentación técnica, y envejece | Contexto, alternativas y consecuencias |
| Cadena de sustituciones sin enlazar | Se lee una decisión derogada creyendo que está vigente | Estado con enlace, en las dos direcciones |

---

## 5. Trucos

- **El ADR-001 siempre es el mismo**: por qué este stack y este dominio. Se escribe en veinte minutos y es el que más se lee.
- **Tabla de ADR en la portada de la wiki**, con número, título, estado y fecha. Cuatro columnas y se ve el criterio del proyecto de un vistazo.
- **Buscar decisiones sobre un tema** sin abrir la interfaz: `GET /projects/:id/wikis?with_content=true | jq -r '.[] | select(.slug | startswith("ADR")) | select(.content | test("postgres";"i")) | .slug'`.
- **Listar solo los ADR**: `GET /projects/:id/wikis | jq -r '.[].slug | select(startswith("ADR"))'`.
- **Un ADR también sirve para decir que no**: "consideramos Kubernetes y decidimos no usarlo" ahorra la misma discusión cada seis meses.
- **La plantilla MADR** ([adr.github.io](https://adr.github.io/madr/)) es la versión larga, con más secciones. Empieza por la corta: la larga se abandona antes.

---

## 📚 Recursos Adicionales

- [Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) — el artículo original de Michael Nygard, dos páginas
- [MADR](https://adr.github.io/madr/) — la plantilla más usada, con su justificación
- [ADR GitHub organization](https://adr.github.io/) — herramientas y ejemplos de proyectos reales
- [Wiki de proyecto](https://docs.gitlab.com/ee/user/project/wiki/) — dónde van a vivir en este bootcamp

---

## ✅ Checklist de Verificación

- [ ] Puedes decidir en diez segundos si algo merece un ADR
- [ ] Tu ADR-001 tiene contexto, decisión, alternativas y consecuencias en las dos direcciones
- [ ] Sabes qué se cambia en un ADR cuando la decisión deja de valer, y qué no
- [ ] La portada de tu wiki lista los ADR con su estado

---

[← Anterior: La wiki del proyecto](04-la-wiki-del-proyecto.md) · [Volver a la Semana 04](../README.md) · [Siguiente: Snippets →](06-snippets.md)

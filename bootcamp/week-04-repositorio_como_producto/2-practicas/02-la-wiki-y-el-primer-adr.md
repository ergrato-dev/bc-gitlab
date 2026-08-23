# Práctica 02 — La wiki y el primer ADR

> Una portada que es un índice, dos decisiones registradas, un runbook y una barra lateral. Y la wiki clonada en tu máquina, que es como se trabaja de verdad.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 01 completada · Teorías [04](../1-teoria/04-la-wiki-del-proyecto.md) y [05](../1-teoria/05-decisiones-como-adr.md) leídas

---

## Contexto

Hasta ahora todo lo que sabe tu plataforma está en el código o en tu cabeza. Por qué elegiste ese dominio, por qué TypeScript, por qué `app` no se movió a un subgrupo en la Semana 03: nada de eso se deduce leyendo el repositorio, y dentro de seis meses tú tampoco lo recordarás con precisión.

Esta práctica monta la wiki del proyecto y escribe las primeras decisiones. Es la documentación que **no envejece con el código**: no se revisa en un merge request, no dispara pipelines, y vive en un repositorio Git propio que vas a clonar.

Al final la wiki tiene cinco páginas y una estructura que aguanta las veintidós semanas que quedan.

---

## Paso 0: Preparar el terreno

**Por qué**: las mismas variables de la práctica 01, más el directorio donde vas a clonar la wiki.

```bash
source ~/.bc-gitlab

export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
export WIKI_URL="$GITLAB_URL/$PROYECTO.wiki.git"

echo "wiki: $WIKI_URL"
```

**Verifica**: la URL termina en `.wiki.git` y lleva la ruta completa de tu proyecto.

---

## Paso 1: Comprobar el estado de la wiki

**Por qué**: la wiki viene activada por defecto, pero su nivel de acceso se decide igual que el del repositorio. En un proyecto privado, `private` significa "solo los miembros"; `enabled` la hace tan visible como el proyecto.

```bash
curl -s -H "$H" "$API/projects/$P" | jq '{wiki_access_level, snippets_access_level}'

# Y lo que hay dentro, que ahora mismo es nada
curl -s -H "$H" "$API/projects/$P/wikis" | jq 'length'
# 0
```

**Verifica**: `wiki_access_level` no es `disabled` y la lista de páginas está vacía. Si estuviera desactivada:

```bash
curl -s --request PUT "$API/projects/$P" -H "$H" \
  --data-urlencode "wiki_access_level=private" | jq -r '.wiki_access_level'
```

> [!NOTE]
> El repositorio de la wiki **no existe hasta que se crea la primera página**. Por eso el paso 2 va por API y el clon viene después: intentar clonar ahora daría un repositorio vacío.

---

## Paso 2: La portada, que es un índice

**Por qué**: la portada de la wiki tiene un nombre fijado en el código de GitLab, `home`. Si la creas con otro título, no es la portada: es una página más, y la wiki abre en la lista alfabética de todo.

**Con la interfaz**: `Proyecto → Plan → Wiki → Create your first page`. El formulario ya propone el título `home`.

**Con la API**:

```bash
curl -s --request POST "$API/projects/$P/wikis" -H "$H" \
  --data-urlencode "title=home" \
  --data-urlencode "format=markdown" \
  --data-urlencode "content=# Documentacion de la plataforma

Lo que no envejece con el codigo. Lo que si, esta en el repositorio.

## Decisiones (ADR)

| ADR | Titulo | Estado | Fecha |
|---|---|---|---|
| 001 | Dominio y stack | Aceptada | 2026-08-24 |

## Runbooks

| Runbook | Cuando se usa |
|---|---|
| Recuperar el acceso de administracion | Cuando nadie puede entrar como root |
" \
  | jq '{slug, title, format}'
```

```json
{ "slug": "home", "title": "home", "format": "markdown" }
```

**Verifica**: el slug es exactamente `home`, en minúscula.

```bash
curl -s -H "$H" "$API/projects/$P/wikis" | jq -r '.[].slug'
# home
```

> [!IMPORTANT]
> GitLab muestra esta página como "Home" con mayúscula, pero el archivo es `home.md` y el slug es `home`. Crearla con el título `Home` produce una página distinta con slug `Home`, y la wiki se queda sin portada.

---

## Paso 3: Clonar la wiki

**Por qué**: escribir cinco páginas por formulario web es lento y no se puede revisar. Como es un repositorio Git, se clona, se escribe en tu editor y se empuja de una vez.

```bash
cd /ruta/donde/trabajas
git clone "$WIKI_URL" wiki-app
cd wiki-app
ls
# home.md
```

**Verifica**: el clon trae `home.md` y `git log` muestra el commit que creó la página por API.

```bash
git log --oneline
# a1b2c3d Create home
```

> [!TIP]
> Esta es la razón de fondo por la que las decisiones van a la wiki y no a un Google Doc: **tienen historia**. `git log --oneline -- ADR-001-dominio-y-stack.md` responde "quién cambió esta decisión y cuándo" en un segundo.

---

## Paso 4: ADR-001, el que siempre existe

**Por qué**: la primera decisión de cualquier proyecto es la misma —qué dominio y qué stack— y es la que más se lee, porque explica todo lo demás. Escríbela hoy, que aún recuerdas por qué.

Crea `ADR-001-dominio-y-stack.md` en el clon de la wiki. Adapta el contenido a tus decisiones reales:

```markdown
# ADR-001: Dominio y stack de la plataforma

- **Estado**: Aceptada
- **Fecha**: 2026-08-24
- **Decide**: Tu Nombre

## Contexto

La plataforma se construye durante 26 semanas sobre una instancia GitLab CE
autohospedada, en una maquina de 16 GB, con una sola persona trabajando y sin
presupuesto para licencias de pago. El codigo existe para que CI, el registry,
los escaneres y los despliegues tengan algo que morder: no es el objetivo.

## Decision

El dominio es la gestion de una biblioteca. El codigo es una libreria en
TypeScript con tests en el runner nativo de Node.

## Alternativas consideradas

| Alternativa | Por que no |
|---|---|
| Un servicio web completo | Mas superficie que mantener, sin aportar nada a la plataforma |
| Python con pytest | Igual de valido; TypeScript se eligio por el `package.json` publicable |
| Sin codigo, solo configuracion | Sin nada que construir, la mitad del bootcamp no tiene sujeto |

## Consecuencias

**Facilita**: publicar un paquete npm (S13), imagen pequena, tests rapidos,
escaneres con soporte de sobra.

**Dificulta**: el ecosistema de Node arrastra muchas dependencias, y eso hara
mas ruidoso el escaneo de dependencias de la Semana 19.
```

**Verifica**: el archivo tiene las cinco secciones, y las consecuencias tienen las dos caras. Un ADR sin consecuencias negativas no se ha pensado.

---

## Paso 5: ADR-002 y un runbook

**Por qué**: un ADR solo no enseña el formato ni el ciclo de vida. El segundo registra una decisión que ya tomaste en la Semana 03 y que hoy parece obvia, pero no lo era.

`ADR-002-app-no-se-mueve-a-un-subgrupo.md`:

```markdown
# ADR-002: `app` cuelga del grupo raiz, no de un subgrupo

- **Estado**: Aceptada
- **Fecha**: 2026-08-24
- **Decide**: Tu Nombre

## Contexto

La Semana 03 creo los subgrupos `infra` y `ci`. La simetria invitaba a crear
tambien un subgrupo `app` y mover el proyecto dentro.

## Decision

`app` se queda colgando del grupo raiz.

## Alternativas consideradas

| Alternativa | Por que no |
|---|---|
| Mover `app` a un subgrupo `app/` | Cambia la ruta, y la ruta es parte de la identidad del proyecto |

## Consecuencias

**Facilita**: la ruta de `app` no cambia, y con ella no cambian los remotos de
Git, la configuracion del autograding ni las rutas de las imagenes que la
Semana 13 publicara en el registry.

**Dificulta**: el arbol no es simetrico, y hay que explicarlo. Este ADR es la
explicacion.
```

Y un runbook, que es el otro tipo de contenido que vive en la wiki. `Runbook-recuperar-acceso-de-administracion.md`:

```markdown
# Runbook: recuperar el acceso de administracion

- **Ultima revision**: 2026-08-24

## Cuando se usa

Nadie puede entrar como administrador de la instancia: contrasena perdida,
cuenta bloqueada o token revocado.

## Pasos

1. Comprobar que el contenedor esta vivo y sano:
   `docker compose ps` y `docker compose logs -f gitlab | tail -20`
2. Abrir una consola de Rails dentro del contenedor:
   `docker compose exec gitlab gitlab-rails console`
3. Localizar la cuenta y cambiar la contrasena desde la consola.
4. Salir y entrar por la interfaz para confirmar.

## Si no funciona

Restaurar desde el ultimo backup. El procedimiento completo esta en la
Semana 22; hasta entonces, el backup es la copia del volumen de datos.
```

**Verifica**: los tres archivos están en el clon.

```bash
ls *.md
# ADR-001-dominio-y-stack.md
# ADR-002-app-no-se-mueve-a-un-subgrupo.md
# Runbook-recuperar-acceso-de-administracion.md
# home.md
```

---

## Paso 6: La barra lateral

**Por qué**: sin barra lateral, GitLab muestra la lista de páginas ordenada alfabéticamente. Con cinco páginas se aguanta; con veinte, ya no se encuentra nada. `_sidebar` es el nombre que GitLab busca, y también está fijado en el código.

Crea `_sidebar.md`:

```markdown
### Plataforma

- [Portada](home)

### Decisiones

- [ADR-001 Dominio y stack](ADR-001-dominio-y-stack)
- [ADR-002 app no se mueve](ADR-002-app-no-se-mueve-a-un-subgrupo)

### Runbooks

- [Recuperar acceso de administracion](Runbook-recuperar-acceso-de-administracion)
```

**Verifica**: los enlaces usan el **slug**, que conserva las mayúsculas del título del archivo. `ADR-001-dominio-y-stack` funciona; `adr-001-dominio-y-stack` da un 404.

---

## Paso 7: Empujar la wiki

**Por qué**: las cinco páginas son un solo cambio y entran juntas. La wiki no pasa por merge requests: lo que empujas, se publica.

```bash
git add .
git commit -m "docs(wiki): add ADR-001, ADR-002, runbook and sidebar"
git push origin $(git branch --show-current)
```

**Verifica**: la API ya ve las páginas nuevas.

```bash
curl -s -H "$H" "$API/projects/$P/wikis" | jq -r '.[] | "\(.slug)\t\(.title)"'
```

```
home	home
ADR-001-dominio-y-stack	ADR-001-dominio-y-stack
ADR-002-app-no-se-mueve-a-un-subgrupo	ADR-002-app-no-se-mueve-a-un-subgrupo
Runbook-recuperar-acceso-de-administracion	Runbook-recuperar-acceso-de-administracion
_sidebar	_sidebar
```

Y ábrela en el navegador: la barra lateral tiene que aparecer a la derecha, con tus tres secciones.

---

## Paso 8: Practicar la sustitución de un ADR

**Por qué**: la regla que más cuesta interiorizar es que **un ADR aceptado no se edita**. Practicarla una vez con un caso inventado hace que la siguiente, la de verdad, salga sola.

Supón que dentro de tres meses decides mover `app` a un subgrupo. No se toca el ADR-002: se escribe el ADR-003 y en el 002 se cambia **solo el estado**.

```bash
# Solo la cabecera del ADR-002, nada del cuerpo
sed -i 's/^- \*\*Estado\*\*: Aceptada/- **Estado**: Sustituida por ADR-003 (ejemplo del ejercicio, no aplicada)/' \
  ADR-002-app-no-se-mueve-a-un-subgrupo.md
head -5 ADR-002-app-no-se-mueve-a-un-subgrupo.md
```

**Verifica**: el contexto, la decisión y las consecuencias del ADR-002 están **intactos**. Lo único distinto es la línea de estado.

Ahora deshaz el ejercicio, porque el ADR-002 sigue vigente:

```bash
git checkout ADR-002-app-no-se-mueve-a-un-subgrupo.md
git status --short
# (sin cambios)
```

> [!TIP]
> Que esto se pueda deshacer con un `git checkout` es exactamente la ventaja de que la wiki sea un repositorio Git. En un formulario web, ese ensayo habría sido irreversible.

---

## ✅ Resultado

- [ ] La wiki tiene portada con slug `home`, y es un índice, no un saludo
- [ ] La portada lista los ADR con su estado y su fecha
- [ ] `ADR-001-dominio-y-stack` existe, con contexto, decisión, alternativas y consecuencias en las dos direcciones
- [ ] `ADR-002` registra una decisión que hoy parece obvia y no lo era
- [ ] Hay al menos un runbook, con fecha de última revisión
- [ ] `_sidebar` existe y sus enlaces respetan las mayúsculas del slug
- [ ] La wiki está clonada en tu máquina y sabes empujar cambios
- [ ] Sabes qué se cambia de un ADR sustituido, y qué no

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 04
```

Esta práctica cubre tres comprobaciones: portada, ADR-001 y el mínimo de cuatro páginas.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `git clone` de la wiki devuelve un repositorio vacío | Todavía no hay ninguna página: el repositorio no existe | Crea `home` por API o por la interfaz, y vuelve a clonar |
| La comprobación `wiki-con-portada` falla | La portada se creó con el título `Home` | Renombra la página a `home`, en minúscula |
| La comprobación `wiki-con-adr-001` falla | El título no empieza por `ADR-001` | Renombra el archivo a `ADR-001-...md` y empuja |
| Los enlaces de `_sidebar` dan 404 | El slug conserva mayúsculas y el enlace las perdió | Copia el slug tal cual sale de `GET /wikis` |
| La barra lateral no aparece | El archivo no se llama exactamente `_sidebar.md` | Renómbralo; el nombre está fijado en GitLab |
| `POST /wikis` devuelve 400 | Falta `title` o `content`: los dos son obligatorios | Envía los dos, aunque el contenido sea provisional |
| El contenido con saltos de línea llega en una sola línea | Se envió sin `--data-urlencode` | Usa `--data-urlencode`, que codifica los saltos |
| `wiki_size` sigue a cero | Las estadísticas se recalculan en segundo plano | Espera unos segundos; para el autograding se cuenta el número de páginas, no el tamaño |
| El `push` a la wiki es rechazado | El token o el usuario no tienen rol suficiente en el proyecto | La wiki hereda los permisos del proyecto: hace falta Developer o superior |
| Una página borrada por error | El `DELETE` de wiki es inmediato, sin papelera | El clon conserva la historia: `git checkout <sha> -- <archivo>` y empuja |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Práctica 01 — La portada del proyecto](01-la-portada-del-proyecto.md) | **Práctica 02** | [Práctica 03 — Snippets e insignias](03-snippets-e-insignias.md) |

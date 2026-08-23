# 📖 Glosario — Semana 04

Términos que aparecen esta semana. El nombre real de la feature va en inglés entre paréntesis, y el **tier** cuando aplica.

El glosario acumulado de toda la plataforma está en [glosario-global](../../../docs/glosario-global.md).

---

## A

**ADR** (*Architecture Decision Record*) — Registro de una decisión de arquitectura, con contexto, alternativas y consecuencias, fechado y con estado. No se edita cuando la decisión cambia: se escribe otro que lo sustituye.

**Alerta de Markdown** (*alert*) — Free. Bloque destacado que se escribe como una cita con `> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]` o `> [!CAUTION]`. Cinco tipos, sin HTML.

**Avatar de proyecto** (*project avatar*) — Free. La imagen del proyecto. GitLab la toma de un archivo `logo.png`, `logo.jpg` o `logo.gif` en la raíz del repositorio si existe; si no, del archivo subido por la interfaz.

## B

**Barra lateral de la wiki** (*wiki sidebar*, `_sidebar`) — Free. Página con nombre fijo que sustituye la lista automática de páginas. Sin ella, la wiki se ordena alfabéticamente.

## C

**`CONTRIBUTING.md`** — Free. Archivo de la raíz que GitLab reconoce por nombre y enlaza como guía de contribución.

**Coste de arranque** — El tiempo entre clonar un repositorio y hacer algo útil con él. Se paga una vez por persona; documentar bien lo paga una vez por proyecto.

## F

**Filtro `clean`** — El filtro de Git LFS que actúa al hacer `git add`: sube el binario al almacén y guarda el puntero en la historia.

**Filtro `smudge`** — El complementario: al hacer `checkout`, lee el puntero, descarga el binario y lo deja en el disco.

## G

**`.gitattributes`** — Archivo versionado en la raíz que declara atributos por patrón de ruta. En esta semana, qué archivos rastrea Git LFS; también sirve para el cálculo de lenguajes del proyecto y para el tratamiento de saltos de línea.

**GLFM** (*GitLab Flavored Markdown*) — Free. El Markdown de GitLab, con extensiones propias: `[[_TOC_]]`, alertas, referencias a issues y merge requests, y diagramas Mermaid nativos.

## I

**Insignia** (*badge*) — Free. Par de URLs —imagen y enlace— que se muestra encima del árbol de archivos del proyecto. Vive en la base de datos, no en el repositorio.

**Insignia de grupo** (*group badge*) — Free. Insignia definida en un grupo y heredada por todos sus proyectos y subgrupos. En `GET /projects/:id/badges` aparece con `kind: group`.

## L

**LFS** (*Git Large File Storage*) — Free. Extensión de Git que guarda los binarios grandes en un almacén aparte y deja en la historia un puntero de texto.

**Licencia detectada** (*detected license*) — Free. La licencia que GitLab identifica comparando el archivo `LICENSE` con un catálogo, mediante la librería Licensee. Se expone en `license` y `license_url`, **solo** si se pide `?license=true`.

**Licensee** — La librería que hace esa comparación. Exige el texto íntegro y sin retocar: un `LICENSE` que dice solo "MIT" no se detecta.

## M

**Marcador de insignia** (*badge placeholder*) — Free. Variable que GitLab sustituye al renderizar una insignia: `%{project_path}`, `%{project_id}`, `%{default_branch}`, `%{commit_sha}`, `%{latest_tag}`, `%{gitlab_server}`, entre otras.

**Mermaid** — Free. Sintaxis de diagramas que GitLab renderiza de forma nativa en un bloque ```` ```mermaid ````. A diferencia de PlantUML y Kroki, no necesita ningún servidor configurado.

## P

**Portada de la wiki** (*wiki home page*, `home`) — Free. Página con nombre fijo que se abre al entrar en la wiki. Se crea con el título literal `home`, en minúscula.

**Puntero de LFS** (*LFS pointer*) — Archivo de texto de unos 130 bytes que sustituye al binario en la historia de Git. Tres líneas: `version`, `oid sha256:` y `size`.

## R

**`readme_url`** — Free. Campo de la API que apunta al README reconocido. Es `null` cuando GitLab no ha encontrado ninguno en la raíz.

**Runbook** — Procedimiento operativo que se lee con prisa: qué hacer cuando algo falla. Vive en la wiki porque tiene que poder corregirse sin un ciclo de revisión.

## S

**SPDX** — El estándar de identificadores de licencia: `MIT`, `Apache-2.0`, `GPL-3.0`. Es lo que devuelve `license.key` en minúsculas, y lo que se declara en el `package.json` y en el SBOM.

**Snippet** — Free. Repositorio Git diminuto con una URL estable, para fragmentos que no pertenecen a ningún archivo. Los hay personales y de proyecto, y admiten varios archivos.

## T

**Tema de proyecto** (*topic*) — Free. Etiqueta del proyecto entero, no de sus issues. Sirve para buscar proyectos por tecnología o dominio dentro de la instancia.

**`[[_TOC_]]`** — Free. Marca que genera un índice a partir de los encabezados del documento. Funciona en el README y en las páginas de la wiki. También se acepta `[TOC]`.

## W

**Wiki de proyecto** (*project wiki*) — Free. Repositorio Git independiente, en `<proyecto>.wiki.git`, con permisos heredados del proyecto. No pasa por merge requests y no dispara pipelines.

**Wiki de grupo** (*group wiki*) — **Premium**. Wiki compartida por todos los proyectos de un grupo. En CE no existe: la API de wikis solo expone el recurso `projects`. Sustituto en este bootcamp: la wiki de `app` hace de wiki de la plataforma.

---

[← Volver a la Semana 04](../README.md)

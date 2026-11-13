# Semana 04 — El repositorio como producto

> Un repositorio que solo entiende quien lo escribió es un repositorio con un único
> mantenedor. Esta semana conviertes `app` en algo que un tercero clona, entiende y arranca sin preguntarte.

---

## 🎯 Objetivos de la Semana

Al terminar serás capaz de:

- Enumerar los archivos que GitLab reconoce **por nombre** y decir qué cambia en la interfaz cuando cada uno existe
- Escribir un README que se lee en cinco minutos, con índice automático, alertas y un diagrama que se renderiza solo
- Elegir una licencia con criterio, aplicarla desde la plantilla de tu instancia y comprobar que GitLab la detecta
- Decidir qué documentación va en `docs/` del repositorio y cuál va en la wiki, con una regla que no sea "depende"
- Clonar la wiki como el repositorio Git que es, y escribirla desde tu editor en vez de desde el navegador
- Registrar una decisión de arquitectura como ADR y explicar por qué una decisión no se documenta en el README
- Publicar un snippet de proyecto con varios archivos y decir cuándo un snippet es la herramienta correcta y cuándo es un repositorio que nadie creó
- Crear insignias con marcadores, de forma que sigan funcionando si el proyecto cambia de ruta
- Explicar qué es un puntero de LFS, qué hace `.gitattributes` y por qué borrar un binario grande no libera espacio
- Distinguir qué de todo esto es Free en CE y qué es de pago, y con qué se sustituye

---

## 📋 Prerrequisitos

- **Semana 03 completada**: el árbol `plataforma-<tu-dominio>` con `infra` y `ci`, tres usuarios de laboratorio y `docs/organizacion.md` en `app`
- **Un clon local de `app`** con el remoto apuntando a tu instancia, y commits firmados funcionando (Semana 02)
- **`git-lfs` instalado** en tu máquina — la práctica 04 empieza instalándolo si falta
- **`jq` instalado** y `~/.bc-gitlab` con `GITLAB_URL`, `PROYECTO` y `GITLAB_TOKEN`
- **Perfil de laboratorio**: `base` — ver [perfiles-de-laboratorio](../../docs/perfiles-de-laboratorio.md)
- **LFS activado en la instancia** — el `docker-compose.yml` de este repositorio ya trae `gitlab_rails['lfs_enabled'] = true`

---

## 🗂️ Estructura de la Semana

```
week-04-repositorio_como_producto/
├── README.md                  # Este archivo
├── rubrica-evaluacion.md      # Cómo se evalúa
├── checks.json                # Las 16 comprobaciones automáticas
├── 0-assets/                  # Diagramas
├── 1-teoria/                  # 8 archivos, un concepto cada uno
├── 2-practicas/               # 4 prácticas sobre tu instancia
├── 3-proyecto/                # La capa 4 de tu plataforma
├── 4-recursos/                # Libros, vídeos y enlaces
└── 5-glosario/                # Términos de esta semana
```

---

## 📝 Contenidos

### Teoría

| Archivo | Tema | Duración |
|---|---|:--:|
| [01 — El repositorio como producto](1-teoria/01-el-repositorio-como-producto.md) | El coste de arranque, los archivos que GitLab reconoce por nombre y la portada del proyecto | 15 min |
| [02 — Escribir el README](1-teoria/02-escribir-el-readme.md) | Estructura, `[[_TOC_]]`, alertas, Mermaid, rutas relativas y enlaces que no se pudren | 20 min |
| [03 — Licencia y procedencia](1-teoria/03-licencia-y-procedencia.md) | Qué pasa sin licencia, cómo la detecta GitLab, cómo se elige y qué es de pago | 15 min |
| [04 — La wiki del proyecto](1-teoria/04-la-wiki-del-proyecto.md) | Un repositorio Git aparte, cuándo wiki y cuándo `docs/`, slugs, portada y barra lateral | 15 min |
| [05 — Decisiones como ADR](1-teoria/05-decisiones-como-adr.md) | Qué registra un ADR, la plantilla, el ciclo de vida y por qué no va en el README | 15 min |
| [06 — Snippets](1-teoria/06-snippets.md) | Snippets de proyecto y personales, multiarchivo, visibilidad y el riesgo del snippet público | 15 min |
| [07 — Insignias](1-teoria/07-insignias.md) | Marcadores, insignias de proyecto y de grupo, y las que no cargan en una instancia aislada | 15 min |
| [08 — Git LFS](1-teoria/08-git-lfs.md) | El puntero, `.gitattributes`, `migrate`, el coste real y cuándo LFS no es la respuesta | 10 min |

### Prácticas

| Práctica | Qué haces | Duración |
|---|---|:--:|
| [01 — La portada del proyecto](2-practicas/01-la-portada-del-proyecto.md) | README con índice y diagrama, licencia desde plantilla, CONTRIBUTING, descripción, temas y avatar | 50 min |
| [02 — La wiki y el primer ADR](2-practicas/02-la-wiki-y-el-primer-adr.md) | Wiki clonada por Git, portada, barra lateral, ADR-001 y ADR-002, y una página sustituida | 50 min |
| [03 — Snippets e insignias](2-practicas/03-snippets-e-insignias.md) | Snippet multiarchivo con el arranque del proyecto y dos insignias con marcadores | 50 min |
| [04 — Binarios con Git LFS](2-practicas/04-binarios-con-git-lfs.md) | `git-lfs` instalado, `.gitattributes` con patrón preciso, un binario en LFS y su puntero leído por API | 50 min |

### Proyecto

La **capa 4** de tu plataforma: `app` deja de ser un repositorio con código y pasa a ser un repositorio que otro puede arrancar solo. Detalles en [3-proyecto](3-proyecto/README.md).

---

## ⏱️ Distribución del Tiempo (8 horas)

| Bloque | Tiempo |
|---|:--:|
| Teoría (8 archivos) | 2 h 00 |
| Prácticas (4 × 50 min) | 3 h 20 |
| Proyecto | 2 h 00 |
| Revisión y verificación | 40 min |
| **Total** | **8 h 00** |

> [!TIP]
> Haz la práctica 04 con tiempo por delante. Instalar `git-lfs` y equivocarse con el patrón de `.gitattributes` es rápido de arreglar **antes** del primer `push`, y caro después: un binario que ya entró en la historia de Git no sale reescribiendo el `.gitattributes`, sale reescribiendo la historia.

---

## 🧭 Los tres sitios donde vive la documentación

Esta semana aparecen tres almacenes de texto y conviene no confundirlos, porque cada uno tiene su ciclo de vida:

| Sitio | Qué guarda | Cambia con | Se revisa en un merge request |
|---|---|---|:--:|
| **El repositorio** (`README.md`, `docs/`) | Lo que describe **esta versión** del código | Cada commit | Sí |
| **La wiki** (repositorio `.wiki.git` aparte) | Lo que **no depende de la versión**: decisiones, runbooks, contexto | Cuando cambia el criterio | No |
| **Los snippets** | Fragmentos sueltos y reutilizables que no son de nadie en particular | Cuando estorban | No |

La regla que decide, y es la única que hace falta: **si tiene que quedar obsoleta cuando cambia el código, va en el repositorio**. Un ejemplo de instalación va en el repositorio, porque envejece con el `package.json`. Una decisión de arquitectura va en la wiki, porque no envejece: se sustituye por otra decisión, y las dos siguen siendo ciertas en su fecha.

---

## 🎩 Trucos y atajos

| Truco | Cómo |
|---|---|
| Un `logo.png` en la raíz **es** el avatar del proyecto | GitLab lo detecta solo: nada que subir, y viaja con el repositorio (`Gitlab::FileDetector`) |
| Índice automático en cualquier archivo Markdown | `[[_TOC_]]` en una línea suya. También funciona en las páginas de la wiki |
| Alertas de colores sin HTML | `> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]`, `> [!CAUTION]` |
| Diagramas que se renderizan sin subir imágenes | Bloque ```` ```mermaid ```` — Mermaid es nativo; PlantUML y Kroki necesitan servidor configurado en la instancia |
| Clonar la wiki como lo que es | `git clone <url-del-proyecto>.wiki.git` — es un repositorio Git normal |
| Ver el árbol de la wiki sin navegar | `.../projects/$P/wikis?with_content=true \| jq -r '.[].slug'` |
| Cuánto ocupan wiki, LFS y artefactos | `.../projects/$P?statistics=true \| jq '.statistics'` |
| Comprobar que un archivo está en LFS y no en Git | `.../projects/$P/repository/files/<ruta>?ref=main \| jq -r '.content \| @base64d' \| head -1` |
| Descargar el contenido **real** de un archivo en LFS | `.../projects/$P/repository/files/<ruta>/raw?ref=main&lfs=true` |
| Los puntos de la ruta de un archivo se codifican | `assets%2Flogo%2Epng` — sin `%2E`, Rails se come `.png` como formato de respuesta |
| Plantillas de licencia servidas por tu propia instancia | `.../templates/licenses/mit?project=app&fullname=Tu%20Nombre` |
| Ver qué licencia ha detectado GitLab, y con qué confianza | `.../projects/$P?license=true \| jq '.license'` |
| Insignias que sobreviven a un cambio de ruta | `%{project_path}`, `%{project_id}`, `%{default_branch}`, `%{commit_sha}`, `%{latest_tag}`, `%{gitlab_server}` |
| Ver la URL final de una insignia, ya sustituida | `.../projects/$P/badges \| jq -r '.[].rendered_image_url'` |
| Probar una insignia antes de crearla | `.../projects/$P/badges/render?link_url=...&image_url=...` |
| Qué archivos ocupan LFS en tu clon | `git lfs ls-files --size` |
| Traer un clon sin descargar los binarios | `GIT_LFS_SKIP_SMUDGE=1 git clone <url>` — luego `git lfs pull` cuando los necesites |

---

## 📌 Entregables

1. `README.md` en la raíz, con índice automático, alertas y un diagrama Mermaid
2. Licencia en la raíz, aplicada desde la plantilla de tu instancia y detectada por GitLab
3. `CONTRIBUTING.md` en la raíz, con el flujo real de tu proyecto
4. Descripción del proyecto de al menos 30 caracteres
5. Al menos tres temas (*topics*) asignados al proyecto
6. Avatar del proyecto, desde `logo.png` en la raíz del repositorio
7. Portada de la wiki (`home`) que sirve de índice
8. `ADR-001` en la wiki, con la decisión de dominio y stack
9. Al menos cuatro páginas en la wiki, barra lateral incluida
10. Un snippet de proyecto con varios archivos y visibilidad no pública
11. Dos insignias de proyecto, al menos una con marcador
12. Git LFS activado en el proyecto
13. `.gitattributes` en la raíz, con un patrón preciso
14. `assets/logo-grande.png` guardado en LFS, verificable por su puntero

---

## ✅ Verificación

```bash
./scripts/verificar-semana.sh 04
```

Las 16 comprobaciones tienen que pasar. Si alguna falla, la pista te dice en qué práctica y en qué paso se arregla.

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Semana 03 — Grupos, subgrupos, roles y namespaces](../week-03-grupos_proyectos_y_permisos/README.md) | **Semana 04** | [Semana 05 — Issues, etiquetas y tableros](../week-05-issues_etiquetas_y_tableros/README.md) |

[← Volver al inicio del bootcamp](../README.md)

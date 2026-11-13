# Semana 08 — GitLab Flow, releases y métricas de flujo

> Hasta hoy `app` tiene historia, pero no tiene versiones: nadie puede decir "esto es lo que funcionaba el martes". Esta semana publicas la `v0.1.0` con un CHANGELOG que no escribes a mano, sacas un parche desde una rama de release sin arrastrar lo que está a medias en `main`, y mides con datos propios lo rápido que fluye un cambio.

---

## 🎯 Objetivos de la Semana

Al terminar serás capaz de:

- Elegir un modelo de ramas (GitHub Flow, Git Flow, trunk-based, GitLab Flow) por el tipo de producto y no por costumbre, y dejar la decisión escrita
- Numerar versiones con SemVer, incluidas las reglas especiales de `0.y.z`, y decidir la siguiente a partir de los tipos de Conventional Commits
- Crear una release por API con un tag anotado y firmado, notas, hito y enlaces
- Generar el CHANGELOG con la API de GitLab a partir del trailer `Changelog:`, y conservar ese trailer aunque la fusión sea con squash
- Sacar un parche desde una rama `release/*` protegida con `cherry-pick -x`, sin que entre nada más
- Definir las cuatro métricas DORA, decir qué ofrece GitLab de pago para medirlas, y calcular una versión propia con la API de CE

---

## 📋 Prerrequisitos

- **Semana 07 completada**: `main` y `v*` protegidos, `CODEOWNERS`, server hook instalado (firma, Conventional Commits y `Approved-by:` en `main`), `scripts/gobernanza.sh` en `main`
- **Hito `v0.1.0`** con issues del backlog (Semana 05)
- **`revisor-<dominio>` con Maintainer en `app`** y un token de administrador para crearle un token temporal, como en las Semanas 06 y 07
- **Un clon local de `app`** que firma commits y tags (Semana 02)
- **`jq` instalado** y `~/.bc-gitlab` con `GITLAB_URL`, `PROYECTO` y `GITLAB_TOKEN`
- **Perfil de laboratorio**: `base` — ver [perfiles-de-laboratorio](../../docs/perfiles-de-laboratorio.md)

---

## 🗂️ Estructura de la Semana

```
week-08-gitlab_flow_releases_y_metricas/
├── README.md                  # Este archivo
├── rubrica-evaluacion.md      # Cómo se evalúa
├── checks.json                # Las 18 comprobaciones automáticas
├── 0-assets/                  # Diagramas
├── 1-teoria/                  # 7 archivos, un concepto cada uno
├── 2-practicas/               # 4 prácticas sobre tu instancia
├── 3-proyecto/                # La capa 8 de tu plataforma
├── 4-recursos/                # Libros, vídeos y enlaces
└── 5-glosario/                # Términos de esta semana
```

---

## 📝 Contenidos

### Teoría

| Archivo | Tema | Duración |
|---|---|:--:|
| [01 — Modelos de ramas](1-teoria/01-modelos-de-ramas.md) | GitHub Flow, Git Flow, trunk-based y GitLab Flow; cuál encaja con qué producto | 15 min |
| [02 — Versionado semántico](1-teoria/02-versionado-semantico.md) | `MAYOR.MENOR.PARCHE`, la zona `0.y.z`, la versión que dictan los commits y los tags anotados y firmados | 15 min |
| [03 — Releases en GitLab](1-teoria/03-releases-en-gitlab.md) | Tag, notas, hito, enlaces y evidencia; la API; quién puede publicar | 20 min |
| [04 — El CHANGELOG generado](1-teoria/04-changelog-generado.md) | El trailer `Changelog:`, la API `repository/changelog`, `changelog_config.yml` y el squash | 20 min |
| [05 — Ramas de release y cherry-pick](1-teoria/05-ramas-de-release-y-cherry-pick.md) | *Upstream first*, `release/*` protegidas, `cherry-pick -x` y el CHANGELOG de un parche | 20 min |
| [06 — Las métricas DORA](1-teoria/06-metricas-dora.md) | Las cuatro métricas, lo que mide cada una, lo que es de pago y la ley de Goodhart | 15 min |
| [07 — DORA-lite con la API](1-teoria/07-dora-lite-con-la-api.md) | `scripts/metricas.sh` línea a línea, sus aproximaciones y `docs/metricas.md` | 15 min |

### Prácticas

| Práctica | Qué haces | Duración |
|---|---|:--:|
| [01 — GitLab Flow en `app`](2-practicas/01-gitlab-flow-en-app.md) | ADR-006, `release/*` protegidas, plantilla de squash que conserva trailers y `changelog_config.yml` | 50 min |
| [02 — Cambios que cuentan](2-practicas/02-cambios-que-cuentan.md) | Dos issues del hito fusionados con `Changelog:` y la vista previa del CHANGELOG | 50 min |
| [03 — La primera versión](2-practicas/03-la-primera-version.md) | CHANGELOG por merge request, tag firmado, release `v0.1.0` e hito cerrado | 50 min |
| [04 — El primer parche](2-practicas/04-el-primer-parche.md) | Un bug arreglado en `main`, llevado a `release/0.1` con `cherry-pick -x` y publicado como `v0.1.1` | 50 min |

### Proyecto

La **capa 8** de tu plataforma: hay versiones y el flujo se mide con números propios. Detalles en [3-proyecto](3-proyecto/README.md).

---

## ⏱️ Distribución del Tiempo (8 horas)

| Bloque | Tiempo |
|---|:--:|
| Teoría (7 archivos) | 2 h 00 |
| Prácticas (4 × 50 min) | 3 h 20 |
| Proyecto | 2 h 00 |
| Revisión y verificación | 40 min |
| **Total** | **8 h 00** |

> [!TIP]
> El paso 3 de la práctica 01 cambia la plantilla de squash **antes** de cualquier fusión de esta semana. Si fusionas algo con la plantilla antigua, su trailer `Changelog:` se pierde y no hay forma de recuperarlo sin reescribir `main`, que está protegida.

---

## 🧭 Esta semana publica a mano, la Fase 3 automatiza

Todo lo de esta semana son llamadas a la API que ejecutas tú. Están escritas para que, cuando llegue el runner (Semana 09), se puedan convertir en jobs sin cambiar de lógica.

| Lo que quieres | Semana 08 | Con pipeline (Fase 3) |
|---|---|---|
| El CHANGELOG de una versión | `POST .../repository/changelog` a una rama y merge request | Un job que hace la misma llamada |
| La release | `POST .../releases` con las notas de `GET .../repository/changelog` | La palabra clave `release:` de `.gitlab-ci.yml` |
| Las métricas | `scripts/metricas.sh` cuando te acuerdas | Un pipeline programado (Semana 11) |
| Desplegar lo publicado | No hay entorno todavía | `staging` y `production` (Semana 14) |

---

## 🎩 Trucos y atajos

| Truco | Cómo |
|---|---|
| Ver el CHANGELOG de la próxima versión sin escribir nada | `GET .../repository/changelog?version=0.2.0` devuelve `notes` y no hace commits |
| Generar el CHANGELOG cuando no hay tag anterior | Pasa `from=<sha del primer commit>`: sin tag ni `from`, la API responde `422` |
| Conservar el trailer `Changelog:` con squash | `%{first_multiline_commit_description}` en la última línea de la plantilla de squash |
| Commits que entrarán en el CHANGELOG | `git log --format='%h %(trailers:key=Changelog,valueonly,separator=) %s' v0.1.0..main` |
| La siguiente versión según los tipos | `git log --format=%s v0.1.0..main \| grep -Eq '^feat(\(.+\))?!?:'` y sube `MENOR` |
| Crear un tag anotado y firmado | `git tag -s v0.1.0 -m "v0.1.0"` y `git tag -v v0.1.0` |
| Distinguir un tag anotado de uno ligero por API | Anotado si `.target != .commit.id` en `.../repository/tags/<tag>` |
| Llevar un arreglo de `main` a una rama de release | `git cherry-pick -x <sha>`: deja `(cherry picked from commit …)` en el mensaje |
| Saber qué lleva una versión que no está en `main` | `GET .../repository/compare?from=main&to=v0.1.1` |
| Crear una rama protegida desde un tag | Solo por API o web, y desde un commit que ya esté en una rama protegida |
| La última release, sin saber su tag | `GET .../releases/permalink/latest` |
| Mediana de duraciones con `jq` | `sort \| .[length/2 \| floor]` sobre los segundos de cada intervalo |

---

## 📌 Entregables

1. `ADR-006` en la wiki: modelo de ramas, numeración de versiones y qué se parchea
2. `release/*` protegidas: push para nadie, fusión para Maintainers, sin force push
3. Plantilla de squash con `%{first_multiline_commit_description}` y `.gitlab/changelog_config.yml` en `main`
4. Tres cambios en `main` con trailer `Changelog:`: dos de la práctica 02 y el arreglo de la práctica 04
5. `CHANGELOG.md` generado con la sección `0.1.0` en `main` y la `0.1.1` en `release/0.1`
6. Tags anotados `v0.1.0` y `v0.1.1`, y sus releases con notas; la `v0.1.0` asociada al hito, que queda cerrado
7. `release/0.1` protegida, con el arreglo traído por `cherry-pick -x`
8. `scripts/metricas.sh` y `docs/metricas.md` en `main`, con las cuatro métricas definidas y medidas

---

## ✅ Verificación

```bash
./scripts/verificar-semana.sh 08
```

Las 18 comprobaciones tienen que pasar. Si alguna falla, la pista te dice en qué práctica y en qué paso se arregla.

Lo que el script **no** puede comprobar es que los tags estén firmados con tu clave ni que los números de `docs/metricas.md` sean los que da el script. Eso lo evalúa la rúbrica.

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Semana 07 — Gobernanza de ramas y aprobaciones](../week-07-gobernanza_de_ramas_y_aprobaciones/README.md) | **Semana 08** | Semana 09 — CI/CD: fundamentos, runner, artifacts y cache |

[← Volver al inicio del bootcamp](../README.md)

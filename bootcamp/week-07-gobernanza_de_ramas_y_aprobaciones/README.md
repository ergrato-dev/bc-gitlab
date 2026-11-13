# Semana 07 — Gobernanza de ramas y aprobaciones

> Una regla que solo vive en `CONTRIBUTING.md` funciona mientras nadie tenga prisa. Esta semana `main` deja de aceptar `push` de nadie, cada ruta tiene dueño, y un hook del servidor comprueba lo que entra aunque alguien quite la protección.

---

## 🎯 Objetivos de la Semana

Al terminar serás capaz de:

- Proteger una rama para que solo cambie por merge request, y comprobarlo contra tu propio usuario de Owner
- Proteger los tags de versión antes de la primera release, y saber qué operaciones bloquea esa protección
- Escribir un `CODEOWNERS` correcto sabiendo que en CE GitLab no lo lee, y usarlo igualmente como fuente de una auditoría
- Escribir, probar en local e instalar un server hook `pre-receive` con `gitaly hooks set`
- Exigir firma, formato convencional y aprobación sin las *Push rules* ni las *Approval rules* de Premium
- Decir quién puede saltarse cada capa de gobernanza en CE, y detectar cuándo lo hizo
- Escribir un procedimiento de emergencia que no quite ninguna capa

---

## 📋 Prerrequisitos

- **Semana 06 completada**: método de fusión `rebase_merge` o `ff`, squash por defecto, plantilla de squash con `%{approved_by}`, tres merge requests fusionadas con `revisor-<dominio>`
- **`revisor-<dominio>` con Maintainer en `app`** (Semana 03)
- **Un token de administrador** para crear el token de `revisor`, como en la Semana 06
- **Acceso a `docker exec`** en el contenedor `gitlab`: el server hook se instala desde dentro
- **Un clon local de `app`** que firma los commits (Semana 02)
- **`jq` instalado** y `~/.bc-gitlab` con `GITLAB_URL`, `PROYECTO` y `GITLAB_TOKEN`
- **Perfil de laboratorio**: `base` — ver [perfiles-de-laboratorio](../../docs/perfiles-de-laboratorio.md)

---

## 🗂️ Estructura de la Semana

```
week-07-gobernanza_de_ramas_y_aprobaciones/
├── README.md                  # Este archivo
├── rubrica-evaluacion.md      # Cómo se evalúa
├── checks.json                # Las 15 comprobaciones automáticas
├── 0-assets/                  # Diagramas
├── 1-teoria/                  # 7 archivos, un concepto cada uno
├── 2-practicas/               # 4 prácticas sobre tu instancia
├── 3-proyecto/                # La capa 7 de tu plataforma
├── 4-recursos/                # Libros, vídeos y enlaces
└── 5-glosario/                # Términos de esta semana
```

---

## 📝 Contenidos

### Teoría

| Archivo | Tema | Duración |
|---|---|:--:|
| [01 — De la convención a la regla](1-teoria/01-de-la-convencion-a-la-regla.md) | Convención, regla y auditoría; las capas de CE y quién quita cada una; lo que es de pago | 15 min |
| [02 — Ramas protegidas](1-teoria/02-ramas-protegidas.md) | Push, merge y force push; niveles de acceso; comodines; protección por defecto del grupo | 20 min |
| [03 — Tags protegidos](1-teoria/03-tags-protegidos.md) | `v*`, quién crea versiones, qué no se puede mover ni borrar, y qué desbloquea después | 15 min |
| [04 — CODEOWNERS en CE](1-teoria/04-codeowners-en-ce.md) | Sintaxis, la última regla gana, lo que hace Premium y lo que no hace CE | 15 min |
| [05 — Server hooks](1-teoria/05-server-hooks.md) | `pre-receive`, entrada y entorno, `GL_PROTOCOL=web`, `GL-HOOK-ERR` y `gitaly hooks set` | 20 min |
| [06 — Un hook de gobernanza](1-teoria/06-un-hook-de-gobernanza.md) | El hook de `app` línea a línea: linealidad, firma, formato y aprobación, y sus límites | 20 min |
| [07 — Lo que no se puede bloquear](1-teoria/07-lo-que-no-se-puede-bloquear.md) | La auditoría `gobernanza`, la foto de las protecciones y el procedimiento de emergencia | 15 min |

### Prácticas

| Práctica | Qué haces | Duración |
|---|---|:--:|
| [01 — `main` y tags protegidos](2-practicas/01-main-y-tags-protegidos.md) | `main` solo por merge request, `v*` protegidos, protección por defecto del grupo y la foto de referencia | 50 min |
| [02 — CODEOWNERS y la auditoría](2-practicas/02-codeowners-y-la-auditoria.md) | Dueños por ruta, `scripts/gobernanza.sh`, y la primera merge request con `main` protegida | 50 min |
| [03 — El server hook](2-practicas/03-el-server-hook.md) | Probar el hook en local, versionarlo, instalarlo y ver una fusión sin aprobar rechazada | 50 min |
| [04 — Quién se salta las reglas](2-practicas/04-quien-se-salta-las-reglas.md) | `revisor` desprotege `main` y el hook aguanta; detectar, restaurar, ADR-005 y revocar | 50 min |

### Proyecto

La **capa 7** de tu plataforma: las reglas se cumplen aunque nadie mire. Detalles en [3-proyecto](3-proyecto/README.md).

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
> El paso 2 de la práctica 03 (probar el hook en local) parece prescindible y no lo es. Un error de sintaxis en un hook instalado bloquea todos los `push` y todas las fusiones de `app`, y la forma de arreglarlo es entrar en el contenedor. Cinco minutos con un repositorio desnudo en `/tmp` lo evitan.

---

## 🧭 Esta semana detecta, la 09 automatiza

El hook bloquea lo que llega a `main` sin aprobación. Pero no sabe **quién** aprobó, y por eso existe `scripts/gobernanza.sh`, que esta semana ejecutas tú.

| Lo que quieres | Semana 07 | Semana 09 |
|---|---|---|
| Que nadie empuje a `main` | Rama protegida + hook | Igual |
| Que lo apruebe otra persona | Hook (`Approved-by:`) + auditoría a mano | El script como job en cada pipeline de merge request |
| Que lo apruebe el dueño de la ruta | `CODEOWNERS` + auditoría a mano | El mismo job |
| Que la merge request cierre un issue | Auditoría a mano | El mismo job |

El script ya está escrito para eso: lee las variables `CI_*` antes que las tuyas, y no cambiará una línea cuando pase a ser un job.

---

## 🎩 Trucos y atajos

| Truco | Cómo |
|---|---|
| Ver qué te deja hacer una rama, con todas las reglas combinadas | `.../repository/branches/main \| jq '{protected, can_push}'` |
| Cambiar los roles de una rama protegida en CE | `DELETE` y `POST` seguidos: no hay `PATCH` para los niveles |
| Proteger todas las versiones, también las futuras | Tag protegido con comodín `v*` |
| Borrar un tag protegido cuando de verdad hace falta | `DELETE .../repository/tags/<tag>`: por `git push` no se puede |
| Los dueños de un archivo según `CODEOWNERS` | La función `duenos` de una línea de `awk`: gana la última regla que coincide |
| La ruta en disco de un proyecto | `printf '%s' <id> \| sha256sum`: `@hashed/<2>/<2>/<hash>.git` |
| Instalar un server hook en un repositorio | `gitaly hooks set --storage default --repository <ruta> --config /var/opt/gitlab/gitaly/config.toml < hooks.tar` |
| Que el mensaje del hook se vea en la UI | Cada línea con el prefijo `GL-HOOK-ERR:` |
| Probar un hook sin GitLab | `git init --bare` en `/tmp` y el hook en `hooks/pre-receive` |
| Saber por qué falló una fusión | `.../merge_requests/<iid> \| jq -r .merge_error` |
| Ir de un commit de `main` a su merge request | `.../repository/commits/<sha>/merge_requests \| jq -r '.[].iid'` |
| Detectar que cambió una protección | Una foto con `jq -S` y `diff <(foto) foto-guardada.json` |

---

## 📌 Entregables

1. `main` con push para nadie, fusión para Maintainers y sin force push
2. Tags `v*` protegidos, creados solo por Maintainers
3. `CODEOWNERS` en la raíz, con regla por defecto y dueño para el propio archivo
4. `scripts/gobernanza.sh` en `main`
5. `scripts/hooks/pre-receive` en `main` e instalado en `app`
6. Plantilla del commit de fusión con `%{approved_by}`, o `ff` con squash obligatorio
7. Cinco merge requests fusionadas con aprobación de otra persona en total: las dos de la Semana 06 y las tres de esta semana, con `Approved-by:` en su commit
8. `ADR-005` en la wiki, con las consecuencias y el procedimiento de emergencia

---

## ✅ Verificación

```bash
./scripts/verificar-semana.sh 07
```

Las 15 comprobaciones tienen que pasar. Si alguna falla, la pista te dice en qué práctica y en qué paso se arregla.

Lo que el script **no** puede comprobar es que el hook esté instalado: vive en el disco del servidor, no en la API. Eso lo demuestra la práctica 04, paso 3, y lo evalúa la rúbrica.

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Semana 06 — Merge requests y code review](../week-06-merge_requests_y_code_review/README.md) | **Semana 07** | Semana 08 — GitLab Flow, releases y métricas de flujo |

[← Volver al inicio del bootcamp](../README.md)

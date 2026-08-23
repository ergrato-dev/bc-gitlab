# Guía de autoría — Bootcamp GitLab CE

Instrucciones para cualquier agente o persona que cree o edite contenido de este repositorio. Es **la** referencia de convenciones pedagógicas; `CLAUDE.md` no las duplica, remite aquí.

---

## 📋 Contexto del Bootcamp

Bootcamp de **GitLab CE autohospedado**. Trata GitLab como plataforma de ingeniería que el alumno **opera**, no como el sitio donde sube el código.

### 📊 Datos del bootcamp

| Dato | Valor |
|---|---|
| Duración | 26 semanas (~6 meses) |
| Dedicación semanal | 8 h |
| Total | 208 h |
| Modalidad | Autoestudio asincrónico |
| Nivel de entrada | `clone`, `commit`, `push` y qué es una rama |
| Nivel de salida | Platform Engineer |
| Edición | **GitLab CE puro**, autohospedado en Docker. Sin gitlab.com, sin EE, sin trials |
| Versión fijada | `19.2.4-ce.0` — ver [stack-versions](../docs/stack-versions.md) antes de cambiarla |
| Máquina asumida | 16 GB de RAM |
| Instancia | `http://localhost:8888` |

---

## 🎯 Objetivos de Aprendizaje

Al terminar, el alumno es capaz de:

- Instalar, configurar y operar GitLab CE autohospedado, y explicar qué hace cada proceso interno
- Operar Git con precisión quirúrgica y firmar todo lo que entra al repositorio
- Modelar una organización en grupos y subgrupos con el menor privilegio posible
- Gobernar `main` con ramas protegidas, CODEOWNERS y server hooks
- Escribir pipelines en DAG, con hijos y disparos entre proyectos
- Publicar componentes CI/CD versionados en el catálogo
- Construir, almacenar, firmar y limpiar imágenes y paquetes en su instancia
- Dar a cada merge request un entorno vivo y a cada despliegue una vuelta atrás
- Escalar la ejecución con una flota de runners y calcular su coste
- Automatizar la plataforma por REST, GraphQL, webhooks y ChatOps
- Cubrir SAST, secretos, dependencias e imágenes con herramientas libres
- Firmar artefactos, generar SBOM y bloquear lo que no cumple política
- Instrumentar la instancia y definir SLO con error budget
- Perder la instancia a propósito y recuperarla con el tiempo medido
- Montar alta disponibilidad con Praefect, PostgreSQL replicado y PgBouncer
- Gestionar la plataforma como código con Terraform y estado remoto en GitLab
- Sincronizar un clúster desde Git y desplegar por fases con reversión automática

---

## 📚 Estructura del Bootcamp

### Distribución por fases

#### Fase 1 — Fundamentos (S01-04, 32 h)
Instalación en Docker y arquitectura interna, Git quirúrgico y firma SSH, grupos y roles, el repositorio como producto. Al terminar, el alumno tiene su instancia operativa y un repositorio que otro puede arrancar.

#### Fase 2 — Colaboración (S05-08, 32 h)
Issues, etiquetas y tableros, merge requests y code review, gobernanza de ramas, GitLab Flow, releases y métricas. Al terminar, el cambio está gobernado y medido.

#### Fase 3 — CI/CD (S09-13, 40 h)
Fundamentos de pipeline, reglas y secretos, DAG y multi-proyecto, componentes y catálogo, registry y paquetes. La fase más larga a propósito: es la que más se usa en el trabajo real.

#### Fase 4 — Entrega, escala y automatización (S14-17, 32 h)
Entornos, review apps, Pages y feature flags, ejecutores y configuración de runners, Kubernetes y FinOps, API y webhooks.

#### Fase 5 — Seguridad y cadena de suministro (S18-20, 24 h)
Administración y hardening, actualizaciones, escaneo con herramientas libres, SBOM, firma y política como código.

#### Fase 6 — Operación, observabilidad y HA (S21-23, 24 h)
Métricas, logs y tuning, SLO y error budgets, backup y DR drill, incidentes y postmortem, Praefect y PostgreSQL replicado.

#### Fase 7 — IaC y GitOps (S24-25, 16 h)
Terraform con estado remoto y módulos, GitLab Agent, Auto DevOps, entrega progresiva.

#### Fase 8 — Capstone (S26, 8 h)
Auditoría de las 25 capas, `v1.0.0`, documentación y defensa.

### Contenido semana a semana

| Semana | Slug | Tema |
|:--:|---|---|
| 01 | `week-01-instalacion_y_arquitectura_de_gitlab_ce` | Instalación en Docker y arquitectura interna |
| 02 | `week-02-git_avanzado_y_firma_de_commits` | Git quirúrgico y commits firmados |
| 03 | `week-03-grupos_proyectos_y_permisos` | Grupos, subgrupos, roles y namespaces |
| 04 | `week-04-repositorio_como_producto` | Docs, wiki, snippets, insignias, LFS |
| 05 | `week-05-issues_etiquetas_y_tableros` | Issues, taxonomía de etiquetas, tableros, hitos |
| 06 | `week-06-merge_requests_y_code_review` | MRs, sugerencias, estrategias de fusión |
| 07 | `week-07-gobernanza_de_ramas_y_aprobaciones` | Ramas y tags protegidos, CODEOWNERS, server hooks |
| 08 | `week-08-gitlab_flow_releases_y_metricas` | GitLab Flow, releases, changelog, DORA-lite |
| 09 | `week-09-ci_cd_fundamentos` | `.gitlab-ci.yml`, runner, artifacts, cache |
| 10 | `week-10-reglas_variables_y_secretos` | rules, workflow, variables, secure files |
| 11 | `week-11-pipelines_dag_y_multiproyecto` | needs/DAG, padre-hijo, multi-proyecto, resource groups |
| 12 | `week-12-componentes_ci_cd_y_catalogo` | include/extends/inputs, componentes, catálogo |
| 13 | `week-13-registry_de_contenedores_y_paquetes` | Container Registry, cleanup, dependency proxy, packages |
| 14 | `week-14-entornos_review_apps_y_feature_flags` | Environments, deployments, review apps, Pages, feature flags |
| 15 | `week-15-runners_ejecutores_y_configuracion` | Ejecutores, `config.toml`, tags, caché distribuida |
| 16 | `week-16-runners_en_kubernetes_y_finops` | Ejecutor Kubernetes en k3d, autoescalado, coste |
| 17 | `week-17-api_webhooks_y_chatops` | REST v4, GraphQL, webhooks, integraciones, ChatOps |
| 18 | `week-18-administracion_hardening_y_actualizaciones` | Admin area, OIDC, rate limits, upgrade paths |
| 19 | `week-19-seguridad_del_pipeline_con_herramientas_oss` | Semgrep, Gitleaks, OSV-Scanner, Trivy, SARIF |
| 20 | `week-20-cadena_de_suministro_y_politicas_como_codigo` | SBOM, Cosign, SLSA, OPA/Conftest |
| 21 | `week-21-observabilidad_slo_y_troubleshooting` | Prometheus, Grafana, Loki, Sidekiq/Puma, SLO |
| 22 | `week-22-backup_recuperacion_y_respuesta_a_incidentes` | Backup/restore, DR drill, incidentes, postmortem |
| 23 | `week-23-alta_disponibilidad_con_praefect_y_postgresql` | Praefect + Gitaly, PostgreSQL replicado, PgBouncer |
| 24 | `week-24-terraform_y_estado_remoto_en_gitlab` | Terraform, backend HTTP de estado, módulos, Conftest |
| 25 | `week-25-gitops_con_gitlab_agent_y_entrega_progresiva` | GitLab Agent, GitOps, Auto DevOps, canary, rollback |
| 26 | `week-26-capstone_plataforma_gitlab_completa` | Auditoría, integración, `v1.0.0`, defensa |

> Esta tabla existe en **tres** sitios: aquí, en `README.md` y en `docs/decision-renombre-semanas.md`. Si cambias una, cambia las tres. El agente `curriculo-coherencia-reviewer` lo verifica.

---

## 🗂️ Estructura de Carpetas

```
bc-gitlab/
├── README.md                    # Contrato con el estudiante: malla, stack, evaluación
├── CLAUDE.md                    # Índice para agentes; delega aquí
├── CONTRIBUTING.md              # Cómo contribuir
├── docker-compose.yml           # Laboratorio por perfiles: base, observabilidad, ha
├── .env.example                 # Versiones y puertos
├── monitoring/                  # Configuración de Prometheus, Grafana, Loki, Promtail
├── scripts/
│   ├── start.sh / stop.sh       # Arranque y parada del laboratorio
│   ├── verificar-enlaces.sh     # Contrato estructural
│   ├── verificar-semana.sh      # Autograding (motor genérico, cero lógica por semana)
│   └── lab/                     # Utilidades dentro del contenedor: lab-health, lab-backup, lab-audit
├── docs/                        # Documentación transversal
├── .github/
│   ├── copilot-instructions.md  # Este archivo
│   └── prompts/                 # Plantillas de generación
├── .claude/
│   ├── agents/                  # Revisores de solo lectura
│   └── skills/                  # Verificaciones previas al cierre
└── bootcamp/
    ├── README.md                # Índice con el estado real de publicación
    ├── _legado/                 # Las 13 semanas antiguas, en absorción. Desaparece al final
    └── week-NN-tema/            # Una carpeta por semana
```

---

## 🎓 Componentes de Cada Semana

```
week-XX-tema_principal/
├── README.md
├── rubrica-evaluacion.md
├── checks.json
├── 0-assets/
├── 1-teoria/
├── 2-practicas/
├── 3-proyecto/README.md
├── 4-recursos/{ebooks-free,videografia,webgrafia}/README.md
├── 5-glosario/README.md
└── starter/            ← solo si la semana lleva código de apoyo
```

### 1-teoria/

**El número de archivos es libre: los que pida el temario, no un cupo fijo.** Siete u ocho es lo normal. Antes eran cinco y eso comprimía el contenido. **Nunca se sacrifica profundidad para que quepa.**

- **Extensión por archivo**: ~250 líneas, rango sano 200-300. Si un archivo se sale, casi siempre es porque mezcla dos temas: divídelo en dos, no recortes.
- **Un archivo, un concepto.** Si el título necesita una "y", sospecha.
- **Orden fijo dentro del archivo**: qué problema resuelve → cómo se configura → antipatrones → trucos.
- **Ejemplos con `glab` y con la UI web.** La UI cambia de sitio los botones; el CLI es estable. El alumno tiene que saber hacer las dos cosas.
- **Marca el tier siempre.** Si la feature es Premium o Ultimate, dilo, explica qué problema resuelve, cuándo compensa pagarla, y **cuál es el sustituto libre que usa este bootcamp**.
- Diagramas en SVG, nunca arte ASCII.

Nomenclatura: `NN-tema-en-kebab-case.md`, numerados desde `01`.

### 2-practicas/

Cuatro archivos, **200-380 líneas** cada uno. **Las prácticas son operaciones sobre GitLab, no código en `starter/`.** El entregable es el estado real de la instancia y se verifica con la API v4.

> El rango es más ancho que el de la teoría a propósito: aquí cada paso lleva cuatro bloques (Por qué, UI, `glab`, Verifica) y ocho o nueve pasos suman rápido. Si una práctica se pasa de 380, no la recortes: mira si son dos prácticas.

Formato canónico de un paso:

```markdown
## Paso 3: Proteger la rama main

**Por qué**: sin protección, cualquiera con rol Developer puede empujar
directamente a `main` y saltarse la revisión. La protección no impide el
error humano: lo convierte en un merge request.

**Con la UI**: `Settings → Repository → Protected branches`, añade `main`
con *Allowed to push* en `No one` y *Allowed to merge* en `Maintainers`.

**Con `glab`**:

```bash
glab api --method POST "projects/:id/protected_branches" \
  -f name=main -f push_access_level=0 -f merge_access_level=40
```

**Verifica**:

```bash
glab api "projects/:id/protected_branches" | jq '.[].name'
# "main"
```
```

Reglas:

- **Todo paso termina en una verificación ejecutable.** Sin excepción.
- **Advertencia antes de lo destructivo**, con el comando de backup delante.
- Cierra con `## ✅ Resultado` (casillas + el comando de `verificar-semana.sh`) y `## 🧯 Si algo sale mal` (tabla Síntoma | Causa | Solución).
- Para las semanas con código: patrón de **descomentar**.

  ```yaml
  # PASO 2: añade el stage de test.
  # Descomenta las siguientes líneas:
  # test:
  #   stage: test
  #   script: npm test
  ```

- ❌ **No uses `# TODO:` en prácticas.** El `TODO` es formato de proyecto.

### 3-proyecto/README.md

La capa que esta semana añade al hilo conductor. Ocho secciones:

1. `## 🎯 Objetivo`
2. `## 📦 Qué añade esta capa` — cómo encaja con la semana anterior y qué desbloquea en la siguiente
3. `## ✅ Requisitos verificables` — **copia literal de las descripciones de `checks.json`**. Si no coinciden palabra por palabra, el alumno no sabe qué le falta cuando una comprobación falla
4. `## 🎨 Criterios de calidad` — lo que la API no ve
5. `## 💡 Adaptación a tu dominio` — tabla con 3-4 dominios
6. `## 🚦 Cómo entregarlo`
7. `## 🧯 Errores comunes`
8. `## 🔗 Navegación`

### 4-recursos/

Tres subcarpetas: `ebooks-free/`, `videografia/`, `webgrafia/`. **Cada recurso lleva una línea de por qué vale la pena**, no solo el enlace. Los enlaces se comprueban y se fecha la comprobación.

### 5-glosario/

A-Z en español, con el nombre real de la feature en inglés entre paréntesis y **su tier**. Enlaza al glosario global.

### checks.json

Contrato completo en [`docs/autograding.md`](../docs/autograding.md). Lo esencial:

- Se escribe **antes** que el contenido: define qué es entregable y por tanto qué tienen que enseñar las prácticas.
- Entre 6 y 18 comprobaciones, creciendo con la complejidad de la semana.
- Cada `descripcion` se copia literal al proyecto; cada `pista` apunta a archivo + paso.
- Una comprobación, un hecho. `jq` devuelve booleano.
- **Cero lógica bash por semana.** Si necesita código imperativo, el entregable no es verificable y va a rúbrica manual.
- `token: admin` solo cuando de verdad sea configuración de instancia.

### starter/

Solo en las semanas con código de apoyo. Contiene esqueletos que el alumno completa, nunca la solución.

---

## 🎩 Sección de Trucos

**Obligatoria en el README de cada semana.** Es lo que no viene en la documentación oficial, o viene enterrado.

Criterio de admisión:

- ✅ Un atajo, una URL oculta, un flag poco conocido que ahorra tiempo de verdad
- ✅ Una forma de ver algo que la UI no enseña
- ❌ Repetir lo que ya dice la teoría de esa semana
- ❌ Trivialidades ("puedes usar Ctrl+C para copiar")

Todo truco se replica en `docs/trucos-gitlab.md`, en la sección de su semana. El skill `sincronizar-trucos` mantiene los dos lados de acuerdo; si difieren, gana el README de la semana.

---

## 📝 Convenciones

### Comandos

✅ **BIEN** — el porqué, el comando, y qué esperar:

```bash
# El endpoint acepta la ruta completa URL-encoded como ID del proyecto.
glab api "projects/plataforma-biblioteca%2Fapp" | jq '.visibility'
# "private"
```

❌ **MAL** — comando desnudo, sin motivo ni salida esperada:

```bash
glab api projects/1
```

### YAML de pipeline

✅ **BIEN**:

```yaml
test:
  stage: test
  image: node:22-alpine
  script:
    - npm ci
    - npm test
  rules:
    # Solo en MR y en main: evita el pipeline duplicado.
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

❌ **MAL** — `only` está desaconsejado, y sin `rules` el pipeline se duplica en cada MR:

```yaml
test:
  script: npm test
  only:
    - main
```

### Nomenclatura

| Elemento | Formato | Ejemplo |
|---|---|---|
| Carpeta de semana | `week-XX-tema_en_snake_case` | `week-09-ci_cd_fundamentos` |
| Archivo de teoría | `NN-tema-en-kebab-case.md` | `03-artifacts-y-cache.md` |
| Archivo de práctica | `NN-titulo-en-kebab-case.md` | `02-proteger-tags.md` |
| SVG | `NN-nombre-descriptivo.svg` | `01-anatomia-de-un-pipeline.svg` |
| Rama en ejemplos | inglés, kebab-case | `feat/add-late-fee` |
| Variable de CI | `UPPER_SNAKE_CASE` | `DEPLOY_TOKEN` |
| Job de pipeline | inglés, kebab-case | `build-image` |

**Inglés para código, identificadores, ramas, jobs y mensajes de commit. Español para documentación y comentarios educativos.**

### Placeholders

| Placeholder | Uso |
|---|---|
| `<tu-dominio>` | El dominio que eligió el alumno |
| `<grupo>/<proyecto>` | Ruta genérica |
| `plataforma-biblioteca/app` | Ejemplo concreto, siempre el mismo |
| `<TOKEN>` | Cualquier token |

Nunca uses el proyecto real de un tercero como ejemplo.

---

## 🔐 Reglas de Seguridad del Contenido

Este bootcamp enseña seguridad. El material tiene que predicar con el ejemplo.

1. **Nunca un token con formato válido**, ni real ni inventado. Un `glpat-` seguido de 20 caracteres dispara la detección de secretos del propio GitLab. Usa `<TOKEN>` o `$CI_JOB_TOKEN`.
2. **Todo `.gitlab-ci.yml` de ejemplo lleva `rules`.** Sin ellas el pipeline se duplica en cada merge request y el alumno aprende el antipatrón.
3. **Las imágenes de terceros se pinnean por digest** en cualquier ejemplo que vaya a producción, con el tag en un comentario al lado.
4. **Nada de `curl | bash`** sin advertirlo explícitamente y sin enseñar la alternativa.
5. **Los comandos destructivos van precedidos de su backup.** `down -v`, `gitlab-backup restore`, `git push --force`: los tres necesitan aviso.
6. **Cero telemetría.** La configuración del laboratorio la desactiva y eso no se toca.
7. **`~/.bc-gitlab` nunca dentro del repositorio**, y siempre con `chmod 600`.

---

## 🎨 Recursos Visuales

- **SVG siempre. Arte ASCII prohibido.** Un diagrama de cajas dibujado con guiones se rompe en cuanto cambia la fuente.
- Tema oscuro, sin degradados, tipografía sans-serif.
- Paleta de GitLab:

  | Color | Hex | Uso |
  |---|---|---|
  | Naranja GitLab | `#FC6D26` | Elemento principal |
  | Naranja oscuro | `#E24329` | Acento |
  | Morado | `#554488` | Secundario |
  | Fondo | `#1F1F1F` | Lienzo |
  | Texto | `#FAFAFA` | Etiquetas |
  | Gris apagado | `#666666` | Líneas y bordes |

- Nombrados en orden de lectura: `01-`, `02-`…
- **Todo SVG tiene que estar enlazado desde algún `.md`.** `verificar-enlaces.sh` falla si hay huérfanos.

---

## 📖 Documentación

### Las 10 secciones del README de semana, en orden

1. `# Semana NN — Tema`
2. Blockquote de gancho, 2 líneas
3. `## 🎯 Objetivos de la Semana` — bullets "serás capaz de"
4. `## 📋 Prerrequisitos` — encadenados a semanas anteriores, concretos: "Semana 07 completada: `main` protegida con al menos un check requerido"
5. `## 🗂️ Estructura de la Semana` — árbol comentado
6. `## 📝 Contenidos` — tabla de teoría (Archivo | Tema | Duración) y tabla de prácticas (Práctica | Qué haces | Duración)
7. `## ⏱️ Distribución del Tiempo (8 horas)` — **la tabla tiene que sumar 8 h exactas**
8. `## 🎩 Trucos y atajos`
9. `## 📌 Entregables` — numerados
10. `## ✅ Verificación` — el comando
11. `## 🔗 Navegación` — tabla Anterior | Actual | Siguiente + volver al inicio

Entre la 7 y la 8 cabe una sección temática propia de la semana si el tema lo pide.

### Plantilla de archivo de teoría

```markdown
# Título del concepto

> Una línea que sitúa el concepto y por qué importa.

## 🎯 Objetivos

- Lo que sabrás hacer al terminar este archivo

## 1. Qué problema resuelve

Antes de la solución, el problema. Con un caso concreto.

## 2. Cómo funciona

### 2.1 Subtema

Tablas para comparar opciones. Bloques ✅/❌ para contrastar.

## 3. Cómo se configura

Con `glab` y con la UI.

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|

## 5. Trucos

## 📚 Recursos Adicionales

## ✅ Checklist de Verificación

- [ ] Casillas verificables sobre la propia instancia
```

---

## 📊 Evaluación

| Evidencia | Peso | Instrumento |
|---|:--:|---|
| 🧠 Conocimiento | 30% | 10 preguntas conceptuales, respuestas en `<details>` |
| 💪 Desempeño | 40% | Las 4 prácticas, verificadas por `checks.json` |
| 📦 Producto | 30% | 60 pts verificables por API + 40 pts de rúbrica manual |

**Mínimo 70% en cada evidencia**, no en el promedio.

### Estructura de `rubrica-evaluacion.md`

1. `## 📊 Distribución de Evidencias` — tabla + nota mínima
2. `## 🧠 Conocimiento (30%)` — tabla `# | Pregunta` con 10 preguntas **conceptuales, no de memoria**, seguida de `<details><summary><strong>Respuestas</strong></summary>` con 10 respuestas de párrafo argumentado
3. `## 💪 Desempeño (40%)` — tabla Práctica | Criterio | Puntos (10 c/u)
4. `## 📦 Producto (30%)` — **dos tablas**: "Verificable por API — 60 puntos" y "Calidad — 40 puntos"
5. `### Penalizaciones` — tabla Situación | Deducción, graduada y con señal moral clara
6. Cierre con enlace de vuelta

Una buena pregunta de conocimiento contrasta dos cosas y pide el porqué: *"¿Qué diferencia hay entre un artefacto y una caché, y por qué un pipeline sigue funcionando si se pierde la caché pero no si se pierde el artefacto?"*. Una mala pregunta pide recordar un flag.

---

## 🤖 Instrucciones para el agente

### Límites de respuesta

- **Una semana por tanda**, usando la última semana publicada como plantilla de calidad.
- Dentro de la semana, divide por carpetas: primero `checks.json`, luego README, luego teoría, luego prácticas, luego proyecto, luego rúbrica, luego recursos y glosario.

### Reglas de generación

1. **Profundidad sobre cobertura.** Es preferible explicar bien tres palabras clave de `rules` que listar veinte. El bootcamp existe porque los tutoriales superficiales sobran.
2. **Siempre el porqué.** Un comando sin motivo es una receta.
3. **Verificable.** Si un entregable no se puede comprobar por API, no es obligatorio: va a rúbrica manual.
4. **Fechar lo volátil.** Precios, tiers y disponibilidad de features llevan fecha de comprobación.
5. **No inventar.** Endpoints de la API v4, palabras clave de `.gitlab-ci.yml`, subcomandos de `glab`, opciones de `gitlab.rb`: si dudas, comprueba contra la instancia o enlaza `docs.gitlab.com`. **Es el fallo más probable en este repositorio**: un endpoint plausible pero inexistente pasa la revisión y revienta cuando el alumno lo ejecuta. Usa el skill `verificar-comandos-glab`.
6. **Marca el tier.** Toda feature de pago que se mencione lleva su tier y su sustituto libre.

### Estado de la plataforma

GitLab publica una versión menor al mes. Antes de escribir sobre una feature reciente, confirma que existe en la versión fijada (`19.2.4-ce.0`) y no solo en la documentación de `latest`. El selector de versión de `docs.gitlab.com` está arriba a la derecha.

---

## 📚 Referencias Oficiales

- [Documentación de GitLab](https://docs.gitlab.com/)
- [API REST v4](https://docs.gitlab.com/ee/api/api_resources.html)
- [API GraphQL](https://docs.gitlab.com/ee/api/graphql/)
- [Referencia de `.gitlab-ci.yml`](https://docs.gitlab.com/ee/ci/yaml/)
- [Variables predefinidas de CI/CD](https://docs.gitlab.com/ee/ci/variables/predefined_variables.html)
- [GitLab Runner](https://docs.gitlab.com/runner/)
- [Configuración de Omnibus](https://docs.gitlab.com/omnibus/settings/)
- [Comparativa de tiers](https://about.gitlab.com/pricing/feature-comparison/)
- [CLI `glab`](https://gitlab.com/gitlab-org/cli)
- [Gitaly Cluster y Praefect](https://docs.gitlab.com/ee/administration/gitaly/praefect.html)
- [Backup y restauración](https://docs.gitlab.com/ee/administration/backup_restore/)

---

## ✅ Checklist para Nuevas Semanas

- [ ] `checks.json` escrito **primero**, con 6-18 comprobaciones y sus pistas
- [ ] Cada endpoint del `checks.json` comprobado a mano contra una instancia real
- [ ] `README.md` con las 10 secciones en orden
- [ ] La tabla de tiempos suma **8 h exactas**
- [ ] 7-8 archivos de teoría, 200-300 líneas cada uno, un concepto por archivo
- [ ] 4 prácticas (200-380 líneas), cada paso con Por qué / Comando / Verifica
- [ ] Cada práctica cierra con `## ✅ Resultado` y `## 🧯 Si algo sale mal`
- [ ] `3-proyecto/README.md` con los requisitos copiados literalmente del `checks.json`
- [ ] `rubrica-evaluacion.md` con 10 preguntas, respuestas argumentadas y penalizaciones
- [ ] Sección de trucos en el README, replicada en `docs/trucos-gitlab.md`
- [ ] Glosario A-Z con el tier de cada término
- [ ] Recursos con la línea de "por qué vale la pena" y la fecha de comprobación
- [ ] SVG en `0-assets/`, todos enlazados, ninguno con arte ASCII
- [ ] Prerrequisitos encadenados a semanas anteriores, concretos
- [ ] Navegación anterior/siguiente correcta
- [ ] Las tres tablas maestras siguen coincidiendo
- [ ] `bootcamp/README.md` marca la semana como ✅ y la enlaza
- [ ] Se ha borrado de `bootcamp/_legado/` lo que esta semana absorbió
- [ ] `bash scripts/verificar-enlaces.sh` en verde
- [ ] Los dos agentes de revisión pasados

---

## 💡 Notas Finales

- **Profundidad sobre cobertura.** Siempre.
- **Nunca comprimir para que quepa.** Si no cabe, se divide.
- **Lo que no se puede verificar no es obligatorio.**
- **Si dudas de un endpoint, compruébalo. No lo escribas "porque suena bien".**

_Última actualización: agosto de 2026 · Versión 2.0 (malla de 26 semanas)_

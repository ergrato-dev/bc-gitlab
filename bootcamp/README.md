# Bootcamp GitLab CE — Zero to Platform Engineer

26 semanas · 8 h/semana · 208 horas. Una sola instancia GitLab CE autohospedada, un solo proyecto que crece capa a capa.

La columna **Estado** dice la verdad sobre el repositorio: ✅ la semana está escrita, ⬜ todavía no. El contenido se publica en orden, una semana por entrega.

---

## Índice de Semanas

### Fase 1 — Fundamentos (S01-04, 32 h)

| Semana | Tema | Estado |
|:--:|---|:--:|
| [01](week-01-instalacion_y_arquitectura_de_gitlab_ce/README.md) | Instalación de GitLab CE en Docker y arquitectura interna | ✅ |
| 02 | Git quirúrgico y commits firmados | ⬜ |
| 03 | Grupos, subgrupos, roles y namespaces | ⬜ |
| 04 | El repositorio como producto: docs, wiki, snippets, LFS | ⬜ |

### Fase 2 — Colaboración (S05-08, 32 h)

| Semana | Tema | Estado |
|:--:|---|:--:|
| 05 | Issues, taxonomía de etiquetas y tableros | ⬜ |
| 06 | Merge requests y code review | ⬜ |
| 07 | Gobernanza de ramas y aprobaciones | ⬜ |
| 08 | GitLab Flow, releases y métricas de flujo | ⬜ |

### Fase 3 — CI/CD (S09-13, 40 h)

| Semana | Tema | Estado |
|:--:|---|:--:|
| 09 | CI/CD: fundamentos, runner, artifacts y cache | ⬜ |
| 10 | Reglas, variables y secretos | ⬜ |
| 11 | Pipelines DAG, padre-hijo y multi-proyecto | ⬜ |
| 12 | Componentes CI/CD y catálogo | ⬜ |
| 13 | Registry de contenedores y de paquetes | ⬜ |

### Fase 4 — Entrega, escala y automatización (S14-17, 32 h)

| Semana | Tema | Estado |
|:--:|---|:--:|
| 14 | Entornos, review apps y feature flags | ⬜ |
| 15 | Runners: ejecutores y configuración | ⬜ |
| 16 | Runners en Kubernetes y FinOps | ⬜ |
| 17 | API, webhooks y ChatOps | ⬜ |

### Fase 5 — Seguridad y cadena de suministro (S18-20, 24 h)

| Semana | Tema | Estado |
|:--:|---|:--:|
| 18 | Administración, hardening y actualizaciones | ⬜ |
| 19 | Seguridad del pipeline con herramientas OSS | ⬜ |
| 20 | Cadena de suministro y políticas como código | ⬜ |

### Fase 6 — Operación, observabilidad y HA (S21-23, 24 h)

| Semana | Tema | Estado |
|:--:|---|:--:|
| 21 | Observabilidad, SLO y troubleshooting | ⬜ |
| 22 | Backup, recuperación y respuesta a incidentes | ⬜ |
| 23 | Alta disponibilidad con Praefect y PostgreSQL | ⬜ |

### Fase 7 — IaC y GitOps (S24-25, 16 h)

| Semana | Tema | Estado |
|:--:|---|:--:|
| 24 | Terraform y estado remoto en GitLab | ⬜ |
| 25 | GitOps con GitLab Agent y entrega progresiva | ⬜ |

### Fase 8 — Capstone (S26, 8 h)

| Semana | Tema | Estado |
|:--:|---|:--:|
| 26 | Capstone: plataforma GitLab completa | ⬜ |

---

## Estructura de cada semana

```
week-XX-tema_principal/
├── README.md                 # Objetivos, contenidos, tiempos, trucos, entregables
├── rubrica-evaluacion.md     # Conocimiento 30% / Desempeño 40% / Producto 30%
├── checks.json               # Autograding declarativo contra la API v4
├── 0-assets/                 # Diagramas SVG
├── 1-teoria/                 # 7-8 archivos, un concepto por archivo
├── 2-practicas/              # 4 prácticas guiadas, cada paso verificable
├── 3-proyecto/               # La capa que esta semana añade al proyecto
├── 4-recursos/               # ebooks-free, videografia, webgrafia
└── 5-glosario/               # Términos clave A-Z con su tier
```

Las semanas con código de apoyo añaden `starter/`.

---

## Antes de empezar

1. [Preparar el entorno](../docs/setup-entorno.md) — Docker, `glab`, `jq`, k3d, firma de commits y token.
2. [Elegir dominio y crear el proyecto](../docs/proyecto-hilo-conductor.md) — el mismo durante 26 semanas.
3. [Entender el autograding](../docs/autograding.md) — quién corrige y qué no puede corregir.

## Verificar una semana

```bash
./scripts/verificar-semana.sh --doctor   # una vez, antes de la Semana 01
./scripts/verificar-semana.sh 09         # al terminar cada semana
```

## Perfiles del laboratorio

No todas las semanas levantan lo mismo, y algunos perfiles no caben juntos en memoria. Consulta [perfiles-de-laboratorio.md](../docs/perfiles-de-laboratorio.md) antes de las semanas 16, 21, 23 y 25.

```bash
docker compose --profile base up -d
```

---

[← Volver al README principal](../README.md)

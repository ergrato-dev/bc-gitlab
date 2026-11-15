# Semana 12 — Componentes CI/CD y catálogo

> Hasta hoy, cada proyecto que quería construir con npm o auditar sus merge requests tenía que copiar el YAML de `app`. Esta semana ese YAML sale de `app`: `ci/componentes` publica dos componentes versionados en el catálogo de tu instancia, `app` los consume con `@1`, e `infra/entornos` declara con `spec:inputs` qué acepta de quien lo dispara.

---

## 🎯 Objetivos de la Semana

Al terminar serás capaz de:

- Partir un `.gitlab-ci.yml` con `include` y demostrar que el pipeline resultante no ha cambiado
- Predecir cómo se fusionan `include`, `extends` y `!reference`, y por qué las listas se sustituyen
- Declarar `spec:inputs` con tipos, listas cerradas y expresiones regulares, y leer sus errores
- Escribir un componente que no dependa del proyecto que lo usa, y que se pruebe en su propio pipeline
- Publicar versiones semánticas en el catálogo CI/CD desde el pipeline del tag
- Elegir con qué versión consume cada proyecto y saber a qué se resuelve
- Pasar datos tipados a otro pipeline con `trigger:inputs`, y saber cuáles no pueden ser inputs
- Proteger el proyecto de componentes como lo que es: código que se ejecuta en todos sus consumidores

---

## 📋 Prerrequisitos

- **Semana 11 completada**: pipeline de `app` en DAG, `ci/docs.yml` como hijo, `infra/entornos` disparado desde `main` con tres variables y `ci_pipeline_variables_minimum_override_role=maintainer`, `.fuera-de-programados` en los jobs que despliegan y el programado de `caducidades`
- **Subgrupo `ci` vacío** dentro de tu grupo raíz (Semana 03): esta semana nace `ci/componentes`
- **`revisor-<dominio>`** Guest en el grupo y Maintainer en `app` (Semana 03), con la aprobación que exige `gobernanza`, y `GITLAB_ADMIN_TOKEN` en `~/.bc-gitlab` para crear y revocar su token
- **`GOBERNANZA_TOKEN`** en `app` (Semana 09) y CODEOWNERS con `/ci/` (Semana 11)
- **Runner `docker-app` en línea** (Semana 09), desbloqueado: esta semana lo habilitas en un tercer proyecto
- **Perfil `base` levantado** — ver [perfiles-de-laboratorio](../../docs/perfiles-de-laboratorio.md)
- **`jq`** instalado y clones locales de `app` y de `infra/entornos` que firman commits y tags

---

## 🗂️ Estructura de la Semana

```
week-12-componentes_ci_cd_y_catalogo/
├── README.md                  # Este archivo
├── rubrica-evaluacion.md      # Cómo se evalúa
├── checks.json                # Las 17 comprobaciones automáticas
├── 0-assets/                  # Diagramas
├── 1-teoria/                  # 8 archivos, un concepto cada uno
├── 2-practicas/               # 4 prácticas sobre tu instancia
├── 3-proyecto/                # La capa 12 de tu plataforma
├── 4-recursos/                # Libros, vídeos y enlaces
└── 5-glosario/                # Términos de esta semana
```

---

## 📝 Contenidos

### Teoría

| Archivo | Tema | Duración |
|---|---|:--:|
| [01 — `include`](1-teoria/01-include.md) | Cuatro orígenes, qué versión entra, cómo se fusiona, `merged_yaml` e `includes` | 15 min |
| [02 — `extends` y `!reference`](1-teoria/02-extends-y-reference.md) | Fusión profunda, varios padres, quitar claves, componer listas, por qué no anclas | 15 min |
| [03 — `spec:inputs`](1-teoria/03-spec-inputs.md) | El contrato de un archivo, tipos, errores, cuándo se sustituye, funciones | 15 min |
| [04 — Componentes CI/CD](1-teoria/04-componentes.md) | Estructura, la dirección con `$CI_SERVER_FQDN`, qué no debe tener un componente, `spec:component` | 15 min |
| [05 — El catálogo](1-teoria/05-catalogo.md) | Marcar, requisitos, qué publica, visibilidad, qué es de pago y qué no está en CE | 15 min |
| [06 — Versionar y probar un componente](1-teoria/06-versionar-y-probar.md) | Qué rompe a un consumidor, resolución de versiones, la `v`, pruebas y el pipeline del tag | 15 min |
| [07 — Inputs de pipeline](1-teoria/07-inputs-de-pipeline.md) | `spec:inputs` en un proyecto, `trigger:inputs`, la restricción de variables y lo que un input no puede llevar | 15 min |
| [08 — Gobernar el CI compartido](1-teoria/08-gobernar-el-ci-compartido.md) | El radio de un cambio, las cuatro capas, el job token y las *pipeline execution policies* (Ultimate) | 15 min |

### Prácticas

| Práctica | Qué haces | Duración |
|---|---|:--:|
| [01 — `include` en `app`](2-practicas/01-include-en-app.md) | Separas el despliegue en `ci/deploy.yml` y demuestras que el pipeline no cambia | 50 min |
| [02 — Los dos componentes](2-practicas/02-los-dos-componentes.md) | Creas `ci/componentes` con `npm` y `gobernanza`, probados en su propio pipeline | 50 min |
| [03 — Publicar y consumir](2-practicas/03-publicar-y-consumir.md) | Proteges `ci/componentes`, publicas `1.0.0` en el catálogo y `app` la consume con `@1` | 50 min |
| [04 — Inputs en `infra`](2-practicas/04-inputs-en-infra.md) | `infra/entornos` declara el entorno como input y `app` se lo pasa con `trigger:inputs` | 50 min |

### Proyecto

La **capa 12** de tu plataforma: el YAML deja de duplicarse entre proyectos. Detalles en [3-proyecto](3-proyecto/README.md).

---

## ⏱️ Distribución del Tiempo (8 horas)

| Bloque | Tiempo |
|---|:--:|
| Teoría (8 archivos) | 2 h 00 |
| Prácticas (4 × 50 min) | 3 h 20 |
| Proyecto | 2 h 00 |
| Revisión y verificación | 40 min |
| **Total** | **8 h 00** |

> [!IMPORTANT]
> Desde la práctica 03, `build`, `test` y `gobernanza` de `app` vienen de `ci/componentes`. Una versión `1.x.y` mala llega a `app` en su siguiente pipeline sin ninguna merge request en `app`. Por eso `ci/componentes` tiene `main` y tags protegidos, y por eso su propio pipeline prueba cada componente antes de publicarlo.

---

## 🧭 Lo que entra esta semana y lo que espera

| Lo que quieres | Semana 12 | Después |
|---|---|---|
| Que la imagen de un componente sea tuya y esté firmada | Imágenes públicas con tag fijo | Caché en tu instancia con el dependency proxy (Semana 13), firma (Semana 20) |
| Imponer un job en todos los proyectos, quieran o no | Componentes que es más fácil usar que no usar | *Pipeline execution policies*: Ultimate |
| Exigir la aprobación del dueño en `ci/componentes` | `gobernanza` lo audita y deja rastro | Aprobaciones por CODEOWNERS: Premium |
| Saber qué proyecto usa qué versión de un componente | Un bucle sobre `ci/lint` | Detalle de uso en el catálogo: Premium |
| Que `infra/entornos` despliegue de verdad en el entorno que recibe | Lo registra en `registro.txt` | Entornos y despliegues (Semana 14) |
| Que `ci/componentes` se cree desde código | Creado por API | `infra/terraform` (Semana 24) |

---

## 🎩 Trucos y atajos

| Truco | Cómo |
|---|---|
| Lint de una rama sin abrir la merge request | `GET .../ci/lint?content_ref=<rama>`; `?ref=` no cambia de rama |
| Saber a qué versión se resolvió `@1` | `GET .../ci/lint \| jq '.includes[] \| select(.type=="component") \| .blob'`: el SHA está en la URL |
| Demostrar que partir el YAML no cambia nada | `diff <(sort antes.yml) <(sort despues.yml)` sobre los dos `merged_yaml`: el orden cambia, las líneas no |
| Por qué un pipeline se creó en `failed` sin ningún job | GraphQL `project { pipeline(iid:) { errorMessages { nodes { content } } } }`: la REST no lo da |
| Los inputs de un componente sin abrir su repositorio | GraphQL `ciCatalogResources { nodes { versions { nodes { components { nodes { inputs { name default type } } } } } } }` |
| Lanzar un pipeline con inputs desde la terminal | `git push -o ci.input='entorno=production'` |
| Probar un cambio de un componente antes de publicarlo | En una rama del consumidor, `@<SHA>` del commit del componente. Nunca en `main` |
| Marcar un proyecto para el catálogo sin la UI | Mutación GraphQL `catalogResourcesCreate(input: {projectPath:})`; no hay REST |

---

## 📌 Entregables

1. `ci/deploy.yml` con el despliegue y el disparo, incluido desde `.gitlab-ci.yml` de `app`, con el mismo pipeline que antes
2. `ci/componentes` privado, con los componentes `npm` y `gobernanza`, `scripts/gobernanza.sh` y un pipeline que los prueba en verde
3. `ci/componentes` con `main` y tags protegidos, `revisor` como Developer y dueño en CODEOWNERS, y el grupo raíz en la lista de permitidos de su job token
4. `ci/componentes` en el catálogo, con al menos dos versiones semver sin `v` publicadas por el job `publicar`
5. `app` consumiendo `npm@1` y `gobernanza@1`, sin `.npm`, `build`, `test`, `gobernanza` ni `scripts/gobernanza.sh` propios
6. `infra/entornos` con el input `entorno` (`options` y `default: staging`), y `app` pasándoselo con `trigger:inputs`
7. El README de `ci/componentes` y el ADR-009 en la wiki de `app`

---

## ✅ Verificación

```bash
./scripts/verificar-semana.sh 12
```

Las 17 comprobaciones tienen que pasar.

Lo que el script **no** puede comprobar es que la segunda versión respete la versión semántica, que el README de `ci/componentes` sirva a alguien que no lo escribió, ni que el ADR-009 explique por qué las tres variables del disparo no son inputs. Eso lo evalúa la rúbrica.

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Semana 11 — Pipelines DAG y multiproyecto](../week-11-pipelines_dag_y_multiproyecto/README.md) | **Semana 12** | [Semana 13 — Registry de contenedores y paquetes](../week-13-registry_de_contenedores_y_paquetes/README.md) |

[← Volver al inicio del bootcamp](../README.md)

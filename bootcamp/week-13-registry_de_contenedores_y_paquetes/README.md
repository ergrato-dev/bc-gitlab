# Semana 13 — Registry de contenedores y paquetes

> Hasta hoy, lo único que quedaba de un pipeline de `app` era un `.tgz` que caducaba en una semana y que `infra/entornos` encontraba por el ID de un job. Esta semana los binarios viven versionados dentro de tu instancia: una imagen por commit construida sin runner privilegiado, un paquete por SHA, una política que borra lo que sobra, y las imágenes de Docker Hub cacheadas en tu grupo. Todo es Free.

---

## 🎯 Objetivos de la Semana

Al terminar serás capaz de:

- Explicar cómo se autentica un cliente contra el registry, y por qué el realm tiene que poder alcanzarlo quien pregunta
- Construir y subir una imagen desde un job sin `privileged`, con kaniko, y resolver la trampa del realm del laboratorio
- Elegir los tags de una imagen según de dónde sale, y proteger los de versión
- Escribir una política de limpieza que no toque nunca una versión, y ensayarla antes de activarla
- Publicar un paquete genérico por SHA y decidir qué versiones admiten duplicados
- Cachear las imágenes de Docker Hub con el dependency proxy del grupo
- Interpretar el `404` de un job token como lo que es
- Decidir dónde vive cada binario de `app`, cuánto vive y quién lo borra

---

## 📋 Prerrequisitos

- **Semana 12 completada**: `ci/componentes` en el catálogo con `1.0.0` y `1.1.0`, `app` consumiendo `npm@1` y `gobernanza@1`, `infra/entornos` con el input `entorno` y `ci/deploy.yml` en `app`
- **Versiones `v0.1.0` y `v0.1.1`** de `app` con sus releases (Semana 08), y los tags `v*` protegidos para Maintainer (Semana 07)
- **`revisor-<dominio>`** con la aprobación que exige `gobernanza`, y `GITLAB_ADMIN_TOKEN` en `~/.bc-gitlab` para crear y revocar tokens
- **Owner del grupo raíz** (Semana 03): los ajustes de duplicados y del dependency proxy son del grupo
- **Variables de instancia `CI_SERVER_URL` y `CI_API_V4_URL`** apuntando a `http://gitlab:8888` (Semana 09), y `app` con `infra/entornos` en la lista de permitidos de su job token (Semana 11)
- **Perfil `base` levantado** con el `docker-compose.yml` actual del repositorio — ver [perfiles-de-laboratorio](../../docs/perfiles-de-laboratorio.md)
- **`jq`**, Docker en el host y clones locales de `app`, `ci/componentes` e `infra/entornos` que firman commits y tags

---

## 🗂️ Estructura de la Semana

```
week-13-registry_de_contenedores_y_paquetes/
├── README.md                  # Este archivo
├── rubrica-evaluacion.md      # Cómo se evalúa
├── checks.json                # Las 17 comprobaciones automáticas
├── 0-assets/                  # Diagramas
├── 1-teoria/                  # 8 archivos, un concepto cada uno
├── 2-practicas/               # 4 prácticas sobre tu instancia
├── 3-proyecto/                # La capa 13 de tu plataforma
├── 4-recursos/                # Libros, vídeos y enlaces
└── 5-glosario/                # Términos de esta semana
```

---

## 📝 Contenidos

### Teoría

| Archivo | Tema | Duración |
|---|---|:--:|
| [01 — El container registry](1-teoria/01-el-container-registry.md) | Rutas, tag y digest, el 401 y el realm, credenciales, `CI_REGISTRY*`, la base de metadatos | 15 min |
| [02 — Construir sin privilegios](1-teoria/02-construir-sin-privilegios.md) | Docker-in-Docker, Buildah y kaniko; el `Dockerfile` de `app`; la trampa del realm y `registrytoken` | 15 min |
| [03 — Etiquetas, digests y protección](1-teoria/03-etiquetas-y-proteccion.md) | Qué tag lleva cada imagen, por qué no `latest`, etiquetas OCI, tags protegidos e inmutables (Ultimate) | 15 min |
| [04 — La limpieza](1-teoria/04-la-limpieza.md) | El orden en que decide la política, sus valores, el borrado masivo y la recolección de basura | 15 min |
| [05 — El registro de paquetes](1-teoria/05-el-registro-de-paquetes.md) | Genérico o npm, la URL, duplicados con excepción, limpieza y protección de paquetes | 15 min |
| [06 — El dependency proxy](1-teoria/06-el-dependency-proxy.md) | La caché del grupo, las variables, con componentes, qué no pasa por el proxy, la caducidad | 15 min |
| [07 — Permisos y job token](1-teoria/07-permisos-y-job-token.md) | Las dos comprobaciones, el `404`, deploy tokens y la visibilidad de cada registry | 15 min |
| [08 — Qué binario va dónde](1-teoria/08-que-binario-va-donde.md) | Los seis sitios, lo que produce `app`, enlaces de release y cuánto ocupa cada cosa | 15 min |

### Prácticas

| Práctica | Qué haces | Duración |
|---|---|:--:|
| [01 — El registry y el Dockerfile](2-practicas/01-el-registry-y-el-dockerfile.md) | Compruebas el registry, subes y borras desde el host, ves la trampa y proteges los tags de versión | 50 min |
| [02 — El componente `imagen`](2-practicas/02-el-componente-imagen.md) | Escribes y pruebas el componente, publicas `1.2.0` y `app` sube su imagen | 50 min |
| [03 — Limpieza y dependency proxy](2-practicas/03-limpieza-y-dependency-proxy.md) | Dos políticas ensayadas con el borrado masivo, y las imágenes de Docker Hub por el proxy | 50 min |
| [04 — El paquete por SHA](2-practicas/04-el-paquete-por-sha.md) | `app` publica su `.tgz` por SHA e `infra/entornos` lo descarga sin `APP_PACKAGE_JOB_ID` | 50 min |

### Proyecto

La **capa 13** de tu plataforma: los binarios viven versionados dentro de tu instancia. Detalles en [3-proyecto](3-proyecto/README.md).

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
> Desde la práctica 02, cada commit de `main` sube una imagen de unos 60 MB. Hasta la práctica 03 no hay ninguna política que las borre. No dejes pasar días entre las dos: un laboratorio en una máquina de 16 GB no tiene disco de sobra.

---

## 🧭 Lo que entra esta semana y lo que espera

| Lo que quieres | Semana 13 | Después |
|---|---|---|
| Construir imágenes con Docker de verdad, con `docker build` | kaniko, sin privilegios | Runner `dind` aislado y etiquetado (Semana 15) |
| Que nadie pueda sobrescribir una versión, ni un Owner | Tags protegidos para Maintainer | Tags inmutables: Ultimate |
| Saber si la imagen tiene vulnerabilidades | — | Trivy en el pipeline (Semana 19) |
| Saber que la imagen que corre es la que salió del pipeline | Digest en la release | Firma con Cosign y SBOM (Semana 20) |
| Borrar los paquetes por SHA viejos | A mano, o por API | Automatizado por API (Semana 17) |
| Desplegar la imagen | Arranca en tu máquina | En un clúster (Semana 25); la Semana 14 despliega el paquete |
| Que el `FROM` del build pase por el dependency proxy | Sale a Docker Hub: kaniko no llega a `localhost:8888` | Fuera del laboratorio, con un nombre que resuelve igual dentro y fuera de los contenedores |

---

## 🎩 Trucos y atajos

| Truco | Cómo |
|---|---|
| Ver dónde pide token el registry | `curl -sI http://localhost:5050/v2/ \| grep -i www-authenticate` |
| Construir como el pipeline, sin pipeline ni subida | `docker run --rm -v "$PWD:/w" ghcr.io/osscontainertools/kaniko:v1.29.0-debug --context /w --no-push` |
| Subir con kaniko sin pasar por el realm | `{"auths":{"<registry>":{"registrytoken":"<token>"}}}` en `/kaniko/.docker/config.json`, con el token de `$CI_SERVER_URL/jwt/auth` |
| Ensayar la política de limpieza ya | `DELETE …/registry/repositories/<id>/tags` con `name_regex_delete`: los mismos criterios, una vez por hora |
| Comprobar una expresión como la ancla GitLab | `grep -xE '[0-9a-f]{8}'` sobre la lista de tags |
| El tamaño real de un repositorio de imágenes | `GET /registry/repositories/<id>?size=true`; las estadísticas del proyecto llegan tarde |
| Un `404` de un job contra otro proyecto | Es la lista de permitidos del job token del **destino**, no la URL |
| Duplicados prohibidos salvo los SHA | `updateNamespacePackageSettings` con `genericDuplicateExceptionRegex: "^[0-9a-f]{40}$"`; no hay REST |

---

## 📌 Entregables

1. `Dockerfile` y `.dockerignore` en `main` de `app`, y la regla de tags protegidos para las versiones de su imagen
2. El componente `imagen` en `ci/componentes`, probado en su propio pipeline, y publicado en `1.2.0`
3. `app` subiendo su imagen con `imagen@1` en cada commit de `main`
4. Políticas de limpieza en `app` y en `ci/componentes`, y el dependency proxy del grupo con caducidad y en uso por `app`
5. Duplicados genéricos prohibidos en el grupo salvo por SHA, `app` publicando su paquete por SHA, e `infra/entornos` descargándolo sin `APP_PACKAGE_JOB_ID`
6. `v0.2.0` con su imagen y su paquete, y la release enlazando a los dos
7. El ADR-010 en la wiki de `app`

---

## ✅ Verificación

```bash
./scripts/verificar-semana.sh 13
```

Las 17 comprobaciones tienen que pasar.

Lo que el script **no** puede comprobar es que la imagen no lleve nada que sobre, que el componente `imagen` no dependa de `app`, ni que el ADR-010 explique la trampa del realm a quien no la ha sufrido. Eso lo evalúa la rúbrica.

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Semana 12 — Componentes CI/CD y catálogo](../week-12-componentes_ci_cd_y_catalogo/README.md) | **Semana 13** | [Semana 14 — Entornos, review apps y feature flags](../week-14-entornos_review_apps_y_feature_flags/README.md) |

[← Volver al inicio del bootcamp](../README.md)

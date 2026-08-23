# 📦 Versiones del Stack

Todo el material se escribió y se comprobó contra estas versiones. Si algo no te funciona, lo primero que hay que descartar es una diferencia de versión.

_Última revisión: 23 de agosto de 2026 — auditoría completa de versiones y CVEs de todo el stack._

---

## Versiones fijadas

| Componente | Versión | Dónde se fija | Nota |
|---|---|---|---|
| **GitLab CE** | `19.2.4-ce.0` | `.env` → `GITLAB_VERSION` | Pinneada. No uses `latest` |
| **GitLab Runner** | `alpine-v19.2.2` | `.env` → `RUNNER_VERSION` | Misma serie que el servidor |
| Docker | 27.5+ | Tu máquina | |
| Docker Compose | 2.32+ | Tu máquina | El plugin `docker compose`, no `docker-compose` |
| Git | 2.46+ | Tu máquina | 2.34+ para firma SSH; 2.46 por comodidad |
| `glab` | 1.50+ | Tu máquina | CLI oficial de GitLab |
| `jq` | 1.7+ | Tu máquina | El autograding lo necesita |

### Dentro de la imagen de GitLab CE

No los instalas tú: vienen con Omnibus. Se listan porque el material los menciona.

| Componente | Versión en 19.2.4 |
|---|---|
| PostgreSQL | 16.x |
| Redis | 7.x |
| Nginx | 1.26.x |
| Gitaly | La de la propia versión de GitLab |
| Puma / Sidekiq | Ídem |

Compruébalo en tu instancia:

```bash
docker compose exec gitlab gitlab-rake gitlab:env:info
```

---

## Herramientas por semana

Se instalan cuando la semana lo pide, no antes.

| Herramienta | Versión | Semana | Imagen o paquete | Para qué |
|---|---|:--:|---|---|
| k3d | 5.7+ | 16, 25 | binario | Kubernetes local |
| `kubectl` | 1.32+ | 16, 25 | binario | Cliente de Kubernetes |
| Helm | 3.16+ | 16, 25 | binario | Runner y agente en el clúster |
| **SeaweedFS** | `4.40` | 15 | `chrislusf/seaweedfs:4.40` | Caché distribuida de runners |
| Keycloak | 26+ | 18 | `quay.io/keycloak/keycloak` | OIDC contra la instancia |
| **Semgrep** | `1.173.0` | 19 | `semgrep/semgrep:1.173.0` | SAST |
| **Gitleaks** | `8.30.1` | 19 | `zricethezav/gitleaks:v8.30.1` | Detección de secretos |
| **OSV-Scanner** | `2.5.1` | 19 | `ghcr.io/google/osv-scanner:v2.5.1` | Vulnerabilidades de dependencias |
| **Trivy** | `0.74.0` | 19 | `aquasec/trivy:0.74.0` | Escaneo de imágenes |
| **Syft** | `1.51.0` | 20 | `anchore/syft:v1.51.0` | Generación de SBOM |
| **Cosign** | `3.1.3` | 20 | `ghcr.io/sigstore/cosign/cosign:v3.1.3` | Firma de artefactos |
| **Conftest / OPA** | `0.69.0` | 20, 24 | `openpolicyagent/conftest:v0.69.0` | Política como código |
| Terraform | 1.9+ | 24 | binario | La plataforma como código |
| **Prometheus** | `3.14.0` | 21 | `prom/prometheus:v3.14.0` | Métricas |
| **Grafana** | `13.1.4` | 21 | `grafana/grafana:13.1.4` | Paneles |
| **Loki / Promtail** | `3.6.11` | 21 | `grafana/loki:3.6.11`, `grafana/promtail:3.6.11` | Logs centralizados |
| PgBouncer | 1.23+ | 23 | `edoburu/pgbouncer` | Pooling de conexiones |
| **Registry (cache)** | `2.8.3` | Todas | `registry:2.8.3` | Cache de Docker Hub, perfil `base` |

Las versiones **en negrita se fijaron y se auditaron el 23 de agosto de 2026** con las cuatro comprobaciones de más abajo: tag existente en el registro, CVEs consultadas en OSV y contrastadas con el aviso del propio proyecto cuando el feed no distinguía entre versiones. Cuando llegue la tanda de su semana hay que **repetir la auditoría**, no dar por buena la fecha.

Las que van con `+` son herramientas del anfitrión que no entran en ninguna imagen del laboratorio; ahí la versión mínima basta y se pinnea en el momento de instalarlas.

> [!IMPORTANT]
> **Una herramienta que corre dentro de un job de CI no está exenta de pinado.** Es exactamente al revés: es la que más lo necesita, porque tiene acceso al código, a las variables del pipeline y al registro. Ver el caso de Trivy, aquí abajo.

### Tres hallazgos de la auditoría de agosto de 2026

**Trivy — compromiso de la cadena de suministro (marzo de 2026).** Unas credenciales robadas publicaron una release maliciosa: **binario `v0.69.4`** e **imágenes de Docker Hub `0.69.5` y `0.69.6`**, más `trivy-action` `0.0.1`-`0.34.2` y `setup-trivy` `0.2.0`-`0.2.5`. El código exfiltraba secretos del entorno de CI. `CVE-2026-33634` / `GHSA-69fq-xp46-6x23`. La entrada de OSV **no tiene evento `fixed`**, así que marca como afectada cualquier versión posterior; leyendo el aviso, la línea remediada empieza en `v0.69.2`/`v0.69.3` y sigue en las series posteriores, entre ellas la `0.74.0` que fija este bootcamp. Es el ejemplo con el que la Semana 20 explica por qué se pinnea por digest y no por tag.

**El stack de observabilidad estaba dos años atrasado.** El compose fijaba Prometheus `2.54.1`, Grafana `11.2.0` y Loki `3.2.0`, todas de mediados de 2024. La decisiva es Grafana: **`CVE-2024-9264`** es ejecución remota de código a través de las *SQL Expressions*, y se corrigió en **`11.2.1`** — es decir, la versión que fijaba el laboratorio era exactamente la afectada. Re-pinadas a `3.14.0`, `13.1.4` y `3.6.11`. El `registry:2` de la cache, que era un tag flotante de la serie 2.x, queda en `2.8.3`.

Dos avisos para la tanda de la Semana 21, cuando este perfil se levante de verdad:

- **Prometheus sube de major.** `monitoring/prometheus.yml` es un `global` + `scrape_configs` plano y los cuatro flags del compose siguen existiendo en 3.x, pero el stack no se ha arrancado desde el cambio: hay que hacerle una prueba de humo antes de escribir el material.
- **Promtail está descontinuado** en favor de Grafana Alloy, y sus imágenes ya no siguen a Loki: no existe `grafana/promtail:3.7.6`. Por eso Loki y Promtail se quedan en `3.6.11`, la última pareja que sí existe en las dos. La Semana 21 tendrá que decidir si migra a Alloy.

**MinIO — sustituido por SeaweedFS.** La última release de la edición comunitaria es `RELEASE.2025-10-15T17-29-55Z`, de hace diez meses, y acumula avisos sin corregir. Dos son de omisión de autenticación: `CVE-2026-40344` y `CVE-2026-41145`, escritura de objetos arbitrarios en cualquier bucket sabiendo solo una clave de acceso —el `minioadmin` por defecto vale— sin firma válida y con prueba de concepto pública. **El arreglo salió solo en MinIO AIStor**, el producto comercial (`RELEASE.2026-04-11T03-20-12Z`); la edición libre sigue sin parche. Instalarlo en el laboratorio contradiría lo que enseña la Semana 19, así que la caché distribuida de la Semana 15 usa **SeaweedFS `4.40`** (Apache-2.0, API S3 compatible, sin CVEs conocidas). Si al llegar la Semana 15 MinIO ha publicado un parche comunitario, se reevalúa.

---

## Política de versiones

1. **Nunca `latest`. Nada, nunca.** Ni GitLab, ni el runner, ni las imágenes de los ejemplos de CI, ni un `docker run` de un solo uso. `latest` rompe el material sin avisar —un endpoint cambia de forma, una opción se mueve de sitio, una feature pasa de CE a Premium— y además **impide auditar CVEs por adelantado**: no puedes evaluar la seguridad de una versión que aún no sabes cuál será.
2. **El runner va en la misma serie que el servidor.** Un runner más nuevo que GitLab no está soportado; uno mucho más viejo pierde palabras clave del `.gitlab-ci.yml`.
3. **Las imágenes de terceros se pinnean por digest en los pipelines.** La Semana 20 explica por qué un tag no es un identificador.
4. **Lo volátil va fechado.** Cualquier afirmación sobre precios, tiers o disponibilidad de una feature lleva la fecha de comprobación.

### Los tres repos comparten versión

Esta versión no es solo del bootcamp. Hay tres repositorios que corren GitLab CE
y **los tres van a la misma**:

| Repo | Qué es |
|---|---|
| `ergrato-dev/gitlab` | Producción — gitlab.datasena.com |
| `ergrato-dev/gitlab-epti` | Laboratorio |
| `ergrato-dev/bc-gitlab` | Este bootcamp |

Si divergen, el material enseña comandos que en producción ya no existen. Es lo
que pasó hasta agosto de 2026, con tres versiones distintas a la vez: 17.11.1,
`latest` y 19.1.1.

**El orden importa**: la versión se valida primero en el laboratorio, luego
entra en el bootcamp, y **producción es la última**.

---

### Antes de cambiar la versión

Cuatro comprobaciones. Ninguna es opcional, y la segunda es la que más se salta.

**1. Que el tag existe.**

```bash
curl -s "https://hub.docker.com/v2/repositories/gitlab/gitlab-ce/tags?page_size=100&ordering=last_updated" \
  | jq -r '.results[].name' | grep -E '^19\.[0-9]+\.[0-9]+-ce\.0$' | sort -V
```

**2. Auditar sus CVEs.** Ser la última patch de su minor no basta.

```bash
curl -s -X POST "https://api.osv.dev/v1/query" -H "Content-Type: application/json" \
  -d '{"version":"19.2.4","package":{"name":"gitlab"}}' \
  | jq -r '(.vulns // [])[] | (.aliases // [.id])[] | select(startswith("CVE-"))' | sort -u
```

Compara **dos** candidatas con el mismo comando y mira la diferencia de
conjuntos: el número absoluto engaña. El feed de Bitnami en OSV tiene entradas
con un `introduced` sin `fixed` que lo cierre, y esas casan con cualquier
versión posterior. Comprueba los rangos antes de dar una CVE por abierta:

```bash
curl -s "https://api.osv.dev/v1/vulns/BIT-gitlab-2025-1754" | jq '.affected[].ranges[]?.events'
```

> [!WARNING]
> **Para algunos proyectos el feed de Go de OSV no sirve para decidir.** Grafana,
> Prometheus y Loki tienen decenas de entradas con `introduced` y sin `fixed`, así
> que **cualquier** versión que consultes sale con la misma lista: Grafana `11.2.0`
> y Grafana `13.1.4` devuelven las 38 mismas CVE. Comprobado el 23 de agosto de
> 2026. Cuando dos candidatas den listas idénticas, el feed no está diciendo nada:
> la fuente de verdad son las páginas de avisos del propio proyecto.
>
> El mismo patrón, al revés, con **Trivy**: una sola entrada abierta desde `0.69.4`
> marca como vulnerables versiones que sí están remediadas. Lee siempre el aviso
> antes de descartar o aceptar una versión.

Cuenta cuántas devuelve cada candidata antes de creerte el resultado:

```bash
for v in 11.2.0 13.1.4; do
  n=$(curl -s -X POST https://api.osv.dev/v1/query \
        -d "{\"package\":{\"name\":\"github.com/grafana/grafana\",\"ecosystem\":\"Go\"},\"version\":\"$v\"}" \
      | jq '(.vulns // []) | length')
  echo "$v: $n"
done
# 11.2.0: 38
# 13.1.4: 38   <- el feed no distingue; no decidas con esto
```

**3. Que sea parada de actualización, o que el camino pase por ellas.** En la
serie 19 son **19.2, 19.5, 19.8 y 19.11**. Desde la última patch de una parada,
el siguiente salto es directo. Ruta oficial:
<https://docs.gitlab.com/update/upgrade_paths/>

**4. Que exista el tag del runner.** No publica uno por cada patch de GitLab: la
serie 19.2 llega a `v19.2.2`, no hay `v19.2.4`. El runner puede ir por detrás
del servidor en la misma minor; **nunca por delante**.

---

### Subir la versión

> [!WARNING]
> **GitLab no soporta downgrade.** Cuando una versión aplica sus migraciones, ya
> no se puede volver atrás sin borrar los datos. En tu laboratorio eso significa
> perder el proyecto de las 26 semanas.

```bash
# Antes de tocar nada
docker compose exec gitlab /opt/lab/lab-backup
docker compose cp gitlab:/etc/gitlab/gitlab-secrets.json ./gitlab-secrets.json

# Editar GITLAB_VERSION y RUNNER_VERSION en .env, y despues
./scripts/stop.sh && ./scripts/start.sh
```

Espera a que vacíen las migraciones en segundo plano antes del siguiente salto:
`http://localhost:8888/admin/background_migrations`.

La Semana 18 practica una actualización real, con backup previo.

---

### Las claves de configuración también cambian

Una actualización no solo cambia el número: puede mover opciones de sitio.

En **GitLab 19.2** las opciones de Nginx pasaron de `nginx[...]` a
`gitlab_rails['nginx'][...]`. Las antiguas siguen aplicándose, pero están
deprecadas. Y el Registry y Pages tienen su propio Nginx —`registry['nginx'][...]`
y `gitlab_pages['nginx'][...]`— que **no** hereda lo que pongas en
`gitlab_rails['nginx']`.

Contrasta las claves de tu configuración con la plantilla oficial de esa versión:

```bash
curl -s "https://gitlab.com/gitlab-org/omnibus-gitlab/-/raw/master/files/gitlab-config-template/gitlab.rb.template" \
  | grep -oE "[a-z_]+\['[a-z_]+'\]" | sort -u
```

> [!IMPORTANT]
> Una clave que no existe **no da error**: Omnibus la ignora en silencio. Es el
> fallo más difícil de detectar de toda la configuración, y la razón por la que
> este paso está aquí y no en una nota al pie.

---

## Qué hacer si tu versión es otra

El material sigue sirviendo, pero comprueba dos cosas antes de dar por roto un ejercicio:

```bash
# Qué versión tienes de verdad
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" http://localhost:8888/api/v4/version | jq

# Si un endpoint no existe, míralo en la documentación de TU versión
# https://docs.gitlab.com/ee/api/  → selector de versión arriba a la derecha
```

Si encuentras una diferencia real, es un buen issue para el repositorio del bootcamp.

---

[← Volver a docs](README.md)

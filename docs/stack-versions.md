# 📦 Versiones del Stack

Todo el material se escribió y se comprobó contra estas versiones. Si algo no te funciona, lo primero que hay que descartar es una diferencia de versión.

_Última revisión: agosto de 2026._

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

| Herramienta | Versión | Semana | Para qué |
|---|---|:--:|---|
| k3d | 5.7+ | 16, 25 | Kubernetes local |
| `kubectl` | 1.32+ | 16, 25 | Cliente de Kubernetes |
| Helm | 3.16+ | 16, 25 | Runner y agente en el clúster |
| MinIO | latest | 15 | Caché distribuida de runners |
| Keycloak | 26+ | 18 | OIDC contra la instancia |
| Semgrep | latest | 19 | SAST |
| Gitleaks | latest | 19 | Detección de secretos |
| OSV-Scanner | latest | 19 | Vulnerabilidades de dependencias |
| Trivy | latest | 19 | Escaneo de imágenes |
| Syft | latest | 20 | Generación de SBOM |
| Cosign | latest | 20 | Firma de artefactos |
| Conftest / OPA | latest | 20, 24 | Política como código |
| Terraform | 1.9+ | 24 | La plataforma como código |
| Prometheus | 2.54+ | 21 | Métricas |
| Grafana | 11.2+ | 21 | Paneles |
| Loki / Promtail | 3.2+ | 21 | Logs centralizados |
| PgBouncer | 1.23+ | 23 | Pooling de conexiones |

Las que aparecen como `latest` corren dentro de un job de CI o de un contenedor de usar y tirar, así que la versión concreta no condiciona el material.

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

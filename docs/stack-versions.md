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

1. **GitLab está pinneado a propósito.** `latest` rompe el material sin avisar: un endpoint cambia de forma, una opción se mueve de sitio, una feature pasa de CE a Premium. El bootcamp fija la versión y la sube deliberadamente.
2. **El runner va en la misma serie que el servidor.** Un runner más nuevo que GitLab no está soportado; uno mucho más viejo pierde palabras clave del `.gitlab-ci.yml`.
3. **Las imágenes de terceros se pinnean por digest en los pipelines.** La Semana 20 explica por qué un tag no es un identificador.
4. **Lo volátil va fechado.** Cualquier afirmación sobre precios, tiers o disponibilidad de una feature lleva la fecha de comprobación.

### Subir la versión de GitLab

No es tan simple como cambiar el número: GitLab exige pasar por versiones intermedias según la ruta de actualización, y saltarse una migración deja la base de datos a medias.

La ruta oficial se consulta en [gitlab.com/upgrade-path](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/update/upgrade_paths.md). La Semana 18 lo practica de verdad, con backup previo.

```bash
# Antes de tocar nada
docker compose exec gitlab /opt/lab/lab-backup
docker compose cp gitlab:/etc/gitlab/gitlab-secrets.json ./gitlab-secrets.json
```

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

# Documentación General — Bootcamp GitLab CE

## Índice

| Documento | Descripción |
|-----------|-------------|
| [stack-versions.md](./stack-versions.md) | Versiones oficiales del stack tecnológico |
| [docker-setup.md](./docker-setup.md) | Configuración de Docker para el bootcamp |
| [setup/](./setup/) | Guías de instalación y configuración inicial |
| [decision-renombre-semanas.md](./decision-renombre-semanas.md) | ADR: Decisión de estructura de semanas |

## Entornos disponibles

El bootcamp incluye dos entornos Docker:

### `docker-compose.yml` — Entorno estándar (recomendado para todas las semanas)

```bash
docker compose up -d
```

GitLab CE + Runner + Registry cache + Prometheus/Grafana (profile: `monitoring`). Acceso en `http://localhost`.

### `docker-compose.gl-epti.yml` — Entorno de laboratorio hardened

Imagen custom con scripts de utilidad pre-instalados (`gl-epti-health`, `gl-epti-backup`, `gl-epti-audit`). Útil para practicar administración avanzada (Semanas 10-11).

```bash
# Usar el Makefile de atajos:
make -f Makefile.gl-epti up          # Levantar (http://localhost:8888)
make -f Makefile.gl-epti health      # Check de salud completo
make -f Makefile.gl-epti backup      # Ejecutar backup
make -f Makefile.gl-epti audit       # Auditoría de seguridad / CVEs
make -f Makefile.gl-epti monitoring-up  # Prometheus + Grafana (puerto 9091/3001)
```

> Para registro de runner en gl-epti usar `make -f Makefile.gl-epti register` — el token se obtiene desde `http://localhost:8888`.

## Requisitos del Sistema

### Minimos para GitLab CE

- **CPU**: 4 cores
- **RAM**: 4 GB (8 GB recomendado)
- **Disco**: 20 GB SSD
- **Sistema operativo**: Ubuntu Server 24.04 LTS (recomendado)

### Para el Entorno de Desarrollo

- Docker 27+
- Docker Compose 2.32+
- Git 2.46+
- 8 GB RAM minimo (GitLab CE + Runner + Registry)

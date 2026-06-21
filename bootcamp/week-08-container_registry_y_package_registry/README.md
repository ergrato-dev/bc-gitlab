# Semana 08 — Container Registry y Package Registry

## Objetivos

- Configurar y usar GitLab Container Registry
- Construir y publicar imagenes Docker en el pipeline
- Gestionar versiones y tags de imagenes
- Configurar GitLab Package Registry (npm, Maven, PyPI)
- Implementar escaneo de seguridad de contenedores

## Requisitos Previos

- Pipelines CI/CD (Semanas 05-06)
- Docker y GitLab Runner (Semana 07)

## Estructura de la Semana

| Componente | Tiempo | Descripcion |
|-----------|--------|-------------|
| Teoria | 2h | Container Registry, Package Registry, seguridad |
| Practicas | 3h | Build y push de imagenes, publicar paquetes |
| Proyecto | 1h | Pipeline que publica imagen y paquete |

## Contenidos

### Teoria
1. [01-container-registry.md](./1-teoria/01-container-registry.md) — Configuracion y uso
2. [02-docker-build-en-ci.md](./1-teoria/02-docker-build-en-ci.md) — Docker-in-Docker, Kaniko
3. [03-package-registry.md](./1-teoria/03-package-registry.md) — npm, Maven, PyPI, NuGet
4. [04-gestion-de-versiones.md](./1-teoria/04-gestion-de-versiones.md) — Tags semanticos, limpieza
5. [05-container-scanning.md](./1-teoria/05-container-scanning.md) — SAST, Dependency Scanning

### Practicas
1. [01-container-registry-setup/](./2-practicas/01-container-registry-setup/) — Habilitar y autenticar
2. [02-build-y-push-imagenes/](./2-practicas/02-build-y-push-imagenes/) — Pipeline de Docker build
3. [03-package-registry/](./2-practicas/03-package-registry/) — Publicar paquete npm/PyPI
4. [04-security-scanning/](./2-practicas/04-security-scanning/) — Container Scanning en pipeline

### Proyecto
- [3-proyecto/](./3-proyecto/) — Pipeline que construye imagen, escanea y publica

## Entregables

- [ ] Imagen Docker publicada en Container Registry
- [ ] Pipeline con build, scan y push
- [ ] Paquete publicado en Package Registry
- [ ] Limpieza de imagenes antiguas configurada

---

[← Semana 07](../week-07-gitlab_runner_gestion_y_escalado/README.md) | [Semana 09 →](../week-09-gitlab_api_y_automatizacion/README.md)

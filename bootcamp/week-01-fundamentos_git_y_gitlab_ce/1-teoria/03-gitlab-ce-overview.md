# 03 — GitLab CE: Descripcion General

## Objetivos

- Entender que es GitLab CE y su proposito en DevOps
- Conocer la diferencia entre GitLab CE y EE
- Identificar los modulos principales y su proposito
- Comprender el ciclo de vida DevOps en GitLab

## Que es GitLab CE?

GitLab Community Edition (CE) es la version gratuita y open source (licencia MIT) de la plataforma DevOps de GitLab. A diferencia de otras herramientas que requieren integrar multiples servicios (GitHub + Jenkins + Artifactory + Jira + ...), GitLab integra todo en una sola aplicacion:

- **Repositorios Git**: Alojamiento de codigo fuente con proteccion de ramas
- **CI/CD**: Pipelines de integracion y despliegue continuo (`.gitlab-ci.yml`)
- **Container Registry**: Registro privado de imagenes Docker por proyecto
- **Package Registry**: Gestion de paquetes (npm, Maven, PyPI, NuGet, Composer)
- **Issues**: Seguimiento de tareas, bugs, mejoras con labels y milestones
- **Merge Requests**: Revision de codigo colaborativa con diff, comentarios, aprobaciones
- **Wiki**: Documentacion del proyecto en Markdown
- **Security**: SAST, Secret Detection, Dependency Scanning, Container Scanning
- **Environments**: Gestion de entornos de despliegue (staging, production)

### El Ciclo DevOps en GitLab

```
Plan → Code → Verify → Package → Release → Configure → Monitor
  │      │       │        │         │          │           │
Issues  MRs    CI/CD   Registry  Deploy    IaC/K8s   Prometheus
```

## GitLab CE vs EE

| Caracteristica | CE (Free) | EE (Pago) |
|---------------|-----------|-----------|
| Repositorios Git | Si | Si |
| CI/CD | Si | Si |
| Container Registry | Si | Si |
| Package Registry | Si | Si |
| Issues y Merge Requests | Si | Si |
| Wiki | Si | Si |
| Pipelines multi-proyecto | Si | Si |
| **Epics** | No | Si |
| **Roadmaps** | No | Si |
| **Value Stream Analytics** | No | Si |
| **Scoped Labels** | No | Si |
| **Multi-level Epics** | No | Si |
| Compliance pipelines | Basico | Avanzado |
| LDAP/SAML SSO | Si | Si (mas opciones) |
| Soporte | Comunidad | Comercial 24/7 |

> **Para este bootcamp usamos CE.** Todo lo que se aprende aqui aplica directamente a EE. CE cubre el 90% de lo que un DevOps engineer necesita en el dia a dia.

## Arquitectura General

```
                         ┌─────────────────────────┐
  Usuario ──→ Nginx ──→  │ GitLab Rails (Puma)     │
  (HTTPS)    (proxy)     │                         │
                         │  ├── PostgreSQL (datos)  │
                         │  ├── Redis (cache/colas) │
                         │  ├── Gitaly (git ops)    │
                         │  └── Sidekiq (bg jobs)   │
                         └─────────────────────────┘
```

## Modulos Principales

1. **GitLab Rails**: Aplicacion web principal. Framework Ruby on Rails. Maneja la UI, API REST/GraphQL, logica de negocio.

2. **Gitaly**: Servicio gRPC para operaciones Git. Separa el acceso a repositorios para mejorar rendimiento y permitir escalado horizontal (Gitaly Cluster).

3. **PostgreSQL**: Base de datos relacional. Almacena usuarios, proyectos, issues, MRs, configuracion CI/CD, variables. Es el unico componente con estado persistente critico.

4. **Redis**: Cache, colas de Sidekiq, sesiones, rate limiting, estado de runners. Multiples instancias para separar responsabilidades en produccion.

5. **Sidekiq**: Procesamiento asincrono. Maneja envio de emails, creacion de pipelines, webhooks, exportaciones, garbage collection de repositorios.

6. **Nginx**: Servidor web y proxy reverso incluido en Omnibus. Maneja SSL, static assets, y enruta peticiones a Puma.

## En Nuestro Docker Compose

El archivo `docker-compose.yml` de la raiz del proyecto incluye todos estos componentes **empaquetados en la imagen `gitlab/gitlab-ce`** (Omnibus empaquetado para Docker). No necesitas configurar PostgreSQL o Redis por separado — GitLab los gestiona internamente.

## Requisitos del Sistema

| Componente | Minimo | Recomendado |
|-----------|--------|-------------|
| CPU | 4 cores | 8 cores |
| RAM | 4 GB | 8 GB |
| Almacenamiento | 20 GB | 50 GB+ SSD |
| Sistema Operativo | Linux | Ubuntu 24.04 LTS |

# Bootcamp GitLab CE — Zero to Hero

[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/license-CC%20BY--NC--SA%204.0-lightgrey.svg)](./LICENSE)
[![12 Semanas](https://img.shields.io/badge/semanas-12-yellow.svg)](#)
[![72 Horas](https://img.shields.io/badge/horas-72-orange.svg)](#)
[![GitLab CE](https://img.shields.io/badge/GitLab-CE-fc6d26?logo=gitlab&logoColor=white)](#)

---

## Descripcion

Bootcamp intensivo de **12 semanas (~3 meses)** enfocado en el dominio de **GitLab Community Edition** como plataforma DevOps integral. Disenado para llevar a estudiantes de cero a **Administrador DevOps Junior**, con enfasis en CI/CD, administracion de infraestructura, automatizacion y mejores practicas.

### Objetivos

Al finalizar el bootcamp, los estudiantes seran capaces de:

- Dominar los fundamentos de Git y control de versiones
- Instalar, configurar y administrar GitLab CE en multiples entornos
- Disenar y gestionar pipelines CI/CD completos con `.gitlab-ci.yml`
- Administrar GitLab Runners (shared, specific, autoscaling)
- Gestionar Container Registry y Package Registry
- Automatizar tareas con GitLab API (REST y GraphQL)
- Implementar politicas de seguridad, RBAC y cumplimiento
- Configurar monitoreo, backup y alta disponibilidad
- Integrar GitLab con herramientas externas (Slack, Jira, Prometheus)
- Desplegar una plataforma DevOps completa lista para produccion

### Por que GitLab CE?

> **Plataforma DevOps unificada** — GitLab CE integra repositorio, CI/CD, registro, seguridad y monitoreo en una sola aplicacion.

GitLab CE es la version gratuita y open source de la plataforma DevOps mas completa del mercado. Este bootcamp se enfoca en GitLab CE autogestionado, preparando a los estudiantes para entornos empresariales reales donde el control total de la infraestructura es critico.

---

## Estructura del Bootcamp

| Etapa | Semanas | Horas | Temas Principales |
|-------|---------|-------|-------------------|
| **Fundamentos** | 1-3 | 18h | Git, instalacion GitLab CE, proyectos y grupos |
| **Intermedio** | 4-7 | 24h | Issues/MR, CI/CD basico y avanzado, GitLab Runner |
| **Avanzado** | 8-11 | 24h | Registry, API, administracion, seguridad, monitoreo |
| **Produccion** | 12 | 6h | Proyecto final — Plataforma DevOps completa |

**Total: 12 semanas** | **72 horas** de formacion intensiva

---

## Contenido por Semana

Cada semana incluye:

```
bootcamp/week-XX-tema_principal/
├── README.md                 # Descripcion y objetivos
├── rubrica-evaluacion.md     # Criterios de evaluacion
├── 0-assets/                 # Imagenes y diagramas
├── 1-teoria/                 # Material teorico
├── 2-practicas/              # Ejercicios guiados
├── 3-proyecto/               # Proyecto semanal
├── 4-recursos/               # Recursos adicionales
│   ├── ebooks-free/
│   ├── videografia/
│   └── webgrafia/
└── 5-glosario/               # Terminos clave
```

### Componentes Clave

- **Teoria**: Conceptos fundamentales con ejemplos del mundo real
- **Practica**: Ejercicios progresivos y laboratorios hands-on
- **Evaluacion**: Evidencias de conocimiento, desempeno y producto
- **Recursos**: Glosarios, referencias y material complementario

---

## Stack Tecnologico

| Tecnologia | Version | Uso |
|-----------|---------|-----|
| GitLab CE | **17.x+** | Plataforma DevOps principal |
| Docker | **27+** | Containerizacion de GitLab y Runners |
| Docker Compose | **2.32+** | Orquestacion local |
| GitLab Runner | **17.x+** | Ejecucion de pipelines CI/CD |
| Git | **2.46+** | Control de versiones |
| Ubuntu Server | **24.04 LTS** | Sistema operativo de produccion |
| PostgreSQL | **16+** | Backend de base de datos GitLab |
| Redis | **7+** | Cache y colas GitLab |
| Nginx | **1.26+** | Reverse proxy |
| Python | **3.12+** | Automatizacion con GitLab API |
| Minikube | **latest** | Kubernetes local para practicas |
| Prometheus | **2.50+** | Monitoreo |
| Grafana | **10+** | Dashboards |

---

## Inicio Rapido

### Prerrequisitos

- **Docker 27+** y **Docker Compose 2.32+** instalados
- **Git 2.46+** para control de versiones
- **VS Code** (recomendado) con extensiones
- Navegador moderno (Chrome, Firefox, Edge)
- **Minimo 8 GB RAM** (GitLab CE requiere ~4 GB)

> **Todo corre en Docker.** No necesitas instalar GitLab, Ruby, PostgreSQL ni ninguna otra dependencia en tu sistema. Docker Compose orquesta GitLab CE, GitLab Runner, Registry cache, Prometheus y Grafana.

### 1. Clonar y configurar

```bash
git clone https://github.com/ergrato-dev/bc-gitlab.git
cd bc-gitlab
cp .env.example .env
```

### 2. Levantar GitLab CE

```bash
docker compose up -d
# Esperar ~5 min (primer inicio). Ver progreso:
docker compose logs -f gitlab
```

### 3. Acceder a GitLab CE

```bash
# Obtener contrasena root
docker compose exec gitlab grep 'Password:' /etc/gitlab/initial_root_password

# Abrir http://localhost en navegador
# Usuario: root / Contrasena: la obtenida arriba
```

### 4. Navegar a la Semana Actual

```bash
cd bootcamp/week-01-fundamentos_git_y_gitlab_ce
```

### 5. Seguir las Instrucciones

Cada semana contiene un `README.md` con instrucciones detalladas.

### Comandos esenciales Docker

```bash
docker compose up -d              # Iniciar GitLab
docker compose down               # Detener GitLab
docker compose down -v            # Destruir todo (volumenes incluidos)
docker compose logs -f gitlab     # Logs en tiempo real
docker compose ps                 # Estado de servicios
docker compose exec gitlab bash   # Shell dentro del contenedor
```

---

## Metodologia de Aprendizaje

### Estrategias Didacticas

- **Aprendizaje Basado en Proyectos (ABP)**
- **Practica Deliberada**
- **DevOps Challenges**
- **Infraestructura como Codigo (IaC)**
- **Pair Administration**

### Distribucion del Tiempo (6h/semana)

- **Teoria**: 1.5-2 horas
- **Practicas**: 2.5-3 horas
- **Proyecto**: 1.5-2 horas

### Evaluacion

Cada semana incluye tres tipos de evidencias:

1. **Conocimiento** (30%): Cuestionarios y evaluaciones teoricas
2. **Desempeno** (40%): Ejercicios practicos y laboratorios
3. **Producto** (30%): Entregables evaluables (infraestructura funcional)

**Criterio de aprobacion**: Minimo 70% en cada tipo de evidencia

---

## Soporte

- **Discussions**: [GitHub Discussions](https://github.com/ergrato-dev/bc-gitlab/discussions)
- **Issues**: [GitHub Issues](https://github.com/ergrato-dev/bc-gitlab/issues)

---

## Exencion de Responsabilidad

Este repositorio es un recurso **educativo** creado con fines de aprendizaje. Al utilizarlo, aceptas los siguientes terminos:

- **Solo fines educativos**: El contenido, los ejemplos de codigo y los proyectos estan disenados exclusivamente para la ensenanza y el aprendizaje. No constituyen asesoramiento profesional, legal ni de seguridad.
- **Sin garantias**: El material se proporciona **"tal cual"**, sin garantias de ningun tipo, expresas o implicitas, incluyendo idoneidad para un proposito particular o ausencia de errores.
- **Codigo en produccion**: Los ejemplos de configuracion son ilustrativos. Antes de usarlos en entornos productivos, debes realizar revisiones de seguridad, rendimiento y adaptacion a tu contexto especifico.
- **Versiones de software**: Las versiones de herramientas mencionadas pueden quedar desactualizadas. Siempre consulta la documentacion oficial mas reciente.
- **Limitacion de responsabilidad**: Los autores y contribuidores no se responsabilizan por perdidas de datos, danos directos o indirectos, interrupciones de servicio ni cualquier otro perjuicio derivado del uso de este material.

---

## Licencia

Este proyecto esta bajo la licencia **[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)** (Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International).

**Puedes:** compartir y adaptar el material, incluso crear forks educativos.
**No puedes:** usar este material con fines comerciales.
**Debes:** dar credito apropiado y distribuir las adaptaciones bajo la misma licencia.

Ver el archivo [LICENSE](./LICENSE) para el texto completo.

---

## Agradecimientos

- [GitLab](https://about.gitlab.com/) — Por la plataforma DevOps mas completa
- [GitLab Community](https://gitlab.com/gitlab-org/gitlab-foss) — Por el proyecto open source
- [Docker](https://www.docker.com/) — Por la containerizacion
- Todos los contribuidores

---

## Documentacion Adicional

- [Instrucciones de Copilot](./.github/copilot-instructions.md)
- [Codigo de Conducta](./CODE_OF_CONDUCT.md)
- [Politica de Seguridad](./SECURITY.md)

---

**Bootcamp GitLab CE — Zero to Hero**
*De cero a administrador DevOps en 3 meses — Todo sobre Docker*

[Comenzar Semana 1](./bootcamp/week-01-fundamentos_git_y_gitlab_ce/README.md) • [Ver Documentacion](./docs) • [Reportar Issue](https://github.com/ergrato-dev/bc-gitlab/issues)

Hecho con dedicacion para la comunidad DevOps

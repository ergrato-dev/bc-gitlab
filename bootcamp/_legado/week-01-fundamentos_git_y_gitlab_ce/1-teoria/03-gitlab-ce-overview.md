# 📖 03 — GitLab CE: ¿Qué es y Para Qué Sirve?

## 🎯 Objetivos de Aprendizaje

Al finalizar esta lección serás capaz de:

- Explicar qué es GitLab CE y su posicionamiento como plataforma DevOps
- Describir la diferencia entre GitLab CE, EE y GitLab.com
- Identificar los módulos principales de GitLab y su propósito
- Comparar GitLab con GitHub entendiendo cuándo elegir cada uno
- Explicar por qué usamos Docker en este bootcamp (en lugar de Omnibus o K8s)
- Navegar los elementos principales de la interfaz web de GitLab

---

## 📖 ¿Qué es GitLab CE?

**Analogía**: Imagina que tu equipo necesita un taller de software completo. GitHub sería como alquilar un escritorio en un coworking (acceso a herramientas básicas, pero dependes de que el edificio esté abierto). GitLab CE sería como construir tu propio taller en tu terreno: tú decides los horarios, las reglas, qué entra y qué no, y nadie más tiene acceso a tus planos.

**GitLab Community Edition (CE)** es la versión gratuita y de código abierto (licencia MIT) de la plataforma DevOps de GitLab. Su diferenciador clave: en lugar de necesitar integrar múltiples herramientas separadas (GitHub + Jenkins + Artifactory + Jira + SonarQube), GitLab integra **todo el ciclo DevOps en una sola aplicación**:

| Módulo | Qué hace | Herramienta equivalente que reemplaza |
|--------|----------|------------------------------------|
| **Repository** | Alojamiento de código con protección de ramas | GitHub, Bitbucket |
| **CI/CD** | Pipelines (`.gitlab-ci.yml`) | Jenkins, CircleCI, GitHub Actions |
| **Container Registry** | Registro privado de imágenes Docker | Docker Hub (privado), Harbor |
| **Package Registry** | npm, Maven, PyPI, NuGet, Composer | Nexus, Artifactory |
| **Issues & Boards** | Seguimiento de tareas y bugs | Jira, Trello, Linear |
| **Merge Requests** | Revisión de código con diff, comentarios, aprobaciones | GitHub PRs |
| **Wiki** | Documentación del proyecto en Markdown | Confluence, Notion |
| **Environments** | Gestión de entornos (staging, production) | Octopus Deploy |
| **Security Scanning** | SAST, secretos, dependencias | Snyk, SonarQube |

---

## 📅 Historia y Posicionamiento

```
2011 — Dmitriy Zaporozhets y Valery Sizov crean GitLab como alternativa open source a GitHub
2012 — Primera versión pública (Ruby on Rails)
2014 — GitLab Inc. se funda; se divide en CE (gratis) y EE (pago)
2015 — Lanzamiento de GitLab CI/CD integrado
2017 — GitLab Runner en Go, mejoras masivas de rendimiento
2018 — GitLab obtiene valoración de $1.1B (unicornio)
2019 — Auto DevOps, Kubernetes integration
2021 — IPO en NASDAQ ($GTLB)
2023 — GitLab 16: nueva UI, mejoras de AI (GitLab Duo)
2024 — GitLab 17: runners next-gen, token authentication renovado
```

> 🌍 **Dato**: Más de 30 millones de usuarios registrados y más de 1 millón de organizaciones usan GitLab. Empresas como NVIDIA, Siemens, Goldman Sachs y la NASA usan GitLab CE/EE self-hosted.

---

## 🔀 GitLab CE vs EE vs GitLab.com

| Característica | CE (Gratis Self-hosted) | EE (Pago Self-hosted) | GitLab.com (SaaS) |
|----------------|------------------------|----------------------|-------------------|
| Repositorios Git | ✅ Ilimitados | ✅ | ✅ Free tier |
| CI/CD | ✅ Ilimitado | ✅ | ✅ 400 min/mes gratis |
| Container Registry | ✅ | ✅ | ✅ |
| Package Registry | ✅ | ✅ | ✅ |
| Issues y MRs | ✅ | ✅ | ✅ |
| Wiki | ✅ | ✅ | ✅ |
| **Epics** | ❌ | ✅ | ✅ Premium |
| **Roadmaps** | ❌ | ✅ | ✅ Premium |
| **Value Stream Analytics** | ❌ | ✅ | ✅ Premium |
| **Scoped Labels** | ❌ | ✅ | ✅ Premium |
| **Multi-level Epics** | ❌ | ✅ | ✅ Ultimate |
| LDAP/SAML SSO | ✅ Básico | ✅ Completo | ✅ |
| Compliance pipelines | ✅ Básico | ✅ Avanzado | ✅ Ultimate |
| Soporte | Comunidad | Comercial 24/7 | Según plan |
| Control total de datos | ✅ Total | ✅ Total | ❌ (datos en nube GitLab) |
| Costo | **Gratis** | Desde $29/usuario/mes | Gratis con límites |

> **En este bootcamp usamos CE.** Todo lo que aprendas aquí aplica directamente a EE y a GitLab.com. La CE cubre el 90% de lo que un DevOps engineer necesita en el día a día.

---

## 🆚 GitLab vs GitHub: ¿Cuándo Elegir Cada Uno?

No es una pregunta de "cuál es mejor" — es una pregunta de contexto:

| Escenario | GitLab CE | GitHub |
|-----------|-----------|--------|
| Empresa que necesita control total de datos | ✅ Self-hosted | ❌ Cloud only* |
| Open source público con visibilidad máxima | ⚠️ Menos comunidad | ✅ Estándar |
| CI/CD integrado sin costo adicional | ✅ Ilimitado | ✅ Acciones gratis con límites |
| Privacidad / datos sensibles | ✅ Tú controlas el servidor | ❌ Datos en Microsoft |
| Ecosistema de herramientas en una sola app | ✅ Todo integrado | ⚠️ Requiere integraciones |
| Cumplimiento normativo (GDPR, HIPAA) | ✅ On-premise | ✅ Enterprise options |
| Equipo pequeño, inicio rápido | ⚠️ Requiere servidor | ✅ Inmediato |

> 💡 **El mundo real**: Muchas empresas usan **ambos**. GitLab para proyectos internos y privados, GitHub para open source y visibilidad pública.

---

## 🐳 ¿Por Qué Docker en Este Bootcamp?

GitLab se puede instalar de tres formas principales:

| Método | Ventajas | Desventajas | Uso típico |
|--------|----------|-------------|------------|
| **Omnibus** (paquete nativo) | Más rendimiento, producción real | Requiere Linux dedicado, más complejo | Producción |
| **Docker / Docker Compose** | Portátil, rápido de levantar, fácil de limpiar | Algo más lento | Desarrollo, bootcamps, staging |
| **Kubernetes (Helm)** | Alta disponibilidad, escalado automático | Muy complejo | Producción enterprise |

**Usamos Docker Compose porque**:
- ✅ Funciona en cualquier sistema operativo del alumno
- ✅ Se levanta en un comando: `docker compose up -d`
- ✅ Se destruye y recrea limpio fácilmente
- ✅ Fácil de compartir la configuración (docker-compose.yml en el repo)
- ✅ El comportamiento de GitLab CE es idéntico a producción

```bash
# Con Docker Compose, levantar GitLab CE es tan simple como:
docker compose up -d

# Ver que está corriendo
docker compose ps gitlab

# Acceder
# Abrir http://localhost en el navegador
```

---

## 🗺️ Tour de la Interfaz Web

### La Barra Superior (Top Bar)

```
┌──────────────────────────────────────────────────────────────────────────┐
│  🦊 GitLab   [Barra de búsqueda: / para activar]   🔔  +  👤            │
└──────────────────────────────────────────────────────────────────────────┘
              │                                        │  │  │
              │                               Notifs   │  │  Perfil/Preferencias
              │                              Crear nuevo ─┘
              Buscar proyectos, issues, MRs, usuarios
```

- **`/`** (atajo): Activa la búsqueda global
- **`+`**: Menú de creación rápida (proyecto, grupo, issue, MR, snippet)
- **🔔**: Notificaciones
- **Avatar**: Preferences, Edit profile, Sign out

### El Sidebar Izquierdo

| Ítem | Qué muestra |
|------|-------------|
| **Your work** | Dashboard personal (issues asignados, MRs, proyectos) |
| **Explore** | Proyectos y grupos públicos de la instancia |
| **Groups** | Los grupos a los que perteneces |
| **Admin Area** | Solo visible para administradores |

### Dentro de un Proyecto

| Sección | Contenido |
|---------|-----------|
| **Repository** | Árbol de archivos, commits, ramas, tags, comparaciones |
| **Issues** | Lista con filtros, labels, milestones, boards Kanban |
| **Merge Requests** | MRs abiertos, revisiones pendientes, merged, cerrados |
| **CI/CD** | Pipelines, jobs, artifacts, schedules, variables, environments |
| **Packages & Registries** | Container Registry, Package Registry |
| **Wiki** | Documentación del proyecto en Markdown |
| **Settings** | Miembros, webhooks, CI/CD, integrations, visibilidad |

### El Ciclo DevOps en GitLab

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│   Plan      Code       Verify      Package    Release    Monitor    │
│     │         │           │           │          │          │       │
│  Issues    Repo +      CI/CD       Container  Deploy    Prometheus  │
│  Boards    MRs +       Pipelines   Registry   Envs      Grafana     │
│  Roadmap   Editor      SAST        Package    GitLab    Alerts      │
│                        Tests       Registry   Pages                 │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Comandos Docker Esenciales para el Bootcamp

```bash
# ¿QUÉ VAMOS A HACER?: Ver el estado de GitLab CE en Docker
# ¿POR QUÉ LO HACEMOS?: Para saber si está disponible antes de conectarnos
# ¿PARA QUÉ SIRVE?: Verificar que el contenedor está "healthy" (tarda ~3-5 min)
docker compose ps gitlab

# Obtener la contraseña inicial de root (solo funciona las primeras 24h)
docker compose exec gitlab grep 'Password:' /etc/gitlab/initial_root_password

# Ver los logs de GitLab en tiempo real
docker compose logs -f gitlab

# Reiniciar GitLab si hay problemas
docker compose restart gitlab

# Parar y arrancar todo el entorno del bootcamp
docker compose stop
docker compose start
```

---

## 🤔 Preguntas de Reflexión

1. ¿Por qué una empresa con datos sensibles (médicos, financieros) preferiría GitLab CE self-hosted sobre GitLab.com?
2. ¿Qué herramientas separadas tendría que mantener una empresa que usa solo GitHub para obtener lo que GitLab CE incluye de serie?
3. Docker hace que levantar GitLab sea más fácil, pero ¿qué desventajas tiene para un entorno de producción real?
4. Navega `http://localhost` en tu bootcamp. ¿Cuántas secciones del sidebar puedes identificar que corresponden a etapas del ciclo DevOps?
5. ¿En qué tipo de proyecto o empresa crees que GitLab CE tiene más valor que GitHub? ¿Y viceversa?

---

## 📚 Recursos Adicionales

- [GitLab CE vs EE](https://about.gitlab.com/install/ce-or-ee/) — Comparativa oficial
- [GitLab Handbook](https://handbook.gitlab.com/) — Cómo trabaja GitLab internamente
- [GitLab Architecture Overview](https://docs.gitlab.com/ee/development/architecture.html) — Documentación técnica
- [GitLab Overview Video](https://www.youtube.com/watch?v=7KHOIkh32j0) — Tour oficial (1 hora)

---

## ➡️ Siguiente Lección

[04 — Arquitectura Interna de GitLab CE →](./04-arquitectura-gitlab.md)

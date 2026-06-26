# Semana 01 — Fundamentos de Git y GitLab CE

## Objetivos

- Comprender los fundamentos del control de versiones con Git
- Configurar Git correctamente (user, email, SSH)
- Dominar operaciones basicas de Git (clone, commit, push, pull, branch, merge)
- Entender la arquitectura de GitLab CE y sus componentes
- Explorar la interfaz web de GitLab CE
- Crear el primer proyecto en GitLab

## Requisitos Previos

- **Docker 27+** y **Docker Compose 2.32+** instalados
- **Git 2.46+** instalado
- Terminal de comandos
- 8 GB RAM minimo

> **GitLab CE se instala en detalle en Semana 02.** Para esta semana basta con levantarlo una vez:
> ```bash
> cd bc-gitlab
> cp .env.example .env
> docker compose up -d
> # Esperar ~5 min. Obtener contrasena root:
> docker compose exec gitlab grep 'Password:' /etc/gitlab/initial_root_password
> ```
> GitLab CE estara en `http://localhost`. Usa `root` + la contrasena obtenida.
> La Semana 02 explica el `docker-compose.yml` en detalle y todos los parametros de configuracion.

## Estructura de la Semana

| Componente | Tiempo | Descripcion |
|-----------|--------|-------------|
| Teoria | 2h | Git fundamentals, GitLab CE overview |
| Practicas | 3h | Hands-on Git + primer proyecto GitLab |
| Proyecto | 1h | Configurar repo personal en GitLab CE |

## Contenidos

### Teoria
1. [01-git-fundamentos.md](./1-teoria/01-git-fundamentos.md) — Comandos esenciales de Git
2. [02-git-ramas-y-flujos.md](./1-teoria/02-git-ramas-y-flujos.md) — Ramas, merge, rebase
3. [03-gitlab-ce-overview.md](./1-teoria/03-gitlab-ce-overview.md) — Que es GitLab CE
4. [04-arquitectura-gitlab.md](./1-teoria/04-arquitectura-gitlab.md) — Componentes internos
5. [05-primeros-pasos-gitlab.md](./1-teoria/05-primeros-pasos-gitlab.md) — Interfaz web y SSH

### Practicas
1. [01-configuracion-git/](./2-practicas/01-configuracion-git/) — Configurar Git (user, email, SSH)
2. [02-flujo-git-basico/](./2-practicas/02-flujo-git-basico/) — Clone, commit, push, pull
3. [03-ramas-y-merges/](./2-practicas/03-ramas-y-merges/) — Crear ramas y fusionar
4. [04-primer-proyecto-gitlab/](./2-practicas/04-primer-proyecto-gitlab/) — Crear proyecto en GitLab CE

### Proyecto
- [3-proyecto/](./3-proyecto/) — Configurar repositorio personal con README, .gitignore y ramas

## Entregables

- [ ] Git configurado con SSH
- [ ] Repositorio creado en GitLab CE
- [ ] Al menos 3 commits en el repositorio
- [ ] Al menos 2 ramas creadas

---

[← Bootcamp](../README.md) | [Semana 02 →](../week-02-instalacion_gitlab_ce/README.md)

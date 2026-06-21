# Semana 02 — Instalacion de GitLab CE con Docker

## Objetivos

- Instalar GitLab CE usando **Docker Compose** (metodo unico del bootcamp)
- Configurar GitLab CE con dominio personalizado y persistencia
- Entender los requisitos de hardware y software
- Configurar variables de entorno con `.env`
- Realizar la configuracion post-instalacion
- Levantar GitLab Runner como servicio Docker

## Requisitos Previos

- Docker y Docker Compose instalados y funcionales
- Git (Semana 01)
- 8 GB RAM minimo
- 20 GB espacio en disco
- El repositorio bc-gitlab clonado

> **Todo se levanta con `docker compose up -d` desde la raiz del proyecto.** No se instala GitLab en el sistema host.

## Estructura de la Semana

| Componente | Tiempo | Descripcion |
|-----------|--------|-------------|
| Teoria | 2h | Docker Compose, configuracion, persistencia |
| Practicas | 3h | Levantar, configurar, backup/restore |
| Proyecto | 1h | Instancia GitLab CE funcional documentada |

## Contenidos

### Teoria
1. [01-metodos-instalacion.md](./1-teoria/01-metodos-instalacion.md) — Omnibus, Docker, K8s (por que elegimos Docker)
2. [02-instalacion-docker.md](./1-teoria/02-instalacion-docker.md) — docker-compose.yml paso a paso
3. [03-configuracion-inicial.md](./1-teoria/03-configuracion-inicial.md) — Post-instalacion via GITLAB_OMNIBUS_CONFIG
4. [04-persistencia-y-volumenes.md](./1-teoria/04-persistencia-y-volumenes.md) — Volumenes Docker y backups
5. [05-solucion-problemas.md](./1-teoria/05-solucion-problemas.md) — Troubleshooting comun en Docker

### Practicas
1. [01-preparacion-entorno/](./2-practicas/01-preparacion-entorno/) — Verificar requisitos y preparar
2. [02-docker-compose-gitlab/](./2-practicas/02-docker-compose-gitlab/) — Levantar GitLab CE
3. [03-configuracion-post-instalacion/](./2-practicas/03-configuracion-post-instalacion/) — Configurar root, temas, SMTP
4. [04-backup-y-restore/](./2-practicas/04-backup-y-restore/) — Backup basico

### Proyecto
- [3-proyecto/](./3-proyecto/) — Instancia GitLab CE funcional y documentada

## Entregables

- [ ] GitLab CE corriendo en Docker
- [ ] Acceso web funcional
- [ ] Password root cambiada
- [ ] Proyecto de prueba creado

---

[← Semana 01](../week-01-fundamentos_git_y_gitlab_ce/README.md) | [Semana 03 →](../week-03-proyectos_grupos_y_organizacion/README.md)

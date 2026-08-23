# 📖 Ebooks y Documentación Gratuita — Semana 02

Recursos de lectura curados para profundizar en Docker, Docker Compose y la instalación de GitLab CE.

---

## Documentación oficial (siempre actualizada)

### GitLab CE — Documentación de instalación con Docker

- **URL:** [docs.gitlab.com/ee/install/docker/](https://docs.gitlab.com/ee/install/docker/)
- **Tipo:** Documentación oficial GitLab
- **Relevancia para el bootcamp:** Directa — cubre exactamente lo que hacemos en la semana
- **Lo que encontrarás:** Pre-configuración, variables de entorno, troubleshooting, actualización

### GitLab Omnibus — Referencia de configuración

- **URL:** [docs.gitlab.com/omnibus/settings/](https://docs.gitlab.com/omnibus/settings/)
- **Tipo:** Referencia técnica
- **Relevancia:** Alta — es la referencia de todas las opciones de `GITLAB_OMNIBUS_CONFIG`
- **Lo que encontrarás:** Cada opción de `gitlab.rb` explicada con ejemplos (SMTP, SSL, backups, etc.)

### GitLab Backup & Restore

- **URL:** [docs.gitlab.com/ee/administration/backup_restore/](https://docs.gitlab.com/ee/administration/backup_restore/)
- **Tipo:** Guía de administración
- **Relevancia:** Alta — cubre el proceso completo de backup y restore
- **Lo que encontrarás:** Opciones de backup, estrategias, restauración, backup en S3

---

## Libros gratuitos (parcial o completo)

### Docker Deep Dive — Nigel Poulton

- **URL:** [nigelpoulton.com/books/](https://nigelpoulton.com/books/)
- **Capítulos relevantes para esta semana:**
  - Cap. 4: Docker Images
  - Cap. 5: Containers
  - Cap. 7: Docker Compose
  - Cap. 9: Volumes
- **Nota:** El autor ofrece capítulos de muestra gratuitos; la versión completa es de pago pero muy asequible

### Docker Compose Reference (oficial)

- **URL:** [docs.docker.com/compose/compose-file/](https://docs.docker.com/compose/compose-file/)
- **Tipo:** Referencia técnica completa
- **Lo que encontrarás:** Todas las keys soportadas en `docker-compose.yml` con ejemplos: `services`, `volumes`, `networks`, `profiles`, `healthcheck`, `depends_on`

### Docker Storage — Documentación oficial

- **URL:** [docs.docker.com/storage/volumes/](https://docs.docker.com/storage/volumes/)
- **Lo que encontrarás:** Named volumes vs bind mounts vs tmpfs, comandos de gestión, drivers de volúmenes

---

## Referencias rápidas

| Recurso | URL | Para qué sirve |
|---------|-----|----------------|
| `gitlab-ctl` reference | [docs.gitlab.com/omnibus/maintenance/](https://docs.gitlab.com/omnibus/maintenance/) | Comandos de administración: status, restart, reconfigure, tail |
| Docker Compose CLI | [docs.docker.com/compose/reference/](https://docs.docker.com/compose/reference/) | Todos los subcomandos: up, down, logs, exec, ps, cp |
| Docker Hub gitlab-ce | [hub.docker.com/r/gitlab/gitlab-ce](https://hub.docker.com/r/gitlab/gitlab-ce) | Tags disponibles, notas de versión |
| GitLab Runner Docker | [docs.gitlab.com/runner/install/docker.html](https://docs.gitlab.com/runner/install/docker.html) | Configurar el runner (lo usaremos en semanas siguientes) |

# 🌐 Webgrafía — Semana 02

Referencias web curadas, organizadas por tema y nivel de uso durante la semana.

---

## Referencias principales

| URL | Descripción | Cuándo usarla |
|-----|-------------|---------------|
| [hub.docker.com/r/gitlab/gitlab-ce](https://hub.docker.com/r/gitlab/gitlab-ce) | Imagen oficial de GitLab CE en Docker Hub. Tags, changelog, variables de entorno | Verificar qué versión usar |
| [docs.gitlab.com/ee/install/docker/](https://docs.gitlab.com/ee/install/docker/) | Guía oficial de instalación de GitLab CE con Docker | Práctica 02 |
| [docs.docker.com/compose/](https://docs.docker.com/compose/) | Referencia completa de Docker Compose (CLI y formato de archivo) | Durante todas las prácticas |
| [docs.docker.com/storage/volumes/](https://docs.docker.com/storage/volumes/) | Documentación de volúmenes Docker: named, bind mounts, tmpfs | Práctica 04 y teoría |
| [docs.gitlab.com/omnibus/settings/](https://docs.gitlab.com/omnibus/settings/) | Referencia de GITLAB_OMNIBUS_CONFIG — todas las opciones de gitlab.rb | Configuración de la instancia |

---

## Referencias de administración

| URL | Descripción | Nivel |
|-----|-------------|-------|
| [docs.gitlab.com/omnibus/maintenance/](https://docs.gitlab.com/omnibus/maintenance/) | Referencia de `gitlab-ctl`: status, restart, reconfigure, tail, backup | Básico |
| [docs.gitlab.com/ee/administration/raketasks/](https://docs.gitlab.com/ee/administration/raketasks/) | Comandos `gitlab-rake`: check, backup, importaciones | Básico |
| [docs.gitlab.com/ee/administration/backup_restore/](https://docs.gitlab.com/ee/administration/backup_restore/) | Guía completa de backup y restore (incluye S3, NFS) | Básico-Intermedio |
| [docs.gitlab.com/omnibus/settings/smtp.html](https://docs.gitlab.com/omnibus/settings/smtp.html) | Configuración SMTP para Gmail, SendGrid, Office 365 y más | Intermedio |

---

## Referencias de Docker

| URL | Descripción | Nivel |
|-----|-------------|-------|
| [docs.docker.com/compose/compose-file/](https://docs.docker.com/compose/compose-file/) | Especificación completa de docker-compose.yml: todas las keys | Referencia |
| [docs.docker.com/compose/profiles/](https://docs.docker.com/compose/profiles/) | Profiles de Docker Compose (--profile monitoring) | Básico |
| [docs.docker.com/compose/environment-variables/](https://docs.docker.com/compose/environment-variables/) | Variables de entorno en Compose: .env, ${VAR}, set_vars | Básico |
| [docs.docker.com/engine/reference/commandline/stats/](https://docs.docker.com/engine/reference/commandline/stats/) | Referencia de `docker stats` para monitoreo de recursos | Básico |

---

## Herramientas online

| URL | Descripción | Uso |
|-----|-------------|-----|
| [play-with-docker.com](https://labs.play-with-docker.com/) | Entorno Docker en el navegador — sin instalación local | Practicar si no tienes Docker local |
| [composerize.com](https://www.composerize.com/) | Convierte comandos `docker run` a formato docker-compose.yml | Utilidad |
| [yaml.to](https://yaml.to/json) | Valida y formatea archivos YAML en línea | Depurar docker-compose.yml |
| [crontab.guru](https://crontab.guru/) | Editor visual de expresiones cron | Configurar backups automáticos |

---

## Troubleshooting y comunidad

| URL | Descripción |
|-----|-------------|
| [docs.gitlab.com/ee/install/docker/troubleshooting.html](https://docs.gitlab.com/ee/install/docker/troubleshooting.html) | Troubleshooting oficial de GitLab con Docker |
| [forum.gitlab.com](https://forum.gitlab.com/) | Foro oficial de la comunidad GitLab |
| [stackoverflow.com/questions/tagged/gitlab](https://stackoverflow.com/questions/tagged/gitlab) | Preguntas frecuentes sobre GitLab en Stack Overflow |
| [gitlab.com/gitlab-org/gitlab/-/issues](https://gitlab.com/gitlab-org/gitlab/-/issues) | Reportar bugs o buscar problemas conocidos |

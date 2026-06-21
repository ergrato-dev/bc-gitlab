# 01 — Tipos de Runners

## Clasificacion por ambito

### Shared Runner (Runner compartido)
- Disponible para todos los proyectos de la instancia
- Administrado por el administrador de GitLab (Admin Area → Runners)
- Ideal para organizaciones que quieren ofrecer CI a todos los equipos sin que cada uno gestione su infraestructura
- Trabaja con cola compartida (fair queuing)

### Group Runner (Runner de grupo)
- Disponible para todos los proyectos dentro de un grupo y subgrupos
- Administrado por el owner del grupo (Group → CI/CD → Runners)
- Balance entre shared y specific: comparte runner entre equipos relacionados
- Util para organizaciones con multiples equipos que comparten stack tecnologico

### Specific Runner (Runner especifico de proyecto)
- Asignado a un solo proyecto
- Administrado por el maintainer del proyecto (Project → Settings → CI/CD → Runners)
- Maximo control y aislamiento
- Ideal para proyectos con requisitos especiales de hardware, software o seguridad

### Instance Runner (GitLab.com / EE)
- Disponible para toda la instancia en GitLab.com o GitLab EE
- Los administradores de la instancia pueden configurar pools de Runners por region

## Estados de un Runner

- **Active**: Conectado, puede recibir jobs
- **Paused**: Conectado pero no recibe nuevos jobs (termina los actuales)
- **Offline**: No conectado en los ultimos minutos

## Autenticacion del Runner

Cada runner usa un `registration token` para registrarse y recibe un `runner token` (authentication token) que usa para comunicarse con GitLab via API. La autenticacion es por HTTPS con el token en los headers.

# 📖 04 — Arquitectura Interna de GitLab CE

## 🎯 Objetivos de Aprendizaje

Al finalizar esta lección serás capaz de:

- Identificar los componentes principales de GitLab CE y su función
- Describir el flujo completo de una petición HTTP desde el navegador hasta la base de datos
- Explicar cómo fluye un `git push` desde el cliente hasta Gitaly
- Usar comandos `gitlab-ctl` para diagnosticar el estado de GitLab
- Usar Docker Compose para inspeccionar y depurar el entorno del bootcamp

---

## 📖 Visión General: GitLab como Ciudad

**Analogía**: Piensa en GitLab CE como una pequeña ciudad. Cada componente es un departamento con una función específica:

- **Nginx** = La entrada principal (recepcionista que dirige el tráfico)
- **Puma/Rails** = El ayuntamiento (toma decisiones, procesa solicitudes)
- **PostgreSQL** = El archivo histórico (guarda todos los registros)
- **Redis** = El tablón de avisos (información rápida y temporal)
- **Gitaly** = El almacén de planos (todos los repositorios Git)
- **Sidekiq** = Los mensajeros (hacen tareas en segundo plano)

Cuando haces `git push`, es como llevar un paquete a la ciudad: pasa por la recepción (Nginx), el recepcionista lo lleva al almacén (Gitaly), y los mensajeros (Sidekiq) se encargan de avisar a todos los interesados.

---

## 🏛️ Componentes en Detalle

### 🔵 Nginx — El Proxy Inverso

Nginx es el punto de entrada de toda comunicación HTTP/HTTPS. No ejecuta lógica de negocio; enruta el tráfico:

- Sirve assets estáticos (imágenes, JS, CSS) directamente (sin tocar Rails)
- Enruta peticiones dinámicas a Puma vía Unix socket
- Maneja SSL/TLS (en instalaciones con HTTPS)
- Rate limiting básico

En Docker: el puerto `80` del host se mapea al `80` del contenedor → Nginx.

### 🔴 Puma (GitLab Rails) — El Servidor Web

Puma es el servidor de aplicaciones Ruby que ejecuta el código Rails de GitLab. Reemplazó a Unicorn en GitLab 13.0.

```
Arquitectura de Puma:
  Master Process
    ├── Worker 1 (proceso independiente)
    │     ├── Thread 1 → maneja petición A
    │     └── Thread 2 → maneja petición B
    └── Worker 2
          ├── Thread 1 → maneja petición C
          └── Thread 2 → maneja petición D
```

- Cada worker tiene su propio espacio de memoria (Copy-on-Write para eficiencia)
- Los threads dentro de cada worker manejan peticiones concurrentes
- En Docker/bootcamp: 2 workers × 4 threads = 8 peticiones simultáneas

### 🟠 Gitaly — El Motor Git

Gitaly es el componente **más crítico para el rendimiento**. Es un servicio gRPC (Go) que ejecuta **todas** las operaciones Git. Antes de Gitaly, GitLab llamaba al binario `git` directamente, lo que no escalaba bien.

```
Gitaly almacena repos así:
/var/opt/gitlab/git-data/repositories/
  @hashed/
    ab/cd/
      abcdef1234567890...git  ← el repo real (dirección por hash, no por nombre)
```

- Todos los `git clone`, `git push`, `git log` pasan por Gitaly vía gRPC
- Soporta Gitaly Cluster para alta disponibilidad (con Praefect como proxy)
- Tiene su propio caché de objetos Git en memoria

### 🟡 PostgreSQL — La Base de Datos

PostgreSQL almacena **toda la metadata** de GitLab. Todo excepto el contenido real de los repositorios (eso es Gitaly):

```sql
-- Tablas principales de GitLab
projects              -- Proyectos (nombre, descripción, visibilidad, configuración)
users                 -- Usuarios (email, preferencias, tokens)
namespaces            -- Grupos y usuarios como espacios de nombres
issues                -- Issues con estado, asignados, labels
merge_requests        -- MRs con estado, aprobaciones, revisiones
ci_pipelines          -- Pipelines de CI/CD
ci_builds             -- Jobs individuales dentro de pipelines
ci_job_artifacts      -- Artifacts de los jobs
members               -- Permisos de usuario en proyectos/grupos
labels                -- Labels
milestones            -- Milestones
```

### 🔵 Redis — Caché y Colas

Redis maneja datos volátiles que necesitan velocidad extrema:

| Función | Por qué Redis y no PostgreSQL |
|---------|-------------------------------|
| Sesiones de usuario | Lectura/escritura en microsegundos |
| Caché de consultas | Evitar queries SQL repetitivas |
| Colas de Sidekiq | Sistema de mensajería para jobs async |
| Estado de Runners | Los runners hacen polling frecuente |
| Logs de CI en tiempo real | Buffer de streaming antes de persistir |
| Rate limiting | Contadores por IP/token que expiran solos |

### 🟢 Sidekiq — El Procesador de Tareas en Segundo Plano

Sidekiq ejecuta trabajos asíncronos para no bloquear las peticiones web:

```
Usuario hace push → Rails responde inmediatamente (200 OK)
                          ↓ (en background, Sidekiq hace):
                    1. Crear pipeline (CreatePipelineWorker)
                    2. Enviar email de notificación (NotificationWorker)
                    3. Actualizar estadísticas del proyecto (StatsWorker)
                    4. Procesar webhooks (WebhookWorker)
```

Ejemplos de jobs de Sidekiq:
- `CreatePipelineWorker` — Crear pipeline al hacer push
- `NotificationEmailWorker` — Enviar emails
- `WebhookWorker` — Disparar webhooks HTTP
- `ProjectExportWorker` — Exportar proyecto como ZIP
- `RepositoryGarbageCollectionWorker` — Limpiar objetos Git huérfanos
- `LdapSyncWorker` — Sincronizar usuarios con LDAP

### 🟣 GitLab Workhorse — El Optimizador de Tráfico

Workhorse es un proxy en Go que se sienta entre Nginx y Puma para manejar operaciones costosas sin bloquear los workers de Rails:

- Maneja uploads/downloads de archivos grandes (artifacts, LFS)
- Gestiona conexiones SSH para `git clone` vía HTTPS
- Sirve archivos de Gitaly directamente al cliente

---

## 🗺️ Diagrama de Arquitectura Completo

```
                            GitLab CE (Omnibus en Docker)
┌───────────────────────────────────────────────────────────────────┐
│                                                                   │
│  Internet/Browser                                                 │
│       │                                                           │
│       ▼ HTTP :80                                                  │
│  ┌─────────┐    assets    ┌──────────────────────────────────┐    │
│  │  Nginx  │──────────────▶  Filesystem (static assets)      │    │
│  │ (proxy) │              └──────────────────────────────────┘    │
│  └────┬────┘                                                      │
│       │ HTTP (unix socket)                                        │
│       ▼                                                           │
│  ┌────────────┐  gRPC    ┌─────────┐  disk   ┌───────────────┐   │
│  │ Workhorse  │──────────▶ Gitaly  │─────────▶ Git Repos     │   │
│  └─────┬──────┘          └─────────┘          │ /git-data/   │   │
│        │                                      └───────────────┘   │
│        │ HTTP (unix socket)                                       │
│        ▼                                                          │
│  ┌──────────────┐  SQL   ┌────────────┐                          │
│  │  Puma        │────────▶ PostgreSQL │                          │
│  │  (Rails app) │        └────────────┘                          │
│  └──────┬───────┘  Redis ┌────────────┐                          │
│         │────────────────▶   Redis    │                          │
│         │                └─────┬──────┘                          │
│         │                      │ queues                          │
│         │                ┌─────▼──────┐                          │
│         └── jobs ────────▶  Sidekiq   │                          │
│                          └────────────┘                          │
│                                                                   │
│  SSH :2224 (host) → :22 (contenedor)                             │
│       │                                                           │
│  ┌────▼──────────┐  gRPC  ┌─────────┐                            │
│  │  gitlab-shell │────────▶ Gitaly  │                            │
│  └───────────────┘        └─────────┘                            │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## 🌐 Flujo de una Petición HTTP

### Caso 1: Cargar el Dashboard de GitLab

```
1. Navegador → GET http://localhost/dashboard
   │
2. Nginx recibe la petición en puerto 80
   │ ¿Es un asset estático? No → pasar a Workhorse
   │
3. Workhorse recibe la petición
   │ ¿Necesita acceso a Git? No → pasar a Puma
   │
4. Puma (Rails) procesa:
   ├── Verifica sesión en Redis (¿usuario logueado?)
   ├── SELECT proyectos del usuario → PostgreSQL
   ├── SELECT issues asignados → PostgreSQL
   ├── Obtiene contadores de caché → Redis
   └── Renderiza HTML con los datos
   │
5. Puma → Workhorse → Nginx → Navegador (HTML renderizado)
```

### Caso 2: Navegar el Repositorio de un Proyecto

```
1. Navegador → GET http://localhost/root/mi-proyecto/-/tree/main
   │
2. Nginx → Workhorse
   │
3. Workhorse detecta: necesita datos de Git
   │
4. Workhorse → Gitaly (gRPC: GetTreeEntries)
   │
5. Gitaly lee el repositorio en disco, devuelve árbol de archivos
   │
6. Workhorse + Puma renderizan la vista con el árbol
   │
7. Respuesta al navegador
```

---

## 🔀 Flujo de un git push

```
Developer$ git push origin main
    │
    │ SSH → localhost:2224 (host) → localhost:22 (contenedor)
    ▼
[gitlab-shell] verifica que el usuario tiene acceso al repo (consulta Rails API)
    │
    │ gRPC
    ▼
[Gitaly] recibe los objetos Git y los escribe en disco
    │
    │ hook post-receive → notifica a Rails
    ▼
[Rails/Puma] recibe la notificación
    │
    │ Encola job en Redis
    ▼
[Sidekiq] procesa en background:
    ├── CreatePipelineWorker → crea pipeline en PostgreSQL
    ├── NotificationWorker → encola emails
    └── WebhookWorker → dispara webhooks configurados
    │
    ▼
[GitLab Runner] hace polling a la API de GitLab
→ Descarga el job
→ Lo ejecuta
→ Reporta resultado (pass/fail) a PostgreSQL vía API
```

---

## 🛠️ Comandos `gitlab-ctl` para Diagnóstico

`gitlab-ctl` es la herramienta de gestión de Omnibus GitLab. Desde Docker:

```bash
# ¿QUÉ VAMOS A HACER?: Ver el estado de todos los servicios internos de GitLab
# ¿POR QUÉ LO HACEMOS?: Para verificar que todos los componentes están corriendo
# ¿PARA QUÉ SIRVE?: Primer paso para diagnosticar cualquier problema
docker compose exec gitlab gitlab-ctl status

# Ver los logs de un componente específico (Ctrl+C para salir)
docker compose exec gitlab gitlab-ctl tail nginx
docker compose exec gitlab gitlab-ctl tail postgresql
docker compose exec gitlab gitlab-ctl tail gitaly
docker compose exec gitlab gitlab-ctl tail sidekiq
docker compose exec gitlab gitlab-ctl tail puma

# Reiniciar un componente específico
docker compose exec gitlab gitlab-ctl restart nginx
docker compose exec gitlab gitlab-ctl restart sidekiq

# Probar que PostgreSQL responde correctamente
docker compose exec gitlab gitlab-psql -c "SELECT version();"

# Probar que Redis responde
docker compose exec gitlab gitlab-redis-cli PING
# Respuesta esperada: PONG

# Ver versión de GitLab y estado general
docker compose exec gitlab gitlab-rake gitlab:env:info
```

---

## 🔍 Comandos Docker para Monitoreo

```bash
# ¿QUÉ VAMOS A HACER?: Ver uso de CPU, memoria y red del contenedor GitLab
# ¿POR QUÉ LO HACEMOS?: Para detectar si GitLab está saturado o si falta RAM
# ¿PARA QUÉ SIRVE?: Solucionar problemas de rendimiento (GitLab requiere mínimo 4 GB)
docker stats gitlab

# Ver todos los procesos internos del contenedor
docker compose exec gitlab ps aux

# Métricas de salud desde la consola Rails
docker compose exec gitlab gitlab-rails runner "puts Project.count"
docker compose exec gitlab gitlab-rails runner "puts User.count"
docker compose exec gitlab gitlab-rails runner "puts Sidekiq::Queue.new.size"

# Verificación completa de la instalación
docker compose exec gitlab gitlab-rake gitlab:check
```

---

## ⚙️ Tabla de Comunicación entre Componentes

| Origen → Destino | Protocolo | Puerto interno | Nota |
|-----------------|-----------|----------------|------|
| Host → Nginx | HTTP | 80 (host:80 → container:80) | Acceso web |
| Host → SSH | SSH | 2224 (host:2224 → container:22) | `git clone` vía SSH |
| Nginx → Workhorse | HTTP | Unix socket | Interno |
| Workhorse → Puma | HTTP | Unix socket | Interno |
| Puma → PostgreSQL | TCP (libpq) | 5432 | Interno |
| Puma → Redis | TCP (RESP) | 6379 | Interno |
| Puma/Workhorse → Gitaly | gRPC | 8075 | Interno |
| Sidekiq → Redis | TCP (RESP) | 6379 | Colas de jobs |
| GitLab Runner → API | HTTP | 80 (host) | Polling de jobs |

---

## 🤔 Preguntas de Reflexión

1. ¿Por qué existe Gitaly como servicio separado en lugar de que Rails llame directamente al binario `git`? ¿Qué ventajas ofrece esta arquitectura?
2. Si GitLab está muy lento al cargar páginas, ¿qué componente investigarías primero y con qué comando?
3. ¿Por qué los jobs de CI/CD son procesados por Sidekiq y no directamente por Rails en la misma petición HTTP?
4. Cuando haces `git push`, ¿cuántos componentes diferentes de GitLab participan en el proceso? Lista cada uno con su rol.
5. ¿Qué pasaría si Redis se cayera? ¿Qué funcionalidades de GitLab se verían afectadas primero?

---

## 📚 Recursos Adicionales

- [GitLab Architecture Overview](https://docs.gitlab.com/ee/development/architecture.html) — Documentación oficial completa
- [Gitaly Documentation](https://docs.gitlab.com/ee/administration/gitaly/) — Detalles de configuración
- [Sidekiq at GitLab](https://docs.gitlab.com/ee/development/sidekiq/) — Guía de desarrollo para workers
- [GitLab Performance](https://docs.gitlab.com/ee/administration/monitoring/) — Monitoreo y ajuste de rendimiento

---

## ➡️ Siguiente Lección

[05 — Primeros Pasos en GitLab CE →](./05-primeros-pasos-gitlab.md)

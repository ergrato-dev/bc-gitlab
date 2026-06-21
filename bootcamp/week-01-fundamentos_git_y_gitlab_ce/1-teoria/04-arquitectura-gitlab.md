# 04 — Arquitectura Interna de GitLab CE

## Objetivos

- Comprender la comunicacion entre componentes de GitLab
- Entender el flujo de una peticion HTTP completa
- Conocer cada servicio interno y su proposito
- Diagnosticar problemas comunes usando este conocimiento

## Componentes en Detalle

### Puma (Web Server)

Servidor de aplicaciones Ruby que maneja las peticiones HTTP. Reemplazo de Unicorn desde GitLab 13.0.

```yaml
# Configuracion en gitlab.rb
puma['worker_processes'] = 2
puma['min_threads'] = 1
puma['max_threads'] = 4
```

- Modelo multi-proceso + multi-hilo para concurrencia
- Cada worker es un proceso independiente con memoria compartida (Copy-on-Write)
- Threads dentro de cada worker manejan peticiones simultaneas

### Gitaly

Servicio gRPC que ejecuta **todas** las operaciones Git. Es el componente mas critico para el rendimiento de operaciones Git.

```protobuf
// Gitaly expone operaciones via gRPC
service SmartHTTPService {
  rpc InfoRefsUploadPack(InfoRefsRequest) returns (stream InfoRefsResponse);
  rpc PostUploadPack(stream PostUploadPackRequest) returns (stream PostUploadPackResponse);
}
```

- Almacena repositorios en disco con hashing de directorios
- Soporta Gitaly Cluster para HA (con Praefect como proxy)
- Cachea objetos Git en memoria para acelerar clones y fetches

### PostgreSQL

Base de datos que almacena **toda la metadata** de GitLab:

- Usuarios, grupos, membresias
- Proyectos, configuracion, variables CI/CD
- Issues, Merge Requests, comentarios
- Pipelines, jobs, artifacts, deployments

**No almacena** el contenido de los repositorios (eso es Gitaly).

```sql
-- Ejemplo de tablas principales
SELECT * FROM projects WHERE id = 1;
SELECT * FROM users WHERE username = 'root';
SELECT * FROM ci_pipelines WHERE project_id = 1 ORDER BY id DESC LIMIT 10;
```

### Redis

Usado para datos volatiles de alta velocidad:

| Funcion | Instancia Redis |
|---------|----------------|
| Cache | Redis (cache) |
| Colas Sidekiq | Redis (queues) |
| Sesiones | Redis (sessions) |
| Rate Limiting | Redis (rate limiting) |
| Estado de Runners | Redis (shared state) |
| Trace chunks (logs CI) | Redis (trace chunks) |

En produccion se recomiendan instancias Redis separadas por responsabilidad.

### Sidekiq

Procesador de trabajos asincronos. Usa Redis como backend de colas.

Ejemplos de jobs:
- Enviar email de notificacion
- Crear pipeline cuando se hace push
- Procesar webhooks
- Exportar proyecto como ZIP
- Actualizar estadisticas del proyecto
- Sincronizar permisos LDAP/SAML

## Flujo Completo de una Peticion

### Clone de un Repositorio

```
1. Cliente → git clone git@localhost:root/proyecto.git
2. SSH → GitLab Shell → Gitaly (gRPC: InfoRefs)
3. Gitaly lee repositorio del disco
4. Gitaly → GitLab Shell → Cliente (stream de objetos Git)
```

### Carga de una Pagina Web (Dashboard)

```
1. Navegador → GET http://localhost/dashboard
2. Nginx → Puma (HTTP en Unix socket)
3. Puma consulta:
   ├── Redis: ¿sesion valida?
   ├── PostgreSQL: SELECT proyectos del usuario
   └── Redis: cache de contadores, avatares
4. Puma renderiza HTML (ERB/Haml)
5. Puma → Nginx → Navegador
```

### Ejecucion de un Pipeline

```
1. Usuario hace git push
2. GitLab Shell → Gitaly (guardar objetos)
3. Gitaly notifica a GitLab Rails via hook interno
4. Rails → Sidekiq (job: CreatePipelineWorker)
5. Sidekiq:
   ├── PostgreSQL: leer .gitlab-ci.yml + variables
   ├── Redis: encolar jobs para el Runner
6. GitLab Runner hace polling a GitLab API
7. Runner ejecuta jobs y reporta resultado
```

## Comunicacion entre Componentes

| Origen → Destino | Protocolo | Puerto | En Docker |
|-----------------|-----------|--------|-----------|
| Nginx → Puma | HTTP / Unix socket | 8080 | Interno |
| Puma → PostgreSQL | TCP (libpq) | 5432 | Interno |
| Puma → Redis | TCP (RESP) | 6379 | Interno |
| Puma → Gitaly | gRPC | 8075 | Interno |
| Sidekiq → Redis | TCP (RESP) | 6379 | Interno |
| Sidekiq → PostgreSQL | TCP (libpq) | 5432 | Interno |
| Runner → GitLab API | HTTP | 80/443 | `gitlab:80` |

## Diagnosticar Problemas con Docker

```bash
# Ver estado de todos los servicios internos
docker compose exec gitlab gitlab-ctl status

# Ver logs de un componente especifico
docker compose exec gitlab gitlab-ctl tail nginx
docker compose exec gitlab gitlab-ctl tail postgresql
docker compose exec gitlab gitlab-ctl tail gitaly

# Probar conexion a PostgreSQL desde dentro
docker compose exec gitlab gitlab-psql -c "SELECT 1"

# Probar conexion a Redis desde dentro
docker compose exec gitlab gitlab-redis-cli PING

# Ver procesos en el contenedor
docker compose exec gitlab ps aux

# Uso de recursos
docker stats gitlab
```

## Metricas Clave de Salud

```bash
# Numero de proyectos
docker compose exec gitlab gitlab-rails runner "puts Project.count"

# Numero de usuarios
docker compose exec gitlab gitlab-rails runner "puts User.count"

# Jobs en cola de Sidekiq
docker compose exec gitlab gitlab-rails runner "puts Sidekiq::Queue.new.size"

# Version de GitLab
docker compose exec gitlab gitlab-rake gitlab:env:info
```

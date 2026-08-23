# Omnibus y `gitlab.rb`

> Un solo archivo configura los siete procesos. Y no se aplica hasta que ejecutas `reconfigure`.

## 🎯 Objetivos

- Explicar qué es Omnibus y por qué GitLab se distribuye así
- Escribir opciones de `gitlab.rb` con el prefijo correcto
- Entender el ciclo `gitlab.rb` → `reconfigure` → configuración efectiva
- Saber por qué editar los archivos de configuración generados no sirve de nada

---

## 1. Qué problema resuelve

GitLab necesita PostgreSQL, Redis, Nginx, Ruby, Go y una docena de bibliotecas del sistema, cada uno con su versión concreta. Instalarlos por separado significa que la versión de PostgreSQL de tu distribución decide si GitLab arranca, y que actualizar el sistema puede romper la aplicación.

**Omnibus** resuelve eso metiendo GitLab y **todas** sus dependencias en un solo paquete, instalado bajo `/opt/gitlab`, aislado del sistema operativo. El PostgreSQL que usa GitLab no es el de tu máquina: es el suyo.

A cambio de ese aislamiento, la configuración deja de estar donde esperarías. No editas `postgresql.conf` ni `nginx.conf`: editas **un solo archivo** que los genera todos.

---

## 2. Un archivo para gobernarlos a todos

```
/etc/gitlab/gitlab.rb
```

Es un archivo Ruby, aunque en la práctica se escribe como una lista de asignaciones. Cada opción lleva un **prefijo** que dice a qué componente pertenece:

```ruby
external_url 'http://localhost:8888'

nginx['listen_port'] = 8888
postgresql['shared_buffers'] = '256MB'
redis['maxmemory'] = '256mb'
puma['worker_processes'] = 2
sidekiq['max_concurrency'] = 10
gitaly['configuration'] = { ... }
gitlab_rails['lfs_enabled'] = true
```

### Los prefijos que importan

| Prefijo | Configura | Ejemplo |
|---|---|---|
| `gitlab_rails[...]` | La aplicación: features, correo, backup, integraciones | `gitlab_rails['lfs_enabled'] = true` |
| `nginx[...]` | El servidor web | `nginx['listen_port'] = 8888` |
| `postgresql[...]` | La base de datos | `postgresql['shared_buffers'] = '256MB'` |
| `redis[...]` | Caché y colas | `redis['maxmemory'] = '256mb'` |
| `puma[...]` | El servidor de aplicación | `puma['worker_processes'] = 2` |
| `sidekiq[...]` | Los trabajos en segundo plano | `sidekiq['max_concurrency'] = 10` |
| `gitaly[...]` | El servicio de Git | `gitaly['configuration']` |
| `registry[...]` | El Container Registry | `registry['enable'] = true` |
| `gitlab_pages[...]` | Pages | `gitlab_pages['enable'] = true` |
| `prometheus_monitoring[...]` | Los exportadores de métricas | `prometheus_monitoring['enable'] = false` |

**Equivocarse de prefijo es el error más común y el más silencioso**: `gitlab_rails['listen_port']` no da error, simplemente no hace nada, y te pasas media hora buscando por qué el puerto no cambia.

### `external_url`, la opción especial

Es la única sin prefijo, y la más importante:

```ruby
external_url 'http://localhost:8888'
```

De ella se derivan automáticamente el puerto en que escucha Nginx, las URL que GitLab pone en los correos, las URL de clonado que muestra la interfaz y la configuración de las cookies. Cambiarla mal deja la instancia accesible pero generando enlaces rotos.

---

## 3. El ciclo: escribir, reconfigurar, aplicar

Esto es lo que más cuesta interiorizar:

**GitLab no lee `gitlab.rb` en caliente. Nunca.**

```
gitlab.rb  ──gitlab-ctl reconfigure──▶  archivos de configuración reales  ──▶  procesos reiniciados
```

`gitlab-ctl reconfigure` ejecuta Chef, que:

1. Lee `/etc/gitlab/gitlab.rb`
2. Genera los archivos de configuración reales de cada componente
3. Ajusta permisos y directorios
4. Reinicia los procesos cuya configuración cambió

```bash
docker compose exec gitlab gitlab-ctl reconfigure
```

Tarda entre 1 y 3 minutos. Es idempotente: ejecutarlo dos veces no rompe nada.

### Los archivos generados: mirar sí, editar no

`reconfigure` escribe, entre otros:

| Archivo generado | De dónde sale |
|---|---|
| `/var/opt/gitlab/gitlab-rails/etc/gitlab.yml` | De las opciones `gitlab_rails[...]` |
| `/var/opt/gitlab/nginx/conf/gitlab-http.conf` | De `nginx[...]` y `external_url` |
| `/var/opt/gitlab/postgresql/data/postgresql.conf` | De `postgresql[...]` |
| `/var/opt/gitlab/gitaly/config.toml` | De `gitaly[...]` |

> [!WARNING]
> **Editar cualquiera de estos archivos es tirar el trabajo a la basura.** El siguiente `reconfigure` los regenera desde `gitlab.rb` y tu cambio desaparece. Y `reconfigure` se ejecuta solo en cada arranque del contenedor.
>
> Si necesitas algo que `gitlab.rb` no expone, la salida son las opciones de escape (`nginx['custom_gitlab_server_config']`), no editar la salida.

Sí es muy útil **leerlos** para comprobar qué configuración quedó efectivamente aplicada:

```bash
docker compose exec gitlab grep -A3 'listen' /var/opt/gitlab/nginx/conf/gitlab-http.conf
```

---

## 4. Los otros comandos de `gitlab-ctl`

| Comando | Qué hace | Cuándo |
|---|---|---|
| `gitlab-ctl reconfigure` | Regenera la configuración y reinicia lo necesario | Tras tocar `gitlab.rb` |
| `gitlab-ctl restart` | Reinicia todo sin regenerar nada | Rara vez; casi siempre quieres reiniciar un solo proceso |
| `gitlab-ctl restart <proceso>` | Reinicia solo ese | Lo habitual |
| `gitlab-ctl status` | Estado de todos los procesos | Lo primero ante un fallo |
| `gitlab-ctl tail <proceso>` | Sigue sus logs | Diagnóstico |
| `gitlab-ctl show-config` | Muestra la configuración que **generaría**, sin aplicarla | Antes de un cambio arriesgado |

`show-config` es el que menos se conoce y el que más disgustos evita: te enseña qué va a hacer `reconfigure` **antes** de hacerlo.

---

## 5. En Docker, `gitlab.rb` se escribe desde fuera

Aquí hay un giro importante para el laboratorio. En una instalación normal editas `/etc/gitlab/gitlab.rb` a mano. En Docker, la imagen oficial lee una variable de entorno:

```yaml
environment:
  GITLAB_OMNIBUS_CONFIG: |
    external_url 'http://localhost:8888'
    nginx['listen_port'] = 8888
    puma['worker_processes'] = 2
```

Todo lo que pongas ahí se inyecta en `gitlab.rb` **en cada arranque del contenedor**, y `reconfigure` se ejecuta automáticamente.

Consecuencia práctica, y trampa clásica:

> [!IMPORTANT]
> Si editas `/etc/gitlab/gitlab.rb` a mano dentro del contenedor y luego reinicias, `GITLAB_OMNIBUS_CONFIG` vuelve a imponerse y **tu cambio desaparece**.
>
> En este laboratorio, la configuración permanente se toca en `docker-compose.yml`. Editar `gitlab.rb` dentro del contenedor sirve para probar algo rápido, sabiendo que no sobrevive al reinicio.

El detalle: `GITLAB_OMNIBUS_CONFIG` **añade** al principio de `gitlab.rb`, no lo sustituye entero. Lo que escribas a mano sigue ahí debajo, pero lo de la variable gana porque se evalúa después.

---

## 6. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Editar `gitlab.yml`, `nginx.conf` o `postgresql.conf` | El siguiente `reconfigure` los regenera y borra tu cambio | Tocar `gitlab.rb`, o el compose en este laboratorio |
| Cambiar `gitlab.rb` y no reconfigurar | No pasa nada y crees que la opción no funciona | `gitlab-ctl reconfigure`, siempre |
| Equivocar el prefijo | No da error, simplemente se ignora | Comprobar el prefijo en la documentación de Omnibus |
| Editar `gitlab.rb` dentro del contenedor esperando permanencia | `GITLAB_OMNIBUS_CONFIG` lo pisa en el siguiente arranque | Cambiarlo en `docker-compose.yml` |
| `gitlab-ctl restart` para todo | Cinco minutos de caída innecesarios | `restart <proceso>`, o `reconfigure` si tocaste la configuración |
| Cambiar `external_url` sin pensar | La instancia responde pero genera enlaces rotos en correos y clonado | Cambiarla junto con el puerto publicado, y comprobar los enlaces después |

---

## 7. Trucos

**Ver la configuración efectiva, no la que creíste escribir:**

```bash
docker compose exec gitlab cat /var/opt/gitlab/gitlab-rails/etc/gitlab.yml | head -40
```

Es la fuente de verdad de lo que la aplicación está usando de verdad.

**Ensayar un cambio sin aplicarlo:**

```bash
docker compose exec gitlab gitlab-ctl show-config | less
```

**Ver el `gitlab.rb` que quedó tras inyectar la variable de entorno:**

```bash
docker compose exec gitlab head -30 /etc/gitlab/gitlab.rb
```

Confirma que lo que pusiste en el compose llegó donde tenía que llegar.

**Cuándo basta con `restart` y cuándo hace falta `reconfigure`:** si tocaste `gitlab.rb` o el compose, `reconfigure`. Si solo quieres despertar un proceso colgado, `restart <proceso>`. En la duda, `reconfigure`: es más lento pero nunca se queda corto.

---

## 📚 Recursos Adicionales

- [Configuración de Omnibus](https://docs.gitlab.com/omnibus/settings/) — el índice de todas las opciones por prefijo. Tenlo a mano toda la semana
- [Plantilla completa de `gitlab.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-config-template/gitlab.rb.template) — miles de líneas, todas comentadas. La referencia definitiva de qué existe
- [Comandos de `gitlab-ctl`](https://docs.gitlab.com/omnibus/maintenance/) — el listado completo
- [Imagen de Docker de GitLab](https://docs.gitlab.com/ee/install/docker/) — cómo se usa `GITLAB_OMNIBUS_CONFIG`

---

## ✅ Checklist de Verificación

- [ ] Sabes qué prefijo usar para cambiar el puerto, la memoria de PostgreSQL y los workers de Puma
- [ ] Puedes explicar por qué editar `gitlab.yml` no sirve de nada
- [ ] Sabes dónde mirar la configuración **efectiva** de tu instancia
- [ ] Entiendes por qué en este laboratorio la configuración vive en `docker-compose.yml`
- [ ] Sabes cuándo basta `restart` y cuándo hace falta `reconfigure`

---

| Anterior | Siguiente |
|---|---|
| [← 02 — Los procesos por dentro](02-arquitectura-los-procesos.md) | [04 — GitLab en Docker →](04-gitlab-en-docker.md) |

[← Volver a la Semana 01](../README.md)

# 05 — Solucion de Problemas Comunes

## Objetivos

- Diagnosticar problemas frecuentes en instalaciones de GitLab CE
- Interpretar logs para identificar errores
- Aplicar soluciones a errores comunes

## Problema 1: Error 502 — GitLab no responde

**Sintoma:** El navegador muestra "502 Bad Gateway" o "GitLab is taking too much time to respond".

**Causas probables:**
- GitLab aun esta iniciando (primer inicio puede tomar 5-10 min)
- Memoria RAM insuficiente (< 4 GB)
- Proceso Puma no esta corriendo

**Diagnostico:**
```bash
# Ver logs de GitLab
docker compose logs gitlab --tail 100

# Ver estado de servicios internos
docker compose exec gitlab gitlab-ctl status

# Ver consumo de recursos
docker stats gitlab-ce
```

**Solucion:**
- Si esta iniciando: esperar. Monitorear con `docker compose logs -f gitlab`
- Si falta RAM: reducir workers de Puma y Sidekiq en `gitlab.rb`:
  ```ruby
  puma['worker_processes'] = 1
  sidekiq['max_concurrency'] = 5
  ```
- Reiniciar servicios: `docker compose exec gitlab gitlab-ctl restart`

## Problema 2: Error 500 — Internal Server Error

**Diagnostico:**
```bash
docker compose exec gitlab gitlab-ctl tail
docker compose exec gitlab gitlab-rake gitlab:check
```

**Causas comunes:**
- Permisos incorrectos en volumenes
- Corrupcion de base de datos
- Migraciones pendientes

## Problema 3: Memoria RAM Agotada

**Sintoma:** El sistema se vuelve lento, OOM killer mata procesos.

**Diagnostico:**
```bash
free -h
docker stats --no-stream
```

**Solucion:**
- Agregar swap si no existe:
  ```bash
  sudo fallocate -l 4G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  ```
- Reducir configuracion en `GITLAB_OMNIBUS_CONFIG`:
  ```ruby
  postgresql['shared_buffers'] = '256MB'
  puma['worker_processes'] = 1
  sidekiq['max_concurrency'] = 5
  prometheus_monitoring['enable'] = false
  ```

## Problema 4: Volumenes no Persisten

**Diagnostico:**
```bash
docker compose down  # bajar servicios
docker compose up -d # levantar de nuevo
# Verificar si datos persisten (proyectos, usuarios, etc.)
```

**Solucion:**
Asegurar que los volumenes esten nombrados en `docker-compose.yml` (no usar bind mounts anonimos).

## Problema 5: SSH no Funciona

**Sintoma:** `git clone git@localhost:...` no se conecta.

**Causa:** Puerto SSH mapeado a 2224 en el host, pero el comando `git clone` usa puerto 22 por defecto.

**Solucion:**
Crear configuracion SSH en `~/.ssh/config`:
```
Host gitlab.local
  HostName localhost
  Port 2224
  User git
  IdentityFile ~/.ssh/id_ed25519
```

Luego: `git clone git@gitlab.local:root/proyecto.git`

## Comandos de Diagnostico Rapido

```bash
# Estado general de GitLab
docker compose exec gitlab gitlab-ctl status

# Verificar configuracion
docker compose exec gitlab gitlab-rake gitlab:check

# Reinicio seguro
docker compose exec gitlab gitlab-ctl restart

# Reconfigurar (aplica cambios de gitlab.rb)
docker compose exec gitlab gitlab-ctl reconfigure
```

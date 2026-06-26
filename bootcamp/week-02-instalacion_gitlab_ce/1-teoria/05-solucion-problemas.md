# 📖 05 — Solución de Problemas en GitLab CE con Docker

## 🎯 Objetivos de aprendizaje

- ✅ Aplicar un checklist de diagnóstico sistemático antes de buscar en Google
- ✅ Identificar y resolver el error 502 (el más común en el primer inicio)
- ✅ Solucionar problemas de RAM insuficiente sin reinstalar
- ✅ Configurar correctamente SSH en el puerto 2224
- ✅ Depurar servicios internos caídos con `gitlab-ctl`
- ✅ Recuperarse de un restore fallido por secrets incompatibles

---

## 🤔 La analogía del médico

**El troubleshooting es como diagnosticar a un paciente: síntomas → diagnóstico → tratamiento.**

Un buen médico no receta antibióticos al primer síntoma sin saber cuál es la infección. Primero hace preguntas, luego mide temperatura y presión, después solicita análisis. Solo entonces prescribe tratamiento. En GitLab es igual: antes de reiniciar todo desesperadamente, hay que medir el estado actual.

---

## ✅ Checklist de diagnóstico rápido

Antes de ver el problema específico, ejecuta estos 6 comandos en orden. La respuesta de cada uno te dirigirá al problema correcto.

```bash
# DIAGNÓSTICO 1: ¿El contenedor está corriendo?
docker compose ps

# DIAGNÓSTICO 2: ¿GitLab responde HTTP?
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost

# DIAGNÓSTICO 3: ¿Los servicios internos están activos?
docker compose exec gitlab gitlab-ctl status

# DIAGNÓSTICO 4: ¿Hay suficiente RAM?
docker stats --no-stream gitlab

# DIAGNÓSTICO 5: ¿Qué dicen los logs recientes?
docker compose logs gitlab --tail 30

# DIAGNÓSTICO 6: ¿Los puertos están libres en el host?
ss -tuln | grep -E ':80 |:443 |:2224 '
```

---

## 🚨 Problema 1: Error 502 Bad Gateway

**Síntoma:** El navegador muestra "502 Bad Gateway" o "GitLab is taking too much time to respond".

Este es el error más común y, a la vez, el más frecuentemente mal diagnosticado. Tiene tres causas completamente distintas con tratamientos diferentes.

### Causa A: GitLab aún está iniciando (causa más común)

**Diagnóstico:**
```bash
docker compose logs gitlab --tail 20
# Busca líneas como:
# "Reconfigure..." (está configurando)
# "Starting postgresql" (iniciando servicios)
# NO ves "GitLab is ready" aún
```

**Tratamiento:**
```bash
# ¿QUÉ HACE?: Sigue los logs hasta ver que GitLab está listo
# ¿POR QUÉ?: El primer inicio tarda 5-10 minutos (migraciones de BD, compilación de assets)
# ¿PARA QUÉ?: Esperar pacientemente sin reiniciar (reiniciarlo alarga el proceso)
docker compose logs -f gitlab
# Espera el mensaje: "gitlab Reconfigured!" o hasta que el healthcheck diga "healthy"
```

> ⏱️ El tiempo de arranque en primera instalación: **5-10 minutos**. En reinicios posteriores: **1-3 minutos**.

### Causa B: RAM insuficiente — OOM Killer actuando

**Diagnóstico:**
```bash
# Buscar "OOM" en los logs del sistema
docker compose logs gitlab | grep -i "oom\|killed\|memory"

# Ver uso de RAM en tiempo real
docker stats gitlab --no-stream
# Si RAM usage > 90%, este es el problema
```

**Tratamiento:**
```bash
# Agregar en GITLAB_OMNIBUS_CONFIG para reducir uso de RAM:
# puma['worker_processes'] = 1      # default: 2
# sidekiq['max_concurrency'] = 5    # default: 25
# postgresql['shared_buffers'] = '128MB'  # default: 256MB

# Después de editar .env o docker-compose.yml:
# ¿QUÉ HACE?: Recrea el contenedor con la nueva configuración
# ¿POR QUÉ?: Los cambios de env vars solo aplican al crear el contenedor, no al reiniciarlo
# ¿PARA QUÉ?: Que GitLab use menos RAM y no sea matado por el kernel
docker compose up -d --force-recreate gitlab
```

### Causa C: Puma caído o bloqueado

**Diagnóstico:**
```bash
docker compose exec gitlab gitlab-ctl status puma
# Si muestra: "down: puma: 5s" → Puma está caído
```

**Tratamiento:**
```bash
# ¿QUÉ HACE?: Reinicia solo el servicio Puma dentro del contenedor
# ¿POR QUÉ?: Reiniciar Puma es mucho más rápido que reiniciar todo GitLab
# ¿PARA QUÉ?: Recuperar el acceso web sin interrumpir la base de datos ni Sidekiq
docker compose exec gitlab gitlab-ctl restart puma

# Verificar que arrancó
docker compose exec gitlab gitlab-ctl status puma
# Output esperado: run: puma: (pid XXXX) 5s; run: log/...
```

---

## 🚨 Problema 2: GitLab muy lento o se congela (RAM/OOM)

**Síntoma:** Las páginas tardan 30+ segundos en cargar, el servidor se vuelve inutilizable, el contenedor se reinicia solo.

**Diagnóstico:**
```bash
# ¿QUÉ HACE?: Muestra el uso de CPU y RAM de los contenedores en tiempo real
# ¿POR QUÉ?: GitLab puede estar consumiendo toda la RAM disponible
# ¿PARA QUÉ?: Confirmar que el problema es de recursos antes de cambiar config
docker stats --no-stream

# Verificar si hay swap disponible
docker compose exec gitlab free -h
```

**Tratamiento — Reducir consumo de RAM:**

```yaml
# En GITLAB_OMNIBUS_CONFIG (agregar al docker-compose.yml o .env):
puma['worker_processes'] = 1         # Un solo proceso web
sidekiq['max_concurrency'] = 5       # Máximo 5 trabajos paralelos
postgresql['shared_buffers'] = '128MB'
prometheus_monitoring['enable'] = false  # Deshabilitar si no usas monitoreo
```

**Tratamiento alternativo — Agregar swap al host:**

```bash
# ¿QUÉ HACE?: Crea un archivo de swap de 4 GB en el host
# ¿POR QUÉ?: El swap actúa como RAM extra (más lento, pero evita que maten procesos)
# ¿PARA QUÉ?: Que GitLab no sea matado por el OOM Killer cuando se quede sin RAM
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Hacerlo permanente (sobrevive reinicios del host)
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

---

## 🚨 Problema 3: SSH no conecta (puerto 2224)

**Síntoma:** `git clone git@localhost:root/proyecto.git` falla con "Connection refused" o "Permission denied".

**Diagnóstico:**
```bash
# Verificar que el puerto 2224 está escuchando
ss -tuln | grep 2224
# Output esperado: tcp  LISTEN  0.0.0.0:2224

# Intentar conexión SSH directa con verbose
ssh -v -p 2224 git@localhost
```

**Causa A: Puerto incorrecto en el comando de clonado**

GitLab muestra en la UI el comando correcto, pero a veces se copia el `git clone git@localhost:...` sin el puerto. SSH por defecto usa el puerto 22, no el 2224.

**Tratamiento:**

Crea (o edita) `~/.ssh/config` en tu máquina local:

```
# ¿QUÉ HACE?: Define un alias "gitlab-local" que apunta a localhost:2224
# ¿POR QUÉ?: Permite usar git@gitlab-local:... sin especificar el puerto en cada comando
# ¿PARA QUÉ?: Experiencia de clonado idéntica a producción sin cambiar el puerto
Host gitlab-local
  HostName localhost
  Port 2224
  User git
  IdentityFile ~/.ssh/id_ed25519
```

Con esta configuración:
```bash
# Ahora puedes clonar así (sin especificar puerto):
git clone git@gitlab-local:root/mi-proyecto.git
```

**Causa B: Clave SSH no registrada en GitLab**

```bash
# ¿QUÉ HACE?: Muestra tu clave pública para copiarla en GitLab
# ¿POR QUÉ?: GitLab necesita conocer tu clave pública para autenticarte
# ¿PARA QUÉ?: Pegar esta clave en GitLab → User Settings → SSH Keys
cat ~/.ssh/id_ed25519.pub
```

---

## 🚨 Problema 4: Los datos no persisten entre reinicios

**Síntoma:** Después de `docker compose down` y `docker compose up`, los proyectos o usuarios creados han desaparecido.

**Diagnóstico:**
```bash
# Verificar que los volúmenes nombrados existen
docker volume ls | grep bc-gitlab
# Si no aparecen o hay nombres tipo "abc123_gitlab-data" (sin "bc-gitlab"), el problema está aquí

# Verificar que el docker-compose.yml tiene los nombres explícitos
grep -A 3 "^volumes:" docker-compose.yml
```

**Causa más común:** El `docker compose down -v` (con el flag `-v`) elimina los volúmenes. Sin el `-v`, los datos persisten.

**Tratamiento:**

Si ya perdiste los datos y tienes backup:
```bash
# Ver la sección de restore en la lección 04
docker compose exec gitlab gitlab-backup restore BACKUP=TIMESTAMP
```

Si no tienes backup, aprende la lección y configura backups automáticos.

**Prevención:**
```bash
# ¿QUÉ HACE?: Para GitLab sin eliminar volúmenes
# ¿POR QUÉ?: -v solo se necesita cuando quieres resetear completamente
# ¿PARA QUÉ?: Apagar y encender GitLab de forma segura preservando todos los datos
docker compose down   # SIN -v
docker compose up -d
```

---

## 🚨 Problema 5: `gitlab-ctl status` muestra servicios "down"

**Síntoma:** Algún servicio interno de GitLab aparece como "down" en `gitlab-ctl status`.

```
run: puma: (pid 1234) 120s; run: log/...
down: postgresql: 5s, normally up; run: log/...   ← PROBLEMA
run: sidekiq: (pid 5678) 120s; run: log/...
```

**Diagnóstico:**
```bash
# ¿QUÉ HACE?: Lee los logs de un servicio específico
# ¿POR QUÉ?: El log explica por qué cayó el servicio
# ¿PARA QUÉ?: Identificar si es un error de configuración, permisos o recursos
docker compose exec gitlab gitlab-ctl tail postgresql
# (Reemplaza 'postgresql' por el servicio caído)
```

**Tratamiento:**
```bash
# ¿QUÉ HACE?: Intenta reiniciar el servicio específico
# ¿POR QUÉ?: A veces los servicios caen por un error transitorio y arrancan bien
# ¿PARA QUÉ?: Recuperar el servicio sin afectar al resto
docker compose exec gitlab gitlab-ctl restart postgresql

# Si persiste, reiniciar todos los servicios:
# ¿QUÉ HACE?: Para y arranca todos los servicios internos de GitLab
# ¿POR QUÉ?: Puede haber dependencias entre servicios que requieren un reinicio conjunto
# ¿PARA QUÉ?: Restablecer el estado completo cuando hay múltiples servicios caídos
docker compose exec gitlab gitlab-ctl restart
```

---

## 🚨 Problema 6: `gitlab-backup restore` falla

**Síntoma A:** El restore falla con mensaje sobre secrets.

```
Error: The backup you're trying to restore was created with a different secret key
```

**Tratamiento:** Ver sección "Si el restore falla por secrets incompatibles" en la lección 04.

**Síntoma B:** El restore falla con permisos denegados.

```bash
# ¿QUÉ HACE?: Corrige los permisos del archivo de backup
# ¿POR QUÉ?: gitlab-backup requiere que el archivo sea del usuario 'git'
# ¿PARA QUÉ?: Permitir que el proceso de restore lea el archivo
docker compose exec gitlab chown git:git /var/opt/gitlab/backups/NOMBRE_DEL_BACKUP.tar
```

**Síntoma C:** Error de espacio en disco durante el restore.

```bash
# ¿QUÉ HACE?: Verifica el espacio disponible en el directorio de datos
# ¿POR QUÉ?: Un restore necesita el doble del tamaño del backup (extracción temporal)
# ¿PARA QUÉ?: Confirmar si el problema es de espacio antes de intentar otra solución
docker compose exec gitlab df -h /var/opt/gitlab
```

---

## 📊 Tabla de referencia: comandos de diagnóstico rápido

| Qué verificar | Comando | Output "sano" |
|--------------|---------|---------------|
| Estado contenedores | `docker compose ps` | `Up X minutes (healthy)` |
| Servicios internos | `docker compose exec gitlab gitlab-ctl status` | Todo en `run:` |
| RAM del contenedor | `docker stats --no-stream gitlab` | MEM USAGE < 80% |
| Respuesta HTTP | `curl -I http://localhost` | `HTTP/1.1 302` |
| Espacio en disco | `docker compose exec gitlab df -h /var/opt/gitlab` | `Use%` < 80% |
| Logs recientes | `docker compose logs gitlab --tail 20` | Sin `ERROR` ni `FATAL` |
| Puertos del host | `ss -tuln \| grep -E ':80\|:2224'` | Aparecen los puertos |
| Sanity check | `docker compose exec gitlab gitlab-rake gitlab:check SANITIZE=true` | Todo en verde/OK |

---

## 🛠️ Comandos de recuperación de emergencia

```bash
# ── Reconfigurar desde cero (aplica gitlab.rb actual)
docker compose exec gitlab gitlab-ctl reconfigure

# ── Reinicio completo de todos los servicios internos
docker compose exec gitlab gitlab-ctl restart

# ── Acceso a shell de emergencia
docker compose exec gitlab bash

# ── Consola Rails (modificar BD directamente)
docker compose exec gitlab gitlab-rails console

# ── Resetear contraseña de root por consola
docker compose exec gitlab gitlab-rails runner \
  "u = User.find_by_username('root'); u.password = 'NuevaClave123!'; u.password_confirmation = 'NuevaClave123!'; u.save!(validate: false)"

# ── Ver logs de un servicio específico en tiempo real
docker compose exec gitlab gitlab-ctl tail puma
docker compose exec gitlab gitlab-ctl tail nginx
docker compose exec gitlab gitlab-ctl tail postgresql
docker compose exec gitlab gitlab-ctl tail gitaly
docker compose exec gitlab gitlab-ctl tail sidekiq
```

---

## 🤔 Preguntas de reflexión

1. El checklist de diagnóstico tiene 6 pasos en orden específico. ¿Por qué importa el orden? ¿Qué problema podría ocurrir si ejecutas el paso 3 antes que el paso 1?

2. ¿Por qué un error 502 durante el primer inicio es **normal** y no debe preocuparte, mientras que el mismo error 502 dos horas después del inicio sí requiere investigación?

3. Si el OOM Killer mata a Sidekiq pero deja Puma vivo, ¿qué operaciones de GitLab siguen funcionando y cuáles no?

4. La solución al problema de SSH usa `~/.ssh/config` en lugar de especificar el puerto en cada `git clone`. ¿Qué ventaja operativa tiene esto en un proyecto con 10 desarrolladores?

5. ¿Por qué `gitlab-ctl reconfigure` puede resolver problemas de permisos que `gitlab-ctl restart` no puede?

---

## 📚 Recursos adicionales

- [Troubleshooting oficial de GitLab con Docker](https://docs.gitlab.com/ee/install/docker/troubleshooting.html)
- [Referencia de gitlab-ctl](https://docs.gitlab.com/omnibus/maintenance/)
- [Diagnóstico de rendimiento en GitLab](https://docs.gitlab.com/ee/administration/monitoring/performance/)
- [GitLab log files: qué hay en cada log](https://docs.gitlab.com/ee/administration/logs/)
- [Recuperación ante desastres en GitLab](https://docs.gitlab.com/ee/administration/backup_restore/restore_gitlab.html)

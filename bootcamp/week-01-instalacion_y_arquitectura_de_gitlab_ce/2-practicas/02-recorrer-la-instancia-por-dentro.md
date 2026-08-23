# Práctica 02 — Recorrer la instancia por dentro

> La teoría dice que hay siete procesos. Aquí los ves, los sigues, los reinicias y encuentras sus datos en el disco.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 01 completada — instancia levantada, `readiness` en verde y `~/.bc-gitlab` configurado

---

## Contexto

Un compañero te escribe: *"GitLab va lentísimo"*. No hay más información. Antes de reiniciar nada, hay que saber **qué** va lento y **por qué**.

Esta práctica es el recorrido que harás cada vez que pase eso. La primera vez con calma, para conocer el terreno; a partir de entonces, en dos minutos.

---

## Paso 1: Ver los siete procesos

**Por qué**: `docker compose ps` te dice que el contenedor está arriba. Dentro hay siete procesos y cualquiera de ellos puede estar caído sin que el contenedor se entere.

```bash
docker compose exec gitlab gitlab-ctl status
```

**Verifica** que aparecen los principales:

```bash
docker compose exec gitlab gitlab-ctl status | awk '{print $2}' | tr -d ':' | sort
```

```
gitaly
gitlab-exporter
gitlab-workhorse
logrotate
nginx
node-exporter
postgresql
puma
redis
sidekiq
```

---

## Paso 2: Leer los tiempos, no los estados

**Por qué**: todos dirán `run:` incluso si uno se acaba de reiniciar en bucle. Lo que delata a un proceso enfermo es llevar mucho menos tiempo arriba que sus compañeros.

```bash
docker compose exec gitlab gitlab-ctl status | awk '{print $2, $4}' | tr -d ':;'
```

```
gitaly 312s
gitlab-workhorse 310s
nginx 308s
postgresql 320s
puma 305s
redis 325s
sidekiq 300s
```

Todos en el mismo orden de magnitud: la instancia arrancó una vez y nadie se ha muerto.

**Verifica** que ninguno destaque por abajo. Si uno tiene 20 segundos y el resto 300, ese se está reiniciando.

---

## Paso 3: Reiniciar un solo proceso

**Por qué**: reiniciar GitLab entero son cinco minutos de caída. Reiniciar el proceso concreto son segundos. La diferencia importa cuando hay gente trabajando.

```bash
docker compose exec gitlab gitlab-ctl restart sidekiq
```

**Verifica** que solo ese reinició:

```bash
docker compose exec gitlab gitlab-ctl status | grep -E 'sidekiq|puma'
```

Sidekiq tendrá unos pocos segundos y Puma seguirá con su tiempo original. Eso es exactamente lo que buscabas: cirugía en vez de amputación.

---

## Paso 4: Seguir los logs de un componente

**Por qué**: `docker compose logs` mezcla la salida de todo. `gitlab-ctl tail <proceso>` te deja mirar solo el que te interesa.

Abre una segunda terminal en el mismo directorio y deja corriendo:

```bash
docker compose exec gitlab gitlab-ctl tail nginx
```

En la primera terminal, provoca tráfico:

```bash
for i in 1 2 3; do curl -s -o /dev/null http://localhost:8888/-/health; done
```

Verás aparecer las tres peticiones en la segunda terminal. Corta con `Ctrl+C`.

**Verifica** que puedes seguir otro componente distinto:

```bash
docker compose exec gitlab gitlab-ctl tail gitaly | head -5
```

---

## Paso 5: Filtrar los logs, que son JSON

**Por qué**: `production.log` es una línea JSON por petición. Leerlo a pelo es inviable; con `jq` se vuelve una herramienta.

Las peticiones más lentas de las últimas 200:

```bash
docker compose exec gitlab tail -200 /var/log/gitlab/gitlab-rails/production.log \
  | jq -c 'select(.duration_s > 0.5) | {path, duration_s, status}'
```

Los errores de servidor, si los hay:

```bash
docker compose exec gitlab tail -200 /var/log/gitlab/gitlab-rails/production.log \
  | jq -c 'select(.status >= 500) | {path, status}'
```

En una instancia recién levantada lo normal es que el segundo comando no devuelva nada. Eso también es información.

**Verifica** que el log existe y tiene formato JSON:

```bash
docker compose exec gitlab tail -1 /var/log/gitlab/gitlab-rails/production.log | jq -e '.path' > /dev/null && echo "JSON correcto"
```

---

## Paso 6: Ver qué se está comiendo la memoria

**Por qué**: la mitad de los "GitLab va lento" son falta de memoria, no un bug. Comprobarlo cuesta un comando.

Desde fuera del contenedor:

```bash
docker stats --no-stream
```

Y desde dentro, ordenado por consumo:

```bash
docker compose exec gitlab ps aux --sort=-%mem | head -8
```

Verás arriba los workers de Puma (alrededor de 1 GB cada uno) y PostgreSQL. Es lo esperado.

**Verifica**:

```bash
docker stats --no-stream --format '{{.Name}}: {{.MemUsage}}' | grep gitlab
```

> [!TIP]
> Anota cuánta memoria consume tu instancia recién arrancada y sin uso. Es tu línea base: en la Semana 21, cuando midas de verdad, te servirá de referencia.

---

## Paso 7: Encontrar tu repositorio en el disco

**Por qué**: los repositorios no están en una carpeta con su nombre, sino bajo `@hashed`. Saber localizarlos es imprescindible para diagnosticar y para recuperar.

Primero mira qué hay:

```bash
docker compose exec gitlab ls /var/opt/gitlab/git-data/repositories/@hashed/
```

Verás directorios de dos caracteres. Ninguno se llama como tus proyectos, y es lo correcto.

Todavía no tienes proyectos —eso es la Práctica 03—, así que de momento comprueba el mecanismo con el cálculo:

```bash
echo -n "1" | sha256sum
```

El resultado empieza por `6b86b273...`, de modo que el proyecto con ID 1 estaría en `@hashed/6b/86/6b86b273...git`.

**Verifica** que entiendes la estructura:

```bash
docker compose exec gitlab find /var/opt/gitlab/git-data/repositories -maxdepth 3 -type d | head -10
```

Cuando termines la Práctica 03, vuelve aquí y localiza el repositorio de tu proyecto `app` de verdad.

---

## Paso 8: Ver quién ocupa el disco

**Por qué**: es el comando que ejecutarás el día que el disco se llene, y ese día no querrás estar buscándolo.

```bash
docker compose exec gitlab du -sh /var/opt/gitlab/* 2>/dev/null | sort -rh | head
```

En una instancia nueva domina `postgresql/`. Con el tiempo pasarán al frente `git-data/`, los artefactos y el registry.

**Verifica**:

```bash
docker compose exec gitlab du -sh /var/opt/gitlab 2>/dev/null
```

---

## Paso 9: Comprobar la configuración efectiva

**Por qué**: lo que escribiste en `docker-compose.yml` y lo que GitLab está usando de verdad son dos cosas distintas, separadas por un `reconfigure`. Comprobarlo cierra el ciclo de la teoría 03.

Lo que llegó a `gitlab.rb`:

```bash
docker compose exec gitlab grep -E "worker_processes|max_concurrency|listen_port" /etc/gitlab/gitlab.rb
```

Lo que Nginx está aplicando de verdad:

```bash
docker compose exec gitlab grep -m2 'listen' /var/opt/gitlab/nginx/conf/service_conf/gitlab-rails.conf
```

**Verifica** que el puerto coincide con el de tu `.env`:

```bash
docker compose exec gitlab grep -c '8888' /etc/gitlab/gitlab.rb
# un número mayor que 0
```

> [!NOTE]
> Si cambiaste el puerto en `.env` en la Práctica 01, aquí verás el tuyo, no 8888. Lo importante es que **coincida**: eso demuestra que el valor viajó de `.env` al compose, del compose a `GITLAB_OMNIBUS_CONFIG`, de ahí a `gitlab.rb` y de ahí a la configuración de Nginx.

---

## ✅ Resultado

- [ ] Sabes listar los procesos y leer sus tiempos de actividad
- [ ] Has reiniciado un solo proceso sin tocar los demás
- [ ] Has seguido los logs de un componente concreto
- [ ] Sabes filtrar `production.log` con `jq`
- [ ] Conoces el consumo de memoria de tu instancia en reposo
- [ ] Entiendes la estructura `@hashed` y sabes recorrerla
- [ ] Sabes qué comando te dice quién ocupa el disco
- [ ] Has comprobado que tu configuración llegó hasta Nginx

```bash
./scripts/verificar-semana.sh 01
```

Esta práctica no añade comprobaciones automáticas: es de diagnóstico, y el diagnóstico se evalúa en el cuestionario de la rúbrica.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `gitlab-ctl: command not found` | Estás ejecutándolo fuera del contenedor | Antepón `docker compose exec gitlab` |
| `gitlab-ctl status` dice `down: puma` | Ese proceso se cayó | `gitlab-ctl tail puma` para ver por qué, luego `gitlab-ctl restart puma` |
| Un proceso vuelve a caerse tras reiniciarlo | Casi siempre memoria | `docker stats --no-stream`; comprueba que no haya dos perfiles levantados |
| `production.log` está vacío | Nadie ha usado la instancia todavía | Abre la interfaz en el navegador y repite |
| `jq` da error al leer el log | Alguna línea no es JSON (avisos de arranque) | Usa `jq -c 'select(...)? // empty'` o filtra con `grep '^{'` antes |
| `du` tarda muchísimo | Está recorriendo todo el volumen | Normal la primera vez. Acota: `du -sh /var/opt/gitlab/git-data` |
| `@hashed` está vacío | Aún no has creado ningún proyecto | Es lo esperado. Vuelve tras la Práctica 03 |
| El puerto en `gitlab.rb` no es el de `.env` | El contenedor no se recreó tras cambiar `.env` | `docker compose --profile base up -d --force-recreate gitlab` |

---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| [← Práctica 01 — Levantar la instancia](01-levantar-la-instancia.md) | [Práctica 03 — Crear tu plataforma →](03-crear-tu-plataforma.md) |

[← Volver a la Semana 01](../README.md)

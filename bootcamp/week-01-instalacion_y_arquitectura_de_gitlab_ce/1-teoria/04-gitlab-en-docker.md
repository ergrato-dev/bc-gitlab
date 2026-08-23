# GitLab en Docker

> Un contenedor con siete procesos dentro y tres volúmenes fuera. Si entiendes qué guarda cada volumen, entiendes qué se pierde cuando algo va mal.

## 🎯 Objetivos

- Explicar qué guarda cada uno de los tres volúmenes y cuál duele perder
- Entender por qué la imagen oficial no sigue el principio de un proceso por contenedor
- Leer el arranque de GitLab y saber en qué fase está
- Configurar los perfiles del laboratorio y saber cuál levantar en cada semana

---

## 1. Qué problema resuelve

Instalar GitLab con Omnibus en tu máquina funciona, y te deja la máquina llena de cosas: un PostgreSQL propio, un Redis propio, un Nginx propio, servicios de systemd y 3 GB en `/opt`. Desinstalarlo del todo es incómodo, y tener dos versiones a la vez es imposible.

En Docker, todo eso vive dentro de un contenedor. Se levanta, se tira, se vuelve a levantar. Para un laboratorio donde vas a romper cosas a propósito, es la única opción razonable.

> [!NOTE]
> **Docker es la forma de instalación de este bootcamp, no la recomendación universal.** En producción, la imagen oficial de Docker es una opción válida y soportada, pero muchas organizaciones prefieren Omnibus sobre una máquina dedicada o el chart de Helm en Kubernetes. La Semana 18 discute las rutas de actualización, que es donde más se nota la diferencia.

---

## 2. Un contenedor con siete procesos: la herejía necesaria

La regla de oro de Docker dice: un proceso por contenedor. La imagen oficial de GitLab la incumple descaradamente: dentro corren Nginx, Puma, Sidekiq, Gitaly, PostgreSQL, Redis y Workhorse a la vez, gestionados por un supervisor (`runit`) que es el que responde a `gitlab-ctl`.

Es deliberado. Partir GitLab en siete contenedores es posible —lo hace el chart de Helm— pero exige coordinar arranques, secretos compartidos y red interna. Para un solo nodo, un contenedor gordo es mucho más simple.

La consecuencia práctica es la que ya conoces:

```bash
docker compose exec gitlab gitlab-ctl status
```

Dentro del contenedor sigues necesitando las herramientas de Omnibus, porque dentro del contenedor **hay** un Omnibus.

---

## 3. Los tres volúmenes

Toda la persistencia está en tres rutas, y conviene saberse de memoria qué hay en cada una:

| Volumen | Ruta dentro | Qué guarda | Si lo pierdes |
|---|---|---|---|
| `gitlab-config` | `/etc/gitlab` | `gitlab.rb` y **`gitlab-secrets.json`** | Los backups dejan de poder restaurarse |
| `gitlab-data` | `/var/opt/gitlab` | Repositorios, base de datos, adjuntos, artefactos, backups | Lo pierdes todo |
| `gitlab-logs` | `/var/log/gitlab` | Logs de todos los procesos | Nada crítico |

### `gitlab-secrets.json`: el archivo que casi nadie copia

Dentro de `/etc/gitlab` hay un archivo pequeño y decisivo. Contiene las claves con las que GitLab cifra, entre otras cosas:

- Las variables de CI/CD marcadas como enmascaradas
- Los tokens de acceso
- Las credenciales de integraciones
- Los secretos de autenticación de dos factores

> [!WARNING]
> **Un backup de GitLab sin `gitlab-secrets.json` es un backup que no se puede restaurar del todo.** El comando `gitlab-backup create` **no** lo incluye: hay que copiarlo aparte.
>
> ```bash
> docker compose cp gitlab:/etc/gitlab/gitlab-secrets.json ./gitlab-secrets.json
> ```
>
> Es el error número uno en recuperaciones reales. Restauras, GitLab arranca, y todos los secretos cifrados son ilegibles. La Semana 22 lo practica de verdad.

### Volúmenes con nombre, no bind mounts

En el laboratorio son volúmenes gestionados por Docker:

```yaml
volumes:
  gitlab-config:
    name: bc-gitlab-config
  gitlab-data:
    name: bc-gitlab-data
  gitlab-logs:
    name: bc-gitlab-logs
```

Sobreviven a `docker compose down`. Solo desaparecen con `down -v`:

```bash
docker compose --profile base down      # para el contenedor, conserva los datos
docker compose --profile base down -v   # BORRA los volúmenes
```

Esa `-v` es la diferencia entre pausar el laboratorio y perder tu proyecto de veintiséis semanas.

---

## 4. Qué pasa cuando arranca

El primer arranque tarda unos cinco minutos y no es que esté colgado. Pasa por fases:

| Fase | Qué ocurre | Cuánto |
|---|---|---|
| 1 | El contenedor arranca y `runit` toma el control | segundos |
| 2 | `gitlab-ctl reconfigure`: Chef genera toda la configuración | 1-3 min |
| 3 | PostgreSQL arranca y corre las migraciones del esquema | 1-2 min |
| 4 | Puma, Sidekiq, Gitaly y Workhorse arrancan | ~30 s |
| 5 | Nginx empieza a aceptar peticiones | segundos |

Durante las fases 2 y 3 el puerto ya está publicado, pero **nadie responde todavía**. De ahí el 502 clásico del primer arranque.

Se sigue así:

```bash
docker compose logs -f gitlab
```

Las líneas que importan:

```
gitlab Reconfigured!          ← acabó la fase 2
GitLab is now healthy         ← ya se puede entrar
```

En los arranques siguientes la cosa baja a 1-2 minutos: la configuración ya está generada y las migraciones ya corrieron.

### El healthcheck del compose

```yaml
healthcheck:
  test: curl -f http://localhost:8888/-/health || exit 1
  interval: 60s
  start_period: 300s
```

`start_period: 300s` es lo que le dice a Docker "no te asustes durante los primeros cinco minutos". Sin eso, Docker marcaría el contenedor como no saludable y, si algo dependiera de él, no arrancaría nunca.

---

## 5. Los perfiles del laboratorio

Compose puede agrupar servicios en perfiles y levantar solo los que pidas. El laboratorio usa esa capacidad para que quepa en 16 GB:

| Perfil | Qué levanta | Semanas | RAM |
|---|---|---|:--:|
| `base` | GitLab, Runner, cache de registry | Todas | ~5 GB |
| `observabilidad` | Prometheus, Grafana, Loki, Promtail | 21 | +4 GB |
| `ha` | Praefect, 3 Gitaly, PostgreSQL replicado, PgBouncer | 23 | +8 GB |

```bash
docker compose --profile base up -d
docker compose --profile observabilidad up -d    # se suma a base
docker compose --profile observabilidad down     # apaga solo ese perfil
```

> [!IMPORTANT]
> **Ningún servicio del laboratorio está fuera de un perfil.** Eso significa que `docker compose up -d` a secas **no levanta nada** y no da error. Es deliberado: obliga a elegir perfil, y así nunca levantas por accidente algo que no cabe.
>
> `observabilidad` y `ha` juntos superan los 16 GB. Nunca a la vez.

Kubernetes (Semanas 16 y 25) no es un perfil: k3d crea su propio clúster fuera de Compose.

---

## 6. Los puertos que publica el laboratorio

```yaml
ports:
  - "8888:8888"     # interfaz web y API
  - "5050:5050"     # Container Registry (S13)
  - "8090:8090"     # GitLab Pages (S14)
  - "2224:22"       # SSH de Git
```

El 2224 merece una nota: el SSH de Git dentro del contenedor escucha en el 22, pero publicarlo en el 22 de tu máquina chocaría con tu propio servidor SSH. Por eso se mapea al 2224, y por eso tu `~/.ssh/config` necesita saberlo:

```
Host gitlab-lab
  HostName localhost
  Port 2224
  User git
```

---

## 7. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| `down -v` para "empezar limpio" | Borra los volúmenes: se va el proyecto entero | `down` sin `-v`. Con `-v` solo si de verdad quieres perderlo todo |
| Hacer backup sin copiar `gitlab-secrets.json` | El backup no se puede restaurar del todo | Copiarlo siempre, aparte del backup |
| Dar por caído GitLab a los 30 segundos | Todavía está en la fase 2 de 5 | Esperar a `Reconfigured!` en los logs |
| Guardar datos dentro del contenedor, fuera de los volúmenes | Se pierden al recrear el contenedor | Todo lo persistente vive en los tres volúmenes |
| `docker compose up -d` sin perfil | No levanta nada y parece que falla | `--profile base` |
| Levantar `observabilidad` y `ha` a la vez | Se acaba la memoria y GitLab devuelve 502 sin explicar por qué | Un perfil pesado cada vez |

---

## 8. Trucos

**Ver los volúmenes reales y su tamaño:**

```bash
docker volume ls | grep bc-gitlab
docker system df -v | grep bc-gitlab
```

**Sacar un archivo del contenedor sin entrar:**

```bash
docker compose cp gitlab:/etc/gitlab/gitlab-secrets.json ./gitlab-secrets.json
```

**Saber en qué fase del arranque está:**

```bash
docker compose logs gitlab | tail -5
```

Si la última línea habla de Chef, está en la fase 2. Si habla de migraciones, en la 3.

**Comprobar qué levanta cada perfil sin levantarlo:**

```bash
docker compose --profile base config --services
docker compose --profile observabilidad config --services
```

**Qué se está comiendo la memoria:**

```bash
docker stats --no-stream
```

---

## 📚 Recursos Adicionales

- [GitLab en Docker](https://docs.gitlab.com/ee/install/docker/) — la documentación oficial de la imagen, incluida `GITLAB_OMNIBUS_CONFIG`
- [Perfiles de Compose](https://docs.docker.com/compose/how-tos/profiles/) — cómo funcionan y por qué un servicio con perfil no arranca por defecto
- [Perfiles de laboratorio del bootcamp](../../../docs/perfiles-de-laboratorio.md) — el presupuesto de memoria semana a semana
- [Requisitos de instalación](https://docs.gitlab.com/ee/install/requirements.html) — CPU, memoria y disco según número de usuarios

---

## ✅ Checklist de Verificación

- [ ] Sabes qué guarda cada uno de los tres volúmenes
- [ ] Sabes por qué `gitlab-secrets.json` se copia aparte del backup
- [ ] Distingues `down` de `down -v` y sabes qué pierde cada uno
- [ ] Sabes reconocer en qué fase del arranque está la instancia
- [ ] Sabes qué perfil levantar y por qué `docker compose up -d` a secas no hace nada

---

| Anterior | Siguiente |
|---|---|
| [← 03 — Omnibus y `gitlab.rb`](03-omnibus-y-gitlab-rb.md) | [05 — Anatomía de una petición →](05-anatomia-de-una-peticion.md) |

[← Volver a la Semana 01](../README.md)

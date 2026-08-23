# Semana 01 — Instalación de GitLab CE en Docker y arquitectura interna

> Al terminar esta semana tendrás tu propio GitLab corriendo y sabrás nombrar cada
> proceso que hay dentro. Eso es lo que separa a quien usa GitLab de quien lo opera:
> cuando la instancia devuelva un 502, sabrás dónde mirar.

---

## 🎯 Objetivos de la Semana

Al terminar serás capaz de:

- Explicar qué problema resuelve una plataforma DevOps unificada frente a cinco herramientas sueltas
- Distinguir GitLab CE de las ediciones de pago y decir qué te falta y qué no
- Nombrar los siete procesos internos de GitLab y qué hace cada uno
- Explicar el ciclo `gitlab.rb` → `reconfigure` y por qué GitLab no lee su configuración en caliente
- Levantar la instancia con Docker Compose por perfiles y saber qué guarda cada volumen
- Trazar una petición desde tu navegador hasta Gitaly, y un `git push` desde tu terminal hasta el disco
- Localizar dónde vive cada dato: repositorios, base de datos, artefactos, adjuntos
- Diagnosticar una instancia con `gitlab-ctl`, `/-/health`, `/-/readiness` y los logs
- Crear un token de la API v4 y hacer tus primeras consultas con `curl` y `glab`
- Crear el grupo y el proyecto que te acompañarán las 26 semanas

---

## 📋 Prerrequisitos

- **Entorno preparado** — Docker 27+, Git 2.46+, `glab`, `jq` y una clave SSH. Todo en [setup-entorno](../../docs/setup-entorno.md)
- **Dominio elegido** — lee [proyecto-hilo-conductor](../../docs/proyecto-hilo-conductor.md) antes del proyecto de esta semana
- **16 GB de RAM** y unos 40 GB de disco libres
- **Perfil de laboratorio**: `base` — ver [perfiles-de-laboratorio](../../docs/perfiles-de-laboratorio.md)
- Saber `clone`, `commit`, `push` y qué es una rama. Nada más: Git se trabaja a fondo en la Semana 02

Esta es la primera semana. No asume nada de semanas anteriores.

---

## 🗂️ Estructura de la Semana

```
week-01-instalacion_y_arquitectura_de_gitlab_ce/
├── README.md                  # Este archivo
├── rubrica-evaluacion.md      # Cómo se evalúa
├── checks.json                # Las 12 comprobaciones automáticas
├── 0-assets/                  # Diagramas
├── 1-teoria/                  # 8 archivos, un concepto cada uno
├── 2-practicas/               # 4 prácticas sobre tu instancia
├── 3-proyecto/                # La capa 1 de tu plataforma
├── 4-recursos/                # Libros, vídeos y enlaces
└── 5-glosario/                # Términos de esta semana
```

---

## 📝 Contenidos

### Teoría

| Archivo | Tema | Duración |
|---|---|:--:|
| [01 — Qué es GitLab CE](1-teoria/01-que-es-gitlab-ce.md) | El problema de las cinco herramientas, y qué incluye CE frente a Premium y Ultimate | 15 min |
| [02 — Los procesos por dentro](1-teoria/02-arquitectura-los-procesos.md) | Nginx, Workhorse, Puma, Sidekiq, Gitaly, PostgreSQL, Redis | 20 min |
| [03 — Omnibus y `gitlab.rb`](1-teoria/03-omnibus-y-gitlab-rb.md) | Un archivo, un `reconfigure`, y por qué no hay recarga en caliente | 15 min |
| [04 — GitLab en Docker](1-teoria/04-gitlab-en-docker.md) | La imagen, los tres volúmenes, `GITLAB_OMNIBUS_CONFIG` y el arranque | 15 min |
| [05 — Anatomía de una petición](1-teoria/05-anatomia-de-una-peticion.md) | De tu navegador a Gitaly, y de `git push` al disco | 15 min |
| [06 — Dónde viven los datos](1-teoria/06-donde-viven-los-datos.md) | `@hashed`, la base de datos, adjuntos y artefactos | 15 min |
| [07 — Salud, logs y diagnóstico](1-teoria/07-salud-logs-y-diagnostico.md) | `gitlab-ctl`, `/-/health`, `/-/readiness` y dónde mirar cuando falla | 15 min |
| [08 — Tokens y la API v4](1-teoria/08-tokens-y-api-v4.md) | Tipos de token, scopes, y cómo se consulta la API | 10 min |

### Prácticas

| Práctica | Qué haces | Duración |
|---|---|:--:|
| [01 — Levantar la instancia](2-practicas/01-levantar-la-instancia.md) | La arrancas, confirmas que arrancó **de verdad** y la endureces un poco | 50 min |
| [02 — Recorrerla por dentro](2-practicas/02-recorrer-la-instancia-por-dentro.md) | Ves los procesos, los logs y los datos con tus propios ojos | 50 min |
| [03 — Crear tu plataforma](2-practicas/03-crear-tu-plataforma.md) | Grupo, proyecto, SSH y el primer commit del hilo conductor | 50 min |
| [04 — Hablar con la API](2-practicas/04-hablar-con-la-api.md) | Token, `curl`, `glab` y el autograding funcionando | 50 min |

### Proyecto

La **capa 1** de tu plataforma: la instancia, el grupo `plataforma-<tu-dominio>` y el proyecto `app` con un README que declara tu dominio. Detalles en [3-proyecto](3-proyecto/README.md).

---

## ⏱️ Distribución del Tiempo (8 horas)

| Bloque | Tiempo |
|---|:--:|
| Teoría (8 archivos) | 2 h 00 |
| Prácticas (4 × 50 min) | 3 h 20 |
| Proyecto | 2 h 00 |
| Revisión y verificación | 40 min |
| **Total** | **8 h 00** |

> [!TIP]
> El primer arranque de GitLab tarda unos 5 minutos y no depende de ti. Aprovecha
> ese rato para leer la teoría 02: cuando el log empiece a nombrar procesos, ya
> sabrás qué es cada uno.

---

## ⚠️ Lo que casi todo el mundo hace mal la primera semana

Tres errores que cuestan horas y que esta semana intenta evitarte:

1. **Confundir "el contenedor está arriba" con "GitLab funciona".** `docker compose ps` puede decir `running` mientras Puma todavía no acepta peticiones. Lo que responde es `/-/readiness`, no el estado del contenedor.
2. **Editar la configuración y esperar que se aplique.** GitLab no relee `gitlab.rb` en caliente. Sin `gitlab-ctl reconfigure` no ha pasado nada.
3. **Crear el proyecto en el espacio personal.** Funciona, y en la Semana 03 hay que rehacerlo todo. El proyecto cuelga del grupo desde el primer día.

---

## 🎩 Trucos y atajos

| Truco | Cómo |
|---|---|
| Ver el arranque sin adivinar | `docker compose logs -f gitlab` y espera a la línea `gitlab Reconfigured!` |
| Saber si está listo de verdad | `curl -s localhost:8888/-/readiness \| jq` — `/-/health` miente, solo dice que Nginx contesta |
| Estado de todos los procesos de golpe | `docker compose exec gitlab gitlab-ctl status` |
| Seguir un solo componente | `docker compose exec gitlab gitlab-ctl tail sidekiq` |
| Ver la configuración **efectiva**, no la que escribiste | `docker compose exec gitlab cat /var/opt/gitlab/gitlab-rails/etc/gitlab.yml` |
| Comprobar la versión sin abrir el navegador | `curl -s localhost:8888/api/v4/version -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \| jq` |
| Contraseña inicial de `root` | `docker compose exec gitlab grep 'Password:' /etc/gitlab/initial_root_password` — el archivo se autodestruye a las 24 h |
| Explorar la API sin leer la documentación | `http://localhost:8888/-/graphql-explorer`, autocompleta con `Ctrl+Espacio` |
| Ver todas las tareas de mantenimiento disponibles | `docker compose exec gitlab gitlab-rake -T \| less` |
| Ver cuánta memoria come cada cosa | `docker stats --no-stream` |
| Reiniciar un solo proceso, no todo | `docker compose exec gitlab gitlab-ctl restart sidekiq` |
| Encontrar un repositorio en disco | Saca el ID por API y calcula la ruta: `H=$(echo -n "<id>" \| sha256sum \| cut -c1-64); echo @hashed/${H:0:2}/${H:2:2}/$H.git` |

---

## 📌 Entregables

1. Instancia GitLab CE 19.x levantada con el perfil `base` y respondiendo en `/-/readiness`
2. Contraseña de `root` cambiada
3. Registro público de usuarios desactivado
4. Clave SSH registrada en tu usuario
5. Grupo `plataforma-<tu-dominio>` creado, con descripción
6. Proyecto `app` creado **dentro del grupo**, privado, con descripción que declara tu dominio
7. Rama por defecto `main`
8. Al menos un commit tuyo y un `README.md` en la raíz
9. `~/.bc-gitlab` configurado y `verificar-semana.sh --doctor` en verde

---

## ✅ Verificación

```bash
./scripts/verificar-semana.sh 01
```

Las 12 comprobaciones tienen que pasar. Si alguna falla, la pista te dice en qué práctica y en qué paso se arregla.

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| — | **Semana 01** | Semana 02 — Git avanzado y firma de commits |

[← Volver al inicio del bootcamp](../README.md)

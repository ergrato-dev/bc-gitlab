# Rúbrica de Evaluación — Semana 01

## 📊 Distribución de Evidencias

| Tipo | Peso | Instrumento | Quién juzga |
|---|:--:|---|---|
| 🧠 Conocimiento | 30% | 10 preguntas conceptuales, 10 pts cada una | Autoevaluación |
| 💪 Desempeño | 40% | Las 4 prácticas, 10 pts cada una | La API de tu instancia |
| 📦 Producto | 30% | La capa 1 de tu plataforma: 60 pts por API + 40 pts de calidad | Mixto |

**Criterio de aprobación: mínimo 70% en cada evidencia**, no en el promedio. Sacar 100 en desempeño y 50 en conocimiento no aprueba la semana.

---

## 🧠 Conocimiento (30%)

| # | Pregunta |
|:--:|---|
| 1 | ¿Qué diferencia hay entre "GitLab autohospedado" y "GitLab CE", y por qué mezclarlas lleva a decisiones equivocadas? |
| 2 | `/-/health` devuelve `GitLab OK` y la instancia no funciona. ¿Cómo es posible y qué endpoint deberías haber usado? |
| 3 | Haces `git push`, el commit aparece en la interfaz, pero el pipeline no se crea. ¿En qué punto exacto del recorrido se quedó, y qué proceso investigarías? |
| 4 | ¿Por qué un `git clone` por HTTP no ocupa un hilo de Puma durante toda la transferencia, y qué pasaría si lo ocupara? |
| 5 | Editas `/var/opt/gitlab/nginx/conf/service_conf/gitlab-rails.conf`, reinicias, y tu cambio desaparece. ¿Por qué, y dónde había que hacerlo? |
| 6 | ¿Por qué los repositorios se guardan en `@hashed/93/50/9350c2...` y no en una carpeta con el nombre del proyecto? Da dos razones. |
| 7 | Restauras un backup de GitLab en una máquina nueva. La instancia arranca, pero todas las variables de CI enmascaradas son ilegibles. ¿Qué te faltó copiar y por qué el backup no lo incluye? |
| 8 | `gitlab-ctl status` muestra todos los procesos con `run:`. ¿Qué otro dato de esa misma salida puede indicar que algo va mal, y qué significa? |
| 9 | ¿Por qué el autograding de este bootcamp pide un token con scope `read_api` en vez de `api`, y qué principio general ilustra? |
| 10 | Consultas `/api/v4/projects/plataforma-biblioteca/app` y recibes `404 Project Not Found`, pero el proyecto existe. ¿Qué falla? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** Son dos ejes independientes. *Autohospedado* (frente a GitLab.com o Dedicated) responde a **dónde corre** y quién lo opera. *CE* (frente a EE) responde a **qué código** estás ejecutando, y sobre EE se aplican además los tiers Free, Premium y Ultimate. Puedes tener Ultimate en tu propio servidor y puedes usar GitLab.com gratis. Mezclarlas produce dos errores caros: creer que autohospedar te da features de pago, y creer que una feature Premium estará disponible solo por instalar el software tú.

**2.** `/-/health` responde sin arrancar la lógica de la aplicación: solo confirma que el servidor web contesta. Puede devolver `OK` con PostgreSQL caído. Es deliberado: sirve como healthcheck barato que se ejecuta cada minuto. Para saber si GitLab funciona de verdad hay que usar `/-/readiness`, que comprueba base de datos, Redis y Gitaly; con `?all=1` desglosa cada componente y te dice directamente cuál falla.

**3.** El push terminó en Gitaly: los objetos están escritos en disco y la referencia actualizada, por eso el commit se ve. Lo que ocurre después es asíncrono: Gitaly dispara un hook `post-receive`, GitLab **encola** en Redis el trabajo de crear el pipeline, y **Sidekiq** lo ejecuta cuando le llega el turno. Si el pipeline no aparece, el sospechoso es Sidekiq: comprobar que está vivo con `gitlab-ctl status` y mirar el tamaño de las colas en `Admin → Monitoring → Background jobs`. Antes de eso conviene descartar lo trivial: que exista `.gitlab-ci.yml` en esa rama.

**4.** Porque Workhorse intercepta las peticiones de Git. Le pide a Puma **solo la autorización** —una respuesta pequeña y rápida— y con ese permiso habla directamente con Gitaly, haciendo de tubería para el packfile. Si el clon pasara por Puma, un repositorio grande tendría ocupado un hilo de Rails durante minutos. Con 2 workers × 4 threads = 8 hilos en el laboratorio, tres clones simultáneos dejarían la interfaz web inservible. Puma decide *si puedes*; Workhorse y Gitaly hacen *el trabajo*.

**5.** Porque ese archivo no es configuración: es **salida**. `gitlab-ctl reconfigure` lo regenera desde `/etc/gitlab/gitlab.rb` cada vez que se ejecuta, y en la imagen de Docker `reconfigure` corre automáticamente en cada arranque. El cambio había que hacerlo en `gitlab.rb`, con el prefijo `nginx[...]`, y aplicarlo con `reconfigure`. En este laboratorio hay un nivel más: `gitlab.rb` se genera a su vez desde `GITLAB_OMNIBUS_CONFIG` en `docker-compose.yml`, así que la configuración permanente se toca ahí.

**6.** Primera razón: **renombrar no mueve nada**. La ruta se deriva del ID numérico del proyecto, que nunca cambia; renombrar un grupo con 300 proyectos no toca el disco. Segunda: **reparte la carga en el sistema de archivos**, con 256 × 256 subdirectorios posibles, evitando directorios con decenas de miles de entradas que degradan el rendimiento. Hay dos más: no hay colisiones de nombre entre grupos, y las rutas no filtran los nombres de proyectos privados a quien tenga acceso al disco.

**7.** Faltó `/etc/gitlab/gitlab-secrets.json`. Contiene las claves con las que GitLab cifra las variables enmascaradas, los tokens y las credenciales de integraciones. `gitlab-backup create` respalda la base de datos, los repositorios, los adjuntos, los artefactos y el registry, pero **no** el contenido de `/etc/gitlab`: son cosas distintas, datos frente a configuración y secretos. La consecuencia es que los valores cifrados siguen ahí y son indescifrables. Se copia aparte, y los dos comandos van siempre juntos.

**8.** El **tiempo de actividad** de cada proceso. Todos aparecen como `run:` incluso si uno acaba de reiniciarse. Si Puma lleva 42 segundos y el resto más de 3000, Puma se murió y `runit` lo levantó. Si al mirar de nuevo un minuto después sigue teniendo un tiempo bajo, está en bucle, y la causa más frecuente es memoria insuficiente. La lectura útil de `gitlab-ctl status` no son los estados, son los tiempos.

**9.** Porque el script solo hace `GET`: no necesita permiso de escritura para nada. `api` concede acceso completo de lectura y escritura a toda la API, incluido borrar proyectos, cambiar permisos y crear otros tokens. El principio es el de **mínimo privilegio**: un componente recibe exactamente los permisos que necesita para su función y ni uno más, de modo que si se filtra, el daño posible está acotado. Es el mismo razonamiento que en la Semana 10 lleva a no usar tokens personales en pipelines.

**10.** La barra sin codificar. La API v4 acepta como identificador de proyecto el ID numérico o la **ruta completa URL-encoded**, donde `/` se escribe `%2F`. Con una barra literal, la API interpreta que `app` es un subrecurso de un proyecto llamado `plataforma-biblioteca` y devuelve 404. Lo correcto es `/api/v4/projects/plataforma-biblioteca%2Fapp`. Es el atasco más común al empezar, y por eso el `checks.json` del bootcamp usa el marcador `{proyecto}`, que hace la codificación por ti.

</details>

---

## 💪 Desempeño (40%)

| Práctica | Criterio | Puntos |
|---|---|:--:|
| 01 — Levantar la instancia | La instancia responde en `/-/readiness?all=1` con todos los componentes en `ok`, la contraseña de `root` está cambiada y el registro público desactivado | 10 |
| 02 — Recorrerla por dentro | Sabes listar procesos, leer sus tiempos, reiniciar uno solo, filtrar `production.log` con `jq` y localizar quién ocupa el disco | 10 |
| 03 — Crear tu plataforma | Grupo y proyecto creados con los siete atributos correctos, clave SSH funcionando y primer commit empujado | 10 |
| 04 — Hablar con la API | Token comprobado, consultas REST con `jq`, una escritura por API, `glab` autenticado y una consulta GraphQL ejecutada | 10 |

---

## 📦 Producto (30%)

### Verificable por API — 60 puntos

Los ejecuta `./scripts/verificar-semana.sh 01`. Cinco puntos cada uno.

| # | Requisito | Puntos |
|:--:|---|:--:|
| 1 | Tu instancia responde y corre la version fijada del bootcamp | 5 |
| 2 | El registro publico de usuarios esta desactivado en la instancia | 5 |
| 3 | Tu usuario tiene al menos una clave SSH registrada | 5 |
| 4 | Existe el grupo raiz de tu plataforma | 5 |
| 5 | El grupo tiene una descripcion que dice de que va tu plataforma | 5 |
| 6 | Existe el proyecto app dentro de ese grupo | 5 |
| 7 | El proyecto cuelga del grupo, no de tu espacio personal | 5 |
| 8 | El proyecto es privado | 5 |
| 9 | La descripcion del proyecto declara el dominio que elegiste | 5 |
| 10 | La rama por defecto del proyecto se llama main | 5 |
| 11 | El repositorio tiene al menos un commit tuyo | 5 |
| 12 | Hay un README.md en la raiz del repositorio | 5 |

### Calidad — 40 puntos

Lo que la API confirma que existe pero no puede juzgar.

| Criterio | Qué se valora | Puntos |
|---|---|:--:|
| Concreción del dominio | Se pueden inventar issues creíbles sobre él. "Préstamos de biblioteca con fechas de devolución" sí; "aplicación web" no | 10 |
| Calidad del README | Un desconocido entiende de qué va el proyecto en treinta segundos | 10 |
| Descripciones diferenciadas | La del grupo describe la plataforma; la del proyecto, el producto. No son la misma frase copiada | 10 |
| Mensaje del primer commit | Conventional Commits, en imperativo, y dice qué hace en vez de qué archivo toca | 10 |

---

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Un token pegado en el repositorio, aunque sea inventado | **-100 (revocar y rehacer)** |
| `~/.bc-gitlab` versionado en el repositorio | **-50** |
| La contraseña de `root` sigue siendo la inicial | -30 |
| Registro público abierto tras haberlo cerrado, para "que sea más fácil" | -25 |
| El proyecto en el espacio personal en vez del grupo | -20 |
| Descripciones que existen solo para pasar la comprobación de 20 caracteres | -15 |
| README con la plantilla del material sin adaptar al dominio propio | -15 |
| El correo de Git no coincide con el de GitLab | -10 |
| Rama por defecto `master` renombrada solo en local, sin cambiarla en el proyecto | -10 |
| Comprobaciones que pasan porque se reutilizó un proyecto anterior | -10 |

La primera es la única que anula la semana entera. Un token en un repositorio se revoca **primero** y se explica después: mientras exista, es válido.

---

[← Volver a la Semana 01](README.md)

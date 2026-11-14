# 📖 Glosario — Semana 11

Términos que aparecen esta semana. El nombre real de la feature va en inglés entre paréntesis, y el **tier** cuando aplica.

El glosario acumulado de toda la plataforma está en [glosario-global](../../../docs/glosario-global.md).

---

## C

**Camino crítico** (*critical path*) — La cadena más larga de jobs encadenados por `needs`. Su duración es el mínimo del pipeline aunque hubiera runners de sobra. Acortar un job fuera de ella no acorta nada.

**`concurrent`** — Ajuste global de `config.toml` del runner: cuántos jobs ejecuta a la vez entre todos sus runners registrados. Con `1`, un DAG no acelera nada.

## D

**DAG** (*directed acyclic graph*) — Free. Un pipeline cuyos jobs esperan solo a los que nombran en `needs`, no al stage anterior entero.

**`dotenv`** (*dotenv report*) — Free. Informe de artefactos (`artifacts:reports:dotenv`) que convierte un archivo `CLAVE=valor` en variables de los jobs que lo descargan, incluidos los jobs de disparo.

## I

**`!reference`** — Free. Etiqueta YAML que copia una sección de otro job (por ejemplo, su lista de `rules`). En `rules`, la lista insertada se aplana.

## J

**Job de disparo** (*trigger job*, *bridge*) — Free. Un job con `trigger`: no se ejecuta en un runner, crea otro pipeline. Admite solo un subconjunto de palabras clave. Por API, `GET .../pipelines/<id>/bridges`.

**Job token** (`CI_JOB_TOKEN`) — Free. Credencial de vida corta de cada job, con los permisos del usuario que lanzó el pipeline y acceso a un conjunto limitado de endpoints.

## L

**Lista de permitidos del job token** (*job token allowlist*, *inbound scope*) — Free. Los proyectos que pueden usar su job token contra este. La configura el proyecto al que se accede, no el que accede.

## M

**Modo de proceso** (*process mode*) — Free. El orden en que un `resource_group` atiende su cola: `unordered`, `oldest_first`, `newest_first` o `newest_ready_first`. Se cambia por API.

## N

**`needs`** — Free. Los jobs a los que espera un job, y de los que descarga artefactos. `needs: []` no espera a nadie.

**`needs:optional`** — Free. Un `needs` hacia un job que puede no estar en el pipeline: si falta, no hay error de creación.

**`needs:project`** — **Premium**. Descarga artefactos de un job de otro proyecto desde el YAML. En CE: el job token y la API de artefactos.

## P

**Pipeline hijo** (*child pipeline*) — Free. Pipeline del mismo proyecto y commit creado con `trigger:include`. `CI_PIPELINE_SOURCE` vale `parent_pipeline`; el `workflow` del padre no se le aplica.

**Pipeline hijo dinámico** (*dynamic child pipeline*) — Free. Pipeline hijo cuyo YAML es el artefacto de un job (`trigger:include:artifact`).

**Pipeline multiproyecto** (*multi-project pipeline*) — Free. Pipeline de otro proyecto creado con `trigger:project`, con la identidad de quien creó el de arriba. `CI_PIPELINE_SOURCE` vale `pipeline`.

**Pipeline programado** (*scheduled pipeline*) — Free. Pipeline creado por un cron sobre una rama, con los permisos de su propietario. `CI_PIPELINE_SOURCE` vale `schedule`.

**Prevent outdated deployment jobs** — Free. Ajuste del proyecto (`ci_forward_deployment_enabled`) que hace fallar un despliegue más antiguo que el último correcto de su entorno.

**Propietario del programado** (*schedule owner*) — El usuario con cuyos permisos se ejecuta. Si sale del proyecto o se bloquea, el programado se desactiva; *Take ownership* lo recupera.

## R

**`resource_group`** — Free. Candado por nombre dentro de un proyecto: los jobs con el mismo grupo no se ejecutan a la vez. El que espera queda en `waiting_for_resource`.

## S

**`strategy: mirror`** — Free, GitLab 18.2. El job de disparo refleja exactamente el estado del pipeline de abajo. Sustituye a `depend`, desaconsejado.

## T

**Token de disparo** (*pipeline trigger token*) — Free. Credencial de larga vida para que un sistema externo cree pipelines por `POST .../trigger/pipeline`. Entre proyectos de la misma instancia sobra: `trigger:project`.

**`trigger:forward`** — Free. Qué variables viajan al pipeline de abajo: `yaml_variables` (sí, por defecto) y `pipeline_variables` (no, por defecto).

---

[← Volver a la Semana 11](../README.md)

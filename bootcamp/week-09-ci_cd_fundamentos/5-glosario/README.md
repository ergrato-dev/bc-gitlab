# 📖 Glosario — Semana 09

Términos que aparecen esta semana. El nombre real de la feature va en inglés entre paréntesis, y el **tier** cuando aplica.

El glosario acumulado de toda la plataforma está en [glosario-global](../../../docs/glosario-global.md).

---

## A

**`allow_failure`** — Palabra clave de job. Si el job falla, el pipeline sigue y termina en `success` con aviso. En `app`, la lleva `gobernanza`.

**Artefacto** (*job artifact*) — Free. Archivos que un job declara en `artifacts` y que GitLab guarda hasta su `expire_in`: los reciben los jobs de stages siguientes y se pueden descargar por API. El último correcto de cada rama se conserva aunque caduque.

**Authentication token** (*runner authentication token*) — Token con prefijo `glrt-` que GitLab devuelve al crear un runner y que `gitlab-runner register` guarda en `config.toml`. Identifica a ese runner concreto.

## C

**Caché** (*cache*) — Free. Archivos que un job guarda para que otros jobs con la misma clave los reutilicen, sin garantía de que estén. En el runner del laboratorio vive en volúmenes Docker locales; la caché compartida llega en la Semana 15.

**`CI_JOB_TOKEN`** — Token que recibe cada job, válido mientras el job corre, con los permisos de quien lanzó el pipeline y solo en los endpoints que lo aceptan. Va en la cabecera `JOB-TOKEN`.

**`config.toml`** — Configuración del runner: `concurrent`, y por cada runner registrado su URL, `clone_url`, ejecutor e imagen por defecto.

**`coverage`** — Palabra clave de job: una expresión regular que GitLab aplica al log para sacar el porcentaje de cobertura del pipeline y de la insignia `coverage.svg`. Free.

## E

**Ejecutor** (*executor*) — Cómo ejecuta un runner los jobs: `shell`, `docker`, `kubernetes`, `docker-autoscaler`… `app` usa `docker`: un contenedor nuevo por job.

**`extends`** — Palabra clave que copia en un job la configuración de otro, normalmente oculto. Mezcla los mapas en profundidad y sustituye las listas.

## F

**`failure_reason`** — Campo de un job fallido que dice por qué: `script_failure`, `stuck_or_timeout_failure`, `runner_system_failure`, `job_execution_timeout`…

## I

**Informe** (*artifacts report*) — Artefacto que GitLab lee y presenta: `reports:junit` da la pestaña de tests y el resumen en la merge request. Free.

**Integración continua** (*continuous integration*, CI) — Construir y probar cada cambio en cuanto llega al servidor, en un entorno limpio, con el resultado junto al cambio.

**`interruptible`** — Palabra clave de job: un pipeline más nuevo de la misma rama puede cancelarlo mientras corre.

## J

**Job** — Free. Unidad de ejecución de un pipeline: un script que corre en un runner, en su propio entorno.

**Job oculto** (*hidden job*) — Job cuyo nombre empieza por punto. No se ejecuta; sirve de plantilla para `extends`.

## P

**Pipeline** — Free. Todo lo que se ejecuta para un commit: stages y jobs, creados por GitLab a partir de `.gitlab-ci.yml`.

**Pipelines must succeed** — Free. Ajuste del proyecto (`only_allow_merge_if_pipeline_succeeds`) que impide fusionar una merge request sin pipeline en verde.

**Token de acceso de proyecto** (*project access token*) — Token de un usuario bot que solo es miembro de un proyecto, con rol y scopes elegidos y caducidad obligatoria. Free en self-managed; en GitLab.com, Premium.

## R

**Runner** — Programa (`gitlab-runner`) que pide jobs a GitLab y los ejecuta. De instancia, de grupo o de proyecto, todos Free.

## S

**Stage** — Grupo de jobs de un pipeline. Los stages van en orden; `.pre` y `.post` existen siempre.

## V

**Variable de instancia** (*instance CI/CD variable*) — Free. Variable CI/CD que llega a todos los pipelines de la instancia. En el laboratorio, `CI_API_V4_URL` y `CI_SERVER_URL` apuntan a `http://gitlab:8888`.

**Variable oculta** (*hidden variable*) — Variable enmascarada cuyo valor ya no se puede ver en la interfaz ni en la API. Solo se activa al crearla (`masked_and_hidden`).

## W

**`workflow:rules`** — Reglas que deciden si se crea el pipeline entero. En `app`, evitan el pipeline duplicado de rama y de merge request.

---

[← Volver a la Semana 09](../README.md)

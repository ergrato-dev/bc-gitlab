# 📖 Glosario — Semana 10

Términos que aparecen esta semana. El nombre real de la feature va en inglés entre paréntesis, y el **tier** cuando aplica.

El glosario acumulado de toda la plataforma está en [glosario-global](../../../docs/glosario-global.md).

---

## A

**Ámbito de entorno** (*environment scope*) — Free. Atributo de una variable CI/CD: el nombre de entorno (o patrón, como `review/*`) para el que vale. Un job solo recibe la variable si su `environment` coincide. Organiza; no protege.

**`auto_cancel`** — Free. Clave de `workflow`. `on_new_commit` decide qué se cancela del pipeline anterior cuando llega un commit nuevo a la misma ref: `conservative`, `interruptible` o `none`.

## C

**`changes`** — Free. Condición de una regla: cierta si el cambio toca alguno de los archivos de `paths`. Compara con la rama de destino en una merge request y con el push anterior en una rama; en ramas nuevas, tags y pipelines manuales es siempre cierta.

**`CI_DEBUG_TRACE`** — Variable que activa la traza del shell en el job y escribe en el log todas sus variables. Las enmascaradas salen como `[MASKED]`; las demás, incluido el contenido de las variables de tipo archivo, en claro.

**`ci_pipeline_variables_minimum_override_role`** — Free. Ajuste del proyecto: el rol mínimo para pasar variables al lanzar un pipeline. En 19.2.4 un proyecto nuevo nace con `developer`; `app` lo sube a `maintainer`.

## D

**Despliegue** (*deployment*) — Free. El registro que crea cada ejecución de un job con `environment`: entorno, ref, commit, job y estado. `GET .../deployments`.

## E

**Entorno** (*environment*) — Free. Un destino con nombre, URL, *tier* e historial de despliegues, creado la primera vez que un job lo declara. En `app`, `staging` y `production`.

**Entorno protegido** (*protected environment*) — **Premium**. Limita quién puede desplegar en un entorno. En CE se sustituye por un job manual que solo corre en una rama protegida y una variable protegida con ámbito.

**`exists`** — Free. Condición de una regla: cierta si alguno de los archivos existe en el repositorio.

## H

**Hidden** (*hidden variable*) — Free. Variable cuyo valor no se puede volver a leer en la interfaz ni por la API, ni siquiera un Maintainer. Se activa al crearla y no se desactiva. El job la recibe igual.

## I

**`id_tokens`** — Free. Palabra clave de job: el job recibe un JWT firmado por GitLab con su identidad (proyecto, ref, si es protegida), que un servicio externo verifica para entregarle un secreto de vida corta.

**Inventario de secretos** — En `app`, `docs/secretos.md`: una fila por secreto con tipo, ámbito, protección, quién puede leerlo de verdad, origen, rotación y qué pasa si se filtra. Nunca el valor.

## M

**Masked** (*masked variable*) — Free. Variable cuyo valor exacto se sustituye por `[MASKED]` en el log. En 19.2.4 exige ocho caracteres o más, en una sola línea y sin espacios. No impide que el job use o envíe el valor.

## P

**Precedencia de variables** (*variable precedence*) — Qué valor recibe un job cuando la misma variable está en varios sitios. De más a menos: pipeline, proyecto, grupo, instancia, job del YAML, global del YAML, predefinidas.

**Protected** (*protected variable*) — Free. Variable que solo se entrega a pipelines de ramas y tags protegidos. Es el único atributo que impide que un secreto llegue a una merge request.

## R

**Regla** (*rule*) — Free. Cada elemento de `rules`: una o varias condiciones (`if`, `changes`, `exists`) y lo que pasa si se cumplen (`when`, `allow_failure`, `variables`). Gana la primera que coincide; si ninguna coincide, el job no entra.

**Rotar** (*rotate*) — Sustituir un secreto por otro nuevo con los mismos permisos. Para tokens de proyecto, `POST .../access_tokens/<id>/rotate` crea el nuevo y revoca el anterior en una sola operación.

## S

**`secrets:`** — **Premium**. Palabra clave de job que pide un secreto a Vault, Azure Key Vault o GCP Secret Manager. En CE el lint la rechaza como clave desconocida; el sustituto es `id_tokens` y el cliente del gestor en el script.

**Secure file** (*project-level secure file*) — Free. Archivo de hasta 5 MB guardado cifrado en el proyecto y descargable con `CI_JOB_TOKEN`. Sin protección ni ámbito: cualquier Developer lo descarga. No es sitio para una clave privada.

## V

**Variable de pipeline** (*pipeline variable*) — Variable que se pasa al lanzar un pipeline a mano, por API, por trigger o en un pipeline programado. Gana a todas las demás.

**Variable de tipo archivo** (*file type variable*) — Free. Variable cuyo valor el runner escribe en un archivo temporal fuera del repositorio; el job recibe la ruta. Se puede proteger y limitar por entorno, pero no enmascarar si tiene varias líneas. En `app`, `DEPLOY_SSH_KEY`.

## W

**`when: manual`** — En una regla, el job entra en el pipeline pero espera a que alguien lo lance. Sin `allow_failure: true` en la misma regla, el pipeline se queda en `manual` en lugar de `success`.

**`workflow:name`** — Free. Nombre de cada pipeline, con variables. Se ve en la lista, en la API (`.name`) y en `CI_PIPELINE_NAME`.

**`workflow:rules`** — Free. Reglas que deciden si se crea el pipeline entero. Si ninguna coincide, no hay pipeline: `Review the workflow:rules configuration`.

---

[← Volver a la Semana 10](../README.md)

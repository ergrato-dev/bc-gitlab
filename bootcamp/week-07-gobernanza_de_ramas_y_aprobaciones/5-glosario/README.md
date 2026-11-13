# 📖 Glosario — Semana 07

Términos que aparecen esta semana. El nombre real de la feature va en inglés entre paréntesis, y el **tier** cuando aplica.

El glosario acumulado de toda la plataforma está en [glosario-global](../../../docs/glosario-global.md).

---

## A

**Allowed to unprotect** — **Premium**. Permiso aparte para quitar la protección de una rama. En CE no existe: cualquier Maintainer puede desproteger.

**Approval rules** — **Premium**. Reglas que exigen un número de aprobaciones, de ciertos usuarios, para fusionar. En CE se sustituyen por el server hook que exige `Approved-by:` y la auditoría `gobernanza`.

**`Approved-by:`** — *Trailer* que GitLab escribe en el commit al fusionar si la plantilla incluye `%{approved_by}`: una línea por persona que aprobó. Es lo que lee el hook de esta semana.

**Auditoría** — Comprobación que se ejecuta después y detecta lo que ya pasó. No bloquea. En `app`, `scripts/gobernanza.sh` y la foto de las protecciones.

## B

**Break-glass** (*procedimiento de emergencia*) — Forma prevista y escrita de saltarse una regla cuando hace falta, que deja rastro y no quita ninguna capa. En `app`, la autoaprobación del Owner con un issue `emergencia`.

## C

**CODEOWNERS** — Archivo que asigna dueños a rutas del repositorio. Gana la última regla que coincide. En **Premium**, GitLab lo muestra y puede exigir la aprobación del dueño; en CE no lo lee, y lo usa la auditoría.

**Code Owners approval** — **Premium**. Opción de la rama protegida que exige la aprobación del dueño de cada archivo tocado.

**Cuarentena** (*quarantine*) — Estado de los objetos de un `push` mientras se ejecuta el `pre-receive`: ya están en el servidor y Git los puede leer, pero ninguna referencia los apunta. Si el hook rechaza, se borran.

## D

**Default branch protection** — Free. Protección que recibe la rama por defecto de un proyecto al crearse. La fija la instancia y la puede sobrescribir el grupo con `default_branch_protection_defaults`.

## G

**`gitaly hooks set`** — Free. Comando de Gitaly que instala los hooks de un repositorio a partir de un tarball con el directorio `custom_hooks/`. Con un tarball vacío, los quita.

**`GL-HOOK-ERR:`** — Prefijo que hace que GitLab muestre en la UI y en la API una línea escrita por un server hook. Las líneas sin él se descartan.

**`GL_PROTOCOL`** — Variable que recibe un server hook: `ssh`, `http` o `web`. `web` significa que el cambio lo hace GitLab (fusión, sugerencia, rebase, API de archivos).

## H

**`@hashed`** — Forma en que GitLab guarda los repositorios en disco: `@hashed/<2>/<2>/<sha256 del id>.git`. Hace falta para instalar un hook.

## N

**Nivel de acceso** (*access level*) — Número que una regla de protección compara con el rol: `0` nadie, `30` Developer, `40` Maintainer, `60` administradores de la instancia.

## P

**Pre-receive** — Hook del servidor que se ejecuta una vez por `push`, antes de actualizar ninguna referencia. Si sale con error, no entra nada.

**Push rules** — **Premium**. Formulario para rechazar `push` por firma, formato de mensaje o autor. En CE, un server hook `pre-receive` hace lo mismo.

## R

**Rama protegida** (*protected branch*) — Free. Regla que decide quién puede empujar, quién puede fusionar y si se puede forzar en una rama o un patrón.

**Rol efectivo** — El mayor entre el rol heredado del grupo y el directo en el proyecto. Es el que se compara con el nivel de acceso.

## S

**Server hook** — Free. Programa que Gitaly ejecuta en el servidor ante cada cambio de un repositorio, venga de un `push`, de la UI o de la API. Solo lo instala quien tiene una shell en el servidor.

## T

**Tag protegido** (*protected tag*) — Free. Regla que decide quién puede crear tags que coinciden con un patrón. Un tag protegido no se puede mover, y solo se borra desde la UI o la API.

---

[← Volver a la Semana 07](../README.md)

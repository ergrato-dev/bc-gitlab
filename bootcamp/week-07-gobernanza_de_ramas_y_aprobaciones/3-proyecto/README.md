# Proyecto Semana 07 — Las reglas se cumplen aunque nadie mire

> En la Semana 06 decidiste cómo se trabaja. Esta semana lo haces cumplir: `main` solo cambia por merge request, cada ruta tiene dueño, y un hook que ningún Maintainer puede quitar exige firma, formato y aprobación. Lo que no se puede bloquear, se detecta.

---

## 🎯 Objetivo

Dejar en pie la **capa 7** de tu plataforma: ramas y tags protegidos, `CODEOWNERS`, un server hook versionado e instalado, una auditoría por merge request, el ADR-005 con sus límites honestos, y un `CONTRIBUTING.md` que explica las reglas como las ve quien choca con ellas.

---

## 📦 Qué añade esta capa

La Semana 06 dejó el flujo por merge request como convención. Esta lo convierte en el único camino, y deja escrito qué pasa cuando alguien intenta otro.

| Lo que creas esta semana | Se usa a partir de |
|---|---|
| `main` y `v*` protegidos | S08 (la release `v0.1.0` nace protegida), S10 (las variables protegidas solo llegan a refs protegidas) |
| `CODEOWNERS` | S09 (el job de auditoría lo lee), S12 (los componentes de `ci/` tienen sus propios dueños) |
| `scripts/gobernanza.sh` | S09 (pasa a ser un job sin cambiar una línea), S11 (auditoría programada) |
| Server hook `pre-receive` | S08 (el CHANGELOG se genera desde asuntos que el hook garantiza convencionales), S18 (revisión de la instancia) |
| Protección por defecto del grupo | S11 y S12 (los proyectos nuevos nacen protegidos) |
| ADR-005 | S18 (endurecimiento), S26 (auditoría final) |
| La foto de las protecciones | Cada semana, hasta que la S11 la automatice |

La decisión con más recorrido es **qué hace el hook**. Cada regla que añadas la pagan todos los `push` y todas las fusiones, y quitarla después exige otro ADR. Por eso el hook de esta semana tiene cuatro reglas y ninguna más.

---

## ✅ Requisitos verificables

Los comprueba `./scripts/verificar-semana.sh 07` contra la API de tu instancia.

1. La rama main esta protegida
2. Nadie puede hacer push directo a main
3. Solo los Maintainers pueden fusionar en main
4. Nadie puede forzar el push sobre main
5. Los tags v* estan protegidos
6. Solo los Maintainers pueden crear tags v*
7. Existe un archivo CODEOWNERS en la raiz de main
8. CODEOWNERS tiene una regla por defecto para todo el repositorio
9. CODEOWNERS nombra un dueno para el propio CODEOWNERS
10. El script scripts/gobernanza.sh esta en main
11. El server hook esta versionado en scripts/hooks/pre-receive
12. La plantilla del commit de fusion incluye quien aprobo, o el metodo es fast-forward con squash obligatorio
13. El commit que trajo CODEOWNERS a main lleva un trailer Approved-by
14. Al menos cinco merge requests fusionadas fueron aprobadas por alguien distinto de su autor
15. La wiki tiene una pagina cuyo slug empieza por adr-005

Las prácticas 01 a 04 dejan los quince en verde. Ninguno comprueba que el hook esté **instalado**: eso no se ve desde la API. Lo demuestra la práctica 04 y lo puntúa la rúbrica.

---

## 🛠️ Lo que haces en el proyecto

### 1. `CONTRIBUTING.md`: las reglas, desde el lado de quien choca con ellas

El `CONTRIBUTING.md` de la Semana 06 describe el flujo. Añade una sección "Las reglas" que responda, para cada mensaje de rechazo que puede ver alguien que contribuye:

| Mensaje | Qué significa | Qué hacer |
|---|---|---|
| `You are not allowed to push code to protected branches` | Intentaste empujar a `main` | Rama con el número del issue y merge request |
| `GL-HOOK-ERR: … no está firmado` | | |
| `GL-HOOK-ERR: … es un merge commit` | | |
| `GL-HOOK-ERR: … no sigue Conventional Commits` | | |
| `GL-HOOK-ERR: nada entra en main sin una aprobación` | | |

Rellena la tabla con tus palabras. Añade quién es dueño de qué (enlazando a `CODEOWNERS`, sin copiarlo) y un enlace al ADR-005 para las emergencias.

Hazlo **como una merge request más**: issue `tipo::docs`, rama con su número, aprobación de `revisor` y fusión. Esta vez la fusión pasa por el hook. Si la rechaza, el mensaje de rechazo va directo a tu tabla.

### 2. `CODEOWNERS` por área

La Semana 05 creó las etiquetas `area::`. Si en `app` cada área vive en su propio archivo o directorio (`src/prestamos.ts`, `src/multas.ts`), añade una regla por área con su dueño. Si todavía está todo en un archivo, escribe en el ADR-005 cuándo lo dividirías y quién sería dueño de cada parte.

Cambiar `CODEOWNERS` es tocar `/CODEOWNERS`, que es de `revisor`: necesitas su aprobación, y la auditoría la comprobará con el `CODEOWNERS` de antes del cambio.

### 3. El ADR-005, completo

Revisa el ADR de la práctica 04 con lo que viste en los pasos 2 a 5. Tiene que decir, con tus datos:

- Qué capa cayó y cuál aguantó cuando `revisor` quitó la protección
- Las merge requests de la Semana 06 que no pasan la auditoría de hoy, y por qué no se arreglan
- El procedimiento de emergencia, con el comando exacto para quitar el hook y quién puede ejecutarlo

Enlázalo desde la barra lateral de la wiki, junto al ADR-004.

### 4. La auditoría, como costumbre

Añade a `~/.bc-gitlab` un alias o una función que ejecute la foto de las protecciones y el bucle de `gobernanza.sh` sobre las merge requests fusionadas. Ejecútalo al terminar el proyecto y pega la salida al final del ADR-005, con la fecha. Es tu primera entrada del registro de auditoría.

---

## 🎨 Criterios de calidad

Lo que la API confirma que existe pero no puede juzgar:

- **El hook está instalado y es idéntico al de `main`.** Lo comprueba el `diff` de la práctica 03, paso 5.
- **El hook se probó en local antes de instalarlo**, con casos que pasan y casos que fallan.
- **Cada mensaje de rechazo dice qué hacer**, no solo qué falló.
- **`CODEOWNERS` tiene lo general arriba y lo específico abajo**, y ningún dueño que no sea miembro de `app`.
- **El ADR-005 nombra sus propios huecos**: autoaprobación, trailer falsificable, Maintainer que desprotege. Un ADR que dice que todo está bloqueado no es honesto.
- **El procedimiento de emergencia no quita ninguna capa.**
- **El token de `revisor` está revocado**, comprobado en negativo.
- **`CONTRIBUTING.md` explica las reglas a quien choca con ellas**, con los mensajes literales.

---

## 💡 Adaptación a tu dominio

Las reglas son las mismas. Lo que cambia es qué rutas merecen dueño propio y por qué.

| Dominio | Ruta que pide dueño propio | Por qué |
|---|---|---|
| 📖 Biblioteca | El cálculo de multas | Un error cobra dinero a los socios |
| 🏋️ Gimnasio | La lógica de cupos de clase | Un error deja a gente fuera o mete más de los que caben |
| 🎥 Cine | La reserva de asientos | Un error vende el mismo asiento dos veces |
| 💊 Farmacia | El control de caducidad de lotes | Un error dispensa un medicamento caducado |

El patrón: **el dueño propio va donde un error tiene consecuencias fuera del código**. El resto puede ir a la regla por defecto.

---

## 🚦 Cómo entregarlo

No hay nada que subir a ningún sitio. El entregable **es el estado de tu proyecto, su wiki y el hook instalado en tu instancia**.

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 07
```

```
15 de 15 verificaciones superadas.
```

Si alguna falla, la pista dice en qué práctica y en qué paso se arregla.

---

## 🧯 Errores comunes

| Error | Cómo se detecta | Solución |
|---|---|---|
| `main` con `push = Maintainers` "para poder arreglar algo rápido" | Falla el requisito 2 | `push = No one`; las urgencias van por el procedimiento del ADR-005 |
| `*` al final de `CODEOWNERS` | La auditoría pide la aprobación de los dueños por defecto en `src/` | `*` la primera línea |
| El hook instalado no es el de `main` | No lo detecta ninguna comprobación; lo detecta el `diff` de la práctica 03 | Reinstalar con `git show main:scripts/hooks/pre-receive` |
| Las fusiones fallan con un error genérico | `merge_error` sin `nada entra en main` ni `Conventional Commits` | El hook falla antes de rechazar: quitarlo, probar en local con `bash -x`, reinstalar |
| Título de MR no convencional | La fusión falla por el hook | Cambiar el título y volver a fusionar |
| Autoaprobar para que el hook deje pasar | Falla la auditoría; en la rúbrica, penalización | Aprobación de `revisor`, o el procedimiento de emergencia con su issue |
| Quitar la protección en vez de seguir el procedimiento | La foto de las protecciones cambia | Restaurar desde la foto; documentarlo en el ADR |
| El token del revisor sin revocar | No lo detecta ninguna comprobación | Práctica 04, paso 8 |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Proyecto Semana 06](../../week-06-merge_requests_y_code_review/3-proyecto/README.md) | **Proyecto Semana 07** | Proyecto Semana 08 |

[← Volver a la Semana 07](../README.md)

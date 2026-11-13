# Proyecto Semana 06 — Nada entra sin revisión

> `main` deja de ser el sitio donde se escribe y pasa a ser el sitio donde se acepta. Cada cambio nace de un issue, lo lee otra identidad, y entra con una estrategia que alguien decidió y dejó escrita.

---

## 🎯 Objetivo

Dejar en pie la **capa 6** de tu plataforma: un proyecto configurado para revisar, una plantilla que traza cada merge request a su issue, una estrategia de fusión registrada en el ADR-004, tres merge requests revisadas y fusionadas, y un `CONTRIBUTING.md` que describe el flujo que de verdad sigues.

---

## 📦 Qué añade esta capa

La Semana 05 dejó el trabajo modelado: backlog, hito y tablero. Esta conecta ese trabajo con el código: **cada issue que se cierra lo cierra una merge request revisada**, y la historia de `main` dice quién revisó cada cambio.

| Lo que creas esta semana | Se usa a partir de |
|---|---|
| Método de fusión, squash y hilos obligatorios | S07 (la rama protegida hace que no haya otro camino), S11 (los pipelines de MR) |
| Plantilla del commit de squash con *trailers* | S08 (changelog y métricas por merge request) |
| `Default.md` de merge request | S07 (el script `gobernanza` comprueba que la MR cierra un issue; job desde la S09), S12 (se comparte como componente) |
| ADR-004 | S08 (GitLab Flow parte de esta decisión), S26 (auditoría) |
| Tres merge requests fusionadas | S08 (las primeras entradas del changelog de `v0.1.0`) |
| `revisor` como revisor habitual | S07 (CODEOWNERS lo nombra) |
| `CONTRIBUTING.md` con el flujo real | S07 (las reglas que se harán cumplir son exactamente estas) |

La decisión con más recorrido de esta semana es **la estrategia de fusión**. Se puede cambiar en un minuto, pero la historia ya escrita no cambia con ella: si en dos meses pasas de `rebase_merge` a `merge`, `git log` mezclará dos estilos para siempre. Por eso va en un ADR, y cambiarla exige otro.

---

## ✅ Requisitos verificables

Los comprueba `./scripts/verificar-semana.sh 06` contra la API de tu instancia.

1. El proyecto usa un metodo de fusion con historia lineal o semilineal
2. El squash viene marcado por defecto o es obligatorio
3. Solo se puede fusionar con todos los hilos resueltos
4. La rama de origen se borra por defecto al fusionar
5. La plantilla del commit de squash incluye a quien reviso
6. Existe la plantilla de merge request Default
7. La plantilla Default pide el issue que se cierra
8. La wiki tiene una pagina cuyo slug empieza por adr-004
9. El proyecto tiene al menos tres merge requests fusionadas
10. Al menos tres merge requests fusionadas cierran un issue desde su descripcion
11. Al menos tres merge requests fusionadas tienen un revisor distinto de su autor
12. Al menos una merge request fusionada tiene dos o mas comentarios
13. Al menos una merge request se fusiono con squash
14. Al menos una merge request fusionada fue aprobada por alguien distinto de su autor
15. Al menos una merge request fusionada recibio una sugerencia de codigo
16. El proyecto tiene al menos cuatro issues cerrados

Las prácticas 01 a 04 dejan los dieciséis en verde. El proyecto es lo que convierte eso en una forma de trabajar: lo que sigue.

---

## 🛠️ Lo que haces en el proyecto

### 1. `CONTRIBUTING.md` con el flujo real, por merge request

El `CONTRIBUTING.md` de la Semana 04 dice "rama desde `main`: `git switch -c feat/nombre-corto`". Ya no es verdad. Reescribe la sección "El flujo" para que describa lo que haces desde esta semana:

- Todo cambio nace de un issue del backlog
- La rama empieza por el número del issue: `7-la-multa-cuenta-los-domingos`
- La merge request se abre en borrador, con la plantilla `Default` rellena
- `revisor-<dominio>` como revisor; los hilos los resuelve quien los abre
- Squash por defecto, con la plantilla de commit del proyecto
- Los commits que crea GitLab (sugerencias, squash, rebase en el servidor) no llevan firma, y eso está aceptado

Y hazlo **como una cuarta merge request**: issue `tipo::` que corresponda, rama con su número, revisión de `revisor` y fusión. Cambiar las reglas del flujo pasando por el flujo es la prueba de que el flujo funciona.

### 2. El ADR-004, completo

Revisa el ADR de la práctica 01 con la experiencia de la práctica 04 delante. Tiene que decir qué pasó cuando dos merge requests tocaron la misma función, y si eso cambia algo de la decisión. Enlázalo desde la barra lateral de la wiki y desde `CONTRIBUTING.md`.

### 3. El tablero, al día

Los issues que cerraron las merge requests están en la columna *Closed* del tablero `Flujo`. Comprueba que ningún issue abierto se ha quedado en `estado::en-revision` sin merge request abierta: es la señal de un cambio que se abandonó sin decirlo.

```bash
curl -s -H "$H" "$API/projects/$P/issues?state=opened&labels=estado::en-revision&per_page=100" \
  | jq -r '.[] | "#\(.iid) \(.title)"'
```

---

## 🎨 Criterios de calidad

Lo que la API confirma que existe pero no puede juzgar:

- **Cada merge request hace una sola cosa**, y su título lo dice en formato convencional.
- **La descripción responde a las cuatro preguntas** de la plantilla, sin secciones vacías ni "ver issue".
- **Los comentarios del revisor dicen si bloquean.** `issue (blocking):`, `nitpick:`, `question:`: el autor nunca tiene que adivinar.
- **Los hilos los resuelve quien los abrió**, y el autor responde antes de que se resuelvan.
- **La resolución del conflicto aplica las dos reglas**, y el revisor la vio antes de fusionar.
- **Los commits de squash cuentan la historia**: título, referencia, issue y quién revisó. Nada de casillas de plantilla en `git log`.
- **El ADR-004 tiene las dos caras de las consecuencias**, incluido el precio que pagaste en la práctica 04.
- **`CONTRIBUTING.md` describe tu flujo real.** Si algo de lo que dice no lo hiciste en las cuatro merge requests, sobra o falta algo.

---

## 💡 Adaptación a tu dominio

El flujo es el mismo en todos los dominios. Lo que cambia son los cambios que se revisan y los conflictos que aparecen.

| Dominio | Un bug para la práctica 02 | Dos issues que chocan en la práctica 04 |
|---|---|---|
| 📖 Biblioteca | La multa cuenta los domingos | Préstamo vencido bloquea / multa de céntimos tolerada |
| 🏋️ Gimnasio | Se puede reservar una clase con el cupo lleno | Socio con cuota impagada no reserva / socio invitado reserva una vez |
| 🎥 Cine | Dos personas pueden comprar el mismo asiento | Asiento accesible solo para quien lo pide / reserva caduca a los diez minutos |
| 💊 Farmacia | Un lote caducado sigue apareciendo como disponible | Lote retirado no se dispensa / lote que caduca este mes se dispensa primero |

El patrón se repite: **los conflictos interesantes no son de sintaxis, son de reglas**. Dos cambios correctos por separado que, juntos, obligan a decidir qué pasa cuando se cumplen las dos condiciones.

---

## 🚦 Cómo entregarlo

No hay nada que subir a ningún sitio. El entregable **es el estado de tu proyecto, sus merge requests y su wiki**.

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 06
```

```
16 de 16 verificaciones superadas.
```

Si alguna falla, la pista dice en qué práctica y en qué paso se arregla.

---

## 🧯 Errores comunes

| Error | Cómo se detecta | Solución |
|---|---|---|
| Activar *Pipelines must succeed* | Ninguna merge request se puede fusionar: `ci_must_pass` | Desactivarlo hasta la Semana 09 |
| La plantilla de squash escrita con `\n` literales | El commit sale en una línea con barras | Construirla con `printf` (práctica 01, paso 3) |
| Merge requests abiertas por API sin descripción | Falla el requisito 10: no cierran nada | Rama con el número del issue y *push options*, o `Closes #N` en la descripción |
| Comentarios del revisor publicados con tu token | Falla el requisito 14, y el 11 si te asignaste como revisor | `$HR` para todo lo que hace `revisor` |
| Revisión sin enviar | Los comentarios no se ven, y no hay `Reviewed-by:` | `bulk_publish` (práctica 03, paso 4) |
| Squash desmarcado al fusionar | Falla el requisito 13 | `squash=true` en la fusión por API |
| Fusionar con `merge_method=merge` y cambiarlo después | Los requisitos pasan, pero la historia mezcla estilos | Configurar antes de la primera fusión |
| Conflicto resuelto eligiendo una de las dos ramas | No lo detecta ninguna comprobación; lo detecta la rúbrica, y un test | Las dos reglas, y un test que lo pruebe |
| El token del revisor sin revocar | No lo detecta ninguna comprobación | Práctica 04, paso 9 |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Proyecto Semana 05](../../week-05-issues_etiquetas_y_tableros/3-proyecto/README.md) | **Proyecto Semana 06** | [Proyecto Semana 07](../../week-07-gobernanza_de_ramas_y_aprobaciones/3-proyecto/README.md) |

[← Volver a la Semana 06](../README.md)

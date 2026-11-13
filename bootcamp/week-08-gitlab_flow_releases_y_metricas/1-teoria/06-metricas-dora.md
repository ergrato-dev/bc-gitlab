# Las métricas DORA

> "¿Vamos bien?" no se responde con sensaciones. Cuatro números, medidos igual cada semana, dicen si el equipo entrega más rápido sin romper más. Y dicen poco más que eso: el resto del trabajo es que nadie los convierta en objetivo.

---

## 🎯 Objetivos

- Definir las cuatro métricas DORA y decir qué mide cada una: velocidad o estabilidad
- Explicar por qué se miran en pareja y no por separado
- Saber qué ofrece GitLab para medirlas y en qué tier, y qué queda en CE
- Reconocer la ley de Goodhart en las métricas de entrega y evitar sus usos dañinos
- Decidir qué aproxima cada métrica en `app` mientras no hay despliegues

---

## 1. Qué problema resuelve

Sin métricas, la conversación sobre el proceso se gana por insistencia. "Las revisiones nos frenan", "publicamos demasiado poco", "cada release rompe algo": todo puede ser verdad o no, y sin números no se sabe.

El programa **DORA** (*DevOps Research and Assessment*), con datos de miles de equipos desde 2014, encontró que cuatro métricas de entrega bastan para distinguir a los equipos que entregan bien de los que no, y que velocidad y estabilidad **no** se oponen: los mejores equipos son rápidos y estables a la vez.

---

## 2. Cómo funciona

### 2.1 Las cuatro métricas

| Métrica | Pregunta | Mide |
|---|---|---|
| **Frecuencia de entrega** (*deployment frequency*) | ¿Cada cuánto llega un cambio a producción? | Velocidad |
| **Tiempo de entrega de cambios** (*lead time for changes*) | ¿Cuánto tarda un commit en llegar a producción? | Velocidad |
| **Tasa de fallo de cambios** (*change failure rate*) | ¿Qué parte de las entregas necesita un arreglo urgente? | Estabilidad |
| **Tiempo de restauración** (*failed deployment recovery time*) | Cuando una entrega falla, ¿cuánto se tarda en recuperar el servicio? | Estabilidad |

La cuarta se llamó *time to restore service* (MTTR) hasta el informe de 2023, que la acotó a los fallos causados por una entrega. Los informes recientes añaden una quinta, la **fiabilidad** (cumplir los objetivos de servicio). En el bootcamp, la idea reaparece con los SLO de la instancia en la Semana 21.

### 2.2 Siempre en pareja

Cada métrica de velocidad tiene una de estabilidad que la vigila:

- Subir la **frecuencia** publicando sin probar dispara la **tasa de fallo**.
- Bajar el **tiempo de entrega** saltándose la revisión dispara el **tiempo de restauración**, porque nadie entiende lo que entró.

Un equipo que solo mira la velocidad acaba rompiendo más. Uno que solo mira la estabilidad acaba publicando una vez al trimestre, con lotes enormes que, paradójicamente, fallan más. Por eso las cuatro se presentan juntas, o ninguna.

### 2.3 Las categorías de rendimiento

Cada informe anual agrupa a los equipos en categorías (*elite*, *high*, *medium*, *low*) según los valores de las cuatro métricas. Los umbrales cambian de un año a otro, pero la forma es estable: los equipos *elite* entregan bajo demanda, varias veces al día, con tiempos de entrega de menos de un día, pocos fallos y recuperación en menos de una hora.

No compares `app` con esas cifras: es un proyecto de laboratorio con una persona. Lo útil es la **tendencia de tus propios números**, semana a semana.

### 2.4 Lo que ofrece GitLab, por tier

| Herramienta | Qué da | Tier |
|---|---|---|
| *DORA metrics* (gráficos y API `dora/metrics`) | Las cuatro métricas calculadas desde despliegues e incidentes | **Ultimate** |
| *Insights* | Gráficos configurables sobre issues y merge requests | **Ultimate** |
| *Value Stream Analytics* de grupo y etapas personalizadas | El tiempo que pasa un cambio en cada etapa, para varios proyectos | **Premium** |
| *Value Stream Analytics* de proyecto | Etapas por defecto (issue, plan, código, test, revisión, staging) de un proyecto | CE |
| *CI/CD analytics* | Éxito y duración de los pipelines | CE |
| API de merge requests, releases, issues y despliegues | Los datos en bruto, con sus fechas | CE |

En CE, las métricas se **calculan** con la API. Es más trabajo, y a cambio la definición de cada métrica es tuya, está escrita y se puede discutir.

La de proyecto está en `Analyze → Value stream analytics`, o en `<proyecto>/-/value_stream_analytics`. Mírala una vez esta semana: es la vista que más se parece a lo que vas a calcular.

### 2.5 Qué aproximar en `app` sin despliegues

`app` todavía no se despliega en ningún sitio: los entornos llegan en la Semana 14. Mientras tanto, **la release es la entrega**: es el momento en que un cambio llega a quien usa `app`.

| Métrica | En `app`, esta semana | Lo que no captura |
|---|---|---|
| Frecuencia de entrega | Releases publicadas por semana | Que una release no es un despliegue |
| Tiempo de entrega | De la creación de la merge request a su fusión | El tiempo hasta la release, y el que pasa en local antes de abrirla |
| Tasa de fallo | Releases que tuvieron un parche (`vX.Y.Z+1`) / releases | Fallos que nadie arregló con un parche |
| Tiempo de restauración | De la apertura de un issue `tipo::bug` a su cierre | El tiempo hasta que el arreglo se publica |

Son aproximaciones, y está bien mientras lo digan. La teoría [07](07-dora-lite-con-la-api.md) las calcula, y `docs/metricas.md` las deja escritas con sus límites. Cuando lleguen los entornos, cambiará la fuente de la frecuencia y del tiempo de entrega, no la idea.

### 2.6 La ley de Goodhart

"Cuando una medida se convierte en objetivo, deja de ser una buena medida." Con las métricas de entrega pasa así:

| Si el objetivo es… | Lo que ocurre |
|---|---|
| Más releases | Releases vacías o partidas en trozos sin sentido |
| Menos tiempo de entrega | Merge requests abiertas cuando ya están aprobadas en privado |
| Menos tasa de fallo | Los arreglos dejan de etiquetarse como `tipo::bug` |
| Menos tiempo de restauración | Issues de bug cerrados antes de comprobar el arreglo |

Las métricas sirven para hacer preguntas al equipo, no para evaluar a personas ni para comparar equipos con contextos distintos.

---

## 3. Cómo se configura

Nada que activar en CE. Lo que sí se decide, y se escribe en `docs/metricas.md`:

| Decisión | En `app` |
|---|---|
| Qué cuenta como entrega | Una release sin pre-release |
| Qué cuenta como fallo | Una versión que necesitó un parche |
| De dónde salen las fechas | `released_at`, `created_at`, `merged_at` y `closed_at` de la API |
| Ventana de medida | Los últimos 30 días |
| Estadístico | La mediana: un caso extremo no la mueve |

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Medir una sola métrica | Se optimiza a costa de la que nadie mira | Las cuatro, siempre juntas |
| Media en lugar de mediana | Una merge request olvidada un mes dispara el tiempo de entrega | Mediana, y mira los extremos aparte |
| Métricas por persona | Se juega con los datos y se rompe la colaboración | Métricas de equipo |
| Comparar con las cifras *elite* del informe | Contextos distintos; desanima o tranquiliza sin motivo | Tu tendencia, semana a semana |
| Definición implícita ("lead time es lo que dice la herramienta") | Nadie sabe qué mide, y cambia al cambiar de herramienta | Definición escrita en `docs/metricas.md` |
| Medir sin decidir nada | Números que nadie lee | Cada métrica con la pregunta que responde |

---

## 5. Trucos

- **Cuatro números, una línea**: preséntalos siempre en el mismo orden (frecuencia, tiempo de entrega, tasa de fallo, restauración) para que la vista aprenda dónde buscar.
- **Anota los cambios de proceso.** Si un número cambia la semana que activaste squash obligatorio, apúntalo en `docs/metricas.md`. Sin contexto, una serie temporal no explica nada.
- **Pocos datos, pocas conclusiones.** Con dos releases, la tasa de fallo es 0 %, 50 % o 100 %. Dilo así.

---

## 📚 Recursos Adicionales

- [DORA — Get better at getting better](https://dora.dev/) — las métricas, los informes anuales y el cuestionario rápido
- [DORA's software delivery metrics: the four keys](https://dora.dev/guides/dora-metrics-four-keys/) — definiciones actuales de cada métrica
- [DORA metrics en GitLab](https://docs.gitlab.com/user/analytics/dora_metrics/) — lo que calcula Ultimate y de dónde saca los datos
- [Value Stream Analytics](https://docs.gitlab.com/user/group/value_stream_analytics/) — etapas, y qué es de proyecto y qué de grupo

---

## ✅ Checklist de Verificación

- [ ] Sabes las cuatro métricas y cuáles miden velocidad y cuáles estabilidad
- [ ] Sabes por qué se miran en pareja
- [ ] Sabes qué herramientas de GitLab son Ultimate, cuáles Premium y cuáles CE
- [ ] Sabes qué aproxima cada métrica en `app` y qué deja fuera
- [ ] Puedes poner un ejemplo de la ley de Goodhart con cada métrica

---

[← Anterior: Ramas de release y cherry-pick](05-ramas-de-release-y-cherry-pick.md) · [Volver a la Semana 08](../README.md) · [Siguiente: DORA-lite con la API →](07-dora-lite-con-la-api.md)

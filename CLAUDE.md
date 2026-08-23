# CLAUDE.md — bc-gitlab

Bootcamp GitLab CE Zero to Platform Engineer (26 semanas, 208 h, ergrato-dev).
Trata **GitLab como plataforma de ingeniería que el alumno opera**, no como el
sitio donde sube el código. Edición **CE pura**, autohospedada en Docker, versión
fijada `19.1.1-ce.0`, instancia en `http://localhost:8888`. Modalidad:
**autoestudio asincrónico**, 8 h/semana, máquina de 16 GB.

Las convenciones de contenido pedagógico (estructura de semana, tono, malla,
checklist de nueva semana, reglas de seguridad del contenido) viven en
[`.github/copilot-instructions.md`](.github/copilot-instructions.md) — léelo
antes de crear o editar contenido de cualquier semana. No se duplican aquí.

## Prompts reutilizables

`.github/prompts/` tiene plantillas para tareas recurrentes — úsalas en vez de
generar contenido libre: `nueva-semana`, `nueva-teoria`, `nueva-practica`,
`nuevo-proyecto`, `checks-json`, `svg-diagrama`, `commit-message`.

## Skills y agentes

`.claude/skills/`: `verificar-estructura` (enlaces, navegación y lo que el
script no ve), `verificar-comandos-glab` (que los comandos y endpoints existan
de verdad), `sincronizar-trucos` (README de semana ↔ `docs/trucos-gitlab.md`).

`.claude/agents/`: `curriculo-coherencia-reviewer` (malla ↔ semanas ↔ 8 h),
`seguridad-contenido-reviewer` (tokens, `rules`, imágenes sin pinnear).

## Estructura por semana

```
week-XX-tema/
├── README.md · rubrica-evaluacion.md (30% conocimiento / 40% desempeño / 30% producto)
├── checks.json (autograding declarativo contra la API v4)
├── 0-assets/ · 1-teoria/ · 2-practicas/ · 3-proyecto/ · 4-recursos/ · 5-glosario/
```

## Reglas que rompen fácil

- **No inventes endpoints, palabras clave ni nombres de features.** Es el fallo
  más probable en este repo: un endpoint de la API v4 plausible pero inexistente,
  una palabra clave de `.gitlab-ci.yml` que no existe, un subcomando de `glab`
  inventado. Pasa desapercibido en revisión y revienta cuando el alumno lo
  ejecuta. Compruébalo contra la instancia o enlaza `docs.gitlab.com`. Usa el
  skill `verificar-comandos-glab`.
- **Marca el tier de toda feature de pago** y di con qué se sustituye en CE. La
  tabla completa de sustituciones está en el `README.md` raíz. El error contrario
  también cuenta: Praefect, los componentes CI/CD, los feature flags, el
  dependency proxy, el estado de Terraform y Auto DevOps **son gratis** y el
  material tiene que decirlo.
- **Nunca un token con formato válido**, ni falso. `glpat-` más veinte caracteres
  dispara la detección de secretos del propio GitLab. Usa `<TOKEN>` o
  `$CI_JOB_TOKEN`.
- **Todo `.gitlab-ci.yml` de ejemplo lleva `rules`.** Sin ellas el pipeline se
  duplica en cada merge request y se enseña el antipatrón. `only`/`except` solo
  se menciona como legado.
- **Las prácticas son operaciones sobre GitLab, no código en `starter/`.** El
  entregable es el estado real de la instancia, verificado con la API v4.
- **`docker compose` es el único método de instalación.** No sugieras Omnibus en
  el host ni Helm para la instancia. Los perfiles (`base`, `observabilidad`,
  `ha`) son mutuamente excluyentes en memoria: ver
  [`docs/perfiles-de-laboratorio.md`](docs/perfiles-de-laboratorio.md).
- **Una sola instancia y un solo grupo hilo conductor**, no un proyecto
  desechable por semana. Ver
  [`docs/proyecto-hilo-conductor.md`](docs/proyecto-hilo-conductor.md).
- **Si un entregable no se puede verificar por API, no es entregable
  obligatorio** — va a la rúbrica manual. Nunca metas lógica bash específica de
  una semana en `verificar-semana.sh`; declara la comprobación en `checks.json`.
- **La tabla de tiempos del README de cada semana suma 8 h exactas.** Si suma
  más, la semana está sobrecargada: se recorta el alcance, no se maquilla la tabla.
- **Diagramas en SVG, nunca arte ASCII.** Paleta y reglas en la guía de autoría.
- Antes de cerrar cualquier cambio: `bash scripts/verificar-enlaces.sh` sin
  errores. Los enlaces desde `bootcamp/week-NN/README.md` a la raíz son
  `../../README.md` (2 niveles).

## Contenido heredado

`bootcamp/_legado/` tiene las 13 semanas de la malla antigua (6 h/semana, 5
archivos de teoría). Es **material de partida, no contenido publicable**: cada
semana nueva toma lo que le sirve, lo reescribe al estándar actual y borra lo que
consumió. La correspondencia antigua → nueva está en
[`docs/decision-renombre-semanas.md`](docs/decision-renombre-semanas.md). Cuando
`_legado/` quede vacío, bórralo junto con su exclusión en
`scripts/verificar-enlaces.sh`.

## Ritmo de trabajo

Una semana por tanda, de la 01 a la 26. La tanda termina con
`bash scripts/verificar-enlaces.sh` en verde y un commit:

```
feat(week-NN): contenido completo de la Semana NN — <tema>
```

## Enlaces

- [docs/](docs/README.md) — setup, hilo conductor, autograding, perfiles, trucos, glosario
- [Checklist de nueva semana](.github/copilot-instructions.md) (sección final)

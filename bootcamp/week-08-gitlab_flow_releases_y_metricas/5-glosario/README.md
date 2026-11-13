# 📖 Glosario — Semana 08

Términos que aparecen esta semana. El nombre real de la feature va en inglés entre paréntesis, y el **tier** cuando aplica.

El glosario acumulado de toda la plataforma está en [glosario-global](../../../docs/glosario-global.md).

---

## C

**`changelog_config.yml`** — Archivo `.gitlab/changelog_config.yml` de la rama por defecto que configura el CHANGELOG generado: categorías, plantilla, formato de fecha y `tag_regex`. Free.

**CHANGELOG generado** (*changelog*) — Free. Sección de notas de una versión que GitLab construye con los commits del rango que llevan el trailer `Changelog:`. `GET .../repository/changelog` la devuelve; `POST` la escribe en un archivo con un commit.

**`Changelog:`** — *Trailer* que marca un commit para el CHANGELOG. Su valor es la categoría: `added`, `fixed`, `changed`, `deprecated`, `removed`, `security`, `performance` u `other`.

**Cherry-pick** — Aplicar los cambios de un commit sobre otra rama, en un commit nuevo. Con `-x`, Git añade `(cherry picked from commit <sha>)` al mensaje.

## D

**DORA** (*DevOps Research and Assessment*) — Programa de investigación que definió las cuatro métricas de entrega: frecuencia de entrega, tiempo de entrega de cambios, tasa de fallo de cambios y tiempo de restauración. Los gráficos y la API `dora/metrics` de GitLab son **Ultimate**; en CE se calculan con la API.

**DORA-lite** — Nombre que usa el bootcamp para las cuatro métricas calculadas con la API de CE y aproximaciones documentadas en `docs/metricas.md`.

## E

**Evidencia de release** (*release evidence*) — Free. Foto JSON del proyecto, sus hitos y sus issues en el momento de publicar una release. No se genera para releases históricas.

## G

**Git Flow** — Modelo de ramas con `main`, `develop`, `feature/*`, `release/*` y `hotfix/*`. Pensado para software con publicaciones espaciadas; su coste es la doble integración.

**GitHub Flow** — Modelo con una sola rama de larga vida, `main`, y ramas cortas que vuelven por merge request y se despliegan.

**GitLab Flow** — Modelo que parte de GitHub Flow y añade ramas de larga vida solo cuando hacen falta: de entorno o de release. Su regla es *upstream first*.

## L

**Ley de Goodhart** — "Cuando una medida se convierte en objetivo, deja de ser una buena medida". La razón por la que las métricas DORA no se usan como objetivo ni para evaluar personas.

## P

**Parche** (*patch release*) — Versión que solo sube `PARCHE` y solo contiene arreglos. En `app` sale de una rama `release/X.Y`.

## R

**Rama de release** (*release branch*) — Rama de larga vida `release/X.Y` que contiene una versión `MENOR` y sus parches. En `app` nace desde el tag `vX.Y.0` cuando hace falta el primer parche.

**Release** — Free. Página de GitLab asociada a un tag, con notas, hitos, assets y evidencia. Borrarla no borra el tag.

**Release histórica / próxima** (*historical / upcoming release*) — Release con `released_at` anterior a su creación, o en el futuro. La histórica no tiene evidencia; la próxima la recoge al llegar la fecha.

## S

**SemVer** (*Semantic Versioning*) — Convención `MAYOR.MENOR.PARCHE` que da significado a cada cifra. Con `MAYOR = 0` no hay contrato, y cada proyecto fija su propia regla.

## T

**Tag anotado** (*annotated tag*) — Tag que es un objeto propio con autor, fecha y mensaje, y que se puede firmar. Por API se distingue de uno ligero porque `target` y `commit.id` son distintos.

**Tag firmado** (*signed tag*) — Tag anotado con firma. Con `gpg.format ssh`, `git tag -s` firma con la clave SSH y `git tag -v` la comprueba.

**Trunk-based development** — Modelo en el que todo se integra en `main` al menos una vez al día y lo incompleto se esconde detrás de *feature flags*.

## U

**Upstream first** — Regla de GitLab Flow: todo cambio entra primero en `main` y de ahí baja a las ramas de release o de entorno. Nunca al revés.

---

[← Volver a la Semana 08](../README.md)

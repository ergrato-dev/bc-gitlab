# 📖 Glosario — Semana 12

Términos que aparecen esta semana. El nombre real de la feature va en inglés entre paréntesis, y el **tier** cuando aplica.

El glosario acumulado de toda la plataforma está en [glosario-global](../../../docs/glosario-global.md).

---

## C

**Catálogo CI/CD** (*CI/CD Catalog*) — Free. Lista de los proyectos de componentes de una instancia, con sus versiones publicadas, sus inputs y su README. Un proyecto entra al marcarlo y aparece al publicar su primera versión. El detalle de qué proyectos usan qué versión es Premium.

**Componente** (*CI/CD component*) — Free. Un archivo YAML con `spec:inputs` en `templates/` de un proyecto, que otro proyecto incluye por dirección y versión: `$CI_SERVER_FQDN/<proyecto>/<nombre>@<versión>`. Solo viaja el YAML; sus scripts se descargan aparte.

**`component.sha`** — Contexto que un componente puede interpolar con `$[[ component.sha ]]`: el commit exacto de la versión que se resolvió. Junto a `component.name`, `component.version` y `component.reference`.

## E

**`extends`** — Hereda las claves de uno o varios jobs, con fusión profunda: los mapas se mezclan y las listas se sustituyen. Hasta 11 niveles.

## F

**Fusión profunda** (*deep merge*) — Cómo combinan GitLab `include` y `extends`: claves de mapas se mezclan una a una; una lista definida en los dos lados se queda con la última, entera.

## I

**`include`** — Mete en el pipeline YAML de otro archivo: `local`, `project`, `remote` o `template`, y `component`. Hasta 150 por pipeline.

**Input** (*input*) — Parámetro que un archivo declara en `spec:inputs` y que se sustituye como texto al crear el pipeline, antes de `workflow` y `rules`. Tiene tipo (`string`, `number`, `boolean`, `array`) y puede tener `default`, `options` o `regex`.

**Input de pipeline** (*pipeline input*) — Free. Un input declarado en el `.gitlab-ci.yml` de un proyecto, que se pasa al lanzar el pipeline: por API, con `trigger:inputs` o con `git push -o ci.input=`. No cuenta para la restricción de variables de pipeline.

## R

**`!reference`** — Etiqueta YAML de GitLab que copia una clave de otro job, también de un archivo incluido: `!reference [.job, rules]`. Sirve para componer listas sin que la fusión las sustituya.

## S

**`spec:inputs`** — La cabecera de un archivo, separada del resto por `---`, que declara qué inputs acepta. Pasar uno que no declara, o no pasar uno sin `default`, impide crear el pipeline.

**`spec:component`** — Lista de los contextos de componente que el archivo usa (`name`, `version`, `sha`, `reference`). Sin ella, `$[[ component.sha ]]` no se sustituye.

## V

**Versión parcial** — `@1` o `@1.2`: la versión publicada más alta que empieza así. `@~latest`, la más alta de todas. Solo encuentran tags semver sin `v` y excluyen las *prereleases*.

---

[← Volver a la Semana 12](../README.md)

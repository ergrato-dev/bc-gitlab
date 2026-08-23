---
name: verificar-comandos-glab
description: Comprueba que los comandos glab, endpoints de la API v4 y GraphQL, palabras clave de .gitlab-ci.yml y opciones de gitlab.rb citados en el material existan de verdad y hagan lo que el texto dice. Usar SIEMPRE después de escribir teoría o prácticas con comandos, y antes de dar por cerrada cualquier semana.
allowed-tools: Bash(glab *) Bash(curl *) Bash(jq*) Bash(grep*) Bash(docker compose exec*) Read Grep Glob WebFetch
---

# Verificar comandos, endpoints y palabras clave

El fallo más probable de este repositorio no es un enlace roto: es un **comando
plausible que no existe**. Pasa la revisión a ojo y revienta cuando el alumno lo
ejecuta. Este skill lo caza.

Cuatro familias de invento, por frecuencia:

1. **Endpoints de la API v4** que suenan bien y no están (`/projects/:id/settings`).
2. **Palabras clave de `.gitlab-ci.yml`** que no existen o cambiaron de nombre.
3. **Subcomandos y flags de `glab`** tomados prestados de `gh`.
4. **Opciones de `gitlab.rb`** con el prefijo equivocado (`gitlab_rails[...]` cuando es `nginx[...]`).

Y un quinto que no es invento sino error de tier: **atribuir a CE una feature
que es Premium o Ultimate**.

## Alcance

Los archivos que se pasan como argumento, o si no se indica nada, la semana en
curso completa: `1-teoria/`, `2-practicas/`, `3-proyecto/` y `checks.json`.

## Procedimiento

### 1. Extraer lo que hay que comprobar

```bash
# Comandos glab
grep -rhoE '\bglab [a-z]+( [a-z-]+)*' <ruta> | sort -u

# Endpoints citados en texto y en checks.json
grep -rhoE '(api/v4/|"api": ")[a-zA-Z0-9_{}/%:.-]+' <ruta> | sort -u

# Palabras clave de pipeline en bloques yaml
grep -rhoE '^\s{0,4}[a-z_]+:' <ruta>/**/*.md | sort -u

# Opciones de Omnibus
grep -rhoE "[a-z_]+\['[a-z_]+'\]" <ruta> | sort -u
```

### 2. Comprobar contra la instancia real

Es la comprobación que vale. Si hay una instancia levantada:

```bash
source ~/.bc-gitlab

# ¿Existe el endpoint? Un 404 con mensaje de GitLab es distinto de un 404 de ruta.
curl -s -o /dev/null -w '%{http_code}\n' \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/<endpoint>"

# ¿Existe el subcomando de glab?
glab <comando> --help > /dev/null 2>&1 && echo existe || echo NO EXISTE

# ¿Es válida la palabra clave del pipeline? El linter de la propia instancia lo dice.
curl -s --request POST "$GITLAB_URL/api/v4/projects/<id>/ci/lint" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$(jq -Rs '{content: .}' < pipeline.yml)" | jq '.valid, .errors'
```

El endpoint `ci/lint` de proyecto es la forma más rápida y fiable de validar
cualquier `.gitlab-ci.yml` de ejemplo. Úsalo siempre que la semana lleve YAML.

### 3. Comprobar el tier

Para cada feature mencionada, confirma en
`https://docs.gitlab.com/ee/<ruta-de-la-feature>` la insignia de tier que
aparece junto al título, o en la comparativa de planes. Si es Premium o
Ultimate, el material **tiene que decirlo y dar el sustituto libre**.

Ojo con el error inverso: dar por premium algo que es Free. Praefect, los
componentes CI/CD y su catálogo, los feature flags, el dependency proxy, el
backend de estado de Terraform, Auto DevOps, los server hooks, Pages y el
Service Desk **son Free** y el material debe usarlos sin disculparse.

### 4. Comprobar la versión

La versión fijada es la de `.env` (`GITLAB_VERSION`). Una feature que solo
existe en una versión posterior no sirve. En `docs.gitlab.com` el selector de
versión está arriba a la derecha; úsalo, no leas la de `latest`.

## Salida

Una tabla, sin prosa alrededor:

```
archivo:línea | lo citado | veredicto | corrección
```

Veredictos: `OK`, `NO EXISTE`, `TIER ERRÓNEO`, `VERSIÓN`, `DEPRECADO`.

Cierra con el recuento: `N comprobados, M problemas`.

## Reglas

- **No corrijas nada.** Este skill informa; quien escribe decide.
- **Si no puedes comprobarlo, dilo.** `SIN VERIFICAR` es una respuesta honesta;
  inventar un veredicto no.
- **No inventes hallazgos para parecer exhaustivo.** Cero problemas es un
  resultado válido y frecuente.
- Un comando que existe pero hace otra cosa distinta de lo que dice el texto es
  un problema, y de los peores. Compruébalo también.

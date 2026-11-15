# El catálogo CI/CD

> El catálogo es el escaparate de la instancia: la lista de proyectos de componentes con al menos una versión publicada, con su README, sus componentes y los inputs de cada uno. Un componente se puede usar sin estar en el catálogo, pero entonces nadie lo encuentra y las versiones parciales (`@1`) no funcionan. **Es Free**.

---

## 🎯 Objetivos

- Marcar un proyecto como recurso del catálogo, por la UI y por GraphQL
- Saber qué exige GitLab para publicar una versión y qué la publica de verdad
- Consultar el catálogo por GraphQL: versiones, componentes e inputs
- Saber qué partes del catálogo son de pago y qué las sustituye en CE

---

## 1. Qué problema resuelve

Con un proyecto de componentes y tres consumidores, la pregunta deja de ser "cómo lo incluyo" y pasa a ser "¿existe ya algo que haga esto?". Sin un sitio donde buscar, cada equipo escribe su propio `.npm`. El catálogo responde a esa pregunta, y además da a cada versión un estado: **publicada**. Solo las versiones publicadas se resuelven con `@1`, `@1.2` o `@~latest` (teoría 06).

---

## 2. Cómo funciona

### 2.1 Proyecto de catálogo

Un proyecto entra en el catálogo en dos pasos:

1. **Se marca** como proyecto de catálogo. Una vez.
2. **Se publica una versión**. Cada vez.

Hasta el segundo paso no aparece en la lista: `ciCatalogResources` solo devuelve proyectos con al menos una versión publicada.

### 2.2 Requisitos para publicar

| Requisito | Si falta |
|---|---|
| Rol Maintainer u Owner en el proyecto | No puedes marcarlo |
| Descripción del proyecto | No se publica |
| `README.md` en la raíz **en el commit del tag** | No se publica |
| Al menos un componente en `templates/` en ese commit | No se publica |
| El tag en versión semántica: `1.0.0`, `1.0.0-rc.1` | No se publica |
| La release creada por un job con la palabra clave `release` | Ver 2.3 |

### 2.3 Lo que publica

La documentación de 19.2.4 es explícita: la release tiene que crearla **un job con `release:`**, no la API de releases. Al probarlo en 19.2.4, una release creada por API con un token personal también apareció como versión del catálogo. No construyas nada sobre eso: no está documentado, y el job tiene una ventaja que la API no tiene, que la versión solo se publica si las pruebas del mismo pipeline pasan (teoría 06).

```yaml
publicar:
  stage: release
  image: registry.gitlab.com/gitlab-org/cli:v1.126.0
  script: echo "Publicando $CI_COMMIT_TAG"
  release:
    tag_name: $CI_COMMIT_TAG
    description: "Versión $CI_COMMIT_TAG de $CI_PROJECT_PATH"
  rules:
    - if: $CI_COMMIT_TAG =~ /^[0-9]+\.[0-9]+\.[0-9]+$/
```

El runner ejecuta `release:` con `glab`, que tiene que estar en la imagen. La documentación usa `cli:latest`; aquí va fijada, como cualquier imagen del bootcamp.

### 2.4 Visibilidad

El catálogo respeta la visibilidad del proyecto:

| Proyecto | Quién lo ve en el catálogo | Quién puede usarlo |
|---|---|---|
| Privado | Sus miembros | Desde Reporter |
| Interno | Cualquier usuario con sesión | Cualquier usuario con sesión |
| Público | Cualquiera que llegue a la instancia | Cualquiera |

`ci/componentes` es privado, como el resto del grupo. Los miembros del grupo raíz lo heredan: todos lo ven.

### 2.5 Despublicar

Desmarcar el proyecto lo saca del catálogo y **borra los metadatos de todas sus versiones**. El repositorio y los tags siguen ahí, pero `@1` deja de resolverse en todos los consumidores hasta que se publique una versión nueva. No es un botón para probar.

### 2.6 Lo que es de pago o no está en CE

| Feature | Tier | En CE |
|---|---|---|
| Catálogo, marcar, publicar, versiones parciales | Free | ✅ |
| Recuento de uso (proyectos que usaron un componente en 30 días) | Free | ✅ |
| Pestaña de analítica para quien mantiene (desde 18.9) | Free | ✅ |
| Qué proyecto usa qué versión, "Up to date" / "Outdated" (desde 19.0) | Premium | ❌ Sustituto: el bucle sobre `ci/lint` del apartado 5 |
| Insignia de creador verificado | Free según la documentación | ❌ En CE 19.2.4 la mutación `verifiedNamespaceCreate` no existe |

La última fila es un buen ejemplo de por qué este bootcamp comprueba contra la instancia: la documentación dice Free y la API de tu CE dice `Field 'verifiedNamespaceCreate' doesn't exist on type 'Mutation'`.

---

## 3. Cómo se configura

**Con la UI**: en `ci/componentes`, `Settings → General → Visibility, project features, permissions`, activa **CI/CD Catalog project** y guarda. El catálogo está en `Search or go to → Explore → CI/CD Catalog`, y también en el editor de pipelines.

**Por API**: no hay endpoint REST para marcarlo (está propuesto en la issue 463043). Es una mutación GraphQL:

```bash
jq -n --arg p "plataforma-<tu-dominio>/ci/componentes" \
  '{query: "mutation($p: ID!) { catalogResourcesCreate(input: {projectPath: $p}) { errors } }",
    variables: {p: $p}}' \
  | curl -s "$GITLAB_URL/api/graphql" -H "$H" -H "Content-Type: application/json" -d @-
# {"data":{"catalogResourcesCreate":{"errors":[]}}}
```

Y se comprueba en el propio proyecto:

```bash
jq -n --arg p "plataforma-<tu-dominio>/ci/componentes" \
  '{query: "query($p: ID!) { project(fullPath: $p) { isCatalogResource } }", variables: {p: $p}}' \
  | curl -s "$GITLAB_URL/api/graphql" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq .data.project
# {"isCatalogResource": true}
```

Las versiones publicadas, sus componentes y sus inputs:

```bash
jq -n '{query: "{ ciCatalogResources { nodes { fullPath versions { nodes { name
          components { nodes { name includePath inputs { name required default type } } } } } } } }"}' \
  | curl -s "$GITLAB_URL/api/graphql" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -c '.data.ciCatalogResources.nodes[].versions.nodes[]
           | {name, c: [.components.nodes[] | {name, inputs: [.inputs[].name]}]}'
```

`includePath` es la línea exacta que el consumidor tiene que copiar, ya con `$CI_SERVER_FQDN`.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Publicar con la API para "ahorrarse" el job | La versión sale sin pasar las pruebas, y el comportamiento no está documentado | El job con `release:` en el pipeline del tag |
| Un README que dice "ver el código" | El catálogo enseña el README como portada: nadie sabe qué hace ni qué inputs importan | Un apartado por componente con ejemplo de uso |
| Desmarcar y volver a marcar para "arreglar" una versión | Borra todas las versiones; los consumidores con `@1` se rompen | Publicar una versión nueva |
| Componentes en un proyecto público "para que los vea todo el mundo" | Expones tu forma de desplegar a cualquiera que llegue a la instancia | Privado o interno, según quién tenga que usarlos |
| `cli:latest` en el job de publicar | La herramienta que publica cambia sin que nadie lo decida | Un tag fijo |

---

## 5. Trucos

- **El sustituto libre de "quién usa qué versión"**: recorre los proyectos del grupo y pregunta a `ci/lint` qué componentes resuelve cada uno.

  ```bash
  curl -s -H "$H" "$API/groups/plataforma-<tu-dominio>/projects?include_subgroups=true&per_page=100" \
    | jq -r '.[].id' | while read -r id; do
        curl -s -H "$H" "$API/projects/$id/ci/lint?ref=main" \
          | jq -r --arg id "$id" '.includes[]? | select(.type == "component") | "\($id)\t\(.location)\t\(.blob)"'
      done
  ```

- **El catálogo desde el editor**: `Build → Pipeline editor` tiene un botón al catálogo; útil cuando ya estás escribiendo el `include`.

---

## 📚 Recursos Adicionales

- [CI/CD Catalog](https://docs.gitlab.com/ci/components/#cicd-catalog) — publicar, visibilidad, despublicar
- [`release`](https://docs.gitlab.com/ci/yaml/#release) — la palabra clave y la imagen de `glab`
- [Mutation `catalogResourcesCreate`](https://docs.gitlab.com/api/graphql/reference/#mutationcatalogresourcescreate)

---

## ✅ Checklist de Verificación

- [ ] Sabes por qué un proyecto marcado no aparece en el catálogo hasta su primera versión
- [ ] Sabes los requisitos que tiene que cumplir el commit del tag
- [ ] Sabes qué pasa con los consumidores si despublicas el proyecto
- [ ] Sabes cómo saber, en CE, qué proyecto usa qué versión de un componente

---

[← Anterior: Componentes CI/CD](04-componentes.md) · [Volver a la Semana 12](../README.md) · [Siguiente: Versionar y probar un componente →](06-versionar-y-probar.md)

# 02 — GraphQL API de GitLab

GitLab ofrece una API GraphQL disponible en `https://gitlab.example.com/api/graphql`. A diferencia de REST, GraphQL permite solicitar exactamente los campos necesarios en una sola petición, evitando over-fetching y under-fetching.

## GraphiQL Explorer

GitLab incluye un explorador GraphiQL en `/-/graphql-explorer` dentro de la interfaz web. Esta herramienta permite escribir queries interactivamente, explorar el esquema con autocompletado y ver la documentación integrada de cada tipo y campo. Es el punto de partida recomendado para aprender la API GraphQL.

## Autenticación

Se usa el mismo PAT que en REST, enviado como header `Authorization: Bearer <token>`. También se acepta `PRIVATE-TOKEN` como header alternativo para compatibilidad con scripts existentes.

## Queries vs Mutations

- **Queries**: operaciones de solo lectura. Ejemplo: obtener todos los proyectos de un grupo con sus pipelines recientes.
- **Mutations**: operaciones que modifican datos (crear, actualizar, eliminar). Ejemplo: crear un issue, aceptar un merge request, añadir un miembro a un proyecto.

## Fragments

Los fragments permiten reutilizar conjuntos de campos entre múltiples queries, evitando duplicación. Se definen con `fragment Nombre on Tipo { ... }` y se usan con `...Nombre`.

## Ejemplo de query

```graphql
query {
  project(fullPath: "grupo/subgrupo/proyecto") {
    name
    mergeRequests(state: opened) {
      nodes {
        title
        author { name }
      }
    }
  }
}
```

## Límites

- Complejidad máxima de query: 200 puntos por defecto
- Profundidad máxima: 10 niveles
- Rate limit: 600 peticiones por minuto

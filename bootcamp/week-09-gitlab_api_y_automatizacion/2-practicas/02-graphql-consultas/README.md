# Práctica 02 — GraphQL en Práctica

## Objetivo

Realizar consultas GraphQL para obtener datos consolidados en una sola petición.

## Instrucciones

1. Accede al GraphiQL Explorer en `http://localhost:8080/-/graphql-explorer`
2. Ejecuta las siguientes queries:

### Query 1: Proyectos con sus últimas pipelines
```graphql
query {
  projects(membership: true, first: 10) {
    nodes {
      name
      fullPath
      pipelines(first: 3) {
        nodes {
          status
          ref
          createdAt
        }
      }
    }
  }
}
```

### Query 2: Issues abiertos con etiquetas
```graphql
query {
  project(fullPath: "tu-grupo/tu-proyecto") {
    issues(state: opened) {
      nodes {
        title
        labels { nodes { title } }
        assignees { nodes { name } }
      }
    }
  }
}
```

### Mutation: Crear un issue vía GraphQL
Usa la pestaña de mutations en el explorer para generar la mutation de `createIssue`.

## Preguntas de reflexión
- ¿Cuántas peticiones REST necesitarías para obtener la misma información de la Query 1?
- ¿Qué ventajas ves en GraphQL frente a REST para dashboards?
- ¿Notaste alguna limitación del GraphiQL Explorer?

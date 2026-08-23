---
name: "checks.json"
description: "Genera el checks.json de una semana: comprobaciones declarativas contra la API v4 de GitLab, con descripciones que se copian literales al proyecto y pistas que apuntan al paso que las arregla."
argument-hint: "Semana (ej: 09) y qué entrega el alumno esa semana"
mode: "agent"
---

# checks.json — Bootcamp GitLab CE

**Se escribe ANTES que el contenido de la semana.** Define qué es entregable y,
por tanto, qué tienen que enseñar las prácticas. Escribirlo después lleva a
prácticas que enseñan cosas que nadie comprueba.

Contrato completo: `docs/autograding.md`.

## Estructura

```json
{
  "semana": "09",
  "titulo": "CI/CD: fundamentos",
  "checks": [
    {
      "id": "pipeline-verde",
      "descripcion": "El ultimo pipeline de main termino en success",
      "api": "projects/{proyecto}/pipelines?ref=main&per_page=1",
      "jq": ".[0].status == \"success\"",
      "pista": "2-practicas/01-primer-pipeline.md, paso 5"
    }
  ]
}
```

## Campos

| Campo | Obligatorio | Nota |
|---|:--:|---|
| `id` | sí | kebab-case, estable |
| `descripcion` | sí | Se copia **literal** a `3-proyecto/README.md` |
| `api` | sí* | REST v4, sin `/api/v4/`. Marcadores `{proyecto}`, `{grupo}`, `{nombre}` |
| `graphql` | sí* | Recibe `$fullPath` y `$grupo` |
| `jq` | sí | Devuelve booleano |
| `token` | no | `proyecto` (por defecto) o `admin` |
| `pista` | no | Archivo + paso que lo arregla |

\* Exactamente uno de `api` o `graphql`.

## Cuántas

Entre 6 y 18, creciendo con la complejidad de la semana. Las primeras semanas
rondan 6-8; a partir de la Semana 11, 12-18.

## Reglas

1. **Una comprobación, un hecho.** Si la descripción lleva una "y", son dos.
2. **`jq` devuelve booleano**, nunca un valor. `length > 0`, no `length`.
3. **Cero lógica bash.** Si necesita código imperativo, el entregable no es
   verificable: va a rúbrica manual y fuera de aquí.
4. **Un 404 es un fallo**, no un error. No hay que preverlo.
5. **Nunca escribe.** Solo `GET` (y el `POST` de GraphQL, que es una lectura).
6. **`token: admin` solo para configuración de instancia**, no por comodidad.
7. **Comprueba cada endpoint a mano antes de escribirlo.** Es la regla que más
   se salta y la que más caro sale:

   ```bash
   source ~/.bc-gitlab
   curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     "$GITLAB_URL/api/v4/<endpoint>" | jq '<expresion>'
   # true
   ```

8. **La pista apunta a un archivo que existe** dentro de esa semana, con el paso
   concreto.

## Antes de entregar

- [ ] `jq -e . checks.json` pasa
- [ ] Cada endpoint comprobado contra una instancia real
- [ ] Cada `jq` devuelve `true` o `false`, nunca otra cosa
- [ ] Las descripciones no llevan "y"
- [ ] Cada pista apunta a un archivo real de la semana
- [ ] Las descripciones están listas para copiarse literales al proyecto

$input

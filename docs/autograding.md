# ✅ Autograding

En autoestudio nadie revisa tus entregables. Los revisa la API de tu instancia.

Cada semana declara sus comprobaciones en un `checks.json`. El script `scripts/verificar-semana.sh` las traduce a llamadas reales contra **tu** GitLab y te dice qué falta y en qué paso se arregla.

---

## Configuración

Una sola vez, antes de la Semana 01:

```bash
cat > ~/.bc-gitlab <<'EOF'
GITLAB_URL=http://localhost:8888
PROYECTO=plataforma-biblioteca/app
GITLAB_TOKEN=glpat-...
EOF
chmod 600 ~/.bc-gitlab
```

| Variable | Obligatoria | Qué es |
|---|:--:|---|
| `GITLAB_URL` | sí | Raíz de tu instancia, sin `/api/v4` |
| `PROYECTO` | sí | Ruta completa del proyecto: `<grupo>/<proyecto>` |
| `GITLAB_TOKEN` | sí | Token personal con scope `api` |
| `GITLAB_ADMIN_TOKEN` | no | Token de administrador. Si falta se usa `GITLAB_TOKEN` |

> [!NOTE]
> En el laboratorio eres `root`, así que tu token personal ya es de administrador y `GITLAB_ADMIN_TOKEN` sobra. La variable existe para quien practique con un usuario sin privilegios y quiera ver qué comprobaciones necesitan permisos de instancia.

El archivo tiene tu token: `chmod 600` y nunca dentro del repositorio.

---

## Uso

```bash
# Diagnóstico del entorno (antes de empezar)
./scripts/verificar-semana.sh --doctor

# Verificar una semana
./scripts/verificar-semana.sh 07

# Verificar contra otro proyecto sin tocar la configuración
./scripts/verificar-semana.sh 07 --proyecto plataforma-cine/app
```

Salida:

```
== Semana 07 — Gobernanza de ramas y aprobaciones ==
   instancia: http://localhost:8888
   proyecto:  plataforma-biblioteca/app

✅ La rama main esta protegida
✅ Nadie puede hacer push directo a main
❌ Los tags v* estan protegidos
   → 2-practicas/01-main-y-tags-protegidos.md, paso 5
✅ Existe un archivo CODEOWNERS en la raiz de main

3 de 4 verificaciones superadas.
```

Código de salida: `0` si pasan todas, `1` si falla alguna. Sirve para meterlo en tu propio pipeline si quieres.

---

## Formato de `checks.json`

```json
{
  "semana": "07",
  "titulo": "Gobernanza de ramas y aprobaciones",
  "checks": [
    {
      "id": "main-protegida",
      "descripcion": "La rama main está protegida",
      "api": "projects/{proyecto}/protected_branches",
      "jq": "map(select(.name == \"main\")) | length > 0",
      "pista": "2-practicas/01-proteger-main.md, paso 3"
    },
    {
      "id": "registro-abierto-cerrado",
      "descripcion": "El registro público de usuarios está desactivado",
      "api": "application/settings",
      "token": "admin",
      "jq": ".signup_enabled == false",
      "pista": "2-practicas/04-endurecer-instancia.md, paso 2"
    },
    {
      "id": "catalogo-publicado",
      "descripcion": "El proyecto está marcado como recurso del catálogo CI/CD",
      "graphql": "query($fullPath:ID!){ project(fullPath:$fullPath){ isCatalogResource } }",
      "jq": ".data.project.isCatalogResource == true",
      "pista": "3-proyecto/README.md"
    }
  ]
}
```

### Campos

| Campo | Obligatorio | Qué hace |
|---|:--:|---|
| `id` | sí | Identificador estable, kebab-case |
| `descripcion` | sí | Lo que se imprime. Se copia **literal** al proyecto como requisito |
| `api` | sí* | Endpoint REST v4, sin `/api/v4/`. Admite marcadores |
| `graphql` | sí* | Query GraphQL. Recibe `$fullPath` y `$grupo` como variables |
| `jq` | sí | Expresión que debe evaluar a `true` sobre la respuesta |
| `token` | no | `proyecto` (por defecto) o `admin` |
| `pista` | no | Dónde está el paso que lo arregla |

\* Exactamente uno de `api` o `graphql`.

### Marcadores

Con `PROYECTO=plataforma-biblioteca/app`:

| Marcador | Se sustituye por | Nota |
|---|---|---|
| `{proyecto}` | `plataforma-biblioteca%2Fapp` | URL-encoded: es como la API v4 acepta la ruta completa como ID |
| `{grupo}` | `plataforma-biblioteca` | Para endpoints de `groups/` |
| `{nombre}` | `app` | Para los pocos endpoints que solo quieren el nombre |

En GraphQL no hay marcadores: la query recibe `$fullPath` (`plataforma-biblioteca/app`, **sin** codificar) y `$grupo`.

### Reglas de diseño

1. **Una comprobación, un hecho.** Si la descripción lleva una "y", divídela en dos.
2. **La expresión `jq` devuelve un booleano**, nunca un valor. `length > 0`, no `length`.
3. **Cero lógica bash por semana.** Si una comprobación necesita código imperativo, replantea el entregable: probablemente no es verificable y por tanto no debería ser obligatorio.
4. **Un 404 es un fallo**, no un error del script. Si el recurso no existe, la comprobación simplemente no pasa.
5. **Nunca escribe.** El script solo hace `GET` (y `POST` a `/api/graphql`, que es como se leen las queries). No arregla nada por ti.
6. **`token: admin` solo cuando de verdad haga falta.** Es una señal para el lector: "esto es configuración de instancia, no de tu proyecto".

---

## Lo que NO se puede verificar por API

Bastante, y es importante saberlo:

| No verificable | Por qué | Cómo se evalúa |
|---|---|---|
| Que un mensaje de commit sea bueno | La API ve el texto, no el criterio | Rúbrica manual |
| Que un comentario de review aporte algo | Ídem | Rúbrica manual |
| Que entendieras por qué proteges `main` | No hay endpoint para eso | Cuestionario de la rúbrica |
| La reconciliación de Praefect (S23) | Se comprueba con `praefect dataloss`, que es CLI y no API | Rúbrica manual, con la salida pegada |
| La calidad de un postmortem (S22) | Es prosa | Rúbrica manual |
| Que los paneles de Grafana midan lo correcto (S21) | La API confirma que existen, no que sirvan | Rúbrica manual |
| Que tu canario detecte de verdad una regresión (S25) | La API ve el deployment, no el criterio de corte | Rúbrica manual |
| La defensa final (S26) | Es una conversación | Rúbrica manual |

El autograding cubre el **40% de desempeño** y 60 de los 100 puntos del producto. El 30% de conocimiento sale del cuestionario. **Pasar las verificaciones no es aprobar la semana.**

### Comprobaciones con línea base

Dos casos comparan contra un estado anterior, no contra un valor fijo: el recuento de issues antes y después de restaurar el backup (S22) y la duración de pipeline antes y después de mover la ejecución a Kubernetes (S16). Ahí el `checks.json` verifica que **exista** el artefacto de línea base versionado en tu repositorio; que el número mejore lo juzga la rúbrica.

---

## Escribir una comprobación nueva

Prueba la llamada a mano primero:

```bash
source ~/.bc-gitlab
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/plataforma-biblioteca%2Fapp/protected_branches" | jq .
```

Reduce a un booleano:

```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/plataforma-biblioteca%2Fapp/protected_branches" \
  | jq 'map(select(.name == "main")) | length > 0'
# true
```

Esa misma expresión va literal al campo `jq`.

Para GraphQL:

```bash
curl -s -X POST "$GITLAB_URL/api/graphql" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" -H "Content-Type: application/json" \
  -d '{"query":"query($fullPath:ID!){ project(fullPath:$fullPath){ isCatalogResource } }",
       "variables":{"fullPath":"plataforma-biblioteca/app"}}' \
  | jq '.data.project.isCatalogResource == true'
```

> [!WARNING]
> **No inventes endpoints.** Un endpoint plausible pero inexistente pasa desapercibido al escribirlo y revienta cuando lo ejecutas. Si no estás seguro, compruébalo con `curl` contra tu instancia antes de meterlo en el `checks.json`.

---

## Trampa

Puedes hacer trampa: las comprobaciones miran el estado final, no cómo llegaste. Puedes proteger `main` a mano sin entender qué protege.

Y da exactamente igual, porque nadie te va a contratar por el `checks.json`. Las verificaciones son un detector de humo, no un examen.

---

[← Volver a docs](README.md)

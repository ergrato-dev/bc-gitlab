# 🔬 Práctica 02 — Crear y Configurar Merge Requests

## 🎯 Objetivo

Crear Merge Requests bien descritos, vincularlos a issues, experimentar con estados Draft/Ready, configurar opciones de merge del proyecto, y explorar las estrategias de merge disponibles.

## ⏱️ Tiempo estimado: 50 minutos

## 📋 Requisitos previos

- Completada la Práctica 01 (issues y labels creados)
- Proyecto `bootcamp-org/backend/api-gateway` con al menos 3 issues abiertos
- `$GITLAB_TOKEN` disponible, usuario `developer1` activo

---

## 📝 Paso 1: Configurar Opciones de Merge del Proyecto

Antes de crear MRs, configura cómo funcionará el merge:

```
http://localhost/bootcamp-org/backend/api-gateway/-/settings/merge_requests

Merge method:
  ● Merge commit (seleccionar)

Squash commits when merging:
  ● Encourage (para verlo como opción pero no obligatorio)

Merge checks:
  ✓ All threads must be resolved   ← Marcar este
  □ Pipelines must succeed         ← Dejar desmarcado (no tenemos CI aún)

After merge:
  ✓ Enable "Delete source branch" option by default ← Marcar
```

Click **Save changes**.

---

## 📝 Paso 2: Crear una Rama con Cambios Reales

```bash
GITLAB_URL="http://localhost"
NAMESPACE="bootcamp-org/backend"
PROJECT="api-gateway"

PROJECT_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects?search=$PROJECT" \
  | python3 -c "
import sys,json
projects=[p for p in json.load(sys.stdin) if '$NAMESPACE' in p['path_with_namespace']]
print(projects[0]['id'])
")

ISSUE_IID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$PROJECT_ID/issues?state=opened&per_page=1" \
  | python3 -c "import sys,json; issues=json.load(sys.stdin); print(issues[0]['iid'])")

echo "Project ID: $PROJECT_ID | Issue: #$ISSUE_IID"

git clone "http://root:$GITLAB_TOKEN@localhost/$NAMESPACE/$PROJECT.git" /tmp/api-gw-mr-practice
cd /tmp/api-gw-mr-practice

BRANCH="${ISSUE_IID}-health-check-endpoint"
git checkout -b "$BRANCH"

mkdir -p src/routes
cat > src/routes/health.js << 'JSEOF'
const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: process.env.APP_VERSION || '1.0.0'
  });
});

module.exports = router;
JSEOF

git add src/routes/health.js
git commit -m "feat(health): add basic health check endpoint"

mkdir -p tests
cat > tests/health.test.js << 'TESTEOF'
describe('GET /health', () => {
  it('should return 200 with healthy status', () => {
    expect(true).toBe(true); // TODO: implementar con supertest
  });
});
TESTEOF

git add tests/health.test.js
git commit -m "test(health): add placeholder tests for health endpoint"

git push "http://root:$GITLAB_TOKEN@localhost/$NAMESPACE/$PROJECT.git" "$BRANCH"
```

---

## 📝 Paso 3: Crear el Draft MR

```bash
MILESTONE_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$PROJECT_ID/milestones" \
  | python3 -c "import sys,json; ms=json.load(sys.stdin); print(ms[0]['id'] if ms else 'null')")

DEVELOPER_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/users?username=developer1" \
  | python3 -c "import sys,json; users=json.load(sys.stdin); print(users[0]['id'] if users else 1)")

MAINTAINER_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/users?username=maintainer1" \
  | python3 -c "import sys,json; users=json.load(sys.stdin); print(users[0]['id'] if users else 1)")

# ¿QUÉ HACE?: Crea el MR en estado Draft via API
# ¿POR QUÉ?: "Draft:" en el título bloquea el merge accidental durante el desarrollo
# ¿PARA QUÉ?: Trabajo visible desde el primer commit, CI ejecutándose, sin riesgo de merge prematuro
MR_DATA=$(curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{
    \"source_branch\": \"${ISSUE_IID}-health-check-endpoint\",
    \"target_branch\": \"main\",
    \"title\": \"Draft: feat(health): implementar endpoint /health con verificacion de dependencias\",
    \"description\": \"## Que hace este MR?\nImplementa GET /health con estado del servicio y verificacion de dependencias.\n\n## Issue relacionado\nCloses #${ISSUE_IID}\n\n## Tipo de cambio\n- [ ] Bug fix\n- [x] Nueva funcionalidad\n\n## Checklist\n- [x] Ruta creada\n- [ ] Tests implementados (en progreso)\",
    \"assignee_id\": $DEVELOPER_ID,
    \"reviewer_ids\": [$MAINTAINER_ID],
    \"milestone_id\": $MILESTONE_ID,
    \"squash\": true,
    \"remove_source_branch\": true,
    \"labels\": \"feature,area::backend,workflow::review\"
  }" \
  "$GITLAB_URL/api/v4/projects/$PROJECT_ID/merge_requests")

MR_IID=$(echo $MR_DATA | python3 -c "import sys,json; mr=json.load(sys.stdin); print(mr.get('iid', 'ERROR'))")
MR_URL=$(echo $MR_DATA | python3 -c "import sys,json; mr=json.load(sys.stdin); print(mr.get('web_url', 'ERROR'))")

echo "MR !$MR_IID creado"
echo "URL: $MR_URL"
```

Verificar en browser:
- Título muestra "Draft: feat(health): ..."
- Botón "Merge" desactivado
- Reviewer: `maintainer1` asignado

---

## 📝 Paso 4: Agregar Commit Final y Marcar como Ready

```bash
cd /tmp/api-gw-mr-practice

cat > src/routes/health.js << 'JSEOF'
const express = require('express');
const router = express.Router();

async function checkDatabaseHealth() {
  return { status: 'healthy', latency_ms: 2 };
}

router.get('/', async (req, res) => {
  try {
    const db = await checkDatabaseHealth();
    const allHealthy = db.status === 'healthy';

    res.status(allHealthy ? 200 : 503).json({
      status: allHealthy ? 'healthy' : 'degraded',
      timestamp: new Date().toISOString(),
      version: process.env.APP_VERSION || '1.0.0',
      services: { database: db }
    });
  } catch (err) {
    res.status(503).json({ status: 'unhealthy', error: err.message });
  }
});

module.exports = router;
JSEOF

git add src/routes/health.js
git commit -m "feat(health): add database health check with 503 on failure"

git push "http://root:$GITLAB_TOKEN@localhost/$NAMESPACE/$PROJECT.git" \
  "${ISSUE_IID}-health-check-endpoint"

# ¿QUÉ HACE?: Quita el prefijo Draft del título via API
# ¿POR QUÉ?: GitLab habilita el botón Merge cuando no hay "Draft:" en el título
# ¿PARA QUÉ?: Señalar al reviewer que el trabajo está completo y listo para revisión
curl --silent --request PUT \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{\"title\": \"feat(health): implementar endpoint /health con verificacion de dependencias\"}" \
  "$GITLAB_URL/api/v4/projects/$PROJECT_ID/merge_requests/$MR_IID" \
  | python3 -c "import sys,json; mr=json.load(sys.stdin); print(f'MR !{mr[\"iid\"]}: draft={mr.get(\"draft\")}, state={mr[\"state\"]}')"
```

---

## 📝 Paso 5: Explorar la Vista de Cambios

```
http://localhost/bootcamp-org/backend/api-gateway/-/merge_requests/<N>/diffs

1. Toggle "Side-by-side" / "Inline"
2. Hovear sobre una línea → ícono de burbuja de comentario
3. Click en el ícono → escribir: "Buen manejo del error 503"
4. Click "Add comment now"
5. Verificar que el thread aparece en la pestaña "Overview"
```

---

## 📝 Paso 6: Verificar via API

```bash
# ¿QUÉ HACE?: Lista todos los MRs abiertos con sus detalles
# ¿POR QUÉ?: Verifica que el MR tiene el estado correcto tras los cambios
# ¿PARA QUÉ?: Aprender la estructura de respuesta de la API de MRs
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$PROJECT_ID/merge_requests?state=opened" \
  | python3 -c "
import sys, json
mrs = json.load(sys.stdin)
for mr in mrs:
    draft = '(DRAFT) ' if mr.get('draft', False) else ''
    print(f'  !{mr[\"iid\"]} {draft}{mr[\"title\"]}')
    print(f'     {mr[\"source_branch\"]} -> {mr[\"target_branch\"]}')
    print(f'     Estado: {mr[\"state\"]} | squash={mr[\"squash\"]}')
    print(f'     Labels: {mr[\"labels\"]}')
"
```

---

## 🔧 Troubleshooting

**Push rechazado: "protected branch"**
```
→ No hacer push a main directamente
→ git branch → confirmar que estás en la feature branch
```

**MR sigue en Draft tras cambiar el título**
```
→ En la UI: click en "Mark as ready"
→ Verificar que la API retorna draft: false tras el PUT
```

---

## ✅ Checklist de verificación

- [ ] Opciones de merge configuradas en Settings
- [ ] Feature branch con al menos 3 commits
- [ ] MR creado en estado Draft con descripción y reviewer
- [ ] MR marcado como Ready (draft: false)
- [ ] Comentario en línea en la pestaña "Changes"
- [ ] API confirma MR abierto y sin estado Draft

## 📦 Entregables

- [ ] Captura del MR en estado Draft (botón Merge desactivado)
- [ ] Captura del MR en estado Ready (botón Merge activo)
- [ ] Captura de "Changes" con al menos un comentario en línea
- [ ] Output del API listando MRs abiertos

---

⬅️ **Anterior:** [01 — Crear Issues](../01-crear-issues/README.md)
➡️ **Siguiente:** [03 — Code Review Práctico](../03-code-review-practico/README.md)

# 📁 Proyecto Semana 04 — Ciclo Completo GitLab Flow

## 🎯 Objetivo del Proyecto

Ejecutar un **ciclo completo de GitLab Flow** de principio a fin, integrando todo lo aprendido en la semana: desde la creación estructurada de issues hasta el merge con code review y cierre automático del issue. El resultado es un proyecto en GitLab con trazabilidad completa issue → rama → commit → MR → merge.

## ⏱️ Tiempo estimado: 3-4 horas

---

## 📋 Contexto del Proyecto

Eres el developer asignado al proyecto `api-gateway` dentro de `bootcamp-org`. El equipo ha acordado implementar un sistema de **health checks** para el API Gateway en el primer sprint. Tu trabajo es ejecutar el proceso completo, desde la planificación hasta el merge a producción.

---

## 🏗️ Fase 1: Planificación (30 min)

### 1.1 Crear los Labels del Proyecto

Todos los labels necesarios deben existir antes de crear issues. Ejecutar el script de setup de labels de la Práctica 01 para asegurar que están todos creados.

### 1.2 Crear el Milestone del Sprint

```
Proyecto → Issues → Milestones → New milestone

Title:       Sprint 1 — Health Checks & Autenticación
Start date:  <fecha actual>
Due date:    <fecha actual + 14 días>
Description:
  Primer sprint productivo del proyecto api-gateway.
  
  Objetivos del sprint:
  - Implementar health checks para todas las dependencias
  - Agregar autenticación JWT al API Gateway
  - Documentar todos los endpoints del API
```

### 1.3 Crear 6 Issues del Sprint

Crear los siguientes issues usando el template de Feature para los primeros y el de Bug para el último:

| # | Título | Labels | Weight | Assignee |
|---|--------|--------|--------|----------|
| 1 | [feature] Implementar endpoint GET /health básico | feature, area::backend, priority::2, workflow::todo | 3 | developer1 |
| 2 | [feature] Agregar verificación de PostgreSQL al health check | feature, area::backend, priority::2, workflow::todo | 5 | developer1 |
| 3 | [feature] Agregar verificación de Redis al health check | feature, area::backend, priority::3, workflow::todo | 5 | developer1 |
| 4 | [feature] Implementar autenticación JWT en todos los endpoints | feature, area::backend, priority::1, workflow::todo | 8 | developer1 |
| 5 | [docs] Documentar endpoints del API en README | documentation, priority::3, workflow::todo | 3 | developer1 |
| 6 | [bug] Endpoint /health devuelve 500 cuando Redis no responde | bug, area::backend, priority::1, workflow::todo | 3 | developer1 |

**Via API (script):**

```bash
PROJECT_ID=<ID>
DEVELOPER_ID=<ID del developer1>
MILESTONE_ID=<ID del sprint>

ISSUES=(
  "feat: Implementar endpoint GET /health basico|feature,area::backend,priority::2,workflow::todo|3"
  "feat: Agregar verificacion de PostgreSQL al health check|feature,area::backend,priority::2,workflow::todo|5"
  "feat: Agregar verificacion de Redis al health check|feature,area::backend,priority::3,workflow::todo|5"
  "feat: Implementar autenticacion JWT en todos los endpoints|feature,area::backend,priority::1,workflow::todo|8"
  "docs: Documentar endpoints del API en README|documentation,priority::3,workflow::todo|3"
  "fix: Endpoint /health devuelve 500 cuando Redis no responde|bug,area::backend,priority::1,workflow::todo|3"
)

for issue_data in "${ISSUES[@]}"; do
  IFS='|' read -r title labels weight <<< "$issue_data"
  result=$(curl --silent --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{
      \"title\": \"$title\",
      \"labels\": \"$labels\",
      \"weight\": $weight,
      \"milestone_id\": $MILESTONE_ID,
      \"assignee_ids\": [$DEVELOPER_ID]
    }" \
    "http://localhost/api/v4/projects/$PROJECT_ID/issues")
  
  iid=$(echo $result | python3 -c "import sys,json; print(json.load(sys.stdin).get('iid', 'ERROR'))")
  echo "Created #$iid: $title"
done
```

---

## 💻 Fase 2: Desarrollo — Issue #1 (Health Check Básico) (45 min)

### 2.1 Crear la Rama desde el Issue

```bash
# Obtener el iid del primer issue
ISSUE_IID=1  # Ajustar según el ID real

git clone "http://root:$GITLAB_TOKEN@localhost/<namespace>/api-gateway.git" /tmp/project-sprint1
cd /tmp/project-sprint1

git checkout -b "${ISSUE_IID}-health-check-basico"
```

### 2.2 Implementar el Código

Crear `src/routes/health.js` con la implementación completa:

```javascript
const express = require('express');
const router = express.Router();

/**
 * GET /health
 * Retorna el estado actual del servicio y sus dependencias.
 * Responde 200 si todo funciona, 503 si alguna dependencia falla.
 */
router.get('/', async (req, res) => {
  const startTime = Date.now();
  
  const checks = {
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    version: process.env.APP_VERSION || 'dev',
    environment: process.env.NODE_ENV || 'development'
  };

  res.status(200).json({
    status: 'healthy',
    ...checks
  });
});

module.exports = router;
```

Crear `tests/health.test.js`:

```javascript
const request = require('supertest');
// const app = require('../src/app');

describe('GET /health', () => {
  it('should return 200 with healthy status', () => {
    // expect((await request(app).get('/health')).status).toBe(200);
    expect(true).toBe(true); // Placeholder
  });

  it('should include version and timestamp in response', () => {
    expect(true).toBe(true); // Placeholder
  });
});
```

### 2.3 Commits Atómicos

```bash
git add src/routes/health.js
git commit -m "feat(health): implement basic GET /health endpoint

Returns service status, uptime, version and timestamp.
Responds 200 when service is healthy."

git add tests/health.test.js
git commit -m "test(health): add placeholder tests for basic health endpoint"

git push origin "${ISSUE_IID}-health-check-basico"
```

### 2.4 Crear el Draft MR

```bash
curl --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{
    \"source_branch\": \"${ISSUE_IID}-health-check-basico\",
    \"target_branch\": \"main\",
    \"title\": \"Draft: feat(health): implementar endpoint GET /health basico\",
    \"description\": \"## Que hace este MR?\nImplementa el endpoint GET /health con informacion de estado del servicio.\n\n## Issue relacionado\nCloses #${ISSUE_IID}\n\n## Checklist\n- [x] Implementacion basica\n- [ ] Tests completos (pendiente)\",
    \"squash\": true,
    \"remove_source_branch\": true,
    \"labels\": \"feature,area::backend,workflow::review\"
  }" \
  "http://localhost/api/v4/projects/$PROJECT_ID/merge_requests"
```

---

## 👀 Fase 3: Code Review (45 min)

### 3.1 El Reviewer Revisa el MR

Con el usuario `maintainer1` o como root (en este ejercicio podemos hacer auto-review con fines de práctica):

1. Abrir el MR → pestaña "Changes"
2. Dejar al menos 3 comentarios:
   - `[question]` sobre los tests placeholder
   - `[suggestion]` para mejorar el manejo de errores
   - `[praise]` por algo bien hecho

3. Enviar review con "Request changes"

### 3.2 El Autor Responde

```bash
cd /tmp/project-sprint1

# Mejorar el código según el feedback
cat > src/routes/health.js << 'JSEOF'
const express = require('express');
const router = express.Router();

router.get('/', async (req, res) => {
  try {
    res.status(200).json({
      status: 'healthy',
      uptime_seconds: Math.floor(process.uptime()),
      timestamp: new Date().toISOString(),
      version: process.env.APP_VERSION || 'dev',
      environment: process.env.NODE_ENV || 'development'
    });
  } catch (err) {
    res.status(503).json({
      status: 'unhealthy',
      error: err.message,
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;
JSEOF

git add src/routes/health.js
git commit -m "fix(health): add error handling and uptime in seconds

Adds try/catch to return 503 on unexpected errors.
Converts uptime to seconds integer for cleaner response.
Addresses code review feedback."

git push origin "${ISSUE_IID}-health-check-basico"
```

Responder y resolver todos los threads en la UI del MR.

### 3.3 Marcar como Ready y Aprobar

```bash
MR_IID=<id del MR>
curl --request PUT \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{\"title\": \"feat(health): implementar endpoint GET /health basico\"}" \
  "http://localhost/api/v4/projects/$PROJECT_ID/merge_requests/$MR_IID"
```

Aprobar en la UI → Click "Approve".

---

## ✅ Fase 4: Merge y Verificación (20 min)

### 4.1 Merge con Squash

En la UI del MR:
- Click "Merge"
- Activar "Squash commits"
- Editar el mensaje del squash commit

### 4.2 Verificar el Cierre Automático del Issue

```bash
# El issue #1 debe aparecer como "closed"
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/issues/1" \
  | python3 -c "
import sys, json
i = json.load(sys.stdin)
print(f'Issue #{i[\"iid\"]}: {i[\"state\"]}')
print(f'Titulo: {i[\"title\"]}')
"
```

### 4.3 Verificar el Historial de main

```bash
git checkout main
git pull origin main
git log --oneline -5

# Debe mostrar el squash commit del MR al tope del historial
```

---

## 📊 Fase 5: Issue Board y Resumen del Sprint (20 min)

### 5.1 Actualizar el Board

En la UI del Issue Board:
- Mover los issues restantes (#2-#6) a `workflow::in-progress` o `workflow::todo` según corresponda
- El issue #1 ya está cerrado y aparece en la columna "Closed"

### 5.2 Resumen Final via API

```bash
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/issues?milestone=Sprint 1&per_page=20" \
  | python3 -c "
import sys, json
from collections import Counter

issues = json.load(sys.stdin)
by_state = Counter()
by_workflow = Counter()

for i in issues:
    by_state[i['state']] += 1
    labels = [l['name'] for l in i['labels']]
    workflow = next((l for l in labels if l.startswith('workflow::')), 'sin-label')
    by_workflow[workflow] += 1

total = len(issues)
closed = by_state.get('closed', 0)
print(f'=== Sprint 1 Progress ===')
print(f'Total issues: {total}')
print(f'Cerrados: {closed}/{total} ({int(closed/total*100)}%)')
print()
print('Por estado de workflow:')
for state, count in sorted(by_workflow.items()):
    print(f'  {state:<25} {count}')
"
```

---

## 📋 Entregables del Proyecto

Subir al proyecto `bootcamp-org/backend/api-gateway` en GitLab:

### Código implementado:
- [ ] `src/routes/health.js` — endpoint funcional en `main`
- [ ] `tests/health.test.js` — tests (aunque sean placeholder)

### Evidencia del proceso:
- [ ] Screenshot del board con los 6 issues creados en Sprint 1
- [ ] Screenshot del MR con comentarios de code review
- [ ] Screenshot del MR aprobado y mergeado
- [ ] Screenshot del issue #1 cerrado automáticamente por el merge
- [ ] Output del script de resumen del sprint

### Documentación:
- [ ] Archivo `FLOW.md` en la raíz del repo con una descripción del proceso seguido:
  - Qué issues se crearon y por qué
  - Qué labels y milestone se usaron
  - Cómo fue el code review (qué se solicitó cambiar)
  - Cuántos commits tiene el MR vs el squash commit final

---

## 🏆 Criterios de Evaluación

| Criterio | Puntos |
|----------|--------|
| 6 issues creados con labels correctos y milestone | 20 pts |
| MR vinculado al issue con descripción completa | 20 pts |
| Code review con al menos 3 tipos de comentarios | 20 pts |
| Fix commit en respuesta al review | 15 pts |
| MR aprobado y mergeado con squash | 15 pts |
| Issue cerrado automáticamente y verificado via API | 10 pts |

**Total: 100 puntos** — Ver [rúbrica completa](../rubrica-evaluacion.md)

---

⬅️ **Prácticas:** [2-practicas/README.md](../2-practicas/README.md)
➡️ **Glosario:** [5-glosario/README.md](../5-glosario/README.md)

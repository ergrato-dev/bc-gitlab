# 🔬 Práctica 03 — Code Review Práctico

## 🎯 Objetivo

Realizar code review constructivo en GitLab: revisar diffs, escribir comentarios clasificados, usar Suggested Changes, aprobar/rechazar MRs, y experimentar el flujo completo de reviewer y autor.

## ⏱️ Tiempo estimado: 45 minutos

## 📋 Requisitos previos

- Completada la Práctica 02 (MR en estado Ready)
- Usuario `maintainer1` con acceso al proyecto
- `$GITLAB_TOKEN` disponible

---

## 📝 Paso 1: Agregar Código con Problemas Intencionales

Para practicar el feedback de seguridad, agregar código problemático:

```bash
cd /tmp/api-gw-mr-practice

cat >> src/routes/health.js << 'JSEOF'

// Endpoint de diagnóstico temporal
router.get('/debug', (req, res) => {
  const query = req.query.filter;
  res.json({
    debug: true,
    filter: query,
    env: process.env  // Exposición intencional para practicar review
  });
});

function logRequest(req) {
  console.log('Request from:', req.headers);
}
JSEOF

# Agregar console.log al inicio
sed -i '1s/^/\/\/ console.log debug\n/' src/routes/health.js

git add src/routes/health.js
git commit -m "feat(health): add debug endpoint (WIP)"

git push "http://root:$GITLAB_TOKEN@localhost/bootcamp-org/backend/api-gateway.git" \
  "$(git branch --show-current)"
```

---

## 📝 Paso 2: Revisar el Diff

```
http://localhost/bootcamp-org/backend/api-gateway/-/merge_requests

Click en el MR → pestaña "Changes"
```

Identificar los 4 problemas:
1. `env: process.env` — expone todos los secretos
2. `console.log` — logs en producción
3. Endpoint `/debug` sin autenticación
4. `function logRequest` — código muerto (no se llama)

---

## 📝 Paso 3: Escribir el Review (Start a Review)

En la pestaña "Changes":

**1. Buscar la línea `env: process.env` → Click en burbuja → "Start a review"**

```
[blocker] Este endpoint expone TODAS las variables de entorno del proceso,
incluyendo secretos como JWT_SECRET, DB_PASSWORD, GITLAB_TOKEN.

Vulnerabilidad crítica OWASP A02 (Cryptographic Failures / Information Exposure).

Eliminar el endpoint /debug completamente.
```

Insertar sugerencia (click "Insert suggestion"):

````suggestion
// Endpoint /debug eliminado — nunca exponer process.env via API
````

**2. Buscar `console.log` → "Add to review"**

```
[nit] console.log en producción satura los logs.
Eliminar o reemplazar con un logger estructurado (winston, pino).
```

**3. Buscar `function logRequest` → "Add to review"**

```
[question] Esta función no parece estar siendo llamada.
¿Es work in progress o puede eliminarse?
Si es necesaria en el futuro, crear issue para darle seguimiento.
```

**4. Buscar el bloque `try/catch` → "Add to review"**

```
[praise] Buen manejo de errores — devolver 503 en lugar de 500 es
la práctica correcta para health checks. Kubernetes/ELB usan este
código para decidir si sacar el pod de rotación.
```

**5. Click "Finish review" → seleccionar "Request changes"**

```
Summary: "Hay un blocker de seguridad crítico (process.env expuesto).
Corregir antes de mergear. Los nit son opcionales.
Buen trabajo en el manejo de 503."
```

Click **"Submit review"**.

---

## 📝 Paso 4: El Autor Corrige (Fix Commits)

```bash
cd /tmp/api-gw-mr-practice

# Versión limpia sin el código problemático
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
git commit -m "fix(health): remove debug endpoint and console.log

Remove /debug endpoint that exposed process.env (security blocker).
Remove console.log from production code.
Remove unused logRequest function.

Addresses code review by maintainer1."

git push "http://root:$GITLAB_TOKEN@localhost/bootcamp-org/backend/api-gateway.git" \
  "$(git branch --show-current)"
```

Responder a los threads en la UI del MR:

```
Thread [blocker]:
  → Comentar: "Fixed in último commit — /debug endpoint eliminado completamente"
  → Click "Resolve thread"

Thread [nit]:
  → Comentar: "Eliminado en el mismo commit"
  → Click "Resolve thread"

Thread [question]:
  → Comentar: "Era código de debug temporal, ya eliminado"
  → Click "Resolve thread"

Thread [praise]:
  → Comentar: "Gracias, era el comportamiento intencional para el health check"
  → (No resolver — es solo un comentario positivo)
```

---

## 📝 Paso 5: El Reviewer Aprueba

```
maintainer1 accede al MR:
  → Pestaña "Changes" → verifica la versión limpia
  → Confirma que /debug fue eliminado
  → Confirma sin console.log
  → Todos los threads bloqueantes están resueltos

Click "Approve" → Submit review → "Approve"

Verificar: banner verde "Approved by maintainer1"
```

---

## 📝 Paso 6: Merge Final

```
Click "Merge"

Opciones de merge:
  ✓ Squash commits cuando sea posible
  ✓ Delete source branch

Editar el mensaje del squash commit:
  feat(health): implementar endpoint /health con verificacion de dependencias

  Endpoint GET /health retorna 200 cuando el servicio esta sano
  y 503 cuando alguna dependencia falla.

  Closes #<N>

Click "Merge"
```

---

## 📝 Paso 7: Verificar Cierre Automático del Issue

```bash
# ¿QUÉ HACE?: Verifica que el issue se cerró automáticamente por el MR
# ¿POR QUÉ?: "Closes #N" en la descripción del MR cierra el issue al mergear
# ¿PARA QUÉ?: Confirmar que la trazabilidad issue→MR→commit funciona correctamente
PROJECT_ID=<TU_PROJECT_ID>
ISSUE_IID=<TU_ISSUE_IID>

curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$PROJECT_ID/issues/$ISSUE_IID" \
  | python3 -c "
import sys, json
i = json.load(sys.stdin)
print(f'Issue #{i[\"iid\"]}: estado={i[\"state\"]}')
print(f'  Titulo: {i[\"title\"]}')
print(f'  Cerrado: {i[\"closed_at\"] or \"No cerrado aun\"}')
"
```

---

## 🔧 Troubleshooting

**"All threads must be resolved" bloquea el merge**
```
→ Ir a Overview → buscar threads sin ✓ verde
→ Resolver cada uno: "Resolve thread"
→ El thread [praise] puede quedarse sin resolver (no es blocker)
```

**Reviewer no puede hacer Approve**
```
→ Verificar rol: maintainer1 necesita rol Maintainer en el proyecto
→ El autor del MR no puede auto-aprobarse
```

---

## ✅ Checklist de verificación

- [ ] Review enviado con "Request changes"
- [ ] Al menos 4 tipos de comentarios: [blocker], [nit], [question], [praise]
- [ ] Commit de fix corrige todos los problemas
- [ ] Threads de blocker y nit resueltos
- [ ] Reviewer aprueba tras verificar el fix
- [ ] MR mergeado con squash
- [ ] Issue cerrado automáticamente

## 📦 Entregables

- [ ] Captura del review con comentarios clasificados por tipo
- [ ] Captura del MR con "Changes Requested" (Request changes enviado)
- [ ] Captura de los threads resueltos
- [ ] Captura del MR con "Approved by maintainer1"
- [ ] Captura del issue con estado "Closed" y referencia al MR

---

⬅️ **Anterior:** [02 — Crear Merge Requests](../02-crear-merge-requests/README.md)
➡️ **Siguiente:** [04 — Issue Boards](../04-issue-boards/README.md)

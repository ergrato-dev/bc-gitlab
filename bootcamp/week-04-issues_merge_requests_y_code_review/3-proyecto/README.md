# Proyecto Semana 04 — Ciclo Completo GitLab Flow

## Objetivo
Ejecutar un ciclo completo de desarrollo usando GitLab Flow: desde la creacion del issue hasta el merge en produccion, pasando por code review.

## Escenario

Eres el developer asignado para implementar una nueva funcionalidad en el proyecto `api-gateway` de TechNova: **"Health Check Endpoint"** — un endpoint que reporta el estado de los servicios dependientes.

Debes seguir el GitLab Flow completo:

```
Issue → Branch → Development → Draft MR → Code Review → 
Fix → Approval → Merge to main → Merge to staging → Merge to production
```

## Requisitos

### 1. Issue

Crear issue `Implementar health check endpoint` con:
- Descripcion detallada (que hace, como se usa, respuesta esperada)
- Labels: ~feature, ~backend, ~priority::1
- Milestone: Sprint 1
- Criterios de aceptacion claros

### 2. Rama y Desarrollo

```bash
git checkout -b 6-health-check-endpoint
```

Implementar:
- Archivo `src/routes/health.js`:
  ```javascript
  const express = require('express');
  const router = express.Router();

  router.get('/health', async (req, res) => {
    const checks = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {
        database: await checkDatabase(),
        redis: await checkRedis()
      }
    };

    const allHealthy = Object.values(checks.services)
      .every(s => s.status === 'healthy');

    res.status(allHealthy ? 200 : 503).json(checks);
  });

  async function checkDatabase() {
    try {
      // Simulacion - en produccion usarias tu ORM/DB real
      return { status: 'healthy', latency: '12ms' };
    } catch {
      return { status: 'unhealthy', error: 'Connection refused' };
    }
  }

  async function checkRedis() {
    try {
      return { status: 'healthy', latency: '3ms' };
    } catch {
      return { status: 'unhealthy', error: 'Connection timeout' };
    }
  }

  module.exports = router;
  ```
- Agregar ruta en `src/app.js` o `src/index.js`
- Pruebas unitarias en `tests/health.test.js`
- Documentacion actualizada en README

### 3. Draft MR

- Crear MR con template y vincular al issue
- Titulo: `Draft: Implementar health check endpoint`
- Incluir `Closes #6` en descripcion
- Pipeline debe ejecutarse (aunque las pruebas fallen, es draft)

### 4. Code Review

Asignar reviewer y recibir al menos 2 comentarios de feedback (pueden ser de companeros del bootcamp o tu mismo usando otro usuario).

### 5. Correcciones y Merge

- Resolver todos los comentarios
- Pipeline en verde
- Quitar Draft
- Merge con Squash and Merge a `main`

### 6. Promocion a staging

Crear MR de `main` → `staging`:
- Titulo: `Release: Health check endpoint v1.0.0`
- Merge a staging

### 7. Promocion a produccion

Crear MR de `staging` → `production`:
- Titulo: `Deploy: Health check endpoint to production`
- Merge a produccion (final)

## Entregables

1. **URL del issue** con descripcion completa y labels
2. **URL del MR inicial** (Draft) con template
3. **Capturas del code review**:
   - Al menos 2 comentarios en linea
   - Review summary con Request Changes
   - Approval final
4. **URL del MR mergeado** a main
5. **URLs de MRs de promocion**: main→staging y staging→production
6. **Documento FLOW.md** describiendo:
   - El flujo seguido paso a paso
   - Decisiones tomadas (por que squash merge, por que draft primeiro)
   - Lecciones aprendidas
   - Que mejorarias para el proximo ciclo

## Criterios de Evaluacion

- [ ] Issue bien estructurado (descripcion, labels, milestone, criterios)
- [ ] Rama nombrada con ID del issue
- [ ] Commits atomicos y descriptivos
- [ ] MR usa template y vincula issue correctamente
- [ ] Draft MR creado ANTES de estar listo para merge
- [ ] Code review incluye comentarios especificos en lineas
- [ ] Cambios solicitados fueron corregidos
- [ ] Pipeline pasa (green)
- [ ] Merge squash mantiene historial limpio
- [ ] Ramas de ambiente (staging, production) existen y tienen proteccion
- [ ] Ciclo completo documentado en FLOW.md
- [ ] Issue se cerro automaticamente al mergear

## Script de Verificacion

```bash
#!/bin/bash
PROJECT="bootcamp-org/backend/api-gateway"
echo "=== Verificacion GitLab Flow - Semana 04 ==="

echo "--- Ramas ---"
git branch -a

echo "--- Issues abiertos ---"
# Via GitLab API
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$(echo $PROJECT | sed 's/\//%2F/g')/issues?state=opened" \
  | python3 -m json.tool 2>/dev/null || echo "Requiere GITLAB_TOKEN"

echo "--- MRs mergeados ---"
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects/$(echo $PROJECT | sed 's/\//%2F/g')/merge_requests?state=merged" \
  | python3 -m json.tool 2>/dev/null || echo "Requiere GITLAB_TOKEN"

echo "=== Verificacion completada ==="
```

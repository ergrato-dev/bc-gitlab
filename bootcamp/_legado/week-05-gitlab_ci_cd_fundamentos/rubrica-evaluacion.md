# 📊 Rúbrica de Evaluación — Semana 05

**CI/CD Fundamentos con GitLab**

---

## Información General

| Campo | Detalle |
|-------|---------|
| **Semana** | 05 — CI/CD Fundamentos |
| **Puntos totales** | 100 puntos |
| **Peso en el bootcamp** | 10% de la nota final |
| **Modalidad** | Individual |
| **Entrega** | URL del proyecto con `.gitlab-ci.yml` en `main` y pipelines visibles |

---

## Criterios de Evaluación

### 1. Estructura del Pipeline (20 puntos)

| Nivel | Descripción | Puntos |
|-------|-------------|--------|
| **Excelente** | 4 stages (validate, test, build, deploy). Jobs paralelos en al menos 2 stages. Deploy manual a producción configurado. Variables `$CI_COMMIT_SHORT_SHA` usadas en artifact names o build info. | 18-20 |
| **Bien** | 3 stages con al menos 2 jobs paralelos. Deploy stage presente aunque sea solo staging. | 14-17 |
| **Suficiente** | 2 stages secuenciales. Al menos 2 jobs. Pipeline que llega a "Passed". | 8-13 |
| **Insuficiente** | Solo 1 stage o pipeline que no pasa. | 0-7 |

**Evidencia requerida:**
- Captura del gráfico del pipeline mostrando stages y paralelismo
- El `.gitlab-ci.yml` committeado y accesible en el repo

---

### 2. Tests con Cobertura Reportada (25 puntos)

| Nivel | Descripción | Puntos |
|-------|-------------|--------|
| **Excelente** | Al menos 5 tests unitarios pasando. Cobertura extraída con regex `coverage:` y visible en la UI del pipeline. Artifact `coverage/` generado y descargable. `artifacts:reports:junit` configurado y mostrando resultados en el MR/pipeline. | 23-25 |
| **Bien** | Al menos 3 tests pasando. Cobertura reportada en los logs aunque no en la UI. Artifact de coverage presente. | 18-22 |
| **Suficiente** | Al menos 2 tests. Pipeline de tests en verde aunque sin reporte de cobertura estructurado. | 10-17 |
| **Insuficiente** | Sin tests o tests que no se ejecutan en el pipeline. | 0-9 |

**Evidencia requerida:**
- Captura de los logs del job `unit-tests` mostrando los tests pasados y el porcentaje de cobertura
- Captura del artifact de coverage descargable

---

### 3. Tests de Integración con Services (20 puntos)

| Nivel | Descripción | Puntos |
|-------|-------------|--------|
| **Excelente** | Job de integración con PostgreSQL o Redis como service. Espera activa al servicio antes de correr tests (`pg_isready` o similar). Al menos 2 operaciones verificadas (INSERT + SELECT, o GET + SET en Redis). Alias configurado en el service. | 18-20 |
| **Bien** | Job de integración con al menos un service. Conexión verificada. Al menos 1 operación. | 14-17 |
| **Suficiente** | Intento de usar services pero con issues menores (como no esperar al servicio). | 8-13 |
| **Insuficiente** | Sin tests de integración o sin services. | 0-7 |

**Evidencia requerida:**
- Captura de los logs del job de integración mostrando la conexión a PostgreSQL/Redis exitosa
- Las queries o comandos ejecutados visibles en los logs

---

### 4. Artifacts Funcionales (20 puntos)

| Nivel | Descripción | Puntos |
|-------|-------------|--------|
| **Excelente** | Artifact de build descargable desde la UI con nombre descriptivo (`api-gateway-$CI_COMMIT_SHORT_SHA`). Artifact pasa entre stages correctamente (build → deploy usa el artifact de build). `expire_in` configurado apropiadamente. | 18-20 |
| **Bien** | Artifact de build generado y descargable. Pasa entre stages. `expire_in` presente. | 14-17 |
| **Suficiente** | Artifact generado pero sin configuración de nombre o `expire_in`. | 8-13 |
| **Insuficiente** | Sin artifacts o artifacts vacíos. | 0-7 |

**Evidencia requerida:**
- Captura del job con el artifact descargable visible
- Script de descarga via API ejecutado exitosamente

---

### 5. Cache Configurado (15 puntos)

| Nivel | Descripción | Puntos |
|-------|-------------|--------|
| **Excelente** | Cache con `key.files` apuntando al archivo de dependencias (package.json, requirements.txt). Política `pull-push` en install, `pull` en los demás jobs. Segunda ejecución claramente más rápida (cache hit en logs). | 13-15 |
| **Bien** | Cache configurado con alguna `key`. Funciona en la segunda ejecución. | 10-12 |
| **Suficiente** | Cache configurado aunque sea con `key: $CI_COMMIT_REF_SLUG` básico. | 6-9 |
| **Insuficiente** | Sin cache o cache mal configurado que no funciona. | 0-5 |

**Evidencia requerida:**
- Captura de los logs del segundo run mostrando "Downloading cache..." (cache hit)
- Comparación de tiempo entre primera ejecución (sin cache) y segunda (con cache)

---

## Penalizaciones

| Situación | Penalización |
|-----------|-------------|
| Credenciales o tokens hardcodeados en `.gitlab-ci.yml` | −20 pts (obligatorio revocar el token) |
| Pipeline que nunca llega a "Passed" | −10 pts |
| Jobs que dependen de estado global del servidor (no reproducibles) | −10 pts |
| Sin `expire_in` en artifacts (deja basura acumulándose) | −5 pts |
| Usar `only/except` en lugar de `rules` (deprecados) | −5 pts |

---

## Bonificaciones

| Situación | Bonificación |
|-----------|-------------|
| Usar `extends` o anchors YAML para evitar duplicación | +5 pts |
| Job matrix con `parallel:matrix` (mismos tests en múltiples versiones) | +5 pts |
| `artifacts:reports:junit` correctamente integrado en el MR | +5 pts |
| Pipeline ejecutándose en < 5 minutos total (bien optimizado) | +3 pts |

*Puntuación máxima con bonificaciones: 118 pts. Se reporta sobre 100.*

---

## Escala de Calificación Final

| Rango | Calificación | Descripción |
|-------|-------------|-------------|
| 90-100 pts | **A — Excelente** | Pipeline completo, bien estructurado, con tests reales y cache |
| 75-89 pts | **B — Bien** | Pipeline funcional con áreas menores por mejorar |
| 60-74 pts | **C — Suficiente** | Pipeline básico, comprensión de CI pero implementación incompleta |
| 40-59 pts | **D — Insuficiente** | Pipeline que llega a Passed pero sin estructura ni best practices |
| 0-39 pts | **F — Reprobado** | Sin pipeline funcional o trabajo no entregado |

---

## Cómo Entregar

1. Proyecto en `http://localhost/bootcamp-org/backend/api-gateway`
2. `.gitlab-ci.yml` en la rama `main`
3. Al menos 2 pipelines exitosos visibles en `CI/CD → Pipelines`
4. Screenshots subidas a `4-recursos/evidencias-semana-05/` del proyecto

---

⬅️ **Glosario:** [5-glosario/README.md](./5-glosario/README.md)

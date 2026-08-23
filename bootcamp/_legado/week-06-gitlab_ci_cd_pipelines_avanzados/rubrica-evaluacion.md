# 📊 Rúbrica de Evaluación — Semana 06

**GitLab CI/CD: Pipelines Avanzados**

---

## Información General

| Campo | Detalle |
|-------|---------|
| **Semana** | 06 — Pipelines Avanzados |
| **Puntos totales** | 100 puntos |
| **Peso en el bootcamp** | 10% de la nota final |
| **Modalidad** | Individual |
| **Entrega** | URL del proyecto con pipeline modular en `main`, environments configurados y capturas de pantalla |

---

## Criterios de Evaluación

### 1. Variables y Secretos (20 puntos)

| Nivel | Descripción | Puntos |
|-------|-------------|--------|
| **Excelente** | Al menos 2 variables en Settings (una masked, una protected). Variables predefinidas de GitLab usadas en artifacts names (`$CI_COMMIT_SHORT_SHA`) o en script. Ningún secreto hardcodeado en `.gitlab-ci.yml`. `DEPLOY_TOKEN` protegida y disponible solo en ramas protegidas verificado. | 18-20 |
| **Bien** | Una variable masked configurada. Variables predefinidas usadas en logs. Sin secretos hardcodeados. | 14-17 |
| **Suficiente** | Variables en `.gitlab-ci.yml` pero ninguna configurada en Settings. Sin masked/protected. | 8-13 |
| **Insuficiente** | Secretos hardcodeados en el pipeline o sin uso de variables. | 0-7 |

**Evidencia requerida:**
- Captura de `Settings → CI/CD → Variables` mostrando las variables (columnas Key, Masked, Protected)
- Captura de logs con `SECRET_TOKEN: ****` (variable enmascarada)
- Captura del job mostrando que `DEPLOY_TOKEN` está vacía en rama `feature/*` y disponible en `main`

---

### 2. Rules y Ejecución Condicional (25 puntos)

| Nivel | Descripción | Puntos |
|-------|-------------|--------|
| **Excelente** | Pipeline ejecuta jobs diferentes en al menos 3 contextos distintos: feature branch (solo tests rápidos), develop (staging automático), main (tests completos + deploy manual), tag semántico (deploy a producción). Usa `rules:variables` para ajustar comportamiento según contexto. | 23-25 |
| **Bien** | Pipeline diferencia entre 2 contextos (ej: main vs feature). Tags disparan deploy a producción. `rules` correctamente usando `if`, `when` y `allow_failure`. | 18-22 |
| **Suficiente** | Al menos una `rule` condicional funcionando. Puede tener jobs que se saltan según la rama. Sin uso de `changes` o `exists`. | 10-17 |
| **Insuficiente** | Usando `only`/`except` legacy o sin ninguna condicionalidad. | 0-9 |

**Evidencia requerida:**
- Captura del pipeline en `main`: jobs de test completos + `deploy-production` en estado manual ⏸️
- Captura del pipeline en `feature/*`: solo tests rápidos y lint
- Captura del pipeline de un tag `v*`: `deploy-production` disponible y ejecutado

---

### 3. Modularización con Include (25 puntos)

| Nivel | Descripción | Puntos |
|-------|-------------|--------|
| **Excelente** | `.gitlab-ci.yml` principal solo contiene `include:` y `variables:` globales. Al menos 4 módulos: `stages.yml`, `build.yml`, `test.yml`, `deploy.yml`. Usa `extends` con templates (prefijo `.`) para evitar duplicación. CI Lint confirma el pipeline expandido como válido. | 23-25 |
| **Bien** | Pipeline dividido en al menos 3 módulos. `.gitlab-ci.yml` con algo de contenido adicional además de includes. `extends` usado en al menos un job. | 18-22 |
| **Suficiente** | Al menos 2 archivos con `include:local`. El pipeline funciona aunque el orquestador tenga jobs directamente. | 10-17 |
| **Insuficiente** | Todo en un solo `.gitlab-ci.yml`. Sin modularización. | 0-9 |

**Evidencia requerida:**
- Captura de la estructura de directorios `.gitlab/ci/` con los módulos
- Captura del pipeline completo mostrando todos los stages y jobs (provenientes de módulos distintos)
- Output del CI Lint API mostrando `valid: true` y la lista completa de jobs

---

### 4. Environments y Deployments (20 puntos)

| Nivel | Descripción | Puntos |
|-------|-------------|--------|
| **Excelente** | Environments `staging` y `production` visibles en `Operate → Environments` con URLs configuradas. `staging` con despliegue automático desde `develop` y `on_stop` configurado. `production` con deploy manual. Historial de al menos 3 deployments a staging. Rollback probado. | 18-20 |
| **Bien** | Ambos environments configurados. URLs presentes. Al menos 2 deployments en staging. Deploy manual a producción exitoso. | 14-17 |
| **Suficiente** | Al menos un environment configurado con `environment:` keyword. Historial de 1 deployment. | 8-13 |
| **Insuficiente** | Sin `environment:` keyword o environments que no aparecen en la UI. | 0-7 |

**Evidencia requerida:**
- Captura de `Operate → Environments` mostrando staging y production con sus URLs
- Captura del historial de deployments de staging (al menos 3 entradas)
- Captura del environment `staging` en estado `stopped` después de usar Stop

---

### 5. Integración y Calidad General (10 puntos)

| Nivel | Descripción | Puntos |
|-------|-------------|--------|
| **Excelente** | Pipeline en `main` llega a passed con todos los stages. Artifacts de build con `expire_in` y nombre con `$CI_COMMIT_SHORT_SHA`. JUnit report visible en la pestaña Tests. Al menos 1 trigger o downstream pipeline configurado. | 9-10 |
| **Bien** | Pipeline funciona. Artifacts generados. JUnit report presente aunque sea básico. | 7-8 |
| **Suficiente** | Pipeline llega a passed pero sin artifacts nombrados o JUnit report. | 4-6 |
| **Insuficiente** | Pipeline que no llega a passed en `main`. | 0-3 |

**Evidencia requerida:**
- Captura del pipeline completo en `main` con status `passed`
- Captura de la pestaña `Tests` del job `unit-tests` mostrando los tests pasados

---

## Penalizaciones

| Situación | Penalización |
|-----------|-------------|
| Credenciales o tokens hardcodeados en `.gitlab-ci.yml` o en módulos | −20 pts (obligatorio revocar el token) |
| Usando `only`/`except` legacy en lugar de `rules` | −5 pts |
| Pipeline que nunca llega a "Passed" en `main` | −10 pts |
| Sin `expire_in` en ningún artifact | −5 pts |
| Todos los jobs en un único `.gitlab-ci.yml` (sin modularizar) | −10 pts |
| Variable masked sin cumplir requisitos de formato (sin enmascaramiento real) | −5 pts |

---

## Bonificaciones

| Situación | Bonificación |
|-----------|-------------|
| Review app configurada para MRs con `auto_stop_in` | +5 pts |
| Trigger multi-proyecto con `strategy: depend` funcionando | +5 pts |
| `include:project` usando un repositorio de templates separado | +5 pts |
| `rules:variables` para mismo job con diferente comportamiento | +3 pts |
| Protected environment con aprobaciones configuradas | +3 pts |

*Puntuación máxima con bonificaciones: 121 pts. Se reporta sobre 100.*

---

## Escala de Calificación Final

| Rango | Calificación | Descripción |
|-------|-------------|-------------|
| 90-100 pts | **A — Excelente** | Pipeline completo, modular, con variables protegidas y environments funcionales |
| 75-89 pts | **B — Bien** | Pipeline funcional con áreas menores por mejorar |
| 60-74 pts | **C — Suficiente** | Pipeline básico, comprensión de conceptos pero implementación incompleta |
| 40-59 pts | **D — Insuficiente** | Pipeline que funciona pero sin modularización ni buenas prácticas |
| 0-39 pts | **F — Reprobado** | Sin pipeline funcional o trabajo no entregado |

---

## Cómo Entregar

1. Proyecto en `http://localhost/bootcamp-org/backend/api-gateway` (o el proyecto asignado)
2. `.gitlab-ci.yml` + módulos `.gitlab/ci/` en la rama `main`
3. Al menos 3 pipelines exitosos visibles en `CI/CD → Pipelines` (main, develop, feature)
4. Screenshots en `4-recursos/evidencias-semana-06/` del proyecto GitLab

---

⬅️ **Glosario:** [5-glosario/README.md](./5-glosario/README.md)

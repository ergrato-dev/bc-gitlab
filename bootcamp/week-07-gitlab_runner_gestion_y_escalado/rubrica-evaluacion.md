# 📊 Rúbrica de Evaluación — Semana 07

**GitLab Runner: Gestión y Escalado**

---

## Información General

| Campo | Detalle |
|-------|---------|
| **Semana** | 07 — GitLab Runner: Gestión y Escalado |
| **Puntos totales** | 100 puntos |
| **Peso en el bootcamp** | 10% de la nota final |
| **Modalidad** | Individual |
| **Entrega** | URL del proyecto con pipeline de demostración + config.toml anotados + evidencias visuales |

---

## Criterios de Evaluación

### 1. Instalación y Registro de Runners (25 puntos)

| Nivel | Descripción | Puntos |
|-------|-------------|--------|
| **Excelente** | 5 runners registrados y activos (● verde). Registro vía authentication tokens modernos (no registration tokens legacy). `config.toml` de cada runner exportado, con parámetros anotados (concurrent, pull_policy, volumes). Al menos 2 tipos de executor (Docker + Shell). | 23-25 |
| **Bien** | Al menos 3 runners activos con diferentes tags. Config.toml básico sin anotaciones. Uso de registration tokens (método antiguo aceptado). | 18-22 |
| **Suficiente** | Al menos 1 runner activo con executor Docker. Config.toml existe aunque sin documentar. Pipeline ejecuta al menos un job. | 10-17 |
| **Insuficiente** | Sin runners activos o runners en estado offline persistente. Pipeline en `pending` por falta de runners. | 0-9 |

**Evidencia requerida:**
- Captura de Admin Area → CI/CD → Runners mostrando 5 runners ● verde
- `config.toml` de al menos 2 runners (Docker + Shell) con comentarios explicando cada sección
- Output de `docker ps` mostrando los contenedores de runners corriendo

---

### 2. Ejecutores y Configuración (25 puntos)

| Nivel | Descripción | Puntos |
|-------|-------------|--------|
| **Excelente** | Pipeline demuestra Docker Executor con `image:` personalizada y `services:` (PostgreSQL u otro). Shell Executor accede directamente al host (hostname y whoami diferentes). Demostración de aislamiento: archivo creado en job Docker no persiste en el siguiente job. `pull_policy = "if-not-present"` configurado para reducir latencia. | 23-25 |
| **Bien** | Docker y Shell Executor funcionando. `services:` usados aunque sea con imagen trivial. Diferencia entre hostname del contenedor y del host documentada. | 18-22 |
| **Suficiente** | Solo Docker Executor funcionando. Sin demostración de `services:`. Comprensión básica de la diferencia entre ejecutores en la documentación. | 10-17 |
| **Insuficiente** | Solo un tipo de executor. Sin evidencia de comprensión de aislamiento. | 0-9 |

**Evidencia requerida:**
- Captura de log del job Docker mostrando hostname del contenedor (ID aleatorio)
- Captura de log del job Shell mostrando hostname real del servidor
- Log del job con `services:` PostgreSQL mostrando conexión exitosa
- Comparación `whoami` + `OS` de Docker vs Shell en la tabla de análisis

---

### 3. Tags y Enrutamiento de Jobs (25 puntos)

| Nivel | Descripción | Puntos |
|-------|-------------|--------|
| **Excelente** | Pipeline con al menos 5 jobs dirigidos a 3 runners diferentes por tags. Demostración de: (a) job sin tags → runner con run_untagged=true, (b) job con tags inexistentes → estado pending, (c) runner pausado → jobs quedan pending → runner activado → jobs corren. Tabla de routing completa (job → runner verificado). | 23-25 |
| **Bien** | Pipeline con 3 jobs en 2 runners diferentes. Demostración de job pending documentada. `run_untagged` configurado correctamente en runners especializados. | 18-22 |
| **Suficiente** | Al menos 2 jobs en runners diferentes por tags. Sin demostración de pending ni runner pausado. | 10-17 |
| **Insuficiente** | Todos los jobs van al mismo runner. Sin demostración de routing diferenciado. | 0-9 |

**Evidencia requerida:**
- Output del script de análisis (Prueba D del proyecto): tabla job → runner
- Captura de job en estado `pending` por tags inexistentes (GPU en este caso)
- Captura de runner en estado `paused` con jobs pending
- Captura de jobs retomando ejecución al reactivar el runner

---

### 4. Administración y Gestión via API (15 puntos)

| Nivel | Descripción | Puntos |
|-------|-------------|--------|
| **Excelente** | Uso de API para: crear runner tokens, listar runners con estado y tags, pausar/reactivar runner, consultar jobs por estado (running, pending, success). Al menos 4 comandos API distintos usados y documentados con su propósito. | 14-15 |
| **Bien** | API usada para al menos 2 operaciones (listar runners + consultar jobs). Comandos con su propósito explicado. | 10-13 |
| **Suficiente** | Solo verificación via API (GET /runners). Sin operaciones de gestión (pause/resume). | 6-9 |
| **Insuficiente** | Solo uso de UI. Sin demostración de uso de API. | 0-5 |

**Evidencia requerida:**
- Logs de terminales mostrando los comandos `curl` ejecutados y sus respuestas
- Al menos una operación de escritura via API (pausa de runner o actualización de tags)

---

### 5. Calidad y Documentación (10 puntos)

| Nivel | Descripción | Puntos |
|-------|-------------|--------|
| **Excelente** | `config.toml` de cada runner exportado y anotado explicando cada parámetro. Pipeline en `main` en estado `passed`. Evidencias visuales organizadas. Directorio `devcorp-runners/` con estructura completa (config/ + evidencia/). | 9-10 |
| **Bien** | Config.toml disponible aunque parcialmente anotado. Pipeline funcional. Capturas de pantalla presentes. | 7-8 |
| **Suficiente** | Config.toml sin anotar. Pipeline llega a `passed` aunque con warnings. | 4-6 |
| **Insuficiente** | Sin config.toml documentado. Pipeline que no llega a `passed` en `main`. | 0-3 |

**Evidencia requerida:**
- Captura del pipeline completo en `main` con status `passed`
- Directorio de evidencias con capturas numeradas
- Config.toml de al menos los runners Docker y Shell anotados

---

## Penalizaciones

| Situación | Penalización |
|-----------|-------------|
| Registration token hardcodeado en scripts commiteados al repositorio | −15 pts |
| Runner con `privileged = true` sin justificación documentada (DinD sin alternativa) | −5 pts |
| Usando `docker+machine` executor (Docker Machine deprecado) | −10 pts |
| Pipeline que nunca llega a `passed` en `main` | −10 pts |
| Todos los runners con mismo executor (sin diversidad Docker + Shell) | −10 pts |
| Jobs con tags genéricos que no demuestran enrutamiento real | −5 pts |

---

## Bonificaciones

| Situación | Bonificación |
|-----------|-------------|
| Runner en Kubernetes (Práctica 04 completada) con pods efímeros demostrados | +10 pts |
| Configuración de autoscaling con Fleeting (aunque sea en sandbox/demo) | +8 pts |
| Métricas del runner exportadas a Prometheus (puerto 9252 accesible) | +5 pts |
| Runner con `max_use_count` configurado para renovación periódica de workers | +3 pts |
| Script de infra-como-código para reproducir toda la instalación | +5 pts |

*Puntuación máxima con bonificaciones: 131 pts. Se reporta sobre 100.*

---

## Escala de Calificación Final

| Rango | Calificación | Descripción |
|-------|-------------|-------------|
| 90-100 pts | **A — Excelente** | Infraestructura completa, routing demostrado, API usada, configuración documentada |
| 75-89 pts | **B — Bien** | Infraestructura funcional con routing básico y documentación adecuada |
| 60-74 pts | **C — Suficiente** | Runners instalados y funcionando pero routing y documentación incompletos |
| 40-59 pts | **D — Insuficiente** | Runner básico funcionando pero sin demostración de gestión real |
| 0-39 pts | **F — Reprobado** | Sin runners activos o trabajo no entregado |

---

## Cómo Entregar

1. Proyecto GitLab con el pipeline de demostración en `main` (estado `passed`)
2. Directorio `devcorp-runners/` en el repositorio con:
   - `config/` — archivos config.toml anotados
   - `evidencia/` — capturas de pantalla numeradas
3. MR de entrega con descripción indicando los runners creados y los IDs de los pipelines de evidencia

---

⬅️ **Glosario:** [5-glosario/README.md](./5-glosario/README.md)

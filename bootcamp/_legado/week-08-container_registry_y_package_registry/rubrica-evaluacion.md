# Rúbrica de Evaluación — Semana 08: Container Registry y Package Registry

**Mínimo para aprobar:** 70 puntos (sobre 100)
**Penalización por entrega tardía:** -5 puntos por día hábil
**Bonificación por reto adicional:** +5 puntos (máx 1 reto)

---

## Criterio 1: Container Registry y Autenticación (20 puntos)

| Nivel | Puntos | Descripción |
|-------|--------|-------------|
| Excelente | 20 | Habilita el Container Registry via `gitlab.rb`, demuestra los 3 métodos de autenticación (PAT / CI Job Token / Deploy Token), explica correctamente qué método usar en cada escenario y por qué. |
| Bien | 15 | Habilita el registry y usa correctamente CI Job Token en el pipeline. Conoce los otros métodos pero no los demuestra en práctica. |
| Suficiente | 10 | Container Registry habilitado y puede hacer push de una imagen, pero confunde los métodos de autenticación o necesita ayuda para configurar el login. |
| Insuficiente | 0 | No logra habilitar el registry o no puede autenticarse. No distingue entre PAT, CI Job Token y Deploy Token. |

---

## Criterio 2: Build de Imágenes en CI (25 puntos)

| Nivel | Puntos | Descripción |
|-------|--------|-------------|
| Excelente | 25 | Implementa Dockerfile con multi-stage build (builder + runtime). Pipeline funcional con DinD Y Kaniko. Aplica las 4 estrategias de tag (SHA inmutable, branch movible, SemVer, latest). Explica la diferencia de seguridad entre DinD (privileged) y Kaniko (rootless). |
| Bien | 19 | Multi-stage Dockerfile + pipeline con al menos uno de los dos métodos (DinD o Kaniko). Aplica al menos 3 de las 4 estrategias de tag. |
| Suficiente | 13 | Dockerfile sin multi-stage o con multi-stage pero pipeline funciona solo con DinD. Aplica 1-2 estrategias de tag. |
| Insuficiente | 0 | No logra construir ni publicar una imagen en CI. Pipeline falla sin diagnóstico claro. |

---

## Criterio 3: Package Registry (20 puntos)

| Nivel | Puntos | Descripción |
|-------|--------|-------------|
| Excelente | 20 | Publica paquete npm Y paquete PyPI en el Package Registry del proyecto. Configura `.npmrc` con scope correcto. Verifica las publicaciones via API. Explica cuándo usar cada formato (npm, PyPI, Maven, Generic). |
| Bien | 15 | Publica al menos un tipo de paquete (npm o PyPI) correctamente via CI Job Token. La publicación es verificable en la UI y via API. |
| Suficiente | 10 | Intenta publicar al menos un paquete pero hay problemas en la configuración del `.npmrc` o en la autenticación (requiere correcciones). |
| Insuficiente | 0 | No logra publicar ningún paquete en el Package Registry. No comprende la diferencia entre Container Registry y Package Registry. |

---

## Criterio 4: Security Scanning (25 puntos)

| Nivel | Puntos | Descripción |
|-------|--------|-------------|
| Excelente | 25 | Integra los 4 tipos de scanning (SAST, Secret Detection, Dependency Scanning, Container Scanning) en el pipeline. Configura `CS_SEVERITY_THRESHOLD` para Container Scanning. Interpreta el Vulnerability Report: identifica al menos 1 vulnerabilidad real, la triage y la dismiss con razón documentada. |
| Bien | 19 | Integra al menos 3 tipos de scanning. Pipeline ejecuta los escaneos y los resultados aparecen en el Security tab. Dismissea al menos 1 vulnerabilidad. |
| Suficiente | 13 | Integra solo Container Scanning o solo SAST. Los templates se incluyen correctamente pero hay errores de configuración en alguno de los jobs. |
| Insuficiente | 0 | No logra integrar ningún scanner. No entiende la diferencia entre SAST, Dependency Scanning y Container Scanning. |

---

## Criterio 5: Tag Cleanup Policy y Gestión del Registry (10 puntos)

| Nivel | Puntos | Descripción |
|-------|--------|-------------|
| Excelente | 10 | Configura la Tag Cleanup Policy via API con cadencia, `keep_n`, `older_than` y `name_regex_keep` personalizados. Verifica la configuración consultando el proyecto via API. Explica la diferencia entre eliminar un tag (libera referencia) y garbage collection (recupera espacio físico). |
| Bien | 7 | Configura la Cleanup Policy via UI o API. La política tiene al menos `keep_n` y `name_regex_keep` configurados de forma que protege los tags de producción. |
| Suficiente | 4 | Configura la Cleanup Policy con los valores por defecto sin personalizarla. Habilita la política pero no verifica que esté activa. |
| Insuficiente | 0 | No configura ninguna política de limpieza. No conoce el concepto de garbage collection en el registry. |

---

## Penalizaciones

| Situación | Penalización |
|-----------|-------------|
| Pipeline con credenciales hardcodeadas (token, password) en el código | -10 puntos |
| Uso de `privileged: true` en Kaniko (derrota el propósito del ejercicio) | -5 puntos |
| Imagen publicada sin ningún tag (solo digest) | -3 puntos |
| `latest` como único tag (sin SHA ni SemVer) | -3 puntos |
| Cleanup Policy configurada para eliminar tags de producción (`v*`, `main`) | -5 puntos |

---

## Bonificaciones (máx. +5 puntos, solo 1 reto)

| Reto | Bonificación |
|------|-------------|
| Pipeline de Kaniko con cache en registry (`--cache=true --cache-repo`) + medición de tiempo con/sin cache | +5 |
| Security gate personalizado que bloquea publish si hay CRITICAL en Container Scanning | +5 |
| Publicar paquete npm con metadatos de build (SHA + pipeline ID en `gitlabBuild` del package.json) | +5 |

---

## Tabla de calificación

| Puntos | Calificación |
|--------|-------------|
| 90-100 | Excelente |
| 80-89  | Muy bien |
| 70-79  | Bien |
| 60-69  | Suficiente (requiere revisión) |
| 0-59   | Insuficiente (no aprueba) |

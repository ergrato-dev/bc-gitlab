# Práctica 03 — Security Scanning: SAST + Secret Detection

## Objetivo

Implementar SAST y Secret Detection en un pipeline CI/CD de GitLab CE.

## Instrucciones

### Paso 1: Preparar el repositorio
Crea o usa un proyecto existente con código en algún lenguaje soportado (Python, JavaScript, Java, etc.). Crea un archivo `.gitlab-ci.yml` con la siguiente estructura base:

```yaml
stages:
  - test

include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
```

### Paso 2: Introducir vulnerabilidades de prueba
Agrega código vulnerable intencionalmente para verificar que SAST lo detecta. Ejemplos:

**Python (bandit):**
```python
import pickle
data = pickle.loads(user_input)  # B301: Deserialization vulnerability

password = "hardcoded123"  # B105: Hardcoded password
```

**JavaScript (eslint-plugin-security):**
```javascript
eval("console.log('" + userInput + "')");  // eval injection
```

### Paso 3: Introducir un secreto falso
Agrega un archivo con un secreto falso para probar Secret Detection:
```
# .env.example
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

### Paso 4: Ejecutar el pipeline
1. Haz commit y push de los cambios
2. Observa la ejecución del pipeline en CI/CD → Pipelines
3. Verifica que los jobs `sast` y `secret_detection` se ejecuten

### Paso 5: Analizar resultados
1. Ve a Security → Vulnerability Report
2. Identifica las vulnerabilidades detectadas
3. Para cada vulnerabilidad, verifica: severidad, archivo, línea, CWE
4. Clasifica los hallazgos como verdaderos positivos o falsos positivos

### Paso 6: Configurar umbrales
En `.gitlab-ci.yml`, configura la sensibilidad:
```yaml
sast:
  variables:
    SAST_EXCLUDED_PATHS: "spec, test, tests, tmp"
    SECRET_DETECTION_HISTORIC_SCAN: "true"
```

## Preguntas de reflexión
- ¿Cuánto tiempo tardó el job de SAST en ejecutarse?
- ¿Detectó Secret Detection el secreto falso? ¿Qué patrón usó?
- ¿Qué harías con los falsos positivos encontrados?

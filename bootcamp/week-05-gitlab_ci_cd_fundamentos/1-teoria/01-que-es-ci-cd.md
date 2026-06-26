# 📖 01 — ¿Qué es CI/CD?

## 🎯 Objetivos de aprendizaje

- ✅ Entender la diferencia entre CI, CD (Delivery) y CD (Deployment)
- ✅ Comprender el concepto de "Pipeline as Code" y sus ventajas
- ✅ Identificar los problemas que CI/CD resuelve en equipos de software
- ✅ Conocer el rol de GitLab Runner en la ejecución de pipelines
- ✅ Entender qué ocurre internamente cuando haces push a un repositorio con CI

---

## 🤔 ¿Por Qué CI/CD?

Antes de CI/CD, el proceso de integración de código era así:

```
Semana 1: Developer A trabaja en feature-login en su máquina
Semana 1: Developer B trabaja en feature-payments en su máquina
Semana 2: Ambos intentan integrar sus cambios → 47 conflictos
Semana 2-3: "Integration Hell" — resolver conflictos, tests rotos, deploy manual
Semana 3: Deploy en producción — cruzan los dedos
```

**Con CI/CD:**

```
Día 1: Developer A hace push de 5 commits pequeños
Día 1: Pipeline automático: lint ✓ → tests ✓ → deploy staging ✓
Día 1: Developer B también push, también se integra automáticamente
Día 1: Cualquier conflicto se detecta en minutos, no semanas
```

**Analogía:** CI/CD es como la línea de montaje de una fábrica de coches. Sin ella, cada obrero construye el coche entero en su taller y al final hay que unir todas las piezas (integration hell). Con la línea de montaje, cada pieza se verifica antes de pasar al siguiente punto — si un tornillo falla, se detecta en ese punto, no cuando el coche ya está pintado.

---

## 📐 Definiciones Fundamentales

### Continuous Integration (CI) — Integración Continua

La práctica de integrar cambios de código frecuentemente (varias veces al día) en un repositorio compartido, donde cada integración dispara una verificación automatizada.

```
CI responde a: "¿Este código funciona junto con el código de todos los demás?"

Incluye:
  - Compilar el código (si aplica)
  - Ejecutar tests unitarios
  - Analizar calidad del código (lint, code coverage)
  - Detectar vulnerabilidades de seguridad (SAST)
```

### Continuous Delivery (CD) — Entrega Continua

Extensión de CI donde el código que pasa todas las verificaciones se mantiene en un estado listo para desplegar en cualquier momento. El deploy a producción es **manual** (un humano decide cuándo).

```
CD Delivery responde a: "¿Podemos desplegar este código a producción ahora mismo
                          si así lo decidimos?"

El deploy existe pero requiere un click/aprobación humana.
```

### Continuous Deployment (CDep) — Despliegue Continuo

Cada commit que pasa todos los tests se despliega automáticamente a producción **sin intervención humana**.

```
CD Deployment responde a: "¿Este código está en producción ya?"

Requiere:
  - Cobertura de tests muy alta
  - Monitoreo y alertas robustas
  - Capacidad de rollback automático
  - Mucha confianza en el proceso
```

### La Progresión

```
          CI                CD-Delivery          CD-Deployment
          ↓                      ↓                     ↓
Push → [Tests automáticos] → [Deploy staging] → [Deploy producción]
           ↑ Auto                 ↑ Auto            ↑ Auto o Manual
```

| Práctica | Deploy a staging | Deploy a producción |
|----------|-----------------|---------------------|
| Solo CI | Manual | Manual |
| CI + CD Delivery | Automático | Manual (click) |
| CI + CD Deployment | Automático | Automático |

---

## 🔄 Pipeline as Code

La configuración del pipeline vive en el repositorio como un archivo YAML — no en una interfaz web externa. Esto tiene implicaciones importantes:

```
Proyecto/
├── src/
│   └── app.js
├── tests/
│   └── app.test.js
├── package.json
└── .gitlab-ci.yml        ← La definición del pipeline
```

**Ventajas de tener el pipeline en el repositorio:**

```
Versionado junto al código  → La historia de cambios del pipeline está en git
Revisable en MRs            → El code review incluye cambios al pipeline
Reproducible                → Cualquiera puede levantar el mismo pipeline en otro repo
Auditable                   → git blame muestra quién cambió qué en el pipeline
Multi-branch                → Cada rama puede tener su propia versión del pipeline
```

---

## ⚙️ Cómo Funciona GitLab CI/CD

### Los Actores

```
┌─────────────────────────────────────────────────────────────┐
│                      GitLab Server                          │
│  (donde está el código y la definición del pipeline)        │
│                                                             │
│  ┌──────────────┐    ┌──────────────────────────────────┐   │
│  │  Repository  │ →  │  Pipeline Engine                 │   │
│  │  .gitlab-ci  │    │  (lee .gitlab-ci.yml y planifica)│   │
│  └──────────────┘    └──────────────────────────────────┘   │
│                                    ↓                        │
│                         Envía jobs a los Runners            │
└────────────────────────────────────┼────────────────────────┘
                                     │
          ┌──────────────────────────┼──────────────────────┐
          ↓                          ↓                       ↓
   ┌──────────────┐         ┌──────────────┐        ┌──────────────┐
   │  Runner 1    │         │  Runner 2    │        │  Runner 3    │
   │  (Docker)    │         │  (Shell)     │        │  (K8s)       │
   │  test job    │         │  lint job    │        │  deploy job  │
   └──────────────┘         └──────────────┘        └──────────────┘
```

### El Flujo Completo

```
1. Developer hace git push origin feature/42-jwt-auth
        ↓
2. GitLab recibe el push y detecta cambio en la rama
        ↓
3. GitLab lee el archivo .gitlab-ci.yml del commit
        ↓
4. GitLab crea un Pipeline con los Jobs definidos
        ↓
5. El GitLab Runner "escucha" y recoge el job
        ↓
6. El Runner descarga el código del commit
        ↓
7. El Runner ejecuta los comandos del job (npm test, etc.)
        ↓
8. El Runner reporta el resultado (passed/failed) al GitLab Server
        ↓
9. GitLab actualiza el estado del pipeline en la UI
        ↓
10. El MR muestra: ✅ Pipeline passed o ❌ Pipeline failed
```

---

## 🏃 GitLab Runner

El GitLab Runner es el agente que ejecuta los jobs del pipeline. Puede correr en:

| Tipo de Executor | Cómo ejecuta | Cuándo usar |
|-----------------|--------------|-------------|
| **Docker** | Cada job en un contenedor limpio | Proyectos que necesitan entornos aislados. Recomendado. |
| **Shell** | Directamente en el OS del servidor | Acceso directo a hardware/GPU, builds nativos |
| **Docker-in-Docker** | Docker dentro de Docker | Para construir y testear imágenes Docker |
| **Kubernetes** | Jobs como pods de K8s | Alta escala, muchos jobs en paralelo |

### GitLab Runner en el Bootcamp

El entorno del bootcamp ya tiene un GitLab Runner configurado con el executor Docker. Verificar:

```bash
# ¿QUÉ HACE?: Lista los runners disponibles en el servidor
# ¿POR QUÉ?: Confirmar que hay al menos un runner activo antes de crear pipelines
# ¿PARA QUÉ?: Sin runner activo, los jobs quedan en estado "pending" indefinidamente
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/runners?type=instance_type&status=online" \
  | python3 -c "
import sys, json
runners = json.load(sys.stdin)
print(f'Runners online: {len(runners)}')
for r in runners:
    print(f'  Runner #{r[\"id\"]}: {r[\"description\"]} [{r[\"executor\"]}]')
"
```

---

## 🖼️ Diagrama: Flujo de CI/CD en GitLab

![Diagrama del flujo CI/CD](../0-assets/01-cicd-flow.svg)

> **Diagrama:** Muestra el ciclo completo: push → GitLab Server → Pipeline Engine → Runners → jobs de test/lint → jobs de deploy → notificación al MR. También ilustra la diferencia entre Delivery (deploy manual a producción) y Deployment (deploy automático).

---

## 🤔 Preguntas de reflexión

1. Un equipo hace deploy a producción una vez por semana manualmente. ¿Qué tipo de CI/CD están haciendo? ¿Qué cambiarías para mejorar su proceso?

2. La diferencia entre "Continuous Delivery" y "Continuous Deployment" es que en uno el deploy a producción es manual y en el otro es automático. ¿En qué tipos de proyectos preferirías Delivery sobre Deployment? ¿Y viceversa?

3. "Pipeline as Code" significa que el pipeline está en el repositorio. ¿Qué pasa si tienes 20 proyectos con pipelines muy similares? ¿Cómo evitarías duplicar la configuración en cada uno?

4. El GitLab Runner descarga el código del commit para cada job. Si tienes 10 jobs en paralelo, el código se descarga 10 veces. ¿Cómo mitigarías esto en un pipeline con muchos jobs?

5. En el flujo CI/CD, los tests automatizados son la "red de seguridad". ¿Qué pasa con los bugs que los tests no detectan? ¿Qué otras capas de verificación podrías agregar al pipeline?

---

## 📚 Recursos adicionales

- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [GitLab Runner](https://docs.gitlab.com/runner/)
- [CI/CD concepts](https://docs.gitlab.com/ee/ci/introduction/)
- [The Twelve-Factor App — Build, Release, Run](https://12factor.net/build-release-run)
- [DORA Metrics — Deployment Frequency](https://cloud.google.com/blog/products/devops-sre/using-the-four-keys-to-measure-your-devops-performance)

---

➡️ **Siguiente lección:** [02 — Estructura del .gitlab-ci.yml](./02-gitlab-ci-yml.md)

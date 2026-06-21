# Instrucciones para GitHub Copilot

## Contexto del Bootcamp

Este es un **Bootcamp de GitLab CE Zero to Hero** estructurado para llevar a estudiantes de cero a heroe en administracion de plataformas DevOps con GitLab Community Edition.

### Datos del Bootcamp

- **Duracion**: 12 semanas (~3 meses)
- **Dedicacion semanal**: 6 horas
- **Total de horas**: ~72 horas
- **Nivel de salida**: Administrador DevOps Junior (GitLab CE)
- **Enfoque**: GitLab CE autogestionado con Docker/Kubernetes
- **Stack**: GitLab CE 17.x+, Docker 27+, GitLab Runner 17.x+, PostgreSQL 16+, Redis 7+

---

## Objetivos de Aprendizaje

Al finalizar el bootcamp, los estudiantes seran capaces de:

- Dominar los fundamentos de Git y control de versiones
- Instalar, configurar y administrar GitLab CE en multiples entornos
- Disenar y gestionar pipelines CI/CD completos con `.gitlab-ci.yml`
- Administrar GitLab Runners (shared, specific, autoscaling)
- Gestionar Container Registry y Package Registry
- Automatizar tareas con GitLab API (REST y GraphQL)
- Implementar politicas de seguridad, RBAC y cumplimiento
- Configurar monitoreo, backup y alta disponibilidad
- Integrar GitLab con herramientas externas (Slack, Jira, Prometheus)
- Desplegar una plataforma DevOps completa lista para produccion

---

## Estructura del Bootcamp

### Distribucion por Etapas

#### **Fundamentos (Semanas 1-3)** - 18 horas

- Fundamentos de Git (commits, ramas, merges, rebase)
- GitLab CE: descripcion general y arquitectura
- Instalacion de GitLab CE (Omnibus, Docker, Kubernetes)
- Proyectos, grupos y organizacion
- Permisos y visibilidad

#### **Intermedio (Semanas 4-7)** - 24 horas

- Issues, Merge Requests y Code Review
- GitLab CI/CD: Fundamentos (`.gitlab-ci.yml`, stages, jobs)
- GitLab CI/CD: Pipelines Avanzados (variables, artifacts, cache, environments)
- GitLab Runner: Instalacion, configuracion, tipos (shared, specific, group)
- GitLab Runner: Autoscaling con Docker Machine / Kubernetes

#### **Avanzado (Semanas 8-11)** - 24 horas

- Container Registry y Package Registry
- GitLab API REST y GraphQL: Automatizacion
- Administracion de GitLab CE (backup, restore, upgrade)
- Seguridad: RBAC, SAST, Secret Detection, politicas
- Monitoreo: Prometheus, Grafana, logs

#### **Produccion (Semana 12)** - 6 horas

- Alta disponibilidad y escalado
- Proyecto final: Plataforma DevOps completa

---

## Estructura de Carpetas

Cada semana sigue esta estructura estandar:

```
bootcamp/week-XX-tema_principal/
├── README.md                 # Descripcion y objetivos de la semana
├── rubrica-evaluacion.md     # Criterios de evaluacion detallados
├── 0-assets/                 # Imagenes, diagramas y recursos visuales
├── 1-teoria/                 # Material teorico (archivos .md)
├── 2-practicas/              # Ejercicios guiados paso a paso
├── 3-proyecto/               # Proyecto semanal integrador
├── 4-recursos/               # Recursos adicionales
│   ├── ebooks-free/          # Libros electronicos gratuitos
│   ├── videografia/          # Videos y tutoriales recomendados
│   └── webgrafia/            # Enlaces y documentacion
└── 5-glosario/               # Terminos clave de la semana (A-Z)
    └── README.md
```

### Carpetas Raiz

- **`assets/`**: Recursos visuales globales (logos, headers, etc.)
- **`docs/`**: Documentacion general que aplica a todo el bootcamp
- **`scripts/`**: Scripts de automatizacion y utilidades
- **`bootcamp/`**: Contenido semanal del bootcamp

---

## Componentes de Cada Semana

### 1. Teoria (1-teoria/)

- Archivos markdown con explicaciones conceptuales
- Ejemplos de configuracion con comentarios claros
- Diagramas de arquitectura y flujo
- Referencias a documentacion oficial de GitLab

### 2. Practicas (2-practicas/)

- Ejercicios guiados paso a paso (tutoriales)
- Laboratorios con Docker Compose
- Configuraciones reales de GitLab CI/CD
- Casos de uso del mundo real

#### Formato de Ejercicios

Los ejercicios son **tutoriales guiados**, NO tareas con TODOs. El estudiante aprende descomentando codigo:

**starter/.gitlab-ci.yml:**
```yaml
# ============================================
# PASO 1: Definir stages basicos
# ============================================
# Descomenta el siguiente bloque:
# stages:
#   - build
#   - test
#   - deploy
```

#### NO usar este formato en ejercicios:
```yaml
# INCORRECTO - Este formato es para PROYECTOS
# TODO: Definir stages
```

### 3. Proyecto (3-proyecto/)

- Proyecto integrador que consolida lo aprendido
- README.md con instrucciones claras
- Configuracion inicial en `starter/`
- Carpeta `solution/` oculta (en `.gitignore`) solo para instructores
- Criterios de evaluacion especificos

El proyecto SI usa TODOs para que el estudiante implemente desde cero.

### 4. Recursos (4-recursos/)

- **ebooks-free/**: Libros gratuitos relevantes
- **videografia/**: Videos tutoriales complementarios
- **webgrafia/**: Enlaces a documentacion y articulos

### 5. Glosario (5-glosario/)

- Terminos tecnicos ordenados alfabeticamente
- Definiciones claras y concisas
- Ejemplos de configuracion cuando aplique

---

## Convenciones

### Configuraciones y Codigo

```yaml
# BIEN - YAML bien estructurado con comentarios educativos
stages:
  - build
  - test
  - deploy

build-job:
  stage: build
  image: docker:27
  script:
    - echo "Compilando la aplicacion..."
  artifacts:
    paths:
      - dist/

# MAL - Sin comentarios ni estructura clara
stages: [build,test,deploy]
```

### Nomenclatura

- **Archivos de configuracion**: kebab-case (`.gitlab-ci.yml`, `docker-compose.yml`)
- **Scripts**: snake_case (`.sh`)
- **Variables CI/CD**: UPPER_SNAKE_CASE (`DOCKER_REGISTRY`, `DEPLOY_TOKEN`)
- **Ramas Git**: kebab-case (`feature/login`, `hotfix/security-patch`)
- **Idioma**: Ingles para codigo/configuraciones, espanol para documentacion

### Estructura de Pipeline GitLab CI/CD

```yaml
stages:
  - validate
  - build
  - test
  - security
  - package
  - deploy
  - release

variables:
  DOCKER_REGISTRY: registry.gitlab.com
  IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA

include:
  - template: Security/SAST.gitlab-ci.yml
  - local: 'ci-templates/docker-build.yml'

cache:
  paths:
    - .cache/
    - node_modules/
```

---

## Testing y Validacion

El bootcamp incluye validacion de:

- **Pipelines CI/CD**: Verificar que los stages se ejecutan correctamente
- **Configuraciones YAML**: Usar `yamllint` y `gitlab-ci-lint`
- **Dockerfiles**: Usar `hadolint` para linting
- **Infraestructura**: Usar `docker compose config` para validar

```yaml
# Pipeline de validacion tipico
validate-pipeline:
  stage: validate
  script:
    - yamllint .gitlab-ci.yml
    - gitlab-ci-local --list
    - hadolint Dockerfile
```

---

## Documentacion

### README.md de Semana

Debe incluir:

1. **Titulo y descripcion**
2. **Objetivos de aprendizaje**
3. **Requisitos previos**
4. **Estructura de la semana**
5. **Contenidos** (con enlaces a teoria/practicas)
6. **Distribucion del tiempo** (6 horas)
7. **Entregables**
8. **Navegacion** (anterior/siguiente semana)

### Archivos de Teoria

```markdown
# Titulo del Tema

## Objetivos

- Objetivo 1
- Objetivo 2

## Contenido

### 1. Introduccion

### 2. Conceptos Clave

### 3. Ejemplos Practicos

### 4. Ejercicios

## Recursos Adicionales

## Checklist de Verificacion
```

---

## Recursos Visuales y Estandares de Diseno

### Formato de Assets

- **Preferir SVG** para todos los diagramas, iconos y graficos
- **NO usar ASCII art** para diagramas o visualizaciones
- Usar PNG/JPG solo para screenshots o fotografias
- Optimizar imagenes antes de incluirlas

### Tema Visual

- **Tema dark** para todos los assets visuales
- **Sin degradados** (gradients) en disenos
- Colores solidos y contrastes claros
- **Paleta GitLab**: naranja `#FC6D26`, morado `#554488`, rojo `#E24329`

### Tipografia

- **Fuentes sans-serif** exclusivamente
- Recomendadas: Inter, Roboto, Open Sans, System UI
- **NO usar fuentes serif** (Times, Georgia, etc.)

---

## Idioma y Nomenclatura

### Codigo y Configuraciones

- **Nomenclatura en ingles** (variables, jobs, stages)
- **Comentarios tecnicos en ingles**
- Usar terminos tecnicos estandar de la industria

### Documentacion

- **Documentacion en espanol** (READMEs, teoria, guias)
- Explicaciones y tutoriales en espanol
- Comentarios educativos en espanol cuando expliquen conceptos

---

## Mejores Practicas

### Infraestructura como Codigo (IaC)

- **Todo cambio mediante archivos de configuracion versionados**
- **Docker Compose** es el UNICO metodo para GitLab CE en este bootcamp
- Helm/Kustomize para Kubernetes solo en semana 11 (HA)
- NO sugerir Omnibus package, NO sugerir instalacion directa en host

### Seguridad

- Nunca hardcodear secretos (usar variables CI/CD)
- Escaneo de seguridad integrado en pipeline (SAST, Secret Detection)
- RBAC con minimo privilegio
- Backup automatico y probado
- HTTPS con Let's Encrypt en produccion
- **Cero telemetria**: `usage_ping_enabled = false`, `sentry_enabled = false`, `snowplow_enabled = false`

### Rendimiento

- Usar cache en pipelines CI/CD
- Optimizar imagenes Docker (multi-stage builds)
- Limpiar artifacts antiguos
- Configurar GitLab con recursos adecuados (minimo 4 GB RAM)

---

## Evaluacion

Cada semana incluye **tres tipos de evidencias**:

1. **Conocimiento** (30%): Evaluaciones teoricas, cuestionarios
2. **Desempeno** (40%): Ejercicios practicos y laboratorios
3. **Producto** (30%): Infraestructura funcional o pipeline operativo

### Criterios de Aprobacion

- Minimo **70%** en cada tipo de evidencia
- Entrega puntual de proyectos
- Infraestructura funcional y bien documentada
- Pipelines ejecutandose correctamente

---

## Metodologia de Aprendizaje

### Estrategias Didacticas

- **Aprendizaje Basado en Proyectos (ABP)**: Proyectos semanales integradores
- **Practica Deliberada**: Ejercicios incrementales
- **DevOps Challenges**: Problemas del mundo real
- **Pair Administration**: Administracion colaborativa
- **Live Configuration**: Sesiones en vivo de configuracion

### Distribucion del Tiempo (6h/semana)

- **Teoria**: 1.5-2 horas
- **Practicas**: 2.5-3 horas
- **Proyecto**: 1.5-2 horas

---

## Instrucciones para Copilot

Cuando trabajes en este proyecto:

### Limites de Respuesta

1. **Divide respuestas largas**
   - **NUNCA generar respuestas que superen los limites de tokens**
   - **SIEMPRE dividir contenido extenso en multiples entregas**

2. **Estrategia de Division**
   - Para semanas completas: dividir por carpetas (teoria -> practicas -> proyecto)
   - Para archivos grandes: dividir por secciones logicas

### Generacion de Configuraciones

1. **Usa siempre YAML bien estructurado**
   - Comentarios explicativos en espanol
   - Separacion clara de secciones
   - Indentacion consistente (2 espacios)

2. **Entorno de Desarrollo — SOLO Docker**
   - **USAR Docker** para todos los entornos practicos. NUNCA sugerir instalacion local.
   - **docker compose** para orquestar GitLab + Runner + Registry + Monitoreo
   - Referenciar `.env.example` y `docker-compose.yml` de la raiz
   - Ejemplo de instruccion correcta:
     ```
     cd bc-gitlab
     cp .env.example .env
     docker compose up -d
     docker compose exec gitlab grep 'Password:' /etc/gitlab/initial_root_password
     ```
   - Ejemplo INCORRECTO (NO hacer):
     ```
     sudo apt install gitlab-ce          # NO usar Omnibus
     gitlab-ctl reconfigure              # NO usar comandos de host
     ```

3. **GitLab CI/CD**
   - Usar executor Docker en todos los pipelines
   - `include` para modularizar pipelines
   - Referenciar templates oficiales de GitLab
   - Documentar variables de entorno requeridas
   - Los jobs siempre deben correr en el Runner Docker del docker-compose.yml

4. **Scripts de Automatizacion**
   - Bash para scripts de administracion
   - Python para GitLab API
   - Documentar precondiciones y dependencias

5. **Documentacion**
   - READMEs en espanol
   - Codigo/configuracion en ingles
   - Ejemplos completos y funcionales

### Referencias Oficiales

- **GitLab Documentation**: https://docs.gitlab.com/
- **GitLab CI/CD**: https://docs.gitlab.com/ee/ci/
- **GitLab API**: https://docs.gitlab.com/ee/api/
- **Docker Documentation**: https://docs.docker.com/
- **GitLab Runner**: https://docs.gitlab.com/runner/

---

## Checklist para Nuevas Semanas

Cuando crees contenido para una nueva semana:

- [ ] Crear estructura de carpetas completa
- [ ] README.md con objetivos y estructura
- [ ] Material teorico en 1-teoria/
- [ ] Ejercicios practicos en 2-practicas/
- [ ] Proyecto integrador en 3-proyecto/
- [ ] Recursos adicionales en 4-recursos/
- [ ] Glosario de terminos en 5-glosario/
- [ ] Rubrica de evaluacion
- [ ] Verificar coherencia con semanas anteriores
- [ ] Revisar progresion de dificultad
- [ ] Probar configuraciones de ejemplo

---

_Ultima actualizacion: Junio 2026_
_Version: 1.0_

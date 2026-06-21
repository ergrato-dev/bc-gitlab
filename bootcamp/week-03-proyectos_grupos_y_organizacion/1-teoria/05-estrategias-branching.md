# 05 — Estrategias de Branching

## Objetivos

- Conocer las principales estrategias de branching
- Evaluar cual se adapta mejor a cada contexto
- Implementar la estrategia elegida con proteccion de ramas

## Estrategias Principales

### Git Flow

Propuesto por Vincent Driessen en 2010. Define un modelo estricto con ramas de larga vida.

**Ramas:**
- `main` (o `master`): Codigo en produccion. Cada commit es un release.
- `develop`: Rama de integracion principal.
- `feature/*`: Nuevas funcionalidades. Se crean desde `develop` y se fusionan de vuelta.
- `release/*`: Preparacion de un release. Se crea desde `develop` y se mergea a `main` y `develop`.
- `hotfix/*`: Correcciones urgentes en produccion. Se crea desde `main` y se mergea a `main` y `develop`.

**Ventajas:**
- Estructura clara y predecible
- Ideal para software con releases versionados
- Bueno para equipos grandes

**Desventajas:**
- Complejidad innecesaria para entrega continua
- Ramas de larga vida acumulan divergencia

### GitHub Flow

Simplificado, usado por GitHub. Ideal para equipos con despliegue continuo.

**Ramas:**
- `main`: Siempre desplegable. Cada merge a main dispara un deploy.
- Ramas descriptivas: `feature/nombre`, `fix/bug-descripcion`, `docs/actualizacion`

**Flujo:**
1. Crear rama desde `main`
2. Hacer commits y push
3. Abrir Pull/Merge Request
4. Discutir y revisar
5. Merge a `main` (automaticamente despliega)

**Ventajas:**
- Simple y facil de entender
- Integracion continua real
- Sin ramas de larga vida

**Desventajas:**
- Requiere excelente cobertura de pruebas
- No maneja bien multiples versiones en produccion

### GitLab Flow

Extiende GitHub Flow agregando ramas de ambiente.

**Ramas:**
- `main`: Desarrollo activo.
- `pre-production` (o `staging`): Ambiente de staging.
- `production`: Ambiente productivo.

**Flujo:**
1. Feature branches → `main` (via MR)
2. `main` → `pre-production` (via MR, despliegue a staging)
3. `pre-production` → `production` (via MR, despliegue a prod)

Tambien soporta **release branches** para versionado:
- `main`: Desarrollo
- `1-0-stable`, `2-0-stable`: Ramas de release LTS

### Trunk-Based Development

Estrategia extrema de CI. Todos trabajan en `main` (o `trunk`) con ramas de vida muy corta (< 24h).

**Caracteristicas:**
- Commits directos a `main` o ramas de < 1 dia
- Feature flags para codigo incompleto
- Excelente suite de pruebas automatizadas
- Despliegue continuo obligatorio

**Ventajas:**
- Integracion maxima
- Cero divergencia de codigo
- Ideal para equipos de alto rendimiento

**Desventajas:**
- Requiere disciplina extrema
- Feature flags complejos
- No apto para equipos junior o software no critico

## Comparacion

| Estrategia | Ramas larga vida | Complejidad | Deploy continuo | Releases versionados |
|-----------|-----------------|-------------|-----------------|---------------------|
| Git Flow | Si (main, develop) | Alta | No | Si |
| GitHub Flow | 1 (main) | Baja | Si | No |
| GitLab Flow | 2-3 (main, staging, prod) | Media | Si | Si (con release branches) |
| Trunk-Based | 1 (main) | Baja config, Alta disciplina | Si | Via feature flags |

## Recomendacion para el Bootcamp

Usaremos **GitHub Flow** como base y migraremos a **GitLab Flow** cuando introduzcamos CI/CD (Semanas 05-08). Es el equilibrio ideal entre simplicidad y practicidad para aprendizaje.

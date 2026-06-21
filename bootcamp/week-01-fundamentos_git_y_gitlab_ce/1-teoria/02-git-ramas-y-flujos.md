# 02 — Git: Ramas, Merges y Conflictos

## Objetivos

- Entender el concepto de ramas y su proposito
- Dominar operaciones con ramas (crear, cambiar, fusionar, eliminar)
- Resolver conflictos de merge
- Conocer flujos de trabajo comunes (Git Flow, GitHub Flow, Trunk-based)

## Ramas en Git

Una rama es un apuntador movil a un commit. Permite desarrollar funcionalidades de forma aislada sin afectar la rama principal. Git crea ramas en milisegundos (solo escribe un archivo de 40 bytes con el hash del commit).

### Por que usar ramas

- **Aislamiento**: Trabajar sin afectar `main`
- **Experimentacion**: Probar ideas sin riesgo
- **Colaboracion**: Cada feature en su rama
- **CI/CD**: Pipelines por rama (staging, production)

## Comandos de Ramas

```bash
# ── Listar ramas ──
git branch                    # Ramas locales (* = actual)
git branch -a                 # Incluye remotas
git branch -v                 # Con ultimo commit

# ── Crear rama ──
git branch feature/login      # Crear (sin cambiar)
git checkout -b feature/login # Crear y cambiar
git switch -c feature/login   # Alternativa moderna (Git 2.23+)

# ── Cambiar de rama ──
git checkout feature/login    # Tradicional
git switch feature/login      # Moderno (mas simple)
git switch -                  # Volver a rama anterior

# ── Fusionar ramas ──
git checkout main
git merge feature/login       # Fusiona feature/login en main

# ── Eliminar rama ──
git branch -d feature/login   # Seguro (solo si ya fue fusionada)
git branch -D feature/login   # Forzado (pierde commits no fusionados)

# ── Renombrar rama ──
git branch -m nombre-nuevo           # Renombrar rama actual
git branch -m viejo-nombre nuevo     # Renombrar otra rama
```

## Merge vs Rebase

### Merge (fusion tradicional)

Crea un **merge commit** que une dos historiales. El historial muestra exactamente cuando y como se fusionaron las ramas.

```bash
git checkout main
git merge feature/login

# Historial resultante:
# *   abc123 (HEAD -> main) Merge branch 'feature/login'
# |\
# | * def456 (feature/login) Agregar validacion de login
# | * ghi789 Preparar endpoint de login
# |/
# * jkl012 Configuracion inicial
```

**Ventaja**: Preserva el historial real, seguro para ramas compartidas.
**Desventaja**: Historial con muchos merge commits puede ser ruidoso.

### Rebase

Reaplica los commits de una rama sobre la punta de otra. El historial queda lineal.

```bash
git checkout feature/login
git rebase main
git checkout main
git merge feature/login  # Fast-forward (no crea merge commit)

# Historial resultante:
# * def456 (HEAD -> main, feature/login) Agregar validacion de login
# * ghi789 Preparar endpoint de login
# * jkl012 Configuracion inicial
```

**Ventaja**: Historial limpio y lineal.
**Desventaja**: Reescribe historial. **NUNCA usar rebase en ramas compartidas/publicadas.**

### Regla de Oro del Rebase

> Si la rama es solo tuya y no la has pusheado: puedes rebasear.
> Si otros trabajan en la rama o ya esta en remoto: usa merge.

## Resolucion de Conflictos

Un conflicto ocurre cuando Git no puede fusionar automaticamente dos cambios al mismo archivo.

### Escenario tipico

```bash
# Dos personas editan la misma linea en ramas diferentes

# Persona A (en feature/a):
echo "Version A" > config.txt
git add . && git commit -m "Config: version A"

# Persona B (en feature/b):
echo "Version B" > config.txt
git add . && git commit -m "Config: version B"
```

### Resolver el conflicto

```bash
git checkout main
git merge feature/a   # OK
git merge feature/b   # CONFLICTO!

# El archivo se marca con marcadores:
# <<<<<<< HEAD
# Version A
# =======
# Version B
# >>>>>>> feature/b
```

**Pasos para resolver:**

1. Editar el archivo eliminando los marcadores `<<<<<<<`, `=======`, `>>>>>>>`
2. Decidir que contenido mantener (o combinar ambos)
3. `git add <archivo>` para marcarlo como resuelto
4. `git commit` para completar el merge

```bash
# Abortar un merge conflictivo si no sabes resolverlo
git merge --abort
```

```bash
# Herramienta visual de merge (recomendada)
git mergetool
```

## Flujos de Trabajo Comunes

### Git Flow (Vincent Driessen, 2010)

Ideal para software con versiones publicas (librerias, productos):

- `main`: Codigo en produccion
- `develop`: Rama de integracion
- `feature/*`: Nuevas funcionalidades (desde develop, vuelve a develop)
- `release/*`: Preparacion de releases (desde develop, vuelve a main + develop)
- `hotfix/*`: Correcciones urgentes (desde main, vuelve a main + develop)

**Ventaja**: Muy estructurado. **Desventaja**: Complejo, lento para CI/CD continuo.

### GitHub Flow (GitHub, 2011)

Ideal para aplicaciones web con despliegue continuo:

- `main`: Siempre desplegable
- Ramas descriptivas: `feature/`, `fix/`, `docs/`
- Pull Requests para revisar antes de merge

**Ventaja**: Simple, rapido. **Desventaja**: Menos control para releases versionados.

### Trunk-based Development

Ideal para equipos maduros con CI/CD rapido:

- Una sola rama principal (`main`/`trunk`)
- Ramas de vida corta (< 1 dia)
- Feature flags para codigo incompleto

## Nombres de Ramas (Buenas Practicas)

```bash
# Prefijos comunes
feature/agregar-login      # Nueva funcionalidad
fix/error-validacion       # Correccion de bug
docs/actualizar-readme     # Documentacion
chore/actualizar-librerias # Tareas de mantenimiento
refactor/extraer-servicio  # Refactorizacion
hotfix/corregir-xss        # Correccion urgente

# Incluir numero de issue (si usas tracker)
feature/42-login-oauth
fix/137-error-timeout
```

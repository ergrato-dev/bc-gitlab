# 04 — Proteccion de Ramas en GitLab

## Objetivos

- Entender el concepto de ramas protegidas
- Configurar reglas de proteccion para ramas criticas
- Implementar protected branches con code owner approval

## Ramas Protegidas

Las ramas protegidas impiden que desarrolladores hagan push directo o eliminen ramas criticas como `main` o `production`. Forzan el uso de Merge Requests para integrar cambios.

### Protecciones Disponibles

**Por rol permitido para merge:**
- Nobody (nadie puede hacer merge - util para congelar rama)
- Developers + Maintainers
- Maintainers only
- Maintainers + Owners

**Por rol permitido para push directo:**
- Nobody (push solo via MR)
- Developers + Maintainers
- Maintainers only
- Maintainers + Owners

## Configurar Proteccion de Ramas

### Via Web UI
1. **Project → Settings → Repository → Protected branches**
2. Expandir **Protected branches**
3. Seleccionar rama del dropdown (ej: `main`)
4. Configurar:
   - **Allowed to merge**: Maintainers
   - **Allowed to push and merge**: Nobody (o Maintainers)
5. Click **Protect**

### Codigo de Ejemplo (reglas comunes)

```
Rama: main
├── Allowed to merge: Maintainers
└── Allowed to push: Nobody  (todo via MR)

Rama: develop
├── Allowed to merge: Developers + Maintainers
└── Allowed to push: Developers + Maintainers

Rama: release/*
├── Allowed to merge: Maintainers
└── Allowed to push: Nobody
```

## Reglas de Proteccion Avanzadas

A partir de GitLab 13.12+:

### Code Owner Approval
Define owners de archivos/directorios que deben aprobar MRs:

```plaintext
# Archivo .gitlab/CODEOWNERS en la raiz del proyecto
*.rb @backend-lead @backend-team
*.js @frontend-lead
*.tf @devops-lead
docs/* @tech-writer
```

### Approval Rules
Configurar reglas de aprobacion por paquete:

```yaml
# Requiere 2 approvals, incluyendo code owners
Settings → Repository → Merge request approvals:
  - Approval required: 2
  - Code owner approval required: Yes
```

### Requerir pipelines exitosos
En **Settings → Merge requests → Pipelines must succeed**:
- El MR no puede mergearse si el pipeline falla

### Requerir que todos los threads esten resueltos
En **Settings → Merge requests → All threads must be resolved**:
- Todos los comentarios de code review deben resolverse antes del merge

## Push Rules (Premium en EE, limitado en CE)

En GitLab CE, las push rules son limitadas. En EE incluyen:
- Rechazar commits sin DCO sign-off
- Prevenir commits con ciertas firmas de autor
- Bloquear nombres de archivo prohibidos
- Restringir tamano maximo de archivo

## Desproteger una Rama

Solo Maintainers y Owners pueden desproteger ramas:

1. **Project → Settings → Repository → Protected branches**
2. En la rama protegida, click **Unprotect**
3. Confirmar la accion

## Buenas Practicas

- Siempre proteger `main` y `production`
- Proteger `develop` en equipos con Git Flow
- Usar wildcards (`release/*`, `hotfix/*`) para patrones de ramas
- Implementar code owners para proyectos con >3 desarrolladores
- Requerir al menos 1 approval antes de merge
- Combinar proteccion de ramas con CI/CD (pipelines must succeed)

# Practica 04 — Proteger Ramas

## Objetivo
Configurar proteccion de ramas en proyectos y verificar que las reglas se aplican correctamente.

## Instrucciones

### 1. Configurar proteccion en main

1. Ve a **Bootcamp-Org / backend / api-gateway**
2. **Settings → Repository → Protected branches**
3. Selecciona rama: `main`
4. Configura:
   - **Allowed to merge**: Maintainers
   - **Allowed to push**: Nobody
5. Click **Protect**

### 2. Verificar proteccion como Developer

Inicia sesion como `developer1`:

```bash
# Clonar el repo
git clone git@localhost:bootcamp-org/backend/api-gateway.git
cd api-gateway

# Intentar push directo a main
echo "cambio directo" >> README.md
git add README.md
git commit -m "intento de push directo"
git push origin main
# Debe ser RECHAZADO: "You are not allowed to push code to protected branches"
```

### 3. Flujo correcto con MR

Como `developer1`:

```bash
# Crear rama feature
git checkout -b feature/test-protection

# Hacer cambios
echo "cambio via MR" >> README.md
git add README.md
git commit -m "feat: cambio via merge request"

# Push a la rama (no protegida)
git push origin feature/test-protection
```

En la UI, veras un banner para crear Merge Request. Crealo.

### 4. Merge como Maintainer

Inicia sesion como `maintainer1`:
1. Ve al MR creado por `developer1`
2. Revisa los cambios
3. Click **Merge**
4. Verifica que `main` ahora tiene los cambios

### 5. Configurar reglas adicionales

En el proyecto `api-gateway`:

1. **Settings → Repository → Protected branches**
2. Agrega proteccion para `develop`:
   - **Allowed to merge**: Developers + Maintainers
   - **Allowed to push**: Developers + Maintainers

3. **Settings → Merge requests → Merge checks**:
   - Marcar **Pipelines must succeed** (aunque no tengas CI/CD aun)
   - Marcar **All threads must be resolved**

### 6. Proteger multiples ramas con wildcard

Protege todas las ramas que empiecen con `release/`:

1. **Settings → Repository → Protected branches**
2. Selecciona **Wildcard**: `release/*`
3. **Allowed to merge**: Maintainers
4. **Allowed to push**: Nobody
5. Click **Protect**

Verifica creando una rama `release/1.0.0`:

```bash
git checkout -b release/1.0.0
echo "v1.0.0" > VERSION
git add VERSION
git commit -m "chore: version 1.0.0"
git push origin release/1.0.0  # Debe ser rechazado
```

## Entregable
- Captura de **Protected branches** mostrando `main`, `develop` y `release/*`
- Mensaje de error al intentar push directo a `main`
- URL del Merge Request creado y mergeado exitosamente

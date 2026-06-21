# Practica 03 — Configuracion Post-Instalacion

## Objetivo
Configurar GitLab CE despues del primer inicio: cambiar contrasena, personalizar apariencia y configurar ajustes basicos.

## Instrucciones

### 1. Iniciar sesion como root

- URL: `http://localhost`
- Usuario: `root`
- Contrasena: La obtenida en la practica anterior

### 2. Cambiar contrasena de root

1. Click en tu avatar (esquina superior derecha) → **Preferences**
2. Sidebar izquierdo → **Password**
3. Ingresa la contrasena actual y la nueva (ej: `Bootcamp2024!`)
4. Guarda los cambios

### 3. Configurar apariencia de la instancia

1. Ve a **Admin Area** (icono de llave abajo en el sidebar)
2. **Settings → Appearance**
3. Configura:
   - **Title**: `Bootcamp DevOps - GitLab CE`
   - **Description**: `Instancia de practica del bootcamp`
   - **Sign-in page description**: `Bienvenido al Bootcamp de GitLab CE`

### 4. Configurar visibilidad por defecto

1. **Admin Area → Settings → General**
2. **Visibility and access controls**
3. **Default project visibility**: Private
4. Guarda los cambios

### 5. Registro de usuarios

1. **Admin Area → Settings → General**
2. **Sign-up enabled**: Desmarcar (solo el admin crea usuarios)
3. Guarda los cambios

### 6. Verificar servicios internos

```bash
docker compose exec gitlab gitlab-ctl status
```

Todos los servicios deben mostrar `run: ... (pid X) Xs`.

## Entregable
- Captura de la pagina de Preferences mostrando el cambio de password exitoso
- Captura de **Admin Area → Settings → Appearance** con tu configuracion
- Salida de `docker compose exec gitlab gitlab-ctl status`

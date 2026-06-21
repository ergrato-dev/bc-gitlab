# Práctica 02 — MFA y Restricciones de Seguridad

## Objetivo

Configurar autenticación de dos factores (MFA) y restricciones de seguridad a nivel de instancia.

## Requisitos

- Acceso de administrador a GitLab CE
- Aplicación TOTP (Google Authenticator, Authy, Bitwarden, etc.)
- Al menos 2 usuarios de prueba

## Instrucciones

### Paso 1: Habilitar MFA para un usuario
1. Inicia sesión como usuario normal (no admin)
2. Ve a Settings → Account → Two-Factor Authentication
3. Escanea el código QR con tu app TOTP
4. Ingresa el código generado para confirmar
5. Guarda los códigos de recuperación (backup codes) en lugar seguro

### Paso 2: Forzar MFA desde Admin Area
1. Inicia sesión como administrador
2. Ve a Admin Area → Settings → General → Sign-up restrictions
3. Marca "Enforce two-factor authentication"
4. Configura un grace period de 2 horas
5. Guarda los cambios

### Paso 3: Configurar IP Restrictions
1. En Admin Area → Settings → Network → IP restrictions
2. Agrega tu rango IP actual (usa `ip a` o `ifconfig` para verificarlo)
3. Guarda e intenta acceder desde otra IP (o simula con un proxy/VPN)

### Paso 4: Crear un usuario sin MFA
1. Crea un nuevo usuario de prueba
2. Observa qué sucede al intentar iniciar sesión después del grace period
3. ¿El usuario es bloqueado completamente? ¿Puede el admin desbloquearlo?

### Paso 5: Revisar Audit Events
1. Admin Area → Monitoring → Audit Events
2. Filtra por tipo de evento: "Added member", "Changed authentication"
3. Identifica los eventos generados durante esta práctica

## Preguntas de reflexión
- ¿Qué sucede si un usuario pierde su dispositivo MFA y sus backup codes?
- ¿Es suficiente MFA para proteger una instancia GitLab? ¿Qué más agregarías?
- ¿Cómo afecta la IP restriction a usuarios en trabajo remoto?

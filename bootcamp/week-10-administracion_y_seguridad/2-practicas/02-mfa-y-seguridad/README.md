# Práctica 02 — MFA, Tokens y Auditoría de Seguridad

## Objetivo

Configurar autenticación de dos factores (MFA) obligatoria, políticas de Personal Access Tokens, restricciones IP, y realizar una auditoría de seguridad via API.

## Requisitos

- Acceso de administrador a GitLab CE local
- App TOTP instalada (Google Authenticator, Authy, Bitwarden, o cualquier compatible RFC 6238)
- Al menos 2 usuarios de prueba (pueden ser los de la práctica anterior)
- `jq` instalado en tu terminal

---

## Instrucciones

### Paso 1: Configurar MFA personal

**Como usuario normal** (no admin), activa MFA en tu cuenta:

1. Login como usuario normal
2. Ir a **Settings → Account → Two-Factor Authentication**
3. Hacer clic en **"Enable two-factor authentication"**
4. La pantalla muestra un código QR — escanearlo con la app TOTP
5. Ingresar el código de 6 dígitos que muestra la app para confirmar
6. Guardar los **10 backup codes** en un lugar seguro (gestor de contraseñas)

> Los backup codes son de un solo uso. Si pierdes el dispositivo y no los tienes, el admin deberá desactivar tu MFA manualmente.

Verificación:
```bash
# Después de configurar MFA, hacer logout y login de nuevo
# → El sistema debe pedir el código TOTP como segundo factor

# Via API: verificar que el usuario tiene MFA habilitado
curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/users?username=tu-usuario" | \
  jq '.[0].two_factor_enabled'
# Expected: true
```

### Paso 2: Forzar MFA para toda la instancia

**Como administrador**:

```
Admin Area → Settings → General → Sign-up restrictions
```

Configurar:
- **Enforce two-factor authentication**: ✅ activado
- **Two-factor grace period**: 48 horas

Guardar cambios.

```bash
# Via API: configurar MFA obligatorio
curl -s --request PUT \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "require_two_factor_authentication": true,
    "two_factor_grace_period": 48
  }' \
  "http://localhost/api/v4/application/settings" | \
  jq '{require_two_factor_authentication, two_factor_grace_period}'
```

### Paso 3: Observar el grace period en acción

```bash
# 1. Crear un usuario nuevo sin MFA
NEW_USER_ID=$(curl -s --request POST \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "Test NoMFA",
    "username": "test-nomfa",
    "email": "nomfa@test.local",
    "password": "SecurePass123!",
    "skip_confirmation": true
  }' \
  "http://localhost/api/v4/users" | jq '.id')
echo "Usuario sin MFA creado: $NEW_USER_ID"

# 2. Crear un PAT para ese usuario con fecha en el pasado para forzar el grace period
# (el admin puede manipular el grace period para testing)
# En la práctica, el grace period se evalúa desde que se activa el enforcement
```

Ahora intenta hacer login con ese usuario en la UI:
- Durante el grace period: login funciona pero muestra banner de advertencia
- Después del grace period: login redirige obligatoriamente a configurar MFA

Para forzar la expiración del grace period sin esperar (testing):
```bash
# Desactivar temporalmente el grace period (0 horas = inmediato)
curl -s --request PUT \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --data "two_factor_grace_period=0" \
  "http://localhost/api/v4/application/settings" | \
  jq '.two_factor_grace_period'
# → Ahora test-nomfa es bloqueado al intentar hacer login (redirigido a setup MFA)
```

### Paso 4: Desbloquear MFA perdida (simulación de incidente)

Escenario: el usuario `test-nomfa` "perdió" su dispositivo MFA y sus backup codes.

```bash
# Procedimiento de admin para recuperar acceso:

# 1. Verificar identidad del usuario (en producción: videollamada, ID, etc.)
echo "Verificando identidad de test-nomfa... (simulado)"

# 2. Desactivar MFA temporalmente
curl -s --request PATCH \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --data "two_factor_enabled=false" \
  "http://localhost/api/v4/users/$NEW_USER_ID" | \
  jq '{id, username, two_factor_enabled}'

# 3. Notificar al usuario que tiene 24h para reconfigurar MFA
echo "MFA desactivado para test-nomfa. Debe reconfigurar en menos de 24h"

# 4. Verificar que el usuario puede hacer login de nuevo
curl -s --request GET \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/users/$NEW_USER_ID" | \
  jq '{username, two_factor_enabled}'
# Expected: two_factor_enabled: false
```

### Paso 5: Gestión de Personal Access Tokens

```bash
# 5.1 Configurar expiración máxima de tokens
curl -s --request PUT \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --data "max_personal_access_token_lifetime=90" \
  "http://localhost/api/v4/application/settings" | \
  jq '.max_personal_access_token_lifetime'
# → 90 días máximo

# 5.2 Crear un PAT con scopes mínimos para testing
MINIMUM_PAT=$(curl -s --request POST \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --data "name=test-minimal-token&scopes[]=read_repository&expires_at=$(date -d '+30 days' +%Y-%m-%d)&user_id=$NEW_USER_ID" \
  "http://localhost/api/v4/users/$NEW_USER_ID/personal_access_tokens" | \
  jq '{name, scopes, expires_at, token}')
echo "PAT mínimo creado: $MINIMUM_PAT"

# 5.3 Intentar crear un PAT con expiración > 90 días (debe fallar)
curl -s --request POST \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --data "name=long-token&scopes[]=api&expires_at=$(date -d '+365 days' +%Y-%m-%d)&user_id=$NEW_USER_ID" \
  "http://localhost/api/v4/users/$NEW_USER_ID/personal_access_tokens" | \
  jq '.message'
# Expected: "Personal access token expiry cannot exceed 90 days" (o similar)

# 5.4 Listar todos los PATs activos del usuario
curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/personal_access_tokens?user_id=$NEW_USER_ID&state=active" | \
  jq '.[] | {name, scopes, expires_at, last_used_at}'
```

### Paso 6: Configurar y probar restricciones IP

```bash
# 6.1 Obtener tu IP actual
MY_IP=$(curl -s http://checkip.amazonaws.com/ 2>/dev/null || ip route get 1 | awk '{print $NF;exit}')
echo "Tu IP actual: $MY_IP"

# 6.2 Activar restricción de IP (whitelist con tu IP)
curl -s --request PUT \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{\"ip_restriction_ranges\": \"$MY_IP/32\"}" \
  "http://localhost/api/v4/application/settings" | \
  jq '.ip_restriction_ranges'
```

> **Precaución**: si configuras una IP incorrecta, puedes quedar bloqueado. En una VM local, la restricción IP aplica a la UI web pero NO a acceso directo al servidor.

```bash
# 6.3 Verificar que el acceso desde tu IP sigue funcionando
curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/version"
# Expected: {"version":"...","revision":"..."}

# 6.4 Simular acceso desde IP no autorizada
# (desde otra máquina, o usando un proxy, o cambiando la restricción a una IP falsa)
curl -s --request PUT \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --data "ip_restriction_ranges=192.0.2.1/32" \  # IP falsa — te bloquea a ti también
  "http://localhost/api/v4/application/settings"

# Intenta acceder ahora: ¿recibes 404 o error de conexión?
curl -v "http://localhost/api/v4/version"

# 6.5 IMPORTANTE: Restaurar para no quedar bloqueado
# Si te bloqueaste, accede al servidor directamente:
# sudo gitlab-rails runner "ApplicationSetting.current.update(ip_restriction_ranges: '')"

# Si aún tienes acceso admin desde el servidor:
curl -s --request PUT \
  --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  --data "ip_restriction_ranges=" \
  "http://localhost/api/v4/application/settings"
echo "Restricción IP eliminada"
```

### Paso 7: Explorar y exportar Audit Events

```bash
# 7.1 Ver los últimos 20 audit events via UI
# → Admin Area → Monitoring → Audit Events

# 7.2 Via API: obtener los audit events de la última hora
SINCE=$(date -d "1 hour ago" +%Y-%m-%dT%H:%M:%SZ)

curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/audit_events?created_after=$SINCE" | \
  jq '.[] | {
    time: .created_at,
    who: .author_name,
    entity: .entity_type,
    action: .details.action,
    ip: .details.ip_address
  }'
```

```bash
# 7.3 Buscar eventos específicos: todos los logins de hoy
TODAY=$(date +%Y-%m-%dT00:00:00Z)

curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/audit_events?created_after=$TODAY&per_page=100" | \
  jq '[.[] | select(.details.action == "failed_login" or .details.action == "successful_login")] | 
      group_by(.details.action) | 
      map({action: .[0].details.action, count: length})'
```

```bash
# 7.4 Generar reporte de auditoría en markdown
REPORT_FILE="/tmp/security-audit-$(date +%Y-%m-%d).md"

cat > "$REPORT_FILE" << 'HEADER'
# Reporte de Auditoría de Seguridad
HEADER

echo "**Fecha**: $(date)" >> "$REPORT_FILE"
echo "**GitLab URL**: http://localhost" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "## 1. Estado de MFA" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "### Usuarios SIN MFA habilitado:" >> "$REPORT_FILE"
curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/users?two_factor=disabled&per_page=100" | \
  jq -r '.[] | "- \(.username) (\(.email))"' >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"
echo "## 2. PATs sin fecha de expiración" >> "$REPORT_FILE"
curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/personal_access_tokens?state=active&per_page=100" | \
  jq -r '.[] | select(.expires_at == null) | "- \(.name) (user_id: \(.user_id))"' >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"
echo "## 3. Últimos 10 eventos de auditoría" >> "$REPORT_FILE"
curl -s --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "http://localhost/api/v4/audit_events?per_page=10" | \
  jq -r '.[] | "- [\(.created_at)] \(.author_name): \(.details.action // .details.custom_message)"' >> "$REPORT_FILE"

cat "$REPORT_FILE"
echo ""
echo "Reporte guardado en: $REPORT_FILE"
```

---

## Preguntas de reflexión

1. ¿Qué sucede si un usuario pierde su dispositivo MFA Y sus backup codes? ¿Qué información verificarías antes de desactivar su MFA como admin?

2. El CEO de la empresa argumenta que MFA "es muy molesto" y pide una excepción. ¿Cómo argumentarías que no debe haber excepciones al MFA obligatorio?

3. ¿Qué diferencia hay en términos de seguridad entre un PAT con scope `api` vs uno con `read_repository` + `read_registry`?

4. Las restricciones IP bloquean el acceso a empleados en trabajo remoto. ¿Cómo diseñarías una solución que mantenga la seguridad pero permita trabajo remoto?

5. Mirando los audit events generados durante esta práctica, ¿qué eventos consideras más críticos de monitorear en tiempo real? ¿Por qué?

---

## Entregables

- [ ] MFA configurado en tu usuario personal y verificado vía API
- [ ] MFA obligatorio configurado con grace period de 48h en la instancia
- [ ] Procedimiento de recuperación de MFA ejecutado y documentado
- [ ] Expiración máxima de PAT configurada en 90 días
- [ ] Intento de crear PAT con expiración > 90 días documentado (error esperado)
- [ ] Restricciones IP probadas (activar, verificar bloqueo, restaurar)
- [ ] Reporte de auditoría generado en markdown y guardado

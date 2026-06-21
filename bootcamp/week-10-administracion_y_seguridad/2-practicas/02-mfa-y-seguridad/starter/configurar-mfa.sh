#!/usr/bin/env bash
# ============================================
# Practica 02 — MFA y Seguridad de Cuenta
# ============================================

echo "=== Practica 02: MFA y Seguridad ==="
echo ""

# ── PASO 1: Habilitar MFA ──
echo "--- Paso 1: Habilitar MFA para usuario root ---"
echo "1. Settings → Account → Two-Factor Authentication"
echo "2. Escanear QR con Google Authenticator / Authy"
echo "3. Ingresar codigo TOTP para confirmar"
echo "4. GUARDAR los recovery codes en lugar seguro"
echo "5. Cerrar sesion y verificar que pide 2FA"
echo ""

# ── PASO 2: Enforcement ──
echo "--- Paso 2: Forzar MFA desde Admin Area ---"
echo "1. Admin Area → Settings → General → Sign-up restrictions"
echo "2. Marcar 'Enforce two-factor authentication'"
echo "3. Grace period: 2 horas"
echo "4. Save changes"
echo ""

# ── PASO 3: IP Restrictions ──
echo "--- Paso 3: Verificar IP actual y configurar whitelist ---"
# echo "Tu IP actual:"
# curl -s ifconfig.me
echo ""
echo "1. Admin Area → Settings → Network → IP restrictions"
echo "2. Agregar: TU_RANGO_IP (ej: 192.168.1.0/24)"
echo "3. Save"
echo ""

# ── PASO 4: Audit Events ──
echo "--- Paso 4: Revisar Audit Events ---"
echo "Admin Area → Monitoring → Audit Events"
echo "Filtrar eventos de tipo:"
echo "  - Changed authentication"
echo "  - Added member"
echo ""
echo "O via API:"
# curl -s --header "PRIVATE-TOKEN: $TOKEN" \
#   "http://localhost/api/v4/audit_events?entity_type=User&per_page=10"
echo ""

echo "=== Practica 02 completada ==="

#!/usr/bin/env bash
# ============================================
# Practica 03: Code Review Practico
# ============================================

echo "=== Practica 03: Code Review ==="
echo ""

# ── PASO 1: Crear MR con errores intencionales ──
echo "--- Paso 1 (Autor): Crear codigo con problemas ---"
# cat > src/userController.js << 'ENDCODE'
# const db = require('../db');
# const ADMIN_PASSWORD = 'admin123';  // ❌ hardcoded
# async function getUsers(req, res) {
#   try {
#     const users = await db.query('SELECT * FROM users');
#     res.json(users);
#   } catch (err) {
#     console.log(err);               // ❌ console.log en prod
#     res.status(500).send('Error');
#   }
# }
# async function getUser(req, res) {
#   const id = req.params.id;
#   const user = await db.query('SELECT * FROM users WHERE id = ' + id); // ❌ SQLi
#   if (user.length == 0) {           // ❌ == en vez de ===
#     res.status(404).send('Not found');
#   } else { res.json(user[0]); }
# }
# ENDCODE
# git add . && git commit -m "feat: agregar controlador de usuarios" && git push
# Crear MR en UI, asignar reviewer
echo ""

# ── PASO 2: Revisar como Reviewer ──
echo "--- Paso 2 (Reviewer): Encontrar problemas ---"
echo "Busca en el diff:"
echo "  1. ❌ console.log(err) → usar logger estructurado"
echo "  2. ❌ SQL injection en getUser (concatenacion)"
echo "  3. ❌ ADMIN_PASSWORD hardcodeada"
echo "  4. ❌ == en vez de ==="
echo "  5. ❌ Error generico sin detalles"
echo ""

# ── PASO 3: Comentarios constructivos ──
echo "--- Paso 3: Modelos de comentarios ---"
cat << 'COMMENTS'
Comentario BIEN (constructivo):
  "Sugiero reemplazar console.log con un logger estructurado
   (winston/pino) o console.error. Facilita monitoreo en prod."

Comentario BIEN (con sugerencia):
  ```suggestion
  const user = await db.query('SELECT * FROM users WHERE id = $1', [id]);
  ```

Comentario MAL (evitar):
  "Esto esta mal, arreglalo."
COMMENTS
echo ""

# ── PASO 4: Suggested Change ──
echo "--- Paso 4: Usar Suggested Changes ---"
echo "En linea del SQL injection, usa el boton 'Insert suggestion':"
echo '```suggestion'
echo 'const user = await db.query("SELECT * FROM users WHERE id = $1", [id]);'
echo '```'
echo "El autor podra aceptar con 1 click."
echo ""

# ── PASO 5: Review Summary ──
echo "--- Paso 5: Enviar Review Summary ---"
echo "Despues de revisar todos los archivos:"
echo "  1. Click 'Finish review'"
echo "  2. Seleccionar 'Request changes'"
echo "  3. Escribir resumen amable y especifico"
echo ""
echo "Ejemplo: 'Buen trabajo con la estructura. Solicito:"
echo "  1. Corregir SQL injection (critico)"
echo "  2. Remover credenciales hardcodeadas"
echo "  3. Mejorar logging. El resto se ve bien!'"
echo ""

# ── PASO 6: Corregir y re-revisar ──
echo "--- Paso 6: Ciclo Author → Fix → Reviewer → Approve → Merge"
echo "1. Author corrige y pushea fixes"
echo "2. Reviewer re-revisa, resuelve threads"
echo "3. Reviewer aprueba (Approve)"
echo "4. Maintainer mergea"
echo ""

echo "=== Practica 03 completada ==="

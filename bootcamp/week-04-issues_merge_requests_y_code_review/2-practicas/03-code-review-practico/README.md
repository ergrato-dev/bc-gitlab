# Practica 03 — Code Review Practico

## Objetivo
Realizar code review constructivo en GitLab usando comentarios en linea, sugerencias y approvals.

## Instrucciones

### 1. Preparar: Autor crea MR con errores intencionales

Como `developer1`, en el proyecto `api-gateway`:

```bash
git checkout main
git pull origin main
git checkout -b 4-user-controller

# Crear archivo con algunos problemas de codigo
mkdir -p src/controllers

cat > src/controllers/userController.js << 'ENDCODE'
const db = require('../db');

// Get all users
async function getUsers(req, res) {
  try {
    const users = await db.query('SELECT * FROM users');
    res.json(users);
  } catch (err) {
    console.log(err);
    res.status(500).send('Error');
  }
}

// Get user by id - TODO: add validation
async function getUser(req, res) {
  const id = req.params.id;
  const user = await db.query('SELECT * FROM users WHERE id = ' + id);
  
  if (user.length == 0) {
    res.status(404).send('Not found');
  } else {
    res.json(user[0]);
  }
}

// Password in code is bad practice
const ADMIN_PASSWORD = 'admin123';

module.exports = { getUsers, getUser, ADMIN_PASSWORD };
ENDCODE

git add src/
git commit -m "feat: agregar controlador de usuarios"
git push origin 4-user-controller
```

Crea MR y asigna como reviewer a otro usuario (o usa otro usuario para revisar).

### 2. Revisar codigo como Reviewer

Inicia sesion como el reviewer. En el MR:

**Pestana Changes** — Revisa el codigo y encuentra:

1. **console.log(err)** en produccion (linea ~9)
2. **SQL Injection** en getUser (linea ~17): `'SELECT * FROM users WHERE id = ' + id`
3. **Hardcoded password** (linea ~24)
4. **Error generico** sin detalles (linea ~11)
5. **Uso de `==` en lugar de `===`** (linea ~19)

### 3. Agregar comentarios en linea

Para cada problema, agrega un comentario constructivo:

**Comentario 1 — console.log:**
```
Sugiero reemplazar `console.log` con un logger estructurado (ej: winston, pino) 
o al menos `console.error` para que los logs de error vayan a stderr.
Esto facilita el monitoreo en produccion.
```

**Comentario 2 — SQL Injection:**
```
**Seguridad**: Esta consulta es vulnerable a SQL injection. Usa parametros 
preparados (parameterized queries):

```suggestion
const user = await db.query('SELECT * FROM users WHERE id = $1', [id]);
```

Esto previene que un atacante inyecte SQL malicioso via el parametro `id`.
```

**Comentario 3 — Hardcoded password:**
```
Nunca hardcodees credenciales en el codigo fuente. Usa variables de entorno:

```javascript
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD;
```

Y configura la variable en GitLab CI/CD Settings o en tu archivo .env (no commiteado).
```

### 4. Usar "Start a Review"

1. En cada comentario, click en **Start a review** (no Comment individual)
2. Al agregar todos los comentarios, click en **Finish review**
3. Selecciona **Request changes**
4. Escribe un resumen general:
   ```
   Buen trabajo con la estructura general. Solicitos estos cambios:
   
   1. Seguridad critica: SQL injection en getUser
   2. Remover credenciales hardcodeadas
   3. Mejorar manejo de errores y logging
   
   El resto se ve bien! La estructura de carpetas es clara.
   ```

### 5. Autor corrige los cambios

Como `developer1`:

```bash
# Corregir los problemas
# Editar src/controllers/userController.js segun feedback

git add src/
git commit -m "fix: corregir SQL injection, remover hardcoded password, mejorar logging (#4)"
git push origin 4-user-controller
```

### 6. Re-revision y Approval

1. Como reviewer, verifica que los cambios se hicieron
2. Resuelve los threads de comentarios
3. **Approve** el MR

### 7. Merge

Como maintainer, mergea el MR.

## Entregable
- Captura de un MR con comentarios en linea (al menos 3)
- Captura del "Finish review" con Request Changes
- Captura del MR aprobado despues de correcciones
- Reflexion breve: Que aprendiste del proceso de code review?

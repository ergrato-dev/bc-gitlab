# Practica 02 — Crear Merge Requests

## Objetivo
Crear Merge Requests con templates, vincularlos a issues y experimentar con diferentes metodos de merge.

## Instrucciones

### 1. Crear template de MR

Crea el archivo `.gitlab/merge_request_templates/Default.md` en tu proyecto:

```bash
cd ~/ruta/a/tu/proyecto
mkdir -p .gitlab/merge_request_templates

cat > .gitlab/merge_request_templates/Default.md << 'EOF'
## Descripcion
[Describe los cambios]

## Issue Relacionado
Closes #

## Tipo de Cambio
- [ ] Bug fix
- [ ] Feature
- [ ] Refactor
- [ ] Documentation

## Checklist
- [ ] Codigo probado localmente
- [ ] Pipeline verde
- [ ] No hay codigo comentado

/assign @me
EOF

git add .gitlab/
git commit -m "chore: agregar template de MR"
git push origin main
```

### 2. Crear rama para feature

```bash
# Desde main
git checkout main
git pull origin main

# Crear rama con numero de issue
git checkout -b 2-jwt-authentication
```

### 3. Hacer cambios y push

```bash
# Crear archivo de ejemplo
mkdir -p src/auth
cat > src/auth/jwt.js << 'EOF'
const jwt = require('jsonwebtoken');

function generateToken(user) {
  return jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, {
    expiresIn: '24h'
  });
}

function verifyToken(token) {
  return jwt.verify(token, process.env.JWT_SECRET);
}

module.exports = { generateToken, verifyToken };
EOF

# Commit y push
git add src/auth/
git commit -m "feat: implementar generacion y verificacion de JWT (#2)"
echo "console.log('hello');" >> src/auth/jwt.js
git add src/auth/
git commit -m "fix: remover console.log de jwt.js (#2)"

git push origin 2-jwt-authentication
```

### 4. Crear MR con template

1. Ve al proyecto en GitLab
2. Veras un banner: "Create merge request for 2-jwt-authentication"
3. Click en **Create merge request**
4. En el dropdown **Choose a template**, selecciona **Default**
5. Completa:
   - Titulo: `Draft: Implementar autenticacion JWT`
   - Description: Completar con los cambios realizados
   - En "Issue Relacionado": `Closes #2`
6. Asigna un reviewer (si tienes otro usuario)
7. Click **Create merge request**

### 5. Probar diferentes metodos de merge

**No merges aun** — primero explora las opciones en la UI:

En la pagina del MR, observa el widget de merge. Nota las opciones disponibles:
- Merge commit
- Squash and merge

### 6. Resolver comentarios y mergear

1. Agrega un comentario de prueba en el MR
2. Resuelvelo
3. Quita `Draft:` del titulo
4. Click **Merge** (usa Squash and Merge)
5. Verifica que:
   - El issue #2 se cerro automaticamente
   - La rama fuente se elimino
   - main tiene el historial limpio (un solo commit del squash)

### 7. Crear segundo MR

Repite el proceso para el issue #3 (documentacion):

```bash
git checkout -b 3-api-docs
echo "## API Endpoints" >> README.md
git add README.md
git commit -m "docs: documentar endpoints de la API (#3)"
git push origin 3-api-docs
```

Crea MR, usa template, y mergea.

## Entregable
- URL de 2 Merge Requests creados
- Captura del MR mostrando template, labels y vinculacion a issue
- Captura del issue cerrado automaticamente tras merge
- Salida de `git log --oneline` en main mostrando commits squash

# 🛠️ Práctica 04 — Explorar GitLab CE: Proyecto Completo

⏱️ **Tiempo estimado**: 30 minutos
⭐ **Dificultad**: Básico
📋 **Prerrequisitos**: GitLab CE corriendo, acceso como administrador (`root`)

---

## 🎯 Objetivo

Configurar un proyecto GitLab CE con todas las opciones relevantes: visibilidad, descripción, .gitignore desde template, labels, un milestone y la Wiki habilitada. El objetivo es conocer la interfaz de administración de un proyecto antes de construir el portafolio.

---

## 📚 Teoría Relacionada

- [03 — GitLab CE: Overview](../../1-teoria/03-gitlab-ce-overview.md) (sección: Tour de la Interfaz Web)
- [05 — Primeros Pasos en GitLab CE](../../1-teoria/05-primeros-pasos-gitlab.md)

---

## 📋 Instrucciones

### Paso 1: Crear el Proyecto desde la UI

En `http://localhost`:

1. Click **`+`** (top bar) → **New project/repository**
2. Seleccionar **Create blank project**
3. Completar el formulario:
   - **Project name**: `explorar-gitlab-ce`
   - **Project slug**: `explorar-gitlab-ce` (se auto-completa)
   - **Project description**: `Proyecto de práctica para explorar la interfaz de GitLab CE`
   - **Visibility Level**: `Internal` (visible para todos los usuarios de la instancia)
   - ✅ **Initialize repository with a README**
4. Click **Create project**

---

### Paso 2: Explorar y Editar el README desde la UI

1. En el proyecto, click en `README.md`
2. Click en el **ícono de lápiz** (Edit this file)
3. Reemplaza el contenido con:

```markdown
# Explorar GitLab CE

Proyecto de práctica para el Bootcamp GitLab CE Zero to Hero.

## Propósito

Explorar y entender las funcionalidades de la interfaz web de GitLab CE:

- Configuración del proyecto
- Labels y milestones
- Wiki
- Issues
- Merge Requests

## Tecnologías

- GitLab CE 17.x (Docker)
- Git + SSH
- Markdown
```

4. En **Commit changes**:
   - Message: `docs: escribir README inicial del proyecto`
   - Branch: `main`
5. Click **Commit changes**

---

### Paso 3: Agregar .gitignore desde Template

GitLab puede generar un `.gitignore` automáticamente:

1. En el repositorio, click **`+`** → **New file**
2. En el nombre del archivo escribir: `.gitignore`
3. Click en el dropdown **Select a template** → seleccionar **gitignore**
4. En el filtro buscar: `Bash` o `Linux` (para un proyecto de shell scripts)
5. El contenido del template se cargará automáticamente
6. Commit:
   - Message: `chore: agregar .gitignore para proyecto de scripts bash`
   - Branch: `main`
7. Click **Commit changes**

---

### Paso 4: Crear Labels

Las labels son etiquetas para categorizar issues y MRs. GitLab tiene labels predefinidas que puedes generar:

1. Sidebar del proyecto → **Manage** → **Labels**
2. Click **Generate a default set of labels** (si aparece la opción)
   — Esto crea labels como `bug`, `feature`, `documentation`, `enhancement`, etc.

Si no aparece el botón de generar, crea las siguientes manualmente:
- **Name**: `feature`, **Color**: `#0075ca`
- **Name**: `bug`, **Color**: `#ee0701`
- **Name**: `documentation`, **Color**: `#0075ca`
- **Name**: `semana-01`, **Color**: `#e4e669`

---

### Paso 5: Crear un Milestone

Los milestones agrupan issues y MRs con un objetivo y fecha:

1. Sidebar del proyecto → **Plan** → **Milestones**
2. Click **New milestone**
3. Completar:
   - **Title**: `Semana 01 — Fundamentos`
   - **Description**: `Completar todas las prácticas y el proyecto de la semana 01`
   - **Start date**: Fecha de hoy
   - **Due date**: 7 días desde hoy
4. Click **Create milestone**

---

### Paso 6: Crear un Issue de Ejemplo

1. Sidebar → **Plan** → **Issues**
2. Click **New issue**
3. Completar:
   - **Title**: `Explorar la interfaz de GitLab CE`
   - **Description**: 
     ```
     ## Tareas
     - [x] Crear el proyecto
     - [x] Configurar README
     - [x] Agregar .gitignore
     - [ ] Crear labels
     - [ ] Crear milestone
     - [ ] Explorar la Wiki
     ```
   - **Assignee**: Asignarte a ti mismo
   - **Labels**: `documentation`, `semana-01`
   - **Milestone**: `Semana 01 — Fundamentos`
4. Click **Create issue**

---

### Paso 7: Habilitar y Explorar la Wiki

1. Sidebar del proyecto → **Settings** → **General**
2. Expandir **Visibility, project features, permissions**
3. Asegurarse de que **Wiki** está habilitado (toggle en azul)
4. Click **Save changes**
5. Sidebar → **Plan** → **Wiki**
6. Click **Create your first page**
7. Título: `Inicio`
8. Contenido:

```markdown
# Wiki del Proyecto

Bienvenido a la documentación del proyecto `explorar-gitlab-ce`.

## Páginas

- [Comandos Git](comandos-git) ← (puedes crear esta página después)

## Notas Rápidas

Esta wiki fue creada durante el Bootcamp GitLab CE.
```

9. **Message**: `docs: crear página de inicio de la wiki`
10. Click **Create page**

---

### Paso 8: Explorar Configuraciones de Seguridad del Proyecto

1. Sidebar → **Settings** → **Repository**
2. Expandir **Protected branches**
3. Ver que `main` ya está protegida por defecto
4. Explorar las opciones: quién puede hacer push, quién puede hacer merge

5. Sidebar → **Settings** → **Members**
6. Entender los roles: Guest, Reporter, Developer, Maintainer, Owner

---

## ✅ Verificación Final

Al completar la práctica, el proyecto debe tener:

- [ ] README.md con contenido real
- [ ] Archivo `.gitignore` generado desde template
- [ ] Al menos 3 labels creadas
- [ ] 1 milestone con fecha de vencimiento
- [ ] 1 issue creado y asignado
- [ ] Wiki habilitada con al menos 1 página
- [ ] Al menos 2 commits en el historial

```bash
# Clonar el proyecto y verificar localmente
git clone ssh://git@localhost:2224/root/explorar-gitlab-ce.git
cd explorar-gitlab-ce
git log --oneline
ls -la
```

---

## 🚨 Troubleshooting

| Problema | Causa | Solución |
|----------|-------|----------|
| No aparece "Generate default labels" | Labels ya existen | Ir directamente a crear labels manualmente |
| Wiki no aparece en el sidebar | Módulo deshabilitado | Settings → General → habilitar Wiki |
| No puedo editar archivos desde la UI | Sin permisos | Verifica que estás con el usuario correcto (root o con rol Developer+) |
| El milestone no aparece al crear un issue | Milestone en proyecto equivocado | Verificar que el milestone pertenece a este proyecto |

---

## 📝 Entregable

Capturas de pantalla mostrando:

1. El proyecto `explorar-gitlab-ce` con sus archivos en `http://localhost/root/explorar-gitlab-ce`
2. La lista de labels creadas
3. El milestone con su porcentaje de completado
4. El issue creado con labels y milestone asignados
5. La página de inicio de la Wiki

---

## ➡️ Siguiente Paso

¡Terminaste todas las prácticas! Ahora ve al [Proyecto de la Semana 01 →](../../3-proyecto/README.md)

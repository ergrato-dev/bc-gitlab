# Practica 04 — Primer Proyecto en GitLab CE

## Objetivo
Crear un proyecto en GitLab CE y conectarlo localmente.

## Instrucciones

1. Crear proyecto en GitLab CE via UI
2. Agregar clave SSH a GitLab
3. Clonar el proyecto localmente
4. Crear README.md con contenido
5. Hacer push del primer commit

### Paso a Paso

#### En GitLab CE (UI)

1. Click en **New Project** en el dashboard
2. Seleccionar **Create blank project**
3. Nombre: `practica-04-gitlab`
4. Visibility: Private
5. Marcar **Initialize repository with a README**

#### Agregar SSH Key

1. Ir a **Preferences → SSH Keys**
2. Pegar tu clave publica (`~/.ssh/id_ed25519.pub`)
3. Titulo: "Mi Laptop"
4. Click **Add key**

#### En tu terminal

```bash
# Clonar
git clone git@localhost:root/practica-04-gitlab.git
cd practica-04-gitlab

# Editar README.md
echo "## Acerca de" >> README.md
echo "Proyecto creado como practica del bootcamp." >> README.md

# Commit y push
git add README.md
git commit -m "docs: actualizar README con seccion Acerca de"
git push origin main
```

## Entregable
- URL del proyecto en GitLab CE
- Captura del proyecto mostrando el README renderizado

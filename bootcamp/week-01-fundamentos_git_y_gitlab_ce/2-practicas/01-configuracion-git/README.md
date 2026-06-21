# Practica 01 — Configuracion de Git

## Objetivo
Configurar Git con identidad, editor por defecto y autenticacion SSH.

## Instrucciones

1. Configurar nombre y email globales
2. Configurar editor por defecto (VS Code)
3. Generar y registrar clave SSH
4. Verificar configuracion

### Paso 1: Configurar identidad

Abre la terminal y ejecuta:

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu@email.com"
```

### Paso 2: Configurar editor por defecto

```bash
git config --global core.editor "code --wait"
```

### Paso 3: Configurar rama por defecto

```bash
git config --global init.defaultBranch main
```

### Paso 4: Generar clave SSH

```bash
ssh-keygen -t ed25519 -C "tu@email.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

### Paso 5: Verificar configuracion

```bash
git config --list
cat ~/.ssh/id_ed25519.pub
```

## Entregable
Captura de pantalla de `git config --list` mostrando usuario, email y editor configurados.

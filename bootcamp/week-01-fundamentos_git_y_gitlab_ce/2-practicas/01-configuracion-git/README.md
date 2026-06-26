# 🛠️ Práctica 01 — Configurar Git y SSH

⏱️ **Tiempo estimado**: 45 minutos
⭐⭐ **Dificultad**: Básico-Intermedio
📋 **Prerrequisitos**: Git instalado (`git --version` ≥ 2.30), GitLab CE corriendo

---

## 🎯 Objetivo

Configurar Git correctamente con identidad personal, editor preferido y autenticación SSH hacia GitLab CE. Al finalizar, podrás hacer `git push` y `git pull` sin ingresar contraseña.

---

## 📚 Teoría Relacionada

- [01 — Git: Comandos Esenciales](../../1-teoria/01-git-fundamentos.md) (sección "Configuración Inicial")
- [05 — Primeros Pasos en GitLab CE](../../1-teoria/05-primeros-pasos-gitlab.md) (sección "Configurar Autenticación SSH")

---

## 📋 Instrucciones

### Paso 1: Configurar la Identidad Global de Git

```bash
# Configura tu nombre (aparece en todos tus commits)
git config --global user.name "Tu Nombre Completo"

# Configura tu email (debe coincidir con tu cuenta de GitLab CE)
git config --global user.email "tu@email.com"

# Configura la rama por defecto al hacer git init
git config --global init.defaultBranch main

# Configura el editor para mensajes de commit
# Para VS Code:
git config --global core.editor "code --wait"
# Para nano (si no tienes VS Code):
git config --global core.editor "nano"

# Habilita colores en la salida
git config --global color.ui auto
```

### ✅ Verificación del Paso 1

```bash
git config --list --global
# Debes ver:
# user.name=Tu Nombre Completo
# user.email=tu@email.com
# init.defaultbranch=main
# core.editor=code --wait (o nano)
```

---

### Paso 2: Agregar Alias Útiles (Opcional pero Recomendado)

```bash
# Alias para ver el historial de forma visual
git config --global alias.lg "log --oneline --graph --all --decorate"

# Alias cortos para comandos frecuentes
git config --global alias.st "status"
git config --global alias.co "checkout"
git config --global alias.br "branch"
git config --global alias.sw "switch"

# Probar los alias
git lg    # (en cualquier repositorio con historial)
git st    # equivalente a git status
```

---

### Paso 3: Generar Clave SSH ed25519

```bash
# Generar par de claves SSH (ed25519 es más seguro que RSA)
ssh-keygen -t ed25519 -C "bootcamp-gitlab-ce" -f ~/.ssh/id_ed25519_gitlab

# El comando pregunta por una passphrase
# Para el bootcamp: presiona Enter dos veces (sin passphrase)
# En producción: siempre pon una passphrase

# Verificar que se crearon los archivos
ls -la ~/.ssh/id_ed25519_gitlab*
# Debes ver: id_ed25519_gitlab (privada) y id_ed25519_gitlab.pub (pública)
```

---

### Paso 4: Iniciar el ssh-agent y Cargar la Clave

```bash
# Iniciar el agente SSH
eval "$(ssh-agent -s)"
# Output esperado: Agent pid XXXXX

# Agregar la clave privada al agente
ssh-add ~/.ssh/id_ed25519_gitlab

# Verificar que la clave está cargada
ssh-add -l
# Debe mostrar la huella digital (fingerprint) de tu clave
```

---

### Paso 5: Agregar la Clave Pública a GitLab CE

```bash
# Mostrar la clave pública (copia TODO el output)
cat ~/.ssh/id_ed25519_gitlab.pub
# Empieza con: ssh-ed25519 AAAA...
```

En el navegador, ir a `http://localhost`:
1. Click en tu **avatar** (esquina superior derecha)
2. Seleccionar **Preferences**
3. Sidebar izquierdo → **SSH Keys**
4. Pegar la clave pública en el campo **Key**
5. **Title**: `mi-laptop-bootcamp`
6. **Expiration date**: Dejar vacío
7. Click **Add key**

---

### Paso 6: Configurar ~/.ssh/config

```bash
# Crear o editar el archivo de configuración SSH
cat >> ~/.ssh/config << 'EOF'

Host gitlab.local
    HostName localhost
    Port 2224
    User git
    IdentityFile ~/.ssh/id_ed25519_gitlab
    StrictHostKeyChecking no
EOF

# Corregir permisos (SSH es estricto con esto)
chmod 600 ~/.ssh/config
```

---

### Paso 7: Verificar la Conexión SSH con GitLab CE

```bash
# Probar la conexión con puerto explícito
ssh -T -p 2224 git@localhost

# Probar con el alias configurado
ssh -T gitlab.local

# En ambos casos debe responder:
# Welcome to GitLab, @root!
```

---

## ✅ Verificación Final Completa

Ejecuta estos comandos y guarda la salida para tu entregable:

```bash
# Ver toda la configuración de Git
git config --list

# Ver las claves SSH cargadas en el agente
ssh-add -l

# Probar autenticación con GitLab CE
ssh -T -p 2224 git@localhost

# Ver el archivo de configuración SSH
cat ~/.ssh/config
```

---

## 🚨 Troubleshooting

| Problema | Causa | Solución |
|----------|-------|----------|
| `Permission denied (publickey)` | La clave no está en GitLab o no está en el agente | `ssh-add -l` para verificar; re-agregar la clave en GitLab |
| `Connection refused` en puerto 2224 | GitLab no está corriendo | `docker compose ps gitlab` y reiniciar si es necesario |
| `WARNING: UNPROTECTED PRIVATE KEY FILE!` | Permisos incorrectos en la clave | `chmod 600 ~/.ssh/id_ed25519_gitlab` |
| `Host key verification failed` | Cambio en el host (reconectar) | `ssh-keygen -R "[localhost]:2224"` para limpiar known_hosts |
| `git config --list` muestra valores incorrectos | Configuración en wrong nivel | Verificar con `git config --list --show-origin` |
| `ssh-agent` no está corriendo | Faltó ejecutar `eval` | Volver a ejecutar `eval "$(ssh-agent -s)"` |

---

## 📝 Entregable

Crea un archivo `docs/semana-01/practica-01.md` en tu repositorio de portafolio con el output de:

1. `git config --list` (tu configuración completa)
2. `ssh -T -p 2224 git@localhost` (el "Welcome to GitLab" confirma que funciona)
3. `ssh-add -l` (muestra la clave cargada)

---

## ➡️ Siguiente Práctica

[Práctica 02 — Flujo Git Básico →](../02-flujo-git-basico/README.md)

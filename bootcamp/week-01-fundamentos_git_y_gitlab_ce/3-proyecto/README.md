# Proyecto Semana 01 — Repositorio Personal Profesional

## Objetivo

Configurar un repositorio Git personal en GitLab CE que sirva como portafolio DevOps. Este proyecto demuestra que dominas el flujo basico de Git y GitLab.

## Requisitos

Crear el proyecto `mi-portafolio-devops` en GitLab CE con la siguiente estructura:

```
mi-portafolio-devops/
├── README.md           # Titulo, descripcion, badges, stack
├── .gitignore          # Reglas de ignorado apropiadas
├── src/
│   └── hello.sh        # Script bash de ejemplo
├── docs/
│   └── notas.md        # Notas de aprendizaje
└── .gitlab-ci.yml      # Placeholder para CI/CD (se usa en semana 05)
```

## Instrucciones

### Fase 1: Crear proyecto en GitLab CE

1. Crear **blank project** llamado `mi-portafolio-devops`
2. Visibility: Private
3. **NO** marcar "Initialize with README" (lo crearemos manualmente)

### Fase 2: Inicializar localmente

```bash
# Crear carpeta local
mkdir mi-portafolio-devops
cd mi-portafolio-devops
git init

# Conectar con GitLab CE
git remote add origin git@gitlab.local:root/mi-portafolio-devops.git
```

### Fase 3: Crear estructura de archivos

```bash
# Crear directorios
mkdir -p src docs

# README.md
cat > README.md << 'EOF'
# Mi Portafolio DevOps

[![GitLab CE](https://img.shields.io/badge/GitLab-CE-fc6d26?logo=gitlab)](http://localhost)
[![Bootcamp](https://img.shields.io/badge/bootcamp-zero--to--hero-brightgreen)]()

Proyecto personal creado durante el Bootcamp GitLab CE Zero to Hero.

## Stack

- GitLab CE (Docker)
- Git + SSH
- Bash scripting
EOF

# .gitignore
cat > .gitignore << 'EOF'
# Archivos temporales
*.log
*.tmp
temp/

# Sistema operativo
.DS_Store
Thumbs.db

# Editor
*.swp
*.swo
*~
EOF

# Script de ejemplo
cat > src/hello.sh << 'EOF'
#!/usr/bin/env bash
echo "Hola desde mi portafolio DevOps!"
echo "Fecha: $(date)"
echo "GitLab CE corriendo en Docker"
EOF
chmod +x src/hello.sh

# Notas
cat > docs/notas.md << 'EOF'
# Notas de Aprendizaje

## Semana 01 — Fundamentos de Git y GitLab CE

- Git es un sistema de control de versiones distribuido
- GitLab CE integra repositorios, CI/CD, registry y mas
- SSH es el metodo recomendado para autenticacion
- El flujo basico es: clone → edit → add → commit → push
- Las ramas permiten desarrollo aislado
EOF

# Placeholder CI/CD
cat > .gitlab-ci.yml << 'EOF'
# Pipeline placeholder — Se implementara en Semana 05
stages:
  - hello

hello-world:
  stage: hello
  script:
    - echo "Pipeline funcionando en GitLab CE"
    - bash src/hello.sh
EOF
```

### Fase 4: Primer commit

```bash
git add -A
git status

git commit -m "feat: inicializar portafolio DevOps

- README.md con badges y descripcion
- .gitignore con reglas basicas
- src/hello.sh: script de ejemplo
- docs/notas.md: notas de aprendizaje
- .gitlab-ci.yml: placeholder para CI/CD"
```

### Fase 5: Push inicial

```bash
git branch -M main
git push -u origin main
```

### Fase 6: Trabajar con ramas

```bash
# Crear rama develop para trabajo futuro
git checkout -b develop

# Agregar algo en develop
echo "" >> docs/notas.md
echo "## Proximos temas" >> docs/notas.md
echo "- Instalacion de GitLab CE" >> docs/notas.md
echo "- Proyectos y grupos" >> docs/notas.md

git add docs/notas.md
git commit -m "docs: agregar proximos temas a notas"
git push -u origin develop

# Volver a main
git checkout main
```

### Fase 7: Merge de develop a main

```bash
git merge develop
git push origin main
```

## Entregables

- [ ] URL del repositorio en GitLab CE (`http://localhost/root/mi-portafolio-devops`)
- [ ] Captura del historial de commits:
  ```bash
  git log --oneline --graph --all
  ```
- [ ] Captura de las ramas:
  ```bash
  git branch -a
  ```
- [ ] Captura del proyecto en GitLab CE mostrando los archivos

## Criterios de Evaluacion

| Criterio | Peso | Check |
|----------|------|-------|
| Proyecto creado en GitLab CE | 15% | [ ] |
| README.md con badges y contenido | 20% | [ ] |
| .gitignore con reglas apropiadas | 10% | [ ] |
| Al menos 2 ramas (main + develop) | 15% | [ ] |
| 5+ commits con mensajes descriptivos | 25% | [ ] |
| Codigo de ejemplo funcional | 15% | [ ] |

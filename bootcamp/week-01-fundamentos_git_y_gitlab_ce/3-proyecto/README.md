# 🚀 Proyecto Semana 01 — Repositorio Personal Profesional

⏱️ **Tiempo estimado**: 1 hora
👤 **Modalidad**: Individual
⭐⭐ **Dificultad**: Básico-Intermedio

---

## 📋 Descripción

Crea un repositorio personal en GitLab CE que funcione como tu **portafolio DevOps**. Este repositorio te acompañará durante todo el bootcamp: cada semana agregar áreas de ramas, pipelines, configuraciones y documentación de lo aprendido.

El objetivo no es tener el repositorio perfecto desde el inicio, sino demostrar que dominas el flujo Git + GitLab CE y construir la base de algo que irá creciendo.

---

## 🎯 Objetivos del Proyecto

- Demostrar dominio del flujo completo de Git: `init` → `add` → `commit` → `push`
- Practicar Conventional Commits en mensajes reales
- Crear y fusionar ramas usando Merge Requests en GitLab CE
- Estructurar un repositorio profesional con README informativo, .gitignore y documentación

---

## 🏗️ Estructura Requerida

```
mi-portafolio-devops/
├── README.md              # Presentación profesional del portafolio
├── .gitignore             # Reglas de ignorado apropiadas para bash/scripts
├── docs/
│   └── aprendizaje.md    # Reflexión sobre lo aprendido en la semana
└── scripts/
    └── hola.sh           # Script básico de shell que se puede ejecutar
```

---

## 📋 Instrucciones Detalladas

Ver [instrucciones.md](./instrucciones.md) para los comandos exactos paso a paso.

**Resumen de fases**:

1. **Crear proyecto** en GitLab CE (sin README inicial)
2. **Inicializar localmente** con `git init` y conectar al remoto
3. **Crear estructura** de archivos con contenido real
4. **Commits semánticos**: al menos 5 commits descriptivos con Conventional Commits
5. **Trabajar con ramas**: `main` + `dev` + al menos 1 rama `feature/`
6. **Merge Request**: crear una MR en GitLab CE y hacer el merge
7. **Push final**: el estado completo del proyecto en el remoto

---

## 📄 Contenido Esperado por Archivo

### `README.md` — Presentación del Portafolio

Debe incluir:
- Tu nombre y descripción breve (1-2 oraciones)
- Lo que aprenderás/aprendiste en el bootcamp
- Stack tecnológico (GitLab CE, Docker, Bash, etc.)
- Estado actual del repositorio (semana 01: fundamentos)
- Tabla de contenido o estructura del repo

### `.gitignore` — Reglas de Ignorado

Debe incluir reglas para:
- Sistema operativo: `.DS_Store`, `Thumbs.db`
- Archivos temporales: `*.log`, `*.tmp`, `temp/`
- Editor: `*.swp`, `.vscode/` (o el editor que uses)
- Secretos: `.env` (muy importante)

### `docs/aprendizaje.md` — Reflexión de la Semana

Debe incluir:
- Los 3 conceptos más importantes que aprendiste
- El error más común que cometiste y cómo lo resolviste
- Qué comando de Git te parece más útil y por qué
- Una pregunta que aún no tienes clara

### `scripts/hola.sh` — Script Funcional

Debe ser ejecutable (`chmod +x`) y mostrar al menos:
- Un mensaje de bienvenida
- La fecha y hora actual
- Información del sistema (o cualquier otra info útil)

---

## ✅ Criterios de Evaluación

| Criterio | Peso | Indicadores |
|----------|------|-------------|
| **README.md profesional** | 30% | Incluye nombre, descripción, stack; está bien formateado en Markdown; tiene contenido real (no el template) |
| **Commits semánticos** | 30% | Mínimo 5 commits; siguen formato `tipo: descripción`; mensajes descriptivos; uno por propósito |
| **Ramas y MR** | 20% | Rama `dev` existe; al menos 1 MR creada y fusionada en GitLab CE; se ve el historial de ramas en `git log` |
| **Documentación** | 20% | `docs/aprendizaje.md` tiene contenido real y reflexivo; `scripts/hola.sh` es ejecutable y funciona |

**Puntuación mínima para aprobar**: 70/100

---

## 📦 Entregables

- [ ] URL del repositorio en GitLab CE: `http://localhost/root/mi-portafolio-devops` (o tu usuario)
- [ ] Output de `git log --oneline --graph --all` mostrando al menos 5 commits y ramas
- [ ] Captura de la Merge Request cerrada/merged en GitLab CE
- [ ] `scripts/hola.sh` ejecutado: `bash scripts/hola.sh`

---

## 💡 Tips para Destacar

- Agrega badges al README (GitLab CE, bootcamp, etc.)
- Escribe la reflexión honestamente — es para tu propio aprendizaje
- Haz commits pequeños y frecuentes en lugar de uno solo enorme
- El nombre del proyecto puede ser más creativo que `mi-portafolio-devops`

---

## ➡️ Siguiente Semana

Al terminar este proyecto estarás listo para la [Semana 02 — Instalación de GitLab CE](../../week-02-instalacion_gitlab_ce/).

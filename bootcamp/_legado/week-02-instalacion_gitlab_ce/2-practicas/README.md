# 🛠️ Prácticas — Semana 02: Instalación de GitLab CE

Esta carpeta contiene las 4 prácticas guiadas de la semana. Deben realizarse **en orden**, ya que cada una depende de la anterior.

---

## Índice de prácticas

| # | Práctica | Tiempo | Dificultad | Descripción |
|---|---------|--------|-----------|-------------|
| 01 | [Preparación del entorno](./01-preparacion-entorno/README.md) | 30 min | ⭐ Básico | Verificar Docker, recursos y clonar el repositorio |
| 02 | [Levantar GitLab CE](./02-docker-compose-gitlab/README.md) | 60 min | ⭐⭐ Básico-Intermedio | Docker Compose up, monitorear inicio, obtener contraseña root |
| 03 | [Configuración post-instalación](./03-configuracion-post-instalacion/README.md) | 45 min | ⭐⭐ Básico-Intermedio | Cambiar contraseña, apariencia, crear usuario, proyecto de prueba |
| 04 | [Backup y Restore](./04-backup-y-restore/README.md) | 45 min | ⭐⭐ Básico-Intermedio | Backup completo, secrets, restore verificado, script automático |

**Tiempo total estimado:** ~3 horas (incluye espera del primer arranque de GitLab)

---

## Flujo recomendado

```
01-preparacion-entorno
        ↓
02-docker-compose-gitlab   ← El que más tiempo toma (esperar "healthy")
        ↓
03-configuracion-post-instalacion
        ↓
04-backup-y-restore
        ↓
3-proyecto/instrucciones.md  ← Proyecto integrador
```

---

## Notas importantes

- **No saltes prácticas.** Cada una produce artefactos (contenedores, proyectos, backups) que las siguientes necesitan.
- **El primer arranque de GitLab tarda 5-15 minutos.** Es normal. No reinicies el contenedor mientras esperas.
- **Guarda `gitlab-secrets.json`** en un lugar seguro fuera del repositorio después de la práctica 04.
- Todos los comandos asumen que estás en la **raíz del repositorio** `bc-gitlab/`.

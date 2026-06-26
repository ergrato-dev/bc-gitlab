# 🛠️ Prácticas — Semana 03: Proyectos, Grupos y Organización

Esta carpeta contiene las 4 prácticas guiadas de la semana. Deben realizarse **en orden**, ya que cada una construye sobre la anterior.

---

## Índice de prácticas

| # | Práctica | Tiempo | Dificultad | Descripción |
|---|---------|--------|-----------|-------------|
| 01 | [Crear Proyectos](./01-crear-proyectos/README.md) | 45 min | ⭐ Básico | Crear proyectos en blanco, desde template, por importación y via API |
| 02 | [Grupos y Subgrupos](./02-grupos-y-subgrupos/README.md) | 45 min | ⭐⭐ Básico-Intermedio | Estructura jerárquica `bootcamp-org` con subgrupos y proyectos |
| 03 | [Permisos y Roles](./03-permisos-y-roles/README.md) | 45 min | ⭐⭐ Básico-Intermedio | Crear usuarios, asignar roles, verificar herencia de permisos |
| 04 | [Proteger Ramas](./04-proteger-ramas/README.md) | 60 min | ⭐⭐⭐ Intermedio | Protected branches, wildcard, CODEOWNERS, flujo MR completo |

**Tiempo total estimado:** ~3.5 horas

---

## Flujo recomendado

```
01-crear-proyectos            ← Token de acceso y proyectos individuales
        ↓
02-grupos-y-subgrupos         ← Estructura bootcamp-org con 6 proyectos
        ↓
03-permisos-y-roles           ← Usuarios y permisos heredados/directos
        ↓
04-proteger-ramas             ← Protected branches + MR flow completo
        ↓
3-proyecto/instrucciones.md   ← Proyecto integrador (TechNova)
```

---

## Prerequisito compartido

Todas las prácticas usan el mismo Personal Access Token. Créalo antes de empezar:

```
http://localhost/-/user_settings/personal_access_tokens
Token name:  practica-03-api
Scopes:      ✓ api
```

```bash
export GITLAB_TOKEN="tu-token-aqui"
```

---

## Notas importantes

- **No saltes prácticas.** Cada una produce usuarios, grupos y proyectos que las siguientes necesitan.
- **La práctica 04 requiere `git` en la terminal.** Verifica con `git --version`.
- **Los usuarios creados** (`developer1`, `maintainer1`, `reporter1`) se reusan en el Proyecto de la semana.
- Si algo sale mal en una práctica, puedes limpiar con la API (`DELETE /api/v4/groups/:id`) y empezar de nuevo.

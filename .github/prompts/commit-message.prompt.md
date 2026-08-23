---
name: "Mensaje de commit"
description: "Genera un mensaje de commit en Conventional Commits, en español, con los tipos y ámbitos propios del Bootcamp GitLab CE."
argument-hint: "Qué se cambió (o deja que se deduzca del diff en el área de staging)"
mode: "agent"
---

# Mensaje de commit — Bootcamp GitLab CE

Genera **un solo** mensaje de commit. Sin alternativas, sin explicación alrededor.

## Formato

```
<tipo>(<ámbito>): <resumen en imperativo, minúscula, sin punto final>

<cuerpo opcional: qué cambió y por qué, no cómo>
```

El resumen no pasa de 72 caracteres.

## Tipos

| Tipo | Cuándo |
|---|---|
| `feat` | Contenido nuevo: una semana, un archivo de teoría, una práctica |
| `fix` | Corregir algo que estaba mal: un endpoint inexistente, un enlace roto, un tier equivocado |
| `docs` | Documentación transversal de `docs/`, README raíz, CONTRIBUTING |
| `chore` | Infraestructura del repo: compose, scripts, `.env.example`, dependencias |
| `refactor` | Reorganizar contenido sin cambiar lo que enseña |
| `style` | Formato, tipografía, tablas. Nunca cambia el significado |

## Ámbitos

- `week-01` … `week-26` para contenido de una semana concreta
- `bootcamp` para cambios que cruzan varias semanas
- `docs`, `scripts`, `lab`, `ci` para lo transversal
- Sin ámbito si el cambio es global

## Ejemplos

```
feat(week-09): contenido completo de la Semana 09 — CI/CD fundamentos
```

```
fix(week-13): corregir el endpoint de politicas de limpieza del registry

El material usaba projects/:id/registry/cleanup_policies, que no existe.
La politica se lee y se escribe en el propio proyecto, en el campo
container_expiration_policy.
```

```
chore(lab): separar el compose en perfiles base y observabilidad
```

## Reglas

- **En español**, salvo el tipo, que es la palabra clave inglesa.
- **Imperativo**: "añade", "corrige", "separa". No "añadido" ni "añadiendo".
- El cuerpo explica **por qué**, no repite el diff.
- Una línea en blanco entre resumen y cuerpo, siempre.
- Si el cambio arregla algo que estaba mal en el material, el cuerpo dice **qué
  fallaba**: es la información que le sirve a quien lo lea dentro de un año.

$input

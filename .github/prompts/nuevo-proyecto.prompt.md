---
name: "Nuevo proyecto de semana"
description: "Genera el 3-proyecto/README.md de una semana: la capa que esa semana añade al hilo conductor, con los requisitos copiados literalmente del checks.json."
argument-hint: "Semana (ej: 14) y qué capa añade al proyecto del alumno"
mode: "agent"
---

# Nuevo proyecto de semana — Bootcamp GitLab CE

El proyecto **no es un ejercicio desechable**: es la capa que esta semana añade
a la plataforma que el alumno construye durante 26 semanas. La tabla de capas
está en `docs/proyecto-hilo-conductor.md` y manda.

## Estructura obligatoria

```markdown
# Proyecto Semana NN — Nombre de la capa

> Una línea: qué tendrá tu plataforma que no tenía.

## 🎯 Objetivo

## 📦 Qué añade esta capa

Cómo encaja con lo que construiste la semana anterior y qué desbloquea en la
siguiente. Esto es lo que convierte 26 ejercicios en un proyecto.

## ✅ Requisitos verificables

1. Copia literal de la descripción del check 1
2. Copia literal de la descripción del check 2

## 🎨 Criterios de calidad

Lo que la API no ve y sí puntúa la rúbrica.

## 💡 Adaptación a tu dominio

| Dominio | Cómo se concreta aquí |
|---|---|

## 🚦 Cómo entregarlo

```bash
./scripts/verificar-semana.sh NN
```

## 🧯 Errores comunes

## 🔗 Navegación
```

## Reglas

1. **Los requisitos verificables son literalmente las descripciones de
   `checks.json`.** Si no coinciden palabra por palabra, el alumno no sabe qué
   le falta cuando una comprobación falla. Cópialas, no las reescribas.
2. **La sección "Qué añade esta capa" mira hacia atrás y hacia delante.** Sin
   eso, el proyecto se lee como un ejercicio suelto.
3. **Los criterios de calidad son lo que la API no puede ver**: nombres que se
   entienden, un `.gitlab-ci.yml` legible, un mensaje de commit que explica el
   porqué. Son los 40 puntos manuales del producto.
4. **La tabla de dominios trae 3-4 dominios de los de
   `docs/proyecto-hilo-conductor.md`**, con la concreción real de esta capa en
   cada uno.
5. **Nada de crear proyectos nuevos** salvo que la tabla de capas lo diga
   (`ci/componentes` en la S12, `ci/automatizacion` en la S17, `infra` en la S11).
6. **Los errores comunes salen de haberlo hecho**, no de imaginarlos.

## Extensión

100-140 líneas. Es el documento más corto de la semana y el que más se relee.

## Antes de entregar

- [ ] Los requisitos coinciden literalmente con `checks.json`
- [ ] La capa coincide con la tabla de `docs/proyecto-hilo-conductor.md`
- [ ] Se explica el encaje con la semana anterior y la siguiente
- [ ] La tabla de dominios usa los dominios oficiales
- [ ] Enlaces de navegación correctos

$input

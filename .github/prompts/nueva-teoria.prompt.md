---
name: "Nueva teoría"
description: "Genera un archivo de teoría del Bootcamp GitLab CE con la estructura fija: qué problema resuelve, cómo funciona, cómo se configura, antipatrones, trucos. 200-300 líneas, con comandos glab reales y verificables."
argument-hint: "Semana (ej: 11), nombre del archivo (ej: 03-artifacts-y-cache.md) y el concepto a explicar"
mode: "agent"
---

# Nuevo archivo de teoría — Bootcamp GitLab CE

## Estructura obligatoria

```markdown
# Título del concepto

> Una línea: qué resuelve esto y por qué te importa.

## 🎯 Objetivos

- Objetivo verificable 1
- Objetivo verificable 2

## 1. Qué problema resuelve

El problema antes que la solución, con un caso concreto y reconocible.

## 2. Cómo funciona

### 2.1 Subtema

Tablas para comparar opciones. Bloques ✅/❌ para contrastar.

## 3. Cómo se configura

Con `glab` **y** con la UI web.

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|

## 5. Trucos

## 📚 Recursos Adicionales

## ✅ Checklist de Verificación

- [ ] Casillas verificables sobre la propia instancia
```

Las secciones numeradas pueden ser más de cinco. Antipatrones y trucos van
siempre al final, en ese orden.

## Extensión

**200-300 líneas, objetivo ~250.** Si se pasa, casi siempre es porque mezcla dos
conceptos: **divídelo en dos archivos, no recortes el contenido.** Nunca se
sacrifica profundidad para que quepa.

## Reglas

1. **Un archivo, un concepto.** Si el título necesita una "y", sospecha.
2. **El porqué antes del comando.** Siempre.
3. **`glab` y UI.** La UI cambia de sitio los botones; el CLI es estable. El
   alumno tiene que saber hacer las dos cosas.
4. **Marca el tier.** Si la feature es Premium o Ultimate: qué problema resuelve,
   qué tier la incluye, cuándo compensa pagarla, y **cuál es el sustituto libre
   que usa este bootcamp**. Si es Free pero suele darse por premium, dilo también.
5. **No inventes** endpoints de la API v4, palabras clave de `.gitlab-ci.yml`,
   subcomandos de `glab` ni opciones de `gitlab.rb`. Compruébalo contra la
   instancia o enlaza `docs.gitlab.com`.
6. **Los bloques de comando muestran la salida esperada** en un comentario.
7. **Diagramas SVG**, referenciados con ruta relativa a `../0-assets/`. Nada de
   arte ASCII.
8. **Todo `.gitlab-ci.yml` de ejemplo lleva `rules`**, o dice explícitamente que
   es un fragmento mínimo.
9. **Nunca un token con formato válido**, ni inventado. `<TOKEN>` o `$CI_JOB_TOKEN`.
10. **Fecha lo volátil**: precios, tiers, disponibilidad.
11. Los recursos adicionales llevan una línea de por qué valen la pena.

## Antes de entregar

- [ ] Entre 200 y 300 líneas
- [ ] Un solo concepto
- [ ] Cada comando comprobado contra una instancia real
- [ ] Cada feature de pago marcada con su tier y su sustituto
- [ ] Antipatrones en tabla, con las tres columnas
- [ ] Checklist final verificable sobre la instancia del alumno
- [ ] Enlaces relativos correctos (`../0-assets/`, `../../../README.md`)

$input
